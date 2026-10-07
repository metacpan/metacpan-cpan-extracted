use strict;
use warnings;
use Test::More;
use Test::RedisServer;
use Test::TCP qw(empty_port);
use IO::Socket::INET;
use Scalar::Util qw(weaken);
use EV;
use EV::Redis;

$SIG{PIPE} = 'IGNORE';

my $redis_server;
eval {
    $redis_server = Test::RedisServer->new;
} or plan skip_all => 'redis-server is required to this test';

my %connect_info = $redis_server->connect_info;
# timers count from the loop's clock, last read before the server started
EV::now_update;

# failed-connect cases need an async refusal; FreeBSD may refuse inside connect()
my $sync_refusal = 'loopback connect refused synchronously';

{
    my @cb;
    my $r = EV::Redis->new(path => $connect_info{sock});
    $r->on_error(sub {});

    $r->command('ping', sub {
        my ($res, $err) = @_;
        is($res, 'PONG', 'deferred disconnect: connected');

        my $w; $w = EV::timer 0.01, 0, sub {
            undef $w;
            # outside any hiredis callback
            $r->command('ping', sub { push @cb, [@_] });
            $r->disconnect;
            undef $r;
        };
    });

    my $guard = EV::timer 3, 0, sub { EV::break };
    EV::run;

    is(scalar @cb, 1, 'deferred disconnect: in-flight callback invoked exactly once');
    ok(!defined $cb[0][0], 'deferred disconnect: no result after destruction');
    ok(defined $cb[0][1], 'deferred disconnect: got error string');
}
pass('survived DESTROY after deferred disconnect with in-flight command');

# the new context is freed while the draining old one keeps its cbts
{
    my @cb;
    my $connected = 0;
    my $r = EV::Redis->new(path => $connect_info{sock});
    $r->on_error(sub {});
    $r->on_connect(sub { $connected++ });

    $r->command('ping', sub {
        my ($res, $err) = @_;

        my $w; $w = EV::timer 0.01, 0, sub {
            undef $w;
            $r->command('ping', sub { push @cb, [@_] });
            $r->disconnect;
            $r->connect_unix($connect_info{sock});
            undef $r;
        };
    });

    my $guard = EV::timer 3, 0, sub { EV::break };
    EV::run;

    is(scalar @cb, 1, 'disconnect+reconnect+destroy: old in-flight callback invoked once');
    ok(defined $cb[0][1], 'disconnect+reconnect+destroy: got error string');
}
pass('survived DESTROY after disconnect+connect with old context draining');

# hiredis fires pending reply callbacks only after connect_cb returns
SKIP: {
    my @cb;
    my $errors = 0;
    my $port = empty_port();

    my $r = EV::Redis->new;
    $r->on_error(sub {
        $errors++;
        undef $r;
    });
    $r->connect('127.0.0.1', $port);
    skip $sync_refusal, 4 unless $r;
    $r->command('ping', sub { push @cb, [@_] });

    my $guard = EV::timer 3, 0, sub { EV::break };
    EV::run;

    ok($errors >= 1, 'connect failure: on_error fired');
    is(scalar @cb, 1, 'connect failure: pending callback invoked exactly once');
    ok(!defined $cb[0][0], 'connect failure: no result');
    ok(defined $cb[0][1], 'connect failure: got error string');
}
pass('survived DESTROY inside on_error during failed connect with pending command');

# the context must be tracked for draining once, not twice
SKIP: {
    my @cb;
    my $port = empty_port();
    for my $round (1, 2) {
        my $r = EV::Redis->new;
        $r->on_error(sub {});
        $r->connect('127.0.0.1', $port);
        skip $sync_refusal, 2 unless $r->is_connected;
        $r->command('ping', sub { push @cb, [@_] });
        $r->disconnect;
        my $guard = EV::timer 2, 0, sub { EV::break };
        EV::run;
        undef $r;
    }
    is scalar @cb, 2, 'double-track guard: each round invoked its callback once';
    ok defined $cb[0][1] && defined $cb[1][1], 'double-track guard: callbacks got errors';
}
pass('survived disconnect-while-connecting followed by connect failure, twice');

