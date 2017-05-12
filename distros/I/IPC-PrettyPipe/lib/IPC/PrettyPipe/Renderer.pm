# --8<--8<--8<--8<--
#
# Copyright (C) 2014 Smithsonian Astrophysical Observatory
#
# This file is part of IPC::PrettyPipe
#
# IPC::PrettyPipe is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# -->8-->8-->8-->8--

package IPC::PrettyPipe::Renderer;

use Moo::Role;

requires qw[ render ];

1;

__END__

=head1 NAME

B<IPC::PrettyPipe::Renderer> - role for renderer backends

=head1 SYNOPSIS

  package IPC::PrettyPipe::Render::My::Backend;

  sub render { }

  with 'IPC::PrettyPipe::Renderer';

=head1 DESCRIPTION

This role defines the required interface for rendering backends for
B<L<IPC::PrettyPipe>>.  Backend classes must consume this role.


=head1 METHODS

The following methods must be defined:

=over

=item B<render>

Return the rendered the pipeline.

=back


=head1 COPYRIGHT & LICENSE

Copyright 2014 Smithsonian Astrophysical Observatory

This software is released under the GNU General Public License.  You
may find a copy at

   http://www.fsf.org/copyleft/gpl.html


=head1 AUTHOR

Diab Jerius E<lt>djerius@cfa.harvard.eduE<gt>

=cut
