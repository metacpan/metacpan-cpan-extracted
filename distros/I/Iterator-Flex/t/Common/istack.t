#! perl

use Test2::V0;
use Iterator::Flex::Common 'iseq', 'istack';
use experimental 'signatures';


my $iter = istack();

$iter->push( iseq( 1, 10 ) );
is( $iter->next, 1 );

$iter->unshift( iseq( 11, 20 ) );
is( $iter->next, 11 );

my $tmp = $iter->pop;

is( $tmp->next, 2 );
is( $tmp->current, 2 );

$iter->unshift( $tmp );

is ( $iter->next, 3 );
is ( $iter->current, 3 );
is ( $iter->prev, 11 );


$tmp = $iter->shift;

is ( $iter->next, 12 );
is ( $iter->current, 12 );
is ( $iter->prev, 3 );

$iter->push( $tmp );

is ( $iter->next, 13 );
is ( $iter->current, 13 );
is ( $iter->prev, 12 );

my @rest = map { $iter->next } 1.. 7 + 7;

is ( \@rest, [ 14..20, 4..10 ] );

is( $iter->next, U() );
is( $iter->is_exhausted, T() );

done_testing;
