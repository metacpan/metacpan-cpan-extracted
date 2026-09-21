#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(read_binary write_binary);
use JSON::MaybeXS qw(JSON);

use File::SOPS;
use File::SOPS::Comment;
use File::SOPS::Encrypted;
use File::SOPS::Metadata;
use File::SOPS::Metadata::Flat;
use File::SOPS::Backend::Age;
use File::SOPS::Format::ENV;
use Crypt::Age;
use lib 't/lib';
use SopsBin qw(find_sops_bin);

# ----------------------------------------------------------------------------
# k36 / docs/adr/0045: the ENV (dotenv) format handler.
#
# The parser is the easy half. What this file pins is the rest of it, and every
# claim in it was measured against sops 3.13.3 on a whole document rather than
# reasoned about:
#
#   * THE LINE. `KEY=VALUE`, the key up to the FIRST `=`, nothing trimmed,
#     quotes not stripped, an EMPTY line skipped and a blank line refused.
#   * THE COMMENT. `#...` is a leaf, and in this format it is the ORDINARY
#     case. It authenticates under the AAD `:` -- an empty key component -- so
#     it lives under the empty key, as a sequence, and it is not in the digest.
#   * THE ORDER. A file sops writes is in DOCUMENT order and a file this
#     library writes is in SORTED order, because the MAC's encrypt side hashes
#     sorted. Both have to verify, which is what parse_in_document_order is
#     for (docs/adr/0036). Section 3 shows the two orders really differ.
#   * THE ESCAPE. A newline becomes backslash-n; a value that already holds
#     backslash-n is refused rather than written, because sops writes such a
#     file at exit 0 and then cannot read it (docs/adr/0030).
#   * THE UNENCRYPTED LEAF. Written as exactly the bytes the digest covers,
#     which is where sops writes a display form and breaks its own file for a
#     boolean, a null and an integral float (docs/adr/0035, k124/k125/k137).
#
# WHAT THE BINARY IS FOR. Sections 1-7 are Perl->Perl and prove only that this
# library agrees with itself, which is the failure mode that ships broken files.
# Sections 8 and on are the compatibility claim, asked in both directions:
#
#   sops -e            -> File::SOPS reads, MAC and all
#   File::SOPS writes  -> sops -d, exit 0
#
# They are skipped without a binary, and then this file proves nothing about
# sops.
# ----------------------------------------------------------------------------

my $sops_bin = find_sops_bin();
diag("Using sops binary: $sops_bin") if $sops_bin;

my $tempdir = tempdir(CLEANUP => 1);
my ($public, $secret) = Crypt::Age->generate_keypair();
write_binary("$tempdir/key.txt", $secret);
$ENV{SOPS_AGE_KEY_FILE} = "$tempdir/key.txt";

my $FLAT = File::SOPS::Metadata::Flat->new(prefix => 'sops_');

