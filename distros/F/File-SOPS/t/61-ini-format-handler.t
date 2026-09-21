#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw(tempdir);
use File::Slurper qw(read_binary write_binary);

use File::SOPS;
use File::SOPS::Comment;
use File::SOPS::Encrypted;
use File::SOPS::Metadata;
use File::SOPS::Metadata::Flat;
use File::SOPS::Backend::Age;
use File::SOPS::Format::INI;
use Crypt::Age;
use lib 't/lib';
use SopsBin qw(find_sops_bin);

# ----------------------------------------------------------------------------
# k37 / docs/adr/0047: the INI format handler.
#
# What it inherits from the dotenv handler is not re-proved here (the flat
# metadata, docs/adr/0022; the type rule, docs/adr/0035; the order-preserving
# reparse, docs/adr/0036; the comment leaf, docs/adr/0041). What this file
# pins is what INI had to measure for itself:
#
#   * THE COMMENT AAD, and it is the one that decides the tree. An ini comment
#     authenticates under its SECTION -- `db:` -- and NOT under `db::`, which
#     is what a genuine empty key nested in a mapping authenticates under. So
#     a section's comments live under its empty key AND File::SOPS's walk
#     knows that key adds no path component.
#   * THE GRAMMAR. go-ini's, not a convenience: two delimiters, the
#     continuation backslash, the inline comment, three quote forms, and the
#     fact that CONSECUTIVE comment lines are ONE leaf.
#   * THE QUOTING. go-ini's writer quotes for `#`, `;`, a newline, a backtick
#     and edge whitespace; its reader strips a surrounding pair of quotes its
#     writer never wrote. The four values where the two disagree are files
#     sops writes at exit 0 and then refuses to read, and they are refused
#     here instead.
#   * THE TWO-LEVEL TREE. A nested document is refused -- sops does NOT refuse
#     it, it writes a dump of the Go value -- and so are a duplicate section,
#     a duplicate key and a section named `sops`.
#   * THE ORDER. A file sops writes is in DOCUMENT order, a file this library
#     writes is in SORTED order, and both have to verify.
#
# WHAT THE BINARY IS FOR. Sections 1-8 are Perl->Perl and prove only that this
# library agrees with itself, which is the failure mode that ships broken
# files. Section 9 on is the compatibility claim, in both directions. They are
# skipped without a binary, and then this file proves nothing about sops.
# ----------------------------------------------------------------------------

my $sops_bin = find_sops_bin();
diag("Using sops binary: $sops_bin") if $sops_bin;

my $tempdir = tempdir(CLEANUP => 1);
my ($public, $secret) = Crypt::Age->generate_keypair();
write_binary("$tempdir/key.txt", $secret);
$ENV{SOPS_AGE_KEY_FILE} = "$tempdir/key.txt";

sub exception {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? undef : $@;
}

sub sops_run {
    my (@args) = @_;
    my $out = `$sops_bin @args 2>&1`;
    return ($?, $out);
}

