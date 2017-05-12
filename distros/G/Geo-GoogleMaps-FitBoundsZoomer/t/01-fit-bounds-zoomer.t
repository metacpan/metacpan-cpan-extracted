use 5.10.0;
use strict;
use warnings;

use Test::More tests => 49;
use Test::Exception;

use Geo::GoogleMaps::FitBoundsZoomer;

use constant PRECISION_DELTA =>  0.00001; # care to ~ 1m precision

# the zoom levels and coordinates were aquired by using GoogleMaps API.
my @max_google_zoom_test_data = (

    # square map
    {
        width       => 500,
        height      => 500,
        marker_coords_array => 
            [{'lat' => 43.71419491549136,
              'long' => -79.38574782259177},
             {'lat' => 43.71458749889745,
              'long' => -79.38511482126425}],
        zoom_level => 20,
    },

    {
        width       => 500,
        height      => 500,
        marker_coords_array => 
            [{'lat' => 43.54790152241965,
              'long' => -80.43324297911833},
             {'lat' => 43.4886485416885,
              'long' => -80.10021990782927}],
        zoom_level => 11,
    },

   {
        width       => 500,
        height      => 500,
        marker_coords_array =>
            [{'lat' => 47.55390637961721,
              'long' => -55.17110949999999},
             {'lat' => 67.08860849498518,
              'long' => -139.5461095}],
        zoom_level => 3,
    },
    
    # small map
    {
        width       => 218,
        height      => 216,
        marker_coords_array =>
            [{'lat' => 43.61578584092233,
              'long' => -80.28310901171874},
             {'lat' => 44.06744876361351,
              'long' => -79.18996936328124}],
        zoom_level => 8,
    },

    # large map
    {
        width       => 425,
        height      => 460,
        marker_coords_array =>
            [{'lat' => 49.15596920563539,
              'long' => -122.90825969226073},
             {'lat' => 49.18683298472213,
              'long' => -122.83822185046385}],
        zoom_level => 13,
    },

    # large map, 4 nodes
    {
        width       => 425,
        height      => 460,
        marker_coords_array =>
            [{'lat' => 53.459178698913874,
              'long' => -113.62339622027586},
             {'lat' => 53.66472718846658,
              'long' => -113.26496726519774},
             {'lat' => 53.476345900203846,
              'long' => -113.24711448199461},
             {'lat' => 53.52045825624463,
              'long' => -113.80879050738524}],
        zoom_level => 10,
    },

    # tall map 1 (markers at top and bottom)
    {
        width       => 200,
        height      => 500,
        marker_coords_array =>
            [{'lat' => 43.22787770197578,
              'long' => -70.59887534625243},
             {'lat' => 56.388582666287625,
              'long' => -72.84008628375243}],
        zoom_level => 5,
    },

    # tall map 2 (markers on left and right)
    {
        width       => 200,
        height      => 500,
        marker_coords_array =>
            [{'lat' => 51.997297168039665,
              'long' => -63.699461283752434},
             {'lat' => 50.79090410074657,
              'long' => -55.481687846252434}],
        zoom_level => 5,
    },

    
    # wide map
    {
        width       => 550,
        height      => 150,
        marker_coords_array =>
            [{'lat' => 50.596038508785256,
              'long' => -119.11450034625243},
             {'lat' => 52.40131573357405,
              'long' => -95.64770347125243}],
        zoom_level => 5,
    },
    
    # earth map
    {
        width       => 700,
        height      => 800,
        marker_coords_array =>
            [{'lat' => 82.14988053130267,
              'long' => -153.96016399999974},
             {'lat' => -83.33284390134914,
              'long' => 145.57108800000026}],
        zoom_level => 1,
    },

    
    # earth map -> smallest single tile map
    {
        width       => 260,
        height      => 260,
        marker_coords_array =>
            [{'lat' => 82.14988053130267,
              'long' => -153.96016399999974},
             {'lat' => -83.33284390134914,
              'long' => 145.57108800000026}],
        zoom_level => 0,
    },
    
    # single map point
    {
        width       => 260,
        height      => 260,
        marker_coords_array =>
            [{'lat' => -83.33284390134914,
              'long' => 145.57108800000026}],
        zoom_level => 20,
    },
    
    # single map point (middle-earth)
    {
        width       => 260,
        height      => 260,
        marker_coords_array =>
            [{'lat' =>  0,
              'long' => 0}],
        zoom_level => 20,
    },
    
    # edge case - pixel map
    {
        width       => 1,
        height      => 1,
        marker_coords_array =>
            [{'lat' =>  0,
              'long' => 0}],
        zoom_level => 20,
    },

    # edge case - extreme point
    {
        width       => 1,
        height      => 1,
        marker_coords_array =>
            [{'lat'  =>  90,
              'long' => 180}],
        zoom_level => 20,
    },


    # edge case - extreme bounding box
    {
        width       => 1,
        height      => 1,
        marker_coords_array =>
            [{'lat'  =>  90,
              'long' => 180},
             {'lat'  => -90,
              'long' => -180}],
        zoom_level => 0,
    },
);

