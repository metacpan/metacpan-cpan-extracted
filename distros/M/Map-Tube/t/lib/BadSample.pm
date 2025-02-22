#!/usr/bin/perl
package BadSample;

use 5.006;
use File::Spec;
use Moo;
use namespace::clean;

has xml => ( is => 'ro', default => sub { return File::Spec->catfile( 't', 'sample.xml' ) } );

1;
