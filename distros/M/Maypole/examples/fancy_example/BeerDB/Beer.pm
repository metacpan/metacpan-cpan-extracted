package BeerDB::Beer;
use strict;
use warnings;

# do this to test we get the expected @ISA after setup_model()
use base 'BeerDB::Base';

sub fooey : Exported {}

1;
