#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'Devel::Events::Generator::ClassPublisher';

use Devel::Events::Handler::Callback;
use Class::Publisher;

{
	package Foo;
	use base qw/Class::Publisher/;

	sub new { bless { }, shift };
}

my $foo = Foo->new;

my @events;

my $gen = Devel::Events::Generator::ClassPublisher->new(
	handler => Devel::Events::Handler::Callback->new(sub { push @events, [@_] })
);

$gen->subscribe( $foo );

$foo->notify_subscribers( oink => foo => 42 );

is_deeply(
	\@events,
	[
		[ oink => ( generator => $gen, publisher => $foo, foo => 42 ) ],
	],
	"event relayed",
);

$gen->unsubscribe( $foo );

$foo->notify_subscribers( boink => bar => "blah" );

is( scalar(@events), 1, "unsubscribe" );

