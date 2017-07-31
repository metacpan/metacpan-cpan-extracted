package MariaDB::NonBlocking::Promises;
use parent 'MariaDB::NonBlocking';

use v5.18.2; # needed for __SUB__, implies strict
use warnings;

BEGIN {
    my $loaded_ok;
    eval { require Sub::StrictDecl; $loaded_ok = 1; };
    Sub::StrictDecl->import if $loaded_ok;
}

use Promises ();  # for deferred

# Better to import this, since it is a custom op
use Ref::Util qw(is_ref is_arrayref);

# We use EV directly, because we might need to wait on
# both reads AND writes on a handle, and doing that through
# AnyEvent means maintaining multiple IO watchers.
use EV ();

use MariaDB::NonBlocking ':all';

sub _decide_what_watchers_we_need {
    my $wait_on = 0;
    $wait_on |= EV::READ  if $_[0] & MYSQL_WAIT_READ;
    $wait_on |= EV::WRITE if $_[0] & MYSQL_WAIT_WRITE;

    return $wait_on;
}

sub ev_event_to_mysql_event {
    return MYSQL_WAIT_TIMEOUT
        if $_[0] & EV::TIMER;

    my $events = 0;
    $events |= MYSQL_WAIT_READ  if $_[0] & EV::READ;
    $events |= MYSQL_WAIT_WRITE if $_[0] & EV::WRITE;

    return $events;
}

sub ____run {
    my (
        $type,
        $have_work_for_conn,
        $start,
        $results,
        $connections,
        $extras
    ) = @_;

    $extras //= {};

    my $perl_timeout = $extras->{perl_timeout};

    my $deferred = Promises::deferred();

    $connections = [$connections] if ! is_arrayref($connections);

    my (@per_query_results, @errors);

    my $call_start = sub {
        return if @errors; # Quick exit...

        my ($maria) = @_;

        my $wait_for;
        while ( $have_work_for_conn->($maria) ) {
            last if $wait_for;

            local $@;
            eval {
                $wait_for = $start->($maria);
                1;
            } or do {
                my $e = $@ || 'zombie error';
                push @errors, $e;
            };

            # if $wait_for is true, then we need to wait
            # before calling _cont, so this connection is now
            # busy.  Break out of this loop and return to the caller.
            return $wait_for if $wait_for;

            if ( !defined($wait_for) || @errors ) {
                return; # return undef, meaning nothing to do
            }

            if ( !$wait_for ) {
                # Query finished immediately, so we can just
                # run the next one
                push @per_query_results, $results->($maria);
            }
        }

        return $wait_for;
    };

    my %watchers;
    # TODO alarms
    CONNECTION:
    foreach my $maria ( @$connections ) {
        last CONNECTION if @errors;

        my $wait_for = $call_start->($maria);

        if ( !$wait_for ) {
            # Nothing to wait for!
            # See if we can still use this connection
            redo CONNECTION if $have_work_for_conn->($maria);
            # Otherwise, move on to the next connection
            next CONNECTION;
        }

        # Need to wait on the query
        my $socket_fd         = $maria->mysql_socket_fd;
        my $previous_wait_for = $wait_for;

        my $mysql_socket_ready_callback = sub {
            if ( $extras->{cancel} ) {
                # Right... this needs some explanation.
                # Consider this situation:
                # run_multiple_queries(
                #   [$conn1, $conn2],
                #   [ "select * from NonExistent", "select * from HugeTable1" ],
                #   $extras,
                # );
                # run_multiple_queries(
                #   [$conn3, $conn4],
                #   [ "select * from HugeTable2", "select * from HugeTable3" ],
                #   $extras,
                # );
                # So we have two sets of promises, each running multiple
                # queries.  The first query for the first promise will
                # fail since the table doesn't exist.  While that means
                # that we will have a chance to stop the select on HugeTable1,
                # we have no such luck for the second promise!
                # So what if we want to stop the second promise entirely?
                # Well, it's no easy task.  You could disconnect the
                # handles and hope that works, but it might be that
                # we are actually chaining a connect promise, ala
                #   connect()->then(sub { run_multiple() })
                # So the disconnect might not do anything!
                # The A+ spec sadly has nothing for us here, so this
                # tiny shim here will do; by sharing the $extras hash
                # as in the example above, a reject/catch for the
                # first promise will be able to stop the execution of any
                # other related promises, by simply setting
                #   $extras->{cancelled} = 1
                # If the promise is already rejected or resolved,
                # then we just return from this loop; otherwise we
                # reject it.
                undef %watchers;
                $deferred->reject("Manual cancellation, reason: $extras->{cancel}")
                    if $deferred->is_in_progress;
                return;
            }

            if ( @errors ) { # Error in another connection
                delete $watchers{$socket_fd};
                return;
            }

            my (undef, $ev_event) = @_;

            # Always release the timer.
            delete $watchers{$socket_fd}->{timer};

            my $events_for_mysql = ev_event_to_mysql_event($ev_event);

            my $wait_for;
            local $@;
            eval {
                $wait_for = $maria->cont($events_for_mysql);
                1;
            } or do {
                my $e = $@ || 'zombie error';
                push @errors, $e;
            };

            while ( !$wait_for ) {
                # query we were waiting on finished!
                last if @errors;

                # Get the results
                push @per_query_results, $results->($maria);

                # And schedule another!
                $wait_for = $call_start->($maria);
                # Loop will keep going until we either run a query
                # we need to block on, in which case $wait_for will
                # be true, or we exhaust all @queries, in which case
                # $wait_for will be undef
                last if !defined $wait_for;
            }

            if ( @errors ) {
                undef %watchers; # Destroy ALL watchers, otherwise
                                 # we might leak some!
                # We got an error above.  Reject the promise and bail
                $deferred->reject(@errors);
                return;
            }

            # If we still don't need to wait for anything, that
            # means we are done with all queries for this dbh,
            # so decrease the condvar counter
            if ( !$wait_for ) {
                delete $watchers{$socket_fd}; # BOI!!
                if ( !keys %watchers ) {
                    # Ran all the queries! We can resolve and go home
                    $deferred->resolve(\@per_query_results);
                    return;
                }
                # Another connection is still running.  The last query
                # must resolve.
                return;
            }
            else {
                if ( $wait_for != $previous_wait_for ) {
                    $previous_wait_for = $wait_for;
                    my $new_ev_mask = _decide_what_watchers_we_need($wait_for);
                    # Server wants us to wait on something else, so
                    # we can't reuse the previous watcher.
                    # e.g. we had a watcher waiting on the socket
                    # being readable, but we need to wait for it to
                    # become writeable (or both) instead.
                    # This almost never happens.
                    delete $watchers{$socket_fd}->{io};
                    $watchers{$socket_fd}->{io} = EV::io(
                                        $socket_fd,
                                        $new_ev_mask,
                                        __SUB__,
                                      );
                }

                if ( $wait_for & MYSQL_WAIT_TIMEOUT ) {
                    # A timeout was specified with the connection.
                    # This will call this same callback, with $ev_event
                    # as EV::TIMEOUT; query_cont will eventually call
                    # the relevant _cont method with MYSQL_WAIT_TIMEOUT,
                    # and let the driver decide what to do next.
                    my $timeout_ms = $maria->get_timeout_value_ms();
                    # Bug in the client lib makes the no-timeout case come
                    # back as 0 timeout.  So only create the timer if we
                    # actually have a timeout.
                    # https://lists.launchpad.net/maria-developers/msg09971.html
                    EV::now_update();
                    $watchers{$socket_fd}->{timer} = EV::timer(
                                            # EV wants (fractional) seconds
                                            $timeout_ms/1000,
                                            0, # do not repeat
                                            __SUB__,
                                       ) if $timeout_ms;
                }
            }
            return;
        };

        $watchers{$socket_fd}->{io} = EV::io(
            $socket_fd,
            _decide_what_watchers_we_need($wait_for),
            $mysql_socket_ready_callback,
        );

        EV::now_update();
        $watchers{$socket_fd}->{timer_global} = EV::timer(
            $perl_timeout,
            0, # no repeat
            sub {
                undef %watchers;

                push @errors, "$type execution was interrupted by perl, maximum execution time exceeded (timeout=$perl_timeout)";
                $deferred->reject(@errors);
            },
        ) if $perl_timeout;
    }

    my $promise = $deferred->promise;
    if ( !keys %watchers ) {
        # All queries on all connections finished immediately.
        # So reject or resolve as necessary
        if ( @errors ) {
            # Sigh... need to give back a list here, because error handlers
            # tend to want to stringify $_[0] / $@
            $deferred->reject(@errors);
        }
        else {
            $deferred->resolve(\@per_query_results);
        }
    }

    return $promise;
}

