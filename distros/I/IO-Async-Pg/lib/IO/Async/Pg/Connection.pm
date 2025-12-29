package IO::Async::Pg::Connection;

use strict;
use warnings;
use parent 'IO::Async::Notifier';

use Future::AsyncAwait;
use IO::Async::Handle;
use DBD::Pg qw(:async);

use IO::Async::Pg::Cursor;
use IO::Async::Pg::Error;
use IO::Async::Pg::Results;
use IO::Async::Pg::Util qw(convert_placeholders);

sub _init {
    my ($self, $params) = @_;
    $self->{dbh}            = delete $params->{dbh};
    $self->{pool}           = delete $params->{pool};
    $self->{created_at}     = delete $params->{created_at} // time();
    $self->{query_count}    = delete $params->{query_count} // 0;
    $self->{last_used}      = time();
    $self->{released}       = 0;
    $self->{in_transaction} = 0;
    $self->SUPER::_init($params);
}

# Accessors
sub dbh            { shift->{dbh} }
sub pool           { shift->{pool} }
sub last_used      { shift->{last_used} }
sub query_count    { shift->{query_count} }
sub created_at     { shift->{created_at} }
sub in_transaction { shift->{in_transaction} }
sub is_released    { shift->{released} }

# Execute a query asynchronously
async sub query {
    my ($self, $sql, @args) = @_;

    # Parse arguments: can be positional values, hashref for named, or options
    my ($bind, $opts) = $self->_parse_query_args(@args);

    # Convert named placeholders if hashref provided
    if (ref $bind eq 'HASH') {
        ($sql, $bind) = convert_placeholders($sql, $bind);
    }

    $self->{query_count}++;
    $self->{last_used} = time();

    # Execute with optional timeout
    my $result;
    if (my $timeout = $opts->{timeout}) {
        $result = await $self->_query_with_timeout($sql, $bind, $timeout);
    }
    else {
        $result = await $self->_execute_async($sql, $bind);
    }

    return $result;
}

# Parse query arguments into bind values and options
sub _parse_query_args {
    my ($self, @args) = @_;

    my $opts = {};
    my $bind = [];

    # Check if last arg is options hash
    if (@args && ref $args[-1] eq 'HASH') {
        my $last = $args[-1];
        # Distinguish between named placeholders and options
        if (exists $last->{timeout}) {
            $opts = pop @args;
        }
    }

    # Remaining args are bind values
    if (@args == 1 && ref $args[0] eq 'HASH') {
        $bind = $args[0];  # Named placeholders
    }
    elsif (@args) {
        $bind = \@args;    # Positional placeholders
    }

    return ($bind, $opts);
}

# Execute async query with timeout
async sub _query_with_timeout {
    my ($self, $sql, $bind, $timeout) = @_;

    my $query_future = $self->_execute_async($sql, $bind);
    my $timer = $self->loop->delay_future(after => $timeout);

    my $winner = await Future->wait_any($query_future, $timer);

    if ($winner == $timer) {
        # Timer won - cancel the query
        $self->cancel;

        # Wait for query to finish with error
        eval { await $query_future };

        die IO::Async::Pg::Error::Timeout->new(
            message => "Query timeout after ${timeout}s",
            timeout => $timeout,
        );
    }

    return $winner->get;
}

# Core async query execution using DBD::Pg async support
async sub _execute_async {
    my ($self, $sql, $bind) = @_;
    $bind //= [];

    my $dbh = $self->{dbh};

    # Prepare statement
    my $sth = eval { $dbh->prepare($sql, { pg_async => PG_ASYNC }) };
    if ($@ || !$sth) {
        $self->_throw_query_error($@ || $dbh->errstr, $sql);
    }

    # Execute with bind values
    my $rv = eval {
        if (ref $bind eq 'ARRAY' && @$bind) {
            $sth->execute(@$bind);
        }
        else {
            $sth->execute;
        }
    };

    if ($@ || !defined $rv) {
        $self->_throw_query_error($@ || $sth->errstr || $dbh->errstr, $sql);
    }

    # Wait for async result
    await $self->_wait_for_result($dbh);

    # Get result
    my $result = eval { $dbh->pg_result };
    if ($@ || !$result) {
        $self->_throw_query_error($@ || $dbh->errstr, $sql);
    }

    return IO::Async::Pg::Results->new($sth);
}

# Wait for PostgreSQL socket to be readable
async sub _wait_for_result {
    my ($self, $dbh) = @_;

    my $socket_fd = $dbh->{pg_socket};
    die "No PostgreSQL socket" unless defined $socket_fd;

    my $future = $self->loop->new_future;

    # Create handle to watch the socket
    my $handle;
    $handle = IO::Async::Handle->new(
        read_fileno => $socket_fd,
        want_readready => 1,
        on_read_ready => sub {
            # Check if result is ready
            if ($dbh->pg_ready) {
                $self->loop->remove($handle);
                $future->done;
            }
            # else keep waiting
        },
    );

    $self->loop->add($handle);

    # Ensure cleanup on cancellation
    $future->on_cancel(sub {
        $self->loop->remove($handle) if $handle->loop;
    });

    await $future;
}

# Cancel current query
sub cancel {
    my ($self) = @_;
    eval { $self->{dbh}->pg_cancel };
}

