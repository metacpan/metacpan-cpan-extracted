use strict;
use warnings;

use Test::More tests => 1;

use IO::Socket::INET;
use Plack::Loader;
use Test::TCP;

test_tcp(
    client => sub {
        my $port = shift;

        my $sock = IO::Socket::INET->new(
            Proto    => 'tcp',
            PeerAddr => '127.0.0.1',
            PeerPort => $port,
        ) or die "Cannot open client socket: $!";
        $sock->autoflush;

        $sock->print("GET / HTTP/1.0\r\n\r\n");

        my $res = join('', <$sock>);
        $sock->close;

        is $res => "HTTP/1.0 200 OK\r\n\r\n";
    },
    server => sub {
        my $port = shift;
        my $server =
          Plack::Loader->load('Fliggy', port => $port, host => '127.0.0.1');
        $server->run(sub { [200, [], ['']] });
    }
);
