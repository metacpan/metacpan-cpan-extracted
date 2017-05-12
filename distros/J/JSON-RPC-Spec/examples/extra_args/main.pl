#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';
use lib 'lib';
use MyApp;
use JSON::MaybeXS qw(JSON);

my $app   = MyApp->new;
my $coder = JSON->new;

my $params = +{
    jsonrpc => '2.0',
    method  => 'foo.bar',
    params  => +{
        key => 'value',
    },
    id => 1
};
my $json = $coder->encode($params);

my $extra_args = +{
    extra => 'args',
};
my $result = $app->jsonrpc->parse($json, $extra_args);
say $result;

=result

{
    "id": 1,
    "result": {
        "action": "bar",
        "params": {
            "key": "value"
        },
        "extra_args": [{
            "extra": "args"
        }],
        "controller": "foo"
    },
    "jsonrpc": "2.0"
}

=cut

my @extra_args = qw(fizz buzz);
my $result2 = $app->jsonrpc->parse($json, @extra_args);
say $result2;

=result2

{
    "jsonrpc": "2.0",
    "result": {
        "params": {
            "key": "value"
        },
        "action": "bar",
        "controller": "foo",
        "extra_args": ["fizz", "buzz"]
    },
    "id": 1
}

=cut
