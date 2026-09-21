#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(read_binary write_binary);
use Crypt::Age;

use lib 't/lib';
use SopsBin qw(find_sops_bin);

use File::SOPS;
use File::SOPS::Format::YAML;

# Multi-document YAML used to be accepted and silently reduced to its LAST
# document, because YAML::XS::Load in scalar context returns only that one.
# Encrypting a two-document file therefore wrote one document back and threw
# the other away, with no error and nothing in the output to show it had
# happened. k31 / docs/adr/0033 replaces that with real support.
# WIRE (File::SOPS::Format::YAML->parse, _parse_in_document_order, the MAC
# over all documents), the public API's READ path -- decrypt returns an
# ArrayRef of HashRefs for a real stream and a bare HashRef for a single
# document, extract takes a document => $n argument -- and, since k31
# step 5, the WRITE path too: encrypt/encrypt_file/encrypt_in_place/rotate and
# decrypt_file-to-YAML all write a multi-document stream now, with one sops:
# block per document (byte-identical) and the documents joined by --- (points
# 1 and 5). All of that is pinned below as round-trip tests against the real
# binary.
#
# Two refusals remain, both deliberate rather than pending work:
#   * converting a stream to a format with no document axis -- json, env, ini
#     -- is refused (Decision 3), because sops itself drops all but the first
#     document there, silently, at exit 0 (N1), and this library declines to
#     reproduce that data loss;
#   * edit on a multi-document stream is refused (k41): edit re-encrypts
#     under a NEW data key, and docs/adr/0033 deliberately leaves
#     edit-on-a-stream semantics open rather than settling k41 by
#     accident.
#
# The measured sops model is recorded in docs/adr/0033 and in
# File::SOPS::Format::YAML.

my $TWO_DOCS = "alpha: one\nshared: first\n---\nbeta: two\nshared: second\n";

# Encrypts $content with the real sops binary using $sops_bin, on a fresh age
# keypair, and returns ($enc, $secret) -- the encrypted bytes and the secret
# key that can decrypt them. Records whether sops itself exited 0 as a test
# belonging to whichever subtest is currently running; returns nothing if it
# did not, so callers write
# `my (...) = sops_encrypt(...); return unless defined $enc;`.
sub sops_encrypt {
    my ($sops_bin, $content, $name) = @_;
    $name //= 'doc.yaml';

    my ($public, $secret) = Crypt::Age->generate_keypair();
    my $tempdir = tempdir(CLEANUP => 1);
    write_binary("$tempdir/key.txt", $secret);
    local $ENV{SOPS_AGE_KEY_FILE} = "$tempdir/key.txt";

    write_binary("$tempdir/$name", $content);
    my $enc = `$sops_bin --age $public -e $tempdir/$name 2>&1`;
    is($? >> 8, 0, "sops encrypted $name") or do {
        diag("sops output: $enc");
        return;
    };

    return ($enc, $secret);
}

# A fixed-output stand-in for the CSPRNG, used only to prove Decision 1's
# byte-identity promise (see the subtest below). File::SOPS::Encrypted's
# shared _random_bytes calls through to Crypt::PRNG::random_bytes for both the
# data key and every per-value GCM nonce, and _encrypt_tree walks a hash with
# `for my $k (keys %$node)` -- UNSORTED, and NOT guaranteed to visit two
# structurally-identical-but-separately-built hashes in the same order:
# measured, `{ %doc }` evaluated twice in the same process gives `keys` two
# different orders. A call-order-based deterministic mock (a counter) would
# therefore hand the wrong nonce to the wrong leaf between the two encrypt()
# calls being compared. A single FIXED return sidesteps that: ciphertext is a
# pure function of (key, iv, aad, plaintext), and aad/plaintext are identical
# for the same leaf regardless of which order the walk reached it in, so a
# constant key and a constant nonce make every leaf's ciphertext depend only
# on its own path and value -- not on when it was visited.
sub fixed_random_bytes {
    return sub {
        my ($n) = @_;
        return substr('K' x 64, 0, $n);
    };
}

###############################################################################
subtest 'parse returns a document list for a two-document stream' => sub {
    my ($first, $metadata, $documents) = eval {
        File::SOPS::Format::YAML->parse($TWO_DOCS) };
    ok(!$@, 'parse no longer dies on a multi-document stream') or diag($@);

    is(scalar @$documents, 2, 'both documents came back');
    is_deeply($documents,
        [ { alpha => 'one', shared => 'first' },
          { beta  => 'two', shared => 'second' } ],
        'each document keeps its own values, in document order');
    is_deeply($first, $documents->[0],
        'the first return value mirrors document 0');
    is($metadata, undef,
        'neither document in this fixture has a sops section, so no metadata');

    # Metadata comes from the FIRST document only, and is stripped from every
    # document's value tree wherever a sops section appears (docs/adr/0033
    # point 2).
    my ($first2, $metadata2, $documents2) = eval { File::SOPS::Format::YAML->parse(
        "alpha: one\nsops:\n    version: 3.13.3\n---\nbeta: two\n"
    ) };
    ok(!$@, 'a stream carrying metadata only in its first document parses')
        or diag($@);
    isa_ok($metadata2, 'File::SOPS::Metadata', 'metadata built from the first document');
    is($metadata2->version, '3.13.3', 'metadata is taken from the first document');
    is_deeply($documents2,
        [ { alpha => 'one' }, { beta => 'two' } ],
        'sops is stripped from document 0, and document 1 is unaffected');
};

