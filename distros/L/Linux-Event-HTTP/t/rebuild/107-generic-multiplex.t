use v5.36;
use Test::More;
use File::Temp qw(tempdir);
use Linux::Event::Loop;
use Linux::Event::Kernel::Timer;
use Linux::Event::HTTP::Server;
use Linux::Event::HTTP::Client;

my $available = eval {
    require Unblock::HTTP2;
    Unblock::HTTP2->VERSION('0.13');
    require Unblock::HTTP3;
    Unblock::HTTP3->VERSION('0.14');
    require Net::QUIC;
    Net::QUIC->VERSION('0.06');
    1;
};
die "multiplexed CONNECT engines required: $@"
    if !$available && $ENV{REBUILD_REQUIRE_GENERIC_CONNECT};
plan skip_all => 'optional HTTP2, HTTP3 and QUIC engines required'
    unless $available;
plan skip_all => 'openssl required' unless -x '/usr/bin/openssl';

{
    package Local::Tunnel;
    sub new ($class, %option) {
        return bless { %option, bytes => '', eof => 0, failures => [] }, $class;
    }
    sub input ($self, $bytes) {
        $self->{bytes} .= $bytes;
        if ($self->{role} eq 'server' && $self->{bytes} eq 'PING') {
            $self->{bridge}->unblock_send('PONG');
        }
        if ($self->{role} eq 'client'
            && index($self->{bytes}, 'PONG') >= 0
            && !$self->{finished}) {
            $self->{finished} = 1;
            $self->{bridge}->unblock_finish;
        }
        return length $bytes;
    }
    sub input_eof ($self) {
        ++$self->{eof};
        $self->{bridge}->unblock_finish
            if $self->{role} eq 'server' && !$self->{finished}++;
        return;
    }
    sub transport_error ($self, $error) {
        push @{ $self->{failures} }, "$error";
        return;
    }
    sub resume_output ($self) { ++$self->{drains}; return }
}

my $dir = tempdir(CLEANUP => 1);
my ($cert, $key) = ("$dir/cert.pem", "$dir/key.pem");
system('/usr/bin/openssl', 'req', '-x509', '-newkey', 'ec',
    '-pkeyopt', 'ec_paramgen_curve:prime256v1', '-nodes',
    '-keyout', $key, '-out', $cert, '-subj', '/CN=localhost',
    '-addext', 'subjectAltName=DNS:localhost,IP:127.0.0.1',
    '-days', '1') == 0 or die "certificate generation failed";

