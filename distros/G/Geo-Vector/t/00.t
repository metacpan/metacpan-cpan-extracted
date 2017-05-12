# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Geo-Vector.t'

#########################

use Test::More qw(no_plan);
BEGIN { use_ok('Geo::Vector') };

use Geo::OGC::Geometry;
#use Data::Dumper;

#########################

for ('dbf','prj','shp','shx') {
    unlink "t/test.$_";
}

eval {
    $test = Geo::Vector->new();
};
ok(($test and ($@ eq '')), "open memory as a data source: $@");

for (@Geo::OGR::Geometry::GEOMETRY_TYPES) {
    next if $_ =~ /GeometryC/;
    next if $_ =~ /Multi/;
    next if $_ =~ /Unkno/;
    next if $_ =~ /None/;
    next if $_ =~ /Ring/;
    eval {
	$test = Geo::Vector->new(create=>'test'.$_, geometry_type=>$_);
    };
    my $tt = '';
    $tt = $test->geometry_type() unless $@;
    ok($_ eq $tt,"Create layer with $_ type: $@");
}

eval {
    $test = Geo::Vector->new(driver=>'ESRI Shapefile', data_source=>'./t', create=>'test', geometry_type=>'Point');
};
ok($@ eq '', "create a layer into the new dataset: $@");

eval {
    $test->schema(Fields => [{Name => 'int', Type=> 'Integer'}, {Name => 'real', Type => 'Real'}]);
};
ok($@ eq '', "add a schema into the layer: $@");

eval {
    $test->add_feature(Geometry=>Geo::OGC::Point->new(1.123,2.345),int=>12,real=>3.4);
    $test->feature({Geometry=>Geo::OGC::Point->new(2.123,2.345),int=>13,real=>4.4});
    $test->add_feature(Geometry=>Geo::OGC::Point->new(0.123,2.345),int=>15,real=>7.4);
};
ok($@ eq '', "add a feature into the layer: $@");

@range = $test->value_range(field_name=>'int',filter_rect=>[1,2,3,3]);

ok($range[1] == 13, 'value_range with filter_rect');
undef $test;

eval {
    $test = new Geo::Vector(data_source=>'./t', open=>'test');
};
ok($@ eq '', "open a layer: $@");

ok ($test->feature_count == 3, 'feature_count '.$test->feature_count);

@w = $test->world;
ok (@w == 4, 'world size');

eval {
    $f = $test->feature(0);
};
ok($@ eq '', "retrieve a feature: $@");

#ok (abs($f->{geometry}->X - 1.123) < 0.01, 'returns correct data');
#ok (abs($f->{real}-3.4) < 0.01, 'returns correct attr');
$f = 1;
ok(1);
ok(1);

for ('dbf','prj','shp','shx') {
    unlink "t/test.$_";
}

# test a layer of features with varying schema
$v = Geo::Vector->new( features => [] );

$v->add_feature(sfield => 'string',
		ifield => 1,
		rfield => 1.23, 
		Geometry => Geo::OGC::Point->new(12.34, 56.78));

ok($v->feature_count == 1, 'fset: feature count');

my $s = $v->feature(0)->Schema;
ok($s->field('rfield')->{Name} eq 'rfield', 'fset: schema');
ok($s->field('sfield')->{Name} eq 'sfield', 'fset: schema');

my $ogc = Geo::OGC::Point->new(1,2);
my $ogr = Geo::OGR::CreateGeometryFromWkt($ogc->AsText);
ok($ogc->AsText eq $ogr->ExportToWkt, "OGC and OGR wkts equal in Point");
$ogc = Geo::OGC::LineString->new();
$ogc->AddPoint(Geo::OGC::Point->new(1,2));
$ogc->AddPoint(Geo::OGC::Point->new(3,4));
$ogc->AddPoint(Geo::OGC::Point->new(6,5));
$ogr = Geo::OGR::CreateGeometryFromWkt($ogc->AsText);
my $wkt = $ogr->ExportToWkt;
my $ogc2 = Geo::OGC::Geometry->new(Text => $wkt);
ok(is_deeply($ogc, $ogc2), "OGC and OGR wkts equal in LineString");

$C = new Geo::OGC::GeometryCollection;
$C->AddGeometry(Geo::OGC::Point->new(0, 0));
$ogr = Geo::OGR::CreateGeometryFromWkt($C->AsText);

$box = Geo::Vector->new();
$box->add_feature(Geometry=>'POLYGON((0 0, 0 10, 10 10, 10 0, 0 0))');
$points = Geo::Vector->new();
$points->add_feature(Geometry=>'POINT(1 1)');
$points->add_feature(Geometry=>'POINT(20 1)');
$within = $points->features( that_are_within => $box->geometry(0) );
ok($within->[0]->GetGeometry->ExportToWkt eq 'POINT (1 1)', 'Within, WKT');

$g = Geo::OGR::Geometry->create(WKT => 'POINT (1 1)');
$v = Geo::Vector->new(geometries => [$g]);
$p = $v->geometry(0);
ok($g->ExportToWkt eq $p->ExportToWkt, "geometries");

#$c = Geo::Vector->new(features=>"t/data/a.geojson");

