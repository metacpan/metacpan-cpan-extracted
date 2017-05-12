use Test::More tests => 4;
BEGIN { use_ok('Graphics::ColorObject') };

ok( Graphics::ColorObject::_delta_v3( 
    Graphics::ColorObject->new_XYZ([0.634215, 0.327965, 0.947785], white_point => 'D65')->as_Lab(),
    [63.995843, 92.111668, -53.029855] 
) < 0.05 );

ok( Graphics::ColorObject::_delta_v3( 
    Graphics::ColorObject->new_XYZ([0.634215, 0.327965, 0.947785], white_point => 'D65')->as_LCHab(),
    [63.995843, 106.286052, -29.92958] 
) < 0.005 );

ok( Graphics::ColorObject::_delta_v3( 
    Graphics::ColorObject->new_Lab([63.995843, 92.111668, -53.029855], white_point => 'D65')->as_XYZ(),
    [0.634215, 0.327965, 0.947785]
) < 0.005 );

