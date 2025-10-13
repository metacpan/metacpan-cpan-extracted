#! perl

use v5.28;
use Test2::V0;

use Iterator::Flex::Common 'iseq';
use Scalar::Util 'refaddr';

use experimental 'declared_refs';

subtest 'return' => sub {

    my $iter = iseq( 20, { exhaustion => 'return' } );

    my \@values = $iter->drain;

    is( $iter->is_exhausted, T(),         'exhausted' );
    is( \@values,            [ 0 .. 20 ], 'values' );

};

subtest 'throw' => sub {

    my $iter = iseq( 20, { exhaustion => 'throw' } );

    my \@values = $iter->drain;

    is( $iter->is_exhausted, T(),         'exhausted' );
    is( \@values,            [ 0 .. 20 ], 'values' );

};

done_testing;
