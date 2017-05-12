package My::Module;
use strict;

sub hello {
    my $self = shift;
    return "Hello World: @_";
}

package My::Another::Module;
use strict;

sub hi {
    my $self = shift;
    return "Hi There: @_";
}

sub _hello {
    my $self = shift;
    return "Hello World: @_";
}

package main;

use strict;
use Test::More;
use Plack::Test;

use JSON::RPC::Dispatcher::ClassMapping;
my $server = JSON::RPC::Dispatcher::ClassMapping->new(
    dispatch => { 
        Foo   => 'My::Module', 
        Bar   => 'My::Module', 
        Baz   => 'My::Another::Module', 
    },
);

my $app = $server->to_app;

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(HTTP::Request->new(POST => 'http://localhost/', ['Accept' => 'application/json-rpc', 'Content-Type' => 'application/json-rpc'], 
                                       '{"jsonrpc": "2.0", "method": "Foo.hello", "params": ["foo", "bar"], "id": 1}'));
    like $res->content, qr/Hello World: foo bar/;
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(HTTP::Request->new(POST => 'http://localhost/', ['Accept' => 'application/json-rpc', 'Content-Type' => 'application/json-rpc'], 
                                       '{"jsonrpc": "2.0", "method": "Bar.hello", "params": ["foo", "bar"], "id": 2}'));
    like $res->content, qr/Hello World: foo bar/;
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(HTTP::Request->new(POST => 'http://localhost/', ['Accept' => 'application/json-rpc', 'Content-Type' => 'application/json-rpc'], 
                                       '{"jsonrpc": "2.0", "method": "Baz.hi", "params": ["baz", "qux"], "id": 3}'));
    like $res->content, qr/Hi There: baz qux/;
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(HTTP::Request->new(POST => 'http://localhost/', ['Accept' => 'application/json-rpc', 'Content-Type' => 'application/json-rpc'], 
                                       '{"jsonrpc": "2.0", "method": "Baz._hello", "params": ["foo", "bar"], "id": 4}'));
    like $res->content, qr/Method not found/;
};

done_testing;
