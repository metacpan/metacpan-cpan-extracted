#!/usr/bin/env perl
# Regression tests for review-loop round 5: empty-Tuple insert bytes,
# DateTime64 fraction overflow, AggregateFunction depth guard, JSON
# array-offset validation, FixedString(0/-N) hostile inputs,
# Pool::shutdown vs drain, Pool::drain validation, URI last-@ userinfo,
# MANIFEST completeness, query_log_comment */ handling.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::ClickHouse;

my $host  = $ENV{TEST_CLICKHOUSE_HOST}        || '127.0.0.1';
my $hport = $ENV{TEST_CLICKHOUSE_PORT}        || 8123;
my $nport = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

my $nat_ok = !!IO::Socket::INET->new(PeerAddr => $host, PeerPort => $nport, Timeout => 2);
plan skip_all => 'no ClickHouse native at $host:$nport' unless $nat_ok;
plan tests => 18;

sub new_ch {
    my $ch = EV::ClickHouse->new(host => $host, port => $nport,
                                 protocol => 'native',
                                 on_connect => sub { EV::break },
                                 on_error => sub { EV::break });
    EV::run;
    $ch;
}

# --- minimal fake native server (hostile-input cases) -------------------------
sub _vu { my $n = shift; my $o = ''; do { my $b = $n & 0x7f; $n >>= 7; $o .= chr($b | ($n ? 0x80 : 0)); } while ($n); $o }
sub _str { my $s = shift; _vu(length $s) . $s }
sub _hello { _vu(0) . _str('FakeCH') . _vu(26) . _vu(9) . _vu(54460) . _str('UTC') . _str('') . _vu(0) }
sub _binfo { _vu(1) . chr(0) . _vu(2) . pack('l<', -1) . _vu(0) }
sub _data_pkt {
    my ($type, $nrows, $payload) = @_;
    _vu(1) . _str('') . _binfo() . _vu(1) . _vu($nrows) . _str('c') . _str($type) . chr(0) . $payload;
}
sub _eos { _vu(5) }
# Fork a one-shot server on $port; $bytes_cb->() returns post-hello bytes.
sub _serve {
    my ($port, $bytes_cb, $post_grace) = @_;
    pipe(my $rr, my $ww) or die "pipe: $!";
    my $pid = fork(); die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        close $rr;
        my $srv = IO::Socket::INET->new(LocalAddr => "127.0.0.1:$port",
                                        Listen => 1, ReuseAddr => 1) or die "listen: $!";
        print $ww "up\n"; close $ww;
        my $c = $srv->accept();
        $c->blocking(0);
        my $drain = sub { my $t = shift; my $end = time() + $t;
            while (time() < $end) { sysread($c, my $x, 65536); select(undef, undef, undef, 0.05); } };
        $drain->(0.4);
        syswrite($c, _hello());
        $drain->(0.6);
        syswrite($c, $bytes_cb->());
        $drain->($post_grace || 1.0);
        close $c; close $srv;
        exit 0;
    }
    close $ww; my $line = <$rr>; close $rr;
    $pid;
}

# --- R5-A2: empty-Tuple arrayref insert ---------------------------------------
SKIP: {
my $have_tuple0 = 0;
{
    my $ch = new_ch();
    $ch->query('select cast(() as Tuple())', sub { $have_tuple0 = !$_[1]; EV::break });
    my $pt = EV::timer(10, 0, sub { EV::break });
    EV::run;
    $ch->finish;
}
skip 'server has no empty Tuple()', 1 unless $have_tuple0;
{
    my $ch = new_ch();
    my ($err, $n);
    $ch->query('drop table if exists t63_t0', sub {
    $ch->query('create table t63_t0 (t Tuple()) engine=Memory', sub {
        $ch->insert('t63_t0', [[[]]], sub {
            (undef, $err) = @_;
            $ch->query('select count() from t63_t0', sub {
                my ($r) = @_; $n = $r ? $r->[0][0] : -1;
                $ch->query('drop table t63_t0', sub { EV::break });
            });
        });
    }) });
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;
    ok(!$err && $n == 1, 'R5-A2: Tuple() arrayref insert lands one row');
    $ch->finish;
}
}

