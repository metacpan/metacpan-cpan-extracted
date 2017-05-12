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
    plan tests => 8;

    my $ua      = shift;
    my $any_ua  = HTTP::AnyUA->new(ua => $ua, response_is_future => 1);

    my $path    = '/modify-document';
    my $url     = $server->url . $path;
    my $future  = $any_ua->delete($url);

    $future->on_ready(sub {
        my $self    = shift;
        my $resp    = $self->is_done ? $self->get : $self->failure;
        my $env     = $server->read_env;

        note explain 'RESPONSE: ', $resp;
        note explain 'ENV: ', $env;

        SKIP: {
            skip 'unexpected env', 2 if ref($env) ne 'HASH';
            is($env->{REQUEST_METHOD}, 'DELETE', 'correct method sent');
            is($env->{REQUEST_URI}, $path, 'correct url sent');
        }

        is_response_reason($resp, 'No Content');
        is_response_status($resp, 204);
        is_response_success($resp, 1);
        is_response_url($resp, $url);
        response_protocol_ok($resp);

        my $body = ref($resp) eq 'HASH' && $resp->{content};
        ok(!$body, 'response body is empty');
    });

    return $future;
};

