package MariaDB::NonBlocking::Event;
use parent 'MariaDB::NonBlocking';

use v5.18.2; # needed for __SUB__, implies strict
use warnings;

use constant DEBUG => $ENV{MariaDB_NonBlocking_DEBUG} // 0;
sub TELL (@) {
    say STDERR __PACKAGE__, ': ', join " ", @_;
}

BEGIN {
    my $loaded_ok;
    local $@;
    eval { require Sub::StrictDecl; $loaded_ok = 1; };
    Sub::StrictDecl->import if $loaded_ok;
}

use Carp     (); # for confess

# Better to import this, since it is a custom op
use Ref::Util qw(is_ref is_arrayref is_coderef);
use Scalar::Util qw(refaddr weaken);

use AnyEvent;

use MariaDB::NonBlocking ':all';

my $IS_EV;

# is anyevent using EV? If so, cut the middleman and
# use EV directly, since we can reuse/reset watchers,
# as well as use IO watchers for both read and write
# polling.
# EV lets us cut down the number of watchers created
# per connection significantly.
AnyEvent::post_detect {
    $IS_EV = ($AnyEvent::MODEL//'') eq 'AnyEvent::Impl::EV' ? 1 : 0;
    DEBUG && TELL $IS_EV ? "Using EV" : "Using AnyEvent";
};

BEGIN {
    my $loaded_ok;
    local $@;
    eval { require EV; $loaded_ok = 1; };

    # Because we use Sub::StrictDecl, we cannot
    # use EV::foo() directly, since those may
    # not be loaded.

    if ( $loaded_ok ) {
        # EV loaded fine.  Add some aliases
        *EV_READ       = \*EV::READ;
        *EV_WRITE      = \*EV::WRITE;
        *EV_TIMER      = \*EV::TIMER;
        *EV_io         = \*EV::io;
        *EV_timer      = \*EV::timer;
        *EV_now_update = \*EV::now_update;
    }
    else {
        # EV failed to load.  Add some useless
        # aliases to tide us over.
        constant->import({
            EV_READ  => 0,
            EV_WRITE => 1,
            EV_TIMER => 2,
        });
        *EV_io         = sub {};
        *EV_timer      = sub {};
        *EV_now_update = sub {};
    }
}

sub _mysql_watchers_to_ev_watchers {
    my $wait_on = 0;
    $wait_on |= EV_READ  if $_[0] & MYSQL_WAIT_READ;
    $wait_on |= EV_WRITE if $_[0] & MYSQL_WAIT_WRITE;
    return $wait_on;
}

sub _ev_event_to_mysql_event {
    return MYSQL_WAIT_TIMEOUT
        if $_[0] & EV_TIMER;

    my $events = 0;
    $events |= MYSQL_WAIT_READ  if $_[0] & EV_READ;
    $events |= MYSQL_WAIT_WRITE if $_[0] & EV_WRITE;

    return $events;
}

sub empty;

our %WATCHER_POOL;
our $WATCHER_POOL_MAX = 2; # keep two standby watchers alive at most
sub __return_watcher {
    return unless $IS_EV; # watcher pool is only useful in EV; elsewhere we
                          # cannot reuse watchers
    my ($watcher_type, $watcher) = @_;
    return unless $watcher;
    my $pool = $WATCHER_POOL{$watcher_type} //= [];
    return if @$pool >= $WATCHER_POOL_MAX;
    $watcher->stop; # includes $watcher->clear_pending;
    $watcher->keepalive(0);
    $watcher->cb(\&empty);
    push @$pool, $watcher;
}

sub __stop_or_return_watcher {
    my $args         = $_[0] // {};
    my $watcher_type = $args->{watcher_type};
    my $storage      = $args->{storage};
    if ( !$IS_EV ) {
        return __return_watcher(
            $watcher_type,
            delete $storage->{$watcher_type},
        );
    }

    # Keep the watcher in $storage so that we'll reuse it.
    my $watcher = $storage->{$watcher_type};
    $watcher->stop; # includes $watcher->clear_pending;
    $watcher->keepalive(0);

    # WOAH. Keeping this coderef alive is doing something nasty;
    # replace it asap.
    $watcher->cb(\&empty);

    return;    
}
sub __return_all_watchers {
    my ($watchers) = @_;
    return unless $watchers; # can be undef if the object went out of scope
    foreach my $watcher_type ( keys %$watchers ) {
        my $watcher = delete $watchers->{$watcher_type};
        next unless $IS_EV;
        $watcher_type = 'io'    if index($watcher_type, 'io')    != -1;
        $watcher_type = 'timer' if index($watcher_type, 'timer') != -1;
        __return_watcher($watcher_type, $watcher);
    }
}

sub __wrap_ev_cb {
    my ($cb) = @_;
    return sub {
        my (undef, $ev_event) = @_;
        my $events_for_mysql  = _ev_event_to_mysql_event($ev_event);
        $cb->($events_for_mysql);
    }
}

sub __grab_watcher {
    my ($args) = @_;

    my $watcher_type = $args->{watcher_type};
    my $watcher_args = $args->{watcher_args};
    my $storage      = $args->{storage};

    if ( exists $storage->{$watcher_type} ) {
        Carp::confess("Overriding a $watcher_type watcher!  How did this happen?");
    }

    AnyEvent::detect() unless defined $IS_EV;

    if ( $IS_EV ) {
        # If we are using EV, reuse a watcher if we can.
        my $cb = __wrap_ev_cb($watcher_args->[2]);

        my $existing_watcher = $storage->{$watcher_type}
                           ||= pop @{ $WATCHER_POOL{$watcher_type} //= [] };

        if ( $watcher_type eq 'io' ) {
            my $ev_mask = _mysql_watchers_to_ev_watchers($watcher_args->[1]);

            if ( !$existing_watcher ) {
                # No pre-existing watcher for us to use;
                # make a new one!
                DEBUG && TELL "Started new $watcher_type watcher ($watcher_args->[1])";
                $storage->{$watcher_type} = EV_io(
                    $watcher_args->[0],
                    $ev_mask,
                    $cb
                );
                return;
            }

            DEBUG && TELL "Reusing existing $watcher_type watcher ($watcher_args->[1])";
            $existing_watcher->set(
                    $watcher_args->[0],
                    $ev_mask,
            );
        }
        elsif ( index($watcher_type, 'timer') != -1 ) {
            EV_now_update();
            if ( !$existing_watcher ) {
                DEBUG && TELL "Started new $watcher_type watcher";
                $storage->{$watcher_type} = EV_timer(
                    $watcher_args->[0],
                    $watcher_args->[1],
                    $cb
                );
                return;
            }
            DEBUG && TELL "Reusing existing $watcher_type watcher";
            $existing_watcher->set(
                    $watcher_args->[0],
                    $watcher_args->[1],
            );
        }
        else {
            die "Unhandled watcher type: $watcher_type";
        }

        $existing_watcher->cb($cb);
        $existing_watcher->keepalive(1);
        $existing_watcher->start;

        return;
    }
    else {
        # Slightly easier, really.  Less performant since
        # we never reuse watchers.
        if ( index($watcher_type, 'timer') != -1 ) {
            delete $storage->{$watcher_type};

            my $cb         = $watcher_args->[2];
            my $wrapped_cb = sub { return $cb->(MYSQL_WAIT_TIMEOUT) };
            DEBUG && TELL "Started new $watcher_type watcher";
            AnyEvent->now_update;
            $storage->{$watcher_type} = AnyEvent->timer(
                after    => $watcher_args->[0],
                interval => $watcher_args->[1],
                cb       => $wrapped_cb,
            );
        }
        elsif ( $watcher_type eq 'io' ) {
            # We might need a read watcher, we might need
            # a write watcher.. we might need both : (

            # drop any previous watchers
            delete @{$storage}{qw/io_r io_w/};

            # amusingly, this is broken in libuv, since
            # you cannot have two watchers on the same fd;
            # AnyEvent works around it though, so all is good.
            my $wait_for      = $watcher_args->[1];
            my $cb            = $watcher_args->[2];
            DEBUG && TELL "Started new $watcher_type watcher ($wait_for)";
            $storage->{io_r} = AnyEvent->io(
                fh   => $watcher_args->[0],
                poll => "r",
                cb   => sub { $cb->(MYSQL_WAIT_READ) }
            ) if $wait_for & MYSQL_WAIT_READ;
            $storage->{io_w} = AnyEvent->io(
                fh   => $watcher_args->[0],
                poll => "w",
                cb   => sub { $cb->(MYSQL_WAIT_WRITE) }
            ) if $wait_for & MYSQL_WAIT_WRITE;
        }
        else {
            die "Unhandled watcher type: $watcher_type";
        }
        return;
    }
}

sub __reset_current_watcher_or_grab_a_new_one {
    return &__grab_watcher unless $IS_EV;

    # Got an EV watcher -- means we can go ahead and
    # just stop the one we have here.

    my $args = $_[0];

    my $watcher_type = $args->{watcher_type};
    my $watcher      = $args->{storage}->{$watcher_type};

    return &__grab_watcher unless $watcher;

    my $watcher_args = $args->{watcher_args};

    # simply reset the watcher and be happy
    my $ev_mask = _mysql_watchers_to_ev_watchers($watcher_args->[1]);
    $watcher->set($watcher_args->[0], $ev_mask);
    $watcher->cb(__wrap_ev_cb($watcher_args->[2]));
}

sub ____run {
    my (
        $outside_maria,
        $type,
        $start_work_cb,
        $grab_results_cb,
        $have_work_for_conn,
        $extras,
    ) = @_;

    $extras //= {};

    my $perl_timeout = $extras->{perl_timeout};
    my $success_cb   = $extras->{success_cb};
    my $failure_cb   = $extras->{failure_cb};

    if ( !is_coderef($success_cb) ) {
        Carp::croak(ref($outside_maria) . " was not given a coderef to success_cb");
    }

    if ( !is_coderef($failure_cb) ) {
        Carp::croak(ref($outside_maria) . " was not given a coderef to failure_cb");
    }


    my (@per_query_results, @errors);

    my $call_start = sub {
        return if @errors; # Quick exit...

        my ($maria) = @_;

        my $wait_for;
        while ( $have_work_for_conn->($maria) ) {
            local $@;
            eval {
                $wait_for = $start_work_cb->($maria);
                1;
            } or do {
                my $e = $@ || 'zombie error';
                push @errors, $e;
            };

            # if $wait_for is true, then we need to wait
            # before calling _cont, so this connection is now
            # busy.  Break out of this loop and return to the caller.
            return $wait_for if $wait_for;

            # Errors of some sort.  Return!
            return if !defined($wait_for) || @errors;

            # false-but-defined means the query finished
            # immediately, so we can just run the next one
            push @per_query_results, $grab_results_cb->($maria);

            # and now, see if we need to run the query again
        }

        return $wait_for;
    };

    my $wait_for = $call_start->($outside_maria);

    if ( !$wait_for ) {
        DEBUG && TELL "Immediately finished $type action";
        # All queries on all connections finished immediately.
        # So reject or resolve as necessary
        if ( @errors ) {
            $failure_cb->(@errors);
        }
        else {
            $success_cb->(@per_query_results);
        }
        return;
    }

    # Need to wait on the query
    my $socket_fd         = $outside_maria->mysql_socket_fd;
    my $previous_wait_for = $wait_for & ~MYSQL_WAIT_TIMEOUT;

    $outside_maria->{watchers} //= {};

    # $maria is weakened here, as otherwise we would
    # have this cycle:
    # $maria->{watchers}{any}{cb} => sub { ...; $maria; ...; }
    my $maria = $outside_maria;
    weaken($maria);

    my $reject_refaddr = refaddr($failure_cb);

    my $watcher_ready_cb = sub {
        if ( !$maria ) {
            $failure_cb->("Connection object went away");
            return;
        }

        my ($events_for_mysql) = @_;

        # Always stop/release the timers!
        __stop_or_return_watcher({
            watcher_type => 'timer',
            storage      => $maria->{watchers},
        }) if exists $maria->{watchers}{timer};

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
            push @per_query_results, $grab_results_cb->($maria);

            # And schedule another!
            $wait_for = $call_start->($maria);
            # Loop will keep going until we either run a query
            # we need to block on, in which case $wait_for will
            # be true, or we exhaust all @queries, in which case
            # $wait_for will be undef
            last if !defined $wait_for;
        }

        if ( @errors ) {
            __return_all_watchers(delete $maria->{watchers});
                # Destroy ALL watchers, otherwise
                # we might leak some!
            # We got an error above.  Reject and bail
            delete $maria->{pending}{$reject_refaddr};
            $failure_cb->(@errors);
            return;
        }

        # If we still don't need to wait for anything, that
        # means we are done with all queries for this dbh,
        # so decrease the condvar counter
        if ( !$wait_for ) {
            __return_all_watchers(delete $maria->{watchers}); # BOI!!
            # Ran all the queries! We can resolve and go home
            delete $maria->{pending}{$reject_refaddr};
            $success_cb->(@per_query_results);
            return;
        }

        if ( $wait_for & MYSQL_WAIT_TIMEOUT ) {
            # remove for the next check if()
            $wait_for &= ~MYSQL_WAIT_TIMEOUT;
            # A timeout was specified with the connection.
            # This will call this same callback;
            # query_cont will eventually call
            # the relevant _cont method with MYSQL_WAIT_TIMEOUT,
            # and let the driver decide what to do next.
            my $timeout_ms = $maria->get_timeout_value_ms();
            __reset_current_watcher_or_grab_a_new_one({
                watcher_type => 'timer',
                storage      => $maria->{watchers},
                watcher_args => [
                    # EV wants (fractional) seconds
                    $timeout_ms/1000,
                    0, # do not repeat
                    __SUB__,
                ],
            # Bug in the client lib makes the no-timeout case come
            # back as 0 timeout.  So only create the timer if we
            # actually have a timeout.
            # https://lists.launchpad.net/maria-developers/msg09971.html
            }) if $timeout_ms;
        }

        if ( $wait_for != $previous_wait_for ) {
            $previous_wait_for = $wait_for;
            # Server wants us to wait on something else, so
            # we can't reuse the previous mask.
            # e.g. we had a watcher waiting on the socket
            # being readable, but we need to wait for it to
            # become writeable (or both) instead.
            # This almost never happens, but we need to
            # support it for SSL renegotiation.
            __reset_current_watcher_or_grab_a_new_one({
                watcher_type => 'io',
                storage      => $maria->{watchers},
                watcher_args => [
                    $socket_fd,
                    $wait_for,
                    __SUB__,
                ]
            });
        }
        return;
    };

    $outside_maria->{watchers} //= {};
    __grab_watcher({
        watcher_type => 'io',
        storage      => $outside_maria->{watchers},
        watcher_args => [
            $socket_fd,
            $wait_for & ~MYSQL_WAIT_TIMEOUT,
            $watcher_ready_cb,
        ]
    });

    __grab_watcher({
        watcher_type => 'timer_global',
        storage      => $outside_maria->{watchers},
        watcher_args => [
            $perl_timeout,
            0, # no repeat
            sub {
                DEBUG && TELL "Global timeout reached";

                if ( $maria ) {
                    __return_all_watchers(delete $maria->{watchers});
                    delete $maria->{pending}{$reject_refaddr};
                }

                push @errors,
                    "$type execution was interrupted by perl, maximum execution time exceeded (timeout=$perl_timeout)";
                $failure_cb->(@errors);
            },
        ]
    }) if $perl_timeout;

    $outside_maria->{pending}{$reject_refaddr} = $failure_cb;

    return;
}

sub DESTROY {
    my $self = shift;

    my $pending = $self->{pending} // {};
    my $pending_num = 0;
    for my $reject_cb ( grep defined, values %$pending ) {
        $reject_cb->("Connection object went away");
    }
    DEBUG && $pending_num && TELL "Had $pending_num operations still running when we were freed";
}

sub run_query {
    my ($conn, $sql, $bind, $attr) = @_;

    return $conn->run_multiple_queries(
        [ [ $sql, $attr, $bind ] ],
        $attr,
    );
}

sub run_multiple_queries {
    my ($conn, $remaining_sqls, $extras) = @_;

    if ( !is_ref($remaining_sqls) ) {
        # ->run_query("select 1")
        $remaining_sqls = [ [$remaining_sqls, $extras ] ];
    }

    if ( !is_coderef($remaining_sqls) ) {
        if ( !is_arrayref($remaining_sqls) ) {
            Carp::croak("->run_multiple_queries takes either a coderef of an arrayref; got a " . ref($remaining_sqls));
        }

        # ->run_multiple_queries([...])
        my $original     = $remaining_sqls;
        my $next_sql_idx = 0;
        $remaining_sqls  = sub {
            my $idx = $next_sql_idx++;
            return $original->[$idx] unless $original->[$idx];
            return is_arrayref($original->[$idx])
                    # ->run_multiple_queries([["select 1"], ["select 2"]])
                    ? $original->[$idx]
                    # ->run_multiple_queries(["select 1", "select 2"])
                    : [ $original->[$idx] ];
        };
    }

    my $next_sql = $remaining_sqls->();
    $conn->____run(
        "run_multiple_queries",
        sub {
            my $ret = $_[0]->run_query_start( @$next_sql );
            $next_sql = $remaining_sqls->();
            return $ret;
        },
        sub { $_[0]->query_results },
        sub { is_arrayref($next_sql) && @$next_sql },
        $extras,
    );
}

sub ping {
    my ($conn, $extras) = @_;

    my $once;
    $conn->____run(
        "ping",
        sub { $_[0]->ping_start()  }, # start
        sub { $_[0]->ping_result() }, # end
        sub { !$once++ },             # no multiple operations
        $extras,
    );
}

sub connect {
    my ($conn, $connect_args, $extras) = @_;

    my $once = 0;
    $conn->____run(
        "connect",
        sub { $_[0]->connect_start($connect_args) }, # start
        sub { $_[0] },                               # end
        sub { !$once++ },                            # no multiple operations
        $extras,
    );
}

1;
