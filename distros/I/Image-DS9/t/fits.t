#! perl

use strict;
use warnings;

use Test2::V0;
use Test::Lib;
use My::Util;

use Astro::FITS::Header;

my $ds9 = start_up( clear => 1 );
$ds9->block( to => 1 );
$ds9->smooth( !!0 );

sub _trim {
    my $string = shift;
    $string =~ s/\A\s+//;
    $string =~ s/\s+\z//;
    return $string;
}

subtest image => sub {

    ok( lives { $ds9->fits( M31_FITS ) }, 'load' )
      or note_res_error( $ds9 );
    $ds9->block( to => 1 );

    subtest 'new attr' => sub {
        my $frames;
        $frames = $ds9->frame( 'all' );
        is( 0+ @$frames, 1, 'single frame' )
          or diag pp( $frames );
        ok( lives { $ds9->fits( M31_FITS, { new => 1 } ) }, 'read into new frame' )
          or note_res_error( $ds9 );
        $frames = $ds9->frame( 'all' );
        is( 0+ @$frames, 2, 'two frames' )
          or diag pp( $frames );

        $ds9->frame( delete => $frames->[-1] );
    };


    test_stuff(
        $ds9,
        (
            fits => [
                width  => { in => 71 },
                height => { in => 71 },
                depth  => { in => 1 },
                bitpix => { in => 16 },
            ],
        ),
    );

    subtest size => sub {

        is( $ds9->fits( 'size' ) => [ 71, 71 ], 'no args' );
        is( $ds9->fits( size => wcs => 'degrees' ), [ 0.03374368, 0.03372827 ], 'wcs degrees' );
        is( $ds9->fits( size => wcs => 'arcmin' ),  [ 2.02462,    2.0237 ],     'wcs arcmin' );
        is( $ds9->fits( size => wcs => 'arcsec' ),  [ 121.477,    121.422 ],    'wcs arcsec' );

        is( $ds9->fits( size => fk5 => 'degrees' ), [ 0.03374368, 0.03372827 ], 'fk5 degrees' );
        is( $ds9->fits( size => fk5 => 'arcmin' ),  [ 2.02462,    2.0237 ],     'fk5 arcmin' );
        is( $ds9->fits( size => fk5 => 'arcsec' ),  [ 121.477,    121.422 ],    'fk5 arcsec' );

    };

    subtest header => sub {

        subtest primary => sub {
            my $hdr;
            ok( lives { $hdr = $ds9->fits( 'header' ) }, 'read primary' )
              or note_res_error( $ds9 );

            my @cards = split( /\n/, $hdr );
            my $fhdr  = Astro::FITS::Header->new( Cards => \@cards );

            is( $fhdr, D(), 'header object' );
            is( $ds9->fits( header => keyword => 'BITPIX' ), scalar $fhdr->value( 'BITPIX' ),
                'keyword bitpix' );
        };
    };
};

subtest events => sub {

    $ds9->frame( 'deleteall' );

    ok(
        lives {
            $ds9->fits(
                SNOOKER_FITS,
                {
                    extname => 'raytrace',
                    bin     => [ 'rt_x', 'rt_y' ],
                    new     => 1,
                },
            )
        },
        'load',
    ) or note_res_error( $ds9 );

    # need this so that the image generated below has more than one pixel.
    $ds9->bin( factor => 0.025 );
    $ds9->zoom( 0 );

    subtest 'read table' => sub {
        my $table;
        ok( lives { $table = $ds9->fits( 'table' ) }, 'get' )
          or note_res_error( $@ );
        ( undef, my $offset ) = get_fits_header_cards( $table );
        ( my $cards, $offset ) = get_fits_header_cards( $table, $offset );
        my $fhdr = Astro::FITS::Header->new( Cards => $cards );
        is( $fhdr,                   D(), 'header object' );
        is( $fhdr->value( 'SRFNO' ), 3,   'keyword object' );

        my $nframes = @{ $ds9->frame( 'all' ) };

        # round trip it.
        ok(
            lives {
                $ds9->fits(
                    \$table,
                    {
                        extname => 'raytrace',
                        bin     => [ 'rt_x', 'rt_y' ],
                        new     => 1,
                    },
                )
            },
            'send table',
        ) or note_res_error( $ds9 );
        is( @{ $ds9->frame( 'all' ) }, $nframes + 1, 'got a new frame' );
        my $clone;
        ok( lives { $clone = $ds9->fits( 'table' ) }, 'get' )
          or note_res_error( $@ );
        is( $clone, $table, 'round trip' );

    };

    subtest 'read image' => sub {
        my $image;
        ok( lives { $image = $ds9->fits( 'image' ) }, 'get' )
          or note_res_error( $@ );
        my ( $cards ) = get_fits_header_cards( $image );
        my $fhdr = Astro::FITS::Header->new( Cards => $cards );
        is( $fhdr,                            D(), 'header object' );
        is( _trim( $fhdr->value( 'NAXIS' ) ), 2,   'keyword NAXIS' );
    };

    # no idea what a slice is
    subtest 'read slice' => sub {
        my $slice;
        ok( lives { $slice = $ds9->fits( 'image' ) }, 'get' )
          or note_res_error( $@ );
        my ( $cards ) = get_fits_header_cards( $slice );
        my $fhdr = Astro::FITS::Header->new( Cards => $cards );
        is( $fhdr,                            D(), 'header object' );
        is( _trim( $fhdr->value( 'NAXIS' ) ), 2,   'keyword object' );
    };

};

done_testing;
