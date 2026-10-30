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
plan skip_all => 'optional Net::QUIC and Unblock::HTTP3 required' unless $available;
plan skip_all => 'openssl command required' unless -x '/usr/bin/openssl';

my $dir = tempdir(CLEANUP => 1);
my ($cert, $key) = ("$dir/cert.pem", "$dir/key.pem");
system('/usr/bin/openssl', 'req', '-x509', '-newkey', 'ec',
    '-pkeyopt', 'ec_paramgen_curve:prime256v1', '-nodes',
    '-keyout', $key, '-out', $cert, '-subj', '/CN=localhost',
    '-addext', 'subjectAltName=DNS:localhost', '-days', '1') == 0
    or die 'certificate generation failed';

subtest 'H3 refuses mismatched authenticated origin' => sub {
    my $loop = Linux::Event::Loop->new;
    my (@errors, $admitted, $finished);
    my $server = Linux::Event::HTTP::Server->new(
        loop => $loop, host => '127.0.0.1', port => 0,
        tls => { cert_file => $cert, key_file => $key }, http3 => 1,
        on_request => sub ($tx, $request) {
            ++$admitted;
            $tx->respond(status => 200, body => 'should not arrive');
        },
    );
    my $client = Linux::Event::HTTP::Client->new(
        loop => $loop, http3 => 1, quic => { ca_file => $cert },
    );
    # The certificate is trusted but identifies localhost, not 127.0.0.1.
    my $op = $client->get('https://127.0.0.1:' . $server->port . '/bad',
        http_version => '3', timeout => 2,
        on_response => sub { fail('H3 must not accept a mismatched certificate') },
        on_error => sub ($object, $error, @extra) { push @errors, "$error" },
        on_finish => sub { ++$finished; $loop->stop },
    );
    my $guard = Linux::Event::Kernel::Timer->new(loop => $loop, after => 5,
        on_timer => sub { die "H3 identity rejection timed out\n" });
    $loop->run;
    $guard->cancel;
    is($op->state, 'error', 'strict H3 request fails without original-origin authentication');
    ok(@errors, 'client receives an error for mismatched identity');
    is($finished, 1, 'operation terminates exactly once');
    ok(!$admitted, 'server did not admit an HTTP3 request');
    $client->shutdown;
    $server->shutdown(grace => 0);
    is($loop->count, 0, 'failed handshake and shutdown release resources');
};

subtest 'H3 queued cancellation abandons the UDP connector' => sub {
    my $loop = Linux::Event::Loop->new;
    my (@errors, $finished);
    my $client = Linux::Event::HTTP::Client->new(
        loop => $loop, http3 => 1, quic => { ca_file => $cert },
    );
    my $op = $client->get('https://127.0.0.1:44449/cancel',
        http_version => '3', timeout => 1,
        on_response => sub { fail('cancelled request should not get response') },
        on_error => sub ($object, $error, @extra) { push @errors, "$error" },
        on_finish => sub { ++$finished },
    );
    $op->cancel;
    $client->shutdown;
    is($finished, 1, 'queued cancellation finishes exactly once');
    is($op->state, 'cancelled', 'operation is cancelled before QUIC authentication');
    is($loop->count, 0, 'cancelled UDP resolution/connector has no live watchers');
};

done_testing;
