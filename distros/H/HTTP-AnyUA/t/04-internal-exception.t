#!perl

use warnings;
use strict;

use lib 't/lib';

use HTTP::AnyUA;
use Test::More;
use Util qw(:test :ua);

plan tests => scalar user_agents;

test_all_user_agents {
    plan tests => 3;

    my $ua      = shift;
    my $any_ua  = HTTP::AnyUA->new($ua, response_is_future => 1);

    my $url     = 'invalidscheme://acme.tld/hello';
    my $future  = $any_ua->get($url);

    $future->on_ready(sub {
        my $self    = shift;
        my $resp    = $self->is_done ? $self->get : $self->failure;

        note explain 'RESPONSE: ', $resp;

        is_response_reason($resp, 'Internal Exception');
        is_response_status($resp, 599);
        is_response_success($resp, 0);
    });

    return $future;
};

