#!/usr/bin/perl
# Read any GML file

use warnings;
use strict;

#use Log::Report mode => 3;  #debugging
use Geo::GML            ();

use Data::Dumper 'Dumper';
$Data::Dumper::Indent    = 1;
$Data::Dumper::Quotekeys = 0;
$Data::Dumper::Sortkeys  = 1;

@ARGV==1
   or die "ERROR: one filename required\n";

my ($filename) = @ARGV;

my ($type, $gml) = Geo::GML->from
  ( $filename
  , sloppy_floats   => 1
  , sloppy_integers => 1
  );

print "GML type   = $type\n";
print Dumper $gml;
