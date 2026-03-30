#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::SOM::Num2Word');
    $tests++;
}

use Lingua::SOM::Num2Word qw(num2som_cardinal);

my $result = num2som_cardinal(5);
is($result, 'shán', '5 in SOM');
$tests++;

$result = num2som_cardinal(0);
ok(defined $result, '0 returns defined value');
$tests++;

done_testing($tests);
