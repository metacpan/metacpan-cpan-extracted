#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use Scalar::Util qw/weaken/;

my $m; use ok $m = "Devel::Events::Handler::ObjectTracker";

use Devel::Events::Generator::Objects;
use Devel::Events::Filter::RemoveFields;

my $tracker = Devel::Events::Handler::ObjectTracker->new();

{
	my $gen = Devel::Events::Generator::Objects->new(
		handler => Devel::Events::Filter::RemoveFields->new(
			fields => [qw/generator/],
			handler => $tracker,
		),
	);

	$gen->enable(); # start generating events

	{
		my $object = bless({}, "Class::A");

		$object->{self} = $object;
	}

	{
		my $object = bless({}, "Class::B");
		$object->{foo}{bar}{gorch} = $object;

		weaken($object->{foo}{bar}{gorch});
	}

	{
		my $circ;
		my $object = bless(sub { $circ }, "Class::C");
		$circ = $object;
	}

	{
		my $object = bless(sub { }, "Class::D"); # it leaks but we can't help it
	}

	{
		my $circ;
		my $object = bless(sub { $circ }, "Class::E");
		$circ = $object;
		weaken($circ);
	}

	$gen->disable();

}

# sort by class
my @leaked = sort { ref($a) cmp ref($b) } keys %{ $tracker->live_objects };

is( scalar(@leaked), 2, "two leaked objects" );

is( ref($leaked[0]), "Class::A", "class of first object" );
is( ref($leaked[1]), "Class::C", "class of second object" );

