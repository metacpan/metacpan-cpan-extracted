package IPC::Manager::Base::DBI;
use strict;
use warnings;

our $VERSION = '0.000001';

use Carp qw/croak/;
use Scalar::Util qw/blessed/;
use File::Temp qw/tempfile/;

use DBI;

use parent 'IPC::Manager::Client';
use Object::HashBase qw{
    +dbh
    <user
    <pass
    <attrs
};

sub dsn       { croak "Not Implemented" }
sub table_sql { croak "Not Implemented" }

sub escape { '' }

sub pending_messages { 0 }
sub ready_messages   { $_[0]->_get_message_ids ? 1 : 0 }

sub dbh {
    my $this = shift;
    my (%params) = @_;

    return $this->{+DBH} if blessed($this) && $this->{+DBH};

    my $dsn   = $params{dsn};
    my $user  = $params{user};
    my $pass  = $params{pass};
    my $attrs = $params{attrs};

    if (blessed($this)) {
        $this->pid_check;
        $dsn   //= $this->dsn;
        $user  //= $this->user;
        $pass  //= $this->pass;
        $attrs //= $this->attrs;
    }

    croak "No DSN" unless $dsn;
    $attrs //= {};

    my $dbh = DBI->connect($dsn, $user, $pass, $attrs) or die "Could not connect";

    $this->{+DBH} = $dbh if blessed($this);

    return $dbh;
}

sub init_db {
    my $this = shift;

    my $dbh = $this->dbh(@_);

    for my $sql ($this->table_sql) {
        $dbh->do($sql) or die $dbh->errstr;
    }
}

sub default_attrs {}

sub init {
    my $self = shift;

    $self->SUPER::init();

    $self->{+USER} //= delete $self->{username} // '';
    $self->{+PASS} //= delete $self->{password} // '';

    $self->{+ATTRS} //= $self->default_attrs;

    my $id = $self->{+ID};

    my $row = $self->_get_peer($self->{+ID});

    croak "The '$id' peer does not exist" if $self->{+RECONNECT} && !$row;

    croak "Looks like the connection is already running in pid $row->{pid}"
        if $row && $row->{pid} && $self->pid_is_running($row->{pid});

    my $dbh = $self->dbh;
    my $e   = $self->escape;

    if ($row) {
        my $sth = $dbh->prepare("UPDATE ipcm_peers SET ${e}active${e} = TRUE, ${e}pid${e} = ? WHERE ${e}id${e} = ?");
        $sth->execute($self->{+PID}, $self->{+ID}) or die $dbh->errstr;
    }
    else {
        my $sth = $dbh->prepare("INSERT INTO ipcm_peers(${e}id${e}, ${e}pid${e}, ${e}active${e}) VALUES (?, ?, TRUE)") or die $dbh->errstr;
        $sth->execute($id, $self->{+PID}) or die $dbh->errstr;
    }
}

sub all_stats {
    my $self = shift;

    my $out = {};

    my $dbh = $self->dbh;
    my $e   = $self->escape;
    my $sth = $dbh->prepare("SELECT ${e}id${e}, ${e}stats${e} FROM ipcm_peers") or die $dbh->errstr;
    $sth->execute() or die $dbh->errstr;

    while (my $row = $sth->fetchrow_arrayref) {
        $out->{$row->[0]} = $self->{+SERIALIZER}->deserialize($row->[1]);
    }

    return $out;
}

sub write_stats {
    my $self = shift;

    my $dbh = $self->dbh;
    my $e   = $self->escape;
    my $sth = $dbh->prepare("UPDATE ipcm_peers SET ${e}stats${e} = ? WHERE ${e}id${e} = ?") or die $dbh->errstr;
    $sth->execute($self->{+SERIALIZER}->serialize($self->{+STATS}), $self->{+ID}) or die $dbh->errstr;
}

sub read_stats {
    my $self = shift;

    my $dbh = $self->dbh;
    my $e   = $self->escape;
    my $sth = $dbh->prepare("SELECT ${e}stats${e} FROM ipcm_peers WHERE ${e}id${e} = ?") or die $dbh->errstr;
    $sth->execute($self->{+ID}) or die $dbh->errstr;

    my $row = $sth->fetchrow_arrayref or return undef;
    return $self->{+SERIALIZER}->deserialize($row->[0]);
}

sub peers {
    my $self = shift;

    my $dbh = $self->dbh;
    my $e   = $self->escape;
    my $sth = $dbh->prepare("SELECT ${e}id${e} FROM ipcm_peers WHERE ${e}id${e} != ? AND active = TRUE ORDER BY ${e}id${e} ASC") or die $dbh->errstr;
    $sth->execute($self->{+ID});

    return map { $_->[0] } @{$sth->fetchall_arrayref([0])};
}

sub peer_pid {
    my $self = shift;
    my ($id) = @_;

    my $row = $self->_get_peer($id) or return undef;
    return $row->{pid} // undef if $row->{active};
    return undef;
}

