package Geo::Leaflet::DivIcon;
use strict;
use warnings;
use base qw{Geo::Leaflet::Icon};

our $VERSION = '0.04';
our $PACKAGE = __PACKAGE__;

=head1 NAME

Geo::Leaflet::DivIcon - Leaflet HTML/CSS icon object

=head1 SYNOPSIS

  use Geo::Leaflet;
  my $map = Geo::Leaflet->new;

=head1 DESCRIPTION

This package constructs a Leaflet divIcon object for use in a L<Geo::Leaflet::Marker> object.

=head1 CONSTRUCTORS

=head2 new

=head1 PROPERTIES

=head2 name

=cut

#from parent icon

=head2 icon_set

  $icon->icon_set('fa'); #Font Awesome v4.7

=cut

sub icon_set {
  my $self            = shift;
  $self->{'icon_set'} = shift if @_;
  $self->{'icon_set'} = 'fa' unless defined $self->{'icon_set'};
  return $self->{'icon_set'};
}

=head2 icon_name

  $icon->icon_name('bicycle');

See: https://fontawesome.com/v4/icons/

=cut

sub icon_name {
  my $self             = shift;
  $self->{'icon_name'} = shift if @_;
  return $self->{'icon_name'};
}

=head2 icon_font_size


  $icon->icon_name(48);

Default: 48

=cut

sub icon_font_size {
  my $self                  = shift;
  $self->{'icon_font_size'} = shift if @_;
  $self->{'icon_font_size'} = 48 unless defined $self->{'icon_font_size'};
  return $self->{'icon_font_size'};
}

=head2 

=head2 options

=cut

sub options {
  my $self           = shift;
  $self->{'options'} = shift if @_;
  $self->{'options'} = {} unless $self->{'options'};
  die("Error: $PACKAGE options must be a hash") unless ref($self->{'options'}) eq 'HASH';

  #This override removes the white square background from the icon
  $self->{'options'}->{'className'} = 'leaflet-div-icon-override' unless defined $self->{'options'}->{'className'};

  #This fa helper autobuilds html from icon_name alone
  unless (defined $self->{'options'}->{'html'}) {
    if ($self->icon_set eq 'fa' and defined($self->icon_name)) {
      my $style = sprintf("font-size:%dpx", $self->icon_font_size);
      my $class = sprintf("fa fa-%s", $self->icon_name); #TODO: figure out if fa-fw: fixed width is better here
      my $html  = qq{<i class=\"$class\" style=\"$style\"></i>};
      $self->{'options'}->{'html'} = $html;
    }
  }
  unless (defined $self->{'options'}->{'iconAnchor'}) {
    my $center = $self->icon_font_size / 2; #this assumes square icons
    $self->{'options'}->{'iconAnchor'} = [$center, $center]; #this is a pain!!!
  }
  die("Error: Either the html property in options or the icon_name is required") unless $self->{'options'}->{'html'}; 
  return $self->{'options'};
}

=head1 METHODS

=head2 stringify

=cut

sub _method_name {'divIcon'};

#see parent icon

=head2 JSON

=cut

#from parent icon

=head1 SEE ALSO

=head1 AUTHOR

Michael R. Davis

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Michael R. Davis

MIT LICENSE

=cut

1;
