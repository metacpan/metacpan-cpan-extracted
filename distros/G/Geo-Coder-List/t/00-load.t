#!perl -w

use warnings;
use strict;

use Test::Most tests => 2;

# Test::Most exports explain() which helps inspect $@ (the eval error)
BEGIN {
	use_ok('Geo::Coder::List') or bail_on_fail && diag explain $@;
}

require_ok('Geo::Coder::List') || do {
	diag("Failed to require Geo::Coder::List: $@");
	BAIL_OUT("Geo::Coder::List failed to load: $@");
};

diag("Testing Geo::Coder::List $Geo::Coder::List::VERSION, Perl $], $^X");
