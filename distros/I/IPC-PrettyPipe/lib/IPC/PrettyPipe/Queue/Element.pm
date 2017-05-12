#! perl

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


package IPC::PrettyPipe::Queue::Element;

use Moo::Role;

has last => (
    is => 'rwp',
    default => sub { 0 },
    init_arg => undef,
);

has first => (
    is => 'rwp',
    default => sub { 0 },
    init_arg => undef,
);

1;


__END__

=head1 NAME

B<IPC::PrettyPipe::Queue::Element> - role for an element in an B<IPC::PrettyPipe::Queue>

=head1 SYNOPSIS

  with 'IPC::PrettyPipe::Queue::Element';


=head1 DESCRIPTION

This role should be composed into objects which will be contained in
B<L<IPC::PrettyPipe::Queue>> objects.  No object should be in more than one
queue at a time.


=head1 METHODS

The following methods are available:


=over

=item first

  $is_first = $element->first;

This returns true if the element is the first in its containing queue.

=item last

  $is_last = $element->last;

This returns true if the element is the last in its containing queue.

=back


=head1 COPYRIGHT & LICENSE

Copyright 2014 Smithsonian Astrophysical Observatory

This software is released under the GNU General Public License.  You
may find a copy at

   http://www.fsf.org/copyleft/gpl.html


=head1 AUTHOR

Diab Jerius E<lt>djerius@cfa.harvard.eduE<gt>

=cut
