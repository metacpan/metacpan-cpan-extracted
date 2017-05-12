package Geo::ECEF;
use strict;
use warnings;
use Geo::Ellipsoids;
use Geo::Functions qw{rad_deg deg_rad};

our $VERSION="1.10";

=head1 NAME

Geo::ECEF - Converts between ECEF (earth centered earth fixed) coordinates and latitude, longitude and height above ellipsoid.

=head1 SYNOPSIS

  use Geo::ECEF;
  my $obj=Geo::ECEF->new(); #WGS84 is the default
  my ($x, $y, $z)=$obj->ecef(39.197807, -77.108574, 55); #Lat (deg), Lon (deg), HAE (meters)
  print "X: $x\tY: $y\tZ: $z\n";

  my ($lat, $lon, $hae)=$obj->geodetic($x, $y, $z); #X (meters), Y (meters), Z (meters)
  print "Lat: $lat  \tLon: $lon \tHAE $hae\n";


=head1 DESCRIPTION

Geo::ECEF provides two methods ecef and geodetic.  The ecef method calculates the X,Y and Z coordinates in the ECEF (earth centered earth fixed) coordinate system from latitude, longitude and height above the ellipsoid.  The geodetic method calculates the latitude, longitude and height above ellipsoid from ECEF coordinates.

The formulas were found at http://www.u-blox.ch/ and http://waas.stanford.edu/~wwu/maast/maastWWW1_0.zip.

This code is an object Perl rewrite of a similar package by Morten Sickel, Norwegian Radiation Protection Authority

=head1 CONSTRUCTOR

=head2 new

The new() constructor initializes the ellipsoid method.

  my $obj=Geo::ECEF->new("WGS84"); #WGS84 is the default

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

=head2 initialize

=cut

sub initialize {
  my $self = shift();
  my $param = shift()||undef();
  $self->ellipsoid($param);
}

=head2 ellipsoid

Method to set or retrieve the current ellipsoid object.  The ellipsoid is a Geo::Ellipsoids object.

  my $ellipsoid=$obj->ellipsoid;  #Default is WGS84

  $obj->ellipsoid('Clarke 1866'); #Built in ellipsoids from Geo::Ellipsoids
  $obj->ellipsoid({a=>1});        #Custom Sphere 1 unit radius

=cut

sub ellipsoid {
  my $self = shift();
  if (@_) {
    my $param=shift();
    use Geo::Ellipsoids;
    my $obj=Geo::Ellipsoids->new($param);
    $self->{'ellipsoid'}=$obj;
  }
  return $self->{'ellipsoid'};
}

=head2 ecef

Method returns X (meters), Y (meters), Z (meters) from lat (degrees), lon (degrees), HAE (meters).

  my ($x, $y, $z)=$obj->ecef(39.197807, -77.108574, 55);

=cut

sub ecef {
  my $self = shift();
  my $lat_rad=rad_deg(shift()||0);
  my $lon_rad=rad_deg(shift()||0);
  my $hae=shift()||0;
  return $self->ecef_rad($lat_rad, $lon_rad, $hae);
}

=head2 ecef_rad

Method returns X (meters), Y (meters), Z (meters) from lat (radians), lon (radians), HAE (meters).

  my ($x, $y, $z)=$obj->ecef(0.678, -0.234, 55);

This method may be copyright Michael Kleder, April 2006 from mathworks.com

=cut

sub ecef_rad {
  my $self = shift();
  my $lat=shift()||0;
  my $lon=shift()||0;
  my $hae=shift()||0;
  my $ellipsoid=$self->ellipsoid;
  my $e2=$ellipsoid->e2;
  my $n=$ellipsoid->n_rad($lat);
  my $x=($n+$hae) * cos($lat) * cos($lon);
  my $y=($n+$hae) * cos($lat) * sin($lon);
  my $z=((1-$e2) * $n + $hae) * sin($lat);
  my @array=($x, $y, $z);
  return wantarray ? @array : \@array;
}

=head2 geodetic

Calls the default geodetic method.  This user interface will not change,

Method returns latitude (degrees), longitude (degrees), HAE (meters) from X (meters), Y (meters), Z (meters).

  my ($lat, $lon, $hae)=$obj->geodetic($x, $y, $z);

=cut

