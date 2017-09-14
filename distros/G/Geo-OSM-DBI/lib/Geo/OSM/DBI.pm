# Encoding and name #_{

=encoding utf8
=head1 NAME

Geo::OSM::DBI - Store Open Street Map data with DBI.

=cut
package Geo::OSM::DBI;
#_}
#_{ use …
use warnings;
use strict;

use DBI;
use Time::HiRes qw(time);

use utf8;
use Carp;

use Geo::OSM::DBI::Primitive::Relation;

#_}
our $VERSION = 0.01;
#_{ Synopsis

=head1 SYNOPSIS

    use DBI;
    use Geo::OSM::DBI;

    # Create a DBI connection to a database ...
    my $dbh = DBI->connect("dbi:SQLite:dbname=…", '', '', {sqlite_unicode=>1}) or die;

    # ... and use the DBI connection to construct an OSM DB:
    my $osm_db = Geo::OSM::DBI->new{$dbh};

    $osm_db->create_base_schema_tables(…);

    # TODO: load schemas with Open Street Map data...
    
    $osm_db->create_base_schema_indexes();

=cut
#_}
#_{ Overview

=head1 OVERVIEW

Manage <I>OpenStreetMap</I> data in a L<DBI> database.

Originally, the package was thought to be database product agnostic (does the I<I> in C<DBI> not stand for independent?). It turned out, that I was
happy if I could make it work with L<DBD::SQLite>, so to call it DB-independent is not correct.

=cut

#_}
#_{ Methods

=head1 METHODS
=cut

sub new { #_{
#_{ POD

=head2 new

    my $osm_db = Geo::OSM::DBI->new($dbh);

Create and return a C<< Geo::OSM::DBI >> object that will access the Open Street Database referenced by the C<DBI::db> object C<$dbh>).
It's unclear to me what a C<DBI::db> object actually is...

=cut

