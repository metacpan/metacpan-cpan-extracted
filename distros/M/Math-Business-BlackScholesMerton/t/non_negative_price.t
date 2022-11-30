#!/usr/bin/perl

use lib qw{ lib t/lib };
use Test::Most;
require Test::NoWarnings;
use Math::Business::BlackScholesMerton::Binaries;
use Roundnear;

my $S     = 100;
my $H2    = 104;
my $H1    = 95;
my $K     = 4;
my $tiy   = (60 * 60) / (60 * 60 * 24 * 365);    # 1 hour in years;
my $sigma = 0.40;
my $mu    = 0;
my $type  = 'c';

my $price_abko = Math::Business::BlackScholesMerton::Binaries::americanknockout($S, $H2, $H1, $K, $tiy, $sigma, $mu, $type);
ok($price_abko == 0, 'return 0 for negative values');

$tiy = 1;

$price_abko = Math::Business::BlackScholesMerton::Binaries::americanknockout($S, $H2, $H1, $K, $tiy, $sigma, $mu, $type);
ok(roundnear(0.01, $price_abko) == 2.22, 'price abko');

Test::NoWarnings::had_no_warnings();
done_testing();
