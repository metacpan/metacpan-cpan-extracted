#!perl

use strict;
use warnings;

use Test::More tests => 1;

use Etcd;
use HTTP::Tiny;

my @responses;
{
    no warnings 'redefine';
    sub HTTP::Tiny::request { shift @responses };
}

subtest set => sub {
    push @responses,
        {
            content => '',
            status => 307,
            success => '',
            headers => {
                location => 'http://127.0.0.2:4001/v2/keys/foo?value=bar',
            },
        },
        {
            content => '{"action":"set","node":{"key":"/foo","value":"bar","modifiedIndex":1,"createdIndex":1}}',
            status => 201,
            success => 1,
            headers => {
                'x-etcd-index' => 1,
                'x-raft-index' => 1,
                'x-raft-term' => 1,
            },
        }
    ;

    is(Etcd->new->set('/foo', 'bar')->node->value, 'bar');
    is(@responses, 0);
};