sub geodetic {
  my $self = shift();
  return $self->geodetic_direct(@_);
}

=head2 geodetic_iterative

Method returns latitude (degrees), longitude (degrees), HAE (meters) from X (meters), Y (meters), Z (meters).  This is an iterative calculation.

  my ($lat, $lon, $hae)=$obj->geodetic($x, $y, $z);

Portions of this method may be...

 *************************************************************************
 *     Copyright c 2001 The board of trustees of the Leland Stanford     *
 *                      Junior University. All rights reserved.          *
 *     This script file may be distributed and used freely, provided     *
 *     this copyright notice is always kept with it.                     *
 *                                                                       *
 *     Questions and comments should be directed to Todd Walter at:      *
 *     twalter@stanford.edu                                              *
 *************************************************************************

=cut

sub geodetic_iterative {
  my $self = shift();
  my $x=shift()||0;
  my $y=shift()||0;
  my $z=shift()||0;
  my $ellipsoid=$self->ellipsoid;
  my $e2=$ellipsoid->e2;
  my $p=sqrt($x**2 + $y**2);
  my $lon=atan2($y,$x);
  my $lat=atan2($z/$p, 0.01);
  my $n=$ellipsoid->n_rad($lat);
  my $hae=$p/cos($lat) - $n;
  my $old_hae=-1e-9;
  my $num=$z/$p;
  while (abs($hae-$old_hae) > 1e-4) {
    $old_hae=$hae;
    my $den=1 - $e2 * $n /($n + $hae);
    $lat=atan2($num, $den);
    $n=$ellipsoid->n_rad($lat);
    $hae=$p/cos($lat)-$n;
  }
  $lat=deg_rad($lat);
  $lon=deg_rad($lon);
  my @array=($lat, $lon, $hae);
  return wantarray ? @array : \@array;
}

=head2 geodetic_direct

Method returns latitude (degrees), longitude (degrees), HAE (meters) from X (meters), Y (meters), Z (meters).  This is a direct (non-iterative) calculation from the gpsd distribution.

  my ($lat, $lon, $hae)=$obj->geodetic($x, $y, $z);

This method may be copyright Michael Kleder, April 2006 from mathworks.com

=cut

sub geodetic_direct {
  my $self = shift();
  my $x=shift()||0;
  my $y=shift()||0;
  my $z=shift()||0;

  my $ellipsoid=$self->ellipsoid;
  my $a = $ellipsoid->a;
  my $b = $ellipsoid->b;
  my $e2 = $ellipsoid->e2;
  my $ep2 = $ellipsoid->ep2;
  my $p = sqrt($x**2 + $y**2);
  my $t = atan2($z*$a, $p*$b);
  my $lon=atan2($y, $x);
  my $lat=atan2($z + $ep2*$b*sin($t)**3, $p - $e2*$a*cos($t)**3);
  my $n = $ellipsoid->n_rad($lat);
  my $hae;
  eval {
    $hae = $p/cos($lat) - $n; #Just in case $lat is +-90 degrees
  };

  my @array;
  if ($@) {
    @array=(deg_rad($lat), 0, abs($z)-$b);  #Is this correct?
  } else {
    @array=(deg_rad($lat), deg_rad($lon), $hae);
  }
  return wantarray ? @array : \@array;
}

=head1 TODO

=head1 SUPPORT

DavisNetworks.com supports all Perl applications big or small.

=head1 BUGS

Please log on RT and send email to the geo-perl email list.

=head1 LIMITS

Win32 platforms cannot tell the difference between the deprecated L<geo::ecef> module and the current L<Geo::ECEF> module.  The way to tell is if Geo::ECEF->can("new");

=head1 AUTHORS

Michael R. Davis qw/perl michaelrdavis com/

Morten Sickel http://sickel.net/

=head1 LICENSE

Copyright (c) 2007-2010 Michael R. Davis (mrdvt92)

Copyright (c) 2005 Morten Sickel (sickel.net)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Geo::Ellipsoids>, L<Geo::Functions>, L<geo::ecef>, L<Astro::Coord::ECI>, L<Geo::Tools>, http://www.ngs.noaa.gov/cgi-bin/xyz_getxyz.prl, http://www.mathworks.com/matlabcentral/

=cut

1;
