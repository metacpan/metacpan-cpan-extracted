use 5.38.0;
use experimental 'class';
package Game::Snake::Text 0.10;
class Game::Snake::Text {
	our $VERSION = 0.10;
        use Raylib::FFI;
        use Raylib::Color;

        field $size : param;
        field $x : param;
        field $y : param;
        field $text : param = "";
        field $color : param = Raylib::Color::WHITE;

        method draw ($text, @position) {
                @position = ($x, $y) unless @position;
                DrawText( $text, @position, $size, $color );
        }

        method text (@txt) {
                $text = $txt[0] if @txt;
                $text;
        }
}

1;

=pod

=cut
