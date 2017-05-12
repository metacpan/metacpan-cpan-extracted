# --8<--8<--8<--8<--
#
# Copyright (C) 2012 Smithsonian Astrophysical Observatory
#
# This file is part of Math::Rational::Approx
#
# Math::Rational::Approx is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
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

package Math::Rational::Approx;

use strict;
use warnings;
use Carp;


our $VERSION = '0.02';

use base 'Exporter';
our %EXPORT_TAGS = ( all => [ qw( maxD contfrac contfrac_nd ) ],
                   );
our @EXPORT_OK = map { @$_} values %EXPORT_TAGS;

use POSIX 'floor';
use Math::BigFloat;

use MooX::Types::MooseLike::Numeric ':all';
use Params::Validate qw[ validate_pos ARRAYREF ];

sub _check_bounds {

        my ( $x, $bounds ) = @_;

        croak( "incorrect number of elements in bounds\n" )
          unless 4 == @$bounds;

        my ( $a, $b, $c, $d ) = @$bounds;
        # ensure that a/b < c/d

        croak( "a/b is not less than c/d\n" )
          unless $a / $b < $c / $d;


        croak( "a/b and c/d do not bound x\n" )
          unless $a / $b < $x && $x < $c / $d;

}

sub maxD {

        my ($x, $maxD, $bounds )
          = validate_pos( @_,
                          { callbacks => { 'positive number' => sub { is_PositiveNum($_[0]) } },
                          },
                          { callbacks => { 'positive integer' => sub { is_PositiveInt($_[0]) } },
                          },
                         {  type => ARRAYREF,
                            default => [],
                         },
                        ) ;

        if ( defined $bounds && @$bounds ) {

                _check_bounds( $x, $bounds );
        }

        else {

                my $base = floor( $x );

                @{$bounds} = ( $base, 1, $base+1, 1 );

        }

        my ( $a, $b, $c, $d ) = @{$bounds};

        my ( $nom, $denom );

        while ( $b <= $maxD && $d <= $maxD ) {

                my $mediant = ( $a + $c ) / ( $b + $d );

                if ( $x == $mediant ) {

                        ( $nom, $denom ) =
                          $b + $d <= $maxD ? ( $a + $c, $b + $d )
                        : $d > $b          ? ( $c, $d )
                        :                    ( $a, $b );

                        last;
                }

                elsif ( $x > $mediant ) {

                        ($a, $b) = ( $a + $c, $b + $d );

                }

                else {

                        ($c, $d) = ( $a + $c, $b + $d );

                }

        }

        if ( ! defined $nom && ! defined $denom ) {
                ( $nom, $denom ) = $b > $maxD ? ( $c, $d )
                                              : ( $a, $b );
        }

        @{$bounds} = ( $a, $b, $c, $d );

        return ( $nom, $denom, $bounds );
}

sub contfrac {

        my ( $x, $max, $p ) =
          validate_pos( @_,
                      { callbacks => {
                                      'positive number' => sub { is_PositiveNum($_[0]) },
                                     },
                      },
                      { callbacks => {
                                      'positive integer' => sub { is_PositiveInt($_[0]) },
                                     },
                      },
                      { type => ARRAYREF, default => [] },
                      );

        $x = Math::BigFloat->new( $x );

        my $one = Math::BigFloat->bone;

        for my $n ( 0 .. $max-1 ) {

                my $int = $x->copy->bfloor;
                push @$p, $int;

                # if $x is actually rational, round off error in ( $x - $int )
                # can drive the iteration beyond its true end point, causing
                # bogus results.  Let's hope that 10 digits is enough.
                last if ( $x - $int)->bfround(-10)->is_zero;
                $x = $one->copy->bdiv( $x - $int );
        }

        return $p, $x;
}

sub contfrac_nd {

	# ignore extra parameter to ease use of contfrac_nd( contfrac ( ... ) )
    my ( $terms ) = validate_pos( @_, { type => ARRAYREF }, 0 );
    my @p = reverse @$terms;

    my $n = Math::BigInt->bone;
    my $d = Math::BigInt->new( (shift @p) );

    for my $p ( @p ) {

            $n += $d * $p;

            ( $n, $d ) = ( $d, $n );

    }

    ( $n, $d ) = ( $d, $n );
    return ( $n, $d );
}


1;



__END__

=head1 NAME

