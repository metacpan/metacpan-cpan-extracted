use strict;
use Test::More;

use AnyEvent;
use JSON::RPC2::AnyEvent::Server;
use JSON::RPC2::AnyEvent::Constants qw(:all);

my $srv = JSON::RPC2::AnyEvent::Server->new(
    echo => sub{
        my ($cv, $args) = @_;
        my $w; $w = AE::timer 0.5, 0, sub{ undef $w; $cv->send($args) };
    },
    take_long => sub{
        my ($cv) = @_;
        my $w; $w = AE::timer 2.0, 0, sub{ undef $w; $cv->send("OK") };
    },
);
isa_ok $srv, 'JSON::RPC2::AnyEvent::Server', 'new object';


my $first_flag = 1;

my $cv1 = AE::cv;
my $res = $srv->dispatch({
    #jsonrpc => '2.0',  # Intentionally omitted
    id      => 0,
    method  => 'take_long',
    #params  => [],     # Intentionally omitted
})->cb(sub{
    my $res = shift->recv;
    
    ok(!$first_flag, "take_long is not completed fisrt");
    $first_flag = 0;
    
    isa_ok $res, 'HASH';
    is $res->{id}, 0;
    is $res->{result}, 'OK';
    
    $cv1->send;
});


my $cv2 = AE::cv;
$res = $srv->dispatch({
    jsonrpc => '2.0',
    id      => 1,
    method  => 'echo',
    params  => [qw(hoge fuga)],
})->cb(sub{
    my $res = shift->recv;
    
    ok($first_flag, "echo is completed fisrt");
    $first_flag = 0;
    
    isa_ok $res, 'HASH';
    is $res->{id}, 1;
    isa_ok $res->{result}, 'ARRAY';
    is $res->{result}[0], 'hoge';
    is $res->{result}[1], 'fuga';
    
    $cv2->send;
});


$cv1->recv;
$cv2->recv;

done_testing;
