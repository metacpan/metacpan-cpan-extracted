use v5.36;
use strict;
use warnings;

use Test::More;
use HTTP::CookieJar;

use Linux::Event::HTTP::Client;
use Linux::Event::HTTP::Server;
use Linux::Event::Kernel::Timer;
use Linux::Event::Loop;

my $loop = Linux::Event::Loop->new;

my $state = { requests => [] };
my $proxy = Linux::Event::HTTP::Server->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0,
    data => $state,
    on_request => sub ($conn, $req, $res) {
        push @{$state->{requests}}, {
            target => $req->target,
            host   => $req->header('Host'),
            cookie => $req->header('Cookie'),
        };

        if ($req->target eq 'http://cookie.example/start') {
            $res->status(302);
            $res->header('Location', '/next');
            $res->add_header('Set-Cookie', 'session=abc; Path=/');
            $res->body('');
            return;
        }

        if ($req->target eq 'http://cookie.example/next') {
            $res->add_header('Set-Cookie', 'theme=dark; Path=/');
            $res->body('NEXT');
            return;
        }

        if ($req->target eq 'http://cookie.example/check') {
            $res->body('CHECK');
            return;
        }

        if ($req->target eq 'http://first.example/cross') {
            $res->status(302);
            $res->header('Location', 'http://second.example/land');
            $res->add_header('Set-Cookie', 'firstonly=1; Path=/');
            $res->body('');
            return;
        }

        if ($req->target eq 'http://second.example/land') {
            $res->body('CROSS');
            return;
        }

        $res->status(404);
        $res->body('unexpected target');
    },
);

my $proxy_url = 'http://127.0.0.1:' . $proxy->port;
my $jar = HTTP::CookieJar->new;
$jar->add('http://cookie.example/', 'seed=one; Path=/');
$jar->add("$proxy_url/", 'proxyonly=must-not-leak; Path=/');

my $client = Linux::Event::HTTP::Client->new(
    loop => $loop,
    connect_timeout => 2,
    proxy => $proxy_url,
    cookie_jar => $jar,
);

is($client->cookie_jar, $jar,
    'Client retains injected HTTP::CookieJar object');

my $ok = eval {
    Linux::Event::HTTP::Client->new(
        loop => $loop,
        cookie_jar => {},
    );
    1;
};
ok(!$ok, 'Client constructor rejects non-HTTP::CookieJar value');
like($@, qr/\Anew\(\): cookie_jar must be an HTTP::CookieJar object/,
    'cookie jar validation reports constructor context');

$ok = eval {
    $client->get(
        'http://cookie.example/manual',
        headers => [ [ Cookie => 'manual=1' ] ],
    );
    1;
};
ok(!$ok, 'caller Cookie header is rejected when cookie_jar owns cookie policy');
like($@, qr/Cookie header is managed by cookie_jar/,
    'Cookie ownership error points caller to the configured jar');

my $guard = Linux::Event::Kernel::Timer->new(
    loop => $loop,
    after => 3,
    on_timer => sub ($timer) {
        die "client cookie-jar integration test timed out\n";
    },
);

my @body;
my ($first, $second, $third);

my $finish = sub {
    $guard->cancel;
    $client->close;
    $proxy->close;
    $loop->stop;
};

my $start_cross_origin = sub {
    $third = $client->get(
        'http://first.example/cross',
        on_body => sub ($tx, $res, $bytes) {
            $body[2] .= $bytes;
        },
        on_complete => sub ($tx) {
            $finish->();
        },
        on_error => sub ($tx, $error) {
            die "cross-origin cookie request failed: $error\n";
        },
    );
};

my $start_check = sub {
    $second = $client->get(
        'http://cookie.example/check',
        on_body => sub ($tx, $res, $bytes) {
            $body[1] .= $bytes;
        },
        on_complete => sub ($tx) {
            $start_cross_origin->();
        },
        on_error => sub ($tx, $error) {
            die "cookie check request failed: $error\n";
        },
    );
};

$first = $client->get(
    'http://cookie.example/start',
    on_body => sub ($tx, $res, $bytes) {
        $body[0] .= $bytes;
    },
    on_complete => sub ($tx) {
        $start_check->();
    },
    on_error => sub ($tx, $error) {
        die "cookie redirect request failed: $error\n";
    },
);

$loop->run;

is_deeply(\@body, [ 'NEXT', 'CHECK', 'CROSS' ],
    'cookie-managed requests complete through same-origin and cross-origin redirects');

is(scalar @{$state->{requests}}, 5,
    'proxy observed the expected redirect and follow-up request sequence');

my ($start, $next, $check, $cross, $land) = @{$state->{requests}};

is($start->{host}, 'cookie.example',
    'proxied cookie request keeps target Host identity');
is($start->{cookie}, 'seed=one',
    'jar injects target cookie and does not inject proxy-origin cookie');
unlike($start->{cookie} // '', qr/proxyonly/,
    'proxy-origin cookie never leaks into target request');

like($next->{cookie} // '', qr/(?:\A|; )seed=one(?:;|\z)/,
    'same-origin redirect retains pre-existing target cookie');
like($next->{cookie} // '', qr/(?:\A|; )session=abc(?:;|\z)/,
    'Set-Cookie from redirect response is available on redirected request');

like($check->{cookie} // '', qr/(?:\A|; )seed=one(?:;|\z)/,
    'subsequent operation reuses seeded cookie');
like($check->{cookie} // '', qr/(?:\A|; )session=abc(?:;|\z)/,
    'subsequent operation reuses cookie stored from redirect response');
like($check->{cookie} // '', qr/(?:\A|; )theme=dark(?:;|\z)/,
    'subsequent operation reuses cookie stored from final response');
unlike($check->{cookie} // '', qr/proxyonly/,
    'proxy-origin cookie remains isolated from target origin');

ok(!defined($cross->{cookie}),
    'unrelated target origin does not receive cookies from previous target');
ok(!defined($land->{cookie}),
    'cross-origin redirect does not receive host-only cookie from prior origin');

is($jar->cookie_header('http://first.example/'), 'firstonly=1',
    'Set-Cookie from cross-origin redirect response is stored against its target origin');
is($jar->cookie_header('http://second.example/') // '', '',
    'redirect destination has no cookie merely because the route proxy is shared');

ok($first->is_complete && $second->is_complete && $third->is_complete,
    'cookie-managed Client operations complete normally');
ok($client->is_closed, 'Client closes normally after cookie integration test');

done_testing;
