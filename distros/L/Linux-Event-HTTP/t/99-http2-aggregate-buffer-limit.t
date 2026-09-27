use v5.36;
use strict;
use warnings;

use Test::More;
use Scalar::Util qw(refaddr);

BEGIN {
    eval {
        require Net::HTTP2::nghttp2;
        Net::HTTP2::nghttp2->VERSION('0.011');
        1;
    } or plan skip_all => 'Net::HTTP2::nghttp2 is not installed';

    Net::HTTP2::nghttp2->available
        or plan skip_all => 'nghttp2 library is not available';
}

use Linux::Event::HTTP::Client;
use Linux::Event::HTTP::Request;
use Linux::Event::HTTP::_HTTP2::Client;
use Linux::Event::Loop;

{
    package T::HTTP2AggregateBufferStream;
    use v5.36;

    sub new ($class) {
        return bless { wire => '' }, $class;
    }

    sub write ($self, $bytes) {
        $self->{wire} .= $bytes;
        return 1;
    }
}

sub request ($target) {
    return Linux::Event::HTTP::Request->new(
        method    => 'GET',
        target    => $target,
        version   => '2',
        scheme    => 'https',
        authority => 'example.test',
    );
}

sub start_response ($client, $stream_id) {
    $client->_on_begin_headers($stream_id, 1, 0);
    $client->_on_header($stream_id, ':status', '200', 0);
    $client->_on_frame_recv({
        type      => 1,
        stream_id => $stream_id,
        flags     => 0,
    });
}

my @error;
my $stream = T::HTTP2AggregateBufferStream->new;
my $client = Linux::Event::HTTP::_HTTP2::Client->new(
    stream                      => $stream,
    max_buffered_response_bytes => 10,
);

my $tx1 = $client->request(
    request('/one'),
    buffer_body => 100,
    on_error => sub ($tx, $error) {
        push @error, [ one => $tx, $error ];
    },
);

my $tx2 = $client->request(
    request('/two'),
    buffer_body => 100,
    on_error => sub ($tx, $error) {
        push @error, [ two => $tx, $error ];
    },
);

my $stream1 = $client->{tx_stream}{refaddr($tx1)};
my $stream2 = $client->{tx_stream}{refaddr($tx2)};

ok(defined($stream1) && defined($stream2),
    'two buffered requests have independent H2 stream ids');

start_response($client, $stream1);
start_response($client, $stream2);

$client->_on_data_chunk_recv($stream1, 'abcdef', 0);

is($client->{buffered_response_bytes}, 6,
    'first buffered response consumes connection aggregate budget');
ok(!$tx1->is_terminal,
    'first Transaction remains active while buffering');

$client->_on_data_chunk_recv($stream2, 'ghijkl', 0);

ok($tx2->is_terminal,
    'second Transaction fails when aggregate buffered bytes would cross cap');
is($tx2->state, 'error',
    'aggregate limit produces Transaction error');
is(scalar(@error), 1,
    'aggregate limit invokes one stream error callback');
is($error[0][0], 'two',
    'aggregate error identifies second stream');
like(
    $error[0][2],
    qr/aggregate buffered response body limit exceeded/,
    'aggregate buffer error is explicit',
);
is($client->{buffered_response_bytes}, 6,
    'rejected second chunk does not consume aggregate budget');

ok(!$client->{closed},
    'aggregate buffer failure does not close H2 connection');
ok(!$client->draining,
    'aggregate buffer failure does not mark H2 connection draining');
ok(!$tx1->is_terminal,
    'unrelated buffered Transaction remains healthy');

$client->_on_data_chunk_recv($stream1, 'ghij', 0);

is($client->{buffered_response_bytes}, 10,
    'first response may consume remaining aggregate budget');

$client->_on_frame_recv({
    type      => 0,
    stream_id => $stream1,
    flags     => 1,
});

ok($tx1->is_complete,
    'first buffered Transaction completes normally');
is($tx1->response->body, 'abcdefghij',
    'completed first response receives full buffered body');
is($client->{buffered_response_bytes}, 0,
    'completed response releases connection aggregate buffer accounting');

$client->_on_stream_close($stream2, 8);
is(scalar(@error), 1,
    'later close of already-failed stream does not duplicate error callback');
is($client->{buffered_response_bytes}, 0,
    'failed stream cleanup leaves aggregate accounting at zero');

{
    my $loop = Linux::Event::Loop->new;
    my $high = Linux::Event::HTTP::Client->new(
        loop  => $loop,
        http2 => 1,
        http2_max_buffered_response_bytes => 12_345,
    );

    is($high->http2_max_buffered_response_bytes, 12_345,
        'high-level Client exposes configured aggregate buffer limit');
    $high->close;
}

{
    my $ok = eval {
        Linux::Event::HTTP::Client->new(
            loop => Linux::Event::Loop->new,
            http2_max_buffered_response_bytes => 1024,
        );
        1;
    };
    ok(!$ok,
        'aggregate H2 buffer option is rejected when HTTP/2 is disabled');
    like($@, qr/http2_max_buffered_response_bytes requires http2 => 1/,
        'disabled-HTTP2 aggregate limit error is explicit');
}

{
    my $ok = eval {
        Linux::Event::HTTP::_HTTP2::Client->new(
            stream => T::HTTP2AggregateBufferStream->new,
            max_buffered_response_bytes => 0,
        );
        1;
    };
    ok(!$ok, 'private H2 Client rejects zero aggregate buffer limit');
    like($@, qr/max_buffered_response_bytes must be a positive integer/,
        'invalid aggregate buffer limit error is explicit');
}

done_testing;
