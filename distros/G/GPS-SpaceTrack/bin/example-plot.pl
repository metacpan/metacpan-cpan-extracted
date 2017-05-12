#!/usr/bin/perl -w

=head1 NAME

example-plot.pl - Plot GPS::SpaceTrack data with GD::Graph::Polar

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

my $plot=GD::Graph::Polar->new(size=>800, radius=>90, ticks=>9);
my $obj=GPS::SpaceTrack->new(filename=>$filename) || die();

my $count=0;
my @data=();
foreach my $sec (0..70) {
  $sec*=400;
  $sec+=$time;
  foreach (grep {$_->elev > 0} $obj->getsatellitelist({lat=>$lat,
                                                       lon=>$lon,
                                                       alt=>$hae,
                                                       time=>$sec})) {
    my $r=90-$_->elev;
    my $t=$_->azim;
    $count++;
    push @data, [$_->prn, $count, $r=>$t];
    {
      local $|=1;
      print $count, "\r";
    }
  }
} 
my %prn=map {$_->[0] => 1} @data;
foreach my $prn (keys %prn) {
  my @list=grep {$_->[0] eq $prn} @data;
  foreach (1..$#list) {
    my $r0=$list[$_-1]->[2];
    my $t0=$list[$_-1]->[3];
    my $r1=$list[$_]->[2];
    my $t1=$list[$_]->[3];
    $plot->addGeoPoint($r0=>$t0) if 1==$_;
    $plot->addString($r0=>90-$t0,$prn) if 1==$_;
    $plot->addGeoPoint($r1=>$t1) if $#list==$_;
    $plot->addString($r1=>90-$t1, $prn) if $#list==$_;
    $plot->addGeoLine($r0=>$t0, $r1=>$t1);
  }
}
print "\nTime: ", time()-$time, " seconds\n";
open(IMG, ">example-plot.png");
print IMG $plot->draw;
close(IMG);

__END__

=head1 SAMPLE OUTPUT

L<http://search.cpan.org/src/MRDVT/GPS-SpaceTrack-0.09/bin/example-plot.png>

=cut
