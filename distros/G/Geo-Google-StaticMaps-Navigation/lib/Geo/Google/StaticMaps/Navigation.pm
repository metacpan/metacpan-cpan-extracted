package Geo::Google::StaticMaps::Navigation;
use strict;
use warnings;
use base 'Geo::Google::StaticMaps';
use Carp;
use Geo::Mercator;
our $VERSION = '0.03';

our $DEGREE_PER_PIXEL_ON_ZOOM_3 = 60/342;

sub _clone {
    my ($self) = @_;
    __PACKAGE__->new(%$self);
}

sub north {$_[0]->nearby({lat => 1})};
sub south {$_[0]->nearby({lat => -1})};
sub east {$_[0]->nearby({lng => 1})};
sub west {$_[0]->nearby({lng => -1})};
sub zoom_in {$_[0]->scale(1)}
sub zoom_out {$_[0]->scale(-1)}

sub pageurl {
    my ($self, $old_uri) = @_;
    my %orig = $old_uri->query_form;
    my $uri = $old_uri->clone;
    $uri->query_form(
        {
            %orig,
            lat => $self->{center}->[0],
            lng => $self->{center}->[1],
            zoom => $self->{zoom},
        }
    );
    return $uri;
}

sub nearby {
    my ($self, $args) = @_;
    my $clone = $self->_clone;
    croak "zoom parameter is required" unless defined $clone->{zoom};
    $clone->{center} = _next_latlng(
        $clone->{center}->[0],
        $clone->{center}->[1],
        _degree($clone->{size}->[1], $clone->{zoom}) * ($args->{lat} || 0),
        _degree($clone->{size}->[0], $clone->{zoom}) * ($args->{lng} || 0),
    );
    return $clone;
}

sub scale {
    my ($self, $arg) = @_;
    my $clone = $self->_clone;
    croak "zoom parameter is required" unless defined $clone->{zoom};
    $clone->{zoom} += $arg;
    return $clone;
}

sub _degree {
    my ($size, $zoom) = @_;
    return $size * $DEGREE_PER_PIXEL_ON_ZOOM_3 * ( 2 ** (3 - $zoom));
}

sub _next_latlng {
    my ($lat, $lng, $move_lat, $move_lng) = @_;
    my $move_y = [ mercate($move_lat, 0) ]->[1] - [ mercate(0,0) ]->[1];
    my ($x, $y) = mercate($lat, $lng);
    my ($new_lat) = demercate($x, $y+$move_y);
    return [ 
        $new_lat,
        $lng + $move_lng,
    ];
}

1;
__END__

=head1 NAME

Geo::Google::StaticMaps::Navigation - generates pagers for Google Static Maps

=head1 SYNOPSIS

  use Geo::Google::StaticMaps::Navigation;

  my $map = Geo::Google::StaticMaps::Navigation->new(
    key    => "your Google Maps API key",
    size   => [ 500, 400 ],
    center => [ 35.683, 139.766 ], # tokyo station
    zoom   => 9,
  );

  my $north_map_url = $map->north->url;

  # see Geo::Google::StaticMaps for detailed informations
  # of the constructor and the url method.

  my $uri = URI->new('http://example.com/map');
  my $north_map_pageurl = $map->north->pageurl($uri);

  # returns URI for next page with the map on the north like:
  # http://example.com/map?lat=36.5666495508921&lng=139.766&zoom=9

=head1 DESCRIPTION

Geo::Google::StaticMaps::Navigation generates pagers and nearby map urls
for given Google Static Map informations.

=head1 METHODS

=head2 north, south, west, east

returns nearby map object for each direction.

=head2 zoom_in, zoom_out

returns zoomed map.

=head2 pageurl($old_uri)

returns URI object with query parameters for the map containing lat, lng, zoom.

=head2 nearby({lat => $move_rate, lng => $move_rate})

returns nearby map. $map->nearby({lat => 1}) is identical to 
$map->north, and $map->nearby({lng => -1}) is $map->west.

=head2 scale($zoom_delta)

returns zoomed map with given delta. $map->scale( 1 ) is identical 
to $map->zoom_in, and $map->scale( -1 ) is $map->soom_out.

=head1 AUTHOR

Nobuo Danjou E<lt>nobuo.danjou@gmail.comE<gt>

=head1 SEE ALSO

L<Geo::Google::StaticMaps>

L<Geo::Mercator>

L<http://code.google.com/apis/maps/documentation/staticmaps/>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
