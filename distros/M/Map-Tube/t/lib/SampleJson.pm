#!/usr/bin/perl
package SampleJson;

use 5.006;
use File::Spec;
use Moo;
use namespace::clean;

has json => ( is => 'ro', default => sub { return File::Spec->catfile( 't', 'sample.json' ) } );
with 'Map::Tube';

1;
