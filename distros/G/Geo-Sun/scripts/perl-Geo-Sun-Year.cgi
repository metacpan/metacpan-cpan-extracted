#!/usr/bin/perl

=head1 NAME

perl-Geo-Sun-Year.cgi - Geo::Sun example with Geo::GoogleEarth::Document

=cut

use strict;
use warnings;
use DateTime;
use Geo::Sun;
use CGI;
use Geo::GoogleEarth::Document;
my $cgi=CGI->new;
my $gs=Geo::Sun->new;
my $document=Geo::GoogleEarth::Document->new;
foreach my $days (0 .. 365) {
  my $dt=DateTime->new(year=>DateTime->now->year)
           ->add(days=>$days)->set_hour(12);
  my $point=$gs->point_dt($dt);
  $document->Placemark(name=>scalar($dt->datetime), %$point);
}
print $cgi->header('application/vnd.google-earth.kml+xml'),
      $document->render;
