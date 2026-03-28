#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::SWA::Word2Num');
    $tests++;
}

use Lingua::SWA::Word2Num qw(w2n);

my $result = w2n('tano');
is($result, 5, 'tano in SWA');
$tests++;

$result = w2n(undef);
ok(!defined $result, 'undef input');
$tests++;

done_testing($tests);
