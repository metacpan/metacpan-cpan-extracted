package Geo::Forward;
use strict;
use warnings;
use base qw{Package::New};
use Geo::Constants 0.04 qw{PI};
use Geo::Functions 0.03 qw{deg_rad rad_deg};
use Geo::Ellipsoids 0.09 qw{};

our $VERSION="0.14";

=head1 NAME

Geo::Forward - Calculate geographic location from lat, lon, distance, and heading.

=head1 SYNOPSIS

  use Geo::Forward;
  my $obj = Geo::Forward->new(); # default "WGS84"
  my ($lat1,$lon1,$faz,$dist)=(38.871022, -77.055874, 62.888507083, 4565.6854);
  my ($lat2,$lon2,$baz) = $obj->forward($lat1,$lon1,$faz,$dist);
  print "Input Lat: $lat1  Lon: $lon1\n";
  print "Input Forward Azimuth: $faz\n";
  print "Input Distance: $dist\n";
  print "Output Lat: $lat2 Lon: $lon2\n";
  print "Output Back Azimuth: $baz\n";

=head1 DESCRIPTION

This module is a pure Perl port of the NGS program in the public domain "forward" by Robert (Sid) Safford and Stephen J. Frakes.  

=head1 CONSTRUCTOR

=head2 new

The new() constructor may be called with any parameter that is appropriate to the ellipsoid method which establishes the ellipsoid.

  my $obj = Geo::Forward->new(); # default "WGS84"

=head1 METHODS

=head2 initialize

=cut

sub initialize {
  my $self  = shift;
  my $param = shift || undef;
  $self->ellipsoid($param);
}

=head2 ellipsoid

Method to set or retrieve the current ellipsoid object.  The ellipsoid is a L<Geo::Ellipsoids> object.

  my $ellipsoid=$obj->ellipsoid;  #Default is WGS84

  $obj->ellipsoid('Clarke 1866'); #Built in ellipsoids from Geo::Ellipsoids
  $obj->ellipsoid({a=>1});        #Custom Sphere 1 unit radius

=cut

sub ellipsoid {
  my $self=shift;
  if (@_) {
    my $param=shift;
    $self->{'ellipsoid'}=Geo::Ellipsoids->new($param);
  }
  return $self->{'ellipsoid'};
}

=head2 forward

This method is the user frontend to the mathematics. This interface will not change in future versions.

  my ($lat2,$lon2,$baz) = $obj->forward($lat1,$lon1,$faz,$dist);

Note: Latitude and longitude units are signed decimal degrees.   The distance units are based on the ellipsoid semi-major axis which is meters for WGS-84.  The forward and backward azimuths units are signed degrees clockwise from North.

=cut

sub forward {
  my $self     = shift;
  my $lat      = shift; #degrees
  my $lon      = shift; #degrees
  my $heading  = shift; #degrees
  my $distance = shift; #meters (or the units of the semi-major axis)
  my ($lat2, $lon2, $baz)= $self->_dirct1(rad_deg($lat),rad_deg($lon),rad_deg($heading),$distance);
  return(deg_rad($lat2), deg_rad($lon2), deg_rad($baz));
}

