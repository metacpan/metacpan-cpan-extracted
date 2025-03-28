use 5.38.0;
use experimental 'class';

package Game::Floppy::Sprite 0.07;
class Game::Floppy::Sprite {
	our $VERSION = 0.07;
	use Raylib::FFI;
	use Raylib::Color;

	field $image : param;
	field $width : param = undef;
	field $height : param = undef;
	field $x : param;
	field $y : param;
	field $rotate : param = 0;
	field $total_frames : param = 0;

	field $frame = 0;	
	field $loaded;

	ADJUST {
		my $base_path = __FILE__;
		$base_path =~ s/(.*Floppy[\/\\])(.*)/$1/;
		$loaded = LoadTexture($base_path . $image);
	}

	method loaded () {
		$loaded;
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

	method rotate (@rr)  {
		$rotate = $rr[0] if @rr;
		$rotate;
	}

	method draw ($x_pos, $y_pos, $w_pos, $h_pos) {		
		my $image = Raylib::FFI::Rectangle->new(
			x => $x + (($width || 0) * $frame),
			y => $y,
			width => defined $width ? $width : $loaded->width,
			height => defined $height ? $height : $loaded->height
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
		DrawTexturePro($loaded, $image, $viewport, $vector, $rotate, Raylib::Color::WHITE);
		$frame++;
		if ($frame >= $total_frames) {
			$frame = 0;
		}

	}
}

=pod

=cut
