#_{ Encoding and name

=encoding utf8
=head1 NAME
Geo::OSM::DBI::CH

Store Open Street Map data with DBI, especially for Switzerland
=cut

package Geo::OSM::DBI::CH;

#_}
#_{ use ...
use warnings;
use strict;

use DBI;

use utf8;
use Carp;

use Geo::OSM::DBI;
our @ISA = qw(Geo::OSM::DBI);

#_}
our $VERSION = 0.01;
#_{ Synopsis

=head1 SYNOPSIS
    use Geo::OSM::DBI;
    # or ...
    use Geo::OSM::DBI::CH;

The exact specifica are yet to be defined.
=cut
#_}
#_{ Methods

=head1 METHODS
=cut

sub new { #_{
#_{ POD

=head2 new

    my $osm_db_ch = Geo::OSM::DBI::CH->new($dbh);

Create and return a C<< Geo::OSM::DBI::CH >> object that will access the Open Street Database referenced by the C<DBI::db> object C<$dbh>).
It's unclear to me what a C<DBI::db> object actually is...

=cut

#_}

  my $class = shift;
  my $dbh   = shift;

# croak "dbh is not a DBI object ($dbh)" unless $dbh -> isa('DBI::db');

  my $self = $class->SUPER::new($dbh);

  croak "Wrong class $class" unless $self->isa('Geo::OSM::DBI::CH');

  return $self;

} #_}
sub create_table_municipalities_ch { #_{
#_{ POD

=head2 create_table_municipalities_ch

    $osm_db_ch->create_table_municipalities_ch();


First creates the table C<municipalities> by calling the
L<< parent's class|Geo::OSM::DBI >> L<< create_table_municipalities|Geo::OSM::DBI/create_table_municipalities >>.
Then, it uses the data in table C<municipalities> to create C<municipalities_ch>.
Finanlly, it creates the view C<municipalities_ch_v>.

=cut

#_}
  
  my $self = shift;

  # Call method in parent class:
  $self->create_table_municipalities();

  $self -> _sql_stmt("
  create table municipalities_ch (
     rel_id integer primary key,
     bfs_no integer not null
  )",
  "create table municipalities_ch");
  
  $self -> _sql_stmt("
    insert into municipalities_ch
    select
      mun.rel_id        rel_id,
      bfs.val           bfs_no
    from
      municipalities    mun  join
      tag               bfs  on mun.rel_id = bfs.rel_id
    where
      bfs.key = 'swisstopo:BFS_NUMMER'
  ", "fill table municipalities_ch");


  $self -> _sql_stmt("
    create view municipalities_ch_v as
    select
      rel_id,
      name,
      lat_min,
      lon_min,
      lat_max,
      lon_max,
      bfs_no
    from
      municipalities_ch join
      municipalities    using (rel_id)
  ",
  "create view municipalities_ch_v"
 );

 
#   my $sth = $self->{dbh}->prepare($stmt);
#   $sth->execute;
# 
#   my @ret;
#   while (my $r = $sth->fetchrow_hashref) {
#     push @ret, $r;
#   }
# 
#   return @ret;

} #_}
sub municipalities_ch { #_{
#_{ POD

=head2 municipalities_ch

    $osm_db_ch->create_table_municipalities_ch();
    …
    my %municipalities = $osm_db_ch->municipalities_ch();


=cut

#_}
  
  my $self = shift;
  
  my $stmt = "
    select
      rel_id,
      name,
      lat_min,
      lat_max,
      lon_min,
      lon_max,
      bfs_no
    from
      municipalities_ch_v
  ";


  my $sth = $self->{dbh}->prepare($stmt);
  $sth->execute;

  my %ret;
  while (my $r = $sth->fetchrow_hashref) {
    $ret{$r->{rel_id}} = {
      name    => $r->{name   },
      lat_min => $r->{lat_min},
      lat_max => $r->{lat_max},
      lon_min => $r->{lon_min},
      lon_max => $r->{lon_max},
      bfs_no  => $r->{bfs_no },
    };
  }

  return %ret;

} #_}
sub rel_id_ch { #_{
#_{ POD

=head2 rel_id_ch

    my $rel_id = $osm_db_ch->rel_id_ch();

Return the relation id of Switzerland.

As of 2017-09-05, it returns C<51701>.

Note: apparently, a country can have multiple relations with
C<< key = 'ISO3166-1' >> (See L<< Geo::OSM::DBI/rel_ids_ISO_3166_1 >>), yet
Switzerland has (as it does not have access to the sea) only one.

=cut

#_}

  my $self = shift;
  my ($rel_id_ch) =  $self->rel_ids_ISO_3166_1('CH');
  return $rel_id_ch;

} #_}
sub rel_ch { #_{
#_{ POD

=head2 rel_id_ch

Return the L<relation|Geo::OSM::DBI::Primitive::Relation> of Switzerland.

See L<Geo::OSM::DBI/rel_id_ch> for more details.


=cut

#_}

  my $self = shift;

  my $rel_id_ch = $self->rel_id_ch;

  return Geo::OSM::DBI::Primitive::Relation->new($rel_id_ch, $self);

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

'tq84';
