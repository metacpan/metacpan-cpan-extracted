package Math::Geometry::Construction::Line;
use Moose;

use 5.008008;

use Math::Geometry::Construction::Types qw(PointPoint);
use Carp;
use List::MoreUtils qw(any);
use Scalar::Util qw(blessed);
use Math::Vector::Real;

use overload 'x'    => '_intersect',
             '.'    => '_point_on',
             'bool' => sub { return 1 };

=head1 NAME

C<Math::Geometry::Construction::Line> - line through two points

=head1 VERSION

Version 0.024

=cut

our $VERSION = '0.024';


###########################################################################
#                                                                         #
#                      Class Variables and Methods                        # 
#                                                                         #
###########################################################################

our $ID_TEMPLATE = 'L%09d';

sub id_template { return $ID_TEMPLATE }

###########################################################################
#                                                                         #
#                               Accessors                                 # 
#                                                                         #
###########################################################################

with 'Math::Geometry::Construction::Role::Input';
with 'Math::Geometry::Construction::Role::Object';
with 'Math::Geometry::Construction::Role::PositionSelection';
with 'Math::Geometry::Construction::Role::Output';
with 'Math::Geometry::Construction::Role::PointSet';

has 'support'     => (isa      => PointPoint,
		      is       => 'bare',
		      traits   => ['Array'],
		      required => 1,
		      handles  => {count_support  => 'count',
				   support        => 'elements',
				   single_support => 'accessor'});

sub BUILDARGS {
    my ($class, %args) = @_;
    
    for(my $i=0;$i<@{$args{support}};$i++) {
	$args{support}->[$i] = $class->import_point
	    ($args{construction}, $args{support}->[$i]);
    }

    return \%args;
}

sub BUILD {
    my ($self, $args) = @_;

    $self->style('stroke', 'black') unless($self->style('stroke'));

    $self->register_point($self->support);
}

###########################################################################
#                                                                         #
#                             Retrieve Data                               #
#                                                                         #
###########################################################################

sub positions {
    my ($self) = @_;

    return map { $_->position } $self->points;
}

sub direction {
    my ($self)            = @_;
    my @support_positions = map { $_->position } $self->support;

    # check for defined positions
    if(any { !defined($_) } @support_positions) {
	warn sprintf("Undefined support point in line %s.\n", $self->id);
	return undef;
    }

    return($support_positions[1] - $support_positions[0]);
}

sub parallel {
    my ($self)            = @_;
    my @support_positions = map { $_->position } $self->support;

    # check for defined positions
    if(any { !defined($_) } @support_positions) {
	warn sprintf("Undefined support point in line %s.\n", $self->id);
	return undef;
    }

    my $direction = $support_positions[1] - $support_positions[0];
    my $length    = abs($direction);

    if($length == 0) {
	warn sprintf("Support points of line %s are identical.\n",
		     $self->id);
	return undef;
    }
    
    return($direction / $length);
}

sub normal {
    my ($self)   = @_;
    my $parallel = $self->parallel;

    return $parallel ? V(-$parallel->[1], $parallel->[0]) : undef;
}

sub draw {
    my ($self, %args) = @_;
    return undef if $self->hidden;

    my $parallel = $self->parallel;
    return undef if(!$parallel);

    my $extend    = $self->extend;
    my @positions = ($self->extreme_position(-$parallel)
		     - $parallel * $extend->[0],
		     $self->extreme_position($parallel)
		     + $parallel * $extend->[1]);

    $self->construction->draw_line(x1    => $positions[0]->[0],
				   y1    => $positions[0]->[1],
				   x2    => $positions[1]->[0],
				   y2    => $positions[1]->[1],
				   style => $self->style_hash,
				   id    => $self->id);
    
    $self->draw_label
	('x' => ($positions[0]->[0] + $positions[1]->[0]) / 2,
	 'y' => ($positions[0]->[1] + $positions[1]->[1]) / 2);
}

###########################################################################
#                                                                         #
#                              Overloading                                # 
#                                                                         #
###########################################################################

sub _intersect {
    my ($self, $intersector) = @_;
    my $class;
	 
    $class = 'Math::Geometry::Construction::Line';
    if(eval { $intersector->isa($class) }) {
	return $self->construction->add_derived_point
	    ('IntersectionLineLine', {input => [$self, $intersector]});
    }

    $class = 'Math::Geometry::Construction::Circle';
    if(eval { $intersector->isa($class) }) {
	return $self->construction->add_derived_point
	    ('IntersectionCircleLine', {input => [$self, $intersector]});
    }
}

sub _point_on {
    my ($self, $args) = @_;

    my $derivate = "Math::Geometry::Construction::Derivate::PointOnLine";
    return $self->construction->add_derived_point
	($derivate, {input => [$self], $args});
}

1;


__END__

=pod

=head1 SYNOPSIS

  my $p1 = $construction->add_point('x' => 100, 'y' => 90);
  my $p2 = $construction->add_point('x' => 120, 'y' => 150);
  my $l1 = $construction->add_line(support => [$p1, $p2]);

  my $p3 = $construction->add_point('x' => 200, 'y' => 50);
  my $p4 = $construction->add_point('x' => 250, 'y' => 50);

  my $l2 = $construction->add_line(support        => [$p3, $p4],
                                   extend         => 10,
                                   label          => 'g',
				   label_offset_y => 13);


=head1 DESCRIPTION

An instance of this class represents a line defined by two points.
The points can be either points defined directly by the user
(L<Math::Geometry::Construction::Point|Math::Geometry::Construction::Point>
objects) or so-called derived points
(L<Math::Geometry::Construction::DerivedPoint|Math::Geometry::Construction::DerivedPoint>
objects), e.g. intersection points. This class is not supposed to be
instantiated directly. Use the L<add_line
method|Math::Geometry::Construction/add_line> of
C<Math::Geometry::Construction> instead.


=head1 INTERFACE

=head2 Public Attributes

=head3 support

Holds an array reference of the two points that define the line.
Must be given to the constructor and should not be touched
afterwards (the points can change their positions, of course). Must
hold exactly two points.

=head3 extend

Often it looks nicer if the visual representation of a line extends
somewhat beyond its end points. The length of this extent is set
here. Internally, this is an array reference with two entries
containing the exent in backward in forward direction. If a single
value C<x> is provided it is turned into C<[x, x]>. Defaults to
C<[0, 0]>.

Take care if you are reading this attribute. You get the internal
array reference, so manipulating it will affect the values stored in
the object.

=head2 Methods

=head3 direction

Returns the unnormalized difference vector between the two support
points as a L<Math::Vector::Real|Math::Vector::Real>. Issues a
warning and returns C<undef> if one of the support points has an
undefined position. If the support points have identical positions
the C<0> vector is returned without warning.

=head3 parallel

Returns a L<Math::Vector::Real|Math::Vector::Real> of length C<1>
that is parallel to the line. Issues a warning and returns C<undef>
if one of the support points has an undefined position or if the two
positions are identical.

=head3 normal

Returns a L<Math::Vector::Real|Math::Vector::Real> of length C<1>
that is orthogonal to the line. Issues a warning and returns
C<undef> if one of the support points has an undefined position or
if the two positions are identical.

=head3 draw

Called by the C<Construction> object during output generation.
Draws a line between the most extreme points on this line
(including both support points and points derived from this line).
The line is extended by length of L<extend|/extend> beyond these
points.

=head3 id_template

Class method returning C<$ID_TEMPLATE>, which defaults to C<'L%09d'>.


=head1 AUTHOR

Lutz Gehlen, C<< <perl at lutzgehlen.de> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2011-2013 Lutz Gehlen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

