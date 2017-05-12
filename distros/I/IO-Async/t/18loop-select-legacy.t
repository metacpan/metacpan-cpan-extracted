#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Time::HiRes qw( time );

use IO::Async::Loop::Select;

use IO::Async::OS;

use constant AUT => $ENV{TEST_QUICK_TIMERS} ? 0.1 : 1;

my $loop = IO::Async::Loop::Select->new;

my ( $S1, $S2 ) = IO::Async::OS->socketpair or die "Cannot create socket pair - $!";

# Need sockets in nonblocking mode
$S1->blocking( 0 );
$S2->blocking( 0 );

my $testvec = '';
vec( $testvec, $S1->fileno, 1 ) = 1;

my ( $rvec, $wvec, $evec ) = ('') x 3;
my $timeout;

# Empty

$loop->pre_select( \$rvec, \$wvec, \$evec, \$timeout );
is( $rvec, '', '$rvec idling pre_select' );
is( $wvec, '', '$wvec idling pre_select' );
is( $evec, '', '$evec idling pre_select' );
is( $timeout, undef, '$timeout idling pre_select' );

# watch_io

my $readready = 0;
$loop->watch_io(
   handle => $S1,
   on_read_ready => sub { $readready = 1 },
);

$loop->pre_select( \$rvec, \$wvec, \$evec, \$timeout );

is( $rvec, $testvec, '$rvec readready pre_select' );
is( $wvec, '',       '$wvec readready pre_select' );
is( $evec, '',       '$evec readready pre_select' );
is( $timeout, undef, '$timeout readready pre_select' );

is( $readready,  0, '$readready readready pre_select' );

$rvec = $testvec;
$wvec = '';
$evec = '';

$loop->post_select( $rvec, $wvec, $evec );

is( $readready,  1, '$readready readready post_select' );

$loop->unwatch_io(
   handle => $S1,
   on_read_ready => 1,
);

my $writeready = 0;
$loop->watch_io(
   handle => $S1,
   on_write_ready => sub { $writeready = 1 },
);

$loop->pre_select( \$rvec, \$wvec, \$evec, \$timeout );

is( $rvec, $testvec, '$rvec writeready pre_select' );
is( $wvec, $testvec, '$wvec writeready pre_select' );
is( $evec, IO::Async::OS->HAVE_SELECT_CONNECT_EVEC ? $testvec : '', '$evec writeready pre_select' );
is( $timeout, undef, '$timeout writeready pre_select' );

is( $writeready, 0, '$writeready writeready pre_select' );

$rvec = '';
$wvec = $testvec;
$evec = '';

$loop->post_select( $rvec, $wvec, $evec );

is( $writeready, 1, '$writeready writeready post_select' );

$loop->unwatch_io(
   handle => $S1,
   on_write_ready => 1,
);

# watch_time

$rvec = $wvec = $evec = '';
$timeout = 5 * AUT;

$loop->pre_select( \$rvec, \$wvec, \$evec, \$timeout );
is( $timeout, 5 * AUT, '$timeout idling pre_select with timeout' );

my $done = 0;
$loop->watch_time( after => 2 * AUT, code => sub { $done = 1; } );

$loop->pre_select( \$rvec, \$wvec, \$evec, \$timeout );
cmp_ok( $timeout/AUT, '>', 1.7, '$timeout while timer waiting pre_select at least 1.7' );
cmp_ok( $timeout/AUT, '<', 2.5, '$timeout while timer waiting pre_select at least 2.5' );

my ( $now, $took );

$now = time;
select( $rvec, $wvec, $evec, $timeout );
$took = (time - $now) / AUT;

cmp_ok( $took, '>', 1.7, 'loop_once(5) while waiting for timer takes at least 1.7 seconds' );
cmp_ok( $took, '<', 10, 'loop_once(5) while waiting for timer no more than 10 seconds' );
if( $took > 2.5 ) {
   diag( "took more than 2.5 seconds to select(2).\n" .
         "This is not itself a bug, and may just be an indication of a busy testing machine" );
}

$loop->post_select( $rvec, $evec, $wvec );

# select might have returned just a little early, such that the TimerQueue
# doesn't think anything is ready yet. We need to handle that case.
while( !$done ) {
   die "It should have been ready by now" if( time - $now > 5 * AUT );

   $timeout = 0.1 * AUT;

   $loop->pre_select( \$rvec, \$wvec, \$evec, \$timeout );
   select( $rvec, $wvec, $evec, $timeout );
   $loop->post_select( $rvec, $evec, $wvec );
}

is( $done, 1, '$done after post_select while waiting for timer' );

my $id = $loop->watch_time( after => 1 * AUT, code => sub { $done = 2; } );
$loop->unwatch_time( $id );

$done = 0;
$now = time;

$loop->pre_select( \$rvec, \$wvec, \$evec, \$timeout );
select( $rvec, $wvec, $evec, 1.5 * AUT );
$loop->post_select( $rvec, $evec, $wvec );

is( $done, 0, '$done still 0 before cancelled timeout' );

done_testing;
