#!/usr/bin/env perl
# Regression tests for the second pre-release adversarial review pass.
# Fake-server cases use fake-server cases use forked
# listeners (run anywhere), the rest skip unless ClickHouse is up.
# The JSON-blessed-value case runs LAST: pre-fix it kills the process.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use IO::Select;
use EV;
use EV::ClickHouse;

my $host  = $ENV{TEST_CLICKHOUSE_HOST}        || '127.0.0.1';
my $hport = $ENV{TEST_CLICKHOUSE_PORT}        || 8123;
my $nport = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

my $nat_ok  = !!IO::Socket::INET->new(PeerAddr => $host, PeerPort => $nport, Timeout => 2);
my $http_ok = !!IO::Socket::INET->new(PeerAddr => $host, PeerPort => $hport, Timeout => 2);


my @kids;
END { kill 'TERM', @kids if @kids; waitpid $_, 0 for @kids; }

sub listen_on_127001 {
    IO::Socket::INET->new(Listen => 5, LocalAddr => '127.0.0.1',
                           LocalPort => 0, ReuseAddr => 1) or die "listen: $!";
}

sub fork_child {
    my ($code) = @_;
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (!$pid) { $code->(); exit 0; }
    push @kids, $pid;
    return $pid;
}

sub reap_child {
    my ($pid) = @_;
    kill 'TERM', $pid;
    waitpid $pid, 0;
    @kids = grep { $_ != $pid } @kids;
}

sub run_guarded {
    my ($secs, $flag) = @_;
    my $b = EV::timer($secs, 0, sub { $$flag = 1; EV::break });
    EV::run;
    undef $b;
}

sub drain_idle {
    my ($fh, $idle) = @_;
    my $sel = IO::Select->new($fh);
    my $out = '';
    while ($sel->can_read($idle)) {
        my $b;
        my $n = sysread($fh, $b, 65536);
        last unless $n;
        $out .= $b;
    }
    return $out;
}

sub vu {
    my ($v) = @_;
    my $o = '';
    do {
        my $b = $v & 0x7f;
        $v >>= 7;
        $o .= chr($b | ($v ? 0x80 : 0));
    } while ($v);
    return $o;
}

sub vstr { my ($s) = @_; vu(length $s) . $s }

sub server_hello {
    my ($rev) = @_;
    my $h = "\x00" . vstr("fake") . vu(1) . vu(1) . vu($rev);
    $h .= vstr("UTC")  if $rev >= 54423;
    $h .= vstr("fake") if $rev >= 54372;
    $h .= vu(0)        if $rev >= 54401;
    return $h;
}

sub server_exception {
    my ($code, $name, $msg) = @_;
    "\x02" . pack('l<', $code) . vstr($name) . vstr($msg) . vstr('') . "\x00";
}

sub sample_block_1x_u32 {
    # SERVER_DATA, empty table, block info, 1 col, 0 rows,
    # ("n", "UInt32"), custom=0.
    "\x01" . vstr("") . "\x00" . vu(1) . vu(0) . vstr("n") . vstr("UInt32") . "\x00";
}

