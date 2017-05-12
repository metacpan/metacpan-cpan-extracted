package Math::Geometry::Construction::Point;

use 5.008008;

use Moose;
use Carp;

=head1 NAME

C<Math::Geometry::Construction::Point> - abstract point base class

=head1 VERSION

Version 0.018

=cut

our $VERSION = '0.018';


###########################################################################
#                                                                         #
#                      Class Variables and Methods                        # 
#                                                                         #
###########################################################################

our $ID_TEMPLATE = 'P%09d';

sub id_template { return $ID_TEMPLATE }

###########################################################################
#                                                                         #
#                               Accessors                                 # 
#                                                                         #
###########################################################################

with 'Math::Geometry::Construction::Role::Object';
with 'Math::Geometry::Construction::Role::Output';

has 'size'     => (isa     => 'Num',
	           is      => 'rw',
		   trigger => \&_size_trigger,
		   builder => '_build_size',
		   lazy    => 1);

has 'radius'   => (isa     => 'Num',
	           is      => 'rw',
		   trigger => \&_radius_trigger,
		   builder => '_build_radius',
		   lazy    => 1);

sub BUILD {
    my ($self) = @_;

    $self->style('stroke', 'black') unless($self->style('stroke'));
    $self->style('fill', 'white')   unless($self->style('fill'));
}

sub _size_trigger {
    my ($self, $new, $old) = @_;

    # dirty
    $self->{radius} = $new / 2;
}

sub _build_size {
    my ($self) = @_;

    return $self->construction->point_size;
}

sub _radius_trigger {
    my ($self, $new, $old) = @_;

    warn("The 'radius' attribute of Math::Geometry::Construction::Point ".
	 "is deprecated and might be removed in a future version. Use ".
	 "'size' with the double value (diameter of the circle) ".
	 "instead.\n");

    $self->size(2 * $new);
}

sub _build_radius {
    return($_[0]->_build_size / 2);
}

###########################################################################
#                                                                         #
#                             Retrieve Data                               #
#                                                                         #
###########################################################################

sub position { croak "Method position must be overloaded" }

sub id { croak "Method id must be overloaded" }

sub draw {
    my ($self, %args) = @_;
    return undef if $self->hidden;

    my $position = $self->position;
    if(!defined($position)) {
	warn sprintf("Undefined position of point %s, ".
		     "nothing to draw.\n", $self->id);
	return undef;
    }

    $self->construction->draw_circle(cx    => $position->[0],
				     cy    => $position->[1],
				     r     => $self->size / 2,
				     style => $self->style_hash,
				     id    => $self->id);

    $self->draw_label('x' => $position->[0], 'y' => $position->[1]);

    return undef;
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

This is an abstract base class for points. C<FixedPoint> and
C<DerivedPoint> inherit from it.

=head1 INTERFACE

=head2 Public Attributes

=head2 Methods


=head1 AUTHOR

Lutz Gehlen, C<< <perl at lutzgehlen.de> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Lutz Gehlen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

