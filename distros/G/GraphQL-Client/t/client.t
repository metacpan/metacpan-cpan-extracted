#!/usr/bin/env perl

use warnings;
use strict;

use FindBin '$Bin';
use lib "$Bin/lib";

use Test::Exception;
use Test::More;

use Future;
use GraphQL::Client;
use MockTransport;

subtest 'transport' => sub {
    my $client = GraphQL::Client->new(transport_class => 'http');
    isa_ok($client->transport, 'GraphQL::Client::http', 'decide transport from transport_class');

    $client = GraphQL::Client->new(url => 'https://localhost:4000/graphql');
    isa_ok($client->transport, 'GraphQL::Client::http', 'decide transport from url');

    $client = GraphQL::Client->new(transport_class => 'not a real class');
    is($client->transport_class, 'not a real class', 'transport_class constructor works');
    throws_ok { $client->transport } qr/^Failed to load transport/, 'throws if invalid transport';
};

subtest 'request to transport' => sub {
    my $mock = MockTransport->new;
    my $client = GraphQL::Client->new(transport => $mock);

    $client->execute('{hello}');
    my $req = ($mock->requests)[-1];
    is_deeply($req->[0], {
        query => '{hello}',
    }, 'query is passed to transport');

    $client->execute('{hello}', {foo => 'bar'});
    $req = ($mock->requests)[-1];
    is_deeply($req->[0], {
        query => '{hello}',
        variables => {foo => 'bar'},
    }, 'vars passed to transport');

    $client->execute('{hello}', {foo => 'bar'}, 'opname');
    $req = ($mock->requests)[-1];
    is_deeply($req->[0], {
        query => '{hello}',
        variables => {foo => 'bar'},
        operationName => 'opname',
    }, 'operationName passed to transport');

    $client->execute('{hello}', {foo => 'bar'}, 'opname', {baz => 'qux'});
    $req = ($mock->requests)[-1];
    is_deeply($req->[1], {
        baz => 'qux',
    }, 'transport options passed to transport');

    $client->execute('{hello}', {foo => 'bar'}, {baz => 'qux'});
    $req = ($mock->requests)[-1];
    is_deeply($req->[1], {
        baz => 'qux',
    }, 'operation name can be omitted with transport options');
};

subtest 'success response' => sub {
    my $mock = MockTransport->new;
    my $client = GraphQL::Client->new(transport => $mock);

    $mock->response({
        response    => {
            data    => {
                hello   => 'Hello world!',
            },
        },
    });
    my $resp = $client->execute('{hello}');
    is_deeply($resp, {
        data => {hello => 'Hello world!'},
    }, 'response is packed') or diag explain $resp;
    {
        local $client->{unpack} = 1;
        my $resp = $client->execute('{hello}');
        is_deeply($resp, {
            hello => 'Hello world!',
        }, 'success response is unpacked') or diag explain $resp;
    };

    $mock->response(Future->done({
        response    => {
            data    => {
                hello   => 'Hello world!',
            },
        },
    }));
    my $f = $client->execute('{hello}');
    is_deeply($f->get, {
        data => {hello => 'Hello world!'},
    }, 'future response is packed') or diag explain $f->get;
    {
        local $client->{unpack} = 1;
        my $f = $client->execute('{hello}');
        is_deeply($f->get, {
            hello => 'Hello world!',
        }, 'future success response is unpacked') or diag explain $f->get;
    };
};

subtest 'response with errors' => sub {
    my $mock = MockTransport->new;
    my $client = GraphQL::Client->new(transport => $mock);

    $mock->response({
        response    => {
            data    => {
                hello   => 'Hello world!',
            },
            errors  => [
                {
                    message => 'Uh oh',
                },
            ],
        },
    });
    my $resp = $client->execute('{hello}');
    is_deeply($resp, {
        data => {hello => 'Hello world!'},
        errors => [{message => 'Uh oh'}],
    }, 'response is packed') or diag explain $resp;
    {
        local $client->{unpack} = 1;
        throws_ok { $client->execute('{hello}') } qr/^Uh oh$/, 'error response thrown';
        my $err = $@;
        is($err->error, 'Uh oh', 'error message is from first error');
        is($err->type, 'graphql', 'error type is "graphql"');
        my $resp = $err->{response};
        is_deeply($resp, {
            data => {hello => 'Hello world!'},
            errors => [{message => 'Uh oh'}],
        }, 'error includes the response') or diag explain $resp;
    };

    $mock->response({
        response    => undef,
        error       => 'Transport error',
        details     => {
            foo => 'bar',
        },
    });
    $resp = $client->execute('{hello}');
    is_deeply($resp, {
        errors => [{message => 'Transport error'}],
    }, 'unpacked response munges error into response') or diag explain $resp;
    {
        local $client->{unpack} = 1;
        throws_ok { $client->execute('{hello}') } qr/^Transport error$/, 'error response thrown';
        my $err = $@;
        my $resp = $err->{response};
        is_deeply($resp, {
            errors => [{message => 'Transport error'}],
        }, 'error includes the constructed response') or diag explain $resp;
    };
};

done_testing;
