use strict;
use Test::More;

use JSON::RPC2::AnyEvent::Server;
use JSON::RPC2::AnyEvent::Constants qw(:all);

my $srv = JSON::RPC2::AnyEvent::Server->new(
    hello => '[family_name, first_name]' => sub{
        my ($cv, $args) = @_;
        isa_ok($args, 'ARRAY');
        cmp_ok(scalar @$args, '>=', 2);
        my ($family, $given) = @$args;
        $cv->send("Hello, $given $family!");
    },
    echo => '{this, is, simply, meaningless, here}' => sub{
        my ($cv, undef, $orig_args) = @_;
        $cv->send($orig_args);
    },
    wanthash => '{foo, bar, baz}' => sub{
        my ($cv, $args) = @_;
        $cv->send($args);
    },
);
isa_ok $srv, 'JSON::RPC2::AnyEvent::Server', 'new object';


my $res = $srv->dispatch({
    jsonrpc => '2.0',
    id      => 0,
    method  => 'hello',
    params  => [qw(Sato Kana)],
})->recv;
isa_ok $res, 'HASH';
is $res->{id}, 0;
ok(!exists $res->{error});
is($res->{result}, 'Hello, Kana Sato!');

$res = $srv->dispatch({
    jsonrpc => '2.0',
    id      => 1,
    method  => 'hello',
    params  => "primitive value should not be allowed",
})->recv;
isa_ok $res, 'HASH';
is $res->{id}, 1;
ok(!exists $res->{result});
isa_ok $res->{error}, 'HASH';
is $res->{error}{code}, ERR_INVALID_REQUEST;

$res = $srv->dispatch({
    jsonrpc => '2.0',
    method  => 'echo',
    id      => 2,
    params  => [qw(foo bar baz)],
})->recv;
isa_ok $res, 'HASH';
is $res->{id}, 2;
ok(!exists $res->{error});
isa_ok $res->{result}, 'ARRAY';
is_deeply($res->{result}, ['foo', 'bar', 'baz']);

$res = $srv->dispatch({
    jsonrpc => '2.0',
    method  => 'echo',
    id      => 3,
    params  => {hoge => 1, fuga => 2},
})->recv;
isa_ok $res, 'HASH';
is $res->{id}, 3;
ok(!exists $res->{error});
isa_ok $res->{result}, 'HASH';
is_deeply($res->{result}, {hoge => 1, fuga => 2});

$res = $srv->dispatch({
    jsonrpc => '2.0',
    method  => 'wanthash',
    id      => 4,
    params  => [qw(one two three)],
})->recv;
isa_ok $res, 'HASH';
is $res->{id}, 4;
ok(!exists $res->{error});
isa_ok $res->{result}, 'HASH';
is_deeply($res->{result}, {foo => 'one', bar => 'two', baz => 'three'});


done_testing;

