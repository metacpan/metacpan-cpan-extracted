use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;

# empty_as_default decides per value, accepts the CAST/:: constant forms,
# and table_defaults evaluates constant DEFAULTs on the server.

my $host  = $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1';
my $nport = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;
my $hport = $ENV{TEST_CLICKHOUSE_PORT} || 8123;

require IO::Socket::INET;
plan skip_all => "ClickHouse not reachable"
    unless IO::Socket::INET->new(PeerAddr => $host, PeerPort => $nport, Timeout => 2)
        && IO::Socket::INET->new(PeerAddr => $host, PeerPort => $hport, Timeout => 2);

my %conn;
sub conn {
    my ($proto) = @_;
    return $conn{$proto} if $conn{$proto} && $conn{$proto}->is_connected;
    my ($ok, $err);
    my $ch = EV::ClickHouse->new(
        host => $host, port => $proto eq 'native' ? $nport : $hport,
        protocol => $proto,
        on_connect => sub { $ok = 1; EV::break },
        on_error   => sub { $err = $_[0]; EV::break },
    );
    my $t = EV::timer(10, 0, sub { $err //= 'timeout'; EV::break });
    EV::run until $ok || $err;
    die "connect $proto: $err" unless $ok;
    $ch->on_error(sub { });
    return $conn{$proto} = $ch;
}

sub wait_for {
    my ($start) = @_;
    my ($res, $err, $done);
    $start->(sub { ($res, $err) = @_; $done = 1; EV::break });
    my $t = EV::timer(10, 0, sub { $err //= 'timeout'; $done = 1; EV::break });
    EV::run until $done;
    return ($res, $err);
}

sub q_ {
    my ($sql) = @_;
    my $ch = conn('native');
    my @r = wait_for(sub { $ch->query($sql, $_[0]) });
    delete $conn{native} if $r[1];
    return @r;
}

sub ins {
    my ($table, $data, $opts) = @_;
    my $ch = conn('native');
    my (undef, $err) = wait_for(sub { $ch->insert($table, $data, $opts // {}, $_[0]) });
    delete $conn{native} if $err;
    return $err;
}

# The reporter's table: a non-literal DEFAULT only matters for an empty value.
q_('drop table if exists pf_dpv');
q_(q{create table pf_dpv (n UInt8, a UInt32 DEFAULT CAST(0, 'UInt32'),}
 . q{ c UInt16 DEFAULT n + 100) engine = MergeTree order by n});
my $ead = { empty_as_default => 1 };
is(ins('pf_dpv (n, a, c)', [[1, 0, 5]], $ead), undef, 'no empty value: non-literal DEFAULT unused');
is(ins('pf_dpv (n, a, c)', [[2, '', 6], [3, undef, 7]], $ead), undef, 'CAST default fills a');
like(ins('pf_dpv (n, a, c)', [[4, 1, 8], [5, 1, undef]], $ead),
    qr/column 'c' \(UInt16\), row 1: non-literal DEFAULT 'n \+ 100': use data_format => 'Native'/,
    'empty value needing a non-literal DEFAULT names the row');
is(ins('pf_dpv (n, a, c)', "6\t\t9\n", $ead), undef, 'TabSeparated: CAST default');
like(ins('pf_dpv (n, a, c)', "7\t1\t10\n8\t1\t\n", $ead),
    qr/column 'c' \(UInt16\), line 2: non-literal DEFAULT/, 'TabSeparated: line named');
my ($rows) = q_('select n, a, c from pf_dpv order by n');
is_deeply($rows, [ [1, 0, 5], [2, 0, 6], [3, 0, 7], [6, 0, 9] ], 'stored rows');

# Constant forms, compared with the server's own cast of each DEFAULT.
q_('drop table if exists pf_dcast');
q_(q{create table pf_dcast (n UInt8,}
 . q{ a UInt32 DEFAULT CAST(7, 'UInt32'),}
 . q{ b String DEFAULT CAST('x\'y' AS String),}
 . q{ c UInt8 DEFAULT 9::UInt8,}
 . q{ d Decimal(9, 2) DEFAULT CAST(1.5, 'Decimal(9, 2)'),}
 . q{ e Array(UInt16) DEFAULT [CAST(1, 'UInt16'), 2],}
 . q{ f DateTime('UTC') DEFAULT CAST('2024-02-03 04:05:06', 'DateTime(\'UTC\')'),}
 . q{ g Nullable(String) DEFAULT _CAST('z', 'Nullable(String)'),}
 . q{ h Float64 DEFAULT CAST(0.1 AS Float64)) engine = Memory});
is(ins('pf_dcast', [[1, ('') x 8]], $ead), undef, 'constant forms insert');
{
    my ($cols) = q_(q{select name, type, default_expression from system.columns}
                  . q{ where database = currentDatabase() and table = 'pf_dcast' and name != 'n'}
                  . q{ order by position});
    for my $c (@$cols) {
        my ($name, $type, $expr) = @$c;
        my ($got) = q_("select toString($name) from pf_dcast");
        my ($want) = q_("select toString(cast(($expr) as $type))");
        is($got->[0][0], $want->[0][0], "$name: $expr");
    }
}

# table_defaults: constant DEFAULTs evaluated by the server, both protocols.
q_('drop table if exists pf_tdef');
q_(q{create table pf_tdef (n UInt8, a UInt32 DEFAULT CAST(0, 'UInt32'), c UInt16 DEFAULT n + 100,}
 . q{ s String DEFAULT concat('a', 'b'), t DateTime DEFAULT now(), r UInt32 DEFAULT rand(),}
 . q{ arr Array(UInt8) DEFAULT [1, 2], tu Tuple(UInt8, String) DEFAULT (3, 'q'),}
 . q{ bo Bool DEFAULT false, nu Nullable(UInt8) DEFAULT NULL,}
 . q{ m Map(String, UInt8) DEFAULT map('k', 1), plain UInt8) engine = Memory});
my $want = { a => '0', s => 'ab', arr => [1, 2], tu => [3, 'q'], bo => '0', nu => undef };
for my $proto ('native', 'http') {
    my $ch = conn($proto);
    for my $name ('pf_tdef', 'currentDatabase_placeholder') {
        my $t = $name eq 'pf_tdef' ? 'pf_tdef' : do {
            my ($db) = q_('select currentDatabase()');
            "`$db->[0][0]`.pf_tdef";
        };
        my ($defs, $err) = wait_for(sub { $ch->table_defaults($t, $_[0]) });
        ok(!$err, "$proto table_defaults($t)") or diag $err;
        is_deeply($defs, $want, "$proto table_defaults($t): constant defaults only");
    }
    my (undef, $err) = wait_for(sub { $ch->table_defaults('pf_no_such_table', $_[0]) });
    like($err // '', qr/no table/, "$proto: missing table");
}
{
    my ($defs) = wait_for(sub { conn('native')->table_defaults('pf_tdef', $_[0]) });
    is(ins('pf_tdef (n, a, s, arr, tu, bo, nu, plain)',
           [[1, undef, '', undef, undef, '', undef, 4]], { defaults => $defs }),
       undef, 'table_defaults result works as defaults');
    my ($r) = q_('select a, s, arr, tu, bo, nu, plain from pf_tdef');
    is_deeply($r, [[0, 'ab', [1, 2], [3, 'q'], 0, undef, 4]], 'defaults stored');
}

q_("drop table $_") for qw(pf_dpv pf_dcast pf_tdef);

# A CAST to another type is not the column's literal: the server converts.
{
    q_('drop table if exists pf_dcm');
    q_(q{create table pf_dcm (n UInt8, x UInt16 DEFAULT CAST(257, 'UInt8'),}
     . q{ e Array(UInt16) DEFAULT [CAST(300, 'UInt8'), 2],}
     . q{ y LowCardinality(String) DEFAULT CAST('a', 'String'),}
     . q{ z Nullable(UInt8) DEFAULT CAST(3, 'UInt8')) engine = Memory});
    like(ins('pf_dcm (n, x)', [[1, '']], $ead),
        qr/column 'x' \(UInt16\), row 0: non-literal DEFAULT 'CAST\(257, 'UInt8'\)'/,
        'CAST to a narrower type is not taken as the literal');
    like(ins('pf_dcm (n, e)', [[1, undef]], $ead),
        qr/column 'e' \(Array\(UInt16\)\), row 0: non-literal DEFAULT/,
        'element CAST to another type is not taken either');
    is(ins('pf_dcm (n, y, z)', [[2, '', '']], $ead), undef,
        'CAST to the type under LowCardinality/Nullable is the literal');
    q_('insert into pf_dcm (n) values (3)');
    my ($r) = q_('select toString(y), toString(z) from pf_dcm order by n');
    is_deeply($r, [['a', '3'], ['a', '3']], 'same values as the server default');
    my ($defs, $err) = wait_for(sub { conn('native')->table_defaults('pf_dcm', $_[0]) });
    is_deeply($defs, { x => '1', e => [44, 2], y => 'a', z => '3' },
        'table_defaults converts on the server') or diag $err;
    q_('drop table pf_dcm');
}

# Determinism, not a uuid prefix, decides; backquoted names decode escapes.
{
    q_("drop table if exists `pf_dq\\tx`");
    q_("create table `pf_dq\\tx` (n UInt8, u UUID DEFAULT toUUID('00000000-0000-0000-0000-000000000001'),"
     . " w DateTime DEFAULT UTCTimestamp(), s String DEFAULT UUIDNumToString(toFixedString(unhex('00000000000000000000000000000002'), 16)))"
     . " engine = Memory");
    my ($defs, $err) = wait_for(sub { conn('native')->table_defaults('`pf_dq\\tx`', $_[0]) });
    ok(!$err, 'backquoted name with an escape') or diag $err;
    is_deeply($defs, { u => '00000000-0000-0000-0000-000000000001',
                       s => '00000000-0000-0000-0000-000000000002' },
        'deterministic uuid functions kept, UTCTimestamp() left out');
    q_("drop table `pf_dq\\tx`");
}

# Every evaluation failing is an error, not an empty success.
{
    require IO::Select;
    require POSIX;
    my $vu = sub { my ($v) = @_; my $b = ''; do { my $x = $v & 127; $v >>= 7; $b .= chr($x | ($v ? 128 : 0)) } while $v; $b };
    my $vstr = sub { $vu->(length $_[0]) . $_[0] };
    my $drain = sub { my ($s) = @_; my $sel = IO::Select->new($s); my $got = '';
        while ($sel->can_read(.2)) { sysread($s, my $b, 65536) or last; $got .= $b } $got };
    my $hello = "\x00" . $vstr->('mock') . $vu->(1) . $vu->(1) . $vu->(54492)
              . $vstr->('UTC') . $vstr->('mock') . $vu->(0);
    my $bi = "\x01\x00\x02\xff\xff\xff\xff\x00";
    my @cols = qw(name type default_kind default_expression);
    my @val = ('a', 'UInt8', 'DEFAULT', '1 + 1');
    my $block = $vu->(1) . $vstr->('') . $bi . $vu->(4) . $vu->(1)
              . join('', map { $vstr->($cols[$_]) . $vstr->('String') . "\x00" . $vstr->($val[$_]) } 0 .. 3);
    my $exc = $vu->(2) . pack('l<', 46) . $vstr->('DB::Exception') . $vstr->('mock: evaluation failed')
            . $vstr->('') . "\x00";
    my $l = IO::Socket::INET->new(LocalAddr => '127.0.0.1', Listen => 1, ReuseAddr => 1) or die $!;
    my $pid = fork // die $!;
    if (!$pid) {
        alarm 10;
        my $s = $l->accept or POSIX::_exit(0);
        $drain->($s); syswrite $s, $hello;
        $drain->($s); syswrite $s, $block . $vu->(5);
        while (length $drain->($s)) { syswrite $s, $exc }
        POSIX::_exit(0);
    }
    my $mport = $l->sockport;
    close $l;
    my $ok;
    my $m = EV::ClickHouse->new(host => '127.0.0.1', port => $mport, protocol => 'native',
        compress => 0, on_connect => sub { $ok = 1; EV::break }, on_error => sub { });
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run until $ok;
    my ($defs, $err) = wait_for(sub { $m->table_defaults('t', $_[0]) });
    ok(!$defs, 'no defaults delivered');
    like($err // '', qr/evaluation failed/, 'the evaluation error is delivered');
    $m->finish if $m->is_connected;
    kill 'TERM', $pid;
    waitpid $pid, 0;
}

done_testing;
