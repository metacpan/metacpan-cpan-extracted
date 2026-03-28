#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::HRV::Word2Num');
    $tests++;
}

use Lingua::HRV::Word2Num qw(w2n);

my $result = w2n('pet');
is($result, 5, 'pet in HRV');
$tests++;

$result = w2n(undef);
ok(!defined $result, 'undef input');
$tests++;

done_testing($tests);
