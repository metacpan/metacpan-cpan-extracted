use strict;
use warnings;
use Test::More;
use EV;
use EV::Pg qw(:conn);
use lib 't';
use TestHelper;

require_pg;
plan tests => 11;

# Test 1: basic object creation
{
    my $pg = EV::Pg->new(on_error => sub {});
    ok(defined $pg, 'new without conninfo');
    is($pg->is_connected, 0, 'not connected yet');
}

# Test 2: connect
{
    my $connected = 0;

    my $pg = EV::Pg->new(
        conninfo   => $conninfo,
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
    is($pg->is_connected, 1, 'is_connected returns 1');
    ok($pg->backend_pid > 0, 'backend_pid is positive');

    is($pg->status, CONNECTION_OK, 'status is CONNECTION_OK');
    ok(defined $pg->db, 'db returns a value');

    $pg->finish;
}

# Test 3: connect to nonexistent database -- exercises PGRES_POLLING_FAILED
# after TCP succeeds (distinct from unreachable-host failure)
{
    my $err_msg;
    my $pg = EV::Pg->new(
        conninfo   => "$conninfo dbname=this_db_does_not_exist_xyz",
        on_connect => sub { EV::break },
        on_error   => sub { $err_msg = $_[0]; EV::break },
    );
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    ok(defined $err_msg, 'bad dbname: on_error fired');
    like($err_msg, qr/database|does not exist/i,
         'bad dbname: error mentions database');
}

# Test 3: reset while connecting (connecting == 1)
{
    my $connected = 0;
    my $pg;
    $pg = EV::Pg->new(
        conninfo => $conninfo,
        on_connect => sub {
            if (!$connected) {
                $connected = 1;
                # immediately reset — starts a new connect while just finished
                $pg->on_connect(sub {
                    ok($pg->is_connected, 'reset during connect: reconnected');
                    EV::break;
                });
                $pg->reset;
                return;
            }
        },
        on_error => sub { diag "Error: $_[0]"; EV::break },
    );
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    ok($connected, 'reset during connect: first connect succeeded');
    $pg->finish if $pg && $pg->is_connected;
}
