#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'Devel::Events::Handler::Log::Memory';

my $log = Devel::Events::Handler::Log::Memory->new;

$log->new_event( foo => bar   => [ 1, 2, 3 ] );
$log->new_event( bar => moose => [ 3, 2, 1 ] );

is_deeply(
	[ $log->events ],
	[
		[ foo => bar   => [ 1, 2, 3 ] ],
		[ bar => moose => [ 3, 2, 1 ] ],
	],
	"events logged",
);

$log->clear;

is( scalar(@{ $log->events }), 0, "cleared" );

my $i;
for ( 1 .. 3 ) {
	$log->new_event( foo => bar   => [ 1, 2, 3 ], id => ++$i );
	$log->new_event( bar => moose => [ 3, 2, 1 ], id => ++$i );
}

is_deeply(
	[ $log->grep("foo") ],
	[
		[ foo => bar   => [ 1, 2, 3 ], id => 1 ],
		[ foo => bar   => [ 1, 2, 3 ], id => 3 ],
		[ foo => bar   => [ 1, 2, 3 ], id => 5 ],
	],
	"grep",
);

is_deeply(
	[ $log->limit(
		from => { id => 3 },
		to   => { id => 5 },
	) ],
	[
		[ foo => bar   => [ 1, 2, 3 ], id => 3 ],
		[ bar => moose => [ 3, 2, 1 ], id => 4 ],
		[ foo => bar   => [ 1, 2, 3 ], id => 5 ],
	],
	"limit",
);

