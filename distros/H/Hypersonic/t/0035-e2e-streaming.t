#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use IO::Socket::INET;
use IO::Select;
use Digest::SHA qw(sha1_base64);
use MIME::Base64 qw(encode_base64);
use HypersonicTest qw(spawn_server wait_for_port);


use Hypersonic;

# ============================================================
# End-to-End Tests for Streaming, SSE, and WebSocket
# ============================================================

# Skip if we can't fork
plan skip_all => 'fork not available' if $^O eq 'MSWin32';

my $port = 18500 + ($$ % 1000);  # Unique port based on PID
my $cache_dir = "_test_cache_e2e_$$";

# ============================================================
# Fork server process via spawn_server (captures child STDERR
# so wait_for_port can diag the real failure on bind/listen errors).
# ============================================================
my ($pid, $log) = spawn_server(sub {
    my $server = Hypersonic->new(cache_dir => $cache_dir);

    # Regular route for baseline
    $server->get('/' => sub { 'OK' });

    # Streaming route - sends multiple chunks
    $server->get('/stream' => sub {
        my ($req, $stream) = @_;
        $stream->headers(200, { 'Content-Type' => 'text/plain' });
        $stream->write("chunk1\n");
        $stream->write("chunk2\n");
        $stream->write("chunk3\n");
        $stream->end();
    }, { streaming => 1 });

    # SSE route - sends server-sent events
    $server->get('/sse' => sub {
        my ($req, $stream) = @_;
        require Hypersonic::SSE;
        my $sse = Hypersonic::SSE->new($stream);
        $sse->event(type => 'greeting', data => 'Hello SSE!');
        $sse->event(type => 'update', data => 'First update', id => '1');
        $sse->event(type => 'update', data => "Multi\nLine\nData", id => '2');
        $sse->data('simple data');
        $sse->comment('test comment');
        $sse->retry(5000);
        $sse->close();
    }, { streaming => 1 });

    # SSE with keepalive test
    $server->get('/sse-keepalive' => sub {
        my ($req, $stream) = @_;
        require Hypersonic::SSE;
        my $sse = Hypersonic::SSE->new($stream, keepalive => 1);
        $sse->event(data => 'start');
        $sse->keepalive();
        $sse->event(data => 'end');
        $sse->close();
    }, { streaming => 1 });

    # WebSocket echo route
    $server->websocket('/ws-echo' => sub {
        my ($ws) = @_;
        $ws->on(message => sub {
            my ($data) = @_;
            $ws->send("echo: $data");
        });
        $ws->on(close => sub {
            # Connection closed
        });
    });

    # WebSocket broadcast route (sends message on connect)
    $server->websocket('/ws-greet' => sub {
        my ($ws) = @_;
        $ws->on(open => sub {
            $ws->send("Welcome!");
        });
    });

    $server->compile();
    $server->run(port => $port, workers => 1);
});

# Parent - wait for server to start. This test compiles the largest
# JIT module of the suite (regular + streaming + 2 SSE routes + 2
# websocket routes); on smokers with -O0 -g debugging perls the gcc
# invocation alone can take 30-60s, which is why earlier 5s/10s
# timeouts produced the "child wrote no output" bailouts on CPAN
# testers (host k93msid, perl 5.12 .. 5.42).
wait_for_port($port, { pid => $pid, log => $log, tries => 600, sleep => 0.2 })
    or BAIL_OUT("server child failed to bind port $port (see diag above)");

# ============================================================
# Test helpers
# ============================================================

sub http_request {
    my ($method, $path, %opts) = @_;
    my $body = $opts{body} // '';
    my $headers = $opts{headers} // {};
    my $timeout = $opts{timeout} // 5;

    my $sock = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1',
        PeerPort => $port,
        Proto    => 'tcp',
        Timeout  => $timeout,
    );

    return undef unless $sock;

    my $content_length = length($body);
    my $request = "$method $path HTTP/1.1\r\n"
                . "Host: localhost:$port\r\n"
                . "Content-Length: $content_length\r\n";

    for my $key (keys %$headers) {
        $request .= "$key: $headers->{$key}\r\n";
    }

    $request .= "Connection: close\r\n\r\n$body";

    print $sock $request;

    my $response = '';
    my $select = IO::Select->new($sock);

    while ($select->can_read($timeout)) {
        my $buf;
        my $bytes = sysread($sock, $buf, 4096);
        last unless $bytes;
        $response .= $buf;
    }

    close($sock);
    return $response;
}

