use strict;
use warnings;

use Test::More tests => 2;

use Log::Dispatch;
use Test::SharedFork;
use ZMQ;
use ZMQ::Constants qw(:all);
use POSIX ":sys_wait_h";
my $zmq_recv = $ZMQ::BACKEND eq 'ZMQ::LibZMQ2' ? 'recv' : 'recvmsg';

sub _log {
    my $sock_type = shift;
    Log::Dispatch->new(
        outputs => [[
           'ZMQ',
            zmq_sock_type => $sock_type,
            zmq_bind      => "tcp://127.0.0.1:8881",
            min_level     => 'info',
        ]],
    );
}


my $pid = Test::SharedFork->fork();

if ( $pid == 0 ) {
    my $log = _log('ZMQ_REQ');

    $log->info("Hello!");
    ok(1);
}
else {
    my $ctx    = ZMQ::Context->new;
    my $socket = $ctx->socket(ZMQ_REP);
    $socket->bind("tcp://127.0.0.1:8881");

    my $msg = $socket->$zmq_recv();

    cmp_ok($msg->data,'eq', "Hello!");

    my $kid;
    do {
        $kid = waitpid(-1, WNOHANG);
    } while $kid;
}



