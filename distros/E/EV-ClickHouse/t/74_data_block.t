use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;

my $host = $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1';
my $port = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

require IO::Socket::INET;
plan skip_all => 'ClickHouse native port not reachable'
    unless IO::Socket::INET->new(PeerAddr => $host, PeerPort => $port, Timeout => 2);

sub vu { my ($v) = @_; my $b = ''; do { my $c = $v & 127; $v >>= 7; $b .= chr($c | ($v ? 128 : 0)) } while $v; $b }
sub vstr { vu(length $_[0]) . $_[0] }
sub u64 { pack 'Q<', $_[0] }

# A Native-format block built by hand: UInt32, String, Nullable(Int32),
# Array(UInt8), LowCardinality(String) (keys version 1, HasAdditionalKeys).
my $n = 300;
my @ids  = 1 .. $n;
my @strs = map { 'x' x 40 . $_ } @ids;
my @lcs  = map { 'k' . ($_ % 3) } @ids;
my %slot = (k0 => 0, k1 => 1, k2 => 2);
my $block = vu(5) . vu($n)
    . vstr('id') . vstr('UInt32') . pack('V*', @ids)
    . vstr('s') . vstr('String') . join('', map { vstr($_) } @strs)
    . vstr('n') . vstr('Nullable(Int32)')
        . join('', map { $_ % 2 ? "\1" : "\0" } @ids) . pack('l<*', map { $_ % 2 ? 0 : -$_ } @ids)
    . vstr('a') . vstr('Array(UInt8)')
        . join('', map { u64(2 * $_) } @ids) . pack('C*', map { ($_ % 5, 1) } @ids)
    . vstr('l') . vstr('LowCardinality(String)')
        . u64(1) . u64(1 << 9) . u64(3) . join('', map { vstr("k$_") } 0 .. 2)
        . u64($n) . pack('C*', map { $slot{$_} } @lcs);

my $ddl = 'create table %s (id UInt32, s String, n Nullable(Int32), a Array(UInt8), l LowCardinality(String)) engine = Memory';
my $agg = 'select count(), sum(id), countIf(n is null), sum(n), sum(arraySum(a)), uniqExact(l), max(length(s)) from %s';
my $want = [[ $n, $n * ($n + 1) / 2, $n / 2, -(2 + $n) * $n / 4, (0 + 1 + 2 + 3 + 4) * $n / 5 + $n, 3, 43 ]];

sub wait_for {
    my ($start) = @_;
    my ($res, $err, $done);
    $start->(sub { ($res, $err) = @_; $done = 1; EV::break });
    EV::now_update;
    my $guard = EV::timer(15, 0, sub { $err //= 'timed out'; EV::break });
    EV::run until $done || $err;
    return ($res, $err);
}

my %recv;
for my $compress (0, 1) {
    my $ch = EV::ClickHouse->new(host => $host, port => $port, protocol => 'native',
                                 compress => $compress, on_error => sub { diag("error: $_[0]") });
    my $q = sub { my ($sql, @o) = @_; my ($r, $e) = wait_for(sub { $ch->query($sql, @o, $_[0]) }); die "$sql: $e" if $e; $r };
    my $ins = sub { my ($t, $d, $o) = @_; (wait_for(sub { $ch->insert($t, $d, $o, $_[0]) }))[1] };
    my $tag = "compress=$compress";
    my $t = "db_t$compress";
    $q->("drop table if exists $t");
    $q->(sprintf $ddl, $t);

    my $qid = "evch-t74-$compress-$$-" . int(rand 1e9);
    is($ins->($t, $block, { data_format => 'Native', data_block => 1, query_id => $qid }), undef,
       "$tag: Native block sent as Data");
    is_deeply($q->(sprintf $agg, $t), $want, "$tag: values intact");
    is($ins->($t, $block, { data_format => 'Native' }), undef, "$tag: same block inline");
    is($q->("select count() from $t")->[0][0], 2 * $n, "$tag: both inserted");
    eval { $q->('system flush logs') };
    my $rb = eval { $q->("select ProfileEvents['NetworkReceiveBytes'] from system.query_log "
                       . "where query_id = '$qid' and type = 'QueryFinish'") };
    $recv{$compress} = $rb && @$rb ? $rb->[0][0] : undef;

    my $nb = vu(1) . vu(1) . vstr('id') . vstr('Nullable(UInt32)') . "\1" . pack('V', 0);
    like($ins->("$t (id)", $nb, { data_format => 'Native', data_block => 1 }) // '',
         qr/does not match the table/, "$tag: type mismatch refused");
    like($ins->($t, 'garbage', { data_format => 'Native', data_block => 1 }) // '',
         qr/Native/, "$tag: malformed block refused");
    is($q->('select 1')->[0][0], 1, "$tag: connection still usable");
    ok(!eval { $ch->insert($t, "1\n", { data_format => 'CSV', data_block => 1 }, sub {}); 1 }
       && $@ =~ /data_block needs/, "$tag: data_block needs Native");
    $q->("drop table $t");
    $ch->finish;
}

SKIP: {
    skip 'query_log not available', 1 unless defined $recv{0} && defined $recv{1};
    cmp_ok($recv{1}, '<', $recv{0} / 2, "compressed Data block is smaller on the wire ($recv{1} vs $recv{0})");
}

done_testing;