{
    my $srv2 = Test::RedisServer->new;
    my %ci2 = $srv2->connect_info;
    EV::now_update;
    my $reconnected_alive = 0;
    my $pong2;

    my $r = EV::Redis->new(path => $ci2{sock});
    $r->on_error(sub {});
    $r->command('ping', sub {
        my $w; $w = EV::timer 0.01, 0, sub {
            undef $w;
            $r->on_disconnect(sub {
                $r->on_disconnect(undef);
                $r->connect_unix($ci2{sock});
            });
            $r->disconnect;   # synchronous: idle, outside hiredis callbacks
            $reconnected_alive = $r->is_connected;
            $r->ping(sub { $pong2 = $_[0]; EV::break });
        };
    });
    my $guard = EV::timer 3, 0, sub { EV::break };
    EV::run;

    is $reconnected_alive, 1, 'reconnect-in-on_disconnect: still connected after disconnect()';
    is $pong2, 'PONG', 'reconnect-in-on_disconnect: new connection works';
    $r->disconnect;
}
pass('survived reconnect inside on_disconnect');

# the FREED path must free the persist cbt on the last channel
SKIP: {
    my (@ping_cb, @sub_cb);
    my $port = empty_port();
    my $srv3 = Test::RedisServer->new;
    my %ci3 = $srv3->connect_info;
    EV::now_update;

    my $r = EV::Redis->new;
    $r->on_error(sub {});
    $r->connect('127.0.0.1', $port);
    skip $sync_refusal, 3 unless $r->is_connected;
    $r->command('ping', sub {
        push @ping_cb, [@_];
        undef $r;
    });
    $r->disconnect;
    $r->connect_unix($ci3{sock});
    $r->command('subscribe', 'lk_ch1', 'lk_ch2', sub { push @sub_cb, [@_] });

    my $guard = EV::timer 3, 0, sub { EV::break };
    EV::run;

    is scalar @ping_cb, 1, 'persist-leak: trailing ping callback fired once';
    ok defined $ping_cb[0][1], 'persist-leak: ping got error';
    my @sub_errors = grep { defined $_->[1] } @sub_cb;
    ok scalar(@sub_errors) <= 1, 'persist-leak: subscribe error callback at most once';
}
pass('survived DESTROY-in-trailing-callback with subscribed replacement connection');

# each teardown must untrack its own context, not the other one
SKIP: {
    my $srv = IO::Socket::INET->new(
        Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0,
    ) or die "listen: $!";
    for my $drop (0, 1) {
        my $r = EV::Redis->new;
        $r->on_error(sub {});
        $r->connect('127.0.0.1', empty_port());
        skip $sync_refusal, 2 unless $r->is_connected;
        my $fired;
        $r->command('ping', sub {
            $r->connect('127.0.0.1', $srv->sockport);
            $r->disconnect;
            undef $r if $drop;
            $fired = 1;
            EV::break;
        });
        my $guard = EV::timer 2, 0, sub { EV::break };
        EV::run;
        ok $fired, 'connect + disconnect in a failed connect\'s callback'
            . ($drop ? ', then DESTROY' : '');
    }
}

SKIP: {
    my ($r, $id);
    $r = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    $r->command('BLPOP', 'dd_nokey', 5, sub {});
    $r->disconnect;
    $r->connect_unix($connect_info{sock});
    $r->command('CLIENT', 'ID', sub { $id = $_[0]; EV::break });
    my $t = EV::timer 2, 0, sub { EV::break };
    EV::run;
    undef $t;
    skip 'CLIENT ID not supported', 1 unless $id;
    $r->on_error(sub { undef $r; EV::break });
    my $helper = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    $helper->command('CLIENT', 'KILL', 'ID', $id, sub {});
    my $guard = EV::timer 5, 0, sub { EV::break };
    EV::run;
    ok !defined $r, 'DESTROY in on_error with an older connection draining';
    $helper->disconnect;
}

