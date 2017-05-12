#############################################################################
#
# Provides a to_hash() method for NewBug/NewAttachment/etc classes
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 01/24/2009 11:03:09 AM PST
#
# Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::Bugzilla::Role::NewHash;

use Moose::Role;

#use English qw{ -no_match_vars };  # Avoids regex performance penalty

#use namespace::clean -except => meta;

our $VERSION = '0.13';

sub to_hash {
    my $self = shift @_;

    # get all our attributes (including parent classes if we're subclassed)
    my @all_attrs = $self->meta->get_all_attributes;
    my @atts;

    for my $att (@all_attrs) {

        my $has = 'has_' . $att->name;
        push @atts, $att->name
            if $self->$has;
    }

    #my %data = map { $_ => $self->$_ } @atts;
    my %data = map { my $v = $self->$_; $_ => $v } @atts;

    ### %data

    return \%data;
}


1;

__END__

=head1 NAME

Fedora::Bugzilla::Role::NewHash - Provide a 'to_hash' method 

=head1 DESCRIPTION

Allows for the easy creation of "new" classes, by scanning all attributes and
returning a hashref of { attribute_name => value, ... }.


=head1 SUBROUTINES/METHODS

=head2 to_hash()

Returns a hashref of all attributes we have to their values.

=head1 SEE ALSO

L<Moose::Role>

=head1 BUGS AND LIMITATIONS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or (preferably) 
add the bug to the camelus ticket tracker at 
L<https://fedorahosted.org/camelus/newticket>.

Patches are welcome.

=head1 AUTHOR

Chris Weyl  <cweyl@alumni.drew.edu>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the 

    Free Software Foundation, Inc.
    59 Temple Place, Suite 330
    Boston, MA  02111-1307  USA

=cut

