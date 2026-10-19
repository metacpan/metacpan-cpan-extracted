#!perl

use strict;
use warnings;

use Test::Most tests => 2;

BEGIN {
	use_ok('Geo::Location::Predicate') or BAIL_OUT('Geo::Location::Predicate failed to load');
}

require_ok('Geo::Location::Predicate');

diag("Testing Geo::Location::Predicate $Geo::Location::Predicate::VERSION, Perl $], $^X");
