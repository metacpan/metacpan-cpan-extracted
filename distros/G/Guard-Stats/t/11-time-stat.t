#!/usr/bin/perl -w

use strict;
use Test::More tests => 3;
use Test::Exception;

use Guard::Stats;

throws_ok {
	Guard::Stats->new( time_stat => "My::Fake" );
} qr(Guard::.*doesn't.*method), "Die if wrong time class";

my $st1 = Guard::Stats->new( time_stat => "My::FakeTime" );
do { $st1->guard for 1..10; };
is( $st1->get_stat_time->{count}, 10, "add_data called 10 times");

my $st2 = Guard::Stats->new( time_stat => My::FakeTime->new );
do { $st2->guard for 1..15; };
is( $st2->get_stat_time->{count}, 15, "add_data called 15 times");


package My::Fake;
sub new { return bless {}, shift; };

package My::FakeTime;
BEGIN{ our @ISA = qw(My::Fake); };
sub add_data {
	my $self = shift;
	my $time = shift;

	$self->{count}++;
	die ("Bad time $time") unless $time > 0;
	use Test::More;
	note $time;
};
