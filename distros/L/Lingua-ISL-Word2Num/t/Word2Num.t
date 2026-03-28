#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::ISL::Word2Num');
    $tests++;
}

use Lingua::ISL::Word2Num qw(w2n);

my $result = w2n('fimm');
is($result, 5, 'fimm in ISL');
$tests++;

$result = w2n(undef);
ok(!defined $result, 'undef input');
$tests++;

done_testing($tests);
