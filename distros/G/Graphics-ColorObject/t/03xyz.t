use Test::More tests => 2;
BEGIN { use_ok('Graphics::ColorObject') };

ok( Graphics::ColorObject::_delta_v3( 
    Graphics::ColorObject->new_XYZ([0.634215, 0.3279658, 0.9477849], space => 'Apple RGB')->as_RGB(), 
    [1, 0, 1] 
) < 0.0005 );
