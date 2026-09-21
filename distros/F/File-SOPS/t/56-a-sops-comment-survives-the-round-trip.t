#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(read_binary write_binary);

use File::SOPS;
use File::SOPS::Encrypted;
use File::SOPS::Metadata;
use File::SOPS::Backend::Age;
use File::SOPS::Format::YAML;
use Crypt::Age;
use lib 't/lib';
use SopsBin qw(find_sops_bin);

# ----------------------------------------------------------------------------
# k76 / docs/adr/0041: a sops comment is a leaf of its own -- not a value,
# and not a refusal.
#
# sops attaches a comment to the node that FOLLOWS it. Above a mapping key that
# stays a `#ENC[...,type:comment]` line, which YAML::XS discards. Above a
# SEQUENCE entry there is no comment line to write, so sops writes the comment
# as a sequence entry of its own -- in YAML, and (measured) in JSON written with
# `--output-type json` as well:
#
#     list:
#         - ENC[AES256_GCM,...,type:comment]
#         - ENC[AES256_GCM,...,type:str]
#
# k108 read that entry as a VALUE: an extra string in the caller's list
# that the file does not contain, made permanent by a decrypt+encrypt cycle with
# `sops -d` reporting success at every step. docs/adr/0024 closed it by refusing
# the document. This file pins the answer that replaces the refusal: the entry
# becomes a File::SOPS::Comment, stays at its index, stays OUT of the digest,
# and is written back as a type:comment entry.
#
# WHAT THE BINARY IS FOR HERE. Everything below section 2 is a Perl->Perl round
# trip, which proves this library agrees with itself -- the exact failure mode
# that ships broken files. The claim that matters is the one only sops can
# answer, and it is asked in both directions:
#
#   sops -e -> File::SOPS reads -> File::SOPS writes -> sops -d
#   File::SOPS writes from scratch                   -> sops -d
#
# THE DIGEST IS THE LOAD-BEARING PART. Comments are in NO format's MAC --
# measured against sops 3.13.3 four ways at k108, and once more here: the
# digest this library computes over a sops-written document with comments in it
# matches the one that document stores, which it can only do if the comments are
# left out. If that exclusion is ever lost, section 3 fails on the MAC and every
# sops document with a comment in it stops reading.
#
# Sections 1 and 2 need no binary. Sections 3 to 6 are the compatibility claim
# and are skipped without one.
# ----------------------------------------------------------------------------

my $sops_bin = find_sops_bin();
diag("Using sops binary: $sops_bin") if $sops_bin;

my $tempdir = tempdir(CLEANUP => 1);
my ($public, $secret) = Crypt::Age->generate_keypair();
write_binary("$tempdir/key.txt", $secret);
$ENV{SOPS_AGE_KEY_FILE} = "$tempdir/key.txt";

