use v5.36;
use Test::More;
use Scalar::Util qw(weaken);
use Socket qw(SOL_SOCKET SO_SNDBUF);
use Linux::Event::Loop;
use Linux::Event::Kernel::Timer;
use Linux::Event::HTTP::Server;
use Linux::Event::HTTP::Client;
use Linux::Event::IO::Sock::Stream;

my $native = $ENV{REBUILD_NATIVE_INPUT} // 1;
sub run ($loop) {
    my $guard = Linux::Event::Kernel::Timer->new(loop => $loop, after => 3,
        on_timer => sub { die "transport test timed out\n" });
    $loop->run;
    $guard->cancel;
}

subtest 'fragmented headers, chunked body, trailers and pipelined tail' => sub {
    my $loop = Linux::Event::Loop->new;
    my (@requests, $received, $headers);
    my $server = Linux::Event::HTTP::Server->new(
        loop => $loop, native_input => $native, host => '127.0.0.1', port => 0,
        on_headers => sub { ++$headers },
        on_request => sub ($tx, $req) {
            push @requests, [$req->target, $req->body, scalar $req->trailer('x-tail')];
            $tx->respond(status => 200, body => 'ok');
        },
    );
    my $wire = "POST /first HTTP/1.1\r\nHost: test\r\nTransfer-Encoding: chunked\r\nTrailer: x-tail\r\n\r\n3\r\nabc\r\n0\r\nx-tail: yes\r\n\r\nGET /second HTTP/1.1\r\nHost: test\r\nConnection: close\r\n\r\n";
    my @chunks = (substr($wire, 0, 7, ''), substr($wire, 0, 22, ''), substr($wire, 0, 65, ''), $wire);
    my $timer;
    my $peer = Linux::Event::IO::Sock::Stream->connect(
        loop => $loop, host => '127.0.0.1', port => $server->port,
        on_ready => sub ($stream) {
            $timer = Linux::Event::Kernel::Timer->new(loop => $loop, every => 0.002,
                on_timer => sub ($timer) {
                    $stream->write(shift @chunks);
                    $timer->cancel unless @chunks;
                });
        },
        on_data => sub ($stream, $bytes) { $received .= $bytes },
        on_eof => sub ($stream) { $stream->close },
        on_close => sub { $loop->stop },
    );
    run($loop);
    is($headers, 2, 'one headers callback per pipelined request');
    is_deeply(\@requests, [['/first','abc','yes'], ['/second','',undef]],
        'body, trailer and retained pipelined tail delivered exactly once');
    is(() = $received =~ /HTTP\/1.1 200/g, 2, 'both responses drained before close');
    $server->close;
    $_->close for values %{ $server->{connections} };
};

subtest 'truncated body reports error without request completion' => sub {
    my $loop = Linux::Event::Loop->new;
    my (@errors, $completed, $finished);
    my $server = Linux::Event::HTTP::Server->new(
        loop => $loop, native_input => $native, host => '127.0.0.1', port => 0,
        on_headers => sub ($tx, $req) { $tx->on_finish(sub { ++$finished }) },
        on_request => sub { ++$completed },
        on_error => sub ($tx, $error, @rest) { push @errors, "$error" },
    );
    my $peer = Linux::Event::IO::Sock::Stream->connect(
        loop => $loop, host => '127.0.0.1', port => $server->port,
        on_ready => sub ($stream) {
            $stream->end("POST / HTTP/1.1\r\nHost: test\r\nContent-Length: 9\r\n\r\nabc");
        },
        on_data => sub {}, on_eof => sub ($stream) { $stream->close },
        on_close => sub { $loop->stop },
    );
    run($loop);
    ok(@errors, 'truncated input reports engine error');
    ok(!$completed, 'no full request callback');
    is($finished, 1, 'terminal callback once');
    $server->close;
    $_->close for values %{ $server->{connections} };
};

subtest 'bounded response fails without delivering a partial buffered response' => sub {
    my $loop = Linux::Event::Loop->new;
    my (@errors, $responses);
    my $server = Linux::Event::HTTP::Server->new(
        loop => $loop, native_input => $native, host => '127.0.0.1', port => 0,
        on_request => sub ($tx, $req) { $tx->respond(status => 200, body => 'x' x 64) },
    );
    my $client = Linux::Event::HTTP::Client->new(loop => $loop, native_input => $native,
        http1 => { max_buffered_body_bytes => 32 });
    my $op = $client->get('http://127.0.0.1:' . $server->port . '/',
        on_response => sub { ++$responses },
        on_error => sub ($tx, $error) { push @errors, "$error" },
        on_finish => sub { $loop->stop },
    );
    run($loop);
    is($op->state, 'error', 'oversized buffered response fails');
    like($errors[0], qr/max_buffered_body_bytes/, 'bounded body reason');
    ok(!$responses, 'no partial response');
    $client->shutdown;
    $server->close;
    $_->close for values %{ $server->{connections} };
};

