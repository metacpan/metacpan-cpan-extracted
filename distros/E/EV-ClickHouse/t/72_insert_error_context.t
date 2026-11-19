use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;
use POSIX ();

# Native insert encoding errors name the column, row and value; exceptions
# from user code during the deferred encode fail only that insert.

my $host = $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1';
my $port = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

require IO::Socket::INET;
plan skip_all => "ClickHouse native port not reachable"
    unless IO::Socket::INET->new(PeerAddr => $host, PeerPort => $port, Timeout => 2);

{ package DieStr; use overload '""' => sub { die "stringify died\n" }, fallback => 1; }
{ package DieTie; sub TIESCALAR { bless { n => 0 }, shift } sub FETCH { die "fetch died\n" if $_[0]{n}++; 'ok' } }

my $ch;
sub conn {
    my $ok;
    $ch = EV::ClickHouse->new(
        host => $host, port => $port, protocol => 'native',
        on_connect => sub { $ok = 1; EV::break },
        on_error   => sub { },
    );
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run until $ok;
}

sub wait_for {
    my ($start) = @_;
    my ($res, $err, $done);
    $start->(sub { ($res, $err) = @_; $done = 1; EV::break });
    my $t = EV::timer(10, 0, sub { $err //= 'timeout'; $done = 1; EV::break });
    EV::run until $done;
    return ($res, $err);
}

sub q_ { my ($sql) = @_; my @r = wait_for(sub { $ch->query($sql, $_[0]) }); conn() unless $ch->is_connected; @r }

conn();
my $t = 'er_ctx';
q_("drop table if exists $t");
q_("create table $t (a UInt8, s String, n Nullable(UInt16), arr Array(UInt8),"
 . " m Map(String, UInt8), tu Tuple(UInt8, String), lc LowCardinality(String),"
 . " dt DateTime('Asia/Yakutsk')) engine = Memory");

my @good = map { [ $_ % 200, "s$_", undef, [1], { k => 1 }, [1, 'x'], 'l', 1700000000 ] } 0 .. 2999;

sub ins_err {
    my ($mut) = @_;
    my @rows = map { [@$_] } @good;
    $mut->(\@rows);
    my (undef, $err) = wait_for(sub { $ch->insert($t, \@rows, $_[0]) });
    conn() unless $ch->is_connected;
    return $err // '';
}

my $pre = qr/native INSERT encoding failed \(/;
like(ins_err(sub { $_[0][2500][0] = 'x' }),
    qr/${pre}column 'a' \(UInt8\), row 2500: invalid value 'x'\)/, 'scalar in a later chunk');
like(ins_err(sub { $_[0][7][2] = 70000 }),
    qr/column 'n' \(Nullable\(UInt16\)\), row 7: invalid value '70000'/, 'Nullable');
like(ins_err(sub { $_[0][1500][3] = [1, 2, 300] }),
    qr/column 'arr' \(Array\(UInt8\)\), row 1500: invalid element '300'/, 'Array element');
like(ins_err(sub { $_[0][3][4] = { a => 1, b => 'zz' } }),
    qr/column 'm' \(Map\(String, UInt8\)\), row 3: invalid element 'zz'/, 'Map value');
like(ins_err(sub { $_[0][4][5] = [999, 'q'] }),
    qr/column 'tu' \(Tuple\(UInt8, String\)\), row 4: invalid element '999'/, 'Tuple element');
like(ins_err(sub { $_[0][5][6] = undef }),
    qr/column 'lc' \(LowCardinality\(String\)\), row 5: invalid value undef/, 'LowCardinality undef');
like(ins_err(sub { $_[0][6][0] = 'y' x 100 }),
    qr/row 6: invalid value '${\ ('y' x 40)}'\.\.\.\)/, 'long value truncated');
like(ins_err(sub { $_[0][8][0] = "a\tb\x01\xe9'\\" }),
    qr/row 8: invalid value 'a\\tb\\x01\\xe9\\'\\\\'/, 'control and non-ASCII bytes escaped');
like(ins_err(sub { $_[0][9][0] = undef }),
    qr/column 'a' \(UInt8\), row 9: invalid value undef/, 'undef in a non-Nullable column');
like(ins_err(sub { $_[0][10][0] = {} }),
    qr/row 10: invalid value HASH reference/, 'reference shown by type');
like(ins_err(sub { $_[0][11][0] = 1; $_[0][2900][0] = 'q'; $_[0][12][1] = [] }),
    qr/column 'a' \(UInt8\), row 2900/, 'first failing column, not first failing row');

{
    my ($r) = q_("select count() from $t");
    is($r->[0][0], 0, 'failed inserts stored nothing');
}

# Exceptions from user code during the deferred encode.
{
    my $before = POSIX::strftime('%Z', localtime(0));
    like(ins_err(sub { $_[0][2100][1] = bless {}, 'DieStr' }),
        qr/${pre}column 's' \(String\), row 2100: stringify died\)/, 'dying overload fails the insert');
    ok($ch->is_connected, 'connection survives the exception');
    {
        my @rows = map { [@$_] } @good[0 .. 9];
        my @arr;
        tie $arr[0], 'DieTie';
        my $seen = $arr[0];
        $rows[3][3] = \@arr;
        my (undef, $err) = wait_for(sub { $ch->insert($t, \@rows, $_[0]) });
        conn() unless $ch->is_connected;
        like($err // '', qr/column 'arr' \(Array\(UInt8\)\), row 3: fetch died/,
            'dying FETCH in a nested element fails the insert');
    }
    like(ins_err(sub { $_[0][0][7] = '2024-01-01 00:00:00'; $_[0][1][7] = bless {}, 'DieStr' }),
        qr/column 'dt' \(DateTime\('Asia\/Yakutsk'\)\), row 1: stringify died/,
        'exception inside a timezone-switched column');
    is(POSIX::strftime('%Z', localtime(0)), $before, 'process timezone restored after the exception');
    my (undef, $err) = wait_for(sub { $ch->insert($t, [ @good[0 .. 4] ], $_[0]) });
    ok(!$err, 'next insert on the same connection works') or diag $err;
    my ($r) = q_("select count() from $t");
    is($r->[0][0], 5, 'only the good insert landed');
}

# TabSeparated text: rows are 1-based lines.
{
    my (undef, $err) = wait_for(sub { $ch->insert("$t (a, s)", "1\tx\n300\ty\n", $_[0]) });
    conn() unless $ch->is_connected;
    like($err // '', qr/column 'a' \(UInt8\), line 2: invalid value '300'/, 'TabSeparated line');
}

# A column type the client cannot encode.
{
    my (undef, $cerr) = q_('create table if not exists er_var (v Variant(UInt8, String)) engine = Memory');
    SKIP: {
        skip "Variant not available: $cerr", 1 if $cerr;
        my (undef, $err) = wait_for(sub { $ch->insert('er_var', [[1]], $_[0]) });
        conn() unless $ch->is_connected;
        like($err // '', qr/column 'v' \(Variant\([^)]*\)\): unsupported type\)/, 'unsupported type');
        q_('drop table er_var');
    }
}

# External tables share the encoders.
{
    my $ok = eval {
        $ch->query('select * from ext', { external => { ext => {
            structure => [ a => 'UInt8' ], data => [ [1], [2], [999] ] } } }, sub { });
        1;
    };
    like($ok ? '' : $@, qr/external table 'ext': column 'a' \(UInt8\), row 2: invalid value '999'/,
        'external table row and value');
}

q_("drop table $t");

# empty_as_default against a mock server's column description: one that
# does not parse completely, or a hex DEFAULT past 64 bits, fails the
# insert instead of storing a zero or a wrapped value.
{
    require IO::Select;
    my $vu = sub {
        my ($v) = @_;
        my $b = '';
        do { my $x = $v & 127; $v >>= 7; $b .= chr($x | ($v ? 128 : 0)) } while $v;
        $b;
    };
    my $vstr = sub { $vu->(length $_[0]) . $_[0] };
    my $drain = sub {
        my ($s) = @_;
        my $sel = IO::Select->new($s);
        while ($sel->can_read(.1)) { sysread($s, my $buf, 65536) or last }
    };
    my $hello = "\x00" . $vstr->('mock') . $vu->(1) . $vu->(1) . $vu->(54492)
              . $vstr->('UTC') . $vstr->('mock') . $vu->(0);
    my $sample = $vu->(1) . $vstr->('') . "\x01\x00\x02\xff\xff\xff\xff\x00" . $vu->(2) . $vu->(0)
               . $vstr->('a') . $vstr->('UInt8') . "\x00" . $vstr->('b') . $vstr->('UInt64') . "\x00";
    my $head = "columns format version: 1\n2 columns:\n`a` UInt8\n";
    for my $case (
        [ 'truncated description', $head, qr/cannot parse the server's column description/ ],
        [ 'malformed column line', "$head" . "b UInt64\n", qr/cannot parse the server's column description/ ],
        [ 'hex DEFAULT past 64 bits', "$head`b` UInt64\tDEFAULT\t0x10000000000000001\n",
          qr/column 'b' \(UInt64\), row 0: no client-side default/ ],
        [ 'hex DEFAULT in range', "$head`b` UInt64\tDEFAULT\t0xffffffffffffffff\n", undef ],
    ) {
        my ($name, $desc, $want) = @$case;
        my $listener = IO::Socket::INET->new(LocalAddr => '127.0.0.1', Listen => 1, ReuseAddr => 1)
            or die $!;
        my $pid = fork // die $!;
        if (!$pid) {
            alarm 10;
            my $s = $listener->accept or POSIX::_exit(0);
            $drain->($s);
            syswrite $s, $hello;
            $drain->($s);
            syswrite $s, $vu->(11) . $vstr->('') . $vstr->($desc) . $sample;
            $drain->($s);
            syswrite $s, $vu->(5);
            sleep 2;
            POSIX::_exit(0);
        }
        my $mport = $listener->sockport;
        close $listener;
        my ($m, $done, $err);
        $m = EV::ClickHouse->new(
            host => '127.0.0.1', port => $mport, protocol => 'native', compress => 0,
            on_connect => sub {
                $m->insert('t (a, b)', [[1, undef]], { empty_as_default => 1 },
                    sub { ($done, $err) = (1, $_[1]); EV::break });
            },
            on_error => sub { },
        );
        my $timer = EV::timer(5, 0, sub { EV::break });
        EV::run until $done || !$timer->is_active;
        if ($want) { like($err // '', $want, "mock: $name") }
        else       { ok($done && !$err, "mock: $name") or diag $err // 'no callback' }
        $m->finish if $m->is_connected;
        kill 'TERM', $pid;
        waitpid $pid, 0;
    }
}

done_testing;
