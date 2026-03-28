#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::VIE::Word2Num');
    $tests++;
}

use Lingua::VIE::Word2Num qw(w2n);

my $result = w2n('năm');
is($result, 5, 'năm in VIE');
$tests++;

$result = w2n(undef);
ok(!defined $result, 'undef input');
$tests++;

done_testing($tests);
