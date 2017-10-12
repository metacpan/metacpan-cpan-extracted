package JLogger::Storage::DB;

use strict;
use warnings;

use base 'JLogger::Storage';

use DBIx::Connector;

my %handlers = (message => \&_save_message);

sub init {
    my $self = shift;

    $self->{_connector} =
      DBIx::Connector->new($self->{source}, $self->{username},
        $self->{password},
        {RaiseError => 1, AutoCommit => 1, %{$self->{attr} || {}}});

    $self->{_jid_cache} = {};
}

sub store {
    my ($self, $message) = @_;

    if (my $handler = $handlers{$message->{type}}) {
        return $handler->($self, $message);
    }
    warn "Unknown type: $message->{type}\n";
}

sub _save_message {
    my ($self, $message) = @_;

    my ($sender,    $sender_resource)    = split '/', $message->{from}, 2;
    my ($recipient, $recipient_resource) = split '/', $message->{to},   2;

    my $sql = <<'SQL';
INSERT
    INTO messages(
        sender, sender_resource, recipient, recipient_resource,
        type, body, thread)
VALUES(?, ?, ?, ?, ?, ?, ?)
SQL

    $self->{_connector}->dbh->do(
        $sql,                           undef,
        $self->_get_jid_id($sender),    $sender_resource,
        $self->_get_jid_id($recipient), $recipient_resource,
        @{$message}{qw/message_type body thread/}
    );
}

sub _get_jid_id {
    my ($self, $jid) = @_;

    if (my $id = $self->{_cache}->{$jid}) {
        return $id;
    }

    my $id =
      $self->{_connector}
      ->dbh->selectrow_array('SELECT id FROM identificators WHERE jid = ?',
        undef, $jid);
    unless (defined $id) {
        $id = $self->_create_jid($jid);
    }

    $self->{_cache}->{$jid} = $id;
}

sub _create_jid {
    my ($self, $jid) = @_;

    my $dbh = $self->{_connector}->dbh;

    $dbh->do('INSERT INTO identificators(jid) VALUES(?)', undef, $jid);
    $dbh->last_insert_id(undef, undef, 'identificators', undef);
}

1;
__END__

=head1 NAME

JLogger::Storage::DB - store messages in database

=head1 SYNOPSIS

General config in C<config.yaml>
    storages:
        - JLogger::Storage::DB:
            source: <dbi storage string>
            username: <database username>
            password: <database password>
            attr: <additional connection parameters>

=head1 DESCRIPTION

Stores logged messages in a database. Before storing messages you need to load
schema. Schema files can be found in C<schema/> directory.

=head1 EXAMPLES

Sample configuration strings for C<config.xml> for different databases.

=head2 SQLite

    storages:
        - JLogger::Storage::DB:
            source: dbi:SQLite:jlogger.sql

=head2 MySQL

    storages:
        - JLogger::Storage::DB:
            source: dbi:mysql:database=jlogger
            username: mysql_username
            password: mysql_password

=head2 PostgreSQL

    storage:
        - JLogger::Storage::DB:
            source: dbi:Pg:dbname=jlogger
            username: pg_username
            password: pg_password

=cut
