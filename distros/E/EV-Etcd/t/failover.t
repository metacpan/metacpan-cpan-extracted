#!/usr/bin/env perl
# With several endpoints, a call that cannot reach its endpoint moves the
# client to the next one; no health_interval needed.
use strict;
use warnings;
BEGIN { delete @ENV{qw(http_proxy https_proxy grpc_proxy)} }
use lib 'blib/lib', 'blib/arch';
use Test::More;
use IO::Socket::INET;
use Time::HiRes ();

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

sub rpc {
    my ($client, $method, @args) = @_;
    my ($resp, $err, $done);
    $client->$method(@args, sub { ($resp, $err) = @_; $done = 1; EV::break });
    my $t = EV::timer(4, 0, sub { EV::break });
    EV::run;
    die "$method failed: " . ($err ? $err->{message} : 'timeout') if $err || !$done;
    return $resp;
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

SKIP: {
    # Two rotations must not destroy the first channel under queued unary
    # requests. Streams waiting on it must reconnect on the reachable endpoint.
    # A local listener that never accepts counts as connected on gRPC 1.30.
    my $started = Time::HiRes::time();
    IO::Socket::INET->new(PeerAddr => '192.0.2.1', PeerPort => 2379, Timeout => 0.5);
    skip 'TEST-NET-1 fails fast here instead of timing out', 18
        if Time::HiRes::time() - $started < 0.4;
    my $writer = EV::Etcd->new(endpoints => [$live]);
    my $lease = rpc($writer, 'lease_grant', 30)->{id};
    my $election = "$key/election";
    rpc($writer, 'election_campaign', $election, $lease, 'leader');
    my $c = EV::Etcd->new(
        endpoints => ['192.0.2.1:2379', refused_endpoint(), $live],
        timeout => 1,
    );
    my (%ready, %errors, @handles);
    my (%blocking_done, %blocking_errors);
    $c->lock("$key/queued-lock", $lease, sub {
        $blocking_done{lock} = 1; $blocking_errors{lock} = $_[1];
    });
    $c->election_campaign("$key/queued-election", $lease, 'leader', sub {
        $blocking_done{campaign} = 1; $blocking_errors{campaign} = $_[1];
    });
    my $callback = sub {
        my $name = shift;
        return sub {
            if ($_[1]) { $errors{$name} = $_[1] }
            else { $ready{$name} = 1 }
        };
    };
    push @handles, $c->watch("$key/queued", $callback->('watch'));
    push @handles, $c->lease_keepalive($lease, $callback->('keepalive'));
    push @handles, $c->election_observe($election, $callback->('observe'));
    my ($first_error, $retry_error, $queued_error, $done);
    $c->get($key, sub {
        $first_error = $_[1];
        $c->get($key, sub { $retry_error = $_[1]; $done++ });
    });
    my $later = EV::timer(0.4, 0, sub {
        $c->get($key, sub { $queued_error = $_[1]; $done++ });
    });
    my $check = EV::timer(0.02, 0.02, sub {
        EV::break if $done && $done == 2 && keys(%ready) + keys(%errors) == 3
            && keys(%blocking_done) == 2;
    });
    my $guard = EV::timer(5, 0, sub { EV::break });
    EV::run;
    undef $check;
    undef $guard;
    undef $later;
    is($done, 2, 'both queued unary requests completed');
    is($first_error && $first_error->{status}, 'DEADLINE_EXCEEDED', 'first call advances the connecting endpoint');
    is($retry_error && $retry_error->{status}, 'UNAVAILABLE', 'retry advances the refused endpoint');
    is($queued_error && $queued_error->{status}, 'DEADLINE_EXCEEDED', 'older queued call retains its own deadline');
    ok($queued_error && $queued_error->{retryable}, 'older queued call remains retryable after two rotations');
    for my $name (qw(lock campaign)) {
        ok($blocking_done{$name}, "queued $name completes during failover");
        is($blocking_errors{$name} && $blocking_errors{$name}{status}, 'UNAVAILABLE', "$name reports the abandoned endpoint");
        is($blocking_errors{$name} && $blocking_errors{$name}{retryable}, 0, "$name requires a fresh lease");
    }
    for my $name (qw(watch keepalive observe)) {
        ok($ready{$name}, "queued $name reconnects on the third endpoint");
        is($errors{$name}, undef, "$name reports no terminal error during failover");
    }
    $_->cancel(sub {}) for @handles;
    my $retry_lease = rpc($writer, 'lease_grant', 30)->{id};
    rpc($c, 'lock', "$key/queued-lock", $retry_lease);
    rpc($c, 'election_campaign', "$key/queued-election", $retry_lease, 'leader');
    pass('both blocking operations recover with a fresh lease on the healthy endpoint');
    rpc($writer, 'lease_revoke', $retry_lease);
    rpc($writer, 'lease_revoke', $lease);
}

{
    my $writer = EV::Etcd->new(endpoints => [$live]);
    my $lease = rpc($writer, 'lease_grant', 30)->{id};
    for my $method (qw(lock election_campaign)) {
        my $c = EV::Etcd->new(endpoints => [refused_endpoint()]);
        my ($done, $error);
        my @args = ("$key/refused-$method", $lease);
        push @args, 'candidate' if $method eq 'election_campaign';
        $c->$method(@args, sub { $done++; $error = $_[1]; EV::break });
        my $guard = EV::timer(4, 0, sub { EV::break });
        EV::run;
        is($done, 1, "$method reports a transport failure once");
        is($error && $error->{status}, 'UNAVAILABLE', "$method retains the transport status");
        is($error && $error->{retryable}, 0, "$method does not advertise same-lease retries");
    }
    rpc($writer, 'lease_revoke', $lease);
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
    my $health_calls = 0;
    my $callback = sub { $health_calls++; EV::break };
    my $c = EV::Etcd->new(
        endpoints        => [refused_endpoint()],
        health_interval  => 0.05,
        on_health_change => $callback,
    );
    # new() must retain the callback value, not alias the caller's scalar.
    undef $callback;
    $c->get($key, sub {});
    my $t = EV::timer(3, 0, sub { EV::break });
    EV::run;
    is($health_calls, 1, 'health callback survives releasing the caller variable');
}

{
    my $c = EV::Etcd->new(endpoints => [$live]);
    $c->delete($key, { prefix => 1 }, sub { EV::break });
    my $t = EV::timer(2, 0, sub { EV::break });
    EV::run;
}

done_testing();
