use v5.36;
use strict;
use warnings;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use HTTP::CookieJar;
use Scalar::Util qw(refaddr);
use Uniform::HTTP::Auth;

BEGIN {
    eval {
        require Net::HTTP2::nghttp2;
        Net::HTTP2::nghttp2->VERSION('0.011');
        1;
    } or plan skip_all => 'Net::HTTP2::nghttp2 is not installed';

    Net::HTTP2::nghttp2->available
        or plan skip_all => 'nghttp2 library is not available';
}

use Linux::Event::HTTP::Client;
use Linux::Event::HTTP::Server;
use Linux::Event::Kernel::Timer;
use Linux::Event::Loop;

my $openssl = -x '/usr/bin/openssl' ? '/usr/bin/openssl' : undef;
if (!defined $openssl) {
    for my $dir (File::Spec->path) {
        my $candidate = File::Spec->catfile($dir, 'openssl');
        if (-x $candidate) {
            $openssl = $candidate;
            last;
        }
    }
}
plan skip_all => 'openssl command is required for HTTP/2 policy test'
    if !defined $openssl;

my $temp = tempdir(CLEANUP => 1);
my $cert = File::Spec->catfile($temp, 'server-cert.pem');
my $key = File::Spec->catfile($temp, 'server-key.pem');

my $generated;
{
    local $ENV{OPENSSL_CONF};
    delete $ENV{OPENSSL_CONF};
    $generated = system(
        $openssl, 'req', '-x509', '-newkey', 'rsa:2048', '-nodes',
        '-keyout', $key,
        '-out', $cert,
        '-subj', '/CN=localhost',
        '-addext', 'subjectAltName=DNS:localhost',
        '-days', '1',
    );
}
plan skip_all => 'openssl could not generate temporary TLS certificate'
    if $generated != 0 || !-s $cert || !-s $key;

my $loop = Linux::Event::Loop->new;
my $state = {
    requests      => [],
    connections   => {},
    response_hits => 0,
    redirect_hits => 0,
    body          => '',
    errors        => [],
};

my $server = Linux::Event::HTTP::Server->new(
    loop  => $loop,
    host  => '127.0.0.1',
    port  => 0,
    http2 => 1,
    tls   => {
        cert_file => $cert,
        key_file  => $key,
    },
    on_request => sub ($conn, $req, $res) {
        $state->{connections}{refaddr($conn)} = 1;
        push @{$state->{requests}}, {
            target        => $req->target,
            version       => $req->version,
            authority     => $req->authority,
            cookie        => $req->header('Cookie'),
            authorization => $req->header('Authorization'),
        };

        if ($req->target eq '/start') {
            $res->status(302);
            $res->header('Location', '/private');
            $res->header('Set-Cookie', 'session=abc; Path=/');
            $res->body('redirect-body');
            return;
        }

        if ($req->target eq '/private'
            && !defined($req->header('Authorization'))) {
            $res->status(401);
            $res->header(
                'WWW-Authenticate',
                'Basic realm="Members"',
            );
            $res->body('challenge-body');
            return;
        }

        if ($req->target eq '/private') {
            $res->body('OK');
            return;
        }

        $res->status(404);
        $res->body('unexpected');
    },
    on_error => sub ($conn, $error) {
        push @{$state->{errors}}, "server: $error";
        $loop->stop;
    },
);

my $origin = 'https://localhost:' . $server->port;
my $jar = HTTP::CookieJar->new;
my $auth = Uniform::HTTP::Auth->new(
    origin  => $origin,
    schemes => ['basic'],
    credentials => {
        username => 'user',
        password => 'secret',
    },
);

my $client = Linux::Event::HTTP::Client->new(
    loop       => $loop,
    http2      => 1,
    cookie_jar => $jar,
    auth       => $auth,
    tls        => {
        verify => 0,
        handshake_timeout => 2,
        shutdown_timeout  => 1,
    },
);

my $guard = Linux::Event::Kernel::Timer->new(
    loop  => $loop,
    after => 10,
    on_timer => sub ($timer) {
        die "HTTP/2 high-level policy test timed out\n";
    },
);

my $operation;
$operation = $client->get(
    "$origin/start",
    buffer_body => 1024,
    on_redirect => sub ($op, $tx, $res, $next_url) {
        ++$state->{redirect_hits};
        is($res->status, 302,
            'H2 redirect callback receives intermediate 302');
        is($next_url, "$origin/private",
            'H2 redirect resolves relative Location');
    },
    on_response => sub ($tx, $res) {
        ++$state->{response_hits};
        $state->{final_status} = $res->status;
    },
    on_complete => sub ($tx) {
        $state->{body} = $tx->response->body // '';
        $guard->cancel;
        $client->close;
        $server->close;
        $loop->stop;
    },
    on_error => sub ($tx, $error) {
        push @{$state->{errors}}, "client: $error";
        $loop->stop;
    },
);

is($operation->request->version, '1.1',
    'policy operation begins with provisional Request before ALPN');

$loop->run;

is_deeply($state->{errors}, [], 'H2 redirect/auth/cookie chain has no errors');
ok($operation->is_complete, 'H2 policy operation completes');
is($operation->transaction_count, 3,
    'redirect plus auth retry creates three Transactions');
is($operation->redirect_count, 1, 'H2 Operation records one redirect');
is($operation->auth_retry_count, 1, 'H2 Operation records one auth retry');
is($state->{redirect_hits}, 1, 'on_redirect runs once');
is($state->{response_hits}, 1,
    'on_response exposes only the final H2 response');
is($state->{final_status}, 200, 'final H2 response is 200');
is($state->{body}, 'OK',
    'buffer_body exposes only the final response body');

is(scalar(keys %{$state->{connections}}), 1,
    'redirect and auth retry reuse one H2 TLS connection');
is(scalar(@{$state->{requests}}), 3,
    'server receives redirect hop, auth challenge hop, and retry');

my ($start, $challenge, $retry) = @{$state->{requests}};

is_deeply(
    [ map { $_->{version} } @{$state->{requests}} ],
    [ '2', '2', '2' ],
    'every policy hop executes as HTTP/2',
);
is_deeply(
    [ map { $_->{target} } @{$state->{requests}} ],
    [ '/start', '/private', '/private' ],
    'policy hops preserve expected H2 request targets',
);
is_deeply(
    [ map { $_->{authority} } @{$state->{requests}} ],
    [ map { 'localhost:' . $server->port } 1 .. 3 ],
    'every policy hop preserves H2 authority',
);

ok(!defined($start->{cookie}),
    'initial H2 request has no cookie before Set-Cookie');
ok(!defined($start->{authorization}),
    'initial H2 request has no preemptive Authorization');

is($challenge->{cookie}, 'session=abc',
    'redirected H2 request receives cookie stored from 302');
ok(!defined($challenge->{authorization}),
    'first private H2 request is not preemptively authenticated');

is($retry->{cookie}, 'session=abc',
    'authenticated H2 retry keeps target cookie');
like($retry->{authorization} // '', qr/\ABasic /,
    'authenticated H2 retry carries generated Authorization');

is($jar->cookie_header("$origin/"), 'session=abc',
    'cookie jar retains H2 Set-Cookie result');

my @transactions = $operation->transactions;
is_deeply(
    [ map { $_->request->version } @transactions ],
    [ '2', '2', '2' ],
    'Operation history retains H2 Request version for every Transaction',
);
is_deeply(
    [ map { $_->response->status } @transactions ],
    [ 302, 401, 200 ],
    'Operation history retains redirect, challenge, and final Responses',
);

done_testing;
