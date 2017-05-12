#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More;

BEGIN {
    eval "use Catalyst;";
    plan skip_all => "Catalyst is required for this test" if $@;        
    plan tests => 30;    
}

use Catalyst::Test 'TestApp';

{
    my $request = HTTP::Request->new( 
        GET => 'http://localhost:3000/rpc?method=/test/app/greeting&params=[]' 
    );

    ok(my $response = request($request), '... got a response from the request');
    ok($response->is_success, '... response is successful');
    is($response->header( 'Content-Type' ), 'application/json-rpc', '... got the JSON content-type');    
    is($response->code, 200, '.. response code is 200');
       
    is($response->content, '{"jsonrpc":"2.0","result":"Hello World"}', '... got the content we expected');
}


{
    my $request = HTTP::Request->new( 
        GET => 'http://localhost:3000/foo/rpc?method=/test/app/greeting&params=["Man"]' 
    );

    ok(my $response = request($request), '... got a response from the request');
    ok($response->is_success, '... response is successful');
    is($response->header( 'Content-Type' ), 'application/json-rpc', '... got the JSON content-type');    
    is($response->code, 200, '.. response code is 200');
       
    is($response->content, '{"jsonrpc":"2.0","result":"Yo! What\'s up Man"}', '... got the content we expected');
}

{
    my $request = HTTP::Request->new( 
        GET => 'http://localhost:3000/foo/rpc?method=/test/app/greeting&params=["Man"]&greeting_prefix=Hey!' 
    );

    ok(my $response = request($request), '... got a response from the request');
    ok($response->is_success, '... response is successful');
    is($response->header( 'Content-Type' ), 'application/json-rpc', '... got the JSON content-type');    
    is($response->code, 200, '.. response code is 200');
       
    is($response->content, '{"jsonrpc":"2.0","result":"Hey! What\'s up Man"}', '... got the content we expected');
}

foreach my $i (1 .. 3) {
    my $request = HTTP::Request->new( 
        GET => 'http://localhost:3000/foo/rpc?method=/test/app/foo/bar&params=[]' 
    );

    ok(my $response = request($request), '... got a response from the request');
    ok($response->is_success, '... response is successful');
    is($response->header( 'Content-Type' ), 'application/json-rpc', '... got the JSON content-type');    
    is($response->code, 200, '.. response code is 200');
       
    is($response->content, '{"jsonrpc":"2.0","result":"FOO::BAR(' . $i . ')"}', '... got the content we expected');
}

