#!/usr/bin/env perl
# Callback-reentrancy matrix. Every connection-level callback is exercised
# while the handler performs a destructive operation on the same
# connection — finish(), reset(), cancel(), or dropping the last $ch
# reference (DESTROY). The C layer must never touch freed/torn-down
# state afterwards. Each subtest passes simply by *not crashing*: control
# reaching the bail timer and the assertion proves the process survived.
#
# This consolidates the ad-hoc reentrancy cases from t/37 and guards the
# class of use-after-free bugs found during pre-release review (a Perl
# callback firing from C, the handler tearing the connection down, and
# C code continuing with stale pointers).
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::ClickHouse;

my $host  = $ENV{TEST_CLICKHOUSE_HOST}        || '127.0.0.1';
my $hport = $ENV{TEST_CLICKHOUSE_PORT}        || 8123;
my $nport = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

plan skip_all => "ClickHouse native not reachable"
    unless IO::Socket::INET->new(PeerAddr => $host, PeerPort => $nport, Timeout => 2);
my $http_ok = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $hport, Timeout => 2)
              ? 1 : 0;

# Drive the loop with a hard bail timer so a missed EV::break (or a
# handler that tore down the connection so the normal cb never fires)
# can't hang the test.
sub spin {
    my ($secs) = @_;
    my $t = EV::timer($secs, 0, sub { EV::break });
    EV::run;
    undef $t;
}

# run_case: build a native connection, install callback $name => $handler,
# kick it via $trigger (called from on_connect, or immediately for
# on_connect itself), then assert survival.
sub run_case {
    my (%a) = @_;
    {
        my $ch;
        my %args = (
            host     => $host,
            port     => $a{protocol} && $a{protocol} eq 'http' ? $hport : $nport,
            protocol => $a{protocol} || 'native',
            on_error => sub { },
        );
        # The handler is wrapped so it always gets $ch by closure; the
        # outer my $ch is the only strong ref, so `undef $ch` inside a
        # handler genuinely drops the last reference -> DESTROY.
        $args{ $a{cb} } = sub { $a{handler}->($ch, @_) };
        if ($a{cb} ne 'on_connect') {
            $args{on_connect} = sub { $a{trigger}->($ch) };
        }
        $ch = EV::ClickHouse->new(%args);
        $a{trigger}->($ch) if $a{cb} eq 'on_connect' && $a{trigger};
    }
    spin($a{spin} || 3);
    ok 1, $a{desc};
}

# A query that stays in flight long enough to still be running when we
# cancel / tear down from a callback.
my $SLOW = "select sleep(1)";

plan tests => 22;

# --- on_connect x { finish, reset, undef } -------------------------------
run_case(
    cb => 'on_connect', desc => 'on_connect -> finish()',
    handler => sub { $_[0]->finish },
);
run_case(
    cb => 'on_connect', desc => 'on_connect -> reset()',
    handler => sub { my $ch = shift; $ch->reset; $ch->finish },
);

# on_connect dropping the last ref needs the undef to hit the *outer*
# lexical; do that explicitly.
{
    {
        my $ch;
        $ch = EV::ClickHouse->new(
            host => $host, port => $nport, protocol => 'native',
            on_connect => sub { undef $ch },
            on_error   => sub { },
        );
    }
    spin(3);
    ok 1, 'on_connect -> undef $ch really drops last ref';
}

# --- on_query_start x { finish, cancel, undef } --------------------------
run_case(
    cb => 'on_query_start', desc => 'on_query_start -> finish()',
    handler => sub { $_[0]->finish },
    trigger => sub { $_[0]->query($SLOW, sub { }) },
);
run_case(
    cb => 'on_query_start', desc => 'on_query_start -> cancel()',
    handler => sub { $_[0]->cancel },
    trigger => sub { $_[0]->query($SLOW, sub { }) },
);
{
    {
        my $ch;
        $ch = EV::ClickHouse->new(
            host => $host, port => $nport, protocol => 'native',
            on_query_start => sub { undef $ch },
            on_connect => sub { $ch->query($SLOW, sub { }) },
            on_error   => sub { },
        );
    }
    spin(3);
    ok 1, 'on_query_start -> undef $ch (DESTROY)';
}

# on_query_start -> finish() with a query_timeout set: pipeline_advance
# must bail on the now-disconnected struct rather than re-arming the
# query-timeout timer, which would fire a spurious on_error later.
{
    my $late_err;
    {
        my $ch;
        $ch = EV::ClickHouse->new(
            host => $host, port => $nport, protocol => 'native',
            on_query_start => sub { $ch->finish },
            on_connect => sub {
                $ch->query("select sleep(2)", { query_timeout => 0.3 },
                           sub { });
            },
            on_error => sub { $late_err = $_[0] },
        );
        # Outlast query_timeout (0.3s) so a stray timer would have fired.
        spin(2);
    }
    ok !$late_err, 'on_query_start -> finish() arms no stray query-timeout'
        or diag "spurious on_error: $late_err";
}

