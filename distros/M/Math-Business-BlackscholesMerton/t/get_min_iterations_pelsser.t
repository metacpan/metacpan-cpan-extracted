#!/usr/bin/perl

use lib qw{ lib t/lib };
use Test::Most;
require Test::NoWarnings;
use Test::Exception;
use Math::Business::BlackScholesMerton::Binaries;
use Roundnear;

my $S         = 1.35;
my $barrier_u = 1.36;
my $barrier_l = 1.34;
my $t         = 7 / 365;
my $sigma     = 0.11;
my $r         = 0.002;
my $q         = 0.001;

my $min_iterations =
    Math::Business::BlackScholesMerton::Binaries::get_min_iterations_pelsser_1997($S, $barrier_u, $barrier_l, $t, $r, $r - $q, $sigma, 0,);
ok($min_iterations == 16, 'min_iterations (no accuracy specified)');

$min_iterations =
    Math::Business::BlackScholesMerton::Binaries::get_min_iterations_pelsser_1997($S, $barrier_u, $barrier_l, $t, $r, $r - $q, $sigma, 0, 1);
ok($min_iterations == 16, 'min_iterations (accuracy 1)');

$min_iterations =
    Math::Business::BlackScholesMerton::Binaries::get_min_iterations_pelsser_1997($S, $barrier_u, $barrier_l, $t, $r, $r - $q, $sigma, 0, -1);
ok($min_iterations == 16, 'min_iterations (accuracy 1)');

throws_ok {
    $min_iterations =
        Math::Business::BlackScholesMerton::Binaries::_get_min_iterations_ot_up_ko_down_pelsser_1997($S, $barrier_u, $barrier_l, $t, $r, $r - $q,
        $sigma, 0);
}
qr/accuracy required/, 'accuracy required';

throws_ok {
    $min_iterations =
        Math::Business::BlackScholesMerton::Binaries::_get_min_iterations_ot_up_ko_down_pelsser_1997($S, $barrier_u, $barrier_l, $t, $r, $r - $q,
        $sigma, 0, -1);
}
qr/too many iterations required/, 'too many iterations required';

$Math::Business::BlackScholesMerton::Binaries::MIN_ITERATIONS_UPORDOWN_PELSSER_1997 = -1;
$Math::Business::BlackScholesMerton::Binaries::MAX_ITERATIONS_UPORDOWN_PELSSER_1997 = -1;
$min_iterations =
    Math::Business::BlackScholesMerton::Binaries::_get_min_iterations_ot_up_ko_down_pelsser_1997($S, $barrier_u, $barrier_l, $t, $r, $r - $q, $sigma,
    0, 1);
ok($min_iterations == -1, 'min_iterations (accuracy 1)');

Test::NoWarnings::had_no_warnings();
done_testing();

