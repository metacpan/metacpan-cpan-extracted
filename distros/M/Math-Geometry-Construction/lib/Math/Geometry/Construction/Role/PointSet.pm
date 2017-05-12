package Math::Geometry::Construction::Role::PointSet;
use Moose::Role;

use 5.008008;

use Math::Geometry::Construction::Types qw(HashRefOfPoint Extension);
use Carp;

=head1 NAME

C<Math::Geometry::Construction::Role::PointSet> - point set objects

=head1 VERSION

Version 0.020

=cut

our $VERSION = '0.020';


###########################################################################
#                                                                         #
#                               Accessors                                 # 
#                                                                         #
###########################################################################

has 'points' => (isa     => HashRefOfPoint,
		 is      => 'bare',
		 traits  => ['Hash'],
		 default => sub { {} },
		 handles => {points          => 'values',
			     _pointset_point => 'accessor'});

has 'extend'  => (isa     => Extension,
		  coerce  => 1,
		  is      => 'rw',
		  default => sub { [0, 0] });

sub register_point {
    my ($self, @args) = @_;

    foreach(@args) { $self->_pointset_point($_->id, $_) }
}

sub has_point {
    my ($self, @args) = @_;

    foreach(@args) {
	return 0 if(!$self->_pointset_point(blessed($_) ? $_->id : $_));
    }
    return 1;
}

1;


__END__

=pod

=head1 DESCRIPTION

This role provides attributes and methods that are common to all
classes which represent objects that are point sets (specifically
lines and circles). The role provides means to identify if two such
objects are the same.

=head1 INTERFACE

=head2 Public Attributes

=head3 points

An array of C<Point> objects that lie on this object. This is not
meant in strict geometrical sense. For a line, the C<points> are the
two support points and all points derived from and lying on this
line, e.g. C<PointOnLine> constructions and intersection
points. However, the points must lie on that line. If, for example,
a point is reflected at this line then the reflected point is also
somehow associated with this line, but not a C<point> in the sense
of this list. Similarly, the center of a circle is not a C<point>.

The C<points> accessor will return the array (not a reference), the
C<register_point> method pushes to the array.

=head2 Methods


=head1 AUTHOR

Lutz Gehlen, C<< <perl at lutzgehlen.de> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2011-2012 Lutz Gehlen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

