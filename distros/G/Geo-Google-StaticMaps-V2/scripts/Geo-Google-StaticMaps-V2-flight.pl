#!/usr/bin/perl
use strict;
use warnings;
use Geo::Google::StaticMaps::V2;

my $syntax = qq{Syntax:\n\n  Geo-Google-StaticMaps-V2-flight.pl "Airport City 1" "Airport City 2"\n\n};

my $city1=shift or die($syntax);
my $city2=shift or die($syntax);

my $map=Geo::Google::StaticMaps::V2->new;

$map->path(locations=>[$city1, $city2], geodesic=>1);

print $map->url, "\n";


__END__


=head1 NAME

Geo-Google-StaticMaps-V2-flight.pl - Generates URL for a Google Static Map between two Airport Cities

=cut
