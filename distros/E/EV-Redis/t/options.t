use strict;
use warnings;
use Test::More;
use Test::RedisServer;

use EV;
use EV::Redis;
use lib 't/lib';
use RedisTestHelper qw(get_redis_version);

my $redis_server;
eval {
    $redis_server = Test::RedisServer->new;
} or plan skip_all => 'redis-server is required to this test';

my %connect_info = $redis_server->connect_info;

{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    EV::Redis->new(connect_timout => 500, max_pendng => 1);
    is scalar(@warnings), 1, 'unknown options warn once';
    like $warnings[0], qr/unknown option\(s\): connect_timout max_pendng at \Q$0\E line/,
        '... naming them, at the caller';

    @warnings = ();
    EV::Redis->new(connect_timeout => 100, command_timeout => 100, max_pending => 1,
        waiting_timeout => 100, resume_waiting_on_reconnect => 0, priority => 0,
        keepalive => 0, prefer_ipv6 => 1, tcp_user_timeout => 0, cloexec => 1,
        reuseaddr => 0, reconnect => 0, reconnect_delay => 10, max_reconnect_attempts => 1,
        (EV::Redis->has_ssl ? (tls => 1, tls_verify => 1) : ()),
        on_error => sub {}, on_connect => sub {},
        on_disconnect => sub {}, on_push => sub {}, loop => EV::default_loop);
    is_deeply \@warnings, [], 'documented options do not warn';

    { package EV::Redis::OptionsSubclass; our @ISA = ('EV::Redis'); }
    EV::Redis::OptionsSubclass->new(own_option => 1);
    is_deeply \@warnings, [], 'a subclass may pass options of its own';

    @warnings = ();
    EV::Redis->new(port => 6380);
    is scalar(@warnings), 1, q{'port' without 'host' warns};
    like $warnings[0], qr/'port' has no effect without 'host'/, '... saying so';

    @warnings = ();
    EV::Redis->new(path => $connect_info{sock}, port => 6380);
    is scalar(@warnings), 1, q{'port' with 'path' warns};

    @warnings = ();
    EV::Redis->new(host => '127.0.0.1', port => 6380);
    is_deeply [grep { /'port' has no effect/ } @warnings], [],
        q{'port' with 'host' does not warn about the port};

    @warnings = ();
    EV::Redis->new(tls_ca => 'ca.pem', tls_verify => 1);
    is scalar(@warnings), 1, 'TLS options without tls warn once';
    like $warnings[0], qr/TLS options \(tls_ca tls_verify\) have no effect without 'tls'/,
        '... naming them';
}

{
    my $r = EV::Redis->new;
    is $r->keepalive, 0, 'keepalive default is 0';
    $r->keepalive(15);
    is $r->keepalive, 15, 'keepalive setter/getter roundtrip';
    $r->keepalive(0);
    is $r->keepalive, 0, 'keepalive can be disabled';
}

{
    my $r = EV::Redis->new(keepalive => 30);
    is $r->keepalive, 30, 'keepalive via constructor';
}

{
    eval { EV::Redis->new->keepalive(-1) };
    like $@, qr/non-negative/, 'keepalive rejects negative';

    eval { EV::Redis->new->keepalive(32768) };
    like $@, qr/too large/, 'keepalive rejects too large';
    is eval { EV::Redis->new->keepalive(32767) }, 32767, 'keepalive accepts the maximum';
    eval { EV::Redis->new->keepalive(2**32 + 5) };
    like $@, qr/keepalive interval too large/, 'keepalive rejects a value that wraps in an int';
}

