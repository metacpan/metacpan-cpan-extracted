#!perl -w

use strict;
$^W=1;
BEGIN { chdir "t" if -d "t"; }
use lib '../blib/arch', '../blib/lib';

use Test;
BEGIN { plan tests => 1, todo => [] }

my $current_market_price=10;
my $option_price_in=3;
my $strike_price_in=9;
my $remaining_term_in=0.5;
my $interest_rate=0.06;
my $fractional_yield=0.01;
my $strike_price=12;
my $remaining_term=1.5;

my @closing_prices=map { 10 } (1..10);

# Verify the SYNOPSIS of the man page:

use Math::Business::BlackScholes
  qw/call_price call_put_prices implied_volatility_call/;

my $volatility=implied_volatility_call(
  $current_market_price, $option_price_in, $strike_price_in,
  $remaining_term_in, $interest_rate, $fractional_yield
);

my $call=call_price(
  $current_market_price, $volatility, $strike_price,
  $remaining_term, $interest_rate, $fractional_yield
);

$volatility=Math::Business::BlackScholes::historical_volatility(
  \@closing_prices, 251
);

my $put=Math::Business::BlackScholes::put_price(
  $current_market_price, $volatility, $strike_price,
  $remaining_term, $interest_rate
); # $fractional_yield defaults to 0.0

my ($c, $p)=call_put_prices(
  $current_market_price, $volatility, $strike_price,
  $remaining_term, $interest_rate, $fractional_yield
);

my $call_discrete_div=call_price(
  $current_market_price, $volatility, $strike_price,
  $remaining_term, $interest_rate,
  { 0.3 => 0.35, 0.55 => 0.35 }
);

ok(1);

