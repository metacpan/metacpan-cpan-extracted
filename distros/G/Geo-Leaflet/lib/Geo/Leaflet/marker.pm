package Geo::Leaflet::marker;
use strict;
use warnings;
use base qw{Geo::Leaflet::Objects};

our $VERSION = '0.02';
our $PACKAGE = __PACKAGE__;

=head1 NAME

Geo::Leaflet::marker - Leaflet marker object

=head1 SYNOPSIS

  use Geo::Leaflet;
  my $map    = Geo::Leaflet->new;
  my $marker = $map->marker(
                            lat => $lat,
                            lon => $lon,
                           );

=head1 DESCRIPTION

This package constructs a Leaflet marker object for use on a L<Geo::Leaflet> map.

=head1 PROPERTIES

=head2 lat

=cut

sub lat {
  my $self       = shift;
  $self->{'lat'} = shift if @_;
  die("Error: lat required") unless defined $self->{'lat'};
  return $self->{'lat'};
}

=head2 lon

=cut

sub lon {
  my $self       = shift;
  $self->{'lon'} = shift if @_;
  die("Error: lon required") unless defined $self->{'lon'};
  return $self->{'lon'};
}

=head2 options

=head2 popup

=head1 METHODS

=head2 stringify

=cut

sub stringify {
  my $self    = shift;
  my $options = $self->options;
  my $value   = shift;
  #const object6 = L.marker([51.498,-0.09],
  #                         {"icon":paddle_1})
  #                .addTo(map).bindPopup("marker icon popup").bindTooltip("marker icon tooltip");
  my $class   = 'marker';
  my $addmap  = '.addTo(map)';
  my $popup   = $self->popup   ? sprintf('.bindPopup(%s)',   $self->JSON->encode($self->popup))   : '';
  my $tooltip = $self->tooltip ? sprintf('.bindTooltip(%s)', $self->JSON->encode($self->tooltip)) : '';
  return sprintf(q{L.%s(%s, %s)%s%s%s;},
                 $class,
                 $self->JSON->encode([$self->lat, $self->lon]),
                 $self->_hash_to_json($self->options),
                 $addmap,
                 $popup,
                 $tooltip,
                );
}

#head2 _hash_to_json
#
#Custom JSON encoder!  Unfortunately, no Perl encoders support function name encoding as needed here for "icon" keys
#
#cut

sub _hash_to_json {
  my $self   = shift;
  my $hash   = shift;
  my $string = ''; 
  foreach my $key (keys %$hash) {
    my $value = $hash->{$key};
    if ($key eq "icon") {
      $string = $string . join(':', $self->JSON->encode($key), $value); #function name encoding is not supported by any perl package!
    } else {
      $string = $string . join(':', $self->JSON->encode($key), $self->JSON->encode($value));
    }
  }
  return "{$string}";
}

=head1 SEE ALSO

=head1 AUTHOR

Michael R. Davis

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Michael R. Davis

MIT LICENSE

=cut

1;