subtest 'reentrant transport close releases the native engine' => sub {
    my $loop = Linux::Event::Loop->new;
    my ($server, $weak_engine, $weak_stream, $finished);
    $server = Linux::Event::HTTP::Server->new(
        loop => $loop, native_input => $native, host => '127.0.0.1', port => 0,
        on_request => sub ($tx, $req) {
            $tx->on_finish(sub { ++$finished });
            my ($stream) = values %{ $server->{connections} };
            $weak_stream = $stream; weaken($weak_stream);
            $weak_engine = $stream->{http_engine}; weaken($weak_engine);
            $stream->close;
        },
    );
    my $client = Linux::Event::HTTP::Client->new(loop => $loop, native_input => $native);
    my $op = $client->get('http://127.0.0.1:' . $server->port . '/',
        on_finish => sub { $loop->stop });
    run($loop);
    is($op->state, 'error', 'closed peer fails client operation');
    is($finished, 1, 'server finish once despite recursive abort');
    is($server->connection_count, 0, 'owner releases stream');
    ok(!$weak_engine, 'native context releases engine');
    ok(!$weak_stream, 'native context does not retain stream');
    $client->shutdown;
    $server->close;
};

subtest 'congested output resumes without loss or duplicate writes' => sub {
    my $loop = Linux::Event::Loop->new;
    my ($server, $received, $sent, $blocked, $drains) = (undef, 0, 0, 0, 0);
    my $total = 2 * 1024 * 1024;
    my $chunk = 'z' x 16384;
    my $produce = sub ($tx) {
        while ($sent < $total) {
            $sent += length $chunk;
            if (!$tx->write($chunk)) { ++$blocked; return }
        }
        $tx->end;
    };
    $server = Linux::Event::HTTP::Server->new(
        loop => $loop, native_input => $native, host => '127.0.0.1', port => 0,
        tuning => { high_watermark => 32768, low_watermark => 16384 },
        on_request => sub ($tx, $req) {
            my ($stream) = values %{ $server->{connections} };
            setsockopt($stream->write_fh, SOL_SOCKET, SO_SNDBUF, pack('i', 4096)) or die $!;
            $tx->respond(status => 200, stream_body => 1,
                on_drain => sub ($tx) { ++$drains; $produce->($tx) });
            $produce->($tx);
        },
    );
    my $client = Linux::Event::HTTP::Client->new(loop => $loop, native_input => $native);
    my $op = $client->get('http://127.0.0.1:' . $server->port . '/',
        on_data => sub ($tx, $bytes) {
            die 'corrupt body' if $bytes =~ /[^z]/;
            $received += length $bytes;
        },
        on_finish => sub { $loop->stop },
    );
    run($loop);
    is($op->state, 'complete', 'streamed response completes after congestion');
    ok($blocked > 0, 'producer saw backpressure');
    ok($drains > 0, 'producer resumed on drain');
    is($received, $total, 'every accepted byte arrives exactly once');
    $client->shutdown;
    $server->close;
    $_->close for values %{ $server->{connections} };
};

for my $case (
    ['request body bound', "POST / HTTP/1.1\r\nHost: test\r\nContent-Length: 16\r\n\r\nabcdefghijklmnop"],
    ['ambiguous framing', "POST / HTTP/1.1\r\nHost: test\r\nContent-Length: 1\r\nTransfer-Encoding: chunked\r\n\r\n0\r\n\r\n"],
) {
    subtest $case->[0] => sub {
        my $loop = Linux::Event::Loop->new;
        my ($requests, @errors);
        my $server = Linux::Event::HTTP::Server->new(
            loop => $loop, native_input => $native, host => '127.0.0.1', port => 0,
            http1 => { max_buffered_body_bytes => 8 },
            on_request => sub { ++$requests },
            on_error => sub ($object, $error, @rest) { push @errors, "$error" },
        );
        my $peer = Linux::Event::IO::Sock::Stream->connect(
            loop => $loop, host => '127.0.0.1', port => $server->port,
            on_ready => sub ($stream) { $stream->end($case->[1]) },
            on_data => sub {}, on_eof => sub ($stream) { $stream->close },
            on_close => sub { $loop->stop },
        );
        run($loop);
        ok(@errors, 'engine reports invalid request');
        ok(!$requests, 'no successful full request callback');
        $server->close;
        $_->close for values %{ $server->{connections} };
    };
}

done_testing;
