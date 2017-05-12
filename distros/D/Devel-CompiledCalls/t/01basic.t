#!/usr/bin/env perl

use Test::More tests => 1;

use Devel::CompiledCalls;
my @calls;
BEGIN {
	Devel::CompiledCalls::attach_callback("Data::Dumper::Dumper", sub {
		push @calls, [@_];
	});
}

use Data::Dumper qw(Dumper);

sub never_called {
  print Dumper("foo");
  print Dumper("bar");
}
is_deeply(\@calls, [ 
	[ "Data::Dumper::Dumper", __FILE__, __LINE__ - 4, ],
	[ "Data::Dumper::Dumper", __FILE__, __LINE__ - 4, ],
	[ "Data::Dumper::Dumper", __FILE__, __LINE__ + 1, ],
], "calls correctly recorded") or diag Dumper \@calls;

