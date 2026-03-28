#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::TUR::Num2Word');
    $tests++;
}

use Lingua::TUR::Num2Word qw(num2tur_cardinal);

my $result = num2tur_cardinal(5);
is($result, 'beş', '5 in TUR');
$tests++;

$result = num2tur_cardinal(0);
ok(defined $result, '0 returns defined value');
$tests++;

done_testing($tests);
