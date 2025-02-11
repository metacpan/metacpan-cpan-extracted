use 5.38.0;
use experimental 'class';
package Game::Snake::Sprite 0.10;
class Game::Snake::Sprite {
	our $VERSION = 0.10;
	use Raylib::FFI;
	use Raylib::Color;

	field $image : param;
	field $width : param;
	field $height : param;
	field $x : param;
	field $y : param;
	
	field $loaded;

	ADJUST {
		my $base_path = __FILE__;
		$base_path =~ s/(.*Snake[\/\\])(.*)/$1/;
		$loaded = LoadTexture($base_path . $image);
	}

	method x (@xx)  {
		$x = $xx[0] if @xx;
		$x;
	}

	method y (@yy)  {
		$y = $yy[0] if @yy;
		$y;
	}

	method width (@ww)  {
		$width = $ww[0] if @ww;
		$width;
	}

	method height (@hh)  {
		$height = $hh[0] if @hh;
		$height;
	}

	method draw ($x_pos, $y_pos, $w_pos, $h_pos) {		
		my $image = Raylib::FFI::Rectangle->new(
			x => $x,
			y => $y,
			width => $width,
			height => $height
		);
		my $viewport = Raylib::FFI::Rectangle->new(
			x => $x_pos,
			y => $y_pos,
			width => $w_pos,
			height => $h_pos,
		);
		my $vector = Raylib::FFI::Vector2D->new(
			x => 0,
			y => 0
		);

		DrawTexturePro($loaded, $image, $viewport, $vector, 0, Raylib::Color::WHITE);
	}
}

=pod

=cut
