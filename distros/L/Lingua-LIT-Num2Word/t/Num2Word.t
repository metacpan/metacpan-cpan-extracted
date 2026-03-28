#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::LIT::Num2Word');
    $tests++;
}

use Lingua::LIT::Num2Word qw(num2lit_cardinal);

my $result = num2lit_cardinal(5);
is($result, 'penki', '5 in LIT');
$tests++;

$result = num2lit_cardinal(0);
ok(defined $result, '0 returns defined value');
$tests++;

done_testing($tests);
