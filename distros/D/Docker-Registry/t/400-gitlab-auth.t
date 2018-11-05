#!/usr/bin/env perl
use strict;
use warnings;
use Test::Lib;
use Test::Docker::Registry;

use Test::Deep;
use HTTP::Request;

use Docker::Registry::Auth::Gitlab;

{
    my $auth = Docker::Registry::Auth::Gitlab->new(
        username     => 'foo',
        access_token => 'bar',
    );

    my $jwt = $auth->jwt;
    isa_ok($jwt, 'URI', "Got a JWT URI");

    my $uri = $auth->_build_token_uri('scope');
    isa_ok($uri, 'URI', ".. and we have a access_token URI");
    is($uri->host,     'gitlab.com', ".. with the correct hostname");
    is($uri->userinfo, 'foo:bar',    ".. and the correct login details");
    my %query_params      = $uri->query_form;
    my %want_query_params = (
        service       => 'container_registry',
        scope         => 'scope',
        client_id     => 'docker',
        offline_token => 'true',
    );
    cmp_deeply(\%query_params, \%want_query_params,
        ".. with the correct query params");

    # Override HTTP::Tiny get so we don't need a network connection
    my $override = Sub::Override->new(
        "HTTP::Tiny::get" => sub {
            return {
                success => 1,
                content => '{"token":"mysupersecretaccess_token"}',
            };
        }
    );

    is($auth->get_bearer_token, "mysupersecretaccess_token",
        "Go the super secret token from gitlab!");

    my $req = HTTP::Request->new('GET', $uri);
    $req = $auth->authorize($req);

    isa_ok($req, "HTTP::Request", "->authorize works too");
    is(
        $req->headers->header("authorization"),
        "Bearer mysupersecretaccess_token",
        ".. with the correct header"
    );

    $override->restore;
}

{
    my $auth = Docker::Registry::Auth::Gitlab->new(
        username     => 'foo',
        access_token => 'bar',
        repo => 'foobar',
    );

    my $jwt = $auth->jwt;
    isa_ok($jwt, 'URI', "Got a JWT URI");
}

SKIP: {

    my $msg = "Live test, set GITLAB_USERNAME, GITLAB_TOKEN to run this"
    . " test. Optionally set GITLAB_JWT if you want to test against a"
    . " self-hosted server. GITLAB_REPO can also be set.";

    skip($msg, 1) unless grep { /^GITLAB_/ } keys %ENV;
    note "Running live tests";

    my $auth = Docker::Registry::Auth::Gitlab->new(
        username     => $ENV{GITLAB_USERNAME},
        access_token => $ENV{GITLAB_TOKEN},
        $ENV{GITLAB_JWT}  ? (jwt  => $ENV{GITLAB_JWT})  : (),
        $ENV{GITLAB_REPO} ? (repo => $ENV{GITLAB_REPO}) : (),
    );

    my $token = $auth->get_bearer_token;
    isnt($token, undef, "We got '$token' from gitlab");

}
done_testing;
