use 5.38.0;
use experimental 'class';
our $VERSION = 0.02;
class Game::Snake::Head {
	use Raylib::App;
	use Raylib::FFI;

	field $x : param;
	field $y : param;
	field $height : param;
	field $width : param;
	field $direction : param;

	method x (@xx) {
		$x = $xx[0] if @xx;
		$x;
	}

	method y (@yy) {
		$y = $yy[0] if @yy;
		$y;
	}

	method direction (@dir) {
		$direction = $dir[0] if @dir;
		$direction;
	}

	method draw () {
		my $rectangle = Raylib::FFI::Rectangle->new(
			x => $x,
			y => $y,
			width => $width,
			height => $height
		);
		DrawRectangleRec($rectangle, Raylib::Color::GRAY);
	}
}

1;
