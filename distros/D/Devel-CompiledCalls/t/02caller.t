#!/usr/bin/env perl

use Test::More tests => 1;

use Devel::CompiledCalls;
my @calls;
BEGIN {
	Devel::CompiledCalls::attach_callback("bob", sub {
		push @calls, [@_];
	});
}

use Data::Dumper qw(Dumper);

sub never_called {
  print Devel::CompiledCalls::bob("wibble"); # should not be logged
  print bob("foo");                          # should be logged
  print bob("bar");                          # should be logged
}
is_deeply(\@calls, [ 
	[ "bob", __FILE__, __LINE__ - 4, ],
	[ "bob", __FILE__, __LINE__ - 4, ],
], "calls correctly recorded") or diag Dumper \@calls;

