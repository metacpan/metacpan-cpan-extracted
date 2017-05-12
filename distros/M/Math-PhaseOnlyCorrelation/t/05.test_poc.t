#!perl

use utf8;
use strict;

use Math::PhaseOnlyCorrelation;

BEGIN {
    use Test::Most tests => 6;
}

my ( $array1, $array2, $got );

subtest 'Give different length array' => sub {
    $array1 = [ 1, 2, 3, 4 ];
    $array2 = [ 1, 2, 3, 4, 5, 6, 7, 8 ];
    lives_ok { Math::PhaseOnlyCorrelation::poc( $array1, $array2 ) };
};

subtest 'Give not 2^n length array and die' => sub {
    $array1 = [ 1, 2, 3, 4, 5 ];
    $array2 = [ 1, 2, 3, 4, 5 ];
    dies_ok { Math::PhaseOnlyCorrelation::poc( $array1, $array2 ) };
};

subtest 'Correlation same signal' => sub {
    $array1 = [ 1, 2, 3, 4, 5, 6, 7, 8 ];
    $array2 = [ 1, 2, 3, 4, 5, 6, 7, 8 ];
    $got = Math::PhaseOnlyCorrelation::poc( $array1, $array2 );
    ok(sprintf('%1.7f', $got->[0])  == sprintf('%1.7f', 1));
    ok(sprintf('%1.7f', $got->[1])  == sprintf('%1.7f', 0));
    ok(sprintf('%1.7f', $got->[2])  == sprintf('%1.7f', -3.92523114670944e-17));
    ok(sprintf('%1.7f', $got->[3])  == sprintf('%1.7f', 0));
    ok(sprintf('%1.7f', $got->[4])  == sprintf('%1.7f', 5.55111512312578e-17));
    ok(sprintf('%1.7f', $got->[5])  == sprintf('%1.7f', 0));
    ok(sprintf('%1.7f', $got->[6])  == sprintf('%1.7f', 3.92523114670944e-17));
    ok(sprintf('%1.7f', $got->[7])  == sprintf('%1.7f', 0));
    ok(sprintf('%1.7f', $got->[8])  == sprintf('%1.7f', 0));
    ok(sprintf('%1.7f', $got->[9])  == sprintf('%1.7f', 0));
    ok(sprintf('%1.7f', $got->[10]) == sprintf('%1.7f', 3.92523114670944e-17));
    ok(sprintf('%1.7f', $got->[11]) == sprintf('%1.7f', 0));
    ok(sprintf('%1.7f', $got->[12]) == sprintf('%1.7f', 5.55111512312578e-17));
    ok(sprintf('%1.7f', $got->[13]) == sprintf('%1.7f', 0));
    ok(sprintf('%1.7f', $got->[14]) == sprintf('%1.7f', -3.92523114670944e-17));
    ok(sprintf('%1.7f', $got->[15]) == sprintf('%1.7f', 0));
};

subtest 'Correlation different signal' => sub {
    $array2 = [ 1, -2, 3, -4, 5, -6, 7, -8 ];
    $got = Math::PhaseOnlyCorrelation::poc( $array1, $array2 );
    ok(sprintf('%1.7f', $got->[0])  == sprintf('%1.7f', -0.25));
    ok(sprintf('%1.7f', $got->[1])  == sprintf('%1.7f', 0));
    ok(sprintf('%1.7f', $got->[2])  == sprintf('%1.7f', 0.603553390593274));
    ok(sprintf('%1.7f', $got->[3])  == sprintf('%1.7f', 0));
    ok(sprintf('%1.7f', $got->[4])  == sprintf('%1.7f', -0.25));
    ok(sprintf('%1.7f', $got->[5])  == sprintf('%1.7f', 0));
    ok(sprintf('%1.7f', $got->[6])  == sprintf('%1.7f', 0.103553390593274));
    ok(sprintf('%1.7f', $got->[7])  == sprintf('%1.7f', 0));
    ok(sprintf('%1.7f', $got->[8])  == sprintf('%1.7f', -0.25));
    ok(sprintf('%1.7f', $got->[9])  == sprintf('%1.7f', 0));
    ok(sprintf('%1.7f', $got->[10]) == sprintf('%1.7f', -0.103553390593274));
    ok(sprintf('%1.7f', $got->[11]) == sprintf('%1.7f', 0));
    ok(sprintf('%1.7f', $got->[12]) == sprintf('%1.7f', -0.25));
    ok(sprintf('%1.7f', $got->[13]) == sprintf('%1.7f', 0));
    ok(sprintf('%1.7f', $got->[14]) == sprintf('%1.7f', -0.603553390593274));
    ok(sprintf('%1.7f', $got->[15]) == sprintf('%1.7f', 0));
};

subtest 'Correlation similar signal' => sub {
    $array2 = [ 1.1, 2, 3.3, 4, 5.5, 6, 7.7, 8 ];
    $got = Math::PhaseOnlyCorrelation::poc( $array1, $array2 );
    ok(sprintf('%1.7f', $got->[0])  == sprintf('%1.7f', 0.998032565636364));
    ok(sprintf('%1.7f', $got->[1])  == sprintf('%1.7f', 0));
    ok(sprintf('%1.7f', $got->[2])  == sprintf('%1.7f', 0.0366894970913469));
    ok(sprintf('%1.7f', $got->[3])  == sprintf('%1.7f', 0));
    ok(sprintf('%1.7f', $got->[4])  == sprintf('%1.7f', -0.0233394555681124));
    ok(sprintf('%1.7f', $got->[5])  == sprintf('%1.7f', 0));
    ok(sprintf('%1.7f', $got->[6])  == sprintf('%1.7f', 0.0106622350554301));
    ok(sprintf('%1.7f', $got->[7])  == sprintf('%1.7f', 0));
    ok(sprintf('%1.7f', $got->[8])  == sprintf('%1.7f', 0.00140150322585453));
    ok(sprintf('%1.7f', $got->[9])  == sprintf('%1.7f', 0));
    ok(sprintf('%1.7f', $got->[10]) == sprintf('%1.7f', -0.0129069223836222));
    ok(sprintf('%1.7f', $got->[11]) == sprintf('%1.7f', 0));
    ok(sprintf('%1.7f', $got->[12]) == sprintf('%1.7f', 0.0239053867058937));
    ok(sprintf('%1.7f', $got->[13]) == sprintf('%1.7f', 0));
    ok(sprintf('%1.7f', $got->[14]) == sprintf('%1.7f', -0.0344448097631548));
    ok(sprintf('%1.7f', $got->[15]) == sprintf('%1.7f', 0));
};

subtest 'Check non destructive' => sub {
    is_deeply( $array1, [ 1,   2, 3,   4, 5,   6, 7,   8 ] );
    is_deeply( $array2, [ 1.1, 2, 3.3, 4, 5.5, 6, 7.7, 8 ] );
};

done_testing();
