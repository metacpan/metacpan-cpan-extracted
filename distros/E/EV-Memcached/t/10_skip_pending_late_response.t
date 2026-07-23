use strict;
use warnings;
use Test::More;
use EV;
use EV::Memcached;
use FindBin;
use lib "$FindBin::Bin/lib";
use FakeMemcached;

# skip_pending must keep the connection usable: responses for skipped
# commands are consumed and discarded (strict FIFO opaque matching), a
# later command gets its real response, and no protocol error fires.
# Pre-fix the stale response mismatched the new head's opaque:
# on_error "protocol error: expected opaque 2, got 1" + disconnect.

my $srv = FakeMemcached->new(script => sub {
    my ($listen) = @_;
    my $c = FakeMemcached->accept($listen);
    # Read BOTH requests first (responses withheld), then answer in
    # order: first the stale (skipped) one, then the live one.
    my $r1 = $c->read_request or exit 0;
    my $r2 = $c->read_request or exit 0;
    $c->respond(op => $r1->[0], opaque => $r1->[1], status => 1);  # get1 miss
    $c->respond_hit(op => $r2->[0], opaque => $r2->[1], value => 'REAL');
    sleep 2;
});

my (@events, @errors);
my $mc;
$mc = EV::Memcached->new(
    path          => $srv->path,
    on_error      => sub { push @errors, $_[0] },
    on_disconnect => sub { push @events, 'on_disconnect' },
    on_connect    => sub {
        # Connected now: get1 goes straight on the wire (in flight,
        # response withheld by the server), then gets skipped locally.
        $mc->get('key1', sub {
            push @events, 'get1: ' . (defined $_[1] ? $_[1] : 'miss/ok');
        });
        $mc->skip_pending;
        $mc->get('key2', sub {
            push @events, 'get2: ' . (defined $_[0] ? $_[0] : (defined $_[1] ? "err=$_[1]" : 'miss'));
        });
    },
);

my $t = EV::timer 1.5, 0, sub { EV::break };
EV::run;

is($mc->pending_count, 0, 'pending_count reads 0 right after skip (checked post-run)');
is_deeply(\@errors, [], 'no on_error')
    or diag "errors: @errors";
is_deeply(\@events, ['get1: skipped', 'get2: REAL'],
    'get1 fired once with "skipped"; get2 got the real response')
    or diag "events: @events";
ok($mc->is_connected, 'connection still usable');

$srv->finish;

# --- fresh command from inside a skip callback must survive ---
{
    my $srv2 = FakeMemcached->new(script => sub {
        my ($listen) = @_;
        my $c = FakeMemcached->accept($listen);
        my $r1 = $c->read_request or exit 0;   # get1 (will be skipped)
        my $r2 = $c->read_request or exit 0;   # fresh get2
        $c->respond(op => $r1->[0], opaque => $r1->[1], status => 1);  # late miss
        $c->respond_hit(op => $r2->[0], opaque => $r2->[1], value => 'FRESH');
        sleep 2;
    });

    my (@ev2, @err2);
    my $mc2;
    $mc2 = EV::Memcached->new(
        path     => $srv2->path,
        on_error => sub { push @err2, $_[0] },
    );
    $mc2->on_connect(sub {
        $mc2->get('k1', sub {
            my (undef, $e) = @_;
            push @ev2, 'get1: ' . ($e // 'miss');
            if (($e // '') eq 'skipped') {
                # Fresh command on the intact connection from a skip cb.
                $mc2->get('k2', sub {
                    push @ev2, 'get2: ' . (defined $_[0] ? $_[0] : 'err=' . ($_[1] // 'miss'));
                });
            }
        });
        $mc2->skip_pending;
    });

    my $t2 = EV::timer 1.5, 0, sub { EV::break };
    EV::run;

    is_deeply(\@err2, [], 'no on_error (fresh-from-skip variant)')
        or diag "errors: @err2";
    is_deeply(\@ev2, ['get1: skipped', 'get2: FRESH'],
        'command issued from skip callback gets its real response')
        or diag "events: @ev2";
    ok($mc2->is_connected, 'connection still usable');

    $srv2->finish;
}

done_testing;
