#! perl

use v5.10;
use strict;
use warnings;

use Test2::V0;
use Image::DS9;
use Image::DS9::Constants::V1
  'PRINT_DESTINATIONS',
  'PRINT_COLORS',
  'PRINT_LEVELS',
  'PRINT_RESOLUTIONS';

use Test::Lib;
use My::Util;

my $ds9     = start_up();
my $version = $ds9->version;

test_stuff(
    $ds9,
    (
        print => [
            ( map { ( destination => $_ ) } PRINT_DESTINATIONS ),
            command  => 'print_this',
            filename => 'print_this.ps',
            ( map { ( color => $_ ) } PRINT_COLORS ),
            ( map { ( level => $_ ) } PRINT_LEVELS ),
            (
                map { ( resolution => $_ ) }
                map { $version <= v8.4.1 && $_ eq 'screen' ? 'Screen' : $_ } PRINT_RESOLUTIONS
            ),
        ],
    ) );

done_testing;
