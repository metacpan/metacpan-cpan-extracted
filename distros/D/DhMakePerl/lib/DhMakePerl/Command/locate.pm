package DhMakePerl::Command::locate;

=head1 NAME

DhMakePerl::Command::locate - dh-make-perl locate implementation

=head1 DESCRIPTION

This module implements the I<locate> command of L<dh-make-perl(1)>.

=cut

use strict; use warnings;

our $VERSION = '0.81';

use base 'DhMakePerl';

use DhMakePerl::Utils qw(is_core_module);

=head1 METHODS

=over

=item execute

Provides I<locate> command implementation.

=cut

sub execute {
    my $self = shift;

    @ARGV >= 1
        or die "locate command requires at least one non-option argument\n";

    my $apt_contents = $self->get_apt_contents;

    unless ($apt_contents) {
        die <<EOF;
Unable to locate module packages, because APT Contents files
are not available on the system.

Install the 'apt-file' package, run 'apt-file update' as root
and retry.
EOF
    }

    my $result = 0;
    for my $mod (@ARGV) {
        if ( defined( my $core_since = is_core_module($mod) ) ) {
            print "$mod is in Perl core (package perl)";
            print $core_since ? " since $core_since\n" : "\n";
        }
        elsif ( my $pkg = $apt_contents->find_perl_module_package($mod) ) {
            print "$mod is in $pkg package\n";
        }
        else {
            print "$mod is not found in any Debian package\n";
            $result = 1;
        }
    }

    return $result;
}

=back

=cut

1;

=head1 COPYRIGHT & LICENSE

=over

=item Copyright (C) 2009 Franck Joncourt <franck.mail@dthconnex.com>

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

