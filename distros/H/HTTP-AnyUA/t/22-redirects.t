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
    plan tests => 29;

    my $ua      = shift;
    my $any_ua  = HTTP::AnyUA->new($ua, response_is_future => 1);

    # enable redirects for useragents that don't do it by default
    if ($ua->isa('Mojo::UserAgent')) {
        $ua->max_redirects(5);
    }
    elsif ($ua->isa('Net::Curl::Easy')) {
        $ua->setopt(Net::Curl::Easy::CURLOPT_FOLLOWLOCATION(), 1);
    }

    my $path    = '/foo';
    my $url     = $server->url . $path;
    my $future  = $any_ua->get($url);

    $future->on_ready(sub {
        my $self    = shift;
        my $resp    = $self->is_done ? $self->get : $self->failure;
        my $env     = $server->read_env;

        note explain 'RESPONSE: ', $resp;
        note explain 'ENV: ', $env;

        SKIP: {
            skip 'unexpected env', 3 if ref($env) ne 'HASH';
            is($env->{REQUEST_METHOD}, 'GET', 'correct method sent');
            is($env->{REQUEST_URI}, '/baz', 'correct url sent');
            is($env->{content}, '', 'no body sent');
        }

        is_response_content($resp, 'you found it');
        is_response_reason($resp, 'OK');
        is_response_status($resp, 200);
        is_response_success($resp, 1);
        TODO: {
            local $TODO = 'some user agents do not support this correctly';
            # Furl has the URL from the original request, not the last request
            is_response_url($resp, $server->url . '/baz');
        };
        is_response_header($resp, 'content-type', 'text/plain');
        is_response_header($resp, 'content-length', 12);
        response_protocol_ok($resp);

        SKIP: {
            skip 'no redirect chain', 18 if !$resp || !$resp->{redirects};

            my $chain = $resp->{redirects};
            isa_ok($chain, 'ARRAY', 'redirect chain');
            is(scalar @$chain, 2, 'redirect chain has two redirections');

            my $r1 = $chain->[0];
            is_response_content($r1, 'the thing you seek is not here');
            is_response_reason($r1, 'Found');
            is_response_status($r1, 302);
            is_response_success($r1, 0);
            is_response_url($r1, $server->url . '/foo');
            is_response_header($r1, 'content-type', 'text/plain');
            is_response_header($r1, 'content-length', 30);
            response_protocol_ok($r1);

            my $r2 = $chain->[1];
            is_response_content($r2, 'not here either');
            is_response_reason($r2, 'Moved Permanently');
            is_response_status($r2, 301);
            is_response_success($r2, 0);
            is_response_url($r2, $server->url . '/bar');
            is_response_header($r2, 'content-type', 'text/plain');
            is_response_header($r2, 'content-length', 15);
            response_protocol_ok($r2);
        }
    });

    return $future;
};

