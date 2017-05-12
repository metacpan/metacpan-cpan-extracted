package Math::Geometry::Construction::Role::Object;
use Moose::Role;

use 5.008008;

use Math::Geometry::Construction::Types qw(Construction);
use Carp;

=head1 NAME

C<Math::Geometry::Construction::Role::Object> - shared administrative issues

=head1 VERSION

Version 0.024

=cut

our $VERSION = '0.024';


###########################################################################
#                                                                         #
#                               Accessors                                 # 
#                                                                         #
###########################################################################

requires 'id_template';

has 'id'           => (isa      => 'Str',
		       is       => 'ro',
		       required => 1,
		       lazy     => 1,
		       builder  => '_generate_id');

has 'order_index'  => (isa      => 'Int',
		       is       => 'ro',
		       required => 1);

has 'construction' => (isa      => Construction,
		       is       => 'ro',
		       required => 1,
		       weak_ref => 1);

###########################################################################
#                                                                         #
#                             Retrieve Data                               #
#                                                                         #
###########################################################################

sub _generate_id {
    my ($self) = @_;
    
    return sprintf($self->id_template, $self->order_index);
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

=head3 as_svg


=head1 AUTHOR

Lutz Gehlen, C<< <perl at lutzgehlen.de> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2011, 2013 Lutz Gehlen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

