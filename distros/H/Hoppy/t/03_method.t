use strict;
use warnings;
use Hoppy;
use Test::More tests => 9;

my $server = Hoppy->new; 

can_ok( $server, 'new' );
can_ok( $server, 'start' );
can_ok( $server, 'stop' );
can_ok( $server, 'regist_service' );
can_ok( $server, 'regist_hook' );
can_ok( $server, 'unicast' );
can_ok( $server, 'multicast' );
can_ok( $server, 'broadcast' );
can_ok( $server, 'dispatch' );

POE::Session->create(
    inline_states => {
        _start => sub {
            $server->stop;
        },
    }
);

$server->start;

