#!/usr/bin/perl -w

#
# test the _find_epsilon function in dbfilediff
#

use Test::More;
use Fsdb::Filter::dbfilediff;

my($test_cases) = [
        [ 'v',            'epsilon', 'sig_figs',  'exponent' ],
        [ '0.123456',      0.000001,  6,           0,           ],
	[ '123.456',       0.001,     6,           3], 
        [ '123.000',       0.001,     6,           3],
        [ '123.0',         0.1,       4,           3],
        [ '123000.',        1.0,       6,           6],
        [ '1.23e5',        1000.0,    3,           6],
        [ '0.9',           0.1,       1,           0],
        [ '0.09',          0.01,      1,           -1],
    ];
plan tests => ($#$test_cases * 3);

my(@headings);
foreach my $test_case (@$test_cases) {
    my(@case_parts) = @$test_case;
    my($v) = shift @case_parts;
    if ($v eq 'v') {
        @headings = @case_parts;
	next;
    };
    my(@trial) = Fsdb::Filter::dbfilediff::_find_epsilon($v);
    shift @trial;   # discard v
    foreach my $i (0..$#case_parts) {
       is($trial[$i], $case_parts[$i], "dbfilediff::_find_epsilon on $v, case $headings[$i]");
    };
};
