#!/usr/bin/perl
use strict;
use warnings;
use lib qw{/var/www/html/perl/packages/Geo-GoogleEarth-Pluggable/lib};
use blib;
use Geo::GoogleEarth::Pluggable;

=head1 NAME

Geo-GoogleEarth-Pluggable-CircleByCenterPoint.pl CircleByCenterPoint Plugin for Geo-GoogleEarth-Pluggable

=cut

my $document=Geo::GoogleEarth::Pluggable->new(name=>"My Document");
$document->CircleByCenterPoint(
                               name        => "My Circle",
                               lat         => 38.889471,
                               lon         => -77.035275,
                               radius      => 500,
                              );
#use Data::Dumper qw{Dumper};
#print Dumper($document->structure);
print $document->render;
