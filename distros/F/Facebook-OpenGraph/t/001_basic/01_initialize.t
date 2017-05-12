use strict;
use warnings;
use Test::More;
use Facebook::OpenGraph;
use Furl::HTTP;
use JSON 2;

subtest 'initialize' => sub {
    my $fb = Facebook::OpenGraph->new;
    isa_ok $fb, 'Facebook::OpenGraph', 'isa Facebook::OpenGraph';
};

subtest 'default' => sub {
    my $fb = Facebook::OpenGraph->new;

    is $fb->app_id, undef, 'app_id is not set';
    is $fb->secret, undef, 'secret is not set';
    is $fb->namespace, undef, 'namespace is not set';
    is $fb->access_token, undef, 'access_token is not set';
    is $fb->redirect_uri, undef, 'redirect_uri is not set';
    is $fb->batch_limit, 50, 'default batch_limit is 50';
    is $fb->is_beta, 0, 'default is_beta is 0';
    is $fb->use_appsecret_proof, 0, 'default use_appsecret_proof is 0';
    is $fb->use_post_method, 0, 'default use_post_method is 0';
    is $fb->version, undef, 'default Facebook Platform version is undef';

    my $json = $fb->json;
    isa_ok $json, 'JSON', '$fb->json isa JSON';
    my $ua = $fb->ua;
    isa_ok $ua, 'Furl::HTTP', '$fb->ua isa Furl::HTTP';
    is $ua->agent, 'Facebook::OpenGraph/' . $Facebook::OpenGraph::VERSION, 'default ua';
    is $ua->{capture_request}, 1, 'capture_request is 1';
};

subtest 'accessor' => sub {
    my $version = $Facebook::OpenGraph::VERSION;
    my $fb = Facebook::OpenGraph->new(+{
        app_id              => '123456789',
        secret              => 'secretkey',
        ua                  => Furl::HTTP->new(agent => "Facebook::OpenGraph/$version"),
        namespace           => 'my_app_namespace', # mostly used to deal w/ open graph action
        access_token        => '123456789|fooBarBuzz',
        redirect_uri        => 'https://sample.com/auth_cb',
        batch_limit         => 10,
        is_beta             => 1,
        js                  => JSON->new->utf8,
        use_appsecret_proof => 1,
        use_post_method     => 1,
        version             => 'v1.0',
    });

    is $fb->app_id, '123456789', 'app id';
    is $fb->secret, 'secretkey', 'app secret';
    is $fb->access_token, '123456789|fooBarBuzz', 'access_token';
    is $fb->namespace, 'my_app_namespace', 'app namespace';
    is $fb->redirect_uri, 'https://sample.com/auth_cb';
    is $fb->batch_limit, 10, 'batch limit';
    is $fb->is_beta, 1, 'is_beta';
    is $fb->use_appsecret_proof, 1, 'use_appsecret_proof';
    is $fb->use_post_method, 1, 'use_post_method';
    is $fb->version, 'v1.0', 'version';

    my $ua = $fb->ua;
    isa_ok $ua, 'Furl::HTTP', '$fb->ua isa Furl::HTTP';
    is $ua->agent, "Facebook::OpenGraph/$version", 'agent';
    isa_ok $fb->json, 'JSON', 'json';
};

done_testing;
