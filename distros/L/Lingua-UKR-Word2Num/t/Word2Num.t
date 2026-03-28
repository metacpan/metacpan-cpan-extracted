#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::UKR::Word2Num');
    $tests++;
}

use Lingua::UKR::Word2Num qw(w2n);

my $result = w2n("п'ять");
is($result, 5, "п'ять in UKR");
$tests++;

$result = w2n(undef);
ok(!defined $result, 'undef input');
$tests++;

done_testing($tests);
