#!perl

use strict;
use warnings;

use Test2::V0;

use HTTP::libsfparse qw( parse_list :types );

is parse_list(''), [], 'an empty field value is an empty list';

is parse_list('gzip, br'),
    [
        [ SFPARSE_TYPE_TOKEN, 'gzip', [] ],
        [ SFPARSE_TYPE_TOKEN, 'br',   [] ],
    ],
    'a list of tokens';

is parse_list('a;q=1, b;q=0.5'),
    [
        [
            SFPARSE_TYPE_TOKEN,
            'a',
            [ [ 'q', [ SFPARSE_TYPE_INTEGER, 1, undef ] ] ],
        ],
        [
            SFPARSE_TYPE_TOKEN,
            'b',
            [ [ 'q', [ SFPARSE_TYPE_DECIMAL, 0.5, undef ] ] ],
        ],
    ],
    'list members keep their own parameters';

# The example from the libsfparse distribution.
{
    my $list = parse_list('(1 2 3;b="foo"), bar, baz;f=:aGVsbG8=:');

    is scalar @$list, 3, 'three members';
    is $list->[0][0], SFPARSE_TYPE_INNER_LIST, 'first is an inner list';
    is [ map { $_->[1] } @{ $list->[0][1] } ], [ 1, 2, 3 ],
        'with three integers';
    is $list->[0][1][2][2][0][1][1], 'foo',
        'the third of which has a string parameter';
    is $list->[1][1], 'bar', 'second member';
    is $list->[2][2][0][1][1], 'hello',
        'third member has a byte sequence parameter, decoded';
}

for my $bad ( 'a,', ',a', 'a b', '(1', '1)', 'a, ,b', '(())' ) {
    ok !eval { parse_list($bad); 1 }, "not a list: '$bad'";
}

done_testing;
