package DhMakePerl::Command::refresh_cache;

=head1 NAME

DhMakePerl::Command::refresh_cache - dh-make-perl refresh-cache implementation

=head1 DESCRIPTION

This module implements the I<refresh-cache> command of L<dh-make-perl(1)>.

=cut

use strict; use warnings;

our $VERSION = '0.65';

use base 'DhMakePerl';

=head1 METHODS

=over

=item execute

Provides I<refresh-cache> command implementation.

=cut

sub execute {
    my $self = shift;

    $self->get_apt_contents;

    return 0;
}

=back

=cut

1;

=head1 COPYRIGHT & LICENSE

=over

=item Copyright (C) 2008, 2009, 2010 Damyan Ivanov <dmn@debian.org>

=back

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License version 2 as published by the Free
Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 51 Franklin
Street, Fifth Floor, Boston, MA 02110-1301 USA.

=cut

