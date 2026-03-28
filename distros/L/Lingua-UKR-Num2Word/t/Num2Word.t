#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::UKR::Num2Word');
    $tests++;
}

use Lingua::UKR::Num2Word qw(num2ukr_cardinal);

my $result = num2ukr_cardinal(5);
is($result, "п'ять", '5 in UKR');
$tests++;

$result = num2ukr_cardinal(0);
ok(defined $result, '0 returns defined value');
$tests++;

done_testing($tests);
