#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::FIN::Word2Num');
    $tests++;
}

use Lingua::FIN::Word2Num qw(w2n);

my $result = w2n('viisi');
is($result, 5, 'viisi in FIN');
$tests++;

$result = w2n(undef);
ok(!defined $result, 'undef input');
$tests++;

done_testing($tests);