# Read streaming response incrementally
sub http_streaming_request {
    my ($method, $path, %opts) = @_;
    my $timeout = $opts{timeout} // 5;
    my $headers = $opts{headers} // {};

    my $sock = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1',
        PeerPort => $port,
        Proto    => 'tcp',
        Timeout  => $timeout,
    );

    return undef unless $sock;

    my $request = "$method $path HTTP/1.1\r\n"
                . "Host: localhost:$port\r\n";

    for my $key (keys %$headers) {
        $request .= "$key: $headers->{$key}\r\n";
    }

    $request .= "Connection: close\r\n\r\n";

    print $sock $request;

    my $response = '';
    my @chunks;
    my $select = IO::Select->new($sock);

    while ($select->can_read($timeout)) {
        my $buf;
        my $bytes = sysread($sock, $buf, 4096);
        last unless $bytes;
        $response .= $buf;
        push @chunks, $buf;
    }

    close($sock);
    return wantarray ? ($response, \@chunks) : $response;
}

# WebSocket handshake helper
sub ws_connect {
    my ($path) = @_;

    my $sock = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1',
        PeerPort => $port,
        Proto    => 'tcp',
        Timeout  => 5,
    );

    return undef unless $sock;

    # Generate random key
    my $key = encode_base64(pack("N4", map { int(rand(2**32)) } 1..4), '');

    my $request = "GET $path HTTP/1.1\r\n"
                . "Host: localhost:$port\r\n"
                . "Upgrade: websocket\r\n"
                . "Connection: Upgrade\r\n"
                . "Sec-WebSocket-Key: $key\r\n"
                . "Sec-WebSocket-Version: 13\r\n"
                . "\r\n";

    print $sock $request;

    # Read response
    my $response = '';
    my $select = IO::Select->new($sock);

    while ($select->can_read(2)) {
        my $buf;
        my $bytes = sysread($sock, $buf, 4096);
        last unless $bytes;
        $response .= $buf;
        last if $response =~ /\r\n\r\n/;
    }

    # Calculate expected accept key
    my $magic = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';
    my $expected_accept = sha1_base64($key . $magic) . '=';

    # Separate HTTP headers from any extra WebSocket frame data
    # that may have arrived in the same TCP segment
    my ($headers, $extra_data) = split(/\r\n\r\n/, $response, 2);
    $extra_data //= '';

    return {
        socket   => $sock,
        response => $response,
        key      => $key,
        expected_accept => $expected_accept,
        extra_data => $extra_data,  # Any data after headers (may contain WS frames)
    };
}

# Send WebSocket text frame (client to server - masked)
sub ws_send_text {
    my ($sock, $data) = @_;

    my $len = length($data);
    my $frame = '';

    # FIN + text opcode
    $frame .= chr(0x81);

    # Mask bit set + length
    if ($len < 126) {
        $frame .= chr(0x80 | $len);
    } elsif ($len < 65536) {
        $frame .= chr(0x80 | 126);
        $frame .= pack('n', $len);
    } else {
        $frame .= chr(0x80 | 127);
        $frame .= pack('Q>', $len);
    }

    # Masking key (random)
    my @mask = map { int(rand(256)) } 1..4;
    $frame .= pack('C4', @mask);

    # Masked payload
    for my $i (0 .. $len - 1) {
        $frame .= chr(ord(substr($data, $i, 1)) ^ $mask[$i % 4]);
    }

    print $sock $frame;
}

# Send WebSocket close frame
sub ws_send_close {
    my ($sock, $code) = @_;
    $code //= 1000;

    my $payload = pack('n', $code);
    my $frame = chr(0x88);  # FIN + close opcode
    $frame .= chr(0x80 | 2);  # Masked + length

    # Masking key
    my @mask = map { int(rand(256)) } 1..4;
    $frame .= pack('C4', @mask);

    # Masked payload
    for my $i (0 .. 1) {
        $frame .= chr(ord(substr($payload, $i, 1)) ^ $mask[$i % 4]);
    }

    print $sock $frame;
}

