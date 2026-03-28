#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::FIN::Num2Word');
    $tests++;
}

use Lingua::FIN::Num2Word qw(num2fin_cardinal);

my $result = num2fin_cardinal(5);
is($result, 'viisi', '5 in FIN');
$tests++;

$result = num2fin_cardinal(0);
ok(defined $result, '0 returns defined value');
$tests++;

done_testing($tests);
