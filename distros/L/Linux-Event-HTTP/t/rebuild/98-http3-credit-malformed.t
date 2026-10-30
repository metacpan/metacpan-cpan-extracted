use v5.36;
use Test::More;
use File::Temp qw(tempdir);
use IO::Socket::INET;
use Socket qw(inet_aton pack_sockaddr_in);
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

sub make_server ($loop, %options) {
    return Linux::Event::HTTP::Server->new(
        loop => $loop, host => '127.0.0.1', port => 0,
        http3 => 1, tls => { cert_file => $cert, key_file => $key },
        %options,
    );
}
sub make_client ($loop) {
    return Linux::Event::HTTP::Client->new(
        loop => $loop, http3 => 1, quic => { ca_file => $cert },
    );
}
sub run_guard ($loop) {
    return Linux::Event::Kernel::Timer->new(
        loop => $loop, after => 8,
        on_timer => sub { die "H3 credit/malformed test timed out\n" },
    );
}
sub stop_server ($loop, $server, $client) {
    $client->shutdown;
    my $shutdown_done = 0;
    $server->shutdown(grace => 0, on_complete => sub {
        ++$shutdown_done;
        $loop->stop;
    });
    if (!$shutdown_done) {
        my $guard = run_guard($loop);
        $loop->run;
        $guard->cancel;
    }
    is($shutdown_done, 1, 'forced shutdown completes once');
    is($server->connection_count, 0, 'no remaining QUIC sessions');
    is($loop->count, 0, 'no remaining UDP/TCP/timer watchers');
}

subtest 'H3 stream-credit recovery admits a second queued request' => sub {
    my $loop = Linux::Event::Loop->new;
    my (@errors, @admitted, @responses, @operations, @transactions);
    my $finish = 0;
    my $credit_was_constrained;
    my $server = make_server($loop,
        quic => { transport => { max_bidi_streams => 1 } },
        on_request => sub ($tx, $request) {
            push @admitted, $request->target;
            if ($request->target eq '/one') {
                Linux::Event::Kernel::Timer->new(
                    loop => $loop, after => 0.03,
                    on_timer => sub {
                        $credit_was_constrained = @admitted == 1;
                        $tx->respond(status => 200, body => 'first');
                    },
                );
            } else {
                $tx->respond(status => 200, body => 'second');
            }
        },
        on_error => sub ($tx, $error, @extra) {
            push @errors, "server: $error";
        },
    );
    my $client = make_client($loop);
    my $url = 'https://127.0.0.1:' . $server->port;
    for my $path ('/one', '/two') {
        my $op = $client->get($url . $path,
            http_version => '3', timeout => 5,
            on_transaction => sub ($tx) { push @transactions, $tx },
            on_response => sub ($tx, $response) {
                push @responses, [$path, $response->body];
            },
            on_error => sub ($obj, $error, @extra) {
                push @errors, "$path: $error";
                $loop->stop;
            },
            on_finish => sub { $loop->stop if ++$finish == 2 },
        );
        push @operations, $op;
    }
    my $guard = run_guard($loop);
    $loop->run;
    $guard->cancel;
    is_deeply(\@errors, [], 'no credit/retry errors');
    ok($credit_was_constrained, 'only first request admitted while stream credit was held');
    is($finish, 2, 'both operations eventually finished');
    is_deeply(\@admitted, ['/one', '/two'], 'second admitted after credit recovery');
    is_deeply([sort { $a->[0] cmp $b->[0] } @responses],
        [['/one', 'first'], ['/two', 'second']], 'both responses preserved');
    is(scalar(@transactions), 2, 'two real engine transactions admitted');
    is($_->state, 'complete', 'queued H3 operation completed') for @operations;
    is($server->connection_count, 1, 'both streams shared one QUIC connection');
    stop_server($loop, $server, $client);
};

subtest 'malformed UDP datagrams do not poison subsequent HTTP3 traffic' => sub {
    my $loop = Linux::Event::Loop->new;
    my (@errors, $requests, $body, $finished);
    my $server = make_server($loop,
        on_request => sub ($tx, $request) {
            ++$requests;
            $tx->respond(status => 200, body => 'healthy');
        },
        on_error => sub ($tx, $error, @extra) {
            push @errors, "server: $error";
        },
    );
    my $raw = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1', LocalPort => 0, Proto => 'udp',
    ) or die "cannot create raw UDP peer: $!";
    my $peer = pack_sockaddr_in($server->port, inet_aton('127.0.0.1'));
    for my $junk ("?", "\xC0\x00\x00", "\x00" x 64) {
        my $sent = send($raw, $junk, 0, $peer);
        ok(defined($sent) && $sent == length($junk), 'malformed packet sent');
    }
    my $client = make_client($loop);
    my $op = $client->get('https://127.0.0.1:' . $server->port . '/healthy',
        http_version => '3', timeout => 4,
        on_response => sub ($tx, $response) { $body = $response->body },
        on_error => sub ($obj, $error, @extra) {
            push @errors, "client: $error";
            $loop->stop;
        },
        on_finish => sub { ++$finished; $loop->stop },
    );
    my $guard = run_guard($loop);
    $loop->run;
    $guard->cancel;
    is($op->state, 'complete', 'valid H3 request completes after malformed traffic');
    is($requests, 1, 'one valid request reaches application');
    is($body, 'healthy', 'valid response unaffected');
    is($finished, 1, 'one terminal callback');
    is_deeply(\@errors, [], 'no protocol exception or transport error');
    close $raw;
    stop_server($loop, $server, $client);
};

done_testing;
