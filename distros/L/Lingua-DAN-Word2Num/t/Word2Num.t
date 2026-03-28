#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::DAN::Word2Num');
    $tests++;
}

use Lingua::DAN::Word2Num qw(w2n);

my $result = w2n('fem');
is($result, 5, 'fem in DAN');
$tests++;

$result = w2n(undef);
ok(!defined $result, 'undef input');
$tests++;

done_testing($tests);