Math::Rational::Approx - approximate a number with a rational number


=head1 SYNOPSIS

  use Math::Rational::Approx ':all';

  #
  # find rational approximation with maximum denominator
  ($n, $d, $bounds ) = maxD( $x, 10 );

  # refine; note reuse of $bounds from previous call
  ( $n, $d ) = maxD( $x, 20, $bounds );


  #
  # find rational approximation to arbitrary precision using
  # continued fractions

  # one shot, 10 iterations
  ( $numerator, $denominator ) =
                   contfrac_nd( contfrac( 1.234871035, 10 ) );

  # multiple calls on same number; useful for convergence tests
  # keep array containing terms; get fraction and perhaps test it
  ( $terms, $residual ) = contfrac( 1.234871035, 3 );
  ( $n, $d ) = contfrac_nd( $terms  );

  # continue for an additional number of steps; note reuse of $terms;
  # new terms are appended to it
  ( $terms, $residual ) = contfrac( $residual, 3, $terms );

  # new results
  ( $n, $d ) = contfrac_nd( $terms );


=head1 DESCRIPTION

This module and its object oriented companion modules provide various
means for finding rational number approximations to real numbers.  The
object oriented versions are suitable when repeated refinements are
required.  See L<Math::Rational::Approx::MaxD> and L<Math::Rational::Approx::ContFrac>.



=head1 INTERFACE

=head2 Maximum denominator

B<maxD> finds the best rational approximation (n/d) to a fraction with
a denominator less than a given value.  It uses Farey's sequence and
is based upon the algorithm given at
L<http://www.johndcook.com/blog/2010/10/20/best-rational-approximation/>.

This is an iterative procedure, searching a given range for the
best approximation.   To enable further refinement, the
limiting denominator may by adjusted; the approximation
will be continued from the last calculation.

=over

=item maxD

  ( $n, $d, $bounds ) = maxD( $x, $maxD, );
  ( $n, $d, $bounds ) = maxD( $x, $maxD, $bounds );

Calculate the rational number approximation to C<$x> with denominator
no greater than C<$maxD>.

The optional argument, C<$bounds>, is a reference to a four element
array containing the initial bounds on the region to search.  It takes
the form

  bounds => [ a, b, c, d ]

where the elements are all non-negative integers and the bounds are
given by

  a/b < x < c/d
  b < maxD && d < maxD

The behavior is undefined if the latter condition is not yet, unless
the bounds are the result of a previous run of B<maxD>.

By default it searches from C<float(x)> to C<float(x)+1>.

B<maxD> returns the determined numerator and denominator as well as an
arrayref containing the bounds. If the C<$bounds> argument was
specified this is returned.

=back

=head2 Continued Fractions

To approximate using continued fractions, one first generates the
terms in the fraction using B<contfrac> and then calculates the
numerator and denominator using B<contfrac_nd>.

=over

=item contfrac

  ( $terms, $residual ) = contfrac( $x, $n );
  ( $terms, $residual ) = contfrac( $x, $n, $terms );

Generate C<$n> terms of the continous fraction representing
C<$x>. Additional terms may be added in subsequent calls
to B<contfrac> by passing C<$residual> as the number to approximate and
supplying the previous C<$terms> arrayref:

  ( $terms, $residual ) = contfrac( $x, 10 );
  ( $terms, $residual ) = contfrac( $residual, 3, $terms );


The arguments are as follows:

=over

=item $x

The number to approximate. It must be positive.

=item $n

The number of terms to generate.

=item $terms

I<Optional>.  An arrayref in which to store the terms.  The array is
appended to.

=back

Returns:

=over

=item $terms

An arrayref which holds the terms.  If one was provided in the
argument list it is passed through.

=item $residual

The residual of the input number as a B<Math::BigFloat> object.  This
is I<not> the difference between the input number and the rational
approximation.  It is suitable for reuse in subsequent calls to
B<contfrac>.

=back

=item contfrac_nd

  ( $nominator, $denominator ) = contfrac_nd( $terms );

Generate the nominator and denominator from the terms created by
B<contfrac>.  They are returned as B<Math::BigInt> objects.

=back

=head1 DEPENDENCIES

Math::BigFloat, POSIX, Params::Validate


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-math-rational-approx@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Math-Rational-Approx>.

=head1 SEE ALSO

=for author to fill in:
    Any other resources (e.g., modules or files) that are related.

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



