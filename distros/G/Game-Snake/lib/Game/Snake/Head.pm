use 5.38.0;
use experimental 'class';
our $VERSION = 0.03;
class Game::Snake::Head {
	use Raylib::FFI;
	use Game::Snake::Sprite;

	field $x : param;
	field $y : param;
	field $height : param;
	field $width : param;
	field $direction : param;
	field $last : param = 0;
	
	field $sprite = Game::Snake::Sprite->new(
		image => 'resources/snake-graphics.png',
		x => 0,
		y => 0,
		width => 64,
		height => 64
	);

	field $bend = 0;

	method bend (@b) {
		$bend = $b[0] if @b;
		$bend;
	}

	method last (@l) {
		$last = $l[0] if @l;
		$last;
	}


	method x (@xx) {
		$x = $xx[0] if @xx;
		$x;
	}

	method y (@yy) {
		$y = $yy[0] if @yy;
		$y;
	}

	method width (@w) {
		$width = $w[0] if @w;
		$width;
	}

	method height (@h) {
		$height = $h[0] if @h;
		$height;
	}

	method direction (@dir) {
		$direction = $dir[0] if @dir;
		$direction;
	}

	method sprite {
		$sprite;
	}

	method draw () {
		if ($direction eq 'left') {
			$sprite->y(64);
			$sprite->x(192);
		} elsif ($direction eq 'right') {
			$sprite->y(0);
			$sprite->x(256);
		} elsif ($direction eq 'up') {
			$sprite->y(0);
			$sprite->x(192);
		} else {
			$sprite->y(64);
			$sprite->x(256);
		}
		$sprite->draw($x, $y, $width, $height);
=pod
		my $rectangle = Raylib::FFI::Rectangle->new(
			x => $x,
			y => $y,
			width => $width,
			height => $height
		);
		DrawRectangleRec($rectangle, Raylib::Color::GRAY);
=cut
	}
}

1;
