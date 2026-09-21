#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(read_binary write_binary);

use File::SOPS;
use File::SOPS::Encrypted;
use File::SOPS::Format::YAML;
use Crypt::Age;
use lib 't/lib';
use SopsBin qw(find_sops_bin);

# ----------------------------------------------------------------------------
# k108 / docs/adr/0024, FLIPPED by k76 / docs/adr/0041.
#
# sops attaches a YAML comment to the node that FOLLOWS it. Above a mapping key
# that stays a `#ENC[...,type:comment]` line, which YAML::XS discards and sops
# does not hash -- both sides agree by accident, and such a document has always
# read correctly here. Above a SEQUENCE entry there is no comment line to write,
# so sops emits the comment as a real element:
#
#     list:
#         - ENC[AES256_GCM,...,type:comment]
#         - ENC[AES256_GCM,...,type:str]
#
# k108 measured what that did (sops 3.13.3, three lines of plaintext):
#
#   sops -d                                exit 0
#   File::SOPS->decrypt                    MAC verification failed
#   File::SOPS->decrypt(ignore_mac => 1)   { list => [' only a sequence comment',
#                                                     'one'] }
#
# The last line is the defect: the comment is a silent extra string, and a
# decrypt+encrypt cycle made it PERMANENT with `sops -d` exit 0 at every step.
# ADR 0024 closed it by REFUSING the document at parse, deliberately as an
# intermediate step. ADR 0041 replaces that refusal with the thing it was an
# intermediate step towards: the leaf is PRESERVED. It decrypts to a
# File::SOPS::Comment, stays at its index, stays OUT of the digest (which is
# what sops does with it, measured four ways) and is written back as a
# type:comment element.
#
# THIS FILE THEREFORE PINS TWO THINGS AT ONCE, and the sections say which:
#
#   * what is KEPT -- a comment leaf in a sequence is read, placed and written
#     back, where ADR 0024 refused the whole document for it. The full round
#     trip against the binary is t/56; here it is the tree, the digest and the
#     message.
#   * the refusals that REMAIN, which are the whole of what is left of ADR 0024:
#     a comment as a MAPPING VALUE (a shape no SOPS store writes -- sops reads
#     it back as a dump of Go's comment struct), and a comment this emitter is
#     asked to write as PLAIN TEXT (decrypt_file, edit).
#
# Sections 1 to 5 need no binary: the guards are structural and fire before
# anything is decrypted, so a comment leaf can be constructed here. Section 6 is
# the compatibility claim -- that sops really writes this shape -- and is
# skipped without a binary.
# ----------------------------------------------------------------------------

my $sops_bin = find_sops_bin();
diag("Using sops binary: $sops_bin") if $sops_bin;

my ($public, $secret) = Crypt::Age->generate_keypair();
my $tempdir = tempdir(CLEANUP => 1);
write_binary("$tempdir/key.txt", $secret);
$ENV{SOPS_AGE_KEY_FILE} = "$tempdir/key.txt";

# A well-formed ENC[...] string carrying an arbitrary type label. Built through
# encrypt_value rather than typed out, so the base64 is real and the only thing
# synthetic about it is the label -- which is exactly what sops varies.
sub enc_string {
    my ($type, $plaintext) = @_;
    my $enc = File::SOPS::Encrypted->encrypt_value(
        value => $plaintext,
        key   => "\0" x 32,
        aad   => '',
    );
    (my $s = $enc->to_string) =~ s/,type:\w+\]\z/,type:$type]/;
    return $s;
}

my $COMMENT_LEAF = enc_string('comment', ' only a sequence comment');
my $STR_LEAF     = enc_string('str',     'one');

###############################################################################
# 1. WHAT IS KEPT. A comment leaf in a SEQUENCE is a leaf the document really
#    has, so parse hands it on and the tree keeps it. Every assertion in this
#    section was a refusal under docs/adr/0024.
###############################################################################

