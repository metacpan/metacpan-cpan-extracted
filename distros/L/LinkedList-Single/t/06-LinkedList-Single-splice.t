
use v5.12;

use Test::More;
use Test::Deep;

my $class   = 'LinkedList::Single';

my @valz    = ( 1 .. 9 );

plan tests => 3;

use_ok $class;

my $listh   = $class->new( @valz );

$listh      += 3;

my $snip    = $listh->splice( 3 );

cmp_deeply
(
    $snip->head_node,
    [
        [
            [
                [],
                7
            ],
            6
        ],
        5
    ],
    "Snip contains 5,6,7"
);

cmp_deeply
(
    $listh->head_node,
    [
        [
            [
                [
                    [
                        [
                            [],
                            9
                        ],
                        8
                    ],
                    4
                ],
                3
            ],
            2
        ],
        1
    ],
    "List has 1,2,3,4,8,9"
);

# this is not a module

0

__END__
