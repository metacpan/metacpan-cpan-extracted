use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use EV;
use EV::Nats;
use MockNats;
use Time::HiRes ();

# Timers, file descriptors and flush across connection states, against a
# forked mock server.

sub run_guarded {
    my ($seconds) = @_;
    EV::now_update;
    my $g = EV::timer $seconds, 0, sub { EV::break };
    EV::run;
}

subtest 'a request armed after a blocking callback keeps its full timeout' => sub {
    plan tests => 2;
    my $mock = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c) or return;
        my $rd = MockNats->reader($c);
        my $buf = $rd->(qr/PUB echo (\S+) 4\r\nping\r\n/) or return;
        my ($reply) = $buf =~ /PUB echo (\S+) /;
        my $sid = (values %{ MockNats->subs_in($buf) })[0];
        select undef, undef, undef, 0.3;
        syswrite $c, MockNats->msg_frame($reply, $sid, undef, 'pong');
        sleep 2;
    })->start;

    my ($nats, @got);
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        on_error   => sub { diag "error: $_[0]" },
        on_connect => sub {
            my $t; $t = EV::timer 0, 0, sub {
                undef $t;
                Time::HiRes::sleep(1.5);
                $nats->request('echo', 'ping', sub { @got = @_; EV::break }, 1000);
            };
        },
    );
    run_guarded(6);
    is $got[0], 'pong', 'the reply arrived';
    is $got[1], undef, 'no spurious request timeout';
    $nats->disconnect;
    $mock->stop;
};

subtest 'connect_timeout armed after blocking work is not born expired' => sub {
    plan tests => 2;
    my $mock = MockNats->new(on_accept => sub {
        my ($c) = @_;
        MockNats->handshake($c) or return;
        sleep 2;
    })->start;

    EV::run(EV::RUN_NOWAIT);
    Time::HiRes::sleep(1.5);
    my ($up, $err);
    my $nats = EV::Nats->new(
        connect_timeout => 1000,
        on_connect => sub { $up = 1; EV::break },
        on_error   => sub { $err = $_[0]; EV::break },
    );
    $nats->connect('127.0.0.1', $mock->port);
    my $g = EV::timer 5, 0, sub { EV::break };
    EV::run;
    ok $up, 'connected';
    is $err, undef, 'no connect timeout';
    $nats->disconnect;
    $mock->stop;
};

subtest 'the connection socket is close-on-exec' => sub {
    plan skip_all => 'needs /proc/self/fdinfo' unless -d '/proc/self/fdinfo';
    plan tests => 2;
    my $mock = MockNats->new(on_accept => sub {
        my ($c) = @_;
        MockNats->handshake($c) or return;
        sleep 2;
    })->start;

    my $sockets = sub {
        my %s;
        for my $fd (map { m{/(\d+)\z} ? $1 : () } glob '/proc/self/fd/*') {
            my $link = readlink "/proc/self/fd/$fd";
            $s{$fd} = $link if defined $link && $link =~ /^socket:/;
        }
        return \%s;
    };
    my $before = $sockets->();
    my $up;
    my $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        on_connect => sub { $up = 1; EV::break },
        on_error   => sub { diag "error: $_[0]"; EV::break },
    );
    run_guarded(5);
    ok $up, 'connected';
    my $after = $sockets->();
    my @mine = grep { !defined $before->{$_} || $before->{$_} ne $after->{$_} } keys %$after;
    my @leaky;
    for my $fd (@mine) {
        open my $fi, '<', "/proc/self/fdinfo/$fd" or next;
        my ($flags) = map { /^flags:\s*([0-7]+)/ ? $1 : () } <$fi>;
        push @leaky, $fd if defined $flags && !(oct($flags) & 02000000);
    }
    is scalar(@mine) . " leaky=@leaky", '1 leaky=', 'the client socket does not survive exec';
    $nats->disconnect;
    $mock->stop;
};

subtest 'flush while connecting fences the queued writes after the handshake' => sub {
    plan tests => 3;
    my $mock = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->send_info($c);
        my $rd = MockNats->reader($c);
        $rd->(qr/PING\r\n/) or return;
        select undef, undef, undef, 0.3;
        syswrite $c, "PONG\r\n";
        my $buf = $rd->(qr/PING\r\n.*PING\r\n/s) or return;
        syswrite $c, "PONG\r\n";
        print $report ($buf =~ /PUB q 1\r\nx\r\nPING\r\n\z/ ? "ordered\n" : "unordered\n");
        sleep 2;
    })->start;

    my ($nats, @flushed);
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        on_error => sub { diag "error: $_[0]" },
    );
    $nats->publish('q', 'x');
    ok eval { $nats->flush(sub { @flushed = (1, $_[0]); EV::break }); 1 },
        'flush before on_connect does not croak';
    run_guarded(5);
    is_deeply \@flushed, [1, undef], 'it completed after the handshake';
    is $mock->report(5), 'ordered', 'its PING followed the queued publish';
    $nats->disconnect;
    $mock->stop;
};

