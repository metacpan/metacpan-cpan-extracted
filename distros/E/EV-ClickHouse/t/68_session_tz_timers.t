use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;

my $host  = $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1';
my $port  = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;
my $hport = $ENV{TEST_CLICKHOUSE_PORT} || 8123;

require IO::Socket::INET;
plan skip_all => "ClickHouse native port not reachable"
    unless IO::Socket::INET->new(PeerAddr => $host, PeerPort => $port, Timeout => 2);

my %native = (host => $host, port => $port, protocol => 'native');

sub ch { EV::ClickHouse->new(%native, on_error => sub { diag("error: $_[0]") }, @_) }

sub wait_for {
    my ($start) = @_;
    my ($res, $err, $done);
    $start->(sub { ($res, $err) = @_; $done = 1; EV::break });
    EV::now_update;
    my $guard = EV::timer(15, 0, sub { $err //= 'timed out'; EV::break });
    EV::run until $done || $err;
    return ($res, $err);
}

sub q_ok {
    my ($ch, $sql, @opt) = @_;
    my ($res, $err) = wait_for(sub { $ch->query($sql, @opt, $_[0]) });
    die "$sql: $err" if $err;
    return $res;
}

sub ins {
    my ($ch, $table, $data, @opt) = @_;
    my (undef, $err) = wait_for(sub { $ch->insert($table, $data, @opt, $_[0]) });
    return $err;
}

my $tz = 'Asia/Yakutsk';
my @walls = ('2026-11-17 22:00:00', '1999-12-31 23:59:59');

my $c = ch();
my $server_tz = $c->server_timezone // 'UTC';
q_ok($c, 'drop table if exists me_tz');
q_ok($c, 'create table me_tz (k UInt8, a DateTime, b DateTime64(3), c Array(DateTime), d Nullable(DateTime)) engine = Memory');

sub expected_epochs {
    my ($ch, $zone, @w) = @_;
    my @opt = defined $zone ? ({ session_timezone => $zone }) : ();
    my $sql = 'select ' . join(', ', map { "toUnixTimestamp(toDateTime('$_'))" } @w);
    return @{ q_ok($ch, $sql, @opt)->[0] };
}

for my $case ([server => undef], [session => $tz]) {
    my ($label, $zone) = @$case;
    my @opt = $zone ? ({ session_timezone => $zone }) : ();
    my @want = expected_epochs($c, $zone, @walls);
    q_ok($c, 'truncate table me_tz');
    my $k = 0;
    is(ins($c, 'me_tz (k, a, b, c, d)',
           [ map { [ $k++, $_, "$_.250", [$_], $_ ] } @walls ], @opt),
       undef, "$label tz: arrayref insert of wall-time strings");
    is(ins($c, 'me_tz (k, a, b, d)',
           "9\t$walls[0]\t$walls[0].250\t$walls[0]\n", @opt),
       undef, "$label tz: TabSeparated insert of wall-time strings");
    my $got = q_ok($c, 'select toUnixTimestamp(a), toUnixTimestamp(b), if(empty(c), 0, toUnixTimestamp(c[1])), toUnixTimestamp(d) from me_tz order by k');
    is_deeply($got, [ (map { [ ($want[$_]) x 4 ] } 0 .. $#walls), [ ($want[0]) x 2, 0, $want[0] ] ],
              "$label tz: strings are wall time in the session timezone");

    my $d = ch(decode_datetime => 1);
    my $rows = q_ok($d, 'select a, b, c, d from me_tz where k < 9 order by k', @opt);
    is_deeply($rows, [ map { [ $_, "$_.250", [$_], $_ ] } @walls ],
              "$label tz: decode_datetime renders tz-less columns in it");
    is_deeply(q_ok($d, "select toDateTime('$walls[0]'), toDateTime64('$walls[0].5', 1)", @opt),
              [[ $walls[0], "$walls[0].5" ]],
              "$label tz: decode_datetime of server-computed values");
    $d->finish;
}

{
    my $s = ch(settings => { session_timezone => $tz }, decode_datetime => 1);
    my @want = expected_epochs($s, $tz, $walls[0]);
    q_ok($s, 'truncate table me_tz');
    is(ins($s, 'me_tz (k, a, b, c, d)', [[1, $walls[0], $walls[0], [], undef]]), undef,
       'connection-level session_timezone: insert');
    is(q_ok($s, 'select toUnixTimestamp(a) from me_tz')->[0][0], $want[0],
       'connection-level session_timezone applies to inserts');
    is(q_ok($s, 'select a from me_tz')->[0][0], $walls[0],
       'connection-level session_timezone applies to decoding');
    my @srv = expected_epochs($s, '', $walls[0]);
    q_ok($s, 'truncate table me_tz');
    ins($s, 'me_tz (k, a, b, c, d)', [[1, $walls[0], $walls[0], [], undef]],
        { session_timezone => '' });
    is(q_ok($s, 'select toUnixTimestamp(a) from me_tz')->[0][0], $srv[0],
       'per-query empty session_timezone restores the server timezone');
    $s->finish;
}

{
    my $rows = q_ok($c, 'select toUnixTimestamp(t) from ext', {
        session_timezone => $tz,
        external => { ext => { structure => [t => 'DateTime'], data => [[$walls[0]]] } },
    });
    is($rows->[0][0], (expected_epochs($c, $tz, $walls[0]))[0],
       'external table DateTime strings use the session timezone');
}

{
    q_ok($c, 'drop table if exists me_dst');
    q_ok($c, q{create table me_dst (k UInt8, a DateTime('Europe/Berlin')) engine = Memory});
    my @w = ('2026-03-29 02:30:00', '2026-10-25 02:30:00', '2026-07-01 12:00:00');
    my $k = 0;
    is(ins($c, 'me_dst (k, a)', [ map { [ $k++, $_ ] } @w ]), undef, 'DST: insert');
    my $want = q_ok($c, 'select ' . join(', ',
        map { "toUnixTimestamp(toDateTime('$_', 'Europe/Berlin'))" } @w))->[0];
    my $got = [ map { $_->[0] } @{ q_ok($c, 'select toUnixTimestamp(a) from me_dst order by k') } ];
    is_deeply($got, $want, 'DST gap and fold resolve as on the server');
    q_ok($c, 'drop table me_dst');
}

q_ok($c, 'drop table me_tz');
$c->finish;

{
    my $warm = ch();
    q_ok($warm, 'select 1');
    select undef, undef, undef, 1.5;
    my $late = ch(connect_timeout => 1);
    my ($res, $err) = wait_for(sub { $late->query('select 1', $_[0]) });
    is($err, undef, 'connect_timeout counts from now after blocking work');
    select undef, undef, undef, 1.5;
    ($res, $err) = wait_for(sub { $warm->query('select sleep(0.3)', { query_timeout => 1 }, $_[0]) });
    is($err, undef, 'query_timeout counts from now after blocking work');
    $_->finish for $warm, $late;
}

done_testing;
