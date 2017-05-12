use strict;
use warnings;
use Test::More;
use Math::Trig ':pi';

BEGIN { use_ok 'Math::Shape::Utils' };

# radians to degrees
is equal_floats(radians_to_degrees(pi2), 360.0), 1;
is equal_floats(radians_to_degrees(pi),  180.0), 1;
is equal_floats(radians_to_degrees(pip2), 90.0), 1;
is equal_floats(radians_to_degrees(pip4), 45.0), 1;
is equal_floats(radians_to_degrees(pip4), 90.0), 0;

# degrees to radians
is equal_floats(degrees_to_radians(360.0), pi2), 1;
is equal_floats(degrees_to_radians(180.0),  pi), 1;
is equal_floats(degrees_to_radians(90.0), pip2), 1;
is equal_floats(degrees_to_radians(182.0),  pi), 0;

#equal_floats
is equal_floats(pi, 3.14159265358979),  1;
is equal_floats(pi, 3.14159),           1;
is equal_floats(pi, 3.1),               0;
is equal_floats(pi, 3),                 0;
is equal_floats(pi, -3.14159265358979), 0;

#overlap
is overlap(1, 10, 2, 8), 1;
is overlap(9, 10, 2, 8), 0;

# min
is minimum(1,1),    1;
is minimum(2,1),    1;
is minimum(1,2),    1;
is minimum(-1,2),  -1;
is minimum(-1,-2), -2;

# max
is maximum(1,1),    1;
is maximum(2,1),    2;
is maximum(1,2),    2;
is maximum(-1,2),   2;
is maximum(-1,-2), -1;

#clamp_on_range
is clamp_on_range(1, 0, 10), 1;
is clamp_on_range(11, 0, 10), 10;
is clamp_on_range(-6, 0, 10), 0;

done_testing();
