package Geo::Leaflet::Base;
use strict;
use warnings;
use base qw{Package::New};
use JSON::XS;

our $VERSION = '0.03';
our $PACKAGE = __PACKAGE__;

=head1 NAME

Geo::Leaflet::Base - Leaflet base object

=head1 SYNOPSIS

  use Geo::Leaflet;
  my $map = Geo::Leaflet->new;

=head1 DESCRIPTION

This package provides a base package for L<Geo::Leaflet> map objects.

=head1 CONSTRUCTORS

=head2 new
 
=head1 PROPERTIES

=head2 options

=cut

sub options {
  my $self              = shift;
  $self->{'options'} = shift if @_;
  $self->{'options'} = {} unless $self->{'options'};
  die("Error: options must be a hash") unless ref($self->{'options'}) eq 'HASH';
  return $self->{'options'};
}

=head1 METHODS

=head2 stringify_base

=cut

sub stringify_base {
  my $self    = shift;
  my $value   = shift;
  #const tiles = L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
  #                  maxZoom: 19,
  #                  attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
  #                 }).addTo(map);
  #
  #const circle = L.circle([51.508, -0.11], {
  #                                          color: 'red',
  #                                          fillColor: '#f03',
  #                                          fillOpacity: 0.5,
  #                                          radius: 500
  #                                         }).addTo(map);
  my $class   = ref($self); #e.g., Geo::Leaflet::circle
  $class      =~ s/.*:://;  #e.g., "circle"
  my $addmap  = '.addTo(map)';
  my $popup   = $self->can('popup')   && $self->popup   ? sprintf('.bindPopup(%s)',   $self->JSON->encode($self->popup))   : '';
  my $tooltip = $self->can('tooltip') && $self->tooltip ? sprintf('.bindTooltip(%s)', $self->JSON->encode($self->tooltip)) : '';
  return sprintf(q{L.%s(%s, %s)%s%s%s;},
                 $class,
                 $self->JSON->encode($value),
                 $self->JSON->encode($self->options),
                 $addmap,
                 $popup,
                 $tooltip,
                );
}

=head2 JSON

=cut

sub JSON {
  my $self        = shift;
  $self->{'JSON'} = JSON::XS->new->allow_nonref;
  return $self->{'JSON'};
}

=head1 SEE ALSO

=head1 AUTHOR

Michael R. Davis

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Michael R. Davis

MIT LICENSE

=cut

1;
