# types.t

use Test::Most;

use Geo::JSON::Types -types;

use Geo::JSON::Feature;
use Geo::JSON::Point;

my ($geometry_obj,$feature_obj);

{
    note "Geometry";

    ok Geometry->has_coercion, "Geometry has coercion";

    my $obj = Geo::JSON::Point->new( { coordinates => [ 1, 2 ] } );

    is Geometry->coerce($obj), $obj,
        "does not coerce objects that need no coercion";

    ok my $coerced
        = Geometry->coerce( { type => 'Point', coordinates => [ 1, 2 ] } ),
        "coerce HashRef";

    isa_ok $coerced, 'Geo::JSON::Point';
    ok $coerced->does('Geo::JSON::Role::Geometry'), "Geometry role consumed";
    is_deeply $coerced->coordinates, [ 1, 2 ], "attributes set ok";

    $geometry_obj = $obj;
}

{
    note "Feature";
    ok Feature->has_coercion, "Feature has coercion";

    my $obj = Geo::JSON::Feature->new( { geometry => $geometry_obj } );

    is Feature->coerce($obj), $obj,
        "does not coerce value that needs no coercion";

    ok my $coerced
        = Feature->coerce( { type => 'Feature', geometry => $geometry_obj } ),
        "coerced HashRef";

    isa_ok $coerced, 'Geo::JSON::Feature';
    is_deeply $coerced->geometry, $geometry_obj, "attributes set ok";

    $feature_obj = $obj;
}

{
    note "Features";
    ok Features->has_coercion, "Features has coercion";

    my $features = [$feature_obj];
    is Features->coerce($features), $features,
        "does not coerce value that needs no coercion";

    ok my $coerced
        = Features->coerce(
        [ { type => 'Feature', geometry => $geometry_obj } ] ),
        "coerced ArrayRef[HashRef]";

    ok @{$coerced ||[]}, "got arrayref with value(s)";
    is scalar(@{$coerced}), 1, "one item";
    isa_ok $coerced->[0], 'Geo::JSON::Feature';
}

{
    note "Features with Geometry converion";

    my $features = [
        {   type     => 'Feature',
            geometry => { type => 'Point', coordinates => [ 1, 2 ] }
        }
    ];

    ok my $coerced = Features->coerce($features),
        "coerced from data structure with no objects";

    ok @{ $coerced || [] }, "got arrayref with value(s)";
    is scalar( @{$coerced} ), 1, "one item";
    isa_ok $coerced->[0], 'Geo::JSON::Feature';
    isa_ok $coerced->[0]->geometry, 'Geo::JSON::Point';
}

done_testing();