subtest 'flush when down reports through the callback' => sub {
    plan tests => 4;
    my $nats = EV::Nats->new;
    my @got;
    ok eval { $nats->flush(sub { push @got, $_[0] }); 1 }, 'no croak with a callback';
    is scalar @got, 0, 'not called from inside flush';
    EV::run(EV::RUN_NOWAIT) for 1 .. 3;
    is_deeply \@got, ['not connected'], 'called from the loop with the error';
    ok !eval { $nats->flush; 1 }, 'flush without a callback still croaks';
};

subtest 'a flush queued during reconnect fails when the attempt fails' => sub {
    plan tests => 2;
    my $mock = MockNats->new(run => sub {
        my ($l) = @_;
        my $c = $l->accept or return;
        $c->autoflush(1);
        MockNats->handshake($c) or return;
        close $l;
        select undef, undef, undef, 0.2;
        close $c;
        sleep 3;
    })->start;
    close $mock->{srv};    # the parent's copy would still accept the retry

    my ($nats, @got, $croaked, $armed);
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        reconnect => 1, reconnect_delay => 300, max_reconnect_attempts => 1,
        on_error      => sub { },
        on_disconnect => sub {
            return if $armed++;
            my $t; $t = EV::timer 0, 0, sub {
                undef $t;
                $croaked = !eval { $nats->flush(sub { push @got, $_[0]; EV::break }); 1 };
            };
        },
    );
    run_guarded(5);
    ok !$croaked, 'flush while reconnecting queued';
    is_deeply \@got, ['disconnected'], 'and failed with the attempt';
    $nats->disconnect;
    $mock->stop;
};

subtest 'a queued flush fails when reconnecting gives up' => sub {
    plan tests => 2;
    my @got;
    my $nats = EV::Nats->new(
        path => "/nonexistent-ev-nats-$$.sock",
        reconnect => 1, reconnect_delay => 100, max_reconnect_attempts => 1,
        on_error => sub { },
    );
    ok eval { $nats->flush(sub { push @got, $_[0]; EV::break }); 1 }, 'queued';
    run_guarded(3);
    is_deeply \@got, ['disconnected'], 'failed once no attempt was left';
};

subtest 'reconnect(0) fails a flush waiting for the reconnect' => sub {
    plan tests => 2;
    my @got;
    my $nats = EV::Nats->new(
        path => "/nonexistent-ev-nats-$$.sock",
        reconnect => 1, reconnect_delay => 10_000,
        on_error => sub { },
    );
    $nats->flush(sub { push @got, $_[0] });
    is scalar @got, 0, 'queued';
    $nats->reconnect(0);
    is_deeply \@got, ['disconnected'], 'failed once reconnecting stopped';
};

subtest 'inbox_prefix' => sub {
    plan tests => 5;
    my $mock = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->handshake($c) or return;
        my $rd = MockNats->reader($c);
        my $buf = $rd->(qr/PUB svc (\S+) 1\r\nq\r\n/) or return;
        my ($reply) = $buf =~ /PUB svc (\S+) /;
        my ($wild, $sid) = %{ MockNats->subs_in($buf) };
        print $report "$wild $reply\n";
        syswrite $c, MockNats->msg_frame($reply, $sid, undef, 'a');
        sleep 2;
    })->start;

    my ($nats, @got);
    $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        inbox_prefix => '_INBOX_w1',
        on_error   => sub { diag "error: $_[0]" },
        on_connect => sub { $nats->request('svc', 'q', sub { @got = @_; EV::break }, 3000) },
    );
    like $nats->new_inbox, qr/\A_INBOX_w1\.[0-9a-f]{16}\.\d+\z/, 'new_inbox';
    run_guarded(5);
    like $mock->report(5), qr/\A_INBOX_w1\.[0-9a-f]{16}\.\* _INBOX_w1\.[0-9a-f]{16}\.\d+\z/,
        'request inbox subscription and reply subject';
    is $got[0], 'a', 'the reply was routed';
    my @bad = grep { !eval { EV::Nats->new(inbox_prefix => $_); 1 } }
        ('', 'a.*', 'a.>', 'a..b', '.a', 'a.', 'a b', 'x' x 65);
    is scalar @bad, 8, 'invalid prefixes croak';
    like(EV::Nats->new(inbox_prefix => undef)->new_inbox, qr/\A_INBOX\./, 'undef keeps the default');
    $nats->disconnect;
    $mock->stop;
};

done_testing;
