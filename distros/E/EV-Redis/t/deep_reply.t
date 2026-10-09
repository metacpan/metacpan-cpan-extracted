use strict;
use warnings;
use Test::More;
use Test::RedisServer;

my $redis_server;
eval {
    $redis_server = Test::RedisServer->new;
} or plan skip_all => 'redis-server is required to this test';

my %connect_info = $redis_server->connect_info;

use EV;
use EV::Redis;

$SIG{PIPE} = 'IGNORE';

my $r = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});

sub depth_of {
    my ($res) = @_;
    my $d = 0;
    while (ref $res eq 'ARRAY' && @$res) { $d++; $res = $res->[0] }
    return ($d, $res);
}

sub eval_depth {
    my ($n) = @_;
    my ($res, $err);
    $r->eval("local t=0; for i=1,$n do t={t} end return t", 0,
        sub { ($res, $err) = @_; EV::break });
    my $guard = EV::timer 5, 0, sub { EV::break };
    EV::run;
    return ($res, $err);
}

{
    my ($res, $err) = eval_depth(10);
    is $err, undef, '10-deep reply has no error';
    my ($d, $leaf) = depth_of($res);
    is $d, 10, '... and decodes fully';
    is $leaf, 0, '... with the leaf intact';
}

{
    my ($res, $err) = eval_depth(512);
    is $err, undef, '512-deep reply has no error';
    my ($d512) = depth_of($res);
    is $d512, 512, '... and decodes fully';
}

for my $n (513, 600) {
    my ($res, $err) = eval_depth($n);
    is $res, undef, "$n-deep reply returns no result";
    like $err, qr/nesting depth/, "$n-deep reply fails through the callback";
}

{
    my $pong;
    $r->ping(sub { $pong = $_[0]; EV::break });
    my $guard = EV::timer 5, 0, sub { EV::break };
    EV::run;
    is $pong, 'PONG', 'the connection survives an over-deep reply';
    $r->disconnect;
}

done_testing;
