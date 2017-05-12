use strict;
use Test::More 0.98;

use_ok $_ for qw(
    Imager::LineTrace::Figure
);

{
    my $figure = Imager::LineTrace::Figure->new( {
        points => [
            [ 0, 0 ]
        ],
        is_closed => 0,
        value => 0
    } );

    like( $figure->{type}, qr/Point/, 'Figure is point.' );
}

{
    my $figure = Imager::LineTrace::Figure->new( {
        points => [
            [ 0, 0 ],
            [ 1, 0 ]
        ],
        is_closed => 0,
        value => 0
    } );

    like( $figure->{type}, qr/Line/, 'Figure is line.' );
}

{
    my $figure = Imager::LineTrace::Figure->new( {
        points => [
            [ 0, 0 ],
            [ 1, 0 ],
            [ 1, 1 ]
        ],
        is_closed => 0,
        value => 0
    } );

    like( $figure->{type}, qr/Polyline/, 'Figure is polyline.' );
}

{
    my $figure = Imager::LineTrace::Figure->new( {
        points => [
            [ 0, 0 ],
            [ 1, 0 ],
            [ 1, 1 ],
            [ 0, 1 ]
        ],
        is_closed => 1,
        value => 0
    } );

    like( $figure->{type}, qr/Polygon/, 'Figure is polygon.' );
}

done_testing;

