use strict;
use warnings;
use Test::More;
use Test::RedisServer;
use IO::Socket::INET;

my $redis_server;
eval {
    $redis_server = Test::RedisServer->new;
} or plan skip_all => 'redis-server is required to this test';

my %connect_info = $redis_server->connect_info;

use EV;
use EV::Redis;
use lib 't/lib';
use RedisTestHelper qw(get_redis_version);

my ($major, $minor) = get_redis_version($connect_info{sock});

sub settle {
    my ($sec) = @_;
    EV::now_update;
    my $t = EV::timer $sec // 0.2, 0, sub { EV::break };
    EV::run;
}

sub client { EV::Redis->new(path => $connect_info{sock}, on_error => sub {}) }

my $ctl = client();

# the server answers neither CLIENT REPLY OFF nor SKIP, nor the command SKIP covers
for my $mode (qw(off OFF skip)) {
    my $r = client();
    eval { $r->client('reply', $mode, sub {}) };
    like $@, qr/CLIENT REPLY \Q$mode\E is not supported/, "CLIENT REPLY $mode croaks";
    my $got;
    $r->ping(sub { $got = $_[0] });
    settle();
    is $got, 'PONG', "a command after the refused CLIENT REPLY $mode gets its own reply";
    $r->disconnect;
}
{
    my $r = client();
    my $got;
    $r->client('reply', 'on', sub { $got = $_[0] });
    settle();
    is $got, 'OK', 'CLIENT REPLY ON still works';
    $r->disconnect;
}

# command matching is ASCII-only: tr_TR folds I differently, which must not
# sneak a reply-suppressing command past the refusal
SKIP: {
    require POSIX;
    my $old_locale = POSIX::setlocale(&POSIX::LC_ALL);
    my $tr = POSIX::setlocale(&POSIX::LC_ALL, "tr_TR.UTF-8");
    skip 'tr_TR locale unavailable', 10 unless $tr;
    for my $mode (qw(OFF SKIP)) {
        my $r = client();
        eval { $r->command('CLIENT', 'REPLY', $mode, sub {}) };
        like $@, qr/CLIENT REPLY \Q$mode\E is not supported/,
            "tr_TR: uppercase CLIENT REPLY $mode croaks";
        my $got;
        $r->ping(sub { $got = $_[0] });
        settle();
        is $got, 'PONG', "tr_TR: connection unpoisoned after refused $mode";
        $r->disconnect;
    }
    for my $cmd (qw(SUBSCRIBE PSUBSCRIBE)) {
        my $r = client();
        my @replies;
        $r->command($cmd, 'ps_locale', sub { push @replies, $_[0] if defined $_[0] });
        settle();
        is $replies[0][0], lc($cmd), "tr_TR: uppercase $cmd is routed";
        $r->command($cmd eq 'SUBSCRIBE' ? 'UNSUBSCRIBE' : 'PUNSUBSCRIBE');
        settle();
        is $replies[1][0], $cmd eq 'SUBSCRIBE' ? 'unsubscribe' : 'punsubscribe',
            '... and uppercase unsubscribe is routed';
        $r->disconnect;
    }
    my $r = client();
    my @stream;
    $r->command('MONITOR', sub { push @stream, $_[0] if defined $_[0] });
    settle();
    is $stream[0], 'OK', 'tr_TR: uppercase MONITOR starts';
    $ctl->ping;
    settle();
    ok scalar(grep { /PING/i } @stream), '... and keeps delivering the stream';
    $r->disconnect;
    POSIX::setlocale(&POSIX::LC_ALL, $old_locale);
}

