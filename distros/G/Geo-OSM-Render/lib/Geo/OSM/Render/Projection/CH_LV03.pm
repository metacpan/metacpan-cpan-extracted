# Encoding and name #_{

=encoding utf8
=head1 NAME

Geo::OSM::Render::Projection::CH_LV03 - Project OSM latitudes and longitudes (preferrably within the area of Switzerland) into LV03 (»Landesvermessung 03«) x, y coordinate pairs to be rendered by L<Geo::OSM::Render>.

=cut
package Geo::OSM::Render::Projection::CH_LV03;
#_}
#_{ use …
use warnings;
use strict;

use utf8;
use Carp;
use Geo::OSM::Render::Projection;
use Geo::Coordinates::Converter::LV03 qw(lat_lng_2_y_x);
our @ISA = qw(Geo::OSM::Render::Projection);

#_}
our $VERSION = 0.01;
#_{ Synopsis

=head1 SYNOPSIS

This class derives from L<<Geo::OSM::Render::Projection>> and uses
L<< Geo::Coordinates::Converter::LV03 >> for the conversion.

=cut
#_}
#_{ Overview

=head1 OVERVIEW

See L<Geo::OSM::Render::Projection/OVERVIEW>.

=cut

#_}
#_{ Methods
#_{ POD
=head1 METHODS
=cut
#_}
sub new { #_{
#_{ POD

=head2 new

    my $proj = Geo::OSM::Render::Projection::CH_LV03->new();


=cut

#_}

  my $class = shift;
  my $self  = $class->SUPER::new();
  return $self;

} #_}
sub lat_lon_to_x_y { #_{
#_{ POD

=head2 lat_lon_to_x_y

    my ($x, $y) = $projection->lat_lon_to_x_y($lat, $lon);

=cut

#_}

  my $self = shift;

  return lat_lng_2_y_x(@_);

} #_}
#_}
#_{ POD: Author

=head1 AUTHOR

René Nyffenegger <rene.nyffenegger at adp-gmbh.ch>

=cut

#_}
#_{ POD: Copyright and License

=head1 COPYRIGHT AND LICENSE
Copyright © 2017 René Nyffenegger, Switzerland. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at: L<http://www.perlfoundation.org/artistic_license_2_0>
=cut

#_}
#_{ POD: Source Code

=head1 Source Code

The source code is on L<< github|https://github.com/ReneNyffenegger/perl-Geo-OSM-Render >>. Meaningful pull requests are welcome.

=cut

#_}

'tq84';
