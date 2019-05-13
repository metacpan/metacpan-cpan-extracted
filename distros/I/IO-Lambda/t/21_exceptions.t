#! /usr/bin/perl
# $Id: 21_exceptions.t,v 1.6 2009/12/01 23:01:52 dk Exp $

alarm(10);

use strict;
use warnings;
use Test::More;
use IO::Lambda qw(:lambda);

plan tests => 25;

# just throw
sub throw
{
	lambda { this-> throw('throw') }
}

# exceptions pass through
sub bypass
{
	my $listen = shift;
	lambda {
		context $listen;
		tail { 'pass' };
	}
}

# just a fork
sub forks
{
	my @t = @_;
	lambda {
		context @t;
		tails { @_ }
	}
}

# catch expection, do not propagate further
sub caught
{
	my $listen = shift;
	lambda {
		context $listen;
		catch { 'caught', @_ }
		tail  { 'passed', @_ }
	}
}

# bypass expection but alter the result
sub fin
{
	my $listen = shift;
	lambda {
		context $listen;
		catch    { this-> throw('finally') }
		tail     { 'finally' }
	}
}

# normal exceptions
ok( throw-> wait eq 'throw', 'throw');
ok( bypass(lambda{})-> wait eq 'pass', 'pass');
ok( bypass(throw)-> wait eq 'throw', 'bypass/1');
ok( fin(throw)-> wait eq 'finally', 'finally');
ok( forks(throw)-> wait eq 'throw', 'bypass/*');
ok( caught(throw)-> wait eq 'caught', 'catch');
ok( caught(fin(throw))-> wait eq 'caught', 'finally bypasses ok');
ok( fin(caught(throw))-> wait eq 'finally', 'finally/catch');
ok( caught(bypass(throw))-> wait eq 'caught', 'catch/bypass');
ok( fin(caught(bypass(throw)))-> wait eq 'finally', 'finally/catch/bypass');
ok( caught(caught(throw))-> wait eq 'passed', 'catch/catch');

# SIGTHROW
my $sig = 0;
IO::Lambda-> sigthrow( sub { $sig++ });
throw-> wait;
ok( $sig, 'sigthrow on');

$sig = 0;
IO::Lambda-> sigthrow(undef);
throw-> wait;
ok( 0 == $sig, 'sigthrow off');

IO::Lambda::sigthrow( sub { $sig++ });
throw-> wait;
ok( $sig, 'sigthrow on');

$sig = 0;
IO::Lambda::sigthrow(undef);
throw-> wait;
ok( 0 == $sig, 'sigthrow off');

# stack
sub stack
{
	lambda {
		context 0.001;
	# make sure that lambdas wait for each other before throw is called
	timeout {
		this-> throw( this-> backtrace )
	}}
}

my $s = stack-> wait;
ok((1 == @$s and 1 == @{$s->[0]}), 'stack 1/1');

$s = bypass( stack )-> wait;
ok((1 == @$s and 2 == @{$s->[0]}), 'stack 1/2');

$s = bypass( bypass( stack ))-> wait;
ok((1 == @$s and 3 == @{$s->[0]}), 'stack 1/3');

my $x = stack;
$s = forks($x, $x)-> wait;
ok((2 == @$s and 2 == @{$s->[0]} and 2 == @{$s->[1]}), 'stack 2/2/2');

$x = stack;
$s = forks(bypass($x), bypass($x))-> wait;
ok((2 == @$s and 3 == @{$s->[0]} and 3 == @{$s->[1]}), 'stack 2/3/3');

$x = stack;
$x = bypass($x);
$s = forks(bypass($x), bypass($x))-> wait;
ok((2 == @$s and 4 == @{$s->[0]} and 4 == @{$s->[1]}), 'stack 2/4/4');

# check that catch() is restartable
my $ret = 0;
$x = lambda {
    context lambda {
	context 0.01;
	catch   { $ret |= 1 }
	timeout { $ret |= 2; again };
    };
    catch { $ret |= 4 }
    tail  { $ret |= 8 };
};

$x-> start;
lambda { context 0.1; &timeout }-> wait;
undef $x;
IO::Lambda::clear;
ok( $ret == 7, 'catch is restartable');


# check catch propagations
$ret = 0;
$x = lambda {
	context lambda {};
	catch {
		$ret |= 1;
		this-> call_again;
	} tail {
		$ret |= 2 if this-> is_cancelling;
	}
};
$x-> start;
undef $x;
ok($ret == 3, 'catch restarts event');

$ret = 0;
$x = lambda {
	context lambda {};
	autocatch tail { $ret |= 2 if this-> is_cancelling };
};
$x-> start;
undef $x;
ok($ret == 2, 'autocatch can restart');

# autocatch indeed rethrows
$ret = 0;
$x = lambda {
	context lambda {};
	autocatch tail { $ret |= 2 if this-> is_cancelling };
};
$x-> start;

lambda {
	context $x;
	catch { $ret |= 4; } tail {};
	$x-> throw(42);
}-> wait;
ok( $ret == 6, 'autocatch can rethrow');
