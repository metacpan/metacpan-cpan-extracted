#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::HEB::Num2Word');
    $tests++;
}

use Lingua::HEB::Num2Word qw(num2heb_cardinal);

my $result = num2heb_cardinal(5);
is($result, 'חמישה', '5 in HEB');
$tests++;

$result = num2heb_cardinal(0);
ok(defined $result, '0 returns defined value');
$tests++;

done_testing($tests);
