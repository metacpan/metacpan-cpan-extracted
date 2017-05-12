#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'Devel::Events::Generator::Objects';

use Devel::Events::Handler::Callback;

my $file = quotemeta(__FILE__);

eval { bless "foo", "bar" };
like( $@, qr/^Can't bless non-reference value at $file line \d+/, "bless doesn't poop errors");

my @events;

my $h = Devel::Events::Handler::Callback->new(sub {
	push @events, [ map { ref($_) ? "$_" : $_ } @_ ]; # don't leak
});

my $gen = Devel::Events::Generator::Objects->new(
	handler => $h,
);

isa_ok( $gen, "Devel::Events::Generator::Objects" );

is( $gen->handler, $h, "right handler" );

is( @events, 0, "no events" );

bless( {}, "Some::Class" );

{ package Some::Class; ::isa_ok( bless({}), "Some::Class") }

is( @events, 0, "no events" );

$gen->enable();

eval { bless "foo", "bar" };
like( $@, qr/^Can't bless non-reference value at $file line \d+/, "bless doesn't poop errors after registring handler either" );

is( @events, 0, "no events" );

my $line;

my $obj = bless( {}, "Some::Class" ); $line = __LINE__;
my $obj_str = "$obj";

is( @events, 1, "one event" );

is_deeply(
	\@events,
	[
		[ object_bless => (
			generator => "$gen",
			object    => $obj_str,
			tracked   => 1,
			class     => "Some::Class",
			old_class => undef,
			package   => "main",
			file      => __FILE__,
			line      => $line,
		) ],
	],
	"event log",
);

@events = ();

{ package Some::Other::Class; bless($obj); $line = __LINE__ }
$obj_str = "$obj";

is( @events, 1, "one event" );

is_deeply(
	\@events,
	[
		[ object_bless => (
			generator => "$gen",
			object    => $obj_str,
			tracked   => 1,
			class     => "Some::Other::Class",
			old_class => "Some::Class",
			package   => "Some::Other::Class",
			file      => __FILE__,
			line      => $line,
		) ],
	],
	"event log",
);

my ( $hash_str ) = ( $obj_str =~ /^Some::Other::Class=(HASH\(0x[\w]+\))$/ ); # objects are first unblessed, then they get freed

@events = ();

$obj = undef;

no warnings 'uninitialized'; # wtf?!

is_deeply(
	\@events,
	[
		[ object_destroy => ( generator => "$gen", object => $hash_str ) ],
	],
	"event log",
);


