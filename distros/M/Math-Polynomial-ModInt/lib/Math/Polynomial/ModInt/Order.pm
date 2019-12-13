package Math::Polynomial::ModInt::Order;

use strict;
use warnings;

BEGIN {
    require Exporter;
    our @ISA = qw(Exporter);
    our @EXPORT_OK = qw($BY_INDEX $SPARSE $CONWAY);
    our %EXPORT_TAGS = ( all => \@EXPORT_OK );
    our $VERSION = '0.004';
}

sub cmp { $_[0]->(@_[1, 2])      }
sub eq  { $_[0]->(@_[1, 2]) == 0 }
sub ne  { $_[0]->(@_[1, 2]) != 0 }
sub lt  { $_[0]->(@_[1, 2]) <  0 }
sub le  { $_[0]->(@_[1, 2]) <= 0 }
sub gt  { $_[0]->(@_[1, 2]) >  0 }
sub ge  { $_[0]->(@_[1, 2]) >= 0 }

package Math::Polynomial::ModInt::Order::ByIndex;

our @ISA = (Math::Polynomial::ModInt::Order::);
$Math::Polynomial::ModInt::Order::BY_INDEX = bless \&_compare;

sub _compare ($$) {
    my ($a, $b) = @_;
    my $n = $a->degree;
    my $result =
        $a->modulus <=> $b->modulus ||
        $n          <=> $b->degree;
    while (!$result && $n >= 0) {
        $result = $a->coeff($n)->residue <=> $b->coeff($n)->residue;
        --$n;
    }
    return $result;
}

sub next_poly {
    my ($class, $poly) = @_;
    my @coeff  = $poly->coeff;
    my $one    = $poly->coeff_one;
    my $i = 0;
    {
        if ($i < @coeff) {
            $coeff[$i++] += $one or redo;
        }
        else {
            $coeff[$i] = $one;
        }
    }
    return $poly->new(@coeff);
}

package Math::Polynomial::ModInt::Order::Sparse;

our @ISA = (Math::Polynomial::ModInt::Order::);
$Math::Polynomial::ModInt::Order::SPARSE = bless \&_compare;

sub _compare ($$) {
    my ($a, $b) = @_;
    my $n = $a->proper_degree || 0;
    my $result =
        $a->modulus            <=> $b->modulus            ||
        $a->degree             <=> $b->degree             ||
        $a->coeff($n)->residue <=> $b->coeff($n)->residue ||
        $a->number_of_terms    <=> $b->number_of_terms;
    while (!$result && --$n >= 0) {
        $result = $a->coeff($n)->residue <=> $b->coeff($n)->residue;
    }
    return $result;
}

sub next_poly {
    my ($class, $poly) = @_;
    my @coeff  = $poly->coefficients;
    my $zero   = $poly->coeff_zero;
    my $one    = $poly->coeff_one;
    my $i = 0;
    my $j = 0;
    while ($i < $#coeff && $zero == $coeff[$i]) {
        ++$i;
    }
    while ($i < $#coeff && $zero == ($coeff[$i] += $one)) {
        ++$j;
        ++$i;
    }
    if ($i == $#coeff) {
        if ($j < $i) {
            ++$j;
        }
        else {
            $j = 0;
            if ($zero == ($coeff[$i] += $one)) {
                $coeff[++$i] = $one;
            }
        }
    }
    elsif ($j && $one == $coeff[$i]) {
        --$j;
    }
    while ($j > 0) {
        $coeff[--$j] = $one;
    }
    return $poly->new(@coeff);
}

package Math::Polynomial::ModInt::Order::Conway;

our @ISA = (Math::Polynomial::ModInt::Order::);
$Math::Polynomial::ModInt::Order::CONWAY = bless \&_compare;

sub _compare ($$) {
    my ($a, $b) = @_;
    my $n = $a->degree;
    my $inv = 0;
    my $result =
        $a->modulus <=> $b->modulus ||
        $n          <=> $b->degree;
    while (!$result && $n >= 0) {
        $result =
            $inv?
                (-$a->coeff($n))->residue <=> (-$b->coeff($n))->residue:
                ( $a->coeff($n))->residue <=> ( $b->coeff($n))->residue;
        --$n;
        $inv ^= 1;
    }
    return $result;
}

sub next_poly {
    my ($class, $poly) = @_;
    my @coeff  = $poly->coeff;
    my $one    = $poly->coeff_one;
    my $delta  = 1 & @coeff? $one: -$one;
    my $i = 0;
    {
        if ($i < @coeff) {
            $coeff[$i++] += $delta or $delta = -$delta, redo;
        }
        else {
            $coeff[$i] = $one;
        }
    }
    return $poly->new(@coeff);
}

1;

__END__

=encoding utf8

=head1 NAME

Math::Polynomial::ModInt::Order - order relations on ModInt polynomials

=head1 VERSION

This documentation refers to version 0.004 of
Math::Polynomial::ModInt::Order.

