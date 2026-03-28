#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::FRA::Numbers');
    $tests++;
}

use Lingua::FRA::Numbers qw(number_to_fr);

my $result = number_to_fr(42);
is($result, 'quarante-deux', '42 in French');
$tests++;

done_testing($tests);