# The MAC's own plaintext: the SHA-512 hex string the document stores,
# decrypted. Two documents whose digests agree hold the same value here.
sub mac_plaintext {
    my ($document) = @_;
    my (undef, $metadata) = File::SOPS::Format::INI->parse($document);
    my $key = File::SOPS::Backend::Age->decrypt_data_key(
        age_keys => $metadata->age, identities => [$secret]);
    return File::SOPS::Encrypted->parse($metadata->mac)->decrypt_bytes(
        key => $key, aad => $metadata->lastmodified // '');
}

###############################################################################
# 1. THE LINE. go-ini's grammar, and it is not "everything after the =".
###############################################################################

subtest 'the line grammar is go-ini\'s, not a convenience' => sub {
    my ($data, $metadata) = File::SOPS::Format::INI->parse(<<'INI');
outside = before any section

[db]
host = localhost
colon: also a delimiter
quoted = "hello world"
squoted = 'single'
spaced =   padded   
empty =
eq = a=b
backticked = `a#b`
hashish = a#b
semi = a;b
tripled = """line1
line2"""
INI

    is($data->{DEFAULT}{outside}, 'before any section',
        'a value outside any section is in the DEFAULT section');
    is($data->{db}{host}, 'localhost', 'key = value');
    is($data->{db}{colon}, 'also a delimiter',
        ': is a key/value delimiter too, and the first one found wins');
    is($data->{db}{quoted}, 'hello world',
        'a surrounding pair of double quotes is STRIPPED (unlike dotenv)');
    is($data->{db}{squoted}, 'single', 'and so is a pair of single quotes');
    is($data->{db}{spaced}, 'padded', 'an unquoted value is trimmed both ends');
    is($data->{db}{empty}, '', 'an empty value is the empty string');
    is($data->{db}{eq}, 'a=b', 'the key stops at the FIRST delimiter');
    is($data->{db}{backticked}, 'a#b', 'backticks quote a value holding a #');
    is($data->{db}{hashish}, 'a',
        'an UNQUOTED # starts an inline comment and the rest is not the value');
    is($data->{db}{semi}, 'a', 'a ; does the same');
    is($data->{db}{tripled}, "line1\nline2",
        'a """ value runs on to the line that closes it');
    is($metadata, undef, 'a plaintext document has no metadata section');

    my ($cont) = File::SOPS::Format::INI->parse("[db]\na = one\\\nb = two\nc = 3\n");
    is($cont->{db}{a}, 'oneb = two',
        'a trailing backslash continues the value onto the next line');
    is($cont->{db}{c}, '3', 'and the line after that is a key again');
    ok(!exists $cont->{db}{b}, 'the continued line is not a key of its own');

    my ($blank) = File::SOPS::Format::INI->parse("[db]\n\n   \na = 1\n");
    is_deeply($blank, { db => { a => 1 } }, 'blank lines are skipped');

    like(exception(sub { File::SOPS::Format::INI->parse("[db]\nbareword\n") }),
        qr/line 2 is neither a comment, a section header nor a/,
        'a line with no delimiter is refused, as sops refuses it');
    like(exception(sub { File::SOPS::Format::INI->parse("[]\na = 1\n") }),
        qr/EMPTY name/,
        'an empty section name is refused, as sops refuses it');
    like(exception(sub { File::SOPS::Format::INI->parse("[db]\n = 1\n") }),
        qr/EMPTY key name/,
        'an empty key name is refused, as sops refuses it');
};

###############################################################################
# 2. THE COMMENT, and the AAD that decides where it lives.
#
# This is the measurement k37 was told to make and not to assume. It is
# ALSO a test of File::SOPS's walk: the path a comment is encrypted under is
# built there, not here.
###############################################################################

subtest 'a comment lives in its section, and the AAD says so' => sub {
    my ($data) = File::SOPS::Format::INI->parse(<<'INI');
; a comment above the first section
[db]
; above a key
host = localhost
port = 5432 ; trailing after the value
INI

    isa_ok($data->{db}{''}[0], 'File::SOPS::Comment',
        'the comment bucket is the section\'s EMPTY key');
    is(scalar @{ $data->{db}{''} }, 3, 'all three blocks land in it');
    is($data->{db}{''}[0]->text, 'a comment above the first section',
        'a comment above the header belongs to the section it precedes');
    is($data->{db}{''}[1]->text, 'above a key', 'and one above a key too');
    is($data->{db}{''}[2]->text, 'trailing after the value',
        'an inline comment is a leaf of its own, on the key it was written on');

    # CONSECUTIVE comment lines are ONE leaf, and only the FIRST line's marker
    # is stripped. Measured against sops 3.13.3, exactly this text.
    my ($block) = File::SOPS::Format::INI->parse(
        "[db]\n;nospace\n; onespace\n#  hash\nk = v\n");
    is(scalar @{ $block->{db}{''} }, 1,
        'consecutive comment lines are ONE leaf');
    is($block->{db}{''}[0]->text, "nospace\n; onespace\n#  hash",
        'and the later lines keep their own markers, verbatim');

    my ($bare) = File::SOPS::Format::INI->parse("[db]\n#\nk = v\n");
    ok(!exists $bare->{db}{''},
        'a comment with no text is dropped, as sops drops one');

    my ($eof) = File::SOPS::Format::INI->parse("[db]\nk = v\n; at the end\n");
    ok(!exists $eof->{db}{''},
        'a comment at the end of the file is dropped: nothing follows it');

    # THE AAD. The comment bucket key adds NO path component, so the leaf is
    # encrypted under the section's own path -- which is what sops does.
    my $encrypted = File::SOPS->encrypt(
        data       => { db => { '' => [ File::SOPS::Comment->new(text => 'c') ],
                                host => 'h' } },
        recipients => [$public],
        format     => 'ini',
    );
    my ($tree, $meta) = File::SOPS::Format::INI->parse($encrypted);
    my $key = File::SOPS::Backend::Age->decrypt_data_key(
        age_keys => $meta->age, identities => [$secret]);
    my $leaf = File::SOPS::Encrypted->parse($tree->{db}{''}[0]);

    is($leaf->type, 'comment', 'the bucket is written as a type:comment leaf');
    is($leaf->decrypt_bytes(key => $key, aad => 'db:'), 'c',
        'and it authenticates under the SECTION path, db:');
    is(exception(sub { $leaf->decrypt_bytes(key => $key, aad => 'db::') })
        ? 'refused' : 'accepted', 'refused',
        'NOT under db::, which is what an empty KEY would give it');

    is($File::SOPS::Format::INI::COMMENT_KEY, $File::SOPS::COMMENT_BUCKET_KEY,
        'the handler and the walk spell the bucket key the same way');
};

###############################################################################
# 3. THE WALK RULE IS NARROW. A genuine empty key keeps the AAD sops gives it.
###############################################################################

subtest 'an empty key that is not a comment bucket keeps its path component' => sub {
    my $encrypted = File::SOPS->encrypt(
        data       => { map => { '' => 'nested empty key', real => 'x' } },
        recipients => [$public],
        format     => 'yaml',
    );
    my ($tree, $meta) = File::SOPS::Format::YAML->parse($encrypted);
    my $key = File::SOPS::Backend::Age->decrypt_data_key(
        age_keys => $meta->age, identities => [$secret]);
    my $leaf = File::SOPS::Encrypted->parse($tree->{map}{''});

    is($leaf->decrypt_bytes(key => $key, aad => 'map::'), 'nested empty key',
        'a scalar under an empty key is still map:: -- measured against sops');

    # And the dotenv bucket, which is at the document ROOT, is untouched: the
    # rule only fires where the path is already non-empty.
    my $env = File::SOPS->encrypt(
        data       => { '' => [ File::SOPS::Comment->new(text => 'c') ],
                        FOO => 'bar' },
        recipients => [$public],
        format     => 'env',
    );
    my ($etree, $emeta) = File::SOPS::Format::ENV->parse($env);
    my $ekey = File::SOPS::Backend::Age->decrypt_data_key(
        age_keys => $emeta->age, identities => [$secret]);
    is(File::SOPS::Encrypted->parse($etree->{''}[0])
        ->decrypt_bytes(key => $ekey, aad => ':'), 'c',
        'a dotenv comment still authenticates under :, unchanged');
};

subtest 'every walk that builds a path asks the same question' => sub {
    # The rule decides an AAD, so a walk that answers it differently from
    # _encrypt_tree makes this library write a document it then refuses.
    # `^$` matches the bucket key and nothing else, so it separates the two
    # answers exactly: under the section's path (`db`) it selects nothing and
    # the comment is encrypted; under `db:` + the bucket key it would select
    # the comment and rotate's guard would call that file mis-ruled.
    my $encrypted = File::SOPS->encrypt(
        data       => { db => { '' => [ File::SOPS::Comment->new(text => 'n') ],
                                host => 'h' } },
        recipients => [$public],
        format     => 'ini',
        unencrypted_regex => '^$',
    );
    like($encrypted, qr/^; ENC\[[^\]]*type:comment\]$/m,
        'the comment is ENCRYPTED under a rule that matches only the bucket key');

    write_binary("$tempdir/walks.ini", $encrypted);
    is(exception(sub {
        File::SOPS->rotate(file => "$tempdir/walks.ini", identities => [$secret])
    }), undef, 'and rotate accepts the file encrypt just wrote');

    # The guard is not weakened: a rule that really does exclude the section
    # still refuses, because the comment would be rewritten as plain text.
    (my $misruled = $encrypted) =~ s/^(unencrypted_regex +\= )\^\$$/$1^db\$/m
        or die 'the rule line moved';
    write_binary("$tempdir/misruled.ini", $misruled);
    like(exception(sub {
        File::SOPS->rotate(file => "$tempdir/misruled.ini", identities => [$secret])
    }), qr/MAC verification failed/,
        'a rule that excludes the section itself now fails the MAC (docs/adr/0049)');
};

