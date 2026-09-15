use v5.36;
use strict;
use warnings;

use Test::More;

use Linux::Event::HTTP::Client;
use Linux::Event::HTTP::Server;
use Linux::Event::Kernel::Timer;
use Linux::Event::Loop;

my $loop = Linux::Event::Loop->new;

my $proxy1_state = { requests => [] };
my $proxy1 = Linux::Event::HTTP::Server->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0,
    data => $proxy1_state,
    on_request => sub ($conn, $req, $res) {
        push @{$proxy1_state->{requests}}, {
            target => $req->target,
            host   => $req->header('Host'),
        };
        $res->body('PROXY1');
    },
);

my $proxy2_state = { requests => [] };
my $proxy2 = Linux::Event::HTTP::Server->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0,
    data => $proxy2_state,
    on_request => sub ($conn, $req, $res) {
        push @{$proxy2_state->{requests}}, {
            target => $req->target,
            host   => $req->header('Host'),
        };
        $res->body('PROXY2');
    },
);

my $origin_state = { requests => [] };
my $origin = Linux::Event::HTTP::Server->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0,
    data => $origin_state,
    on_request => sub ($conn, $req, $res) {
        push @{$origin_state->{requests}}, {
            target => $req->target,
            host   => $req->header('Host'),
        };
        $res->body('DIRECT');
    },
);

my $proxy1_url = 'http://127.0.0.1:' . $proxy1->port;
my $proxy2_url = 'http://127.0.0.1:' . $proxy2->port;
my $origin_url = 'http://127.0.0.1:' . $origin->port;

my $client = Linux::Event::HTTP::Client->new(
    loop => $loop,
    connect_timeout => 2,
    proxy => $proxy1_url,
);

is($client->proxy, $proxy1_url,
    'Client retains configured default proxy URL');

my $no_proxy_client = Linux::Event::HTTP::Client->new(loop => $loop);
ok(!defined($no_proxy_client->proxy),
    'Client without proxy configuration reports no default proxy');
$no_proxy_client->close;

my $ok = eval {
    Linux::Event::HTTP::Client->new(
        loop => $loop,
        proxy => "$proxy1_url/path",
    );
    1;
};
ok(!$ok, 'Client constructor rejects proxy URL with path');
like($@, qr/\Anew\(\): proxy URL must not contain a path or query/,
    'constructor proxy validation reports constructor context');

$ok = eval {
    $client->request('CONNECT', 'http://target.example:443/');
    1;
};
ok(!$ok, 'default proxy is not used to smuggle CONNECT through ordinary request API');
like($@, qr/use connect_tunnel\(\)/,
    'default-proxy CONNECT rejection points to explicit tunnel API');

my $guard = Linux::Event::Kernel::Timer->new(
    loop => $loop,
    after => 3,
    on_timer => sub ($timer) {
        die "client default-proxy integration test timed out\n";
    },
);

my @body;
my @operation;
my ($first, $second, $third);

my $finish = sub {
    $guard->cancel;
    $client->close;
    $proxy1->close;
    $proxy2->close;
    $origin->close;
    $loop->stop;
};

my $start_third = sub {
    $third = $client->get(
        "$origin_url/direct?x=1#ignored",
        proxy => undef,
        on_body => sub ($tx, $res, $bytes) {
            $body[2] .= $bytes;
        },
        on_complete => sub ($tx) {
            push @operation, $third;
            $finish->();
        },
        on_error => sub ($tx, $error) {
            die "direct bypass request failed: $error\n";
        },
    );

    is($third->request->target, '/direct?x=1',
        'proxy => undef bypass restores origin-form request target');
    is($third->request->header('Host'), '127.0.0.1:' . $origin->port,
        'direct bypass Host identifies target origin');
};

my $start_second = sub {
    $second = $client->get(
        'http://two.example/override?y=2#ignored',
        proxy => $proxy2_url,
        on_body => sub ($tx, $res, $bytes) {
            $body[1] .= $bytes;
        },
        on_complete => sub ($tx) {
            push @operation, $second;
            $start_third->();
        },
        on_error => sub ($tx, $error) {
            die "proxy override request failed: $error\n";
        },
    );

    is($second->request->target, 'http://two.example/override?y=2',
        'per-request proxy override retains absolute-form target');
    is($second->request->header('Host'), 'two.example',
        'per-request proxy override retains target Host');
};

$first = $client->get(
    'http://one.example/default?x=1#ignored',
    on_body => sub ($tx, $res, $bytes) {
        $body[0] .= $bytes;
    },
    on_complete => sub ($tx) {
        push @operation, $first;
        $start_second->();
    },
    on_error => sub ($tx, $error) {
        die "default proxy request failed: $error\n";
    },
);

is($first->request->target, 'http://one.example/default?x=1',
    'Client default proxy uses absolute-form request target');
is($first->request->header('Host'), 'one.example',
    'Client default proxy derives Host from target URL');

$loop->run;

is_deeply(\@body, [ 'PROXY1', 'PROXY2', 'DIRECT' ],
    'default, override, and bypass routes return from expected endpoints');

is(scalar @{$proxy1_state->{requests}}, 1,
    'default proxy receives only the default-routed request');
is($proxy1_state->{requests}[0]{target}, 'http://one.example/default?x=1',
    'default proxy receives absolute-form target');
is($proxy1_state->{requests}[0]{host}, 'one.example',
    'default proxy receives target Host');

is(scalar @{$proxy2_state->{requests}}, 1,
    'override proxy receives only explicitly overridden request');
is($proxy2_state->{requests}[0]{target}, 'http://two.example/override?y=2',
    'override proxy receives absolute-form target');
is($proxy2_state->{requests}[0]{host}, 'two.example',
    'override proxy receives target Host');

is(scalar @{$origin_state->{requests}}, 1,
    'origin server receives only explicit default-proxy bypass');
is($origin_state->{requests}[0]{target}, '/direct?x=1',
    'bypass reaches origin using origin-form target');

for my $operation (@operation) {
    ok($operation->is_complete,
        'default-proxy routing operation completes normally');
}

ok($client->is_closed, 'Client closes normally after mixed proxy routes');

done_testing;