# Parse WebSocket frame from data buffer (no socket read)
sub ws_parse_frame {
    my ($data) = @_;
    return undef unless defined $data && length($data) >= 2;

    my @bytes = unpack('C*', $data);
    my $byte1 = $bytes[0];
    my $byte2 = $bytes[1];

    my $fin = ($byte1 & 0x80) >> 7;
    my $opcode = $byte1 & 0x0F;
    my $masked = ($byte2 & 0x80) >> 7;
    my $len = $byte2 & 0x7F;

    my $pos = 2;

    # Extended length
    if ($len == 126) {
        return undef if length($data) < 4;
        $len = unpack('n', substr($data, 2, 2));
        $pos = 4;
    } elsif ($len == 127) {
        return undef if length($data) < 10;
        $len = unpack('Q>', substr($data, 2, 8));
        $pos = 10;
    }

    # Read payload
    return undef if length($data) < $pos + $len;
    my $payload = substr($data, $pos, $len);

    return {
        fin     => $fin,
        opcode  => $opcode,
        masked  => $masked,
        payload => $payload,
    };
}

# Read WebSocket frame (server to client - unmasked)
sub ws_read_frame {
    my ($sock, $timeout) = @_;
    $timeout //= 2;

    my $select = IO::Select->new($sock);
    return undef unless $select->can_read($timeout);

    my $header;
    sysread($sock, $header, 2) or return undef;

    my $byte1 = ord(substr($header, 0, 1));
    my $byte2 = ord(substr($header, 1, 1));

    my $fin = ($byte1 & 0x80) >> 7;
    my $opcode = $byte1 & 0x0F;
    my $masked = ($byte2 & 0x80) >> 7;
    my $len = $byte2 & 0x7F;

    # Extended length
    if ($len == 126) {
        my $ext;
        sysread($sock, $ext, 2);
        $len = unpack('n', $ext);
    } elsif ($len == 127) {
        my $ext;
        sysread($sock, $ext, 8);
        $len = unpack('Q>', $ext);
    }

    # Read payload
    my $payload = '';
    if ($len > 0) {
        sysread($sock, $payload, $len);
    }

    return {
        fin     => $fin,
        opcode  => $opcode,
        masked  => $masked,
        payload => $payload,
    };
}

# ============================================================
# Tests
# ============================================================

plan tests => 8;

# ============================================================
# Test 1: Basic server health check
# ============================================================
subtest 'Server health check' => sub {
    plan tests => 2;

    my $resp = http_request('GET', '/');
    ok($resp, 'Server responds');
    like($resp, qr/200 OK/, 'Returns 200');
};

# ============================================================
# Test 2: Streaming response with multiple chunks
# ============================================================
subtest 'Streaming response (chunked)' => sub {
    plan tests => 6;

    my $resp = http_request('GET', '/stream');
    ok($resp, 'Got streaming response');
    like($resp, qr/HTTP\/1\.1 200 OK/, 'Status 200');
    like($resp, qr/Transfer-Encoding: chunked/i, 'Chunked encoding header');
    like($resp, qr/chunk1/, 'Contains chunk1');
    like($resp, qr/chunk2/, 'Contains chunk2');
    like($resp, qr/chunk3/, 'Contains chunk3');
};

# ============================================================
# Test 3: SSE response format
# ============================================================
subtest 'SSE response format' => sub {
    plan tests => 10;

    my $resp = http_request('GET', '/sse');
    ok($resp, 'Got SSE response');
    like($resp, qr/HTTP\/1\.1 200 OK/, 'Status 200');
    like($resp, qr/Content-Type: text\/event-stream/, 'SSE content type');
    like($resp, qr/Cache-Control: no-cache/, 'No-cache header');

    # Event with type
    like($resp, qr/event: greeting\n/, 'Has greeting event type');
    like($resp, qr/data: Hello SSE!\n/, 'Has greeting data');

    # Event with ID
    like($resp, qr/id: 1\n/, 'Has event ID');

    # Multiline data
    like($resp, qr/data: Multi\n.*data: Line\n.*data: Data\n/s, 'Multiline data formatted correctly');

    # Comment
    like($resp, qr/: test comment\n/, 'Comment formatted correctly');

    # Retry
    like($resp, qr/retry: 5000\n/, 'Retry directive present');
};

