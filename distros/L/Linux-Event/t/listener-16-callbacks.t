use v5.36;
use strict;
use warnings;

use Test::More;
use Socket qw(AF_INET SOCK_STREAM inet_aton pack_sockaddr_in);

use Linux::Event::IO::Sock::Listener;
use Linux::Event::Loop;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::IO::Sock::Stream;

{
    package T::CallbackStream;
    use parent 'Linux::Event::IO::Sock::Stream';

    sub on_ready ($stream) {
        $stream->data->{ready}++;
        return;
    }

    sub on_data ($stream, $bytes) { return }

    sub on_close ($stream) {
        $stream->data->{closed}++;
        return;
    }
}

{
    package T::FailingAcceptListener;
    use parent 'Linux::Event::IO::Sock::Listener';

    sub on_accept ($listener, $stream) {
        $stream->data->{stream} = $stream;
        die "application rejected accept\n";
    }

    sub on_error ($listener, $error) {
        $listener->data->{error} = $error;
        $listener->loop->stop;
        return;
    }
}

my $loop = Linux::Event::Loop->new;
my $state = { ready => 0, closed => 0 };
my $listener = T::FailingAcceptListener->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0,
    stream => { class => 'T::CallbackStream', data => $state },
    on_error => sub ($listener, $error) {
        $state->{error} = $error;
        $listener->loop->stop;
    },
);

socket(my $client, AF_INET, SOCK_STREAM, 0) or die "socket: $!";
connect($client, pack_sockaddr_in($listener->port, inet_aton('127.0.0.1')))
    or die "connect: $!";
$loop->run;

isa_ok($state->{error}, 'Linux::Event::Error');
is($state->{error}->type, 'callback',
    'on_accept exception becomes a callback error');
is($state->{error}->operation, 'on_accept',
    'callback error identifies on_accept');
like($state->{error}->message, qr/application rejected accept/,
    'callback error retains the exception message');
ok(!$state->{error}->fatal, 'on_accept callback failure is not Listener-fatal');
is($listener->last_error, $state->{error},
    'Listener retains the callback error');
ok($state->{stream}->is_closed,
    'on_accept exception closes the constructed Stream');
is($state->{closed}, 1, 'failed accepted Stream closes exactly once');
is($state->{ready}, 0, 'failed on_accept suppresses Stream on_ready');
is($listener->state, 'listening',
    'handled callback error leaves Listener accepting');

$listener->close;
close $client;

{
    package T::BrokenAttachStream;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($stream, $bytes) { }
    sub on_close ($stream) { $stream->data->{setup_closed}++ }
    sub _attach_to_loop ($stream, $loop) {
        die "synthetic accepted Stream attachment failure\n";
    }
}

{
    package T::SetupFailureListener;
    use parent 'Linux::Event::IO::Sock::Listener';
    sub on_error ($listener, $error) {
        $listener->data->{setup_error} = $error;
        $listener->loop->stop;
    }
}

my $setup_loop = Linux::Event::Loop->new;
my $setup_state = { setup_closed => 0 };
my $setup_listener = T::SetupFailureListener->new(
    loop => $setup_loop,
    host => '127.0.0.1',
    port => 0,
    stream => { class => 'T::BrokenAttachStream', data => $setup_state },
    on_error => sub ($listener, $error) {
        $setup_state->{setup_error} = $error;
        $listener->loop->stop;
    },
);
socket(my $setup_client, AF_INET, SOCK_STREAM, 0) or die "socket: $!";
connect($setup_client,
    pack_sockaddr_in($setup_listener->port, inet_aton('127.0.0.1')))
    or die "connect: $!";
$setup_loop->run;
is($setup_state->{setup_error}->type, 'setup',
    'accepted Stream attachment failure is typed');
is($setup_state->{setup_error}->operation, 'accepted_socket',
    'accepted setup error identifies Stream attachment');
is($setup_state->{setup_closed}, 1,
    'accepted Stream attachment failure closes the Stream exactly once');
is($setup_listener->state, 'listening',
    'handled accepted setup failure leaves Listener active');
$setup_listener->close;
close $setup_client;
done_testing;
