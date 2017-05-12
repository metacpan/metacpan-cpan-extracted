package Geo::Sun;
use strict;
use warnings;
use Astro::Coord::ECI::Sun;
use DateTime;
use Geo::Constants qw{PI};
use Geo::Functions qw{deg_rad};
use Geo::Ellipsoids;
use GPS::Point;

BEGIN {
    use vars qw($VERSION);
    $VERSION     = '0.04';
}

=head1 NAME

Geo::Sun - Calculates the Geodetic Position of the Sun over the Surface of the Earth

=head1 SYNOPSIS

  use Geo::Sun;
  my $gs=Geo::Sun->new;                              #isa Geo::Sun
  my $point=$gs->set_datetime(DateTime->now)->point; #Full OO interface
  printf "Point isa %s\n", ref($point);              #isa GPS::Point
  printf "Latitude: %s, Longitude: %s\n", $point->latlon;

=head1 DESCRIPTION

The Geo::Sun package calculates the position of the Sun over the Earth. The user method point_dt takes a L<DateTime> object as a parameter and returns a L<GPS::Point> which is the point on the earth where the Sun is directly over at the given time.

The Geo::Sun package is a wrapper around L<Astro::Coord::ECI::Sun> with a user friendly interface.

=head1 USAGE

  use Geo::Sun;
  my $gs=Geo::Sun->new;
  printf "Lat: %s, Lon: %s\n", $gs->point->latlon;

=head1 CONSTRUCTOR

=head2 new

  my $gs=Geo::Sun->new;

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
  my $self=shift;
  %$self=@_;
  $self->sun(Astro::Coord::ECI::Sun->new)
    unless ref($self->sun) eq "Astro::Coord::ECI::Sun";
  $self->ellipsoid(Geo::Ellipsoids->new)
    unless ref($self->ellipsoid) eq "Geo::Ellipsoids";
  if (defined $self->datetime) {
    $self->point_recalculate; #supports $gs->new(datetime=>$dt)
  } else {
    $self->datetime(DateTime->now)
  }
  $self->initialize2; #a hook if you need it
  return $self;
}

sub initialize2 {
  my $self=shift;
  return $self;
}

=head2 point

Returns a GPS::Point for the location of the sun at the current datetime.

  my $point=$gs->point;
  my $point=$gs->set_datetime(DateTime->now)->point;

=cut

sub point {
  my $self=shift;
  return $self->{'point'};
}

=head2 point_dt

Set the current datetime and returns a GPS::Point

  my $point=$gs->point_dt($datetime);

Implemented as

  my $point=$gs->set_datetime($datetime)->point;

=cut

sub point_dt {
  my $self=shift;
  return $self->set_datetime(@_)->point;
}

=head2 datetime

Sets or returns the current datetime which is a L<DateTime> object. The default is DateTime->now.

=cut

sub datetime {
  my $self = shift;
  if (@_) {
    $self->{"datetime"}=shift;
    $self->point_recalculate;
  }
  return $self->{"datetime"};
}

=head2 set_datetime

Sets datetime returns self

=cut

sub set_datetime {
  my $self=shift;
  $self->datetime(@_) if @_;
  return $self;
}

=head1 METHODS (INTERNAL)

=head2 point_recalculate

Recalculates the point when the DateTime is changed.

=cut

sub point_recalculate {
  my $self=shift;
  my $epoch=$self->datetime->clone->set_time_zone("UTC")->epoch;
  my ($psi, $lambda, $h) = $self->sun->universal($epoch)->geodetic;
  #speed is 2 pi distance from the polar axis to the surface
  #of the earth at latitude divided by 1 day (m/s)
  my $speed=2 * PI() * $self->ellipsoid->n_rad($psi) * cos($psi) / 24 / 60 / 60;
  $self->{'point'}=GPS::Point->new(
    time        => $self->sun->universal, #float seconds unix epoch (UTC)
    lat         => deg_rad($psi),         #signed decimal degrees
    lon         => deg_rad($lambda),      #signed decimal degrees
    alt         => $h * 1000,             #meters above the WGS-84 ellipsoid
    speed       => $speed, #is this right #meters/second (over ground)
    heading     => 270,  #need real value #degrees clockwise from North
    mode        => 3,                     #GPS mode 3-D
    tag         => "Geo::Sun",            #Name of the GPS message for data
  ); 
  $self->point_onchange; #a hook if you need it.
  return $self;
}

=head2 point_onchange

Override this method if you want to calculate something when the point changes

=cut

sub point_onchange {
  my $self=shift;
  return $self;
}

=head2 sun

Sets or returns the L<Astro::Coord::ECI::Sun> object.

  my $sun=$gs->sun;

=cut

sub sun {
  my $self=shift;
  $self->{'sun'}=shift if @_;
  return $self->{'sun'};
}

=head2 ellipsoid

Set or returns the L<Geo::Ellipsoids> object.

  my $ellipsoid=$gs->ellipsoid;  #WGS84

=cut

sub ellipsoid {
  my $self = shift();
  $self->{'ellipsoid'}=shift if (@_);
  return $self->{'ellipsoid'};
}

=head1 BUGS

Please send to the geo-perl email list.

=head1 SUPPORT

Try the geo-perl email list.

=head1 LIMITATIONS

Calculations are only good to about 3 decimal places.

=head1 AUTHOR

    Michael R. Davis
    CPAN ID: MRDVT
    STOP, LLC
    domain=>stopllc,tld=>com,account=>mdavis
    http://www.stopllc.com/

=head1 COPYRIGHT

This program is free software licensed under the...

	The BSD License

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

=cut

1;