# generic tests - vary points and map geometry
foreach my $test_case (@max_google_zoom_test_data) {
    my $zoomer = Geo::GoogleMaps::FitBoundsZoomer::->new(
                      points => $test_case->{marker_coords_array}, 
			          width  => $test_case->{width}, 
			          height => $test_case->{height}); 
	is (
        $zoomer->max_bounding_zoom(),
		$test_case->{zoom_level}, 
		'max_bounding_zoom - generic test' 
	);
}

# zoom limit constructor test
my $test_case = {
        width       => 500,
        height      => 500,
        marker_coords_array => 
        [{'lat' => 43.71419491549136,
          'long' => -79.38574782259177},
         {'lat' => 43.71458749889745,
          'long' => -79.38511482126425}],
         zoom_level => 20
    };

my $zoomer = Geo::GoogleMaps::FitBoundsZoomer::->new(
                  points => $test_case->{marker_coords_array}, 
                  width  => $test_case->{width}, 
                  height => $test_case->{height},
                  zoom_limit => 19); 
is (
    $zoomer->max_bounding_zoom(),
    19, 
    'max_bounding_zoom: zoom limit constructor test' 
);

# getter test (no params) max_bounding_zoom
is ($zoomer->max_bounding_zoom(), 19, 'max_bounding_zoom getter test');

# getter test (no params) bounding_box_center
my $bb_center = $zoomer->bounding_box_center();
ok ( $bb_center->{lat}  > 0 , 'bounding_box_center: getter test - lat positive' ); 
ok ( $bb_center->{long} < 0 , 'bounding_box_center: getter test - long negative');

ok ( (abs ( $bb_center->{lat} )  - 43.7143912071944) < PRECISION_DELTA , 'bounding_box_center: getter test - lat precision delta');
ok ( (abs ( $bb_center->{long} ) - 79.385431321928)  < PRECISION_DELTA , 'bounding_box_center: getter test - long precision delta');


# update map parameters for existing instance using max_bounding_zoom
$test_case =  {
        width       => 425,
        height      => 460,
        marker_coords_array =>
            [{'lat' => 53.459178698913874,
              'long' => -113.62339622027586},
             {'lat' => 53.66472718846658,
              'long' => -113.26496726519774},
             {'lat' => 53.476345900203846,
              'long' => -113.24711448199461},
             {'lat' => 53.52045825624463,
              'long' => -113.80879050738524}],
        zoom_level => 10,
    };

is ( $zoomer->max_bounding_zoom(
            points => $test_case->{marker_coords_array}, 
            width  => $test_case->{width}, 
            height => $test_case->{height},
            zoom_limit => 20), # reset zoom limit
            $test_case->{zoom_level},
            'max_bounding_zoom: update existing instance params'
   ); 


# retest getter (no params) bounding_box_center
$bb_center = $zoomer->bounding_box_center();
ok ( $bb_center->{lat}  > 0 , 'bounding_box_center: retest getter following param update - lat positive' );
ok ( $bb_center->{long} < 0 , 'bounding_box_center: retest getter following param update - long negative');

ok ( (abs ( $bb_center->{lat} )  - 53.5619529436902)  < PRECISION_DELTA , 'bounding_box_center: retest getter following param update - lat precision delta');
ok ( (abs ( $bb_center->{long} ) - 113.52795249469 )  < PRECISION_DELTA , 'bounding_box_center: retest getter following param update - long precision delta');


