#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'Devel::Events::Handler::Multiplex';

use Devel::Events::Handler::Callback;

my ( @a, @b );

my $h = Devel::Events::Handler::Multiplex->new(
	handlers => [
		Devel::Events::Handler::Callback->new(sub{ push @a, [ @_ ] }),
		Devel::Events::Handler::Callback->new(sub{ push @b, [ @_ ] }),
	],
);

$h->new_event( blah => ( foo => [ 1 .. 3 ] ) );

is_deeply( \@a, [ [ blah => ( foo => [ 1 .. 3 ] ) ] ], "first handler" );
is_deeply( \@b, [ [ blah => ( foo => [ 1 .. 3 ] ) ] ], "second handler" );
