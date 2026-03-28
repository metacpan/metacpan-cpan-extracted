#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::BUL::Num2Word');
    $tests++;
}

use Lingua::BUL::Num2Word qw(num2bul_cardinal);

my $result = num2bul_cardinal(5);
is($result, 'пет', '5 in BUL');
$tests++;

$result = num2bul_cardinal(0);
ok(defined $result, '0 returns defined value');
$tests++;

done_testing($tests);
