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

plan tests => 10;

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

# Test 1-2: simple select
with_ch(cb => sub {
    $ch->q("select 1, 'hello', 3.14 format TabSeparated", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'simple select: no error');
        is_deeply($rows, [['1', 'hello', '3.14']], 'simple select: correct data');
        EV::break;
    });
});

# Test 3-6: multi-row
with_ch(cb => sub {
    $ch->q("select number from numbers(5) format TabSeparated", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'multi-row: no error');
        is(scalar @$rows, 5, 'multi-row: 5 rows');
        is($rows->[0][0], '0', 'multi-row: first row');
        is($rows->[4][0], '4', 'multi-row: last row');
        EV::break;
    });
});

# Test 7-8: NULL handling
with_ch(cb => sub {
    $ch->q("select NULL format TabSeparated", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'NULL: no error');
        ok(!defined $rows->[0][0], 'NULL: value is undef');
        EV::break;
    });
});

# Test 9: empty result (format Null)
with_ch(cb => sub {
    $ch->q("select 1 format Null", sub {
        my ($rows, $err) = @_;
        ok(!$err, 'format Null: no error');
        EV::break;
    });
});

# Test 10: syntax error handling
with_ch(cb => sub {
    $ch->q("select from invalid syntax", sub {
        my ($rows, $err) = @_;
        ok($err, 'syntax error: got error');
        EV::break;
    });
});
