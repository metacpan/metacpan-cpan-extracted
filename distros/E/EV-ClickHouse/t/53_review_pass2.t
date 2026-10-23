#!/usr/bin/env perl
# Regression tests for the pre-release adversarial review pass. Each case
# below pins one fixed defect; tests that need no real server use a forked
# fake listener so they run anywhere, the rest skip unless ClickHouse is up.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use IO::Select;
use IO::Compress::Gzip qw(gzip);
use Time::Local qw(timegm);
use EV;
use EV::ClickHouse;

my $host  = $ENV{TEST_CLICKHOUSE_HOST}        || '127.0.0.1';
my $hport = $ENV{TEST_CLICKHOUSE_PORT}        || 8123;
my $nport = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

my $nat_ok  = !!IO::Socket::INET->new(PeerAddr => $host, PeerPort => $nport, Timeout => 2);
my $http_ok = !!IO::Socket::INET->new(PeerAddr => $host, PeerPort => $hport, Timeout => 2);

plan tests => 45;

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

# ---------------------------------------------------------------------
# A. connect_timeout covers a stalled handshake on an immediately-connected
# (localhost) socket. The ret==0 path used to arm no timer at all. Ticks
# red pre-fix only where localhost connects complete synchronously.
# ---------------------------------------------------------------------
{
    my $lsn   = listen_on_127001();
    my $pport = $lsn->sockport;
    my $pid = fork_child(sub {
        my $c = $lsn->accept or exit 0;
        sleep 30;
    });

    my ($err, $bailed);
    my $ch; $ch = EV::ClickHouse->new(
        host => '127.0.0.1', port => $pport, protocol => 'native',
        connect_timeout => 0.5,
        on_connect => sub { $err = 'unexpected connect'; EV::break },
        on_error   => sub { $err = $_[0]; EV::break },
    );
    run_guarded(5, \$bailed);
    reap_child($pid);

    ok(!$bailed && ($err // '') =~ /connect timeout/,
       'immediate-connect ServerHello stall trips connect_timeout')
        or diag("err: " . (defined $err ? $err : '(undef)') . " bailed: $bailed");
    ok(!$ch->is_connected, 'stillborn connection is not marked connected');
    $ch->finish;
}

# ---------------------------------------------------------------------
# B. A peer that stalls every handshake must trip reconnect_max_attempts
# instead of spinning forever (attempts used to reset on TCP accept).
# Needs test A's timer on sync-connect platforms to fail pre-fix there.
# ---------------------------------------------------------------------
{
    my $lsn   = listen_on_127001();
    my $pport = $lsn->sockport;
    my $pid = fork_child(sub {
        $SIG{PIPE} = 'IGNORE';
        while (my $c = $lsn->accept) { sleep 30 }
    });

    my (@errors, $connects, $bailed);
    my $ch; $ch = EV::ClickHouse->new(
        host => '127.0.0.1', port => $pport, protocol => 'native',
        connect_timeout => 0.3, auto_reconnect => 1,
        reconnect_delay => 0.05, reconnect_max_attempts => 3,
        on_connect => sub { $connects++ },
        on_error   => sub {
            push @errors, $_[0];
            EV::break if $_[0] =~ /max reconnect attempts/;
        },
    );
    run_guarded(10, \$bailed);
    reap_child($pid);

    ok(!$bailed && grep(/max reconnect attempts exceeded/, @errors),
       'handshake-stall loop gives up after max attempts')
        or diag("errors: @errors bailed: $bailed");
    is($connects // 0, 0, 'never spuriously connected to the stalled peer');
    $ch->finish;
}

# ---------------------------------------------------------------------
# C. finish() during reconnect backoff must not leave a zombie timer that
# reconnects afterwards.
# ---------------------------------------------------------------------
{
    my (@errors, $connects, $bailed, $settle, $finished);
    my $ch; $ch = EV::ClickHouse->new(
        host => '127.0.0.1', port => 1, protocol => 'native',
        auto_reconnect => 1, reconnect_delay => 0.3,
        on_connect => sub { $connects++ },
        on_error   => sub {
            push @errors, $_[0];
            # Finish as soon as the first refusal lands (backoff armed),
            # then watch for a zombie retry inside the settle window.
            # $ch may still be undef when the refusal is synchronous.
            return if $finished || !defined $ch;
            $finished = 1;
            $ch->finish;
            $settle = EV::timer(1.2, 0, sub { EV::break });
        },
    );
    # Synchronous refusal: the error (and backoff) already landed inside
    # new(), before $ch was assigned, so finish here instead.
    if (@errors && !$finished) {
        $finished = 1;
        $ch->finish;
        $settle = EV::timer(1.2, 0, sub { EV::break });
    }
    run_guarded(5, \$bailed);

    ok(!$bailed && @errors == 1, 'no zombie reconnect attempt after finish')
        or diag("errors: @errors connects: " . ($connects // 0));
}

# ---------------------------------------------------------------------
# D. A registered drain waiter fires when the query fails (timeout), not
# just on success.
# ---------------------------------------------------------------------
SKIP: {
    skip "ClickHouse native not reachable", 2 unless $nat_ok;
    my ($qerr, $drained, $bailed);
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub {
            $ch->query("select sleep(3)", { query_timeout => 0.3 }, sub {
                (undef, $qerr) = @_;
            });
            $ch->drain(sub { $drained = 1; EV::break });
        },
        on_error => sub { EV::break },
    );
    run_guarded(8, \$bailed);

    ok(!$bailed && defined $qerr, 'timed-out query delivered its error');
    ok(!$bailed && $drained, 'drain waiter released on query failure');
    $ch->finish;
}

# ---------------------------------------------------------------------
# E. reset() from inside another reset's cancel_pending: the inner reset
# wins exactly once (no redundant second connect tearing it down). The
# redundant attempt is only observable with synchronous connects.
# ---------------------------------------------------------------------
SKIP: {
    skip "ClickHouse HTTP not reachable", 2 unless $http_ok;
    my ($connects, $rows, $bailed);
    my ($reset_done, $settle);
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $hport, protocol => 'http',
        on_connect => sub {
            $connects++;
            return if $connects > 1;
            $ch->query("select sleep(2) format TabSeparated", sub {
                return if $reset_done++;
                $ch->reset;
            });
            $ch->query("select 1 format TabSeparated", sub { });
            $ch->reset;
            $settle = EV::timer(1.5, 0, sub {
                $ch->query("select 7 format TabSeparated",
                           sub { ($rows) = @_; EV::break });
            });
        },
        on_error => sub { },
    );
    run_guarded(10, \$bailed);

    ok(!$bailed && ($connects // 0) == 2, 'nested reset connected exactly once more')
        or diag("connects: " . ($connects // 0));
    ok(!$bailed && $rows && @$rows && $rows->[0][0] == 7,
       'connection usable after nested reset');
    $ch->finish;
}

# ---------------------------------------------------------------------
# F. A second overlapping drain() croaks instead of silently dropping the
# first waiter.
# ---------------------------------------------------------------------
SKIP: {
    skip "ClickHouse native not reachable", 2 unless $nat_ok;
    my ($croak, $first_fired, $bailed);
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub {
            $ch->query("select sleep(5)", sub { });
            $ch->drain(sub { $first_fired = 1; EV::break });
            eval { $ch->drain(sub { }) };
            $croak = $@;
            $ch->cancel;
        },
        on_error => sub { EV::break },
    );
    run_guarded(8, \$bailed);

    like($croak // '', qr/drain already pending/, 'overlapping drain croaks');
    ok(!$bailed && $first_fired, 'first drain waiter survived and fired');
    $ch->finish;
}

# ---------------------------------------------------------------------
# G. An unknown mid-stream packet tears the connection down (resync is
# impossible) and auto_reconnect re-establishes it.
# ---------------------------------------------------------------------
{
    my $lsn   = listen_on_127001();
    my $pport = $lsn->sockport;
    my $pid = fork_child(sub {
        $SIG{PIPE} = 'IGNORE';
        my $c1 = $lsn->accept or exit 0;
        drain_idle($c1, 0.5);
        syswrite $c1, server_hello(54492);
        drain_idle($c1, 1.0);
        syswrite $c1, "\x63";
        # Hold conn #1 open (no EOF: that would trigger an unrelated
        # slow-path reconnect and mask the fix) while serving the
        # expected reconnect on the listener.
        my $sel = IO::Select->new($lsn);
        if ($sel->can_read(10)) {
            my $c2 = $lsn->accept or exit 0;
            drain_idle($c2, 0.5);
            syswrite $c2, server_hello(54492);
            sleep 3;
        }
        exit 0;
    });

    my (@errors, $connects, $bailed);
    my $ch; $ch = EV::ClickHouse->new(
        host => '127.0.0.1', port => $pport, protocol => 'native',
        auto_reconnect => 1, reconnect_delay => 0.05,
        on_connect => sub {
            $connects++;
            if ($connects == 1) {
                $ch->query("select 1", sub { });
            } else {
                EV::break;
            }
        },
        on_error => sub { push @errors, $_[0] },
    );
    run_guarded(8, \$bailed);
    reap_child($pid);

    ok(!$bailed && grep(/unknown server packet type: 99/, @errors),
       'corrupt mid-stream packet reported via on_error')
        or diag("errors: @errors");
    is($connects // 0, 2, 'auto_reconnect re-established after teardown');
    $ch->finish;
}

# ---------------------------------------------------------------------
# H. An HTTP keepalive ping carries a deadline: a peer that swallows it
# must not wedge the connection forever.
# ---------------------------------------------------------------------
{
    my $lsn   = listen_on_127001();
    my $pport = $lsn->sockport;
    my $pid = fork_child(sub {
        $SIG{PIPE} = 'IGNORE';
        while (my $c = $lsn->accept) {
            my $req = '';
            while ($req !~ /\r\n\r\n/) {
                my $b;
                my $n = sysread($c, $b, 4096);
                last unless $n;
                $req .= $b;
            }
            if ($req =~ m{^GET /ping}mi) {
                sleep 5;
            } else {
                syswrite $c, "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\n1\n";
            }
            close $c;
        }
        exit 0;
    });

    my ($connects, $t);
    my $ch; $ch = EV::ClickHouse->new(
        host => '127.0.0.1', port => $pport, protocol => 'http',
        keepalive => 0.3, auto_reconnect => 1, reconnect_delay => 0.05,
        on_connect => sub { $connects++ },
        on_error   => sub { },
    );
    $t = EV::timer(2.5, 0, sub { EV::break });
    EV::run;
    undef $t;
    reap_child($pid);

    cmp_ok($connects // 0, '>=', 2, 'swallowed keepalive ping timed out and recovered');
    $ch->finish;
}

# ---------------------------------------------------------------------
# I. With compress=1 the client pins network_compression_method=LZ4 on the
# wire unless the user set it, so ZSTD-default servers stay readable.
# ---------------------------------------------------------------------
SKIP: {
    skip "ClickHouse native not reachable", 3 unless $nat_ok;

    # Probe: does this build decode LZ4, and does the server honour a
    # per-query compression method override? An LZ4 build must loudly
    # reject ZSTD data; anything else means the pin test can't run here.
    my ($probe_err, $bailed);
    my $pch; $pch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native', compress => 1,
        on_connect => sub {
            $pch->query("select 1", { network_compression_method => 'ZSTD' },
                        sub { (undef, $probe_err) = @_; EV::break });
        },
        on_error => sub { $probe_err //= $_[0]; EV::break },
    );
    run_guarded(10, \$bailed);
    $pch->finish;
    my $have_lz4 = !$bailed && ($probe_err // '') =~ /unsupported compression/;
    ok(!$bailed && (!$probe_err || $have_lz4), 'zstd probe behaved sanely')
        or diag("probe err: " . (defined $probe_err ? $probe_err : '(undef)'));

    SKIP: {
        skip "no LZ4 decode (or server ignored the method override)", 2
            unless $have_lz4;

        pipe(my $pr, my $pw) or die "pipe: $!";
        my $lsn   = listen_on_127001();
        my $pport = $lsn->sockport;
        my $pid = fork_child(sub {
            close $pr;
            $SIG{PIPE} = 'IGNORE';
            my $c = $lsn->accept or exit 0;
            drain_idle($c, 0.5);
            syswrite $c, server_hello(54492);
            my $query = drain_idle($c, 1.0);
            print $pw ($query =~ /network_compression_method/ && $query =~ /LZ4/
                        ? "PIN\n" : "NOPIN\n");
            close $pw;
            syswrite $c, "\x05";
            sleep 2;
            exit 0;
        });
        close $pw;

        my ($rows, $err, $bailed2);
        my $ch; $ch = EV::ClickHouse->new(
            host => '127.0.0.1', port => $pport, protocol => 'native',
            compress => 1,
            on_connect => sub {
                $ch->query("select 1", sub { ($rows, $err) = @_; EV::break });
            },
            on_error => sub { $err //= $_[0]; EV::break },
        );
        run_guarded(8, \$bailed2);
        my $pin = <$pr>;
        close $pr;
        reap_child($pid);

        is($pin // '', "PIN\n", 'query carried the LZ4 method pin');
        # No Data packets preceded EndOfStream, so rows is undef — the
        # established shape for a dataless result (cf. zero-row SELECT).
        ok(!$bailed2 && !$err && !defined $rows,
           'query completed against the fake server');
        $ch->finish;
    }
}

# ---------------------------------------------------------------------
# J. Transfer-Encoding is a list: "gzip, chunked" must de-chunk AND gunzip.
# ---------------------------------------------------------------------
{
    my $body = "1\thello\n2\tworld\n";
    my $gz;
    gzip(\$body => \$gz) or die "gzip failed";
    my $half = int(length($gz) / 2);
    my ($c1, $c2) = (substr($gz, 0, $half), substr($gz, $half));

    my $lsn   = listen_on_127001();
    my $pport = $lsn->sockport;
    my $pid = fork_child(sub {
        $SIG{PIPE} = 'IGNORE';
        my $c = $lsn->accept or exit 0;
        drain_idle($c, 0.5);
        syswrite $c, "HTTP/1.1 200 OK\r\nTransfer-Encoding: gzip, chunked\r\n\r\n"
            . sprintf("%X\r\n", length $c1) . $c1 . "\r\n"
            . sprintf("%X\r\n", length $c2) . $c2 . "\r\n"
            . "0\r\n\r\n";
        sleep 2;
        exit 0;
    });

    my ($rows, $err, $bailed);
    my $ch; $ch = EV::ClickHouse->new(
        host => '127.0.0.1', port => $pport, protocol => 'http',
        on_connect => sub {
            $ch->query("select 1", sub { ($rows, $err) = @_; EV::break });
        },
        on_error => sub { $err //= $_[0]; EV::break },
    );
    run_guarded(8, \$bailed);
    reap_child($pid);

    ok(!$bailed && !$err, 'gzip+chunked response decoded without error')
        or diag("err: " . (defined $err ? $err : '(undef)'));
    is(ref $rows eq 'ARRAY' ? scalar @$rows : -1, 2, 'both rows present');
    ok(!$bailed && $rows && @$rows == 2
        && $rows->[0][0] == 1 && $rows->[0][1] eq 'hello'
        && $rows->[1][0] == 2 && $rows->[1][1] eq 'world',
       'row values intact through de-chunk + gunzip');
    $ch->finish;
}

# ---------------------------------------------------------------------
# K. A TLS handshake that dies at the TCP level records a SYSCALL
# diagnostic in last_tls_error instead of leaving it stale.
# ---------------------------------------------------------------------
SKIP: {
    my $tls_ok = eval {
        my $probe = EV::ClickHouse->new(
            host => '127.0.0.1', port => 1, protocol => 'http',
            tls => 1, on_error => sub { });
        1;
    };
    skip "built without OpenSSL", 2 unless $tls_ok;

    my $lsn   = listen_on_127001();
    my $pport = $lsn->sockport;
    my $pid = fork_child(sub {
        require Socket;
        my $c = $lsn->accept or exit 0;
        # Wait for the ClientHello so connect() always succeeds and the
        # abort deterministically lands mid-handshake (an early RST can
        # otherwise fail the connect itself, racing the test).
        my $b = '';
        sysread($c, $b, 4096);
        # RST instead of FIN: a TCP-level abort with no queued alert.
        setsockopt($c, Socket::SOL_SOCKET(), Socket::SO_LINGER(),
                   pack('ii', 1, 0));
        close $c;
        exit 0;
    });

    my ($err, $bailed);
    my $ch; $ch = EV::ClickHouse->new(
        host => '127.0.0.1', port => $pport, protocol => 'http',
        tls => 1, tls_skip_verify => 1,
        on_connect => sub { $err = 'unexpected connect'; EV::break },
        on_error   => sub { $err = $_[0]; EV::break },
    );
    run_guarded(8, \$bailed);
    my $tls_err = $ch->last_tls_error;
    reap_child($pid);

    ok(!$bailed && ($err // '') =~ /SSL_connect failed|SSL handshake failed/,
       'aborted handshake reported')
        or diag("err: " . (defined $err ? $err : '(undef)'));
    like($tls_err // '', qr/SYSCALL|eof|reset|closed/i,
         'last_tls_error carries a TCP-level diagnostic, not stale text')
        or diag("last_tls_error: " . (defined $tls_err ? $tls_err : '(undef)'));
    $ch->finish;
}

# ---------------------------------------------------------------------
# L. Invalid Date/DateTime strings fail the INSERT loudly instead of
# landing as wrapped-around dates; valid edge dates still round-trip.
# ---------------------------------------------------------------------
SKIP: {
    skip "ClickHouse native not reachable", 9 unless $nat_ok;
    my $tbl = "ev_ch_dt53_$$";
    my $bailed;
    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native',
        on_connect => sub {
            $ch->query(
                "create table $tbl (d Date, dt DateTime, d32 Date32,"
              . " dt64 DateTime64(3)) engine=Memory",
                sub {
                    my (undef, $e) = @_;
                    if ($e) { fail("setup: $e"); EV::break; return; }
                    my @steps = (
                        ['month 13',
                         ['2024-13-01', '2024-01-01 00:00:00',
                          '2024-01-01', '2024-01-01 00:00:00.000']],
                        ['feb 29 on a non-leap year',
                         ['2023-02-29', '2024-01-01 00:00:00',
                          '2024-01-01', '2024-01-01 00:00:00.000']],
                        ['hour 25',
                         ['2024-01-01', '2024-01-01 25:00:00',
                          '2024-01-01', '2024-01-01 00:00:00.000']],
                        ['Date year out of uint16 range',
                         ['2200-01-01', '2024-01-01 00:00:00',
                          '2024-01-01', '2024-01-01 00:00:00.000']],
                        ['DateTime64 fractional garbage',
                         ['2024-01-01', '2024-01-01 00:00:00',
                          '2024-01-01', '2024-01-01 00:00:00.1x']],
                    );
                    my $run;
                    $run = sub {
                        my $s = shift @steps;
                        if ($s) {
                            $ch->insert($tbl, [$s->[1]], sub {
                                my (undef, $e4) = @_;
                                like($e4 // '', qr/encoding failed/,
                                     "$s->[0] rejected loudly");
                                $run->();
                            });
                            return;
                        }
                        return $ch->query(
                            "select count() from $tbl",
                            sub {
                                my ($r) = @_;
                                is($r && $r->[0][0], 0,
                                   'rejected batches inserted nothing');
                                $ch->insert($tbl, [[
                                    '2024-02-29', '2024-02-29 12:00:00',
                                    '2024-02-29', '2024-02-29 12:00:00.123',
                                ]], sub {
                                    my (undef, $e2) = @_;
                                    ok(!$e2, 'valid leap-day row accepted')
                                        or diag("err: $e2");
                                    $ch->insert($tbl, [[
                                        '2023-05-05', '2024-01-01 00:00:00',
                                        '1960-01-01', '1960-06-15 12:00:00.500',
                                    ]], sub {
                                        my (undef, $e3) = @_;
                                        if ($e3) {
                                            fail("pre-1970 dt64 rejected: $e3");
                                            fail('readback skipped');
                                            return $ch->query(
                                                "drop table $tbl",
                                                sub { EV::break });
                                        }
                                        $ch->query(
                                            "select d, dt, d32, dt64 from $tbl order by d",
                                            sub {
                                                my ($rows) = @_;
                                                my $d_exp = timegm(0, 0, 0, 29, 1, 2024) / 86400;
                                                my $t_exp = timegm(0, 0, 12, 29, 1, 2024);
                                                my $r1 = $rows && @$rows == 2 && $rows->[1];
                                                ok($r1 && $r1->[0] == $d_exp
                                                    && $r1->[1] == $t_exp
                                                    && $r1->[2] == $d_exp
                                                    && $r1->[3] == $t_exp * 1000 + 123,
                                                   'leap-day row round-tripped exactly');
                                                my $neg = $rows && @$rows == 2 && $rows->[0];
                                                my $n_exp = timegm(0, 0, 12, 15, 5, 1960);
                                                ok($neg && $neg->[3] == $n_exp * 1000 + 500
                                                    && $neg->[2] == timegm(0, 0, 0, 1, 0, 1960) / 86400,
                                                   'pre-1970 DateTime64/Date32 round-tripped');
                                                $ch->query("drop table $tbl",
                                                           sub { EV::break });
                                            });
                                    });
                                });
                            });
                    };
                    $run->();
                });
        },
        on_error => sub { EV::break },
    );
    run_guarded(30, \$bailed);
    diag("date validation sequence bailed mid-run") if $bailed;
    $ch->finish if $ch->is_connected;
}

# ---------------------------------------------------------------------
# M. A cancelled INSERT answers the sample block with Cancel alone.
# ---------------------------------------------------------------------
{
    pipe(my $pr, my $pw) or die "pipe: $!";
    my $lsn   = listen_on_127001();
    my $pport = $lsn->sockport;
    my $pid = fork_child(sub {
        close $pr;
        $SIG{PIPE} = 'IGNORE';
        my $c = $lsn->accept or exit 0;
        drain_idle($c, 0.5);
        syswrite $c, server_hello(54492);
        drain_idle($c, 1.0);
        syswrite $c, "\x01" . vstr("") . "\x00" . vu(1) . vu(0)
            . vstr("x") . vstr("UInt8") . "\x00";
        my $phase2 = drain_idle($c, 1.0);
        print $pw ($phase2 eq "\x03"
                    ? "CANCELLED\n" : "LOST:" . length($phase2) . "\n");
        close $pw;
        syswrite $c, "\x05";
        sleep 2;
        exit 0;
    });
    close $pw;

    my ($done, $bailed, $cancel_error);
    my $ch; $ch = EV::ClickHouse->new(
        host => '127.0.0.1', port => $pport, protocol => 'native',
        compress => 0,
        on_connect => sub {
            $ch->insert("fake_table", [[7]], sub {
                $cancel_error = $_[1]; $done = 1; EV::break;
            });
            # Dispatch happens after on_connect returns; cancel once the
            # INSERT is in flight, long before the sample block arrives.
            my $t; $t = EV::timer(0.01, 0, sub { undef $t; $ch->cancel });
        },
        on_error => sub { EV::break },
    );
    run_guarded(8, \$bailed);
    my $verdict = <$pr>;
    close $pr;
    reap_child($pid);

    ok(!$bailed && $done && ($cancel_error // '') =~ /cancel/i,
       'insert callback reports cancellation');
    is($verdict // '', "CANCELLED\n",
       'CLIENT_CANCEL replaces the data block')
        or diag("verdict: " . (defined $verdict ? $verdict : '(undef)'));
    $ch->finish;
}

# ---------------------------------------------------------------------
# N. A multi-frame compressed result survives tiny fragmented reads: no
# split (not even a <26-byte frame-header stub) may read as corruption.
# ---------------------------------------------------------------------
SKIP: {
    skip "ClickHouse native not reachable", 3 unless $nat_ok;
    my $ROWS = 40_000;

    my $lsn   = listen_on_127001();
    my $pport = $lsn->sockport;
    my $pid = fork_child(sub {
        $SIG{PIPE} = 'IGNORE';
        my $client = $lsn->accept or exit 0;
        my $up = IO::Socket::INET->new(
            PeerAddr => $host, PeerPort => $nport, Timeout => 5) or exit 0;
        my $sel = IO::Select->new($client, $up);
        OUTER: while (my @ready = $sel->can_read(10)) {
            for my $fh (@ready) {
                my $buf;
                my $n = sysread($fh, $buf, 65536);
                last OUTER unless defined $n && $n > 0;
                if ($fh == $client) {
                    syswrite($up, $buf);
                } else {
                    while (length $buf) {
                        my $piece = substr($buf, 0, 179, '');
                        syswrite($client, $piece) or last OUTER;
                    }
                }
            }
        }
        exit 0;
    });

    my ($rows, $err, $bailed);
    my $ch; $ch = EV::ClickHouse->new(
        host => '127.0.0.1', port => $pport, protocol => 'native',
        compress => 1, query_timeout => 120,
        on_connect => sub {
            $ch->query(
                "SELECT number, repeat('x', 64) AS pad FROM numbers($ROWS)",
                { max_block_size => 4096 },
                sub { ($rows, $err) = @_; EV::break });
        },
        on_error => sub { $err //= $_[1] // 'connection error'; EV::break },
    );
    run_guarded(120, \$bailed);
    reap_child($pid);

    ok(!$bailed && !$err, 'fragmented multi-frame stream decoded without error')
        or diag("err: " . (defined $err ? $err : '(undef)'));
    is(ref $rows eq 'ARRAY' ? scalar @$rows : -1, $ROWS,
       "all $ROWS rows present");
    my $ok = $rows && @$rows == $ROWS ? 1 : 0;
    if ($ok) {
        for my $i (0, int($ROWS / 2), $ROWS - 1) {
            my $r = $rows->[$i];
            unless (ref $r eq 'ARRAY' && $r->[0] == $i
                    && $r->[1] eq ('x' x 64)) {
                $ok = 0;
                diag("row $i mismatch");
                last;
            }
        }
    }
    ok(!$bailed && $ok, 'row contents intact across split frames');
    $ch->finish;
}

# ---------------------------------------------------------------------
# O. on_* setters reject non-coderefs loudly and keep the old handler;
# loading the module must leave SIGPIPE non-fatal so a reset peer
# surfaces as EPIPE errors instead of killing the process.
# ---------------------------------------------------------------------
{
    require POSIX;
    my $sa = POSIX::SigAction->new;
    POSIX::sigaction(&POSIX::SIGPIPE, undef, $sa);
    isnt($sa->{HANDLER}, 'DEFAULT', 'SIGPIPE is non-fatal after load');
    my $ch = EV::ClickHouse->new(
        host => '127.0.0.1', port => 1, protocol => 'http',
        on_error => sub { });
    eval { $ch->on_error("junk") };
    like($@ // '', qr/CODE reference/, 'non-coderef handler croaks');
    is(ref($ch->on_error), 'CODE', 'old handler preserved after bad set');
    $ch->on_error(undef);
    ok(!defined($ch->on_error), 'undef still clears the handler');
    $ch->finish;
}

# ---------------------------------------------------------------------
# P. _set_failover validates before freeing: a bad call croaks and the
# configured ring still rotates afterwards.
# ---------------------------------------------------------------------
{
    my $lsn   = listen_on_127001();
    my $pport = $lsn->sockport;
    my $pid = fork_child(sub {
        my $c = $lsn->accept or exit 0;
        sleep 30;
    });

    my ($croak, $bailed, @fo);
    my $ch; $ch = EV::ClickHouse->new(
        hosts => ["127.0.0.1:$pport", '127.0.0.1:2'], protocol => 'native',
        connect_timeout => 0.3,
        on_failover => sub { @fo = @_; EV::break },
        on_error    => sub { },
    );
    # The bad call lands while the first host is still mid-handshake, so
    # the later rotation proves the stored ring survived it.
    eval { $ch->_set_failover("junk", 9000) };
    $croak = $@;
    run_guarded(5, \$bailed);
    reap_child($pid);
    like($croak // '', qr/arrayref/, 'bad failover config croaks');
    ok(!$bailed && @fo >= 4 && $fo[2] eq '127.0.0.1' && $fo[3] == 2,
       'preserved ring still rotated to the next host')
        or diag("failover args: @fo");
    is($ch->current_port, 2, 'connection now targets the rotated port');
    $ch->finish;
}

# ---------------------------------------------------------------------
# R. Dual-stack hosts: when the first resolved address refuses, the
# client falls through to the next one instead of failing outright.
# ---------------------------------------------------------------------
SKIP: {
    my $v6first = 0;
    if ($nat_ok) {
        require Socket;
        my ($e, @ai) = Socket::getaddrinfo('localhost', $nport);
        if (!$e && @ai >= 2 && $ai[0]->{family} == Socket::AF_INET6()) {
            if (socket(my $s, Socket::PF_INET6(), Socket::SOCK_STREAM(), 0)) {
                my $addr = Socket::pack_sockaddr_in6(
                    $nport, Socket::inet_pton(Socket::AF_INET6(), "::1"));
                $v6first = 1 unless connect($s, $addr);
                close $s;
            }
        }
    }
    skip "needs localhost resolving ::1-first with v6 refusing", 2
        unless $nat_ok && $v6first;

    my ($rows, $err, $bailed);
    my $ch; $ch = EV::ClickHouse->new(
        host => 'localhost', port => $nport, protocol => 'native',
        on_connect => sub {
            $ch->query("select 1", sub { ($rows, $err) = @_; EV::break });
        },
        on_error => sub { $err //= $_[0]; EV::break },
    );
    run_guarded(10, \$bailed);

    ok(!$bailed && !$err, 'connected via address fallback')
        or diag("err: " . (defined $err ? $err : '(undef)'));
    ok(!$bailed && $rows && @$rows && $rows->[0][0] == 1,
       'query ran on the fallback address');
    $ch->finish;
}
