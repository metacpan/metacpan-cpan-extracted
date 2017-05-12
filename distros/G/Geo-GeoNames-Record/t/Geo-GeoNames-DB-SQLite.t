use Test::More tests => 9;

BEGIN 
{ 
  use_ok('Geo::GeoNames::DB::SQLite');
  use_ok('Geo::GeoNames::File');
}

my $geo_filename = 't/geonames_sample.txt';

my $geo_file = Geo::GeoNames::File->open($geo_filename);
ok( $geo_file, 'Geo::GeoNames::File' );

my $db_filename = 't/geonames_sample.sqlite';

my $db = Geo::GeoNames::DB::SQLite->connect($db_filename);
ok( $db, 'connect()');

ok( $db->insert($geo_file), 'insert()' );

$geo_file->close();

my @recs = $db->query('Dubai');
is( $recs[0]->id, '292223', 'query() by name' );

@recs = $db->_query_id(292223);
is( $recs[0]->name, 'Dubai', 'query() by id' );

$recs[0]->name = 'DUBAI';
ok( $db->insert($recs[0]), 'insert dup record' );

$db->commit();

$db->disconnect();

$db = Geo::GeoNames::DB::SQLite->connect($db_filename);
ok( $db, 're connect()');

$db->disconnect();

unlink( $db_filename );