sub _dirct1 {
  my $self  = shift; #provides A and F
  my $GLAT1 = shift; #radians
  my $GLON1 = shift; #radians
  my $FAZ   = shift; #radians
  my $S     = shift; #units of semi-major axis (default meters)

#      SUBROUTINE DIRCT1(GLAT1,GLON1,GLAT2,GLON2,FAZ,BAZ,S)
#C
#C *** SOLUTION OF THE GEODETIC DIRECT PROBLEM AFTER T.VINCENTY
#C *** MODIFIED RAINSFORD'S METHOD WITH HELMERT'S ELLIPTICAL TERMS
#C *** EFFECTIVE IN ANY AZIMUTH AND AT ANY DISTANCE SHORT OF ANTIPODAL
#C
#C *** A IS THE SEMI-MAJOR AXIS OF THE REFERENCE ELLIPSOID
#C *** F IS THE FLATTENING OF THE REFERENCE ELLIPSOID
#C *** LATITUDES AND LONGITUDES IN RADIANS POSITIVE NORTH AND EAST
#C *** AZIMUTHS IN RADIANS CLOCKWISE FROM NORTH
#C *** GEODESIC DISTANCE S ASSUMED IN UNITS OF SEMI-MAJOR AXIS A
#C
#C *** PROGRAMMED FOR CDC-6600 BY LCDR L.PFEIFER NGS ROCKVILLE MD 20FEB75
#C *** MODIFIED FOR SYSTEM 360 BY JOHN G GERGEN NGS ROCKVILLE MD 750608
#C
#      IMPLICIT REAL*8 (A-H,O-Z)
#      COMMON/CONST/PI,RAD
#      COMMON/ELIPSOID/A,F
       my $ellipsoid=$self->ellipsoid;
       my $A=$ellipsoid->a;
       my $F=$ellipsoid->f;
#      DATA EPS/0.5D-13/
       my $EPS=0.5E-13;
#      R=1.-F
       my $R=1.-$F;
#      TU=R*DSIN(GLAT1)/DCOS(GLAT1)
       my $TU=$R*sin($GLAT1)/cos($GLAT1);
#      SF=DSIN(FAZ)
       my $SF=sin($FAZ);
#      CF=DCOS(FAZ)
       my $CF=cos($FAZ);
#      BAZ=0.
       my $BAZ=0.;
#      IF(CF.NE.0.) BAZ=DATAN2(TU,CF)*2.
       $BAZ=atan2($TU,$CF)*2. if ($CF != 0);
#      CU=1./DSQRT(TU*TU+1.)
       my $CU=1./sqrt($TU*$TU+1.);
#      SU=TU*CU
       my $SU=$TU*$CU;
#      SA=CU*SF
       my $SA=$CU*$SF;
#      C2A=-SA*SA+1.
       my $C2A=-$SA*$SA+1.;
#      X=DSQRT((1./R/R-1.)*C2A+1.)+1.
       my $X=sqrt((1./$R/$R-1.)*$C2A+1.)+1.;
#      X=(X-2.)/X
       $X=($X-2.)/$X;
#      C=1.-X
       my $C=1.-$X;
#      C=(X*X/4.+1)/C
       $C=($X*$X/4.+1)/$C;
#      D=(0.375D0*X*X-1.)*X
       my $D=(0.375*$X*$X-1.)*$X;
#      TU=S/R/A/C
       $TU=$S/$R/$A/$C;
#      Y=TU
       my $Y=$TU;
#  100 SY=DSIN(Y)
       my ($SY, $CY, $CZ, $E);
   do{ $SY=sin($Y);
#      CY=DCOS(Y)
       $CY=cos($Y);
#      CZ=DCOS(BAZ+Y)
       $CZ=cos($BAZ+$Y);
#      E=CZ*CZ*2.-1.
       $E=$CZ*$CZ*2.-1.;
#      C=Y
       $C=$Y;
#      X=E*CY
       $X=$E*$CY;
#      Y=E+E-1.
       $Y=$E+$E-1.;
#      Y=(((SY*SY*4.-3.)*Y*CZ*D/6.+X)*D/4.-CZ)*SY*D+TU
       $Y=((($SY*$SY*4.-3.)*$Y*$CZ*$D/6.+$X)*$D/4.-$CZ)*$SY*$D+$TU;
#      IF(DABS(Y-C).GT.EPS)GO TO 100
     } while (abs($Y-$C) > $EPS);
#      BAZ=CU*CY*CF-SU*SY
       $BAZ=$CU*$CY*$CF-$SU*$SY;
#      C=R*DSQRT(SA*SA+BAZ*BAZ)
       $C=$R*sqrt($SA*$SA+$BAZ*$BAZ);
#      D=SU*CY+CU*SY*CF
       $D=$SU*$CY+$CU*$SY*$CF;
#      GLAT2=DATAN2(D,C)
       my $GLAT2=atan2($D,$C);
#      C=CU*CY-SU*SY*CF
       $C=$CU*$CY-$SU*$SY*$CF;
#      X=DATAN2(SY*SF,C)
       $X=atan2($SY*$SF,$C);
#      C=((-3.*C2A+4.)*F+4.)*C2A*F/16.
       $C=((-3.*$C2A+4.)*$F+4.)*$C2A*$F/16.;
#      D=((E*CY*C+CZ)*SY*C+Y)*SA
       $D=(($E*$CY*$C+$CZ)*$SY*$C+$Y)*$SA;
#      GLON2=GLON1+X-(1.-C)*D*F
       my $GLON2=$GLON1+$X-(1.-$C)*$D*$F;
#      BAZ=DATAN2(SA,BAZ)+PI
       $BAZ=atan2($SA,$BAZ)+PI;
#      RETURN
       return $GLAT2, $GLON2, $BAZ;
#      END
}

=head1 TODO

Add tests for more ellipsoids.

=head1 BUGS

Please log on RT and email to the geo-perl email list as well as the author.

=head1 SUPPORT

DavisNetworks.com supports all Perl applications including this package.

=head1 LIMITS

No guarantees that Perl handles all of the double precision calculations in the same manner as Fortran.

=head1 AUTHOR

  Michael R. Davis qw/perl michaelrdavis com/
  CPAN ID: MRDVT

=head1 LICENSE

Copyright (c) 2011 Michael R. Davis (mrdvt92)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

=head3 Similar Packages

L<Geo::Distance>, L<Geo::Ellipsoid>

=head2 Opposite Packages

L<Geo::Inverse>

=head2 Building Blocks

L<Geo::Ellipsoids>, L<Geo::Constants>, L<Geo::Functions>

=cut

1;
