#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'Devel::Events::Filter::Drop';

use Devel::Events::Handler::Callback;

{
	my @events;
	my $f = Devel::Events::Filter::Drop->new(
		match => "foo",
		handler => Devel::Events::Handler::Callback->new(sub { push @events, [@_] }),
	);

	$f->new_event( foo => bar => 42 );
	$f->new_event( bar => gorch => 43 );

	is_deeply( \@events, [ [ bar => gorch => 43 ] ], "filtered" );
}

{
	my @events;
	my $f = Devel::Events::Filter::Drop->new(
		match => "foo",
		non_matching => 1,
		handler => Devel::Events::Handler::Callback->new(sub { push @events, [@_] }),
	);

	$f->new_event( foo => bar => 42 );
	$f->new_event( bar => gorch => 43 );

	is_deeply( \@events, [ [ foo => bar => 42 ] ], "non matching" );
}
