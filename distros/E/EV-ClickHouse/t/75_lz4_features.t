use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;

# EVCH-3: LZ4 is bundled, and the build reports its capabilities.
# Class-level feature assertions need no server; the round-trip below
# exercises the bundled codec against a live native endpoint.

my $host = $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1';
my $nport = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

require IO::Socket::INET;
my $nat_ok = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $nport, Timeout => 2) ? 1 : 0;

plan tests => 10;

my $f = EV::ClickHouse->features;
is(ref $f, 'HASH', 'features returns a hashref');
is($f->{lz4}, 1, 'lz4 bundled: features reports 1');
ok(defined $f->{tls} && ($f->{tls} == 0 || $f->{tls} == 1),
    'features reports tls as 0 or 1');
is(EV::ClickHouse->has_lz4, 1, 'has_lz4 is 1');
is(EV::ClickHouse->has_tls, $f->{tls}, 'has_tls matches features');

SKIP: {
    skip "ClickHouse native port not reachable at $host:$nport", 5 unless $nat_ok;

    my @warn;
    my ($ch, $err);
    {
        local $SIG{__WARN__} = sub { push @warn, @_ };
        $ch = EV::ClickHouse->new(
            host       => $host,
            port       => $nport,
            protocol   => 'native',
            compress   => 1,
            on_connect => sub { EV::break },
            on_error   => sub { $err = $_[0]; EV::break },
        );
    }
    my $t = EV::timer(10, 0, sub { $err //= 'connect timeout'; EV::break });
    EV::run;
    undef $t;
    ok(!$err, 'compressed connect: no error') or diag $err;
    is_deeply($ch->features, $f, 'instance features matches class features');
    ok(!@warn, 'compress honoured: no warning') or diag "@warn";

    my $tbl = "lz_feat_$$";
    my ($rows, $qerr, $phase);
    $ch->query("create table $tbl (a UInt32, b String) engine = Memory", sub {
        my (undef, $e) = @_;
        if ($e) { $phase = "create: $e"; return EV::break }
        $ch->insert($tbl, [[10, 'alpha'], [20, 'beta']], sub {
            my (undef, $e2) = @_;
            if ($e2) { $phase = "insert: $e2"; return EV::break }
            $ch->query("select a, b from $tbl order by a", sub {
                ($rows, $qerr) = @_;
                $ch->query("drop table $tbl", sub { EV::break });
            });
        });
    });
    $t = EV::timer(15, 0, sub { $phase //= 'timeout'; EV::break });
    EV::run;
    undef $t;
    $ch->finish if $ch->is_connected;
    ok(!$phase && !$qerr, 'compressed round-trip: no error')
        or diag($phase // $qerr // 'undef');
    is_deeply($rows, [[10, 'alpha'], [20, 'beta']],
        'compressed round-trip: rows intact');
}
