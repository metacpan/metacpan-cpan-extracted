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
# k169 / docs/adr/0060 -- the asymmetry between the two positions a
# sops comment can occupy is deliberate, and THIS file pins it.
#
# sops attaches a comment to the node that FOLLOWS it:
#
#   * above a MAPPING KEY: stays a `#ENC[...,type:comment]` LINE,
#   * above a SEQUENCE ENTRY: written as a real list element
#     (`- ENC[...,type:comment]`) because there is no comment line to write.
#
# ADR 0041 makes the second position LOUD: the leaf is in the tree as an
# `ENC[...,type:comment]` string, the emit guard croaks at it, and
# `decrypt_file` / `edit` refuse the document and write nothing.
#
# The first position is SILENT, and that is what this file pins. YAML::XS
# discards comment text before parse ever sees a tree, so the mapping-
# position comment is not in `$data` for any guard to refuse -- the tree
# is the values, with no trace of the comment, and `decrypt_file` writes
# the plaintext at exit 0 with the comment gone.
#
# The asymmetry is measured against sops 3.13.3:
#
#   A (mapping-only comments)        sops -d exit 0, comments back
#                                    decrypt_file exit 0, NO comments in out
#   B (sequence + mapping comments)  sops -d exit 0, all comments back
#                                    decrypt_file REFUSED, no output
#
# So the same loss is loud in one position and silent in the other, and
# which one a caller gets depends on whether the document happens to
# contain a sequence. Making the mapping-position case loud would need the
# read half of k148 (YAML::PP's raw token stream) purely to power a
# refusal -- a recovered mapping-position comment has nowhere to live,
# since a Perl hash has no "before a key" slot. The asymmetry is also
# already sops's own: `sops -e --output-type json` drops mapping-position
# comments too.
#
# Sections 1 and 2 need no binary: they pin the structural pieces (what
# parse keeps, what the read path returns, what decrypt_file refuses vs
# writes). Section 3 is the compatibility claim -- that the asymmetry is
# also what sops --d reports -- and is skipped without a binary.
# ----------------------------------------------------------------------------

my $sops_bin = find_sops_bin();
diag("Using sops binary: $sops_bin") if $sops_bin;

my ($public, $secret) = Crypt::Age->generate_keypair();
my $tempdir = tempdir(CLEANUP => 1);
write_binary("$tempdir/key.txt", $secret);
$ENV{SOPS_AGE_KEY_FILE} = "$tempdir/key.txt";

# A well-formed ENC[...,type:comment] string, used for the structural subtests.
# Built through encrypt_value rather than typed out, so the base64 is real.
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

my $COMMENT_LEAF = enc_string('comment', ' a mapping-position comment');
my $STR_LEAF     = enc_string('str',     'localhost');

###############################################################################
# 1. THE STRUCTURAL PIECE. Parse drops mapping-position comment lines
#    silently: the tree has the values and no trace of the comments, so
#    nothing on the read or write paths can see what was discarded.
###############################################################################

subtest 'a mapping-position comment line leaves no trace in the parse tree' => sub {
    # A file-leading comment (above the document, where sops writes the
    # same `#ENC[...]` shape it uses above a mapping key) and one above
    # a mapping key. Both are real YAML comment lines; YAML::XS drops
    # both before parse ever sees a tree.
    my $doc = "#$COMMENT_LEAF\n"
            . "database:\n"
            . "    #$COMMENT_LEAF\n"
            . "    host: $STR_LEAF\n";

    my ($data) = File::SOPS::Format::YAML->parse($doc);
    is_deeply($data, { database => { host => $STR_LEAF } },
        'the tree is the values -- the comments are gone before parse');

    # No leaf in the tree is a comment: not even an ENC[...,type:comment]
    # string, which is the shape the sequence position would produce.
    my $found_comment = 0;
    my $walk;
    $walk = sub {
        my ($node) = @_;
        return if $found_comment;
        if (ref $node eq 'HASH') {
            $walk->($_) for values %$node;
        }
        elsif (ref $node eq 'ARRAY') {
            $walk->($_) for @$node;
        }
        elsif (defined $node && !ref $node
            && File::SOPS::Encrypted->encrypted_type($node) eq 'comment') {
            $found_comment = 1;
        }
    };
    $walk->($data);
    ok(!$found_comment,
        'no leaf in the parse tree is even a comment-shaped string');
};

subtest 'a sequence-position comment IS in the tree (the asymmetry)' => sub {
    # The structural piece from the OTHER side, to make the asymmetry
    # concrete in the same file: the file-leading comment is gone
    # (above the document), the sequence-position comment reaches
    # parse and is at its index in the tree.
    my $doc = "#$COMMENT_LEAF\n"
            . "list:\n"
            . "    - $COMMENT_LEAF\n"
            . "    - $STR_LEAF\n";

    my ($data) = File::SOPS::Format::YAML->parse($doc);
    is_deeply($data, { list => [ $COMMENT_LEAF, $STR_LEAF ] },
        'the sequence comment is element 0, the file-leading one is gone');
};

