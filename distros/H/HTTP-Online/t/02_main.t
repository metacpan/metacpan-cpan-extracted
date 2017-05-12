#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 9;
use HTTP::Online ();





######################################################################
# Constructor Test

my $internet = HTTP::Online->new;
isa_ok( $internet, 'HTTP::Online' );
isa_ok( $internet->http, 'HTTP::Tiny' );
ok( $internet->url, '->url' );
ok( $internet->content, '->content' );





######################################################################
# Functional Test

# We can't actually be sure if we are online or not when this test starts.
# So as long as calling online never crashes, and returns EITHER
# 1 or '', then it is a success.
# diag("Checking for the internet...");

my $rv = eval {
	$internet->online;
};
is( $@, '', 'Call to ->online does not crash' );
ok( ($rv eq '1' or $rv eq ''), "online returns a valid result '$rv'" );
if ( $rv ) {
	diag("Online");
} else {
	diag("Offline");
}

my $off = eval {
	$internet->offline;
};
is( $@, '', 'Call to offline() does not crash' );
ok( ($rv eq '1' or $rv eq ''), "online returns a valid result '$rv'" );

is( $off, ! $rv, 'online() and offline() return opposite results' );
