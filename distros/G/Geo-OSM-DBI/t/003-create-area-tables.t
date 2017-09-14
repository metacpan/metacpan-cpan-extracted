#!/usr/bin/perl
#
#  See inkscape created file t/002-data.svg for what's being
#  loaded with this script.
#


use strict;
use warnings;

use Test::Simple tests => 8;
use Test::More;
use DBI;

use Geo::OSM::DBI;

use t::helper;

my $area_schema = 'area_test';
my $db_area_schema = "${area_schema}.db";
my $db_test = 'test.db';
unlink $db_area_schema if -f $db_area_schema;

my $dbh = DBI->connect("dbi:SQLite:dbname=$db_test") or die "Could not create $db_test";
$dbh->do("attach database '$db_area_schema' as $area_schema");
$dbh->{AutoCommit} = 0;

my $osm_db = Geo::OSM::DBI->new($dbh);

$osm_db -> create_area_tables(# 47, 48, 7, 9,
    { coords=>{
        lat_min => 47,
        lat_max => 48,
        lon_min =>  7,
        lon_max =>  9
      },
      schema_name_to => $area_schema,
    });

$dbh->commit;

$dbh = undef;

my $dbh_area = DBI->connect("dbi:SQLite:dbname=$db_area_schema") or die "could not create $db_area_schema";
$dbh_area->{AutoCommit} = 0;

t::helper::exec_sql_stmts_in_file($dbh_area, 't/003-fill-expected-area-data.sql');
$dbh_area -> commit;

my ($count) = $dbh_area->selectrow_array("
  select count(*) from (
    select id from nod              except
    select id from nod_id_expected
  )
");

is($count, 0, "nod.id");

$count = $dbh_area->selectrow_array("
  select count(*) from (
    select id from nod_id_expected  except
    select id from nod
  )
");

is($count, 0, "nod_id_epxected");


# ----

$count = $dbh_area->selectrow_array("
  select count(*) from (
    select way_id, nod_id, order_ from nod_way          except
    select way_id, nod_id, order_ from nod_way_expected
  )
");

is($count, 0, "nod_way");

$count = $dbh_area->selectrow_array("
  select count(*) from (
    select way_id, nod_id, order_ from nod_way_expected except
    select way_id, nod_id, order_ from nod_way
  )
");

is($count, 0, "nod_way_expected");
# ----

$count = $dbh_area->selectrow_array("
  select count(*) from (
    select * from rel_mem          except
    select * from rel_mem_expected
  )
");

is($count, 0, "rel_mem");

$count = $dbh_area->selectrow_array("
  select count(*) from (
    select * from rel_mem_expected except
    select * from rel_mem
  )
");

is($count, 0, "rel_mem_expected");

# ----

$count = $dbh_area->selectrow_array("
  select count(*) from (
    select * from tag              except
    select * from tag_expected
  )
");

is($count, 0, "tag");

$count = $dbh_area->selectrow_array("
  select count(*) from (
    select * from tag_expected     except
    select * from tag
  )
");

is($count, 0, "tag_expected");