{
    my $r;
    $r = EV::Redis->new(path => $connect_info{sock}, max_pending => 1, on_error => sub {});
    $r->command('BLPOP', 'dd_nokey', 5, sub {});
    $r->disconnect;
    $r->connect_unix($connect_info{sock});
    $r->command('PING', sub {});
    $r->command('GET', 'dd_w', sub { undef $r });
    $r->skip_pending;
    ok !defined $r, 'DESTROY in a skip_pending callback with an older connection draining';
}

# DESTROY's callbacks run a nested loop while an older connection drains
{
    my ($r, $n, $nested, $hit) = (undef, 0, 0);
    $r = EV::Redis->new(on_error => sub {});
    $r->on_connect(sub {
        return if $n++;
        $r->blpop('dd_n1', 1, sub { $hit = $nested; EV::break });
        $r->disconnect;
        $r->connect_unix($connect_info{sock});
    });
    $r->connect_unix($connect_info{sock});
    my $t = EV::timer 0.1, 0, sub {
        $r->blpop('dd_n2', 5, sub {
            $nested = 1;
            my $w = EV::timer 3, 0, sub { EV::break };
            EV::run;
            $nested = 0;
            EV::break;
        });
        $r->on_connect(undef);
        undef $r;
    };
    my $guard = EV::timer 5, 0, sub { EV::break };
    EV::run;
    ok !defined $r, 'DESTROY with a nested loop in a callback while an older connection drains';
    ok $hit, 'the draining reply arrived inside the nested loop';
}

# disconnect() again from a callback run by disconnect()'s own teardown
{
    my ($r, $err);
    $r = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    $r->subscribe('dd_twice', sub {
        if (defined $_[1]) { $err = $_[1]; $r->disconnect; return }
        EV::break;
    });
    my $guard = EV::timer 3, 0, sub { EV::break };
    EV::run;
    $r->disconnect;
    undef $r;
    is $err, 'disconnected', 'disconnect() from its own teardown, then DESTROY';
}

# DESTROY's callbacks reach the object through a weak ref
{
    my $r = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    weaken(my $w = $r);
    my @got;
    $r->max_pending(1);
    $r->ping(sub { push @got, $_[1] });
    $r->ping(sub { push @got, $_[1]; $w->skip_waiting if $w });
    undef $r;
    is_deeply \@got, ['disconnected', 'disconnected'],
        'skip_waiting through a weak ref during DESTROY';
}
{
    my $r = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    weaken(my $w = $r);
    my $got;
    $r->ping(sub { $got = $_[1]; $w->skip_pending if $w });
    $r->disconnect;
    undef $r;
    is $got, 'disconnected', 'skip_pending through a weak ref during DESTROY with a draining connection';
}

# replacing a handler that holds the last strong reference to the object
for my $method (qw(on_error on_connect on_disconnect on_push)) {
    my $r = EV::Redis->new(on_error => sub {});
    weaken(my $w = $r);
    { my $self = $r; $r->$method(sub { $self }) }  # only the handler holds it
    undef $r;
    $w->$method(undef);
    ok !defined $w, "$method(undef) through a weak ref frees the object after the call";
}

# callbacks run synchronously by a method keep the caller's $@
{
    my $r = EV::Redis->new(path => $connect_info{sock}, on_error => sub {}, max_pending => 1);
    $r->command('blpop', 'dd_errsv_nokey', 1, sub {});
    $r->command('get', 'dd_errsv', sub {});
    eval { die "boom\n" };
    $r->skip_waiting;
    is $@, "boom\n", 'skip_waiting keeps $@';
    eval { die "boom2\n" };
    undef $r;
    is $@, "boom2\n", 'DESTROY running pending callbacks keeps $@';
}

