#!perl

use warnings;
use strict;
use 5.010;

use Test::More tests => 24;
use Lab::SCPI;

my @tests;
my $keyword = "voltage[:dc]";

push @tests, [ $keyword, 'volt',       1 ];
push @tests, [ $keyword, 'VOLT',       1 ];
push @tests, [ $keyword, ' voltage',   1 ];
push @tests, [ $keyword, 'VOLTAGE ',   1 ];
push @tests, [ $keyword, "volt:dc\t",  1 ];
push @tests, [ $keyword, 'VOLT:DC',    1 ];
push @tests, [ $keyword, 'voltage:dc', 1 ];

push @tests, [ $keyword, 'volta',  0 ];
push @tests, [ $keyword, ':volt',  0 ];
push @tests, [ $keyword, 'volt:',  0 ];
push @tests, [ $keyword, 'volt:',  0 ];
push @tests, [ $keyword, 'volt:d', 0 ];
push @tests, [ $keyword, 'volt:',  0 ];

push @tests, [ ':abc', ':ABC', 1 ];
push @tests, [ ':abc', 'ABC',  0 ];

push @tests, [ 'timer', 'timer', 1 ];
push @tests, [ 'timer', 'time',  0 ];
push @tests, [ 'timer', 'tim',   1 ];
push @tests, [ 'time',  'time',  1 ];
push @tests, [ 'time',  'tim',   0 ];

# alternation
$keyword = 'abcdef|ghijkl';
push @tests, [ $keyword, 'abcd',          1 ];
push @tests, [ $keyword, 'ghij',          1 ];
push @tests, [ $keyword, 'defghi',        0 ];
push @tests, [ $keyword, 'abcdef|ghijkl', 0 ];

for my $test (@tests) {
    my $keyword = $test->[0];
    my $header  = $test->[1];
    my $result  = $test->[2];

    is(
        scpi_match( $header, $keyword ),
        $result, "header = $header, keyword = $keyword, result = $result"
    );
}

