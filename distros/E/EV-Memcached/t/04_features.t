use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Memcached;

my $host = $ENV{TEST_MEMCACHED_HOST} || '127.0.0.1';
my $port = $ENV{TEST_MEMCACHED_PORT} || 11211;

my $sock = IO::Socket::INET->new(
    PeerAddr => $host, PeerPort => $port, Proto => 'tcp', Timeout => 1,
);
unless ($sock) { plan skip_all => "No memcached at $host:$port" }
close $sock;

sub make_mc {
    my %opts = @_;
    my $mc = EV::Memcached->new(
        host => $host, port => $port,
        on_error => sub { diag "error: @_" },
        %opts,
    );
    $mc->on_connect(sub { EV::break });
    my $t = EV::timer 5, 0, sub { fail("connect timeout"); EV::break };
    EV::run;
    $mc->on_connect(undef);
    return $mc;
}

sub run_ev {
    my $t = EV::timer 5, 0, sub { fail("timeout"); EV::break };
    EV::run;
}

my $prefix = "ev_mc_feat_$$\_";

# --- key length validation ---
{
    my $mc = make_mc();
    my $long_key = 'x' x 251;
    eval { $mc->set($long_key, 'val') };
    like($@, qr/key too long/, "key >250 bytes rejected");

    my $ok_key = 'x' x 250;
    $mc->set($ok_key, 'val', sub {
        my ($res, $err) = @_;
        ok(!$err, "key =250 bytes accepted");
        EV::break;
    });
    run_ev();
    $mc->disconnect;
}

# --- mget rejects too-long key without corrupting connection ---
# Regression: a too-long key in the middle of an mget array used to croak
# after partial GETKQ packets had been queued, leaving the connection in
# a broken state (opaque mismatch on next response).
{
    my $mc = make_mc();
    my $k1 = "${prefix}mget_pre";
    my $k2 = "${prefix}mget_post";
    $mc->set($k1, "v1", sub {
        $mc->set($k2, "v2", sub {
            eval { $mc->mget([$k1, 'x' x 251, $k2], sub {}) };
            like($@, qr/key too long/, "mget: too-long key rejected");

            # Connection must still be usable after the rejection.
            $mc->mget([$k1, $k2], sub {
                my ($results, $err) = @_;
                ok(!$err, "mget: connection survives rejected call");
                is($results->{$k1}, "v1", "mget: $k1 still readable");
                is($results->{$k2}, "v2", "mget: $k2 still readable");
                $mc->disconnect;
                EV::break;
            });
        });
    });
    run_ev();
}

# --- connect_timeout ---
# Tested via connect_timeout getter/setter below.
# Non-routable IP test skipped: behavior varies across platforms
# (Linux: EINPROGRESS+timeout, FreeBSD: immediate EHOSTUNREACH).

# --- connect_timeout getter/setter ---
{
    my $mc = make_mc();
    is($mc->connect_timeout, 0, "connect_timeout default is 0");
    $mc->connect_timeout(5000);
    is($mc->connect_timeout, 5000, "connect_timeout set to 5000");
    $mc->disconnect;
}

# --- XS ALIAS: set/add/replace share implementation ---
{
    my $mc = make_mc();
    my $key = "${prefix}alias";

    $mc->set($key, "v1", sub {
        my ($res, $err) = @_;
        ok(!$err, "set via XS ALIAS");

        $mc->replace($key, "v2", sub {
            my ($res, $err) = @_;
            ok(!$err, "replace via XS ALIAS");

            $mc->delete($key, sub {
                $mc->add($key, "v3", sub {
                    my ($res, $err) = @_;
                    ok(!$err, "add via XS ALIAS");
                    EV::break;
                });
            });
        });
    });
    run_ev();
    $mc->disconnect;
}

# --- XS ALIAS: incr/decr ---
{
    my $mc = make_mc();
    my $key = "${prefix}arith_alias";

    $mc->set($key, "100", sub {
        $mc->incr($key, 5, sub {
            my ($val, $err) = @_;
            is($val, 105, "incr via XS ALIAS");

            $mc->decr($key, 3, sub {
                my ($val, $err) = @_;
                is($val, 102, "decr via XS ALIAS");
                EV::break;
            });
        });
    });
    run_ev();
    $mc->disconnect;
}

# --- XS ALIAS: version/noop/quit share implementation ---
{
    my $mc = make_mc();
    $mc->version(sub {
        my ($ver, $err) = @_;
        ok($ver, "version via XS ALIAS: $ver");
        $mc->noop(sub {
            my ($res, $err) = @_;
            ok($res, "noop via XS ALIAS");
            $mc->disconnect;
            EV::break;
        });
    });
    run_ev();
}

# --- XS ALIAS: append/prepend ---
{
    my $mc = make_mc();
    my $key = "${prefix}ap_alias";
    $mc->set($key, "hello", sub {
        $mc->append($key, " world", sub {
            my ($res, $err) = @_;
            ok(!$err, "append via XS ALIAS");
            $mc->prepend($key, "say ", sub {
                ok(!$err, "prepend via XS ALIAS");
                $mc->get($key, sub {
                    my ($val) = @_;
                    is($val, "say hello world", "append/prepend correct");
                    EV::break;
                });
            });
        });
    });
    run_ev();
    $mc->disconnect;
}

# --- XS ALIAS: touch/gat/gats ---
{
    my $mc = make_mc();
    my $key = "${prefix}tg_alias";
    $mc->set($key, "data", 0, 42, sub {
        $mc->touch($key, 300, sub {
            my ($res, $err) = @_;
            ok(!$err, "touch via XS ALIAS");

            $mc->gat($key, 300, sub {
                my ($val, $err) = @_;
                is($val, "data", "gat via XS ALIAS");

                $mc->gats($key, 300, sub {
                    my ($result, $err) = @_;
                    is($result->{value}, "data", "gats value");
                    is($result->{flags}, 42, "gats flags");
                    ok($result->{cas}, "gats cas");
                    EV::break;
                });
            });
        });
    });
    run_ev();
    $mc->disconnect;
}

# --- new() constructor in XS ---
{
    my $mc = EV::Memcached->new(
        host            => $host,
        port            => $port,
        max_pending     => 10,
        keepalive       => 5,
        priority        => 1,
        connect_timeout => 3000,
        on_error        => sub { diag "error: @_" },
    );
    $mc->on_connect(sub { EV::break });
    my $t = EV::timer 5, 0, sub { fail("timeout"); EV::break };
    EV::run;

    ok($mc->is_connected, "XS new() connected");
    is($mc->max_pending, 10, "XS new() max_pending");
    is($mc->connect_timeout, 3000, "XS new() connect_timeout");
    $mc->disconnect;
}

# --- fire-and-forget set with expiry and flags ---
{
    my $mc = make_mc();
    my $key = "${prefix}ff_opts";
    $mc->set($key, "val", 300, 77);
    $mc->noop(sub {
        $mc->gets($key, sub {
            my ($result, $err) = @_;
            is($result->{value}, "val", "fire-and-forget set with expiry/flags: value");
            is($result->{flags}, 77, "fire-and-forget set with expiry/flags: flags");
            EV::break;
        });
    });
    run_ev();
    $mc->disconnect;
}

done_testing;
