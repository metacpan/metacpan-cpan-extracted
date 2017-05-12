#!/usr/bin/perl

use v5.10;
use strict;
use warnings;
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Test::More tests => 1;

use ok 'Locale::CLDR';

__END__

my $locale = Locale::CLDR->new('en');
my $collation = $locale->collation;

is_deeply([$collation->sort(qw( 1 £ ৴ ))], [qw(£ ৴ 1)], 'Using CLDR root collation');
is_deeply([$collation->sort(qw(John john Fred Fréd))], [qw(Fréd Fred john John)], 'Collation with longer words');
is_deeply([$collation->sort(qw(John J Joh Jo))], [qw(J Jo Joh John)], 'Collation with sub strings');
is_deeply([$collation->sort(qw(Aé áe))], [qw(áe Aé)], 'Case and accents');

# level handling
my @sorted = (
	undef,
	['á e', 'a e', 'A e', 'Á e', 'ae', 'Áe', 'áe', 'Ae'], # Ignore accents and case
	['á e', 'Á e', 'Áe', 'áe', 'a e', 'A e', 'ae', 'Ae'], # Ignore case
	['á e', 'áe', 'a e', 'ae',  'Á e', 'Áe', 'A e', 'Ae'],
	['á e', 'áe', 'a e', 'ae',  'Á e', 'Áe', 'A e', 'Ae'],
);

foreach my $level ( 1 .. 4) {
	my $collation = $locale->collation(strength => $level);
	is_deeply([$collation->sort('á e', 'ae', 'Áe', 'a e', 'A e', 'áe', 'Ae', 'Á e')], $sorted[$level], "Sorted at level $level");
}

# Canonical Equivalence
#   ANGSTROM SIGN, LATIN CAPITAL LETTER A WITH RING ABOVE, LATIN CAPITAL LETTER A + COMBINING RING ABOVE
is_deeply([$collation->sort(qw(a Å b Å c Å d))], [qw( a Å Å Å b c d )], "Canonical equivalence");
