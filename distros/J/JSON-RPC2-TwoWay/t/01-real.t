#!/usr/bin/perl

use strict;
use warnings;
use 5.10.0;

use Data::Dumper;

use Test::More tests => 40;

use JSON::MaybeXS;
use JSON::RPC2::TwoWay;

my $rpc = JSON::RPC2::TwoWay->new();

isa_ok($rpc, 'JSON::RPC2::TwoWay');

local $@;

eval { $rpc->register('nocallback'); };
like($@, qr/^no callback?/ , 'died with no callback?');

eval { $rpc->register('ping', sub { return 'pong' }); };
ok(!$@, 'register ping worked');

eval { $rpc->register('ping', sub { return 'pong' }); };
like($@, qr/^procedure ping already registered/ , 'died with procedure already registered');

eval { $rpc->register('greetings', sub { return 'hello there' }, notification => 1); };
ok(!$@, 'register notification');

eval { $rpc->register('arraytest', sub { return qw(array test) }, by_name => 0, state => 'foo'); };
ok(!$@, 'register positional');

my $cb; # need this one later on
eval { $rpc->register('nbtest', sub { $cb = pop; return 'nbtest' }, non_blocking => 1); };
ok(!$@, 'register non_blocking');

eval { $rpc->register('nbtest', sub { return 'nbtest' }, notification => 1, non_blocking => 1); };
like($@, qr/^a non_blocking notification is not sensible/ , 'died with a non_blocking notification is not sensible');

eval { $rpc->newconnection(); };
like($@, qr/^no write?/ , 'died with no write?');

my $writebuf = '';
my $con = eval { $rpc->newconnection(write => sub { $writebuf .= join('', @_) }); };
ok(!$@, 'create new connection');

isa_ok($con, 'JSON::RPC2::TwoWay::Connection');

my @res;
$writebuf = '';
@res = $con->handle('{"jsonrpc":"2.0","method":"ping","id":"foo","params":{}}');
ok(!@res, 'no errors from handle');
# meh.. order of the fields in the json object is undefined, so do this
is_deeply(decode_json($writebuf), {jsonrpc => '2.0', id => 'foo', result => 'pong'}, 'ping replied pong');

$writebuf = '';
@res = $con->handle('{"jsonrpc":"2.0');
like($res[0], qr/^json decode failed:/, 'json decode failed trapped');
$writebuf = decode_json($writebuf);
$writebuf->{error}->{message} = 'foo';
is_deeply($writebuf, {jsonrpc => '2.0', id => undef, error => {code => -32600, message => 'foo'} }, 'error 32600 in writebuf');

@res = $con->handle('["jsonrpc"]');
like($res[0], qr/^not a json object/, 'not a json object trapped');

@res = $con->handle('{"jsonrpc":"1.0"}');
like($res[0], qr/^expected jsonrpc version 2.0/, 'wrong jsonrpc version trapped');

@res = $con->handle('{"jsonrpc":"2.0","id":["foo"]}');
like($res[0], qr/^id is not a string or number/, 'invalid id trapped');

@res = $con->handle('{"jsonrpc":"2.0","id":"foo","a":1}');
like($res[0], qr/^invalid jsonnrpc object/, 'invalid jsonnrpc object trapped');

$writebuf = '';
@res = $con->handle('{"jsonrpc":"2.0","method":"pang","id":"foo","params":{}}');
is($res[1], 'error: -32601 Method not found.', 'method pang not found');
$writebuf = decode_json($writebuf);
$writebuf->{error}->{message} = 'foo';
is_deeply($writebuf, {jsonrpc => '2.0', id => 'foo', error => {code => -32601, message => 'foo'} }, 'error 32601 in writebuf');

@res = $con->handle('{"jsonrpc":"2.0","method":"ping","params":{}}');
is($res[1], 'error: -32000 Method is not a notification.', 'not a notification');

@res = $con->handle('{"jsonrpc":"2.0","method":"greetings","params":"foo"}');
is($res[1], 'error: -32600 Invalid Request: params should be array or object.', 'not a array or object');

@res = $con->handle('{"jsonrpc":"2.0","method":"greetings","params":["foo"]}');
is($res[1], 'error: -32602 This method expects named params.', 'require named params');

@res = $con->handle('{"jsonrpc":"2.0","method":"arraytest","id":"foo","params":{"foo":"bar"}}');
is($res[1], 'error: -32602 This method expects positional params.', 'require positional params');

@res = $con->handle('{"jsonrpc":"2.0","method":"arraytest","id":"foo","params":["foo"]}');
is($res[1],  'error: -32002 This method requires connection state foo', 'wrong connection state');

$con->state('foo');

$writebuf='';
@res = $con->handle('{"jsonrpc":"2.0","method":"arraytest","id":"foo","params":["foo"]}');
ok(!@res, 'no errors from arraytest');
is_deeply(decode_json($writebuf), {jsonrpc => '2.0', id => 'foo', result => [qw(array test)]}, 'connection state foo');

$writebuf='';
@res = $con->handle('{"jsonrpc":"2.0","method":"nbtest","id":"foo","params":{"foo":"bar"}}');
ok(!@res, 'no errors from nbtest');
is($writebuf, '', 'writebuf still empty');
$cb->({nbtest => 'nbtest'});
is_deeply(decode_json($writebuf), {jsonrpc => '2.0', id => 'foo', result => {nbtest => 'nbtest' }}, 'result via callback');

eval { $con->call('foo'); };
like($@, qr/^args should be a array or hash reference/ , 'no valid args trapped');

eval { $con->call('foo', {}); };
like($@, qr/^no callback?/ , 'no cb trapped');

eval { $con->call('foo', {}, 'foo'); };
like($@, qr/^callback should be a code reference/ , 'invalid cb trapped');

my @callres;
$writebuf='';
$con->call('foo', {}, sub { @callres = @_; });
$writebuf = decode_json($writebuf);
my $callid = $writebuf->{id};
$writebuf->{id} = 'bar';
is_deeply($writebuf, {jsonrpc => '2.0', method => 'foo', id => 'bar', params => {}}, 'call foo');

@res = $con->handle('{"jsonrpc":"2.0","id":"foo","result":"foo"}');
is($res[1], 'unknown call', 'unknown call');

@res = $con->handle('{"jsonrpc":"2.0","id":"'.$callid.'","result":"foo"}');
ok(!@res, 'no errors from handle');
#is($res[1], 'unknown call', 'unknown call');
is_deeply(\@callres, [ 0, 'foo' ], 'expected result from call to foo in callback');

@callres = ();
$writebuf='';
$con->call('foo', {}, sub { @callres = @_; });
$writebuf = decode_json($writebuf);
$callid = $writebuf->{id};
@res = $con->handle('{"jsonrpc":"2.0","id":"'.$callid.'","error":{"code":123,"message":"ouch"}}');
ok(!@res, 'no errors from handle');
is_deeply(\@callres, [{ code => 123, message => 'ouch' }], 'expected error from call to foo in callback');

# todo: test error object parsing


#print Dumper(\@callres);
#print Dumper(\@res);


