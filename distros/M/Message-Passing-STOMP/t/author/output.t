use strict;
use warnings;
use Test::More;

use AnyEvent;
use Message::Passing::Input::STOMP;
use Message::Passing::Output::Test;
use Message::Passing::Output::STOMP;
use JSON;

use Net::Stomp;
my $stomp = Net::Stomp->new( { hostname => 'localhost', port => '6163' } );
$stomp->connect( { login => 'guest', passcode => 'guest' } );
$stomp->subscribe(
    {   destination             => '/queue/foo',
        'ack'                   => 'client',
        'activemq.prefetchSize' => 1
    }
);

my $output = Message::Passing::Output::STOMP->new(
    destination => '/queue/foo',
    hostname => '127.0.0.1',
);
my $cv = AnyEvent->condvar;
my $timer; $timer = AnyEvent->timer(after => 1, cb => sub { undef $timer; $cv->send });
$cv->recv;
$output->consume('{"foo":"bar"}');
my $frame = $stomp->receive_frame;
$stomp->ack( { frame => $frame } );
$stomp->disconnect;

is_deeply(decode_json($frame->body), {foo => 'bar'});

done_testing;

