#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';


my $m; use ok $m = "Devel::Events::Handler::Callback";

can_ok($m, "new");

{
	my @log;

	isa_ok(my $o = $m->new(sub { push @log, [ @_  ] }), $m);

	$o->new_event( foo => ( bar => 42 ) );

	is_deeply(
		\@log,
		[ [ foo => ( bar => 42 ) ] ],
		"callback",
	);
}

{
	my @log;

	isa_ok(my $o = $m->new(callback => sub { push @log, [ @_  ] }), $m);

	$o->new_event( foo => ( bar => [qw/elk/], bar => "moose" ) );

	is_deeply(
		\@log,
		[ [ foo => ( bar => [qw/elk/], bar => "moose" ) ] ],
		"callback",
	);
}
