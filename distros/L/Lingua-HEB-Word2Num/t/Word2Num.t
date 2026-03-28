#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::HEB::Word2Num');
    $tests++;
}

use Lingua::HEB::Word2Num qw(w2n);

my $result = w2n('חמישה');
is($result, 5, 'חמישה in HEB');
$tests++;

$result = w2n(undef);
ok(!defined $result, 'undef input');
$tests++;

done_testing($tests);
