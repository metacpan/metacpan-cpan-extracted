package IPC::Manager::Client::MariaDB;
use strict;
use warnings;

our $VERSION = '0.000030';

use Carp qw/croak/;
use File::Temp qw/tempdir/;

use DBI 1.644;

use parent 'IPC::Manager::Base::DBI';
use Object::HashBase qw{
    +QDB
};

sub _viable {
    require DBD::MariaDB;
    DBD::MariaDB->VERSION('1.00');
    require DBIx::QuickDB;
    DBIx::QuickDB->VERSION('0.000040');
    my ($ok, $fqn, $why) = DBIx::QuickDB->check_driver('DBIx::QuickDB::Driver::MariaDB', {bootstrap => 1, autostart => 1});
    die $why unless $ok;
    1;
}

sub dsn       { $_[0]->{+ROUTE} }
sub blob_type { DBI::SQL_BINARY }

sub escape { '`' }

sub default_attrs { +{ AutoCommit => 1 } }

sub table_sql {
    return (
        <<"        EOT",
            CREATE TABLE IF NOT EXISTS ipcm_peers(
                `id`        VARCHAR(512)    NOT NULL PRIMARY KEY,
                `pid`       INTEGER         DEFAULT NULL,
                `active`    DOUBLE          DEFAULT UNIX_TIMESTAMP(),
                `stats`     BLOB            DEFAULT NULL
            );
        EOT
        <<"        EOT",
            CREATE TABLE IF NOT EXISTS ipcm_messages(
                `id`        UUID            NOT NULL PRIMARY KEY,
                `to`        VARCHAR(512)    NOT NULL REFERENCES ipcm_peers(id) ON DELETE CASCADE,
                `from`      VARCHAR(512)    NOT NULL REFERENCES ipcm_peers(id) ON DELETE CASCADE,
                `stamp`     DOUBLE          NOT NULL,
                `content`   BLOB            NOT NULL,
                `broadcast` BOOL            NOT NULL DEFAULT FALSE
            );
        EOT
    );
}

sub spawn {
    my $class = shift;
    my (%params) = @_;

    my $dsn = $params{route};

    unless ($dsn) {
        require DBIx::QuickDB;
        my $qdb = DBIx::QuickDB->build_db(m_db => {driver => 'MariaDB'});
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

IPC::Manager::Client::MariaDB - Use MariaDB as a message store.

=head1 DESCRIPTION

A table 'ipcm_clients' is used to track clients, and a table 'ipcm_messages' is
used to hold messages.

=head1 SYNOPSIS

    use IPC::Manager qw/ipcm_spawn ipcm_connect/;

    my $spawn = ipcm_spawn(protocol => 'MariaDB');

    my $con1 = $spawn->connect('con1');
    my $con2 = ipcm_connect(con2, $spawn->info);

    $con1->send_message(con1 => {'hello' => 'con2'});

    my @messages = $con2->get_messages;

=head1 METHODS

See L<IPC::Manager::Client>.

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
