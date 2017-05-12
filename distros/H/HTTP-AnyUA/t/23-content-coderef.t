#!perl

use warnings;
use strict;

use lib 't/lib';

use HTTP::AnyUA;
use Test::More;
use Util qw(:server :test :ua);

# using Starman because we need a server that can handle chunked requests
my $server = start_server('t/app.psgi', type => 'Starman');

plan tests => scalar user_agents;

test_all_user_agents {
    plan tests => 10;

    my $ua      = shift;
    my $any_ua  = HTTP::AnyUA->new(ua => $ua, response_is_future => 1);

    if ($ua->isa('Mojo::UserAgent')) {
        # disable keep-alive to avoid Mojo::Reactor::EV warnings
        $ua->max_connections(0);
    }

    my $chunk   = 0;
    my @chunk   = ('some ', 'document');
    my $code    = sub { return $chunk[$chunk++] };

    my $path    = '/create-document';
    my $url     = $server->url . $path;
    my $future  = $any_ua->post($url, {
        headers => {'content-type' => 'text/plain'},
        content => $code,
    });

    $future->on_ready(sub {
        my $self    = shift;
        my $resp    = $self->is_done ? $self->get : $self->failure;
        my $env     = $server->read_env;

        note explain 'RESPONSE: ', $resp;
        note explain 'ENV: ', $env;

        SKIP: {
            skip 'unexpected env', 3 if ref($env) ne 'HASH';
            is($env->{REQUEST_METHOD}, 'POST', 'correct method sent');
            is($env->{REQUEST_URI}, $path, 'correct url sent');
            is($env->{content}, 'some document', 'correct body sent');
        }

        is_response_content($resp, 'created document');
        is_response_reason($resp, 'Created');
        is_response_status($resp, 201);
        is_response_success($resp, 1);
        is_response_url($resp, $url);
        is_response_header($resp, 'content-type', 'text/plain');
        response_protocol_ok($resp);
    });

    return $future;
};

