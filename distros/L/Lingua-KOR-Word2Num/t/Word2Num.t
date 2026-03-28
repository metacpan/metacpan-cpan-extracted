#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::KOR::Word2Num');
    $tests++;
}

use Lingua::KOR::Word2Num qw(w2n);

my $result = w2n('오');
is($result, 5, '오 in KOR');
$tests++;

$result = w2n(undef);
ok(!defined $result, 'undef input');
$tests++;

done_testing($tests);
