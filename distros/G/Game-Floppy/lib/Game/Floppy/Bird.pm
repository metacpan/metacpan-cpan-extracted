use 5.38.0;
use experimental 'class';

package Game::Floppy::Bird 0.07;
class Game::Floppy::Bird {
	our $VERSION = 0.07;
	use Raylib::FFI;
	use Raylib::Color;
	use Game::Floppy::Sprite;

	field $x : param;
	field $y : param;
	field $width : param;
	field $height : param;
	field $sprite = Game::Floppy::Sprite->new(
		image => 'resources/bluebird.png',
		x => 0,
		y => 0,
		width => 34,
		height => 24,
		total_frames => 4
	);

	method x (@xx) {
		$x = $xx[0] if @xx;
		$x;
	}

	method y (@yy) {
		$y = $yy[0] if @yy;
		$y;
	}

	method width () {
		$width
	}

	method sprite () {
		$sprite;
	}

	method position () {
		return Raylib::FFI::Vector2D->new( x => $x, y =>  $y);
	}

	method draw {
		my $rotate = $sprite->rotate;
		if ($rotate < 45) {
			$rotate++;
			$sprite->rotate($rotate);
		}
		$sprite->draw($x, $y, $width, $height);
	}
}

1;

=pod

=cut
