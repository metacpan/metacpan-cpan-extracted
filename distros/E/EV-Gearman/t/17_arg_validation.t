# Argument-validation croaks. No gearmand needed — these all fail
# before any I/O.
use strict;
use warnings;
use Test::More;
use EV::Gearman;

# new()
eval { EV::Gearman->new('host') };
like $@, qr/odd number of arguments/, 'new: odd args croak';

eval { EV::Gearman->new(host => '127.0.0.1', path => '/tmp/x') };
like $@, qr/cannot specify both 'host' and 'path'/, 'new: host+path conflict croak';

# new() croaks on unknown keys — a typo must not silently disable the
# intended option
{
    eval { EV::Gearman->new(reconect => 1) };
    like $@, qr/unknown constructor option 'reconect'/,
        'new: typo key croaks, naming the key';
    eval { EV::Gearman->new(command_timeout => 100, bogus_key => 1) };
    like $@, qr/unknown constructor option 'bogus_key'/,
        'new: unknown key croaks even among valid keys';

    # every documented key is still accepted — the croak must not be
    # over-eager
    my $g = EV::Gearman->new(
        on_error              => sub {},
        on_connect            => sub {},
        on_disconnect         => sub {},
        connect_timeout       => 100,
        command_timeout       => 100,
        priority              => 1,
        keepalive             => 0,
        reconnect             => 1,
        reconnect_delay       => 100,
        max_reconnect_attempts => 2,
        exceptions            => 1,
        client_id             => 't17',
        grab_unique           => 1,
        loop                  => EV::default_loop,
    );
    ok $g, 'all non-connect documented keys accepted';
    my $g2 = EV::Gearman->new(host => '127.0.0.1', port => 4730, on_error => sub {});
    ok $g2, 'host/port accepted';
    my $g3 = EV::Gearman->new(path => '/tmp/nonexistent-ev-gearman.sock',
                              on_error => sub {});
    ok $g3, 'path accepted';
}

# register_function requires a coderef
{
    my $g = EV::Gearman->new;
    eval { $g->register_function('f') };
    like $@, qr/callback required/, 'register_function: missing cb croak';
    eval { $g->register_function('f', 'not-a-coderef') };
    like $@, qr/unexpected argument/, 'register_function: non-coderef croak';
}

# grab_job() with no args is an XS-level usage error. (Its coderef
# check sits behind the connection check, so the non-coderef croak
# isn't reachable on an unconnected client — not worth a live server
# here.)
{
    my $g = EV::Gearman->new;
    eval { $g->grab_job() };
    like $@, qr/Usage|callback required/, 'grab_job: missing cb croak';
}

# reconnect setter needs the enable arg
{
    my $g = EV::Gearman->new;
    eval { $g->reconnect() };
    like $@, qr/enable arg required/, 'reconnect: missing enable croak';
}

# maxqueue Perl-layer guards (text-protocol injection surface)
{
    my $g = EV::Gearman->new;
    eval { $g->maxqueue('f') };
    like $@, qr/size/, 'maxqueue: missing size croak';
    eval { $g->maxqueue("f\nshutdown", 10) };
    like $@, qr/whitespace/, 'maxqueue: whitespace in function name croak';
    eval { $g->maxqueue('f', "10\nshutdown") };
    like $@, qr/non-negative integer/, 'maxqueue: injection via size croak';
    eval { $g->maxqueue(undef, 10) };
    like $@, qr/function name required/, 'maxqueue: undef func croak';
}

# connect_unix path length is bounded by sun_path (~108 bytes). This
# surfaces via on_error (not a croak), fired synchronously from the
# connect attempt.
{
    my $err;
    my $g = EV::Gearman->new(on_error => sub { $err = $_[0] });
    $g->connect_unix('/tmp/' . ('x' x 200));
    like $err, qr/path too long/, 'connect_unix: overlong path -> on_error';
}

# Payload over GM_MAX_PACKET (256 MiB) is rejected before any request
# is allocated. Needs one ~256 MiB transient scalar (a bounded single
# allocation, not list construction) and no gearmand: the object is
# "alive" (connecting) so the guard is reached, and the croak fires
# during the synchronous submit before any I/O.
{
    my $g = EV::Gearman->new(host => '127.0.0.1', port => 4730);
    my $huge = 'x' x (256 * 1024 * 1024 + 1);
    eval { $g->submit_job('f', $huge, sub {}) };
    like $@, qr/payload too large/, 'submit_job: oversized payload croaks';
    undef $huge;
    $g->reconnect(0);   # stop any reconnect attempts before teardown
}

# echo() takes the same arbitrary user payload and must have the same
# guard — parity with submit/epoch.
{
    my $g = EV::Gearman->new(host => '127.0.0.1', port => 4730);
    my $huge = 'x' x (256 * 1024 * 1024 + 1);
    eval { $g->echo($huge, sub {}) };
    like $@, qr/payload too large/, 'echo: oversized payload croaks';
    undef $huge;
    $g->reconnect(0);
}

