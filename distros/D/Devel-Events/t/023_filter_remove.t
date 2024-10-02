# vim: set ts=2 sw=2 noet nolist :
use strict;
use warnings;

use Test::More 0.88;


my $m; use ok $m = "Devel::Events::Filter::RemoveFields";

use Devel::Events::Handler::Callback;

my $o = $m->new(
	fields => [qw/blah/],
	handler => Devel::Events::Handler::Callback->new(sub { }),
);

isa_ok($o, $m);

is_deeply(
	[ $o->filter_event( event_name => ( blah => 42, foro => 3, blah => "and", moose => "elk" ) ) ],
	[ event_name => ( foro => 3, moose => "elk" ) ],
	"remove fields",
);

done_testing;
