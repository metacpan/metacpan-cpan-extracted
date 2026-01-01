package IPC::Manager::Client::PostgreSQL;
use strict;
use warnings;

our $VERSION = '0.000001';

use Carp qw/croak/;
use File::Temp qw/tempdir/;

use DBI;

use parent 'IPC::Manager::Base::DBI';
use Object::HashBase qw{
    +QDB
};

sub escape { '"' }

sub dsn { $_[0]->{+ROUTE} }

sub table_sql {
    return (
        <<"        EOT",
            CREATE TABLE IF NOT EXISTS ipcm_peers(
                "id"        VARCHAR(36)     NOT NULL PRIMARY KEY,
                "pid"       INTEGER         DEFAULT NULL,
                "active"    BOOL            NOT NULL DEFAULT TRUE,
                "stats"     BYTEA           DEFAULT NULL
            );
        EOT
        <<"        EOT",
            CREATE TABLE IF NOT EXISTS ipcm_messages(
                "id"        UUID            NOT NULL PRIMARY KEY,
                "to"        VARCHAR(36)     NOT NULL REFERENCES ipcm_peers(id) ON DELETE CASCADE,
                "from"      VARCHAR(36)     NOT NULL REFERENCES ipcm_peers(id) ON DELETE CASCADE,
                "stamp"     NUMERIC         NOT NULL,
                "content"   BYTEA           NOT NULL,
                "broadcast" BOOL            NOT NULL DEFAULT FALSE
            );
        EOT
    );
}

sub default_attrs { +{ AutoCommit => 1 } }

sub spawn {
    my $class = shift;
    my (%params) = @_;

    my $dsn = $params{route};

    unless ($dsn) {
        require DBIx::QuickDB;
        my $qdb = DBIx::QuickDB->build_db(pg_db => {driver => 'PostgreSQL'});
        $params{+QDB}  = $qdb;
        $params{+ROUTE} = $qdb->connect_string;
        $params{+USER} = $qdb->username;
        $params{+PASS} = $qdb->password;

        $dsn = $params{+ROUTE};
    }

    $class->init_db(%params, dsn => $dsn);

    return ($dsn, $params{+QDB});
}

sub unspawn {
    my $self = shift;
    my ($route, $stash) = @_;

    undef($stash);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Manager::Client::PostgreSQL - Use PostgreSQL as a message store.

=head1 DESCRIPTION

A table 'ipcm_clients' is used to track clients, and a table 'ipcm_messages' is
used to hold messages.

=head1 SYNOPSIS

    use IPC::Manager qw/ipcm_spawn ipcm_connect/;

    my $spawn = ipcm_spawn(protocol => 'PostgreSQL');

    my $con1 = $spawn->connect('con1');
    my $con2 = ipcm_connect(con2, $spawn->info);

    $con1->send_message(con1 => {'hello' => 'con2'});

    my @messages = $con2->get_messages;

=head1 METHODS

See L<IPC::Manager::Client>.

=head1 SOURCE

The source code repository for IPC::Manager can be found at
L<https://https://github.com/exodist/IPC-Manager>.

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
