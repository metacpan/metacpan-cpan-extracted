#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::EST::Word2Num');
    $tests++;
}

use Lingua::EST::Word2Num qw(w2n);

my $result = w2n('viis');
is($result, 5, 'viis in EST');
$tests++;

$result = w2n(undef);
ok(!defined $result, 'undef input');
$tests++;

done_testing($tests);
