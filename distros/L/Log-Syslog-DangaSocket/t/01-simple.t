use strict;
use warnings;

use Test::More tests => 1 + 3 * 4;
BEGIN { use_ok('Log::Syslog::DangaSocket') };

use IO::Socket::INET;
use IO::Socket::UNIX;

$SIG{CHLD} = 'IGNORE';

my $proto;
for $proto (qw/ tcp udp unix /) {

    my $test_host = $proto eq 'unix' ? '/tmp/testdevlog' : 'localhost';

    my $listener;
    my $test_port = 0;
    if ($proto eq 'unix') {
        $listener = IO::Socket::UNIX->new(
            Local  => $test_host,
            Listen => 1,
        );
    }
    else {
        $listener = IO::Socket::INET->new(
            Proto       => $proto,
            LocalHost   => 'localhost',
            LocalPort   => 0,
            ($proto eq 'tcp' ? (Listen => 5) : ()),
            Reuse       => 1,
        );
        $test_port = $listener->sockport;
    }
    ok($listener, "$proto: listen on port $test_port");

    my $pid = fork;
    die "fork failed" unless defined $pid;

    if (!$pid) {
        sleep 1;
        my $logger = Log::Syslog::DangaSocket->new(
            $proto,
            $test_host,
            $test_port,
            'testhost',
            'LogSyslogDangaSocketTest',
            16,
            5,
        );
        Danga::Socket->AddTimer(1, sub {
            $logger->send('message');
            exit 0;
        } );
        Danga::Socket->EventLoop;
        die "shouldn't be here";
    }

    my $receiver = $listener;
    if ($proto eq 'tcp' || $proto eq 'unix') {
        $receiver = $listener->accept;
        $receiver->blocking(0);
    }

    vec(my $rin = '', fileno($receiver), 1) = 1;
    my $found = select(my $rout = $rin, undef, undef, 5);

    ok($found, "$proto: didn't time out while waiting for data");

    if ($found) {
        $receiver->recv(my $buf, 256);
        ok($buf =~ /^<133>/, "$proto: message the right priority");
        ok($buf =~ /message$/, "$proto: message has the right payload");
    }

    kill 9, $pid;
    unlink $test_host if $proto eq 'unix';
}
