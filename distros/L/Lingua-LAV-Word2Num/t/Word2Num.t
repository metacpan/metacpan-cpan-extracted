#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::LAV::Word2Num');
    $tests++;
}

use Lingua::LAV::Word2Num qw(w2n);

my $result = w2n('pieci');
is($result, 5, 'pieci in LAV');
$tests++;

$result = w2n(undef);
ok(!defined $result, 'undef input');
$tests++;

done_testing($tests);
