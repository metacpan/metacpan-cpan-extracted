#!/usr/bin/perl
# $Id: throttle.pl,v 1.1 2010/03/05 12:43:21 dk Exp $

# This example demonstrates uses of rate-limiter

use strict;
use IO::Lambda qw(:lambda);
use IO::Lambda::Throttle qw(throttle);

$|++;
sub ping($)
{
	my $k = shift;
	return lambda { print "$k.." }
}

print "throttle with speed 2 lambda/sec: ";
throttle(2)-> wait( map { ping $_ } 1..6 );
print "\nthrottle with no speed limit:";
throttle(0)-> wait( map { ping $_ } 1..6 );
print "\nthrottle with 1 lambda in 2 sec:";
throttle(0.5)-> wait( map { ping $_ } 1..3 );
print "\nrelaxed rate limiting, speed 1.5 l/s - does 2 lambdas in 1.3 sec:";
throttle(1.5,0)-> wait( map { ping $_ } 1..6 );
print "\nstrict rate limiting, speed 1.5 l/s - does 1 lambda in 0.7 sec:";
throttle(1.5,1)-> wait( map { ping $_ } 1..6 );

my $t;
sub track1
{
	my ( $from, $to) = @_;
	return lambda {
		context $t-> ratelimit, map { ping $_ } $from .. $to;
		tail {};
	};
}

print "\ntwo parallel tracks and a common rate limiter:";
$t = IO::Lambda::Throttle-> new(1);
lambda {
	context 
		track1(1,3),
		track1(4,6);
	tails {};
}-> wait;

print "\nsame but with explicit rate-stopper:";

sub track2
{
	my ( $from, $to) = @_;
	my @l = map { ping $_ } $from .. $to;
	return lambda {
		context $t-> lock;
		tail {
			context shift @l;
			tail {
				this-> start if @l;
			}
		}
	};
}

lambda {
	context 
		track2(1,3),
		track2(4,6);
	tails {};
}-> wait;

print "\n";
