package IPC::Manager::Base::DBI;
use strict;
use warnings;

our $VERSION = '0.000037';

use Carp qw/croak/;
use Scalar::Util qw/blessed/;
use Time::HiRes qw/time/;
use File::Temp qw/tempfile/;

use DBI 1.644;

use parent 'IPC::Manager::Client';
use Object::HashBase qw{
    +dbh
    <user
    <pass
    <attrs
};

sub dsn       { croak "Not Implemented" }
sub table_sql { croak "Not Implemented" }

sub escape    { '' }
sub blob_type { DBI::SQL_BLOB }

sub pending_messages { 0 }
sub ready_messages   { $_[0]->_get_message_ids ? 1 : 0 }

sub dbh {
    my $this = shift;
    my (%params) = @_;

    if ($params{dbh}) {
        $this->{+DBH} = $params{dbh} if blessed($this);
        return $params{dbh};
    }

    if (blessed($this) && $this->{+DBH}) {
        $this->pid_check;

        # During global destruction DBI's tied inner handle may already
        # be torn down; probing ->{Active} then emits
        # "Can't call method 'FETCH' on an undefined value".  Guard the
        # probe so we transparently fall through to reconnect instead.
        my $active;
        {
            local $SIG{__WARN__} = sub { };
            local $@;
            $active = eval { $this->{+DBH}->{Active} };
        }

        return $this->{+DBH} if $active;
        delete $this->{+DBH};
    }

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

sub route_from_dbh {
    my ($class_or_self, $dbh) = @_;
    return "dbi:" . $dbh->{Driver}->{Name} . ":" . $dbh->{Name};
}

sub init_db {
    my $this = shift;

    my $dbh = $this->dbh(@_);

    for my $sql ($this->table_sql) {
        local $dbh->{PrintWarn} = 0;
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

    if ($self->{+RECONNECT} && !$row) {
        $self->{disconnected} = 1;
        croak "The '$id' peer does not exist";
    }

    if ($row && $row->{pid} && $self->pid_is_running($row->{pid})) {
        $self->{disconnected} = 1;
        croak "Looks like the connection is already running in pid $row->{pid}";
    }

    my $dbh = $self->dbh;
    my $e   = $self->escape;

    if ($row) {
        # Predecessor died without pre_disconnect_hook (SIGKILL etc).
        # Reap stale inbox + stats; suspended rows (pid IS NULL) are left alone.
        if ($row->{pid} && !$self->pid_is_running($row->{pid})) {
            my $del_msgs  = $dbh->prepare("DELETE FROM ipcm_messages WHERE ${e}to${e} = ?")               or die $dbh->errstr;
            my $clr_stats = $dbh->prepare("UPDATE ipcm_peers SET ${e}stats${e} = NULL WHERE ${e}id${e} = ?") or die $dbh->errstr;
            $del_msgs->execute($self->{+ID})  or die $dbh->errstr;
            $clr_stats->execute($self->{+ID}) or die $dbh->errstr;
        }

        my $sth = $dbh->prepare("UPDATE ipcm_peers SET ${e}active${e} = ?, ${e}pid${e} = ?, ${e}suspend_expires${e} = NULL WHERE ${e}id${e} = ?") or die $dbh->errstr;
        $sth->execute(time, $self->{+PID}, $self->{+ID}) or die $dbh->errstr;
    }
    else {
        my $sth = $dbh->prepare("INSERT INTO ipcm_peers(${e}id${e}, ${e}pid${e}, ${e}active${e}) VALUES (?, ?, ?)") or die $dbh->errstr;
        $sth->execute($id, $self->{+PID}, time) or die $dbh->errstr;
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
    $sth->bind_param(1, $self->{+SERIALIZER}->serialize($self->{+STATS}), $self->blob_type);
    $sth->bind_param(2, $self->{+ID});
    $sth->execute or die $dbh->errstr;
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
    my $sth = $dbh->prepare("SELECT ${e}id${e}, ${e}pid${e} FROM ipcm_peers WHERE ${e}id${e} != ? AND active IS NOT NULL ORDER BY ${e}id${e} ASC") or die $dbh->errstr;
    $sth->execute($self->{+ID});

    my @out;
    while (my $row = $sth->fetchrow_arrayref) {
        my ($id, $pid) = @$row;
        next if $pid && !$self->pid_is_running($pid);
        push @out => $id;
    }

    return @out;
}

sub peer_left {
    my $self = shift;

    my $dbh = $self->dbh;
    my $e   = $self->escape;

    my $sth = $dbh->prepare("SELECT ${e}id${e}, ${e}pid${e} FROM ipcm_peers WHERE ${e}id${e} != ? AND active IS NOT NULL") or die $dbh->errstr;
    $sth->execute($self->{+ID}) or die $dbh->errstr;

    my @dead;
    while (my $row = $sth->fetchrow_arrayref) {
        my ($id, $pid) = @$row;
        next unless $pid;
        next if $self->pid_is_running($pid);
        push @dead => $id;
    }

    return 0 unless @dead;

    my $del_peers = $dbh->prepare("DELETE FROM ipcm_peers WHERE ${e}id${e} = ?")    or die $dbh->errstr;
    my $del_msgs  = $dbh->prepare("DELETE FROM ipcm_messages WHERE ${e}to${e} = ?") or die $dbh->errstr;
    for my $id (@dead) {
        $del_msgs->execute($id)  or die $dbh->errstr;
        $del_peers->execute($id) or die $dbh->errstr;
    }

    return scalar @dead;
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

    my $peer_id = $msg->to or croak "Message has no peer";
    croak "Client '$peer_id' does not exist" unless $self->peer_exists($peer_id);

    my $dbh = $self->dbh;
    my $e   = $self->escape;
    my $sth = $dbh->prepare("INSERT INTO ipcm_messages(${e}id${e}, ${e}from${e}, ${e}to${e}, ${e}stamp${e}, ${e}broadcast${e}, ${e}content${e}) VALUES (?, ?, ?, ?, ?, ?)")
        or die $dbh->errstr;

    my $content = $self->{+SERIALIZER}->serialize($msg->{content});
    $sth->bind_param(1, $msg->{id});
    $sth->bind_param(2, $msg->{from});
    $sth->bind_param(3, $msg->{to});
    $sth->bind_param(4, $msg->{stamp});
    $sth->bind_param(5, $msg->{broadcast} ? 1 : 0);
    $sth->bind_param(6, $content, $self->blob_type);
    $sth->execute or die $dbh->errstr;

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
    my $sth   = $dbh->prepare("SELECT * $where ORDER BY ${e}stamp${e} ASC") or die $dbh->errstr;
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
    my $sth = $dbh->prepare("UPDATE ipcm_peers SET ${e}pid${e} = NULL, ${e}active${e} = NULL, ${e}suspend_expires${e} = NULL WHERE ${e}id${e} = ?") or die $dbh->errstr;
    $sth->execute($self->{+ID}) or die $dbh->errstr;
}

sub pre_suspend_hook {
    my $self = shift;
    my (%params) = @_;

    my $expires_at = $params{expires_at};

    my $dbh = $self->dbh;
    my $e   = $self->escape;

    my $sth = $dbh->prepare("UPDATE ipcm_peers SET ${e}pid${e} = NULL, ${e}suspend_expires${e} = ? WHERE ${e}id${e} = ?") or die $dbh->errstr;
    $sth->execute(defined($expires_at) ? $expires_at + 0 : undef, $self->{+ID}) or die $dbh->errstr;
}

sub peer_suspend_expires {
    my $self = shift;
    my ($peer_id) = @_;
    return undef unless defined $peer_id && length $peer_id;

    my $dbh = $self->dbh;
    my $e   = $self->escape;

    my $sth = $dbh->prepare("SELECT ${e}suspend_expires${e} FROM ipcm_peers WHERE ${e}id${e} = ?") or die $dbh->errstr;
    $sth->execute($peer_id) or die $dbh->errstr;

    my $row = $sth->fetchrow_arrayref;
    $sth->finish;
    return undef unless $row && defined $row->[0];
    return $row->[0] + 0;
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

You may pass C<< dbh => $dbh >> to reuse an already-connected DBI handle
instead of having C<init_db> open one from the DSN.

=item $dbh = $class_or_obj->dbh(dbh => $dbh)

=item $dbh = $obj->dbh

=item $dbh = $class->dbh(dsn => $dsn, user => $u, pass => $p, attrs => \%a)

Get the database handle. When called with a C<< dbh => $dbh >> parameter
the supplied handle is returned (and cached on an instance) without
consulting the DSN. Without that parameter, an instance returns its cached
handle if it is still active, otherwise reconnects via C<< DBI->connect >>
using the instance's stored DSN / user / pass / attrs. As a class method
this unconditionally opens a fresh connection from the supplied parameters.

=item $route = $class_or_obj->route_from_dbh($dbh)

Reassemble a route from a connected DBI handle. The default builds
C<< "dbi:$drv:$name" >> from C<< $dbh->{Driver}{Name} >> and
C<< $dbh->{Name} >>. L<IPC::Manager::Client::SQLite> overrides this to
return the bare db file path because that is its route format.

This is what C<ipcm_spawn(dbh => $dbh)> calls to derive the route stored on
the resulting Spawn object's info string. See
L<IPC::Manager/"Spawning against an existing DBI handle">.

=item $password = $con->pass

Connection password.

=item @sql = $class->table_sql

Get the table schema in SQL format to apply to the database.

=item $username = $con->user

Connection username.

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
