#!/usr/bin/perl
# Do not normalise this test file. It has deliberately unnormalised characters in it.
use v5.10;
use strict;
use warnings;
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Test::More tests => 359;

use ok 'Locale::CLDR';

my $locale = Locale::CLDR->new('br_FR');

#                    0    1   2   3   4        5 .. 8       9     10 .. 19
my @results = ((qw( other one two few few), ('other') x 4, 'few', ('other') x 10),
#    20    21  22  23  24       25 .. 28     29  30 .. 69
(qw(other one two few few), ('other') x 4, 'few') x 5,
#    70 .. 79             80   81  82  83  84      85 .. 88      89    90 .. 129 
((qw( other )) x 10, (qw(other one two few few), ('other') x 4, 'few')) x 3,
#     130  131 132 133 134       135 .. 138  139          140 141 142 143 144      145 .. 148   149  150 .. 169 
((qw(other one two few few), ('other') x 4, 'few'), (qw(other one two few few), ('other') x 4, 'few')) x 2,
#    170 .. 179           180  181 182 183 184      185 .. 188   189
(qw( other )) x 10, (qw(other one two few few), ('other') x 4, 'few'),
# 190 .. 199
('other') x 10
);

for (my $count = 0; $count < @results; $count++) {
	is ($locale->plural($count), $results[$count], "Plural for $count in Breton");
}

@results = (('other') x 66);
my $count = 0;
foreach my $start (qw(zero one two few many other)) {
	foreach my $end (qw(zero one two few many other)) {
		is ($locale->plural_range($start, $end), $results[$count++], "Plural range $start - $end in Breton");
	}
}

@results = ('other') x 121;
$count = 0;
foreach my $start (0 .. 10) {
	foreach my $end (0 .. 10) {
		is ($locale->plural_range($start, $end), $results[$count++], "Plural range $start - $end in Breton");
	}
}

is ($locale->plural_range(2.73, 6.43), 'other', "Plural range 2.73 - 6.43 in Breton");