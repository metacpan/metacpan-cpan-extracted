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

my $loop = Linux::Event::Loop->new;
my ($slow_admitted, $slow_seen, $slow_finished, $fast_finished, $fast_body);
my ($fast, @slow_errors, @fast_errors);
my $server = Linux::Event::HTTP::Server->new(
    loop => $loop, host => '127.0.0.1', port => 0, http3 => 1,
    tls => { cert_file => $cert, key_file => $key },
    on_request => sub ($tx, $request) {
        if ($request->target eq '/slow') {
            ++$slow_seen;
            return; # Deliberately hold one admitted HTTP3 stream.
        }
        $tx->respond(status => 200, body => 'still healthy');
    },
);
my $client = Linux::Event::HTTP::Client->new(
    loop => $loop, http3 => 1, quic => { ca_file => $cert },
);
my $url = 'https://127.0.0.1:' . $server->port;
my $slow = $client->get($url . '/slow',
    http_version => '3', timeout => 0.30,
    on_transaction => sub ($tx) {
        ++$slow_admitted;
        isa_ok($tx, 'Unblock::HTTP3::Transaction');
    },
    on_response => sub { fail('unanswered request cannot succeed') },
    on_error => sub ($tx, $error, @extra) {
        push @slow_errors, "$error";
    },
    on_finish => sub {
        ++$slow_finished;
        # Schedule the second operation after the failed request has
        # completely unwound the engine and pool terminal callbacks.
        $loop->defer(sub {
            $fast = $client->get($url . '/healthy',
                http_version => '3', timeout => 3,
                on_response => sub ($tx, $response) {
                    $fast_body = $response->body;
                },
                on_error => sub ($tx, $error, @extra) {
                    push @fast_errors, "$error";
                },
                on_finish => sub {
                    ++$fast_finished;
                    $loop->stop;
                },
            );
        });
    },
);

my $watchdog = Linux::Event::Kernel::Timer->new(
    loop => $loop, after => 8,
    on_timer => sub { die "HTTP3 timeout isolation test timed out\n" },
);
$loop->run;
$watchdog->cancel;

is($slow_admitted, 1, 'slow request admitted to real HTTP3 stream');
is($slow_seen, 1, 'server observed slow stream exactly once');
is($slow->state, 'error', 'expired active operation reports error');
like($slow->error, qr/timed out/, 'active timeout reason preserved');
is($slow_finished, 1, 'timed-out operation finished once');
is(scalar @slow_errors, 1, 'timeout error callback delivered once');
is_deeply(\@fast_errors, [], 'healthy follow-up has no error');
is($fast_finished, 1, 'healthy follow-up finished once');
is($fast->state, 'complete', 'healthy operation completes after timeout');
is($fast_body, 'still healthy', 'subsequent HTTP3 response intact');

$client->shutdown;
my $shutdown_done = 0;
$server->shutdown(grace => 0, on_complete => sub {
    ++$shutdown_done;
    $loop->stop;
});
if (!$shutdown_done) {
    $watchdog = Linux::Event::Kernel::Timer->new(
        loop => $loop, after => 5,
        on_timer => sub { die "HTTP3 timeout cleanup timed out\n" },
    );
    $loop->run;
    $watchdog->cancel;
}
is($shutdown_done, 1, 'server shutdown completion once');
is($server->connection_count, 0, 'no active QUIC sessions after timeout cleanup');
is($loop->count, 0, 'no socket/timer watchers after timeout cleanup');

done_testing;
