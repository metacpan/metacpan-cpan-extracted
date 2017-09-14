# Encoding and name #_{

=encoding utf8
=head1 NAME

Geo::OSM::Primitive - Abstract base classes for the three Open Street Map primitives: L<node|Geo::OSM::Primitive::Node>, L<way|Geo::OSM::Primitive::Way> and L<relation|Geo::OSM::Primitive::Relation>.

=cut
package Geo::OSM::Primitive;
#_}
#_{ use …
use warnings;
use strict;

use utf8;
use Carp;

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

    new($osm_id, $primitive_type);

=cut

#_}

  my $class = shift;
  my $id    = shift;
  my $type  = shift;

  my $self = {};
  bless $self, $class;


  croak "Wrong class $class" unless $self->isa('Geo::OSM::Primitive');
  croak "id $id is not an integer" if ref($id) or int($id) != $id;

  $self->{id} = $id;
  $self->{primitive_type} = $type;

  return $self;

} #_}
sub primitive_type { #_{
#_{ POD

=head2 primitive_type

    my $type = $osm_primitive->primitive_type();

    if ($type eq 'way') {
       …
    }
    elsif ($type eq 'nod') {
       …
    }
    elsif ($type eq 'rel') {
       …
    }

Returns the type of the primitive: C<'nod'> (I<sic!>) if the primitive is a L<<node|Geo::OSM::Primitive::Node>>,
C<'way'> if the primitive is a L<<way|Geo::OSM::Primitive::Way>> or C<'rel'> if the primitive is
a L<<relation|Geo::OSM::Primitive::Relation>>.

=cut

#_}

  my $self=shift;

  return $self->{primitive_type};

} #_}
sub member_of { #_{
#_{ POD

=head2 member_of

    if ($osm_primitive->member_of($rel)) { …
    }

Tests whether the primitive is a member of the L<relation|Geo::OSM::Primitive::Relation> C<$rel>.
(B<TODO>: currently only checks the cache. If the membership is not found in the cache, it is not
further checked for its existence. That should of course be fixed once).

=cut

#_}

  my $self = shift;
  my $rel  = shift;

  croak unless $rel->isa('Geo::OSM::Primitive::Relation');

  return $self->{cache}->{member_of}->{$rel->{id}};
} #_}
sub role { #_{

#_{ POD

=head2 role

    my $role = $osm_primitive->role($osm_relation);

Returns the role of C<$osm_relation> in L<<relation|Geo::OSM::Primitive::Relation>> C<<$osm_relation>>.
(B<TODO>: currently only works if the role had been set with L</_set_cache_role>. Of course, the role
should also be found if it is not in the cache.).


=cut

#_}


  my $self = shift;
  my $rel  = shift;

  croak unless $rel->isa('Geo::OSM::Primitive::Relation');

  return undef unless $self->member_of($rel);

  if (exists $self->{cache}->{member_of}->{$rel->{id}}->{rol}) {
    return $self->{cache}->{member_of}->{$rel->{id}}->{rol};
  }

  return undef;


} #_}
sub _set_cache_role { #_{
#_{ POD

=head2 _set_cache_role

    my $role = 'outer';
    $osm_primitive->_set_cache_role($osm_relation, $role);

This method assumes that the primitive on which it is called is a member of C<< $osm_relation >> (which must
be a L<Geo::OSM::Primitive::Relation>) and that the role (which is a string) is C<< $role >>.

This method is internal and should not be called from a user of C<Geo::OSM::DBI>.

=cut

#_}

  my $self = shift;
  my $rel  = shift;
  my $rol  = shift;

  croak "Relation expected unless " unless $self->isa('Geo::OSM::Primitive');

  $self->{cache}->{member_of}->{$rel->{id}}->{rol}=$rol;

} #_}

#_}
#_{ POD: Author

=head1 AUTHOR

René Nyffenegger

=cut

#_}
#_{ POD: See also

=head1 SEE ALSO

L<Geo::OSM::Render> is a base class to render osm data. L<Geo::OSM::Render::SVG> is a derivation of that base class to
render SVG files.

L<Geo::OSM::DBI> can be used to store Open Street Map data in a database. (It should be database independant (hence DBI), yet currently, it probably only works
with SQLite.

=cut

#_}
#_{ POD: Copyright and license

=head1 COPYRIGHT AND LICENSE
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