subtest 'a comment leaf in a sequence is handed on by parse' => sub {
    my $doc = "list:\n    - $COMMENT_LEAF\n    - $STR_LEAF\n";

    # Under ADR 0024 parse croaked here: `list:0: ... type:comment`.
    my ($data) = File::SOPS::Format::YAML->parse($doc);
    is_deeply($data, { list => [ $COMMENT_LEAF, $STR_LEAF ] },
        'the element is in the tree, at its index, untouched');

    ok(File::SOPS::Encrypted->is_encrypted($data->{list}[0]),
        'and it is still just the ENC[...] string the file holds');
    is(File::SOPS::Encrypted->encrypted_type($data->{list}[0]), 'comment',
        'which says what it is without decoding anything');
};

subtest 'a comment leaf is kept at every depth a sequence reaches' => sub {
    # Every position here was a refusal at parse under ADR 0024. The two
    # SEQUENCE ones are read; the MAPPING VALUE one is refused, one layer
    # further in -- see section 4.
    my %doc = (
        'a:b:1' => "a:\n    b:\n        - $STR_LEAF\n        - $COMMENT_LEAF\n",
        'deep'  => "outer:\n    - inner:\n        - $COMMENT_LEAF\n",
    );

    my ($a) = File::SOPS::Format::YAML->parse($doc{'a:b:1'});
    is_deeply($a, { a => { b => [ $STR_LEAF, $COMMENT_LEAF ] } },
        'nested list, comment last');

    my ($d) = File::SOPS::Format::YAML->parse($doc{deep});
    is_deeply($d, { outer => [ { inner => [ $COMMENT_LEAF ] } ] },
        'a list under a key under a list');
};

subtest 'a damaged comment leaf is recognised without being decoded' => sub {
    # sops tolerates a comment whose ciphertext will not decrypt -- measured, it
    # warns and leaves the text alone. The label alone therefore has to be
    # enough to keep such a leaf out of the digest, which is what
    # encrypted_type is for. Decrypting it is a different matter: that croaks,
    # naming the path, which is one place this distribution is stricter than
    # the reference.
    my $damaged = 'ENC[AES256_GCM,data:!!!!,iv:!!!!,tag:!!!!,type:comment]';

    eval { File::SOPS::Encrypted->parse($damaged) };
    like($@, qr/Invalid base64/, 'parse of the value itself still croaks');

    is(File::SOPS::Encrypted->encrypted_type($damaged), 'comment',
        'but the label is readable, so the digest can skip it');

    # Under ADR 0024 the document was refused at parse.
    my ($data) = File::SOPS::Format::YAML->parse("list:\n    - $damaged\n");
    is_deeply($data, { list => [$damaged] }, 'and the document parses');
};

###############################################################################
# 2. WHAT MUST NOT MOVE. The mapping position has always read correctly, and
#    the guard must not reach it -- there the comment is a real YAML comment
#    line that YAML::XS discards before parse ever gets a tree.
###############################################################################

subtest 'mapping-position comment lines still parse away silently' => sub {
    my $doc = "#$COMMENT_LEAF\n"
            . "database:\n"
            . "    #$COMMENT_LEAF\n"
            . "    host: $STR_LEAF\n";

    my ($data) = File::SOPS::Format::YAML->parse($doc);
    is_deeply($data, { database => { host => $STR_LEAF } },
        'the tree is the values, with no trace of the comments');
};

subtest 'documents without a comment leaf are untouched' => sub {
    my ($data) = File::SOPS::Format::YAML->parse(
        "a: $STR_LEAF\nb:\n    - 1\n    - 2\nc: plain\n");
    is_deeply($data, { a => $STR_LEAF, b => [1, 2], c => 'plain' },
        'an ordinary encrypted document parses as it always did');

    # Plaintext input has no ENC[...] strings in it, so nothing on the encrypt
    # side can trip the guard -- including a plaintext file full of comments.
    my ($plain) = File::SOPS::Format::YAML->parse(
        "# a comment\nlist:\n  # and one in a list\n  - one\n");
    is_deeply($plain, { list => ['one'] }, 'and plaintext with comments parses');

    my $out = File::SOPS->encrypt(
        data => { list => ['one'] }, recipients => [$public], format => 'yaml');
    like($out, qr/type:str/, 'encrypt is unaffected');
};

