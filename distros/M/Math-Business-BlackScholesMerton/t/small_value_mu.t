#!/usr/bin/perl

use lib qw{ lib t/lib };
use Test::Most;
require Test::NoWarnings;
use Math::Business::BlackScholesMerton::Binaries;
use Roundnear;

my $S         = 1.35;
my $barrier_u = 1.36;
my $barrier_l = 1.34;
my $t         = 7 / 365;
my $sigma     = 0.11;
my $r         = 0.002;
my $q         = 0.001;

$Math::Business::BlackScholesMerton::Binaries::SMALL_VALUE_MU = 10;

my $c = Math::Business::BlackScholesMerton::Binaries::common_function_pelsser_1997($S, $barrier_u, $barrier_l, $t, $r, $r - $q, $sigma, 0, 0,);
ok(roundnear(0.01, $c) == 0.49, 'price_upordown');

Test::NoWarnings::had_no_warnings();
done_testing();

