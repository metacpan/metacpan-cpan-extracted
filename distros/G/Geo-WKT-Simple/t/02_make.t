use strict;
use warnings;
use Test::More;

use Geo::WKT::Simple;

subtest "Make POINT" => sub {
    is wkt_make_point(10, 20),     'POINT(10 20)';
    is wkt_make_point(12.5, 18.3), 'POINT(12.5 18.3)';

    is wkt_make(POINT => [ 12.5, 18.3 ]), 'POINT(12.5 18.3)';
};

subtest "Make LINESTRING" => sub {
    is wkt_make_linestring(
        [ 10, 20 ],
        [ 30, 40 ],
    ), 'LINESTRING(10 20, 30 40)';
    is wkt_make_linestring(
        [ 10.5, 20.8 ],
        [ 30.2, 4.5 ],
    ), 'LINESTRING(10.5 20.8, 30.2 4.5)';

    is wkt_make(LINESTRING => [
        [ 10, 20 ],
        [ 30, 40 ],
    ]), 'LINESTRING(10 20, 30 40)';
};

subtest "Make MULTILINESTRING" => sub {
    is wkt_make_multilinestring(
        [
            [ 10, 20 ],
            [ 30, 40 ],
        ],
        [
            [ 10.5, 20.8 ],
            [ 30.2, 4.5 ],
        ],
    ), 'MULTILINESTRING((10 20, 30 40), (10.5 20.8, 30.2 4.5))';

    is wkt_make(MULTILINESTRING => [
        [
            [ 10, 20 ],
            [ 30, 40 ],
        ],
        [
            [ 10.5, 20.8 ],
            [ 30.2, 4.5 ],
        ],
    ]), 'MULTILINESTRING((10 20, 30 40), (10.5 20.8, 30.2 4.5))';
};

subtest "Make POLYGON" => sub {
    is wkt_make_polygon(
        [
            [ 10, 20 ],
            [ 30, 40 ],
            [ 50, 60 ],
            [ 10, 20 ],
        ],
    ), 'POLYGON((10 20, 30 40, 50 60, 10 20))';
    is wkt_make_polygon(
        [
            [ 10, 20 ],
            [ 30, 40 ],
            [ 50, 60 ],
            [ 10, 20 ],
        ],
        [
            [ 2.5, 3.5   ],
            [ 4.5, 8.5   ],
            [ 9.5, 10.5  ],
            [ 11.5, 12.5 ],
        ],
    ), 'POLYGON((10 20, 30 40, 50 60, 10 20), (2.5 3.5, 4.5 8.5, 9.5 10.5, 11.5 12.5))';

    is wkt_make(POLYGON => [
        [
            [ 10, 20 ],
            [ 30, 40 ],
            [ 50, 60 ],
            [ 10, 20 ],
        ],
    ]), 'POLYGON((10 20, 30 40, 50 60, 10 20))';
};

subtest "Make MULTIPOLYGON" => sub {
    is wkt_make_multipolygon(
        [
            [
                [ 10, 20 ],
                [ 30, 40 ],
                [ 50, 60 ],
                [ 10, 20 ],
            ],
        ],
        [
            [
                [ 10, 20 ],
                [ 30, 40 ],
                [ 50, 60 ],
                [ 10, 20 ],
            ],
            [
                [ 2.5, 3.5   ],
                [ 4.5, 8.5   ],
                [ 9.5, 10.5  ],
                [ 11.5, 12.5 ],
            ],
        ],
    ), 'MULTIPOLYGON(((10 20, 30 40, 50 60, 10 20)), ((10 20, 30 40, 50 60, 10 20), (2.5 3.5, 4.5 8.5, 9.5 10.5, 11.5 12.5)))';

    is wkt_make(MULTIPOLYGON => [
        [
            [
                [ 10, 20 ],
                [ 30, 40 ],
                [ 50, 60 ],
                [ 10, 20 ],
            ],
        ],
        [
            [
                [ 10, 20 ],
                [ 30, 40 ],
                [ 50, 60 ],
                [ 10, 20 ],
            ],
            [
                [ 2.5, 3.5   ],
                [ 4.5, 8.5   ],
                [ 9.5, 10.5  ],
                [ 11.5, 12.5 ],
            ],
        ],
    ]), 'MULTIPOLYGON(((10 20, 30 40, 50 60, 10 20)), ((10 20, 30 40, 50 60, 10 20), (2.5 3.5, 4.5 8.5, 9.5 10.5, 11.5 12.5)))';
};

subtest "Make GEOMETRYCOLLECTION" => sub {
    is wkt_make_geometrycollection(
        [ POINT      => [ 12.5, 20.8 ] ],
        [ POLYGON    => [
            [
                [ 10, 20 ],
                [ 30, 40 ],
                [ 50, 60 ],
                [ 10, 20 ],
            ]
        ]],
        [ LINESTRING => [ [ 10.5, 20.8 ], [ 30.2, 4.5 ] ] ],
    ), 'GEOMETRYCOLLECTION(POINT(12.5 20.8), POLYGON((10 20, 30 40, 50 60, 10 20)), LINESTRING(10.5 20.8, 30.2 4.5))';

    is wkt_make(GEOMETRYCOLLECTION => [
        [ POINT      => [ 12.5, 20.8 ] ],
        [ POLYGON    => [
            [
                [ 10, 20 ],
                [ 30, 40 ],
                [ 50, 60 ],
                [ 10, 20 ],
            ],
        ]],
        [ LINESTRING => [ [ 10.5, 20.8 ], [ 30.2, 4.5 ] ] ],
    ]), 'GEOMETRYCOLLECTION(POINT(12.5 20.8), POLYGON((10 20, 30 40, 50 60, 10 20)), LINESTRING(10.5 20.8, 30.2 4.5))';
    # TODO: Test for recursive structured geometry collection
};

subtest "Invalid(or not supported) type of wkt should denied" => sub {
    is wkt_make(MULTIPOINT => []), undef;
};

done_testing;