=head1 SYNOPSIS

  use Math::Polynomial::ModInt qw(modpoly);
  use Math::Polynomial::ModInt::Order qw($BY_INDEX $SPARSE $CONWAY);

  @monic_mod_5_degree_3 = map { modpoly($_, 5) } 125 .. 249;

  @sorted_by_index      = sort $BY_INDEX @monic_mod_5_degree_3;
  @sorted_sparse_first  = sort $SPARSE   @monic_mod_5_degree_3;
  @sorted_for_conway    = sort $CONWAY   @monic_mod_5_degree_3;

  $p1 = modpoly(12, 3);     # x^2 + x
  $p2 = modpoly(13, 3);     # x^2 + x + 1
  $p3 = modpoly(15, 3);     # x^2 + 2*x

  $cmp = $BY_INDEX->cmp($p1, $p2);   # -1 (p1 < p2 lexically)
  $cmp = $SPARSE->cmp($p2, $p3);     # 1  (p2 > p3 in sparse order)
  $cmp = $CONWAY->cmp($p1, $p3);     # 1  (p1 > p3 in Conway order)

  $bool = $BY_INDEX->eq($p1, $p2);   # false (equal)
  $bool = $BY_INDEX->ne($p1, $p2);   # true  (not equal)
  $bool = $BY_INDEX->lt($p1, $p2);   # true  (less than)
  $bool = $BY_INDEX->le($p1, $p2);   # true  (less or equal)
  $bool = $BY_INDEX->gt($p1, $p2);   # false (greater than)
  $bool = $BY_INDEX->ge($p1, $p2);   # false (greater or equal)
  # ... etc. etc. ...

  for (
    my $p = modpoly(125, 5);
    $p->is_monic;
    $p = $CONWAY->next_poly($p)
  ) {
    # do something with $p, $p running through monic
    # third degree polynomials in Conway order
  }

=head1 DESCRIPTION

This module provides several different set order relations for modular
integer polynomials.  They are given as (read-only) variables so that
they can be used as name argument for the perl builtin I<sort> operator.
These variables are at the same time objects with methods for additional
functionality, most notably a mechanism for iterating through polynomials
in a given order.

While it would be conceivable to implement comparison operators as
overloaded perl operators on Math::Polynomial::ModInt objects directly,
this module keeps them separate for two reasons.

Firstly, the generic class Math::Polynomial chooses to treat comparisons
other than for equality as an error, since polynomial rings are not in
general ordered spaces.  This might change if the API is extended to
distinguish more strictly between different coefficient spaces and to
treat them differently.  Secondly, this separate module emphasizes the
fact that there are multiple orderings of interest even for the same
set of elements.  We hesitate to couple an arbitrary order relation
too closely with the entities to order, which means builtin operators
probably should not be used for just one particular such relation.

=head1 CLASS VARIABLES

Math::Polynomial::ModInt::Order provides these exportable variables:

=over 4

=item I<$BY_INDEX>

C<$BY_INDEX> represents the order given by comparing first the modulus,
then the index in ascending order.  With the same modulus, this is
lexicographic order based on coefficients' normalized residue values
(ranging from zero to the modulus minus one, each).  Highest order
coefficients are most significant.

=item I<$SPARSE>

C<$SPARSE> represents an order similar to C<$BY_INDEX> as far as the
modulus, the degree, and the highest order coefficient are concerned,
but considers the number of non-zero terms before the rest of the
coefficients, with sparse polynomials preceding abundant polynomials.
This order is intended for use by algorithms searching for monic
polynomials with certain properties, and as few non-zero coefficients as
possible, by visiting monic polynomials before others, and among those,
sparse polynomials first.

=item I<$CONWAY>

C<$CONWAY> represents an order similar to C<$BY_INDEX>, but in the lexical
part considering the positive value of the highest order coefficient,
the negative of the second highest, and so on with alternating signs.
This order is intended for use by algorithms searching for Conway
polynomials.

=back

=head1 OBJECT METHODS

=over 4

=item I<cmp>

C<$order-E<gt>cmp($p1, $p2)> compares two polynomials, returning minus
one if the first sorts before the second, zero if both are equivalent,
or plus one if the first sorts after the second.

=item I<eq>

=item I<ne>

=item I<lt>

=item I<le>

=item I<gt>

=item I<ge>

Boolean comparison operators C<$order-E<gt>eq($p1, $p2)> etc. return
boolean results analoguous to the builtin string comparison operators
they are named after.  They check whether two modular integer polynomials
are equal, or inequal, or the first one is strictly less, less or equal,
strictly greater, or not less than the second one, respectively, with
respect to the given order.

=item I<next_poly>

C<$order-E<gt>next_poly($p)> returns the next higher element in a given
sort order C<$order> by calculating an "incremented" polynomial adjacent
to the argument C<$p>.  This is usually more space efficient than sorting
and more space and time efficient than calculating an index, incrementing
that, and mapping the index back to a polynomial, even with the simplest
order C<$BY_INDEX>.

=back

=head1 DIAGNOSTICS

There are no diagnostics specific to this module.

=head1 DEPENDENCIES

Math::Polynomial::ModInt::Order has no external dependencies,
but it operates on Math::Polynomial::ModInt objects.

=head1 BUGS AND LIMITATIONS

The singleton variables this module provides must be treated as read-only.
Some future release will enforce this if we find a portable way to do that.
Meanwhile, just don't mess with them.

Other bug reports and suggestions are always welcome E<8212>
please submit them as lined out in the distribution's main module,
L<Math::Polynomial::ModInt>.

=head1 SEE ALSO

=over 4

=item *

L<Math::Polynomial::ModInt>

=item *

L<Math::Polynomial>

=back

=head1 AUTHOR

Martin Becker, C<< <becker-cpan-mp (at) cozap.com> >>

=head1 CONTRIBUTING

Contributions to this library are welcome (see the CONTRIBUTING file).

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013-2019 by Martin Becker, Blaubeuren.

This library is free software; you can distribute it and/or modify it
under the terms of the Artistic License 2.0 (see the LICENSE file).

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut
