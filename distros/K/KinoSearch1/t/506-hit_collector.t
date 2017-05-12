use strict;
use warnings;

use Test::More tests => 4;

BEGIN { use_ok('KinoSearch1::Search::HitCollector') }

my @docs_and_scores = ( [ 0, 2 ], [ 5, 0 ], [ 10, 0 ], [ 1000, 1 ] );

my $hc = KinoSearch1::Search::HitQueueCollector->new( size => 3, );
$hc->collect( $_->[0], $_->[1] ) for @docs_and_scores;

my $hit_queue = $hc->get_storage;
isa_ok( $hit_queue, 'KinoSearch1::Search::HitQueue' );

my @scores = map { $_->get_score } @{ $hit_queue->hits };
is_deeply( \@scores, [ 2, 1, 0 ], "collect into HitQueue" );

$hc = KinoSearch1::Search::BitCollector->new;
$hc->collect( $_->[0], $_->[1] ) for @docs_and_scores;
is_deeply(
    $hc->get_bit_vector()->to_arrayref,
    [ 0, 5, 10, 1000 ],
    "BitCollector produces a valid BitVector with the right doc nums"
);

