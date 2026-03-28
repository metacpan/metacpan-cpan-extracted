#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::BUL::Word2Num');
    $tests++;
}

use Lingua::BUL::Word2Num qw(w2n);

my $result = w2n('пет');
is($result, 5, 'пет in BUL');
$tests++;

$result = w2n(undef);
ok(!defined $result, 'undef input');
$tests++;

done_testing($tests);
