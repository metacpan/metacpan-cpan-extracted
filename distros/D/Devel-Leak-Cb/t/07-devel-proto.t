#!/usr/bin/env perl

use common::sense;
use lib::abs '../lib';
use Test::More tests => 2;
BEGIN { $ENV{DEBUG_CB} = 1 }
use Devel::Leak::Cb;
use Carp;

sub call (@) {
	my %args = @_;
	for ( values %args ) {
		$_->();
	}
}

my $i = 0;

call (
	1 => cb {
		is ++$i, 1, "First call";
	},
	2 => cb {
		is ++$i, 2, "Second call";
	},
);
