#!perl

use strict;
use warnings;

use Test2::V0;

use HTTP::libsfparse qw( parse_item parse_dictionary :types );

# A string that happens to be stored as utf8 internally, but holds only
# bytes, is still the same field value.
{
    my $field = 'a=1, b="x"';
    utf8::upgrade($field);

    ok utf8::is_utf8($field), 'input is internally utf8';
    is parse_dictionary($field),
        [
            [ 'a', [ SFPARSE_TYPE_INTEGER, 1,   [] ] ],
            [ 'b', [ SFPARSE_TYPE_STRING,  'x', [] ] ],
        ],
        'and parses identically';
}

# Anything genuinely wide is refused rather than parsed as utf8 internals.
{
    ok !eval { parse_item("\x{263a}"); 1 }, 'a wide character is refused';
    like $@, qr/must be a byte string/, '... with an explanation';
}

# Empty and NUL-containing input.
{
    is parse_dictionary(''), [], 'the empty string';
    ok !eval { parse_item("a\0b"); 1 }, 'a NUL byte is not a valid token';
}

# Repeated use does not depend on any global state.
{
    my $bad = 0;
    for ( 1 .. 2000 ) {
        my $d = parse_dictionary('a=(1 2 3;b="foo");c;d=1, e=1.001');
        $bad++ unless $d->[1][1][1] == 1.001;
    }
    is $bad, 0, 'two thousand parses, all identical';
}

done_testing;
