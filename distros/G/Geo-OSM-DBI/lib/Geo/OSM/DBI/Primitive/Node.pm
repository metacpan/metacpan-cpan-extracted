# Encoding and name #_{

=encoding utf8
=head1 NAME

Geo::OSM::DBI::Primitive::Node - Derivation of L<< Geo::OSM::Primitive::Node >> and L<<Geo::OSM::DBI::Primitive >>, to be used with L<< Geo::OSM::DBI >>.

=cut
package Geo::OSM::DBI::Primitive::Node;
#_}
#_{ use …
use warnings;
use strict;

use utf8;
use Carp;

use Geo::OSM::Primitive::Node;
our @ISA=qw(Geo::OSM::Primitive::Node Geo::OSM::DBI::Primitive);

#_}
our $VERSION = 0.01;
#_{ Synopsis

=head1 SYNOPSIS

    …

=cut
#_}
#_{ Overview

=head1 OVERVIEW

…

=cut

#_}
#_{ Methods

=head1 METHODS
=cut

sub new { #_{
#_{ POD

=head2 new

    my $osm_dbi = Geo::OSM::DBI->new(…);

    new($osm_way_id, $osm_dbi, $lat, $lon);

=cut

#_}

  my $class   = shift;
  my $id      = shift;
  my $osm_dbi = shift;
  my $lat     = shift;
  my $lon     = shift;

  my $self = $class->SUPER::new($id, $lat, $lon);

  croak "not a Geo::OSM::DBI::Primitive::Node" unless $self -> isa('Geo::OSM::DBI::Primitive::Node');

  $self->_init_geo_osm_dbi_primitive($osm_dbi);

  return $self;

} #_}
#_}
#_{ POD: Copyright and license

=head1 COPYRIGHT and LICENSE

Copyright © 2017 René Nyffenegger, Switzerland. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at: L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

#_}
#_{ POD: Source Code

=head1 SOURCE CODE

The source code is on L<< github|https://github.com/ReneNyffenegger/perl-Geo-OSM-DBI >>. Meaningful pull requests are welcome.

=cut

#_}
