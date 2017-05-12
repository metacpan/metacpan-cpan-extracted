#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Geo::JSON::Simple;

note("Testing point");

my @point = qw( 717862.48638976 6648347.0162409 );
my $point = point(@point);
isa_ok($point,'Geo::JSON::Point');
is($point->type,'Point','Type is also Point');
is_deeply($point->all_positions,[[@point]],'All positions of point are correct');
like($point->to_json,qr/"717862\.48638976","6648347\.0162409"/,'JSON of point contains coordinates');

note("Testing multipoint");

my @multipoint = qw( 718080.211892762 6648726.81062054 718108.735817997 6648709.22683759 );
my $multipoint = multipoint(@multipoint);
isa_ok($multipoint,'Geo::JSON::MultiPoint');
is($multipoint->type,'MultiPoint','Type is also MultiPoint');
is_deeply($multipoint->all_positions,[[@multipoint[0..1]],[@multipoint[2..3]]],'All positions of multipoint are correct');

note("Testing linestring");

my @linestring = qw(
  717568.28347994 6648262.89106777
  717572.668905149 6648264.63149797
  717681.203513697 6648317.424723
  717712.507985127 6648329.39956498
  717938.721280314 6648402.98944419
  718148.80180915 6648508.07223732
  718202.611909519 6648535.23570413
  718218.530069959 6648544.05715605 
);
my $linestring = linestring(@linestring);
isa_ok($linestring,'Geo::JSON::LineString');
is($linestring->type,'LineString','Type is also LineString');
is_deeply($linestring->all_positions,[
  [@linestring[0..1]],
  [@linestring[2..3]],
  [@linestring[4..5]],
  [@linestring[6..7]],
  [@linestring[8..9]],
  [@linestring[10..11]],
  [@linestring[12..13]],
  [@linestring[14..15]]
],'All positions of linestring are correct');

note("Testing multilinestring");

my @multilinestring = ([qw(
  718202.611909519 6648535.23570413
  718208.023710842 6648505.26068976
)],[qw(
  718281.960113708 6648455.20340417
  718296.777252493 6648483.08073735
)]);
my $multilinestring = multilinestring(@multilinestring);
isa_ok($multilinestring,'Geo::JSON::MultiLineString');
is($multilinestring->type,'MultiLineString','Type is also MultiLineString');
is_deeply($multilinestring->all_positions,[
  [@{$multilinestring[0]}[0..1]],
  [@{$multilinestring[0]}[2..3]],
  [@{$multilinestring[1]}[0..1]],
  [@{$multilinestring[1]}[2..3]]
],'All positions of multilinestring are correct');

note("Testing polygon");

my @polygon = ([qw(
  100.0 0.0 101.0 0.0 101.0 1.0 100.0 1.0
)],[qw(
  100.2 0.2 100.8 0.2 100.8 0.8 100.2 0.8
)]);
my $polygon = polygon(@polygon);
isa_ok($polygon,'Geo::JSON::Polygon');
is($polygon->type,'Polygon','Type is also Polygon');
is_deeply($polygon->all_positions,[
  [@{$polygon[0]}[0..1]],
  [@{$polygon[0]}[2..3]],
  [@{$polygon[0]}[4..5]],
  [@{$polygon[0]}[6..7]],
  [@{$polygon[0]}[0..1]],
  [@{$polygon[1]}[0..1]],
  [@{$polygon[1]}[2..3]],
  [@{$polygon[1]}[4..5]],
  [@{$polygon[1]}[6..7]],
  [@{$polygon[1]}[0..1]]
],'All positions of polygon are correct');

note("multipolygon untested... be my guest!");

note("Testing feature");

my @point_feature = qw( 1.1 1.1 );
my $feature = feature point(@point_feature), a => 1, b => 2;
isa_ok($feature,'Geo::JSON::Feature');
is($feature->type,'Feature','Type is also Feature');
is($feature->properties->{a},1,'Property a is correct');
is($feature->properties->{b},2,'Property b is correct');
is_deeply($feature->geometry->all_positions,[[@point_feature]],'All positions of point inside geometry are correct');

note("Testing featurecollection");

my @featurecollection = (
  point(@point_feature), a => 1, b => 2,
  point(@point_feature), c => 3, d => 4,
);
my $featurecollection = featurecollection @featurecollection;
isa_ok($featurecollection,'Geo::JSON::FeatureCollection');
is($featurecollection->type,'FeatureCollection','Type is also FeatureCollection');
is($featurecollection->features->[0]->properties->{a},1,'Property a of first feature is correct');
is($featurecollection->features->[0]->properties->{b},2,'Property b of first feature is correct');
is($featurecollection->features->[1]->properties->{c},3,'Property c of second feature is correct');
is($featurecollection->features->[1]->properties->{d},4,'Property d of second feature is correct');
is($featurecollection->features->[0]->properties->{c},undef,'Property c of first feature is undef');
is($featurecollection->features->[0]->properties->{d},undef,'Property d of first feature is undef');
is($featurecollection->features->[1]->properties->{a},undef,'Property a of second feature is undef');
is($featurecollection->features->[1]->properties->{b},undef,'Property b of second feature is undef');

note("Testing geometrycollection");

my @geometrycollection = (
  point(@point_feature),
  point(@point_feature)
);
my $geometrycollection = geometrycollection @geometrycollection;
isa_ok($geometrycollection,'Geo::JSON::GeometryCollection');
is($geometrycollection->type,'GeometryCollection','Type is also GeometryCollection');
is(scalar @{$geometrycollection->geometries},2,'geometrycollection has 2 geometries');

done_testing;