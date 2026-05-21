use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Memcached;

my $host = $ENV{TEST_MEMCACHED_HOST} || '127.0.0.1';
my $port = $ENV{TEST_MEMCACHED_PORT} || 11211;

my $sock = IO::Socket::INET->new(
    PeerAddr => $host,
    PeerPort => $port,
    Proto    => 'tcp',
    Timeout  => 1,
);
unless ($sock) {
    plan skip_all => "No memcached at $host:$port";
}
close $sock;

my $mc = EV::Memcached->new(
    host     => $host,
    port     => $port,
    on_error => sub { diag "error: @_" },
);

# Wait for connect
{
    my $t = EV::timer 5, 0, sub { EV::break };
    $mc->on_connect(sub { EV::break });
    EV::run;
    ok($mc->is_connected, 'connected');
    $mc->on_connect(undef);
}

sub run_with_timeout {
    my $t = EV::timer 5, 0, sub { fail("timeout"); EV::break };
    EV::run;
}

my $prefix = "ev_mc_test_$$\_";

# --- SET / GET ---
{
    my $key = "${prefix}simple";
    $mc->set($key, "hello world", sub {
        my ($res, $err) = @_;
        ok(!$err, "set: no error");

        $mc->get($key, sub {
            my ($val, $err) = @_;
            is($val, "hello world", "get: correct value");
            ok(!$err, "get: no error");
            EV::break;
        });
    });
    run_with_timeout();
}

# --- GET miss ---
{
    $mc->get("${prefix}nonexistent_key_xyz", sub {
        my ($val, $err) = @_;
        ok(!defined $val, "get miss: undef value");
        ok(!defined $err, "get miss: undef error");
        EV::break;
    });
    run_with_timeout();
}

# --- GETS (with flags and CAS) ---
{
    my $key = "${prefix}gets_test";
    $mc->set($key, "test_value", 0, 42, sub {
        my ($res, $err) = @_;
        ok(!$err, "set with flags: no error");

        $mc->gets($key, sub {
            my ($result, $err) = @_;
            ok(!$err, "gets: no error");
            is(ref $result, 'HASH', "gets: returns hashref");
            is($result->{value}, "test_value", "gets: correct value");
            is($result->{flags}, 42, "gets: correct flags");
            ok($result->{cas}, "gets: has cas value");
            EV::break;
        });
    });
    run_with_timeout();
}

# --- ADD ---
{
    my $key = "${prefix}add_test";
    $mc->delete($key, sub {
        $mc->add($key, "added", sub {
            my ($res, $err) = @_;
            ok(!$err, "add: first add succeeds");

            $mc->add($key, "again", sub {
                my ($res, $err) = @_;
                ok($err, "add: second add fails with error: $err");
                EV::break;
            });
        });
    });
    run_with_timeout();
}

# --- REPLACE ---
{
    my $key = "${prefix}replace_test";
    $mc->set($key, "original", sub {
        $mc->replace($key, "replaced", sub {
            my ($res, $err) = @_;
            ok(!$err, "replace: succeeds when key exists");

            $mc->get($key, sub {
                my ($val, $err) = @_;
                is($val, "replaced", "replace: value updated");
                EV::break;
            });
        });
    });
    run_with_timeout();
}

# --- DELETE ---
{
    my $key = "${prefix}delete_test";
    $mc->set($key, "to_delete", sub {
        $mc->delete($key, sub {
            my ($res, $err) = @_;
            ok(!$err, "delete: no error");

            $mc->get($key, sub {
                my ($val, $err) = @_;
                ok(!defined $val, "delete: key gone");
                EV::break;
            });
        });
    });
    run_with_timeout();
}

# --- INCR / DECR ---
{
    my $key = "${prefix}counter";
    $mc->set($key, "10", sub {
        $mc->incr($key, 5, sub {
            my ($val, $err) = @_;
            ok(!$err, "incr: no error");
            is($val, 15, "incr: 10 + 5 = 15");

            $mc->decr($key, 3, sub {
                my ($val, $err) = @_;
                ok(!$err, "decr: no error");
                is($val, 12, "decr: 15 - 3 = 12");
                EV::break;
            });
        });
    });
    run_with_timeout();
}

# --- INCR auto-create with $initial and $expiry (20-byte extras) ---
{
    my $key = "${prefix}incr_auto_$$";  # ensure non-existent
    $mc->incr($key, 1, 42, 60, sub {
        my ($val, $err) = @_;
        ok(!$err, "incr auto-create: no error");
        is($val, 42, "incr auto-create: returns initial value");

        $mc->incr($key, 8, sub {
            my ($val, $err) = @_;
            is($val, 50, "incr auto-create: subsequent incr 42 + 8 = 50");
            EV::break;
        });
    });
    run_with_timeout();
}

# --- DECR clamps at 0 (never negative) ---
{
    my $key = "${prefix}decr_clamp";
    $mc->set($key, "3", sub {
        $mc->decr($key, 10, sub {
            my ($val, $err) = @_;
            ok(!$err, "decr clamp: no error");
            is($val, 0, "decr clamp: 3 - 10 clamped to 0 (unsigned read)");
            EV::break;
        });
    });
    run_with_timeout();
}

