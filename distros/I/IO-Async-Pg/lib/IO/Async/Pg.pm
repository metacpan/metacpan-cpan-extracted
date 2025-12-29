package IO::Async::Pg;

use strict;
use warnings;
use parent 'IO::Async::Notifier';

use Future::AsyncAwait;
use DBI;
use DBD::Pg;

use IO::Async::Pg::Connection;
use IO::Async::Pg::Error;
use IO::Async::Pg::PubSub;
use IO::Async::Pg::Util qw(parse_dsn);

our $VERSION = '0.001001';

sub _init {
    my ($self, $params) = @_;

    # Required
    $self->{dsn} = delete $params->{dsn}
        or die "dsn is required";

    # Pool configuration
    $self->{min_connections} = delete $params->{min_connections} // 1;
    $self->{max_connections} = delete $params->{max_connections} // 10;
    $self->{idle_timeout}    = delete $params->{idle_timeout}    // 300;
    $self->{queue_timeout}   = delete $params->{queue_timeout}   // 30;
    $self->{connect_timeout} = delete $params->{connect_timeout} // 30;
    $self->{statement_timeout} = delete $params->{statement_timeout};
    $self->{max_queries}     = delete $params->{max_queries};

    # Callbacks
    $self->{on_connect} = delete $params->{on_connect};
    $self->{on_release} = delete $params->{on_release};
    $self->{on_log}     = delete $params->{on_log};

    # Pool state
    $self->{idle}    = [];
    $self->{active}  = [];
    $self->{waiting} = [];
    $self->{pid}     = $$;

    # Stats
    $self->{stats} = {
        created          => 0,
        released         => 0,
        discarded        => 0,
        connect_failures => 0,
        timeouts         => 0,
    };

    # Parse DSN once
    $self->{_parsed_dsn} = parse_dsn($self->{dsn});

    $self->SUPER::_init($params);
}

sub _add_to_loop {
    my ($self, $loop) = @_;
    $self->SUPER::_add_to_loop($loop);

    # Record PID for fork detection
    $self->{pid} = $$;

    # Ensure minimum connections (non-blocking)
    $self->_ensure_min_connections;
}

# Accessors
sub min_connections { shift->{min_connections} }
sub max_connections { shift->{max_connections} }
sub idle_count      { scalar @{shift->{idle}} }
sub active_count    { scalar @{shift->{active}} }
sub waiting_count   { scalar @{shift->{waiting}} }
sub total_count     { my $s = shift; scalar(@{$s->{idle}}) + scalar(@{$s->{active}}) }
sub stats           { shift->{stats} }
sub safe_dsn        { IO::Async::Pg::Util::safe_dsn(shift->{dsn}) }

sub is_healthy {
    my ($self) = @_;
    return $self->total_count > 0 || $self->waiting_count < $self->{max_connections};
}

# Get a connection from the pool
async sub connection {
    my ($self) = @_;

    $self->_check_fork;

    # 1. Try to get an idle connection
    if (my $conn = shift @{$self->{idle}}) {
        push @{$self->{active}}, $conn;
        $conn->{last_used} = time();
        $conn->{released} = 0;
        return $conn;
    }

    # 2. Create new connection if under limit
    if ($self->total_count < $self->{max_connections}) {
        my $conn = await $self->_create_connection;
        push @{$self->{active}}, $conn;
        return $conn;
    }

    # 3. Queue and wait
    my $future = $self->loop->new_future;
    my $waiting = {
        future    => $future,
        queued_at => time(),
    };
    push @{$self->{waiting}}, $waiting;

    # Set up timeout
    my $timeout_future;
    if (my $timeout = $self->{queue_timeout}) {
        $timeout_future = $self->loop->delay_future(after => $timeout);
        $timeout_future->on_done(sub {
            @{$self->{waiting}} = grep { $_ != $waiting } @{$self->{waiting}};
            $self->{stats}{timeouts}++;
            $future->fail(
                IO::Async::Pg::Error::PoolExhausted->new(
                    message   => "Connection pool exhausted (waited ${timeout}s)",
                    pool_size => $self->{max_connections},
                )
            ) unless $future->is_ready;
        });
    }

    my $conn = await $future;
    $timeout_future->cancel if $timeout_future && !$timeout_future->is_ready;
    return $conn;
}

# Create a PubSub instance for LISTEN/NOTIFY
sub pubsub {
    my ($self) = @_;

    my $pubsub = IO::Async::Pg::PubSub->new(pool => $self);
    $self->add_child($pubsub);

    return $pubsub;
}