###############################################################################
# 4. THE QUOTING, and the values that are refused because it is lossy.
###############################################################################

subtest 'the writer quotes what the format needs, and refuses what it cannot carry' => sub {
    my %written = (
        'a#b'          => '`a#b`',
        'a;b'          => '`a;b`',
        "line1\nline2" => qq{"""line1\nline2"""},
        'a`b'          => '"""a`b"""',
        '  leading'    => '"  leading"',
        'trailing  '   => '"trailing  "',
        'plain'        => 'plain',
        ''             => '',
        'a=b'          => 'a=b',
    );
    for my $value (sort keys %written) {
        my $out = File::SOPS::Format::INI->emit({ s => { k => $value } });
        my $line = $out;
        $line =~ s/\A\[s\]\nk = //;
        chomp $line;
        is($line, $written{$value}, "quoting for '$value'");
        my ($back) = File::SOPS::Format::INI->parse($out);
        is($back->{s}{k}, $value, "and it reads back as itself");
    }

    # The four sops writes at exit 0 and then cannot read. Refused here.
    for my $value ('"quoted"', "'quoted'", '""', '"""x"""') {
        like(exception(sub {
                File::SOPS::Format::INI->emit({ s => { k => $value } }) }),
            qr/quoting does not round-trip it/,
            "a value spelled $value is refused rather than written");
    }
};