###############################################################################
subtest 'an empty document is a real document and reads back as {}' => sub {
    # An empty document in the middle is a real document to both YAML::XS and
    # sops, which gives it its own metadata block and reads it back as {}
    # (docs/adr/0033 point 6).
    my (undef, undef, $documents) = eval {
        File::SOPS::Format::YAML->parse("a: 1\n---\n---\nb: 2\n") };
    ok(!$@, 'three documents, one empty, parse without dying') or diag($@);
    is(scalar @$documents, 3, 'the empty middle document is counted');
    is_deeply($documents, [ { a => 1 }, {}, { b => 2 } ],
        'and it reads back as {}, not as dropped or merged');

    # A trailing separator opens a second, empty document. sops agrees -- it
    # writes two metadata blocks for this input.
    (undef, undef, $documents) = eval {
        File::SOPS::Format::YAML->parse("a: 1\n---\n") };
    ok(!$@, 'a trailing --- parses without dying') or diag($@);
    is(scalar @$documents, 2, 'a trailing --- is a second document');
    is_deeply($documents, [ { a => 1 }, {} ],
        'and it too reads back as {}');
};

###############################################################################
subtest 'single-document streams are unaffected' => sub {
    my ($data) = File::SOPS::Format::YAML->parse("a: 1\nb: two\n");
    is_deeply($data, { a => 1, b => 'two' }, 'plain single document');

    # A leading separator is legal single-document YAML. sops drops it on
    # write; either way it must not be miscounted as an extra document.
    ($data) = File::SOPS::Format::YAML->parse("---\na: 1\n");
    is_deeply($data, { a => 1 }, 'leading --- is not a second document');

    # The document count comes from a real parser, never from splitting the
    # text on /^---$/. A value that CONTAINS a separator-looking line must not
    # be mistaken for one -- PEM blocks are the obvious real-world case.
    my $pem = "cert: |\n  -----BEGIN CERTIFICATE-----\n  abc\n"
            . "  -----END CERTIFICATE-----\ndashes: \"x --- y\"\n";
    ($data) = File::SOPS::Format::YAML->parse($pem);
    like($data->{cert}, qr/BEGIN CERTIFICATE/, 'block scalar survives intact');
    is($data->{dashes}, 'x --- y', 'a --- inside a value is just text');

    # Unchanged pre-existing behaviour, re-pinned because the empty stream now
    # takes a different route through parse (0 documents, not undef).
    like(do { eval { File::SOPS::Format::YAML->parse("") }; $@ },
        qr/did not parse to a hash/, 'empty input still reports no hash');
    like(do { eval { File::SOPS::Format::YAML->parse("- a\n- b\n") }; $@ },
        qr/did not parse to a hash/, 'a top-level sequence is still refused');
};

###############################################################################
subtest 'encrypt_file and encrypt_in_place write a multi-document stream, and sops -d reads it back' => sub {
    # k31 step 5 landed: the emitter's document separators exist now, so
    # these two write the WHOLE stream instead of refusing it. Proven against
    # the real binary in the direction that actually matters -- can sops read
    # what this library writes -- not just that this library can read its own
    # output back.
    my $sops_bin = find_sops_bin();
    plan skip_all =>
        "No sops binary found (checked \$SOPS_BIN, PATH, .sops-bin/sops, /tmp/sops) -- "
      . "this proves encrypt_file/encrypt_in_place write a stream sops itself "
      . "can read, not just one this library can read back. Fix: run "
      . "maint/fetch-sops .sops-bin to install the pinned binary where the "
      . "suite finds it automatically, or set SOPS_BIN=/path/to/sops."
        unless $sops_bin;
    diag("Using sops binary: $sops_bin");

    my ($public, $secret) = Crypt::Age->generate_keypair();
    my $dir = tempdir(CLEANUP => 1);
    write_binary("$dir/key.txt", $secret);
    local $ENV{SOPS_AGE_KEY_FILE} = "$dir/key.txt";

    my $in = "$dir/two.yaml";
    write_binary($in, $TWO_DOCS);
    my $out = "$dir/two.enc.yaml";

    ok(File::SOPS->encrypt_file(
        input      => $in,
        output     => $out,
        recipients => [$public],
    ), 'encrypt_file returns true');

    my $content = read_binary($out);
    is(scalar(() = $content =~ /^---\s*$/mg), 2,
        'two --- separators -- YAML::XS::Dump prepends one to EVERY document (docs/adr/0033 point 5)');
    is(scalar(() = $content =~ /^sops:\s*$/mg), 2,
        'and two sops: blocks, one per document, byte-identical (docs/adr/0033 point 1)');

    my $decrypted = `$sops_bin -d $out 2>&1`;
    is($? >> 8, 0, 'sops -d reads the written stream back') or diag($decrypted);
    like($decrypted, qr/alpha: one/, 'document 0 survived');
    like($decrypted, qr/beta: two/, 'document 1 survived');

    # encrypt_in_place -- the form where a truncating write used to be
    # unrecoverable, because there was no separate output file to compare
    # against. It writes the same stream over the source file.
    my $inplace = "$dir/inplace.yaml";
    write_binary($inplace, $TWO_DOCS);
    ok(File::SOPS->encrypt_in_place(file => $inplace, recipients => [$public]),
        'encrypt_in_place returns true');

    my $inplace_content = read_binary($inplace);
    is(scalar(() = $inplace_content =~ /^---\s*$/mg), 2,
        'encrypt_in_place: two --- separators too');
    is(scalar(() = $inplace_content =~ /^sops:\s*$/mg), 2,
        'encrypt_in_place: two sops: blocks too');

    my $decrypted2 = `$sops_bin -d $inplace 2>&1`;
    is($? >> 8, 0, 'sops -d reads the in-place-encrypted stream back') or diag($decrypted2);
    like($decrypted2, qr/alpha: one/, 'document 0 survived in-place');
    like($decrypted2, qr/beta: two/, 'document 1 survived in-place');
};