SKIP: {
    skip 'RESET requires Redis 6.2+', 9 if $major < 6 || ($major == 6 && $minor < 2);

    $ctl->del('ps_list', sub {});
    $ctl->rpush('ps_list', 'a', 'b', 'c', sub {});
    settle();

    my $r = client();
    my @msgs;
    $r->subscribe('ps_chan', sub { push @msgs, $_[0] });
    settle();
    eval { $r->command('reset', sub {}) };
    like $@, qr/RESET is not supported on a subscribed connection/,
        'RESET croaks while subscribed';
    $r->disconnect;

    # RESET waiting behind a SUBSCRIBE
    $r = client();
    $r->max_pending(1);
    $r->ping(sub {});
    $r->subscribe('ps_chan', sub {});
    eval { $r->command('reset', sub {}) };
    like $@, qr/RESET is not supported/, 'RESET croaks with a SUBSCRIBE waiting';
    settle();
    $r->disconnect;

    # not subscribed: RESET is fine, and later replies keep their callbacks
    $r = client();
    my ($reset, $range);
    $r->command('reset', sub { $reset = $_[0] });
    $r->lrange('ps_list', 0, -1, sub { $range = $_[0] });
    settle();
    is $reset, 'RESET', 'RESET on an unsubscribed connection';
    is_deeply $range, [qw(a b c)], 'reply after RESET reaches its callback';
    $r->disconnect;

    # a queued unsubscribe is not a subscription: RESET proceeds past it
    $r = client();
    $r->max_pending(1);
    $r->command('blpop', 'ps_nokey', 1, sub {});
    my $unsub_err;
    $r->command('unsubscribe', 'ps_nope', sub { $unsub_err = $_[1] });
    my $reset2;
    eval { $r->command('reset', sub { $reset2 = $_[0] }) };
    is $@, '', 'RESET is accepted with only an unsubscribe waiting';
    settle(2);
    is $unsub_err, 'not subscribed', '... the queued unsubscribe is refused';
    is $reset2, 'RESET', '... and RESET runs once the slot frees';
    $r->disconnect;

    # RESP3 with a push seen, then RESET back to RESP2, then subscribe
    $r = client();
    my (@sub, $ping);
    $r->command('hello', 3, sub {});
    $r->subscribe('ps_x', sub {});
    settle();
    $r->unsubscribe('ps_x');
    settle();
    $r->command('reset', sub {});
    settle();
    $r->subscribe('ps_chan2', sub { push @sub, $_[0] });
    $r->ping(sub { $ping = $_[0] });
    settle();
    $ctl->publish('ps_chan2', 'm1', sub {});
    settle();
    is_deeply $ping, ['pong', ''], 'PING after RESET from RESP3 gets its own reply';
    is_deeply [map { $_->[0] } @sub], [qw(subscribe message)],
        'subscription after RESET from RESP3 gets its confirmation and messages';
    $r->disconnect;
}

SKIP: {
    skip 'HELLO requires Redis 6+', 3 if $major < 6;

    # HELLO 3, one push, back to HELLO 2: subscribe traffic must not shift callbacks
    my $r = client();
    my (@sub, $ping1, $ping2);
    $r->command('hello', 3, sub {});
    $r->subscribe('hs_x', sub {});
    settle();
    $r->unsubscribe('hs_x');
    settle();
    $r->command('hello', 2, sub {});
    settle();
    $r->subscribe('hs_chan', sub { push @sub, $_[0] });
    $r->ping(sub { $ping1 = $_[0] });
    settle();
    $ctl->publish('hs_chan', 'm1', sub {});
    settle();
    $r->ping(sub { $ping2 = $_[0] });
    settle();
    is_deeply $ping1, ['pong', ''], 'PING after HELLO 2 gets its own reply';
    is_deeply [map { "$_->[0]:$_->[2]" } @sub], ['subscribe:1', 'message:m1'],
        'subscription after HELLO 2 gets its confirmation and messages';
    is_deeply $ping2, ['pong', ''], 'second PING gets its own reply';
    $r->disconnect;
}

