package Math::Geometry::Construction::Derivate::TranslatedPoint;
use Moose;
extends 'Math::Geometry::Construction::Derivate';

use 5.008008;

use Math::Geometry::Construction::Types qw(Vector Point);
use Carp;
use Math::Vector::Real;

=head1 NAME

C<Math::Geometry::Construction::Derivate::TranslatedPoint> - point translated by a given vector

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

has 'input'      => (isa       => Point,
		     coerce    => 1,
		     is        => 'ro',
		     required  => 1);

has 'translator' => (isa      => Vector,
		     coerce   => 1,
		     is       => 'rw',
		     required => 1,
		     trigger  => \&clear_global_buffer);

###########################################################################
#                                                                         #
#                             Retrieve Data                               #
#                                                                         #
###########################################################################

sub calculate_positions {
    my ($self)    = @_;
    my $reference = $self->input;

    my $position = $reference->position;
    return if(!$position);

    return($position + $self->translator->value);
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


=head1 AUTHOR

Lutz Gehlen, C<< <perl at lutzgehlen.de> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2011, 2013 Lutz Gehlen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

