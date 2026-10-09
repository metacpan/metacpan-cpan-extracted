use strict;
use warnings;
use Test::More;
use EV;
use EV::Memcached;
use FindBin;
use lib "$FindBin::Bin/lib";
use FakeMemcached;

# Teardown reentrancy: nested disconnect / DESTROY from inside drain
# callbacks must not strand ghost entries or silently drop callbacks.

# --- 1. skip_pending + nested disconnect must not poison the next session ---
# Skipped entries stay on cb_queue by design, but a disconnect() from a
# skip callback must clear them: otherwise the ghosts' dead-session opaques
# mismatch the next session's responses ("protocol error").
{
    my $srv = FakeMemcached->new(script => sub {
        my ($listen) = @_;
        my $c1 = FakeMemcached->accept($listen);
        $c1->read_request;
        $c1->read_request;  # EOF after client's disconnect
        my $c2 = FakeMemcached->accept($listen);
        my $r2 = $c2->read_request or exit 0;
        $c2->respond_hit(op => $r2->[0], opaque => $r2->[1], value => 'REAL');
        sleep 5;
    });

    my (@events, @errors);
    my $mc;
    my $phase = 0;
    $mc = EV::Memcached->new(
        path          => $srv->path,
        on_error      => sub { push @errors, $_[0] },
        on_disconnect => sub { push @events, 'on_disconnect' },
        on_connect    => sub {
            return if $phase++;
            $mc->get('key1', sub {
                push @events, 'get1: ' . (defined $_[1] ? $_[1] : 'miss/ok');
                $mc->disconnect;
            });
            $mc->skip_pending;
            $mc->connect_unix($srv->path);
            $mc->get('key2', sub {
                push @events, 'get2: ' . (defined $_[0] ? $_[0]
                    : (defined $_[1] ? "err=$_[1]" : 'miss'));
            });
        },
    );

    my $t = EV::timer 3, 0, sub { EV::break };
    EV::run;

    ok((grep { $_ eq 'get2: REAL' } @events),
        'command after nested disconnect gets its real response');
    is(scalar @errors, 0, 'no protocol error from ghost entries');
    $srv->finish;
}

# --- 2. nested DESTROY during a drain must fire the parked callbacks ---
# DESTRUCTION promises every pending callback fires once; dropping the
# last ref mid-drain must not silently swallow the parked remainder.
{
    my $srv = FakeMemcached->new(script => sub {
        my ($listen) = @_;
        my $c = FakeMemcached->accept($listen);
        $c->read_request;
        $c->read_request;
        sleep 5;
    });

    my @events;
    my $mc;
    $mc = EV::Memcached->new(
        path       => $srv->path,
        on_error   => sub {},
        on_connect => sub {
            $mc->get('k1', sub {
                push @events, 'get1: ' . ($_[1] // 'ok');
                undef $mc;
            });
            $mc->get('k2', sub { push @events, 'get2: ' . ($_[1] // 'ok') });
            $mc->get('k3', sub { push @events, 'get3: ' . ($_[1] // 'ok') });
            $mc->disconnect;
        },
    );

    my $t = EV::timer 2, 0, sub { EV::break };
    EV::run;

    is_deeply(\@events,
        ['get1: disconnected', 'get2: disconnected', 'get3: disconnected'],
        'all parked callbacks fire on nested DESTROY');
    $srv->finish;
}

# --- 3. nested DESTROY during skip_pending fires fresh stranded commands ---
# Commands issued by skip callbacks live on the live queue (skip_pending
# never splices); destroying mid-skip must fail them, not drop them.
{
    my $srv = FakeMemcached->new(script => sub {
        my ($listen) = @_;
        my $c = FakeMemcached->accept($listen);
        $c->read_request;  # may be undef: bytes never flushed before destroy
        $c->read_request;
        $c->read_request;
    });

    my @events;
    my $mc;
    $mc = EV::Memcached->new(
        path       => $srv->path,
        on_error   => sub {},
        on_connect => sub {
            $mc->get('k1', sub {
                push @events, 'get1: ' . ($_[1] // 'ok');
                $mc->get('k3', sub {
                    push @events, 'get3: ' . ($_[1] // 'ok');
                });
            });
            $mc->get('k2', sub {
                push @events, 'get2: ' . ($_[1] // 'ok');
                undef $mc;
            });
            $mc->skip_pending;
        },
    );

    my $t = EV::timer 2, 0, sub { EV::break };
    EV::run;

    is_deeply(\@events,
        ['get1: skipped', 'get2: skipped', 'get3: disconnected'],
        'command issued mid-skip fires on nested DESTROY');
    $srv->finish;
}

# --- 4. same for skip_waiting: the drain owns only its snapshot ---
{
    my $srv = FakeMemcached->new(script => sub {
        my $c = FakeMemcached->accept(shift);
        1 while $c->read_request;
    });

    my @events;
    my $mc = EV::Memcached->new(path => $srv->path, on_error => sub {});
    # still connecting: everything sits in the waiting queue
    $mc->get('k1', sub {
        push @events, 'get1: ' . ($_[1] // 'ok');
        $mc->get('k3', sub { push @events, 'get3: ' . ($_[1] // 'ok') });
    });
    $mc->get('k2', sub {
        push @events, 'get2: ' . ($_[1] // 'ok');
        undef $mc;
    });
    $mc->skip_waiting;

    is_deeply(\@events,
        ['get1: skipped', 'get2: skipped', 'get3: disconnected'],
        'command issued mid-skip_waiting fires on nested DESTROY');
    $srv->finish;
}

done_testing();
