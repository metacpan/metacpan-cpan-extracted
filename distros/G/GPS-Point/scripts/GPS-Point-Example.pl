#!/usr/bin/perl
use strict;
use warnings;
use GPS::Point;

=head1 NAME

GPS-Point-Example.pl - GPS-Point Simple Example

=cut

my $point=GPS::Point->new(lat=>38.894022, lon=>-77.036626);

printf "Lat: %s, Lon: %s\n", $point->latlon;
