#!/usr/bin/env perl

use warnings;
use strict;

use Test::Exception;
use Test::More;

use GraphQL::Client::CLI;

delete $ENV{GRAPHQL_CLIENT_OPTIONS};

subtest 'get_options' => sub {
    my $expected = {
        format          => 'json:pretty',
        filter          => undef,
        help            => undef,
        manual          => undef,
        operation_name  => undef,
        outfile         => undef,
        query           => 'bar',
        transport       => undef,
        unpack          => 0,
        url             => 'foo',
        variables       => undef,
        version         => undef,
    };

    my $r = GraphQL::Client::CLI->_get_options(qw{--url foo --query bar});
    is_deeply($r, $expected, '--url and --query set options') or diag explain $r;

    $r = GraphQL::Client::CLI->_get_options(qw{foo --query bar});
    is_deeply($r, $expected, '--url is optional') or diag explain $r;

    $r = GraphQL::Client::CLI->_get_options(qw{foo bar});
    is_deeply($r, $expected, '--query is also optional') or diag explain $r;

    {
        local $ENV{GRAPHQL_CLIENT_OPTIONS} = '--url asdf --query "baz qux" --unpack';
        local $expected->{query} = 'baz qux';
        local $expected->{unpack} = 1;
        $r = GraphQL::Client::CLI->_get_options(qw{--url foo});
        is_deeply($r, $expected, 'options can come from GRAPHQL_CLIENT_OPTIONS') or diag explain $r;
    }
};

subtest 'expand_vars' => sub {
    my $r = GraphQL::Client::CLI::_expand_vars({
        'foo.bar'       => 'baz',
        'foo.qux.muf'   => 42,
        'arr1[1].tut'   => 'whatever',
        'arr2[1][0].meh'=> 3.1415,
    });
    is_deeply($r, {
        foo => {
            bar => 'baz',
            qux => {
                muf => 42,
            },
        },
        arr1 => [
            undef,
            {
                tut => 'whatever',
            }
        ],
        arr2 => [
            undef,
            [
                {
                    meh => 3.1415,
                },
            ],
        ],
    }, 'expand all the vars') or diag explain $r;

    throws_ok {
        GraphQL::Client::CLI::_expand_vars({
            'foo[0]'    => 'baz',
            'foo.bar'   => 'muf',
        });
    } qr/^Conflicting keys/, 'throw if conflict between hash and array';

    throws_ok {
        GraphQL::Client::CLI::_expand_vars({
            'foo'       => 'baz',
            'foo.bar'   => 'muf',
        });
    } qr/^Conflicting keys/, 'throw if conflict between hash and scalar';
};

done_testing;
