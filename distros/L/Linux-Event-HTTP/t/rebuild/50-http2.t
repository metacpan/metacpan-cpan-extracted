use v5.36;
use Test::More;
use File::Temp qw(tempdir);
use Scalar::Util qw(refaddr weaken);
use Linux::Event::Loop;
use Linux::Event::Kernel::Timer;
use Linux::Event::HTTP::Server;
use Linux::Event::HTTP::Client;

my $available = eval { require Unblock::HTTP2; Unblock::HTTP2->VERSION('0.13'); 1 };
die "HTTP2 required by this test lane: $@" if !$available && $ENV{REBUILD_REQUIRE_HTTP2};
plan skip_all => 'optional Unblock::HTTP2 >= 0.13 required' unless $available;
subtest 'runtime HTTP2 minimum version matches package metadata' => sub {
    require Linux::Event::HTTP::_Config;
    # Localize the actual package version: the constructor must refuse an
    # installed pre-conformance engine, even if a different layer loads it.
    {
        local $Unblock::HTTP2::VERSION = '0.12';
        my %opt = (http2 => 1);
        my $ok = eval { Linux::Event::HTTP::_Config::protocols(\%opt); 1 };
        ok(!$ok, 'pre-conformance 0.12 engine cannot be selected');
        like("$@", qr/http2 requires Unblock::HTTP2 >= 0\.13/,
            'missing minimum is reported clearly');
    }
    my %opt = (http2 => 1);
    my %actual = Linux::Event::HTTP::_Config::protocols(\%opt);
    ok(exists $actual{http2}, '0.13 or newer engine is accepted');
    ok(!exists $opt{http2}, 'protocol option is consumed once');
};

plan skip_all => 'openssl command required' unless -x '/usr/bin/openssl';
my $dir = tempdir(CLEANUP => 1);
my ($cert, $key) = ("$dir/cert.pem", "$dir/key.pem");
system('/usr/bin/openssl', 'req', '-x509', '-newkey', 'ec', '-pkeyopt',
    'ec_paramgen_curve:prime256v1', '-nodes', '-keyout', $key, '-out', $cert,
    '-subj', '/CN=localhost', '-addext', 'subjectAltName=DNS:localhost', '-days', '1') == 0
    or die 'certificate generation failed';
my $native = $ENV{REBUILD_NATIVE_INPUT} // 1;
sub guard ($loop) {
    Linux::Event::Kernel::Timer->new(loop => $loop, after => 5,
        on_timer => sub { die "HTTP2 test timed out\n" });
}
sub server ($loop, %options) {
    Linux::Event::HTTP::Server->new(loop => $loop, native_input => $native,
        host => '127.0.0.1', port => 0, http2 => 1,
        tls => { cert_file => $cert, key_file => $key }, %options);
}
sub client ($loop, %options) {
    Linux::Event::HTTP::Client->new(loop => $loop, native_input => $native,
        http2 => 1, tls => { ca_file => $cert }, %options);
}
sub cleanup ($loop, $server, $client) {
    $client->shutdown;
    $server->shutdown(grace => 0, on_complete => sub { $loop->stop });
    $loop->run if $server->connection_count;
    is($loop->count, 0, 'no surviving socket or timer watchers');
}

