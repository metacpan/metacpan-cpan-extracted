#!/usr/bin/perl -w

use strict;

use Test::More tests => 10;

use IO::Epoll;

use POSIX qw(
   sigprocmask SIG_BLOCK
   SIGHUP SIGTERM SIGUSR1 SIGUSR2
   EINTR
);

my $epoll = IO::Epoll->new();

ok( !$epoll->sigmask_ismember( SIGHUP ), 'SIGHUP not in initial set' );

$epoll->sigmask_add( SIGHUP );

ok( $epoll->sigmask_ismember( SIGHUP ), 'SIGHUP now in set' );

$epoll->sigmask_del( SIGHUP );

ok( !$epoll->sigmask_ismember( SIGHUP ), 'SIGHUP no longer in set' );

my $SIGHUP_count = 0;
$SIG{HUP} = sub { $SIGHUP_count++ };

kill SIGHUP, $$;

is( $SIGHUP_count, 1, 'Caught SIGHUP before sigprocmask' );

sigprocmask( SIG_BLOCK, POSIX::SigSet->new( SIGHUP ) );

kill SIGHUP, $$;

is( $SIGHUP_count, 1, 'Not caught SIGHUP after sigprocmask' );

my $ret = $epoll->poll( 0.1 );
my $dollarbang = $!+0;

is( $ret, -1, 'poll() returns undef' );
is( $dollarbang, EINTR, 'poll() failed with EINTR' );

is( $SIGHUP_count, 2, 'Caught SIGHUP after poll' );

sigprocmask( SIG_BLOCK, POSIX::SigSet->new( SIGTERM ) );
$epoll->sigmask_add( SIGTERM );

my $SIGTERM_count = 0;
$SIG{TERM} = sub { $SIGTERM_count++ };

kill SIGTERM, $$;

$ret = $epoll->poll( 0.1 );

is( $ret, 0, 'poll() returns 0' );
is( $SIGTERM_count, 0, 'Not caught SIGTERM after poll()' );
