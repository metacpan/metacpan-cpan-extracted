# --8<--8<--8<--8<--
#
# Copyright (C) 2012 Smithsonian Astrophysical Observatory
#
# This file is part of Math::Rational::Approx::MaxD
#
# Math::Rational::Approx::MaxD is free software: you can redistribute
# it and/or modify it under the terms of the GNU General Public
# License as published by the Free Software Foundation, either version
# 3 of the License, or (at your option) any later version.
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

package Math::Rational::Approx::MaxD;

use strict;
use warnings;
use Carp;


our $VERSION = '0.01';

use Params::Validate qw[ validate_pos ARRAYREF ];
use Math::Rational::Approx;

use Moo;
use MooX::Types::MooseLike::Numeric ':all';
use MooX::Types::MooseLike::Base ':all';

has x => (
  is  => 'ro',
  isa => PositiveNum,
  required => 1,
);

has maxD => (
  is  => 'rwp',
  isa => PositiveInt,
  required => 1,
);

has bounds => (
  is => 'ro',
  coerce => sub { return  is_ArrayRef($_[0]) ? [ @{$_[0]} ] : $_[0] },
  isa => ArrayRef[PositiveOrZeroInt],
  default => sub { [] },
);

sub BUILD {

	my $self = shift;

	Math::Rational::Approx::_check_bounds( $self->x, $self->bounds )
	  if @{$self->bounds};
}


sub approx {

	my $self = shift;

	my ( $maxD ) = validate_pos( @_,
	                           { callbacks => { 'positive integer' => sub { is_PositiveInt($_[0]) } },
	                             optional => 1,
	                           }
	                             );
	$self->_set_maxD( $maxD )
	  if defined $maxD && $maxD > $self->maxD;

	my ( $n, $d ) = Math::Rational::Approx::maxD( $self->x, $self->maxD, $self->bounds );

	return ( $n, $d );
}

1;



__END__

=head1 NAME

Math::Rational::Approx::MaxD - approximate a number with a rational number up to a given denominator


=head1 SYNOPSIS

    use Math::Rational::Approx::MaxD;

    # approximate up to denominator of 10
    $rat = Math::Rational::Approx::MaxD->new( x => $x, maxD => 10 );

    ($n, $d ) = $rat->approx;

    # approximate up to denominator of 20
    ($n, $d ) = $rat->approx( 20 );


=head1 DESCRIPTION

This module is an object oriented front end to the
B<Math::Rational::Approx::maxd> function

=head1 INTERFACE

=over

=item new

    $obj = Math::Rational::Approx::MaxD->new( %attr );

Create a new object.  The following attributes are available

=over

=item C<x>

The number to approximate.

=item C<maxD>

The limiting maximum denominator to check;

=item C<bounds>

I<Optional>. A reference to a four element array containing the
initial bounds on the region to search.  It takes the form

  bounds => [ a, b, c, d ]

where the elements are all non-negative integers and the bounds are
given by

  a/b < x < c/d

By default it searches from C<float(x)> to C<float(x)+1>.

=back

=item approx

  ( $n, $d ) = $obj->approx;
  ( $n, $d ) = $obj->approx( $maxD );

Return the nominator and denominator for a given maximum value of the
denominator.  If C<$maxD> is not specified it is that specified in the
call to the constructor or in any subsequent call to approx.  New
values of C<$maxD> less than one already specified are ignored.

=item bounds

  $bounds = $obj->bounds;

Return an arrayref which contains the current bounds on the search,
in the same format as the C<bounds> attribute passed to B<new>.

=item x

  $x = $obj->x;

The original number to be approximated.

=item maxD

The current value of the maximum denominator.

=back

=head1 DEPENDENCIES

L<Moo>, L<MooX::Types::MooseLike>, L<Params::Validate>, L<Math::Rational::Approx>.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-math-rational-approx@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Math-Rational-Approx>.

=head1 SEE ALSO

L<Math::Rational::Approx>

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