# The MAC's own plaintext: the SHA-512 hex string the document stores,
# decrypted. Two documents whose digests agree hold the same value here.
sub mac_plaintext {
    my ($document) = @_;
    my (undef, $metadata) = File::SOPS::Format::ENV->parse($document);
    my $key = File::SOPS::Backend::Age->decrypt_data_key(
        age_keys => $metadata->age, identities => [$secret]);
    return File::SOPS::Encrypted->parse($metadata->mac)->decrypt_bytes(
        key => $key, aad => $metadata->lastmodified // '');
}

sub sops_run {
    my (@args) = @_;
    my $out = `$sops_bin @args 2>&1`;
    return ($?, $out);
}

###############################################################################
# 1. THE LINE. What a dotenv document is, byte for byte.
###############################################################################

subtest 'the line grammar is the store\'s, not a convenience' => sub {
    my ($data, $metadata) = File::SOPS::Format::ENV->parse(join "\n",
        'FOO=bar',
        'QUOTED="hello world"',
        'SPACED=  padded  ',
        'HASH=a#b',
        'EQ=a=b',
        'EMPTY=',
        'a b=spaces in the key',
        '',
    );

    is($data->{FOO}, 'bar', 'KEY=VALUE');
    is($data->{QUOTED}, '"hello world"',
        'quotes are part of the value -- the store does not strip them');
    is($data->{SPACED}, '  padded  ', 'nothing is trimmed, either side');
    is($data->{HASH}, 'a#b', 'a # inside a value is not a comment');
    is($data->{EQ}, 'a=b', 'the key stops at the FIRST =');
    is($data->{EMPTY}, '', 'an empty value is the empty string');
    is($data->{'a b'}, 'spaces in the key', 'a key may hold a space');
    is($metadata, undef, 'a plaintext document has no metadata section');

    # Only a TRULY empty line is skipped. sops refuses a line of blanks with
    # `invalid dotenv input line`, measured, and so does this.
    my ($ok) = File::SOPS::Format::ENV->parse("A=1\n\n\nB=2\n");
    is_deeply($ok, { A => 1, B => 2 }, 'empty lines are skipped');

    like(exception(sub { File::SOPS::Format::ENV->parse("A=1\n   \n") }),
        qr/line 2 is neither a comment nor a KEY=VALUE pair/,
        'a line of blanks is refused, as sops refuses it');
    like(exception(sub { File::SOPS::Format::ENV->parse("A=1\nnope\n") }),
        qr/line 2 is neither a comment nor a KEY=VALUE pair/,
        'and so is a line with no =');
};

sub exception {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? undef : $@;
}

###############################################################################
# 2. THE COMMENT. Where it lives, and why it cannot live anywhere else.
###############################################################################

subtest 'a comment is a leaf under the empty key, and the AAD says so' => sub {
    my ($data) = File::SOPS::Format::ENV->parse(<<"ENV");
# a leading comment
FOO=bar
# a trailing one
ENV

    is_deeply([sort keys %$data], ['', 'FOO'],
        'the comments are under the EMPTY key');
    isa_ok($data->{''}[0], 'File::SOPS::Comment', 'the first comment');
    is($data->{''}[0]->text, ' a leading comment',
        'the text is everything after the #, leading space included');
    is($data->{''}[1]->text, ' a trailing one', 'and the second one is kept');
    is(scalar @{ $data->{'' } }, 2, 'both of them, in document order');

    # THE REASON IT IS THE EMPTY KEY, and it is not a convention this handler
    # was free to pick: measured against sops 3.13.3, a comment leaf in an env
    # document decrypts under the AAD `:` and nothing else. That is the path
    # [''] -- an empty key component -- and a sequence adds none, so every
    # element of the bucket authenticates exactly as sops writes it.
    my $encrypted = File::SOPS->encrypt(
        data       => { '' => [ File::SOPS::Comment->new(text => ' hi') ] },
        recipients => [$public],
        format     => 'env',
    );
    my ($tree, $metadata) = File::SOPS::Format::ENV->parse($encrypted);
    my $key = File::SOPS::Backend::Age->decrypt_data_key(
        age_keys => $metadata->age, identities => [$secret]);

    is(File::SOPS::Encrypted->encrypted_type($tree->{''}[0]), 'comment',
        'the leaf goes onto the wire as type:comment');
    is(File::SOPS::Encrypted->parse($tree->{''}[0])
        ->decrypt_bytes(key => $key, aad => ':'), ' hi',
        'and it authenticates under the AAD sops uses for it');
    is(eval { File::SOPS::Encrypted->parse($tree->{''}[0])
        ->decrypt_bytes(key => $key, aad => '') }, undef,
        'under the empty AAD it does not decrypt at all');
};

subtest 'a comment is verbatim, where a value is escaped' => sub {
    # Measured: a comment holding `a\nb` comes back as `a\nb`, where a data
    # value holding the same bytes comes back as a newline. sops neither
    # escapes nor unescapes a comment.
    my ($data) = File::SOPS::Format::ENV->parse("#a\\nb\nV=a\\nb\n");
    is($data->{''}[0]->text, 'a\nb', 'the comment keeps its backslash-n');
    is($data->{V}, "a\nb", 'the value gets a newline');

    # Which means a comment with a real newline has no spelling at all.
    like(exception(sub { File::SOPS::Format::ENV->emit(
            { '' => [ File::SOPS::Comment->new(text => "a\nb") ] }) }),
        qr/comment holding a newline cannot be written/,
        'so a comment holding one is refused');
};

subtest 'the empty key is reserved, and says so' => sub {
    like(exception(sub { File::SOPS::Format::ENV->parse("=novalue\n") }),
        qr/EMPTY key, which is where this handler keeps.*comments/s,
        'a document with an empty DATA key is refused rather than losing one');

    like(exception(sub { File::SOPS::Format::ENV->emit({ '' => 'scalar' }) }),
        qr/empty key is reserved for this document's comments/,
        'and a scalar in the comment slot is refused');

    like(exception(sub { File::SOPS::Format::ENV->emit({ '' => ['plain'] }) }),
        qr/empty key holds this document's comments/,
        'as is a plain string among the comments');

    like(exception(sub { File::SOPS->encrypt(
            data       => { k => File::SOPS::Comment->new(text => ' x') },
            recipients => [$public], format => 'env') }),
        qr/comment cannot be a mapping value/,
        'a comment in a value slot is refused by the shared walk');
};

###############################################################################
# 3. THE ORDER. The half of MAC verification only the handler can supply.
###############################################################################

subtest 'parse_in_document_order answers in document order' => sub {
    my $content = <<"ENV";
# one
zebra=ENC[AES256_GCM,data:x,iv:y,tag:z,type:str]
alpha=2
# two
middle=3
sops_version=3.13.3
sops_mac=ENC[AES256_GCM,data:x,iv:y,tag:z,type:str]
ENV

    my $ordered = File::SOPS::Format::ENV->parse_in_document_order($content);
    is(ref $ordered, 'HASH', 'a HashRef, as the contract requires');
    is_deeply([keys %$ordered], ['', 'zebra', 'alpha', 'middle'],
        'keys iterate in DOCUMENT order, not sorted and not hash order');
    is(scalar @{ $ordered->{''} }, 2,
        'the comment bucket is there with the right length, so the shapes line up');
    ok(!exists $ordered->{sops_version},
        'the metadata is gone -- the handler drops it, condition 3');
    ok(!defined $ordered->{alpha}, 'values are undef: only the shape is read');

    # Declining is safe, guessing is not.
    is(File::SOPS::Format::ENV->parse_in_document_order("A=1\nnope\n"), undef,
        'a document it cannot scan is DECLINED, not died on');
    is(File::SOPS::Format::ENV->parse_in_document_order("A=1\nA=2\n"), undef,
        'and so is one this handler would refuse to parse');
};

subtest 'the two orders really differ, so the reparse is doing work' => sub {
    # A document in sops's order (not sorted) and the same document as this
    # library would write it (sorted). If parse_in_document_order ever went
    # back to sorted order, section 8 would fail on the MAC and this subtest
    # is what says why.
    my $ordered = File::SOPS::Format::ENV->parse_in_document_order(
        "zebra=1\nalpha=2\nmiddle=3\n");
    is_deeply([keys %$ordered], [qw(zebra alpha middle)], 'document order');
    isnt(join(',', keys %$ordered), join(',', sort keys %$ordered),
        'which is NOT sorted order');

    # ... and what this library writes IS sorted, because the MAC's encrypt
    # side hashes sorted. t/05-format-key-order.t pins the same property for
    # the other two handlers.
    my $emitted = File::SOPS::Format::ENV->emit(
        { zebra => 1, alpha => 2, middle => 3 });
    is($emitted, "alpha=2\nmiddle=3\nzebra=1\n",
        'emit writes sorted keys, one KEY=VALUE per line');
};

###############################################################################
# 4. THE EMITTER.
###############################################################################

subtest 'emit writes the comment block first, then sorted data lines' => sub {
    my $out = File::SOPS::Format::ENV->emit({
        '' => [ File::SOPS::Comment->new(text => ' first'),
                File::SOPS::Comment->new(text => ' second') ],
        b  => 'B',
        a  => 'A',
    });
    is($out, "# first\n# second\na=A\nb=B\n",
        'the empty key sorts first, so the comments head the document');

    # A document's comment position is NOT preserved, and cannot be: the tree
    # is a Perl hash and the data keys are being reordered anyway. Measured:
    # moving every comment of a sops-written file to the top leaves `sops -d`
    # at exit 0, because no comment is in the digest.
    my ($back) = File::SOPS::Format::ENV->parse($out);
    is(scalar @{ $back->{''} }, 2, 'and it reads back as the same two comments');
    is($back->{''}[1]->text, ' second', 'in the same order');
};

subtest 'serialize appends the flat metadata section last' => sub {
    my $metadata = File::SOPS::Metadata->new(
        age     => [ { recipient => 'age1x', enc => "-----BEGIN\nARMOR\n" } ],
        version => '3.13.3',
    );
    my $out = File::SOPS::Format::ENV->serialize(
        data => { k => 'v' }, metadata => $metadata);

    like($out, qr/\Ak=v\n/, 'the data comes first');
    like($out, qr/^sops_age__list_0__map_enc=-----BEGIN\\nARMOR\\n$/m,
        'and the metadata is flattened and escaped by Metadata::Flat');
    like($out, qr/^sops_version=3\.13\.3\n\z/m, 'the section is last');

    like(exception(sub { File::SOPS::Format::ENV->serialize(
            data => { sops_foo => 'x' }, metadata => $metadata) }),
        qr/top-level key starting with 'sops_'/,
        'a data key that would be read back as metadata is refused (sops: exit 203)');
};

###############################################################################
# 5. THE REFUSALS.
###############################################################################

subtest 'what this format cannot carry is refused, and says why' => sub {
    like(exception(sub { File::SOPS::Format::ENV->emit({ db => { h => 1 } }) }),
        qr/cannot use complex value in dotenv file/,
        'a nested value -- sops refuses the same tree, exit 4');
    like(exception(sub { File::SOPS::Format::ENV->emit({ l => [1,2] }) }),
        qr/cannot use complex value in dotenv file/,
        'a list, same reason');
    like(exception(sub { File::SOPS::Format::ENV->emit({ r => \1 }) }),
        qr/cannot use complex value in dotenv file/,
        'an unblessed reference, whose digest would cover a heap address');

    like(exception(sub { File::SOPS::Format::ENV->parse("A=1\nA=2\n") }),
        qr/set twice/,
        'a duplicate key -- sops keeps both, a Perl hash cannot');

    like(exception(sub { File::SOPS::Format::ENV->parse("A=caf\xe9\n") }),
        qr/is not valid UTF-8/,
        'bytes that are not UTF-8, as both other parsers refuse them');
};

subtest 'a value the newline escape cannot carry is refused (docs/adr/0030)' => sub {
    # The rule ASKS the escape rather than testing for a character.
    my $bytes = 'a\nb';
    isnt($FLAT->unescape_value($FLAT->escape_value($bytes)), $bytes,
        'the escape does not round-trip backslash-n -- the premise');

    like(exception(sub { File::SOPS->encrypt(
            data       => { x_unencrypted => 'a\nb' },
            recipients => [$public], format => 'env') }),
        qr/newline escape does not round-trip it/,
        'so an UNENCRYPTED leaf holding it is refused when the document is written');

    # A real newline is fine: it escapes and unescapes back to itself.
    my $ok = File::SOPS->encrypt(
        data       => { x_unencrypted => "line1\nline2" },
        recipients => [$public], format => 'env');
    like($ok, qr/^x_unencrypted=line1\\nline2$/m,
        'a real newline is written as backslash-n, which is what sops writes');

    # An ENCRYPTED leaf is immune: base64 holds neither a backslash nor a
    # newline, so the escape is the identity on it. Refusing it would reject
    # documents that work.
    my $enc = File::SOPS->encrypt(
        data       => { x => 'a\nb' },
        recipients => [$public], format => 'env');
    like($enc, qr/^x=ENC\[/m, 'the same value in an encrypted slot is written');
};

###############################################################################
# 6. THE UNENCRYPTED LEAF (docs/adr/0035).
###############################################################################

subtest 'an unencrypted leaf is written as exactly its digest bytes' => sub {
    my %leaf = (
        'bool_unencrypted'     => JSON->false,
        'null_unencrypted'     => undef,
        'int_unencrypted'      => 42,
        'intfloat_unencrypted' => 1.0,
        'bigfloat_unencrypted' => 1e20,
        'negzero_unencrypted'  => -0.0,
        'str_unencrypted'      => 'plain',
    );
    my $out = File::SOPS->encrypt(
        data => { %leaf }, recipients => [$public], format => 'env');

    for my $key (sort keys %leaf) {
        my $bytes = File::SOPS::Encrypted->value_to_bytes($leaf{$key});
        like($out, qr/^\Q$key=$bytes\E$/m,
            "$key is written as value_to_bytes: '$bytes'");
    }

    # Named individually, because these three are where sops writes a display
    # form and then cannot read its own file: k124, k125 and k137.
    like($out, qr/^bool_unencrypted=False$/m,   'a boolean is False, not false');
    like($out, qr/^null_unencrypted=$/m,        'a null is empty, not <nil>');
    like($out, qr/^intfloat_unencrypted=1$/m,   'an integral float is 1, not 1.0');
    like($out, qr/^bigfloat_unencrypted=100000000000000000000$/m,
        'and an exponent-range one is positional, not 1E+20');
    like($out, qr/^negzero_unencrypted=-0$/m,   'a negative zero keeps its sign');
};

subtest 'the type label still comes from the scalar (ADR 0002, unchanged)' => sub {
    my $out = File::SOPS->encrypt(
        data       => { i => 5, f => 1.5, b => JSON->true, s => '5' },
        recipients => [$public], format => 'env');

    like($out, qr/^i=ENC\[[^\n]*,type:int\]$/m,   'an integer is type:int');
    like($out, qr/^f=ENC\[[^\n]*,type:float\]$/m, 'a float is type:float');
    like($out, qr/^b=ENC\[[^\n]*,type:bool\]$/m,  'a boolean is type:bool');
    like($out, qr/^s=ENC\[[^\n]*,type:str\]$/m,   'and a string is type:str');

    # A document READ from an env source is all strings, with no format rule
    # anywhere: the parser hands the walk plain Perl string SVs.
    my ($data) = File::SOPS::Format::ENV->parse("n=5\n");
    is(File::SOPS::Encrypted->detect_type($data->{n}), 'str',
        'which is why NUM=5 out of an env document is a str');
};

###############################################################################
# 7. THE WIRING.
###############################################################################

subtest 'the format is wired into File::SOPS' => sub {
    is(File::SOPS::Format::ENV->format_name, 'env', 'format_name');
    is_deeply([File::SOPS::Format::ENV->file_extensions], ['env'],
        'file_extensions');
    ok(File::SOPS::Format::ENV->detect('secrets.env'), 'detect a .env file');
    ok(File::SOPS::Format::ENV->detect('.env'), 'and a bare .env');
    ok(!File::SOPS::Format::ENV->detect('secrets.yaml'), 'but not a .yaml one');

    is(File::SOPS::_detect_format_from_filename('secrets.env'), 'env',
        'the filename detector knows the extension');
    is(File::SOPS::_detect_format_from_filename('.env'), 'env',
        'including a bare .env');

    my $encrypted = File::SOPS->encrypt(
        data => { a => 1 }, recipients => [$public], format => 'env');
    is(File::SOPS::_detect_format($encrypted), 'env',
        'and the content detector recognises an encrypted env document');
    is(File::SOPS::_detect_format("a: 1\nsops:\n    version: 3.13.3\n"), 'yaml',
        'a YAML document is still yaml');
    is(File::SOPS::_detect_format('{"a":1}'), 'json', 'and JSON is still json');

    my $alias = File::SOPS->encrypt(
        data => { a => 1 }, recipients => [$public], format => 'dotenv');
    like($alias, qr/^a=ENC\[/m, "sops's own name for the format is an alias");
};

###############################################################################
# 8 and on. THE COMPATIBILITY CLAIM. Everything above is Perl talking to Perl.
###############################################################################

SKIP: {
    skip "no sops binary found (\$SOPS_BIN, PATH, .sops-bin/sops, /tmp/sops) -- the ENV "
       . "compatibility assertions did NOT run", 6 unless $sops_bin;

    ###########################################################################
    # 8. sops writes, File::SOPS reads -- MAC and all.
    ###########################################################################

    subtest 'a document sops wrote reads here, MAC verified' => sub {
        # Deliberately NOT in sorted key order, and with comments in three
        # positions: this is the document that fails to verify if the order
        # recovery or the comment exclusion is lost.
        write_binary("$tempdir/plain.env", <<"ENV");
# a leading comment
zebra=first
NUM=5
# a comment in the middle
alpha=second
EMPTY=
UNI=caf\xc3\xa9
plain_unencrypted=visible
# a trailing comment
ENV
        my ($rc) = sops_run('-e', '--age', $public,
            "$tempdir/plain.env", '>', "$tempdir/enc.env");
        is($rc, 0, 'sops -e wrote the document');

        my $encrypted = read_binary("$tempdir/enc.env");
        like($encrypted, qr/^#ENC\[[^\n]*type:comment\]$/m,
            'with its comments as type:comment lines');

        # The order really is the document's and not sorted, so this document
        # can only verify through parse_in_document_order.
        my $ordered = File::SOPS::Format::ENV->parse_in_document_order($encrypted);
        isnt(join(',', keys %$ordered), join(',', sort keys %$ordered),
            'and in an order that is not sorted');

        my $data = File::SOPS->decrypt(
            encrypted => $encrypted, identities => [$secret]);
        is($data->{zebra}, 'first', 'the values come back');
        is($data->{NUM}, '5', 'an env source types everything str');
        is($data->{EMPTY}, '', 'an empty value stays empty');
        is($data->{UNI}, "caf\x{e9}",
            'a UTF-8 value comes back as characters');
        is($data->{plain_unencrypted}, 'visible',
            'and an unencrypted leaf is read from the line');

        is(scalar @{ $data->{''} }, 3, 'all three comments are kept');
        isa_ok($data->{''}[0], 'File::SOPS::Comment', 'each of them');
        is($data->{''}[1]->text, ' a comment in the middle',
            'with its text intact');

        # The digest claim, stated directly rather than inferred from the
        # decrypt above: what this library computes over that document is what
        # sops stored in it, which it can only be if the comments are out and
        # the order is the document's.
        my ($tree, $metadata) = File::SOPS::Format::ENV->parse($encrypted);
        my $key = File::SOPS::Backend::Age->decrypt_data_key(
            age_keys => $metadata->age, identities => [$secret]);
        my $leaves = File::SOPS::_digested_leaves(
            File::SOPS::_document_leaves($ordered, $tree, [], []), $key);
        is(scalar @$leaves, 6,
            'six values in the digest -- the three comments are not among them');
        is(File::SOPS::_mac_digest(leaves => $leaves, metadata => $metadata,
                data_key => $key),
           mac_plaintext($encrypted),
           'and the digest matches the one sops stored, byte for byte');
    };

    ###########################################################################
    # 9. File::SOPS writes, sops reads.
    ###########################################################################

    subtest 'a document written here reads back out of sops at exit 0' => sub {
        my $encrypted = File::SOPS->encrypt(
            data => {
                ''      => [ File::SOPS::Comment->new(text => ' written here') ],
                FOO     => 'bar',
                NUM     => 5,
                FLOATY  => 1.5,
                BOOL    => JSON->true,
                UNI     => "caf\x{e9}",
                EMPTY   => '',
                NIL     => undef,
                MULTI   => "line1\nline2",
                plain_unencrypted    => 'visible',
                bool_unencrypted     => JSON->false,
                null_unencrypted     => undef,
                int_unencrypted      => 42,
                intfloat_unencrypted => 1.0,
                bigfloat_unencrypted => 1e20,
                negzero_unencrypted  => -0.0,
            },
            recipients => [$public],
            format     => 'env',
        );
        write_binary("$tempdir/ours.env", $encrypted);

        my ($rc, $out) = sops_run('-d', "$tempdir/ours.env");
        is($rc, 0, 'sops -d reads it, MAC and all')
            or diag("sops said: $out");

        my %line = map { /\A([^=]*)=(.*)\z/s ? ($1 => $2) : () }
                   grep { !/\A#/ } split /\n/, $out;

        is($line{FOO}, 'bar', 'the string comes back');
        is($line{NUM}, '5', 'the integer');
        is($line{FLOATY}, '1.5', 'the float');
        is($line{BOOL}, 'true', 'the boolean, in sops\'s own display form');
        is($line{UNI}, "caf\xc3\xa9", 'the UTF-8 value');
        is($line{EMPTY}, '', 'the empty value');
        is($line{NIL}, '', 'and a null, which is not encrypted');
        is($line{MULTI}, 'line1\nline2',
            'a newline comes back escaped, as sops writes it');

        # The three sops defect classes, written as the bytes the digest
        # covers -- these are the lines sops cannot produce for itself.
        is($line{bool_unencrypted}, 'False', 'k124: the boolean is readable');
        is($line{null_unencrypted}, '', 'k125: the null is readable');
        is($line{intfloat_unencrypted}, '1', 'k137: the float is readable');
        is($line{bigfloat_unencrypted}, '100000000000000000000', 'and so is 1e20');
        is($line{negzero_unencrypted}, '-0', 'and a negative zero');

        like($out, qr/^# written here$/m, 'the comment is written back as one');
    };

    ###########################################################################
    # 10. The three documents sops writes and cannot read.
    ###########################################################################

    subtest 'sops\'s own broken lines are refused here the same way' => sub {
        # docs/adr/0035's measurement, reproduced: sops writes a display form
        # into the unencrypted slot where its own digest covers the wire form,
        # so the file it just wrote fails its own MAC.
        for my $case ([true => 'true'], [null => '<nil>'], ['1.0' => '1.0']) {
            my ($yaml_value, $written) = @$case;
            write_binary("$tempdir/defect.yaml", "v_unencrypted: $yaml_value\n");
            my ($erc) = sops_run('-e', '--age', $public, '--input-type', 'yaml',
                '--output-type', 'dotenv', "$tempdir/defect.yaml",
                '>', "$tempdir/defect.env");
            is($erc, 0, "sops -e wrote a document for $yaml_value");

            my $document = read_binary("$tempdir/defect.env");
            like($document, qr/^v_unencrypted=\Q$written\E$/m,
                "  and wrote v_unencrypted=$written");

            my ($drc) = sops_run('-d', "$tempdir/defect.env");
            isnt($drc, 0, '  which sops itself then refuses to read');

            like(exception(sub { File::SOPS->decrypt(
                    encrypted => $document, identities => [$secret]) }),
                qr/MAC verification failed/,
                '  and so does this library, for the same reason');

            my $lax = File::SOPS->decrypt(encrypted => $document,
                identities => [$secret], ignore_mac => 1);
            is($lax->{v_unencrypted}, $written,
                '  ignore_mac hands back the literal text sops wrote');
        }
    };

    ###########################################################################
    # 11. The file API, in both directions, with comments.
    ###########################################################################

    subtest 'the file methods carry a commented .env through sops' => sub {
        my $plain = <<"ENV";
# a comment
FOO=bar
NUM=5

plain_unencrypted=visible
ENV
        write_binary("$tempdir/f.env", $plain);

        File::SOPS->encrypt_file(
            input => "$tempdir/f.env", output => "$tempdir/f.enc.env",
            recipients => [$public]);
        my ($rc, $out) = sops_run('-d', "$tempdir/f.enc.env");
        is($rc, 0, 'encrypt_file -> sops -d at exit 0') or diag($out);
        like($out, qr/^# a comment$/m, 'with the comment still a comment');

        File::SOPS->decrypt_file(
            input => "$tempdir/f.enc.env", output => "$tempdir/f.back.env",
            identities => [$secret]);
        is(read_binary("$tempdir/f.back.env"),
           "# a comment\nFOO=bar\nNUM=5\nplain_unencrypted=visible\n",
           'decrypt_file writes the comment block first and drops blank lines');

        # rotate a document SOPS wrote, and hand it back to sops.
        write_binary("$tempdir/r.env", read_binary("$tempdir/enc.env"));
        File::SOPS->rotate(file => "$tempdir/r.env", identities => [$secret]);
        my ($rrc, $rout) = sops_run('-d', "$tempdir/r.env");
        is($rrc, 0, 'rotate on a sops-written document -> sops -d at exit 0')
            or diag($rout);
        like($rout, qr/^# a leading comment$/m,
            'and the comments survived the re-key');
    };

    ###########################################################################
    # 12. mac_only_encrypted, both ways.
    ###########################################################################

    subtest 'mac_only_encrypted works in both directions' => sub {
        my ($rc) = sops_run('-e', '--age', $public, '--mac-only-encrypted',
            "$tempdir/plain.env", '>', "$tempdir/moe.env");
        is($rc, 0, 'sops -e --mac-only-encrypted');

        my $document = read_binary("$tempdir/moe.env");
        like($document, qr/^sops_mac_only_encrypted=true$/m,
            'the flag is in the flat section as a string');
        my $data = File::SOPS->decrypt(
            encrypted => $document, identities => [$secret]);
        is($data->{zebra}, 'first', 'and this library reads the document');

        my $ours = File::SOPS->encrypt(
            data => { A => '1', B_unencrypted => 'plain' },
            recipients => [$public], format => 'env', mac_only_encrypted => 1);
        write_binary("$tempdir/moe2.env", $ours);
        my ($drc, $dout) = sops_run('-d', "$tempdir/moe2.env");
        is($drc, 0, 'and sops reads one written here') or diag($dout);
    };
}

done_testing;
