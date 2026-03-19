use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;

my $host = $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1';
my $port = $ENV{TEST_CLICKHOUSE_PORT} || 8123;

my $reachable = 0;
eval {
    require IO::Socket::INET;
    my $s = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $port, Timeout => 2);
    $reachable = 1 if $s;
};
plan skip_all => "ClickHouse not reachable at $host:$port" unless $reachable;

plan tests => 4;

my $ch;

sub with_ch {
    my (%args) = @_;
    my $cb = delete $args{cb};
    $ch = EV::ClickHouse->new(
        host       => $host,
        port       => $port,
        session_id => "test_insert_$$",
        on_connect => sub { $cb->() },
        on_error   => sub {
            diag("Error: $_[0]");
            EV::break;
        },
        %args,
    );
    my $timeout = EV::timer(10, 0, sub { EV::break });
    EV::run;
    $ch->finish if $ch && $ch->is_connected;
}

# Test 1-4: insert and verify
with_ch(cb => sub {
    $ch->q("create table if not exists test_ev_insert (id UInt32, name String) engine = Memory", sub {
        my ($r, $e) = @_;
        die "create: $e" if $e;

        $ch->insert("test_ev_insert", "1\talpha\n2\tbeta\n3\tgamma\n", sub {
            my ($ok, $e2) = @_;
            ok(!$e2, 'insert: no error');

            $ch->q("select id, name from test_ev_insert order by id format TabSeparated", sub {
                my ($rows, $e3) = @_;
                ok(!$e3, 'select after insert: no error');
                is(scalar @$rows, 3, 'select after insert: 3 rows');
                is_deeply($rows, [
                    ['1', 'alpha'],
                    ['2', 'beta'],
                    ['3', 'gamma'],
                ], 'select after insert: correct data');

                $ch->q("drop table test_ev_insert", sub { EV::break });
            });
        });
    });
});
