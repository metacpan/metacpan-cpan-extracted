#! perl

use v5.10;
use strict;
use warnings;

use Test2::V0;
use Image::DS9;
use Image::DS9::Constants::V1
  'PAGE_SIZES',
  'PAGE_ORIENTATIONS',
  ;

use Test::Lib;
use My::Util;

my $ds9 = start_up();

test_stuff(
    $ds9,
    (
        pagesetup => [
            ( map { ( [qw( orient )], $_ ) } PAGE_ORIENTATIONS ),
            [qw( scale )] => 22.3,
            ( map { ( [qw( size )], $_ ) } PAGE_SIZES ),
        ],
    ) );

done_testing;
