#!perl
use v5.10.1;
use strict;
use warnings;

use blib;
use Promises qw(collect);
use MariaDB::NonBlocking::Promises;

# methinks collect() has a (doc?) bug
#perl -MPromises=collect,deferred -MAnyEvent -E 'my ($x, $y) = map deferred, 1..2; my $cv = AnyEvent->condvar; collect($x->promise, $y->promise)->then(sub { say "All finished: @_"; $cv->send; }, sub { say "Error! @_"; $cv->send; }); my @w = ( AnyEvent->timer(after => 1, cb => sub { say "Resolving X"; $x->reject("X") }), AnyEvent->timer(after => 2, cb => sub { say "Resolving Y"; $y->resolve("Y") })); $cv->recv; say "End!"'

# In the same vein as collect(), but will *not* immediately
# reject the promise if any single one fails.
# Useful when we want all connections to gracefully stop
# their processing before moving on;  this ensures that
# the handles can be safely reused
sub collect_all_resolve_or_reject {
    my $remaining = @_;
    my $deferred  = Promises::deferred;
    my (@results, @errors);

    foreach my $idx ( 0..$#_ ) {
        $_[$idx]->then(
            sub {
                $remaining--;
                $results[$idx] = \@_ unless @errors;
                if ( !$remaining ) {
                    @errors
                        ? $deferred->reject(@errors)
                        : $deferred->resolve(@results);
                }
            },
            sub {
                $remaining--;
                push @errors, @_;
                @results = (); # no need to keep these around anymore,
                               # since we won't use them.
                $deferred->reject(@errors) if !$remaining;
            }
        )
    }

    if ( !$remaining && $deferred->is_in_progress ) {
        @errors
            ? $deferred->reject(@errors)
            : $deferred->resolve(@results);
    }

    return $deferred->promise;
}

my @queries = (
    [
        "SELECT CONNECTION_ID(), RAND(6959)",
        [ "select 12, rand(464)", {want_hashrefs => 1} ],
        [ "select 1, rand(464), ? as my_param", undef, ["query param"]],
    ],
    [
        "select sleep(1)",
    ],
    [
        "select sleep(2)"
    ],
);

sub run_queries {
    my @all_connections; # used to disconnect all handles in case of an error
    my $extras = {
        perl_timeout => 0.03
    }; # Used to cancel all promises in case of an error

    my @promises;
    for (1..3) {
        # Create 9 connections to mysql (3 promises with 3 connections each)
        my $connections = [ map MariaDB::NonBlocking::Promises->init, 1..2 ];

        # Used during error handling to disconnect everything early
        push @all_connections, $connections;

        push @promises, MariaDB::NonBlocking::Promises::connect(
            $connections,
            {
                host     => "127.0.0.1",
                user     => "root",
                password => "",
            },
            $extras,
        )->then(
            sub {
                return if exists $extras->{cancel}; # Another connection died

                my ($connections) = @_;

                # Return a promise that will be resolved once all the
                # queries are run; the resolve handler will then get
                # the per-query results
                return MariaDB::NonBlocking::Promises::run_multiple_queries(
                        $connections,
                        pop @queries,
                        $extras,
                       );
            },
            sub {
                say "Rejected! @_"
            },
        );
    }

    my $handle_errors = sub {
        # If we already handled an error then we have nothing to do
        return if exists $extras->{cancel};
        # By setting $extras->{cancel}, the other promises will
        # cancel themselves the next time their callbacks are
        # tickled by the eventloop.  And we force that to happen
        # with the disconnect below!
        $extras->{cancel} = "Error in related promise";

        # Disconnect should not die -- if it does, then
        # that takes precedence to whatever else happened!
        $_->disconnect for grep defined,
                           map @{$_//[]},
                           @all_connections;

        die $_[0]; # rethrow
    };

    collect_all_resolve_or_reject(
        map $_->catch($handle_errors), @promises
    )->finally(sub {
        @all_connections = ();
        # ^ At this point, the connections for this promise will
        # be freed.
    });
}

{
    # Wait for the promises to be fulfilled.
    use AnyEvent;
    my $cv = AnyEvent->condvar;
    run_queries()->then(
        sub { use Data::Dumper; say STDERR Dumper(\@_); $cv->send },
        sub { say STDERR "Error! @_"; $cv->send },
    );
    $cv->recv;
    say STDERR "Done waiting";
}

say "END";
