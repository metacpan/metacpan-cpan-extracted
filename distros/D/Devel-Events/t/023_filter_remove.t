#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';


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


