#!perl

use utf8;
use strict;

use Math::PhaseOnlyCorrelation;

BEGIN {
    use Test::More tests => 4;
}

my ( $got_length, $got_array1, $got_array2 );
my ( $test_array1, $test_array2 );

subtest 'Same array' => sub {
    $test_array1 = [ 1, 2, 3, 4 ];
    $test_array2 = [ 1, 2, 3, 4 ];
    ( $got_length, $got_array1, $got_array2 ) =
      Math::PhaseOnlyCorrelation::_adjust_array_length( $test_array1,
        $test_array2 );
    is( $got_length, 3 );
    is_deeply( $got_array1, [ 1, 2, 3, 4 ] );
    is_deeply( $got_array2, [ 1, 2, 3, 4 ] );
};

subtest 'First array is shorter' => sub {
    $test_array1 = [ 1, 2 ];
    $test_array2 = [ 1, 2, 3, 4 ];
    ( $got_length, $got_array1, $got_array2 ) =
      Math::PhaseOnlyCorrelation::_adjust_array_length( $test_array1,
        $test_array2 );
    is( $got_length, 3 );
    is_deeply( $got_array1, [ 1, 2, 0, 0 ] );
    is_deeply( $got_array2, [ 1, 2, 3, 4 ] );
};

subtest 'Second array is shorter' => sub {
    $test_array1 = [ 1, 2, 3, 4 ];
    $test_array2 = [ 1, 2 ];
    ( $got_length, $got_array1, $got_array2 ) =
      Math::PhaseOnlyCorrelation::_adjust_array_length( $test_array1,
        $test_array2 );
    is( $got_length, 3 );
    is_deeply( $got_array1, [ 1, 2, 3, 4 ] );
    is_deeply( $got_array2, [ 1, 2, 0, 0 ] );
};

subtest 'Check nondestructive' => sub {
    my $test_array1 = [ 1, 2, 3, 4 ];
    my $test_array2 = [ 1, 2 ];
    ( $got_length, $got_array1, $got_array2 ) =
      Math::PhaseOnlyCorrelation::_adjust_array_length( $test_array1,
        $test_array2 );
    is_deeply( $test_array2, [ 1, 2 ] );
    is_deeply( $got_array2, [ 1, 2, 0, 0 ] );
    $test_array1 = [ 1, 2 ];
    $test_array2 = [ 1, 2, 3, 4 ];
    ( $got_length, $got_array1, $got_array2 ) =
      Math::PhaseOnlyCorrelation::_adjust_array_length( $test_array1,
        $test_array2 );
    is_deeply( $test_array1, [ 1, 2 ] );
    is_deeply( $got_array1, [ 1, 2, 0, 0 ] );
};

done_testing();
