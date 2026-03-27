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
    package Test::Attach::BasicIO;
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
    package Test::Attach::DuplexIO;
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

subtest 'attach requires name' => sub {
    my $api = make_api(Test::Attach::DuplexIO->new);

    throws_ok {
        $api->attach('Pod', namespace => 'default');
    } qr/name required for attach/, 'name is required';
};

subtest 'attach fails when backend has no duplex transport' => sub {
    my $api = make_api(Test::Attach::BasicIO->new);

    throws_ok {
        $api->attach('Pod', 'nginx', namespace => 'default');
    } qr/missing call_duplex/, 'clear error for unsupported backend';
};

subtest 'attach builds request and forwards callbacks' => sub {
    my $io = Test::Attach::DuplexIO->new;
    my $api = make_api($io);

    my $open_called = 0;
    my $frame_cb = sub { };
    my $close_cb = sub { };
    my $error_cb = sub { };

    my $session = $api->attach('Pod', 'nginx',
        namespace   => 'default',
        container   => 'app',
        stdin       => 1,
        stdout      => 1,
        stderr      => 0,
        tty         => 1,
        on_open     => sub { $open_called = 1 },
        on_frame    => $frame_cb,
        on_close    => $close_cb,
        on_error    => $error_cb,
        subprotocol => 'v4.channel.k8s.io',
    );

    is($session->{type}, 'duplex-session', 'returns backend session object');

    my $req = $io->last_req;
    is($req->method, 'GET', 'uses GET');
    like($req->url, qr{/api/v1/namespaces/default/pods/nginx/attach}, 'uses attach path');
    like($req->url, qr/container=app/, 'container query param');
    like($req->url, qr/stdin=true/, 'stdin query param');
    like($req->url, qr/stdout=true/, 'stdout query param');
    like($req->url, qr/stderr=false/, 'stderr query param');
    like($req->url, qr/tty=true/, 'tty query param');
    is($req->headers->{Connection}, 'Upgrade', 'upgrade connection header');
    is($req->headers->{Upgrade}, 'websocket', 'upgrade websocket header');
    is($req->headers->{'Sec-WebSocket-Protocol'}, 'v4.channel.k8s.io', 'subprotocol header');
    is($req->headers->{Accept}, '*/*', 'accept header overridden for websocket upgrade');

    my $opts = $io->last_opts;
    is(ref($opts->{on_open}), 'CODE', 'on_open callback passed');
    is($opts->{on_frame}, $frame_cb, 'on_frame callback passed');
    is($opts->{on_close}, $close_cb, 'on_close callback passed');
    is($opts->{on_error}, $error_cb, 'on_error callback passed');

    ok(!$open_called, 'on_open callback is transport managed');
};

subtest 'attach default stream flags' => sub {
    my $io = Test::Attach::DuplexIO->new;
    my $api = make_api($io);

    $api->attach('Pod', 'nginx', namespace => 'default');

    my $req = $io->last_req;
    like($req->url, qr/stdin=false/, 'stdin defaults false');
    like($req->url, qr/stdout=true/, 'stdout defaults true');
    like($req->url, qr/stderr=true/, 'stderr defaults true');
    like($req->url, qr/tty=false/, 'tty defaults false');
};

done_testing;