# update with middle-earth point
$test_case = {
        width       => 260,
        height      => 260,
        marker_coords_array =>
            [{'lat' =>  0,
              'long' => 0}],
        zoom_level => 20
    };

is ( $zoomer->max_bounding_zoom(
            points => $test_case->{marker_coords_array}, 
            width  => $test_case->{width}, 
            height => $test_case->{height}),
            $test_case->{zoom_level},
            'max_bounding_zoom: update with middle-earth'
   ); 

# test middle-earth bounding_box_center
is_deeply ( $zoomer->bounding_box_center(), 
            { lat => 0, long => 0 }, 
            'bounding_box_center: middle-earth');

# lat < 90
$test_case = {
        marker_coords_array =>
            [{'lat' =>  -91,
              'long' => 180}],
        zoom_level => 20
    };

throws_ok { $zoomer->max_bounding_zoom(points => $test_case->{marker_coords_array}) }
            qr/Point latitude out of bounds \( < -90 or > 90 \)/,
            'max_bounding_zoom: lat < -90 caught'; 

# lat > 90
$test_case = {
        marker_coords_array =>
            [{'lat'  =>  91,
              'long' => 180}],
        zoom_level => 20
    };

throws_ok { $zoomer->max_bounding_zoom(points => $test_case->{marker_coords_array}) }
            qr/Point latitude out of bounds \( < -90 or > 90 \)/,
            'max_bounding_zoom: lat > 90 caught'; 

# long < -180
$test_case = {
        marker_coords_array =>
            [{'lat' =>  90,
              'long' => -181}],
        zoom_level => 20
    };

throws_ok { $zoomer->max_bounding_zoom(points => $test_case->{marker_coords_array}) }
            qr/Point longitude out of bounds \( < -180 or > 180 \)/,
            'max_bounding_zoom: long < -180 caught'; 

# long > 180
$test_case = {
        marker_coords_array =>
            [{'lat' =>  90,
              'long' => 181}],
        zoom_level => 20
    };

throws_ok { $zoomer->max_bounding_zoom(points => $test_case->{marker_coords_array}) }
            qr/Point longitude out of bounds \( < -180 or > 180 \)/,
            'max_bounding_zoom: lat > 180 caught'; 

# no map `points` param
$zoomer = Geo::GoogleMaps::FitBoundsZoomer::->new(
                  width  => 400,
                  height => 400);

throws_ok { $zoomer->max_bounding_zoom() }
            qr/No map points parameter!/,
            'max_bounding_zoom: no map points parameter'; 

# no map `height` param
$zoomer = Geo::GoogleMaps::FitBoundsZoomer::->new(
                  points => [ { lat => 70, long => 70 } ],
                  width  => 400);

throws_ok { $zoomer->max_bounding_zoom() }
            qr/No map height parameter!/,
            'max_bounding_zoom: no map height parameter'; 

# no map `height` param
$zoomer = Geo::GoogleMaps::FitBoundsZoomer::->new(
                  points => [ { lat => 70, lon => 70 } ],
                  height => 400);

throws_ok { $zoomer->max_bounding_zoom() }
            qr/No map width parameter!/,
            'max_bounding_zoom: no map width parameter'; 

# no map points (empty array ref)
$zoomer = Geo::GoogleMaps::FitBoundsZoomer::->new(
                  points => [],
                  width  => 400,
                  height => 400);

throws_ok { $zoomer->max_bounding_zoom() }
            qr/At least one point must be provided!/,
            'max_bounding_zoom: map points undef'; 

# zero map width
$zoomer = Geo::GoogleMaps::FitBoundsZoomer::->new(
                  points => [ { lat => 70, long => 70 } ],
                  width  => 0,
                  height => 400);

throws_ok { $zoomer->max_bounding_zoom() }
            qr/Map width must be a positive number!/,
            'max_bounding_zoom: zero map width'; 

# zero map height
$zoomer = Geo::GoogleMaps::FitBoundsZoomer::->new(
                  points => [ { lat => 70, long => 70 } ],
                  width  => 400,
                  height => 0);

throws_ok { $zoomer->max_bounding_zoom() }
            qr/Map height must be a positive number!/,
            'max_bounding_zoom: zero map height'; 

# negative zoom limit
$zoomer = Geo::GoogleMaps::FitBoundsZoomer::->new(
                  points => [ { lat => 70, long => 70 } ],
                  width  => 400,
                  height => 400,
                  zoom_limit => -1);

