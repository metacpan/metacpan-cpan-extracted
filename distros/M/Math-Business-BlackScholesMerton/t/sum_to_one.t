#!/usr/bin/perl

use lib qw{ lib t/lib };
use Test::Most;
require Test::NoWarnings;
use Math::Business::BlackScholesMerton::Binaries;
use Roundnear;

my $S     = 1.35;
my $t     = 7 / 365;
my $sigma = 0.11;
my $r     = 0.002;
my $q     = 0.001;

# call + put = 1
my $price_call = Math::Business::BlackScholesMerton::Binaries::call($S, 1.36, 7 / 365, 0.002, 0.001, 0.11);
my $price_put  = Math::Business::BlackScholesMerton::Binaries::put($S, 1.36, 7 / 365, 0.002, 0.001, 0.11);

my $rounded_price_call = roundnear(0.01, $price_call);
my $rounded_price_put  = roundnear(0.01, $price_put);
ok($rounded_price_call + $rounded_price_put == 1, 'call + put = 1');

# onetouch + notouch = 1
my $price_onetouch = Math::Business::BlackScholesMerton::Binaries::onetouch($S, 1.36, 7 / 365, 0.002, 0.001, 0.11);
my $price_notouch  = Math::Business::BlackScholesMerton::Binaries::notouch($S, 1.36, 7 / 365, 0.002, 0.001, 0.11);

my $rounded_price_onetouch = roundnear(0.01, $price_onetouch);
my $rounded_price_notouch  = roundnear(0.01, $price_notouch);
ok($rounded_price_onetouch + $rounded_price_notouch == 1, 'onetouch + notouch = 1');

# expiryrange + expirymiss = 1
my $price_expiryrange = Math::Business::BlackScholesMerton::Binaries::expiryrange($S, 1.36, 1.34, 7 / 365, 0.002, 0.001, 0.11);
my $price_expirymiss  = Math::Business::BlackScholesMerton::Binaries::expirymiss($S, 1.36, 1.34, 7 / 365, 0.002, 0.001, 0.11);

my $rounded_price_expiryrange = roundnear(0.01, $price_expiryrange);
my $rounded_price_expirymiss  = roundnear(0.01, $price_expirymiss);
ok($rounded_price_expiryrange + $rounded_price_expirymiss == 1, 'expiryrange + expirymiss = 1');

# range + upordown = 1
my $price_range    = Math::Business::BlackScholesMerton::Binaries::range($S, 1.36, 1.34, 7 / 365, 0.002, 0.001, 0.11);
my $price_upordown = Math::Business::BlackScholesMerton::Binaries::upordown($S, 1.36, 1.34, 7 / 365, 0.002, 0.001, 0.11);

my $rounded_price_range    = roundnear(0.01, $price_range);
my $rounded_price_upordown = roundnear(0.01, $price_upordown);
ok($rounded_price_range + $rounded_price_upordown == 1, 'range + upordown = 1');

Test::NoWarnings::had_no_warnings();
done_testing();

