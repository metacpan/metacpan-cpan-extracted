#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::LIT::Word2Num');
    $tests++;
}

use Lingua::LIT::Word2Num qw(w2n);

my $result = w2n('penki');
is($result, 5, 'penki in LIT');
$tests++;

$result = w2n(undef);
ok(!defined $result, 'undef input');
$tests++;

done_testing($tests);
