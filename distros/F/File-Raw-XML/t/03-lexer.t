#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Raw::XML;

# Every token kind with its offset, and the two normalisations in their
# order: line ends first, then literal whitespace in attribute values,
# with references exempt from the second.

sub lex   { File::Raw::XML::_lex(@_) }
sub kinds { join ' ', map { $_->[0] } @{ lex($_[0]) } }

# every kind, with offsets
{
    my $doc  = qq{<?xml version="1.0"?><!-- c --><?pi data?><r a="1"><e/>text<![CDATA[cd]]></r>};
    my $rows = lex($doc);
    is(kinds($doc), 'comment pi start empty text cdata end', 'every token kind, in order');

    is_deeply($rows->[0], ['comment', 21, undef, ' c '],      'comment: offset at its <, body verbatim');
    is_deeply($rows->[1], ['pi', 31, 'pi', 'data'],           'PI: target and data');
    is_deeply($rows->[2], ['start', 42, 'r', [['a', '1']]],   'start tag: name and attributes');
    is_deeply($rows->[3], ['empty', 51, 'e', []],             'empty element: no attributes');
    is_deeply($rows->[4], ['text', 55, undef, 'text'],        'text');
    is_deeply($rows->[5], ['cdata', 59, undef, 'cd'],         'CDATA: flagged, body raw');
    is_deeply($rows->[6], ['end', 73, 'r', undef],            'end tag');
}

# the declaration and the BOM
{
    ok(lex(qq{<?xml version="1.0" encoding="UTF-8" standalone="yes"?><a/>}), 'a full declaration');
    ok(lex(qq{<?xml version='1.0' encoding='utf-8'?><a/>}), 'single quotes, lower-case encoding');
    ok(lex(qq{<?xml  version = "1.0" ?><a/>}), 'whitespace around the pseudo-attributes');
    my $rows = lex("\xEF\xBB\xBF<a/>");
    is($rows->[0][1], 3, 'a UTF-8 BOM is skipped and the first token is at offset 3');
    $rows = lex(qq{<?xml version="1.0"?>\n<a/>});
    is($rows->[0][0], 'text', 'whitespace after the declaration is a text token; the parser drops it');
}

# line ends: 2.11
{
    my $rows = lex("<a>x\r\ny\rz\n</a>");
    is($rows->[1][3], "x\ny\nz\n", 'CRLF and lone CR become LF in text');
    $rows = lex("<a><!--\r\n--></a>");
    is($rows->[1][3], "\n", 'and in a comment');
    $rows = lex("<a><![CDATA[\r]]></a>");
    is($rows->[1][3], "\n", 'and in CDATA');
    $rows = lex("<a><?p x\r\ny?></a>");
    is($rows->[1][3], "x\ny", 'and in a PI');
}

# attribute values: 2.11 then 3.3.3, references exempt
{
    my $rows = lex(qq{<a b="x\r\ny\rz"/>});
    is($rows->[0][3][0][1], 'x y z', 'CRLF and CR in an attribute become one space each');
    $rows = lex(qq{<a b="x\ty\nz"/>});
    is($rows->[0][3][0][1], 'x y z', 'literal TAB and LF in an attribute become spaces');
    $rows = lex(qq{<a b="x&#xA;y&#x9;z&#xD;w"/>});
    is($rows->[0][3][0][1], "x\ny\tz\rw", 'referenced LF, TAB and CR stay the character');
    $rows = lex(qq{<a b='it"s'/>});
    is($rows->[0][3][0][1], 'it"s', 'a double quote inside single quotes');
    $rows = lex(qq{<a b="it's"/>});
    is($rows->[0][3][0][1], "it's", 'and the reverse');
    $rows = lex(qq{<a b="&lt;&gt;"/>});
    is($rows->[0][3][0][1], '<>', 'references in an attribute value');
    $rows = lex(qq{<a  b = "1"\tc='2'\n/>});
    is_deeply($rows->[0][3], [['b', '1'], ['c', '2']], 'attributes in document order, whitespace forgiven around =');
}

# references: the five, decimal and hex
{
    my $rows = lex("<a>&lt;&gt;&amp;&apos;&quot;</a>");
    is($rows->[1][3], q{<>&'"}, 'the five predefined entities');
    $rows = lex("<a>&#65;&#x41;&#x00041;&#xe9;</a>");
    is($rows->[1][3], "AAA\xC3\xA9", 'decimal, hex, leading zeros, lower-case hex');
    $rows = lex("<a>a&amp;&amp;b</a>");
    is($rows->[1][3], 'a&&b', 'adjacent references');
}

# CDATA
{
    my $rows = lex("<a><![CDATA[<b>&amp;]]&gt;]]></a>");
    is($rows->[1][3], '<b>&amp;]]&gt;', 'CDATA keeps markup and references raw, and ]] short of ]]>');
    $rows = lex("<a><![CDATA[]]></a>");
    is($rows->[1][3], '', 'an empty CDATA section is an empty text token');
}

# PIs and comments
{
    my $rows = lex("<a><?target?></a>");
    is_deeply([@{ $rows->[1] }[2, 3]], ['target', ''], 'a PI with no data has empty data');
    $rows = lex("<a><?xml-stylesheet href='x'?></a>");
    is($rows->[1][2], 'xml-stylesheet', 'a target beginning with xml is not the reserved one');
    $rows = lex("<a><?p  two  spaces ?></a>");
    is($rows->[1][3], 'two  spaces ', 'PI data starts after the whitespace run following the target (2.6) and keeps the rest');
    $rows = lex("<a><!-- a - b --></a>");
    is($rows->[1][3], ' a - b ', 'a single hyphen inside a comment is fine');
    $rows = lex("<a><!----></a>");
    is($rows->[1][3], '', 'an empty comment');
}

# names
{
    my $rows = lex("<p:a p:b='1'/>");
    is($rows->[0][2], 'p:a', 'a prefixed element name');
    is($rows->[0][3][0][0], 'p:b', 'a prefixed attribute name');
    $rows = lex("<a><b>x</b></a>");
    is(kinds("<a><b>x</b></a>"), 'start start text end end', 'nesting is the parser\'s business; the lexer just streams');
}

done_testing;
