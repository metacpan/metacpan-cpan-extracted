#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::SWA::Num2Word');
    $tests++;
}

use Lingua::SWA::Num2Word qw(num2swa_cardinal);

my $result = num2swa_cardinal(5);
is($result, 'tano', '5 in SWA');
$tests++;

$result = num2swa_cardinal(0);
ok(defined $result, '0 returns defined value');
$tests++;

done_testing($tests);
