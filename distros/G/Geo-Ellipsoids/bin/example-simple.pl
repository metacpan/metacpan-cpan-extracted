#!/usr/bin/perl -w

=head1 NAME

example-simple.pl - Geo::Ellipsoids simple example

=cut

use strict;
use lib qw{./lib ../lib};
use Geo::Ellipsoids;
my $obj=Geo::Ellipsoids->new(); #defaults to WGS84
print "Short Name: ", $obj->shortname, "\n";
print "Long Name:  ", $obj->longname, "\n";
print "Ellipsoid:  ", "{a=>",$obj->a,",i=>",$obj->i,"}", "\n";
print "\n";
print "a=", $obj->a, "\n";
print "b=", $obj->b, "\n";
print "f=", $obj->f, "\n";
print "i=", $obj->i, "\n";

__END__

=head1 SAMPLE OUTPUT

  Short Name: WGS84
  Long Name:  World Geodetic System of 1984
  Ellipsoid:  {a=>6378137,i=>298.257223563}

  a=6378137
  b=6356752.31424518
  f=0.00335281066474748
  i=298.257223563

=cut
