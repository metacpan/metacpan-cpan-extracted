package Math::Geometry::Construction::Derivate::PointOnCircle;
use Moose;
extends 'Math::Geometry::Construction::Derivate';

use 5.008008;

use Math::Geometry::Construction::Types qw(Circle);
use Carp;

=head1 NAME

C<Math::Geometry::Construction::Derivate::PointOnCircle> - point on a Circle

=head1 VERSION

Version 0.024

=cut

our $VERSION = '0.024';


###########################################################################
#                                                                         #
#                               Accessors                                 # 
#                                                                         #
###########################################################################

with 'Math::Geometry::Construction::Role::AlternativeSources';

has 'input'    => (isa       => Circle,
		   coerce    => 1,
		   is        => 'ro',
		   required  => 1);

my %alternative_sources =
    (position_sources => {'distance' => {isa => 'Num'},
			  'quantile' => {isa => 'Num'},
			  'phi'      => {isa => 'Num'}});

while(my ($name, $alternatives) = each %alternative_sources) {
    __PACKAGE__->alternatives
	(name         => $name,
	 alternatives => $alternatives,
	 clear_buffer => 1);
}

sub BUILD {
    my ($self, $args) = @_;

    $self->_check_position_sources;
}

###########################################################################
#                                                                         #
#                             Retrieve Data                               #
#                                                                         #
###########################################################################

sub calculate_positions {
    my ($self) = @_;
    my $circle = $self->input;

    my $center_p  = $circle->center->position;
    my $support_p = $circle->support->position;
    return if(!defined($center_p) or !defined($support_p));
    my $radius_v  = $support_p - $center_p;
    my $radius    = abs($radius_v);
    return $center_p if($radius == 0);

    my $phi = atan2($radius_v->[1], $radius_v->[0]);
    if($self->_has_distance) {
	$phi += $self->_distance / $radius;
    }
    elsif($self->_has_quantile) {
	$phi += 6.28318530717959 * $self->_quantile;
    }
    elsif($self->_has_phi) {
	$phi += $self->_phi;
    }
    else {
	croak "No way to determine position of PointOnCircle ".$self->id;
    }

    return($center_p + [$radius * cos($phi), $radius * sin($phi)]);
}

###########################################################################
#                                                                         #
#                              Change Data                                # 
#                                                                         #
###########################################################################

sub register_derived_point {
    my ($self, $point) = @_;

    $self->input->register_point($point);
}

1;


__END__

=pod

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 INTERFACE

=head2 Public Attributes

=head2 Methods for Users

=head2 Methods for Subclass Developers


=head1 AUTHOR

Lutz Gehlen, C<< <perl at lutzgehlen.de> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Lutz Gehlen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