# values beyond the C int range must not wrap
{
    my $r = EV::Redis->new(on_error => sub { });
    $r->reconnect('yes');
    is $r->reconnect_enabled, 1, 'reconnect: any true value enables';
    $r->reconnect(2**32);
    is $r->reconnect_enabled, 1, 'reconnect: 2**32 enables';
    $r->reconnect(0);
    eval { $r->reconnect(1, 2**32 + 7) };
    like $@, qr/reconnect_delay/, 'reconnect: a delay that wraps in an int croaks';
    is $r->reconnect_enabled, 0, 'reconnect: a croaking call changes nothing';

    eval { $r->connect('127.0.0.1', 2**32 + 6379) };
    like $@, qr/invalid port/, 'connect: a port that wraps in an int croaks';
    eval { $r->connect('127.0.0.1', 0) };
    like $@, qr/invalid port/, 'connect: port 0 croaks';
    ok !$r->is_connected, 'connect: nothing started for an invalid port';

    $r->max_pending(2**32 + 3);
    is $r->max_pending, 2**31 - 1, 'max_pending: a value beyond int range saturates';
    $r->priority(2**32 + 1);
    is $r->priority, 2, 'priority: a value beyond int range clamps to the maximum';

    # beyond IV_MAX too: SvIV alone would turn these negative
    for my $big (2**64, '18446744073709551615', 1e30) {
        $r->priority($big);
        is $r->priority, 2, "priority($big) clamps to the maximum";
        $r->max_pending($big);
        is $r->max_pending, 2**31 - 1, "max_pending($big) saturates";
        eval { $r->keepalive($big) };
        like $@, qr/keepalive interval too large/, "keepalive($big) croaks as too large";
        eval { $r->waiting_timeout($big) };
        like $@, qr/waiting_timeout too large/, "waiting_timeout($big) croaks as too large";
        eval { $r->reconnect(1, $big) };
        like $@, qr/reconnect_delay too large/, "reconnect(1, $big) croaks as too large";
        eval { $r->connect('127.0.0.1', $big) };
        like $@, qr/invalid port \d/, "connect port $big croaks";
    }
    $r->max_pending(0);
    $r->priority(0);

    # NaN is not a large number: it stays what SvIV makes of it
    my $nan = do { no warnings 'numeric'; 'NaN' + 0 };
    my $nan_iv = do { use integer; $nan + 0 };
    SKIP: {
        skip "NaN is $nan_iv as an integer here", 3 if $nan_iv;
        $r->priority(1);
        $r->priority($nan);
        is $r->priority, 0, 'priority(NaN) is 0';
        $r->max_pending(5);
        $r->max_pending($nan);
        is $r->max_pending, 0, 'max_pending(NaN) is 0';
        ok eval { $r->waiting_timeout($nan); 1 }, 'waiting_timeout(NaN) does not croak' or diag $@;
    }
}

{
    my $r = EV::Redis->new(
        path     => $connect_info{sock},
        on_error => sub { },
    );
    my $t; $t = EV::timer 0.1, 0, sub {
        undef $t;
        $r->keepalive(10);
        is $r->keepalive, 10, 'keepalive set while connected';
        $r->disconnect;
    };
    EV::run;
}

{
    my $pong;
    my $r = EV::Redis->new(
        path      => $connect_info{sock},
        keepalive => 10,
        on_error  => sub { },
    );
    ok $r->is_connected, 'keepalive does not fail a unix socket connect';
    $r->command('PING', sub { $pong = $_[0]; EV::break });
    my $g = EV::timer 3, 0, sub { EV::break };
    EV::run;
    is $pong, 'PONG', 'keepalive on a unix socket: commands work';
    $r->disconnect if $r->is_connected;
}

{
    require IO::Socket::INET;
    my $l = IO::Socket::INET->new(
        Listen => 5, LocalAddr => '127.0.0.1', LocalPort => 0,
    ) or die "listen: $!";
    my ($up, $err);
    my $r = EV::Redis->new(
        keepalive  => 32767,
        on_connect => sub { $up = 1; EV::break },
        on_error   => sub { $err = $_[0]; EV::break },
    );
    $r->connect('127.0.0.1', $l->sockport);
    my $g = EV::timer 3, 0, sub { EV::break };
    EV::run unless $up || defined $err;
    ok $up, 'keepalive at the maximum: TCP connect succeeds' or diag $err;
    $r->keepalive(20);
    is $r->keepalive, 20, 'keepalive set on a live TCP connection';
    ok $r->is_connected, 'keepalive set on a live TCP connection: still connected';
    $r->disconnect if $r->is_connected;
}