# ============================================================
# Test 4: SSE keepalive
# ============================================================
subtest 'SSE keepalive' => sub {
    plan tests => 3;

    my $resp = http_request('GET', '/sse-keepalive');
    ok($resp, 'Got SSE response with keepalive');
    like($resp, qr/: keepalive\n/, 'Keepalive comment present');
    like($resp, qr/data: start\n.*: keepalive\n.*data: end\n/s, 'Keepalive in correct position');
};

# ============================================================
# Test 5: WebSocket handshake
# ============================================================
subtest 'WebSocket handshake' => sub {
    plan tests => 5;

    my $ws = ws_connect('/ws-echo');
    ok($ws, 'WebSocket connection initiated');
    ok($ws->{socket}, 'Socket created');
    like($ws->{response}, qr/HTTP\/1\.1 101/, 'Switching Protocols response');
    like($ws->{response}, qr/Upgrade: websocket/i, 'Upgrade header present');
    like($ws->{response}, qr/Sec-WebSocket-Accept: \Q$ws->{expected_accept}\E/, 'Accept key correct');

    close($ws->{socket}) if $ws->{socket};
};

# ============================================================
# Test 6: WebSocket echo
# ============================================================
subtest 'WebSocket echo' => sub {
    plan tests => 4;

    my $ws = ws_connect('/ws-echo');
    ok($ws && $ws->{socket}, 'WebSocket connected');
    like($ws->{response}, qr/HTTP\/1\.1 101/, 'Handshake successful');

    # Send a message
    ws_send_text($ws->{socket}, 'Hello WebSocket!');

    # Read echo response
    my $frame = ws_read_frame($ws->{socket});
    ok($frame, 'Received frame');
    is($frame->{payload}, 'echo: Hello WebSocket!', 'Echo response correct');

    close($ws->{socket}) if $ws->{socket};
};

# ============================================================
# Test 7: WebSocket greeting (server sends on open)
# ============================================================
subtest 'WebSocket server-initiated message' => sub {
    plan tests => 3;

    my $ws = ws_connect('/ws-greet');
    ok($ws && $ws->{socket}, 'WebSocket connected');
    like($ws->{response}, qr/HTTP\/1\.1 101/, 'Handshake successful');

    # The Welcome! frame may arrive in the same TCP segment as the handshake response.
    # Check extra_data first, then try reading from socket.
    my $frame;
    if ($ws->{extra_data} && length($ws->{extra_data}) >= 2) {
        $frame = ws_parse_frame($ws->{extra_data});
    }

    # If no frame in extra_data, try reading from socket
    unless ($frame && $frame->{payload}) {
        for my $attempt (1..10) {
            $frame = ws_read_frame($ws->{socket}, 0.5);
            last if $frame && $frame->{payload};
            select(undef, undef, undef, 0.1);
        }
    }
    ok($frame && $frame->{payload} eq 'Welcome!', 'Received server greeting');

    close($ws->{socket}) if $ws->{socket};
};

# ============================================================
# Test 8: WebSocket close handshake
# ============================================================
subtest 'WebSocket close handshake' => sub {
    plan tests => 3;

    my $ws = ws_connect('/ws-echo');
    ok($ws && $ws->{socket}, 'WebSocket connected');
    like($ws->{response}, qr/HTTP\/1\.1 101/, 'Handshake successful');

    # Send close frame
    ws_send_close($ws->{socket}, 1000);

    # Read close response
    my $frame = ws_read_frame($ws->{socket});
    ok($frame && $frame->{opcode} == 0x08, 'Received close frame');

    close($ws->{socket}) if $ws->{socket};
};

# ============================================================
# Cleanup
# ============================================================
END {
    if ($pid) {
        kill('TERM', $pid);
        waitpid($pid, 0);
        system("rm -rf $cache_dir 2>/dev/null");
    }
}

done_testing();
