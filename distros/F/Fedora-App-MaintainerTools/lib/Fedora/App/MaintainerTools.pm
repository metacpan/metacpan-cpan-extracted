#############################################################################
#
# The application class...
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 06/16/2009
#
# Copyright (c) 2009  <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::App::MaintainerTools;

use Moose;
use namespace::autoclean;

our $VERSION = '0.006';

extends 'MooseX::App::Cmd';

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Fedora::App::MaintainerTools - Main application class

=head1 DESCRIPTION

This is the main application class for MaintainerTools; we don't do much
except extend L<MooseX::App::Cmd> as required.

More extensive documentation should be available as part of the man page
for the command line app, L<maintainertool>.

=head1 SEE ALSO

L<maintainertool>

=head1 BUGS AND LIMITATIONS

This is still a VERY early release; while I don't believe it'll eat any of
your files, if it does, you get to keep both pieces :)

Please report problems to Chris Weyl <cweyl@alumni.drew.edu>, or (preferred)
to this package's RT tracker at E<bug-Fedora-App-MaintainerTools@rt.cpan.org>.

Patches are welcome.

=head1 AUTHOR

Chris Weyl  <cweyl@alumni.drew.edu>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009  <cweyl@alumni.drew.edu>

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


