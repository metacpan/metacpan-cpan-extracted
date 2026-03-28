#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::LAV::Num2Word');
    $tests++;
}

use Lingua::LAV::Num2Word qw(num2lav_cardinal);

my $result = num2lav_cardinal(5);
is($result, 'pieci', '5 in LAV');
$tests++;

$result = num2lav_cardinal(0);
ok(defined $result, '0 returns defined value');
$tests++;

done_testing($tests);
