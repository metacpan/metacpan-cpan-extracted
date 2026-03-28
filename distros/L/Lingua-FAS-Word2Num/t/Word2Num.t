#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::FAS::Word2Num');
    $tests++;
}

use Lingua::FAS::Word2Num qw(w2n);

my $result = w2n('پنج');
is($result, 5, 'پنج in FAS');
$tests++;

$result = w2n(undef);
ok(!defined $result, 'undef input');
$tests++;

done_testing($tests);
