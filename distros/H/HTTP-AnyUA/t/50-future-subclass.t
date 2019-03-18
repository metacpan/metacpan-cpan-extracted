#!perl

use warnings;
use strict;

use lib 't/lib';

use HTTP::AnyUA;
use Test::More tests => 2;
use Util qw(test_user_agent);

HTTP::AnyUA->register_backend(Mock => '+MockBackend');

subtest 'test Future::Mojo as a Future response' => sub {
    test_user_agent 'Mojo::UserAgent' => sub {
        plan tests => 1;

        my $ua      = shift;
        my $any_ua  = HTTP::AnyUA->new($ua, response_is_future => 1);

        my $url = 'http://acme.tld/';

        my $future = $any_ua->get($url);
        isa_ok($future, 'Future::Mojo');

        return $future;
    };
};

subtest 'test AnyEvent::Future as a Future response' => sub {
    test_user_agent 'AnyEvent::HTTP' => sub {
        plan tests => 1;

        my $ua      = shift;
        my $any_ua  = HTTP::AnyUA->new($ua, response_is_future => 1);

        my $url = 'http://acme.tld/';

        my $future = $any_ua->get($url);
        isa_ok($future, 'AnyEvent::Future');

        return $future;
    };
};