# The MAC's own plaintext: the SHA-512 hex string sops stores, decrypted. Two
# documents whose digests agree hold the same value here, whatever their
# ciphertexts look like -- the IV is random, so the ENC[...] strings never
# match even for identical digests.
sub mac_plaintext {
    my ($document) = @_;
    my (undef, $metadata) = File::SOPS::Format::YAML->parse($document);
    my $key = File::SOPS::Backend::Age->decrypt_data_key(
        age_keys => $metadata->age, identities => [$secret]);
    return File::SOPS::Encrypted->parse($metadata->mac)->decrypt_bytes(
        key => $key, aad => $metadata->lastmodified // '');
}

###############################################################################
# 1. THE LEAF. A comment has a Perl value of its own, and the one type ladder
#    and the one conversion answer for it.
###############################################################################

subtest 'the comment leaf is a value of its own kind' => sub {
    my $c = File::SOPS::Comment->new(text => ' a comment');

    isa_ok($c, 'File::SOPS::Comment', 'the constructor');
    is($c->text, ' a comment', 'keeps the text verbatim, leading space and all');

    is(File::SOPS::Encrypted->detect_type($c), 'comment',
        'the ONE type ladder types it');
    is(File::SOPS::Encrypted->value_to_bytes($c), ' a comment',
        'and the ONE conversion writes its text');
    ok(File::SOPS::Encrypted->is_comment($c), 'is_comment says so');

    # NOT overloaded, deliberately: an object that compares equal to a string
    # slips through every `eq` in this distribution, which is how a comment
    # became a value in the first place (k108).
    isnt("$c", ' a comment', 'it does not stringify to its text');
    ok(!File::SOPS::Encrypted->is_comment(' a comment'),
        'and a plain string is not a comment');

    # The wire half is a different question with a different answer, asked of
    # the label and never of a position or a text.
    my $enc = File::SOPS::Encrypted->encrypt_value(
        value => $c, key => "\0" x 32, aad => 'list:');
    is($enc->type, 'comment', 'encrypt_value labels it type:comment');
    ok(!File::SOPS::Encrypted->is_comment($enc->to_string),
        'is_comment is about the Perl value, not the ENC[...] string');
    is(File::SOPS::Encrypted->encrypted_type($enc->to_string), 'comment',
        'which is what encrypted_type is for');

    my $back = $enc->decrypt_value(key => "\0" x 32, aad => 'list:');
    isa_ok($back, 'File::SOPS::Comment', 'and it decrypts back into');
    is($back->text, ' a comment', 'the same text');

    # The text is text, so it is UTF-8 encoded UNCONDITIONALLY on the way to
    # the cipher and decoded on the way back -- docs/adr/0003, the same rule
    # every string leaf follows, and Perl's UTF-8 flag is not consulted for it
    # either.
    my $u = File::SOPS::Comment->new(text => " caf\x{e9} \x{263a}");
    is(File::SOPS::Encrypted->value_to_bytes($u), " caf\xc3\xa9 \xe2\x98\xba",
        'a non-ASCII comment goes to the wire as UTF-8 bytes');
    my $uenc = File::SOPS::Encrypted->encrypt_value(
        value => $u, key => "\0" x 32, aad => 'list:');
    is($uenc->decrypt_value(key => "\0" x 32, aad => 'list:')->text,
        " caf\x{e9} \x{263a}", 'and comes back as the characters it was');
};

subtest 'a comment with no text is refused, because sops writes none' => sub {
    # Measured against sops 3.13.3: a bare `#` above a sequence entry is written
    # as an UNENCRYPTED empty string element (`- ""`) and no comment leaf at
    # all, and read back as `- ""`. So type:comment never carries an empty
    # plaintext, and AES-GCM has no ciphertext for one either.
    ok(!defined(eval { File::SOPS::Comment->new(text => '') }),
        'an empty comment');
    like($@, qr/cannot be empty/, 'says why');
    ok(!defined(eval { File::SOPS::Comment->new() }), 'no text at all');
    ok(!defined(eval { File::SOPS::Comment->new(text => []) }), 'a reference');
};

###############################################################################
# 2. THE DIGEST. A comment is not a leaf value, so it is not in the MAC. This
#    section proves it without a binary, by construction; section 3 proves it
#    against the digest sops itself computed.
###############################################################################

subtest 'a comment changes no digest' => sub {
    my $with = File::SOPS->encrypt(
        data => { list => [ File::SOPS::Comment->new(text => ' a comment'),
                            'one' ], k => 'v' },
        recipients => [$public], format => 'yaml');
    my $without = File::SOPS->encrypt(
        data => { list => ['one'], k => 'v' },
        recipients => [$public], format => 'yaml');

    like($with, qr/,type:comment\]/, 'the first document has a comment leaf');
    unlike($without, qr/,type:comment\]/, 'the second has none');

    is(mac_plaintext($with), mac_plaintext($without),
        'and the two documents digest to the SAME value');

    # Different comment, same digest -- the exclusion is not "the first comment
    # is skipped" but "no comment is a leaf value".
    my $other = File::SOPS->encrypt(
        data => { list => [ File::SOPS::Comment->new(text => ' something else'),
                            'one' ], k => 'v' },
        recipients => [$public], format => 'yaml');
    is(mac_plaintext($other), mac_plaintext($without),
        'whatever the comment says');
};

subtest 'the exclusion holds under mac_only_encrypted too' => sub {
    # Measured against sops 3.13.3: `sops -e --mac-only-encrypted` still
    # ENCRYPTS the comment and still leaves it out of the digest, so the
    # exclusion is by TYPE and not by which leaves the MAC covers.
    my $with = File::SOPS->encrypt(
        data => { list => [ File::SOPS::Comment->new(text => ' a comment'),
                            'one' ] },
        recipients => [$public], format => 'yaml', mac_only_encrypted => 1);
    my $without = File::SOPS->encrypt(
        data => { list => ['one'] },
        recipients => [$public], format => 'yaml', mac_only_encrypted => 1);

    is(mac_plaintext($with), mac_plaintext($without),
        'same digest with the comment and without it');
};

