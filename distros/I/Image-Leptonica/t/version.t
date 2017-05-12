use Test::More;
use strict;

use_ok( "Image::Leptonica" );


my $lept_version = "leptonica-1.71";
is( Image::Leptonica::getLeptonicaVersion(), $lept_version );


done_testing;