for my $version (2, 3) {
    subtest "generic HTTP$version Extended CONNECT isolates a stream" => sub {
        my $loop = Linux::Event::Loop->new;
        my (@errors, $server_consumer, $client_consumer);
        my ($server_handoff, $client_handoff, $server_tx, $tunnel_finished);
        my ($normal, $normal_finished, $http_body);
        my $policy = $version == 2 ? 'http2' : 'http3';
        my $extended = $version == 2 ? 'enable_connect_protocol'
            : 'enable_extended_connect';
        my $server = Linux::Event::HTTP::Server->new(
            loop => $loop, host => '127.0.0.1', port => 0,
            native_input => ($ENV{REBUILD_NATIVE_INPUT} // 1),
            http1 => $version == 3 ? 1 : 0,
            $policy => { $extended => 1 },
            tls => { cert_file => $cert, key_file => $key },
            on_request => sub ($tx, $request) {
                ++$normal;
                $tx->respond(status => 200, body => 'healthy-sibling');
            },
            on_handoff => sub ($tx, $request, $bridge) {
                ++$server_handoff;
                return if $request->target eq '/denied';
                $server_tx = $tx;
                is($request->method, 'CONNECT', 'Server received CONNECT');
                is($request->protocol, 'raw-tunnel',
                    'generic protocol name unchanged');
                $server_consumer = Local::Tunnel->new(
                    role => 'server', bridge => $bridge,
                );
                $bridge->unblock_send('HELLO');
                return $server_consumer;
            },
            on_error => sub ($tx, $error) {
                push @errors, "server: $error";
            },
        );
        my $client = Linux::Event::HTTP::Client->new(
            loop => $loop, native_input => ($ENV{REBUILD_NATIVE_INPUT} // 1),
            http1 => 0,
            $policy => { $extended => 1 },
            tls => { ca_file => $cert },
            ($version == 3 ? (quic => { ca_file => $cert }) : ()),
            max_connections_per_origin => 1,
        );
        my $host = $version == 2 ? 'localhost' : '127.0.0.1';
        my $origin = "$host:" . $server->port;
        # The Client queues Extended CONNECT until peer SETTINGS permits
        # the protocol; no application warmup request is required.
        my $done = sub {
            $loop->stop if $tunnel_finished && $normal_finished;
        };
        my $tunnel = $client->request(
            url => "https://$origin/tunnel",
            http_version => "$version",
            method => 'CONNECT', protocol => 'raw-tunnel',
            timeout => 6,
            on_handoff => sub ($tx, $response, $bridge) {
                ++$client_handoff;
                is($response->status, 200, 'CONNECT response accepted');
                $client_consumer = Local::Tunnel->new(
                    role => 'client', bridge => $bridge,
                );
                $bridge->unblock_send('PING');
                return $client_consumer;
            },
            on_error => sub ($tx, $error) {
                push @errors, "Client CONNECT: $error";
                $loop->stop;
            },
            on_finish => sub {
                ++$tunnel_finished;
                $done->();
            },
        );
        my $plain = $client->get(
            "https://$origin/ordinary", http_version => "$version",
            timeout => 6,
            on_response => sub ($tx, $response) {
                $http_body = $response->body;
            },
            on_error => sub ($tx, $error) {
                push @errors, "Client sibling: $error";
                $loop->stop;
            },
            on_finish => sub {
                ++$normal_finished;
                $done->();
            },
        );
        my $guard = Linux::Event::Kernel::Timer->new(
            loop => $loop, after => 9,
            on_timer => sub {
                push @errors, 'generic multiplexed CONNECT timed out';
                $loop->stop;
            },
        );
        $loop->run;
        $guard->cancel;
        is_deeply(\@errors, [], 'no protocol errors');
        is($server_handoff, 1, 'one Server tunnel handoff');
        is($client_handoff, 1, 'one Client tunnel handoff');
        is($server_consumer->{bytes}, 'PING',
            'Server receives only tunnel DATA');
        is($client_consumer->{bytes}, 'HELLOPONG',
            'Client receives ordered tunnel DATA');
        is($client_consumer->{eof}, 1, 'Client receives one tunnel EOF');
        is($server_consumer->{eof}, 1, 'Server receives one tunnel EOF');
        is_deeply($server_consumer->{failures}, [], 'Server tunnel clean');
        is_deeply($client_consumer->{failures}, [], 'Client tunnel clean');
        is($tunnel_finished, 1, 'Client CONNECT completes exactly once');
        is($server_tx->state, 'complete', 'Server CONNECT completes');
        is($tunnel->state, 'complete', 'Client CONNECT terminal complete');
        is($plain->state, 'complete', 'ordinary sibling completes');
        is($http_body, 'healthy-sibling', 'ordinary sibling body intact');
        is($normal, 1, 'CONNECT did not reach normal HTTP handler');
        is($server->connection_count, 1, 'one shared transport');
        is($client->pool_stats->{connections}, 1,
            'Client retains multiplexed connection');
        is($client->pool_stats->{active}, 0, 'stream credit returned');

        # A denied CONNECT must finish its unused request producer and
        # return a normal HTTP rejection; it must not take over the stream.
        my ($denied_status, $denied_finished, $wrong_handoff);
        my $denied = $client->request(
            url => "https://$origin/denied",
            http_version => "$version",
            method => 'CONNECT', protocol => 'raw-tunnel',
            timeout => 4,
            on_handoff => sub { ++$wrong_handoff; return },
            on_response => sub ($tx, $response) {
                $denied_status = $response->status;
            },
            on_error => sub ($tx, $error) {
                push @errors, "Rejected CONNECT: $error";
                $loop->stop;
            },
            on_finish => sub {
                ++$denied_finished;
                $loop->stop;
            },
        );
        my $deny_guard = Linux::Event::Kernel::Timer->new(
            loop => $loop, after => 5,
            on_timer => sub {
                push @errors, 'rejected CONNECT hung';
                $loop->stop;
            },
        );
        $loop->run;
        $deny_guard->cancel;
        is($denied_status, 403, 'rejected CONNECT gives HTTP 403');
        is($wrong_handoff || 0, 0, 'Client never receives rejected tunnel');
        is($denied_finished, 1, 'rejected HTTP stream finishes exactly once');
        is($denied->state, 'complete', 'rejection is a completed HTTP response');
        is($server_handoff, 2, 'Server examined both CONNECT attempts');
        is($normal, 1, 'rejected CONNECT bypasses ordinary on_request');
        is_deeply(\@errors, [], 'rejection does not damage the connection');
        is($client->pool_stats->{connections}, 1, 'shared transport survives denial');
        is($client->pool_stats->{active}, 0, 'rejected stream returns pool credit');

        $client->shutdown;
        my $closed = 0;
        $server->shutdown(grace => 0, on_complete => sub {
            ++$closed;
            $loop->stop;
        });
        if (!$closed) {
            my $shutdown_guard = Linux::Event::Kernel::Timer->new(
                loop => $loop, after => 5,
                on_timer => sub {
                    push @errors, 'generic CONNECT shutdown timeout';
                    $loop->stop;
                },
            );
            $loop->run;
            $shutdown_guard->cancel;
        }
        is($closed, 1, 'Server shutdown once');
        is($server->connection_count, 0, 'no H2/H3 session retained');
        is($loop->count, 0, 'no socket or timer watchers retained');
    };
}
done_testing;
