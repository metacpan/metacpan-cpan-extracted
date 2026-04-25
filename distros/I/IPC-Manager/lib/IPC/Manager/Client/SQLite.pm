package IPC::Manager::Client::SQLite;
use strict;
use warnings;

our $VERSION = '0.000033';

use Carp qw/croak/;
use File::Temp qw/tempfile/;

use DBI 1.644;

sub _viable {
    require DBIx::QuickDB;
    DBIx::QuickDB->VERSION('0.000040');
    DBIx::QuickDB->check_driver('DBIx::QuickDB::Driver::SQLite', {});
    my ($ok, $fqn, $why) = DBIx::QuickDB->check_driver('DBIx::QuickDB::Driver::SQLite', {bootstrap => 1, autostart => 1});
    die $why unless $ok;
    1;
}

use parent 'IPC::Manager::Base::DBI';
use Object::HashBase;

sub dsn { "dbi:SQLite:dbname=" . (@_ > 1 ? $_[1] : $_[0]->{+ROUTE}) }

sub escape { '`' }

sub table_sql {
    return (
        <<"        EOT",
            CREATE TABLE IF NOT EXISTS ipcm_peers(
                `id`        VARCHAR(512)    NOT NULL PRIMARY KEY,
                `pid`       INTEGER         DEFAULT NULL,
                `active`    REAL            DEFAULT (strftime('%s', 'now')),
                `stats`     BLOB            DEFAULT NULL
            );
        EOT
        <<"        EOT",
            CREATE TABLE IF NOT EXISTS ipcm_messages(
                `id`        UUID            NOT NULL PRIMARY KEY,
                `to`        VARCHAR(512)    NOT NULL REFERENCES ipcm_peers(id) ON DELETE CASCADE,
                `from`      VARCHAR(512)    NOT NULL REFERENCES ipcm_peers(id) ON DELETE CASCADE,
                `stamp`     REAL            NOT NULL,
                `content`   BLOB            NOT NULL,
                `broadcast` BOOL            NOT NULL DEFAULT 0
            );
        EOT
    );
}

sub spawn {
    my $class = shift;
    my (%params) = @_;

    my $dbfile = delete $params{route};
    unless ($dbfile) {
        my $template = delete $params{template} // "PerlIPCManager-$$-XXXXXX";
        my ($fh, $file) = tempfile($template, TMPDIR => 1, CLEANUP => 0, SUFFIX => '.sqlite', EXLOCK => 0);
        $dbfile = $file;
    }

    $params{dsn} //= $class->dsn($dbfile);

    $class->init_db(%params);

    return "$dbfile";
}

sub unspawn {
    my $class = shift;
    my ($route) = @_;
    unlink($route);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Manager::Client::SQLite - Use SQLite as a message store.

=head1 DESCRIPTION

A table 'ipcm_clients' is used to track clients, and a table 'ipcm_messages' is
used to hold messages.

=head1 SYNOPSIS

    use IPC::Manager qw/ipcm_spawn ipcm_connect/;

    my $spawn = ipcm_spawn(protocol => 'SQLite');

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
