use strict;
use warnings;
use Test::More;

my ($host, $port, $secret);
BEGIN {
    $INC{'ESL.pm'} = 1;
    *ESL::ESLconnection::new = sub {
        shift();
        ($host, $port, $secret) = @_;
        return bless {}, 'ESL::ESLconnection';
    };
    *ESL::ESLconnection::events = sub {};
    *ESL::ESLconnection::connected = sub { 1 };
    *ESL::ESLconnection::socketDescriptor = sub { 0 }; # STDIN

    my @stuff = ('foo', 'bar', 'baz', 'quux');

    my $event = bless {}, 'ESL::Event';
    *ESL::ESLconnection::recvEventTimed = sub { scalar(@stuff) ? $event : undef };
    *ESL::Event::nextHeader = sub { shift(@stuff) };
    *ESL::Event::firstHeader = *ESL::Event::nextHeader;
    *ESL::Event::getHeader = *ESL::Event::nextHeader;
}

use AnyEvent;
use Message::Passing::Input::Freeswitch;
use Message::Passing::Output::Test;

my $cv = AnyEvent->condvar;
my $output = Message::Passing::Output::Test->new(
    cb => sub { $cv->send },
);
my $input = Message::Passing::Input::Freeswitch->new(
    hostname => "foo",
    secret => "bar",
    output_to => $output,
);
ok $input;
is $host, "foo";
is $port, 8021;
is $secret, "bar";

$input->_try_rx;

$cv->recv;

is $output->message_count, 1;

is_deeply [$output->messages], [{baz => "quux", foo => "bar"}];

done_testing;

