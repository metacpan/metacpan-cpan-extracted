package Log::Fu::Color;
use strict;
use warnings;
use Log::Fu::Common;
use Log::Fu::Common qw(:levels);
use base qw(Exporter);
our @EXPORT = qw(fu_colorize);

our $USE_COLOR = 1;

BEGIN {
	if ($ENV{LOG_FU_NO_COLOR} || $ENV{ANSI_COLORS_DISABLED}) {
		$USE_COLOR = 0;
	} else {
		eval {
			require Term::Terminfo;
			Term::Terminfo->import();
			my $ti = Term::Terminfo->new();
			my $n_colors = $ti->getnum("colors");
			if ($n_colors < 8) {
				#Color logging disabled:
				die "Must have >= 16 colors!";
			}
		};
		if ($@) {
			$USE_COLOR = 0;
		} else {
			$USE_COLOR = 1;
		}
	}
}
my %COLORS = (
	YELLOW	=> 3,
	WHITE	=> 7,
	MAGENTA	=> 5,
	CYAN	=> 6,
	BLUE	=> 4,
	GREEN	=> 2,
	RED		=> 1,
	BLACK	=> 0,
);

use constant {
	COLOR_FG	=> 3,
	COLOR_BG	=> 4,
	COLOR_BRIGHT_FG	=> 1,
	COLOR_INTENSE_FG=> 9,
	COLOR_DIM_FG	=> 2
};
use constant {
	COLOR_RESET => "\33[0m"
};


sub fu_colorize {
    my ($level_number,$message) = @_;
    my $fmt_begin = "\033[";
    my $fmt_end = COLOR_RESET;
    if ($level_number == LOG_ERR || $level_number == LOG_CRIT) {
        $fmt_begin .= sprintf("%s;%s%sm", COLOR_BRIGHT_FG, COLOR_FG, $COLORS{RED});
    } elsif ($level_number == LOG_WARN) {
        $fmt_begin .= sprintf("%s%sm", COLOR_FG, $COLORS{YELLOW});
    } elsif ($level_number == LOG_DEBUG) {
        $fmt_begin .= sprintf("%s;%s%sm", COLOR_DIM_FG, COLOR_FG, $COLORS{WHITE});
    } else {
        $fmt_begin = "";
        $fmt_end = "";
    }
    $message = $fmt_begin  . $message . $fmt_end;
    return $message;
}

1;