###############################################################################
# 5. THE TWO-LEVEL TREE, and the four things it cannot hold.
###############################################################################

subtest 'the tree is exactly two levels deep' => sub {
    like(exception(sub {
            File::SOPS::Format::INI->emit({ db => { inner => { host => 'x' } } }) }),
        qr/two levels deep/,
        'a nested value is refused -- sops writes a dump of the Go value instead');
    like(exception(sub { File::SOPS::Format::INI->emit({ top => 'scalar' }) }),
        qr/Section values should always be TreeBranches/,
        'a top-level scalar is refused, with the message sops gives it');
    like(exception(sub { File::SOPS::Format::INI->emit({ sops => { a => 1 } }) }),
        qr/read back as metadata/,
        'a section named sops is refused, as sops refuses it (exit 203)');
    like(exception(sub {
            File::SOPS::Format::INI->parse("[db]\na = 1\n[db]\nb = 2\n") }),
        qr/opened twice/,
        'a duplicate section is refused: sops keeps both, a Perl hash cannot');
    like(exception(sub {
            File::SOPS::Format::INI->parse("[db]\nk = 1\nk = 2\n") }),
        qr/is set twice/,
        'a duplicate key is refused rather than silently losing the first');
    like(exception(sub {
            File::SOPS::Format::INI->emit({ db => { '' => 'not a comment' } }) }),
        qr/reserved for this section's comments/,
        'a non-list in the comment bucket is refused');
    like(exception(sub {
            File::SOPS::Format::INI->emit(
                { db => { '' => [ File::SOPS::Comment->new(text => 'a'),
                                  File::SOPS::Comment->new(text => 'b') ] } }) }),
        qr/comment blocks in a section with 0 keys/,
        'more comments than nodes to attach them to is refused, not written '
        . 'as consecutive lines that read back as one');
};

###############################################################################
# 6. THE EMITTER'S LAYOUT. Sorted, and comments spread over the nodes.
###############################################################################

subtest 'the emitter sorts, and puts one comment per node' => sub {
    my $out = File::SOPS::Format::INI->emit({
        zulu    => { b => '2', a => '1' },
        alpha   => { '' => [ File::SOPS::Comment->new(text => 'one'),
                             File::SOPS::Comment->new(text => 'two') ],
                     k => 'v', j => 'w' },
        DEFAULT => { x => '1' },
    });

    is($out, <<'INI', 'sections sorted, keys sorted, DEFAULT with a header');
[DEFAULT]
x = 1

; one
[alpha]
; two
j = w
k = v

[zulu]
a = 1
b = 2
INI

    # Round-trips through this handler's own reader, comments and all.
    my ($back) = File::SOPS::Format::INI->parse($out);
    is($back->{alpha}{''}[0]->text, 'one', 'first comment came back');
    is($back->{alpha}{''}[1]->text, 'two', 'and so did the second, separately');
    is($back->{DEFAULT}{x}, '1', 'and the DEFAULT section');

    # Alignment padding: go-ini pads to the longest key IN THAT SECTION, in
    # bytes. Cosmetic for the digest (measured) and reproduced anyway.
    my $padded = File::SOPS::Format::INI->emit(
        { s => { short => '1', a_much_longer_key => '2' } });
    like($padded, qr/^a_much_longer_key = 2$/m, 'the longest key sets the width');
    like($padded, qr/^short             = 1$/m, 'and the others are padded to it');
};

###############################################################################
# 7. THE ORDER. Document order on the way in, sorted order on the way out.
###############################################################################

