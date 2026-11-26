#!perl

use strict;
use warnings;

use Test2::V0;

use HTTP::libsfparse qw( parse_item :types );

sub value_of { my $item = parse_item( $_[0] ); return $item->[1] }
sub type_of  { my $item = parse_item( $_[0] ); return $item->[0] }

# --- booleans --------------------------------------------------------------

is type_of('?1'),  SFPARSE_TYPE_BOOLEAN, '?1 is a boolean';
is value_of('?1'), 1,         '?1 is true';
is value_of('?0'), 0,         '?0 is false';
ok !eval { parse_item('?2'); 1 }, '?2 is not a boolean';

# --- integers --------------------------------------------------------------

is type_of('42'), SFPARSE_TYPE_INTEGER, 'integers';
is value_of('42'),               42,               'a positive integer';
is value_of('-42'),              -42,              'a negative integer';
is value_of('0'),                0,                'zero';
is value_of('999999999999999'),  999999999999999,  'the largest integer';
is value_of('-999999999999999'), -999999999999999, 'the smallest integer';

ok !eval { parse_item('1000000000000000'); 1 },
    'RFC 9651 allows at most 15 digits';

# --- decimals --------------------------------------------------------------

{
    my $item = parse_item('1.001');

    is $item->[0], SFPARSE_TYPE_DECIMAL, 'decimals';
    is $item->[1], 1.001, 'as a Perl number';
}

is [ map { parse_item($_)->[1] } '4.5', '-1.5', '0.0', '1.100' ],
    [ 4.5, -1.5, 0, 1.1 ],
    'decimal values';

# RFC 9651 allows at most twelve digits before the point and three after, so
# every legal decimal times a thousand is a whole number below 2**53 and the
# double carries it exactly.
is sprintf( '%.3f', parse_item('999999999999.999')->[1] ),
    '999999999999.999', 'the largest legal decimal is still exact';

is sprintf( '%.3f', parse_item('-999999999999.999')->[1] ),
    '-999999999999.999', 'and the smallest';

ok !eval { parse_item('1.0010'); 1 },
    'RFC 9651 allows at most 3 fractional digits';

# --- strings ---------------------------------------------------------------

is type_of('"foo"'), SFPARSE_TYPE_STRING, 'strings';
is value_of('""'), '', 'an empty string';
is value_of('"a\"b\\\\c"'), 'a"b\\c', 'escapes are removed';
is value_of('"\\\\"'), '\\', 'a lone escaped backslash';
ok !utf8::is_utf8( value_of('"foo"') ), 'strings come back as bytes';

ok !eval { parse_item('"unterminated'); 1 }, 'an unterminated string';
ok !eval { parse_item(qq{"tab\there"}); 1 },
    'strings hold printable ASCII only';

# --- tokens ----------------------------------------------------------------

is type_of('foo'), SFPARSE_TYPE_TOKEN, 'tokens';
is value_of('*foo'),  '*foo',  'a token may start with *';
is value_of('a/b:c'), 'a/b:c', 'a token may contain / and :';
ok !eval { parse_item('1foo'); 1 }, 'a token may not start with a digit';

# --- byte sequences --------------------------------------------------------

is type_of(':aGVsbG8=:'), SFPARSE_TYPE_BYTESEQ, 'byte sequences';
is value_of(':aGVsbG8=:'), 'hello', 'decoded, not Base64';
is value_of('::'), '', 'an empty byte sequence';

{
    my $bytes = value_of(':w6k=:');

    is length $bytes, 2, 'a byte sequence may hold non-ASCII bytes';
    is $bytes, "\xc3\xa9", 'returned as the bytes themselves';
    ok !utf8::is_utf8($bytes), 'without being decoded as text';
}

ok !eval { parse_item(':a:'); 1 }, 'invalid Base64 is a parse error';

# --- dates -----------------------------------------------------------------

is type_of('@1659578233'), SFPARSE_TYPE_DATE, 'dates';
is value_of('@1659578233'), 1659578233, 'as seconds since the epoch';
is value_of('@0'),          0,          'the epoch itself';
is value_of('@-1000'),      -1000,      'and before it';
ok !eval { parse_item('@1.5'); 1 }, 'a date is not a decimal';

# --- display strings -------------------------------------------------------

{
    is type_of('%"a b"'), SFPARSE_TYPE_DISPSTRING, 'display strings';

    my $cafe = value_of('%"caf%c3%a9"');

    ok utf8::is_utf8($cafe), 'decoded to characters';
    is length $cafe, 4, 'four characters';
    is $cafe, "caf\x{e9}", 'percent-decoded from UTF-8';
}

ok !eval { parse_item('%"%c3"'); 1 },   'incomplete UTF-8 is a parse error';
ok !eval { parse_item('%"bad%"'); 1 },  'a truncated escape is a parse error';
ok !eval { parse_item('%"A%C3%A9"'); 1 },
    'RFC 9651 requires lowercase hex in display strings';

# --- inner lists -----------------------------------------------------------

is type_of('(1 2)'), SFPARSE_TYPE_INNER_LIST, 'inner lists';
is value_of('()'), [], 'an empty inner list';
ok !eval { parse_item('(())'); 1 }, 'inner lists do not nest';

done_testing;
