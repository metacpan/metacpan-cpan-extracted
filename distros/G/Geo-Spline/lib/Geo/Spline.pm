package Geo::Spline;

=head1 NAME

Geo::Spline - Calculate geographic locations between GPS fixes.

=head1 SYNOPSIS

  use Geo::Spline;
  my $p0={time=>1160449100.67, #seconds
          lat=>39.197807,      #degrees
          lon=>-77.263510,     #degrees
          speed=>31.124,       #m/s
          heading=>144.8300};  #degrees clockwise from North
  my $p1={time=>1160449225.66,
          lat=>39.167718,
          lon=>-77.242278,
          speed=>30.615,
          heading=>150.5300};
  my $spline=Geo::Spline->new($p0, $p1);
  my %point=$spline->point(1160449150);
  print "Lat:", $point{"lat"}, ", Lon:", $point{"lon"}, "\n\n";

  my @points=$spline->pointlist();
  foreach (@points) {
    print "Lat:", $_->{"lat"}, ", Lon:", $_->{"lon"}, "\n";
  }

=head1 DESCRIPTION

This program was developed to be able to calculate the position between two GPS fixes using a 2-dimensional 3rd order polynomial spline.

  f(t)  = A + B(t-t0)  + C(t-t0)^2 + D(t-t0)^3 #position in X and Y
  f'(t) = B + 2C(t-t0) + 3D(t-t0)^2            #velocity in X and Y

I did some simple Math (for an engineer with a math minor) to come up with these formulas to calculate the unknowns from our knowns.

  A = x0                                     # when (t-t0)=0 in f(t)
  B = v0                                     # when (t-t0)=0 in f'(t)
  C = (x1-A-B(t1-t0)-D(t1-t0)^3)/(t1-t0)^2   # solve for C from f(t)
  C = (v1-B-3D(t1-t0)^2)/2(t1-t0)            # solve for C from f'(t)
  D = (v1(t1-t0)+B(t1-t0)-2x1+2A)/(t1-t0)^3  # equate C=C then solve for D

=cut

use strict;
use vars qw($VERSION);
use Geo::Constants qw{PI};
use Geo::Functions qw{deg_rad rad_deg round};

$VERSION = sprintf("%d.%02d", q{Revision: 0.16} =~ /(\d+)\.(\d+)/);

=head1 CONSTRUCTOR

=head2 new

  my $spline=Geo::Spline->new($p0, $p1);

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
  my $self = shift();
  $self->{'pt0'}=shift();
  $self->{'pt1'}=shift();
  my $ellipsoid=$self->ellipsoid("WGS84");
  my $dt=$self->{'pt1'}->{'time'} - $self->{'pt0'}->{'time'};
  die ("Delta time must be greater than zero.") if ($dt<=0);
  my ($A, $B, $C, $D)=$self->ABCD(
     $self->{'pt0'}->{'time'},
     $self->{'pt0'}->{'lat'} * $ellipsoid->polar_circumference / 360,
     $self->{'pt0'}->{'speed'} * cos(rad_deg($self->{'pt0'}->{'heading'})),
     $self->{'pt1'}->{'time'},
     $self->{'pt1'}->{'lat'} * $ellipsoid->polar_circumference / 360,
     $self->{'pt1'}->{'speed'} * cos(rad_deg($self->{'pt1'}->{'heading'})));
  $self->{'Alat'}=$A;
  $self->{'Blat'}=$B;
  $self->{'Clat'}=$C;
  $self->{'Dlat'}=$D;
  ($A, $B, $C, $D)=$self->ABCD(
     $self->{'pt0'}->{'time'},
     $self->{'pt0'}->{'lon'} * $ellipsoid->equatorial_circumference / 360,
     $self->{'pt0'}->{'speed'} * sin(rad_deg($self->{'pt0'}->{'heading'})),
     $self->{'pt1'}->{'time'},
     $self->{'pt1'}->{'lon'} * $ellipsoid->equatorial_circumference / 360,
     $self->{'pt1'}->{'speed'} * sin(rad_deg($self->{'pt1'}->{'heading'})));
  $self->{'Alon'}=$A;
  $self->{'Blon'}=$B;
  $self->{'Clon'}=$C;
  $self->{'Dlon'}=$D;
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