# --- APPEND / PREPEND ---
{
    my $key = "${prefix}appendtest";
    $mc->set($key, "hello", sub {
        $mc->append($key, " world", sub {
            my ($res, $err) = @_;
            ok(!$err, "append: no error");

            $mc->get($key, sub {
                my ($val, $err) = @_;
                is($val, "hello world", "append: correct result");

                $mc->prepend($key, "say ", sub {
                    my ($res, $err) = @_;
                    ok(!$err, "prepend: no error");

                    $mc->get($key, sub {
                        my ($val, $err) = @_;
                        is($val, "say hello world", "prepend: correct result");
                        EV::break;
                    });
                });
            });
        });
    });
    run_with_timeout();
}

# --- MULTI-GET ---
{
    my @keys = map { "${prefix}mget_$_" } 1..5;
    my $remaining = scalar @keys;

    # Set some keys (1, 3, 5)
    for my $i (0, 2, 4) {
        $mc->set($keys[$i], "value_" . ($i+1), sub {
            $remaining--;
            if ($remaining == 0) {
                # Now mget all 5
                $mc->mget(\@keys, sub {
                    my ($results, $err) = @_;
                    ok(!$err, "mget: no error");
                    is(ref $results, 'HASH', "mget: returns hashref");
                    is($results->{$keys[0]}, "value_1", "mget: key 1 found");
                    ok(!exists $results->{$keys[1]}, "mget: key 2 miss");
                    is($results->{$keys[2]}, "value_3", "mget: key 3 found");
                    ok(!exists $results->{$keys[3]}, "mget: key 4 miss");
                    is($results->{$keys[4]}, "value_5", "mget: key 5 found");
                    EV::break;
                });
            }
        });
    }
    # Fire-and-forget delete for keys 2,4
    $mc->delete($keys[1]);
    $mc->delete($keys[3]);
    $remaining -= 2;
    run_with_timeout();
}

# --- STATS ---
{
    $mc->stats(sub {
        my ($stats, $err) = @_;
        ok(!$err, "stats: no error");
        is(ref $stats, 'HASH', "stats: returns hashref");
        ok(exists $stats->{pid}, "stats: has pid");
        ok(exists $stats->{version}, "stats: has version");
        EV::break;
    });
    run_with_timeout();
}

# --- STATS with named group (argument-parsing path) ---
{
    $mc->stats("settings", sub {
        my ($stats, $err) = @_;
        ok(!$err, "stats(name): no error");
        is(ref $stats, 'HASH', "stats(name): returns hashref");
        ok(exists $stats->{maxbytes}, "stats(name): settings group has maxbytes");
        EV::break;
    });
    run_with_timeout();
}

# --- APPEND/PREPEND on non-existent key returns NOT_STORED ---
{
    my $key = "${prefix}missing_appendpath";  # nonexistent
    $mc->append($key, "data", sub {
        my ($res, $err) = @_;
        ok($err, "append on missing key: error returned");
        like($err, qr/NOT_STORED/, "append on missing key: NOT_STORED error");
        $mc->prepend($key, "x", sub {
            my ($res, $err) = @_;
            ok($err, "prepend on missing key: error returned");
            like($err, qr/NOT_STORED/, "prepend on missing key: NOT_STORED error");
            EV::break;
        });
    });
    run_with_timeout();
}

# --- NOOP ---
{
    $mc->noop(sub {
        my ($res, $err) = @_;
        ok(!$err, "noop: no error");
        ok($res, "noop: success");
        EV::break;
    });
    run_with_timeout();
}

# --- Fire-and-forget ---
{
    my $key = "${prefix}ff_test";
    $mc->set($key, "fire_and_forget");  # no callback
    $mc->noop(sub {
        # noop as fence to ensure set completed
        $mc->get($key, sub {
            my ($val, $err) = @_;
            is($val, "fire_and_forget", "fire-and-forget set worked");
            EV::break;
        });
    });
    run_with_timeout();
}

# --- Pipelining ---
{
    my $key = "${prefix}pipeline";
    my @results;

    $mc->set($key, "0");
    for my $i (1..10) {
        $mc->incr($key, 1, sub {
            my ($val, $err) = @_;
            push @results, $val;
            if (@results == 10) {
                is_deeply(\@results, [1..10], "pipeline: 10 increments pipelined correctly");
                EV::break;
            }
        });
    }
    run_with_timeout();
}

# --- FLUSH with delay encodes 4-byte extras ---
# Note: an immediate flush is issued right after to cancel the pending
# delay (flush() with no extras supersedes the schedule). Otherwise the
# delayed flush would wipe data in subsequent test files.
{
    $mc->flush(1, sub {
        my ($res, $err) = @_;
        ok(!$err, "flush(delay): no error");
        ok($res, "flush(delay): success");
        $mc->flush(sub { EV::break });
    });
    run_with_timeout();
}

# Cleanup
$mc->disconnect;

done_testing;
