use strict;
use warnings;
use lib '../lib';

use JSON qw(from_json to_json);
use JSON::RPC::Dispatcher;
use Test::More tests => 6;
use Test::WWW::Mechanize::PSGI;

my $rpc = JSON::RPC::Dispatcher->new;
my $endpoint = 'http://localhost';
my $mech = Test::WWW::Mechanize::PSGI->new(
    app => $rpc->to_app,
);

$rpc->register(echo => sub {
    return $_[0];
});

sub do_jsonrpc {
    my ( $content ) = @_;
    my $req = HTTP::Request->new(POST => $endpoint);
    $req->header('Content-type' => 'application/json');
    $req->header('Content-length' => length($content));
    $req->content($content);
    $mech->request($req);
}

do_jsonrpc(to_json({
    jsonrpc => '2.0',
    id => 0,
    method => 'echo',
    params => ['hello'],
}));

ok($mech->res->is_success);
is_deeply(from_json($mech->content), {
    jsonrpc => '2.0',
    id => 0,
    result => 'hello',
});

do_jsonrpc('{id:1');
is(500, $mech->res->code);
is_deeply(from_json($mech->content), {
    jsonrpc => '2.0',
    error => {
        code => -32700,
        message => 'Parse error.',
        data => '{id:1',
    },
});

do_jsonrpc(to_json({
    jsonrpc => '2.0',
    id => 1,
    method => 'echo',
    params => ['hello'],
}));
ok($mech->res->is_success);
is_deeply(from_json($mech->content), {
    jsonrpc => '2.0',
    id => 1,
    result => 'hello',
});
