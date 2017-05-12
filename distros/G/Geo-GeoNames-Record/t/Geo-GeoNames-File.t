use Test::More tests => 3;

BEGIN { use_ok('Geo::GeoNames::File') };

my $geo_filename = 't/geonames_sample.txt';

my $file = Geo::GeoNames::File->open( $geo_filename, $geo_filename );

ok( $file, "open()" );

sub is_Dubai
{
  return (shift->id == 292223);
}

my @recs;

while( my $rec = $file->next(\&is_Dubai) )
{
  push @recs, $rec->id;
}

is_deeply( \@recs, [292223, 292223] );

$file->close();