subtest 'parse_in_document_order recovers the order the file has' => sub {
    my $document = <<'INI';
zz = 1
aa = 2

[db]
host = h
alpha = a
INI
    my $ordered = File::SOPS::Format::INI->parse_in_document_order($document);
    is_deeply([ keys %$ordered ], [ 'DEFAULT', 'db' ],
        'sections in document order');
    is_deeply([ keys %{ $ordered->{DEFAULT} } ], [ 'zz', 'aa' ],
        'and the keys inside one, which are NOT sorted');
    is_deeply([ keys %{ $ordered->{db} } ], [ 'host', 'alpha' ],
        'in every section');

    my ($tree) = File::SOPS::Format::INI->parse($document);
    is_deeply([ sort keys %$tree ], [ sort keys %$ordered ],
        'the two readers agree on the shape');

    my $with_comments = "; a\n[db]\n; b\nk = v\n";
    my $shape = File::SOPS::Format::INI->parse_in_document_order($with_comments);
    my ($real) = File::SOPS::Format::INI->parse($with_comments);
    is(scalar @{ $shape->{db}{''} }, scalar @{ $real->{db}{''} },
        'the comment sequence is present with the length the tree has');

    is(File::SOPS::Format::INI->parse_in_document_order("[db]\nk=1\nk=2\n"),
        undef, 'and it declines a document parse() refuses');
};

###############################################################################
# 8. THE WHOLE THING, through the public API.
###############################################################################

subtest 'a document goes through encrypt and decrypt with its comments' => sub {
    my $data = {
        DEFAULT => { outside => 'v' },
        db      => { '' => [ File::SOPS::Comment->new(text => 'a note') ],
                     host => 'localhost', port => '5432',
                     uni => "caf\x{e9}", empty => '',
                     plain_unencrypted => 'visible' },
    };
    my $encrypted = File::SOPS->encrypt(
        data => $data, recipients => [$public], format => 'ini');

    like($encrypted, qr/^\[sops\]$/m, 'the metadata is a [sops] section');
    like($encrypted, qr/^version +\= /m, 'flat, aligned, no prefix');
    unlike($encrypted, qr/^sops_/m, 'and NOT under a sops_ prefix');
    like($encrypted, qr/^plain_unencrypted = visible$/m,
        'an _unencrypted leaf is written as its digest bytes');

    my $back = File::SOPS->decrypt(
        encrypted => $encrypted, identities => [$secret], format => 'ini');
    is($back->{db}{host}, 'localhost', 'a value survives');
    is($back->{db}{uni}, "caf\x{e9}", 'and a non-ASCII one');
    is($back->{db}{empty}, '', 'and an empty one');
    is($back->{db}{''}[0]->text, 'a note', 'and the comment');
    is($back->{DEFAULT}{outside}, 'v', 'and the DEFAULT section');

    # Format detection, both ways.
    is(File::SOPS::_detect_format($encrypted), 'ini',
        'an encrypted ini document is recognised by its [sops] section');
    is(File::SOPS::_detect_format_from_filename('x.ini'), 'ini',
        'and a .ini file by its name');

    # The comment is NOT in the digest: dropping it leaves the MAC alone.
    my $without = $encrypted;
    $without =~ s/^; ENC\[[^\]]*\]\n//m;
    is(mac_plaintext($without), mac_plaintext($encrypted),
        'the stored MAC is the same document without its comment line');
    ok(File::SOPS->decrypt(encrypted => $without, identities => [$secret],
                           format => 'ini'),
        'and the document still verifies without it');
};

###############################################################################
# 9. THE COMPATIBILITY CLAIM. Everything above is this library agreeing with
#    itself. Only the binary can say anything about sops.
###############################################################################

