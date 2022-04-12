#!/usr/bin/perl
# Do not normalise this test file. It has deliberately unnormalised characters in it.
use v5.10;
use strict;
use warnings;
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Test::More tests => 359;

use ok 'Locale::CLDR';

my $locale = Locale::CLDR->new('de_DE');

#                       0    1        2 .. 199
my @results = (qw( other one), ('other') x 198);

for (my $count = 0; $count < @results; $count++) {
	is ($locale->plural($count), $results[$count], "Plural for $count in de");
}

@results = (('other') x 31, 'one', ('other') x 34);
my $count = 0;
foreach my $start (qw(zero one two few many other)) {
	foreach my $end (qw(zero one two few many other)) {
		is ($locale->plural_range($start, $end), $results[$count++], "Plural range $start - $end in de");
	}
}

@results = ('other', 'one', ('other') x 21, ('one', ('other') x 10) x 9);
$count = 0;
foreach my $start (0 .. 10) {
	foreach my $end (0 .. 10) {
		is ($locale->plural_range($start, $end), $results[$count++], "Plural range $start - $end in de");
	}
}

is ($locale->plural_range(2.73, 6.43), 'other', "Plural range 2.73 - 6.43 in de");