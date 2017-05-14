package Games::Rezrov::ZConst;
# constants

use strict;

use constant ASCII_DEL => 0x7f;
use constant ASCII_BS  => 0x08;
use constant ASCII_LF  => 0x0a;
use constant ASCII_CR  => 0x0d;
use constant ASCII_SPACE  => 0x20;

use constant LOWER_WIN => 0;
use constant UPPER_WIN => 1;

use constant STYLE_ROMAN => 0;
use constant STYLE_REVERSE => 1;
use constant STYLE_BOLD => 2;
use constant STYLE_ITALIC => 4;
use constant STYLE_FIXED => 8;
# sect15.html#set_text_style

use constant STREAM_SCREEN => 1;
# 7.1.1
use constant STREAM_TRANSCRIPT => 2;
use constant STREAM_REDIRECT => 3;
# 7.1.2.1
use constant STREAM_COMMANDS => 4;
# 7.1.2.3
use constant STREAM_STEAL => 5;
# local: when redirecting screen output; when active send
# output here instead of to screen

use constant INPUT_KEYBOARD => 0;
use constant INPUT_FILE => 1;
# 10.2

# 3.8, table 2:
use constant Z_NEWLINE => 13;
use constant Z_DELETE => 8;
use constant Z_UP => 129;
use constant Z_DOWN => 130;
use constant Z_LEFT => 131;
use constant Z_RIGHT => 132;

# 8.3.1:
use constant COLOR_CURRENT => 0;
use constant COLOR_DEFAULT => 1;

use constant COLOR_BLACK => 2;
use constant COLOR_RED => 3;
use constant COLOR_GREEN => 4;
use constant COLOR_YELLOW => 5;
use constant COLOR_BLUE => 6;
use constant COLOR_MAGENTA => 7;
use constant COLOR_CYAN => 8;
use constant COLOR_WHITE => 9;

# 8.1.2:
use constant FONT_NORMAL => 1;
use constant FONT_PICTURE => 2;
use constant FONT_CHAR_GRAPHICS => 3;
use constant FONT_FIXED => 4;

my %COLOR_MAP = (COLOR_BLACK() => "black",
		 COLOR_RED() => "red",
		 COLOR_GREEN() => "green",
		 COLOR_YELLOW() => "yellow",
		 COLOR_BLUE() => "blue",
		 COLOR_MAGENTA() => "magenta",
		 COLOR_CYAN() => "cyan",
		 COLOR_WHITE() => "white");

sub color_code_to_name {
  return $COLOR_MAP{$_[0]} || undef;
}

1;
