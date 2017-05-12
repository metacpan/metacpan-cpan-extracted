# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 15-objcoeff.t'
use 5.010001;
use Test::Simple tests => 2;

use Math::Utils qw(:polynomial);
use Math::Complex;
use Math::BigRat;
use strict;
use warnings;

#
# Test if the polynomial functions work with coefficients that are objects.
#

#
# returns 0 (equal) or 1 (not equal). There's no -1 value, unlike other
# cmp functions.
#
sub polycmp
{
	my($p_ref1, $p_ref2) = @_;

	my @polynomial1 = @$p_ref1;
	my @polynomial2 = @$p_ref2;

	return 1 if (scalar @polynomial1 != scalar @polynomial2);

	foreach my $c1 (@polynomial1)
	{
		my $c2 = shift @polynomial2;
		return 1 if ($c1 != $c2);
	}

	return 0;
}

#
# (x + cplx(-3, 2)) * (x + cplx(3, 2)) = ?
#
my @c1x = (Math::Complex->new(-3, 2), 1);
my @c1y = (Math::Complex->new(3, 2), 1);

my @c1ans = (-13,
	Math::Complex->new(0, 4),
	1
);

my $ans_ref = pl_mult(\@c1x, \@c1y);

ok((polycmp($ans_ref, \@c1ans) == 0),
	" f() = [ " . join(", ", @c1x) . " ] * \n" .
	" f() = [ " . join(", ", @c1y) . " ] = \n" .
	" f'() = [ " . join(", ", @{$ans_ref}) . " ].\n"
);



#
# (x + cplx(-3, 2)) * (x + cplx(3, 2)) = ?
#
my @c2x = (Math::BigRat->new('3/2'), Math::BigRat->new('103/256'), 1);
my @c2y = (Math::BigRat->new('7/2'), Math::BigRat->new('103/256'), 1);

my @c2ans = (
	Math::BigRat->new('21/4'),
	Math::BigRat->new('515/256'),
	Math::BigRat->new('338289/63536'),
	Math::BigRat->new('103/128'),
	1
);

my $big_ref = pl_mult(\@c2x, \@c2y);

ok((polycmp($ans_ref, \@c1ans) == 0),
	" f() = [ " . join(", ", @c2x) . " ] * \n" .
	" f() = [ " . join(", ", @c2y) . " ] = \n" .
	" f'() = [ " . join(", ", @{$big_ref}) . " ].\n"
);


1;

