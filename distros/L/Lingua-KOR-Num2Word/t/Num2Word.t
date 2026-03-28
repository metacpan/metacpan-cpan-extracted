#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::KOR::Num2Word');
    $tests++;
}

use Lingua::KOR::Num2Word qw(num2kor_cardinal);

my $result = num2kor_cardinal(5);
is($result, '오', '5 in KOR');
$tests++;

$result = num2kor_cardinal(0);
ok(defined $result, '0 returns defined value');
$tests++;

done_testing($tests);
