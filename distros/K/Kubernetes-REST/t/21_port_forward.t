#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

use Kubernetes::REST;
use Kubernetes::REST::Server;
use Kubernetes::REST::AuthToken;
use Kubernetes::REST::HTTPResponse;

{
    package Test::PF::BasicIO;
    use Moo;
    with 'Kubernetes::REST::Role::IO';

    sub call {
        return Kubernetes::REST::HTTPResponse->new(status => 200, content => '{}');
    }

    sub call_streaming {
        return Kubernetes::REST::HTTPResponse->new(status => 200, content => '');
    }
}

{
    package Test::PF::DuplexIO;
    use Moo;
    with 'Kubernetes::REST::Role::IO';

    has last_req  => (is => 'rw');
    has last_opts => (is => 'rw');

    sub call {
        return Kubernetes::REST::HTTPResponse->new(status => 200, content => '{}');
    }

    sub call_streaming {
        return Kubernetes::REST::HTTPResponse->new(status => 200, content => '');
    }

    sub call_duplex {
        my ($self, $req, %opts) = @_;
        $self->last_req($req);
        $self->last_opts(\%opts);
        return { ok => 1, type => 'duplex-session' };
    }
}

sub make_api {
    my ($io) = @_;
    return Kubernetes::REST->new(
        server      => Kubernetes::REST::Server->new(endpoint => 'https://mock.local'),
        credentials => Kubernetes::REST::AuthToken->new(token => 'MockToken'),
        resource_map_from_cluster => 0,
        io          => $io,
    );
}

subtest 'supports_duplex probe' => sub {
    my $basic = Test::PF::BasicIO->new;
    my $duplex = Test::PF::DuplexIO->new;
    ok(!$basic->supports_duplex, 'basic backend reports no duplex support');
    ok($duplex->supports_duplex, 'duplex backend reports duplex support');
};

subtest 'port_forward requires name and ports' => sub {
    my $api = make_api(Test::PF::DuplexIO->new);

    throws_ok {
        $api->port_forward('Pod', namespace => 'default', ports => [8080]);
    } qr/name required for port_forward/, 'name is required';

    throws_ok {
        $api->port_forward('Pod', 'nginx', namespace => 'default');
    } qr/ports required for port_forward/, 'ports are required';
};

subtest 'port_forward validates ports' => sub {
    my $api = make_api(Test::PF::DuplexIO->new);

    throws_ok {
        $api->port_forward('Pod', 'nginx', namespace => 'default', ports => []);
    } qr/ports required for port_forward/, 'empty port list rejected';

    throws_ok {
        $api->port_forward('Pod', 'nginx', namespace => 'default', ports => ['abc']);
    } qr/invalid port/, 'non-numeric port rejected';

    throws_ok {
        $api->port_forward('Pod', 'nginx', namespace => 'default', ports => [70000]);
    } qr/invalid port/, 'out-of-range port rejected';
};

subtest 'port_forward fails when backend has no duplex transport' => sub {
    my $api = make_api(Test::PF::BasicIO->new);

    throws_ok {
        $api->port_forward('Pod', 'nginx', namespace => 'default', ports => [8080]);
    } qr/missing call_duplex/, 'clear error for unsupported backend';
};

subtest 'port_forward builds request and forwards callbacks' => sub {
    my $io = Test::PF::DuplexIO->new;
    my $api = make_api($io);

    my $open_called = 0;
    my $frame_cb = sub { };
    my $close_cb = sub { };
    my $error_cb = sub { };

    my $session = $api->port_forward('Pod', 'nginx',
        namespace   => 'default',
        ports       => [8080, 8443],
        on_open     => sub { $open_called = 1 },
        on_frame    => $frame_cb,
        on_close    => $close_cb,
        on_error    => $error_cb,
        subprotocol => 'v4.channel.k8s.io',
    );

    is($session->{type}, 'duplex-session', 'returns backend session object');

    my $req = $io->last_req;
    is($req->method, 'GET', 'uses GET');
    like($req->url, qr{/api/v1/namespaces/default/pods/nginx/portforward}, 'uses portforward path');
    like($req->url, qr/ports=8080/, 'first port in query');
    like($req->url, qr/ports=8443/, 'second port in query');
    is($req->headers->{Connection}, 'Upgrade', 'upgrade connection header');
    is($req->headers->{Upgrade}, 'websocket', 'upgrade websocket header');
    is($req->headers->{'Sec-WebSocket-Protocol'}, 'v4.channel.k8s.io', 'subprotocol header');
    is($req->headers->{Accept}, '*/*', 'accept header overridden for websocket upgrade');

    my $opts = $io->last_opts;
    is(ref($opts->{on_open}), 'CODE', 'on_open callback passed');
    is($opts->{on_frame}, $frame_cb, 'on_frame callback passed');
    is($opts->{on_close}, $close_cb, 'on_close callback passed');
    is($opts->{on_error}, $error_cb, 'on_error callback passed');
};

subtest 'prepare_request supports array params and extra headers' => sub {
    my $api = make_api(Test::PF::BasicIO->new);

    my $req = $api->prepare_request('GET', '/api/v1/pods',
        parameters => {
            watch => 'true',
            ports => [80, 443],
        },
        headers => {
            Upgrade => 'websocket',
            'X-Test' => 'ok',
        },
    );

    like($req->url, qr/watch=true/, 'scalar query parameter included');
    like($req->url, qr/ports=80/, 'first repeated query parameter included');
    like($req->url, qr/ports=443/, 'second repeated query parameter included');
    is($req->headers->{Upgrade}, 'websocket', 'extra header merged');
    is($req->headers->{'X-Test'}, 'ok', 'custom header merged');
};

done_testing;