subtest 'ALPN multiplexes actual transactions on one TLS connection' => sub {
    my $loop = Linux::Event::Loop->new;
    my (@admitted, @order, @responses, @errors, @weak);
    my $server = server($loop,
        on_headers => sub ($tx, $request) {
            push @order, 'headers:' . $request->target;
            isa_ok($tx, 'Unblock::HTTP2::Transaction');
            isa_ok($request, 'Uniform::HTTP::Request');
        },
        on_request => sub ($tx, $request) {
            push @order, 'request:' . $request->target;
            push @admitted, $tx;
            push @weak, $tx; weaken($weak[-1]);
            # No response until all streams coexist, then reverse completion.
            if (@admitted == 8) {
                $_->respond(status => 200, body => $_->request->target) for reverse @admitted;
                @admitted = ();
            }
        });
    my $client = client($loop);
    my (@ops, $finished);
    for my $i (1 .. 8) {
        push @ops, $client->get('https://localhost:' . $server->port . "/$i",
            http_version => '2', timeout => 3,
            on_response => sub ($tx, $response) {
                isa_ok($tx, 'Unblock::HTTP2::Transaction');
                is($response->version, '2', 'negotiated HTTP2 response');
                push @responses, $response->body;
            }, on_error => sub ($object, $error, @extra) { push @errors, "$error" },
            on_finish => sub { $loop->stop if ++$finished == 8 });
    }
    my $guard = guard($loop); $loop->run; $guard->cancel;
    is_deeply(\@errors, [], 'multiplexed requests have no errors');
    is($server->connection_count, 1, 'all streams share a TLS connection');
    is_deeply([sort @responses], [map { "/$_" } 1 .. 8], 'all independent responses arrive');
    is_deeply(\@order, [map { ("headers:/$_", "request:/$_") } 1 .. 8],
        'headers precede complete request on each stream');
    is($_->state, 'complete', 'actual operation completed') for @ops;
    cleanup($loop, $server, $client);
    ok(!grep(defined, @weak), 'server transactions released after callbacks');
};

for my $case ('HTTP1 fallback', 'strict HTTP2 refuses fallback') {
    subtest $case => sub {
        my $loop = Linux::Event::Loop->new;
        my ($version, @errors, $seen);
        my $server = server($loop, http2 => 0, on_request => sub ($tx, $request) {
            ++$seen; $tx->respond(status => 200, body => 'fallback');
        });
        my $client = client($loop);
        my $op = $client->get('https://localhost:' . $server->port . '/', timeout => 2,
            ($case =~ /^strict/ ? (http_version => '2') : ()),
            on_response => sub ($tx, $response) { $version = $response->version },
            on_error => sub ($object, $error, @extra) { push @errors, "$error" },
            on_finish => sub { $loop->stop });
        my $guard = guard($loop); $loop->run; $guard->cancel;
        if ($case =~ /^strict/) {
            is($op->state, 'error', 'strict protocol selection fails');
            ok(@errors, 'failure reaches operation');
            ok(!$seen, 'no HTTP1 request dispatched for strict HTTP2');
        } else {
            is($version, '1.1', 'ordinary client accepts HTTP1 ALPN fallback');
            is_deeply(\@errors, [], 'fallback has no error');
        }
        cleanup($loop, $server, $client);
    };
}

subtest 'flow-controlled body and cancellation leave sibling streams healthy' => sub {
    my $loop = Linux::Event::Loop->new;
    my ($cancelled, $received, $finished, @errors, @terminal);
    my $payload = 'x' x (2 * 1024 * 1024);
    my $server = server($loop, http2 => { max_buffered_body_bytes => 3 * 1024 * 1024 },
        tuning => { high_watermark => 1024, low_watermark => 512 },
        on_headers => sub ($tx, $req) { $tx->on_finish(sub { push @terminal, $_[0]->state }) },
        on_request => sub ($tx, $request) {
            return if $request->target eq '/cancel';
            $tx->respond(status => 200, body => $payload);
        });
    my $client = client($loop);
    my $cancel = $client->get('https://localhost:' . $server->port . '/cancel',
        http_version => '2', timeout => 3,
        on_transaction => sub ($tx) { $loop->defer(sub { $tx->cancel }) },
        on_finish => sub { ++$cancelled; $loop->stop if ++$finished == 2 });
    my $body = '';
    my $large = $client->get('https://localhost:' . $server->port . '/large',
        http_version => '2', timeout => 3,
        on_data => sub ($tx, $bytes) { $body .= $bytes },
        on_end => sub { ++$received },
        on_error => sub ($obj, $error, @extra) { push @errors, "$error" },
        on_finish => sub { $loop->stop if ++$finished == 2 });
    my $guard = guard($loop); $loop->run; $guard->cancel;
    is($cancelled, 1, 'cancelled operation finishes once');
    is($cancel->state, 'cancelled', 'cancellation preserved');
    is($large->state, 'complete', 'sibling completes despite stream reset');
    is($body, $payload, 'body spans flow-control windows without loss or replay');
    is($received, 1, 'streaming end once');
    is_deeply(\@errors, [], 'no error on healthy sibling');
    is($server->connection_count, 1, 'cancellation did not close shared connection');
    cleanup($loop, $server, $client);
};

