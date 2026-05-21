package Geo::Leaflet::Rectangle;
use strict;
use warnings;
use base qw{Geo::Leaflet::Objects};

our $VERSION = '0.04';
our $PACKAGE = __PACKAGE__;

=head1 NAME

Geo::Leaflet::Rectangle - Leaflet rectangle object

=head1 SYNOPSIS

  use Geo::Leaflet;
  my $map       = Geo::Leaflet->new;
  my $rectangle = $map->rectangle(
                                  llat    => $llat,
                                  llon    => $llon,
                                  ulat    => $ulat,
                                  ulon    => $ulon,
                                  options => {},
                                 );

=head1 DESCRIPTION

This package constructs a Leaflet rectangle object for use on a L<Geo::Leaflet> map.

=head1 PROPERTIES

=head2 llat

=cut

sub llat {
  my $self       = shift;
  $self->{'llat'} = shift if @_;
  die("Error: llat required") unless defined $self->{'llat'};
  return $self->{'llat'};
}

=head2 llon

=cut

sub llon {
  my $self       = shift;
  $self->{'llon'} = shift if @_;
  die("Error: llon required") unless defined $self->{'llon'};
  return $self->{'llon'};
}

=head2 ulat

=cut

sub ulat {
  my $self       = shift;
  $self->{'ulat'} = shift if @_;
  die("Error: ulat required") unless defined $self->{'ulat'};
  return $self->{'ulat'};
}

=head2 ulon

=cut

sub ulon {
  my $self       = shift;
  $self->{'ulon'} = shift if @_;
  die("Error: ulon required") unless defined $self->{'ulon'};
  return $self->{'ulon'};
}

=head2 options

=head2 popup

=head1 METHODS

=head2 stringify

=cut

sub _method_name {'rectangle'};

sub stringify {
  my $self = shift;
  #L.rectangle([[54.559322, -5.767822], [56.1210604, -3.021240]], {color: "#ff7800", weight: 1}).addTo(map);
  return $self->stringify_base([[$self->llat, $self->llon], [$self->ulat, $self->ulon]]);
}

=head1 SEE ALSO

=head1 AUTHOR

Michael R. Davis

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Michael R. Davis

MIT LICENSE

=cut

1;
