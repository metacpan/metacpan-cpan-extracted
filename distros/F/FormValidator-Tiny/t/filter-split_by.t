#!/usr/bin/perl

use v5.18;
use warnings FATAL => 'all';
use Test2::V0;

use FormValidator::Tiny qw( split_by );

like dies {
        my $foo = split_by();
    }, qr/missing string or regex/,
    'invalid split_by by causes error';

like dies {
        my $foo = split_by('', 1);
    }, qr/must be greater than 1/,
    'invalid split_by count causes error';

my $split_comma = split_by(',');
is $split_comma->("1,2,3"), [ '1', '2', '3' ], 'split_by splits';

my $split_comma_2 = split_by(',', 2);
is $split_comma_2->("1,2,3"), [ '1', '2,3' ], 'split_by with count splits up to count';

done_testing;
