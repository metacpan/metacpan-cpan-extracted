use strict;
use warnings;
use Test::More;
use EV;
use EV::Pg qw(:conn);
use lib 't';
use TestHelper;

require_pg;
plan tests => 16;

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

# Default on_error (die) is caught and demoted to warn; the process survives
{
    my $warned = '';
    local $SIG{__WARN__} = sub { $warned .= $_[0] };
    my $pg = EV::Pg->new(
        conninfo => "$conninfo dbname=this_db_does_not_exist_xyz",
    );
    my $t = EV::timer(5, 0, sub { EV::break });
    my $w = EV::timer(0.05, 0.05, sub { EV::break if $warned });
    EV::run;
    ok(1, 'default on_error: process survived failed connect');
    like($warned, qr/exception in error handler/,
         'default on_error: die demoted to warn');
}

# Unusable connection string croaks synchronously from connect
{
    eval { EV::Pg->new(
        conninfo => 'host=/tmp/ev_pg_nonexistent_socket_dir dbname=postgres',
        on_error => sub {},
    ) };
    like($@, qr/connection failed/,
         'bad socket dir: connect croaks synchronously');
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

# connect() from inside on_error croaks: the failed conn is still installed
# while the handler runs.  Timer-deferred connect (endpoint switching) works.
{
    my ($croak, $switched);
    my $pg;
    $pg = EV::Pg->new(
        conninfo => "$conninfo dbname=this_db_does_not_exist_xyz",
        on_connect => sub {
            $switched = 1;
            EV::break;
        },
        on_error => sub {
            return if $croak;
            $croak = eval { $pg->connect($conninfo); 'NO-CROAK' };
            $croak = "CROAK:$@" if $@;
            my $t; $t = EV::timer(0.1, 0, sub {
                undef $t;
                $pg->finish;
                $pg->connect($conninfo);
            });
        },
    );
    my $t = EV::timer(10, 0, sub { EV::break });
    EV::run;
    $pg->finish if $pg && $pg->is_connected;
    like($croak, qr/previous connection failed/,
        'connect in on_error: actionable croak (not "already connected")');
    ok($switched, 'connect in on_error: timer-deferred connect switches endpoints');
}
