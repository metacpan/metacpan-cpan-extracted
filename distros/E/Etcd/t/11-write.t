#!perl

use strict;
use warnings;

use Test::More tests => 2;

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

subtest set => sub {
    $response = {
        content => '{"action":"set","node":{"key":"/foo","value":"bar","modifiedIndex":1,"createdIndex":1}}',
        status => 201,
        success => 1,
        headers => {
            'x-etcd-index' => 1,
            'x-raft-index' => 1,
            'x-raft-term' => 1,
        },
    };

    is(Etcd->new->set('/foo', 'bar')->node->value, 'bar');
    is($method, 'PUT');
    is($url, 'http://127.0.0.1:4001/v2/keys/foo?value=bar');
};

subtest 'delete' => sub {
    $response = {
        content => '{"action":"set","node":{"key":"/foo","value":"bar","modifiedIndex":1,"createdIndex":1}}',
        content => '{"action":"delete","node":{"key":"/foo","modifiedIndex":1,"createdIndex":1},"prevNode":{"key":"/foo","value":"bar","modifiedIndex":1,"createdIndex":1}}',
        status => 200,
        success => 1,
        headers => {
            'x-etcd-index' => 1,
            'x-raft-index' => 1,
            'x-raft-term' => 1,
        },
    };

    is(Etcd->new->delete('/foo')->prev_node->value, 'bar');
    is($method, 'DELETE');
    is($url, 'http://127.0.0.1:4001/v2/keys/foo');
};
