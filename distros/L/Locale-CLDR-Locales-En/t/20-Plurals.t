#!/usr/bin/perl
# Do not normalise this test file. It has deliberately unnormalised characters in it.
use v5.10;
use strict;
use warnings;
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Test::More tests => 359;

use ok 'Locale::CLDR';

my $locale = Locale::CLDR->new('en_GB');

#                       0    1        2 .. 199
my @results = (qw( other one), ('other') x 198);

for (my $count = 0; $count < @results; $count++) {
	is ($locale->plural($count), $results[$count], "Plural for $count in en");
}

@results = (('other') x 66);
my $count = 0;
foreach my $start (qw(zero one two few many other)) {
	foreach my $end (qw(zero one two few many other)) {
		is ($locale->plural_range($start, $end), $results[$count++], "Plural range $start - $end in en");
	}
}

@results = ('other') x 121;
$count = 0;
foreach my $start (0 .. 10) {
	foreach my $end (0 .. 10) {
		is ($locale->plural_range($start, $end), $results[$count++], "Plural range $start - $end in en");
	}
}

is ($locale->plural_range(2.73, 6.43), 'other', "Plural range 2.73 - 6.43 in en");