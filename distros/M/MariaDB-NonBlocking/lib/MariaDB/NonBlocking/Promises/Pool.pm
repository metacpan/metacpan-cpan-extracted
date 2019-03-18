package MariaDB::NonBlocking::Promises::Pool;

use constant DEBUG => $ENV{MariaDB_NonBlocking_DEBUG} // 0;
sub TELL (@) {
    say STDERR __PACKAGE__, ': ', join " ", @_;
}

package MariaDB::NonBlocking::Promises::Stolen {
    BEGIN { $INC{__PACKAGE__ =~ s<::></>gr . '.pm'} = __FILE__ }
    use Exporter 'import';
    use Carp qw/croak/;
    use Ref::Util qw/is_arrayref is_coderef/;
    use AnyEvent::XSPromises qw/resolved rejected deferred/;
    use v5.18.2;
    use warnings;
    use Sub::StrictDecl;
    BEGIN { our @EXPORT_OK = 'p_foreach' }
    sub p_foreach {
        my ($input_ref, $sub, $concurrency)= @_;
        $concurrency ||= 1;

        if (!is_arrayref($input_ref) && !is_coderef($input_ref)) {
            croak('input needs to be an arrayref or coderef');
        }

        my $deferred= deferred;
        my $active= 0;       # Number of currently running concurrent "workers"
        my $continue= 1;     # Has more items
        my $fail_with_error; # Whether to just bail out and throw an error

        my $next= sub {
            my $item;
            if ($continue) {
                if (is_arrayref($input_ref)) {
                    $continue= 0+@$input_ref;
                    $item= shift @$input_ref;
                } else {
                    eval {
                        $item= $input_ref->();
                        $continue= defined($item);
                        1;
                    } or do {
                        my $error= $@ || "zombie";
                        $fail_with_error ||= "Input code died: $error";
                        $continue= 0;
                    };
                }
            }
            if (!$continue) {
                $active--;
                if ($active == 0) {
                    if ($fail_with_error) {
                        $deferred->reject($fail_with_error);
                    } else {
                        $deferred->resolve;
                    }
                }
                return;
            }
            resolved->then(sub {
                $sub->($item);
            })->catch(sub {
                my $error= shift || "zombie promise";
                $continue= 0;
                $fail_with_error ||= $error;
            })->then(__SUB__, __SUB__);
            return;
        };

        $active= $concurrency;
        for (1..$concurrency) {
            $next->();
        }

        return $deferred->promise;
    }
}
use MariaDB::NonBlocking::Promises::Stolen 'p_foreach';

use v5.18.2;
use warnings;
use Sub::StrictDecl;

use constant OUR_DEFAULT_WAIT_TIMEOUT => 60;
use constant MYSQL_MAX_SLAVE_RETRIES  => 4; # magic number

use Data::Dumper;

use Carp ();
BEGIN {
    $Carp::Internal{+__PACKAGE__}     = 1;
    $Carp::CarpInternal{+__PACKAGE__} = 1;
}

use Socket ();
use Time::HiRes;  # for high-res time

use Ref::Util qw(is_arrayref is_hashref);

use List::Util   qw(shuffle sum);
use Scalar::Util qw(weaken refaddr);
use MariaDB::NonBlocking ();
use MariaDB::NonBlocking::Promises qw();

use if DEBUG, 'Digest::MD5' => qw(md5_hex); # dumb fingerprinting when DEBUG is true
BEGIN { *md5_hex = sub {} unless DEBUG };

use constant {
    PENDING_QUERY      => 1,            # tuple of [$query, $bind values]
    PENDING_ATTR       => 2,            # options for the query (timeout, etc)
    PENDING_DEFERRED   => 3,            # the Promises::Deferred object
    PENDING_STACKTRACE => 4,            # Stacktrace from the place the query was scheduled
    PENDING_RETRIES_REMAINING => 5,     # ...
    PENDING_SCHEDULED_TIME    => 6,      # hires unix timestamp of when the query was scheduled, for eventlog purposes
};

