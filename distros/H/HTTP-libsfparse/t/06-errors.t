#!perl

use strict;
use warnings;

use Test2::V0;

use HTTP::libsfparse qw( parse_item parse_list parse_dictionary :types );

# Field values come off the network, so callers are expected to catch these.

{
    my $ok = eval { parse_list('a, b, "unterminated'); 1 };

    ok !$ok, 'malformed input throws';
    like $@, qr/^HTTP::libsfparse: parse error at offset \d+ at /,
        'the message names the offset and the caller';
}

# The offset points at where parsing stopped.
{
    eval { parse_dictionary('a=1, b=!') };
    like $@, qr/offset 7/, 'offset of the bad character';

    eval { parse_item('') };
    like $@, qr/offset 0/, 'offset 0 for an empty item';
}

# Errors leave nothing behind: the same parse fails the same way twice, and
# the process keeps working afterwards.
for ( 1 .. 3 ) {
    ok !eval { parse_dictionary('a=1, b=!'); 1 }, 'repeatable failure';
}

is parse_dictionary('a=1'),
    [ [ 'a', [ SFPARSE_TYPE_INTEGER, 1, [] ] ] ],
    'parsing still works after a failure';

# Bad arguments are told apart from bad field values.

ok !eval { parse_item(undef); 1 }, 'undef input throws';
like $@, qr/input is undefined/, '... saying the input was undef';

ok !eval { parse_item("caf\x{e9}\x{2603}"); 1 }, 'wide characters throw';
like $@, qr/must be a byte string/, '... saying the input must be bytes';

# The parsers take the field value and nothing else.

ok !eval { parse_item( 'foo', 'nonsense' => 1 ); 1 },
    'a second argument throws';
like $@, qr/^Usage: HTTP::libsfparse::parse_item\(input\)/,
    '... with the usage message';

# Input that is not a string is stringified, as everywhere else in Perl.
is parse_item(42), [ SFPARSE_TYPE_INTEGER, 42, [] ],
    'a number is stringified';

done_testing;
