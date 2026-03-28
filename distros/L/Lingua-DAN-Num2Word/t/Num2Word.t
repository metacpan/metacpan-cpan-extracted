#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::DAN::Num2Word');
    $tests++;
}

use Lingua::DAN::Num2Word qw(num2dan_cardinal);

my $result = num2dan_cardinal(5);
is($result, 'fem', '5 in DAN');
$tests++;

$result = num2dan_cardinal(0);
ok(defined $result, '0 returns defined value');
$tests++;

done_testing($tests);
