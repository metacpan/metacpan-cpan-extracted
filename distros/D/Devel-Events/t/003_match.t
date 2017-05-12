#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'Devel::Events::Match';

my $m = Devel::Events::Match->new;

ok( $m->match("blah", "blah" ), "simple match");
ok( !$m->match("blah", "foo" ), "simple match" );
ok( $m->match(sub { 1 }, "foo"), "code" );
ok( !$m->match(sub { 0 }, "foo"), "code" );
ok( $m->match({ foo => { bar => "gorch" }, baz => sub { 1 }, type => "elk" }, elk => foo => { bar => "gorch" } ), "hash" );
ok( $m->match({ foo => { bar => "gorch" }, baz => sub { 1 }, type => "elk" }, elk => baz => "moose", foo => { bar => "gorch" } ), "hash" );
ok( $m->match({ foo => { bar => "gorch" }, baz => sub { 1 }, type => "elk" }, elk => foo => [ bar => "gorch" ] ), "hash (coerce)" );
ok( !$m->match({ foo => { bar => "gorch" }, baz => sub { 1 }, type => "elk" }, moose => foo => [ bar => "gorch" ] ), "hash (no match)" );
ok( !$m->match({ foo => { bar => "gorch" }, baz => sub { 1 }, type => "elk" }, elk => foo => [ bar => "blah" ] ), "hash (no match)" );
ok( !$m->match({ foo => { bar => "gorch" }, baz => sub { 1 }, type => "elk" }, elk => baz => "blah" ), "hash (no match)" );
ok( !$m->match({ foo => { bar => "gorch" }, baz => sub { 1 }, type => "elk" }, elk => "baz" ), "hash (odd sized event)" );

my @args;
ok( $m->match(sub { @args = @_; 1 }, foo => bar => [ 1 ] ), "code" );
is_deeply( \@args, [ foo => bar => [ 1 ] ], "code args" );

my $i = 0;

my @events = map { [ $_ => ++$i ] } qw/bar foo gorch foo bar blah blah zoink bar gorch boink/;

is_deeply( [ $m->first(match => "foo", events => \@events) ], [ foo => 2 ], "first" );
is_deeply( [ $m->grep (match => "foo", events => \@events) ], [ [ foo => 2 ], [ foo => 4 ] ], "grep");
is_deeply( [ $m->limit(from => "foo", to => "blah", events => \@events) ], [ @events[1..5] ], "limit");
is_deeply(
	[ $m->chunk(marker => "foo", events => \@events) ],
	[ [ $events[0] ], [ @events[1 .. 2] ], [ @events[3 .. 10 ] ] ],
	"chunk",
);
is_deeply(
	[ $m->chunk(marker => "foo", first => 0, events => \@events) ],
	[ [ @events[1 .. 2] ], [ @events[3 .. 10 ] ] ],
	"chunk",
);
is_deeply(
	[ $m->chunk(marker => "foo", last => 0, events => \@events) ],
	[ [ $events[0] ], [ @events[1 .. 2] ] ],
	"chunk",
);
is_deeply(
	[ $m->chunk(marker => "foo", first => 0, last => 0, events => \@events) ],
	[ [ @events[1 .. 2] ] ],
	"chunk",
);
