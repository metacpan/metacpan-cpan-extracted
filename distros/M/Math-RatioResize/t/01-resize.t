use strict;
use warnings;

use Test::More;
use Test::Exception;

use Math::RatioResize;

my $gif;

{
    my $w = 360;
    my $h = 240;

    my $target_w = 100;
    my $target_h = 66.66;

    ok( ( $w, $h ) = Math::RatioResize->resize( w => $w, h => $h, max_w => $target_w ), "returned ok" );

    ok( $w == $target_w, "w is ok ($w)" );
    ok( substr($h, 0, 5) eq $target_h, "h is ok ($h)" );
}

{
    my $w = 360;
    my $h = 240;

    my $target_w = 150;
    my $target_h = 100;

    ok( ( $w, $h ) = Math::RatioResize->resize( w => $w, h => $h, max_h => $target_h ), "returned ok" );

    ok( $w == $target_w, "w is ok ($w)" );
    ok( $h == $target_h, "h is ok ($h)" );
}






done_testing();
