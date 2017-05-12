use Test::More tests => 4;
BEGIN { use_ok('Graphics::ColorObject') };

ok( Graphics::ColorObject::_delta_v3( 
    Graphics::ColorObject->new_RGBhex('#FFFFFF', space => 'Apple RGB')->as_XYZ(),
    [0.950466, 0.999999, 1.088969] 
) < 0.00005 );

ok( Graphics::ColorObject::_delta_v3( 
    Graphics::ColorObject->new_RGBhex('#FF00FF', space => 'Apple RGB')->as_XYZ(),
    [0.634215, 0.327965, 0.947785] 
) < 0.00005 );

ok( Graphics::ColorObject->new_RGBhex('#A1B2C3', space => 'Apple RGB')->as_RGBhex() eq 'A1B2C3' );
