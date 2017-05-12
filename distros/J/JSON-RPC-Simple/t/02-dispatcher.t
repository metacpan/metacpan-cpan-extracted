#!/usr/bin/perl

package MyApp::Service;

use strict;
use warnings;

use bytes;

use Test::More tests => 22;
use Test::Exception;

use HTTP::Request;
use JSON qw(encode_json);

use base qw(JSON::RPC::Simple);

BEGIN { use_ok("JSON::RPC::Simple::Dispatcher"); }

my $dispatcher = JSON::RPC::Simple->dispatch_to({});
isa_ok($dispatcher, "JSON::RPC::Simple::Dispatcher");

throws_ok {
    $dispatcher->dispatch_to({
        "/API" => "MyApp::Test1",
    });
} qr{Target for "/API" is not a JSON::RPC::Simple};

lives_ok {
    $dispatcher->dispatch_to({
        "/API" => "MyApp::Service",
    });
}  "Ok to make dispatch table";

sub echo : JSONRpcMethod {
    my ($self, $request, $args) = @_;
    
    is($self, "MyApp::Service", "self is a MyAPP::Server");
    isa_ok($request, "HTTP::Request", "request is a HTTP::Request");
    is(ref $args, "HASH", "args is a hashref");
    
    return $args->{value};
}

my $json = encode_json({
    version => "1.1",
    method => "echo",
    params => {},
});
my $request = HTTP::Request->new(
    POST => "http://localhost/API",
    [ "Content-Type" => "application/json", 
      "Content-Length" => bytes::length($json) 
    ],
    $json,
);

my $response = $dispatcher->handle("/API", $request);
ok(!$dispatcher->errstr, "Got no error");

sub echo_transform_args : JSONRpcMethod(Id, Name, Arg) {
    my ($self, $request, $args) = @_;

    is_deeply($args, {
        Id      => 200,
        Name    => "Foobar",
        Arg     => undef
    }, "Transform positional to named");
    
    1;    
}

$json = encode_json({
    version => "1.1",
    method => "echo_transform_args",
    params => [200, "Foobar"],
});
$request = HTTP::Request->new(
    POST => "http://localhost/API",
    [ "Content-Type" => "application/json", 
      "Content-Length" => bytes::length($json) 
    ],
    $json,
);

$dispatcher->handle("/API", $request);
ok(!$dispatcher->errstr, "Got no error");

our $JSONRPC_AUTOLOAD;

my $called_autoload = 0;
my $called_autoload_attrs = 0;
sub JSONRPC_AUTOLOAD_ATTRS {
    my ($self, $request) = @_;

    is($self, "MyApp::Service", "self in autoloaded attrs is MyApp::Server");
    isa_ok($request, "HTTP::Request", "request in autoloaded attrs is HTTP::Request");

    $called_autoload_attrs = 1;
    return [];
}

sub JSONRPC_AUTOLOAD {
    my ($self, $request, $args) = @_;

    is($self, "MyApp::Service");
    isa_ok($request, "HTTP::Request");
    is(ref $args, "HASH");

    $called_autoload = 1;
    is($JSONRPC_AUTOLOAD, "autoloaded");
}

$json = encode_json({
    version => "1.1",
    method => "autoloaded",
    params => {},
});
$request = HTTP::Request->new(
    POST => "http://localhost/API",
    [ "Content-Type" => "application/json", 
      "Content-Length" => bytes::length($json) 
    ],
    $json,
);

$response = $dispatcher->handle("/API", $request);
ok($called_autoload);
ok($called_autoload_attrs);
ok(!$dispatcher->errstr);

sub dies : JSONRpcMethod {
    my ($self, $request, $args) = @_;

    die "arg";
}

sub dies_modifying_error : JSONRpcMethod {
    my ($self, $request, $args) = @_;

    $JSON::RPC::Simple::Dispatcher::HTTP_ERROR_CODE=200;
    
    die "arg";
}

$json = encode_json({
    version => "1.1",
    method => "dies",
    params => {},
});
$request = HTTP::Request->new(
    POST => "http://localhost/API",
    [ "Content-Type" => "application/json", 
      "Content-Length" => bytes::length($json) 
    ],
    $json,
);

$response = $dispatcher->handle("/API", $request);
is($response->code, 500);

$json = encode_json({
    version => "1.1",
    method => "dies_modifying_error",
    params => {},
});
$request = HTTP::Request->new(
    POST => "http://localhost/API",
    [ "Content-Type" => "application/json", 
      "Content-Length" => bytes::length($json) 
    ],
    $json,
);

$response = $dispatcher->handle("/API", $request);
is($response->code, 200);

$json = encode_json({
    version => "1.1",
    method => "dies",
    params => {},
});
$request = HTTP::Request->new(
    POST => "http://localhost/API",
    [ "Content-Type" => "application/json", 
      "Content-Length" => bytes::length($json) 
    ],
    $json,
);

$response = $dispatcher->handle("/API", $request);
is($response->code, 500);
