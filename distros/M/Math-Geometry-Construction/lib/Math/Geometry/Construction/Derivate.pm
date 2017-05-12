package Math::Geometry::Construction::Derivate;

use 5.008008;

use Math::Geometry::Construction::Types qw(ArrayRefOfGeometricObject);
use Moose;
use Carp;

=head1 NAME

C<Math::Geometry::Construction::Derivate> - derive points from objects

=head1 VERSION

Version 0.019

=cut

our $VERSION = '0.019';


###########################################################################
#                                                                         #
#                      Class Variables and Methods                        # 
#                                                                         #
###########################################################################

our $ID_TEMPLATE = 'D%09d';

sub id_template { return $ID_TEMPLATE }

###########################################################################
#                                                                         #
#                               Accessors                                 # 
#                                                                         #
###########################################################################

with 'Math::Geometry::Construction::Role::Object';
with 'Math::Geometry::Construction::Role::PositionSelection';
with 'Math::Geometry::Construction::Role::Buffering';

###########################################################################
#                                                                         #
#                             Retrieve Data                               #
#                                                                         #
###########################################################################

sub calculate_positions { return }

sub positions {
    my ($self) = @_;

    return(@{$self->buffer('positions') || []})
	if($self->is_buffered('positions'));

    my $positions = [$self->calculate_positions];

    $self->buffer('positions', $positions)
	if($self->construction->buffer_results);
    return @$positions;
}

sub register_derived_point {}

sub create_derived_point {
    my ($self, %args) = @_;

    my $point = $self->construction->add_object
	('Math::Geometry::Construction::DerivedPoint',
	 derivate => $self,
	 %args);

    $self->register_derived_point($point);
    
    return $point;
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


=head1 DESCRIPTION


=head1 INTERFACE

=head2 Public Attributes

=head2 Methods for Users

=head2 Methods for Subclass Developers

=head3 create_derived_point

=head3 id_template


=head1 AUTHOR

Lutz Gehlen, C<< <perl at lutzgehlen.de> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Lutz Gehlen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

