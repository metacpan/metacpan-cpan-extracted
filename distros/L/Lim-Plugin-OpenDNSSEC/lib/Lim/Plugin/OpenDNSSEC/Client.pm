package Lim::Plugin::OpenDNSSEC::Client;

use common::sense;

use Lim::Plugin::OpenDNSSEC ();

use base qw(Lim::Component::Client);

=encoding utf8

=head1 NAME

...

=head1 VERSION

See L<Lim::Plugin::OpenDNSSEC> for version.

=cut

our $VERSION = $Lim::Plugin::OpenDNSSEC::VERSION;

=head1 SYNOPSIS

...

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim-plugin-opendnssec/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lim::Plugin::OpenDNSSEC

You can also look for information at:

=over 4

=item * Lim issue tracker (report bugs here)

L<https://github.com/jelu/lim-plugin-opendnssec/issues>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Jerry Lundström.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lim::Plugin::OpenDNSSEC::Client
