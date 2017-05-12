#!/usr/bin/perl -w

use strict;
# use warnings; # commented out in case you don't have it!

use Test::More tests => 2;
use IChing::Hexagram::Illuminatus;

my $hex = IChing::Hexagram::Illuminatus->new;

is $hex->technological, 'http://www.slashdot.org/slashdot.rdf', 
  "technological site reference correct (default)";

$hex->throw;

$hex = IChing::Hexagram::Illuminatus->new(
	{ technological => 'somewhere.else.com' });

is $hex->technological, 'somewhere.else.com', 
  "technological site reference correct (user defined)";