sub ABCD {
  my $self = shift();
  my $t0 = shift();
  my $x0 = shift();
  my $v0 = shift();
  my $t1 = shift();
  my $x1 = shift();
  my $v1 = shift();
  #x=f(t)=A+B(t-t0)+C(t-t0)^2+D(t-t0)^3
  #v=f'(t)=B+2C(t-t0)+3D(t-t0)^2
  #A=x0
  #B=v0
  #C=(x1-A-B(t1-t0)-D(t1-t0)^3)/((t1-t0)^2) # from f(t)
  #C=(v1-B-3D(t1-t0)^2)/2(t1-t0)            # from f'(t)
  #D=(v1t+Bt-2x1+2A)/t^3                    # from C=C
  my $A=$x0;
  my $B=$v0;
  #=(C3*(A3-A2)+B6*(A3-A2)-2*B3+2*B5)/(A3-A2)^3 # for Excel
  my $D=($v1*($t1-$t0)+$B*($t1-$t0)-2*$x1+2*$A)/($t1-$t0)**3;
  #=(B3-B5-B6*(A3-A2)-B8*(A3-A2)^3)/(A3-A2)^2   # for Excel
  my $C=($x1-$A-$B*($t1-$t0)-$D*($t1-$t0)**3)/($t1-$t0)**2;
  return($A,$B,$C,$D);
}

=head2 point

Method returns a single point from a single time.

  my $point=$spline->point($t1);
  my %point=$spline->point($t1);

=cut

sub point {
  my $self=shift();
  my $timereal=shift();
  my $ellipsoid=$self->ellipsoid;
  my $t=$timereal-$self->{'pt0'}->{'time'};
  my ($Alat, $Blat, $Clat, $Dlat)=($self->{'Alat'}, $self->{'Blat'},$self->{'Clat'},$self->{'Dlat'});
  my ($Alon, $Blon, $Clon, $Dlon)=($self->{'Alon'}, $self->{'Blon'},$self->{'Clon'},$self->{'Dlon'});
  my $lat=$Alat + $Blat * $t + $Clat * $t ** 2 + $Dlat * $t ** 3;
  my $lon=$Alon + $Blon * $t + $Clon * $t ** 2 + $Dlon * $t ** 3;
  my $vlat=$Blat + 2 * $Clat * $t + 3 * $Dlat * $t ** 2;
  my $vlon=$Blon + 2 * $Clon * $t + 3 * $Dlon * $t ** 2;
  my $speed=sqrt($vlat ** 2 + $vlon ** 2);
  my $heading=PI()/2 - atan2($vlat,$vlon);
  $heading=deg_rad($heading);
  $lat/=$ellipsoid->polar_circumference / 360;
  $lon/=$ellipsoid->equatorial_circumference / 360;
  my %pt=(time=>$timereal,
          lat=>$lat,
          lon=>$lon,
          speed=>$speed,
          heading=>$heading);
  return wantarray ? %pt : \%pt;
}

=head2 pointlist

Method returns a list of points from a list of times.

  my $list=$spline->pointlist($t1,$t2,$t3);
  my @list=$spline->pointlist($t1,$t2,$t3);

=cut

sub pointlist {
  my $self=shift();
  my @list=@_;
  @list=$self->timelist() if (scalar(@list)== 0);
  my @points=();
  foreach (@list) {
    push @points, {$self->point($_)};
  }
  return wantarray ? @points : \@points;
}

=head2 timelist

Method returns a list of times (n+1).  The default will return a list with an integer number of seconds between spline end points.

  my $list=$spline->timelist($samples); 
  my @list=$spline->timelist(); 

=cut

sub timelist {
  my $self=shift();
  my $t0=$self->{'pt0'}->{'time'};
  my $t1=$self->{'pt1'}->{'time'};
  my $dt=$t1-$t0;
  my $count=shift() || round($dt);
  my @list;
  foreach(0..$count) {
    my $t=$t0+$dt*($_/$count); 
    push @list, $t;
  }
  return wantarray ? @list : \@list;
}

1;

__END__

=head1 TODO

Integrate a better Lat, Lon to meter conversions.

=head1 BUGS

Please send to the geo-perl email list.

=head1 LIMITS

I use a very rough conversion from degrees to meters and then back.  It is accurate for short distances.

=head1 AUTHOR

Michael R. Davis qw/perl michaelrdavis com/

=head1 LICENSE

Copyright (c) 2006 Michael R. Davis (mrdvt92)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

http://search.cpan.org/src/MRDVT/Geo-Spline-0.16/doc/spline.xls
http://search.cpan.org/src/MRDVT/Geo-Spline-0.16/doc/spline.png
Math::Spline
Geo::Ellipsoids
