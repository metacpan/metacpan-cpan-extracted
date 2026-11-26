#!perl

use strict;
use warnings;

use Test2::V0;

use HTTP::libsfparse qw( parse_dictionary :types );

is parse_dictionary(''), [],
    'an empty field value is an empty dictionary';

is parse_dictionary('a=1, b=2'),
    [
        [ 'a', [ SFPARSE_TYPE_INTEGER, 1, [] ] ],
        [ 'b', [ SFPARSE_TYPE_INTEGER, 2, [] ] ],
    ],
    'a dictionary of integers';

is parse_dictionary('a, b=?0'),
    [
        [ 'a', [ SFPARSE_TYPE_BOOLEAN, 1, [] ] ],
        [ 'b', [ SFPARSE_TYPE_BOOLEAN, 0, [] ] ],
    ],
    'a member without a value is boolean true';

# A dictionary is a list of pairs, so a repeated key is reported twice and it
# is the caller who decides what to do about it. RFC 9651 says the last
# occurrence wins, which is what collapsing into a hash gives you.
{
    my $dict = parse_dictionary('a=1, b=2, a=3');

    is [ map { $_->[0] } @$dict ], [ 'a', 'b', 'a' ],
        'a repeated key is reported each time it appears';

    my %dict = map { $_->[0] => $_->[1] } @$dict;

    is $dict{a}[1], 3, 'and collapsing the pairs keeps the last value';
}

is [ map { $_->[0] } @{ parse_dictionary('b=1, a=2, c=3') } ],
    [ 'b', 'a', 'c' ],
    'members come back in field order, not sorted';

# RFC 9218 Priority, the motivating example.
{
    my $pri = parse_dictionary('u=5, i');

    is $pri->[0][0], 'u', 'first key';
    is $pri->[0][1][0], SFPARSE_TYPE_INTEGER, 'u is an integer';
    is $pri->[0][1][1], 5, 'u = 5';
    is $pri->[1][0], 'i', 'second key';
    is $pri->[1][1][0], SFPARSE_TYPE_BOOLEAN, 'i is a boolean';
    is $pri->[1][1][1], 1, 'i is true';
}

# The example from the libsfparse distribution.
{
    my $dict = parse_dictionary('a=(1 2 3;b="foo");c;d=1, e=1.001');

    is [ map { $_->[0] } @$dict ], [ 'a', 'e' ], 'two members';

    my $a = $dict->[0][1];

    is $a->[0], SFPARSE_TYPE_INNER_LIST, 'a is an inner list';
    is [ map { $_->[1] } @{ $a->[1] } ], [ 1, 2, 3 ],
        'holding three integers';
    is $a->[1][2][2][0][1][1], 'foo', 'the last of which has a parameter';
    is [ map { $_->[0] } @{ $a->[2] } ], [ 'c', 'd' ],
        'the inner list has two parameters of its own';
    is $a->[2][0][1][1], 1, 'c is true';
    is $dict->[1][1][1], 1.001, 'e is a decimal';
}

for my $bad ( 'a=1,', 'A=1', '=1', 'a=', 'a==1', 'a 1', '_a=1', 'a=1;;b' ) {
    ok !eval { parse_dictionary($bad); 1 }, "not a dictionary: '$bad'";
}

done_testing;
