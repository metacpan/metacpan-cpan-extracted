package DhMakePerl::Command::dump_config;

=head1 NAME

DhMakePerl::Command::dump_config - dh-make-perl dump-config implementation

=cut

use strict; use warnings;

our $VERSION = '0.65';

use base 'DhMakePerl';

=head1 METHODS

=over

=item execute

The main command entry point.

=cut

sub execute {
    my $self = shift;

    print $self->cfg->dump_config;

    return 0;
}

=back

=head1 COPYRIGHT & LICENSE

=over

=item Copyright (C) 2009, 2010 Damyan Ivanov <dmn@debian.org>

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


1;
