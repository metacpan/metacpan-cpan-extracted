use v5.36;
use strict;
use warnings;

use Test::More;
use Scalar::Util qw(refaddr);

use Linux::Event::HTTP::Client;
use Linux::Event::HTTP::Server;
use Linux::Event::Kernel::Timer;
use Linux::Event::Loop;

my $loop = Linux::Event::Loop->new;
my $state = {
    requests => [],
};

my $proxy = Linux::Event::HTTP::Server->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0,
    data => $state,
    on_request => sub ($conn, $req, $res) {
        push @{$state->{requests}}, {
            connection          => refaddr($conn),
            method              => $req->method,
            target              => $req->target,
            host                => $req->header('Host'),
            authorization       => $req->header('Authorization'),
            cookie              => $req->header('Cookie'),
            proxy_authorization => $req->header('Proxy-Authorization'),
        };

        if ($req->target eq 'http://start.example/redir') {
            $res->status(302);
            $res->header('Location', 'http://next.example/final');
            $res->body('');
            return;
        }

        $res->body('OK');
    },
);

my $client = Linux::Event::HTTP::Client->new(
    loop => $loop,
    connect_timeout => 2,
);

my $proxy_url = 'http://127.0.0.1:' . $proxy->port;

my $ok = eval {
    $client->get(
        'http://example.test/',
        proxy => "$proxy_url/path",
    );
    1;
};
ok(!$ok, 'forward proxy URL with path is rejected');
like($@, qr/proxy URL must not contain a path or query/,
    'proxy path rejection is clear');

$ok = eval {
    $client->get(
        'http://example.test/',
        proxy => 'ftp://proxy.example/',
    );
    1;
};
ok(!$ok, 'unsupported proxy URL scheme is rejected');
like($@, qr/scheme must be http or https/,
    'proxy scheme rejection uses normal URL policy');

$ok = eval {
    $client->request(
        'CONNECT',
        'http://example.test/',
        proxy => $proxy_url,
    );
    1;
};
ok(!$ok, 'CONNECT cannot be expressed through forward-proxy option');
like($@, qr/use connect_tunnel\(\)/,
    'CONNECT rejection points to explicit tunnel API');

my $guard = Linux::Event::Kernel::Timer->new(
    loop => $loop,
    after => 3,
    on_timer => sub ($timer) {
        die "client forward-proxy integration test timed out\n";
    },
);

my @operations;
my @bodies;

my $finish = sub {
    $guard->cancel;
    $client->close;
    $proxy->close;
    $loop->stop;
};

my $third;
my $start_third = sub {
    $third = $client->get(
        'http://start.example/redir',
        proxy => $proxy_url,
        headers => [
            [ Authorization         => 'Bearer origin-secret' ],
            [ Cookie                => 'session=secret' ],
            [ 'Proxy-Authorization' => 'Basic proxy-secret' ],
        ],
        on_body => sub ($tx, $res, $bytes) {
            $bodies[2] .= $bytes;
        },
        on_complete => sub ($tx) {
            push @operations, $third;
            $finish->();
        },
        on_error => sub ($tx, $error) {
            die "redirected forward-proxy request failed: $error\n";
        },
    );
};

my $second;
my $start_second = sub {
    $second = $client->get(
        'https://secure.example/b?y=2#ignored',
        proxy => $proxy_url,
        on_body => sub ($tx, $res, $bytes) {
            $bodies[1] .= $bytes;
        },
        on_complete => sub ($tx) {
            push @operations, $second;
            $start_third->();
        },
        on_error => sub ($tx, $error) {
            die "second forward-proxy request failed: $error\n";
        },
    );

    is($second->request->target, 'https://secure.example/b?y=2',
        'HTTPS target uses absolute-form through explicit forward proxy');
    is($second->request->header('Host'), 'secure.example',
        'proxied HTTPS target Host identifies target rather than proxy');
};

my $first;
$first = $client->get(
    'http://one.example/a?x=1#ignored',
    proxy => $proxy_url,
    headers => [
        [ Host => 'wrong.example' ],
        [ 'X-Custom' => 'first' ],
    ],
    on_body => sub ($tx, $res, $bytes) {
        $bodies[0] .= $bytes;
    },
    on_complete => sub ($tx) {
        push @operations, $first;
        $start_second->();
    },
    on_error => sub ($tx, $error) {
        die "first forward-proxy request failed: $error\n";
    },
);

is($first->request->target, 'http://one.example/a?x=1',
    'forward proxy uses absolute-form target and strips fragment');
is($first->request->header('Host'), 'one.example',
    'forward proxy regenerates canonical target Host');

$loop->run;

is_deeply(
    \@bodies,
    [ 'OK', 'OK', 'OK' ],
    'proxied responses use the ordinary incremental response path',
);

is(scalar @{$state->{requests}}, 4,
    'proxy receives two ordinary requests plus two redirect hops');

is($state->{requests}[0]{target}, 'http://one.example/a?x=1',
    'proxy receives first absolute-form target');
is($state->{requests}[0]{host}, 'one.example',
    'proxy receives target Host rather than caller override');

is($state->{requests}[1]{target}, 'https://secure.example/b?y=2',
    'proxy receives HTTPS URI in absolute-form');
is($state->{requests}[1]{host}, 'secure.example',
    'HTTPS absolute-form request still carries target Host');

my %first_two_connection = map {
    $state->{requests}[$_]{connection} => 1
} 0, 1;
is(scalar(keys %first_two_connection), 1,
    'different target origins reuse one persistent proxy connection');

is($state->{requests}[2]{target}, 'http://start.example/redir',
    'redirect starts with absolute-form target through proxy');
is($state->{requests}[2]{authorization}, 'Bearer origin-secret',
    'initial proxied request carries caller Authorization');
is($state->{requests}[2]{cookie}, 'session=secret',
    'initial proxied request carries caller Cookie');
is($state->{requests}[2]{proxy_authorization}, 'Basic proxy-secret',
    'initial proxied request carries caller Proxy-Authorization');

is($state->{requests}[3]{target}, 'http://next.example/final',
    'cross-origin redirect remains on same explicit proxy in absolute-form');
is($state->{requests}[3]{host}, 'next.example',
    'redirect regenerates Host from redirected target');
ok(!defined $state->{requests}[3]{authorization},
    'cross-origin redirect strips target Authorization');
ok(!defined $state->{requests}[3]{cookie},
    'cross-origin redirect strips target Cookie');
is($state->{requests}[3]{proxy_authorization}, 'Basic proxy-secret',
    'explicit proxy authorization stays associated with same proxy');
is($state->{requests}[2]{connection}, $state->{requests}[3]{connection},
    'redirect reuses the persistent proxy route when available');

is($third->redirect_count, 1,
    'forward-proxy redirect remains one Client operation with two Transactions');
is(scalar($third->transactions), 2,
    'redirect through proxy preserves Transaction-per-hop invariant');

for my $operation (@operations) {
    ok($operation->is_complete,
        'forward-proxy Client operation completes normally');
}

done_testing;