###############################################################################
subtest 'encrypt(data => arrayref) writes a multi-document stream, and sops -d reads both documents' => sub {
    # Before docs/adr/0033 an ArrayRef died with "data must be a hash ref";
    # since Decision 1 it is the way to write a stream, through encrypt()
    # itself and not only through encrypt_file. Proven against the real
    # binary, not just against this library's own decrypt.
    my $sops_bin = find_sops_bin();
    plan skip_all =>
        "No sops binary found (checked \$SOPS_BIN, PATH, .sops-bin/sops, /tmp/sops) -- "
      . "this proves encrypt(data => arrayref) writes a stream sops itself can "
      . "read. Fix: run maint/fetch-sops .sops-bin to install the pinned "
      . "binary where the suite finds it automatically, or set "
      . "SOPS_BIN=/path/to/sops."
        unless $sops_bin;
    diag("Using sops binary: $sops_bin");

    my ($public, $secret) = Crypt::Age->generate_keypair();
    my $dir = tempdir(CLEANUP => 1);
    write_binary("$dir/key.txt", $secret);
    local $ENV{SOPS_AGE_KEY_FILE} = "$dir/key.txt";

    my $enc = eval {
        File::SOPS->encrypt(
            data       => [ { a => 1 }, { b => 2 } ],
            recipients => [$public],
        );
    };
    ok(!$@, 'encrypt(data => arrayref) with two documents no longer dies') or diag($@);

    my $out = "$dir/arrayref.enc.yaml";
    write_binary($out, $enc);

    my $decrypted = `$sops_bin -d $out 2>&1`;
    is($? >> 8, 0, 'sops -d reads the stream encrypt(data => arrayref) wrote') or diag($decrypted);
    like($decrypted, qr/^a: 1$/m, 'document 0 survived');
    like($decrypted, qr/^b: 2$/m, 'document 1 survived');
};

###############################################################################
subtest 'a one-element ArrayRef is byte-identical to the same HashRef (docs/adr/0033 Decision 1)' => sub {
    # "encrypt given a one-element ArrayRef writes a one-document file,
    # byte-identical to what the same HashRef would produce" -- ADR 0033
    # Decision 1. Two irreducible sources of non-determinism stand between
    # this and a plain string eq: the age `enc:` blob (Crypt::Age's own
    # ephemeral key and nonce, generated inside Crypt::Age and invisible from
    # here -- see t/21-random-bytes.t) and `lastmodified` (real wall-clock
    # seconds). Both are normalised out before comparing; the mac: line is
    # normalised too, because its own ciphertext is authenticated over
    # lastmodified as AAD and so inherits that same variance whenever the two
    # calls straddle a second boundary. Everything else -- key order, quoting,
    # every leaf's own ENC[...] -- is compared byte for byte, with a fixed
    # CSPRNG stand-in (fixed_random_bytes, above) making that possible despite
    # _encrypt_tree's unsorted, order-varying hash walk.
    my ($public, $secret) = Crypt::Age->generate_keypair();
    my %doc = ( alpha => 'one', nested => { x => 1, y => 2.5, z => 'hello world' } );

    my ($enc_hash, $enc_array);
    {
        no warnings 'redefine';
        local *Crypt::PRNG::random_bytes = fixed_random_bytes();
        $enc_hash  = File::SOPS->encrypt(
            data => { %doc }, recipients => [$public], format => 'yaml');
        $enc_array = File::SOPS->encrypt(
            data => [ { %doc } ], recipients => [$public], format => 'yaml');
    }

    for my $enc ($enc_hash, $enc_array) {
        $enc =~ s/-----BEGIN AGE ENCRYPTED FILE-----.*?-----END AGE ENCRYPTED FILE-----/<AGE-BLOB>/s;
        $enc =~ s/lastmodified: "[^"]*"/lastmodified: "<TIME>"/;
        $enc =~ s/mac: ENC\[[^\]]*\]/mac: <MAC>/;
    }

    is($enc_array, $enc_hash,
        'encrypt(data => [\%doc]) writes the same document as encrypt(data => \%doc), '
      . 'byte for byte apart from the age blob and the timestamp');

    # The round-trip half of Decision 1: what comes back OUT is a bare
    # HashRef, not a one-element ArrayRef -- what round-trips is the FILE, not
    # the Perl container that built it.
    my $enc = File::SOPS->encrypt(
        data => [ { alpha => 'one' } ], recipients => [$public], format => 'yaml');
    my $data = File::SOPS->decrypt(encrypted => $enc, identities => [$secret]);
    is(ref($data), 'HASH',
        'decrypt reads a one-document file back as a bare HashRef, not an ArrayRef');
    is_deeply($data, { alpha => 'one' }, 'holding what was encrypted');
};

