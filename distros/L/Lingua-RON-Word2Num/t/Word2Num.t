#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::RON::Word2Num');
    $tests++;
}

use Lingua::RON::Word2Num qw(w2n);

my $result = w2n('cinci');
is($result, 5, 'cinci in RON');
$tests++;

$result = w2n(undef);
ok(!defined $result, 'undef input');
$tests++;

done_testing($tests);
