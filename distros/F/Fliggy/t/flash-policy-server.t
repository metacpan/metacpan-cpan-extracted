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

        $sock->print("<policy-file-request/>\0");

        my $res = join('', <$sock>);
        $sock->close;

        is $res => <<'EOF';
<?xml version="1.0"?>
<!DOCTYPE cross-domain-policy SYSTEM "/xml/dtds/cross-domain-policy.dtd">
<cross-domain-policy>
<site-control permitted-cross-domain-policies="master-only"/>
<allow-access-from domain="*" to-ports="*" secure="false"/>
</cross-domain-policy>
EOF
    },
    server => sub {
        my $port = shift;
        my $server =
          Plack::Loader->load('Fliggy', port => $port, host => '127.0.0.1');
        $server->run(sub { });
    }
);
