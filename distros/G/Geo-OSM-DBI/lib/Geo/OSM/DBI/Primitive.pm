# Encoding and name #_{

=encoding utf8
=head1 NAME

Geo::OSM::DBI::Primitive - Base class for L<Geo::OSM::DBI::Primitive::Node>, L<Geo::OSM::DBI::Primitive::Way> and L<Geo::OSM::DBI::Primitive::Relation>.

=cut
package Geo::OSM::DBI::Primitive;
#_}
#_{ use …
use warnings;
use strict;

use utf8;
use Carp;

use Geo::OSM::Primitive;
our @ISA=qw(Geo::OSM::Primitive);

#_}
our $VERSION = 0.01;
#_{ Synopsis

=head1 SYNOPSIS

    …

=cut
#_}
#_{ Methods
#_{ Pod
=head1 METHODS
=cut
#_}
sub _init_geo_osm_dbi_primitive { #_{
#_{ POD

=head2 _init_geo_osm_dbi_primitive

    my sth = $self->_init_geo_osm_dbi_primitive($osm_dbi);

Initializes a derived class of C<<Geo::OSM::DBI::Primitive>> ( L<Geo::OSM::DBI::Primitive::Node>, L<Geo::OSM::DBI::Primitive::Way> and L<Geo::OSM::DBI::Primitive::Relation>).

This is necessary because these derived classes use multiple inheritance.

C<< $osm_dbi >> must be a L<<Geo::OSM::DBI>>.

=cut

#_}
  
  my $self    = shift;
  my $osm_dbi = shift;

  croak "Need Geo::OSM::DBI" unless ref $osm_dbi and $osm_dbi->isa('Geo::OSM::DBI');
  $self->{osm_dbi} = $osm_dbi;

} #_}
sub name { #_{
#_{ POD

=head2 name

    my $name = $rel->name();

Returns the name of the object;

=cut

#_}

  my $self  = shift;

  my $sth = $self->{osm_dbi}->_sth_prepare_name($self->primitive_type());
  $sth->execute($self->{id}) or die;

  my ($name) = $sth->fetchrow_array;

  return $name;

} #_}
sub name_in_lang { #_{
#_{ POD

=head2 name_in_lang

    my $lang = 'de'; # or 'en' or 'fr' or 'it' or …
    my $name = $rel->name_in_lang($lang);

Returns the name of the object in the language C<$lang>.

=cut

#_}

  my $self = shift;
  my $lang = shift;

  my $sth = $self->{osm_dbi}->_sth_prepare_name_in_lang('rel');
  $sth->execute($self->{id}, "name:$lang") or die;

  my ($name) = $sth->fetchrow_array;

  return $name;

} #_}
#q sub _sth_prepare_name { #_{
#q #_{ POD
#q 
#q =head2 _sth_prepare_name
#q 
#q     my sth = $self->_sth_prepare_name($primitive_type); 
#q 
#q Prepares the statement handle to get the name for a primitive. C<$primitive_type> must be C<node>, C<way> or C<relation>.
#q 
#q =cut
#q 
#q #_}
#q 
#q   my $self           = shift;
#q   my $primitive_type = shift;
#q # my $class = shift;
#q # my $id    = shift;
#q 
#q # my $self  = $class->SUPER::new($id);
#q # croak "not a Geo::OSM::DBI::Primitive::Relation" unless $self -> isa('Geo::OSM::DBI::Primitive::Relation');
#q 
#q   return $self;
#q 
#q } #_}
#_}

'tq84';
