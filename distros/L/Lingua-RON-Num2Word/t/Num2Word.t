#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::RON::Num2Word');
    $tests++;
}

use Lingua::RON::Num2Word qw(num2ron_cardinal);

my $result = num2ron_cardinal(5);
is($result, 'cinci', '5 in RON');
$tests++;

$result = num2ron_cardinal(0);
ok(defined $result, '0 returns defined value');
$tests++;

done_testing($tests);
