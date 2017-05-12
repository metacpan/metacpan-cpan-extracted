# object.t

use Test::Most;

use Geo::JSON;

use lib 't/lib';
use GeoJSONTests;

ok( Geo::JSON->codec->pretty->canonical(1), "set code options" );

ok my $object = GeoJSONTests->object($_), "created $_ with default args"
    foreach GeoJSONTests->types;

foreach my $test ( GeoJSONTests->tests ) {

    note $test->{name} || $test->{class};

    ok my $obj = GeoJSONTests->object( $test->{class}, $test->{args} ),
        "created " . $test->{class} . " object";

    is_deeply $obj->$_, $test->{args}->{$_}, "args $_ set ok"
        foreach sort keys %{ $test->{args} };

    if ( my $bbox = $test->{compute_bbox} ) {
        is_deeply $obj->compute_bbox, $bbox, "compute_bbox() ok";
    } else {
        dies_ok { $obj->compute_bbox } "Can't compute_bbox()";
    }

    # roundtrip testing

    my $json = GeoJSONTests->json( $test->{class}, $test->{args} );

    is $obj->to_json, $json, "to_json ok";

    ok my $obj2 = Geo::JSON->from_json($json),
        "created " . $test->{class} . " object from JSON";

    is_deeply $obj2->$_, $test->{args}->{$_}, "args $_ set ok"
        foreach sort keys %{ $test->{args} };

}

done_testing();