# explicit DESTROY whose callback drops the last reference to the object
{
    my $r = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    $r->ping(sub { EV::break });
    { my $g = EV::timer 3, 0, sub { EV::break }; EV::run }
    my @v;
    $r->command('get', 'dd_explicit', sub { undef $r; push @v, 'payload-1', 'payload-2' });
    $r->DESTROY;
    is_deeply \@v, ['payload-1', 'payload-2'], 'explicit DESTROY whose callback frees the object';
}

# the connect timer finishes a connect (the loop was blocked past
# connect_timeout) and on_connect tears the object down
for my $variant (qw(destroy reconnect)) {
    my $l = IO::Socket::INET->new(Listen => 5, LocalAddr => '127.0.0.1', LocalPort => 0)
        or die "listen: $!";
    my @held;
    my $acc = EV::io $l, EV::READ, sub { push @held, scalar $l->accept };
    my ($r, $n, $up) = (undef, 0);
    $r = EV::Redis->new(
        connect_timeout => 100,
        on_error   => sub {},
        on_connect => sub {
            $up = 1;
            if ($variant eq 'destroy') { undef $r }
            elsif (!$n++) { $r->disconnect; $r->connect('127.0.0.1', $l->sockport) }
        },
    );
    $r->connect('127.0.0.1', $l->sockport);
    select undef, undef, undef, 0.3;
    my $g = EV::timer 1, 0, sub { EV::break };
    EV::run;
    ok $up, "connect finished by the timer, on_connect $variant";
    $r->disconnect if $r && $r->is_connected;
}

