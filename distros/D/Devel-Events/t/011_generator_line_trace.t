#!/usr/bin/perl -d:Events

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'Devel::Events::Generator::LineTrace';
use Devel::Events::Handler::Callback;

my @events;

my $h = Devel::Events::Handler::Callback->new(sub {
	push @events, [ @_ ],
});

my $o = Devel::Events::Generator::LineTrace->new( handler => $h );

$o->enable;

my $line = __LINE__;

$o->disable;

is_deeply(
	\@events,
	[
		[ executing_line => ( generator => $o, package => "main", file => __FILE__, line => $line ) ],
		[ executing_line => ( generator => $o, package => "main", file => __FILE__, line => $line + 2 ) ],
	],
	"line events",
);


