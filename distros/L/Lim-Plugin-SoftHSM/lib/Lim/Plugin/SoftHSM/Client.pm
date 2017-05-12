package Lim::Plugin::SoftHSM::Client;

use common::sense;

use Lim::Plugin::SoftHSM ();

use base qw(Lim::Component::Client);

=encoding utf8

=head1 NAME

Lim::Plugin::SoftHSM::Client - Client class for SoftHSM management plugin

=head1 VERSION

See L<Lim::Plugin::SoftHSM> for version.

=cut

our $VERSION = $Lim::Plugin::SoftHSM::VERSION;

=head1 SYNOPSIS

  use Lim::Plugin::SoftHSM;

  # Create a Client object
  $client = Lim::Plugin::SoftHSM->Client;

=head1 METHODS

All methods are auto generated from the call definitions.

See L<Lim::Plugin::SoftHSM> for list of calls and arguments.

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim-plugin-softhsm/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lim::Plugin::SoftHSM

You can also look for information at:

=over 4

=item * Lim issue tracker (report bugs here)

L<https://github.com/jelu/lim-plugin-softhsm/issues>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Jerry Lundström.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lim::Plugin::SoftHSM::Client
