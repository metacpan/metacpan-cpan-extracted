#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(write_binary);

use File::SOPS;
use File::SOPS::Encrypted;
use File::SOPS::Comment;
use Crypt::Age;
use lib 't/lib';
use SopsBin qw(find_sops_bin);

# ----------------------------------------------------------------------------
# k168 / docs/adr/0056 -- the WIRE-HALF twin of the line-3396 guard.
#
# A plain STRING whose text parses as ENC[...,type:comment] at a path the
# encryption rule EXCLUDES is a file this library cannot read back:
# _encrypt_tree writes the literal as a plain type:str value and hashes its
# text into the MAC, but _is_comment_leaf on the read side (with $data_key
# defined) treats the same text as a comment and drops it from the digest.
# The document fails its own MAC -- produced by this library at exit 0.
#
# The mapping-value File::SOPS::Comment half is ADR 0041's guard. This is the
# wire half of the same shape, at a leaf the rule EXCLUDES, reached because
# the caller passed a plain string rather than a Comment object. No AAD or
# wire byte moves either way: the guard fires before the wire is reached, so
# the only byteset change is "no bytes at all".
# ----------------------------------------------------------------------------

my $sops_bin = find_sops_bin();
diag("Using sops binary: $sops_bin") if $sops_bin;

my ($public, $secret) = Crypt::Age->generate_keypair();
my $tempdir = tempdir(CLEANUP => 1);
write_binary("$tempdir/key.txt", $secret);
$ENV{SOPS_AGE_KEY_FILE} = "$tempdir/key.txt";

# A well-formed ENC[...] string carrying a chosen type label, built through
# encrypt_value rather than typed out, so the base64 is real and the only
# thing synthetic about it is the label -- which is what sops varies.
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

my $COMMENT_TOKEN = enc_string('comment', ' a comment');
my $STR_TOKEN     = enc_string('str',     'one');

###############################################################################
# 1. The shape. A plain ENC[...,type:comment] string at a path the default
#    unencrypted_suffix (_unencrypted) excludes. Today's behaviour (RED):
#    encrypt returns at exit 0 and writes a document that fails its own MAC
#    on the next decrypt. The fix refuses the call at write time.
###############################################################################

