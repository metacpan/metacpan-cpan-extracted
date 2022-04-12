#!/usr/bin/perl
# Do not normalise this test file. It has deliberately unnormalised characters in it.
use v5.10;
use strict;
use warnings;
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Test::More tests => 359;

use ok 'Locale::CLDR';

my $locale = Locale::CLDR->new('cy_GB');

#                   0    1   2   3   4     5     7       8 .. 199        
my @results = (qw( zero one two few other other many),('other') x 193);

for (my $count = 0; $count < @results; $count++) {
	is ($locale->plural($count), $results[$count], "Plural for $count in Welsh");
}

@results = ( #                                     one - two                          two - few
	qw (other one two few many), ( 'other' ) x 3, qw( two few many ), ('other') x 4, qw( few many),
#                   few - many            other - one
	('other') x 5, qw(many), ('other') x 8, qw(one two few many other)
);

my $count = 0;
foreach my $start (qw(zero one two few many other)) {
	foreach my $end (qw(zero one two few many other)) {
		is ($locale->plural_range($start, $end), $results[$count++], "Plural range $start - $end in Welsh");
	}
}
#                                                     0-6               0-10
@results = ((qw(other one two few ), ('other') x 2, qw(many), ('other') x 4 ) x 11);
@results[12, 23, 24, 34 .. 36, 67 .. 69, 72] = ('other') x 10;
$count = 0;
foreach my $start (0 .. 10) {
	foreach my $end (0 .. 10) {
		is ($locale->plural_range($start, $end), $results[$count++], "Plural range $start - $end in Welsh");
	}
}

is ($locale->plural_range(2.73, 6.43), 'other', "Plural range 2.73 - 6.43 in Welsh");