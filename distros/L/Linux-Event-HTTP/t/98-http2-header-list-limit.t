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

use Linux::Event::HTTP::Request;
use Linux::Event::HTTP::_HTTP2::Client;
use Linux::Event::HTTP::_HTTP2::Server;

{
    package T::HTTP2HeaderLimitStream;
    use v5.36;

    sub new ($class) {
        return bless { wire => '' }, $class;
    }

    sub write ($self, $bytes) {
        $self->{wire} .= $bytes;
        return 1;
    }

    sub wire ($self) {
        return $self->{wire};
    }
}

sub settings_value ($wire, $client_preface, $wanted_id) {
    my $offset = $client_preface ? 24 : 0;
    while ($offset + 9 <= length($wire)) {
        my $length =
            (ord(substr($wire, $offset, 1)) << 16)
            | (ord(substr($wire, $offset + 1, 1)) << 8)
            | ord(substr($wire, $offset + 2, 1));
        my $type = ord(substr($wire, $offset + 3, 1));
        last if $offset + 9 + $length > length($wire);

        if ($type == 4) {
            my $payload = substr($wire, $offset + 9, $length);
            for (my $pos = 0; $pos + 6 <= length($payload); $pos += 6) {
                my ($id, $value) = unpack 'nN', substr($payload, $pos, 6);
                return $value if $id == $wanted_id;
            }
        }

        $offset += 9 + $length;
    }
    return undef;
}

my @server_error;
my $server_request_hits = 0;
my $server_stream = T::HTTP2HeaderLimitStream->new;
my $server = Linux::Event::HTTP::_HTTP2::Server->new(
    stream               => $server_stream,
    max_header_list_size => 96,
    on_request => sub {
        ++$server_request_hits;
    },
    on_error => sub ($executor, $stream_id, $error) {
        push @server_error, [ $stream_id, $error ];
    },
);

is(
    settings_value($server_stream->wire, 0, 6),
    96,
    'server advertises SETTINGS_MAX_HEADER_LIST_SIZE',
);

$server->_on_begin_headers(1, 1, 0);
$server->_on_header(1, ':method', 'GET', 0);
$server->_on_header(1, ':path', '/', 0);

is($server_request_hits, 0,
    'request is not materialized before complete header block');
is(scalar(@server_error), 0,
    'server accepts header block while decoded size is within limit');

$server->_on_header(1, 'x-test', 'x' x 20, 0);

is(scalar(@server_error), 1,
    'server rejects decoded request header list over configured limit');
is($server_error[0][0], 1,
    'server header-limit error identifies offending stream');
like(
    $server_error[0][1],
    qr/request header list exceeds configured limit/,
    'server reports explicit request header-list limit error',
);

$server->_on_header(1, 'x-after', 'ignored', 0);
$server->_on_frame_recv({
    type      => 1,
    stream_id => 1,
    flags     => 1,
});

is(scalar(@server_error), 1,
    'server reports oversized header block only once');
is($server_request_hits, 0,
    'oversized request never reaches application on_request');

my @client_error;
my $client_stream = T::HTTP2HeaderLimitStream->new;
my $client = Linux::Event::HTTP::_HTTP2::Client->new(
    stream               => $client_stream,
    max_header_list_size => 80,
);

is(
    settings_value($client_stream->wire, 1, 6),
    80,
    'client advertises SETTINGS_MAX_HEADER_LIST_SIZE',
);

my $request = Linux::Event::HTTP::Request->new(
    method    => 'GET',
    target    => '/',
    version   => '2',
    scheme    => 'https',
    authority => 'example.test',
);

my $tx = $client->request(
    $request,
    on_error => sub ($transaction, $error) {
        push @client_error, [ $transaction, $error ];
    },
);

my $stream_id = $client->{tx_stream}{refaddr($tx)};
ok(defined($stream_id), 'client request has an HTTP/2 stream id');

$client->_on_begin_headers($stream_id, 1, 0);
$client->_on_header($stream_id, ':status', '200', 0);

ok(!$tx->is_terminal,
    'client accepts response header list while within configured limit');

$client->_on_header($stream_id, 'x-test', 'x' x 20, 0);

ok($tx->is_terminal,
    'oversized response header list terminates only its Transaction');
is($tx->state, 'error',
    'oversized response header list marks Transaction error');
is(scalar(@client_error), 1,
    'client invokes on_error once for oversized response header list');
is(refaddr($client_error[0][0]), refaddr($tx),
    'client error callback receives offending Transaction');
like(
    $client_error[0][1],
    qr/response header list exceeds configured limit/,
    'client reports explicit response header-list limit error',
);

ok(!$client->draining,
    'stream header-list failure does not mark whole H2 connection draining');
ok(!$client->{closed},
    'stream header-list failure does not close whole H2 executor');

{
    my $ok = eval {
        Linux::Event::HTTP::_HTTP2::Client->new(
            stream               => T::HTTP2HeaderLimitStream->new,
            max_header_list_size => 0,
        );
        1;
    };
    ok(!$ok, 'client rejects zero header-list limit');
    like($@, qr/max_header_list_size must be a positive integer/,
        'client invalid header-list limit error is explicit');
}

{
    my $ok = eval {
        Linux::Event::HTTP::_HTTP2::Server->new(
            stream               => T::HTTP2HeaderLimitStream->new,
            max_header_list_size => 'bad',
            on_request           => sub {},
        );
        1;
    };
    ok(!$ok, 'server rejects non-numeric header-list limit');
    like($@, qr/max_header_list_size must be a positive integer/,
        'server invalid header-list limit error is explicit');
}

done_testing;
