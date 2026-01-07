#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use IO::Ppoll;

use POSIX qw( sigprocmask EINTR SIG_BLOCK SIGHUP SIGTERM SIGUSR1 SIGUSR2 );

my $ppoll = IO::Ppoll->new();

my $SIGHUP_count = 0;
$SIG{HUP} = sub { $SIGHUP_count++ };

kill SIGHUP, $$;

is( $SIGHUP_count, 1, 'Caught SIGHUP before sigprocmask' );

sigprocmask( SIG_BLOCK, POSIX::SigSet->new( SIGHUP ) );

kill SIGHUP, $$;

is( $SIGHUP_count, 1, 'Not caught SIGHUP after sigprocmask' );

my $ret = $ppoll->poll( 0.1 );
my $dollarbang = $!+0;

is( $ret, -1, 'poll() returns undef' );
is( $dollarbang, EINTR, 'poll() failed with EINTR' );

is( $SIGHUP_count, 2, 'Caught SIGHUP after poll' );

sigprocmask( SIG_BLOCK, POSIX::SigSet->new( SIGTERM ) );
$ppoll->sigmask_add( SIGTERM );

my $SIGTERM_count = 0;
$SIG{TERM} = sub { $SIGTERM_count++ };

kill SIGTERM, $$;

$ret = $ppoll->poll( 0.1 );

is( $ret, 0, 'poll() returns 0' );
is( $SIGTERM_count, 0, 'Not caught SIGTERM after poll()' );

done_testing;
