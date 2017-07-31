package MariaDB::NonBlocking::Select;
use parent 'MariaDB::NonBlocking';

use v5.10.1;
use strict;
use warnings;

use Carp ();

use Sub::StrictDecl;

use IO::Select  ();
use Time::HiRes ();  # for high-res time

# Better to import this, since it is a custom op
use Ref::Util qw(is_ref is_arrayref);

use MariaDB::NonBlocking ':all';

sub ____run; # predeclare

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
        sub {},
        $conn,
        $extras,
    );
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

    $connections = is_arrayref($connections)
                    ? $connections
                    : [$connections];

    my (@per_query_results, @errors);

    my %fd_to_connection;

    my $rin = '';
    my $win = '';

    CONNECTION:
    foreach my $maria ( @$connections ) {
        next unless $have_work_for_conn->($maria);

        my $wait_for = $start->($maria);

        if ( !$wait_for ) {
            push @per_query_results, $results->($maria);

            # Nothing to wait for!
            # See if we can still use this connection
            redo CONNECTION if $have_work_for_conn->($maria);
            # Otherwise, move on to the next connection
            next CONNECTION;
        }

        my $socket_fd                 = $maria->mysql_socket_fd;
        $fd_to_connection{$socket_fd} = $maria;

        vec($rin, $socket_fd, 1) = 1 if $wait_for & MYSQL_WAIT_READ;
        vec($win, $socket_fd, 1) = 1 if $wait_for & MYSQL_WAIT_WRITE;
    }

    while (1) {
        last if !keys %fd_to_connection;

        my $found = select(my $rout = $rin, my $wout = $win, undef, $perl_timeout);
        if ( !$found ) {
            die "timeout";
        }

        foreach my $fd ( keys %fd_to_connection ) {
            my $status = 0;
            if ( vec($rout, $fd, 1) == 1 ) {
                $status |= MYSQL_WAIT_READ;
            }
            if ( vec($wout, $fd, 1) == 1 ) {
                $status |= MYSQL_WAIT_WRITE;
            }
            next unless $status;

            my $maria    = $fd_to_connection{$fd};
            my $wait_for;
            eval {
                $wait_for = $maria->cont($status);
                1;
            } or do {
                my $e = $@ || 'unknown error';
                # CRAP. One query died mid-run.  We need to disconnect
                # all the others, otherwise we might end up running
                # in a weird state!
                delete $fd_to_connection{$fd};
                # ^ should be OK to reuse; the problem is connections
                # in the middle of running queries
                $maria->disconnect for values %fd_to_connection;
                Carp::croak($e);
            };

            vec($rin, $fd, 1) = 0;
            vec($win, $fd, 1) = 0;

            while ( !$wait_for ) {
                push @per_query_results, $results->($maria);

                last unless $have_work_for_conn->($maria);
                my $wait_for = $start->($maria);
            }

            if ( !$wait_for ) {
                delete $fd_to_connection{$fd};
                next;
            }

            vec($rin, $fd, 1) = 1 if $wait_for & MYSQL_WAIT_READ;
            vec($win, $fd, 1) = 1 if $wait_for & MYSQL_WAIT_WRITE;
        }
    }

    return \@per_query_results;
}


1;
