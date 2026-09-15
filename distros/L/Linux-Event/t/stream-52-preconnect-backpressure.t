use v5.36;
use strict;
use warnings;
use Test::More;

use Linux::Event::IO::Sock::Listener;
use Linux::Event::Loop;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::IO::Sock::Stream;

{
    package T::PreconnectSink;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($stream, $bytes) {
        $stream->data->{received} .= $bytes;
    }
}

{
    package T::PreconnectClient;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub stream_tuning ($class) {
        return high_watermark => 8, low_watermark => 4;
    }
    sub on_data ($stream, $bytes) { return }
    sub on_ready ($stream) { $stream->data->{ready}++ }
    sub on_drain ($stream) { $stream->data->{drain}++ }
    sub on_error ($stream, $error) {
        $stream->data->{error} = "$error";
    }
}

my $loop = Linux::Event::Loop->new;
my $state = { received => '', ready => 0, drain => 0, error => '' };
my $listener = Linux::Event::IO::Sock::Listener->new(
    loop => $loop,
    host => '127.0.0.1', port => 0,
    stream => { class => 'T::PreconnectSink', data => $state },
);
my $client = T::PreconnectClient->connect(
    host => '127.0.0.1', port => $listener->port,
    timeout => 1, data => $state,
);

ok($client->write('1234'),
    'pre-connect write below high watermark permits more output');
ok($client->write('5678'),
    'pre-connect queue exactly at high watermark remains writable');
ok(!$client->write('9'),
    'pre-connect queue above high watermark applies backpressure');
is($client->pending_bytes, 9, 'all pre-connect bytes are accepted in order');

$loop->add($client);
$loop->run_for(0.25);

is($state->{error}, '', 'connection and delivery have no error');
is($state->{ready}, 1, 'Stream becomes ready once');
is($state->{received}, '123456789',
    'pre-connect bytes are delivered in original order');
is($state->{drain}, 1,
    'blocked pre-connect interval produces exactly one drain notification');
ok(!$client->is_write_blocked, 'blocked interval is clear after delivery');

$client->close;
$listener->close;
done_testing;
