use strict;
use warnings;
no warnings 'uninitialized';

use Time::HiRes qw( gettimeofday usleep tv_interval );

use Lock::Server;

use Data::Dumper;
use Test::More;

$SIG{ __DIE__ } = sub { Carp::confess( @_ ); exit; };

BEGIN {
    use_ok( "Lock::Server" ) or BAIL_OUT( "Unable to load Lock::Server" ) && exit;
}
$Lock::Server::DEBUG = 0;

my $locks = new Lock::Server( { 
    lock_timeout         => 5,  
    lock_attempt_timeout => 5.050,
                              } );
unless( $locks->start ) {
    my $err = $locks->{error};
    $locks->stop;
    BAIL_OUT( "Unable to start server '$err'" );
    exit;
} 
sleep 1;

test_suite();

my $locker1 = $locks->client( "LOCKER1" );
ok( $locker1->ping, 'ping before thing close' );
ok( $locks->ping, 'lockserv itself ping before thing have close' );

$locker1->shutdown;
ok( $locker1->ping, 'shutdown dissallowed client ping' );
ok( $locks->ping, 'shutdown dissallowed server ping' );

$locks->stop;

note ("Sleep about a half minute to let sockets clear" );
sleep 31;

ok( ! $locker1->ping, 'ping after things have closed' );
ok( ! $locks->ping, 'lockserv itself ping after things have closed' );

$locks = new Lock::Server( {
    lock_timeout         => 5,  
    lock_attempt_timeout => 5.050,
    allow_shutdown       => 1,
                              } );
$locker1 = $locks->client( "LOCKER1" );

note("Restarting");
$locks->start;
sleep 1;

ok( $locker1->ping, 'ping after restarting' );
ok( $locks->ping, 'lockserv itself ping after restarting' );

$locker1->shutdown;

ok( ! $locker1->ping, 'no ping after shutdown client' );
ok( ! $locks->ping, 'no ping after shutdown lockserv' );

done_testing;

exit( 0 );


