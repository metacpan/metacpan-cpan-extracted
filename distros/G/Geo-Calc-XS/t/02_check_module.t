use strict;
use warnings;
use utf8;

use Test::More;
BEGIN {
    my $needed_modules = [ 'Test::Deep', 'List::Util', 'Config' ];
    foreach my $module ( @{ $needed_modules } ) {
        eval "use $module";
        if ($@) {
            plan skip_all => join( ', ', @{ $needed_modules } ). " are needed";
        }
    }
}

use_ok( 'Geo::Calc::XS' );

my $gc_m  = Geo::Calc::XS->new( lat => 40.417875, lon => -3.710205, units => 'm' );
my $gc_m0 = Geo::Calc::XS->new( lat => 40.422371, lon => -3.704298, units => 'm' );
my $gc_km = Geo::Calc::XS->new( lat => 40.417875, lon => -3.710205, units => 'k-m' );
my $gc_mi = Geo::Calc::XS->new( lat => 34.159545, lon => -118.243103, units => 'mi' );
my $gc_ft = Geo::Calc::XS->new( lat => 34.159545, lon => -118.243103, units => 'ft' );

my @tests = (
    ## boundry_box
    # 1x1 km
    [sub { $gc_m->boundry_box( 1000, 1000, -6 ) }, { 'lat_max' => 40.422377, 'lon_max' => -3.704309, 'lon_min' => -3.7161, 'lat_min' => 40.413373 }, 'boundry box 1/1 km' ],
    [sub { $gc_m->boundry_box( 2000, 2000, -6 ) }, { 'lat_max' => 40.426878, 'lon_max' => -3.698414, 'lon_min' => -3.721995, 'lat_min' => 40.408872 }, 'boundry box 2/2 km' ],
    [sub { $gc_m->boundry_box( 2000, 2000, -12 ) }, { 'lat_max' => 40.426878090262, 'lon_max' => -3.698414102952, 'lon_min' => -3.721995897047, 'lat_min' => 40.408871900362 }, 'boundry box 2/2 km with 12 digits' ],

    # 2x2 km == 2000, 2000
    [sub { $gc_m->boundry_box( 1000, undef, -3 ) }, { 'lat_max' => 40.427, 'lon_max' => -3.698, 'lon_min' => -3.721, 'lat_min' => 40.409 }, 'boundry box 2/2 km with 1 args ( 1000, undef, -3 )' ],
    [sub { $gc_m->boundry_box( 1000, undef ) }, { 'lat_max' => 40.426878, 'lon_max' => -3.698414, 'lon_min' => -3.721995, 'lat_min' => 40.408872 }, 'boundry box 2/2 km with args ( 1000, undef )' ],
    [sub { $gc_m->boundry_box( 1000 ) }, { 'lat_max' => 40.426878, 'lon_max' => -3.698414, 'lon_min' => -3.721995, 'lat_min' => 40.408872 }, 'boundry box 2/2 km with args ( 1000 )' ],

    # 6x8 km == 6000x8000 meters
    [sub { $gc_m->boundry_box( 6000, 8000 ) }, { 'lat_max' => 40.453887, 'lon_max' => -3.674832, 'lon_min' => -3.745577, 'lat_min' => 40.381863 }, 'boundry box 6/8 km' ],

    ## destination_point
    [sub { $gc_m->destination_point( 44.3, 1000, -6 ) }, { 'lat' => 40.424321, 'lon' => -3.701973, 'final_bearing' => 44.305337 }, 'destination point 1' ],
    [sub { $gc_m->destination_point( 13.443, 1000, -6 ) }, $gc_km->destination_point( 13.443, 1, -6 ), 'destination point 2' ],

    ## distance_to
    [sub { $gc_m->distance_to( { lat => 40.422371, lon => -3.704298 } ) }, 707.106482, 'distance_to 40.422371/-3.704298' ],
    [sub { $gc_m->distance_to( $gc_m0 ) }, 707.106482, 'distance_to 40.422371/-3.704298 ( Geo::Calc::XS Object )' ],
    [sub { $gc_m->distance_to( { lat => 51.500795, lon => -0.142264 }, -3 ) }, 1269060.915, 'distance_to buckingham palace' ],

    ## midpoint
    [sub { $gc_m->midpoint_to( { lat => 40.422371, lon => -3.704298 }, -6 )  }, { 'lat' => 40.420123, 'lon' => -3.707251 }, 'midpoint' ],
    [sub { $gc_m->midpoint_to( $gc_m0, -6 )  }, { 'lat' => 40.420123, 'lon' => -3.707251 }, 'midpoint ( Geo::Calc::XS Object )' ],
    [sub { $gc_m->midpoint_to( { lat => 40.422371, lon => -3.704298 }, -6 ) }, $gc_km->midpoint_to( { lat => 40.422371, lon => -3.704298 }, -6 ), 'midpoints are the same' ],
    [sub { $gc_m->midpoint_to( { lat => 48.149367, lon => 11.748848 }, -6 )  }, { 'lat' => 44.543903, 'lon' => 3.506819 }, 'midpoint' ],

    ## intersection
    [sub { $gc_m->intersection( 90, { lat => 40.422371, lon => -3.704298 }, 180, -6 ) }, { 'lat' => 40.417875, 'lon' => -3.704298 }, 'intersection' ],
    [sub { $gc_m->intersection( 90, $gc_m0, 180, -6 ) }, { 'lat' => 40.417875, 'lon' => -3.704298 }, 'intersection ( Geo::Calc::XS Object )' ],
    [sub { $gc_m->intersection( 43, { lat => 40.729828, lon => -73.883743 }, 12, -6 ) }, { 'lat' => 54.967178, 'lon' => 85.065586 }, 'over intersection' ],

    ## distance_at
    [sub { $gc_m->distance_at() }, { m_lon => 84871.014948, m_lat => 111042.645811 }, 'distance at latitude' ],

    ## initial bearing
    [sub { $gc_m->bearing_to( { lat => 40.422371, lon => -3.704298 }, -6 ) }, 45.004851, 'initial bearing 1' ],
    [sub { $gc_m->bearing_to( $gc_m0, -6 ) }, 45.004851, 'initial bearing 1 ( Geo::Calc::XS Object )' ],
    [sub { $gc_m->bearing_to( { lat => 12, lon => -85 }, -6 ) }, 273.683864, 'initial bearing 2' ],
    [sub { $gc_m->bearing_to( { lat => 1, lon => 10 }, -6 ) }, 158.973869, 'initial bearing 3' ],
    [sub { $gc_m->bearing_to( { lat => 46, lon => 5 }, -6 ) }, 45.753222, 'initial bearing 4' ],

    ## final bearing
    [sub { $gc_m->final_bearing_to( { lat => 40.422371, lon => -3.704298 } ) }, 45.008681, 'final bearing' ],
    [sub { $gc_m->final_bearing_to( $gc_m0 ) }, 45.008681, 'final bearing ( Geo::Calc::XS Object )' ],
    [sub { $gc_m->final_bearing_to( { lat => 12, lon => -85 } ) }, 230.962738, 'final bearing' ],
    [sub { $gc_m->final_bearing_to( { lat => 1, lon => 10 } ) }, 164.144976, 'final bearing' ],
    [sub { $gc_m->final_bearing_to( { lat => 46, lon => 5 } ) }, 51.729940, 'final bearing' ],

    ## using rhumb
    [sub { $gc_m->rhumb_distance_to( { lat => 40.422371, lon => -3.704298 }, -6 ) }, 707.094665, 'rhumb distance' ],
    [sub { $gc_m->rhumb_distance_to( $gc_m0, -6 ) }, 707.094665, 'rhumb distance ( Geo::Calc::XS Object )' ],

    [sub { $gc_m->rhumb_bearing_to( { lat => 40.422371, lon => -3.704298 } ) }, 45.006766, 'rhumb bearing 1' ],
    [sub { $gc_m->rhumb_bearing_to( $gc_m0 ) }, 45.006766, 'rhumb bearing 1 ( Geo::Calc::XS Object )' ],
    [sub { $gc_m->rhumb_bearing_to( { lat => 12, lon => -85 } ) }, 248.409098, 'rhumb bearing 2' ],
    [sub { $gc_m->rhumb_bearing_to( { lat => 10, lon => -6 } ) }, 183.829572, 'rhumb bearing 3' ],
    [sub { $gc_m->rhumb_bearing_to( { lat => 46, lon => 5 } ) }, 48.644443, 'rhumb bearing 4' ],

    [sub { $gc_m->rhumb_destination_point( 30, 1000, -6 ) }, { 'lat' => 40.425663, 'lon' => -3.704298 }, 'rhumb destination point' ],
    [sub { $gc_m->rhumb_destination_point( 30, 1000, -6 ) }, $gc_km->rhumb_destination_point( 30, 1, -6 ), 'rhumb destination point' ],

    [sub { $gc_m->boundry_box( 1000, 1000, -6 ) }, $gc_km->boundry_box( 1, 1, -6 ), 'boundry box 1/1 km' ],
    [sub { $gc_m->boundry_box( 5500, 1200, -6 ) }, $gc_km->boundry_box( 5.5, 1.2, -6 ), 'boundry box 5.5/1.2 km' ],

    [sub { $gc_mi->boundry_box( 1, 1, -12 ) }, $gc_ft->boundry_box( 5280, 5280, -12 ), 'boundry box 1/1 mi' ],
    [sub { $gc_mi->distance_to( { lat => 40.422371, lon => -3.704298 } ) }, 6119.644619, 'distance_to 40.422371/-3.704298 in miles' ],
    [sub { $gc_mi->distance_to( $gc_m0 ) }, 6119.644619, 'distance_to 40.422371/-3.704298 in miles ( Geo::Calc::XS Object )' ],
    [sub { $gc_mi->distance_to( { lat => 40.853293, lon => -73.987427 }, -5 ) }, 2554.82647, 'distance_to NY -> LA' ],
);

for my $ra_test (@tests) {
    is_deeply($ra_test->[0]->(), $ra_test->[1], $ra_test->[2]);
}

SKIP:
{
    skip "useithreads disabled", 1 if ! $Config{useithreads};
    skip "environment variable SKIP_THREAD_TESTS is true", 1 if $ENV{SKIP_THREAD_TESTS};

    use_ok('threads');
    use_ok('Thread::Queue');

    my $ResultsQueue = Thread::Queue->new();
    my @threads;

    for my $ra_test (List::Util::shuffle @tests) {
        push @threads, threads->create(sub {
            $ResultsQueue->enqueue([$ra_test->[0]->(), $ra_test->[1], $ra_test->[2]]);
        });
    }

    for my $i (1..@tests) {
        my $ra_result = $ResultsQueue->dequeue();
        is_deeply($ra_result->[0], $ra_result->[1], "$ra_result->[2] (in a thread)");
    }

    for my $thread (@threads) {
        $thread->join();
    }

}

done_testing();
