use 5.38.0;
use experimental 'class';

class Game::Floppy::Tube {
	use Raylib::FFI;
	use Game::Floppy::Sprite;
	field $x : param;
	field $y : param;
	field $width : param;
	field $height : param;
	field $top = Game::Floppy::Sprite->new(
		image => 'resources/pipe-green.png',
		x => 0,
		y => 0,
		rotate => 180,
	);
	field $bottom = Game::Floppy::Sprite->new(
		image => 'resources/pipe-green.png',
		x => 0,
		y => 0,
	);
	field $active = 1;

	method width () {
		$width;
	}

	method x (@xx) {
		$x = $xx[0] if @xx;
		$x;
	}

	method active (@act) {
		$active = $act[0] if @act;
		$active;
	}
	
	method top_rectangle () {
		return Raylib::FFI::Rectangle->new(
			x => $x,
			y => $y,
			width => $top->loaded->width,
			height => $top->loaded->height - $height - 20
		);
	}

	method bottom_rectangle () {
		return Raylib::FFI::Rectangle->new(
			x => $x,
			y => ($y + $top->loaded->height - $height) + 120,
			width => $bottom->loaded->width,
			height => $bottom->loaded->height
		);
	}

	method check_collision ($floppy) {
		return 1 if CheckCollisionCircleRec($floppy->position, $floppy->width, $_->top_rectangle) || CheckCollisionCircleRec($floppy->position, $floppy->width, $_->bottom_rectangle);
		return 0;
	}

	method draw {
		$top->draw($x + $top->loaded->width, $y + $top->loaded->height - $height, $top->loaded->width, $top->loaded->height);
		$bottom->draw($x, ($y + $top->loaded->height - $height) + 100, $bottom->loaded->width, $bottom->loaded->height);
	}
}

=pod

=cut
