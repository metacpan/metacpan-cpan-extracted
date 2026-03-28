#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::TUR::Word2Num');
    $tests++;
}

use Lingua::TUR::Word2Num qw(w2n);

my $result = w2n('beş');
is($result, 5, 'beş in TUR');
$tests++;

$result = w2n(undef);
ok(!defined $result, 'undef input');
$tests++;

done_testing($tests);
