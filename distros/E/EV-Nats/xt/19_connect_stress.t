use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../t/lib";
use Socket qw(AF_INET AF_INET6 AF_UNSPEC SOCK_STREAM);
use EV;
use EV::Nats;
use MockNats;

# Author-only connect-path stress regressions: slow (~10s) and dependent
# on host specifics (send-buffer size, dual-stack localhost). Everything
# is bounded by guard timers and skips where the environment cannot
# exercise the bug.

plan tests => 2;

subtest 'CONNECT flush larger than the send buffer survives EAGAIN' => sub {
    plan tests => 3;
    # The bug bites only if the flush EXCEEDS the socket send buffer, so
    # nats_try_write really gets EAGAIN and arms the write watcher.
    my $wmem_max = 4 * 1024 * 1024;
    if (open my $f, '<', '/proc/sys/net/ipv4/tcp_wmem') {
        my @f = split ' ', <$f>;
        close $f;
        $wmem_max = $f[2] if @f >= 3 && $f[2] && $f[2] > 0;
    }
    # One SUB line is ~70 bytes; overshoot the buffer by 2 MB.
    my $nsubs = int(($wmem_max + 2 * 1024 * 1024) / 70) + 10_000;
    plan skip_all => "send buffer too large to overflow sensibly (wmem max $wmem_max)"
        if $nsubs > 300_000;

    my $stall = 2;
    my $mock = MockNats->new(on_accept => sub {
        my ($c, $report) = @_;
        MockNats->send_info($c);
        sleep $stall;                    # let the client's send buffer fill
        my ($total, $ponged, $buf) = (0, 0, '');
        my $deadline = time + 20;
        while (time < $deadline) {
            my $rin = ''; vec($rin, fileno($c), 1) = 1;
            if (select(my $r = $rin, undef, undef, 0.2)) {
                my $n = sysread($c, my $ch, 1 << 20); last unless $n;
                $total += $n; $buf .= $ch;
                if (!$ponged && $buf =~ /PING\r\n/) {
                    syswrite($c, "PONG\r\n");
                    $ponged = 1;
                    last;
                }
                $buf = substr($buf, -16) if length($buf) > 1024;
            }
        }
        print $report "bytes=$total ponged=$ponged\n";
        select undef, undef, undef, 0.5;
    })->start;

    diag sprintf '%d subscriptions (~%.1f MB flush), mock stalls %ds then drains fast',
        $nsubs, $nsubs * 70 / 1048576, $stall;

    my $ever = 0;
    my $nats = EV::Nats->new(
        host => '127.0.0.1', port => $mock->port,
        on_error   => sub { diag "error: $_[0]" },
        on_connect => sub { $ever = 1; EV::break },
    );
    my $cb = sub { };
    $nats->subscribe("subject.number.$_.with.some.padding.to.make.it.longer", $cb)
        for 1 .. $nsubs;

    my $guard = EV::timer 30, 0, sub { EV::break };
    EV::run;
    my $line = $mock->report(25);
    $mock->stop;

    my ($bytes, $ponged) = $line =~ /\Abytes=(\d+) ponged=(\d+)\z/ ? ($1, $2) : (0, 0);
    cmp_ok $bytes, '>', $wmem_max,
        "flush really exceeded the send buffer (bytes=$bytes, wmem max $wmem_max)";
    is $ponged, 1, 'trailing PING reached the mock (write watcher resumed)';
    ok $ever, 'client reached connected after the EAGAIN stall';
};

subtest "IPv4-only server reachable as 'localhost' on a dual-stack host" => sub {
    plan tests => 2;
    my ($err, @res) = Socket::getaddrinfo('localhost', '0',
        { family => AF_UNSPEC, socktype => SOCK_STREAM });
    plan skip_all => "cannot resolve localhost: $err" if $err;
    my @fams = map { $_->{family} } @res;
    plan skip_all => 'localhost does not resolve to both IPv6 and IPv4'
        unless grep({ $_ == AF_INET6 } @fams) && grep({ $_ == AF_INET } @fams);
    plan skip_all => 'localhost resolves IPv4-first here; failover path not exercisable'
        unless $fams[0] == AF_INET6;
    my $v6 = eval { socket(my $probe, AF_INET6, SOCK_STREAM, 0) };
    plan skip_all => 'no IPv6 socket support' unless $v6;

    # IPv4-only listener, exactly like a default nats-server on 0.0.0.0:
    # the ::1 candidate must fail over to 127.0.0.1, not discard the rest
    # of the getaddrinfo list.
    my $mock = MockNats->new(run => sub {
        my ($listen, $report) = @_;
        while (my $c = $listen->accept) {
            $c->autoflush(1);
            MockNats->handshake($c);
            close $c;
        }
    })->start;

    for my $host ('127.0.0.1', 'localhost') {
        my ($ever, $errs) = (0, 0);
        my $nats = EV::Nats->new(
            host => $host, port => $mock->port,
            reconnect => 1, reconnect_delay => 200,
            on_error   => sub { $errs++ },
            on_connect => sub { $ever = 1; EV::break },
        );
        my $guard = EV::timer 5, 0, sub { EV::break };
        EV::run;
        ok $ever, "connected to IPv4-only mock via host => '$host'"
            or diag "errors seen: $errs";
        undef $nats;
    }
    $mock->stop;
};
