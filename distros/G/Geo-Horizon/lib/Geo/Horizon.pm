package Geo::Horizon;
use Math::Trig qw{acos};

=head1 NAME

Geo::Horizon - Calculate distance to the visual horizon

=head1 SYNOPSIS

  use Geo::Horizon;
  my $gh = Geo::Horizon->new("WGS84");
  my $lat=39;
  my $alt=1.7;
  my $distance_to_horizon=$gh->distance($alt,$lat);
  print "Input Lat: $lat1\n";
  print "Output Distance: $dist\n";

=head1 DESCRIPTION

A perl object for calculating the distance to the visual horizon on an ellipsoid.

=cut

use strict;
use vars qw($VERSION);
$VERSION = sprintf("%d.%02d", q{Revision: 0.02} =~ /(\d+)\.(\d+)/);

=head1 CONSTRUCTOR

=head2 new

  my $gh = Geo::Horizon->new(); #default WGS84

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
  $self->ellipsoid(shift);
}

=head2 ellipsoid

Method to set or retrieve the current ellipsoid object.  The ellipsoid is a L<Geo::Ellipsoids> object.

  my $ellipsoid=$gh->ellipsoid;  #Default is WGS84

  $gh->ellipsoid('Clarke 1866'); #Built in ellipsoids from Geo::Ellipsoids
  $gh->ellipsoid({a=>1});        #Custom Sphere 1 unit radius

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

=head2 distance

The straight-line of sight distance to the horizon: This formula does not take in account radio or optical refraction which will be further the longer the wavelength.

  my $dist=$obj->distance($alt, $lat);  #alt in meters (ellipsoid units)
                                        #lat in signed decimal degrees
  my $dist=$obj->distance($alt);        #default lat => 0 (equator)
  my $dist=$obj->distance;              #default alt => 1.7

Formula from http://newton.ex.ac.uk/research/qsystems/people/sque/physics/horizon/

  Ds = sqrt(h(2R + h))

=cut

sub distance {
  my $self=shift();
  my $alt=shift();    #usually meters but actaully ellipsoid units
  $alt=1.7 unless defined $alt; 
  my $lat=shift() || 0;     #degrees
  #Geometric Mean (http://mentorsoftwareinc.com/CC/gistips/TIPS0899.HTM)
  my $R=sqrt($self->ellipsoid->n($lat) * $self->ellipsoid->rho($lat));
  return sqrt($alt * (2 * $R + $alt));
}

=head2 distance_great_circle

The curved distance along the ellipsoid to the horizon:  This is the great circle distance from the track point snapped to the ellipsoid to the visual horizon of the observer.

  my $dist=$obj->distance_great_circle($alt, $lat);
  my $dist=$obj->distance_great_circle($alt);  #default lat => 0
  my $dist=$obj->distance_great_circle();      #default alt => 1.7

Formula from http://newton.ex.ac.uk/research/qsystems/people/sque/physics/horizon/

  Dc = R acos(R / (R + h))

=cut

sub distance_great_circle {
  my $self=shift();
  my $alt=shift();    #usually meters but actaully ellipsoid units
  $alt=1.7 unless defined $alt; 
  my $lat=shift() || 0;      #degrees
  my $R=sqrt($self->ellipsoid->n($lat) * $self->ellipsoid->rho($lat));
  return $R * acos($R / ($R + $alt));
}

1;

__END__

=head1 TODO

=head1 BUGS

Please send to the geo-perl email list.

=head1 LIMITS

=head1 AUTHOR

Michael R. Davis qw/perl michaelrdavis com/

=head1 LICENSE

Copyright (c) 2006 Michael R. Davis (mrdvt92)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

Geo::Ellipsoids
Math::Trig
