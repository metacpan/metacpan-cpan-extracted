use strict;

use Graphics::Color::RGB;
use Graphics::Primitive::Border;
use Graphics::Primitive::Component;
use Graphics::Primitive::Driver::GD;

my $c = Graphics::Primitive::Component->new(
  background_color => Graphics::Color::RGB->new(
      red => 1, green => 1, blue => 0, alpha => 1
  ),
  width => 500, height => 350,
);

$c->border->bottom->color(
    Graphics::Color::RGB->new(red => 1, green => 0, blue => 0, alpha => 1)
);
$c->border->bottom->width(5);
$c->border->left->color(
    Graphics::Color::RGB->new(red => 0, green => 1, blue => 0, alpha => 1)
);
$c->border->left->width(4);
$c->border->right->color(
    Graphics::Color::RGB->new(red => 0, green => 0, blue => 1, alpha => 1)
);
$c->border->right->width(3);
$c->border->top->color(
    Graphics::Color::RGB->new(red => 1, green => 0, blue => 1, alpha => 1)
);
$c->border->top->width(2);

$c->margins->bottom(5);
$c->margins->left(5);
$c->margins->right(5);
$c->margins->top(5);

my $driver = Graphics::Primitive::Driver::GD->new;

$driver->prepare($c);
$driver->finalize($c);
$driver->draw($c);
$driver->write('foo.png');
