#!perl

use strict;
use warnings;

use Test2::V0;

use HTTP::libsfparse qw( parse_item parse_dictionary :types );

# Parameters are [ key, item ] pairs in field order.

is parse_item('foo; a;b=?0;c=1;d="s";e=:aGk=:;f=4.5')->[2],
    [
        [ 'a', [ SFPARSE_TYPE_BOOLEAN, 1,   undef ] ],
        [ 'b', [ SFPARSE_TYPE_BOOLEAN, 0,   undef ] ],
        [ 'c', [ SFPARSE_TYPE_INTEGER, 1,   undef ] ],
        [ 'd', [ SFPARSE_TYPE_STRING,  's', undef ] ],
        [ 'e', [ SFPARSE_TYPE_BYTESEQ, 'hi', undef ] ],
        [ 'f', [ SFPARSE_TYPE_DECIMAL, 4.5, undef ] ],
    ],
    'every bare item type works as a parameter value';

is parse_item('foo;   a=1')->[2],
    [ [ 'a', [ SFPARSE_TYPE_INTEGER, 1, undef ] ] ],
    'spaces are allowed after the semicolon';

ok !defined parse_item('foo;a')->[2][0][1][2],
    'parameter values have no parameters of their own';

is parse_item('foo')->[2], [],
    'an item without parameters has an empty parameter list';

# Repeated keys are kept, as in a dictionary.
is parse_item('foo;a=1;a=2')->[2],
    [
        [ 'a', [ SFPARSE_TYPE_INTEGER, 1, undef ] ],
        [ 'a', [ SFPARSE_TYPE_INTEGER, 2, undef ] ],
    ],
    'a repeated parameter is reported each time it appears';

{
    my %params = map { $_->[0] => $_->[1] } @{ parse_item('foo;a=1;a=2')->[2] };

    is $params{a}[1], 2, 'and collapsing the pairs keeps the last value';
}

# Keys may hold the full RFC 9651 key character set.
is [ map { $_->[0] } @{ parse_item('foo;a1;b_;*c;d-e;f.g')->[2] } ],
    [ 'a1', 'b_', '*c', 'd-e', 'f.g' ],
    'parameter keys may contain digits, _, *, - and .';

# Parameters sit on the member, not on the dictionary.
{
    my $dict = parse_dictionary('a=1;x=1, b=2;y=2');

    is [ map { $_->[0] } @{ $dict->[0][1][2] } ], ['x'], 'a has x';
    is [ map { $_->[0] } @{ $dict->[1][1][2] } ], ['y'], 'b has y';
}

for my $bad ( 'foo;', 'foo;;a', 'foo;A=1', 'foo;a=', 'foo;=1', 'foo;_a' ) {
    ok !eval { parse_item($bad); 1 }, "bad parameters: '$bad'";
}

done_testing;
