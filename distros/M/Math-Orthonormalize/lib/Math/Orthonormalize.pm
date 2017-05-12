
=head1 NAME

Math::Orthonormalize - Gram-Schmidt Orthonormalization of vectors

=head1 SYNOPSIS

  use Math::Orthonormalize qw(:all);
  
  my @base_of_r_2 = (
    [2, 1],
    [1, 3]
  );
  my $vector = [1, 2, 3];
  
  my @orthonormalized = orthonormalize(@base_of_r_2);
  my @orthogonalized  = orthogonalize(@base_of_r_2);
  
  my $normalized      = normalize($vector);
  my $scaled          = scale(2, $vector);
  my $scalar          = scalar_product($vector1, $vector2);

=head1 DESCRIPTION

Math::Orthonormalize offers subroutines to compute normalized or
non-normalized orthogonal bases of Euclidean vector spaces. That means:
Given a vector base of R^n, it computes a new base of R^n whose individual
vectors are all orthogonal. If those new base vectors all have a length of
1, the base is orthonormalized.

The module uses the Gram-Schmidt Algorithm.

=head2 EXPORT

No subroutines are exported by default, but the standart Exporter semantics are
in place, including the ':all' tag that imports all of the exportable
subroutines which are listed below.

=cut

package Math::Orthonormalize;

use 5.006;
use strict;
use warnings;

use Math::Symbolic qw/parse_from_string/;
use Carp;

our $VERSION = '1.00';

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
		orthonormalize
		orthogonalize
		scalar_product
		normalize
		scale
) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = ();

=head1 SUBROUTINES

=head2 orthonormalize

Takes any number (>1) of vectors (array refs of vector components) as argument
which form a base (that is, they are linearly independent) and returns
an orthogonalized and normalized base of the same vector space
(that is, n new array references).

=cut

sub orthonormalize {
	my @vectors = @_;
	croak "No arguments to orthogonalize"
	  if not @vectors;
	croak "Arguments to orthogonalize must be array refs (vectors)"
	  if grep {ref($_) ne 'ARRAY'} @vectors;
	my $dim = @{$vectors[0]};
	croak "Vectors must have same dimension for orthogonalization"
	  if grep {@$_ != $dim} @vectors;

	my @base = orthogonalize(@vectors);
	@base = map {normalize($_)} @base;
	return @base;
}


=head2 orthogonalize

Takes any number (>1) of vectors (array refs of vector components) as argument
which form a base (that is, they are linearly independent) and returns
an orthogonalized base of the same vector space (that is, n new array
references).

=cut

sub orthogonalize {
	my @vectors = @_;
	croak "No arguments to orthogonalize"
	  if not @vectors;
	croak "Arguments to orthogonalize must be array refs (vectors)"
	  if grep {ref($_) ne 'ARRAY'} @vectors;
	my $dim = @{$vectors[0]};
	croak "Vectors must have same dimension for orthogonalization"
	  if grep {@$_ != $dim} @vectors;
	
	my @newbase;
	push @newbase, $vectors[0];
	my @squares;
	push @squares, scalar_product($vectors[0], $vectors[0]) if @vectors > 1;
	foreach my $i (1..$#vectors) {
		my $new = $vectors[$i];
		foreach my $j (0..$#newbase) {
			my $vec = scale(
				scalar_product($vectors[$i], $newbase[$j])
				/ $squares[$j],
				$newbase[$j]
			);
			@$new = map {$_ -= shift @$vec} @$new;
		}
		push @newbase, $new;
		push @squares, scalar_product($new, $new) if $i < $#vectors;
	}
	return @newbase;
}

=head2 normalize

Normalizes a vector. That is, it changes the vector length to 1 without
changing the vector's direction.

Takes an array reference with the vector components as argument and returns
a new array reference containing the normalized vector components.

=cut

sub normalize {
	my $v = shift;
	croak "Argument to normalize() must be an array ref (vector)"
	  if not ref($v) eq 'ARRAY';
	croak "Cannot normalize 0-dimensional vectors"
	  if @$v == 0;
	my $sum = $v->[0]**2;
	$sum += $v->[$_]**2 for 1..$#$v;
	$sum = sqrt($sum);
	croak "Cannot normalize 0-vector"
	  if $sum == 0;
	return [map {$_ / $sum} @$v];
}

=head2 scale

Takes a scalar and a vector (array reference of vector components) as
arguments. Multiplies every component of the vector by the specified
scalar and returns a new array reference containing the scaled vector
components.

=cut

sub scale {
	croak "scale() takes a scalar and a vector (ary ref) as arguments"
	  if not @_ == 2 or not ref($_[1]) eq 'ARRAY';
	croak "Cannot handle 0-dimensional vectors"
	  if @{$_[1]} == 0;
	my $new = [];
	foreach (@{$_[1]}) {
		push @$new, $_[0] * $_;
	}
	return $new;
}

=head2 scalar_product

Computes the scalar product of two vectors. Expects two array references
with vector components (same number of components) as argument and
returns their scalar product.

=cut

sub scalar_product {
	croak "Invalid number of arguments to scalar_product()"
	  if not @_ == 2;
	my ($v1, $v2) = @_;
	croak "Cannot compute the scalar product of vectors of different ",
		"dimensions"
	  if @$v1 != @$v2;
	croak "Cannot deal with 0-dimensional vectors"
	  if @$v1 == 0;
	my $sum = $v1->[0] * $v2->[0];
	return $sum if @$v1 == 1;
	
	$sum += $v1->[$_] * $v2->[$_] for 1..$#$v1;
	return $sum;
}


1;
__END__

=head1 AUTHOR

Steffen Mueller, orthonormalize-module at steffen-mueller dot net

=head1 SEE ALSO

(German) Merziger, Wirth: "Repetitorium der Höheren Mathematik" (Binomi, 1999)

You may find the current versions of this module at http://steffen-mueller.net/
or on CPAN.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2005 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
