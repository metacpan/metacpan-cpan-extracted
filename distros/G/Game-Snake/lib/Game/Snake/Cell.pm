use 5.38.0;
use experimental 'class';

package Game::Snake::Cell 0.10;
class Game::Snake::Cell {
	our $VERSION = 0.10;
	use Raylib::FFI;
	use Raylib::Color;
	field $x : param = 0;
	field $y : param = 0;
	field $width : param = 20;
	field $height : param = 20;
	field $color : param;

	method x () { $x }
	method y () { $y }

	method draw {
		my ($self) = @_;
		my $rectangle = Raylib::FFI::Rectangle->new(
			x => $x,
			y => $y,
			width => $width,
			height => $height
		);
		DrawRectangleRec($rectangle, $color);
		#DrawRectangleLines($x, $y, $width, $height, Raylib::Color::WHITE);
	}
}
1;

=pod

=cut
