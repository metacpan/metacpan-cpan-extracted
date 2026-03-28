#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::CAT::Word2Num');
    $tests++;
}

use Lingua::CAT::Word2Num qw(w2n);

my $result = w2n('cinc');
is($result, 5, 'cinc in CAT');
$tests++;

$result = w2n(undef);
ok(!defined $result, 'undef input');
$tests++;

done_testing($tests);
