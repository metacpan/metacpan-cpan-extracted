#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::VIE::Num2Word');
    $tests++;
}

use Lingua::VIE::Num2Word qw(num2vie_cardinal);

my $result = num2vie_cardinal(5);
is($result, 'năm', '5 in VIE');
$tests++;

$result = num2vie_cardinal(0);
ok(defined $result, '0 returns defined value');
$tests++;

done_testing($tests);
