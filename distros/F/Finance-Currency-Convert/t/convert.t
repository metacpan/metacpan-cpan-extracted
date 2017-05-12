#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 8;

use Finance::Currency::Convert;

# test object creation
my $converter = new Finance::Currency::Convert;
ok($converter, 'object creation');

# test conversion to self
my $amount0 = $converter->convert(456, "EUR", "EUR");
is($amount0, 456, 'convert EUR to self');

# test build in exchange rate
my $amount1 = $converter->convert(1, "EUR", "DEM");
is($amount1, 1.95583, 'test build in exchange rate');

# test convertFromEUR
my $amount2 = $converter->convert(1, "EUR", "DEM");
my $amount3 = $converter->convertFromEUR(1, "DEM");
is($amount2, $amount3, 'convertFromEUR');

# test convertToEUR
my $amount4 = $converter->convert(1, "DEM", "EUR");
my $amount5 = $converter->convertToEUR(1, "DEM");
is($amount4, $amount5, 'convertToEUR');

# test conversion to self
my $e = 0.0000001; # error tolerance for float comparison

my $amount6 = $converter->convertToEUR(456.22, "MTL");
my $amount7 = $converter->convertFromEUR($amount6, "MTL");
ok(abs($amount7 - 456.22) <= $e, 'convert MTL to self');

my $amount8 = $converter->convertToEUR(789.74, "SKK");
my $amount9 = $converter->convertFromEUR($amount8, "SKK");
ok(abs($amount9 - 789.74) <= $e, 'convert SKK to self');

my $amount10 = $converter->convertToEUR(789.74, "EEK");
my $amount11 = $converter->convertFromEUR($amount10, "EEK");
ok(abs($amount11 - 789.74) <= $e, 'convert EEK to self');

