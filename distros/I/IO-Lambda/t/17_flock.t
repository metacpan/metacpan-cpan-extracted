#! /usr/bin/perl
# $Id: 17_flock.t,v 1.8 2009/01/08 15:23:27 dk Exp $
use strict;
use Test::More;
use Fcntl qw(:flock);
use IO::Lambda qw(:all);
use IO::Lambda::Flock qw(flock);

alarm(10);

open G, ">test.lock";
my $m = CORE::flock( \*G, LOCK_EX);
unless ( $m) {
	unlink 'test.lock';
	plan skip_all => "flock(2) is not functional";
}

open F, ">test.lock";
my $l = CORE::flock(\*F, LOCK_EX|LOCK_NB);
if ( $l) {
	unlink 'test.lock';
	plan skip_all => "flock(2) is broken";
}

plan tests => 2;

my $got_it = 2;
lambda {
	context \*F, timeout => 0.2, frequency => 0.2;
	flock { $got_it = ( shift() ? 1 : 0) }
}-> wait;
ok( $got_it == 0, "timeout ok ($got_it)");

$got_it = 2;
SKIP: {

my $order = '';
lambda {
	context \*F, timeout => 2.0, frequency => 0.2;
	flock { $got_it = ( shift() ? 1 : 0); $order .= 'K' };
	context 0.5;
	timeout { close G; $order .= 'O' };
}-> wait;

($order eq 'OK') ? 
	ok( $got_it == 1, "lock ok ($got_it)") : 
	skip("got a race condition($order)", 1);
}

close F;
unlink 'test.lock';