# Execute code within a transaction
async sub transaction {
    my ($self, $code, %opts) = @_;

    my $isolation = $opts{isolation};
    my $savepoint_depth = $self->{_savepoint_depth} // 0;

    if ($savepoint_depth > 0) {
        # Nested transaction - use savepoint
        my $savepoint = "sp_$savepoint_depth";
        await $self->query("SAVEPOINT $savepoint");

        $self->{_savepoint_depth} = $savepoint_depth + 1;

        my $result = eval { await $code->($self) };
        my $err = $@;

        $self->{_savepoint_depth} = $savepoint_depth;

        if ($err) {
            await $self->query("ROLLBACK TO SAVEPOINT $savepoint");
            die $err;
        }

        await $self->query("RELEASE SAVEPOINT $savepoint");
        return $result;
    }
    else {
        # Top-level transaction
        my $begin = 'BEGIN';
        if ($isolation) {
            my $level = uc($isolation);
            $level =~ s/_/ /g;  # read_committed -> READ COMMITTED
            $begin .= " ISOLATION LEVEL $level";
        }
        await $self->query($begin);
        $self->{in_transaction} = 1;

        $self->{_savepoint_depth} = 1;

        my $result = eval { await $code->($self) };
        my $err = $@;

        $self->{_savepoint_depth} = 0;

        if ($err) {
            eval { await $self->query('ROLLBACK') };
            $self->{in_transaction} = 0;
            die $err;
        }

        await $self->query('COMMIT');
        $self->{in_transaction} = 0;
        return $result;
    }
}

# Create a streaming cursor for large result sets
async sub cursor {
    my ($self, $sql, @args) = @_;

    # Parse arguments: can be positional values, hashref for named, or options
    my ($bind, $opts) = $self->_parse_cursor_args(@args);

    # Convert named placeholders if hashref provided
    if (ref $bind eq 'HASH') {
        ($sql, $bind) = convert_placeholders($sql, $bind);
    }

    my $batch_size = delete $opts->{batch_size} // 1000;
    my $cursor_name = delete $opts->{name} // IO::Async::Pg::Cursor::_generate_name();

    # Must be in a transaction for cursors
    my $was_in_transaction = $self->{in_transaction};
    if (!$was_in_transaction) {
        await $self->query('BEGIN');
        $self->{in_transaction} = 1;
    }

    # Build DECLARE CURSOR statement
    my $declare_sql = "DECLARE $cursor_name CURSOR FOR $sql";

    # Execute the DECLARE
    if (ref $bind eq 'ARRAY' && @$bind) {
        await $self->query($declare_sql, @$bind);
    }
    else {
        await $self->query($declare_sql);
    }

    my $cursor = IO::Async::Pg::Cursor->new(
        name       => $cursor_name,
        batch_size => $batch_size,
        conn       => $self,
        _owns_transaction => !$was_in_transaction,
    );

    return $cursor;
}

# Parse cursor arguments into bind values and options
sub _parse_cursor_args {
    my ($self, @args) = @_;

    my $opts = {};
    my $bind = [];

    # Check if last arg is options hash (contains cursor-specific keys)
    if (@args && ref $args[-1] eq 'HASH') {
        my $last = $args[-1];
        # Distinguish between named placeholders and options
        if (exists $last->{batch_size} || exists $last->{name}) {
            $opts = pop @args;
        }
    }

    # Remaining args are bind values
    if (@args == 1 && ref $args[0] eq 'HASH') {
        $bind = $args[0];  # Named placeholders
    }
    elsif (@args) {
        $bind = \@args;    # Positional placeholders
    }

    return ($bind, $opts);
}

# Release connection back to pool
sub release {
    my ($self) = @_;
    return if $self->{released};
    $self->{released} = 1;

    if (my $pool = $self->{pool}) {
        $pool->_return_connection($self);
    }
}

# Close the underlying database handle
sub _close_dbh {
    my ($self) = @_;
    if ($self->{dbh}) {
        eval { $self->{dbh}->disconnect };
        $self->{dbh} = undef;
    }
}

# Auto-release on destruction
sub DESTROY {
    my ($self) = @_;

    # During global destruction, don't try to release to pool
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT';

    $self->release unless $self->{released};
    $self->_close_dbh;
}

# Throw a query error with PostgreSQL details
sub _throw_query_error {
    my ($self, $err, $sql) = @_;

    my $dbh = $self->{dbh};
    my $state = eval { $dbh->state } // '';

    die IO::Async::Pg::Error::Query->new(
        message    => $err,
        code       => $state,
        detail     => eval { $dbh->pg_errorlevel } // undef,
        constraint => undef,  # Would need to parse from error
        hint       => undef,
        position   => undef,
    );
}

1;

__END__

=head1 NAME

IO::Async::Pg::Connection - Async PostgreSQL connection

=head1 SYNOPSIS

    my $conn = await $pg->connection;

    # Positional placeholders
    my $r = await $conn->query('SELECT * FROM users WHERE id = $1', $id);

    # Named placeholders
    my $r = await $conn->query(
        'SELECT * FROM users WHERE name = :name',
        { name => 'Alice' }
    );

    # With timeout
    my $r = await $conn->query(
        'SELECT * FROM slow_view',
        { timeout => 30 }
    );

    # Release back to pool
    $conn->release;

=head1 METHODS

=head2 query($sql, @args)

Execute a query asynchronously. Returns a Future that resolves to
an L<IO::Async::Pg::Results> object.

=head2 cancel

Cancel the current query.

=head2 release

Release the connection back to the pool.

=head1 AUTHOR

John Napiorkowski E<lt>jjn1056@yahoo.comE<gt>

=cut
