#!/usr/bin/perl

=head1 NAME

perl-GPS-Point-Filter.pl - A sample perl-GPS-Point-Filter script.

=cut

use strict;
use warnings;
use DateTime;
use Geo::Forward;
use GPS::Point;
use lib qw{../lib ./lib};
use GPS::Point::Filter;

local $|=1;
my $gpf=GPS::Point::Filter->new(
                                separation => 2000,  #meters
                                interlude  => 1200,  #seconds
                                deviation  => 500,   #meters
                                debug      => 1,     #
                               );


my $gf=Geo::Forward->new;

$gpf->addCallback(sample=>\&GPS::Point::Filter::callback_sample);
#$gpf->deleteCallback("sample");

my $lat=39;
my $lon=-77;
my $speed=35; #m/s
my $heading=90; #degrees from north

print join("\t", qw{Type Time Latitude Longitude Speed Heading}), "\n";
while (sleep 1) {
  my $point=GPS::Point->new(time  => DateTime->now->epoch,
                            lat   => $lat,
                            lon   => $lon,
                            speed => $speed,
                            heading => $heading);
  printf GPS::Point::Filter::callback_sample_string(Point=>$point);
  my $status=$gpf->addPoint($point);
  #printf "%s\n", $status if $status;
  ($lat,$lon,undef)=$gf->forward($lat,$lon,$heading,$speed);
  $heading+=5 - rand(5);
  $heading-=360 if $heading > 360; 
  $speed=35 + 10 - rand(20);
}
