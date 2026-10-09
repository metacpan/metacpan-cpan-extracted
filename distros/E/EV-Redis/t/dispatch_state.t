use strict;
use warnings;
use Test::More;
use Test::RedisServer;
use IO::Socket::INET;
use Time::HiRes qw(sleep);
use EV;
use EV::Redis;
use lib 't/lib';
use RedisTestHelper qw(get_redis_version);

my $server;
eval { $server = Test::RedisServer->new }
    or plan skip_all => 'redis-server is required to this test';
my %ci = $server->connect_info;
my ($major, $minor) = get_redis_version($ci{sock});

sub settle {
    EV::now_update;
    my $g = EV::timer $_[0] // 0.2, 0, sub { EV::break };
    EV::run;
}
sub client { EV::Redis->new(path => $ci{sock}, on_error => sub {}) }
my $ctl = client();

# a slow connect handler must not send commands whose waiting deadline passed
{
    $ctl->del('ds_wait_connect');
    settle();
    my $err;
    my $r = EV::Redis->new(path => $ci{sock}, reconnect => 1,
        resume_waiting_on_reconnect => 1, waiting_timeout => 50,
        on_connect => sub { sleep 0.2 }, on_error => sub {});
    $r->incr('ds_wait_connect', sub { $err = $_[1]; EV::break });
    settle(2);
    is $err, 'waiting timeout', 'command expired during on_connect is cancelled';
    my $value = 'no reply';
    $ctl->get('ds_wait_connect', sub { $value = $_[0]; EV::break });
    settle(2);
    is $value, undef, 'the expired command did not write to Redis';
    $r->disconnect;
}

# lifting max_pending from an expired callback must not send other expired writes
{
    $ctl->del('ds_wait_batch');
    settle();
    my ($first, $second);
    my $r = EV::Redis->new(path => $ci{sock}, max_pending => 1,
        waiting_timeout => 50, on_error => sub {});
    $r->blpop('ds_empty', 1, sub {});
    $r->echo('first', sub { $first = $_[1]; $r->max_pending(0) });
    $r->incr('ds_wait_batch', sub { $second = $_[1]; EV::break });
    settle(3);
    is $first, 'waiting timeout', 'first waiter expired';
    is $second, 'waiting timeout', 'lifting the limit also cancels the expired second waiter';
    my $value = 'no reply';
    $ctl->get('ds_wait_batch', sub { $value = $_[0]; EV::break });
    settle(2);
    is $value, undef, 'the second expired write never reached Redis';
    $r->disconnect;
}

# mixed existing/new names must retain only their own pending confirmations
for my $method (qw(subscribe psubscribe)) {
    my ($old, @seen);
    my $r = client();
    $r->$method('ds_a', sub { $old++ });
    $r->$method('ds_a', 'ds_b', 'ds_b', sub {
        push @seen, defined $_[1] ? $_[1] : $_[0][0];
    });
    settle();
    my $unsub = $method eq 'subscribe' ? 'unsubscribe' : 'punsubscribe';
    $r->$unsub('ds_a', 'ds_b');
    settle();
    is $old // 0, 0, "$method confirmations moved to the replacement callback";
    is_deeply \@seen, [($method) x 4, ($unsub) x 2],
        "$method received all its confirmations";
    my $err;
    eval { $r->monitor(sub {}); 1 } or $err = $@;
    is $err, undef, "$method leaves an idle connection after unsubscribe-all";
    $r->disconnect;
    # MONITOR's final callback is separate: unsubscribed callbacks are gone
    is scalar @seen, 6, "$method callback has no spurious teardown error";
}

