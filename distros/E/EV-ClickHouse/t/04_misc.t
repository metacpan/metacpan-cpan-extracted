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

plan tests => 8;

my $ch;

sub with_ch {
    my (%args) = @_;
    my $cb = delete $args{cb};
    $ch = EV::ClickHouse->new(
        host       => $host,
        port       => $port,
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

# Test 1-2: sequential queries (queue)
with_ch(cb => sub {
    my $done = 0;
    my @results;
    for my $i (1..3) {
        $ch->q("select $i format TabSeparated", sub {
            my ($r, $e) = @_;
            push @results, $r->[0][0];
            $done++;
            if ($done == 3) {
                is_deeply(\@results, ['1', '2', '3'], 'sequential: correct order');
                is($ch->pending_count, 0, 'sequential: pending_count is 0');
                EV::break;
            }
        });
    }
});

# Test 3-4: gzip compression
with_ch(
    compress => 1,
    cb => sub {
        $ch->q("select number from numbers(100) format TabSeparated", sub {
            my ($rows, $err) = @_;
            ok(!$err, 'gzip: no error');
            is(scalar @$rows, 100, 'gzip: 100 rows');
            EV::break;
        });
    },
);

# Test 5-6: session_id
with_ch(
    session_id => "test_misc_$$",
    cb => sub {
        $ch->q("set max_threads = 1", sub {
            my ($r, $e) = @_;
            die "set: $e" if $e;
            $ch->q("select getSetting('max_threads') format TabSeparated", sub {
                my ($r2, $e2) = @_;
                ok(!$e2, 'session: no error');
                is($r2->[0][0], '1', 'session: setting persisted');
                EV::break;
            });
        });
    },
);

# Test 7: skip_pending
with_ch(cb => sub {
    my $called = 0;
    my $got_err = 0;
    for my $i (1..5) {
        $ch->q("select $i format TabSeparated", sub {
            $called++;
            $got_err++ if $_[1];
        });
    }
    $ch->skip_pending;
    # all callbacks should have been called with error
    is($called, 5, 'skip_pending: all 5 callbacks invoked');
    is($got_err, 5, 'skip_pending: all callbacks received error');
    EV::break;
});
