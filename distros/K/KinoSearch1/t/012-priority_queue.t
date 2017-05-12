use strict;
use warnings;

use Test::More tests => 7;

BEGIN { use_ok('KinoSearch1::Util::PriorityQueue') }

my $pq = KinoSearch1::Util::PriorityQueue->new( max_size => 5 );

$pq->insert($_) for ( 3, 1, 2, 20, 10 );

is( $pq->peek, 1, "peek at the least item in the queue" );

is_deeply( $pq->pop_all, [ 20, 10, 3, 2, 1 ], "pop_all sorts correctly" );

is( $pq->get_max_size, 5, "get_max_size" );

$pq->insert($_) for ( 3, 1, 2, 20, 10 );
my @prioritized;
for ( 1 .. 4 ) {
    push @prioritized, $pq->pop;
}
is( $pq->get_size, 1, "get_size" );
$pq->insert(7);
push @prioritized, $pq->pop;
is_deeply(
    \@prioritized,
    [ 1, 2, 3, 10, 7 ],
    "insert, pop, and sort correctly"
);

1 while defined $pq->pop;    # empty queue;
$pq = KinoSearch1::Util::PriorityQueue->new( max_size => 5 );
@prioritized = ();

$pq->insert($_) for ( 1 .. 10, -3, 1590 .. 1600, 5 );
push @prioritized, $pq->pop for 1 .. 5;
is_deeply( \@prioritized, [ 1596 .. 1600 ],
    "insert properly discards waste" );

1 while defined $pq->pop;    # empty queue;
@prioritized = ();

$pq->insert($_) for ( 3, 1, 2, 20, 10 );
