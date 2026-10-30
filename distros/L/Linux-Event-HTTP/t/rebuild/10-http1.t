use v5.36;
use Test::More;
use Scalar::Util qw(refaddr weaken);
use Linux::Event::Loop;
use Linux::Event::Kernel::Timer;
use Linux::Event::HTTP::Server;
use Linux::Event::HTTP::Client;

sub run_until ($loop, $start) {
    my $guard = Linux::Event::Kernel::Timer->new(loop => $loop, after => 3,
        on_timer => sub { die "test timed out\n" });
    $start->();
    $loop->run;
    $guard->cancel;
}

subtest 'GET/POST, identity, callback ordering and persistent pooling' => sub {
    my $loop = Linux::Event::Loop->new;
    my (@order, @server_tx, @response, @ops);
    my $server = Linux::Event::HTTP::Server->new(
        loop => $loop, native_input => ($ENV{REBUILD_NATIVE_INPUT} // 1), host => '127.0.0.1', port => 0,
        on_headers => sub ($tx, $req) {
            isa_ok($tx, 'Unblock::HTTP1::Transaction');
            isa_ok($req, 'Uniform::HTTP::Request');
            push @order, 'headers';
            push @server_tx, refaddr($tx);
        },
        on_request => sub ($tx, $req) {
            is(refaddr($tx), $server_tx[-1], 'same transaction at headers and completion');
            push @order, 'request';
            $tx->respond(status => 200, body => $req->method . ':' . $req->body);
        },
    );
    my $client = Linux::Event::HTTP::Client->new(loop => $loop, native_input => ($ENV{REBUILD_NATIVE_INPUT} // 1), max_connections_per_origin => 1);
    my $url = 'http://127.0.0.1:' . $server->port . '/';
    run_until($loop, sub {
        for my $method (qw(GET POST)) {
            push @ops, $client->request(method => $method, url => $url,
                ($method eq 'POST' ? (body => 'payload') : ()), timeout => 1,
                on_response => sub ($tx, $res) {
                    isa_ok($res, 'Uniform::HTTP::Response');
                    push @response, $res->body;
                },
                on_error => sub ($object, $error) { fail("unexpected error: $error") },
                on_finish => sub { $loop->stop if @response == 2 },
            );
        }
    });
    is_deeply(\@response, ['GET:', 'POST:payload'], 'complete buffered responses');
    is_deeply(\@order, [qw(headers request headers request)], 'headers precede full request');
    isa_ok($ops[0], 'Unblock::HTTP::_ClientOperation');
    isa_ok($ops[0]->transaction, 'Unblock::HTTP1::Transaction');
    is($server->connection_count, 1, 'one persistent socket');
    is($client->pool_stats->{connections}, 1, 'Unblock owns one pooled connection');
    $server->close;
    run_until($loop, sub {
        $client->shutdown;
        Linux::Event::Kernel::Timer->new(loop => $loop, after => 0.01,
            on_timer => sub { $loop->stop });
    });
    is($server->connection_count, 0, 'peer EOF removes server ownership');
    is($loop->count, 0, 'no socket or timer watchers retained');
};

subtest 'streaming response and request bodies' => sub {
    my $loop = Linux::Event::Loop->new;
    my (@order, $received, $body);
    my $server = Linux::Event::HTTP::Server->new(
        loop => $loop, native_input => ($ENV{REBUILD_NATIVE_INPUT} // 1), host => '127.0.0.1', port => 0,
        on_headers => sub ($tx, $req) {
            $tx->on_data(sub ($tx, $bytes) { $received .= $bytes });
        },
        on_request => sub ($tx, $req) {
            is($received, 'upload', 'request chunks precede completion');
            ok(!defined($req->body) || !length($req->body), 'streamed request not accumulated');
            $tx->respond(status => 200, stream_body => 1);
            $tx->write('one');
            $tx->write('two');
            $tx->end;
        },
    );
    my $client = Linux::Event::HTTP::Client->new(loop => $loop);
    run_until($loop, sub {
        $client->post('http://127.0.0.1:' . $server->port . '/', body => 'upload',
            on_response => sub { push @order, 'headers' },
            on_data => sub ($tx, $bytes) { push @order, 'data'; $body .= $bytes },
            on_end => sub { push @order, 'end' },
            on_finish => sub { push @order, 'finish'; $loop->stop },
        );
    });
    is($body, 'onetwo', 'streamed response');
    is($order[0], 'headers', 'response headers first');
    is_deeply([@order[-2,-1]], [qw(end finish)], 'end then finish');
    $client->shutdown;
    $server->close;
    $_->close for values %{ $server->{connections} };
};

subtest 'queued cancellation and request timeout' => sub {
    my $loop = Linux::Event::Loop->new;
    my ($seen, @errors, @finish);
    my $server = Linux::Event::HTTP::Server->new(
        loop => $loop, native_input => ($ENV{REBUILD_NATIVE_INPUT} // 1), host => '127.0.0.1', port => 0,
        on_request => sub { ++$seen },
    );
    my $client = Linux::Event::HTTP::Client->new(loop => $loop, native_input => ($ENV{REBUILD_NATIVE_INPUT} // 1), max_connections_per_origin => 1);
    my $url = 'http://127.0.0.1:' . $server->port . '/';
    my ($active, $queued);
    run_until($loop, sub {
        $active = $client->get($url, timeout => 0.03,
            on_error => sub ($object, $error) { push @errors, "$error" },
            on_finish => sub { push @finish, 'active'; $loop->stop },
        );
        $queued = $client->get($url, on_finish => sub { push @finish, 'queued' });
        $queued->cancel;
    });
    is($queued->state, 'cancelled', 'queued operation cancelled');
    is($active->state, 'error', 'timeout is error');
    like($errors[0], qr/timed out/, 'timeout explanation');
    is($seen, 1, 'cancelled queued request never sent');
    is_deeply(\@finish, [qw(queued active)], 'one finish per operation');
    $client->shutdown;
    $server->close;
    $_->close for values %{ $server->{connections} };
};

done_testing;
