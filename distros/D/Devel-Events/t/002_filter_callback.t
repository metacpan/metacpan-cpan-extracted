# vim: set ts=2 sw=2 noet nolist :
use strict;
use warnings;

use Test::More 0.88;

use ok 'Devel::Events::Filter::Callback';

use Devel::Events::Handler::Callback;

my @events;
my $h = Devel::Events::Handler::Callback->new(sub { push @events, [@_] });
{

	my $f = Devel::Events::Filter::Callback->new(
		callback => sub { @_, "foo" },
		handler  => $h,
	);

	$f->new_event("bar");
	$f->new_event("gorch");

	is_deeply( \@events, [[qw/bar foo/], [qw/gorch foo/]], "filter");
}

@events = ();

{
	my $i;

	my $f = Devel::Events::Filter::Callback->new(
		callback => sub { return if $i++ % 2 == 0; return @_ },
		handler => $h,
	);

	$f->new_event($_) for qw/foo bar gorch baz/;

	is_deeply(\@events, [["bar"],["baz"]], "filter drop");
}

done_testing;
