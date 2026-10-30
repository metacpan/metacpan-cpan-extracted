use v5.36;
use Test::More;
use Linux::Event::Loop;
use Linux::Event::Kernel::Timer;
use Linux::Event::HTTP::Server;
use Linux::Event::HTTP::Client;
use Linux::Event::IO::Sock::Stream;

my $native = $ENV{REBUILD_NATIVE_INPUT} // 1;
sub run ($loop) {
    my $guard = Linux::Event::Kernel::Timer->new(loop => $loop, after => 3,
        on_timer => sub { die "shutdown/upload timed out\n" });
    $loop->run;
    $guard->cancel;
}

subtest 'queued streaming uploads start at admission' => sub {
    my $loop = Linux::Event::Loop->new;
    my (@admitted, @received, @response);
    my $server = Linux::Event::HTTP::Server->new(loop => $loop, native_input => $native,
        host => '127.0.0.1', port => 0, on_request => sub ($tx, $req) {
            push @received, $req->body;
            $tx->respond(status => 200, body => $req->body);
        });
    my $client = Linux::Event::HTTP::Client->new(loop => $loop, native_input => $native,
        max_connections_per_origin => 1);
    for my $body ('first', 'second') {
        $client->post('http://127.0.0.1:' . $server->port . '/', stream_body => 1,
            on_transaction => sub ($tx) {
                push @admitted, $body;
                $tx->write(substr($body, 0, 2));
                $tx->end(substr($body, 2));
            },
            on_response => sub ($tx, $res) { push @response, $res->body },
            on_finish => sub { $loop->stop if @response == 2 },
        );
    }
    run($loop);
    is_deeply(\@admitted, ['first', 'second'], 'one admission for each queued operation');
    is_deeply(\@received, \@admitted, 'server received exact uploads');
    is_deeply(\@response, \@admitted, 'responses completed');
    $client->shutdown;
    $server->shutdown(grace => 0.1, on_complete => sub { $loop->stop });
    run($loop) if $server->connection_count;
    is($loop->count, 0, 'no watcher leaks');
};

subtest 'shutdown completes admitted body and response, excludes pipeline' => sub {
    my $loop = Linux::Event::Loop->new;
    my ($server, $peer, $received, @finish, @requests, $completed);
    $server = Linux::Event::HTTP::Server->new(loop => $loop, native_input => $native,
        host => '127.0.0.1', port => 0,
        on_headers => sub ($tx, $req) {
            $tx->on_finish(sub ($tx) { push @finish, $tx->state });
            $server->shutdown(grace => 1, on_complete => sub { ++$completed; $loop->stop });
            Linux::Event::Kernel::Timer->new(loop => $loop, after => 0.005,
                on_timer => sub { $peer->write("cdGET /later HTTP/1.1\r\nHost: test\r\n\r\n") });
        },
        on_request => sub ($tx, $req) {
            push @requests, $req->body;
            Linux::Event::Kernel::Timer->new(loop => $loop, after => 0.005,
                on_timer => sub { $tx->respond(status => 200, body => 'done') });
        });
    $peer = Linux::Event::IO::Sock::Stream->connect(loop => $loop,
        host => '127.0.0.1', port => $server->port,
        on_ready => sub ($stream) {
            $stream->write("POST / HTTP/1.1\r\nHost: test\r\nContent-Length: 4\r\n\r\nab");
        },
        on_data => sub ($stream, $bytes) { $received .= $bytes },
        on_eof => sub ($stream) { $stream->close });
    run($loop);
    is_deeply(\@requests, ['abcd'], 'only admitted request completes');
    is_deeply(\@finish, ['complete'], 'application finish callback preserved');
    like($received, qr/done\z/, 'response drained before socket closes');
    is($completed, 1, 'shutdown completion once');
    is($server->connection_count, 0, 'all owned sockets removed');
    $server->shutdown;
    is($completed, 1, 'shutdown idempotent');
    is($loop->count, 0, 'grace timer and watchers cancelled');
};

subtest 'grace expiry terminates stalled request exactly once' => sub {
    my $loop = Linux::Event::Loop->new;
    my ($server, @finish, $done);
    $server = Linux::Event::HTTP::Server->new(loop => $loop, native_input => $native,
        host => '127.0.0.1', port => 0,
        on_headers => sub ($tx, $req) {
            $tx->on_finish(sub ($tx) { push @finish, $tx->state });
            $server->shutdown(grace => 0.01, on_complete => sub {
                is_deeply(\@finish, ['error'], 'transactions finish before shutdown callback');
                ++$done;
                $loop->stop;
            });
        }, on_request => sub { fail('incomplete body completed') });
    my $peer = Linux::Event::IO::Sock::Stream->connect(loop => $loop,
        host => '127.0.0.1', port => $server->port,
        on_ready => sub ($stream) {
            $stream->write("POST / HTTP/1.1\r\nHost: test\r\nContent-Length: 4\r\n\r\na");
        }, on_data => sub {});
    run($loop);
    is_deeply(\@finish, ['error'], 'stalled transaction fails once');
    is($done, 1, 'expiry completes shutdown');
    is($server->connection_count, 0, 'no accepted socket survives expiry');
    $peer->close;
    is($loop->count, 0, 'expiry releases timer and socket watchers');
};
subtest 'idle shutdown completes synchronously without timer' => sub {
    my $loop = Linux::Event::Loop->new;
    my $server = Linux::Event::HTTP::Server->new(loop => $loop, native_input => $native,
        host => '127.0.0.1', port => 0, on_request => sub {});
    my $done = 0;
    $server->shutdown(on_complete => sub ($same) {
        is($same, $server, 'completion receives service');
        ++$done;
    });
    is($done, 1, 'idle completion is immediate');
    is($loop->count, 0, 'no watcher retained');
};

done_testing;
