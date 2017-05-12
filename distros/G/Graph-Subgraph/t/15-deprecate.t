#!/usr/bin/perl -w

use strict;
use Test::More tests => 2;

use Graph;

my @warn;
BEGIN {
	$SIG{__WARN__} = sub { push @warn, @_; };

	package Graph;
	sub subgraph { };
};

use Graph::Subgraph;

is (scalar @warn, 1, "1 warning issued");
like ($warn[0], qr/deprecated/, "it was a deprecation warning");
note "Warning was: @warn";
