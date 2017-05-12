#!/usr/bin/perl -w

# some basic tests of podcnv

use Test::More;

BEGIN
  {
  plan tests => 1;
  chdir 't' if -d 't';

  use File::Spec;
  use lib '../lib';
  }

my $perl = $^X;
my $podcnv = File::Spec->catdir( File::Spec->updir(),'extensions', 'podcnv' );
my $cmd = "$perl -T $podcnv --help";

like (`$cmd`, qr/Usage:/, 'Usage shown (and it did compile)');

