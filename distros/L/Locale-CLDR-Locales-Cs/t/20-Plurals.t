#!/usr/bin/perl
# Do not normalise this test file. It has deliberately unnormalised characters in it.
use v5.10;
use strict;
use warnings;
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Test::More tests => 359;

use ok 'Locale::CLDR';

my $locale = Locale::CLDR->new('cs_CZ');

#                   0    1        2 .. 4        5 .. 199
my @results = (qw( other one ), ('few') x 3, ('other') x 195);

for (my $count = 0; $count < @results; $count++) {
	is ($locale->plural($count), $results[$count], "Plural for $count in Czech");
}

#                               one - many 
@results = (('other') x 9, qw( few many ), ('other') x 10, qw(few many), 'other', ( qw(other one other few many other) ) x 2);
my $count = 0;
foreach my $start (qw(zero one two few many other)) {
	foreach my $end (qw(zero one two few many other)) {
		is ($locale->plural_range($start, $end), $results[$count++], "Plural range $start - $end in Czech");
	}
}

#             0-0      0-1    0-4            1-1           1-4                              5-0     5-1     5-4          5-9
@results = ('other', 'one', ('few') x 3, (('other') x 8, ('few') x 3) x 4, ('other') x 6, ('other', 'one', ('few') x 3, ('other') x 6) x 6);
$count = 0;
foreach my $start (0 .. 10) {
	foreach my $end (0 .. 10) {
		is ($locale->plural_range($start, $end), $results[$count++], "Plural range $start - $end in Czech");
	}
}

is ($locale->plural_range(2.73, 6.43), 'many', "Plural range 2.73 - 6.43 in cs");