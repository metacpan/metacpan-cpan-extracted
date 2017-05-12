package DhMakePerl::Command::help;

=head1 NAME

DhMakePerl::Command::help - dh-make-perl help implementation

=head1 DESCRIPTION

This module implements the I<help> command of L<dh-make-perl(1)>.

=cut

use strict; use warnings;

our $VERSION = '0.65';

use base 'DhMakePerl';
use Pod::Usage;

=head1 METHODS

=over

=item execute

Provides I<help> command implementation.

=cut

sub execute {
    my $self = shift;

    # Help requested? Nice, we can just die! Isn't it helpful?
    die pod2usage( -message => "See `man 1 dh-make-perl' for details.\n" )
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

