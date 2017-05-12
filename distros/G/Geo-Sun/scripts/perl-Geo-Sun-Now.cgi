#!/usr/bin/perl

=head1 NAME

perl-Geo-Sun-Now.cgi - Geo::Sun simple example

=cut

use strict;
use warnings;
use DateTime;
use Geo::Sun;
my $gs=Geo::Sun->new;
my $point=$gs->point;
printf "Time: %s, Latitude: %s, Longitude: %s\n",
         DateTime->from_epoch(epoch=>$point->time)->datetime,
         $point->lat, $point->lon;
