#!/usr/bin/env perl
# With several endpoints, a call that cannot reach its endpoint moves the
# client to the next one; no health_interval needed.
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use Test::More;
use IO::Socket::INET;

BEGIN { eval { require EV }; plan skip_all => 'EV required' if $@ }
use EV;
use EV::Etcd;

my $live = '127.0.0.1:2379';

my $available = 0;
eval {
    my $c = EV::Etcd->new(endpoints => [$live], timeout => 2);
    $c->status(sub { $available = 1 if !$_[1]; EV::break });
    my $t = EV::timer(3, 0, sub { EV::break });
    EV::run;
};
plan skip_all => "etcd not available on $live" unless $available;

sub refused_endpoint {
    my $s = IO::Socket::INET->new(Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0)
        or die "listen: $!";
    my $port = $s->sockport;
    close $s;
    return "127.0.0.1:$port";
}

sub put_once {
    my ($client, $key) = @_;
    my $err = 'no callback';
    $client->put($key, 'v', sub { $err = $_[1]; EV::break });
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    return $err;
}

my $key = "/test_failover_$$";

{
    my $c = EV::Etcd->new(endpoints => [refused_endpoint(), $live], timeout => 2);
    my $err = put_once($c, $key);
    is(ref $err && $err->{status}, 'UNAVAILABLE', 'call on a refused first endpoint fails');
    ok(ref $err && $err->{retryable}, 'the failure is retryable');
    is(put_once($c, $key), undef, 'next call reaches the second endpoint');
}

{
    # three rotations would wrap back to the dead first endpoint
    my $c = EV::Etcd->new(
        endpoints => [refused_endpoint(), $live, refused_endpoint()], timeout => 2);
    my $pending = 3;
    my @errs;
    $c->put($key, 'v', sub { push @errs, $_[1]; EV::break unless --$pending }) for 1 .. 3;
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    is(scalar(grep { ref } @errs), 3, 'concurrent calls on the dead endpoint all fail');
    is(put_once($c, $key), undef, 'a burst of failures advances one endpoint');
}

{
    # TEST-NET-1 never answers: the call either times out while connecting
    # or fails fast where there is no route; both must fail over
    my $c = EV::Etcd->new(endpoints => ['192.0.2.1:2379', $live], timeout => 1);
    ok(ref put_once($c, $key), 'call on an unreachable endpoint fails');
    is(put_once($c, $key), undef, 'next call reaches the second endpoint');
}

{
    # the second call is still queued on the unreachable channel when the
    # first one's timeout moves the client on; it must not be failed early
    # with a non-retryable "Channel Destroyed"
    my $c = EV::Etcd->new(endpoints => ['192.0.2.1:2379', $live], timeout => 1);
    my ($pending, @errs) = (2);
    my $done = sub { my $i = shift; sub { $errs[$i] = $_[1]; EV::break unless --$pending } };
    $c->put($key, 'v', $done->(0));
    my $later = EV::timer(0.5, 0, sub { $c->put($key, 'v', $done->(1)) });
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    ok(!ref $errs[1] || $errs[1]{retryable},
        'call queued on the old channel ends retryable or succeeds')
        or diag explain $errs[1];
}

{
    # the listener never answers, so the channel stays connecting (or, on old
    # gRPC, connected): neither is a failure
    my $hole = IO::Socket::INET->new(Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0)
        or die "listen: $!";
    my @health;
    my $c = EV::Etcd->new(
        endpoints        => ['127.0.0.1:' . $hole->sockport],
        timeout          => 1,
        health_interval  => 0.2,
        on_health_change => sub { push @health, [@_] },
    );
    $c->put($key, 'v', sub {});
    my $t = EV::timer(1.5, 0, sub { EV::break });
    EV::run;
    is(scalar @health, 0, 'a connect in progress is not reported unhealthy')
        or diag explain \@health;
}

{
    my $c = EV::Etcd->new(endpoints => [refused_endpoint(), $live]);
    my $writer = EV::Etcd->new(endpoints => [$live]);
    my ($event, $err);
    my $w = $c->watch("$key/w", sub {
        my ($resp, $e) = @_;
        if ($e) { $err = $e; EV::break; return }
        if (@{ $resp->{events} || [] }) { $event = $resp->{events}[0]; EV::break }
    });
    my $tick = EV::timer(0.5, 0.5, sub { $writer->put("$key/w", 'x', sub {}) });
    my $t = EV::timer(8, 0, sub { EV::break });
    EV::run;
    is($err, undef, 'watch on a refused first endpoint does not give up');
    is($event && $event->{kv}{value}, 'x', 'watch reconnects to the second endpoint');
    $w->cancel(sub {});
}

{
    my @health;
    my $c = EV::Etcd->new(
        endpoints        => [refused_endpoint()],
        health_interval  => 0.3,
        on_health_change => sub { push @health, [@_]; EV::break },
    );
    $c->put($key, 'v', sub {});
    my $t = EV::timer(3, 0, sub { EV::break });
    EV::run;
    is($health[0] && $health[0][0], 0, 'fractional health_interval is honoured');
}

{
    my $c = EV::Etcd->new(endpoints => [$live]);
    $c->delete($key, { prefix => 1 }, sub { EV::break });
    my $t = EV::timer(2, 0, sub { EV::break });
    EV::run;
}

done_testing();
