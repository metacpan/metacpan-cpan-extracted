use v5.36;
use strict;
use warnings;

use Test::More;
use Uniform::HTTP::Auth;

use Linux::Event::HTTP::Client;
use Linux::Event::HTTP::Server;
use Linux::Event::Kernel::Timer;
use Linux::Event::Loop;

subtest 'proxy 407 then target 401 use separate Uniform protection spaces' => sub {
    my $loop = Linux::Event::Loop->new;
    my $state = {
        requests => [],
        contexts => [],
        response_hits => 0,
        body => '',
    };

    my $proxy = Linux::Event::HTTP::Server->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 0,
        on_request => sub ($conn, $req, $res) {
            push @{$state->{requests}}, {
                target => $req->target,
                host => $req->header('Host'),
                authorization => $req->header('Authorization'),
                proxy_authorization => $req->header('Proxy-Authorization'),
            };

            if (!defined $req->header('Proxy-Authorization')) {
                $res->status(407);
                $res->header('Proxy-Authenticate', 'Basic realm="Proxy"');
                $res->body('proxy challenge');
                return;
            }

            if (!defined $req->header('Authorization')) {
                $res->status(401);
                $res->header('WWW-Authenticate', 'Basic realm="Origin"');
                $res->body('origin challenge');
                return;
            }

            $res->body('OK');
        },
    );

    my $proxy_url = 'http://127.0.0.1:' . $proxy->port;
    my $auth = Uniform::HTTP::Auth->new(
        schemes => ['basic'],
        credentials => sub ($context) {
            push @{$state->{contexts}}, { %$context };
            return {
                username => $context->{realm} eq 'Proxy' ? 'proxy-user' : 'origin-user',
                password => 'secret',
            };
        },
    );

    my $client = Linux::Event::HTTP::Client->new(
        loop => $loop,
        proxy => $proxy_url,
        auth => $auth,
        proxy_auth => $auth,
        max_auth_retries => 3,
    );

    my $guard = Linux::Event::Kernel::Timer->new(
        loop => $loop,
        after => 3,
        on_timer => sub ($timer) {
            die "client auth integration test timed out\n";
        },
    );

    my $operation;
    $operation = $client->get(
        'http://target.example/private?x=1',
        on_response => sub ($tx, $res) {
            ++$state->{response_hits};
            $state->{final_status} = $res->status;
        },
        on_body => sub ($tx, $res, $bytes) {
            $state->{body} .= $bytes;
        },
        on_complete => sub ($tx) {
            $guard->cancel;
            $client->close;
            $proxy->close;
            $loop->stop;
        },
        on_error => sub ($tx, $error) {
            die "client auth integration failed: $error\n";
        },
    );

    $loop->run;

    is($operation->transaction_count, 3,
        '407 and 401 each create another Transaction');
    is($operation->auth_retry_count, 2,
        'Operation counts both authentication retries');
    is($operation->redirect_count, 0,
        'authentication retries do not count as redirects');
    is_deeply([ $operation->urls ], [
        'http://target.example/private?x=1',
        'http://target.example/private?x=1',
        'http://target.example/private?x=1',
    ], 'authentication retry Transactions retain the same target URL');
    ok($operation->is_complete, 'authenticated operation completes');

    is($state->{response_hits}, 1,
        'on_response sees only the final response');
    is($state->{final_status}, 200, 'final response is successful');
    is($state->{body}, 'OK',
        'on_body receives only the final response body');

    is(scalar @{$state->{requests}}, 3,
        'proxy observes initial request and two authentication retries');
    my ($initial, $proxy_retry, $origin_retry) = @{$state->{requests}};
    is($initial->{target}, 'http://target.example/private?x=1',
        'proxied request uses absolute-form target');
    is($initial->{host}, 'target.example',
        'Host retains target origin identity');
    ok(!defined($initial->{proxy_authorization})
        && !defined($initial->{authorization}),
        'initial request is not preemptively authenticated');
    like($proxy_retry->{proxy_authorization} // '', qr/\ABasic /,
        '407 retry carries generated Proxy-Authorization');
    ok(!defined($proxy_retry->{authorization}),
        'proxy retry does not invent target Authorization');
    like($origin_retry->{proxy_authorization} // '', qr/\ABasic /,
        'target-auth retry preserves proxy authentication for same request');
    like($origin_retry->{authorization} // '', qr/\ABasic /,
        '401 retry carries generated Authorization');

    is(scalar @{$state->{contexts}}, 2,
        'Uniform credential lookup runs once for each protection space');
    is($state->{contexts}[0]{origin}, $proxy_url,
        '407 credential lookup uses proxy route origin');
    is($state->{contexts}[0]{realm}, 'Proxy',
        '407 credential lookup receives proxy realm');
    is($state->{contexts}[1]{origin}, 'http://target.example:80',
        '401 credential lookup uses target origin');
    is($state->{contexts}[1]{realm}, 'Origin',
        '401 credential lookup receives target realm');
};