SKIP: {
    skip 'sops binary not found (set SOPS_BIN, put sops on PATH, or run maint/fetch-sops .sops-bin)', 3 unless $sops_bin;

    subtest 'sops writes it, File::SOPS reads it -- MAC and all' => sub {
        # Key order deliberately NOT sorted, so document order and sorted order
        # differ and the reparse has to do real work.
        my $plain = <<'INI';
; leading semicolon comment
# leading hash comment
zz_outside = before any section
aa_outside = second one

[db]
; comment above a key
host = localhost
port = 5432 ; trailing after value
empty =
alpha = last alphabetically but first here
uni = café
plain_unencrypted = visible
# hash comment inside a section

[api]
zeta = z
key = secret
multi = """line1
line2"""
INI
        write_binary("$tempdir/in.ini", $plain);
        my ($rc) = sops_run('-e', '--age', $public,
            "$tempdir/in.ini", '>', "$tempdir/in.enc.ini");
        is($rc, 0, 'sops -e wrote the document');

        my $document = read_binary("$tempdir/in.enc.ini");
        unlike($document, qr/^alpha .*\nempty/m,
            'and its keys are NOT in sorted order');

        my $data = File::SOPS->decrypt(
            encrypted => $document, identities => [$secret], format => 'ini');
        is($data->{db}{host}, 'localhost', 'a value came back');
        is($data->{db}{uni}, "caf\x{e9}", 'a non-ASCII one');
        is($data->{db}{port}, '5432',
            'an inline comment did not end up in the value');
        is($data->{db}{empty}, '', 'an empty value');
        is($data->{db}{plain_unencrypted}, 'visible', 'an unencrypted one');
        is($data->{api}{multi}, "line1\nline2", 'a multi-line one');
        is($data->{DEFAULT}{zz_outside}, 'before any section',
            'a value outside any section, from the DEFAULT section');
        is(scalar @{ $data->{db}{''} }, 2, 'both of that section\'s comments');
        is($data->{DEFAULT}{''}[0]->text,
            "leading semicolon comment\n# leading hash comment",
            'and the two leading lines as ONE multi-line leaf');
        is($data->{api}{''}[0]->text, 'hash comment inside a section',
            'and one written above a section header, in that section');
        # decrypt fails closed on a bad MAC, so getting here IS the proof.
        pass('the MAC sops computed verifies here');
    };

    subtest 'File::SOPS writes it, sops reads it at exit 0' => sub {
        my $data = {
            DEFAULT => { '' => [ File::SOPS::Comment->new(text => 'top note') ],
                         zz_outside => 'v', aa_outside => 'w' },
            db => { '' => [ File::SOPS::Comment->new(text => 'first note'),
                            File::SOPS::Comment->new(
                                text => "two lines\n# and a hash marker") ],
                    host => 'localhost', port => '5432', empty => '',
                    hashish => 'a#b', semi => 'a;b', spaced => 'padded',
                    multi => "line1\nline2", uni => "caf\x{e9}",
                    plain_unencrypted => 'visible' },
            api => { zeta => 'z', key => 'secret' },
        };
        my $encrypted = File::SOPS->encrypt(
            data => $data, recipients => [$public], format => 'ini');
        write_binary("$tempdir/ours.enc.ini", $encrypted);

        my ($rc, $out) = sops_run('-d', "$tempdir/ours.enc.ini");
        is($rc, 0, 'sops -d read the document this library wrote')
            or diag($out);
        # sops hands back UTF-8 bytes; this file's source is characters.
        utf8::decode($out);
        like($out, qr/^host +\= localhost$/m, 'a value came back');
        like($out, qr/^hashish +\= `a#b`$/m,
            'a value holding a # is backtick-quoted, as sops quotes it');
        like($out, qr/^multi +\= """line1\nline2"""$/m,
            'and a multi-line one takes the triple-quote form');
        like($out, qr/^uni +\= café$/m, 'and a non-ASCII one');
        like($out, qr/^; first note$/m, 'the first comment came back');
        like($out, qr/^; two lines\n# and a hash marker$/m,
            'and the multi-line one, marker and all');
        like($out, qr/^; top note$/m, 'and the DEFAULT section\'s');
        like($out, qr/^\[DEFAULT\]$/m,
            'DEFAULT is written with an explicit header, and sops reads it');
    };

    subtest 'sops -> File::SOPS -> sops, the whole way round' => sub {
        my $document = read_binary("$tempdir/in.enc.ini");
        my $data = File::SOPS->decrypt(
            encrypted => $document, identities => [$secret], format => 'ini');
        my $ours = File::SOPS->encrypt(
            data => $data, recipients => [$public], format => 'ini');
        write_binary("$tempdir/chain.enc.ini", $ours);

        my ($rc, $out) = sops_run('-d', "$tempdir/chain.enc.ini");
        is($rc, 0, 'sops reads a document it wrote and this library rewrote')
            or diag($out);
        utf8::decode($out);
        like($out, qr/^host +\= localhost$/m, 'values survived the trip');
        like($out, qr/^; comment above a key$/m, 'and so did the comments');
        like($out, qr/^zz_outside = before any section$/m,
            'and the DEFAULT section');
    };
}

done_testing;
