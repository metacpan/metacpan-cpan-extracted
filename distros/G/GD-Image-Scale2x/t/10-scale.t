use Test::More tests => 7;

use GD qw( :cmp );

use strict;
use warnings;

BEGIN {
    use_ok( 'GD::Image::Scale2x' );
}

my $image1x = GD::Image->new( 't/mslug2-1.png' );

{
    my $image2x = GD::Image->new( 't/mslug2-2.png' );
    my $scaled2x = $image1x->scale2x;
    isa_ok( $scaled2x, 'GD::Image' );
    ok( !( $image2x->compare( $scaled2x ) & GD_CMP_IMAGE ), 'scale2x' );
}

{
    my $image3x = GD::Image->new( 't/mslug2-3.png' );
    my $scaled3x = $image1x->scale3x;
    isa_ok( $scaled3x, 'GD::Image' );
    ok( !( $image3x->compare( $scaled3x ) & GD_CMP_IMAGE ), 'scale3x' );
}

{
    my $image4x = GD::Image->new( 't/mslug2-4.png' );
    my $scaled4x = $image1x->scale4x;
    isa_ok( $scaled4x, 'GD::Image' );
    ok( !( $image4x->compare( $scaled4x ) & GD_CMP_IMAGE ), 'scale4x' );
}
