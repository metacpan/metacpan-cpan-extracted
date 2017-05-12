#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use IPC::RunSession::Simple;

my $session = IPC::RunSession::Simple->open( [ $^X, 't/assets/basic' ] );
my $result;

$result = $session->read_until( qr/Ready\?/, 1 );
ok( ! $result->expired );
ok( ! $result->closed );
is( $result->content, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Curabitur aliquam condimentum nisi sit amet porttitor. Ut eleifend turpis in est viverra dictum. Mauris bibendum, augue eget bibendum blandit, risus metus eleifend nisl, non malesuada massa sapien et orci. Curabitur ut leo quam, a tempor eros. Fusce et porttitor quam. Donec accumsan lorem id turpis commodo eget dignissim urna pretium. Nunc mattis consectetur ligula nec tincidunt. Nunc facilisis iaculis justo non consectetur. Nulla eget laoreet massa.

Ready? ' );
$session->write( "1\n" );

$result = $session->read_until( qr/Ready\?/, 1 );
ok( ! $result->expired );
ok( ! $result->closed );
is( $result->content, 'Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas.

Ready? ' );
$session->write( "2\n" );

$result = $session->read( 1 );
ok( ! $result->expired );
ok( ! $result->closed );
is( $result->content, "*** Nulla eget laoreet massa. ***\n" );

$result = $session->read( 1 );
ok( ! $result->expired );
ok( $result->closed );
is( $result->content, '' );

1;
