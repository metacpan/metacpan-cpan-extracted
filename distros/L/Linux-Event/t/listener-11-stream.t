use v5.36;
use strict;
use warnings;
use Test::More;
use Socket qw(AF_INET SOCK_STREAM inet_aton pack_sockaddr_in);

use Linux::Event::Loop;
use Linux::Event::IO::Sock::Listener;

{
    package T::LineEchoStream;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Delimiter', "\n";
    sub stream_tuning ($class) { return idle_timeout => 60 }
    sub on_message ($self, $message) {
        $self->data->{stream} = $self;
        $self->send($message);
        $self->data->{messages}++;
        $self->loop->stop;
    }
}

my $loop = Linux::Event::Loop->new;
my $state = { streams => [], messages => 0 };
my $listener = Linux::Event::IO::Sock::Listener->new(
    loop => $loop, host => '127.0.0.1', port => 0,
    stream => { class => 'T::LineEchoStream', data => $state },
);
socket(my $client, AF_INET, SOCK_STREAM, 0) or die "socket: $!";
connect($client, pack_sockaddr_in($listener->port, inet_aton('127.0.0.1')))
    or die "connect: $!";
is(syswrite($client, "hello\n"), 6, 'client sends one framed line');
$loop->run;
$loop->run_once(0);

ok(!$state->{error}, 'Listener constructs the Stream automatically');
is($state->{messages}, 1, 'Stream parses one line');
is($state->{stream}->idle_timeout, 60,
    'accepted Stream receives its subclass deadline policy');
is(sysread($client, my $echo, 6), 6, 'client receives complete echo');
is($echo, "hello\n", 'send reapplies the declared line delimiter');

$listener->close;
close $client;
done_testing;
