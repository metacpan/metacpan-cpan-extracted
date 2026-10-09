use strict;
use warnings;
use Test::More;
use EV;
use EV::Memcached;
use FindBin;
use lib "$FindBin::Bin/lib";
use FakeMemcached;

# resume_waiting_on_reconnect replays an mget held behind max_pending as
# a whole batch: none of its keys were in flight when the session died.

my $srv = FakeMemcached->new(script => sub {
    my ($listen) = @_;
    my $c1 = FakeMemcached->accept($listen);
    $c1->read_request or exit 0;  # set; the batch stays queued
    sleep 3;                      # client disconnects meanwhile; then EOF

    my $c2 = FakeMemcached->accept($listen);
    while (my $r = $c2->read_request) {
        if ($r->[0] == 0x0d && $r->[2] eq 'a') {
            $c2->respond_hit(op => $r->[0], opaque => $r->[1],
                key => 'a', value => 'VA');
        } elsif ($r->[0] == 0x0a) {
            $c2->respond(op => $r->[0], opaque => $r->[1]);
        }
    }
});

my $mc = EV::Memcached->new(
    path => $srv->path, on_error => sub {},
    max_pending => 1, resume_waiting_on_reconnect => 1,
);

my ($set_err, $mget_res, $mget_err, $mget_n, $held);
$mc->set('k', 'v', sub { (undef, $set_err) = @_; });
$mc->mget(['a', 'b'], sub {
    ($mget_res, $mget_err) = @_;
    $mget_n++;
    EV::break;
});

my $stage = 0;
$mc->on_connect(sub {
    return if $stage++;
    my $t; $t = EV::timer 0.5, 0, sub {
        undef $t;
        $held = $mc->pending_count == 1 && $mc->waiting_count == 1;
        $mc->disconnect;
        $mc->connect_unix($srv->path);
    };
});

my $end; $end = EV::timer 7, 0, sub { undef $end; EV::break };
EV::run;

ok($held, 'mget batch held whole before disconnect');
is($set_err, 'disconnected', 'in-flight set failed at disconnect');
is($mget_n, 1, 'mget callback fired exactly once');
is($mget_err, undef, 'replayed batch succeeded');
is_deeply($mget_res, { a => 'VA' }, 'replayed batch delivers its hit');
$mc->disconnect;
$srv->finish;

# --- entryless mget still replays across a resume disconnect ---
# All-undef keys leave a lone NOOP fence; replaying it delivers {}.
{
    my $srv = FakeMemcached->new(script => sub {
        my ($listen) = @_;
        my $c1 = FakeMemcached->accept($listen);
        $c1->read_request;  # EOF: client disconnects before sending
        my $c2 = FakeMemcached->accept($listen);
        my $r = $c2->read_request or exit 0;  # the replayed NOOP fence
        $c2->respond(op => $r->[0], opaque => $r->[1]);
        sleep 3;
    });

    my $mc = EV::Memcached->new(
        on_error => sub {},
        resume_waiting_on_reconnect => 1,
    );
    my ($res, $err, $n);
    $mc->connect_unix($srv->path);  # connecting; completes next iteration
    $mc->mget([undef, undef], sub { ($res, $err) = @_; $n++; });
    $mc->disconnect;                # synchronously, while still connecting
    $mc->connect_unix($srv->path);

    my $t = EV::timer 4, 0, sub { EV::break };
    EV::run;

    is($n, 1, 'entryless mget fired exactly once');
    is($err, undef, 'entryless fence replayed, no error');
    is_deeply($res, {}, 'entryless mget delivers {}');
    $srv->finish;
}

done_testing();