###############################################################################
# 3. THE LABEL READER. encrypted_type is the third sharer of the one anchored
#    ENC regex, and it answers without decoding -- which is what lets the guard
#    above see a damaged comment.
###############################################################################

subtest 'encrypted_type reads the label and nothing else' => sub {
    is(File::SOPS::Encrypted->encrypted_type($COMMENT_LEAF), 'comment',
        'comment');
    is(File::SOPS::Encrypted->encrypted_type($STR_LEAF), 'str', 'str');
    is(File::SOPS::Encrypted->encrypted_type(enc_string('int', '5')), 'int',
        'int');
    is(File::SOPS::Encrypted->encrypted_type(
        'ENC[AES256_GCM,data:!!!!,iv:!!!!,tag:!!!!,type:comment]'), 'comment',
        'and answers for a value parse() would refuse to decode');

    is(File::SOPS::Encrypted->encrypted_type('not encrypted'), undef,
        'undef for a plain string');
    is(File::SOPS::Encrypted->encrypted_type(undef), undef, 'undef for undef');
    is(File::SOPS::Encrypted->encrypted_type("x\n$STR_LEAF"), undef,
        'undef for an unanchored match -- the same regex is_encrypted uses');
};

###############################################################################
# 4. THE PUBLIC API. Every read path goes through _decrypt_tree, so every read
#    path keeps the comment -- and the two shapes that still cannot be written
#    are refused there and at the emitter, naming the path.
###############################################################################

# The document this section reads is written by File::SOPS itself, from a
# File::SOPS::Comment, which is the shape ADR 0041 says it writes: the comment
# encrypted as type:comment at its index, and NOT in the digest. Subtest 9 asks
# the binary whether that is really sops's shape; this one asks whether the
# library reads back what it wrote, which is the half a binary cannot answer for
# a document the binary did not write.
sub document_with_comment_leaf {
    return File::SOPS->encrypt(
        data       => { list => [
            File::SOPS::Comment->new(text => ' only a sequence comment'),
            'one',
        ] },
        recipients => [$public],
        format     => 'yaml',
    );
}

# The same document with the comment RELABELLED from a type:str value, so its
# stored digest covers the comment's plaintext -- which sops's never does. It
# exists to prove the exclusion from the other side: if the digest here still
# covered comments, this document would verify.
sub document_whose_mac_covers_the_comment {
    my $doc = File::SOPS->encrypt(
        data       => { list => [' only a sequence comment', 'one'] },
        recipients => [$public],
        format     => 'yaml',
    );
    # The first `- ENC[` line in the file: `list` sorts before `sops`, and the
    # age entries are `- enc: |`, not ENC values.
    $doc =~ s/^(\s*- ENC\[[^\]]*),type:str\]/$1,type:comment]/m
        or die "test fixture: no encrypted list element found to relabel";
    return $doc;
}

