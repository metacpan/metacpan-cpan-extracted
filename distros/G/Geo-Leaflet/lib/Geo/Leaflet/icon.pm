package Geo::Leaflet::icon;
use strict;
use warnings;
use base qw{Package::New};
use JSON::XS;

our $VERSION = '0.02';
our $PACKAGE = __PACKAGE__;

=head1 NAME

Geo::Leaflet::icon - Leaflet icon object

=head1 SYNOPSIS

  use Geo::Leaflet;
  my $map = Geo::Leaflet->new;

=head1 DESCRIPTION

This package constructs a Leaflet icon object for use in a L<Geo::Leaflet::marker> object.

=head1 CONSTRUCTORS

=head2 new

=head1 PROPERTIES

=head2 name

=cut

sub name {
  my $self        = shift;
  $self->{'name'} = shift if @_;
  die("Error: $PACKAGE name required") unless defined $self->{'name'};
  die("Error: $PACKAGE name invaild variable name") unless $self->{'name'} =~ m/\A[a-z_][a-z0-9_]*\Z/i;
  return $self->{'name'};
}

=head2 options

=cut

sub options {
  my $self              = shift;
  $self->{'options'} = shift if @_;
  $self->{'options'} = {} unless $self->{'options'};
  die("Error: $PACKAGE options must be a hash") unless ref($self->{'options'}) eq 'HASH';
  return $self->{'options'};
}

=head1 METHODS

=head2 stringify

=cut

sub stringify {
  my $self    = shift;
  # var icon_name = L.icon({
  #          iconUrl: 'my-icon.png',
  #          iconSize: [38, 95],
  #          iconAnchor: [22, 94],
  #          popupAnchor: [-3, -76],
  #          shadowUrl: 'my-icon-shadow.png',
  #          shadowSize: [68, 95],
  #          shadowAnchor: [22, 94]
  #        }); 
  return sprintf(q{L.icon(%s);}, $self->JSON->encode($self->options));
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
