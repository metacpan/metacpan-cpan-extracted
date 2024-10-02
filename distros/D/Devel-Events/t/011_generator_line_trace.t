#!/usr/bin/perl -d:Events
# vim: set ts=2 sw=2 noet nolist :
use strict;
use warnings;

use Test::More 0.88;

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

done_testing;
