use strict;
use warnings;
use Test::More;

use AnyEvent;
use JSON qw/ encode_json /;
use Message::Passing::Input::ZeroMQ;
use Message::Passing::Output::Test;
use Message::Passing::Output::ZeroMQ;
use Message::Passing::Filter::Decoder::JSON;

my $pid = fork;
if ($pid){
    # Parent
    my $cv = AnyEvent->condvar;

    my $input = Message::Passing::Input::ZeroMQ->new(
        socket_bind => 'tcp://*:5558',
        output_to => Message::Passing::Filter::Decoder::JSON->new(output_to => Message::Passing::Output::Test->new(
            cb => sub { $cv->send }
        )),
    );
    $cv->recv;

    is $input->output_to->output_to->message_count, 1;
    is_deeply([$input->output_to->output_to->messages], [{foo => 'bar'}]);

    done_testing;
    }
elsif (defined $pid){
    # Child
    my $output = Message::Passing::Output::ZeroMQ->new(
        connect => 'tcp://127.0.0.1:5558',
    );

    $output->consume(encode_json {foo => 'bar'});

    exit;
    }
else {
    die "Failed to fork";
    }