SKIP: {
    skip 'ACL requires Redis 6+', 8 if $major < 6;
    my $user = 'ds_discard';
    my $acl;
    $ctl->command('acl', 'setuser', $user, 'on', '>secret', '~*',
        ($major > 6 || $minor >= 2 ? ('&*') : ()),
        '+@all', '-discard', sub { $acl = $_[0] // $_[1] });
    settle();
    is $acl, 'OK', 'discard: ACL configured';
    my $r = client();
    my ($auth, $denied, $sub_err, $exec, $ping, @errors);
    $r->on_error(sub { push @errors, $_[0] });
    $r->auth($user, 'secret', sub { $auth = $_[0] // $_[1] });
    settle();
    is $auth, 'OK', 'discard: authenticated';
    # pipeline the denied end, subscription and EXEC: no QUEUED reply
    # may be mistaken for EXEC's result
    $r->multi(sub {});
    $r->discard(sub { $denied = $_[1] });
    $r->subscribe('ds_denied', sub { $sub_err = $_[1] });
    $r->exec(sub { $exec = $_[1] // $_[0] });
    $r->ping(sub { $ping = $_[0] });
    settle();
    like $denied, qr/NOPERM/, 'discard: permission error is delivered';
    like $sub_err, qr/inside MULTI/, 'discard: subscription stays refused inside the transaction';
    like $exec, qr/EXECABORT/, 'discard: EXEC receives its own abort reply';
    is $ping, 'PONG', 'discard: the next command receives its own reply';
    is_deeply \@errors, [], 'discard: command errors do not become connection errors';
    is $r->is_connected, 1, 'discard: the connection remains usable';
    $r->disconnect;
    $ctl->command('acl', 'deluser', $user);
}

# successful transaction endings still permit pipelined subscriptions
for my $end (qw(exec discard reset)) {
    next if $end eq 'reset' && ($major < 6 || ($major == 6 && $minor < 2));
    my $r = client();
    my ($sub, @errors);
    $r->on_error(sub { push @errors, $_[0] });
    $r->multi(sub {});
    $r->command($end, sub {});
    $r->subscribe('ds_after_end', sub { $sub = $_[0][0] unless $_[1] });
    settle();
    is $sub, 'subscribe', "$end: a pipelined subscription succeeds after the transaction";
    is_deeply \@errors, [], "$end: replies stay aligned";
    $r->disconnect;
}

# skipping transaction callbacks still releases commands waiting for their replies
{
    my $r = client();
    my $sub;
    $r->multi(sub {});
    $r->exec(sub {});
    $r->skip_pending;
    $r->subscribe('ds_after_skip', sub { $sub = $_[0][0] unless $_[1] });
    settle();
    is $sub, 'subscribe', 'subscription succeeds after skipped transaction replies';
    is $r->waiting_count, 0, 'skipped transaction replies release the wait queue';
    $r->disconnect;
}

# changing flow control in on_connect must leave its setup ahead of the backlog
{
    $ctl->set('ds_setup_read', 'db0');
    $ctl->select(1);
    $ctl->set('ds_setup_read', 'db1');
    $ctl->select(0);
    settle();
    for my $limit (0, 1, 2) {
        $ctl->set('ds_setup_write', 'db0');
        $ctl->select(1);
        $ctl->set('ds_setup_write', 'db1');
        $ctl->select(0);
        settle();
        my ($r, $got, @order, @errors);
        $r = EV::Redis->new(path => $ci{sock}, reconnect => 1,
            resume_waiting_on_reconnect => 1, max_pending => 1,
            on_error => sub { push @errors, $_[0] }, on_connect => sub {
                $r->max_pending($limit);
                $r->select(1, sub { push @order, 'select' });
            });
        $r->set('ds_setup_write', 'changed', sub { push @order, 'write' });
        $r->get('ds_setup_read', sub { $got = $_[0]; push @order, 'read'; EV::break });
        settle(2);
        is_deeply \@order, [qw(select write read)],
            "max_pending=$limit in on_connect: setup still goes first";
        is $got, 'db1', "max_pending=$limit in on_connect: read uses the selected database";
        is_deeply \@errors, [], "max_pending=$limit in on_connect: no connection errors";
        my ($db0, $db1);
        $ctl->get('ds_setup_write', sub { $db0 = $_[0] });
        $ctl->select(1);
        $ctl->get('ds_setup_write', sub { $db1 = $_[0] });
        $ctl->select(0, sub { EV::break });
        settle(2);
        is $db0, 'db0', "max_pending=$limit in on_connect: no write to the default database";
        is $db1, 'changed', "max_pending=$limit in on_connect: write uses the selected database";
        $r->disconnect;
    }
}

# delayed setup commands keep their order and stay ahead of the backlog
SKIP: {
    skip 'HRANDFIELD requires Redis 6.2+', 12 if $major < 6 || ($major == 6 && $minor < 2);
    $ctl->hset('ds_setup_hash', 'field', 'value');
    settle();
    for my $limit (0, 1) {
        for my $where (qw(handler waiting)) {
            my ($r, $got, @order, @errors);
            my $read = sub {
                $r->command('hrandfield', 'ds_setup_hash', 1, 'withvalues', sub {
                    $got = $_[0] // $_[1];
                    push @order, 'read';
                });
            };
            $r = EV::Redis->new(path => $ci{sock}, reconnect => 1,
                resume_waiting_on_reconnect => 1, max_pending => $limit,
                on_error => sub { push @errors, $_[0] }, on_connect => sub {
                    $r->multi(sub { push @order, 'multi' });
                    $r->set('ds_setup_ready', 1, sub { push @order, 'set' });
                    $r->exec(sub { push @order, 'exec' });
                    $r->command('hello', 3, sub { push @order, 'hello' });
                    $read->() if $where eq 'handler';
                });
            $read->() if $where eq 'waiting';
            settle();
            is_deeply \@order, [qw(multi set exec hello read)],
                "$where, max_pending=$limit: setup replies keep their order";
            is_deeply $got, [['field', 'value']],
                "$where, max_pending=$limit: the read uses RESP3";
            is_deeply \@errors, [], "$where, max_pending=$limit: no connection errors";
            $r->disconnect;
        }
    }
}

# setup kept across a lost connection stays ahead of its ordinary backlog
{
    local $SIG{PIPE} = 'IGNORE';
    my $listener = IO::Socket::INET->new(
        Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0,
    ) or die "listen: $!";
    my ($accepted, $reader);
    my $accept = EV::io $listener, EV::READ, sub {
        $accepted = $listener->accept or return;
        $reader = EV::io $accepted, EV::READ, sub {
            my $buf;
            sysread($accepted, $buf, 65536);
            close $accepted;
            undef $reader;
        };
    };
    my ($r, @order);
    my $connects = 0;
    $r = EV::Redis->new(host => '127.0.0.1', port => $listener->sockport,
        reconnect => 1, resume_waiting_on_reconnect => 1, max_pending => 1,
        on_error => sub { $r->connect_unix($ci{sock}) if $connects == 1 },
        on_connect => sub {
            if (++$connects == 1) {
                $r->multi(sub {});
                $r->exec(sub {});
                $r->command('hello', 3, sub { push @order, 'kept setup' });
            }
            else { $r->echo('new setup', sub { push @order, $_[0] }) }
        });
    $r->echo('backlog', sub { push @order, $_[0]; EV::break });
    settle(2);
    is_deeply \@order, ['new setup', 'kept setup', 'backlog'],
        'new and kept setup commands run before the backlog';
    is $r->waiting_count, 0, 'reconnected setup and backlog left the queues';
    $r->disconnect;
}

# cancellation includes setup waiters as well as ordinary commands
{
    my ($r, @skipped);
    $r = EV::Redis->new(path => $ci{sock}, reconnect => 1,
        resume_waiting_on_reconnect => 1, on_error => sub {}, on_connect => sub {
            $r->multi(sub {});
            $r->exec(sub {});
            $r->command('hello', 3, sub { push @skipped, ['setup', $_[1]] });
            $r->echo('later', sub { push @skipped, ['later setup', $_[1]] });
            EV::break;
        });
    $r->ping(sub { push @skipped, ['waiting', $_[1]] });
    settle(2);
    $r->skip_waiting;
    is_deeply \@skipped, [['waiting', 'skipped'], ['setup', 'skipped'], ['later setup', 'skipped']],
        'skip_waiting cancels both queues in creation order';
    is $r->waiting_count, 0, 'skip_waiting empties all waiting queues';
    $r->disconnect;
    settle();
}

# setup held behind transaction replies keeps its priority, and that wait
# counts toward no waiting deadline
SKIP: {
    skip 'HELLO requires Redis 6+', 2 if $major < 6;
    my ($r, @done);
    $r = EV::Redis->new(path => $ci{sock}, reconnect => 1,
        resume_waiting_on_reconnect => 1, waiting_timeout => 200,
        on_error => sub {}, on_connect => sub {
            sleep 0.1;
            $r->blpop('ds_setup_empty', 1, sub {});
            $r->multi(sub {});
            $r->exec(sub {});
            $r->command('hello', 3, sub { push @done, ['setup', $_[1]] });
        });
    $r->ping(sub { push @done, ['waiting', $_[1]]; EV::break });
    settle(3);
    is_deeply \@done, [['setup', undef], ['waiting', undef]],
        'setup and the waiting command run once the transaction replies arrive';
    is $r->waiting_count, 0, 'both waiters left the queue';
    $r->disconnect;
}

# a command held behind transaction replies runs after them, and so do later ones
SKIP: {
skip 'HELLO requires Redis 6+', 8 if $major < 6;
for my $where (qw(waiting handler)) {
    my ($r, $hello_err, $got, $err);
    my $key = "ds_held_barrier_$where";
    $ctl->del($key);
    settle();
    my $queue = sub {
        $r->blpop('ds_barrier_empty', 1, sub {});
        $r->multi(sub {});
        $r->exec(sub {});
        $r->command('hello', 3, sub { $hello_err = $_[1] // 'ok' });
        sleep 0.2;
        $r->incr($key, sub { ($got, $err) = @_; EV::break });
    };
    $r = EV::Redis->new(path => $ci{sock}, waiting_timeout => 400,
        on_error => sub {}, ($where eq 'handler' ? (on_connect => $queue) : ()));
    $queue->() if $where eq 'waiting';
    settle(3);
    is $hello_err, 'ok', "$where: the held command ran";
    is $err, undef, "$where: the later write did not expire behind it";
    is $got, 1, "$where: the later write ran after it";
    is $r->waiting_count, 0, "$where: the wait queue drained";
    $r->disconnect;
}
}

# a stalled EXEC does not cancel what waits for it
{
    my ($r, @got);
    $r = EV::Redis->new(path => $ci{sock}, waiting_timeout => 100, on_error => sub {});
    $r->blpop('ds_barrier_stall', 1, sub {});
    $r->multi(sub {});
    $r->incr('ds_barrier_ctr', sub {});
    $r->exec(sub { push @got, ['exec', $_[1]] });
    $r->subscribe('ds_barrier_chan', sub { push @got, ['subscribe', $_[1] // $_[0][0]]; EV::break });
    settle(3);
    is_deeply \@got, [['exec', undef], ['subscribe', 'subscribe']],
        'a subscribe held behind a stalled EXEC is not cancelled';
    $r->disconnect;
}
SKIP: {
    skip 'HELLO requires Redis 6+', 1 if $major < 6;
    my ($r, @got);
    $r = EV::Redis->new(path => $ci{sock}, waiting_timeout => 100, on_error => sub {});
    $r->blpop('ds_barrier_stall', 1, sub {});
    $r->multi(sub {});
    $r->exec(sub {});
    $r->command('hello', 2, sub { push @got, ['hello', $_[1]] });
    $r->echo('behind', sub { push @got, ['echo', $_[1] // $_[0]]; EV::break });
    settle(3);
    is_deeply \@got, [['hello', undef], ['echo', 'behind']],
        '... nor the commands queued behind it';
    $r->disconnect;
}

# a held command cancelled locally ends the hold; later queued commands keep
# their deadlines and the loop keeps running
{
    my ($r, $echo);
    $r = EV::Redis->new(path => $ci{sock}, waiting_timeout => 300, max_pending => 2,
        on_error => sub {});
    $r->ping(sub { EV::break });
    settle(2);
    $r->blpop('ds_hold_stall', 1, sub {});
    $r->multi(sub {});
    $r->command('hello', 2, sub {});
    settle(0.1);
    $r->skip_waiting;
    $r->echo('after', sub { $echo = $_[1] // $_[0]; EV::break });
    settle(3);
    is $echo, 'waiting timeout', 'a command queued after the hold ended expires on time';
    $r->discard(sub {});
    $r->disconnect;
}

# an expired callback may drop the client before the automatic queue drain
{
    my ($r, @errors);
    $r = EV::Redis->new(path => $ci{sock}, waiting_timeout => 50, max_pending => 1,
        on_error => sub {});
    $r->blpop('ds_destroy_empty', 1, sub {});
    $r->echo('expires', sub {
        push @errors, ['echo', $_[1]];
        undef $r;
        EV::break;
    });
    $r->incr('ds_destroy_barrier', sub { push @errors, ['write', $_[1]] });
    settle(2);
    ok !defined $r, 'the expired callback dropped the client';
    is_deeply \@errors, [['echo', 'waiting timeout'], ['write', 'disconnected']],
        'teardown cancels the remaining waiter once before dispatch resumes';
}

# an earlier unsubscribe reply may acquire a later subscription's callback
for my $method (qw(subscribe psubscribe)) {
    my $unsub = $method eq 'subscribe' ? 'unsubscribe' : 'punsubscribe';
    for my $case (qw(unknown duplicate repeated)) {
        my ($r, @seen, $pong, $err);
        my $name = "ds_unsub_b\0\xff";
        $r = client();
        $r->$method('ds_unsub_a', ($case eq 'repeated' ? ($name) : ()),
            sub { push @seen, $_[0] if $_[0] });
        settle();
        if ($case eq 'repeated') {
            $r->$unsub($name);
            $r->$unsub($name);
        }
        else { $r->$unsub(($name) x ($case eq 'duplicate' ? 2 : 1)) }
        $r->$method($name, sub { push @seen, $_[0] if $_[0] });
        $r->$unsub();
        $r->ping(sub { $pong = $_[0] // $_[1] });
        settle();
        is $pong, 'PONG', "$method, $case: PING gets its reply";
        is $seen[-1][2], 0, "$method, $case: Redis has no subscriptions";
        eval { $r->monitor(sub {}); 1 } or $err = $@;
        is $err, undef, "$method, $case: the client is idle too";
        $r->disconnect;
    }
}
# a waiting deadline due while a reconnect attempt connects sends nothing ahead of on_connect
{
    $ctl->set('ds_timer_setup', 'db0');
    $ctl->select(1);
    $ctl->set('ds_timer_setup', 'db1');
    $ctl->select(0);
    settle();
    my ($r, $id, @order);
    $r = EV::Redis->new(path => $ci{sock}, reconnect => 1, reconnect_delay => 200,
        waiting_timeout => 300, on_error => sub { EV::break },
        on_connect => sub { $r->select(1, sub { push @order, 'select' }) });
    $r->client('id', sub { $id = $_[0] });
    settle();
    $ctl->client('kill', 'id', $id);
    settle(5);
    @order = ();
    my $expiring = EV::timer 0.01, 0, sub { $r->echo('expires', sub {}) };
    my $late = EV::timer 0.02, 0, sub {
        sleep 0.4;
        $r->set('ds_timer_setup', 'changed', sub { push @order, 'write' });
    };
    settle(1.5);
    is_deeply \@order, [qw(select write)], 'a waiting deadline during a reconnect keeps setup first';
    my ($db0, $db1);
    $ctl->get('ds_timer_setup', sub { $db0 = $_[0] });
    $ctl->select(1);
    $ctl->get('ds_timer_setup', sub { $db1 = $_[0] });
    $ctl->select(0, sub { EV::break });
    settle(2);
    is $db0, 'db0', '... nothing is written to the default database';
    is $db1, 'changed', '... the write uses the selected database';
    $r->reconnect(0);
    $r->disconnect;
}

$ctl->disconnect;
done_testing;