subtest 'a plain ENC-comment string at an excluded path is refused' => sub {
    my $got = eval { File::SOPS->encrypt(
        data       => { x_unencrypted => $COMMENT_TOKEN, k => 'v' },
        recipients => [$public],
        format     => 'yaml',
    ) };
    ok(!defined $got, 'encrypt refuses it')
        or diag('encrypt returned: '.($got // 'undef'));
    like($@, qr/\Ax_unencrypted:/, 'naming the key at the start');
    like($@, qr/type:comment/, 'naming the shape');
    unlike($@, qr/\b a comment\b/, 'no plaintext in the message');
};

###############################################################################
# 2. The round trip WITHOUT the bad shape still works. The guard must be
#    precise -- it fires on the bad shape, not on every leaf at an excluded
#    path, and not on every leaf whose text contains "ENC".
###############################################################################

subtest 'a plain string the rule EXCLUDES that is NOT type:comment still writes'
=> sub {
    my $got = eval { File::SOPS->encrypt(
        data       => { x_unencrypted => 'plain value', k => 'v' },
        recipients => [$public],
        format     => 'yaml',
    ) };
    ok(defined $got, 'plain value at excluded path writes') or diag($@);
    like($got, qr/^x_unencrypted: plain value$/m,
        'and is written verbatim, not encrypted');

    my $back = File::SOPS->decrypt(
        encrypted => $got, identities => [$secret], format => 'yaml');
    is_deeply($back, { x_unencrypted => 'plain value', k => 'v' },
        'and reads back unchanged');
};

subtest 'a type:str ENC token at an excluded path is NOT refused' => sub {
    # The label on the wire is what the guard discriminates on, not the
    # fact that the leaf happens to spell an ENC token. A type:str token at
    # an excluded path is what `_encrypt_tree` already wrote verbatim, and
    # the read side returns it as the literal ENC string -- which is the
    # whole point: the guard fires on type:comment and on no other label.
    my $got = eval { File::SOPS->encrypt(
        data       => { x_unencrypted => $STR_TOKEN, k => 'v' },
        recipients => [$public],
        format     => 'yaml',
    ) };
    ok(defined $got, 'a type:str token at an excluded path writes')
        or diag($@);
    like($got, qr/^x_unencrypted: ENC\[AES256_GCM,.*,type:str\]$/m,
        'as a bare ENC string in the document');

    my $back = File::SOPS->decrypt(
        encrypted => $got, identities => [$secret], format => 'yaml');
    is($back->{x_unencrypted}, $STR_TOKEN,
        'and reads back as the literal ENC string -- the rule excluded it');
};

###############################################################################
# 3. The SELECTED path is unaffected. A type:comment string the rule SELECTS
#    is encrypted normally -- which the existing line-3557 guard catches on
#    the way back in if its ENC half is malformed, but a plain-string ENC
#    token at a SELECTED mapping-value slot is just a value to encrypt.
###############################################################################

subtest 'a type:comment string the rule SELECTS is encrypted, not refused'
=> sub {
    # A bare mapping value the rule selects: a plain string the rule would
    # encrypt is encrypted as whatever type the ladder gives it. Here we hand
    # it an existing ENC token; the encrypt side sees a string starting with
    # ENC[...], type:comment. _encrypt_value encrypts it under a new IV/AAD.
    # The guard must NOT fire here, because should_encrypt_path is true.
    my $got = eval { File::SOPS->encrypt(
        data       => { k => $STR_TOKEN },
        recipients => [$public],
        format     => 'yaml',
    ) };
    ok(defined $got, 'a type:str token at a SELECTED path encrypts')
        or diag($@);
    like($got, qr/^k: ENC\[AES256_GCM,.*,type:str\]/m,
        'with the original type preserved');
};

###############################################################################
# 4. The File::SOPS::Comment mapping-value guard at line 3396 still fires.
#    The new guard must not absorb the old one -- a Comment object in a
#    mapping value is a separate shape (a comment OBJECT, not a literal ENC
#    token), and the message the old guard produces is its own.
###############################################################################

subtest 'a File::SOPS::Comment in a mapping value is still refused' => sub {
    my $got = eval { File::SOPS->encrypt(
        data       => { k => File::SOPS::Comment->new(text => ' c') },
        recipients => [$public],
        format     => 'yaml',
    ) };
    ok(!defined $got, 'encrypt refuses a Comment object in a mapping value');
    like($@, qr/\Ak: a comment cannot be a mapping value/,
        'naming the key and the OLD guard message');
};

###############################################################################
# 5. The bucket-list case. Once the bucket predicate recognises a list of
#    ENC-comment strings (k172 / docs/adr/0059) the walk returns the
#    bucket as-is, so this shape is now ACCEPTED -- it is a comment bucket
#    in the wire tree, the same way a list of File::SOPS::Comment objects
#    is a comment bucket in the plaintext tree. The k168 leaf guard
#    never reaches the items because the walk no longer descends into one.
#
#    This replaces an earlier assertion that the same shape was REFUSED.
#    That assertion was correct under k168 alone; k172 narrows
#    the guard's reach deliberately, because a bucket of ENC-comment
#    strings is what a previous encrypt wrote, and re-encrypt must keep
#    the comment line as-is. The non-bucket shape (subtests 1 and 4 above)
#    is still refused.
###############################################################################

subtest 'the bucket-list case is accepted, not refused' => sub {
    my $got = eval { File::SOPS->encrypt(
        data => {
            db_unencrypted => { q{} => [ $COMMENT_TOKEN ] },
            k => q{v},
        },
        recipients => [$public],
        format     => 'yaml',
    ) };
    ok(defined $got, 'a bucket of ENC-comment strings at an excluded path '
        . 'writes (k172)')
        or diag('encrypt died: '.($@ // 'undef'));
    like($got, qr/,type:comment\]/,
        'the comment strings are PRESERVED as type:comment -- the bucket '
        . 'predicate keeps them as-is instead of letting the leaf walk '
        . 'rewrite them as type:str');
    unlike($got, qr/,type:str\]\s*\n[^\n]*ENC\[AES256_GCM,[^\]]* a comment/s,
        'and the original token does not reappear as a re-encrypted type:str');
};

done_testing();
