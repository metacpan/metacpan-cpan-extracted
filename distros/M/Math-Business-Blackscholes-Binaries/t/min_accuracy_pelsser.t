#!/usr/bin/perl

use lib qw{ lib t/lib };
use Test::Most;
require Test::NoWarnings;
use Math::Business::BlackScholes::Binaries;
use Roundnear;

my $S         = 1.35;
my $barrier_u = 1.36;
my $barrier_l = 1.34;
my $t         = 7 / 365;
my $sigma     = 0.11;
my $r         = 0.002;
my $q         = 0.001;

$Math::Business::BlackScholes::Binaries::MIN_ACCURACY_UPORDOWN_PELSSER_1997 = 10**10;

my $price_upordown = Math::Business::BlackScholes::Binaries::upordown($S, $barrier_u, $barrier_l, $t, $r, $r - $q, $sigma);
ok($price_upordown == 0, 'price_upordown');

Test::NoWarnings::had_no_warnings();
done_testing();

