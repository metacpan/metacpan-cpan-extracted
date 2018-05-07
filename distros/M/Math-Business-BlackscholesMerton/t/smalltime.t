#!/usr/bin/perl

use lib qw{ lib t/lib };
use Test::Most;
require Test::NoWarnings;
use Math::Business::BlackScholesMerton::Binaries;
use Roundnear;

my $S       = 1.35;
my $S2      = 1.37;
my $barrier = 1.36;
my $t       = 0.5 / (60 * 60 * 24 * 365);    # 500 ms in years;
my $sigma   = 0.11;
my $r       = 0.002;
my $q       = 0.001;

my $price_call = Math::Business::BlackScholesMerton::Binaries::call($S, $barrier, $t, $r, $r - $q, $sigma);
ok($price_call == 0, 'price_call');

my $price_put = Math::Business::BlackScholesMerton::Binaries::put($S, $barrier, $t, $r, $r - $q, $sigma);
ok(roundnear(0.01, $price_put) == 1, 'price_put');

$price_call = Math::Business::BlackScholesMerton::Binaries::call($S2, $barrier, $t, $r, $r - $q, $sigma);
ok(roundnear(0.01, $price_call) == 1, 'price_call');

$price_put = Math::Business::BlackScholesMerton::Binaries::put($S2, $barrier, $t, $r, $r - $q, $sigma);
ok(roundnear(0.01, $price_put) == 0, 'price_put');

Test::NoWarnings::had_no_warnings();
done_testing();