sub test_suite {
    
    my $locker1 = $locks->client( "LOCKER1" );
    is( $locker1->ping, '1', 'ping for active connection' );
    is( $locker1->isLocked( "KEY1" ), '0', "KEY1 LOCKER1 not locked by anyone" );
    is( $locker1->lockedByMe( "KEY1" ), '0', "KEY1 LOCKER1 reported as not locked before any locking" );
    is( $locker1->unlock( "KEY1" ), '0', "can't unlock what is not locked KEY1 LOCKER1" );
    cmp_ok( $locker1->lock( "KEY1" ), '>', '1', "lock KEY1 LOCKER1" );
    is( $locker1->isLocked( "KEY1" ), '1', "KEY1 LOCKER1 reported as locked" );
    is( $locker1->lockedByMe( "KEY1" ), '1', "KEY1 LOCKER1 reported as locked after locking" );
    cmp_ok( $locker1->lock( "KEY2" ), '>', '1', "lock KEY2 LOCKER1" );
    is( $locker1->isLocked( "KEY2" ), '1', "KEY2 LOCKER1 reported as locked" );
    is( $locker1->lockedByMe( "KEY2" ), '1', "KEY2 LOCKER1 reported as locked after locking" );
    is( $locker1->lock( "KEY1" ), '0', "cannot relock KEY1 LOCKER1" );
    is( $locker1->lockedByMe( "KEY1" ), '1', "KEY1 LOCKER1 reported as locked after locking" );
    is( $locker1->unlock( "KEY1" ), '1', "first unlock KEY1 LOCKER1" );
    is( $locker1->lockedByMe( "KEY1" ), '0', "KEY1 LOCKER1 reported as not locked after unlocking" );
    is( $locker1->lockedByMe( "KEY2" ), '1', "KEY2 LOCKER1 reported as locked after locking" );
    is( $locker1->unlock( "KEY1" ), '0', "cant repeat unlock KEY1 LOCKER1" );
    is( $locker1->lockedByMe( "KEY1" ), '0', "KEY1 LOCKER1 reported as not locked after unlocking twice" );
    is( $locker1->unlock( "KEY2" ), '1', "second lock unlocked KEY2 LOCKER1" );
    is( $locker1->lockedByMe( "KEY1" ), '0', "KEY1 LOCKER1 reported as not locked by me after unlocking" );
    is( $locker1->lockedByMe( "KEY2" ), '0', "KEY2 LOCKER1 reported as not locked by me after unlocking" );
    is( $locker1->isLocked( "KEY2" ), '0', "KEY2 LOCKER1 reported as not locked" );

    my( @pids );

    # see if one process waits on the other

    # L3 locks KEY1
    #   while
    # L4 checks if KEY1 is locked (after a micro sleep)

    if( my $pid = fork ) {
        push @pids, $pid;
    } else {
        my $locker3 = $locks->client( "LOCKER3" );
        my $res = $locker3->lock( "KEY1" ) > 1;
        $res = $res && $locker3->isLocked( "KEY1" ) == 1;
        $res = $res && $locker3->lockedByMe( "KEY1" ) == 1;
        usleep 2_010_000;
        $res = $res && $locker3->unlock( "KEY1" ) == 1;
        exit ! $res;
    }
    if( my $pid = fork ) {
        push @pids, $pid;
    } else {
        my $locker4 = $locks->client( "LOCKER4" );
        usleep 4000; #wait for that to be locked
        my $res = $locker4->isLocked( "KEY1" ) == 1;
        # KEY1 is locked by locker3, so this doesn't return until it
        # is unlocked, a time of 2 seconds
        my $locktry = $locker4->lock( "KEY1" );
        
        $res = $res && $locktry > 1;
        $res = $res && $locker4->unlock( "KEY1" ) == 1;
        exit ! $res;
    }

    my $t1 = time;
    while( @pids ) { 
        my $pid = shift @pids;
        waitpid $pid, 0;
        # XXX
        fail("LOCKER4 $?") if $?;

    }
    cmp_ok( int(time-$t1),'>=',2, "second lock waited on the first" );

    # deadlock timeouts

    # L4 locks A 
    #  while
    # L5 locks B
    #  then
    # L4 sleeps 5
    #  while
    # L5 tries to lock A
    # 
    # L5 times out
    # L4 is able to Lock
    if( my $pid = fork ) {
        push @pids, $pid;
    } else {
        my $locker4 = $locks->client( "LOCKER4" );

        my $lockresp = $locker4->lock( "KEYA" );
        my $res = $lockresp > 1; #this will try to unlock for 5 seconds
        #then, this will remain locked for 5 seconds
        
        usleep 5_550_000;

        #at this point, KEYA had expired
        $res = $res && $locker4->isLocked( "KEYA" ) == 0;

        $res = $res && $locker4->isLocked( "KEYB" ) == 0;

        $res = $res && $locker4->lock( "KEYB" ) > 1;
        $res = $res && $locker4->unlock( "KEYB" ) == 1;
        exit ! $res;
    }
    if( my $pid = fork ) {
        push @pids, $pid;
    } else {
        my $locker5 = new Lock::Server::Client( "LOCKER5", '127.0.0.1', 8004 );
        my $res = $locker5->lock( "KEYB" ) > 1; #this will try to lock for 5 seconds. then it will remained locked for 4 seconds
        $res = $res && $locker5->lockedByMe( "KEYB" ) == 1;
        my $t = time;
        $res = $res && $locker5->lockedByMe( "KEYA" ) == 0;

        #keya will be locked then frozen
        $res = $res && $locker5->lock( "KEYA" ) == 0; #this will try for 5 seconds then give up, 
        $res = $res && $locker5->lockedByMe( "KEYB" ) == 0;
        $res = $res && ( time-$t ) >= 5;
        exit ! $res;
    }

    while( @pids ) { 
        my $pid = shift @pids;
        waitpid $pid, 0;

        # XXX
        fail("LOCKER4/LOCKER5") if $?;
    }
    
} #test suite

__END__
