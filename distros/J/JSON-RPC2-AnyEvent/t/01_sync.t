use strict;
use Test::More;

use JSON::RPC2::AnyEvent::Server;
use JSON::RPC2::AnyEvent::Constants qw(:all);

my $srv = JSON::RPC2::AnyEvent::Server->new(
    echo => sub{
        my ($cv, $args) = @_;
        $cv->send($args);
    },
);
isa_ok $srv, 'JSON::RPC2::AnyEvent::Server', 'new object';

my $res = $srv->dispatch({
    jsonrpc => '2.0',
    id      => 0,
    params  => [qw(hoge fuga)],
})->recv;
isa_ok $res, 'HASH';
is $res->{id}, 0;
is $res->{result}, undef;
isa_ok $res->{error}, 'HASH';
is $res->{error}{code}, ERR_INVALID_REQUEST;

$res = $srv->dispatch({
    jsonrpc => '2.0',
    method  => 'echo',
    id      => 1,
    params  => [qw(hoge fuga)],
})->recv;
isa_ok $res, 'HASH';
is $res->{id}, 1;
isa_ok $res->{result}, 'ARRAY';
is $res->{result}[0], 'hoge';
is $res->{result}[1], 'fuga';

done_testing;

