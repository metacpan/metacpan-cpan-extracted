#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::FAS::Num2Word');
    $tests++;
}

use Lingua::FAS::Num2Word qw(num2fas_cardinal);

my $result = num2fas_cardinal(5);
is($result, 'پنج', '5 in FAS');
$tests++;

$result = num2fas_cardinal(0);
ok(defined $result, '0 returns defined value');
$tests++;

done_testing($tests);
