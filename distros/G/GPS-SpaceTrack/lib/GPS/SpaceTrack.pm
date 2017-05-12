package GPS::SpaceTrack;

=head1 NAME

GPS::SpaceTrack - Package for calculating the position of GPS satellites

=head1 SYNOPSIS

  use GPS::SpaceTrack;
  my $obj=GPS::SpaceTrack->new(filename=>"gps.tle");
  print join("\t", qw{Count PRN ELEV Azim SNR USED}), "\n";
  foreach ($obj->getsatellitelist({lat=>38.870997, lon=>-77.05596})) {
    print join("\t", $_->prn, $_->elev, $_->azim, $_->snr, $_->used), "\n";
  }

=head1 DESCRIPTION

This package can calculates the location of the GPS satellite constellation given the position of the receiver and a time which can be in the future. 

=head1 CONVENTIONS

Function naming convention is "format of the return" underscore "format of the parameters."

=cut

use strict;
use vars qw($VERSION);
$VERSION = sprintf("%d.%02d", q{Revision: 0.11} =~ /(\d+)\.(\d+)/);
use Astro::Coord::ECI;
use Astro::Coord::ECI::TLE;
use Net::GPSD::Satellite;
use Geo::Functions qw{deg_rad rad_deg};
use Time::HiRes qw{time};
use GPS::PRN;
my $gpsprn=GPS::PRN->new;

=head1 CONSTRUCTOR

=head2 new

The new() constructor passes paramaters to the filename() method.

  my $obj = GPS::SpaceTrack->new(filename=>$filename);

=cut

sub new {
  my $this = shift();
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;
  $self->initialize(@_);
  return $self;
}

=head1 METHODS

=cut

sub initialize {
  my $self=shift();
  my $param={@_};
  $self->filename($param->{'filename'});
}

=head2 getsatellitelist

The getsatellitelist() method returns a list of Net::GPSD::Satellite objects.  The getsatellitelist() method is a wrapper around getsatellitelist_rad() for data formatted in degrees instead of radians.

  my $list=$obj->getsatellitelist({lat=>$lat, lon=>$lon, alt=>$hae, time=>$time}); #degrees, degrees, meters, seconds from epoch
  my @list=$obj->getsatellitelist({lat=>$lat, lon=>$lon, alt=>$hae, time=>$time}); #degrees, degrees, meters, seconds from epoch

=cut

sub getsatellitelist {
  my $self=shift();
  my $point=shift(); die() unless ref($point) eq "HASH";
  $point->{'lat'}=rad_deg($point->{'lat'}) if defined($point->{'lat'});
  $point->{'lon'}=rad_deg($point->{'lon'}) if defined($point->{'lon'});
  return $self->getsatellitelist_rad($point);
}

=head2 getsatellitelist_rad

The getsatellitelist_rad() method returns a list of Net::GPSD::Satellite objects.  This method is basically a wrapper around Astro::Coord::ECI::TLE.

  my $list=$obj->getsatellitelist_rad({lat=>$lat, lon=>$lon, alt=>$hae, time=>$time}); #radians, radians, meters, seconds from epoch
  my @list=$obj->getsatellitelist_rad({lat=>$lat, lon=>$lon, alt=>$hae, time=>$time}); #radians, radians, meters, seconds from epoch

=cut

sub getsatellitelist_rad {
  my $self=shift();
  my $point=shift();
  my $gnd_lat_rad=defined($point->{'lat'}) ?
                    $point->{'lat'} : die('Error: Required {lat=>$lat}');
  my $gnd_lon_rad=defined($point->{'lon'}) ?
                    $point->{'lon'} : die('Error: Required {lon=>$lon}');
  my $gnd_hae_km=($point->{'alt'}||0)/1000;
  my $time=$point->{'time'}||time();

  my $tle_data=$self->data;
  my @satellite=Astro::Coord::ECI::TLE->parse($tle_data);
  my @list=();
  foreach my $tle (@satellite) {
    my($sat_lat, $sat_lon, $sat_hae_km)= $tle->universal($time)->geodetic;
    #my($x, $y, $z)=$tle->eci();
    my $id=$tle->get('id');
    #my $name=$tle->get('name');
    my $sta=Astro::Coord::ECI->new(refraction=>1,
                                   name=>'Station')->geodetic($gnd_lat_rad,
                                                              $gnd_lon_rad,
                                                              $gnd_hae_km);
    my ($azm_rad, $elev_rad, $dist_km)=$sta->azel($tle->universal($time));
    my $prn=$gpsprn->prn_oid($id);
    my $elev=deg_rad($elev_rad);
    my $azim=deg_rad($azm_rad);
    my $snr=45 * sin($elev_rad > 0 ? $elev_rad : 0)**2; #rough calc
    my $used=$snr > 10 ? 1 : 0;                         #rough estimate
    if ($prn) {
      push @list, Net::GPSD::Satellite->new($prn, $elev, $azim, $snr, $used);
    }
  }
  @list=sort {$b->elev<=>$a->elev} @list;
  return wantarray ? @list : \@list;
}

=head2 filename

Method to get or set the filename of the TLE data.

  my $filename=$obj->filename;
  my $filename=$obj->filename(filename=>$filename);

=cut

sub filename {
  my $self=shift();
  if (@_) {
    my $filename=shift();
    if (-r $filename) {
      $self->{'filename'} = $filename; 
    } else {
      if (-e $filename) {
        die("Error: $filename does not exist");
      } else {
        die("Error: $filename is not readable");
      }
    }
  }
  undef($self->{'data'});
  return $self->{'filename'};
}

sub data {
  my $self=shift();
  unless (defined($self->{'data'})) {
    my $filename=$self->filename;
    open(DATA, $filename) || die("Error: Cannot open $filename");
    {
    local $/=undef();
    $self->{'data'}=<DATA>;
    }
    close(DATA);
  }
  return $self->{'data'};
}

1;

__END__

=head1 TODO

=head1 BUGS

Please send to the gpsd email list.

=head1 LIMITS

=head1 AUTHOR

Michael R. Davis qw/perl michaelrdavis com/

=head1 LICENSE

Copyright (c) 2006 Michael R. Davis (mrdvt92)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

Astro::Coord::ECI::TLE
Geo::Functions
GPS::PRN
Net::GPSD::Satellite
