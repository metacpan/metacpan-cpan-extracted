use Test::More tests => 7;

use Geometry::Primitive::Circle;
use Geometry::Primitive::Line;
use Graphics::Color::RGB;

BEGIN {
    use_ok('Graphics::Primitive::Paint::Gradient::Linear');
    use_ok('Graphics::Primitive::Paint::Gradient::Radial');
}

my $line = Graphics::Primitive::Paint::Gradient::Linear->new(
    line => Geometry::Primitive::Line->new(
        start => [0, 0],
        end => [10, 10]
    )
);
isa_ok($line, 'Graphics::Primitive::Paint::Gradient::Linear');

my $red = Graphics::Color::RGB->new(red => 1, green => 0, blue => 0);
my $blue = Graphics::Color::RGB->new(red => 0, green => 0, blue => 1);

cmp_ok($line->stop_count, '==', 0, 'stop count');

$line->add_stop(0.0, $red);
cmp_ok($line->stop_count, '==', 1, 'stop count');
$line->add_stop(0.75, $blue);

my @stops = $line->stops;
cmp_ok(scalar(@stops), '==', 2, '2 stops');

my $rad = Graphics::Primitive::Paint::Gradient::Radial->new(
    start => Geometry::Primitive::Circle->new(
        origin => [0, 0],
        radius => 5
    ),
    end => Geometry::Primitive::Circle->new(
        origin => [10, 10],
        radius => 3
    )
);
isa_ok($rad, 'Graphics::Primitive::Paint::Gradient::Radial');