subtest 'streamed upload admission and GOAWAY drain preserve admitted work' => sub {
    my $loop = Linux::Event::Loop->new;
    my ($server, $body, $response, $admissions, $done, $finished, @terminal, @errors);
    $server = server($loop,
        on_headers => sub ($tx, $request) {
            $tx->on_finish(sub { push @terminal, $_[0]->state });
            $server->shutdown(grace => 10, on_complete => sub {
                ++$done; $loop->stop if $finished;
            });
        },
        on_request => sub ($tx, $request) {
            $body = $request->body;
            Linux::Event::Kernel::Timer->new(loop => $loop, after => 0.01,
                on_timer => sub { $tx->respond(status => 200, body => 'drained') });
        });
    my $client = client($loop);
    my $op = $client->post('https://localhost:' . $server->port . '/',
        http_version => '2', timeout => 3, stream_body => 1,
        on_transaction => sub ($tx) {
            ++$admissions;
            $tx->write('first');
            Linux::Event::Kernel::Timer->new(loop => $loop, after => 0.01,
                on_timer => sub { $tx->end('last') });
        }, on_response => sub ($tx, $res) { $response = $res->body },
        on_error => sub ($obj, $error, @extra) { push @errors, "$error" },
        on_finish => sub { ++$finished; $loop->stop if $done });
    my $guard = guard($loop); $loop->run; $guard->cancel;
    is($admissions, 1, 'one actual transaction admission');
    is($body, 'firstlast', 'admitted streaming body completes after GOAWAY');
    is($response, 'drained', 'delayed response drains before closure');
    is($op->state, 'complete', 'client reports completion');
    is_deeply(\@terminal, ['complete'], 'server finish observer preserved once');
    is_deeply(\@errors, [], 'GOAWAY does not fail admitted work');
    is($done, 1, 'service shutdown completed once');
    is($server->connection_count, 0, 'drained connection released');
    $client->shutdown;
    is($loop->count, 0, 'GOAWAY path releases sockets and grace timer');
};

subtest 'native callback can close its own transport without retention' => sub {
    my $loop = Linux::Event::Loop->new;
    my ($server, $weak_engine, $weak_tx, @terminal, @errors);
    $server = server($loop, on_headers => sub ($tx, $request) {
        $weak_tx = $tx; weaken($weak_tx);
        $tx->on_finish(sub { push @terminal, $_[0]->state });
        my ($stream) = values %{ $server->{connections} };
        $weak_engine = $stream->{http_engine}; weaken($weak_engine);
        $stream->close;
    }, on_request => sub { fail('closed request must not reach body completion') });
    my $client = client($loop);
    my $op = $client->get('https://localhost:' . $server->port . '/',
        http_version => '2', timeout => 2,
        on_error => sub ($obj, $error, @extra) { push @errors, "$error" },
        on_finish => sub { $loop->stop });
    my $guard = guard($loop); $loop->run; $guard->cancel;
    is($op->state, 'error', 'peer close reaches real operation');
    is(scalar @errors, 1, 'one terminal error');
    is_deeply(\@terminal, ['error'], 'server transaction fails once');
    ok(!defined $weak_tx && !defined $weak_engine, 'native context releases engine and transaction');
    cleanup($loop, $server, $client);
};

