#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 6;

use lib grep { -d $_ } qw(./lib ../lib);
use Functional::Utility qw(hook_run);

my $duration;
sub timing_of (&) {
	my $code = shift;
	my $start;
	return hook_run(
		before => sub { $start = time() },
		run    => $code,
		after  => sub { $duration = time() - $start },
	);
}

my $inner_context;
sub timeit {
	return timing_of { sleep 1; return $inner_context = wantarray ? 'list' : defined wantarray ? 'scalar' : 'void'; };
}

my $got = timeit;
is( $got, 'scalar' );
is( $inner_context, $got );
is( $duration, 1, 'we ran our before and after hooks' );

($got) = timeit;
is( $got, 'list' );
is( $inner_context, $got );

timeit();
is( $inner_context, 'void' );
