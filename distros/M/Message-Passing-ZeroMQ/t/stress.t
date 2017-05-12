use strict;
use warnings;
use Test::More;
use AnyEvent;
use JSON qw/ encode_json /;
use Message::Passing::Input::ZeroMQ;
use Message::Passing::Output::Test;
use Message::Passing::Output::ZeroMQ;
use Message::Passing::Filter::Decoder::JSON;
use Time::HiRes qw( gettimeofday tv_interval );

my $parent = $$;

our $ITRS = 100000;

sub _receiver_child {
    my $i = 0;
    my $cv = AnyEvent->condvar;
    my $input = Message::Passing::Input::ZeroMQ->new(
        socket_bind => 'tcp://*:5558',
        socket_hwm => 0,
        output_to => Message::Passing::Filter::Decoder::JSON->new(output_to => Message::Passing::Output::Test->new(
            cb => sub {
                $i++;
                $cv->send if $i > $::ITRS;
            },
        )),
    );
    $cv->recv;
    exit 0;
}

sub _sender_child {
    my $output = Message::Passing::Output::ZeroMQ->new(
        connect => 'tcp://127.0.0.1:5558',
        linger => 1,
        socket_hwm => 0,
    );

    my $run = sub {
        $output->consume(encode_json {foo => 'bar'}) for 0..$::ITRS;
        exit 0;
    };
    local $SIG{USR1} = sub { goto $run };
    while (1) { sleep 1 }
};

my $receiver_pid = fork;
if ($receiver_pid) { # Parent
}
else { # Child
    _receiver_child();
}

my $sender_pid = fork;
if ($sender_pid) { #Parent
}
else { # Child
    _sender_child();
}
sleep 2; # Wait for children to spin up.
my $t0 = [gettimeofday];
#print "the code took:",timestr($td),"\n";
kill('USR1', $sender_pid);

is waitpid($sender_pid, 0), $sender_pid;
is waitpid($receiver_pid, 0), $receiver_pid;
my $elapsed = tv_interval ( $t0, [gettimeofday]);
diag "Took " . $elapsed . "s for " . $ITRS . " iterations";
diag $ITRS/$elapsed . " messages per second";

done_testing;

