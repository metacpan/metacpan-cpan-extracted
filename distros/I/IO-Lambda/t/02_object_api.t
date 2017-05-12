#! /usr/bin/perl
# $Id: 02_object_api.t,v 1.11 2009/06/02 11:36:01 dk Exp $

use strict;
use warnings;
use Time::HiRes qw(time);
use Test::More tests => 27;
use IO::Lambda qw(:all);

alarm(10);

# empty lambda
my $l = IO::Lambda-> new;
ok( $l, 'create IO::Lambda');
ok( not($l-> is_stopped), 'initial lambda is not stopped');
ok( $l-> is_passive, 'initial lambda is passive');
ok( not($l-> is_active), 'initial lambda is not active');
ok( not($l-> is_waiting), 'initial lambda is not waiting');

$l-> wait;
ok( $l-> is_stopped, 'finished lambda is stopped');
ok( not($l-> is_passive), 'finished lambda is not passive');
ok( $l-> is_active, 'finished lambda is active');
ok( not($l-> is_waiting), 'finished lambda is not waiting');

$l-> reset;
ok( not($l-> is_stopped), 'reset lambda is not stopped');
ok( $l-> is_passive, 'reset lambda is passive');
ok( not($l-> is_active), 'reset lambda is not active');
ok( not($l-> is_waiting), 'reset lambda is not waiting');

$l-> terminate('moo', 42);
ok( $l-> is_stopped, 'terminated lambda is stopped');
ok( not($l-> is_passive), 'terminated lambda is not passive');
ok( $l-> is_active, 'terminated lambda is active');
ok( not($l-> is_waiting), 'terminated lambda is not waiting');

ok( 2 == @{[$l-> peek]},    'passed data ok');
ok('moo' eq $l-> peek,      'retrieved data ok');

# lambda with initial callback
$l = IO::Lambda-> new( sub { 1, 42 } );
$l-> wait;
my @x = $l-> peek;
ok(( 2 == @x and $x[1] == 42), 'single callback');

# two lambdas, one waiting for another
$l-> reset;
my $m = IO::Lambda-> new( sub { 10 } );
$l-> watch_lambda( $m, sub { @x = @_ });
$l-> wait;
ok(( 2 == @x and $x[1] == 10), 'watch_lambda');

# timer
$m-> reset;
$m-> watch_timer( time, sub { @x = 'time' });
$m-> wait;
ok(( 1 == @x and $x[0] eq 'time'), 'watch_timer');

$m-> reset;
$l-> reset;
$m-> watch_timer( time, sub { 'time' });
$l-> watch_lambda( $m, sub { @x = @_ });
$l-> wait;
ok(( 2 == @x and $x[1] eq 'time'), 'propagate timer');

@x = ();
$l-> reset;
$l-> watch_timer( time + 2, sub { push @x, 't' }, sub { push @x, 'c' }); 
$l-> terminate;
$l-> wait;
ok(( 1 == @x and $x[0] eq 'c'), 'catch');

# file
SKIP: {
	skip "select(file) doesn't work on win32", 3 if $^O =~ /win32/i;
	skip "select(file) doesn't work with AnyEvent", 3 if $IO::Lambda::LOOP =~ /AnyEvent/;
	skip "cannot open $0:$!", 3 unless open FH, '<', $0;

	$m-> reset;
	$m-> watch_io( IO_READ, \*FH, 0.1, sub { @x = @_ });
	$m-> wait;
	ok(( 2 == @x and $x[1] == IO_READ), 'io read');
	
	$m-> reset;
	$m-> watch_io( IO_READ|IO_EXCEPTION, \*FH, 0.1, sub { @x = @_ });
	$m-> wait;
	# solaris and darwin report IO_EXCEPTION on a file :)
	ok(( 2 == @x and $x[1] & IO_READ), 'io read/exception');
	
	$l-> reset;
	$m-> reset;
	$m-> watch_io( IO_READ, \*FH, 0.1, sub { 42 });
	$l-> watch_lambda( $m, sub { @x = @_ });
	$l-> wait;
	ok(( 2 == @x and $x[1] == 42), 'io propagate');

	close FH;
}