###############################################################################
subtest 'rotate re-keys a multi-document stream, and sops -d still reads it (point 3, N6)' => sub {
    # rotate decrypts (now an ArrayRef for a stream), then re-encrypts through
    # encrypt() (now happy to take one) -- the mechanics fall out of the two
    # halves that already work, with no multidoc-specific code of its own.
    # Independent fixture from the edit subtest below: they used to share one
    # $file, and rotate mutating it before edit ran made edit's assertions
    # depend on rotate's.
    my $sops_bin = find_sops_bin();
    plan skip_all =>
        "No sops binary found (checked \$SOPS_BIN, PATH, .sops-bin/sops, /tmp/sops) -- "
      . "rotating a multi-document stream can only be proven against one sops "
      . "itself wrote. Fix: run maint/fetch-sops .sops-bin to install the "
      . "pinned binary where the suite finds it automatically, or set "
      . "SOPS_BIN=/path/to/sops."
        unless $sops_bin;
    diag("Using sops binary: $sops_bin");

    my ($enc, $secret) = sops_encrypt($sops_bin, $TWO_DOCS, 'rotate.yaml');
    return unless defined $enc;

    my $dir  = tempdir(CLEANUP => 1);
    my $file = "$dir/rotate.enc.yaml";
    write_binary($file, $enc);

    my ($blob_before) = $enc =~ /(-----BEGIN AGE ENCRYPTED FILE-----.*?-----END AGE ENCRYPTED FILE-----)/s;
    ok(length $blob_before, 'sanity: found the original age blob to compare against');

    ok(File::SOPS->rotate(file => $file, identities => [$secret]),
        'rotate returns true on a multi-document stream');

    my $rotated = read_binary($file);
    my ($blob_after) = $rotated =~ /(-----BEGIN AGE ENCRYPTED FILE-----.*?-----END AGE ENCRYPTED FILE-----)/s;
    isnt($blob_after, $blob_before,
        'the age blob changed -- rotate really generated a new data key, not a no-op');

    my @macs = ($rotated =~ /^\s*mac: (\S+)$/mg);
    is(scalar @macs, 2, 'still one metadata block per document after rotation');
    is($macs[0], $macs[1], 'and both carry the identical (new) MAC (point 1)');

    # sops_encrypt()'s own SOPS_AGE_KEY_FILE is `local`-scoped to that call
    # and is gone by the time it returns; rotate() kept the same recipient
    # (no `recipients` argument was given), so the same $secret still opens
    # the file -- it just needs pointing at again for this shell-out.
    write_binary("$dir/key.txt", $secret);
    local $ENV{SOPS_AGE_KEY_FILE} = "$dir/key.txt";

    my $decrypted = `$sops_bin -d $file 2>&1`;
    is($? >> 8, 0, 'sops -d reads the rotated stream back') or diag($decrypted);
    like($decrypted, qr/alpha: one/, 'document 0 intact after rotation');
    like($decrypted, qr/beta: two/, 'document 1 intact after rotation');
};

###############################################################################
subtest 'edit refuses a multi-document stream, with its own k41 message' => sub {
    # Unlike rotate, edit's refusal is deliberate rather than mechanical:
    # docs/adr/0033 leaves edit-on-a-stream semantics open because edit
    # re-encrypts under a NEW data key (k41), and enabling it here would
    # settle that question by accident. Independent fixture from the rotate
    # subtest above.
    my $sops_bin = find_sops_bin();
    plan skip_all =>
        "No sops binary found (checked \$SOPS_BIN, PATH, .sops-bin/sops, /tmp/sops) -- "
      . "edit's multidoc refusal on an ORIGINAL stream can only be proven "
      . "against one sops itself wrote. Fix: run maint/fetch-sops .sops-bin "
      . "to install the pinned binary where the suite finds it "
      . "automatically, or set SOPS_BIN=/path/to/sops."
        unless $sops_bin;
    diag("Using sops binary: $sops_bin");

    my ($enc, $secret) = sops_encrypt($sops_bin, $TWO_DOCS, 'edit.yaml');
    return unless defined $enc;

    my $dir  = tempdir(CLEANUP => 1);
    my $file = "$dir/edit.enc.yaml";
    write_binary($file, $enc);

    my $ok = eval {
        File::SOPS->edit(
            file       => $file,
            identities => [$secret],
            editor     => 'true',   # never runs -- edit refuses before it would
        );
        1;
    };
    ok(!$ok, 'edit dies rather than opening a multi-document original for editing');
    like($@, qr/edit on a multi-document YAML stream \(2 documents\) is not supported/,
        'with the edit-specific k41 message, not the old write-pending one');
    like($@, qr/edit re-encrypts under a NEW data key \(unlike sops edit, k41\)/,
        'naming why: the new-data-key divergence, not an unimplemented mechanic');
    like($@, qr/docs\/adr\/0033 deliberately leaves edit-on-a-stream semantics open/,
        'and pointing at the ADR that left this open');
    is(read_binary($file), $enc, 'and the file on disk is untouched');

    # A SINGLE-document file the editor itself turns into a stream is refused
    # the same way -- discovered after the editor has run, but still before
    # anything is re-encrypted or written back.
    my ($public2, $secret2) = Crypt::Age->generate_keypair();
    my $single_file = "$dir/single.enc.yaml";
    write_binary($single_file, File::SOPS->encrypt(
        data => { alpha => 'one' }, recipients => [$public2], format => 'yaml'));
    my $single_before = read_binary($single_file);

    my $editor_script = "$dir/editor-multidoc.pl";
    write_binary($editor_script, <<'PERL');
use strict;
use warnings;
my $file = $ARGV[-1];
open my $out, '>', $file or die $!;
print $out "alpha: one\n---\nbeta: two\n";
close $out;
PERL

    $ok = eval {
        File::SOPS->edit(
            file       => $single_file,
            identities => [$secret2],
            editor     => [$^X, $editor_script],
        );
        1;
    };
    ok(!$ok, 'edit dies when the editor turns one document into a stream');
    like($@, qr/edit on a multi-document YAML stream \(2 documents\) is not supported/,
        'the SAME refusal, discovered after the editor ran rather than before');
    is(read_binary($single_file), $single_before,
        'the original single-document file is untouched -- the edit is discarded, not partially applied');
};

