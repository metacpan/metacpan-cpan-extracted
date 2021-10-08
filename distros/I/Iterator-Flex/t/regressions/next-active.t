#! perl

use Test2::V0;

use Iterator::Flex::Common qw[ iarray thaw ];

my $iter = iarray( [ 0, 10 ] );

is( [ $iter->prev, $iter->current, $iter->next ], [ undef, undef, 0 ] );
is( [ $iter->prev, $iter->current, $iter->next ], [ undef, 0,     10 ] );
is( [ $iter->prev, $iter->current, $iter->next ], [ 0,     10,    undef ] );
is( [ $iter->prev, $iter->current, $iter->next ], [ 10,    undef, undef ] );
is( [ $iter->prev, $iter->current, $iter->next ], [ 10,    undef, undef ] );
is( [ $iter->prev, $iter->current, $iter->next ], [ 10,    undef, undef ] );

done_testing;
