use strict;
use warnings;
use Test::More;
use EV;
use EV::Memcached;
use FindBin;
use lib "$FindBin::Bin/lib";
use FakeMemcached;

# Cancellation callbacks must not swallow commands issued for a NEW
# session: from inside a "disconnected" cancellation callback, reconnect
# and issue a fresh command — it must reach the server and fire with its
# real result (pre-fix the drain loop kept popping the live queue and the
# fresh command was cancelled with "disconnected" immediately).

my $srv = FakeMemcached->new(script => sub {
    my ($listen) = @_;
    # Connection 1: get1 may arrive; client then disconnects (EOF).
    my $c1 = FakeMemcached->accept($listen);
    $c1->read_request;   # get1 (or undef if the write raced the close)
    $c1->read_request;   # EOF
    # Connection 2: answer the re-issued command with a real value.
    my $c2 = FakeMemcached->accept($listen);
    my $r2 = $c2->read_request or exit 0;
    $c2->respond_hit(op => $r2->[0], opaque => $r2->[1], value => 'V2');
    sleep 2;
});

my (@events, @errors);
my $mc = EV::Memcached->new(
    path     => $srv->path,
    on_error => sub { push @errors, $_[0] },
);
$mc->get('k1', sub {
    my (undef, $err) = @_;
    push @events, 'get1: ' . ($err // 'ok');
    # Reentrant: reconnect + fresh command from inside the drain.
    $mc->connect_unix($srv->path);
    $mc->get('k2', sub {
        push @events, 'get2: ' . (defined $_[0] ? $_[0] : "err=" . ($_[1] // '?'));
    });
});
$mc->disconnect;   # synchronously fires get1's callback with "disconnected"

my $t = EV::timer 1.5, 0, sub { EV::break };
EV::run;

is_deeply(\@errors, [], 'no on_error')
    or diag "errors: @errors";
is_deeply(\@events, ['get1: disconnected', 'get2: V2'],
    'command issued from cancellation callback reached the new session')
    or diag "events: @events";

$srv->finish;

# --- cross-queue variant: get1 genuinely IN FLIGHT (cb_queue) ---
# get1's cancellation cb enqueues get2 while connecting (so get2 heads
# for the WAIT queue) DURING cancel_pending's drain; handle_disconnect's
# subsequent cancel_waiting must not swallow it (the two-queue snapshot
# is taken before any callback runs).
{
    my $srv2 = FakeMemcached->new(script => sub {
        my ($listen) = @_;
        # Connection 1: get1 may arrive (response withheld); the client
        # then disconnects (EOF). Tolerate the packet never arriving —
        # the disconnect can race the write flush; what matters is that
        # get1's entry is on cb_queue (in flight) client-side.
        my $c1 = FakeMemcached->accept($listen);
        $c1->read_request;
        $c1->read_request;   # EOF
        # Connection 2: answer the re-issued command with a real value.
        my $c2 = FakeMemcached->accept($listen);
        my $r2 = $c2->read_request or exit 0;
        $c2->respond_hit(op => $r2->[0], opaque => $r2->[1], value => 'V2x');
        sleep 2;
    });

    my (@ev2, @err2);
    my $first = 1;
    my $mc2;
    $mc2 = EV::Memcached->new(
        path     => $srv2->path,
        on_error => sub { push @err2, $_[0] },
    );
    $mc2->on_connect(sub {
        return unless $first--;   # scenario runs on the FIRST connect only
        # get1 goes straight on the wire: in flight on cb_queue, server
        # withholds the response.
        $mc2->get('k1', sub {
            my (undef, $err) = @_;
            push @ev2, 'get1: ' . ($err // 'ok');
            # Reentrant: reconnect + fresh command from inside the drain.
            $mc2->connect_unix($srv2->path);
            $mc2->get('k2', sub {
                push @ev2, 'get2: ' . (defined $_[0] ? $_[0] : "err=" . ($_[1] // '?'));
            });
        });
        # disconnect from a zero timer: event context, after on_connect
        # returned, get1 genuinely in flight.
        my $z; $z = EV::timer 0, 0, sub { undef $z; $mc2->disconnect };
    });

    my $t2 = EV::timer 1.5, 0, sub { EV::break };
    EV::run;

    is_deeply(\@err2, [], 'no on_error (in-flight variant)')
        or diag "errors: @err2";
    is_deeply(\@ev2, ['get1: disconnected', 'get2: V2x'],
        'in-flight cancel: fresh command for the new session survives teardown')
        or diag "events: @ev2";

    $srv2->finish;
}

done_testing;