# Create a new connection
async sub _create_connection {
    my ($self) = @_;

    my $parsed = $self->{_parsed_dsn};

    my %attrs = (
        AutoCommit        => 1,
        RaiseError        => 1,
        PrintError        => 0,
        pg_enable_utf8    => 1,
        pg_server_prepare => 1,
    );

    my $dbh = eval {
        DBI->connect(
            $parsed->{dbi_dsn},
            $parsed->{user},
            $parsed->{password},
            \%attrs,
        );
    };

    if ($@ || !$dbh) {
        my $err = $@ || DBI->errstr || 'Unknown connection error';
        $self->{stats}{connect_failures}++;
        die IO::Async::Pg::Error::Connection->new(
            message => "Connection failed: $err",
            dsn     => $self->safe_dsn,
        );
    }

    # Set statement timeout if configured
    if (my $timeout = $self->{statement_timeout}) {
        $dbh->do("SET statement_timeout = '${timeout}s'");
    }

    my $conn = IO::Async::Pg::Connection->new(
        dbh         => $dbh,
        pool        => $self,
        created_at  => time(),
        query_count => 0,
    );

    $self->add_child($conn);

    # Run on_connect callback
    if (my $on_connect = $self->{on_connect}) {
        eval { await $on_connect->($conn) };
        if ($@) {
            $self->_log(warn => "on_connect failed: $@");
            $conn->_close_dbh;
            $self->remove_child($conn);
            $self->{stats}{connect_failures}++;
            die $@;
        }
    }

    $self->{stats}{created}++;
    return $conn;
}

# Return connection to pool (called by Connection::release)
sub _return_connection {
    my ($self, $conn) = @_;

    # Remove from active list
    @{$self->{active}} = grep { $_ != $conn } @{$self->{active}};

    # Check if connection is still valid
    if (!$conn->{dbh} || !$conn->{dbh}->ping) {
        $self->_discard_connection($conn);
        return;
    }

    # Check max_queries limit
    if ($self->{max_queries} && $conn->query_count >= $self->{max_queries}) {
        $self->_discard_connection($conn);
        $self->_ensure_min_connections;
        return;
    }

    # Run on_release callback
    if (my $on_release = $self->{on_release}) {
        my $cleanup = async sub {
            eval {
                # Reset connection state
                await $conn->query('ROLLBACK') if $conn->{in_transaction};
                await $on_release->($conn);
            };
            if ($@) {
                $self->_log(warn => "on_release failed: $@");
                $self->_discard_connection($conn);
                return;
            }
            $self->_release_to_idle_or_waiting($conn);
        };
        $cleanup->()->retain;
    }
    else {
        $self->_release_to_idle_or_waiting($conn);
    }
}

sub _release_to_idle_or_waiting {
    my ($self, $conn) = @_;

    # If someone is waiting, give them this connection
    if (my $waiting = shift @{$self->{waiting}}) {
        push @{$self->{active}}, $conn;
        $conn->{last_used} = time();
        $conn->{released} = 0;
        $waiting->{future}->done($conn);
        return;
    }

    # Otherwise return to idle pool
    push @{$self->{idle}}, $conn;
    $self->{stats}{released}++;
}

sub _discard_connection {
    my ($self, $conn) = @_;
    $conn->_close_dbh;
    eval { $self->remove_child($conn) };
    $self->{stats}{discarded}++;
}

sub _ensure_min_connections {
    my ($self) = @_;

    my $needed = $self->{min_connections} - $self->total_count;
    return if $needed <= 0;

    # Create connections in parallel (fire and forget)
    for (1 .. $needed) {
        my $f = $self->_create_connection;
        $f->on_done(sub {
            my ($conn) = @_;
            push @{$self->{idle}}, $conn;
        });
        $f->on_fail(sub {
            my ($err) = @_;
            $self->_log(warn => "Failed to create initial connection: $err");
        });
        $f->retain;
    }
}

sub _check_fork {
    my ($self) = @_;
    if ($self->{pid} != $$) {
        # We've forked - discard all connections
        @{$self->{idle}} = ();
        @{$self->{active}} = ();
        $self->{pid} = $$;
    }
}

sub _log {
    my ($self, $level, $message) = @_;
    if (my $cb = $self->{on_log}) {
        $cb->($level, $message);
    }
    else {
        warn "IO::Async::Pg [$level]: $message\n";
    }
}

1;

__END__

=head1 NAME

IO::Async::Pg - Async PostgreSQL client for IO::Async

=head1 SYNOPSIS

    use IO::Async::Loop;
    use IO::Async::Pg;

    my $loop = IO::Async::Loop->new;
    my $pg = IO::Async::Pg->new(
        dsn             => 'postgresql://user:pass@host/db',
        min_connections => 2,
        max_connections => 10,
    );
    $loop->add($pg);

    my $conn = await $pg->connection;
    my $result = await $conn->query('SELECT * FROM users WHERE id = $1', $id);
    print $result->first->{name};

=head1 DESCRIPTION

B<WARNING: This is extremely beta software.> The API is subject to change
without notice. The author reserves the right to redesign, rename, or remove
any part of the interface as the module matures. Use in production at your
own peril.

IO::Async::Pg provides an async PostgreSQL client built on IO::Async and
DBD::Pg's async query support. Features include:

=over 4

=item * Connection pooling with automatic management

=item * Named and positional placeholders

=item * Transaction support with savepoints

=item * Cursor-based streaming for large result sets

=item * LISTEN/NOTIFY pub/sub

=back

=head1 AUTHOR

John Napiorkowski E<lt>jjn1056@yahoo.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