# --- on_query_complete x { finish, reset } -------------------------------
run_case(
    cb => 'on_query_complete', desc => 'on_query_complete -> finish()',
    handler => sub { $_[0]->finish },
    trigger => sub { $_[0]->query("select 1", sub { }) },
);
run_case(
    cb => 'on_query_complete', desc => 'on_query_complete -> reset()',
    handler => sub { $_[0]->reset },
    trigger => sub { $_[0]->query("select 1", sub { }) },
    spin => 3,
);

# --- the per-query callback itself x { finish, reset, cancel } -----------
run_case(
    cb => 'on_error', desc => 'query cb -> finish() (via error path)',
    handler => sub { },
    trigger => sub {
        my $ch = shift;
        $ch->query("select * from no_such_table_$$", sub {
            my (undef, $err) = @_;
            $ch->finish if $err;
        });
    },
);
{
    {
        my $ch;
        $ch = EV::ClickHouse->new(
            host => $host, port => $nport, protocol => 'native',
            on_connect => sub {
                $ch->query("select 1", sub { $ch->reset });
            },
            on_error => sub { },
        );
        spin(3);
    }
    ok 1, 'query cb -> reset()';
}
{
    {
        my $ch;
        $ch = EV::ClickHouse->new(
            host => $host, port => $nport, protocol => 'native',
            on_connect => sub {
                $ch->query("select 1", sub { undef $ch });
            },
            on_error => sub { },
        );
    }
    spin(3);
    ok 1, 'query cb -> undef $ch (DESTROY)';
}

# --- on_data x { cancel, finish, undef } --------------------------------
# on_data is a per-query setting, not a constructor callback, so these
# install the handler via the query's {on_data => ...} option.
for my $c (
    [ 'on_data -> cancel()', sub { $_[0]->cancel } ],
    [ 'on_data -> finish()', sub { $_[0]->finish } ],
) {
    my ($desc, $op) = @$c;
    my $ch;
    $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub {
            $ch->query("select number from numbers(500000)",
                       { on_data => sub { $op->($ch) } }, sub { });
        },
        on_error => sub { },
    );
    spin(3);
    ok 1, $desc;
}
{
    {
        my $ch;
        $ch = EV::ClickHouse->new(
            host => $host, port => $nport, protocol => 'native',
            on_connect => sub {
                $ch->query("select number from numbers(500000)",
                           { on_data => sub { undef $ch } }, sub { });
            },
            on_error => sub { },
        );
    }
    spin(3);
    ok 1, 'on_data -> undef $ch (DESTROY)';
}

# --- on_progress x { finish, undef } ------------------------------------
run_case(
    cb => 'on_progress', desc => 'on_progress -> finish()',
    handler => sub { $_[0]->finish },
    trigger => sub { $_[0]->query("select sum(number) from numbers(200000000)", sub { }) },
    spin => 4,
);

# --- on_log x { finish, undef } -----------------------------------------
run_case(
    cb => 'on_log', desc => 'on_log -> finish()',
    handler => sub { $_[0]->finish },
    trigger => sub {
        $_[0]->query("select sleep(0.01)", { send_logs_level => 'trace' }, sub { });
    },
    spin => 3,
);

# --- on_trace x { finish, reset } ---------------------------------------
run_case(
    cb => 'on_trace', desc => 'on_trace -> finish()',
    handler => sub { my ($ch, $msg) = @_; $ch->finish if $msg =~ /dispatch/ },
    trigger => sub { $_[0]->query("select 1", sub { }) },
);
run_case(
    cb => 'on_trace', desc => 'on_trace -> reset()',
    handler => sub { my ($ch, $msg) = @_; $ch->reset if $msg =~ /dispatch/ },
    trigger => sub { $_[0]->query("select 1", sub { }) },
    spin => 3,
);

# --- on_disconnect x { undef } ------------------------------------------
{
    {
        my $ch;
        $ch = EV::ClickHouse->new(
            host => $host, port => $nport, protocol => 'native',
            on_disconnect => sub { undef $ch },
            on_connect => sub {
                $ch->query("select sleep(3)", { query_timeout => 0.5 }, sub { });
            },
            on_error => sub { },
        );
    }
    spin(3);
    ok 1, 'on_disconnect -> undef $ch (DESTROY)';
}

# --- drain callback x { undef } -----------------------------------------
{
    {
        my $ch;
        $ch = EV::ClickHouse->new(
            host => $host, port => $nport, protocol => 'native',
            on_connect => sub {
                $ch->query("select 1", sub { });
                $ch->drain(sub { my $r = $ch->server_revision; undef $ch });
            },
            on_error => sub { },
        );
    }
    spin(3);
    ok 1, 'drain cb -> undef $ch (DESTROY)';
}

# --- HTTP path: on_query_complete -> cancel ------------------------------
SKIP: {
    skip "ClickHouse HTTP not reachable", 1 unless $http_ok;
    run_case(
        protocol => 'http',
        cb => 'on_query_complete', desc => 'HTTP on_query_complete -> finish()',
        handler => sub { $_[0]->finish },
        trigger => sub {
            $_[0]->query("select 1 format TabSeparated", { raw => 1 }, sub { });
        },
    );
}
