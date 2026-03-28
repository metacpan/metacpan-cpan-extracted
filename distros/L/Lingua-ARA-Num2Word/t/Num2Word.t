#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::ARA::Num2Word');
    $tests++;
}

use Lingua::ARA::Num2Word qw(num2ara_cardinal);

my $result = num2ara_cardinal(5);
is($result, 'خمسة', '5 in ARA');
$tests++;

$result = num2ara_cardinal(0);
ok(defined $result, '0 returns defined value');
$tests++;

done_testing($tests);
