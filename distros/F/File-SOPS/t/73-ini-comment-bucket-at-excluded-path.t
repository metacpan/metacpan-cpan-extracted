#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(read_binary write_binary);
use Test::Fatal qw(exception);

use File::SOPS;
use File::SOPS::Comment;
use Crypt::Age;
use lib 't/lib';
use SopsBin qw(find_sops_bin);

# ----------------------------------------------------------------------------
# k172 / docs/adr/0059 -- the wire half of a comment BUCKET that reaches
# _encrypt_tree carrying ENC[...,type:comment] STRINGS at a path the encryption
# rule EXCLUDES.
#
# ADR 0049 (rule-first decrypt) hands such a leaf back to the caller AS its own
# ENC[...] text -- the comment was decrypted for the read side too, but the
# rule said it stays a literal. The bucket key (the section's '' entry) holds
# those literals, and `_is_comment_bucket` answered NO because its
# `_is_comment_leaf` half is gated on the data key, which `_encrypt_tree` has
# none of. With NO the bucket key ADDS a path component on the way back in, and
# the INI emitter is handed a `''` slot holding a list of plain strings.
#
# Two things that follow, both wrong:
#   * `_encrypt_tree`'s leaf guard (k168) refuses the strings at the
#     excluded path, because the rule says "no ENC-comment strings here" -- but
#     those strings are not a CALLER's, they are what the previous encrypt
#     already wrote, and refusing them is the bug;
#   * at any path the walk would re-encrypt the strings as type:str, losing
#     the comment label, which is what `value_to_bytes` on the read side then
#     refuses ("a plain scalar is not one").
#
# The fix is two halves that belong together: `_is_comment_bucket` recognises
# the wire half (`!ref && encrypted_type eq 'comment'`), and the ARRAY branch
# in `_encrypt_tree` returns the bucket list as-is when it holds nothing but
# those strings -- so the comment line a previous encrypt wrote is preserved,
# the type:comment label is too, and k168's refusal never reaches a
# bucket item because the walk no longer descends into one.
#
# Reachable only through `ignore_mac => 1` plus `rotate` (or `edit`). The MAC
# is what closes the document at the same path by the same disagreement, so the
# scenario without `ignore_mac` fails MAC verification -- and is documented to
# do so in t/61's "every walk that builds a path asks the same question".
# ----------------------------------------------------------------------------

my $sops_bin = find_sops_bin();
diag("Using sops binary: $sops_bin") if $sops_bin;

my ($public, $secret) = Crypt::Age->generate_keypair();
my $tempdir = tempdir(CLEANUP => 1);
write_binary("$tempdir/key.txt", $secret);
$ENV{SOPS_AGE_KEY_FILE} = "$tempdir/key.txt";

###############################################################################
# 1. The misruled-file reproducer. Encrypt under a rule that SELECTS the
#    empty key (so the comment is written as ENC[...,type:comment]), mutate
#    the rule so the SECTION is excluded, and try to rotate the file with
#    ignore_mac => 1.
#
#    Without the fix: rotate dies inside _encrypt_tree -- k168 fires at
#    the leaf because should_encrypt_path returned false on the bucket item,
#    or the ARRAY branch re-encrypts it as a type:str and the INI emitter
#    refuses the result with "a plain scalar is not one".
#    With the fix: rotate succeeds and the comment line is preserved.
###############################################################################

