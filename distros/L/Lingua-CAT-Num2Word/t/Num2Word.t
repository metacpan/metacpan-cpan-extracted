#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::CAT::Num2Word');
    $tests++;
}

use Lingua::CAT::Num2Word qw(num2cat_cardinal);

my $result = num2cat_cardinal(5);
is($result, 'cinc', '5 in CAT');
$tests++;

$result = num2cat_cardinal(0);
ok(defined $result, '0 returns defined value');
$tests++;

done_testing($tests);
