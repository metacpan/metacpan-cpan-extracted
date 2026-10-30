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
my (%pending, %bodies, @errors, @order, @ops);
my ($seen_connections, $finished);
my $server;
$server = Linux::Event::HTTP::Server->new(
    loop => $loop, host => '127.0.0.1', port => 0, http3 => 1,
    tls => { cert_file => $cert, key_file => $key },
    on_request => sub ($tx, $request) {
        my $path = $request->target;
        push @order, "admitted:$path";
        $pending{$path} = $tx;
        return unless keys(%pending) == 2;
        $seen_connections = $server->connection_count;
        # Both connections must remain independently active before either
        # is allowed to receive a response.
        $pending{'/right'}->respond(status => 200, body => 'right-response');
        $pending{'/left'}->respond(status => 200, body => 'left-response');
    },
    on_error => sub ($tx, $error, @detail) {
        push @errors, "server: $error";
    },
);
my $url = 'https://127.0.0.1:' . $server->port;
my @clients = map {
    Linux::Event::HTTP::Client->new(
        loop => $loop, http3 => 1, quic => { ca_file => $cert },
    );
} 1 .. 2;
for my $i (0, 1) {
    my $path = $i ? '/right' : '/left';
    my $op = $clients[$i]->get($url . $path,
        http_version => '3', timeout => 5,
        on_response => sub ($tx, $response) {
            isa_ok($tx, 'Unblock::HTTP3::Transaction');
            $bodies{$path} = $response->body;
            push @order, "response:$path";
        },
        on_error => sub ($obj, $error, @detail) {
            push @errors, "$path: $error";
            $loop->stop;
        },
        on_finish => sub {
            $loop->stop if ++$finished == 2;
        },
    );
    push @ops, $op;
}
my $guard = Linux::Event::Kernel::Timer->new(loop => $loop, after => 8,
    on_timer => sub { die "multiple H3 connections timed out\n" });
$loop->run;
$guard->cancel;

is_deeply(\@errors, [], 'no QUIC or H3 error on either connection');
is($finished, 2, 'both independent client operations completed');
is($seen_connections, 2, 'server retained two concurrent QUIC connections');
is_deeply(\%bodies, {
    '/left' => 'left-response', '/right' => 'right-response',
}, 'responses routed to the correct independent clients');
is($_->state, 'complete', 'each client operation completed') for @ops;
is_deeply([sort keys %pending], ['/left', '/right'], 'both sessions admitted');
ok((grep { $_ eq 'response:/right' } @order), 'reverse response observed');

$_->shutdown for @clients;
my $shutdown_done = 0;
$server->shutdown(grace => 0, on_complete => sub {
    ++$shutdown_done;
    $loop->stop;
});
if (!$shutdown_done) {
    $guard = Linux::Event::Kernel::Timer->new(loop => $loop, after => 5,
        on_timer => sub { die "multiple H3 shutdown timed out\n" });
    $loop->run;
    $guard->cancel;
}
is($shutdown_done, 1, 'two-session shutdown completed once');
is($server->connection_count, 0, 'no QUIC sessions survive shutdown');
is($loop->count, 0, 'all client/server UDP and grace timers released');

done_testing;
