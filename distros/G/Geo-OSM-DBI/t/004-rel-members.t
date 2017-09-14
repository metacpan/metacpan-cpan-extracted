use warnings;
use strict;

use Geo::OSM::DBI;
use Geo::OSM::DBI::Primitive::Relation;

use Test::Simple tests => 16;
use Test::More;

my $db_test = 'test.db';
my $dbh = DBI->connect("dbi:SQLite:dbname=$db_test") or die "Could not create $db_test";
$dbh->{AutoCommit} = 0;

my $osm_db = Geo::OSM::DBI->new($dbh);
my $rel    = Geo::OSM::DBI::Primitive::Relation->new(19, $osm_db);

my @members = $rel->members;

is(scalar @members, 5, '5 members found');

is($members[0]->primitive_type, 'nod', 'member 0: nod');
is($members[1]->primitive_type, 'way', 'member 1: way');
is($members[2]->primitive_type, 'way', 'member 2: way');
is($members[3]->primitive_type, 'way', 'member 3: way');
is($members[4]->primitive_type, 'way', 'member 4: way');

is($members[0]->{id}          ,   50, 'member 0/id: 50');
is($members[1]->{id}          ,    6, 'member 1/id:  6');
is($members[2]->{id}          ,    7, 'member 2/id:  7');
is($members[3]->{id}          ,    8, 'member 3/id:  8');
is($members[4]->{id}          ,    9, 'member 4/id:  9');

is($members[0]->role($rel)    ,   'Rel 19: node'  , 'role of 0: node' );
is($members[1]->role($rel)    ,   'Rel 19: South' , 'role of 1: South');
is($members[2]->role($rel)    ,   'Rel 19: East'  , 'role of 2: East' );
is($members[3]->role($rel)    ,   'Rel 19: North' , 'role of 3: North');
is($members[4]->role($rel)    ,   'Rel 19: West'  , 'role of 4: West' );

$dbh->commit;
