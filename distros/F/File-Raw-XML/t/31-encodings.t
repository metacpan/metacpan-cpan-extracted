#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Encode qw(encode);
use File::Raw::XML qw(file_xml_decode);

# The full profile's encodings: UTF-16 by BOM, by first bytes and by
# declaration; ISO-8859-1 and US-ASCII by declaration; the caller's
# override; every contradiction refused; and every refusal naming an
# offset in the caller's bytes. The fixtures are made here from one
# character source, never stored as binary. Under strict nothing of this
# is reached and the 0.01 refusals stand.

sub full   { my ($b, %o) = @_; file_xml_decode($b, profile => 'full', %o) }
sub strict { my ($b, %o) = @_; file_xml_decode($b, %o) }
sub refused_full { my ($b, %o) = @_; my $ok = eval { full($b, %o); 1 }; $ok ? '' : $@ }
sub tree {
    my ($n, $out) = @_;
    $out .= join('|', $n->kind, $n->name, $n->ns, (map { join '=', @$_ } @{ $n->attrs }),
                      $n->kind == 2 ? $n->text : '') . ';';
    $out .= tree($_, '') for $n->children;
    return $out;
}

# one document, with a Latin-1 character literal and the rest by reference
my $body    = qq{<r a="\x{e9}"><b>&#x3C0; &#x1D11E;</b><!-- c --><![CDATA[x]]></r>\n};
my $ascii   = $body;
$ascii =~ s/\x{e9}/&#xE9;/;
sub doc { my ($enc, $text) = @_; qq{<?xml version="1.0" encoding="$enc"?>\n} . ($text // $body) }

my %fixture = (
    'UTF-8'             => encode('UTF-8',    doc('UTF-8')),
    'UTF-8 with BOM'    => "\xEF\xBB\xBF" . encode('UTF-8', doc('UTF-8')),
    'UTF-8 undeclared'  => encode('UTF-8',    $body),
    'UTF-16LE with BOM' => "\xFF\xFE" . encode('UTF-16LE', doc('UTF-16')),
    'UTF-16BE with BOM' => "\xFE\xFF" . encode('UTF-16BE', doc('UTF-16')),
    'UTF-16LE no BOM'   => encode('UTF-16LE', doc('UTF-16LE')),
    'UTF-16BE no BOM'   => encode('UTF-16BE', doc('UTF-16BE')),
    'ISO-8859-1'        => encode('ISO-8859-1', doc('ISO-8859-1')),
    'latin1 alias'      => encode('ISO-8859-1', doc('latin1')),
    'US-ASCII'          => encode('US-ASCII',   doc('US-ASCII', $ascii)),
);

# one tree, one canonical form, from every encoding
{
    my $ref = full($fixture{'UTF-8'});
    my $c14n = $ref->c14n(mode => 'exclusive', comments => 1);
    my $shape = tree($ref->document, '');
    is($ref->root->attr('a'), "\x{e9}", 'the reference document carries the character');
    for my $name (sort keys %fixture) {
        my $doc = eval { full($fixture{$name}) };
        ok($doc, "$name parses under full") or do { diag $@; next };
        is($doc->c14n(mode => 'exclusive', comments => 1), $c14n, "$name: the same canonical bytes");
        is(tree($doc->document, ''), $shape, "$name: the same tree");
    }
}

# under strict the 0.01 refusals stand
{
    for my $name ('UTF-16LE with BOM', 'UTF-16BE with BOM', 'UTF-16LE no BOM', 'UTF-16BE no BOM') {
        ok(!eval { strict($fixture{$name}); 1 }, "strict refuses $name");
        like($@, qr/UTF-16/, 'naming it');
    }
    ok(!eval { strict($fixture{'ISO-8859-1'}); 1 }, 'strict refuses a declared ISO-8859-1');
    like($@, qr/only the UTF-8 encoding is accepted/, 'with the 0.01 message');
    ok(strict($fixture{'UTF-8 with BOM'}), 'strict still takes a UTF-8 BOM');
}

# 4.3.3: the declaration against what arrived
{
    like(refused_full("\xFF\xFE" . encode('UTF-16LE', doc('UTF-8'))),
         qr/encoding declaration contradicts the byte order mark/, 'a UTF-16 BOM with a declaration of UTF-8 is fatal');
    like(refused_full("\xFF\xFE" . encode('UTF-16LE', doc('UTF-16BE'))),
         qr/contradicts the byte order mark/, 'a little-endian BOM with a declaration of UTF-16BE is fatal');
    ok(full("\xFF\xFE" . encode('UTF-16LE', doc('UTF-16LE'))), 'a little-endian BOM with a declaration of UTF-16LE is fine');
    ok(full("\xFE\xFF" . encode('UTF-16BE', doc('utf-16'))), 'the name is case-insensitive');
    like(refused_full("\xEF\xBB\xBF" . encode('UTF-8', doc('ISO-8859-1'))),
         qr/contradicts the byte order mark/, 'a UTF-8 BOM with a declaration of ISO-8859-1 is fatal');
    like(refused_full(encode('UTF-16LE', doc('ISO-8859-1'))),
         qr/contradicts the encoding the document arrived in/, 'UTF-16 by first bytes with a declaration of ISO-8859-1 is fatal');
    like(refused_full(encode('UTF-8', doc('Shift_JIS'))),
         qr/declared encoding is not one this parser supports/, 'a declaration this parser does not support is refused by name');
    like(refused_full("\0\0\xFE\xFF" . "\0\0\0<"), qr/UCS-4 is not supported/, 'a UCS-4 BOM is refused by name');
    like(refused_full("\0\0\0<\0\0\0?"), qr/UCS-4 is not supported/, 'UCS-4 by first bytes likewise');
    like(refused_full("\x4C\x6F\xA7\x94\x93\x40"), qr/EBCDIC is not supported/, 'and EBCDIC');
}

# the caller's override
{
    my $latin = encode('ISO-8859-1', qq{<r a="\x{e9}"/>});
    like(refused_full($latin), qr/not UTF-8/, 'a Latin-1 byte with no declaration is not UTF-8');
    is(full($latin, encoding => 'ISO-8859-1')->root->attr('a'), "\x{e9}", 'encoding => ISO-8859-1 makes it Latin-1');
    is(full($latin, encoding => 'latin1')->root->attr('a'), "\x{e9}", 'by alias too');
    ok(full(encode('UTF-8', doc('ISO-8859-1', '<r/>')), encoding => 'UTF-8'), 'an override wins over the declaration');
    like(refused_full('<r/>', encoding => 'Shift_JIS'), qr/named by the caller is not one this parser supports/, 'an unknown override is refused');
    like(refused_full("\xFF\xFE" . encode('UTF-16LE', '<r/>'), encoding => 'UTF-8'), qr/named by the caller contradicts the byte order mark/, 'an override contradicting a BOM is refused');
    ok(full("\xFF\xFE" . encode('UTF-16LE', '<r/>'), encoding => 'UTF-16'), 'utf-16 with a BOM takes the BOM\'s endianness');
    ok(full(encode('UTF-16BE', '<r/>'), encoding => 'UTF-16'), 'utf-16 without a BOM is big-endian, RFC 2781');
    ok(!eval { strict('<r/>', encoding => 'UTF-8'); 1 }, 'strict refuses the option rather than ignore it');
    like($@, qr/encoding is an option of profile => 'full'/, 'saying which profile has it');
}

# refusals name the caller's bytes
{
    # an unpaired high surrogate: RFC 2781 section 2.2 forbids a high
    # surrogate not followed by a low one
    my $bad = "\xFF\xFE" . encode('UTF-16LE', '<r>ab') . "\x00\xD8" . encode('UTF-16LE', 'c</r>');
    my $off = 2 + 2 * length('<r>ab');
    like(refused_full($bad), qr/high surrogate not followed by a low surrogate in UTF-16 input at byte offset $off of the UTF-16LE input near "/,
         'an unpaired high surrogate, at its input offset, naming the input');
    $bad = "\xFF\xFE" . encode('UTF-16LE', '<r>a') . "\x00\xDC" . encode('UTF-16LE', '</r>');
    like(refused_full($bad), qr/unpaired low surrogate.* at byte offset 10 of the UTF-16LE input/, 'an unpaired low surrogate, after the BOM and four units');
    $bad = "\xFE\xFF" . encode('UTF-16BE', '<r/>') . "\x00";
    like(refused_full($bad), qr/odd trailing byte in UTF-16 input at byte offset 10 of the UTF-16BE input/, 'an odd trailing byte');
    like(refused_full(encode('UTF-8', doc('US-ASCII', '<r>')) . "\xE9</r>"),
         qr/byte outside US-ASCII in input declared US-ASCII at byte offset (\d+) of the US-ASCII input/, 'a byte outside US-ASCII');

    # a well-formedness error inside a transcoded document maps back
    my $doc16 = "\xFF\xFE" . encode('UTF-16LE', '<a><b></a>');
    my $msg = refused_full($doc16);
    my $want = 2 + 2 * index('<a><b></a>', '</a>');
    like($msg, qr/end tag does not match the open element at byte offset $want of the UTF-16LE input near "/, 'a mismatched end tag in UTF-16 reports the input offset of the tag');
    like($msg, qr/near "<\\x00\/\\x00a\\x00>\\x00"/, 'and the context shows the UTF-16 bytes at that offset');

    # past the first checkpoint
    my $long = '<r>' . ('x' x 5000) . '<b></r>';
    $msg = refused_full("\xFF\xFE" . encode('UTF-16LE', $long));
    $want = 2 + 2 * index($long, '</r>');
    like($msg, qr/at byte offset $want of the UTF-16LE input/, 'the offset map re-walks from a checkpoint past 4 KiB of input');

    # a UTF-8 input with a BOM under full reports offsets in the caller's bytes too
    $msg = refused_full("\xEF\xBB\xBF<a><b></a>");
    like($msg, qr/at byte offset 9 near "/, 'a UTF-8 BOM is counted in the reported offset');
}

# max_bytes is checked on the input
{
    my $b = "\xFF\xFE" . encode('UTF-16LE', '<r/>');
    ok(full($b, max_bytes => length $b), 'max_bytes equal to the input length passes');
    like(refused_full($b, max_bytes => length($b) - 1), qr/input exceeds max_bytes/, 'one less refuses');
}

# Latin-1's whole byte range is characters
{
    my $all = join '', map { chr } 0xA0 .. 0xFF;
    my $doc = full(encode('ISO-8859-1', qq{<?xml version="1.0" encoding="ISO-8859-1"?><r>$all</r>}));
    is($doc->root->text, $all, 'every Latin-1 byte from A0 to FF is its character');
    is(full(encode('ISO-8859-1', qq{<?xml version="1.0" encoding="ISO-8859-1"?><r>\x{85}</r>}))->root->text, "\x{85}", 'and so is a C1 control, which XML 1.0 allows');
}

# the conformance suite's UTF-16 cases, when the suite is here
SKIP: {
    skip 'the conformance suite is not under t/xmlconf/xmlconf', 1 unless -d 't/xmlconf/xmlconf/xmltest';
    my ($seen, $encoding_failures, $parsed) = (0, 0, 0);
    my @dirs = grep { -d } ('t/xmlconf/xmlconf/xmltest', 't/xmlconf/xmlconf/ibm/valid');
    for my $dir (@dirs) {
        for my $file (sort glob("$dir/*/*.xml"), sort glob("$dir/*/*/*.xml")) {
            my $bytes = do { open my $fh, '<:raw', $file or next; local $/; <$fh> };
            next unless length($bytes) >= 2 && (substr($bytes, 0, 2) eq "\xFE\xFF" || substr($bytes, 0, 2) eq "\xFF\xFE");
            $seen++;
            my $doc = eval { full($bytes) };
            if ($doc) { $parsed++; next }
            my $err = $@;
            # every mapped-back message says "of the UTF-16LE input", so the
            # encoding failures are told by their own phrases
            my $enc_fail = $err =~ /in UTF-16 input|contradicts|not one this parser supports|UCS-4|EBCDIC|not UTF-8/;
            $encoding_failures++ if $enc_fail;
            diag("$file: $err") if $enc_fail;
        }
    }
    diag("xmlconf: $seen UTF-16 files seen, $parsed parsed, " . ($seen - $parsed - $encoding_failures) . " refused for a non-encoding reason, $encoding_failures for an encoding reason");
    is($encoding_failures, 0, "no UTF-16 conformance case fails for an encoding reason ($seen seen)");
}

done_testing;