subtest 'Digest auth-int receives exact request-target and replayable entity body' => sub {
    my $loop = Linux::Event::Loop->new;
    my $state = { requests => [], body => '' };

    my $server = Linux::Event::HTTP::Server->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 0,
        on_request => sub ($conn, $req, $res) {
            push @{$state->{requests}}, {
                target => $req->target,
                authorization => $req->header('Authorization'),
            };

            if (!defined $req->header('Authorization')) {
                $res->status(401);
                $res->header(
                    'WWW-Authenticate',
                    'Digest realm="Members", nonce="abc", qop="auth-int", algorithm=SHA-256',
                );
                $res->body('challenge');
                return;
            }

            $res->body('DIGEST-OK');
        },
    );

    my $url = 'http://127.0.0.1:' . $server->port . '/digest?x=1';
    my $auth = Uniform::HTTP::Auth->new(
        origin => 'http://127.0.0.1:' . $server->port,
        schemes => ['digest'],
        credentials => {
            username => 'user',
            password => 'secret',
        },
    );
    my $client = Linux::Event::HTTP::Client->new(loop => $loop, auth => $auth);
    my $guard = Linux::Event::Kernel::Timer->new(
        loop => $loop,
        after => 3,
        on_timer => sub ($timer) { die "Digest auth test timed out\n"; },
    );

    my $operation;
    $operation = $client->get(
        $url,
        on_body => sub ($tx, $res, $bytes) { $state->{body} .= $bytes; },
        on_complete => sub ($tx) {
            $guard->cancel;
            $client->close;
            $server->close;
            $loop->stop;
        },
        on_error => sub ($tx, $error) { die "Digest auth failed: $error\n"; },
    );

    $loop->run;

    is($operation->transaction_count, 2,
        'Digest challenge creates one retry Transaction');
    is($operation->auth_retry_count, 1,
        'Digest challenge increments auth retry count');
    is($state->{body}, 'DIGEST-OK', 'Digest retry reaches final response');
    my $authorization = $state->{requests}[1]{authorization} // '';
    like($authorization, qr/\ADigest /,
        'retry uses Digest Authorization');
    like($authorization, qr/\bqop=auth-int\b/,
        'bodyless request supplies empty entity body for auth-int');
    like($authorization, qr/uri="\/digest\?x=1"/,
        'Digest uses exact origin-form request-target on direct connection');
};

subtest 'zero retry limit exposes challenge and managed headers have one owner' => sub {
    my $loop = Linux::Event::Loop->new;
    my $server = Linux::Event::HTTP::Server->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 0,
        on_request => sub ($conn, $req, $res) {
            $res->status(401);
            $res->header('WWW-Authenticate', 'Basic realm="Members"');
            $res->body('NO');
        },
    );
    my $url = 'http://127.0.0.1:' . $server->port . '/private';
    my $auth = Uniform::HTTP::Auth->new(
        origin => 'http://127.0.0.1:' . $server->port,
        schemes => ['basic'],
        credentials => { username => 'user', password => 'secret' },
    );
    my $client = Linux::Event::HTTP::Client->new(
        loop => $loop,
        auth => $auth,
        max_auth_retries => 0,
    );

    my $ok = eval {
        $client->get(
            $url,
            headers => [ [ Authorization => 'Basic manual' ] ],
        );
        1;
    };
    ok(!$ok, 'manual Authorization is rejected while auth manager owns field');
    like($@, qr/Authorization header is managed by auth/,
        'managed Authorization rejection is explicit');

    my $guard = Linux::Event::Kernel::Timer->new(
        loop => $loop,
        after => 3,
        on_timer => sub ($timer) { die "zero auth retry test timed out\n"; },
    );
    my ($operation, $status, $body) = (undef, undef, '');
    $operation = $client->get(
        $url,
        on_response => sub ($tx, $res) { $status = $res->status; },
        on_body => sub ($tx, $res, $bytes) { $body .= $bytes; },
        on_complete => sub ($tx) {
            $guard->cancel;
            $client->close;
            $server->close;
            $loop->stop;
        },
        on_error => sub ($tx, $error) { die "zero auth retry failed: $error\n"; },
    );
    $loop->run;

    is($status, 401, 'max_auth_retries zero exposes 401 as final response');
    is($body, 'NO', 'challenge body is delivered normally when retry disabled');
    is($operation->transaction_count, 1, 'no retry Transaction is created');
    is($operation->auth_retry_count, 0, 'auth retry count remains zero');
};

done_testing;
