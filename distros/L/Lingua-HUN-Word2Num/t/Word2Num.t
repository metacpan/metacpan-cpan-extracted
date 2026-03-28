#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::HUN::Word2Num');
    $tests++;
}

use Lingua::HUN::Word2Num qw(w2n);

my $result = w2n('öt');
is($result, 5, 'öt in HUN');
$tests++;

$result = w2n(undef);
ok(!defined $result, 'undef input');
$tests++;

done_testing($tests);
