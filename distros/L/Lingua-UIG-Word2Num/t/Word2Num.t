#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::UIG::Word2Num');
    $tests++;
}

use Lingua::UIG::Word2Num qw(w2n);

my $result = w2n('بەش');
is($result, 5, 'بەش in UIG');
$tests++;

$result = w2n(undef);
ok(!defined $result, 'undef input');
$tests++;

done_testing($tests);
