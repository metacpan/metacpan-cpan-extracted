use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::EOLTests 0.17

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Math/Shape/Circle.pm',
    'lib/Math/Shape/Line.pm',
    'lib/Math/Shape/LineSegment.pm',
    'lib/Math/Shape/OrientedRectangle.pm',
    'lib/Math/Shape/Range.pm',
    'lib/Math/Shape/Rectangle.pm',
    'lib/Math/Shape/Utils.pm',
    'lib/Math/Shape/Vector.pm',
    't/Circle.t',
    't/Line.t',
    't/LineSegment.t',
    't/OrientedRectangle.t',
    't/Range.t',
    't/Rectangle.t',
    't/Utils.t',
    't/Vector.t',
    't/collision.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