subtest 'decrypt keeps the comment, in both MAC modes' => sub {
    my $doc = document_with_comment_leaf();

    like($doc, qr/^\s*- ENC\[AES256_GCM,.*,type:comment\]$/m,
        'encrypt wrote the comment as a sequence element');

    # Under ADR 0024 both of these croaked `list:0: ... type:comment`; before
    # that they returned { list => [' only a sequence comment', 'one'] },
    # the comment as a silent extra STRING, which is the defect neither answer
    # had to be.
    for my $mode (['strict', ()], ['ignore_mac', (ignore_mac => 1)]) {
        my ($name, %extra) = @$mode;
        my $got = eval { File::SOPS->decrypt(
            encrypted => $doc, identities => [$secret], format => 'yaml',
            %extra) };
        ok(defined $got, "$name decrypt reads the document") or diag($@);
        isa_ok($got->{list}[0], 'File::SOPS::Comment',
            "$name: element 0 is a comment leaf");
        is($got->{list}[0]->text, ' only a sequence comment',
            "$name: carrying its text");
        is($got->{list}[1], 'one', "$name: and the value is where it was");
    }

    # And the tree goes back where it came from: the round trip is closed here,
    # which is what makes the comment survive rotate and edit-free write-backs.
    my $again = File::SOPS->encrypt(
        data => File::SOPS->decrypt(
            encrypted => $doc, identities => [$secret], format => 'yaml'),
        recipients => [$public], format => 'yaml');
    my $back = File::SOPS->decrypt(
        encrypted => $again, identities => [$secret], format => 'yaml');
    isa_ok($back->{list}[0], 'File::SOPS::Comment',
        'a decrypt/encrypt cycle leaves it a comment');
    is($back->{list}[0]->text, ' only a sequence comment', 'text and all');
};

subtest 'the digest does not cover a comment' => sub {
    # The relabelled document's stored MAC covers the comment's plaintext. Ours
    # does not -- because sops's does not -- so verification must FAIL here. If
    # this ever passes, the exclusion has been lost and every sops-written
    # document with a comment in it stops verifying.
    my $doc = document_whose_mac_covers_the_comment();

    my $strict = eval { File::SOPS->decrypt(
        encrypted => $doc, identities => [$secret], format => 'yaml') };
    ok(!defined $strict, 'a MAC that covers the comment does not verify here');
    like($@, qr/MAC verification failed/, 'and says so');
    like($@, qr/digest over 1 leaf value\b/,
        'over ONE leaf: the comment is not counted, and the count says so');

    my $lax = eval { File::SOPS->decrypt(
        encrypted => $doc, identities => [$secret], format => 'yaml',
        ignore_mac => 1) };
    isa_ok($lax->{list}[0], 'File::SOPS::Comment',
        'and it is still read as a comment, not as a value');
};

subtest 'a comment as a mapping value is still refused, naming the path' => sub {
    # THE REFUSAL THAT REMAINS, and the whole of what is left of ADR 0024. No
    # SOPS store writes this shape: a comment is attached to the node that
    # FOLLOWS it, so above a mapping key it is a comment LINE. Measured against
    # sops 3.13.3 with this guard lifted, `sops -d` reads such a document at
    # exit 0 and hands the key back holding a dump of Go's comment struct
    # (`value:` / `inline:`), which is silent corruption in a file this library
    # would have written.
    my $doc = File::SOPS->encrypt(
        data => { k => 'x' }, recipients => [$public], format => 'yaml');
    $doc =~ s/^(k: ENC\[[^\]]*),type:str\]/$1,type:comment]/m
        or die "test fixture: no encrypted mapping value found to relabel";

    for my $mode (['strict', ()], ['ignore_mac', (ignore_mac => 1)]) {
        my ($name, %extra) = @$mode;
        my $got = eval { File::SOPS->decrypt(
            encrypted => $doc, identities => [$secret], format => 'yaml',
            %extra) };
        ok(!defined $got, "$name decrypt refuses it");
        like($@, qr/\Ak: .*type:comment.*mapping value/s,
            "$name: at the key, as a comment in a mapping value slot");
        unlike($@, qr/\bx\b/, "$name: and no plaintext in the message");
    }

    # The same shape on the WRITE side, which is where a caller can produce it.
    my $written = eval { File::SOPS->encrypt(
        data       => { k => File::SOPS::Comment->new(text => ' c') },
        recipients => [$public], format => 'yaml') };
    ok(!defined $written, 'and encrypt refuses to write one');
    like($@, qr/\Ak: a comment cannot be a mapping value/,
        'naming the key');
};