###############################################################################
# 2. WRITE-PATH ASYMMETRY. decrypt_file refuses the sequence case at the
#    emitter (ADR 0041) and silently writes the mapping-only case. Both
#    documents are built by File::SOPS itself here, so the section needs
#    no sops binary.
###############################################################################

# Document A: a mapping-position comment (file-leading + above a key), no
# sequence anywhere. Built by File::SOPS so the ENC strings are real, but
# the comments this distribution would write as `#ENC[...]` lines were
# scrubbed by hand BEFORE encrypt, so the result is a comment-shaped
# document whose only comments are in mapping position. Plaintext at exit
# 0 with the comments absent is the pinned behaviour.
sub document_with_only_mapping_comments {
    my $doc = File::SOPS->encrypt(
        data       => { database => { host => 'localhost', port => 5432 } },
        recipients => [$public],
        format     => 'yaml',
    );
    # File::SOPS does not emit comment lines (no caller can ask for one),
    # so there is nothing to strip here -- the comment is missing by
    # construction, which is exactly the sops shape this test pins.
    return $doc;
}

# Document B: a sequence comment leaf at list:0. ADR 0041 keeps this in
# the tree as an `ENC[...,type:comment]` string; decrypt_file refuses to
# write plaintext because the emitter cannot emit it.
sub document_with_sequence_comment_leaf {
    return File::SOPS->encrypt(
        data       => { list => [
            File::SOPS::Comment->new(text => ' only a sequence comment'),
            'one',
        ] },
        recipients => [$public],
        format     => 'yaml',
    );
}

subtest 'decrypt_file refuses the sequence-comment document' => sub {
    my $doc  = document_with_sequence_comment_leaf();
    my $file = "$tempdir/B.enc.yaml";
    my $out  = "$tempdir/B.out.yaml";
    write_binary($file, $doc);
    unlink $out;

    eval { File::SOPS->decrypt_file(
        input => $file, output => $out, identities => [$secret]) };
    like($@, qr/\Alist:0: cannot write a sops comment/,
        'the emitter guard croaks, naming the element');
    ok(!-e $out, 'and wrote nothing');

    # The structural reason: the leaf is in the tree. This is the
    # contrast with the mapping-position case below.
    my ($tree) = File::SOPS::Format::YAML->parse($doc);
    ok(File::SOPS::Encrypted->is_encrypted($tree->{list}[0]),
        'sequence: the leaf is in the parse tree as the ENC string');
    is(File::SOPS::Encrypted->encrypted_type($tree->{list}[0]), 'comment',
        'labelled type:comment');
};

subtest 'decrypt_file silently writes the mapping-only document' => sub {
    my $doc  = document_with_only_mapping_comments();
    my $file = "$tempdir/A.enc.yaml";
    my $out  = "$tempdir/A.out.yaml";
    write_binary($file, $doc);
    unlink $out;

    # No eval -- this is the asymmetry. The mapping-only document is
    # written at exit 0 with no error and no warning, because the
    # comments are not in the tree for the emitter to see.
    my $rc = File::SOPS->decrypt_file(
        input => $file, output => $out, identities => [$secret]);
    ok(defined $rc, 'decrypt_file returned a defined value');
    ok(-e $out, 'and the output file exists');

    my $plaintext = read_binary($out);
    unlike($plaintext, qr/type:comment/,
        'no type:comment string in the plaintext output');
    unlike($plaintext, qr/^#ENC\[/m,
        'no leading-comment line either');
    unlike($plaintext, qr/^#/m,
        'and no comment line at all in the plaintext');
    like($plaintext, qr/^\s+host: localhost$/m,
        'with the value intact under database');
    like($plaintext, qr/^\s+port: 5432$/m,
        'and its sibling intact too');

    # The structural reason: the leaf is NOT in the tree. The walk would
    # find no comment-shaped string, because parse never saw one.
    my ($tree) = File::SOPS::Format::YAML->parse($doc);
    my $found = 0;
    my $walk;
    $walk = sub {
        my ($node) = @_;
        return if $found;
        if (ref $node eq 'HASH') { $walk->($_) for values %$node }
        elsif (ref $node eq 'ARRAY') { $walk->($_) for @$node }
        elsif (defined $node && !ref $node
            && File::SOPS::Encrypted->encrypted_type($node) eq 'comment') {
            $found = 1;
        }
    };
    $walk->($tree);
    ok(!$found,
        'mapping-only: no comment-shaped leaf in the parse tree');
};