# --- R5-A1: DateTime64 fraction overflow ---------------------------------------
{
    my $ch = new_ch();
    my ($oerr, $cerr, $sel);
    $ch->query('drop table if exists t63_dt', sub {
    $ch->query('create table t63_dt (d DateTime64(9)) engine=Memory', sub {
        $ch->insert('t63_dt', [['2262-04-11 23:47:16.9']], sub {
            (undef, $oerr) = @_;
            $ch->insert('t63_dt', [['2262-04-11 23:47:16.8']], sub {
                (undef, $cerr) = @_;
                $ch->query('select count() from t63_dt', sub {
                    my ($r) = @_; $sel = $r ? $r->[0][0] : -1;
                    $ch->query('drop table t63_dt', sub { EV::break });
                });
            });
        });
    }) });
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;
    ok($oerr, 'R5-A1: overflowing fraction fails loudly');
    ok(!$cerr && $sel == 1, 'R5-A1: boundary control inserts');
    $ch->finish;
}

# --- R5-A3: AggregateFunction depth guard --------------------------------------
{
    my $type = ('AggregateFunction(sum, ' x 200) . 'UInt8' . (')' x 200);
    my $pid = _serve(19331, sub { _data_pkt($type, 1, "\x01X") . _eos() });
    my ($rows, $err);
    my $ch; $ch = EV::ClickHouse->new(host => '127.0.0.1', port => 19331,
                                 protocol => 'native',
                                 on_connect => sub {
                                     $ch->query('select 1', sub { ($rows, $err) = @_; EV::break });
                                 },
                                 on_error => sub { $err //= $_[0]; EV::break });
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;
    waitpid($pid, 0);
    ok(!$err, 'R5-A3: deep AggregateFunction fails over the guard cleanly');
    is_deeply($rows, [['X']], 'R5-A3: over-deep type reads as String');
    $ch->finish;
}

# --- R5-A4: JSON array-variant offsets ------------------------------------------
{
    my $mk = sub {
        my ($off) = @_;
        pack('Q<', 0) . _vu(0) . _vu(1) . _str('a')
        . pack('Q<', 1) . _vu(0) . _vu(1) . _str('Array(Int64)') . pack('Q<', 0)
        . "\x00" . $off . pack('Q<', 0);
    };
    my $pid = _serve(19332, sub {
        _data_pkt('JSON', 1, $mk->("\xff\xff\xff\xff\xff\xff\xff\x7f")) . _eos();
    });
    my ($rows, $err);
    my $ch; $ch = EV::ClickHouse->new(host => '127.0.0.1', port => 19332,
                                 protocol => 'native',
                                 on_connect => sub {
                                     $ch->query('select 1', sub { ($rows, $err) = @_; EV::break });
                                 },
                                 on_error => sub { $err //= $_[0]; EV::break });
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;
    waitpid($pid, 0);
    ok($err, 'R5-A4: absurd JSON offset errors instead of OOMing');
    $ch->finish;
    my $pid2 = _serve(19333, sub {
        _data_pkt('JSON', 1, $mk->("\x00" x 8)) . _eos();
    });
    my ($rows2, $err2);
    my $ch2; $ch2 = EV::ClickHouse->new(host => '127.0.0.1', port => 19333,
                                  protocol => 'native',
                                  on_connect => sub {
                                      $ch2->query('select 1', sub { ($rows2, $err2) = @_; EV::break });
                                  },
                                  on_error => sub { $err2 //= $_[0]; EV::break });
    my $t2 = EV::timer(10, 0, sub { EV::break });
    EV::run;
    waitpid($pid2, 0);
    is_deeply($rows2, [[{ a => [] }]], 'R5-A4: benign JSON array still decodes');
    $ch2->finish;
}

# --- R5-A5: FixedString(0) huge row count ---------------------------------------
{
    my $pid = _serve(19334, sub { _data_pkt('FixedString(0)', 2**40, '') . _eos() });
    my ($rows, $err);
    my $ch; $ch = EV::ClickHouse->new(host => '127.0.0.1', port => 19334,
                                 protocol => 'native',
                                 on_connect => sub {
                                     $ch->query('select 1', sub { ($rows, $err) = @_; EV::break });
                                 },
                                 on_error => sub { $err //= $_[0]; EV::break });
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;
    waitpid($pid, 0);
    ok($err, 'R5-A5: absurd FixedString(0) row count errors instead of OOMing');
    $ch->finish;
}

# --- R5-A6: FixedString(-5) insert sample ---------------------------------------
{
    my $sample = _vu(1) . _str('') . _binfo()
        . _vu(1) . _vu(0) . _str('x') . _str('FixedString(-5)') . chr(0);
    my $pid = _serve(19335, sub { $sample . _eos() }, 1.5);
    my $err;
    my $ch; $ch = EV::ClickHouse->new(host => '127.0.0.1', port => 19335,
                                 protocol => 'native',
                                 on_connect => sub {
                                     $ch->insert('t', [['a']], sub { (undef, $err) = @_; EV::break });
                                 },
                                 on_error => sub { $err //= $_[0]; EV::break });
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;
    waitpid($pid, 0);
    like($err // '', qr/encoding failed/, 'R5-A6: negative FixedString fails the insert loudly');
    $ch->finish;
}

# --- R5-U2: shutdown during in-flight drain ------------------------------------
{
    my $pool = EV::ClickHouse::Pool->new(hosts => ["$host:$nport"],
                                         protocol => 'native', size => 2);
    $pool->nominate(0)->query('select sleep(3)', sub {});
    sleep 1;
    my $drained = 0;
    $pool->drain(sub { $drained = 1 });
    my $cb_fired = 0;
    my $died = do { local $@; eval { $pool->shutdown(2, sub { $cb_fired = 1 }); }; $@ };
    like($died, qr/^Pool::shutdown:/, 'R5-U2: shutdown during drain dies cleanly');
    my $t = EV::timer(8, 0, sub { EV::break });
    EV::run;
    ok($drained && !$cb_fired, 'R5-U2: user drain completes, no spurious timeout cb');
    my ($qrows, $qerr);
    $pool->nominate(1)->query('select 1', sub { ($qrows, $qerr) = @_; EV::break });
    my $t2 = EV::timer(8, 0, sub { EV::break });
    EV::run;
    ok(!$qerr && $qrows, 'R5-U2: pool stays usable after the abort');
    $pool->finish;
}

# --- R5-U3: Pool::drain validates its callback -----------------------------------
{
    my $pool = EV::ClickHouse::Pool->new(hosts => ["$host:$nport"],
                                         protocol => 'native', size => 1);
    my $died = !eval { $pool->drain(); 1 };
    ok($died, 'R5-U3: Pool::drain without cb dies synchronously');
    $pool->finish;
}

# --- R5-U4: URI userinfo splits at the last @ ------------------------------------
{
    my $h = EV::ClickHouse->parse_uri('clickhouse://user:p@ss@127.0.0.1:9000/db');
    is($h->{password}, 'p@ss', 'R5-U4: parse_uri keeps @ in password');
    my $ch = EV::ClickHouse->new(uri => 'clickhouse://user:p@ss@127.0.0.1:9000/db',
                                 on_error => sub {});
    is($ch->current_host, '127.0.0.1', 'R5-U4: new() parses host past @ password');
    $ch->finish;
}

# --- R5-U5: MANIFEST ships the review tests --------------------------------------
{
    my $man = do { open my $fh, '<', 'MANIFEST' or die "MANIFEST: $!"; local $/; <$fh> };
    ok($man =~ /t\/59_review_loop_r1\.t/ && $man =~ /t\/62_review_loop_r4\.t/,
       'R5-U5: MANIFEST lists the review-loop tests');
}

# --- R5-U1: query_log_comment containing */ stays well-formed ---------------------
{
    for my $proto (qw(http native)) {
        my $port = $proto eq 'http' ? $hport : $nport;
        my $sql = $proto eq 'http' ? 'select 1 format TabSeparated' : 'select 1';
        my ($rows, $err);
        my $ch; $ch = EV::ClickHouse->new(
            host => $host, port => $port, protocol => $proto,
            query_log_comment => 'evil */ tail',
            on_connect => sub {
                $ch->query($sql, sub { ($rows, $err) = @_; EV::break });
            },
            on_error => sub { $err //= $_[0]; EV::break });
        my $t = EV::timer(10, 0, sub { EV::break });
        EV::run;
        ok(!$err && $rows && @$rows == 1, "R5-U1: */ comment queries on $proto");
        $ch->finish;
    }
}
