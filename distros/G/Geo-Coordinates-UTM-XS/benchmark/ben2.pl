#!/usr/bin/perl

use strict;
use warnings;

package pp;
use Geo::Coordinates::UTM;

package xs;
use Geo::Coordinates::UTM::XS;

package main;
use Benchmark qw(cmpthese);

my $n = 1000;
my @lat = map { 84 - rand(164) } 0..$n;
my @lon = map { 180 - rand(260) } 0..$n;

cmpthese(-1,
         {
          pp => sub {
              for (0..$n) {
                  my ($z,$e,$n) = pp::latlon_to_utm(international => $lat[$_], $lon[$_]);
                  my ($lat, $lon) = pp::utm_to_latlon(international => $z, $e, $n);
              }
          },
          xs => sub {
              for (0..$n) {
                  my ($z,$e,$n) = xs::latlon_to_utm(international => $lat[$_], $lon[$_]);
                  my ($lat, $lon) = xs::utm_to_latlon(international => $z, $e, $n);
              }
          },
         }
        );