throws_ok { $zoomer->max_bounding_zoom() }
            qr/Zoom limit must be greater of equal to 0!/,
            'max_bounding_zoom: zoom limit less than 0'; 

# cluster center - points, but no bounds 
$zoomer = Geo::GoogleMaps::FitBoundsZoomer::->new(
                  points => [ { lat => 70, long => 70 } ],
                  width  => 400,
                  height => 400,
                  zoom_limit => -1);

throws_ok { $zoomer->bounding_box_center() }
            qr/Map data not initialized! max_bounding_zoom needs to be called first/,
            'bounding_box_center: no bounds'; 



# cluster center - no points 
$zoomer = Geo::GoogleMaps::FitBoundsZoomer::->new(
                  width  => 400,
                  height => 400,
                  zoom_limit => -1);

throws_ok { $zoomer->bounding_box_center() }
            qr/Map data not initialized! max_bounding_zoom needs to be called first/,
            'bounding_box_center: no points'; 


my @get_bounds_test_data = (    # top left quadrant
                                {
                                    marker_coords_array =>
                                        [ {'lat' => 81.92, 'long' => -141.33 }, 
                                          {'lat' => 70.07, 'long' => -99.84 },
                                        ],
                                    bounds => { 'blp' => {'lat' => 70.07, 'long' => -141.33}, 'trp' => {'lat' => 81.92, 'long' => -99.84} }, 
                                },

                                # top right quadrant
                                {
                                    marker_coords_array =>
                                        [ {'lat' => 65.37, 'long' => 106.88 }, 
                                          {'lat' => 78.49, 'long' => 151.88 },
                                        ],
                                    bounds => { 'blp' => {'lat' => 65.37, 'long' => 106.88}, 'trp' => {'lat' => 78.49, 'long' => 151.88} }, 
                                },

                                # bottom left quadrant
                                {
                                    marker_coords_array => 
                                        [ {'lat' => -74.59, 'long' => -148.36 }, 
                                          {'lat' => -39.09, 'long' => -67.70 },
                                        ],
                                    bounds => { 'blp' => {'lat' => -74.59, 'long' => -148.36}, 'trp' => {'lat' => -39.09, 'long' => -67.70} },
                                },

                                # bottom right quadrant
                                {
                                    marker_coords_array => 
                                        [ {'lat' => -28.30, 'long' => 135.70 }, 
                                          {'lat' => -84.47, 'long' => 46.40 },
                                        ],
                                    bounds => { 'blp' => {'lat' => -84.47, 'long' => 46.40}, 'trp' => {'lat' => -28.30, 'long' => 135.70} },
                                },
                                
                                # northen hemisphere
                                {   
                                    marker_coords_array => 
                                        [ {'lat' => -67.33, 'long' => -108.28 }, 
                                          {'lat' =>  21.44, 'long' =>  115.34 },
                                        ],

                                    bounds => { 'blp' => {'lat' => -67.33, 'long' => -108.28}, 'trp' => {'lat' => 21.44, 'long' => 115.34} },
                                },

                                # southern hemisphere
                                {
                                    marker_coords_array =>
                                        [ {'lat' => -29.55, 'long' =>  149.32 }, 
                                          {'lat' => -4.91,  'long' => -164.53 },
                                        ],
                                    bounds => { 'blp' => {'lat' => -29.55, 'long' => -164.53}, 'trp' => {'lat' => -4.91, 'long' => 149.32} },
                                },

                                # earth
                                {
                                    marker_coords_array => 
                                        [ {'lat' =>  80.29, 'long' => -146.25 }, 
                                          {'lat' => -76.99, 'long' => -131.48 },
                                        ],
                                    bounds => { 'blp' => {'lat' => -76.99, 'long' => -146.25}, 'trp' => {'lat' => 80.29, 'long' => -131.48} },
                                },
                           );

foreach my $test_case (@get_bounds_test_data) {

    my $zoomer = Geo::GoogleMaps::FitBoundsZoomer::->new( points => $test_case->{marker_coords_array}, width => 400, height => 400 );
    is_deeply (
        $zoomer->_get_bounds(),
        $test_case->{bounds},
        '_get_bounds'
    );
}
