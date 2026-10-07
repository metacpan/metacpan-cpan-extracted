use strict;
use warnings;
use Test::More;
use Test::RedisServer;
use File::Temp qw(tempfile);

# A callback's exception is reported with warn(); a $SIG{__WARN__} that dies
# must not unwind through hiredis, which would leave the connection wedged.

my $redis_server;
eval {
    $redis_server = Test::RedisServer->new;
} or plan skip_all => 'redis-server is required to this test';

my %connect_info = $redis_server->connect_info;
my $sock = $connect_info{sock};

use EV;
use EV::Redis;
use lib 't/lib';
use RedisTestHelper qw(get_redis_version);

my ($redis_version) = get_redis_version($sock);

$SIG{PIPE} = 'IGNORE';

sub with_fatal_warnings {
    my ($code, $hook) = @_;
    my ($fh) = tempfile(UNLINK => 1);
    open my $saved, '>&', \*STDERR or die "dup STDERR: $!";
    open STDERR, '>&', $fh or die "redirect STDERR: $!";
    my $died;
    {
        local $SIG{__WARN__} = $hook // sub { die "fatal: $_[0]" };
        eval { $code->(); 1 } or $died = $@;
    }
    open STDERR, '>&', $saved or die "restore STDERR: $!";
    seek $fh, 0, 0;
    my $stderr = do { local $/; <$fh> };
    return ($died, $stderr);
}

sub run_loop {
    my $g = EV::timer 3, 0, sub { EV::break };
    EV::run;
}

sub pings_ok {
    my ($r, $name) = @_;
    my $res = 'no reply';
    eval {
        $r->ping(sub { $res = $_[0] // "error: $_[1]"; EV::break });
        run_loop();
        1;
    } or $res = "croaked: $@";
    is $res, 'PONG', $name;
}

sub kill_clients {
    my $k = EV::Redis->new(path => $sock);
    $k->client('kill', 'type', 'normal', 'skipme', 'yes', sub { $k->disconnect });
}

sub reconnect_ok {
    my ($r, $name) = @_;
    ok eval { $r->connect_unix($sock); 1 }, "$name: connects again"
        or diag $@;
    pings_ok($r, "$name: the new connection works");
}

{
    my $r = EV::Redis->new(path => $sock);
    my ($died, $stderr) = with_fatal_warnings(sub {
        $r->ping(sub { die "callback bug\n" });
        $r->ping(sub { EV::break });
        run_loop();
    });
    is $died, undef, 'reply callback: the warn handler die stays inside the loop';
    like $stderr, qr/^EV::Redis: exception in command callback: callback bug\nEV::Redis: reporting it died: fatal: EV::Redis: exception in command callback: callback bug\n/m,
        'reply callback: both exceptions are printed';
    pings_ok($r, 'reply callback: the connection still works');
    $r->disconnect;
}

{
    my $r = EV::Redis->new(path => $sock);
    my $called = 0;
    my $connected;
    $r->ping(sub { $connected = 1; EV::break });
    run_loop();
    my ($died) = with_fatal_warnings(sub {
        $r->ping(sub { $called++; die "skipped bug\n" }) for 1 .. 2;
        $r->skip_pending;
    });
    ok $connected, 'skip_pending: connected';
    is $died, undef, 'skip_pending: the warn handler die does not escape';
    is $called, 2, 'skip_pending: every skipped callback is called';
    pings_ok($r, 'skip_pending: the connection still works');
    $r->disconnect;
}

{
    my $r = EV::Redis->new(path => $sock, on_disconnect => sub { EV::break });
    my ($died) = with_fatal_warnings(sub {
        $r->ping(sub { kill_clients() });
        run_loop();
    });
    is $died, undef, 'default on_error: the warn handler die stays inside the loop';
    $r->on_disconnect(undef);
    reconnect_ok($r, 'default on_error');
    $r->disconnect;
}

{
    my $r;
    my ($died, $stderr) = with_fatal_warnings(sub {
        $r = EV::Redis->new(path => $sock, on_connect => sub { die "connect bug\n" });
        $r->ping(sub { EV::break });
        run_loop();
    }, sub { die "no warnings allowed\n" });
    is $died, undef, 'on_connect: the warn handler die stays inside the loop';
    like $stderr, qr/^EV::Redis: exception in connect handler: connect bug\nEV::Redis: reporting it died: no warnings allowed\n/m,
        'on_connect: the exception is printed along with what the warn handler died with';
    pings_ok($r, 'on_connect: the connection still works');
    $r->disconnect;
}

{
    my $r = EV::Redis->new(path => $sock, on_error => sub { EV::break },
        on_disconnect => sub { die "disconnect bug\n" });
    my ($died) = with_fatal_warnings(sub {
        $r->ping(sub { kill_clients() });
        run_loop();
    });
    is $died, undef, 'on_disconnect: the warn handler die stays inside the loop';
    $r->on_disconnect(undef);
    reconnect_ok($r, 'on_disconnect');
    $r->disconnect;
}

SKIP: {
    skip 'RESP3 push needs Redis >= 6', 2 if $redis_version < 6;

    my $r = EV::Redis->new(path => $sock);
    my $r2 = EV::Redis->new(path => $sock);
    my $tracking;
    my ($died) = with_fatal_warnings(sub {
        $r->on_push(sub { die "push bug\n" });
        $r->hello(3, sub {
            return EV::break if $_[1];
            $r->command('client', 'tracking', 'on', 'bcast', sub {
                return EV::break if $_[1];
                $tracking = 1;
                $r2->set('warn_hook_die:key', 1, sub {
                    $r->ping(sub { EV::break });
                });
            });
        });
        run_loop();
    });
    skip 'RESP3 client tracking not available', 2 unless $tracking;
    is $died, undef, 'on_push: the warn handler die stays inside the loop';
    pings_ok($r, 'on_push: the connection still works');
    $r->disconnect;
    $r2->disconnect;
}

{
    package TestGuard;
    sub new { my ($class, $cb) = @_; bless { cb => $cb }, $class }
    sub DESTROY { $_[0]{cb}->() }
}

{
    my $freed = 0;
    my $r = EV::Redis->new;
    {
        my $guard = TestGuard->new(sub { $freed++ });
        $r->on_error(sub { $guard });
    }
    my ($died) = with_fatal_warnings(sub { $r->on_error('not code') });
    like $died, qr/^fatal: EV::Redis: handler is not a code reference/,
        'setter: the warn handler die reaches the caller';
    is $freed, 0, 'setter: the old handler stays';
    $r->on_error(undef);
    is $freed, 1, 'setter: the old handler is released';
}

done_testing;
