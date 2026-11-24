use strict;
use warnings;
use Test::More;

use_ok('Google::gRPC::Server');
use_ok('Google::gRPC::Engine::PP');
use_ok('Google::gRPC::Framing');
use_ok('Google::gRPC::Status');

{
    package MockProtoReq;
    sub decode {
        my ($class, $bytes) = @_;
        return bless { text => $bytes }, $class;
    }
    sub text { return $_[0]->{text} }

    package MockProtoResp;
    sub new {
        my ($class, %args) = @_;
        return bless \%args, $class;
    }
    sub encode {
        my ($self) = @_;
        return 'ACK:' . $self->{reply};
    }
}

my $server = Google::gRPC::Server->new();

$server->register_method(
    'example.Echo',
    'Say',
    sub {
        my ($req, $ctx) = @_;
        return 'echo:' . $req;
    },
);

$server->register_service(
    'example.Proto',
    {
        Greet => {
            request_class => 'MockProtoReq',
            handler       => sub {
                my ($req, $ctx) = @_;
                return MockProtoResp->new(reply => 'hi ' . $req->text);
            },
        },
        NotFound => sub {
            die Google::gRPC::Status->new(code => 5, message => 'missing item');
        },
        Boom => sub {
            die 'unexpected crash';
        },
    },
);

ok($server->dispatch_path('/example.Echo/Say'), 'dispatch_path finds registered method');
is($server->dispatch_path('/example.Echo/Missing'), undef, 'dispatch_path returns undef for unknown method');

# 1. Direct handle_unary tests
{
    my ($code, $msg, $bytes) = $server->handle_unary('/example.Echo/Say', 'hello', {});
    is($code, 0, 'unary echo status 0');
    is($msg, '', 'unary echo empty message');
    is($bytes, 'echo:hello', 'unary echo payload');
}

{
    my ($code, $msg, $bytes) = $server->handle_unary('/example.Proto/Greet', 'world', {});
    is($code, 0, 'proto greet status 0');
    is($bytes, 'ACK:hi world', 'proto greet decoded request and encoded response');
}

{
    my ($code, $msg, $bytes) = $server->handle_unary('/example.Proto/NotFound', '', {});
    is($code, 5, 'custom Google::gRPC::Status code propagated');
    is($msg, 'missing item', 'custom Google::gRPC::Status message propagated');
    is($bytes, undef, 'error returns undef payload');
}

{
    my ($code, $msg, $bytes) = $server->handle_unary('/example.Proto/Boom', '', {});
    is($code, 13, 'plain die maps to INTERNAL (13)');
    like($msg, qr/unexpected crash/, 'die message propagated');
}

{
    my ($code, $msg, $bytes) = $server->handle_unary('/no.Such/Method', '', {});
    is($code, 12, 'unknown method maps to UNIMPLEMENTED (12)');
}

# 2. In-memory HTTP/2 round-trip: Engine::PP <-> Google::gRPC::Server->new_session()
{
    my $srv_session = $server->new_session();
    my $resp_buf    = '';
    my $resp_hdrs;
    my $closed      = 0;

    my $client_engine = Google::gRPC::Engine::PP->new(
        on_headers => sub {
            my ($sid, $hdrs) = @_;
            $resp_hdrs = $hdrs;
        },
        on_data => sub {
            my ($sid, $chunk) = @_;
            $resp_buf .= $chunk;
        },
        on_stream_close => sub {
            $closed = 1;
        },
    );

    my $req_frame = Google::gRPC::Framing::pack_frame('ping');
    $client_engine->submit_request({
        headers => [
            ':method'      => 'POST',
            ':scheme'      => 'http',
            ':authority'   => 'localhost',
            ':path'        => '/example.Echo/Say',
            'content-type' => 'application/grpc',
        ],
        data       => $req_frame,
        end_stream => 1,
    });

    # Pump HTTP/2 frames between client and server in memory
    for (1 .. 10) {
        my $c2s = $client_engine->get_output();
        $srv_session->feed($c2s) if length $c2s;

        my $s2c = '';
        while (defined(my $f = $srv_session->next_frame)) {
            $s2c .= $f;
        }
        $client_engine->feed_input($s2c) if length $s2c;
        last if $closed;
    }

    ok($closed, 'HTTP/2 in-memory stream closed cleanly');
    my $trailers = Google::gRPC::Framing::parse_trailers($resp_hdrs);
    is($trailers->{status}, 0, 'HTTP/2 response grpc-status is 0');

    my @frames = Google::gRPC::Framing::unpack_frame(\$resp_buf);
    is(scalar(@frames), 1, 'received 1 gRPC response frame');
    is($frames[0]->{payload}, 'echo:ping', 'HTTP/2 round-trip payload matches');
}

# 3. Live TCP 127.0.0.1 loopback round-trip with AnyEvent
SKIP: {
    eval { require AnyEvent; require AnyEvent::Socket; require AnyEvent::Handle; 1 }
        or skip 'AnyEvent not installed', 3;

    my $port = $server->listen(host => '127.0.0.1', port => 0);
    ok($port && $port > 0, 'server bound to ephemeral TCP port ' . ($port // 'undef'));

    my $done     = AnyEvent->condvar;
    my $resp_buf = '';
    my $resp_hdrs;

    my $client_engine = Google::gRPC::Engine::PP->new(
        on_headers => sub {
            my ($sid, $hdrs) = @_;
            $resp_hdrs = $hdrs;
        },
        on_data => sub {
            my ($sid, $chunk) = @_;
            $resp_buf .= $chunk;
        },
        on_stream_close => sub {
            $done->send;
        },
    );

    my $req_frame = Google::gRPC::Framing::pack_frame('loopback');
    $client_engine->submit_request({
        headers => [
            ':method'      => 'POST',
            ':scheme'      => 'http',
            ':authority'   => '127.0.0.1:' . $port,
            ':path'        => '/example.Proto/Greet',
            'content-type' => 'application/grpc',
        ],
        data       => $req_frame,
        end_stream => 1,
    });

    my $timer = AnyEvent->timer(
        after => 5,
        cb    => sub { $done->send('timeout') },
    );

    my $client_hdl;
    AnyEvent::Socket::tcp_connect(
        '127.0.0.1',
        $port,
        sub {
            my ($fh) = @_;
            if (!$fh) {
                $done->send('connect failed');
                return;
            }
            $client_hdl = AnyEvent::Handle->new(
                fh       => $fh,
                on_error => sub { $done->send('error') },
                on_eof   => sub { $done->send('eof') },
                on_read  => sub {
                    my ($hdl) = @_;
                    my $chunk = delete $hdl->{rbuf};
                    $client_engine->feed_input($chunk) if defined $chunk && length $chunk;
                    my $out = $client_engine->get_output();
                    $hdl->push_write($out) if length $out;
                },
            );
            my $out = $client_engine->get_output();
            $client_hdl->push_write($out) if length $out;
        },
    );

    my $result = $done->recv;
    $client_hdl->destroy if $client_hdl;
    $server->stop();

    is($result, undef, 'live TCP loopback completed without timeout/error');
    my @frames = Google::gRPC::Framing::unpack_frame(\$resp_buf);
    is($frames[0]->{payload}, 'ACK:hi loopback', 'live TCP loopback Protobuf payload matches');
}

done_testing();
