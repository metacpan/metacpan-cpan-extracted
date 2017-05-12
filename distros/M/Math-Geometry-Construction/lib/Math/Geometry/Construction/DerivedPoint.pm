package Math::Geometry::Construction::DerivedPoint;
use Moose;
extends 'Math::Geometry::Construction::Point';

use 5.008008;

use Math::Geometry::Construction::Types qw(Derivate);
use Carp;

=head1 NAME

C<Math::Geometry::Construction::DerivedPoint> - point derived from other objects, e.g. intersection point

=head1 VERSION

Version 0.019

=cut

our $VERSION = '0.019';


###########################################################################
#                                                                         #
#                      Class Variables and Methods                        # 
#                                                                         #
###########################################################################

our $ID_TEMPLATE = 'S%09d';

sub id_template { return $ID_TEMPLATE }

###########################################################################
#                                                                         #
#                               Accessors                                 # 
#                                                                         #
###########################################################################

with 'Math::Geometry::Construction::Role::Object';
with 'Math::Geometry::Construction::Role::Output';
with 'Math::Geometry::Construction::Role::Buffering';

has 'derivate'          => (isa      => Derivate,
			    is       => 'ro',
			    required => 1);

has 'position_selector' => (isa      => 'ArrayRef[Defined]',
			    is       => 'ro',
			    reader   => '_position_selector',
			    default  => sub { ['indexed_position', [0]] },
			    required => 1);

###########################################################################
#                                                                         #
#                             Retrieve Data                               #
#                                                                         #
###########################################################################

sub position {
    my ($self) = @_;

    return $self->buffer('position') if($self->is_buffered('position'));

    my ($selection_method, $args) = @{$self->_position_selector};
    my $position = $self->derivate->$selection_method(@$args);

    $self->buffer('position', $position)
	if($self->construction->buffer_results);
    return $position;
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

=head3 draw

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

