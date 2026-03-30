#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::SOM::Word2Num');
    $tests++;
}

use Lingua::SOM::Word2Num qw(w2n);

my $result = w2n('shán');
is($result, 5, 'shán in SOM');
$tests++;

$result = w2n(undef);
ok(!defined $result, 'undef input');
$tests++;

done_testing($tests);
