#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

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

