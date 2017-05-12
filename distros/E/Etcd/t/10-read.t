#!perl

use strict;
use warnings;

use Test::More tests => 3;

use Etcd;
use HTTP::Tiny;

my ($response, $method, $url);
{
    no warnings 'redefine';
    sub HTTP::Tiny::request {
        my ($self, $m, $u) = @_;
        $method = $m;
        $url = $u;
        $response;
    };
}

subtest server_version => sub {
    $response = {
        content => 'etcd 1.2.3',
        status => 200,
        success => 1,
    };

    is(Etcd->new->server_version, 'etcd 1.2.3');
    is($method, 'GET');
    is($url, 'http://127.0.0.1:4001/version');
};

subtest get => sub {
    $response = {
        content => '{"action":"get","node":{"key":"/foo","value":"bar","modifiedIndex":1,"createdIndex":1}}',
        status => 200,
        success => 1,
        headers => {
            'x-etcd-index' => 1,
            'x-raft-index' => 1,
            'x-raft-term' => 1,
        },
    };

    is(Etcd->new->get('/foo')->node->value, 'bar');
    is($method, 'GET');
    is($url, 'http://127.0.0.1:4001/v2/keys/foo');
};

subtest exists => sub {
    $response = {
        content => '{"action":"get","node":{"key":"/foo","value":"bar","modifiedIndex":1,"createdIndex":1}}',
        status => 200,
        success => 1,
        headers => {
            'x-etcd-index' => 1,
            'x-raft-index' => 1,
            'x-raft-term' => 1,
        },
    };

    ok(Etcd->new->exists('/foo'));
    is($method, 'GET');
    is($url, 'http://127.0.0.1:4001/v2/keys/foo');
};