sub run_multiple_queries {
    my ($conns, $remaining_sqls, $extras) = @_;

    $remaining_sqls = [$remaining_sqls] if !is_ref($remaining_sqls);

    if ( is_arrayref($remaining_sqls) ) {
        my $original     = $remaining_sqls;
        my $next_sql_idx = 0;
        $remaining_sqls  = sub { \ $original->[$next_sql_idx++] };
    }

    my $next_sql = $remaining_sqls->();
    ____run(
        "run_queries",
        sub { $next_sql && !!$$next_sql },
        sub {
            my $ret = $_[0]->run_query_start( $$next_sql );
            $next_sql = $remaining_sqls->();
            return $ret;
        },
        sub {$_[0]->query_results},
        $conns,
        $extras,
    );
}
BEGIN { *run_query = \&run_multiple_queries }

sub ping {
    # use of the per_ping_finished_cb is HIGHLY discouraged.
    # It exists solely for the case when $conn is an arrayref of
    # objects, and waiting on all of them to finish isn't
    # ideal -- for example, if we want to deal immediately
    # with the disconnect
    my ($conn, $extras, $per_ping_finished_cb) = @_;

    my %seen;
    ____run(
        "ping",
        sub { return !$seen{$_[0]} },
        sub {
            $seen{$_[0]}++;
            $_[0]->ping_start();
        },
        sub {
            my $res = $_[0]->ping_result;
            $per_ping_finished_cb->( $_[0], $res )
                if $per_ping_finished_cb;
            return $res;
        },
        $conn,
        $extras,
    );
}

# useful if you want to run the same query on multiple connections
# Think changing per-session settings.
sub query_once_per_connection {
    my ($conns, $query, $extras, $per_query_finished_cb) = @_;

    my %seen;
    ____run(
        "run_query_once_per_conn",
        sub { return !$seen{$_[0]} },
        sub {
            $seen{$_[0]}++;
            $_[0]->run_query_start($query)
        },
        sub {
            my $res = $_[0]->query_results;
            $per_query_finished_cb->($_[0], $res)
                if $per_query_finished_cb;
            return $res;
        },
        $conns,
        $extras,
    );
}

sub connect {
    my ($conn, $connect_args, $extras) = @_;

    my %seen;
    ____run(
        "connect",
        sub { return !$seen{$_[0]} },
        sub {
            $seen{$_[0]}++;
            $_[0]->connect_start($connect_args);
        },
        sub { $_[0] },
        $conn,
        $extras,
    );
}

1;
