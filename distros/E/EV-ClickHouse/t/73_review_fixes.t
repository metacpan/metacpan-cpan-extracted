use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;

my $host = $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1';
my $port = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

require IO::Socket::INET;
plan skip_all => "ClickHouse native port not reachable"
    unless IO::Socket::INET->new(PeerAddr => $host, PeerPort => $port, Timeout => 2);

sub ch { EV::ClickHouse->new(host => $host, port => $port, protocol => 'native',
                             on_error => sub { diag("error: $_[0]") }, @_) }

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
    my ($c, $sql, @opt) = @_;
    my ($res, $err) = wait_for(sub { $c->query($sql, @opt, $_[0]) });
    die "$sql: $err" if $err;
    return $res;
}

sub ins {
    my ($c, $table, $data, @opt) = @_;
    my (undef, $err) = wait_for(sub { $c->insert($table, $data, @opt, $_[0]) });
    return $err;
}

my $c = ch();

{
    q_ok($c, 'drop table if exists rf_en');
    q_ok($c, q{create table rf_en (k UInt8, a Nullable(Enum8('a' = 1, 'b' = 2))) engine = Memory});
    is(ins($c, 'rf_en', [[1, undef], [2, 'b']]), undef,
       'NULL in Nullable(Enum) without a 0 code: arrayref');
    is(ins($c, 'rf_en', "3\t\\N\n"), undef,
       'NULL in Nullable(Enum) without a 0 code: TabSeparated');
    is_deeply(q_ok($c, 'select k, toString(a) from rf_en order by k'),
              [[1, undef], [2, 'b'], [3, undef]], 'NULL enums stored');
}

{
    q_ok($c, 'drop table if exists rf_esc');
    q_ok($c, q{create table rf_esc (k UInt8, e Enum8('a\n' = 1, 'a\\\\n' = 2)) engine = Memory});
    is(ins($c, 'rf_esc', "1\ta\\n\n2\ta\\\\n\n"), undef, 'TSV enum labels with escapes');
    is_deeply(q_ok($c, 'select k, toInt8(e) from rf_esc order by k'), [[1, 1], [2, 2]],
              'escaped TSV field matches the decoded label only');
}

{
    my $type = q{Tuple(Enum8(')' = 1, ',' = 2), LowCardinality(String))};
    q_ok($c, 'drop table if exists rf_paren');
    q_ok($c, "create table rf_paren (t $type) engine = Memory");
    is(ins($c, 'rf_paren', [[[')', 'p']], [[',', 'q']]]), undef,
       'enum labels with parens/commas inside a tuple: insert');
    is_deeply(q_ok($c, 'select toString(t) from rf_paren order by tupleElement(t, 2)'),
              [[q{(')','p')}], [q{(',','q')}]], 'stored');
    my $d = ch(decode_enum => 1);
    is_deeply(q_ok($d, 'select t from rf_paren order by tupleElement(t, 2)'),
              [[[')', 'p']], [[',', 'q']]], 'and decoded');
    $d->finish;
}

SKIP: {
    my (undef, $no_json) = wait_for(sub {
        $c->query(q{select cast('{"a":"x"}' as JSON(a LowCardinality(String)))}, $_[0]) });
    skip 'server has no typed JSON', 1 if $no_json;
    my $rows = q_ok($c, 'select count() from ext', {
        external => { ext => { structure => [j => 'JSON(a LowCardinality(String))', n => 'UInt8'],
                               data => [] } },
    });
    is_deeply($rows, [[0]], 'empty external table with a JSON column');
}

{
    package TiedSettings;
    require Tie::Hash;
    our @ISA = ('Tie::StdHash');
}
{
    tie my %s, 'TiedSettings';
    %s = (data_format => 'CSV');
    q_ok($c, 'drop table if exists rf_tie');
    q_ok($c, 'create table rf_tie (a UInt8, b UInt8) engine = Memory');
    is(ins($c, 'rf_tie', "1,2\n", \%s), undef, 'data_format from a tied settings hash');
    is_deeply(q_ok($c, 'select a, b from rf_tie'), [[1, 2]], 'parsed as CSV');
}

{
    my %conn = (session_timezone => 'Asia/Yakutsk');
    my $z = ch(settings => \%conn, decode_datetime => 1);
    q_ok($z, 'select 1');
    my ($res, $err, $done);
    $z->query(q{select toDateTime('2026-01-01 09:00:00')}, sub { ($res, $err) = @_; $done = 1; EV::break });
    $conn{session_timezone} = 'UTC';
    my $guard = EV::timer(15, 0, sub { $err //= 'timed out'; EV::break });
    EV::run until $done || $err;
    is_deeply($res, [['2026-01-01 09:00:00']],
              'decoding uses the timezone the query was sent with');
    $z->finish;
}

{
    package DropConn;
    use overload '""' => sub { my $s = shift; undef ${ $s->{conn} }; '7' }, fallback => 1;
}
{
    q_ok($c, 'drop table if exists rf_drop');
    q_ok($c, 'create table rf_drop (a UInt8, b UInt8) engine = Memory');
    my $d = ch();
    q_ok($d, 'select 1');
    my ($err, $done);
    my $dflt = bless { conn => \$d }, 'DropConn';
    $d->insert('rf_drop', [[1, undef]], { defaults => { b => $dflt } },
               sub { $err = $_[1]; $done = 1; EV::break });
    my $guard = EV::timer(10, 0, sub { $done = 1; EV::break });
    EV::run until $done;
    ok(!defined $d, 'a defaults value dropping the last connection reference does not crash');
}

q_ok($c, "drop table if exists $_") for qw(rf_en rf_esc rf_paren rf_tie rf_drop);
$c->finish;
done_testing;