{
    my $r = EV::Redis->new;
    is $r->prefer_ipv4, 0, 'prefer_ipv4 default is 0';
    is $r->prefer_ipv6, 0, 'prefer_ipv6 default is 0';

    $r->prefer_ipv4(1);
    is $r->prefer_ipv4, 1, 'prefer_ipv4 set to 1';
    is $r->prefer_ipv6, 0, 'prefer_ipv6 cleared when ipv4 set';

    $r->prefer_ipv6(1);
    is $r->prefer_ipv6, 1, 'prefer_ipv6 set to 1';
    is $r->prefer_ipv4, 0, 'prefer_ipv4 cleared when ipv6 set';

    $r->prefer_ipv6(0);
    is $r->prefer_ipv6, 0, 'prefer_ipv6 cleared';
    is $r->prefer_ipv4, 0, 'prefer_ipv4 still 0';
}

{
    my $r = EV::Redis->new(prefer_ipv4 => 1);
    is $r->prefer_ipv4, 1, 'prefer_ipv4 via constructor';
    is $r->prefer_ipv6, 0, 'prefer_ipv6 not set';
}

{
    my $r = EV::Redis->new(prefer_ipv6 => 1);
    is $r->prefer_ipv6, 1, 'prefer_ipv6 via constructor';
    is $r->prefer_ipv4, 0, 'prefer_ipv4 not set';
}

{
    my $r = EV::Redis->new;
    ok !defined $r->source_addr, 'source_addr default is undef';

    $r->source_addr('192.168.1.1');
    is $r->source_addr, '192.168.1.1', 'source_addr setter/getter roundtrip';

    $r->source_addr('10.0.0.1');
    is $r->source_addr, '10.0.0.1', 'source_addr can be changed';

    $r->source_addr(undef);
    ok !defined $r->source_addr, 'source_addr cleared with undef';
}

{
    my $r = EV::Redis->new(source_addr => '127.0.0.1');
    is $r->source_addr, '127.0.0.1', 'source_addr via constructor';
}

{
    my $r = EV::Redis->new;
    is $r->tcp_user_timeout, 0, 'tcp_user_timeout default is 0';

    $r->tcp_user_timeout(5000);
    is $r->tcp_user_timeout, 5000, 'tcp_user_timeout setter/getter roundtrip';

    $r->tcp_user_timeout(0);
    is $r->tcp_user_timeout, 0, 'tcp_user_timeout reset to 0';
}

{
    my $r = EV::Redis->new(tcp_user_timeout => 3000);
    is $r->tcp_user_timeout, 3000, 'tcp_user_timeout via constructor';
}

{
    eval { EV::Redis->new->tcp_user_timeout(-1) };
    like $@, qr/non-negative/, 'tcp_user_timeout rejects negative';

    eval { EV::Redis->new->tcp_user_timeout(3_000_000_000) };
    like $@, qr/too large/, 'tcp_user_timeout rejects too large';
}

{
    my $r = EV::Redis->new;
    is $r->cloexec, 1, 'cloexec default is 1 (enabled)';

    $r->cloexec(0);
    is $r->cloexec, 0, 'cloexec disabled';

    $r->cloexec(1);
    is $r->cloexec, 1, 'cloexec re-enabled';
}

{
    my $r = EV::Redis->new(cloexec => 0);
    is $r->cloexec, 0, 'cloexec => 0 via constructor';
}

{
    my $r = EV::Redis->new(cloexec => 1);
    is $r->cloexec, 1, 'cloexec => 1 via constructor';
}

{
    my $r = EV::Redis->new;
    is $r->reuseaddr, 0, 'reuseaddr default is 0 (disabled)';

    $r->reuseaddr(1);
    is $r->reuseaddr, 1, 'reuseaddr enabled';

    $r->reuseaddr(0);
    is $r->reuseaddr, 0, 'reuseaddr disabled';
}

{
    my $r = EV::Redis->new(reuseaddr => 1);
    is $r->reuseaddr, 1, 'reuseaddr => 1 via constructor';
}

