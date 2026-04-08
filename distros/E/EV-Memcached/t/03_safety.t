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

sub make_mc {
    my %opts = @_;
    my $mc = EV::Memcached->new(
        host     => $host,
        port     => $port,
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

my $prefix = "ev_mc_safety_$$\_";

# --- disconnect from callback (the fixed SEGFAULT path) ---
{
    my $mc = make_mc();
    my $got_value;
    $mc->set("${prefix}dc", "test", sub {
        my ($res, $err) = @_;
        ok(!$err, "set before disconnect-from-cb: no error");

        $mc->get("${prefix}dc", sub {
            my ($val, $err) = @_;
            $got_value = $val;
            $mc->disconnect;
            EV::break;
        });
    });
    run_ev();
    is($got_value, "test", "disconnect from callback: value received before disconnect");
    ok(!$mc->is_connected, "disconnect from callback: disconnected");
}

# --- CAS ---
{
    my $mc = make_mc();
    $mc->set("${prefix}cas", "v1", sub {
        $mc->gets("${prefix}cas", sub {
            my ($result, $err) = @_;
            ok(!$err, "cas: gets no error");
            my $cas = $result->{cas};
            ok($cas, "cas: got cas value");

            # CAS with correct token
            $mc->cas("${prefix}cas", "v2", $cas, sub {
                my ($res, $err) = @_;
                ok(!$err, "cas: correct token succeeds");

                # CAS with stale token
                $mc->cas("${prefix}cas", "v3", $cas, sub {
                    my ($res, $err) = @_;
                    ok($err, "cas: stale token fails: $err");
                    EV::break;
                });
            });
        });
    });
    run_ev();
}

# --- touch ---
{
    my $mc = make_mc();
    $mc->set("${prefix}touch", "data", 300, sub {
        $mc->touch("${prefix}touch", 600, sub {
            my ($res, $err) = @_;
            ok(!$err, "touch: no error");
            ok($res, "touch: success");
            EV::break;
        });
    });
    run_ev();
}

# --- gat ---
{
    my $mc = make_mc();
    $mc->set("${prefix}gat", "gatval", sub {
        $mc->gat("${prefix}gat", 300, sub {
            my ($val, $err) = @_;
            ok(!$err, "gat: no error");
            is($val, "gatval", "gat: correct value");
            EV::break;
        });
    });
    run_ev();
}

# --- gats ---
{
    my $mc = make_mc();
    $mc->set("${prefix}gats", "gatsval", 0, 99, sub {
        $mc->gats("${prefix}gats", 300, sub {
            my ($result, $err) = @_;
            ok(!$err, "gats: no error");
            is($result->{value}, "gatsval", "gats: correct value");
            is($result->{flags}, 99, "gats: correct flags");
            ok($result->{cas}, "gats: has cas");
            EV::break;
        });
    });
    run_ev();
}

# --- flush ---
{
    my $mc = make_mc();
    $mc->set("${prefix}flush_test", "val", sub {
        $mc->flush(sub {
            my ($res, $err) = @_;
            ok(!$err, "flush: no error");

            $mc->get("${prefix}flush_test", sub {
                my ($val, $err) = @_;
                ok(!defined $val, "flush: key gone after flush");
                EV::break;
            });
        });
    });
    run_ev();
}

# --- max_pending flow control ---
{
    my $mc = make_mc(max_pending => 10);
    is($mc->max_pending, 10, "max_pending: set to 10");

    my $done = 0;
    my $max_wait = 0;
    my $total = 100;

    for my $i (1..$total) {
        $mc->set("${prefix}fc_$i", "v", sub {
            my $w = $mc->waiting_count;
            $max_wait = $w if $w > $max_wait;
            if (++$done == $total) {
                EV::break;
            }
        });
    }
    run_ev();
    is($done, $total, "flow control: all $total commands completed");
    ok($mc->waiting_count == 0, "flow control: waiting queue drained");
}

# --- skip_pending ---
{
    my $mc = make_mc(max_pending => 5);
    my @errors;

    for my $i (1..20) {
        $mc->set("${prefix}skip_$i", "v", sub {
            my ($res, $err) = @_;
            push @errors, $err if $err;
        });
    }

    $mc->skip_pending;
    $mc->skip_waiting;

    # All pending/waiting should have been skipped
    is($mc->pending_count, 0, "skip_pending: pending count is 0");
    is($mc->waiting_count, 0, "skip_waiting: waiting count is 0");
    ok(scalar(@errors) > 0, "skip: callbacks received errors");
    is($errors[0], "skipped", "skip: error is 'skipped'");
    $mc->disconnect;
}

# --- mget empty array ---
{
    my $mc = make_mc();
    my ($mget_result, $mget_err);
    $mc->mget([], sub {
        ($mget_result, $mget_err) = @_;
    });
    # mget([]) fires callback synchronously — no EV::run needed
    ok(!$mget_err, "mget empty: no error");
    is(ref $mget_result, 'HASH', "mget empty: returns hashref");
    is(scalar keys %$mget_result, 0, "mget empty: empty hash");
    $mc->disconnect;
}

# --- mget all misses ---
{
    my $mc = make_mc();
    my @keys = map { "${prefix}nomiss_$_" } 1..5;
    # Delete all keys first (fire-and-forget)
    $mc->delete($_) for @keys;
    # Fence to ensure deletes complete, then run mget
    $mc->noop(sub {
        $mc->mget(\@keys, sub {
            my ($results, $err) = @_;
            ok(!$err, "mget all-miss: no error");
            is(scalar keys %$results, 0, "mget all-miss: empty hash");
            $mc->disconnect;
            EV::break;
        });
    });
    run_ev();
}

# --- error: delete non-existent key ---
{
    my $mc = make_mc();
    $mc->delete("${prefix}does_not_exist_xyz", sub {
        my ($res, $err) = @_;
        ok($err, "delete non-existent: returns error");
        like($err, qr/NOT_FOUND/, "delete non-existent: NOT_FOUND error");
        EV::break;
    });
    run_ev();
    $mc->disconnect;
}

# --- error: replace non-existent key ---
{
    my $mc = make_mc();
    $mc->delete("${prefix}no_replace", sub {});
    $mc->replace("${prefix}no_replace", "val", sub {
        my ($res, $err) = @_;
        ok($err, "replace non-existent: returns error");
        like($err, qr/NOT_FOUND|NOT_STORED/, "replace non-existent: error message");
        EV::break;
    });
    run_ev();
    $mc->disconnect;
}

# --- error: incr on non-numeric value ---
{
    my $mc = make_mc();
    $mc->set("${prefix}nonnumeric", "hello", sub {
        $mc->incr("${prefix}nonnumeric", 1, sub {
            my ($val, $err) = @_;
            ok($err, "incr non-numeric: returns error");
            EV::break;
        });
    });
    run_ev();
    $mc->disconnect;
}

done_testing;
