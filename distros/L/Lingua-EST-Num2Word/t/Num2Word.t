#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::EST::Num2Word');
    $tests++;
}

use Lingua::EST::Num2Word qw(num2est_cardinal);

my $result = num2est_cardinal(5);
is($result, 'viis', '5 in EST');
$tests++;

$result = num2est_cardinal(0);
ok(defined $result, '0 returns defined value');
$tests++;

done_testing($tests);
