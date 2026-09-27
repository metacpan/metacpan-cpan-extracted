use v5.36;
use strict;
use warnings;

use Test::More;
use IO::Socket::INET;
use POSIX ();

use Linux::Event::HTTP::Server;
use Linux::Event::Loop;

my $loop = Linux::Event::Loop->new;
my $server;

$server = Linux::Event::HTTP::Server->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0,
    on_request => sub ($conn, $req, $res) {
        $res->header('Content-Type', 'text/plain');
        $res->body("child-worker\n");
    },
    on_close => sub ($conn) {
        $loop->stop;
    },
);

my $pid = $loop->fork(
    share => [ $server->listener ],
);

if (!defined $pid) {
    die "managed fork failed: $!";
}

if ($pid == 0) {
    my $ok = eval {
        $loop->run_for(5);
        1;
    };
    if (!$ok) {
        warn $@;
        POSIX::_exit(2);
    }
    POSIX::_exit(0);
}

# Keep the shared listening socket open in the parent, but make only the child
# Loop eligible to accept this test connection.
$server->pause;

my $client = IO::Socket::INET->new(
    PeerAddr => '127.0.0.1',
    PeerPort => $server->port,
    Proto    => 'tcp',
    Timeout  => 3,
);
ok($client, 'parent connects to Listener shared with managed-fork child');

my $wire = '';
if ($client) {
    print {$client}
        "GET /worker HTTP/1.1\r\n",
        "Host: localhost\r\n",
        "Connection: close\r\n",
        "\r\n";

    local $SIG{ALRM} = sub { die "managed-fork HTTP read timed out\n" };
    alarm 4;
    my $ok = eval {
        while (1) {
            my $read = sysread($client, my $chunk, 16_384);
            die "managed-fork HTTP read failed: $!" if !defined $read;
            last if $read == 0;
            $wire .= $chunk;
        }
        1;
    };
    my $error = $@;
    alarm 0;
    close $client;
    die $error if !$ok;
}

my $waited = waitpid($pid, 0);
is($waited, $pid, 'managed-fork child is reaped');
is($? >> 8, 0, 'managed-fork child exits cleanly');

like(
    $wire,
    qr{\AHTTP/1\.1 200 OK\r\n}s,
    'child serves HTTP through shared Listener',
);
like(
    $wire,
    qr{\r\n\r\nchild-worker\n\z}s,
    'child response body reaches parent client',
);

$server->close;

done_testing;
