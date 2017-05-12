package Math::Geometry::Construction::Derivate::IntersectionCircleCircle;
use Moose;
extends 'Math::Geometry::Construction::Derivate';

use 5.008008;

use Math::Geometry::Construction::Types qw(CircleCircle);
use Carp;
use Math::Vector::Real;

=head1 NAME

C<Math::Geometry::Construction::Derivate::IntersectionCircleCircle> - circle circle intersection

=head1 VERSION

Version 0.024

=cut

our $VERSION = '0.024';


###########################################################################
#                                                                         #
#                               Accessors                                 # 
#                                                                         #
###########################################################################

has 'input' => (isa      => CircleCircle,
		is       => 'bare',
		traits   => ['Array'],
		required => 1,
		handles  => {count_input  => 'count',
			     input        => 'elements',
			     single_input => 'accessor'});

###########################################################################
#                                                                         #
#                             Retrieve Data                               #
#                                                                         #
###########################################################################

sub calculate_positions {
    my ($self)  = @_;
    my @circles = $self->input;

    # currently assuming that points have to be defined
    my @center_p = map { $_->center->position  } @circles;
    my @radii    = map { $_->radius            } @circles;

    foreach(@center_p, @radii) { return if(!defined($_)) }

    my $distance = $center_p[1] - $center_p[0];
    my $d        = abs($distance);
    return if($d == 0);

    my $parallel = $distance / $d;
    my $normal   = $parallel->normal_base;

    my $x   = ($d**2 - $radii[1]**2 + $radii[0]**2) / (2 * $d);
    my $rad = $radii[0]**2 - $x**2;
    return if($rad < 0);

    my $y = sqrt($rad);
    return($center_p[0] + $parallel * $x + $normal * $y,
	   $center_p[0] + $parallel * $x - $normal * $y);
}

###########################################################################
#                                                                         #
#                              Change Data                                # 
#                                                                         #
###########################################################################

sub register_derived_point {
    my ($self, $point) = @_;

    foreach($self->input) { $_->register_point($point) }
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

Copyright 2011, 2013 Lutz Gehlen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

