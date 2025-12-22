#!/usr/bin/perl
use strict;
use warnings;
use Test::More qw( no_plan );
use Test::NoWarnings;
BEGIN { use_ok('Finance::Currency::Convert') };

use Finance::Currency::Convert;

# test object creation
my $converter = new Finance::Currency::Convert;
ok($converter, 'object creation');

# test conversion to self
is($converter->convert(456, "EUR", "EUR"), 456, 'convert EUR to self');

# test build in exchange rate
is($converter->convert(1, "EUR", "DEM"), 1.95583, 'test build in exchange rate');

# test convertFromEUR
is($converter->convert(1, "EUR", "DEM"), $converter->convertFromEUR(1, "DEM"), 'convertFromEUR');

# test convertToEUR
is($converter->convert(1, "DEM", "EUR"), $converter->convertToEUR(1, "DEM"), 'convertToEUR');

# test conversion to self
my $e = 0.0000001; # error tolerance for float comparison

my $amount7 = $converter->convertFromEUR($converter->convertToEUR(789.74, "MTL") , "MTL");
ok(abs($amount7 - 789.74) <= $e, 'convert MTL to self');

my $amount9 = $converter->convertFromEUR($converter->convertToEUR(789.74, "SKK") , "SKK");
ok(abs($amount9 - 789.74) <= $e, 'convert SKK to self');

my $amount11 = $converter->convertFromEUR($converter->convertToEUR(789.74, "EEK") , "EEK");
ok(abs($amount11 - 789.74) <= $e, 'convert EEK to self');

my $amount12 = $converter->convertFromEUR($converter->convertToEUR(789.74, "BGN") , "BGN");
ok(abs($amount12 - 789.74) <= $e, 'convert BGN to self');

my $amount14 = $converter->convertFromEUR($converter->convertToEUR(789.74, "LTL") , "LTL");
ok(abs($amount14 - 789.74) <= $e, 'convert LTL to self');

my $amount15 = $converter->convertFromEUR($converter->convertToEUR(789.74, "LVL") , "LVL");
ok(abs($amount15 - 789.74) <= $e, 'convert LVL to self');

my $amount16 = $converter->convertFromEUR($converter->convertToEUR(789.74, "HRK") , "HRK");
ok(abs($amount16 - 789.74) <= $e, 'convert HRK to self');

ok($converter->rateAvailable("DEM", "EUR"), 'rateAvailable - builtin rate');
ok(!$converter->rateAvailable("USD", "EUR"), 'rateAvailable - other rate');

# set dummy rates for testing
$converter->setRate("USD", "EUR", 0.85337);
ok($converter->rateAvailable("USD", "EUR"), 'rateAvailable - other rate');
$converter->setRate("EUR", "USD", 1.17165);
$converter->setRate("AUD", "EUR", 0.56414);
$converter->setRate("EUR", "AUD", 1.77212);
my $amount17 = $converter->convertFromEUR(1, "USD");
ok($amount17 > 0.5, 'sanity check on USD rate');
ok($amount17 < 2, 'sanity check on USD rate');
my $amount18 = $converter->convertToEUR(1, "AUD");
ok($amount18 > 0.1, 'sanity check on AUD rate');
ok($amount18 < 1, 'sanity check on AUD rate');

my $fn = '/tmp/rates.txt';
unlink($fn);
$converter->setRatesFile($fn);
is($converter->convertToEUR(1, "EUR"), 1, "make sure builtin rates still exist - EUR");
is($converter->convertToEUR(1, "DEM"), 0.511291881196, "make sure builtin rates still exist - DEM");
ok($converter->convertToEUR(1, "USD") > 0.5 , "make sure previously set rates still exist - USD");
ok($converter->convertFromEUR(1, "AUD") > 0.5 , "make sure previously set rates still exist - AUD");
$converter->writeRatesFile();
ok(-f $fn, 'writeRatesFile - file exists');
ok(-s $fn > 0, 'writeRatesFile - file is non zero');
unlink($fn) or die("Can't delete $fn");

