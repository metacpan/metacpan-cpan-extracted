package BeerDB::Brewery;
use strict;
use warnings;

use Data::Dumper;

sub display_columns { qw/name url beers/ } # note has_man beers
sub list_columns { qw/name url/ } 

1;
