# --8<--8<--8<--8<--
#
# Copyright (C) 2012 Smithsonian Astrophysical Observatory
#
# This file is part of Math::Rational::Approx::ContFrac
#
# Math::Rational::Approx::ContFrac is free software: you can
# redistribute it and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# -->8-->8-->8-->8--

package Math::Rational::Approx::ContFrac;

use strict;
use warnings;
use Carp;

our $VERSION = '0.01';

use Math::BigFloat;

use Moo;
use MooX::Types::MooseLike::Numeric ':all';

use Params::Validate qw[ validate_pos ARRAYREF ];

use Math::Rational::Approx qw[ contfrac contfrac_nd ];

has x => (
  is  => 'ro',
  isa => sub { die( "must be a positive number\n" )
                 unless is_PositiveNum($_[0]) },
  required => 1,
);

has n => (
  is  => 'rwp',
  isa => PositiveInt,
  required => 1,
);


has _terms => (
  is  => 'rwp',
  init_arg => undef,
  default => sub { [] },
);

sub terms { [ @{$_[0]->_terms} ] }

has _resid => (
  is => 'rwp',
  init_arg => undef,
  lazy => 1,
  builder => '_build_resid',
);

sub resid { $_[0]->x->copy }


sub _build_resid  { Math::BigFloat->new( $_[0]->x )  }

sub approx {

	my $self = shift;

	 my ( $n ) = validate_pos( @_,
	                         { optional => 1,
	                           callbacks => {
	                              'positive integer' => sub { is_PositiveInt($_[0]) },
	                                        }, 
	                           });

	$self->_set_n( $self->n + $n )
	  if defined $n;

	my ( undef, $x ) = contfrac( $self->_resid, $self->n - @{$self->_terms}, $self->_terms );
	$self->_set__resid( $x );

	return contfrac_nd( $self->_terms );
}

1;


__END__

=head1 NAME

Math::Rational::Approx::ContFrac - Rational number approximation via continued fractions


=head1 SYNOPSIS

    use Math::Rational::Approx::ContFrac;

    $x = Math::Rational::Approx::ContFrac->new( x => 1.234871035, n => 10 );
    ( $n, $d ) = $x->approx;
    # continue for an additonal number of steps
    ( $n, $d ) = $x->approx( 3 );


=head1 DESCRIPTION

This module is an object oriented front end to the
B<Math::Rational::Approx::contfrac> function

=head1 INTERFACE

=over

=item new


  $obj = Math::Rational::ContFrac->new( %attr );

Construct an object which will maintain state for the continued fraction.
The following attributes are available:

=over

=item x

The number to approximate.  It must be positive.

=item n

The number of terms to generate.  This may be augmented in calls to
the B<approx> method.


=back

=item approx

  ( $n, $d ) = $obj->approx;
  ( $n, $d ) = $obj->approx($n);

Calculate the continued fractions and return the associated nominator
and denominator.  If C<$n> is not specified, the number of terms
generated is that specified in the call to the constructor, plus any
terms requested by additional calls to B<approx> with C<$n> specified.

C<$n> specifies the number of additional terms to generate beyond
what has already been requested.

=item x

  $x = $obj->x;

The original number to be approximated.

=item n

  $n = $obj->n;

The number of terms generated.

=item terms

  $arrayref = $obj->terms

Returns an arrayref of the current terms.

=item resid

The residual of the input number as a B<Math::BigFloat> object.  This
is I<not> the difference between the input number and the rational
approximation.

=back


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

Math::BigFloat, Moo, MooX::Types::MooseLike::Numeric, Params::Validate


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-math-rational-approx-contfrac@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Math-Rational-Approx>.

=head1 SEE ALSO

L<Math::BigFloat>, L<Moo>, L<MooX::Types::MooseLike>, L<Params::Validate>, L<Math::Rational::Approx>.


=head1 AUTHOR

Diab Jerius  E<lt>djerius@cpan.orgE<gt>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012 The Smithsonian Astrophysical Observatory

Math::Rational::Approx is free software: you can redistribute it
and/or modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.