###############################################################################
subtest 'a multi-document stream can become YAML but not json/env/ini (docs/adr/0033 Decision 3)' => sub {
    # json/env/ini have no document stream. sops converts to them silently and
    # loses every document past the first, on read AND write (N1) -- exactly
    # the k14 defect class. This library refuses instead.
    # _serialize_plaintext is the one place a decrypted stream meets an output
    # format; there is currently no PUBLIC path that reaches it with more than
    # one document and a non-YAML target, because decrypt_file uses the SAME
    # format for reading and writing (a real multi-document input
    # auto-detects as YAML from its own filename), so this is exercised
    # directly.
    my $documents = [ { alpha => 'one' }, { beta => 'two' } ];

    for my $fmt (qw(json env ini)) {
        my $err = do { eval { File::SOPS::_serialize_plaintext($documents, $fmt) }; $@ };
        like($err, qr/cannot write a multi-document stream \(2 documents\) as \Q$fmt\E/,
            "$fmt: names the document count and the target format");
        like($err, qr/all but the first document would be lost/,
            "$fmt: says what would happen, not just that it refuses");
        like($err, qr/sops drops them silently here; this library refuses instead/,
            "$fmt: stating the deviation from sops, per the house rule");
    }

    # A single document is not a stream at all, and converts as always.
    my $json = File::SOPS::_serialize_plaintext({ alpha => 'one' }, 'json');
    like($json, qr/"alpha"/, 'a single document still converts to JSON');
    like($json, qr/"one"/, 'and carries its value');

    # YAML CAN hold a stream (point 5), and now actually does: k31 step 5
    # landed the emitter's own document separators, so this WRITES rather than
    # refusing.
    my $yaml = File::SOPS::_serialize_plaintext($documents, 'yaml');
    like($yaml, qr/^alpha: one$/m, 'document 0 written');
    like($yaml, qr/^beta: two$/m, 'document 1 written');
    is(scalar(() = $yaml =~ /^---\s*$/mg), 2,
        'two --- separators, one before each document');
};