sub _format_connection_error { # Override
    my ($pool, $error, $connection_args) = @_;
    return $error;
}

sub _format_query_error { # Override
    my ($pool, $query, $error, $conn, $query_start_time, $cpu_start_time) = @_;
    return $error;
}

sub _log_time_to_connect { # Override
    my ($pool, $connection_args, $connect_start_time) = @_;
}

sub _log_time_to_be_scheduled { # Override
    my ($pool, $query_scheduled_time) = @_;
}

sub _log_query_timings { # Override
    my ($pool, $conn, $query, $query_start_time, $cpu_start_time) = @_;
}

sub _deal_with_query_warnings { # Override
    my ($pool, $query, $warnings, $stacktrace) = @_;
}

sub _preprocess_query { # Override
    my ($pool, $conn, $query, $bind) = @_;
    return AnyEvent::XSPromises::resolved();
}

sub _postprocess_query { # Override
    my ($pool, $conn, $query, $query_start_time, $stack) = @_;
}

sub _can_retry_error { # Override
    my ($pool, $error) = @_;
    return 0;
}

# Must return a hashref that can be given to ->connect.
sub _get_connection_args { # Override
    my ($pool) = @_;
    ...
}

sub _initialize_new_connection { # Override
    my ($pool, $new_connection, $connection_args) = @_;
    return AnyEvent::XSPromises::resolved();
}

my %default_settings = (
    ro => {
        high_water_mark       => 1, # we want these many connections
        low_water_mark        => 1, # but we'll be okay with this much
        # If we need to extend the pool, how many
        # connections do we extend it by in parallel?
        max_extend_at_a_time  => 1, # at most do X connections at once

        query_retries         => 2,
    },
    rw => {
        high_water_mark       => 1,
        low_water_mark        => 1,
        max_extend_at_a_time  => 1,
        query_retries         => 1,
    },
);