# Global destruction needs a process of its own; under valgrind, so does it.
my @perl = ("\"$^X\"", map { "-I$_" } grep { !ref } @INC);
unshift @perl, 'valgrind --error-exitcode=9 --quiet'
    if ($ENV{LD_PRELOAD} // '') =~ /vgpreload/;

sub run_script {
    my $out = `@perl @_ 2>&1`;
    return ($?, $out);
}

# global destruction may destroy a non-default EV::Loop before the client
{
    require File::Temp;
    # arena order decides which goes first; this layout puts the loop first
    my ($fh, $script) = File::Temp::tempfile(SUFFIX => '.pl', UNLINK => 1);
    print $fh <<'EOS';
use strict;
use warnings;
use EV;
use EV::Redis;
our ($loop, $r, @pad);
@pad = map { \my $x } 1 .. 2000;
$r = EV::Redis->new(loop => EV::Loop->new, host => '127.0.0.1', port => 1, on_error => sub {});
print "connected=", $r->is_connected, "\n";
EOS
    close $fh;
    my ($status, $out) = run_script($script);
    is $status, 0, 'non-default loop left to global destruction: clean exit' or diag $out;
}

# ... and an object whose DESTROY calls disconnect() then
{
    require File::Temp;
    my ($fh, $script) = File::Temp::tempfile(SUFFIX => '.pl', UNLINK => 1);
    print $fh <<'EOS';
use strict;
use warnings;
package Wrapper;
sub new { bless {}, $_[0] }
sub DESTROY { $main::r->disconnect if ref $main::r }
package main;
our ($srv, $r, $dummy, %h, @pad);
BEGIN { $h{w} = Wrapper->new }
use EV;
use EV::Redis;
use Test::RedisServer;
$srv = Test::RedisServer->new;
# before global destruction removes its dir, or it cannot shut down
END { $srv->stop if $srv }
$dummy = EV::Redis->new(loop => EV::Loop->new);
@pad = map { \my $x } 1 .. 2000;
{
    my $loop = EV::Loop->new;
    $r = EV::Redis->new(loop => $loop, path => $srv->conf->{unixsocket},
        on_disconnect => sub {});
    $r->ping(sub { $loop->break });
    $loop->run;
}
EOS
    close $fh;
    my ($status, $out) = run_script($script);
    is $status, 0, 'disconnect() from a DESTROY in global destruction: clean exit' or diag $out;
}

# ... while that object's own loop is still alive: running it must return,
# wherever the arena put the client's reference to its loop
for my $early (0, 1) {
    require File::Temp;
    my ($fh, $script) = File::Temp::tempfile(SUFFIX => '.pl', UNLINK => 1);
    print $fh $early ? "our \$client;\n" : "\n", <<'EOS', $early ? '' : 'our ', <<'EOS';
use strict;
use warnings;
use EV;
use EV::Redis;
package Client;
sub new {
    my ($class, $sock) = @_;
    my $loop = EV::Loop->new;
    my $r = EV::Redis->new(loop => $loop, path => $sock, on_error => sub {});
    $r->ping(sub { $loop->break });
    $loop->run;
    bless { loop => $loop, r => $r }, $class;
}
sub DESTROY {
    my $s = shift;
    return unless $s->{r} && $s->{loop};
    print STDERR "started\n";
    $s->{r}->disconnect;
    $s->{loop}->run;
}
package main;
alarm 20;
EOS
$client = Client->new($ARGV[0]);
EOS
    close $fh;
    my ($status, $out) = run_script($script, $connect_info{sock});
    SKIP: {
        skip 'global destruction took the members first', 1
            if 0 == $status && $out !~ /started/;
        is $status, 0, 'a live loop of another object is still usable in global destruction'
            . ($early ? ', client variable declared first' : '') or diag $out;
    }
}

# ... and a client destroyed then takes its timers off that loop
for my $timer (qw(reconnect waiting)) {
    require File::Temp;
    my $closed = IO::Socket::INET->new(Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0)
        or die "listen: $!";
    my $port = $closed->sockport;
    close $closed;
    my ($fh, $script) = File::Temp::tempfile(SUFFIX => '.pl', UNLINK => 1);
    print $fh <<'EOS';
use strict;
use warnings;
use EV;
use EV::Redis;
package Client;
sub new {
    my ($class, $port, $timer) = @_;
    my $loop = EV::Loop->new;
    my $failed;
    my $r = EV::Redis->new(
        loop => $loop, host => '127.0.0.1', port => $port,
        reconnect => 1, reconnect_delay => 60_000,
        waiting_timeout => 60_000, resume_waiting_on_reconnect => 1,
        on_error => sub { $failed = 1; $loop->break },
    );
    $loop->run unless $failed;
    # queued for the reconnect: arms the waiting timer
    $r->ping(sub {}) if $timer eq 'waiting';
    bless { loop => $loop, r => $r }, $class;
}
sub DESTROY {
    my $s = shift;
    return unless $s->{r} && $s->{loop};
    print STDERR "started\n";
    delete $s->{r};
    alarm 5;
    $s->{loop}->run;
}
package main;
alarm 20;
our $client = Client->new(@ARGV);
EOS
    close $fh;
    my ($status, $out) = run_script($script, $port, $timer);
    SKIP: {
        skip 'global destruction took the members first', 1
            if 0 == $status && $out !~ /started/;
        is $status, 0, "a client destroyed in global destruction leaves no $timer timer on a live loop"
            or diag $out;
    }
}

# ... also when that happens inside one of its own callbacks
for my $from (qw(reply skip_waiting skip_pending)) {
    require File::Temp;
    my ($fh, $script) = File::Temp::tempfile(SUFFIX => '.pl', UNLINK => 1);
    print $fh <<'EOS';
use strict;
use warnings;
use EV;
use EV::Redis;
package Client;
sub new {
    my ($class, $sock) = @_;
    my $loop = EV::Loop->new;
    my $r = EV::Redis->new(loop => $loop, path => $sock, on_error => sub {});
    $r->ping(sub { $loop->break });
    $loop->run;
    bless { loop => $loop, r => $r }, $class;
}
sub DESTROY {
    my $s = shift;
    return unless $s->{r} && $s->{loop};
    print STDERR "started\n";
    # not $s itself: a callback global destruction leaves behind would keep it
    my ($loop, $slot) = ($s->{loop}, \$s->{r});
    if ($ARGV[1] eq 'reply') {
        $$slot->ping(sub { undef $$slot; $loop->break });
        $loop->run;
    }
    else {
        my $skip = $ARGV[1];
        $$slot->max_pending(1);
        $$slot->command('blpop', 'dd_gd_nokey', 1, sub {});
        $$slot->ping(sub { undef $$slot });
        $$slot->ping(sub {});
        $$slot->$skip;
    }
}
package main;
alarm 20;
our $client = Client->new($ARGV[0]);
EOS
    close $fh;
    my ($status, $out) = run_script($script, $connect_info{sock}, $from);
    SKIP: {
        skip 'global destruction took the members first', 1
            if 0 == $status && $out !~ /started/;
        is $status, 0, "a client destroyed in global destruction from its own $from callback"
            or diag $out;
    }
}

# ... or by a destructor that releasing a handler runs, into any slot
{
    package Guard;
    sub new { bless { cb => $_[1] }, $_[0] }
    sub DESTROY { $_[0]{cb}->() }
    package main;
    my @slots = qw(on_error on_connect on_disconnect on_push);
    my (@leaked, @warned);
    local $SIG{__WARN__} = sub { push @warned, $_[0] };
    for my $when (qw(early late)) {
        for my $slot (@slots) {
            for my $set (@slots) {
                my $r = EV::Redis->new(path => $connect_info{sock}, max_pending => 1, on_error => sub {});
                $r->ping(sub { EV::break });
                { my $g = EV::timer 3, 0, sub { EV::break }; EV::run }
                weaken(my $w = $r);
                my $token = [];
                weaken(my $held = $token);
                my $install = do {
                    my $t = $token;
                    my $guard = Guard->new(sub { eval { $w->$set(sub { $t }) } });
                    sub { my $g = $guard; undef $guard; $w->$slot(sub { $g }) };
                };
                if ('early' eq $when) {
                    $install->();
                }
                else {
                    $r->command('blpop', 'dd_guard_nokey', 1, sub {});
                    $r->command('ping', do { my $i = $install; sub { $i->() } });
                }
                undef $install;
                undef $token;
                undef $r;
                push @leaked, "$when $slot/$set" if defined $held;
            }
        }
    }
    is_deeply \@leaked, [], 'handlers set while DESTROY releases handlers are released too';
    is_deeply \@warned, [], '... without refcount warnings';
}

# a handler or an option set by a callback that DESTROY runs is released
{
    my $r = EV::Redis->new(path => $connect_info{sock}, on_error => sub {}, max_pending => 1);
    $r->ping(sub { EV::break });
    { my $g = EV::timer 3, 0, sub { EV::break }; EV::run }
    weaken(my $w = $r);
    my $token = [];
    weaken(my $held = $token);
    $r->command('blpop', 'dd_handler_nokey', 1, sub {});
    $r->command('ping', sub {
        my $t = $token;
        $w->on_error(sub { $t });
        $w->connect_timeout(100);
    });
    undef $r;
    undef $token;
    ok !defined $held, 'a handler set by a callback that DESTROY runs is released';
}

# a command issued from a callback that DESTROY runs
{
    my $r = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    $r->ping(sub { EV::break });
    { my $g = EV::timer 3, 0, sub { EV::break }; EV::run }
    weaken(my $w = $r);
    my ($died, $ran);
    $r->command('get', 'dd_cmd', sub {
        eval { $w->command('ping', sub { $ran = 1 }); 1 } or $died = $@;
    });
    undef $r;
    like $died, qr/object is being destroyed/, 'command() from a callback run by DESTROY croaks';
    ok !$ran, 'command() from a callback run by DESTROY: nothing queued';
}

done_testing;
