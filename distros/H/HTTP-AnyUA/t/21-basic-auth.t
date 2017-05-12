#!perl

use warnings;
use strict;

use lib 't/lib';

use HTTP::AnyUA;
use Test::More;
use Util qw(:server :test :ua);

my $server = start_server('t/app.psgi');

plan tests => scalar user_agents;

test_all_user_agents {
    plan tests => 12;

    my $ua      = shift;
    my $any_ua  = HTTP::AnyUA->new($ua, response_is_future => 1);

    my $user    = 'bob';
    my $pass    = 'opensesame';
    my $auth    = 'Ym9iOm9wZW5zZXNhbWU=';
    my $path    = '/get-document';
    my $url     = $server->url . $path;
    $url =~ s!^(https?://)!${1}${user}:${pass}\@!;
    my $future  = $any_ua->get($url);

    $future->on_ready(sub {
        my $self    = shift;
        my $resp    = $self->is_done ? $self->get : $self->failure;
        my $env     = $server->read_env;

        note explain 'RESPONSE: ', $resp;
        note explain 'ENV: ', $env;

        SKIP: {
            skip 'unexpected env', 4 if ref($env) ne 'HASH';
            is($env->{REQUEST_METHOD}, 'GET', 'correct method sent');
            is($env->{REQUEST_URI}, $path, 'correct url sent');
            is($env->{content}, '', 'no body sent');
            is($env->{HTTP_AUTHORIZATION}, "Basic $auth", 'correct authorization sent');
        }

        is_response_content($resp, 'this is a document');
        is_response_reason($resp, 'OK');
        is_response_status($resp, 200);
        is_response_success($resp, 1);
        TODO: {
            local $TODO = 'some user agents strip the auth from the URL';
            # Mojo::UserAgent strips the auth from the URL
            is_response_url($resp, $url);
        };
        is_response_header($resp, 'content-type', 'text/plain');
        is_response_header($resp, 'content-length', 18);
        response_protocol_ok($resp);
    });

    return $future;
};

