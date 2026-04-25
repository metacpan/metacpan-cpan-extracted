package IPC::Manager::DBI;
use strict;
use warnings;

our $VERSION = '0.000033';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Manager::DBI - Database based clients for L<IPC::Manager>.

=head1 DESCRIPTION

These are all based off of L<IPC::Manager::Base::DBI>. These all use a database
as the message store.

These all have 1 table for tracking clients, and another for tracking messages.
Messages are deleted once read. The 'route' is a DSN. You also usually need to
provide a username and password.

    my $con = ipcm_connect(my_con => $info, user => $USER, pass => $PASS);

=over 4

=item MariaDB

L<IPC::Manager::Client::MariaDB>

=item MySQL

L<IPC::Manager::Client::MySQL>

=item PostgreSQL

L<IPC::Manager::Client::PostgreSQL>

=item SQLite

L<IPC::Manager::Client::SQLite>

=back

=head1 SOURCE

The source code repository for IPC::Manager can be found at
L<https://github.com/exodist/IPC-Manager>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
