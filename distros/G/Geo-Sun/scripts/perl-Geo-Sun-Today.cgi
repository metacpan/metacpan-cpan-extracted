#!/usr/bin/perl

=head1 NAME

perl-Geo-Sun-Today.cgi - Geo::Sun simple example

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
foreach my $hour (0 .. 23) {
  foreach my $five (0 .. 11) {
    my $minute=$five * 5;
    my $dt=DateTime->today->set_hour($hour)->set_minute($minute);
    my $point=$gs->point_dt($dt);
    $document->Placemark(name=>scalar($dt->datetime), %$point);
  }
}
print $cgi->header('application/vnd.google-earth.kml+xml'),
      $document->render;
