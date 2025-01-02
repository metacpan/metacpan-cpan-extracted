use 5.38.0;
use experimental 'class';
our $VERSION = 0.07;
class Game::Snake::Food {
	use Raylib::App;
	use Raylib::FFI;

	field $x : param;
	field $y : param;
	field $height : param;
	field $width : param;

	field $sprite = Game::Snake::Sprite->new(
		image => 'resources/snake-graphics.png',
		x => 0,
		y => 192,
		width => 64,
		height => 64
	);

	method x (@xx) {
		$x = $xx[0] if @xx;
		$x;
	}

	method y (@yy) {
		$y = $yy[0] if @yy;
		$y;
	}

	method draw () {
		$sprite->draw($x, $y, $width, $height);
	}
}

1;

=pod

=cut
