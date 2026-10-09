use strict;
use warnings;
use Test::More;
use EV;
use EV::Memcached;
use IO::Socket::INET;
use FindBin;
use lib "$FindBin::Bin/lib";
use FakeMemcached;

# --- 1. TCP connect must fail over past the first getaddrinfo result ---
# 'localhost' typically resolves to ::1 first; a v4-only server must
# still be reachable. (On hosts where localhost is v4-first this passes
# trivially; it guards the failover loop against regressions.)
{
    my $srv = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1:0', Listen => 5, Proto => 'tcp',
        ReuseAddr => 1,
    ) or die "listen: $!";
    my $port = $srv->sockport;

    my ($connected, $error);
    my $mc = EV::Memcached->new(
        host => 'localhost', port => $port,
        on_error   => sub { $error = "@_"; EV::break },
        on_connect => sub { $connected = 1; EV::break },
    );
    my $t = EV::timer 5, 0, sub { $error //= 'TIMEOUT'; EV::break };
    EV::run;

    ok($connected, "connect via 'localhost' to v4-only listener")
        or diag("error was: $error");
    $mc->disconnect if $connected;

    # Positive control: the listener itself is connectable.
    my ($c2, $e2);
    my $mc2 = EV::Memcached->new(
        host => '127.0.0.1', port => $port,
        on_error   => sub { $e2 = "@_"; EV::break },
        on_connect => sub { $c2 = 1; EV::break },
    );
    my $t2 = EV::timer 5, 0, sub { $e2 //= 'TIMEOUT'; EV::break };
    EV::run;
    ok($c2, 'control: numeric 127.0.0.1 connects') or diag("error: $e2");
    $mc2->disconnect if $c2;
}

# --- 2. over-long unix path must behave like any connect failure ---
# Route through the common failure path: reconnect scheduled (and given
# up cleanly), waiting queue drained, no silent death.
{
    my @errors;
    my $mc = EV::Memcached->new(
        path => 'x' x 200, reconnect => 1, reconnect_delay => 50,
        max_reconnect_attempts => 2,
        on_error => sub { push @errors, "@_" },
    );
    my $fired;
    my $err = do {
        local $@;
        eval { $mc->set('k', 'v', sub { $fired = $_[1] // 'ok' }) };
        $@;
    };
    is($err, '', 'command queues while reconnect pending');
    my $t = EV::timer 2, 0, sub { EV::break };
    EV::run;

    ok((grep { /max reconnect attempts reached/ } @errors),
        'reconnect scheduled and given up');
    is($fired, 'disconnected', 'waiting command drained on give-up');
}

# --- 3. the socket must not leak across exec (FD_CLOEXEC) ---
SKIP: {
    skip 'no /proc/self/fd (non-Linux)', 1 unless -d '/proc/self/fd';
    my $srv = FakeMemcached->new(script => sub {
        my ($listen) = @_;
        my $c = FakeMemcached->accept($listen);
        sleep 5;
    });
    my $exec_socks = sub {
        my $out = qx{ls -l /proc/self/fd 2>/dev/null};
        return $out =~ /socket:\[(\d+)\]/g;
    };
    my %inherited = map { $_ => 1 } $exec_socks->();
    my $mc = EV::Memcached->new(
        path => $srv->path, on_error => sub { die "connect: @_" });
    $mc->on_connect(sub { EV::break });
    my $t = EV::timer 5, 0, sub { die "connect timeout" };
    EV::run;

    my @leaked = grep { !$inherited{$_} } $exec_socks->();
    is(scalar @leaked, 0, 'no socket fds visible in exec child');
    $mc->disconnect;
    $srv->finish;
}

done_testing();
