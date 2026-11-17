use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestMySQL;
use EV;
use EV::mysql;

# Test 1: basic object creation (no server needed)
{
    my $m = EV::mysql->new(on_error => sub {});
    ok(defined $m, 'new without connect');
    is($m->is_connected, 0, 'not connected yet');
}

if (!TestMySQL::server_available()) {
    done_testing;
    exit;
}

# Test 2: connect
{
    my $connected = 0;

    my $m = EV::mysql->new(
        TestMySQL::connect_args(),
        on_connect => sub {
            $connected = 1;
            EV::break;
        },
        on_error   => sub {
            diag("Connection error: $_[0]");
            EV::break;
        },
    );

    my $timeout = EV::timer(5, 0, sub { EV::break });
    EV::run;

    ok($connected, 'connected successfully');
    is($m->is_connected, 1, 'is_connected returns 1');
    ok($m->thread_id > 0, 'thread_id is positive');
    ok(defined $m->server_info, 'server_info returns a value');

    $m->finish;
}

done_testing;