sub peer_exists {
    my $self = shift;
    my ($id) = @_;
    return $self->_get_peer($id) ? 1 : 0;
}

sub _get_peer {
    my $self = shift;
    my ($id) = @_;

    my $dbh = $self->dbh;
    my $e   = $self->escape;
    my $sth = $dbh->prepare("SELECT * FROM ipcm_peers WHERE ${e}id${e} = ?") or die $dbh->errstr;
    $sth->execute($id);
    return $sth->fetchrow_hashref;
}

sub send_message {
    my $self = shift;
    my $msg = $self->build_message(@_);

    my $dbh = $self->dbh;
    my $e   = $self->escape;
    my $sth = $dbh->prepare("INSERT INTO ipcm_messages(${e}id${e}, ${e}from${e}, ${e}to${e}, ${e}stamp${e}, ${e}broadcast${e}, ${e}content${e}) VALUES (?, ?, ?, ?, ?, ?)")
        or die $dbh->errstr;

    $sth->execute(
        @{$msg}{qw/id from to stamp/},
        ($msg->{broadcast} ? 1 : 0),
        $self->{+SERIALIZER}->serialize($msg->{content}),
    ) or die $dbh->errstr;

    $self->{+STATS}->{sent}->{$msg->{to}}++;
}

sub _get_message_ids {
    my $self = shift;
    my $dbh  = $self->dbh;
    my $e    = $self->escape;
    my $sth  = $dbh->prepare("SELECT ${e}id${e} FROM ipcm_messages WHERE ${e}to${e} = ? ORDER BY ${e}stamp${e} ASC") or die $dbh->errstr;
    $sth->execute($self->{+ID}) or die $dbh->errstr;
    my $ids = [map { $_->[0] } @{$sth->fetchall_arrayref([0])}];
    return $ids if $ids && @$ids;
    return;
}

sub get_messages {
    my $self = shift;
    my $dbh  = $self->dbh;

    my $ids = $self->_get_message_ids or return;

    my $e     = $self->escape;
    my $where = "FROM ipcm_messages WHERE ${e}id${e} IN (" . join(', ' => map { '?' } 1 .. scalar(@$ids)) . ")";
    my $sth   = $dbh->prepare("SELECT * $where") or die $dbh->errstr;
    $sth->execute(@$ids) or die $dbh->errstr;
    my $rows = $sth->fetchall_arrayref({});

    my @out;

    for my $row (@$rows) {
        $row->{content} = $self->{+SERIALIZER}->deserialize($row->{content});
        $self->{+STATS}->{read}->{$row->{from}}++;
        push @out => IPC::Manager::Message->new($row);
    }

    $sth = $dbh->prepare("DELETE $where") or die $dbh->errstr;
    $sth->execute(@$ids)                  or die $dbh->errstr;


    return @out;
}

sub requeue_message {
    my $self = shift;
    $self->send_message($_) for @_;
}

sub pre_disconnect_hook {
    my $self = shift;

    my $dbh = $self->dbh;
    my $e   = $self->escape;
    my $sth = $dbh->prepare("UPDATE ipcm_peers SET ${e}pid${e} = NULL, active = FALSE WHERE ${e}id${e} = ?") or die $dbh->errstr;
    $sth->execute($self->{+ID}) or die $dbh->errstr;
}

sub pre_suspend_hook {
    my $self = shift;

    my $dbh = $self->dbh;
    my $e   = $self->escape;
    my $sth = $dbh->prepare("UPDATE ipcm_peers SET ${e}pid${e} = NULL WHERE ${e}id${e} = ?") or die $dbh->errstr;
    $sth->execute($self->{+ID}) or die $dbh->errstr;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Manager::Base::DBI - Base class for DBI based protocols

=head1 DESCRIPTION

This is the base class for DBI based message stores and protocols.

=head1 METHODS

See L<IPC::Manager::Client> for inherited methods

=head2 DBI SPECIFIC

=over 4

=item $hashref = $con->attrs

Get the attributes used for this database connection.

=item $dbh = $con->dbh()

=item $dbh = $class->dbh(dsn => $dsn, user => $user, pass => $password, attrs => {...})

Get the database handle. Can be used on an instance, or on the class with
parameters.

=item $attrs = $con_or_class->default_attrs()

Default attributes to be used for connections when none are specified. Returns
undef unless overriden by a subclass.

=item $dsn = $con->dsn

Get the dsn used for the connection.

=item $str = $con->escape

Used to escape column names. Each protocol can specify a custom one, for
example mysql and sqlite use '`', but postgresql uses '"'.

=item $class->init_db(%params)

Used during spawn to put the necessary tables into the database if they are not
already present.

=item $password = $con->pass

Connection password.

=item @sql = $class->table_sql

Get the table schema in SQL format to apply to the database.

=item $username = $con->user

Connection username.

=back

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
