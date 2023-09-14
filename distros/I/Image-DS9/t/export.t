#! perl

use v5.10;
use strict;
use warnings;

use Test2::V0;
use Image::DS9;
use Image::DS9::Constants::V1 'EXPORT_FORMATS_NOARGS', 'ENDIANNESS', 'EXPORT_TIFF_ARGS';
use Path::Tiny;

use Test::Lib;
use My::Util;
use Test::TempDir::Tiny;

my $ds9 = start_up( image => 1 );

in_tempdir 'noargs' => sub {
    my $cwd = path( shift );
    test_stuff(
        $ds9,
        (
            export => [
                ( map { ( $_ => { out => [ $cwd->child( $_ )->stringify ] } ) } EXPORT_FORMATS_NOARGS ),

                ( map { ( array => { out => [ $cwd->child( $_ )->stringify, $_ ] } ) } ENDIANNESS ),
                ( map { ( nrrd  => { out => [ $cwd->child( $_ )->stringify, $_ ] } ) } ENDIANNESS ),
                ( map { ( tiff  => { out => [ $cwd->child( $_ )->stringify, $_ ] } ) } EXPORT_TIFF_ARGS ),

                (
                    map {
                        ( envi =>
                              { out => [ $cwd->child( $_ . '.hdr' )->stringify, $cwd->child( $_ . '.data' )->stringify, $_ ] } )
                    } ENDIANNESS
                ),

            ],
        ) );

};

done_testing;
