#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::ELL::Word2Num');
    $tests++;
}

use Lingua::ELL::Word2Num qw(w2n);

my $result = w2n('πέντε');
is($result, 5, 'πέντε in ELL');
$tests++;

$result = w2n(undef);
ok(!defined $result, 'undef input');
$tests++;

done_testing($tests);
