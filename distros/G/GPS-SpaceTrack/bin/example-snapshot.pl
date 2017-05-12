#!/usr/bin/perl -w

=head1 NAME

example-snapshot.pl - Plot GPS::SpaceTrack data with GD::Graph::Polar

=cut

use strict;
use lib qw{./lib ../lib};
use GPS::SpaceTrack;
use GD::Graph::Polar;
use Time::HiRes qw{time};

my $lat=shift()||39.870997;    #degrees
my $lon=shift()||-77.05596;    #degrees
my $hae=shift()||13;           #meters
my $time=time();               #seconds

my $filename="";
$filename="../doc/gps.tle" if -r "../doc/gps.tle";
$filename="./doc/gps.tle" if -r "./doc/gps.tle";
$filename="./gps.tle" if -r "./gps.tle";
$filename="../gps.tle" if -r "../gps.tle";
$filename="../../gps.tle" if -r "../../gps.tle";

my $obj=GPS::SpaceTrack->new(filename=>$filename) || die();
my $plot=GD::Graph::Polar->new(size=>500, radius=>90, ticks=>9);
$plot->color('gray');
$plot->addString($_*10=>0, $_*10) foreach (1..8);
$plot->addGeoString(87=>$_, $_) foreach (0,90,180,270);

$plot->color('black');
foreach (grep {$_->elev > 0} $obj->getsatellitelist({lat=>$lat,
                                                     lon=>$lon,
                                                     alt=>$hae,
                                                     time=>$time})) {
  my $r=90-$_->elev;
  my $t=$_->azim;
  $plot->addGeoPoint($r=>$t);
  $plot->addGeoString($r=>$t, $_->prn);
}
open(IMG, ">example-snapshot.png");
print IMG $plot->draw;
close(IMG);

__END__

=head1 SAMPLE OUTPUT

L<http://search.cpan.org/src/MRDVT/GPS-SpaceTrack-0.09/bin/example-snapshot.png>

=cut
