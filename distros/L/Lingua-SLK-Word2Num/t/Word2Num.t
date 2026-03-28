#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::SLK::Word2Num');
    $tests++;
}

use Lingua::SLK::Word2Num qw(w2n);

my $result = w2n('päť');
is($result, 5, 'päť in SLK');
$tests++;

$result = w2n(undef);
ok(!defined $result, 'undef input');
$tests++;

done_testing($tests);