subtest 'a comment this emitter would have to write as text is refused' => sub {
    # The second refusal that remains: YAML::XS cannot emit a comment at all, so
    # a plaintext document cannot carry one -- and a comment line handed to an
    # editor would be dropped by YAML::XS on the way back in, which would be a
    # silent loss rather than a round trip. Same guard for the unencrypted slot,
    # where sops leaves the comment as a plain `# ...` line (measured).
    my $tree = { list => [ File::SOPS::Comment->new(text => ' c'), 'one' ] };

    ok(!defined(eval { File::SOPS::Format::YAML->emit($tree) }),
        'the plaintext emitter refuses');
    like($@, qr/\Alist:0: cannot write a sops comment/, 'naming the element');
    like($@, qr/File::SOPS::Comment/, 'and saying what to use instead');

    my $unencrypted = eval { File::SOPS->encrypt(
        data       => { list_unencrypted => [
            File::SOPS::Comment->new(text => ' c') ] },
        recipients => [$public], format => 'yaml') };
    ok(!defined $unencrypted, 'and so does an unencrypted slot');
    like($@, qr/cannot write a sops comment/, 'with the same message');
};

subtest 'the file-based read paths keep it too' => sub {
    my $file = "$tempdir/comment.enc.yaml";
    my $before = document_with_comment_leaf();
    write_binary($file, $before);

    # Under ADR 0024 extract and rotate croaked `list:0: ...` here.
    is(File::SOPS->extract(file => $file, path => '["list"][1]',
        identities => [$secret]), 'one', 'extract reaches past the comment');

    my $comment = File::SOPS->extract(file => $file, path => '["list"][0]',
        identities => [$secret]);
    isa_ok($comment, 'File::SOPS::Comment', 'and extract of the comment itself');
    is($comment->text, ' only a sequence comment', 'gives its text');

    ok(File::SOPS->rotate(file => $file, identities => [$secret]),
        'rotate re-keys the document');
    isnt(read_binary($file), $before, 'writing a new one');
    my $rotated = File::SOPS->decrypt(
        encrypted => read_binary($file), identities => [$secret]);
    isa_ok($rotated->{list}[0], 'File::SOPS::Comment',
        'with the comment still a comment');
    is($rotated->{list}[0]->text, ' only a sequence comment', 'and its text');

    # NOT flipped: decrypt_file has to write PLAINTEXT, which cannot carry a
    # comment. It refuses at the emitter and writes nothing.
    eval { File::SOPS->decrypt_file(input => $file,
        output => "$tempdir/out.yaml", identities => [$secret]) };
    like($@, qr/\Alist:0: cannot write a sops comment/, 'decrypt_file refuses');
    ok(!-e "$tempdir/out.yaml", 'and wrote nothing');
};

###############################################################################
# 5. THE SHAPE IS SOPS'S, NOT OURS. Without a binary the sections above prove
#    what this library does with the shape; they cannot prove that sops writes
#    it. That is section 6. The full round trip -- our document read back by
#    the binary -- is t/56.
###############################################################################

