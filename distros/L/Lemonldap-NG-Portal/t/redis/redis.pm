use strict;
use Redis;
use Time::HiRes qw/usleep/;

use constant REDISSERVER => 'localhost:63379';

sub startRedis {
    note "Starting Redis server";
    mkdir 't/redis/run';
    system( 'redis-server', 't/redis/redis.conf');
    waitForRedis();
}

sub stopRedis {
    my $p = pid();
    note "Stopping Redis server ($p)";
    kill 'KILL', $p;
    note 'Cleaning redis database';
    `rm -rf t/redis/run`;
}

sub pid {
    open F, 't/redis/run/pid' or die $!;
    my $pid = <F>;
    close F;
    chomp $pid;
    return $pid;
}

sub waitForRedis {
    my $waitloop = 0;
    note "Waiting for Redis server to be available";
    while ( $waitloop < 100 ) {
        my $r = Redis->new(server => REDISSERVER);
        last if ( $r and $r->set('test','test') );
        $waitloop++;
        usleep 100000;
    }
    die "Timed out waiting for LDAP server to start" if $waitloop == 100;
    note "Redis server available at localhost:63379";
}

1;