# NUL bytes in function names and unique keys would silently reframe
# the NUL-separated SUBMIT body server-side (wrong route / dedup key /
# workload). Only the workload may contain NULs.
{
    my $g = EV::Gearman->new(host => '127.0.0.1', port => 1,
                             on_error => sub {});
    eval { $g->submit_job("re\0size", 'w', sub {}) };
    like $@, qr/NUL/, 'submit_job: NUL in function name croaks';
    eval { $g->submit_job('f', 'w', { unique => "bin\0ary" }, sub {}) };
    like $@, qr/NUL/, 'submit_job: NUL in unique key croaks';
    eval { $g->submit_job_bg("re\0size", 'w', sub {}) };
    like $@, qr/NUL/, 'submit_job_bg: NUL in function name croaks';
    eval { $g->submit_job_epoch("re\0size", 'w', time + 60, sub {}) };
    like $@, qr/NUL/, 'submit_job_epoch: NUL in function name croaks';
    eval { $g->submit_job_epoch('f', 'w', time + 60, { unique => "a\0b" }, sub {}) };
    like $@, qr/NUL/, 'submit_job_epoch: NUL in unique key croaks';
    # control: NUL in the workload is legal (length-delimited, last arg)
    eval { $g->submit_job_bg('f', "a\0b", sub {}) };
    is $@, '', 'submit_job_bg: NUL in workload accepted';
    $g->reconnect(0);
}

# Same NUL class on the worker side: the registry stores names via
# savepv (NUL-truncated) while the wire sends full bytes, so a NUL
# name could never match again (dup entries, un-removable, JOB_ASSIGN
# misses). SET_CLIENT_ID has the same store/send split.
{
    my $g = EV::Gearman->new;
    eval { $g->can_do("wo\0rk") };
    like $@, qr/NUL/, 'can_do: NUL in function name croaks';
    eval { $g->register_function("wo\0rk", sub {}) };
    like $@, qr/NUL/, 'register_function: NUL in function name croaks';
    eval { $g->set_client_id("id\0x") };
    like $@, qr/NUL/, 'set_client_id: NUL croaks';
    eval { $g->can_do('ok_name') };
    is $@, '', 'can_do: clean name accepted';
    my $g2 = eval {
        EV::Gearman->new(client_id => "bad\0id", on_error => sub {})
    };
    like $@, qr/NUL/, 'new: NUL in client_id croaks';
}

# A negative epoch (e.g. an overdue $when - time()) must not wrap to
# 2**32-1/2**64-1 and schedule the job eons out.
{
    my $g = EV::Gearman->new(host => '127.0.0.1', port => 1,
                             on_error => sub {});
    eval { $g->submit_job_epoch('f', 'w', -1, sub {}) };
    like $@, qr/epoch/i, 'submit_job_epoch: negative epoch croaks';
    eval { $g->submit_job_epoch('f', 'w', -0.5, sub {}) };
    like $@, qr/non-negative/, 'submit_job_epoch: negative fraction croaks';
    eval { $g->submit_job_epoch('f', 'w', undef, sub {}) };
    like $@, qr/non-negative/, 'submit_job_epoch: undef epoch croaks';
    eval { $g->submit_job_epoch('f', 'w', 'abc', sub {}) };
    like $@, qr/non-negative/, 'submit_job_epoch: non-numeric epoch croaks';
    eval { $g->submit_job_epoch('f', 'w', 0, sub {}) };
    is $@, '', 'submit_job_epoch: zero epoch accepted';
    $g->reconnect(0);
}

# admin() interpolates the command into the newline-delimited text
# protocol; an embedded newline would inject a second command and
# desync the reply framing. A single trailing newline stays legal.
{
    my $g = EV::Gearman->new(host => '127.0.0.1', port => 1,
                             on_error => sub {});
    eval { $g->admin("status\nshutdown", sub {}) };
    like $@, qr/newline/, 'admin: embedded newline croaks';
    eval { $g->admin("status\n", sub {}) };
    is $@, '', 'admin: trailing newline accepted';
    $g->reconnect(0);
}

# Constructor numeric options clamp exactly like their accessors —
# the getter must not depend on which path stored the value.
{
    my $g = EV::Gearman->new(priority => 99);
    is $g->priority, 2, 'new: priority 99 clamps to 2';
    my $g2 = EV::Gearman->new(priority => -99);
    is $g2->priority, -2, 'new: priority -99 clamps to -2';
    my $g3 = EV::Gearman->new(connect_timeout => -5, command_timeout => -5,
                              keepalive => -5);
    is $g3->connect_timeout, 0, 'new: negative connect_timeout clamps to 0';
    is $g3->command_timeout, 0, 'new: negative command_timeout clamps to 0';
    is $g3->keepalive, 0, 'new: negative keepalive clamps to 0';
}

# A non-coderef handler assignment must not silently clear the slot
# (ctor case also discards the default warn handler, so connection
# errors would go nowhere). Explicit undef still clears.
{
    my $g = EV::Gearman->new;
    ok ref($g->on_error) eq 'CODE', 'new: default on_error is a coderef';
    $g->on_error(sub { });
    $g->on_error('oops');
    ok ref($g->on_error) eq 'CODE', 'on_error: junk assignment keeps old handler';
    $g->on_error(undef);
    is $g->on_error, undef, 'on_error: undef still clears';
    my $g2 = EV::Gearman->new(on_error => 'x');
    ok ref($g2->on_error) eq 'CODE', 'new: junk on_error keeps default';
}

done_testing;