{
    my $r = EV::Redis->new(
        path     => $connect_info{sock},
        on_error => sub { },
    );
    my $done = 0;
    my $t; $t = EV::timer 0.1, 0, sub {
        undef $t;
        my $ret = $r->command_timeout(5000);
        is $ret, 5000, 'command_timeout set while connected returns new value';
        $r->ping(sub {
            $done = 1;
            $r->disconnect;
        });
    };
    EV::run;
    is $done, 1, 'command after runtime timeout change succeeds';
}

SKIP: {
    my ($redis_version) = get_redis_version($connect_info{sock});
    skip 'on_push live test requires Redis 6+', 2 if $redis_version < 6;

    my $r = EV::Redis->new(path => $connect_info{sock});
    my @push_msgs;
    my $hello_ok = 0;

    my $timeout; $timeout = EV::timer 3, 0, sub {
        undef $timeout;
        $r->disconnect;
    };

    # on_push set only after connecting: the live registration path
    my $setup; $setup = EV::timer 0.1, 0, sub {
        undef $setup;

        $r->hello(3, sub {
            my ($res, $err) = @_;
            if ($err) {
                $r->disconnect;
                undef $timeout;
                return;
            }
            $hello_ok = 1;

            $r->on_push(sub {
                my ($msg) = @_;
                push @push_msgs, $msg;
            });

            $r->command('CLIENT', 'TRACKING', 'ON', 'BCAST', sub {
                $r->get('push:live:key', sub {
                    my $r2 = EV::Redis->new(path => $connect_info{sock});
                    $r2->set('push:live:key', 'modified', sub {
                        $r2->disconnect;
                        my $wait; $wait = EV::timer 0.2, 0, sub {
                            undef $wait;
                            $r->on_push(undef);
                            $r->disconnect;
                            undef $timeout;
                        };
                    });
                });
            });
        });
    };

    EV::run;

    skip 'RESP3 not available', 2 unless $hello_ok;

    ok scalar(@push_msgs) > 0, 'on_push live registration received push messages';
    is $push_msgs[0][0], 'invalidate', 'push message is invalidation';
}

# cloexec and reuseaddr as set on the socket; hiredis keeps both in one bit
SKIP: {
    skip 'needs /proc/self/fdinfo', 8 unless -r '/proc/self/fdinfo/0';
    require IO::Socket::INET;
    require POSIX;
    require Socket;
    my $lsn = IO::Socket::INET->new(Listen => 5, LocalAddr => '127.0.0.1')
        or skip "no TCP listener: $!", 8;
    my $sockets = sub {
        opendir my $d, '/proc/self/fd' or die $!;
        my %fd = map { $_ => readlink("/proc/self/fd/$_") // '' } grep { /^\d+$/ } readdir $d;
        return { map { $_ => 1 } grep { $fd{$_} =~ /^socket:/ } keys %fd };
    };
    for my $case ([0, 0], [0, 1], [1, 0], [1, 1]) {
        my ($cloexec, $reuseaddr) = @$case;
        my $before = $sockets->();
        my $r = EV::Redis->new(host => '127.0.0.1', port => $lsn->sockport,
            source_addr => '127.0.0.1', cloexec => $cloexec, reuseaddr => $reuseaddr,
            on_error => sub {});
        my ($fd) = grep { !$before->{$_} } keys %{ $sockets->() };
        open my $info, '<', "/proc/self/fdinfo/$fd" or die $!;
        my ($flags) = map { /^flags:\s*(\d+)/ ? oct $1 : () } <$info>;
        my $dup = POSIX::dup($fd);
        open my $fh, '+<&=', $dup or die $!;
        my $opt = unpack 'i', getsockopt($fh, Socket::SOL_SOCKET(), Socket::SO_REUSEADDR());
        close $fh;
        is(($flags & 02000000) ? 1 : 0, $cloexec, "cloexec => $cloexec, reuseaddr => $reuseaddr: close-on-exec");
        is($opt ? 1 : 0, $reuseaddr, "cloexec => $cloexec, reuseaddr => $reuseaddr: SO_REUSEADDR");
        $r->disconnect;
    }
}

done_testing;
