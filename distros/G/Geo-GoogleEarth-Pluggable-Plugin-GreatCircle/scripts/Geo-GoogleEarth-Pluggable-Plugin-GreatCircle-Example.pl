#!/usr/bin/perl

=head1 NAME

Geo-GoogleEarth-Pluggable-Plugin-GreatCircle-Example.pl - Great Circle Example

=cut

use strict;
use warnings;
use lib qw{/var/www/html/perl/packages/Geo-GoogleEarth-Pluggable/lib};
use Geo::GoogleEarth::Pluggable;

my $document=Geo::GoogleEarth::Pluggable->new(name=>"My Great Circle Example");
my $folder=$document->Folder(name=>"Points");
my $a1=$document->GreatCircleArcSegment(
                     name       => "My Meridianal Great Circle Arc",
                     startPoint => {lat=>38.8658, lon=>-77.1086},
                     endPoint   => {lat=>35.1994, lon=>-77.1086},
                     style      => $document->LineStyle(width=>2, color=>{red=>255}),
                   );

foreach my $point (@{$a1->{"coordinates"}}) {
  $folder->Point(style=>$document->IconStyleRedDot(scale=>0.2),
                 %$point);
}

my $a2=$document->GreatCircleArcSegment(
                     name       => "My Equatorial Great Circle Arc",
                     startPoint => {lat=>0, lon=>-77.0},
                     endPoint   => {lat=>0, lon=>-97.0},
                     style      => $document->LineStyle(width=>2, color=>{green=>255}),
                   );
foreach my $point (@{$a2->{"coordinates"}}) {
  $folder->Point(style => $document->IconStyleGreenDot(scale=>0.2),
                 %$point);
}

my $a3=$document->GreatCircleArcSegment(
                     name       => "My Favorite Great Circle Arc",
                     startPoint => {lat=>38.8658, lon=>-77.1086},
                     endPoint   => {lat=>44.4438, lon=> 15.0546},
                     style      => $document->LineStyle(width=>2, color=>{blue=>255}),
                   );
foreach my $point (@{$a3->{"coordinates"}}) {
  $folder->Point(style=>$document->IconStyleBlueDot(scale=>0.2),
                 %$point);
}

print $document->render;
