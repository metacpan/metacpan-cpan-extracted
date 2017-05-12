#!/usr/bin/perl
use warnings;
use strict;
use lib qw{/var/www/html/perl/packages/Geo-GoogleEarth-Pluggable/lib};
use blib;
use Geo::GoogleEarth::Pluggable;

=head1 NAME

Geo-GoogleEarth-Pluggable-ArcByCenterPoint.pl ArcByCenterPoint Plugin for Geo-GoogleEarth-Pluggable

=cut

my $document=Geo::GoogleEarth::Pluggable->new(name=>"My Document");
my $arc=$document->ArcByCenterPoint(
                            name       => "My ArcByCenterPoint",
                            radius     => 500,    #meters
                            startAngle => -5.0,   #degrees CW/North
                            endAngle   => 270.0,  #degrees CW/North
                            deltaAngle => 7.2,    #default
                            lat        => 38.889, #WGS-84 degrees
                            lon        =>-77.035, #WGS-84 degrees
                            alt        => 0,      #reference LookAt
                           );

my $start=$arc->coordinates->[0];
my $end=$arc->coordinates->[-1];

$document->Point(name=>"Center", lat=>38.889, lon=>-77.035);
$document->Point(name=>"Start", %$start);
$document->Point(name=>"End", %$end);

#use Data::Dumper qw{Dumper};
#print Dumper([{start=>$start, end=>$end}]);
print $document->render;
