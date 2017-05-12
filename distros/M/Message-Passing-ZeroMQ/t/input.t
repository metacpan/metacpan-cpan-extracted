use strict;
use warnings;
use Test::More;

use AnyEvent;
use Message::Passing::Input::ZeroMQ;
use Message::Passing::Filter::Decoder::JSON;
use Message::Passing::Output::Test;
use ZMQ::FFI::Constants qw/ :all /;
use ZMQ::FFI;

# Test must fork, because it must sleep, and sleeping would put everything to sleep
my $pid = fork();
if ($pid){
    # Parent

    my $cv = AnyEvent->condvar;
    my $output = Message::Passing::Output::Test->new(
        cb => sub { $cv->send;},
    );
    my $dec = Message::Passing::Filter::Decoder::JSON->new(output_to => $output);
    my $input = Message::Passing::Input::ZeroMQ->new(
        socket_bind => 'tcp://*:5558',
        output_to   => $dec,
    );
    ok $input;

    $cv->recv;

    is $output->message_count, 1;

    is_deeply [$output->messages], [{message => "foo"}];

    done_testing;
    }
elsif (defined $pid){
    # Child
    my $ctx = ZMQ::FFI->new();
    my $socket = $ctx->socket(ZMQ_PUB);
    $socket->connect('tcp://127.0.0.1:5558');

    # Sleep, because of libzmq's pub/sub
    # See this link, and the "slow joiner" problem.
    # http://zguide.zeromq.org/page:all#Getting-the-Message-Out
    sleep 1;

    $socket->send('{"message":"foo"}');

    exit;
    }
else {
    die "Failed to fork";
    }