# pub/sub and MONITOR queued inside MULTI would answer QUEUED to the wrong callback
{
    my $r = client();
    my (@got, $sub_err, $mon_err);
    $r->multi(sub { push @got, "multi:$_[0]" });
    $r->subscribe('ms_chan', sub { $sub_err = $_[1] unless defined $_[0] });
    $r->exec(sub { push @got, 'exec:' . (ref $_[0] ? scalar @{$_[0]} : $_[0] // "err $_[1]") });
    $r->ping(sub { push @got, "ping:$_[0]" });
    settle();
    like $sub_err, qr/inside MULTI/, 'SUBSCRIBE inside MULTI is refused through its callback';
    is_deeply \@got, ['multi:OK', 'exec:0', 'ping:PONG'],
        'commands around a refused SUBSCRIBE in MULTI get their own replies';

    $r->multi(sub {});
    settle();
    $r->monitor(sub { $mon_err = $_[1] unless defined $_[0] });
    my $exec;
    $r->exec(sub { $exec = $_[0] });
    settle();
    like $mon_err, qr/inside MULTI/, 'MONITOR inside MULTI is refused';
    is_deeply $exec, [], 'EXEC after a refused MONITOR still works';

    my $sub_ok;
    $r->subscribe('ms_chan', sub { $sub_ok = $_[0] if ref $_[0] });
    settle();
    is $sub_ok->[0], 'subscribe', 'SUBSCRIBE after EXEC works';
    $r->disconnect;
}

# a MONITOR the server refuses must not leave the connection in monitor mode
{
    my $r = client();
    my ($err, @mon, $ping);
    $r->monitor('extra', sub { push @mon, [@_] });
    settle();
    like $mon[0][1], qr/wrong number of arguments/i, 'refused MONITOR reports the error';
    is $r->pending_count, 0, 'nothing pending after a refused MONITOR';
    eval { $r->ping(sub { $ping = $_[0] }); 1 } or $err = $@;
    is $err, undef, 'commands are accepted after a refused MONITOR';
    settle();
    is $ping, 'PONG', 'and get their own replies';
    is scalar @mon, 1, 'the refused MONITOR callback ran once';
    $r->disconnect;
    settle();
    is scalar @mon, 1, 'and is not called again on disconnect';
}

# REPLCONF ACK and GETACK get no reply from a normal client; SYNC and PSYNC
# answer with a replication stream
for my $args ([qw(replconf ack 0)], [qw(replconf getack *)],
              [qw(replconf listening-port 6390 getack *)], [qw(replconf capa eof ack 0)],
              [qw(sync)], [qw(psync ? -1)]) {
    my $r = client();
    eval { $r->command(@$args, sub {}) };
    like $@, qr/(?:REPLCONF ACK and GETACK|$args->[0]) (?:are|is) not supported/i, "@$args croaks";
    my $got;
    $r->ping(sub { $got = $_[0] });
    settle();
    is $got, 'PONG', '... and the next command gets its own reply';
    $r->disconnect;
}

SKIP: {
    skip 'RESET requires Redis 6.2+', 3 if $major < 6 || ($major == 6 && $minor < 2);

    # a RESET that waits while connecting meets the subscription on_connect makes
    my $r;
    my (@msgs, $reset_err, $ping);
    $r = EV::Redis->new(path => $connect_info{sock}, reconnect => 1,
        resume_waiting_on_reconnect => 1, on_error => sub {},
        on_connect => sub { $r->subscribe('rq_chan', sub { push @msgs, $_[0] if ref $_[0] }) });
    $r->command('reset', sub { $reset_err = $_[1] });
    settle();
    $r->ping(sub { $ping = $_[0] });
    $ctl->publish('rq_chan', 'm1', sub {});
    settle();
    like $reset_err, qr/RESET is not supported on a subscribed connection/,
        'a waiting RESET fails once on_connect subscribed';
    is_deeply $ping, ['pong', ''], 'PING after it gets its own reply';
    is_deeply [map { $_->[0] } @msgs], [qw(subscribe message)], 'and the subscription stays';
    $r->reconnect(0);
    $r->disconnect;
}

SKIP: {
    skip 'HELLO requires Redis 6+', 4 if $major < 6;

    # HELLO inside MULTI would switch the protocol inside EXEC's reply, unseen
    $ctl->del('hm_list', sub {});
    $ctl->rpush('hm_list', 'a', 'b', 'c', sub {});
    settle();
    my $r = client();
    my ($hello_err, $range, $ping, $get);
    $r->command('hello', 3, sub {});
    $r->subscribe('hm_chan', sub {});
    settle();
    $r->multi(sub {});
    $r->command('hello', 2, sub { $hello_err = $_[1] });
    $r->exec(sub {});
    settle();
    $r->lrange('hm_list', 0, -1, sub { $range = $_[0] });
    $r->ping(sub { $ping = $_[0] });
    $r->get('hm_nokey', sub { $get = defined $_[0] ? $_[0] : $_[1] // 'nil' });
    settle();
    like $hello_err, qr/HELLO is not supported inside MULTI/, 'HELLO inside MULTI fails';
    is_deeply $range, [qw(a b c)], 'RESP3, subscribed: the next reply reaches its callback';
    is $ping, 'PONG', '... so does the one after';
    is $get, 'nil', '... and the one after that';
    $r->disconnect;
}

# a MULTI the server refuses opens no transaction
{
    my $r = client();
    my ($multi_err, $sub);
    $r->multi('extra', sub { $multi_err = $_[1] });
    settle();
    $r->subscribe('rm_chan', sub { $sub = defined $_[0] ? $_[0][0] : $_[1] });
    settle();
    like $multi_err, qr/wrong number of arguments/i, 'MULTI with an argument is refused';
    is $sub, 'subscribe', 'SUBSCRIBE afterwards is not taken as inside MULTI';
    $r->disconnect;
}

# ... while one pipelined behind it is still open
{
    my $r = client();
    my ($sub_err, $exec, $ping);
    $r->multi('extra', sub {});
    $r->multi(sub {});
    settle();
    $r->subscribe('rm_chan2', sub { $sub_err = $_[1] unless defined $_[0] });
    $r->exec(sub { $exec = $_[0] });
    $r->ping(sub { $ping = $_[0] });
    settle();
    like $sub_err, qr/inside MULTI/, 'SUBSCRIBE inside the open one is refused';
    is_deeply $exec, [], 'EXEC gets its own reply';
    is $ping, 'PONG', '... and so does the next command';
    $r->disconnect;
}

# a server answering each command from %$replies; EXEC and DISCARD take theirs per case
sub scripted_server {
    my ($replies) = @_;
    my $l = IO::Socket::INET->new(Listen => 5, LocalAddr => '127.0.0.1', LocalPort => 0)
        or die "listen: $!";
    my %conns;
    my $accept = EV::io $l, EV::READ, sub {
        my $c = $l->accept or return;
        my $buf = '';
        $conns{fileno $c} = [$c, EV::io $c, EV::READ, sub {
            sysread($c, $buf, 65536, length $buf) or return delete $conns{fileno $c};
            while ($buf =~ /\A\*(\d+)\r\n/) {
                my ($n, $pos, @args) = ($1, $+[0]);
                for (1 .. $n) {
                    substr($buf, $pos) =~ /\A\$(\d+)\r\n/ or return;
                    my $len = $1;
                    $pos += $+[0];
                    return if length($buf) < $pos + $len + 2;
                    push @args, substr($buf, $pos, $len);
                    $pos += $len + 2;
                }
                substr($buf, 0, $pos, '');
                my $reply = $replies->{uc $args[0]};
                syswrite $c, ref $reply ? $reply->(@args) : $reply;
            }
        }];
    };
    return ($l->sockport, [$l, $accept, \%conns]);
}

# errors after which the server holds no transaction
{
    my %replies = (
        MULTI => "+OK\r\n", SET => "+QUEUED\r\n", PING => "+PONG\r\n",
        DISCARD => "-ERR DISCARD without MULTI\r\n",
        SUBSCRIBE => sub { "*3\r\n\$9\r\nsubscribe\r\n\$" . length($_[1]) . "\r\n$_[1]\r\n:1\r\n" },
    );
    my ($port, $keep) = scripted_server(\%replies);
    for my $err ('CLUSTERDOWN Hash slot not served', 'MOVED 3999 127.0.0.1:6381',
                 'ASK 3999 127.0.0.1:6381', 'TRYAGAIN Multiple keys request during rehashing of slot',
                 "CROSSSLOT Keys in request don't hash to the same slot", 'ERR EXEC without MULTI',
                 'ERR Transaction contains write commands but instance is now a read-only replica. EXEC aborted.',
                 ['OOM command not allowed when used memory > maxmemory', 'discard']) {
        my ($exec_err, $discard) = ref $err ? @$err : ($err);
        $replies{EXEC} = "-$exec_err\r\n";
        my $r = EV::Redis->new(host => '127.0.0.1', port => $port, on_error => sub {});
        my ($exec, $sub);
        $r->multi(sub {});
        $r->set('k', 'v', sub {});
        $r->exec(sub { $exec = $_[1] });
        $r->discard(sub {}) if $discard;
        $r->subscribe('te_chan', sub { $sub = defined $_[0] ? $_[0][0] : $_[1] });
        settle();
        my $what = $discard ? "DISCARD without MULTI after EXEC: $exec_err" : "EXEC: $exec_err";
        is $exec, $exec_err, "$what: EXEC gets the error";
        is $sub, 'subscribe', "$what: a subscribe afterwards is not taken as inside MULTI";
        $r->disconnect;
    }
}

done_testing;
