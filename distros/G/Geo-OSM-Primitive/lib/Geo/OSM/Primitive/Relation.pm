# Encoding and name #_{

=encoding utf8
=head1 NAME

Geo::OSM::Primitive::Relation - Abstract base class for the Open Street Map data primitive I<relation>.

=cut
package Geo::OSM::Primitive::Relation;
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

    my $osm_rel = new($osm_relation_id);

=cut

#_}

  my $class = shift;
  my $id    = shift;

  my $self = $class->SUPER::new($id, 'rel');

  croak "Wrong class $class" unless $self->isa('Geo::OSM::Primitive::Relation');

  return $self;

} #_}

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
