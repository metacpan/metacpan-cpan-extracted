use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;
use B ();
use IO::Socket::INET;
use IO::Select;
use POSIX ();

# Wall times resolve through the client's own TZif reader exactly as the
# server parses them (gaps, folds, half-hour zones); an unknown zone is an
# error; numbers are encoded without caching strings in the caller's data.

my $host = $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1';
my $port = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;
plan skip_all => "ClickHouse native port not reachable"
    unless IO::Socket::INET->new(PeerAddr => $host, PeerPort => $port, Timeout => 2);

sub wait_for {
    my ($start) = @_;
    my ($res, $err, $done);
    $start->(sub { ($res, $err) = @_; $done = 1; EV::break });
    my $t = EV::timer(20, 0, sub { $err //= 'timeout'; $done = 1; EV::break });
    EV::run until $done;
    return ($res, $err);
}

sub connect_ch {
    my (%o) = @_;
    my $ok;
    my $ch = EV::ClickHouse->new(host => $host, port => $port, protocol => 'native', %o,
        on_connect => sub { $ok = 1; EV::break }, on_error => sub { });
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run until $ok;
    return $ch;
}

my $ch = connect_ch();
my $dt = connect_ch(decode_datetime => 1);
sub q_ { my ($sql, $c) = @_; wait_for(sub { ($c // $ch)->query($sql, $_[0]) }) }

# Every half hour across DST transition days, in zones with ordinary,
# half-hour and southern-hemisphere rules and a historic offset change.
my @zones = ('Europe/Berlin', 'America/New_York', 'Australia/Lord_Howe',
             'Europe/Moscow', 'America/St_Johns', 'Pacific/Chatham', 'Asia/Kolkata',
             'Pacific/Apia', 'Pacific/Kwajalein');
# Apia skipped 2011-12-30 and Kwajalein 1993-08-21: 24 h offset changes
my @days = ('2011-03-27', '2011-10-30', '2014-10-26', '2021-03-14', '2021-11-07',
            '2023-04-02', '2023-10-01', '2024-09-29', '2037-11-01',
            '2011-12-29', '2011-12-30', '2011-12-31', '1993-08-20', '1993-08-21',
            '1993-08-22');
my @walls;
for my $d (@days) {
    for my $m (0 .. 47) {
        push @walls, sprintf '%s %02d:%02d:00', $d, int($m / 2), $m % 2 * 30;
    }
}
for my $z (@zones) {
    my $t = 'pf_tz_' . ($z =~ s{\W}{_}gr);
    q_("drop table if exists $t");
    q_("create table $t (id UInt32, a DateTime('$z'), b DateTime('$z'), c DateTime64(3, '$z')) engine = Memory");
    my (undef, $err) = wait_for(sub {
        $ch->insert("$t (id, a, c)", [ map { [$_, $walls[$_], "$walls[$_].125"] } 0 .. $#walls ], $_[0]) });
    ok(!$err, "$z: wall-time insert") or diag $err;
    (undef, $err) = wait_for(sub {
        $ch->insert("$t (id, b)", join('', map { "$_\t$walls[$_]\n" } 0 .. $#walls),
            { data_format => 'TabSeparated' }, $_[0]) });
    ok(!$err, "$z: server-parsed insert") or diag $err;
    my ($r) = q_("select id, max(toUnixTimestamp(a)), max(toUnixTimestamp(b)),"
               . " max(toUnixTimestamp64Milli(c)) from $t group by id"
               . " having max(toUnixTimestamp(a)) != max(toUnixTimestamp(b))"
               . " or max(toUnixTimestamp64Milli(c)) != max(toUnixTimestamp(b)) * 1000 + 125");
    is_deeply($r // [], [], "$z: same instants as the server's parse");
    my ($fmt) = q_("select a, c from $t where id > 0 and a > 0 order by id", $dt);
    my ($srv) = q_("select toString(a), toString(c) from $t where id > 0 and a > 0 order by id");
    is_deeply($fmt, $srv, "$z: decode_datetime formatting matches toString");
    q_("drop table $t");
}

# Dates outside 1970..2038 format without time_t.
{
    my ($r) = q_(q{select toDate32('1900-01-01'), toDate32('2299-12-31'), toDate('2149-06-06'),}
               . q{ toDateTime64('1900-01-01 00:00:00.5', 1, 'UTC'),}
               . q{ toDateTime64('2299-12-31 23:59:59.25', 2, 'Asia/Kolkata'),}
               . q{ toDateTime('2106-02-07 06:28:15', 'UTC')}, $dt);
    my ($s) = q_(q{select toString(toDate32('1900-01-01')), toString(toDate32('2299-12-31')),}
               . q{ toString(toDate('2149-06-06')),}
               . q{ toString(toDateTime64('1900-01-01 00:00:00.5', 1, 'UTC')),}
               . q{ toString(toDateTime64('2299-12-31 23:59:59.25', 2, 'Asia/Kolkata')),}
               . q{ toString(toDateTime('2106-02-07 06:28:15', 'UTC'))});
    is_deeply($r, $s, 'far dates format as the server prints them');
}

# Numbers are encoded from the number, without a string cached in them.
{
    q_('drop table if exists pf_num2');
    q_('create table pf_num2 (d Decimal(18, 6), f Float64, s String) engine = Memory');
    my @row = (0.000017 + 3 * 0.001, 42, 7);
    my (undef, $err) = wait_for(sub { $ch->insert('pf_num2', [ \@row ], $_[0]) });
    ok(!$err, 'numeric insert') or diag $err;
    my @pok = grep { B::svref_2object(\$row[$_])->FLAGS & (B::SVf_POK | B::SVp_POK) } 0 .. 2;
    is_deeply(\@pok, [], 'inserted numbers keep no string form');
    my ($r) = q_('select toString(d), f, s from pf_num2');
    is_deeply($r, [[ '0.003017', 42, '7' ]], 'values as Perl would print them');
    q_('drop table pf_num2');
}

# An unknown zone fails the insert and the decode, naming the zone.
{
    my $vu = sub { my ($v) = @_; my $b = ''; do { my $x = $v & 127; $v >>= 7; $b .= chr($x | ($v ? 128 : 0)) } while $v; $b };
    my $vstr = sub { $vu->(length $_[0]) . $_[0] };
    my $drain = sub { my ($s) = @_; my $sel = IO::Select->new($s); while ($sel->can_read(.1)) { sysread($s, my $b, 65536) or last } };
    my $hello = "\x00" . $vstr->('mock') . $vu->(1) . $vu->(1) . $vu->(54492)
              . $vstr->('UTC') . $vstr->('mock') . $vu->(0);
    my $type = "DateTime('No/Such_Zone')";
    my $block = sub { my ($rows, $data) = @_;
        $vu->(1) . $vstr->('') . "\x01\x00\x02\xff\xff\xff\xff\x00" . $vu->(1) . $vu->($rows)
        . $vstr->('c') . $vstr->($type) . "\x00" . $data };
    for my $case ([insert => $block->(0, '')], [select => $block->(1, pack('V', 0)) . $vu->(5)]) {
        my ($what, $reply) = @$case;
        my $l = IO::Socket::INET->new(LocalAddr => '127.0.0.1', Listen => 1, ReuseAddr => 1) or die $!;
        my $pid = fork // die $!;
        if (!$pid) {
            alarm 10;
            my $s = $l->accept or POSIX::_exit(0);
            $drain->($s); syswrite $s, $hello; $drain->($s);
            syswrite $s, $reply; $drain->($s);
            syswrite $s, $vu->(5);
            sleep 2;
            POSIX::_exit(0);
        }
        my $mport = $l->sockport;
        close $l;
        my $m = connect_ch(port => $mport, decode_datetime => 1, compress => 0);
        my (undef, $err) = wait_for(sub {
            $what eq 'insert'
                ? $m->insert('t', [['2024-01-01 00:00:00']], $_[0])
                : $m->query('select c', $_[0]) });
        like($err // '', qr/unknown timezone 'No\/Such_Zone'/, "unknown zone fails the $what");
        $m->finish if $m->is_connected;
        kill 'TERM', $pid;
        waitpid $pid, 0;
    }

    # A zone (from TZDIR) whose clocks go back 36 hours: a wall time in the
    # last hours of the fold still resolves to the earlier instant.
    require File::Temp;
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    my $tt = 1_000_000_000;
    my $tzif = 'TZif' . "\0" x 16 . pack('N6', 0, 0, 0, 1, 2, 4)
             . pack('N', $tt) . "\x01" . pack('N', 93600) . "\0\0"
             . pack('N', -36000 & 0xffffffff) . "\0\0" . "AAA\0";
    mkdir "$dir/Test";
    open my $fh, '>', "$dir/Test/Back36" or die $!;
    binmode $fh;
    print $fh $tzif;
    close $fh;
    local $ENV{TZDIR} = $dir;
    my $wall = $tt + 25 * 3600;
    my $want = pack('V', $wall - 93600);
    my $l = IO::Socket::INET->new(LocalAddr => '127.0.0.1', Listen => 1, ReuseAddr => 1) or die $!;
    pipe(my $rd, my $wr) or die $!;
    my $pid = fork // die $!;
    if (!$pid) {
        alarm 10;
        close $rd;
        my $s = $l->accept or POSIX::_exit(0);
        $drain->($s); syswrite $s, $hello; $drain->($s);
        syswrite $s, $vu->(1) . $vstr->('') . "\x01\x00\x02\xff\xff\xff\xff\x00" . $vu->(1)
            . $vu->(0) . $vstr->('c') . $vstr->("DateTime('Test/Back36')") . "\x00";
        my $sel = IO::Select->new($s);
        my $got = '';
        while ($sel->can_read(.3)) { sysread($s, my $b, 65536) or last; $got .= $b }
        syswrite $s, $vu->(5);
        print $wr unpack('H*', $got), "\n";
        close $wr;
        sleep 1;
        POSIX::_exit(0);
    }
    close $wr;
    my $mport = $l->sockport;
    close $l;
    my $m = connect_ch(port => $mport, compress => 0);
    my @g = gmtime($wall);
    my $text = sprintf '%04d-%02d-%02d %02d:%02d:%02d', $g[5] + 1900, $g[4] + 1, @g[3, 2, 1, 0];
    my (undef, $err) = wait_for(sub { $m->insert('t', [[$text]], $_[0]) });
    ok(!$err, '36-hour fold insert') or diag $err;
    my $hex = <$rd>;
    like($hex // '', qr/\Q${\ unpack('H*', $want)}\E/, 'fold resolves to the earlier instant');
    $m->finish if $m->is_connected;
    waitpid $pid, 0;
}

done_testing;
