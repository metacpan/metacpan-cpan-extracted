package Math::Geometry::Construction::Derivate::IntersectionLineLine;
use Moose;
extends 'Math::Geometry::Construction::Derivate';

use 5.008008;

use Math::Geometry::Construction::Types qw(LineLine);
use Carp;
use List::MoreUtils qw(any);
use Math::Vector::Real;
use Math::MatrixReal;

=head1 NAME

C<Math::Geometry::Construction::Derivate::IntersectionLineLine> - line line intersection

=head1 VERSION

Version 0.024

=cut

our $VERSION = '0.024';


###########################################################################
#                                                                         #
#                               Accessors                                 # 
#                                                                         #
###########################################################################

has 'input' => (isa      => LineLine,
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
    my ($self) = @_;
    my @lines  = $self->input;

    my @normals   = ();
    my @constants = ();
    foreach(@lines) {
	my @support           = $_->support;
	my @support_positions = map { $_->position } @support;

	return undef if(any { !defined($_) } @support_positions);
	
	my $this_normal = $_->normal;
	push(@normals, $this_normal);
	push(@constants, $this_normal * $support_positions[0]);
    }

    my $matrix = Math::MatrixReal->new_from_rows([map { [@$_] } @normals]);

    return if($matrix->det == 0);  # check to prevent carp from inverse
    my $inverse = $matrix->inverse;
    return if(!$inverse);  # only possible - if at all - for num. reasons

    return V($inverse->element(1, 1) * $constants[0] +
	     $inverse->element(1, 2) * $constants[1],
	     $inverse->element(2, 1) * $constants[0] +
	     $inverse->element(2, 2) * $constants[1]);
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

