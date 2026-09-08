#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Raw::XML;

# The decoder and the Char production, through the lexer's private
# accessor: what is accepted comes back as the same bytes, and what is
# refused names an offset.

sub lex     { File::Raw::XML::_lex($_[0]) }
sub refused { my $r = eval { File::Raw::XML::_lex($_[0]); 1 }; $r ? '' : $@ }

# accepted
{
    my $rows = lex("<\xC3\xA9>\xC3\xBC</\xC3\xA9>");
    is($rows->[0][0], 'start', 'a multibyte element name lexes');
    is($rows->[0][2], "\xC3\xA9", 'and comes back as its bytes');
    is($rows->[1][3], "\xC3\xBC", 'multibyte text comes back as its bytes');

    $rows = lex("<a>&#x10FFFF;</a>");
    is($rows->[1][3], "\xF4\x8F\xBF\xBF", 'U+10FFFF by reference encodes to four bytes');

    $rows = lex("<a>\xF4\x8F\xBF\xBF</a>");
    is($rows->[1][3], "\xF4\x8F\xBF\xBF", 'and a literal U+10FFFF is accepted');

    $rows = lex("<a>\xE2\x82\xAC \xF0\x9F\x98\x80</a>");
    is($rows->[1][3], "\xE2\x82\xAC \xF0\x9F\x98\x80", 'three- and four-byte characters');

    $rows = lex("<a>\t\n ok</a>");
    is($rows->[1][3], "\t\n ok", 'TAB and LF are Char');
}

# refused
{
    my $msg = refused("<a>\xC0\x80</a>");
    like($msg, qr/^File::Raw::XML: not UTF-8 at byte offset 3 near "/, 'the overlong C0 80 is refused at its offset');

    like(refused("<a>\xED\xA0\x80</a>"), qr/not UTF-8 at byte offset 3/, 'a surrogate ED A0 80 is refused');
    like(refused("<a>\xF4\x90\x80\x80</a>"), qr/not UTF-8 at byte offset 3/, 'F4 90 80 80 (above U+10FFFF) is refused');
    like(refused("<a>\xE0\x80\x80</a>"), qr/not UTF-8 at byte offset 3/, 'the overlong E0 80 80 is refused');
    like(refused("<a>\xF0\x80\x80\x80</a>"), qr/not UTF-8 at byte offset 3/, 'the overlong F0 80 80 80 is refused');
    like(refused("<a>\x80</a>"), qr/not UTF-8 at byte offset 3/, 'a bare continuation byte is refused');
    like(refused("<a>\xC3</a>"), qr/not UTF-8 at byte offset 3/, 'a truncated sequence is refused');
    like(refused("<a>\x01</a>"), qr/control character is not allowed at byte offset 3/, 'a C0 control other than TAB, LF, CR is refused');
    like(refused("<a>\x1f</a>"), qr/control character/, 'and so is 0x1f');
    like(refused("<a>&#xFFFE;</a>"), qr/character reference to a non-XML character at byte offset 3/, '&#xFFFE; is valid UTF-8 and not Char');
    like(refused("<a>&#xFFFF;</a>"), qr/non-XML character/, '&#xFFFF; likewise');
    like(refused("<a>\xEF\xBF\xBE</a>"), qr/not an XML character at byte offset 3/, 'a literal U+FFFE is refused');
    like(refused("<a>&#0;</a>"), qr/non-XML character/, '&#0; is refused');
    like(refused("<a>&#xD800;</a>"), qr/non-XML character/, 'a surrogate by reference is refused');
    like(refused("<a>&#x110000;</a>"), qr/non-XML character/, 'above U+10FFFF by reference is refused');

    # in a name, in an attribute value, in a comment: the same decoder
    like(refused("<a\xC0\x80/>"), qr/not UTF-8 at byte offset 2/, 'not UTF-8 in a name');
    like(refused("<a b='\xC0\x80'/>"), qr/not UTF-8 at byte offset 6/, 'not UTF-8 in an attribute value');
    like(refused("<a><!-- \xED\xA0\x80 --></a>"), qr/not UTF-8 at byte offset 8/, 'not UTF-8 in a comment');
    like(refused("<a><![CDATA[\x01]]></a>"), qr/control character is not allowed at byte offset 12/, 'a control in CDATA');
}

# names: the classes from 2.3
{
    like(refused("<1a/>"), qr/expected a name at byte offset 1/, 'a name may not start with a digit');
    like(refused("<-a/>"), qr/expected a name/, 'nor with a hyphen');
    ok(!refused("<a-b.c1_d/>"), 'but may carry them after the first character');
    ok(!refused("<_a/>"), 'and may start with an underscore');
    ok(!refused("<\xE4\xBD\xA0\xE5\xA5\xBD/>"), 'CJK name characters are NameStartChar');
    like(refused("<a\xC2\xB7b/>") || 'ok', qr/^ok$/, 'U+00B7 is a NameChar after the first');
    like(refused("<\xC2\xB7a/>"), qr/expected a name/, 'and not a NameStartChar');
}

done_testing;