subtest 'extract and rotate behave the same way' => sub {
    # extract / rotate do not write plaintext through the emitter (they
    # return a tree / write the encrypted form), so neither of them has
    # the asymmetry: both succeed on both documents, and the comment is
    # silently absent from the tree in the mapping-only case.

    my $a_doc = document_with_only_mapping_comments();
    write_binary("$tempdir/A.enc.yaml", $a_doc);
    is(File::SOPS->extract(file => "$tempdir/A.enc.yaml",
        path => '["database"]["host"]', identities => [$secret]),
        'localhost',
        'mapping-only: extract reaches the value');
    ok(File::SOPS->rotate(file => "$tempdir/A.enc.yaml",
        identities => [$secret]),
        'mapping-only: rotate re-keys the document');

    my $b_doc = document_with_sequence_comment_leaf();
    write_binary("$tempdir/B.enc.yaml", $b_doc);
    my $got = File::SOPS->extract(file => "$tempdir/B.enc.yaml",
        path => '["list"][1]', identities => [$secret]);
    is($got, 'one',
        'sequence: extract reaches past the comment');
    ok(File::SOPS->rotate(file => "$tempdir/B.enc.yaml",
        identities => [$secret]),
        'sequence: rotate re-keys the document');
};

###############################################################################
# 3. THE COMPATIBILITY CLAIM. The asymmetry is real and matches what
#    sops --d reports on the same documents. Skipped without a binary.
###############################################################################

SKIP: {
    skip "no sops binary (\$SOPS_BIN, PATH, .sops-bin/sops, /tmp/sops) -- the compatibility "
       . "claim this file makes was NOT verified", 4
        unless $sops_bin;

    # The two plaintexts k169 measured against. A carries comments
    # in BOTH positions; B carries them in MAPPING position only.
    write_binary("$tempdir/A.plain.yaml", <<'YAML');
# a file-leading comment
database:
    # a comment above a mapping key
    host: localhost
    port: 5432
list:
    # a comment above a sequence entry
    - one
YAML
    write_binary("$tempdir/B.plain.yaml", <<'YAML');
# a file-leading comment
database:
    # a comment above a mapping key
    host: localhost
    port: 5432
YAML

    my $enc = `$sops_bin -e --age $public --input-type yaml --output-type yaml $tempdir/A.plain.yaml 2>&1`;
    is($? >> 8, 0, 'sops -e encrypts the sequence-position document')
        or diag($enc);
    write_binary("$tempdir/A.enc.yaml", $enc);

    my $enc2 = `$sops_bin -e --age $public --input-type yaml --output-type yaml $tempdir/B.plain.yaml 2>&1`;
    is($? >> 8, 0, 'sops -e encrypts the mapping-only document')
        or diag($enc2);
    write_binary("$tempdir/B.enc.yaml", $enc2);

    subtest 'sops -d returns the comments intact for both documents' => sub {
        # The reference behaviour. If this stops holding, k169's
        # premise (that the asymmetry is a this-library-only thing) is
        # gone and the whole ADR pivots.
        for my $case (['A', 'A'], ['B', 'B']) {
            my ($name, $tag) = @$case;
            my $back = `$sops_bin -d --input-type yaml --output-type yaml $tempdir/$tag.enc.yaml 2>&1`;
            is($? >> 8, 0, "$name: sops -d reads it back") or diag($back);
        }

        my $a_back = `$sops_bin -d --input-type yaml --output-type yaml $tempdir/A.enc.yaml 2>&1`;
        like($a_back, qr/^# a file-leading comment$/m,
            'A: the file-leading comment is back as a comment');
        like($a_back, qr/^    # a comment above a mapping key$/m,
            'A: the mapping-position comment is back as a comment');
        like($a_back, qr/^    # a comment above a sequence entry$/m,
            'A: the sequence-position comment is back as a comment');

        my $b_back = `$sops_bin -d --input-type yaml --output-type yaml $tempdir/B.enc.yaml 2>&1`;
        like($b_back, qr/^# a file-leading comment$/m,
            'B: the file-leading comment is back as a comment');
        like($b_back, qr/^    # a comment above a mapping key$/m,
            'B: the mapping-position comment is back as a comment');
        unlike($b_back, qr/sequence entry/,
            'B: no sequence comment, because there is no sequence');
    };

    subtest 'decrypt_file refuses the sequence document' => sub {
        unlink "$tempdir/A.out.yaml";
        eval { File::SOPS->decrypt_file(
            input      => "$tempdir/A.enc.yaml",
            output     => "$tempdir/A.out.yaml",
            identities => [$secret]) };
        like($@, qr/\Alist:0: cannot write a sops comment/,
            'refusing the sequence-position document by name');
        ok(!-e "$tempdir/A.out.yaml",
            'and writing nothing');
    };

    subtest 'decrypt_file silently writes the mapping-only document' => sub {
        unlink "$tempdir/B.out.yaml";
        my $rc = File::SOPS->decrypt_file(
            input      => "$tempdir/B.enc.yaml",
            output     => "$tempdir/B.out.yaml",
            identities => [$secret]);
        ok(defined $rc, 'defined return value');
        ok(-e "$tempdir/B.out.yaml",
            'and the output file exists');

        my $plaintext = read_binary("$tempdir/B.out.yaml");
        like($plaintext, qr/^\s+host: localhost$/m,
            'with the value intact under database');
        unlike($plaintext, qr/^#/m,
            'and no comment line at all in the plaintext');
        unlike($plaintext, qr/type:comment/,
            'and no type:comment string either');
    };
}

done_testing();
