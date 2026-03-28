#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::ELL::Num2Word');
    $tests++;
}

use Lingua::ELL::Num2Word qw(num2ell_cardinal);

my $result = num2ell_cardinal(5);
is($result, 'πέντε', '5 in ELL');
$tests++;

$result = num2ell_cardinal(0);
ok(defined $result, '0 returns defined value');
$tests++;

done_testing($tests);
