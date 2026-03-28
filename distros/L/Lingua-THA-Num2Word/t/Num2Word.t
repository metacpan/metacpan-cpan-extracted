#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::THA::Num2Word');
    $tests++;
}

use Lingua::THA::Num2Word qw(num2tha_cardinal);

my $result = num2tha_cardinal(5);
is($result, 'ห้า', '5 in THA');
$tests++;

$result = num2tha_cardinal(0);
ok(defined $result, '0 returns defined value');
$tests++;

done_testing($tests);
