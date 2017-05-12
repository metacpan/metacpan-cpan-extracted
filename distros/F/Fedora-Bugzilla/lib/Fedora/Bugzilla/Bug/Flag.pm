#############################################################################
#
# Small class representing a flag on a bug
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 01/04/2009 12:38:31 PM PST
#
# Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::Bugzilla::Bug::Flag;

use Moose;

use Fedora::Bugzilla::Types 'EmailAddress';

use namespace::clean;

use overload '""' => sub { shift->status }, fallback => 1;

our $VERSION = '0.13';

has [ qw{ name status } ] => (is => 'ro', isa => 'Str', required => 1);
has setter => (is => 'ro', isa => EmailAddress, required => 1, coerce => 1);

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Fedora::Bugzilla::Bug::Flag - A set flag on a bug

=head1 SYNOPSIS

    # ...
    my $flag = $bug->get_flag('fedora-cvs');


=head1 DESCRIPTION

A little class describing a flag set on a bug.


=head1 ATTRIBUTES

=head2 name

The flag name; e.g. 'fedora-review'.

=head2 status

? / + / -.

=head2 setter

Email addy of the person who last touched the flag.

=head1 SEE ALSO

L<Fedora::Bugzilla::Bug>.

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

