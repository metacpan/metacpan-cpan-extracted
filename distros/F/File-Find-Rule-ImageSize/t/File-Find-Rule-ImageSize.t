#!perl -w
use strict;
use Test::More tests => 4;

use File::Find::Rule::ImageSize;
is_deeply( [ find( image_x => 640, maxdepth => 2, in => 't' ) ],
           [ 't/happy-baby.JPG' ], "x == 640" );

is_deeply( [ find( image_x => 641, maxdepth => 2, in => 't' ) ],
           [ ] );

is_deeply( [ find( image_y => 480, maxdepth => 2, in => 't' ) ],
           [ 't/happy-baby.JPG' ], "y == 480" );

is_deeply( [ find( image_y => 481, maxdepth => 2, in => 't' ) ],
           [ ] );
