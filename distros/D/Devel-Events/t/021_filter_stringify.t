# vim: set ts=2 sw=2 noet nolist :
use strict;
use warnings;

use Test::More 0.88;

use Devel::Events::Handler::Callback;

my $m; use ok $m = "Devel::Events::Filter::Stringify";

my @events;
my $h = Devel::Events::Handler::Callback->new(sub { push @events, [ @_ ] });

my $f = $m->new( handler => $h );

my @event = ( foo => ( blah => [ bless({}, "zork") ], oink => bless({}, "oink"), gorch => { }, string => "moose" ) );

$f->new_event( @event );

is_deeply(
	\@events,
	[ [ map { "$_" } @event ] ],
	"event stringified",
);

done_testing;
