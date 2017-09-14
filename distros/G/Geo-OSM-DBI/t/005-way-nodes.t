use warnings;
use strict;

use Geo::OSM::DBI;
use Geo::OSM::DBI::Primitive::Relation;

use Test::More tests => 19;
# use Test::More;

my $db_test = 'test.db';
my $dbh = DBI->connect("dbi:SQLite:dbname=$db_test") or die "Could not create $db_test";
$dbh->{AutoCommit} = 0;

my $osm_db = Geo::OSM::DBI->new($dbh);
my $way = Geo::OSM::DBI::Primitive::Way->new(8, $osm_db);

my @nodes = $way->nodes;
is (scalar @nodes, 3);

isa_ok($nodes[0], 'Geo::OSM::DBI::Primitive::Node');
isa_ok($nodes[1], 'Geo::OSM::DBI::Primitive::Node');
isa_ok($nodes[2], 'Geo::OSM::DBI::Primitive::Node');
#
isa_ok($nodes[0], 'Geo::OSM::DBI::Primitive');
isa_ok($nodes[1], 'Geo::OSM::DBI::Primitive');
isa_ok($nodes[2], 'Geo::OSM::DBI::Primitive');
#
isa_ok($nodes[0], 'Geo::OSM::Primitive::Node');
isa_ok($nodes[1], 'Geo::OSM::Primitive::Node');
isa_ok($nodes[2], 'Geo::OSM::Primitive::Node');

is ($nodes[0]->{id}, 80);
is ($nodes[1]->{id}, 81);
is ($nodes[2]->{id}, 82);

is ($nodes[0]->lat, 47.9); is ($nodes[0]->lon, 7.4);
is ($nodes[1]->lat, 47.8); is ($nodes[1]->lon, 7.2);
is ($nodes[2]->lat, 47.7); is ($nodes[2]->lon, 7.1);


$dbh->commit;
