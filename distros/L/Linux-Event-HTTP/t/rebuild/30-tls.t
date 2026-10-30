use v5.36;
use Test::More;
use File::Temp qw(tempdir);
use Linux::Event::Loop;
use Linux::Event::Kernel::Timer;
use Linux::Event::HTTP::Server;
use Linux::Event::HTTP::Client;
use Linux::Event::IO::Sock::Stream;

plan skip_all => 'openssl command required' unless -x '/usr/bin/openssl';
my $dir = tempdir(CLEANUP => 1);
my ($cert, $key) = ("$dir/cert.pem", "$dir/key.pem");
{
    open my $log, '>', "$dir/openssl.log" or die $!;
    local *STDERR = $log;
    system('/usr/bin/openssl', 'req', '-x509', '-newkey', 'ec', '-pkeyopt', 'ec_paramgen_curve:prime256v1', '-nodes',
        '-keyout', $key, '-out', $cert, '-subj', '/CN=localhost',
        '-addext', 'subjectAltName=DNS:localhost', '-days', '1') == 0
        or die 'could not generate certificate';
}
my $native = $ENV{REBUILD_NATIVE_INPUT} // 1;
for my $case ('trusted localhost', 'untrusted localhost', 'wrong hostname') {
    subtest $case => sub {
        my $loop = Linux::Event::Loop->new;
        my ($seen, $body, @errors);
        my $server = Linux::Event::HTTP::Server->new(
            loop => $loop, native_input => $native, host => '127.0.0.1', port => 0,
            tls => { cert_file => $cert, key_file => $key },
            on_request => sub ($tx, $req) {
                ++$seen;
                $tx->respond(status => 200, body => 'secure');
            },
        );
        my $client = Linux::Event::HTTP::Client->new(loop => $loop, native_input => $native,
            tls => { ($case ne 'untrusted localhost' ? (ca_file => $cert) : ()) });
        my $host = $case eq 'wrong hostname' ? '127.0.0.1' : 'localhost';
        my $op = $client->get("https://$host:" . $server->port . '/', timeout => 1,
            on_response => sub ($tx, $res) { $body = $res->body },
            on_error => sub ($object, $error) { push @errors, "$error" },
            on_finish => sub { $loop->stop },
        );
        my $guard = Linux::Event::Kernel::Timer->new(loop => $loop, after => 3,
            on_timer => sub { die "TLS test timed out\n" });
        $loop->run;
        $guard->cancel;
        if ($case eq 'trusted localhost') {
            is($op->state, 'complete', 'verified HTTPS completed');
            is($body, 'secure', 'decrypted response');
            is($seen, 1, 'application received request');
        } else {
            is($op->state, 'error', 'verification failure');
            ok(@errors, 'error reaches operation');
            ok(!$seen, 'HTTP request not sent over unauthenticated TLS');
        }
        $client->shutdown;
        $server->close;
        $_->close for values %{ $server->{connections} };
    };
}

subtest 'shutdown owns and closes a stalled TLS handshake' => sub {
    my $loop = Linux::Event::Loop->new;
    my $server = Linux::Event::HTTP::Server->new(
        loop => $loop, native_input => $native, host => '127.0.0.1', port => 0,
        tls => { cert_file => $cert, key_file => $key },
        on_request => sub { fail('no HTTP request during incomplete TLS handshake') });
    my $completed = 0;
    my $peer = Linux::Event::IO::Sock::Stream->connect(loop => $loop,
        host => '127.0.0.1', port => $server->port,
        on_ready => sub {
            Linux::Event::Kernel::Timer->new(loop => $loop, after => 0.01,
                on_timer => sub {
                    is($server->connection_count, 1, 'TLS handshake tracked before HTTP readiness');
                    $server->shutdown(grace => 1, on_complete => sub {
                        ++$completed;
                        $loop->stop;
                    });
                });
        }, on_data => sub {});
    my $guard = Linux::Event::Kernel::Timer->new(loop => $loop, after => 3,
        on_timer => sub { die "TLS shutdown test timed out\n" });
    $loop->run;
    $guard->cancel;
    is($completed, 1, 'shutdown completes without waiting for TLS');
    is($server->connection_count, 0, 'stalled handshake no longer owned');
    $peer->close;
    is($loop->count, 0, 'no handshake watcher or grace timer survives');
};

done_testing;
