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

package IPC::PrettyPipe::Arg::Format;

use Moo;

use Carp;

use Types::Standard qw[ Str ];

with 'IPC::PrettyPipe::Format';

shadowable_attrs( qw[ pfx sep ] );

has pfx => (
    is        => 'rw',
    isa       => Str,
    clearer   => 1,
    predicate => 1,
);

has sep => (
    is        => 'rw',
    isa       => Str,
    clearer   => 1,
    predicate => 1,
);

sub copy_into { $_[0]->_copy_attrs( $_[1], 'sep', 'pfx' ); }


1;

__END__


=head1 NAME

B<IPC::PrettyPipe::Arg::Format> - Encapsulate argument formatting attributes


=head1 SYNOPSIS

  use IPC::PrettyPipe::Arg::Format;

  $fmt = IPC::PrettyPipe::Arg::Format->new( %attr );

=head1 DESCRIPTION

This class encapsulates argument formatting attributes


=head1 FUNCTIONS


=over

=item B<new>

  $fmt = IPC::PrettyPipe::Arg::Format->new( %attr );

The constructor.  The following attributes are available:

=over

=item pfx

The prefix to apply to an argument

=item sep

The string which will separate option names and values.  If C<undef> (the default),
option names and values will be treated as separate entities.

=back


=back

=head1 COPYRIGHT & LICENSE

Copyright 2014 Smithsonian Astrophysical Observatory

This software is released under the GNU General Public License.  You
may find a copy at

   http://www.fsf.org/copyleft/gpl.html


=head1 AUTHOR

Diab Jerius E<lt>djerius@cfa.harvard.eduE<gt>
