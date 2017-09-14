# Encoding and name #_{

=encoding utf8
=head1 NAME

Geo::OSM::Primitive::Node - Abstract base class for the Open Street Map data primitive I<node>.

=cut
package Geo::OSM::Primitive::Node;
our @ISA = qw(Geo::OSM::Primitive);
#_}
#_{ use …
use warnings;
use strict;

use utf8;
use Carp;
use Geo::OSM::Primitive;

#_}
our $VERSION = 0.01;
#_{ Synopsis

=head1 SYNOPSIS

    …

=cut
#_}
#_{ Overview

=head1 OVERVIEW

The idea is to encapsulte methods that use OpenStreetMap data (that is possibly stored in L<Geo::OSM::DBI>.

=cut

#_}
#_{ Methods

=head1 METHODS
=cut

sub new { #_{
#_{ POD

=head2 new

    my $osm_node = Geo::OSM::Primitive::Node->new($osm_node_id, $lat, $lon);

=cut

#_}

  my $class = shift;
  my $id    = shift;
  my $lat   = shift;
  my $lon   = shift;

  my $self = $class->SUPER::new($id, 'nod');

  croak "Wrong class $class" unless $self->isa('Geo::OSM::Primitive::Node');

# TODO: use _set_cache_lat_lon ?
  $self->{lat} = $lat;
  $self->{lon} = $lon;

  return $self;

} #_}
sub lat { #_{
#_{ POD

=head2 lat

    my $lat = $node->lat();

Return the lattitude of the node.

=cut

#_}

  my $self = shift;
  return $self->{lat};

} #_}
sub lon { #_{
#_{ POD

=head2 lon

    my $lon = $node->lon();

Return the longitude of the node.

=cut

#_}

  my $self = shift;
  return $self->{lon};

} #_}
# todo sub _set_cache_lat_lon { #_{
# todo #_{ POD
# todo 
# todo =head2 _set_cache_lat_lon
# todo 
# todo     my $lat = …;
# todo     my $lon = …;
# todo     $node->_set_cache_lat_lon($lat, $lon);
# todo 
# todo Set the node's lattitude and longitude in its cache.
# todo 
# todo This method is internal and should not be called from a user of C<Geo::OSM::DBI>.
# todo 
# todo =cut
# todo 
# todo #_}
# todo 
# todo   my $self = shift;
# todo   my $lat  = shift;
# todo   my $lon  = shift;
# todo 
# todo 
# todo   $self->{cache}->{lat} = $lat;
# todo   $self->{cache}->{lon} = $lon;
# todo 
# todo } #_}

#_}
#_{ POD: Copyright

=head1 Copyright
Copyright © 2017 René Nyffenegger, Switzerland. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at: L<http://www.perlfoundation.org/artistic_license_2_0>
=cut

#_}
#_{ POD: Source Code

=head1 Source Code

The source code is on L<< github|https://github.com/ReneNyffenegger/perl-Geo-OSM-Primitive >>. Meaningful pull requests are welcome.

=cut

#_}

'tq84';
