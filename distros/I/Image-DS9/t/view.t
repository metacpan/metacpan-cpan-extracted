#! perl

use v5.10;
use strict;
use warnings;

use Test2::V0;
use Image::DS9;
use Image::DS9::Constants::V1 'WCS', 'GRAPH_ORIENTATIONS', 'VIEW_BOOL_COMPONENTS', 'VIEW_LAYOUTS',
  'RGB_COMPONENTS';

use List::Util 'zip';
use Test::Lib;
use My::Util;

my $ds9     = start_up();
my $version = $ds9->version;

my @reset  = ( VIEW_BOOL_COMPONENTS, 'layout' );
my @status = map { scalar $ds9->view( $_ ) } @reset;


test_stuff(
    $ds9,
    (
        view => [
            ( map { ( $_ => !!0, $_ => !!1 ) } VIEW_BOOL_COMPONENTS, ),
            ( map { ( $_ => !!0, $_ => !!1 ) } ( map { [ 'graph', $_ ] } GRAPH_ORIENTATIONS ) ),

            # get for RGB doesn't work in 8.4.1
            (
                map {
                    (
                        $_ => { out => !!0, in => ( $version == v8.4.1 ? undef : !!0 ) },
                        $_ => { out => !!1, in => ( $version == v8.4.1 ? undef : !!1 ) },
                    )
                } RGB_COMPONENTS
            ),
            keyvalue => 'snapfraggle',
            ( map { ( layout => $_ ) } VIEW_LAYOUTS ),

        ],
    ) );

# reset some things
$ds9->view( @{$_} ) for zip \@reset, \@status;

done_testing;