subtest 'malformed preface closes one connection without stopping service' => sub {
    require Linux::Event::TLS;
    require Linux::Event::IO::Sock::Stream;
    my $loop = Linux::Event::Loop->new;
    my $server = server($loop, on_request => sub ($tx, $request) {
        $tx->respond(status => 200, body => 'still serving');
    });
    my $peer = Linux::Event::IO::Sock::Stream->connect(loop => $loop,
        host => '127.0.0.1', port => $server->port,
        transport => Linux::Event::TLS->client(ca_file => $cert,
            server_name => 'localhost', alpn => ['h2']),
        on_ready => sub ($stream) { $stream->write('!' x 24) },
        on_data => sub {},
        on_eof => sub ($stream) { $stream->close },
        on_close => sub { $loop->stop });
    my $guard = guard($loop);
    my $ok = eval { $loop->run; 1 };
    my $error = "$@";
    $guard->cancel;
    ok($ok, 'invalid peer input is contained to its connection') or diag $error;
    $peer->close;
    my $client = client($loop);
    my ($body, @errors);
    my $op = $client->get('https://localhost:' . $server->port . '/',
        http_version => '2', timeout => 2,
        on_response => sub ($tx, $res) { $body = $res->body },
        on_error => sub ($obj, $err, @extra) { push @errors, "$err" },
        on_finish => sub { $loop->stop });
    $guard = guard($loop); $loop->run; $guard->cancel;
    is($body, 'still serving', 'new connection succeeds on the same listener and loop');
    is_deeply(\@errors, [], 'healthy request has no inherited error');
    cleanup($loop, $server, $client);
};

subtest 'grace deadline terminates a stalled HTTP2 stream once' => sub {
    my $loop = Linux::Event::Loop->new;
    my ($server, @terminal, $done, $finished);
    $server = server($loop, on_headers => sub ($tx, $request) {
        $tx->on_finish(sub { push @terminal, $_[0]->state });
        $server->shutdown(grace => 0.01, on_complete => sub {
            is_deeply(\@terminal, ['error'], 'terminal callback precedes service completion');
            ++$done; $loop->stop if $finished;
        });
    }, on_request => sub {});
    my $client = client($loop);
    my $op = $client->get('https://localhost:' . $server->port . '/',
        http_version => '2', timeout => 2,
        on_finish => sub { ++$finished; $loop->stop if $done });
    my $guard = guard($loop); $loop->run; $guard->cancel;
    is($op->state, 'error', 'incomplete response fails on forced closure');
    is($done, 1, 'shutdown completion once');
    is($finished, 1, 'operation terminal callback once');
    is($server->connection_count, 0, 'no stalled connection survives deadline');
    $client->shutdown;
    is($loop->count, 0, 'deadline leaves no timer or socket watchers');
};

for my $case ('untrusted certificate', 'wrong hostname') {
    subtest "HTTP2 refuses $case" => sub {
        my $loop = Linux::Event::Loop->new;
        my ($seen, @errors);
        my $server = server($loop, on_request => sub { ++$seen });
        my $client = client($loop,
            tls => { ($case eq 'wrong hostname' ? (ca_file => $cert) : ()) });
        my $host = $case eq 'wrong hostname' ? '127.0.0.1' : 'localhost';
        my $op = $client->get("https://$host:" . $server->port . '/',
            http_version => '2', timeout => 2,
            on_error => sub ($obj, $error, @extra) { push @errors, "$error" },
            on_finish => sub { $loop->stop });
        my $guard = guard($loop); $loop->run; $guard->cancel;
        is($op->state, 'error', 'TLS verification fails before HTTP2 dispatch');
        is(scalar @errors, 1, 'one operation error');
        ok(!$seen, 'no application request on unauthenticated TLS');
        cleanup($loop, $server, $client);
    };
}

done_testing;
