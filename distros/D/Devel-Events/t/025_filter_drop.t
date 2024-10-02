# vim: set ts=2 sw=2 noet nolist :
use strict;
use warnings;

use Test::More 0.88;

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

done_testing;
