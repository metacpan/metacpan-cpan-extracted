#!/usr/bin/env perl
# Regression tests for the third pre-release adversarial review pass:
# silent native-encoder corruption (Decimal/Int/Bool/DateTime64/Enum),
# named_rows helpers, the TLS stall, queue preservation across teardown,
# on_trace reentrancy, the server-revision floor, and Perl API validation
# gaps. The on_trace-reset case runs LAST: pre-fix it segfaults.
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
my $ssl_pid;
my @tmpfiles;
END {
    kill 'TERM', @kids if @kids;
    waitpid $_, 0 for @kids;
    if ($ssl_pid) { kill 'TERM', $ssl_pid; waitpid $ssl_pid, 0; }
    unlink @tmpfiles if @tmpfiles;
}

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

# Run async steps in order; each step receives $next.
sub chain {
    my ($steps, $done) = @_;
    my $i = 0;
    my $next;
    $next = sub {
        return $done->() if $i >= @$steps;
        $steps->[$i++]->($next);
    };
    $next->();
}

# ---------------------------------------------------------------------
# H1: a JSON column split across recvs must wait for more data instead
# of failing the query with "decode_column failed".
# ---------------------------------------------------------------------
{
    my ($json_ok, $probed);
    if ($nat_ok) {
        my $p; $p = EV::ClickHouse->new(
            host => $host, port => $nport, protocol => 'native',
            on_error => sub {},
            on_connect => sub {
                $p->query("create temporary table _ch55_probe (j JSON) ENGINE = Memory",
                    { allow_experimental_json_type => 1 },
                    sub { my (undef, $err) = @_; $json_ok = !$err; EV::break });
            },
        );
        run_guarded(10, \$probed);
        $p->finish;
    }
  SKIP: {
        skip "JSON type or native unavailable", 3
            unless $nat_ok && $json_ok && !$probed;
        my $round = sub {
            my ($compress) = @_;
            my ($rows, $err, $bailed);
            my $table = "_ev_ch55_json_${compress}_$$";
            my $ch; $ch = EV::ClickHouse->new(
                host => $host, port => $nport, protocol => 'native',
                compress => $compress,
                settings => { allow_experimental_json_type => 1 },
                on_error => sub { $err //= $_[0] },
                on_connect => sub {
                    $ch->query("create temporary table $table (j JSON) ENGINE = Memory",
                        sub {
                            my @data = map [ { name => "n$_", v => $_ } ], 1..3000;
                            $ch->insert($table, \@data, sub {
                                my (undef, $ierr) = @_;
                                if ($ierr) { $err = $ierr; EV::break; return; }
                                $ch->query("select j from $table", sub {
                                    ($rows, $err) = @_; EV::break;
                                });
                            });
                        });
                },
            );
            run_guarded(30, \$bailed);
            $ch->finish;
            return ($rows, $err, $bailed);
        };
        {
            my ($rows, $err, $bailed) = $round->(0);
            ok(!$bailed && !$err, "H1 JSON uncompressed: decoded")
                or diag $err // 'bailed';
            is($rows ? scalar(@$rows) : -1, 3000, "H1 JSON uncompressed: all rows");
        }
        {
            my ($rows, $err, $bailed) = $round->(1);
            ok(!$bailed && !$err, "H1 JSON compressed: decoded")
                or diag $err // 'bailed';
        }
    }
}

# ---------------------------------------------------------------------
# M2: Decimal input with trailing garbage or beyond-precision digits
# must fail the batch, not land as a wrapped value.
# ---------------------------------------------------------------------
{
    my (@got, $back, $bailed);
    my $table = "_ev_ch55_dec_$$";
    my $ch;
    if ($nat_ok) {
        $ch = EV::ClickHouse->new(
            host => $host, port => $nport, protocol => 'native',
            on_error => sub {},
            on_connect => sub {
                $ch->query("create temporary table $table (d Decimal(10,2), d5 Decimal(5,2)) ENGINE = Memory",
                    sub {
                        chain([
                            sub { my ($n) = @_; $ch->insert($table, [["12.34abc", "1.00"]], sub { push @got, $_[1]; $n->() }) },
                            sub { my ($n) = @_; $ch->insert($table, [["99999999999999999999.99", "1.00"]], sub { push @got, $_[1]; $n->() }) },
                            sub { my ($n) = @_; $ch->insert($table, [["1.00", "100000"]], sub { push @got, $_[1]; $n->() }) },
                            sub { my ($n) = @_; $ch->insert($table, [["12.34", "1.00"]], sub { push @got, $_[1]; $n->() }) },
                            sub { my ($n) = @_; $ch->insert($table, [["12.349", "1.00"]], sub { push @got, $_[1]; $n->() }) },
                            sub { my ($n) = @_; $ch->insert($table, [["+12.34", "1.00"]], sub { push @got, $_[1]; $n->() }) },
                            sub { my ($n) = @_; $ch->insert($table, [["1.00", "999.99"]], sub { push @got, $_[1]; $n->() }) },
                            sub { my ($n) = @_; $ch->query("select d from $table order by d", sub { ($back) = @_; $n->() }) },
                        ], sub { EV::break });
                    });
            },
        );
        run_guarded(20, \$bailed);
        $ch->finish;
    }
  SKIP: {
        skip "native unavailable", 7 unless $nat_ok;
        like($got[0] // '', qr/encoding/i, "M2 trailing garbage rejected");
        like($got[1] // '', qr/encoding/i, "M2 overflow rejected");
        like($got[2] // '', qr/encoding/i, "M2 precision overflow rejected");
        ok(!$got[3], "M2 valid decimal accepted");
        ok(!$got[4] && !$got[5], "M2 truncation and leading plus accepted");
        is_deeply([sort map { $_->[0] } @{$back // []}], [100, 1234, 1234, 1234],
            "M2 stored values exact");
        ok(!$got[6], "M2 precision boundary accepted");
    }
}

# ---------------------------------------------------------------------
# R4: NV input (1e15) must encode exactly; garbage and out-of-range
# integers must fail instead of truncating/wrapping.
# ---------------------------------------------------------------------
{
    my (@got, $back, $bailed);
    my $table = "_ev_ch55_int_$$";
    my $ch;
    if ($nat_ok) {
        $ch = EV::ClickHouse->new(
            host => $host, port => $nport, protocol => 'native',
            on_error => sub {},
            on_connect => sub {
                $ch->query("create temporary table $table (i Int64, u UInt64, b Int8) ENGINE = Memory",
                    sub {
                        chain([
                            sub { my ($n) = @_; $ch->insert($table,
                                [[1e15, 5, 7], [-1e15, 6, 8], [100.5, 9, 10], [42, 1e15, 11]],
                                sub { push @got, $_[1]; $n->() }) },
                            sub { my ($n) = @_; $ch->query("select i, u, b from $table order by b", sub { ($back) = @_; $n->() }) },
                            sub { my ($n) = @_; $ch->insert($table, [[1e30, 1, 1]], sub { push @got, $_[1]; $n->() }) },
                            sub { my ($n) = @_; $ch->insert($table, [["12abc", 1, 1]], sub { push @got, $_[1]; $n->() }) },
                            sub { my ($n) = @_; $ch->insert($table, [[1, 1, 300]], sub { push @got, $_[1]; $n->() }) },
                        ], sub { EV::break });
                    });
            },
        );
        run_guarded(20, \$bailed);
        $ch->finish;
    }
  SKIP: {
        skip "native unavailable", 8 unless $nat_ok;
        ok(!$got[0], "R4 NV integers accepted") or diag $got[0];
        is($back->[0][0], "1000000000000000", "R4 1e15 stored exactly");
        is($back->[1][0], "-1000000000000000", "R4 -1e15 stored exactly");
        is($back->[2][0], 100, "R4 100.5 truncates like SvIV");
        is($back->[3][1], "1000000000000000", "R4 UInt64 1e15 stored exactly");
        like($got[1] // '', qr/encoding/i, "R4 out-of-range NV rejected");
        like($got[2] // '', qr/encoding/i, "R4 garbage string rejected");
        like($got[3] // '', qr/encoding/i, "R4 out-of-width integer rejected");
    }
}

# ---------------------------------------------------------------------
# R5: undef into a non-nullable column must fail, not land as 0/''.
# ---------------------------------------------------------------------
{
    my (@got, $back, $bailed);
    my $table = "_ev_ch55_null_$$";
    my $ch;
    if ($nat_ok) {
        $ch = EV::ClickHouse->new(
            host => $host, port => $nport, protocol => 'native',
            on_error => sub {},
            on_connect => sub {
                $ch->query("create temporary table $table (i Int32, s String, n Nullable(Int32), g Bool) ENGINE = Memory",
                    sub {
                        chain([
                            sub { my ($n) = @_; $ch->insert($table, [[undef, "a", 1, 1]], sub { push @got, $_[1]; $n->() }) },
                            sub { my ($n) = @_; $ch->insert($table, [[1, undef, 1, 1]], sub { push @got, $_[1]; $n->() }) },
                            sub { my ($n) = @_; $ch->insert($table, [[1, "a", undef, 1]], sub { push @got, $_[1]; $n->() }) },
                            sub { my ($n) = @_; $ch->query("select i, s, n, g from $table", sub { ($back) = @_; $n->() }) },
                            sub { my ($n) = @_; $ch->insert($table, [[1, "a", 1, undef]], sub { push @got, $_[1]; $n->() }) },
                        ], sub { EV::break });
                    });
            },
        );
        run_guarded(20, \$bailed);
        $ch->finish;
    }
  SKIP: {
        skip "native unavailable", 5 unless $nat_ok;
        like($got[0] // '', qr/encoding/i, "R5 undef Int32 rejected");
        like($got[1] // '', qr/encoding/i, "R5 undef String rejected");
        ok(!$got[2], "R5 undef Nullable accepted") or diag $got[2];
        is_deeply($back, [[1, "a", undef, 1]], "R5 null round-trips");
        like($got[3] // '', qr/encoding/i, "R5 undef Bool rejected");
    }
}

# ---------------------------------------------------------------------
# R6: DateTime64 trailing garbage (Zulu/offset designators the client
# cannot interpret) must fail; extra fraction digits still truncate.
# ---------------------------------------------------------------------
{
    my (@got, $back, $bailed);
    my $table = "_ev_ch55_dt64_$$";
    my $ch;
    if ($nat_ok) {
        $ch = EV::ClickHouse->new(
            host => $host, port => $nport, protocol => 'native',
            decode_datetime => 1,
            on_error => sub {},
            on_connect => sub {
                $ch->query("create temporary table $table (t DateTime64(3)) ENGINE = Memory",
                    sub {
                        chain([
                            sub { my ($n) = @_; $ch->insert($table, [["2024-05-01 00:00:00.123Z"]], sub { push @got, $_[1]; $n->() }) },
                            sub { my ($n) = @_; $ch->insert($table, [["2024-05-01 00:00:00+03:00"]], sub { push @got, $_[1]; $n->() }) },
                            sub { my ($n) = @_; $ch->insert($table, [["2024-05-01 00:00:00.1239"], ["2024-05-01 00:00:00.12"]], sub { push @got, $_[1]; $n->() }) },
                            sub { my ($n) = @_; $ch->query("select t from $table order by t", sub { ($back) = @_; $n->() }) },
                        ], sub { EV::break });
                    });
            },
        );
        run_guarded(20, \$bailed);
        $ch->finish;
    }
  SKIP: {
        skip "native unavailable", 4 unless $nat_ok;
        like($got[0] // '', qr/encoding/i, "R6 Zulu suffix rejected");
        like($got[1] // '', qr/encoding/i, "R6 offset suffix rejected");
        ok(!$got[2], "R6 valid datetimes accepted") or diag $got[2];
        is_deeply($back, [["2024-05-01 00:00:00.120"], ["2024-05-01 00:00:00.123"]],
            "R6 fraction truncated/padded like the server");
    }
}

# ---------------------------------------------------------------------
# R7: Bool encodes from Perl truthiness; TSV booleans match the server.
# ---------------------------------------------------------------------
{
    my (@got, $sums, $bailed);
    my $table = "_ev_ch55_bool_$$";
    my $ch;
    if ($nat_ok) {
        $ch = EV::ClickHouse->new(
            host => $host, port => $nport, protocol => 'native',
            on_error => sub {},
            on_connect => sub {
                $ch->query("create temporary table $table (b Bool) ENGINE = Memory",
                    sub {
                        chain([
                            sub { my ($n) = @_; $ch->insert($table, [["true"], ["false"], [0], [1]], sub { push @got, $_[1]; $n->() }) },
                            sub { my ($n) = @_; $ch->query("select sum(b), count() from $table", sub { push @$sums, $_[0]; $n->() }) },
                            sub { my ($n) = @_; $ch->insert($table, "true\nfalse\n", sub { push @got, $_[1]; $n->() }) },
                            sub { my ($n) = @_; $ch->query("select sum(b), count() from $table", sub { push @$sums, $_[0]; $n->() }) },
                            sub { my ($n) = @_; $ch->insert($table, "2\n", sub { push @got, $_[1]; $n->() }) },
                        ], sub { EV::break });
                    });
            },
        );
        run_guarded(20, \$bailed);
        $ch->finish;
    }
  SKIP: {
        skip "native unavailable", 5 unless $nat_ok;
        ok(!$got[0], "R7 truthy strings accepted") or diag $got[0];
        is_deeply($sums->[0], [[3, 4]], "R7 'true'/'false'/0/1 encode by truthiness");
        ok(!$got[1], "R7 TSV booleans accepted") or diag $got[1];
        is_deeply($sums->[1], [[4, 6]], "R7 TSV true/false match the server");
        like($got[2] // '', qr/encoding/i, "R7 TSV '2' rejected");
    }
}

# ---------------------------------------------------------------------
# R8: Enum labels with doubled quotes decode un-doubled.
# ---------------------------------------------------------------------
{
    my ($rows, $err, $bailed);
    my $table = "_ev_ch55_enum_$$";
    my $ch;
    if ($nat_ok) {
        $ch = EV::ClickHouse->new(
            host => $host, port => $nport, protocol => 'native',
            decode_enum => 1,
            on_error => sub {},
            on_connect => sub {
                $ch->query("create temporary table $table (e Enum8('it''s' = 1, 'ok' = 2)) ENGINE = Memory",
                    sub {
                        $ch->insert($table, [[1], [2]], sub {
                            $ch->query("select e from $table order by e", sub {
                                ($rows, $err) = @_; EV::break;
                            });
                        });
                    });
            },
        );
        run_guarded(15, \$bailed);
        $ch->finish;
    }
  SKIP: {
        skip "native unavailable", 2 unless $nat_ok;
        ok(!$err, "R8 enum select: no error") or diag $err;
        is_deeply($rows, [["it's"], ["ok"]], "R8 doubled quote collapsed");
    }
}

# ---------------------------------------------------------------------
# M1: scalar helpers work with named_rows (hashref rows) instead of
# dying on positional indexing inside a swallowed eval.
# ---------------------------------------------------------------------
{
    my ($setting, $count, $size, $mut, $bailed);
    my $table = "_ev_ch55_m1_$$";
    my $ch;
    if ($nat_ok) {
        $ch = EV::ClickHouse->new(
            host => $host, port => $nport, protocol => 'native',
            named_rows => 1,
            on_error => sub {},
            on_connect => sub {
                $ch->query("create temporary table $table (id UInt32) ENGINE = Memory",
                    sub {
                        $ch->insert($table, [[1], [2], [3]], sub {
                            chain([
                                sub { my ($n) = @_; $ch->server_setting("max_threads", sub { ($setting) = @_; $n->() }) },
                                sub { my ($n) = @_; $ch->row_count($table, sub { ($count) = @_; $n->() }) },
                                sub { my ($n) = @_; $ch->table_size($table, sub { ($size) = @_; $n->() }) },
                                sub { my ($n) = @_; $ch->wait_mutation($table, sub { ($mut) = @_; $n->() }) },
                            ], sub { EV::break });
                        });
                    });
            },
        );
        run_guarded(25, \$bailed);
        $ch->finish;
    }
  SKIP: {
        skip "native unavailable", 4 unless $nat_ok;
        ok(defined $setting, "M1 server_setting works with named_rows");
        is($count, 3, "M1 row_count works with named_rows");
        ok(ref $size eq 'HASH' && exists $size->{rows},
            "M1 table_size works with named_rows");
        is_deeply($mut, { pending => 0 }, "M1 wait_mutation works with named_rows");
    }
}

# ---------------------------------------------------------------------
# L1: hedged_query over unconnected members delivers an async error
# instead of throwing synchronously and stranding $pending.
# ---------------------------------------------------------------------
{
    my ($fired, $herr, $sync_died);
    my $pool = EV::ClickHouse::Pool->new(
        size => 2, host => '127.0.0.1', port => 1, protocol => 'native',
        on_error => sub {},
    );
    $_->finish for $pool->conns;
    my $ok = eval {
        $pool->hedged_query('select 1', sub { $fired = 1; (undef, $herr) = @_; });
        1;
    };
    $sync_died = !$ok;
    ok(!$sync_died, "L1 hedged_query does not throw on down members");
    ok($fired && defined $herr, "L1 hedged_query delivers async error");
}

# ---------------------------------------------------------------------
# L2a: finish() from a "connect" trace wins; the outer frame must not
# connect over it.
# ---------------------------------------------------------------------
{
    my ($armed, $did_reset, $bailed, $settle);
    my $ch;
    if ($nat_ok) {
        $ch = EV::ClickHouse->new(
            host => $host, port => $nport, protocol => 'native',
            on_error => sub {},
            on_trace => sub {
                return unless $armed && $_[0] =~ /^connect/;
                $ch->finish;
                $settle = EV::timer(0.5, 0, sub { EV::break });
            },
            on_connect => sub {
                $armed = 1;
                $ch->reset unless $did_reset++;
            },
        );
        run_guarded(6, \$bailed);
        undef $settle;
    }
  SKIP: {
        skip "native unavailable", 1 unless $nat_ok;
        ok(!$ch->is_connected, "L2 connect-trace finish wins");
        $ch->finish if $ch;
    }
}

# ---------------------------------------------------------------------
# L3: a pre-floor server revision fails fast with a clear error instead
# of desyncing; a modern revision connects.
# ---------------------------------------------------------------------
{
    my ($err_old, $connected_new, $bailed);
    {
        my $lsn   = listen_on_127001();
        my $pport = $lsn->sockport;
        my $pid = fork_child(sub {
            my $c = $lsn->accept or exit 0;
            drain_idle($c, 0.5);
            syswrite $c, server_hello(54000);
            sleep 5;
            exit 0;
        });
        my $ch; $ch = EV::ClickHouse->new(
            host => '127.0.0.1', port => $pport, protocol => 'native',
            auto_reconnect => 1,
            on_error => sub { $err_old //= $_[0]; EV::break },
        );
        run_guarded(8, \$bailed);
        $ch->finish;
        reap_child($pid);
    }
    {
        my $lsn   = listen_on_127001();
        my $pport = $lsn->sockport;
        my $pid = fork_child(sub {
            my $c = $lsn->accept or exit 0;
            drain_idle($c, 0.5);
            syswrite $c, server_hello(54492);
            drain_idle($c, 1.0);
            sleep 5;
            exit 0;
        });
        my $ch; $ch = EV::ClickHouse->new(
            host => '127.0.0.1', port => $pport, protocol => 'native',
            on_error => sub { EV::break },
            on_connect => sub { $connected_new = 1; EV::break },
        );
        run_guarded(8, \$bailed);
        $ch->finish;
        reap_child($pid);
    }
    like($err_old // '', qr/too old/i, "L3 old revision fails fast");
    ok(!$bailed, "L3 no hang on either revision");
    ok($connected_new, "L3 modern revision connects");
}

# ---------------------------------------------------------------------
# R2: a query timeout fails only the in-flight query; never-sent
# queued queries survive for the reconnect.
# ---------------------------------------------------------------------
{
    my ($err1, $rows2, $bailed, $done1, $done2, $started);
    my $ch;
    if ($nat_ok) {
        $ch = EV::ClickHouse->new(
            host => $host, port => $nport, protocol => 'native',
            auto_reconnect => 1, reconnect_delay => 0.05,
            on_error => sub {},
            on_connect => sub {
                return if $started++;
                $ch->query("select sleep(2)", { query_timeout => 0.5 },
                    sub { (undef, $err1) = @_; $done1 = 1; EV::break if $done2 });
                $ch->query("select 2",
                    sub { ($rows2, my $e) = @_; $rows2 = "ERR:$e" if $e; $done2 = 1; EV::break if $done1 });
            },
        );
        run_guarded(15, \$bailed);
        $ch->finish;
    }
  SKIP: {
        skip "native unavailable", 2 unless $nat_ok;
        like($err1 // '', qr/timeout/i, "R2 slow query reports timeout");
        is_deeply($rows2, [[2]], "R2 queued query survives the timeout");
    }
}

# ---------------------------------------------------------------------
# R14: cancelling the dispatched HTTP query must not fail never-sent
# queued queries.
# ---------------------------------------------------------------------
{
    my ($err1, $rows2, $bailed, $cancelled, $done1, $done2, $started);
    my $ch;
    if ($http_ok) {
        $ch = EV::ClickHouse->new(
            host => $host, port => $hport, protocol => 'http',
            auto_reconnect => 1, reconnect_delay => 0.05,
            on_error => sub {},
            on_query_start => sub { $ch->cancel unless $cancelled++ },
            on_connect => sub {
                return if $started++;
                $ch->query("select sleep(2) format TabSeparated",
                    sub { (undef, $err1) = @_; $done1 = 1; EV::break if $done2 });
                $ch->query("select 2 format TabSeparated",
                    sub { ($rows2, my $e) = @_; $rows2 = "ERR:$e" if $e; $done2 = 1; EV::break if $done1 });
            },
        );
        run_guarded(15, \$bailed);
        $ch->finish;
    }
  SKIP: {
        skip "HTTP unavailable", 2 unless $http_ok;
        like($err1 // '', qr/cancelled/i, "R14 dispatched query reports cancelled");
        is_deeply($rows2, [[2]], "R14 queued query survives the cancel");
    }
}

# ---------------------------------------------------------------------
# R3: on_query_complete for a torn-down queued query reports that
# entry's own query_id, not the in-flight query's stale id.
# ---------------------------------------------------------------------
{
    my (%seen, $bailed, $started);
    my $ch;
    if ($nat_ok) {
        $ch = EV::ClickHouse->new(
            host => $host, port => $nport, protocol => 'native',
            on_error => sub {},
            on_query_complete => sub {
                my ($qid, undef, undef, undef, undef, $err) = @_;
                $seen{$qid // '<undef>'} = $err;
                EV::break if keys %seen >= 2;
            },
            on_connect => sub {
                return if $started++;
                $ch->query("select sleep(2)", { query_id => 'qid-one' }, sub {});
                $ch->query("select 1", { query_id => 'qid-two' }, sub {});
                my $t; $t = EV::timer(0.3, 0, sub { undef $t; $ch->reset });
            },
        );
        run_guarded(10, \$bailed);
        $ch->finish;
    }
  SKIP: {
        skip "native unavailable", 2 unless $nat_ok;
        like($seen{'qid-one'} // '', qr/reset/i, "R3 in-flight id attributed");
        like($seen{'qid-two'} // '', qr/reset/i, "R3 queued id attributed");
    }
}

# ---------------------------------------------------------------------
# R15: a nested teardown during a queued entry's error fire still
# measures the in-flight query's real duration (queued stays 0.0).
# ---------------------------------------------------------------------
{
    my (%durs, $bailed, $reset_done, $started);
    my $ch;
    if ($nat_ok) {
        $ch = EV::ClickHouse->new(
            host => $host, port => $nport, protocol => 'native',
            on_error => sub {},
            on_query_complete => sub {
                my ($qid, undef, undef, undef, $dur) = @_;
                $durs{$qid // '<undef>'} = $dur;
                EV::break if keys %durs >= 2;
            },
            on_connect => sub {
                return if $started++;
                $ch->query("select sleep(2)", { query_id => 'dur-one' }, sub {});
                $ch->query("select 1", { query_id => 'dur-two' },
                    sub { $ch->reset unless $reset_done++ });
                my $t; $t = EV::timer(0.3, 0, sub { undef $t; $ch->reset });
            },
        );
        run_guarded(10, \$bailed);
        $ch->finish;
    }
  SKIP: {
        skip "native unavailable", 2 unless $nat_ok;
        ok(($durs{'dur-two'} // -1) == 0, "R15 queued duration is 0.0");
        ok(($durs{'dur-one'} // 0) > 0.2, "R15 in-flight duration is real");
    }
}

# ---------------------------------------------------------------------
# R9: hex-looking hostnames ("db") take async EV::cares DNS instead of
# blocking the loop in the sync resolver.
# ---------------------------------------------------------------------
{
    my $have_cares = eval { require EV::cares; 1 };
  SKIP: {
        skip "EV::cares not installed", 2 unless $have_cares;
        my $a = EV::ClickHouse->new(
            host => 'db', port => $nport, protocol => 'native',
            on_error => sub {},
        );
        is($a->_take_dns_pending, 1, "R9 hex hostname takes async DNS");
        my $b = EV::ClickHouse->new(
            host => '127.0.0.1', port => $nport, protocol => 'native',
            on_error => sub {},
        );
        is($b->_take_dns_pending ? 1 : 0, 0, "R9 IP literal stays sync");
        $a->finish;
        $b->finish;
        # Let the 'db' resolve round-trip (and its deferred resolver
        # delete) run so nothing leaks into global destruction.
        my $t = EV::timer(0.5, 0, sub { EV::break });
        EV::run;
        undef $t;
    }
}

# ---------------------------------------------------------------------
# R10: is_healthy / ping_round_trip on a down connection deliver an
# async failure instead of throwing synchronously.
# ---------------------------------------------------------------------
{
    my $ch = EV::ClickHouse->new(
        host => '127.0.0.1', port => $hport, protocol => 'http',
        on_error => sub {},
    );
    $ch->finish;
    my ($ok1, $e1, $r2, $e2);
    my $died1 = !eval { $ch->is_healthy(sub { ($ok1, $e1) = @_ }); 1; };
    my $died2 = !eval { $ch->ping_round_trip(sub { ($r2, $e2) = @_ }); 1; };
    ok(!$died1, "R10 is_healthy does not die when down");
    ok(defined($ok1) && !$ok1 && defined $e1, "R10 is_healthy delivers (0, err)");
    ok(!$died2, "R10 ping_round_trip does not die when down");
    ok(!defined($r2) && defined $e2, "R10 ping_round_trip delivers (undef, err)");
}

# ---------------------------------------------------------------------
# R11: unknown keyword options die instead of silently keeping defaults.
# ---------------------------------------------------------------------
{
    my $ch = EV::ClickHouse->new(
        host => '127.0.0.1', port => $hport, protocol => 'http',
        on_error => sub {},
    );
    my $d1 = !eval { $ch->insert_async('t', [], sub {}, wait_for_flsh => 0); 1; };
    ok($d1, "R11 insert_async rejects unknown options");
    my $d2 = !eval { $ch->kill_query('x', sub {}, bogus => 1); 1; };
    ok($d2, "R11 kill_query rejects unknown options");
    $ch->finish;
}

# ---------------------------------------------------------------------
# R12: kill_query accepts server-legal namespaced ids but still
# rejects quote injection.
# ---------------------------------------------------------------------
{
    my $ch = EV::ClickHouse->new(
        host => '127.0.0.1', port => $hport, protocol => 'http',
        on_error => sub {},
    );
    my $d = !eval { $ch->kill_query("a'b", sub {}); 1; };
    ok($d, "R12 kill_query still rejects quotes");
    $ch->finish;
    my ($fired, $kerr, $died, $bailed);
    if ($nat_ok) {
        my $c2; $c2 = EV::ClickHouse->new(
            host => $host, port => $nport, protocol => 'native',
            on_error => sub {},
            on_connect => sub {
                $died = !eval {
                    $c2->kill_query('etl:hourly:probe-55', sub {
                        $fired = 1; (undef, $kerr) = @_; EV::break;
                    });
                    1;
                };
                EV::break if $died;
            },
        );
        run_guarded(10, \$bailed);
        $c2->finish;
    }
  SKIP: {
        skip "native unavailable", 2 unless $nat_ok;
        ok(!$died, "R12 namespaced id accepted");
        ok($fired && !$kerr, "R12 kill of unknown id completes cleanly");
    }
}

# ---------------------------------------------------------------------
# R13: parse_uri rejects unknown protocols instead of dying later
# inside new().
# ---------------------------------------------------------------------
{
    is(EV::ClickHouse->parse_uri('clickhouse+nativ://h/db'), undef,
        "R13 bad scheme proto rejected");
    is(EV::ClickHouse->parse_uri('clickhouse://h/db?protocol=nativ'), undef,
        "R13 bad query-string proto rejected");
    my $u = EV::ClickHouse->parse_uri('clickhouse+native://h:9001/db');
    is($u->{protocol}, 'native', "R13 good URI still parses");
}

# ---------------------------------------------------------------------
# L2b (LAST): reset() from a "disconnect" trace must terminate, not
# recurse cleanup -> trace -> reset until the process dies. Pre-fix
# this segfaults, so nothing may follow it.
# ---------------------------------------------------------------------
{
    my (@traces, $bailed);
    my $lsn   = listen_on_127001();
    my $pport = $lsn->sockport;
    my $pid = fork_child(sub {
        my $c = $lsn->accept or exit 0;
        close $c;
        close $lsn;
        sleep 10;
        exit 0;
    });
    my $ch; $ch = EV::ClickHouse->new(
        host => '127.0.0.1', port => $pport, protocol => 'http',
        auto_reconnect => 0,
        # The first EOF breaks the loop after the current callback stack
        # (including the nested trace-reset) fully unwinds.
        on_error => sub { EV::break },
        on_trace => sub {
            push @traces, $_[0];
            $ch->reset if $_[0] =~ /^disconnect/;
        },
        on_connect => sub {
            $ch->query("select 1 format TabSeparated", sub {});
        },
    );
    run_guarded(8, \$bailed);
    $ch->finish;
    reap_child($pid);
    ok(grep({ /^disconnect/ } @traces), "L2 disconnect trace observed");
    ok(!$bailed, "L2 trace-reset terminates");
}

done_testing;
