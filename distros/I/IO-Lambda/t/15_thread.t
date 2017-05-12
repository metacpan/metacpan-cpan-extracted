#! /usr/bin/perl
# $Id: 15_thread.t,v 1.14 2010/01/17 09:44:11 dk Exp $

use strict;
use warnings;
use Test::More;
use Config;

alarm(10);

use IO::Lambda qw(:lambda);
use IO::Lambda::Thread qw(threaded);

plan skip_all => $IO::Lambda::Thread::DISABLED if $IO::Lambda::Thread::DISABLED;
plan skip_all => "Threads don't work with AnyEvent" if IO::Lambda::Loop-> new =~ /AnyEvent/;

plan tests    => 6;

sub sec { select(undef,undef,undef,0.1 * ( $_[0] || 1 )) }

this threaded { 42 };
ok( this-> wait == 42, 'scalar' );

this threaded { (1,2,3) };
ok(( join('', this-> wait) eq '123'), 'list' );

this threaded { sec; 42 };
ok( this-> wait == 42, 'delay' );

this lambda {
	context
		threaded { 1 },
		threaded { 2 },
		threaded { 3 };
	tails { join('', sort @_) }
};
my $ret = this-> wait;
ok( $ret eq '123', "join all ($ret)" );

my $t;
this lambda {
	context
		0.1,
		threaded { 2 },
		$t = threaded { sec(16); 1 };
	any_tail {
		@_ ? join('', sort map { $_-> peek } @_) : again
	}
};
$ret = this-> wait;
ok( $ret =~ /1?2/, "join some ($ret)" );
$t-> wait;

my $l = threaded { 42 };
$l-> start;
$l-> terminate;
my $p = $l-> wait || 'undef';
ok(( $l-> thread-> join == 42 and $p eq 'undef'), 'abort');
