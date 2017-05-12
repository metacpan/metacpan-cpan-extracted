use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::RedisServer;

my $redis_server;
eval {
    $redis_server = Test::RedisServer->new;
} or plan skip_all => 'redis-server is required to this test';

plan tests => 6;

my %connect_info = $redis_server->connect_info;

use EV;
use EV::Hiredis;

my $subscriber = EV::Hiredis->new( path => $connect_info{sock} );
my $publisher  = EV::Hiredis->new( path => $connect_info{sock} );

$subscriber->command('subscribe', 'foo', sub {
    my ($r, $e) = @_;

    if ($r->[0] eq 'subscribe') {
        is $r->[1], 'foo';

        $publisher->command('publish', 'foo', 'bar', sub {
            my ($r, $e) = @_;
            ok !$e;
            is $r, 1;

            $publisher->disconnect;
        });

    } elsif ($r->[0] eq 'message') {
        is $r->[1], 'foo';
        is $r->[2], 'bar';

        $subscriber->unsubscribe('foo', sub {
            fail 'no called here';
        });
    } elsif ($r->[0] eq 'unsubscribe') {
        is $r->[1], 'foo';

        $subscriber->disconnect;
    }
});

EV::run;
