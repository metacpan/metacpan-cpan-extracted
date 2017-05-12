package Eve::PgSqlConnection;

use parent qw(Eve::Class);

use strict;
use warnings;

use DBI;

=head1 NAME

B<Eve::PgSqlConnection> - a class for PostgreSQL connection.

=head1 SYNOPSIS

    my $pgsql_connection = Eve::PgSqlConnection->new(
        host => 'localhost', port => '5432', database => 'somedb',
        user => 'someuser', password => 'somepassword', schema => 'someschema');

=head1 DESCRIPTION

B<Eve::PgSqlConnection> is an adapter class for PostgreSQL
connection. It adapts B<DBI>'s database handle with B<DBD::Pg> driver
and encapsulates connection establishing mechanisms and confuguring
practices.

=head3 Attributes

=over 4

=item C<dbh>

a service attribute containing a data base handle (not for regular
use).

=back

=head3 Constructor arguments

=over 4

=item C<host>

=item C<port>

=item C<database>

=item C<user>

=item C<password>

=item C<schema>

=back

For default argument values see the B<DBD::Pg> documentation.

=head1 METHODS

=head2 B<init()>

=cut

sub init {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(
        \%arg_hash,
        my ($host, $port, $database, $user, $password, $schema) =
           (\undef) x 6);

    $self->{'dbh'} = DBI->connect(
        'dbi:Pg:dbname='.($database or '').';host='.($host or '').
        ';port='.($port or ''), $user, $password,
        {
             RaiseError => 1, ShowErrorStatement => 1, AutoCommit => 1,
             pg_server_prepare => 1, pg_enable_utf8 => 1
         });

    return;
}

=head1 SEE ALSO

=over 4

=item L<DBI>

=item L<DBD::Pg>

=item L<Eve::Class>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Igor Zinovyev.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=head1 AUTHOR

=over 4

=item L<Sergey Konoplev|mailto:gray.ru@gmail.com>

=back

=cut

1;