###############################################################################
subtest 'metadata only in a later document is refused (docs/adr/0033 point 2)' => sub {
    # Measured against sops 3.13.3: a stream carrying sops only in the FIRST
    # document decrypts fine (see subtest 1 above). One carrying it only in a
    # LATER document is refused with "sops metadata not found". The ENC[...]
    # values below need not decrypt to anything real -- decrypt croaks before
    # the data key is even looked up, because $metadata comes from document 0
    # alone (File::SOPS::Format::YAML's _parse_multidoc).
    my $doc = <<'YAML';
alpha: ENC[AES256_GCM,data:GJx8,iv:UviTVNZsDhJiAqmdlzPo4w==,tag:AVtDgfBZYXqXxTfAdVR/dg==,type:str]
---
beta: ENC[AES256_GCM,data:+6I2,iv:CG1b+tUlZIexygqHqNDyKQ==,tag:AWnPwk+HEGGk0ejcgh9dcA==,type:str]
sops:
    lastmodified: "2026-08-08T23:38:52Z"
    mac: ENC[AES256_GCM,data:IUoe,iv:hvGgd6z/nbAmyUMtTkWf3Q==,tag:JK/b2t4PFxlus6NiQ4mB4A==,type:str]
    version: 3.13.3
YAML

    my (undef, $metadata, $documents) = File::SOPS::Format::YAML->parse($doc);
    is($metadata, undef, 'no metadata is recognised from a document that is not the first');
    is(scalar @$documents, 2, 'both documents still came back');
    is_deeply(
        [ sort keys %{ $documents->[1] } ],
        [ 'beta' ],
        'and the sops section is stripped from document 1 regardless, so the '
      . 'walks never see it as an ordinary key');

    eval {
        File::SOPS->decrypt(
            encrypted  => $doc,
            identities => ['AGE-SECRET-KEY-1QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQ'],
        );
    };
    like($@, qr/No SOPS metadata found/,
        q{decrypt refuses with the message that maps to sops's own "sops metadata not found"});
};

###############################################################################
subtest 'decrypt returns an ArrayRef for a real multi-document sops file, MAC verified' => sub {
    my $sops_bin = find_sops_bin();
    plan skip_all =>
        "No sops binary found (checked \$SOPS_BIN, PATH, .sops-bin/sops, /tmp/sops) -- "
      . "this proves decrypt's ArrayRef return against a stream sops itself "
      . "wrote, not just against this library's own parser. Fix: run "
      . "maint/fetch-sops .sops-bin to install the pinned binary where the "
      . "suite finds it automatically, or set SOPS_BIN=/path/to/sops."
        unless $sops_bin;
    diag("Using sops binary: $sops_bin");

    my ($enc, $secret) = sops_encrypt($sops_bin, $TWO_DOCS, 'two.yaml');
    return unless defined $enc;

    # What sops wrote really is multi-document, with one metadata block per
    # document and the same MAC in each (docs/adr/0033 point 1).
    my @macs = ($enc =~ /^    mac: (\S+)$/mg);
    is(scalar @macs, 2, 'sops wrote one metadata block per document');
    is($macs[0], $macs[1], 'both carry the same MAC (one digest, whole stream)');

    my $data = File::SOPS->decrypt(encrypted => $enc, identities => [$secret]);
    is(ref($data), 'ARRAY', 'a real multi-document stream decrypts to an ArrayRef')
        or diag(explain($data));
    is(scalar @$data, 2, 'both documents came back');
    is_deeply($data,
        [ { alpha => 'one', shared => 'first' },
          { beta  => 'two', shared => 'second' } ],
        'each document holds exactly what sops encrypted -- with the MAC '
      . 'verified, not ignore_mac');

    # What round-trips is the FILE, not the Perl container (Decision 1): a
    # genuinely single-document sops file still comes back as a bare HashRef.
    my ($enc1, $secret1) = sops_encrypt($sops_bin, "alpha: one\n", 'one.yaml');
    return unless defined $enc1;
    my $data1 = File::SOPS->decrypt(encrypted => $enc1, identities => [$secret1]);
    is(ref($data1), 'HASH', 'a real single-document sops file decrypts to a bare HashRef');
    is_deeply($data1, { alpha => 'one' }, 'holding what sops encrypted');
};

###############################################################################
subtest 'the MAC reparse pairs a multi-document stream by index' => sub {
    # _parse_in_document_order supplies the key ORDER for MAC verification
    # while the values come from the main parse. The two parsers disagree in
    # SCALAR context on a multi-document stream -- YAML::PP yields the FIRST
    # document, YAML::XS the LAST -- so a reparse that read either side in
    # scalar context would pair one document's order with another's values.
    # docs/adr/0033 closes this by reading BOTH sides in list context, so
    # document i's order now pairs with document i's values structurally.
    my $ordered = File::SOPS::_parse_in_document_order($TWO_DOCS);
    is(ref($ordered), 'ARRAY', 'reparse returns a document list for a stream');
    is_deeply($ordered,
        [ { alpha => 'one', shared => 'first' },
          { beta  => 'two', shared => 'second' } ],
        'each document keeps its own key/value pairs');

    my $single = File::SOPS::_parse_in_document_order("a: 1\nb: 2\n");
    is_deeply($single, { a => 1, b => 2 },
        'and still recovers a single document');

    # The sops branch is dropped structurally, as before.
    my $with_meta = File::SOPS::_parse_in_document_order(
        "a: 1\nsops:\n    version: 3.13.3\n");
    is_deeply($with_meta, { a => 1 }, 'sops branch still removed');
};

###############################################################################
# Interop: does the read path actually work against what sops produces, not
# just against this library's own writer? Deliberately real per-document
# values (not "a"/"b") so a wrong pairing (docs/adr/0033's trap) would show up
# as a wrong VALUE, not just a wrong count.
###############################################################################
subtest 'extract addresses one document at a time, and never falls through' => sub {
    my $sops_bin = find_sops_bin();
    plan skip_all =>
        "No sops binary found (checked \$SOPS_BIN, PATH, .sops-bin/sops, /tmp/sops) -- "
      . "extract's document argument is proven here against a real "
      . "multi-document file sops itself wrote, not just one this library "
      . "wrote. Fix: run maint/fetch-sops .sops-bin to install the pinned "
      . "binary where the suite finds it automatically, or set "
      . "SOPS_BIN=/path/to/sops."
        unless $sops_bin;
    diag("Using sops binary: $sops_bin");

    my ($enc, $secret) = sops_encrypt($sops_bin, $TWO_DOCS, 'two.yaml');
    return unless defined $enc;

    my $dir  = tempdir(CLEANUP => 1);
    my $file = "$dir/two.enc.yaml";
    write_binary($file, $enc);

    is(File::SOPS->extract(file => $file, path => '["alpha"]', identities => [$secret]),
        'one', 'document is 0 by default, reaching document 0');
    is(File::SOPS->extract(file => $file, path => '["alpha"]', document => 0, identities => [$secret]),
        'one', 'document => 0 explicitly is the same document');
    is(File::SOPS->extract(file => $file, path => '["beta"]', document => 1, identities => [$secret]),
        'two', 'document => 1 reaches the second document');
    is(File::SOPS->extract(file => $file, path => '["shared"]', document => 0, identities => [$secret]),
        'first', "document 0's own \"shared\" value");
    is(File::SOPS->extract(file => $file, path => '["shared"]', document => 1, identities => [$secret]),
        'second', "document 1's own value, not document 0's");

    my $err = do { eval {
        File::SOPS->extract(file => $file, path => '["alpha"]', document => 2, identities => [$secret]);
    }; $@ };
    like($err, qr/document => 2 is beyond the last document/,
        'document => 2 errors naming that it is out of range');
    like($err, qr/\b2 documents\b/, 'and names how many documents the file has');

    # beta exists in document 1, not document 0 -- extract must not fall
    # through looking for it there (docs/adr/0033 Decision 2).
    $err = do { eval {
        File::SOPS->extract(file => $file, path => '["beta"]', document => 0, identities => [$secret]);
    }; $@ };
    like($err, qr/component 'beta' not found/, 'beta really is not in document 0');
    like($err, qr/\bdocument 0\b/, 'and the error names WHICH document was searched');
    unlike($err, qr/document 1/, 'never document 1, even though beta is right there');
};

###############################################################################
subtest 'document => 1 on a single-document file is out of range' => sub {
    my ($public, $secret) = Crypt::Age->generate_keypair();
    my $dir  = tempdir(CLEANUP => 1);
    my $file = "$dir/one.enc.yaml";
    write_binary($file, File::SOPS->encrypt(
        data       => { alpha => 'one' },
        recipients => [$public],
    ));

    is(File::SOPS->extract(file => $file, path => '["alpha"]', identities => [$secret]),
        'one', 'document => 0 (the default) works as always');

    my $err = do { eval {
        File::SOPS->extract(file => $file, path => '["alpha"]', document => 1, identities => [$secret]);
    }; $@ };
    like($err, qr/document => 1 is beyond the last document/,
        'document => 1 is refused; there is no document 1');
    like($err, qr/\b1 document\b/,
        'the message says the file has one document, singular, not "1 documents"');
};

###############################################################################
# The remaining docs/adr/0033 findings that are measured facts about the
# FORMAT, not about this library's own choices -- pinned so a future change
# cannot quietly narrow or widen what the MAC actually covers.
###############################################################################

subtest 'N3: the MAC covers the concatenated leaf sequence, not where the document boundary falls' => sub {
    # ADR 0033, finding N3: a stream `a: 1, b: 2 / --- / c: 3` re-split by
    # moving the `b` ciphertext line into the second document -- giving
    # `a: 1 / --- / b: 2, c: 3` -- still verifies, exit 0. The digest is the
    # concatenated leaf sequence across all documents; only that ORDER is
    # authenticated, not which document each leaf sits in. This is a property
    # of the format (sops itself does this), not a bug either implementation
    # could fix, and it belongs in a pinned regression rather than only in the
    # POD.
    my $sops_bin = find_sops_bin();
    plan skip_all =>
        "No sops binary found (checked \$SOPS_BIN, PATH, .sops-bin/sops, /tmp/sops) -- "
      . "N3 is a measured fact about the real binary's MAC, not about this "
      . "library's own digest in isolation. Fix: run maint/fetch-sops "
      . ".sops-bin to install the pinned binary where the suite finds it "
      . "automatically, or set SOPS_BIN=/path/to/sops."
        unless $sops_bin;
    diag("Using sops binary: $sops_bin");

    my ($enc, $secret) = sops_encrypt($sops_bin, "a: 1\nb: 2\n---\nc: 3\n", 'three.yaml');
    return unless defined $enc;

    my ($b_line) = $enc =~ /^(b: ENC\[.*\])$/m;
    ok(length($b_line // ''), 'sanity: found b\'s own ENC[...] line to move') or return;

    # Move the `b` line out of document 0 and into document 1, in front of
    # `c` -- so the CONCATENATED leaf order (a, b, c) is unchanged, only
    # which document b's ciphertext physically sits in.
    (my $mutated = $enc) =~ s/^\Q$b_line\E\n//m;
    $mutated =~ s/^(c: ENC\[)/$b_line\n$1/m;
    isnt($mutated, $enc, 'sanity: the text really was rearranged');

    my $dir  = tempdir(CLEANUP => 1);
    my $file = "$dir/three.mutated.yaml";
    write_binary($file, $mutated);

    # sops_encrypt()'s own SOPS_AGE_KEY_FILE is `local`-scoped to that call
    # and is gone by the time it returns, so the identity for this shell-out
    # has to be set again here, against the same $secret it gave back.
    write_binary("$dir/key.txt", $secret);
    local $ENV{SOPS_AGE_KEY_FILE} = "$dir/key.txt";

    my $decrypted = `$sops_bin -d $file 2>&1`;
    is($? >> 8, 0, 'sops -d still verifies the rearranged stream -- the documented limitation') or diag($decrypted);
    like($decrypted, qr/^a: 1$/m, 'a is where it always was');
    like($decrypted, qr/^b: 2$/m, 'b decrypts correctly even though it moved documents');
    like($decrypted, qr/^c: 3$/m, 'c is unaffected');

    # This library's own MAC has the same property -- it is built to the same
    # spec (leaves in document order, no boundary marker), so it verifies the
    # identical rearrangement rather than only tolerating sops's own instance
    # of it.
    my $data = eval { File::SOPS->decrypt(encrypted => $mutated, identities => [$secret]) };
    ok(!$@, 'File::SOPS->decrypt also verifies the rearranged stream') or diag($@);
    is_deeply($data, [ { a => 1 }, { b => 2, c => 3 } ],
        'and reads back exactly where the leaves now physically sit');
};

subtest 'point 6: an empty document round-trips through both directions, middle and trailing' => sub {
    # "An empty document anywhere is a real document: it gets its own
    # metadata block and reads back as {}" -- already pinned as a PARSE fact
    # (see 'an empty document is a real document and reads back as {}' above).
    # This subtest is the round-trip: does WRITING one through this library
    # produce something sops reads back as {}, and does READING one sops
    # wrote come back as {} here too?
    my $sops_bin = find_sops_bin();
    plan skip_all =>
        "No sops binary found (checked \$SOPS_BIN, PATH, .sops-bin/sops, /tmp/sops) -- "
      . "an empty document's round-trip can only be proven against the real "
      . "binary in both directions. Fix: run maint/fetch-sops .sops-bin to "
      . "install the pinned binary where the suite finds it automatically, "
      . "or set SOPS_BIN=/path/to/sops."
        unless $sops_bin;
    diag("Using sops binary: $sops_bin");

    # Direction 1: this library writes a stream with an empty MIDDLE and an
    # empty TRAILING document; sops -d reads both back as {}.
    my ($public, $secret) = Crypt::Age->generate_keypair();
    my $dir = tempdir(CLEANUP => 1);
    write_binary("$dir/key.txt", $secret);
    local $ENV{SOPS_AGE_KEY_FILE} = "$dir/key.txt";

    my $enc = File::SOPS->encrypt(
        data       => [ { a => 1 }, {}, { b => 2 }, {} ],
        recipients => [$public],
        format     => 'yaml',
    );
    my $out = "$dir/empty.enc.yaml";
    write_binary($out, $enc);

    my $decrypted = `$sops_bin -d $out 2>&1`;
    is($? >> 8, 0, 'sops -d reads a stream we wrote with empty documents in it') or diag($decrypted);
    my @docs_out = split /^---\s*$/m, $decrypted;
    is(scalar @docs_out, 4, 'all four documents came back, including the two empty ones');
    like($decrypted, qr/^a: 1$/m, 'document 0 intact');
    like($decrypted, qr/^\{\}$/m, 'and at least one empty document reads back as {}, not dropped');
    like($decrypted, qr/^b: 2$/m, 'document 2 intact');

    # Direction 2: sops writes a stream with an empty middle and empty
    # trailing document; this library's decrypt reads them back as {}.
    my ($enc2, $secret2) = sops_encrypt($sops_bin, "a: 1\n---\n---\nb: 2\n---\n", 'empty.yaml');
    return unless defined $enc2;

    my $data = File::SOPS->decrypt(encrypted => $enc2, identities => [$secret2]);
    is_deeply($data, [ { a => 1 }, {}, { b => 2 }, {} ],
        'a stream sops wrote with empty documents reads back the same shape here');
};

subtest 'N5/Decision 5: a cross-document anchor is a stream sops reads that this library refuses loudly' => sub {
    # ADR 0033, finding N5: go-yaml carries the anchor table ACROSS `---`;
    # anchors are document-scoped in both YAML::XS and YAML::PP. sops reads
    # `a: &x 1\n---\nb: *x\n` and resolves the alias in document 2 against
    # document 1's anchor. Decision 5 is that there is no fix at this layer --
    # the parser's own error must surface, loudly, rather than this library
    # silently mis-reading or truncating the stream. k132, parked
    # alongside k31.
    my $sops_bin = find_sops_bin();
    plan skip_all =>
        "No sops binary found (checked \$SOPS_BIN, PATH, .sops-bin/sops, /tmp/sops) -- "
      . "N5 is only a real divergence if sops really does accept the input "
      . "this library refuses; without the binary there is nothing to "
      . "diverge from. Fix: run maint/fetch-sops .sops-bin to install the "
      . "pinned binary where the suite finds it automatically, or set "
      . "SOPS_BIN=/path/to/sops."
        unless $sops_bin;
    diag("Using sops binary: $sops_bin");

    my $anchor_doc = "a: &x 1\n---\nb: *x\n";

    # First, confirm sops really does accept and resolve it -- this is what
    # makes the refusal below a DIVERGENCE and not just a made-up limitation.
    my ($enc, $secret) = sops_encrypt($sops_bin, $anchor_doc, 'anchor.yaml');
    return unless defined $enc;

    my $dir  = tempdir(CLEANUP => 1);
    my $file = "$dir/anchor.enc.yaml";
    write_binary($file, $enc);

    # sops_encrypt()'s own SOPS_AGE_KEY_FILE is `local`-scoped to that call
    # and is gone by the time it returns, so the identity for this shell-out
    # has to be set again here, against the same $secret it gave back.
    write_binary("$dir/key.txt", $secret);
    local $ENV{SOPS_AGE_KEY_FILE} = "$dir/key.txt";

    my $decrypted = `$sops_bin -d $file 2>&1`;
    is($? >> 8, 0, 'sops -d reads the stream it wrote from the anchor input') or diag($decrypted);
    like($decrypted, qr/^a: 1$/m, 'a is 1, as written');
    like($decrypted, qr/^b: 1$/m, 'and b resolved the alias across the document boundary, to the SAME 1');

    # Now the divergence itself: THIS library refuses the plain-text input
    # loudly, at the parser, rather than silently mis-reading it (there is no
    # anchor left to find once sops has already resolved and encrypted the
    # value, so this is exercised on the raw text, which is exactly where a
    # caller's encrypt_file would meet it too).
    my $err = do { eval { File::SOPS::Format::YAML->parse($anchor_doc) }; $@ };
    ok(length $err, 'File::SOPS::Format::YAML->parse dies on the same input') or return;
    like($err, qr/anchor/i,
        'loudly -- the parser\'s own anchor/alias error surfaces, not a silent wrong answer');

    # And through the public API: decrypt hits the same parse step before it
    # ever looks for a data key, so a caller handing this text to decrypt (as
    # they would any file that came from sops) gets the same loud refusal.
    my $err2 = do { eval {
        File::SOPS->decrypt(encrypted => $anchor_doc, identities => [$secret]);
    }; $@ };
    ok(length $err2, 'File::SOPS->decrypt dies too, before ever reaching metadata or a data key');
    like($err2, qr/anchor/i, 'with the same loud parser error, not a MAC or metadata message');
};

done_testing;