subtest 'a misruled INI file with an ENC-comment bucket rotates under ignore_mac'
=> sub {
    # The original rule must SELECT the empty key so the bucket is encrypted
    # as ENC[...,type:comment]. `^public_` does exactly that -- nothing in
    # the fixture's keys starts with `public_`, so it excludes no key.
    my $encrypted = File::SOPS->encrypt(
        data       => { db => { '' => [ File::SOPS::Comment->new(text => ' a comment') ],
                                host => 'h' } },
        recipients => [$public],
        format     => 'ini',
        unencrypted_regex => '^public_',
    );
    like($encrypted, qr/^; ENC\[[^\]]*type:comment\]$/m,
        'the comment line is encrypted as type:comment under ^public_');

    # Mutate the rule to ^db$ -- the section is now excluded. The encrypted
    # comment line stays in the file: rotation, not re-encryption, is what
    # the test exercises.
    (my $misruled = $encrypted)
        =~ s/(^unencrypted_regex\s+\=\s+)\^public_(\s*)$/$1^db\$/m
        or die 'the rule line moved';
    like($misruled, qr/^unencrypted_regex\s+\=\s+\^db\$$/m,
        'the file is misruled: rule is now ^db$');
    like($misruled, qr/^; ENC\[[^\]]*type:comment\]$/m,
        'and the comment line is still an ENC-comment string in the file');

    write_binary("$tempdir/misruled.ini", $misruled);

    my $err = exception {
        File::SOPS->rotate(
            file       => "$tempdir/misruled.ini",
            identities => [$secret],
            ignore_mac => 1,
        );
    };
    is($err, undef, 'rotate with ignore_mac succeeds')
        or diag("rotate died: $err");

    # The comment line survives. It is still an ENC-comment string (a fresh
    # one, with a fresh IV -- the bucket predicate is what lets the walk
    # keep the wire half as-is), and the type:comment label is intact.
    my $rotated = read_binary("$tempdir/misruled.ini");
    like($rotated, qr/^; ENC\[[^\]]*type:comment\]$/m,
        'the comment line is preserved as type:comment, not rewritten as type:str');
};

###############################################################################
# 2. The narrower claim: _is_comment_bucket answers YES for BOTH shapes --
#    Comment objects (the plaintext tree's spelling) and plain
#    ENC-comment strings (the wire tree's spelling) -- and NO for anything
#    else at the slot. Both have to be YES for the two walks to agree on
#    the path they build, which is what keeps the encrypt-side AAD equal
#    to the decrypt-side AAD. The data-key gate _is_comment_leaf carries
#    is dropped for the wire half because _encrypt_tree has no key to
#    open it with -- the same predicate k168 added to the leaf guard.
###############################################################################

subtest '_is_comment_bucket recognises both shapes, and nothing else' => sub {
    my $enc_comment = File::SOPS::Encrypted->encrypt_value(
        value => ' a comment',
        key   => "\0" x 32,
        aad   => '',
    );
    (my $wire = $enc_comment->to_string) =~ s/,type:\w+\]\z/,type:comment]/;

    is(File::SOPS::_is_comment_bucket([ $wire ]),
        1, 'a single ENC-comment string in a list is a bucket');

    is(File::SOPS::_is_comment_bucket([ $wire, $wire ]),
        1, 'and a list of more than one of them still is');

    is(File::SOPS::_is_comment_bucket([ File::SOPS::Comment->new(text => 'p') ]),
        1, 'and a Comment object in the slot is too (the plaintext half)');

    is(File::SOPS::_is_comment_bucket([ $wire, File::SOPS::Comment->new(text => 'p') ]),
        1, 'and a mixed list is still YES, because either shape counts');

    is(File::SOPS::_is_comment_bucket([ 'plain string' ]),
        0, 'but a plain non-Comment scalar in the slot is NOT a bucket');
};

###############################################################################
# 3. The normal case is unaffected: a Comment object bucket at a SELECTED
#    path still produces ENC-comment strings on the way out (the round trip
#    goes plaintext Comment -> ENC-comment -> Comment), and the bucket key
#    adds no path component on either side -- so the AAD the encrypt side
#    uses is the same one the decrypt side uses.
###############################################################################

subtest 'a Comment object bucket round-trips, with the same AAD on both sides'
=> sub {
    my $encrypted = File::SOPS->encrypt(
        data       => { db => { '' => [ File::SOPS::Comment->new(text => ' p') ],
                                host => 'h' } },
        recipients => [$public],
        format     => 'ini',
    );
    like($encrypted, qr/^; ENC\[[^\]]*type:comment\]$/m,
        'Comment objects in the bucket encrypt to ENC-comment strings '
        . 'under the default rule (which selects every key)');

    my $back = File::SOPS->decrypt(
        encrypted  => $encrypted,
        identities => [$secret],
        format     => 'ini',
    );
    is_deeply($back,
        { db => { '' => [ File::SOPS::Comment->new(text => ' p') ],
                  host => 'h' } },
        'and reads back to Comment objects unchanged');
};

done_testing();
