use v5.36;
use Test::More;
use File::Temp qw(tempdir);
use Linux::Event::Loop;
use Linux::Event::Kernel::Timer;
use Linux::Event::HTTP::Server;
use Linux::Event::HTTP::Client;

my $available = eval {
    require Net::QUIC;
    Net::QUIC->VERSION('0.06');
    require Unblock::HTTP3;
    Unblock::HTTP3->VERSION('0.14');
    1;
};
die "HTTP3 required by this test lane: $@" if !$available && $ENV{REBUILD_REQUIRE_HTTP3};
plan skip_all => 'optional Net::QUIC and Unblock::HTTP3 required'
    unless $available;
plan skip_all => 'openssl command required' unless -x '/usr/bin/openssl';

my $dir = tempdir(CLEANUP => 1);
my ($cert, $key) = ("$dir/cert.pem", "$dir/key.pem");
system('/usr/bin/openssl', 'req', '-x509', '-newkey', 'ec',
    '-pkeyopt', 'ec_paramgen_curve:prime256v1', '-nodes',
    '-keyout', $key, '-out', $cert, '-subj', '/CN=localhost',
    '-addext', 'subjectAltName=DNS:localhost,IP:127.0.0.1',
    '-days', '1') == 0 or die 'certificate generation failed';

sub make_server ($loop, %callback) {
    return Linux::Event::HTTP::Server->new(
        loop => $loop, host => '127.0.0.1', port => 0, http3 => 1,
        tls => { cert_file => $cert, key_file => $key },
        %callback,
    );
}
sub make_client ($loop) {
    return Linux::Event::HTTP::Client->new(
        loop => $loop, http3 => 1, quic => { ca_file => $cert },
    );
}
sub guard ($loop) {
    return Linux::Event::Kernel::Timer->new(
        loop => $loop, after => 8,
        on_timer => sub { die "HTTP3 active/drain test timed out\n" },
    );
}

subtest 'active H3 cancellation isolates a flow-controlled sibling' => sub {
    my $loop = Linux::Event::Loop->new;
    my (@errors, $cancel_seen, $cancel_finish, $large_finish, $end);
    my $body = '';
    my $payload = 'x' x (512 * 1024);
    my $server = make_server($loop,
        on_request => sub ($tx, $request) {
            if ($request->target eq '/cancel') {
                ++$cancel_seen;
                return; # Keep this stream active until the client cancels.
            }
            $tx->respond(status => 200, body => $payload);
        },
        on_error => sub ($tx, $error, @extra) {
            # RST_STREAM/STOP_SENDING for /cancel may be expected here.
        },
    );
    my $client = make_client($loop);
    my $url = 'https://127.0.0.1:' . $server->port;
    my $cancel = $client->get($url . '/cancel',
        http_version => '3', timeout => 4,
        on_transaction => sub ($tx) {
            isa_ok($tx, 'Unblock::HTTP3::Transaction');
            $loop->defer(sub { $tx->cancel });
        },
        on_error => sub ($object, $error, @extra) {
            push @errors, "cancel: $error"
                unless $object->state eq 'cancelled';
        },
        on_finish => sub {
            ++$cancel_finish;
            $loop->stop if $large_finish;
        },
    );
    my $large = $client->get($url . '/large',
        http_version => '3', timeout => 4,
        on_data => sub ($tx, $chunk) { $body .= $chunk },
        on_end => sub { ++$end },
        on_error => sub ($object, $error, @extra) {
            push @errors, "large: $error";
        },
        on_finish => sub {
            ++$large_finish;
            $loop->stop if $cancel_finish;
        },
    );
    my $watchdog = guard($loop);
    $loop->run;
    $watchdog->cancel;
    is($cancel->state, 'cancelled', 'admitted request cancelled');
    is($cancel_finish, 1, 'cancelled operation finished once');
    is($large->state, 'complete', 'sibling H3 request completed');
    is($large_finish, 1, 'sibling operation finished once');
    is($end, 1, 'large streaming body ended once');
    is($body, $payload, 'flow-controlled sibling body intact');
    is_deeply(\@errors, [], 'no unexpected errors');
    is($server->connection_count, 1, 'sibling kept shared QUIC connection alive');
    $client->shutdown;
    my $shutdown_done = 0;
    $server->shutdown(grace => 0, on_complete => sub {
        ++$shutdown_done;
        $loop->stop;
    });
    # The zero-grace deadline fires on the next reactor turn. It is not
    # synchronous teardown for an established QUIC connection.
    if (!$shutdown_done) {
        my $closing_guard = guard($loop);
        $loop->run;
        $closing_guard->cancel;
    }
    is($shutdown_done, 1, 'forced shutdown completion called once');
    is($server->connection_count, 0, 'server released the QUIC session');
    is($loop->count, 0, 'all socket and timer watchers released');
};

subtest 'H3 shutdown preserves a delayed admitted response' => sub {
    my $loop = Linux::Event::Loop->new;
    my ($server, $client, $timer_fired, $finish, $shutdown_done);
    my ($response, @errors, @order);
    $server = make_server($loop,
        on_request => sub ($tx, $request) {
            push @order, 'admitted';
            Linux::Event::Kernel::Timer->new(
                loop => $loop, after => 0.03,
                on_timer => sub {
                    ++$timer_fired;
                    push @order, 'respond';
                    $tx->respond(status => 200, body => 'delayed H3');
                },
            );
            $server->shutdown(grace => 2, on_complete => sub {
                ++$shutdown_done;
                push @order, 'drained';
                $loop->stop if $finish;
            });
            is($shutdown_done // 0, 0, 'shutdown waits for admitted response');
        },
        on_error => sub ($tx, $error, @extra) {
            push @errors, "server: $error";
        },
    );
    $client = make_client($loop);
    my $op = $client->get(
        'https://127.0.0.1:' . $server->port . '/delayed',
        http_version => '3', timeout => 4,
        on_response => sub ($tx, $res) {
            $response = $res->body;
            push @order, 'client-response';
        },
        on_error => sub ($object, $error, @extra) {
            push @errors, "client: $error";
        },
        on_finish => sub {
            ++$finish;
            $loop->stop if $shutdown_done;
        },
    );
    my $watchdog = guard($loop);
    $loop->run;
    $watchdog->cancel;
    is($timer_fired, 1, 'delayed response timer fired');
    is($response, 'delayed H3', 'HTTP3 response survived GOAWAY');
    is($op->state, 'complete', 'admitted operation completed');
    is($finish, 1, 'one client terminal callback');
    is($shutdown_done, 1, 'one server shutdown callback');
    is_deeply(\@errors, [], 'no QUIC or HTTP3 error during drain');
    ok((grep { $_ eq 'respond' } @order), 'response was generated after shutdown began');
    $client->shutdown;
    is($server->connection_count, 0, 'server QUIC connection retired');
    is($loop->count, 0, 'grace timer and UDP resources released');
};

done_testing;
