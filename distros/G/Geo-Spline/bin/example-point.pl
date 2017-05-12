#!/usr/bin/perl -w

=head1 NAME

example-point.pl - Geo::Spline example to list a single point in time between GPS fixes

=cut

use strict;
use lib qw{./lib ../lib};
use Geo::Spline;

my $p0={time=>1160449100.67,
        lat=>39.197807,
        lon=>-77.263510,
        speed=>31.124,
        heading=>144.8300};
my $p1={time=>1160449225.66,
        lat=>39.167718,
        lon=>-77.242278,
        speed=>30.615,
        heading=>150.5300};
my $spline=Geo::Spline->new($p0, $p1);
my $pt=$spline->point(1160449150);
print "Time: ",    "\t", $pt->{"time"},    "\n",
      "Lat: ",     "\t", $pt->{"lon"},     "\n",
      "Lon: ",     "\t", $pt->{"lat"},     "\n",
      "Speed: ",   "\t", $pt->{"speed"},   "\n",
      "Heading: ", "\t", $pt->{"heading"}, "\n";

__END__

=head1 SAMPLE OUTPUT

  Time:    1160449150
  Lat:     -77.2548824212533
  Lon:      39.1861322117117
  Speed:    33.6486345148074
  Heading: 142.982403679392

=cut
