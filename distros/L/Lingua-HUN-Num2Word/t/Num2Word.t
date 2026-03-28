#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::HUN::Num2Word');
    $tests++;
}

use Lingua::HUN::Num2Word qw(num2hun_cardinal);

my $result = num2hun_cardinal(5);
is($result, 'öt', '5 in HUN');
$tests++;

$result = num2hun_cardinal(0);
ok(defined $result, '0 returns defined value');
$tests++;

done_testing($tests);
