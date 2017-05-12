use strict;

use Graphics::Color::RGB;
use Graphics::Primitive::Border;
use Graphics::Primitive::Canvas;
use Graphics::Primitive::Driver::GD;
use Graphics::Primitive::Operation::Fill;
use Graphics::Primitive::Operation::Stroke;
use Graphics::Primitive::Paint::Solid;

my $c = Graphics::Primitive::Canvas->new(
  background_color => Graphics::Color::RGB->new(
      red => 1, green => 1, blue => 0, alpha => 1
  ),
  width => 500, height => 350,
  border => new Graphics::Primitive::Border->new(
      color => Graphics::Color::RGB->new(
          red => 1, green => 0, blue => 0, alpha => 1
      ),
      width => 5
  )
);
$c->path->move_to(50, 50);
$c->path->line_to(20, 0);
$c->arc(50, 0, 1.14, 1);
$c->path->ellipse(40, 100, 1);

my $stroke = Graphics::Primitive::Operation::Stroke->new;
$stroke->brush->color(Graphics::Color::RGB->new(blue => 0, red => 0.3));
$stroke->brush->width(3);

$c->do($stroke);

$c->path->move_to(150, 150);
$c->path->line_to(120, 0);
$c->arc(50, 0, 1.14, 1);
$c->path->ellipse(40, 100, 1);

my $fill = Graphics::Primitive::Operation::Fill->new(
    paint => Graphics::Primitive::Paint::Solid->new(
        color => Graphics::Color::RGB->new(red => 1, green => 0, blue => 0)
    )
);
$c->do($fill);

my $driver = Graphics::Primitive::Driver::GD->new;

$driver->prepare($c);
$driver->finalize($c);
$driver->draw($c);
$driver->write('foo.png');
