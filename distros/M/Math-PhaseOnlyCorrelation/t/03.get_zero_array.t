#!perl

use utf8;
use strict;

use Math::PhaseOnlyCorrelation;

BEGIN {
    use Test::Most tests => 4;
}

my $got;

my $test_array = [1];
$got = Math::PhaseOnlyCorrelation::_get_zero_array($#$test_array);
is_deeply( $got, [0] );

$test_array = [ 1, 2 ];
$got = Math::PhaseOnlyCorrelation::_get_zero_array($#$test_array);
is_deeply( $got, [ 0, 0 ] );

$test_array = [ 1, 2, 3 ];
$got = Math::PhaseOnlyCorrelation::_get_zero_array($#$test_array);
is_deeply( $got, [ 0, 0, 0 ] );

$test_array = [];
dies_ok { Math::PhaseOnlyCorrelation::_get_zero_array($#$test_array) };

done_testing();
