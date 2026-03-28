#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::THA::Word2Num');
    $tests++;
}

use Lingua::THA::Word2Num qw(w2n);

my $result = w2n('ห้า');
is($result, 5, 'ห้า in THA');
$tests++;

$result = w2n(undef);
ok(!defined $result, 'undef input');
$tests++;

done_testing($tests);
