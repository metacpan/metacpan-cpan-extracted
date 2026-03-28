#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;

my $tests;

BEGIN {
    use_ok('Lingua::ARA::Word2Num');
    $tests++;
}

use Lingua::ARA::Word2Num qw(w2n);

my $result = w2n('خمسة');
is($result, 5, 'خمسة in ARA');
$tests++;

$result = w2n(undef);
ok(!defined $result, 'undef input');
$tests++;

done_testing($tests);
