#!/usr/bin/env perl

use Test::More tests => 1;

use Devel::CompiledCalls;
my @calls;

sub bob {};

BEGIN {
	Devel::CompiledCalls::attach_callback(\&bob, sub {
		push @calls, [@_];
	});
}

use Data::Dumper qw(Dumper);

sub never_called {
  print bob("foo");
  print bob("bar");
}
is_deeply(\@calls, [ 
	[ "main::bob", __FILE__, __LINE__ - 4, ],
	[ "main::bob", __FILE__, __LINE__ - 4, ],
], "calls correctly recorded") or diag Dumper \@calls;

