use v5.36;
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);

use Linux::Event::Loop;
use Linux::Event::IO::Sock::Listener;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::IO::Sock::Stream;

our ($LOOP, $CLIENT_ID, $READY, $REPLY, $SERVER_PEER, $ERROR);

{
    package T::AutomaticEcho;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Delimiter', "\n";

    sub on_message ($stream, $message) {
        $main::SERVER_PEER = $stream->peer;
        $stream->send($message);
    }

    sub on_error ($stream, $error) {
        $main::ERROR = "$error";
        $main::LOOP->stop;
    }
}

{
    package T::AutomaticClient;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::Framer 'Delimiter', "\n";

    sub on_ready ($stream) {
        $main::READY++;
        die 'connecting Stream identity changed'
            if Scalar::Util::refaddr($stream) != $main::CLIENT_ID;
    }

    sub on_message ($stream, $message) {
        $main::REPLY = $message;
        $stream->close;
        $main::LOOP->stop;
    }

    sub on_error ($stream, $error) {
        $main::ERROR = "$error";
        $main::LOOP->stop;
    }
}

$LOOP = Linux::Event::Loop->new;
my $listener = Linux::Event::IO::Sock::Listener->new(
    stream => { class => 'T::AutomaticEcho' },
    host => '127.0.0.1',
    port => 0,
);
isa_ok($listener, 'Linux::Event::IO::Sock::Listener');
is($listener->state, 'unattached', 'Listener construction is detached');
is($LOOP->add($listener), $listener, 'add returns the same Listener');
is($listener->state, 'listening', 'add starts the Listener');
is($listener->loop, $LOOP, 'add sets the Listener loop');
my $reattach = eval { $LOOP->add($listener); 1 };
ok(!$reattach, 'Listener rejects a second attachment');
like($@, qr/not unattached/, 'Listener reattachment failure is explicit');

my $client = T::AutomaticClient->connect(
    host => '127.0.0.1',
    port => $listener->port,
    timeout => 5,
);
$CLIENT_ID = refaddr($client);
is($client->state, 'unattached', 'connecting Stream construction is detached');
ok($client->send('hello'),
    'queued pre-connect send below high watermark permits more output');
is($client->pending_bytes, 6, 'pre-connect queue includes outbound framing');
is($LOOP->add($client), $client, 'add returns the same Stream');
is($client->state, 'connecting', 'add starts outbound connection');
is($client->loop, $LOOP, 'add sets the Stream loop');
$reattach = eval { $LOOP->add($client); 1 };
ok(!$reattach, 'Stream rejects a second attachment');
like($@, qr/not unattached/, 'Stream reattachment failure is explicit');

$LOOP->run;

is($ERROR, undef, 'automatic client/server path has no error');
is($READY, 1, 'on_ready fires once after the connection is usable');
is($REPLY, 'hello', 'automatic accepted Stream echoes one framed message');
isa_ok($SERVER_PEER, 'Linux::Event::Address');
is(refaddr($client), $CLIENT_ID, 'client retains identity through connection');
is($client->state, 'closed', 'client reaches terminal state');

$listener->close;
done_testing;
