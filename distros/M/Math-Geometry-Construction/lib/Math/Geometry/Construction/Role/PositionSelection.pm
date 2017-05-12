package Math::Geometry::Construction::Role::PositionSelection;
use Moose::Role;

use 5.008008;

use Math::Geometry::Construction::Vector;
use Math::Geometry::Construction::Types qw(Vector);
use MooseX::Params::Validate 0.13;
use Math::Vector::Real;
use Carp;

=head1 NAME

C<Math::Geometry::Construction::Role::PositionSelection> - select position from list

=head1 VERSION

Version 0.024

=cut

our $VERSION = '0.024';


###########################################################################
#                                                                         #
#                               Accessors                                 # 
#                                                                         #
###########################################################################

requires 'id';
requires 'positions';

###########################################################################
#                                                                         #
#                             Retrieve Data                               #
#                                                                         #
###########################################################################

sub indexed_position {
    my ($self, $index) = @_;
    my @positions      = grep { defined($_) } $self->positions;

    croak "Undefined index in 'indexed_position' selector"
	if(!defined($index));
    
    if(!@positions) {
	warn sprintf("No positions to select from in %s.\n", $self->id);
	return undef;
    }
    if($index < 0 or $index >= @positions) {
	warn sprintf("Position index out of range in %s.\n", $self->id);
	return undef;
    }

    return($positions[$index]);
}

sub extreme_position {
    my $self        = shift;
    my ($direction) = map { $_->value } pos_validated_list
	(\@_, {isa => Vector, coerce => 1});
    
    my $d = abs($direction);
    return undef if($d == 0);

    my $norm      = $direction / $d;
    my @positions = grep { defined($_) } $self->positions;

    if(!@positions) {
	warn sprintf("No positions to select from in %s.\n", $self->id);
	return undef;
    }

    return((map  { $_->[0] }
	    sort { $b->[1] <=> $a->[1] }
	    map  { [$_, $_ * $norm] }
	    @positions)[0]);
}

sub close_position {
    my $self        = shift;
    my ($reference) = map { $_->value } pos_validated_list
	(\@_, {isa => Vector, coerce => 1});
    
    my @positions = grep { defined($_) } $self->positions;

    if(!@positions) {
	warn sprintf("No positions to select from in %s.\n", $self->id);
	return undef;
    }

    return((map  { $_->[0] }
	    sort { $a->[1] <=> $b->[1] }
	    map  { [$_, abs($_ - $reference)] }
	    @positions)[0]);
}

sub distant_position {
    my $self        = shift;
    my ($reference) = map { $_->value } pos_validated_list
	(\@_, {isa => Vector, coerce => 1});
    
    my @positions = grep { defined($_) } $self->positions;

    if(!@positions) {
	warn sprintf("No positions to select from in %s.\n", $self->id);
	return undef;
    }

    return((map  { $_->[0] }
	    sort { $b->[1] <=> $a->[1] }
	    map  { [$_, abs($_ - $reference)] }
	    @positions)[0]);
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