# ---------------------------------------------------------------------
# B. reset() from an error callback, followed immediately by a query
# from the same callback, must dispatch the query (it used to strand
# on the live connection: enqueued at depth > 0, never advanced).
# ---------------------------------------------------------------------
SKIP: {
    skip 'ClickHouse HTTP not reachable', 1 unless $http_ok;
    # The strand needs the inner reset to complete synchronously (an
    # async connect is rescued by finish_connect's advance), which is
    # timing-dependent under load — repeat rounds so a quiet machine
    # trips it pre-fix, and any machine passes post-fix.
    my $rounds_ok = 0;
    for my $round (1..6) {
        my ($rows, $err, $started, $kick, $round_bailed);
        my $ch; $ch = EV::ClickHouse->new(
            host => $host, port => $hport, protocol => 'http',
            on_connect => sub {
                return if $started++;
                $ch->query("select sleep(2) format TabSeparated", sub {
                    my (undef, $e) = @_;
                    $ch->reset;
                    $ch->query("select 1 format TabSeparated",
                               { query_id => 'b-stranded' },
                               sub { ($rows, $err) = @_; EV::break });
                });
                $kick = EV::timer(0.2, 0, sub { $ch->reset });
            },
            on_error => sub { $err //= $_[0]; },
        );
        run_guarded(3, \$round_bailed);
        $ch->finish if $ch->is_connected;
        last if $round_bailed || $err || !$rows || $rows->[0][0] != 1;
        $rounds_ok++;
    }
    is($rounds_ok, 6, 'query issued after reset-from-callback completes (6 rounds)');
}

# ---------------------------------------------------------------------
# C. A cancel() raced with an INSERT that the server rejects with an
# Exception (instead of a sample block) must not poison the NEXT
# insert with a spurious CLIENT_CANCEL.
# ---------------------------------------------------------------------
SKIP: {
    skip 'ClickHouse native not reachable', 3 unless $nat_ok;
    my $tbl = "ev_ch54_meta_$$";
    my ($err1, $err2, $back, $bailed, $kick);
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub {
            $ch->query("create table if not exists $tbl (n UInt32) engine=Memory", sub {
                # From a timer (depth 0) insert #1 dispatches
                # synchronously; the server reply needs a loop turn, so
                # the cancel() on the next line always lands in META.
                $kick = EV::timer(0.05, 0, sub {
                    $ch->insert("ev_ch54_no_such_table_$$", [[1]], sub {
                        (undef, $err1) = @_;
                        $ch->insert($tbl, [[7]], sub {
                            (undef, $err2) = @_;
                            return EV::break if $err2;
                            $ch->query("select n from $tbl", sub {
                                my ($r) = @_;
                                $back = $r && $r->[0][0];
                                $ch->query("drop table if exists $tbl", sub { EV::break });
                            });
                        });
                    });
                    $ch->cancel;
                });
            });
        },
        on_error => sub { EV::break },
    );
    run_guarded(10, \$bailed);
    like(($err1 // ''), qr/does not exist|unknown table/i, 'rejected INSERT errors with the server text')
        or diag("err1: " . ($err1 // '(undef)'));
    is($err2, undef, 'following INSERT is not spuriously cancelled')
        or diag("err2: " . ($err2 // '(undef)'));
    is($back, 7, 'following INSERT landed its row');
    $ch->finish if $ch->is_connected;
}

# ---------------------------------------------------------------------
# C2. Wire-level pin for the same defect (needs no real server): after
# a cancel() raced with a server-rejected INSERT, the NEXT insert's
# data block must not carry a trailing CLIENT_CANCEL byte.
# ---------------------------------------------------------------------
{
    # Result travels over a pipe, not the exit code: EV::run reaps
    # forked children, so waitpid reports ECHILD afterwards.
    my ($rd, $wr);
    pipe($rd, $wr) or die "pipe: $!";
    my $lsn   = listen_on_127001();
    my $pport = $lsn->sockport;
    my $pid = fork_child(sub {
        close $rd;
        my $say = sub { syswrite $wr, chr($_[0]); exit $_[0]; };
        my $c = $lsn->accept or $say->(3);
        drain_idle($c, 0.5);                       # ClientHello
        syswrite $c, server_hello(54492);
        my $q1 = drain_idle($c, 1.0);              # INSERT #1
        $say->(3) unless length $q1;
        syswrite $c, server_exception(60, 'DB::Exception',
            'Table nope_aaa does not exist');
        my $q2 = drain_idle($c, 1.0);              # INSERT #2
        $say->(3) unless length $q2;
        syswrite $c, sample_block_1x_u32();
        my $data = drain_idle($c, 1.5);            # data block
        $say->(1) unless length $data;
        $say->(substr($data, -1) eq "\x03" ? 7 : 0); # CLIENT_CANCEL == 3
    });
    close $wr;

    my ($err1, $kick);
    my $ch; $ch = EV::ClickHouse->new(
        host => '127.0.0.1', port => $pport, protocol => 'native',
        on_connect => sub {
            $kick = EV::timer(0.05, 0, sub {
                $ch->insert('nope_aaa', [[1]], sub {
                    (undef, $err1) = @_;
                    $ch->insert('tbl_bbb', [[7]], sub { });
                });
                $ch->cancel;
            });
        },
        on_error => sub { },
    );
    my $t = EV::timer(6, 0, sub { EV::break });
    EV::run;
    my $code = 9;
    if (IO::Select->new($rd)->can_read(8)) {
        my $b = '';
        sysread($rd, $b, 1);
        $code = length $b ? ord($b) : 9;
    }
    close $rd;
    reap_child($pid);
    like(($err1 // ''), qr/does not exist/, 'fake server rejects INSERT #1')
        or diag("err1: " . ($err1 // '(undef)'));
    is($code, 0, 'no trailing CLIENT_CANCEL after INSERT #2 data')
        or diag($code == 7 ? 'SPURIOUS CANCEL byte present'
              : $code == 1 ? 'client sent no data block'
              : $code == 3 ? 'script desync (query missing)'
              : $code == 9 ? 'child timed out'
              : "child exit $code");
    $ch->finish;
}

# ---------------------------------------------------------------------
# D. cancel() with an in-flight query, where the error callback resets
# and on_connect issues a fresh query, must not deliver the stale
# teardown error to the live query (phantom error) or desync send_count.
# ---------------------------------------------------------------------
SKIP: {
    skip 'ClickHouse HTTP not reachable', 1 unless $http_ok;
    # The phantom needs the inner reset to connect synchronously (an
    # async connect fires on_connect after the outer drain, so nothing
    # is eaten) — repeat rounds; see block B.
    my $rounds_ok = 0;
    for my $round (1..6) {
        my ($started, $kick, $round_bailed);
        my ($q3_n, $q3_err, $q3_rows, $q4_ok);
        my $ch; $ch = EV::ClickHouse->new(
            host => $host, port => $hport, protocol => 'http',
            on_connect => sub {
                if (!$started++) {
                    $ch->query("select sleep(2) format TabSeparated", sub {
                        $ch->reset;
                    });
                    $kick = EV::timer(0.2, 0, sub { $ch->cancel });
                } else {
                    $ch->query("select 1 format TabSeparated", sub {
                        my ($r, $e) = @_;
                        $q3_n++; $q3_err = $e; $q3_rows = $r;
                        $ch->query("select 2 format TabSeparated", sub {
                            my ($r2, $e2) = @_;
                            $q4_ok = !$e2 && $r2 && $r2->[0][0] == 2;
                            EV::break;
                        });
                    });
                }
            },
            on_error => sub { },
        );
        run_guarded(3, \$round_bailed);
        $ch->finish if $ch->is_connected;
        last if $round_bailed || ($q3_n // 0) != 1 || $q3_err
             || !$q3_rows || $q3_rows->[0][0] != 1 || !$q4_ok;
        $rounds_ok++;
    }
    is($rounds_ok, 6, 'no phantom error after reset-during-cancel (6 rounds)');
}

# ---------------------------------------------------------------------
# S. skip_pending() with an in-flight query, where the error callback
# resets and re-issues, must not tear down the revived connection or
# fail the re-issued query with the stale skip error.
# ---------------------------------------------------------------------
SKIP: {
    skip 'ClickHouse HTTP not reachable', 2 unless $http_ok;
    my ($err, $rows, $bailed, $started, $kick);
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $hport, protocol => 'http',
        on_connect => sub {
            return if $started++;
            $ch->query("select sleep(2) format TabSeparated", sub {
                $ch->reset;
                $ch->query("select 1 format TabSeparated", sub {
                    ($rows, $err) = @_; EV::break;
                });
            });
            $kick = EV::timer(0.2, 0, sub { $ch->skip_pending });
        },
        on_error => sub { },
    );
    run_guarded(5, \$bailed);
    ok(!$bailed && !$err && $rows && $rows->[0][0] == 1,
       're-issued query survives skip_pending + reset')
        or diag("bailed: $bailed err: " . ($err // '(undef)'));
    ok($ch->is_connected, 'revived connection not torn down');
    $ch->finish if $ch->is_connected;
}

# ---------------------------------------------------------------------
# F. drain() on an idle connection fires immediately; a query issued
# from that handler must be dispatched (it used to strand until the
# next event — forever with keepalive off).
# ---------------------------------------------------------------------
SKIP: {
    skip 'ClickHouse HTTP not reachable', 2 unless $http_ok;
    my ($drained, $rows, $err, $bailed, $kick);
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $hport, protocol => 'http',
        on_connect => sub {
            # From a timer (depth 0): drain() fires its handler at
            # depth > 0, so the handler's query is enqueued
            # undispatched — calling drain from on_connect itself
            # would be rescued by finish_connect's advance instead.
            $kick = EV::timer(0.05, 0, sub {
                $ch->drain(sub {
                    $drained = 1;
                    $ch->query("select 1 format TabSeparated",
                               sub { ($rows, $err) = @_; EV::break });
                });
            });
        },
        on_error => sub { $err //= $_[0]; EV::break },
    );
    run_guarded(5, \$bailed);
    ok($drained, 'immediate drain fired on idle connection');
    ok(!$bailed && !$err && $rows && $rows->[0][0] == 1,
       'query from the drain handler completes')
        or diag("bailed: $bailed err: " . ($err // '(undef)'));
    $ch->finish if $ch->is_connected;
}

# ---------------------------------------------------------------------
# G. With auto_reconnect, the connection must come back after an
# oversize response tears it down (it used to stay down forever).
# ---------------------------------------------------------------------
SKIP: {
    skip 'ClickHouse HTTP not reachable', 3 unless $http_ok;
    my ($connects, $conn_err, $small_ok, $bailed);
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $hport, protocol => 'http',
        max_recv_buffer => 1000,
        auto_reconnect  => 1,
        on_connect => sub {
            if (!$connects++) {
                $ch->query("select number from numbers(100000) format TabSeparated",
                           sub { });
            } else {
                $ch->query("select 1 format TabSeparated", sub {
                    my ($r, $e) = @_;
                    $small_ok = !$e && $r && $r->[0][0] == 1;
                    EV::break;
                });
            }
        },
        on_error => sub { $conn_err //= $_[0] },
    );
    run_guarded(10, \$bailed);
    like(($conn_err // ''), qr/max_recv_buffer/,
        'oversize response trips the cap teardown')
        or diag("conn_err: " . ($conn_err // '(undef)'));
    is($connects, 2, 'reconnected after the oversize teardown');
    ok(!$bailed && $small_ok, 'fresh query works on the revived link');
    $ch->finish if $ch->is_connected;
}

# ---------------------------------------------------------------------
# H. A manual reset() from on_disconnect must suppress the pending
# auto-reconnect: otherwise the zombie schedule burns an attempt,
# inflating backoff or tripping reconnect_max_attempts on a live link.
# ---------------------------------------------------------------------
{
    # The zombie increment survives only when the inner reset connects
    # synchronously (an async finish_connect wipes it) — repeat rounds
    # so a quiet machine trips it pre-fix; see block B.
    my $rounds_ok = 0;
    for my $round (1..6) {
        my $lsn   = listen_on_127001();
        my $pport = $lsn->sockport;
        my $pid = fork_child(sub {
            # Drain before every close: shutting down with the
            # client's query bytes unread would RST instead of FIN,
            # taking a different (unscheduled-teardown) path.
            my $c1 = $lsn->accept or exit 0;
            drain_idle($c1, 0.3);
            close $c1;                   # EOF #1 (client resets manually)
            my $c2 = $lsn->accept or exit 0;
            drain_idle($c2, 0.3);
            sleep 1;
            close $c2;                   # EOF #2 (auto-reconnect must fire)
            my $c3 = $lsn->accept or exit 0;
            drain_idle($c3, 8.0);        # held past the parent timer
        });

        # Every connection carries an in-flight query: an idle link
        # arms no read watcher, so only in-flight EOFs are prompt.
        my ($connects, $discs, $reset_done, @errs, $round_bailed);
        my $ch; $ch = EV::ClickHouse->new(
            host => '127.0.0.1', port => $pport, protocol => 'http',
            auto_reconnect => 1,
            reconnect_delay => 0.05,
            reconnect_max_attempts => 1,
            on_connect    => sub {
                $connects++;
                if ($connects == 3) { EV::break; return; }
                $ch->query("select 1 format TabSeparated", sub { });
            },
            on_disconnect => sub { $discs++; $ch->reset unless $reset_done++ },
            on_error      => sub { push @errs, $_[0] },
        );
        my $t = EV::timer(5, 0, sub { $round_bailed = 1; EV::break });
        EV::run;
        reap_child($pid);
        $ch->finish;
        if ($round_bailed || ($connects // 0) != 3
            || grep(/max reconnect attempts/, @errs)) {
            diag("round $round: connects=" . ($connects // 0)
               . " disconnects=" . ($discs // 0) . " errors: @errs");
            last;
        }
        $rounds_ok++;
    }
    is($rounds_ok, 6, 'auto-reconnect survives manual reset (6 rounds)');
}

# ---------------------------------------------------------------------
# I. cancel() from on_query_start must cancel the dispatch (it used to
# be a silent no-op: send_count isn't bumped yet at that point).
# ---------------------------------------------------------------------
SKIP: {
    skip 'ClickHouse native not reachable', 2 unless $nat_ok;
    my ($err, $follow_ok, $bailed, $cancelled);
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_query_start => sub { $ch->cancel unless $cancelled++ },
        on_connect => sub {
            $ch->query("select sleep(2)", sub {
                (undef, $err) = @_;
                $ch->query("select 1", sub {
                    my ($r, $e) = @_;
                    $follow_ok = !$e && $r && $r->[0][0] == 1;
                    EV::break;
                });
            });
        },
        on_error => sub { },
    );
    run_guarded(6, \$bailed);
    like(($err // ''), qr/query cancelled/, 'native dispatch cancelled from on_query_start')
        or diag("bailed: $bailed err: " . ($err // '(undef)'));
    ok(!$bailed && $follow_ok, 'native connection usable after dispatch cancel');
    $ch->finish if $ch->is_connected;
}
SKIP: {
    skip 'ClickHouse HTTP not reachable', 2 unless $http_ok;
    my ($err, $follow_ok, $bailed, $cancelled, $connects);
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $hport, protocol => 'http',
        auto_reconnect => 1,
        on_query_start => sub { $ch->cancel unless $cancelled++ },
        on_connect => sub {
            if (!$connects++) {
                $ch->query("select sleep(1) format TabSeparated", sub {
                    (undef, $err) = @_;
                });
            } else {
                $ch->query("select 1 format TabSeparated", sub {
                    my ($r, $e) = @_;
                    $follow_ok = !$e && $r && $r->[0][0] == 1;
                    EV::break;
                });
            }
        },
        on_error => sub { },
    );
    run_guarded(6, \$bailed);
    like(($err // ''), qr/cancelled/, 'HTTP dispatch cancelled from on_query_start')
        or diag("bailed: $bailed err: " . ($err // '(undef)'));
    ok(!$bailed && $follow_ok, 'HTTP connection usable after dispatch cancel');
    $ch->finish if $ch->is_connected;
}

# ---------------------------------------------------------------------
# I3. Wire-level pin (needs no real server): a native query cancelled
# from on_query_start must send NOTHING — and a query queued behind it
# must still dispatch (the advance loop must not strand it).
# ---------------------------------------------------------------------
{
    my ($rd, $wr);
    pipe($rd, $wr) or die "pipe: $!";
    my $lsn   = listen_on_127001();
    my $pport = $lsn->sockport;
    my $pid = fork_child(sub {
        close $rd;
        my $say = sub { syswrite $wr, chr($_[0]); exit $_[0]; };
        my $c = $lsn->accept or $say->(3);
        drain_idle($c, 0.5);                       # ClientHello
        syswrite $c, server_hello(54492);
        my $got = drain_idle($c, 1.5);              # Q1 suppressed, Q2 sent
        $say->(1) unless length $got;
        $say->(6) if $got =~ /marker_aaa_111/;
        $say->($got =~ /marker_bbb_222/ ? 0 : 5);
    });
    close $wr;

    my ($err1, $bailed, $cancelled);
    my $ch; $ch = EV::ClickHouse->new(
        host => '127.0.0.1', port => $pport, protocol => 'native',
        on_query_start => sub { $ch->cancel unless $cancelled++ },
        on_connect => sub {
            $ch->query("select 111 as marker_aaa_111", { query_id => 'q-one' },
                       sub { (undef, $err1) = @_; });
            $ch->query("select 222 as marker_bbb_222", { query_id => 'q-two' },
                       sub { });
        },
        on_error => sub { },
    );
    my $t = EV::timer(4, 0, sub { EV::break });
    EV::run;
    my $code = 9;
    if (IO::Select->new($rd)->can_read(8)) {
        my $b = '';
        sysread($rd, $b, 1);
        $code = length $b ? ord($b) : 9;
    }
    close $rd;
    reap_child($pid);
    like(($err1 // ''), qr/query cancelled/, 'cancelled dispatch errors its callback')
        or diag("err1: " . ($err1 // '(undef)'));
    is($code, 0, 'cancelled query sent nothing; queued query dispatched')
        or diag($code == 5 ? 'Q2 bytes never arrived (advance loop stranded it)'
              : $code == 6 ? 'Q1 bytes leaked onto the wire'
              : $code == 1 ? 'client sent nothing at all'
              : $code == 9 ? 'child timed out'
              : "child exit $code");
    $ch->finish;
}

# ---------------------------------------------------------------------
# J. Never-dispatched cancelled queries report zero duration.
# ---------------------------------------------------------------------

SKIP: {
    skip 'ClickHouse HTTP not reachable', 2 unless $http_ok;
    # Fires arrive in cancel order (queued c2, c3 first, in-flight c1
    # last); key by position, not query_id — a never-dispatched entry
    # reports the last dispatched id, not its own.
    my (@durs, $bailed, $kick, $fires);
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $hport, protocol => 'http',
        on_query_complete => sub {
            my (undef, undef, undef, undef, $dur) = @_;
            push @durs, $dur;
            EV::break if ++$fires == 3;
        },
        on_connect => sub {
            $ch->query("select sleep(0.5) format TabSeparated",
                       { query_id => 'c1' }, sub { });
            $ch->query("select 1 format TabSeparated",
                       { query_id => 'c2' }, sub { });
            $ch->query("select 2 format TabSeparated",
                       { query_id => 'c3' }, sub { });
            $kick = EV::timer(0.3, 0, sub { $ch->cancel });
        },
        on_error => sub { },
    );
    run_guarded(5, \$bailed);
    ok(!$bailed && @durs == 3 && $durs[0] == 0 && $durs[1] == 0,
       'never-dispatched cancelled queries report 0')
        or diag("durs: @durs");
    ok(!$bailed && @durs == 3 && $durs[2] > 0.2,
       'cancelled in-flight query keeps its duration')
        or diag("durs: @durs");
    $ch->finish if $ch && $ch->is_connected;
}

# ---------------------------------------------------------------------
# M. UUID text rendering is byte-identical after the snprintf -> nibble
# table change (pins the fast path's output).
# ---------------------------------------------------------------------
SKIP: {
    skip 'ClickHouse native not reachable', 1 unless $nat_ok;
    my ($rows, $err, $bailed);
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub {
            $ch->query("select toUUID('123e4567-e89b-12d3-a456-426614174000')", sub {
                ($rows, $err) = @_; EV::break;
            });
        },
        on_error => sub { $err //= $_[0]; EV::break },
    );
    run_guarded(5, \$bailed);
    is($rows && $rows->[0][0], '123e4567-e89b-12d3-a456-426614174000',
       'UUID renders byte-identical')
        or diag("err: " . ($err // '(undef)'));
    $ch->finish if $ch->is_connected;
}

# ---------------------------------------------------------------------
# L. LAST: a blessed (non-Boolean) hashref inside a JSON column value
# must error the INSERT, not croak from the I/O path and kill the
# process. Pre-fix this aborts the whole file.
# ---------------------------------------------------------------------
SKIP: {
    skip 'ClickHouse native not reachable', 2 unless $nat_ok;
    my $json_ok = 0;
    {
        my $pch;
        $pch = EV::ClickHouse->new(
            host => $host, port => $nport, protocol => 'native',
            on_connect => sub {
                $pch->query("create temporary table _ch54_json_probe (j JSON) ENGINE = Memory",
                    { allow_experimental_json_type => 1 },
                    sub { my (undef, $e) = @_; $json_ok = !$e; EV::break });
            },
            on_error => sub { EV::break },
        );
        my $t = EV::timer(5, 0, sub { EV::break });
        EV::run;
        $pch->finish if $pch->is_connected;
    }
    skip 'JSON column type not available on this server', 2 unless $json_ok;

    my ($err, $follow_ok, $bailed);
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        settings => { allow_experimental_json_type => 1 },
        on_connect => sub {
            $ch->query("create temporary table _ch54_json (j JSON) ENGINE = Memory", sub {
                $ch->insert('_ch54_json', [[{ a => bless({}, 'EvCh54Bogus') }]], sub {
                    (undef, $err) = @_;
                    $ch->query("select 1", sub {
                        my ($r, $e) = @_;
                        $follow_ok = !$e && $r && $r->[0][0] == 1;
                        EV::break;
                    });
                });
            });
        },
        on_error => sub { },
    );
    run_guarded(5, \$bailed);
    like(($err // ''), qr/encoding failed/,
        'blessed JSON leaf errors the INSERT instead of dying')
        or diag("err: " . ($err // '(undef)') . " bailed: $bailed");
    ok(!$bailed && $follow_ok, 'connection usable after bad JSON value');
    $ch->finish if $ch->is_connected;
}

done_testing;