SKIP: {
    skip "no sops binary (\$SOPS_BIN, PATH, .sops-bin/sops, /tmp/sops) -- the compatibility "
       . "claim this file makes was NOT verified", 3
        unless $sops_bin;

    subtest 'sops really writes a list comment as a list element' => sub {
        # The three-line minimal reproducer from k108, verbatim.
        write_binary("$tempdir/seq.plain.yaml", "list:\n  # only a sequence comment\n  - one\n");
        my $out = `$sops_bin -e --age $public --input-type yaml --output-type yaml $tempdir/seq.plain.yaml 2>&1`;
        is($? >> 8, 0, 'sops -e writes the document') or diag($out);

        like($out, qr/^\s+- ENC\[AES256_GCM,.*,type:comment\]$/m,
            'the comment is a SEQUENCE ELEMENT, not a comment line');
        like($out, qr/^\s+- ENC\[AES256_GCM,.*,type:str\]$/m,
            'followed by the value it was written above');

        write_binary("$tempdir/seq.enc.yaml", $out);
        my $back = `$sops_bin -d --input-type yaml --output-type yaml $tempdir/seq.enc.yaml 2>&1`;
        is($? >> 8, 0, 'and sops -d reads it back') or diag($back);
        like($back, qr/# only a sequence comment/,
            'with the comment restored as a comment');

        # ADR 0024 asserted a refusal here. The MAC verifying is the
        # load-bearing half -- it is sops's own digest, and it only matches
        # because the comment is left out of ours.
        my $got = eval { File::SOPS->decrypt(
            encrypted => read_binary("$tempdir/seq.enc.yaml"),
            identities => [$secret]) };
        ok(defined $got, 'File::SOPS reads the document sops just wrote')
            or diag($@);
        isa_ok($got->{list}[0], 'File::SOPS::Comment', 'element 0');
        is($got->{list}[0]->text, ' only a sequence comment', 'with its text');
        is($got->{list}[1], 'one', 'and the value after it');
    };

    subtest 'a flow sequence with a trailing comment reads as sops reads it' => sub {
        # sops rewrites `flow: [1, 2]  # after` into a BLOCK sequence with the
        # comment as element 0, so a list of integers gained a leading string:
        # sops reads [1, 2], File::SOPS read [' after a flow seq', 1, 2].
        write_binary("$tempdir/flow.plain.yaml", "flow: [1, 2]  # after a flow seq\n");
        my $out = `$sops_bin -e --age $public --input-type yaml --output-type yaml $tempdir/flow.plain.yaml 2>&1`;
        is($? >> 8, 0, 'sops -e writes the document') or diag($out);
        like($out, qr/^flow:\n\s+- ENC\[AES256_GCM,.*,type:comment\]$/m,
            'the flow sequence became a block sequence led by the comment');

        write_binary("$tempdir/flow.enc.yaml", $out);
        # A refusal at flow:0 under ADR 0024. sops reads [1, 2] with a
        # comment; so do we, where k108 read
        # [' after a flow seq', 1, 2].
        my $got = eval { File::SOPS->decrypt(
            encrypted => read_binary("$tempdir/flow.enc.yaml"),
            identities => [$secret]) };
        ok(defined $got, 'File::SOPS reads it, MAC and all') or diag($@);
        isa_ok($got->{flow}[0], 'File::SOPS::Comment', 'element 0');
        is($got->{flow}[0]->text, ' after a flow seq', 'is the comment');
        is_deeply([ @{$got->{flow}}[1, 2] ], [1, 2],
            'and the integers are the integers');
    };

    subtest 'a document whose comments are all in mapping position still reads' => sub {
        # The control, and the thing this change must not break. Every comment
        # position sops turns into a `#ENC[...]` LINE rather than an element.
        write_binary("$tempdir/map.plain.yaml", <<'YAML');
# first line
database:
  # above a key
  host: localhost
  port: 5432  # trailing
api:
  key: secret
YAML
        my $out = `$sops_bin -e --age $public --input-type yaml --output-type yaml $tempdir/map.plain.yaml 2>&1`;
        is($? >> 8, 0, 'sops -e writes the document') or diag($out);
        like($out, qr/^#ENC\[AES256_GCM,.*,type:comment\]$/m,
            'the comments are comment LINES');
        unlike($out, qr/^\s*- ENC\[AES256_GCM,.*,type:comment\]$/m,
            'and not one of them is a sequence element');

        write_binary("$tempdir/map.enc.yaml", $out);
        my $got = eval { File::SOPS->decrypt(
            encrypted => read_binary("$tempdir/map.enc.yaml"),
            identities => [$secret]) };
        ok(defined $got, 'File::SOPS reads it, MAC and all') or diag($@);
        is_deeply($got, {
            database => { host => 'localhost', port => 5432 },
            api      => { key  => 'secret' },
        }, 'with the comments simply absent, as they always were');
    };
}

done_testing();
