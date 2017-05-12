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
    plan tests => 13;

    my $ua      = shift;
    my $any_ua  = HTTP::AnyUA->new($ua, response_is_future => 1);

    my $path    = '/get-document';
    my $url     = $server->url . $path;
    my $body    = '';
    my $future  = $any_ua->get($url, {
        data_callback   => sub { my ($part, $resp) = @_; $body .= $part; },
    });

    $future->on_ready(sub {
        my $self    = shift;
        my $resp    = $self->is_done ? $self->get : $self->failure;
        my $env     = $server->read_env;

        note explain 'RESPONSE: ', $resp;
        note explain 'ENV: ', $env;

        SKIP: {
            skip 'unexpected env', 3 if ref($env) ne 'HASH';
            is($env->{REQUEST_METHOD}, 'GET', 'correct method sent');
            is($env->{REQUEST_URI}, $path, 'correct url sent');
            is($env->{content}, '', 'no body sent');
        }

        is($body, 'this is a document', 'streamed response content matches');
        ok($resp && !$resp->{content}, 'content in response structure is empty');

        is_response_reason($resp, 'OK');
        is_response_status($resp, 200);
        is_response_success($resp, 1);
        is_response_url($resp, $url);
        is_response_header($resp, 'content-type', 'text/plain');
        is_response_header($resp, 'content-length', 18);
        is_response_header($resp, 'x-foo', 'bar');
        response_protocol_ok($resp);
    });

    return $future;
};

