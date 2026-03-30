#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::UIG::Num2Word');
    $tests++;
}

use Lingua::UIG::Num2Word qw(num2uig_cardinal);

my $result = num2uig_cardinal(5);
is($result, 'بەش', '5 in UIG');
$tests++;

$result = num2uig_cardinal(0);
ok(defined $result, '0 returns defined value');
$tests++;

done_testing($tests);
