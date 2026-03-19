use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;

my $host = $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1';
my $port = $ENV{TEST_CLICKHOUSE_PORT} || 8123;

# check ClickHouse is reachable
my $reachable = 0;
eval {
    require IO::Socket::INET;
    my $s = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $port, Timeout => 2);
    $reachable = 1 if $s;
};
plan skip_all => "ClickHouse not reachable at $host:$port" unless $reachable;

plan tests => 8;

# Test 1-2: connect
{
    my $connected = 0;
    my $ch;
    $ch = EV::ClickHouse->new(
        host       => $host,
        port       => $port,
        on_connect => sub { $connected = 1; EV::break },
        on_error   => sub { diag("Error: $_[0]"); EV::break },
    );
    my $guard = EV::timer(5, 0, sub { EV::break });
    EV::run;
    ok($connected, 'connected to ClickHouse');
    ok($ch->is_connected, 'is_connected returns true');
    $ch->finish;
}

# Test 3: connect failure (port 1)
{
    my $err_msg;
    my $ch = EV::ClickHouse->new(
        host       => '127.0.0.1',
        port       => 1,
        on_connect => sub { EV::break },
        on_error   => sub { $err_msg = $_[0]; EV::break },
    );
    my $guard = EV::timer(5, 0, sub { EV::break });
    EV::run;
    ok($err_msg, 'connect failure: got error');
}

# Test 4: ping
{
    my $ping_ok;
    my $ch;
    $ch = EV::ClickHouse->new(
        host       => $host,
        port       => $port,
        on_connect => sub {
            $ch->ping(sub {
                my ($ok, $err) = @_;
                $ping_ok = !$err;
                EV::break;
            });
        },
        on_error => sub { diag("Error: $_[0]"); EV::break },
    );
    my $guard = EV::timer(5, 0, sub { EV::break });
    EV::run;
    ok($ping_ok, 'ping succeeded');
    $ch->finish if $ch && $ch->is_connected;
}

# Test 5-6: accessors (is_connected, pending_count)
{
    my $ch;
    $ch = EV::ClickHouse->new(
        host       => $host,
        port       => $port,
        on_connect => sub {
            ok($ch->is_connected, 'accessor: is_connected');
            is($ch->pending_count, 0, 'accessor: pending_count is 0');
            EV::break;
        },
        on_error => sub { diag("Error: $_[0]"); EV::break },
    );
    my $guard = EV::timer(5, 0, sub { EV::break });
    EV::run;
    $ch->finish if $ch && $ch->is_connected;
}

# Test 7: finish
{
    my $ch;
    $ch = EV::ClickHouse->new(
        host       => $host,
        port       => $port,
        on_connect => sub {
            $ch->finish;
            ok(!$ch->is_connected, 'finish: disconnected');
            EV::break;
        },
        on_error => sub { diag("Error: $_[0]"); EV::break },
    );
    my $guard = EV::timer(5, 0, sub { EV::break });
    EV::run;
}

# Test 8: reset
{
    my $reset_ok = 0;
    my $ch;
    $ch = EV::ClickHouse->new(
        host       => $host,
        port       => $port,
        on_connect => sub {
            if (!$reset_ok) {
                $reset_ok = 1;
                $ch->on_connect(sub {
                    $ch->q("select 1 format TabSeparated", sub {
                        my ($r, $e) = @_;
                        $reset_ok = 2 if !$e && $r->[0][0] eq '1';
                        EV::break;
                    });
                });
                $ch->reset;
            }
        },
        on_error => sub { diag("Error: $_[0]"); EV::break },
    );
    my $guard = EV::timer(5, 0, sub { EV::break });
    EV::run;
    is($reset_ok, 2, 'reset: reconnected and query works');
    $ch->finish if $ch && $ch->is_connected;
}
