package Geo::Sun::Bearing;
use strict;
use warnings;
use Geo::Inverse 0.05; #GPS::Point->distance need array context
use base qw{Geo::Sun};

BEGIN {
    use vars qw($VERSION);
    $VERSION     = '0.04';
}

=head1 NAME

Geo::Sun::Bearing - Calculates the bearing from a station on the surface of the Earth to the Sun.

=head1 SYNOPSIS

  use Geo::Sun::Bearing;
  use GPS::Point;
  my $datetime=DateTime->now;
  my $station=GPS::Point->new(lat=>39, lon=>-77);
  my $gs=Geo::Sun::Bearing->new->set_datetime($datetime)->set_station($station);
  printf "Bearing from Station to Sun is %s\n", $gs->bearing;

=head1 DESCRIPTION

The Geo::Sun::Bearing is a L<Geo::Sun> object.  This package calculates the bearing from a station on the surface of the Earth to the point where the Sun is directly over at the given time.

=head1 USAGE

  use Geo::Sun::Bearing;
  my $gs=Geo::Sun::Bearing->new;

=head1 CONSTRUCTOR

=head2 new

  my $gs=Geo::Sun::Bearing->new; #Inherited from Geo::Sun
  my $gs=Geo::Sun::Bearing->new(datetime=>$dt, station=>$station);

=cut

sub initialize2 {
  my $self=shift;
  $self->bearing_recalculate if defined $self->station;
  $self->initialize3; #a hook if you need it
  return $self;
}

sub initialize3 {
  my $self=shift;
  return $self;
}

=head1 METHODS

Many methods are inherited from L<Geo::Sun>.

=head2 bearing

Returns the bearing from the station to the Sun.

=cut
 
sub bearing {
  my $self=shift;
  return $self->{'bearing'};
}

=head2 bearing_dt_pt

Returns bearing given a datetime and a station point.

  my $bearing=$gs->bearing_dt_pt($datetime, $station);

Implemented as

  my $bearing=$gs->set_datetime($datetime)->set_station($station)->bearing;

=cut

sub bearing_dt_pt {
  my $self=shift;
  my $datetime=shift;
  my $station=shift;
  return $self->set_datetime($datetime)->set_station($station)->bearing;
}

=head2 station

Sets or returns station. Station must be a valid point argument for L<GSP::Point> distance method. Currently, L<Geo::Point> and L<GPS::Point>. I'm planning to add {lat=>$lat, lon=>$lon} and [$lat, $lon] shortly.

=cut

sub station {
  my $self=shift;
  if (@_) {
    $self->{"station"}=shift;
    $self->bearing_recalculate;
  }
  return $self->{"station"};
}

=head2 set_station

Sets station returns self

=cut

sub set_station {
  my $self=shift;
  $self->station(@_) if @_;
  return $self;
}

=head1 METHODS (INTERNAL)

=head2 point_onchange

Overridden from Geo::Sun to recalculate the bearing when the point changes

=cut

sub point_onchange {
  my $self=shift;
  $self->bearing_recalculate if defined $self->station;
  return $self;
}

=head2 bearing_recalculate

Method which is called to recalculate the bearing when the datetime or the station is changed.

=cut

sub bearing_recalculate {
  my $self=shift;
  my (undef, $baz, undef) = $self->point->distance($self->station);
  $self->{'bearing'}=$baz;
  $self->bearing_onchange; #a hook if you need it
  return $self;
}

=head2 bearing_onchange

In this base module this does nothing but to return the object

Override this function if you want to calculate something when the bearing changes. By nature this hook also gets called when point_onchange is called so don't override both.

=cut

sub bearing_onchange {
  my $self=shift;
  return $self;
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
