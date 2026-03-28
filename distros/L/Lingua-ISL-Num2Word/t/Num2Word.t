#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::ISL::Num2Word');
    $tests++;
}

use Lingua::ISL::Num2Word qw(num2isl_cardinal);

my $result = num2isl_cardinal(5);
is($result, 'fimm', '5 in ISL');
$tests++;

$result = num2isl_cardinal(0);
ok(defined $result, '0 returns defined value');
$tests++;

done_testing($tests);
