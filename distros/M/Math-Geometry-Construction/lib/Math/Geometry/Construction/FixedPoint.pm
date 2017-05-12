package Math::Geometry::Construction::FixedPoint;
use Moose;
extends 'Math::Geometry::Construction::Point';

use 5.008008;

use Math::Geometry::Construction::Vector;
use Math::Geometry::Construction::Types qw(Vector);
use Math::Vector::Real;
use Carp;

=head1 NAME

C<Math::Geometry::Construction::FixedPoint> - independent user-defined point

=head1 VERSION

Version 0.024

=cut

our $VERSION = '0.024';


###########################################################################
#                                                                         #
#                               Accessors                                 # 
#                                                                         #
###########################################################################

with 'Math::Geometry::Construction::Role::Buffering';

has 'position_vector' => (isa      => Vector,
			  coerce   => 1,
			  is       => 'rw',
			  required => 1,
			  init_arg => 'position',
			  trigger  => \&clear_global_buffer);

sub BUILDARGS {
    my ($class, %args) = @_;

    if(defined($args{x}) and defined($args{y})) {
	$args{position} = V($args{x}, $args{y});
    }

    return \%args;
}

###########################################################################
#                                                                         #
#                             Retrieve Data                               #
#                                                                         #
###########################################################################

sub position {
    my ($self, @args) = @_;

    return $self->position_vector(@args) if(@args);
    return $self->position_vector->value;
}

###########################################################################
#                                                                         #
#                              Change Data                                # 
#                                                                         #
###########################################################################

1;


__END__

=pod

=head1 SYNOPSIS

  my $p1 = $construction->add_point(position => [100, 150]);

  my $p2 = $construction->add_point('x' => 50, 'y' => 90,
                                    hidden => 1);

  my $p3 = $construction->add_point('x' => 70, 'y' => 130,
                                    style          => {stroke => 'red'},
                                    label          => 'A',
	                            label_offset_x => 5,
	                            label_offset_y => -5);


=head1 DESCRIPTION

An instance of this class represents a user defined free point, as
opposed to a derived point, e.g. an intersection point. An instance
of this class got its position directly from the user. It is created
by using the L<add_point
method|Math::Geometry::Construction/add_point> of
C<Math::Geometry::Construction>.

=head1 INTERFACE

=head2 Public Attributes

=head3 position

The accessor returns a L<Math::Vector::Real|Math::Vector::Real>
object with the position of the point. To the constructor or
mutator, you can give anything that
L<Math::Geometry::Construction::Vector|Math::Geometry::Construction::Vector>
accepts. The constructor additionally supports explicit C<x> and
C<y> arguments.

Examples:

  # arrayref
  $construction->add_point(position => [1, 4]);
  $construction->position([5, -3]);
  $construction->position([4, -1, 7]);  # 7 is ignored

  # Math::Vector::Real object
  $construction->add_point(position => V(1, 4));
  $construction->position(V(5, -3));

  # x and y
  $construction->add_point('x' => 1, 'y' => 4);

See also
L<Math::Geometry::Construction::Vector|Math::Geometry::Construction::Vector>.

Note that you must not alter the elements of the
C<Math::Vector::Real> object directly although the class interface
allows it. This will circumvent the tracking of changes that
C<Math::Geometry::Construction> performs in order to improve
performance.

  $point = $construction->add_point([5, 7]);
  $pos   = $point->position;
  $pos->[0] = 6;             # wrong!
  $point->position([6, 7]);  # right

=head3 size

A point is currently always drawn as a circle. This might become
more flexible in the future. C<size> determines the size of the
point in the output. For a circle it is its diameter. This parameter
is currently C<undef> by default, because the output falls back to
L<radius|/radius> (see below). When C<radius> is removed, C<size>
will default to C<6>.

=head3 radius

Half of L<size|/size>. This attribute is deprecated and might be
removed in a future version. Use L<size|/size> instead.

=head2 General Output Attributes

See
L<Math::Geometry::Construction::Output|Math::Geometry::Construction::Output>.

=head2 Methods

=head3 draw

Called by the C<Construction> object during output generation.
Currently draws a circle of diameter L<size|/size>, but this might
become more flexible in the future.

=head3 id_template

Class method returning C<$ID_TEMPLATE>, which defaults to C<'P%09d'>.


=head1 AUTHOR

Lutz Gehlen, C<< <perl at lutzgehlen.de> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2011, 2013 Lutz Gehlen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