###############################################################################
# 3. THE ROUND TRIP, sops -> here -> sops. The compatibility claim, and the
#    only thing in this file a Perl-only run cannot make.
###############################################################################

SKIP: {
    skip "no sops binary (\$SOPS_BIN, PATH, .sops-bin/sops, /tmp/sops) -- the compatibility "
       . "claim this file makes was NOT verified", 4
        unless $sops_bin;

    my $PLAIN = <<'YAML';
list:
  # comment above the first entry
  - one
  - two
tail:
  - alpha
  # comment after the last entry
mixed:
  - beta  # trailing on a value's line
  - gamma
flow: [1, 2]  # after a flow sequence
map:
  # above a mapping key
  k: v
YAML

    subtest 'a sops document with comments is read, MAC and all' => sub {
        write_binary("$tempdir/all.plain.yaml", $PLAIN);
        my $enc = `$sops_bin -e --age $public --input-type yaml --output-type yaml $tempdir/all.plain.yaml 2>&1`;
        is($? >> 8, 0, 'sops -e writes the document') or diag($enc);
        write_binary("$tempdir/all.enc.yaml", $enc);

        is(scalar(() = $enc =~ /^\s*- ENC\[AES256_GCM,[^\]]*,type:comment\]$/mg),
            4, 'four of the five comments became sequence ELEMENTS');
        like($enc, qr/^\s*#ENC\[AES256_GCM,[^\]]*,type:comment\]$/m,
            'and the mapping-position one stayed a comment LINE');

        # THE MAC. This verifies only because the comment leaves are left out
        # of the digest -- it is sops's own digest, computed by sops, over the
        # values and nothing else.
        my $got = eval { File::SOPS->decrypt(
            encrypted => $enc, identities => [$secret]) };
        ok(defined $got, 'File::SOPS reads it with the MAC verified')
            or diag($@);

        isa_ok($got->{list}[0], 'File::SOPS::Comment', 'list element 0');
        is($got->{list}[0]->text, ' comment above the first entry', 'its text');
        is_deeply([ @{$got->{list}}[1, 2] ], ['one', 'two'], 'then the values');

        isa_ok($got->{tail}[1], 'File::SOPS::Comment',
            'a comment attached to nothing is the LAST element');
        isa_ok($got->{mixed}[0], 'File::SOPS::Comment',
            'a trailing comment moved in front of the value it followed');
        isa_ok($got->{flow}[0], 'File::SOPS::Comment',
            'and a flow sequence became a block sequence led by the comment');
        is_deeply([ @{$got->{flow}}[1, 2] ], [1, 2],
            'with its integers still integers');

        is_deeply($got->{map}, { k => 'v' },
            'the mapping-position comment is simply absent, as it always was');
    };

    subtest 'and written back, sops reads what sops wrote' => sub {
        my $tree = File::SOPS->decrypt(
            encrypted => read_binary("$tempdir/all.enc.yaml"),
            identities => [$secret]);

        write_binary("$tempdir/all.rt.yaml", File::SOPS->encrypt(
            data => $tree, recipients => [$public], format => 'yaml'));

        my $ours = `$sops_bin -d --input-type yaml --output-type yaml $tempdir/all.rt.yaml 2>&1`;
        is($? >> 8, 0, 'sops -d reads our re-encryption') or diag($ours);

        # sops's OWN round trip of the same file, as the reference. It
        # normalises: the indentation changes, a trailing comment moves onto a
        # line of its own above the node it was attached to, and a flow sequence
        # becomes a block sequence. So the comparison is against what sops
        # itself produces, not against the source file.
        my $theirs = `$sops_bin -d --input-type yaml --output-type yaml $tempdir/all.enc.yaml 2>&1`;
        is($? >> 8, 0, 'and reads its own') or diag($theirs);

        # Key order is ours (the emitters sort; t/05 pins that), so the
        # comparison is line-wise and order-free.
        my @ours   = sort grep { /\S/ } split /\n/, $ours;
        my @theirs = sort grep { /\S/ } split /\n/, $theirs;

        # The mapping-position comment is the one thing that does not survive:
        # YAML::XS discards it on the way in and cannot write one on the way
        # out. That is the open half of k76, and it is asserted rather
        # than glossed over.
        @theirs = grep { !/# above a mapping key/ } @theirs;

        is_deeply(\@ours, \@theirs,
            'every sequence comment is back on the node it belonged to');

        for my $text (' comment above the first entry',
                      ' comment after the last entry',
                      ' trailing on a value\'s line',
                      ' after a flow sequence') {
            like($ours, qr/#\Q$text\E/, "sops restored '$text' as a comment");
        }
    };

    subtest 'a comment written here from scratch is read by sops' => sub {
        my $doc = File::SOPS->encrypt(
            data => { list => [
                File::SOPS::Comment->new(text => ' written by File::SOPS'),
                'one',
            ], plain => 'x' },
            recipients => [$public], format => 'yaml');
        write_binary("$tempdir/fresh.enc.yaml", $doc);

        my $out = `$sops_bin -d --input-type yaml --output-type yaml $tempdir/fresh.enc.yaml 2>&1`;
        is($? >> 8, 0, 'sops -d reads it -- MAC included') or diag($out);
        like($out, qr/# written by File::SOPS/,
            'and puts the comment back as a comment');
        like($out, qr/- one/, 'above the entry it belongs to');

        # rotate re-keys every leaf, the comment among them, and the document
        # stays one sops reads.
        ok(File::SOPS->rotate(file => "$tempdir/fresh.enc.yaml",
            identities => [$secret]), 'rotate re-keys the document');
        isnt(read_binary("$tempdir/fresh.enc.yaml"), $doc, 'writing a new one');

        my $after = `$sops_bin -d --input-type yaml --output-type yaml $tempdir/fresh.enc.yaml 2>&1`;
        is($? >> 8, 0, 'which sops still reads') or diag($after);
        like($after, qr/# written by File::SOPS/, 'comment and all');

        # The encoding half, against the binary: a non-ASCII comment reaches
        # sops as UTF-8 and comes back out of it unchanged (docs/adr/0003).
        write_binary("$tempdir/u.enc.yaml", File::SOPS->encrypt(
            data => { list => [
                File::SOPS::Comment->new(text => " caf\x{e9} \x{263a}"), 'one',
            ] },
            recipients => [$public], format => 'yaml'));
        my $unicode = `$sops_bin -d --input-type yaml --output-type yaml $tempdir/u.enc.yaml 2>&1`;
        is($? >> 8, 0, 'sops reads a non-ASCII comment') or diag($unicode);
        # The BYTES, compared with index rather than a pattern: \Q...\E would
        # quote the \x escapes themselves instead of the characters they name.
        my $utf8 = "# caf\xc3\xa9 \xe2\x98\xba";
        ok(index($unicode, $utf8) >= 0,
            'and writes it back as the same UTF-8 bytes')
            or diag(unpack 'H*', $unicode);
    };

    subtest 'the same leaf in a JSON document' => sub {
        # sops writes type:comment leaves into JSON too -- a YAML source with a
        # comment in a list, written with --output-type json. That document was
        # never covered by ADR 0024's guard, so k108's defect was open in
        # JSON the whole time: measured at that HEAD, ignore_mac => 1 returned
        # { list => [' a comment', 'one'] }.
        write_binary("$tempdir/j.plain.yaml", "list:\n  # a json comment\n  - one\n");
        my $enc = `$sops_bin -e --age $public --input-type yaml --output-type json $tempdir/j.plain.yaml 2>&1`;
        is($? >> 8, 0, 'sops -e writes JSON') or diag($enc);
        like($enc, qr/,type:comment\]/, 'with a comment leaf in it');
        write_binary("$tempdir/j.enc.json", $enc);

        my $got = eval { File::SOPS->decrypt(
            encrypted => $enc, identities => [$secret], format => 'json') };
        ok(defined $got, 'File::SOPS reads it with the MAC verified')
            or diag($@);
        isa_ok($got->{list}[0], 'File::SOPS::Comment', 'element 0');
        is($got->{list}[0]->text, ' a json comment', 'is the comment');
        is($got->{list}[1], 'one', 'and the value is the value');

        write_binary("$tempdir/j.rt.json", File::SOPS->encrypt(
            data => $got, recipients => [$public], format => 'json'));
        my $out = `$sops_bin -d --input-type json --output-type json $tempdir/j.rt.json 2>&1`;
        is($? >> 8, 0, 'sops reads our re-encryption') or diag($out);
        like(read_binary("$tempdir/j.rt.json"), qr/,type:comment\]/,
            'which still carries the comment leaf');
        # JSON has no comment syntax, so sops drops it on OUTPUT -- exactly as
        # it does for its own file. The leaf survives in the document; only the
        # rendering loses it.
        unlike($out, qr/a json comment/, 'though JSON output cannot show it');
    };
}

done_testing();
