#!/usr/bin/perl
package Sample;

use 5.014;
use File::Spec;
use Moo;
use namespace::clean;

has xml  => ( is => 'ro', default => sub { return File::Spec->catfile( 't', 'sample.xml' ) } );
with 'Map::Tube';

1;
