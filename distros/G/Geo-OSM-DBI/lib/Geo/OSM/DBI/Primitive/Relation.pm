# Encoding and name #_{

=encoding utf8
=head1 NAME

Geo::OSM::DBI::Primitive::Relation - Derivation of L<< Geo::OSM::Primitive::Relation >> and L<<Geo::OSM::DBI::Primitive >>, to be used with L<< Geo::OSM::DBI >>.

=cut
package Geo::OSM::DBI::Primitive::Relation;
#_}
#_{ use …
use warnings;
use strict;

use utf8;
use Carp;

# use Geo::OSM::Primitive;
use Geo::OSM::Primitive::Relation;
use Geo::OSM::DBI::Primitive;
use Geo::OSM::DBI::Primitive::Node;
use Geo::OSM::DBI::Primitive::Way;
our @ISA=qw(Geo::OSM::Primitive::Relation Geo::OSM::DBI::Primitive);

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

    new($osm_relation_id, $osm_dbi);

=cut

#_}

  my $class   = shift;
  my $id      = shift;
  my $osm_dbi = shift;

  my $self = $class->SUPER::new($id);

  croak "not a Geo::OSM::DBI::Primitive::Relation" unless $self -> isa('Geo::OSM::DBI::Primitive::Relation');

  $self->_init_geo_osm_dbi_primitive($osm_dbi);

  return $self;

} #_}
sub members { #_{
#_{ POD

=head2 members

    my @members = $rel->members();

Returns the members of the relation. The returned elements are hashes with
the keys C<rol> (role of the member) and C<mem> (the member itself,
a L<node|Geo::OSM::DBI::Primitive::Node>, L<way|Geo::OSM::DBI::Primitive::Way> or
a L<relation|Geo::OSM::DBI::Primitive::Relation>.

     my $elem = shift @members;
     my $primitive = $elem->{mem};
     my $role      = $elem->{rol};

=cut

#_}

  my $self = shift;

  my $sth = $self->{osm_dbi}->{dbh}->prepare( #_{
"   select
      rm.nod_id,
      rm.way_id,
      rm.rel_id,
      rm.rol
    from
      rel_mem rm
    where
      rm.rel_of = ?
    order by
      order_
") or croak; #_}

  $sth->execute($self->{id});
  my @ret;
  while (my $r = $sth->fetchrow_hashref) { #_{

    my $elem;

    if     (defined $r->{nod_id}) { $elem = Geo::OSM::DBI::Primitive::Node    ->new($r->{nod_id}, $self->{osm_dbi}) }
    elsif  (defined $r->{way_id}) { $elem = Geo::OSM::DBI::Primitive::Way     ->new($r->{way_id}, $self->{osm_dbi}) }
    elsif  (defined $r->{rel_id}) { $elem = Geo::OSM::DBI::Primitive::Relation->new($r->{rel_id}, $self->{osm_dbi}) }
    else   {die "Neither nod_id, nor way_id, nor rel_id defined"};

    $elem->_set_cache_role($self, $r->{rol});

    push @ret, $elem;

  } #_}

  return @ret;
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
