#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::SLK::Num2Word');
    $tests++;
}

use Lingua::SLK::Num2Word qw(num2slk_cardinal);

my $result = num2slk_cardinal(5);
is($result, 'päť', '5 in SLK');
$tests++;

$result = num2slk_cardinal(0);
ok(defined $result, '0 returns defined value');
$tests++;

done_testing($tests);
