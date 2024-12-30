use 5.38.0;
use experimental 'class';
our $VERSION = 0.02;
class Game::Snake::Cell {
	use Raylib::FFI;
	use Raylib::Color;
	field $x : param = 0;
	field $y : param = 0;
	field $width : param = 20;
	field $height : param = 20;

	method x { $x }
	method y { $y }

	method draw {
		my ($self) = @_;
		DrawRectangleLines($x, $y, $width, $height, Raylib::Color::WHITE);
	}
}
1;
