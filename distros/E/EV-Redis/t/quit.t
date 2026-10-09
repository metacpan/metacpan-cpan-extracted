use strict;
use warnings;
use Test::More;
use Test::RedisServer;

my $redis_server;
eval {
    $redis_server = Test::RedisServer->new;
} or plan skip_all => 'redis-server is required to this test';

my %connect_info = $redis_server->connect_info;

use EV;
use EV::Redis;

$SIG{PIPE} = 'IGNORE';

# Sending QUIT instead of disconnect() is reported as a lost connection ...
{
    my (@events, $qres, $qerr);
    my $r = EV::Redis->new(path => $connect_info{sock},
        on_error => sub { push @events, "error:$_[0]"; },
        on_disconnect => sub { push @events, 'disconnect'; EV::break; });
    $r->command('QUIT', sub { ($qres, $qerr) = @_; });
    my $guard = EV::timer 4, 0, sub { push @events, 'TIMEOUT'; EV::break };
    EV::run;
    is $qres, 'OK', 'QUIT is answered';
    is $qerr, undef, '... without error';
    is $r->is_connected, 0, 'the connection is gone';
    like $events[0] || '', qr/^error:Server closed the connection/,
        'QUIT is reported as a lost connection';
    is $events[1], 'disconnect', '... then on_disconnect runs';
    $r->disconnect;
}

# ... and reconnect connects again.
{
    my (@events, $qres, $ups);
    my $r = EV::Redis->new(path => $connect_info{sock},
        reconnect => 1, reconnect_delay => 100,
        on_error => sub { push @events, "error:$_[0]"; },
        on_connect => sub { $ups++; push @events, "connect#$ups"; EV::break if 2 == $ups; },
        on_disconnect => sub { push @events, 'disconnect'; });
    $r->command('QUIT', sub { $qres = $_[0]; });
    my $guard = EV::timer 4, 0, sub { push @events, 'TIMEOUT'; EV::break };
    EV::run;
    is $qres, 'OK', 'QUIT is answered';
    is_deeply \@events,
        ['connect#1', 'error:Server closed the connection', 'disconnect', 'connect#2'],
        'reconnect connects again after QUIT';
    my $pong;
    $r->ping(sub { $pong = $_[0]; EV::break });
    my $guard2 = EV::timer 4, 0, sub { EV::break };
    EV::run;
    is $pong, 'PONG', 'the reconnected connection works';
    $r->disconnect;
}

done_testing;
