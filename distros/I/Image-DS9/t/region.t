#! perl

use v5.10;
use strict;
use warnings;

use Test2::V0;
use Data::Dump 'pp';

use Image::DS9;
use Image::DS9::Constants::V1 -sky_coord_systems, -angular_formats, -frame_coord_systems,
  -region_formats,
  'ANGULAR_FORMATS',
  'COLORS',
  'FRAME_COORD_SYSTEMS',
  'SKY_COORD_SYSTEMS',
  ;

use Test::Lib;
use My::Util;

diag( 'not fully implemented or tested' );

my $ds9 = start_up( image => 1 );
$ds9->zoom( 0 );

test_stuff(
    $ds9,
    (
        region => [
            ( map { ( 'format' => $_ ) } qw( ciao saotng saoimage pros xy ds9 ) ),
            ( map { ( sky      => $_ ) } grep { !/^(?:B1950|J2000)/i } SKY_COORD_SYSTEMS ),
            sky => { out => ['j2000'], in => ['fk5'] },
            sky => { out => ['b1950'], in => ['fk4'] },
            ( map { ( skyformat => $_ ) } ANGULAR_FORMATS ),
            ( map { ( system    => $_ ) } FRAME_COORD_SYSTEMS ),
            ( map { ( color     => $_ ) } COLORS ),
            width => 3,
            width => 1,
            strip => !!0,
            strip => !!1,
        ],
    ) );


sub parse_get_region {

    $ds9->region( format    => REGION_FORMAT_DS9 );
    $ds9->region( sky       => SKY_COORDSYS_FK5 );
    $ds9->region( system    => FRAME_COORDSYS_WCS );
    $ds9->region( skyformat => ANGULAR_FORMAT_DEGREES );
    $ds9->region( strip     => 0 );

    my @lines = split( /\n/, $ds9->region );

    # remove header lines
    shift @lines while $lines[0] =~ /^#/;

    # next line should list attributes
    shift @lines if $lines[0] =~ /^global/;

    return join( q{}, @lines );
}

# ok, now we get to play

ok( lives { $ds9->region( 'deleteall' ) }, 'region deleteall' )
  or note $@;

# center the image and grab the coords
$ds9->frame( 'center' );
my $coords = $ds9->pan( 'wcs', SKY_COORDSYS_FK5, ANGULAR_FORMAT_DEGREES );

my $region = sprintf( '# text(%s, %s) color=red text={Hello}', @{$coords} );

## no critic (RegularExpressions::ProhibitComplexRegexes)

use Regexp::Common 'number';

my $expected_region = qr/fk5\h*[#]
       \h*text
       [(]
       ($RE{num}{real}), ($RE{num}{real})
       [)]
       \h+color=(.*)
       \h+text=[{](.*)[}]$/x;

sub check_region {

    my $got = shift;
    my $ctx = context;

    my ( $ra, $dec, $color, $text ) = $got =~ $expected_region;

    # no idea why these change.
    is( $ra,    within( 10.7013046, 1e-3 ), 'ra' );
    is( $dec,   within( 41.2703684, 1e-3 ), 'dec' );
    is( $color, 'red',                      'color' );
    is( $text,  'Hello',                    'text' );

    $ctx->release;
}

subtest 'region scalar' => sub {
    ok(
        lives {
            $ds9->region( 'deleteall' );
            $ds9->region( $region );
        },
        'set',
    ) or note $@, pp $region, pp( $ds9->res );

    subtest 'get' => sub {
        check_region( parse_get_region );
    };

};

subtest 'region scalarref' => sub {
    ok(
        lives {
            $ds9->region( 'deleteall' );
            $ds9->region( \$region );
        },
        'region scalarref set',
    ) or note $@, pp( $ds9->res );

    subtest 'get' => sub {
        check_region( parse_get_region );
    };
};

done_testing;
