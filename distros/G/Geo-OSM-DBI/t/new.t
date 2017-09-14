#!/usr/bin/perl
use strict;
use warnings;

use Geo::OSM::DBI;
# use Geo::OSM::DBI::Primitive::Way;
use Geo::OSM::DBI::Primitive::Relation;

use Test::Simple tests => 7;
use Test::More;

my $db_test = 'test.db';

unlink $db_test if -f $db_test;

my $dbh = DBI->connect("dbi:SQLite:dbname=$db_test") or die "Could not create $db_test";
$dbh->{AutoCommit} = 0;

my $osm_db = Geo::OSM::DBI->new($dbh);
my $rel    = Geo::OSM::DBI::Primitive::Relation->new(1, $osm_db);

ok(1); # Test also class hierarchy Node and Way

# isa_ok($nod, 'Geo::OSM::DBI::Primitive::Node');
# isa_ok($nod, 'Geo::OSM::DBI::Primitive');
# isa_ok($nod, 'Geo::OSM::Primitive::Node');
# isa_ok($nod, 'Geo::OSM::Primitive');
# 
# isa_ok($way, 'Geo::OSM::DBI::Primitive::Way');
# isa_ok($way, 'Geo::OSM::DBI::Primitive');
# isa_ok($way, 'Geo::OSM::Primitive::Way');
# isa_ok($way, 'Geo::OSM::Primitive');

isa_ok($rel, 'Geo::OSM::DBI::Primitive::Relation');
isa_ok($rel, 'Geo::OSM::DBI::Primitive');
isa_ok($rel, 'Geo::OSM::Primitive::Relation');
isa_ok($rel, 'Geo::OSM::Primitive');

is($rel->{id}, 1, 'rel->id == 1');
is($rel->primitive_type(), 'rel', 'rel->primitive_type == rel');
