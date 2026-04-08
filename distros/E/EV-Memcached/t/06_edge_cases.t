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

my $prefix = "ev_mc_edge_$$\_";

# --- quit command ---
{
    my $mc = make_mc();
    my $quit_ok;
    $mc->quit(sub {
        my ($res, $err) = @_;
        $quit_ok = !$err;
        EV::break;
    });
    run_ev();
    ok($quit_ok, "quit: server acknowledged");
}

# --- mgets (multi-get with metadata) ---
{
    my $mc = make_mc();
    my @keys = map { "${prefix}mgets_$_" } 1..3;
    $mc->set($keys[0], "val1", 0, 11);
    $mc->set($keys[2], "val3", 0, 33);
    $mc->noop(sub {
        $mc->mgets(\@keys, sub {
            my ($results, $err) = @_;
            ok(!$err, "mgets: no error");
            is(ref $results, 'HASH', "mgets: returns hashref");

            ok(exists $results->{$keys[0]}, "mgets: key 1 found");
            is($results->{$keys[0]}{value}, "val1", "mgets: key 1 value");
            is($results->{$keys[0]}{flags}, 11, "mgets: key 1 flags");
            ok($results->{$keys[0]}{cas}, "mgets: key 1 cas");

            ok(!exists $results->{$keys[1]}, "mgets: key 2 miss");

            is($results->{$keys[2]}{value}, "val3", "mgets: key 3 value");
            is($results->{$keys[2]}{flags}, 33, "mgets: key 3 flags");

            $mc->disconnect;
            EV::break;
        });
    });
    run_ev();
}

# --- quiet fire-and-forget SET (SETQ) ---
{
    my $mc = make_mc();
    my $key = "${prefix}setq_test";

    # Fire-and-forget uses SETQ (no server response)
    for my $i (1..100) {
        $mc->set("${key}_$i", "v$i");
    }

    # Fence to ensure all SETQ completed
    $mc->noop(sub {
        # Verify a sample
        $mc->get("${key}_50", sub {
            my ($val, $err) = @_;
            is($val, "v50", "quiet SET (SETQ): value correct");

            $mc->get("${key}_100", sub {
                my ($val, $err) = @_;
                is($val, "v100", "quiet SET (SETQ): last value correct");
                $mc->disconnect;
                EV::break;
            });
        });
    });
    run_ev();
}

# --- quiet fire-and-forget flush (FLUSHQ) ---
{
    my $mc = make_mc();
    $mc->set("${prefix}flushq", "val", sub {
        $mc->flush;  # fire-and-forget flush
        $mc->noop(sub {
            $mc->get("${prefix}flushq", sub {
                my ($val, $err) = @_;
                ok(!defined $val, "quiet FLUSH (FLUSHQ): data cleared");
                $mc->disconnect;
                EV::break;
            });
        });
    });
    run_ev();
}

# --- waiting_timeout expiry ---
{
    # Queue commands while reconnecting (not connected), so they stay
    # in the waiting queue and can't be sent. The waiting_timeout timer
    # fires and cancels them before reconnect succeeds.
    my @errors;
    my $mc = EV::Memcached->new(
        host                        => $host,
        port                        => $port + 1000, # wrong port — connect will fail
        reconnect                   => 1,
        reconnect_delay             => 5000, # 5s delay — won't reconnect in time
        max_reconnect_attempts      => 2,
        resume_waiting_on_reconnect => 1,
        waiting_timeout             => 100,  # 100ms timeout
        on_error                    => sub {},
    );

    # Queue commands during reconnect delay — they go to wait_queue
    my $w; $w = EV::timer 0.2, 0, sub {
        undef $w;
        for my $i (1..5) {
            $mc->set("${prefix}wt_$i", "v", sub {
                my ($res, $err) = @_;
                push @errors, $err if $err;
            });
        }
        ok($mc->waiting_count > 0, "waiting_timeout: commands queued while reconnecting");
    };

    # Check after 500ms — timeout should have fired
    my $w2; $w2 = EV::timer 1, 0, sub {
        undef $w2;
        my $timeouts = grep { /waiting timeout/ } @errors;
        ok($timeouts > 0, "waiting_timeout: $timeouts commands expired");
        $mc->disconnect;
        EV::break;
    };
    run_ev();
}

# --- large value error ---
{
    my $mc = make_mc();
    my $big = 'x' x (1024 * 1024 + 1); # >1MB default limit
    $mc->set("${prefix}big", $big, sub {
        my ($res, $err) = @_;
        ok($err, "large value: error returned");
        like($err, qr/VALUE_TOO_LARGE|TOO_LARGE/i, "large value: correct error type");
        $mc->disconnect;
        EV::break;
    });
    run_ev();
}

# --- Unix socket connection ---
SKIP: {
    my $unix_path = $ENV{TEST_MEMCACHED_UNIX};
    skip "TEST_MEMCACHED_UNIX not set", 2 unless $unix_path;

    my $mc = EV::Memcached->new(
        path     => $unix_path,
        on_error => sub { diag "unix error: @_" },
    );
    $mc->on_connect(sub { EV::break });
    my $t = EV::timer 5, 0, sub { EV::break };
    EV::run;
    $mc->on_connect(undef);

    ok($mc->is_connected, "unix socket: connected");
    $mc->version(sub {
        my ($ver, $err) = @_;
        ok($ver, "unix socket: version=$ver");
        $mc->disconnect;
        EV::break;
    });
    run_ev();
}

done_testing;
