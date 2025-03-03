package Geo::Inverse;
use strict;
use warnings;
use base qw{Package::New};
use Geo::Constants qw{PI};
use Geo::Functions qw{rad_deg deg_rad};
use Geo::Ellipsoids;

our $VERSION = '0.09';

=head1 NAME

Geo::Inverse - Calculate geographic distance from a latitude and longitude pair

=head1 SYNOPSIS

  use Geo::Inverse;
  my $obj                         = Geo::Inverse->new();                       #default "WGS84"
  my ($lat1, $lon1, $lat2, $lon2) = (38.87, -77.05, 38.95, -77.23);
  my ($faz, $baz, $dist)          = $obj->inverse($lat1, $lon1, $lat2, $lon2); #array context
  my $dist                        = $obj->inverse($lat1, $lon1, $lat2, $lon2); #scalar context
  print "Input Lat: $lat1 Lon: $lon1\n";
  print "Input Lat: $lat2 Lon: $lon2\n";
  print "Output Distance: $dist\n";
  print "Output Forward Azimuth: $faz\n";
  print "Output Back Azimuth: $baz\n";

=head1 DESCRIPTION

This module is a pure Perl port of the NGS program in the public domain "inverse" by Robert (Sid) Safford and Stephen J. Frakes.  

=head1 CONSTRUCTOR

=head2 new

The new() constructor may be called with any parameter that is appropriate to the ellipsoid method which establishes the ellipsoid.

  my $obj = Geo::Inverse->new(); # default "WGS84"

=head1 METHODS

=head2 initialize

=cut

sub initialize {
  my $self  = shift;
  my $param = shift || undef;
  $self->ellipsoid($param);
}

=head2 ellipsoid

Method to set or retrieve the current ellipsoid object.  The ellipsoid is a Geo::Ellipsoids object.

  my $ellipsoid = $obj->ellipsoid;  #Default is WGS84

  $obj->ellipsoid('Clarke 1866'); #Built in ellipsoids from Geo::Ellipsoids
  $obj->ellipsoid({a=>1});        #Custom Sphere 1 unit radius

=cut

sub ellipsoid {
  my $self = shift;
  if (@_) {
    my $param = shift();
    $self->{'ellipsoid'} = Geo::Ellipsoids->new($param);
  }
  return $self->{'ellipsoid'};
}

=head2 inverse

This method is the user frontend to the mathematics. This interface will not change in future versions.

  my ($faz, $baz, $dist) = $obj->inverse($lat1,$lon1,$lat2,$lon2);

=cut

sub inverse {
  my $self               = shift;
  my $lat1               = shift;      #degrees
  my $lon1               = shift;      #degrees
  my $lat2               = shift;      #degrees
  my $lon2               = shift;      #degrees
  die('Syntax Error: function inverse lat1 not defined') unless defined $lat1;
  die('Syntax Error: function inverse lon1 not defined') unless defined $lon1;
  die('Syntax Error: function inverse lat2 not defined') unless defined $lat2;
  die('Syntax Error: function inverse lon2 not defined') unless defined $lon2;
  my ($faz, $baz, $dist) = $self->_inverse(rad_deg($lat1), rad_deg($lon1),
                                           rad_deg($lat2), rad_deg($lon2));
  return wantarray ? (deg_rad($faz), deg_rad($baz), $dist) : $dist;
}

########################################################################
#
#   This function was copied from Geo::Ellipsoid
#   Copyright 2005-2006 Jim Gibson, all rights reserved.
#   
#   This program is free software; you can redistribute it and/or modify it
#   under the same terms as Perl itself.
#
#      internal functions
#
#	inverse
#
#	Calculate the displacement from origin to destination.
#	The input to this subroutine is 
#	  ( latitude-1, longitude-1, latitude-2, longitude-2 ) in radians.
#
#	Return the results as the list (range,bearing) with range in meters
#	and bearing in radians.
#
########################################################################

sub _inverse {
  my $self = shift;
  my( $lat1, $lon1, $lat2, $lon2 ) = (@_);

  my $ellipsoid=$self->ellipsoid;
  my $a = $ellipsoid->a;
  my $f = $ellipsoid->f;

  my $eps = 1.0e-23;
  my $max_loop_count = 20;
  my $pi=PI;
  my $twopi = 2 * $pi;

  my $r = 1.0 - $f;
  my $tu1 = $r * sin($lat1) / cos($lat1);
  my $tu2 = $r * sin($lat2) / cos($lat2);
  my $cu1 = 1.0 / ( sqrt(($tu1*$tu1) + 1.0) );
  my $su1 = $cu1 * $tu1;
  my $cu2 = 1.0 / ( sqrt( ($tu2*$tu2) + 1.0 ));
  my $s = $cu1 * $cu2;
  my $baz = $s * $tu2;
  my $faz = $baz * $tu1;
  my $dlon = $lon2 - $lon1;

  my $x = $dlon;
  my $cnt = 0;
  my( $c2a, $c, $cx, $cy, $cz, $d, $del, $e, $sx, $sy, $y );
  do {
    $sx = sin($x);
    $cx = cos($x);
    $tu1 = $cu2*$sx;
    $tu2 = $baz - ($su1*$cu2*$cx);
    $sy = sqrt( $tu1*$tu1 + $tu2*$tu2 );
    $cy = $s*$cx + $faz;
    $y = atan2($sy,$cy);
    my $sa;
    if( $sy == 0.0 ) {
      $sa = 1.0;
    }else{
      $sa = ($s*$sx) / $sy;
    }

    $c2a = 1.0 - ($sa*$sa);
    $cz = $faz + $faz;
    if( $c2a > 0.0 ) {
      $cz = ((-$cz)/$c2a) + $cy;
    }
    $e = ( 2.0 * $cz * $cz ) - 1.0;
    $c = ( ((( (-3.0 * $c2a) + 4.0)*$f) + 4.0) * $c2a * $f )/16.0;
    $d = $x;
    $x = ( ($e * $cy * $c + $cz) * $sy * $c + $y) * $sa;
    $x = ( 1.0 - $c ) * $x * $f + $dlon;
    $del = $d - $x;
 
  } while( (abs($del) > $eps) && ( ++$cnt <= $max_loop_count ) );

  $faz = atan2($tu1,$tu2);
  $baz = atan2($cu1*$sx,($baz*$cx - $su1*$cu2)) + $pi;
  $x = sqrt( ((1.0/($r*$r)) -1.0 ) * $c2a+1.0 ) + 1.0;
  $x = ($x-2.0)/$x;
  $c = 1.0 - $x;
  $c = (($x*$x)/4.0 + 1.0)/$c;
  $d = ((0.375*$x*$x) - 1.0)*$x;
  $x = $e*$cy;

  $s = 1.0 - $e - $e;
  $s = (((((((( $sy * $sy * 4.0 ) - 3.0) * $s * $cz * $d/6.0) - $x) * 
    $d /4.0) + $cz) * $sy * $d) + $y ) * $c * $a * $r;

  # adjust azimuth to (0,360)
  $faz += $twopi if $faz < 0;

  return($faz, $baz, $s);
}

=head1 LIMITATIONS

No guarantees that Perl handles all of the double precision calculations in the same manner as Fortran.

=head1 LICENSE

Copyright (c) 2025 Michael R. Davis
Copyright (c) 2005-2006 Jim Gibson, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Geo::Ellipsoid>, L<GIS::Distance::GeoEllipsoid>, L<Geo::Calc>

=cut

1;
