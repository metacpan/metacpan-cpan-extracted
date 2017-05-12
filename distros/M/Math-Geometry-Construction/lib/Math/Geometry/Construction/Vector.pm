package Math::Geometry::Construction::Vector;

use 5.008008;

use Math::Vector::Real;
use Math::Geometry::Construction::Types qw(MathVectorReal
                                           Point
                                           PointPoint);
use Moose;
use Carp;

=head1 NAME

C<Math::Geometry::Construction::Vector> - anything representing a vector

=head1 VERSION

Version 0.024

=cut

our $VERSION = '0.024';


###########################################################################
#                                                                         #
#                      Class Variables and Methods                        # 
#                                                                         #
###########################################################################

###########################################################################
#                                                                         #
#                               Accessors                                 # 
#                                                                         #
###########################################################################

with 'Math::Geometry::Construction::Role::AlternativeSources';

my %alternative_sources =
    (value_sources => {'vector'      => {isa    => MathVectorReal,
					 coerce => 1},
		       'point'       => {isa    => Point},
		       'point_point' => {isa    => PointPoint,
					 coerce => 1}});

while(my ($name, $alternatives) = each %alternative_sources) {
    __PACKAGE__->alternatives
	(name         => $name,
	 alternatives => $alternatives,
	 clear_buffer => 0);
}

sub BUILD {
    my ($self, $args) = @_;

    $self->_check_value_sources;
}

###########################################################################
#                                                                         #
#                             Retrieve Data                               #
#                                                                         #
###########################################################################

sub value {
    my ($self)   = @_;

    return $self->_vector          if($self->_has_vector);
    return $self->_point->position if($self->_has_point);
    if($self->_has_point_point) {
	my $points = $self->_point_point;
	return $points->[1]->position - $points->[0]->position;
    }
    croak('No way to determine value of Vector, '.
	  'please send a bug report');
}
###########################################################################
#                                                                         #
#                              Change Data                                # 
#                                                                         #
###########################################################################

1;


__END__

=pod

=head1 DESCRIPTION

The typical user will not interact directly with this class. It
unifies the access to different sources of a vector. This can be

=over 4

=item * a reference to an array of numbers

In this case, the L<value|/value> method will return a
L<Math::Vector::Real|Math::Vector::Real> object consisting of the
first two items of the array. It is only checked if the type is the
C<Moose> type C<ArrayRef[Num]>. It is not checked if the array
contains at least two items.

=item * a L<Math::Vector::Real> object

The L<value|/value> method returns the object itself (not a clone).

=item * a L<Math::VectorReal> object

The L<value|/value> method returns an
L<Math::Vector::Real|Math::Vector::Real> object consisting of the
C<x> and C<y> component of the vector.

=item * a
L<Math::Geometry::Construction::Point|Math::Geometry::Construction::Point>
object

The L<value|/value> method returns the
L<position|Math::Geometry::Construction::Point/position> attribute
of the point.

=item * a
L<Math::Geometry::Construction::Line|Math::Geometry::Construction::Line>
object

The L<value|/value> method returns the
L<direction|Math::Geometry::Construction::Point/direction> of the
line.

=back

C<Point> and C<Line> objects are evaluated at the time you call
L<value|/value>.

=head1 INTERFACE

=head2 Constructors

=head3 new

  $vector = Math::Geometry::Construction::Vector->new
      (provider => ...)

Creates a new C<Math::Geometry::Construction::Vector> object and
initializes attributes. This is the default L<Moose|Moose>
constructor.


=head2 Public Attributes

=head3 provider

This is the only attribute. It must be set at construction time and
is readonly after that. The possible values are described in the
L<DESCRIPTION section|/DESCRIPTION>.

=head2 Methods

=head3 value

Returns a L<Math::Vector::Real|Math::Vector::Real> object as
described in the L<DESCRIPTION section|/DESCRIPTION>.


=head1 AUTHOR

Lutz Gehlen, C<< <perl at lutzgehlen.de> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Lutz Gehlen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

