use Test::More tests => 7;

use Geometry::Primitive::Arc;
use Geometry::Primitive::Bezier;
use Geometry::Primitive::Circle;
use Geometry::Primitive::Line;
use Geometry::Primitive::Point;
use Geometry::Primitive::Polygon;
use Geometry::Primitive::Rectangle;

my $arc = Geometry::Primitive::Arc->new(radius => 5, angle_start => 15, angle_end => 45);
my $arc2 = Geometry::Primitive::Arc->thaw($arc->freeze({ format => 'JSON' }), { format => 'JSON' });
is_deeply($arc, $arc2, 'arc deserialized');

my $bezier = Geometry::Primitive::Bezier->new(
    control1 => [ 0, 0 ],
    control2 => [ 10, 10 ],
    start => [0, 0 ],
    end => [ 5, 5 ]
);
my $bezier2 = Geometry::Primitive::Bezier->thaw($bezier->freeze({ format => 'JSON' }), { format => 'JSON' });
is_deeply($bezier, $bezier2, 'bezier deserialized');

my $circle = Geometry::Primitive::Circle->new(
    radius => 5, origin => [ 10, 10 ]
);
my $circle2 = Geometry::Primitive::Circle->thaw($circle->freeze({ format => 'JSON' }), { format => 'JSON' });
is_deeply($circle, $circle2, 'circle deserialized');

my $line = Geometry::Primitive::Line->new(
    start => [ 0, 0 ], end => [ 10, 10 ]
);
my $line2 = Geometry::Primitive::Line->thaw($line->freeze({ format => 'JSON' }), { format => 'JSON' });
is_deeply($line, $line2, 'line deserialized');

my $point = Geometry::Primitive::Point->new(x => 1, y => 5);
my $point2 = Geometry::Primitive::Point->unpack($point->pack);
ok($point->equal_to($point2), 'point equal_to');

my $polygon = Geometry::Primitive::Polygon->new;
$polygon->add_point(Geometry::Primitive::Point->new(x => 0, y => 10));
$polygon->add_point(Geometry::Primitive::Point->new(x => 5, y => 10));
$polygon->add_point(Geometry::Primitive::Point->new(x => 10, y => 10));
my $polygon2 = Geometry::Primitive::Polygon->thaw($polygon->freeze({ format => 'JSON'}), { format => 'JSON' });
is_deeply($polygon, $polygon2, 'polygon deserialized');

my $rect = Geometry::Primitive::Rectangle->new(
    origin => [0, 0], width => 100, height => 25
);
my $rect2 = Geometry::Primitive::Rectangle->thaw($rect->freeze({ format => 'JSON' }), { format => 'JSON' });
is_deeply($rect, $rect2, 'rectangle deserialized');