#!perl

use utf8;
use strict;

use Math::FFT;
use Math::PhaseOnlyCorrelation;

BEGIN {
    use Test::Most tests => 4;
}

my ( $array1,     $array2,     $result );
my ( $array1_fft, $array2_fft, $result_fft );
my $got;

subtest 'Correlation same signal' => sub {
    $array1 = [ 1, 0, 2, 0, 3, 0, 4, 0, 5, 0, 6, 0, 7, 0, 8, 0 ];
    $array2 = [ 1, 0, 2, 0, 3, 0, 4, 0, 5, 0, 6, 0, 7, 0, 8, 0 ];
    $array1_fft = Math::FFT->new($array1);
    $array2_fft = Math::FFT->new($array2);
    $result =
      Math::PhaseOnlyCorrelation::poc_without_fft( $array1_fft->cdft(),
        $array2_fft->cdft() );
    $result_fft = Math::FFT->new($result);
    $got        = $result_fft->invcdft($result);
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
    $array2 = [ 1, 0, -2, 0, 3, 0, -4, 0, 5, 0, -6, 0, 7, 0, -8, 0 ];
    $array2_fft = Math::FFT->new($array2);
    $result =
      Math::PhaseOnlyCorrelation::poc_without_fft( $array1_fft->cdft(),
        $array2_fft->cdft() );
    $result_fft = Math::FFT->new($result);
    $got        = $result_fft->invcdft($result);
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
    $array2 = [ 1.1, 0, 2, 0, 3.3, 0, 4, 0, 5.5, 0, 6, 0, 7.7, 0, 8, 0 ];
    $array2_fft = Math::FFT->new($array2);
    $result =
      Math::PhaseOnlyCorrelation::poc_without_fft( $array1_fft->cdft(),
        $array2_fft->cdft() );
    $result_fft = Math::FFT->new($result);
    $got        = $result_fft->invcdft($result);
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

subtest 'Give different length and die' => sub {
    $array2 = [ 1, 0, 2, 0, 3, 0, 4, 0 ];
    $array2_fft = Math::FFT->new($array2);
    dies_ok {
        Math::PhaseOnlyCorrelation::poc_without_fft( $array1_fft->cdft(),
            $array2_fft->cdft() );
    };
};

done_testing();
