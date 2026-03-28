#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::HRV::Num2Word');
    $tests++;
}

use Lingua::HRV::Num2Word qw(num2hrv_cardinal);

my $result = num2hrv_cardinal(5);
is($result, 'pet', '5 in HRV');
$tests++;

$result = num2hrv_cardinal(0);
ok(defined $result, '0 returns defined value');
$tests++;

done_testing($tests);
