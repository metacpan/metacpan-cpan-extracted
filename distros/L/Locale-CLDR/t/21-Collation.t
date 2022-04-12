#!/usr/bin/perl

use v5.10;
use strict;
use warnings;
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Test::More tests => 10;

use ok 'Locale::CLDR';

my $locale = Locale::CLDR->new('en');
my $collation = $locale->collation;

is_deeply([$collation->sort('1', "\x{00A3}", "\x{09F4}")], ["\x{00A3}", "\x{09F4}", 1], 'Using CLDR root collation');
is_deeply([$collation->sort(qw(John john Fred ), "Fr\x{00E9}d")], ["Fred", "Fr\x{E9}d", qw( john John)], 'Collation with longer words');
is_deeply([$collation->sort(qw(John J Joh Jo))], [qw(J Jo Joh John)], 'Collation with sub strings');
is_deeply([$collation->sort("\x{00E1}e", "A\x{00E9}" )], ["A\x{00E9}", "\x{00E1}e"], 'Case and accents');

# level handling
my @sorted = (
	undef,
	['á e', 'a e', 'A e', 'Á e', 'ae', 'Áe', 'áe', 'Ae' ], # Ignore accents and case
	['a e', 'A e', 'á e', 'Á e', 'ae', 'Ae', 'Áe', 'áe' ], # Ignore case
	['a e', 'A e', 'á e', 'Á e', 'ae', 'Ae', 'áe', 'Áe' ],
	['a e', 'A e', 'á e', 'Á e', 'ae', 'Ae', 'áe', 'Áe' ],
);

foreach my $level ( 1 .. 4) {
	my $collation = $locale->collation(strength => $level);
	is_deeply([$collation->sort('á e', 'ae', 'Áe', 'a e', 'A e', 'áe', 'Ae', 'Á e')], $sorted[$level], "Sorted at level $level");
}

# Canonical Equivalence
#   ANGSTROM SIGN, LATIN CAPITAL LETTER A WITH RING ABOVE, LATIN CAPITAL LETTER A + COMBINING RING ABOVE
is_deeply([$collation->sort(qw(a Å b Å c Å d))], [qw( a Å Å Å b c d )], "Canonical equivalence");
