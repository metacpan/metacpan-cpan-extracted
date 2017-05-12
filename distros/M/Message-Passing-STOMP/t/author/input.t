use strict;
use warnings;
use Test::More;

use Net::Stomp;
my $stomp = Net::Stomp->new( { hostname => 'localhost', port => '6163' } );
$stomp->connect( { login => 'guest', passcode => 'guest' } );
$stomp->send(
    { destination => '/queue/foo', body => '{"message":"foo"}' } );
$stomp->disconnect;

use AnyEvent;
use Message::Passing::Input::STOMP;
use Message::Passing::Output::Test;

my $cv = AnyEvent->condvar;
my $output = Message::Passing::Output::Test->new(
    cb => sub { $cv->send },
);
my $input = Message::Passing::Input::STOMP->new(
    output_to => $output,
    destination => '/queue/foo',
    hostname => '127.0.0.1',
);
ok $input;

$cv->recv;

is $output->message_count, 1;
is_deeply [$output->messages], ['{"message":"foo"}'];

done_testing;