#_}

  my $class = shift;
  my $dbh   = shift;

  croak "dbh is not a DBI object ($dbh)" unless $dbh -> isa('DBI::db');

  my $self = {};
  bless $self, $class;
  croak "Wrong class $class" unless $self->isa('Geo::OSM::DBI');

  $self->{dbh} = $dbh;

  return $self;

} #_}
#_{ Create base schema objects
sub create_base_schema_tables { #_{
#_{ POD

=head2 create_base_schema_tables

    $osm_db->create_base_schema_tables();
    $osm_db->create_base_schema_tables({schema => $schema_name);

Create the base tables C<nod>, C<nod_way>, C<rel_mem> and C<tag>.

After creating the schema, the tables should be filled with C<pbf2sqlite.v2.py>.

After filling the tables, the indexes on the tables should be created with L</create_base_schema_indexes>.


=cut

#_}
  
  my $self = shift;
  my $opts = shift;

  my ($schema, $schema_dot) = _schema_dot_from_opts($opts);

  $self->_sql_stmt("
    create table ${schema_dot}nod (
          id  integer primary key,
          lat real not null,
          lon real not null
    )",
    "create table ${schema_dot}nod"
  );

  $self->_sql_stmt("
        create table ${schema_dot}nod_way (
          way_id         integer not null,
          nod_id         integer not null,
          order_         integer not null
    )",
  "create table ${schema_dot}nod_way");

  $self->_sql_stmt("
        create table ${schema_dot}rel_mem (
          rel_of         integer not null,
          order_         integer not null,
          nod_id         integer,
          way_id         integer,
          rel_id         integer,
          rol            text
    )",
  "create table ${schema_dot}rel_mem");

# $self->{dbh}->do("
  $self->_sql_stmt("
        create table ${schema_dot}tag(
          nod_id      integer null,
          way_id      integer null,
          rel_id      integer null,
          key         text not null,
          val         text not null
   )",
 "create table ${schema_dot}tag");

} #_}
sub create_base_schema_indexes { #_{
#_{ POD

=head2 create_base_schema_indexes()

    $osm_db->create_base_schema_tables();

    # fill tables (as of yet with pbf2sqlite.v2.py

    $osm_db->create_base_schema_indexes();
    # or, if create_base_schema_indexes was created in another schema:
    $osm_db->create_base_schema_indexes({schema=>$schema_name);

Create the base tables C<nod>, C<nod_way>, C<rel_mem> and C<tag>.

After creating the base schema and filling the tables, the indexes should be created on the base schema tables.

=cut

  my $self = shift;
  my $opts = shift;

  my ($schema, $schema_dot) = _schema_dot_from_opts($opts);

#
# TODO: to put the schema in front of the index name rather than the table name seems
#       to be very sqlite'ish.
#
  $self->_sql_stmt("create index ${schema_dot}nod_way_ix_way_id on nod_way (way_id)"   , "index ${schema_dot}nod_way_ix_way_id");
                                                                                                                               
  $self->_sql_stmt("create index ${schema_dot}tag_ix_val        on tag     (     val)" , "index ${schema_dot}tag_ix_val"       );
  $self->_sql_stmt("create index ${schema_dot}tag_ix_key_val    on tag     (key, val)" , "index ${schema_dot}tag_ix_key_val"   );
                                                                                                                               
  $self->_sql_stmt("create index ${schema_dot}tag_ix_nod_id     on tag     (nod_id)"   , "index ${schema_dot}tag_ix_nod_id"    );
  $self->_sql_stmt("create index ${schema_dot}tag_ix_way_id     on tag     (way_id)"   , "index ${schema_dot}tag_ix_way_id"    );
  $self->_sql_stmt("create index ${schema_dot}tag_ix_rel_id     on tag     (rel_id)"   , "index ${schema_dot}tag_ix_rel_id"    );

# 2017-08-28
# $self->{dbh}->do("create index ${schema_dot}rel_mem_ix_nod_id on rel_mem (nod_id)"   );
  $self->_sql_stmt("create index ${schema_dot}rel_mem_ix_rel_of on rel_mem (rel_of)"   , "index ${schema_dot}rel_mem_ix_rel_of");

# 2017-09-11
  $self->_sql_stmt("analyze $schema", 'analyze');

#_}
} #_}
#_}
sub create_table_municipalities { #_{
#_{ POD

=head2 create_table_municipalities

    $osm->create_table_municipalities();

Creates the table C<municipalites>.

=cut

#_}

  my $self = shift;

  $self -> _sql_stmt("
    create table municipalities (
      rel_id                   integer primary key,
      name                     text    not null,
      lat_min                  real    not null,
      lon_min                  real    not null,
      lat_max                  real    not null,
      lon_max                  real    not null,
      cnt_ways                 integer not null,
      cnt_nodes                integer not null,
      cnt_nodes_verification   integer not null
    )",
    "create table municipalities"
  );

  $self->_sql_stmt("commit", "commit");


  $self -> _sql_stmt("
    insert into municipalities
    select
       admi.rel_id rel_id,
       name.val    name,
       min  (node.lat            )   lat_min,
       min  (node.lon            )   lon_min,
       max  (node.lat            )   lat_max,
       max  (node.lon            )   lon_max,
       count(distinct relm.way_id)   cnt_ways,
       count(distinct node.id    )   cnt_nodes,
    /* cnt_nodes_verification: 
          Must/should be 0 because each way counts one node that another way already counted.
          Borders that are not 100 % in the database return -1 or so.
    */
       count(*                   ) -
       count(distinct relm.way_id) -
       count(distinct node.id    )   cnt_nodes_verification
    from
      tag     admi                                   join
      tag     name on admi.rel_id = name.rel_id      join
      rel_mem relm on admi.rel_id = relm.rel_of      join
      nod_way nodw on relm.way_id = nodw.way_id      join
      nod     node on nodw.nod_id = node.id
    where
      admi.key = 'admin_level' and
      admi.val =  8            and
      name.key = 'name'
    group by
      admi.rel_id,
      name.val
     order by
    --   relm.way_id,
    --   node.id
      cnt_nodes_verification,
      name
  ", "fill table municipalities");
#q
#q  $sth->execute or croak;
#q
#Qwhile (my @r = $sth->fetchrow_array) {
#Q  printf "%2d %2d %2d %s\n", $r[0], $r[1], $r[2], $r[3];
#Q}

} #_}
sub create_area_tables { #_{
#_{ POD

=head2 new

    $osm_db->create_area_tables(
      coords           => {
        lat_min => 47,
        lat_max => 48,
        lon_min =>  7,
        lon_max =>  9
      },
      schema_name_to   => 'area'
    });

    $osm_db->create_area_tables(
      municipality_rel_id =>  $rel_id,
      schema_name_to      => 'area'
    });

=cut

#_}

  my $self    = shift;
  my $opts    = shift;

  my $lat_min;
  my $lat_max;
  my $lon_min;
  my $lon_max;

  if (my $coords = delete $opts->{coords}) {

     $lat_min = $coords->{lat_min};
     $lat_max = $coords->{lat_max};
     $lon_min = $coords->{lon_min};
     $lon_max = $coords->{lon_max};
  }
  elsif (my $municipality_rel_id = delete $opts->{municipality_rel_id}) {
    my $sth = $self->{dbh}->prepare ('select lat_min, lat_max, lon_min, lon_max from municipalities where rel_id = ?');
    $sth->execute($municipality_rel_id);
    my $r = $sth->fetchrow_hashref or croak "No record found for municipality_rel_id $municipality_rel_id";

    $lat_min = $r->{lat_min};
    $lat_max = $r->{lat_max};
    $lon_min = $r->{lon_min};
    $lon_max = $r->{lon_max};

  }

  my ($schema_name_to, $schema_name_to_dot) = _schema_dot_from_opts($opts, 'schema_name_to');
  croak "Must have a destination schema name" unless $schema_name_to;

  croak "lat_min not defined" unless defined $lat_min;
  croak "lat_max not defined" unless defined $lat_max;
  croak "lon_min not defined" unless defined $lon_min;
  croak "lon_max not defined" unless defined $lon_max;

  $self->create_base_schema_tables({schema=>$schema_name_to});

  #_{ nod

  # my $f = '%16.13f';
    my $f = '%s';
    
    my $stmt = sprintf("
    
      insert into ${schema_name_to_dot}nod
      select * from nod
      where 
        lat between $f and $f and
        lon between $f and $f
    
    ", $lat_min, $lat_max, $lon_min, $lon_max);
    
    $self->_sql_stmt($stmt, "${schema_name_to}nod filled");
    

  #_}
  #_{ nod_way

    $stmt = sprintf("
    
      insert into ${schema_name_to_dot}nod_way
      select * from nod_way
      where 
         nod_id in (
          select
            id
          from
            ${schema_name_to_dot}nod
      )
     ");

    $self->_sql_stmt($stmt, "${schema_name_to_dot}nod_way filled");

  #_}
  #_{ rel_mem

    $stmt = sprintf("
    
      insert into ${schema_name_to_dot}rel_mem
      select * from rel_mem
      where
        nod_id in (select              id from ${schema_name_to_dot}nod    ) or
        way_id in (select distinct way_id from ${schema_name_to_dot}nod_way) or
        rel_id in (select distinct rel_id 
                    from rel_mem where
        nod_id in (select              id from ${schema_name_to_dot}nod    ) or
        way_id in (select distinct way_id from ${schema_name_to_dot}nod_way)
        )                                                                    or
        rel_id in (select distinct rel_of 
                    from rel_mem where
        nod_id in (select              id from ${schema_name_to_dot}nod    ) or
        way_id in (select distinct way_id from ${schema_name_to_dot}nod_way)
        )
     ");

    $self->_sql_stmt($stmt, "${schema_name_to_dot}.nod_rel filled");

  #_}
  #_{ tag

    $stmt = sprintf("

      insert into ${schema_name_to_dot}tag
      select * from tag
      where 
        nod_id in (select              id from ${schema_name_to_dot}nod    ) or
        way_id in (select distinct way_id from ${schema_name_to_dot}nod_way) or
        rel_id in (select distinct rel_of from ${schema_name_to_dot}rel_mem) or
        rel_id in (select distinct rel_id from ${schema_name_to_dot}rel_mem)
     ");

    $self->_sql_stmt($stmt, "area_db.way_rel filled");

  #_}

  $self->create_base_schema_indexes({schema=>$schema_name_to});

} #_}
sub _schema_dot_from_opts { #_{
#_{ POD

=head2 _schema_dot_from_opts

    my ($schema, $schema_dot) = _schema_dot_from_opts($opts            );
    # or
    my ($schema, $schema_dot) = _schema_dot_from_opts($opts, "opt_name");

Returns C<< ('schema_name', 'schema_name.') >>  or C<< ('', '') >>.

=cut

#_}

  my $opts    = shift;
  my $name    = shift // 'schema';

  my $schema = delete $opts->{$name} // '';
  my $schema_dot = '';
  if ($schema) {
    $schema_dot = "$schema.";
  }
  return ($schema, $schema_dot);

} #_}
sub _sql_stmt { #_{
#_{ POD

=head2 _sql_stmt

    $self->_sql_stmt($sql_text, 'dientifiying text')

Internal function. executes C<$sql_text>. Prints time it took to complete

=cut

#_}

  my $self = shift;
  my $stmt = shift;
  my $desc = shift;

  my $t0 = time;
  $self->{dbh}->do($stmt) or croak ("Could not execute $stmt");
  my $t1 = time;

  printf("SQL: $desc, took %6.3f seconds\n", $t1-$t0);

} #_}
sub _sth_prepare_ways_of_relation { #_{
#_{ POD

=head2 _sth_prepare_name

    my $primitive_type = 'rel'; # or 'way'. or 'node';

    my sth = $osm_dbi->_sth_prepare_name(); 

    $sth->execute($primitive_id);

Prepares the statement handle to get the name for a primitive. C<$primitive_type> must be C<node>, C<way> or C<relation>.

=cut

#_}

  my $self           = shift;
  my $primitive_type = shift;

  croak "Unsupported primitive type $primitive_type" unless grep { $_ eq $primitive_type} qw(rel nod way);

  my $sth = $self->{dbh}->prepare("select val as name from tag where ${primitive_type}_id = ? and key = 'name'") or croak;

  return $sth;

} #_}
sub _sth_prepare_name { #_{
#_{ POD

=head2 _sth_prepare_name

    my $primitive_type = 'rel'; # or 'way'. or 'node';

    my sth = $osm_dbi->_sth_prepare_name(); 

    $sth->execute($primitive_id);

Prepares the statement handle to get the name for a primitive. C<$primitive_type> must be C<node>, C<way> or C<relation>.

=cut

#_}

  my $self           = shift;
  my $primitive_type = shift;

  croak "Unsupported primitive type $primitive_type" unless grep { $_ eq $primitive_type} qw(rel nod way);

  my $sth = $self->{dbh}->prepare("select val as name from tag where ${primitive_type}_id = ? and key = 'name'") or croak;

  return $sth;

} #_}
sub _sth_prepare_name_in_lang { #_{
#_{ POD

=head2 _sth_prepare_name_in_lang

    my $primitive_type = 'rel'; # or 'way'. or 'node';

    my sth = $osm_dbi->_sth_prepare_name_in_lang($primitive_type); 

    my $lang           = 'de';  # or 'it' or 'en' or 'fr' or …

    $sth->execute($primitive_id, "lang:$lang");

Prepares the statement handle to get the name for a primitive. C<$primitive_type> must be C<node>, C<way> or C<relation>.

=cut

#_}

  my $self           = shift;
  my $primitive_type = shift;

  croak "Unsupported primitive type $primitive_type" unless grep { $_ eq $primitive_type} qw(rel nod way);

  my $sth = $self->{dbh}->prepare("select val as name from tag where ${primitive_type}_id = ? and key = ?") or croak;

  return $sth;

} #_}
sub rel_ids_ISO_3166_1 { #_{

#_{ POD

=head2 rel_ids_ISO_3166_1

    my $two_letter_country_code = 'DE';
    my @rel_ids = $self->rel_ids_ISO_3166_1($two_letter_country_code);

Returns the L<< relation|Geo::OSM::Primitive::Relation >> ids for a country.
Apparently, a country can have multiple relation ids. For example, Germany has three (as 2017-09-05).
These relations somehow distinguish between land mass and land mass plus sea territories.

=cut

#_}

  my $self                    = shift;
  my $two_letter_country_code = shift or croak 'Need a two letter country code';

  my $sth = $self->{dbh}->prepare("select rel_id from tag where key = 'ISO3166-1' and val = ? and rel_id is not null") or croak;
  $sth->execute($two_letter_country_code) or croak;

  my @ret;

  while (my ($rel_id) = $sth->fetchrow_array) {
     push @ret, $rel_id;
#    Geo::OSM::DBI::Primitive::Relation->new($rel_id, $self);
  }

  return @ret;

} #_}
sub rels_ISO_3166_1 {
#_{ POD

=head2 rels_ISO_3166_1

    my $two_letter_country_code = 'DE';
    my @rels = $self->rels_ISO_3166_1($two_letter_country_code);

Returns the L<< relations|Geo::OSM::Primitive::Relation >> for a country.
See L</rels_ISO_3166_1> for more details.

=cut

#_}

  my $self                    = shift;
  my $two_letter_country_code = shift or croak 'Need a two letter country code';

  my @rel_ids_ISO_3166_1 = $self->rel_ids_ISO_3166_1($two_letter_country_code);

  my @ret;
  for my $rel_id (@rel_ids_ISO_3166_1) {
    push @ret, Geo::OSM::DBI::Primitive::Relation->new($rel_id, $self);
  }
  return @ret;

}
#_}
#_{ POD: Testing

=head1 TESTING

The package unfortunately only comes with some basic tests.

The modules can be tested however by loading the Swiss dataset
from L<< geofabrik.cde|http://download.geofabrik.de/europe.html >> with
L<< load-country.pl|https://github.com/ReneNyffenegger/OpenStreetMap/blob/master/scripts/load-country.pl >> and then
running the script
L<< do-Switzerland.pl|https://github.com/ReneNyffenegger/OpenStreetMap/blob/master/scripts/do-Switzerland >>.

=cut

#_}
#_{ POD: Copyright and License

=head1 COPYRIGHT and LICENSE

Copyright © 2017 René Nyffenegger, Switzerland. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at: L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

#_}
#_{ POD: Source Code

=head1 Source Code

The source code is on L<< github|https://github.com/ReneNyffenegger/perl-Geo-OSM-DBI >>. Meaningful pull requests are welcome.

=cut

#_}

'tq84';