sub set_default_configuration {
    my ($pool, %new_settings) = @_;
    my $mode       = $pool->{mode};
    my $settings   = { %{ $default_settings{$mode} // $default_settings{ro} } };
    foreach my $setting ( keys %$settings ) {
        next unless exists $new_settings{$setting};
        $pool->{$setting} = $settings->{$setting} = $new_settings{$setting}
    }
    return;
}

sub DESTROY {
    my ($pool) = @_;
    $pool->fail_pending('Pool was released before query was finished');
    return;
}

# Public interface.
our $STACKTRACE_IGNORE = {};
for ( my @parts = split /::/, __PACKAGE__; @parts; pop @parts ) {
    $STACKTRACE_IGNORE->{join '::', @parts} = 1;
}
sub run_query {
    my ($pool, $query, $attr, $bind) = @_;
    $attr //= { want_hashrefs => 1 };

    my $deferred = AnyEvent::XSPromises::deferred();
    my @pending;
    $pending[PENDING_QUERY()]      = [$query, $bind];
    $pending[PENDING_ATTR()]       = $attr;
    $pending[PENDING_DEFERRED()]   = $deferred;
    $pending[PENDING_STACKTRACE()] = \MariaDB::NonBlocking::get_simple_stacktrace($STACKTRACE_IGNORE);
    $pool->_add_to_pending(\@pending);

    return $deferred->promise;
}


our $MYSQL_MAX_EXECUTION_TIME = 4;
sub new {
    my ($class, $new_args) = @_;

    my ($schema_name, $database_name, $mode) = @{$new_args}{qw/schema database mode/};
    $schema_name   //= $database_name;
    $database_name //= $schema_name;
    $mode          //= 'ro';

    my $max_execution_time = $new_args->{max_execution_time} || $MYSQL_MAX_EXECUTION_TIME || 4;

    my $pool_name  = $schema_name ne $database_name
                   ? join('-', $schema_name, $database_name, $mode)
                   : join('-', $schema_name, $mode)
    ;

    # Let's untangle this mess.
    # The easy scenario is this:
    #
    #   schema_name   =>  'review',
    #   database_name =>  'review',
    #
    # The nasty scenario is this:
    #
    #   schema_name   => 'review',
    #   database_name => 'ng',
    #
    # Because even though both of them go to the same
    # hosts, they end up querying different schemas;
    # in fact, the code assumes that it can query
    # without prefixing the table names.
    #
    # We could deal with this by adding a 'use `$db_name`'
    # prior to every query, but that's a lot of wasted resources
    # for what is primarily an edge case.  So instead, we pretend
    # that the two are totally different replication chains;
    # review.review and review.bp each have their own pool.

    my $mode_for_settings = $mode eq 'rw' ? 'rw' : 'ro';

    my $default_settings = { %{ $default_settings{$mode_for_settings} // $default_settings{ro} } };

    my %extra_settings = map +($_ => $new_args->{$_}),
                         grep exists $new_args->{$_},
                         keys %$default_settings;

    return bless {
        %$default_settings,
        %extra_settings,

        _counters          => {},
        stats              => {},

        pending_queries    => [],

        pool_size            => 0, # NOTE: Should be free + in_use + currently_connecting
        free_connections     => {},
        in_use_connections   => {},
        currently_connecting => {},

        pool_name     => $pool_name,
        schema_name   => $schema_name,
        database_name => $database_name,
        mode          => $mode,

        max_execution_time => $max_execution_time,
    }, $class;
}

sub reset_pool {
    my ($pool) = @_;
    $pool->{pool_size}   = 0;
    $pool->{in_use_connections} = {};
    $pool->{free_connections}   = {};
    $pool->{stats}              = {};
    $pool->{_counters}          = {};
    $pool->{pending_queries}    = [];
    # remove internal counters
    delete $pool->{$_} for grep /^_/, keys %$pool;
}

# End of public interface

sub _drop_connection {
    my ($pool, $conn, $refaddr) = @_;

    if ( $conn ) {
        $refaddr //= refaddr $conn;
        delete $pool->{free_connections}->{$refaddr};
        delete $pool->{in_use_connections}->{$refaddr};

        eval { $conn->disconnect; 1; };
        undef %$conn if is_hashref($conn); # bye!
        undef $conn;
    }

    $pool->{pool_size}--;
    $pool->{pool_size} = 0 if $pool->{pool_size} < 0;
}

sub _remove_connection_and_extend {
    my ($pool, $conn) = @_;

    $pool->_drop_connection($conn) if $conn;

    DEBUG && TELL " pool after removing connection: " . Dumper($pool);

    return $pool->_check_and_maybe_extend_pool_size;
}

sub _add_connection_to_pool {
    my ($pool, $conn, $refaddr) = @_;
    $refaddr //= refaddr $conn;
    my $lifeline = delete $pool->{in_use_connections}{$refaddr}; # $conn & $lifeline are now the last strong refs

    if ( $conn->current_state ne 'STANDBY' ) {
        Carp::cluck("Tried to add a broken connection to the nonblocking pool.  Thanks, but no thanks.  How did this happen?");
        $pool->_drop_connection($conn, $refaddr);
        return;
    }

    # TODO randomly drop connections here.

    $conn->{_last_used}   ||= time();
    $pool->{free_connections}{$refaddr} = $conn;
}

sub _get_connect_splay {
    my ($pool) = @_;
    my $currently_connecting = $pool->{_counters}{connections_currently_connecting};

    return 0 unless $currently_connecting;

    # Add a small splay between simultaneous connections, to prevent
    # thundering herds, particularly during restarts of roles that
    # preconnect to MySQL.  hai soylent.
    my $splay = int(5 + rand(40))/1000; # 5ms - 45ms
    return $splay;
}

# Subclasses should override this with something useful
sub _delay_promise {
    my ($delay_in_seconds) = @_;
    return AnyEvent::XSPromises::resolved();
}

sub _fetch_some_wait_timeout {
    my ($pool, $conn) = @_;
    return AnyEvent::XSPromises::resolved() if $pool->{wait_timeout};
    return $conn->run_query(q{SELECT @@session.wait_timeout})->then(sub {
        my ($results) = @_;
        my $session_wait_timeout = $results->[0][0] || OUR_DEFAULT_WAIT_TIMEOUT;
        $pool->{wait_timeout} = $session_wait_timeout;
    });
}

# Removes ghost connections, and extends the pool if needed
sub _check_and_maybe_extend_pool_size {
    my ($outside_pool) = @_;

    my $pool = $outside_pool;

    # Return if pool already at max size:
    return if $pool->{pool_size} >= $pool->{high_water_mark};

    # Return if pool has more than the low water mark
    return if $pool->{pool_size} >= $pool->{low_water_mark};

    my $needed_connections
        = $pool->{high_water_mark} - $pool->{pool_size};

    $needed_connections -= $pool->{_counters}{connections_currently_connecting} || 0;
    DEBUG && TELL "Going to extend the pool by $needed_connections";

    # Should never happen:
    return if $needed_connections < 1;

    my $max_extend = $pool->{max_extend_at_a_time} || 1;

    $pool->{stats}{started_connections_sum} += $needed_connections;

    # preemptively expand the pool size to prevent overextending
    $pool->{pool_size} += $needed_connections;

    my $connecting_here = $needed_connections;
    weaken($pool);
    return p_foreach([1..$needed_connections], sub {
        return unless $pool;

        my $splay = $pool->_get_connect_splay();
        $pool->{_counters}{connections_currently_connecting}++;
        return $pool->_delay_promise($splay)->then(sub {
            return unless $pool;

            my $connection_args = $pool->_get_connection_args();

            # This is the one and only reference to this connection.  If we don't keep
            # a reference around, it will be freed in the following return, because ->connect
            # tries very very hard not to keep a hard reference around.  So we will keep
            # it in $pool->{currently_connecting}
            my $initial_connection = MariaDB::NonBlocking::Promises::->new();
            my $refaddr = refaddr $initial_connection;

            $pool->{currently_connecting}{$refaddr} = $initial_connection;
            my $t0 = time;
            return $initial_connection->connect($connection_args)->then(sub {
                # Success
                my ($connection) = @_; # $connection is a hard reference to the connection.
                $pool->_log_time_to_connect($connection_args, $t0);

                return $pool->_fetch_some_wait_timeout($connection)->then(sub {
                    return $pool->_initialize_new_connection($connection, $connection_args);
                })->then(sub {
                    $pool->_add_connection_to_pool($connection, $refaddr);
                });
            },
            sub {
                # Error
                my ($error) = @_;

                if ( !$pool ) {
                    warn "Failed to connect to MySQL, and the connection pool went away.  Connection error:\n$error";
                    return;
                }

                # un-extend
                $pool->{pool_size}--;

                delete $pool->{in_use_connections}{$refaddr}; # Final hard reference for this connection

                # Track how long we spent on connection errors too!
                $pool->_log_time_to_connect($connection_args, $t0);

                my $confession = $pool->_format_connection_error($error, $connection_args);

                if ( $pool->{pool_size} > 0 || !$pool->pool_has_any_pending ) {
                    # Well... One connection failed, but we still have some in the pool,
                    # or we don't have any pending queries, therefore we don't care.
                    # Just toss a warning, in the hope that this is transient.
                    warn $confession;
                    return;
                }

                # Failed to extend the pool to even 1 connection, and we have
                # pending queries.  Fail the queries now.
                my $pool_name    = $pool->{pool_name};
                my $error_string = "Connection pool for $pool_name is empty and we failed to extend it.  All pending queries will be marked as failed. Error: $confession";
                $pool->fail_pending(
                    # $error_string has the confession AND the stacktrace
                    $error_string,
                );
                # Don't rethrow, let the actual promises deal with the fallout
                return;
            })->finally(sub {
                delete $pool->{currently_connecting}{$refaddr} if $pool;
            });
        })->finally(sub {
            $connecting_here--;
            $pool->{_counters}{connections_currently_connecting}--;
        });
    }, $max_extend)->then(sub {
        $pool->_start_running_queries_if_needed if $pool;
        return;
    })->catch(sub {
        # We get here if, somehow, p_foreach or _start_running_queries_if_needed died.
        my $error = $_[0];
        $pool->fail_pending($error) if $pool;
        die $error;
    })->finally(sub {
        # This should be a no-op, unless we had some exception
        $pool->{_counters}{connections_currently_connecting} -= $connecting_here
            if $pool;
    });
}

sub lifo_queue { pop   @{ $_[0] } }
sub fifo_queue { shift @{ $_[0] } }
sub rand_queue {
    # pop a random element off it.
    my $q = $_[0];
    return unless @$q;
    return splice(@$q, int(rand(scalar @$q)), 1);
}

sub pool_has_any_pending {
    my ($pool)       = @_;
    my $pending_pool = $pool->{pending_queries} // [];
    return scalar @$pending_pool;
}

# Can be overriden by replacing the sub -- useful if we want
# the pending queries to be run in a different way.
# (e.g. remove in non-deterministic order, to ensure nothing
# is depending on the order)
our $REMOVE_ELEMENT_FROM_PENDING
    = DEBUG #&& int(rand(2))
        ? \&rand_queue
        : \&lifo_queue;

sub _get_from_pending {
    my ($pool) = @_;

    my $pending_pool = $pool->{pending_queries} //= [];
    return unless @$pending_pool;

    return $REMOVE_ELEMENT_FROM_PENDING->($pending_pool);
}

sub _add_to_pending_array {
    my ($pool, $pending) = @_;

    my $pending_pool = $pool->{pending_queries} //= [];
    push @$pending_pool, $pending;
    # TODO: stats
    #$db_pools_event->{max_queue_size}{$pool_name} = scalar @$pending_pool
    #    if ($db_pools_event->{max_queue_size}{$pool_name}||0) < @$pending_pool;
    return;
}

sub fail_pending {
    my ($pool, $error_string) = @_;
    while ( my $pending = $pool->_get_from_pending() ) {
        my $deferred       = $pending->[PENDING_DEFERRED];
        my $stacktrace_ref = $pending->[PENDING_STACKTRACE];
        $deferred->reject($error_string . $$stacktrace_ref)
            if $deferred->is_in_progress;
    }
}

# Pushes a new query to the pending pool.
sub _add_to_pending {
    my ($pool, $to_enqueue) = @_;

    # Start the retry counter
    $to_enqueue->[PENDING_SCHEDULED_TIME]      = time;
    $to_enqueue->[PENDING_RETRIES_REMAINING] //= $pool->{query_retries};
    $to_enqueue->[PENDING_STACKTRACE]        //= \''; # No stacktrace given

    # add to the current pending pool
    $pool->_add_to_pending_array($to_enqueue);

    my $weak_pool = $pool;
    weaken($weak_pool);

    # Avoid a common issue: Scheduling a query, then doing a blocking
    # sleep for 5 minutes.  It makes some queries look like they
    # took ages to run
    AnyEvent::XSPromises::resolved()->then(sub {
        $weak_pool->_start_running_queries_if_needed if $weak_pool;
    });
}

use constant SHOW_WARNINGS_SQL => 'SHOW WARNINGS';
sub _report_warnings_and_return_to_pool {
    my ($outside_pool, $outside_conn, $query, $stacktrace) = @_;

    my $time0 = time();
    my $cpu0  = times;

    my $conn = $outside_conn;
    weaken($conn);
    my $pool = $outside_pool;
    weaken($pool);

    return $conn->run_query(SHOW_WARNINGS_SQL)->then(sub {
        # Track how long the query took, regardless of whether it was successful or not
        $pool->_log_query_timings( $conn, SHOW_WARNINGS_SQL, $time0, $cpu0 ) if $pool;
        # resolve handler: SHOW WARNINGS ran successfully
        my ($warnings) = @_;

        # Great, got the warnings we wanted, waste
        # no time and resolve the promise and put
        # the connection back into the pool
        $pool->_add_connection_to_pool($conn) if $conn;

        return unless is_arrayref($warnings);

        return $pool->_deal_with_query_warnings( $query, $warnings, $stacktrace );
    },
    sub {
        # reject handler:
        # the SHOW WARNINGS failed in some way

        # Track how long the query took, regardless of whether it was successful or not
        $pool->_log_query_timings( $conn, SHOW_WARNINGS_SQL, $time0, $cpu0 ) if $pool;
        my ($error) = @_;
        warn "SHOW WARNINGS failed: $error";
        return $pool->_remove_connection_and_extend($conn);
    })
}

sub _run_query {
    my (
        $outside_pool,
        $outside_conn,
        $query,
        $attr,
        $bind,
        $deferred,
        $pending,
    ) = @_;

    DEBUG && TELL "Starting query " . md5_hex($query) .
        (DEBUG > 3 ? " (actual query string: $query)" : "");

    my $time0 = time();
    my $cpu0  = times;
    $attr //= {};
    local $attr->{want_hashrefs} = 1 unless exists $attr->{want_hashrefs};

    # Force all queries to have timeouts.
    local $attr->{perl_timeout}
        = ($attr->{timeout}//0) <= 0
            # Default to slightly higher than the MySQL timeout:
            ? $outside_pool->{max_execution_time} * 1.2
            : $attr->{timeout};

    my $conn = $outside_conn;
    weaken($conn);
    my $pool = $outside_pool;
    weaken($pool);

    $pool->{stats}{total_queries_run}++;

    my $return_last_inserted_id = $attr->{return_last_inserted_id};

    return $pool->_preprocess_query($conn, $query, $bind)->then(sub {
        $conn->run_query($query, $bind, $attr);
    })->then(sub {
        $pool->_log_query_timings( $conn, $query, $time0, $cpu0 ) if $pool;

        DEBUG && TELL "Successfully ran query " . md5_hex($query);

        my ($query_results) = @_;

        $query_results = $conn ? $conn->insert_id : -1
            if $return_last_inserted_id;

        $pool->_postprocess_query($conn, $query, $time0, $pending->[PENDING_STACKTRACE])
            if $pool;

        # Resolve the query.  Hooray!
        $deferred->resolve($query_results)
            if $deferred->is_in_progress; # maybe we timed out?

        return if !$pool; # released from under us

        # Before returning the connection into the pool, let's
        # run a SHOW WARNINGS if needed
        if ( !$conn || !$conn->mysql_warning_count() ) {
            # Common case: no warnings
            # Send the connection back into the pool and
            # potentially start new queries.
            $pool->_add_connection_to_pool($conn) if $conn;
            return;
        }

        # Uncommon case: warnings!  Run a query to get them
        # Sadly we cannot resolve the promise until we are done
        # with the SHOW WARNINGS, as otherwise that query might be
        # left dangling in the eventloop.
        # Note that unlike B:Db, we ALWAYS show warnings if we had any
        return $pool->_report_warnings_and_return_to_pool(
            $conn,
            $query,
            $pending->[PENDING_STACKTRACE],
        );
    },
    sub {
        # Add the times even if the query failed.
        $pool->_log_query_timings( $conn, $query, $time0, $cpu0 ) if $pool;

        DEBUG && TELL "Failed query " . md5_hex($query) . ", reason: " . $_[0]//'<unknown>';

        # Oh shit, the query failed in some way.
        my $error = $_[0] || 'unknown error';
        $error =~ s/run_query/MySQL query (nonblocking)/;

        if ( $pool && $pending->[PENDING_RETRIES_REMAINING] > 0 && $pool->_can_retry_error($error) ) {
            # We can retry!  Push back into the pool.
            $pending->[PENDING_RETRIES_REMAINING]--;
            $pending->[PENDING_SCHEDULED_TIME] = time;
            $pool->_add_to_pending_array($pending);
            return;
        }

        $error = $pool->_format_query_error($query, $error, $conn, $time0, $cpu0);

        $deferred->reject($error . ${$pending->[PENDING_STACKTRACE]})
            if $deferred->is_in_progress; # fail the promise

        # TODO so... here we could check if the connection
        # is still viable and add it back into the pool.
        # But that would require examining the error message
        # in addition to the actual object.  So for now,
        # on any error, just disconnect and potentially
        # re-extend the pool.
        return $pool->_remove_connection_and_extend( $conn ) if $pool;
    })->catch(sub {
        my $e = $_[0];

        # TODO: is this double-appending the stacktrace?
        $deferred->reject( "Error when running query: $e" . ${$pending->[PENDING_STACKTRACE]} ) if $deferred->is_in_progress;

        $pool->_remove_connection_and_extend( $conn ) if $pool;
    })->finally(sub {
        # Schedule the next query
        $pool->_start_running_queries_if_needed if $pool;
    })
}

sub _grab_connection {
    my ($pool) = @_;

    my $now          = time();
    # || in case wait_timeout is mistakenly set to 0
    my $wait_timeout = $pool->{wait_timeout} || OUR_DEFAULT_WAIT_TIMEOUT;

    my $free_connections = $pool->{free_connections} //= {};
    foreach my $conn_key ( keys %$free_connections ) {
        my $conn = delete $free_connections->{$conn_key};

        my $expected_idling_timeout =
            $conn->{_last_used} + $wait_timeout;
        if ( $now > $expected_idling_timeout ) {
            DEBUG && TELL "Dropping connection $conn_key because it has gone unused for longer than wait_timeout ($wait_timeout)";
            # Connection died from doing nothing for too long.
            # Slacker.
            $pool->_remove_connection_and_extend($conn);
            next;
        }

        $pool->{in_use_connections}{$conn_key} = $conn;
        return $conn;
    }

    # We get here if we had free connections, but they
    # were ALL unused for long enough to be dropped.
    # Return nothing, let the caller handle waiting
    return;
}

sub _start_running_queries_if_needed {
    my ($pool) = @_;

    # Schedule an extend, if needed:
    my $extend = $pool->_check_and_maybe_extend_pool_size;

    # But don't let that stop us.  We might have free connections
    my $conn = $pool->_grab_connection();
    if ( !$conn ) {
        # Ah well. We'll try again after the extend.
        return;
    }

    PENDING:
    while ( my $pending = $pool->_get_from_pending() ) {
        my $query_and_bind = $pending->[PENDING_QUERY];
        my $attr           = $pending->[PENDING_ATTR];
        my $deferred       = $pending->[PENDING_DEFERRED];

        my $p;
        eval {
            $pool->_log_time_to_be_scheduled($pending->[PENDING_SCHEDULED_TIME]);

            if ( !$deferred->is_in_progress ) {
                # Probably timed out
                DEBUG && TELL "Found already finished query in the deferred queue";
                $pool->_add_connection_to_pool($conn);
                next PENDING;
            }

            DEBUG && TELL "About to start running a new query";
            my ($query, $bind) = @{ $query_and_bind };
            $p = $pool->_run_query(
                $conn,
                $query,
                $attr,
                $bind,
                $deferred,
                $pending,
            );
            1;
        } or do {
            my $e = $@ || 'zombie error';
            DEBUG && TELL "Failed to run query: $e";

            $deferred->reject($e . ${$pending->[PENDING_STACKTRACE]})
                if $deferred->is_in_progress;
            next PENDING;
        };
        return $p;
    }

    return $pool->_add_connection_to_pool($conn);
}

1;
__END__

