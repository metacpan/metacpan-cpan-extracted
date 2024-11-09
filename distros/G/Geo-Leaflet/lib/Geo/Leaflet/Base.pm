package Geo::Leaflet::Base;
use strict;
use warnings;
use base qw{Package::New};
use JSON::XS;

our $VERSION = '0.01';
our $PACKAGE = __PACKAGE__;

=head1 NAME

Geo::Leaflet::Base - Generates Leaflet web page

=head1 SYNOPSIS

  use Geo::Leaflet;
  my $map = Geo::Leaflet->new;

=head1 DESCRIPTION

Geo::Leaflet object base package.

=head1 CONSTRUCTORS

=head2 new
 
=head1 PROPERTIES

=head2 properties

=cut

sub properties {
  my $self              = shift;
  $self->{'properties'} = shift if @_;
  $self->{'properties'} = {} unless $self->{'properties'};
  die("Error: properties must be a hash") unless ref($self->{'properties'}) eq 'HASH';
  $self->{'properties'}->{'radius'} = $self->{'radius'} if defined $self->{'radius'};
  return $self->{'properties'};
}

=head2 popup

=cut

sub popup {
  my $self         = shift;
  $self->{'popup'} = shift if @_; 
  return $self->{'popup'};
}

=head1 METHODS

=head2 stringify_base

=cut

sub stringify_base {
  my $self   = shift;
  my $encode = shift;
  #const circle3 = L.circle([51.508, -0.11], {
  #                                           color: 'red',
  #                                           fillColor: '#f03',
  #                                           fillOpacity: 0.5,
  #                                           radius: 500
  #                                          }).addTo(map);
  my $class  = ref($self); #e.g., Geo::Leaflet::circle
  $class     =~ s/.*:://;    #e.g., "circle"
  my $addmap = '.addTo(map)';
  my $popup  = $self->popup ? sprintf(".bindPopup('%s')", $self->popup) : '';
  return sprintf(q{L.%s(%s, %s)%s%s;}, $class, $self->JSON->encode($encode), $self->JSON->encode($self->properties), $addmap, $popup);
}

=head2 JSON

=cut

sub JSON {
  my $self        = shift;
  $self->{'JSON'} = JSON::XS->new;
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
