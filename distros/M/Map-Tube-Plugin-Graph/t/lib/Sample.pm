#!/usr/bin/perl
package Sample;

use 5.014;
use Path::Tiny;
use Moo;
use namespace::clean;

has xml  => ( is => 'ro', default => sub { return path( 't', 'sample.xml' ) } );
with 'Map::Tube';

1;
