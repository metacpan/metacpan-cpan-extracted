package Games::2048::Board;
use 5.012;
use Moo;

use Text::Wrap;
use Term::ANSIColor;
use POSIX qw/floor ceil/;
use List::Util qw/max min/;

extends 'Games::2048::Grid';

has needs_redraw => is => 'rw', default => 1;
has score        => is => 'rw', default => 0;
has win          => is => 'rw', default => 0;
has lose         => is => 'rw', default => 0;

has best_score    => is => 'rw', default => 0;
has no_animations => is => 'rw', default => 0;
has zoom          => is => 'rw', default => 2, trigger => 1, coerce => \&_coerce_zoom;
has colors        => is => 'rw', builder => 1, coerce => \&_coerce_colors;

has appearing     => is => 'rw';
has moving        => is => 'rw';
has moving_vec    => is => 'rw';

has border_width   => is => 'rw', default => 2;
has border_height  => is => 'rw', default => 1;
has cell_width     => is => 'rw', default => 7;
has cell_height    => is => 'rw', default => 3;
has score_width    => is => 'rw', default => 7;
has score_height   => is => 'rw', default => 1;
has options_height => is => 'rw', default => 5;

my @zooms = (
	[ 3, 1 ],
	[ 5, 2 ],
	[ 7, 3 ],
	[ 9, 4 ],
	[ 11, 5 ],
);

sub insert_tile {
	my ($self, $tile) = @_;

	$self->needs_redraw(1);
	return if $self->no_animations;

	$tile->appearing(1);
	$self->appearing(Games::2048::Animation->new(
		duration => 0.3,
		first_value => -1 / max($self->cell_width, $self->cell_height),
		last_value => 1,
	));

	$tile;
}

sub move_tiles {
	my ($self, $vec) = @_;

	$self->needs_redraw(1);
	return if $self->no_animations;

	$self->reset_animations;

	$self->moving_vec($vec);
	$self->moving(Games::2048::Animation->new(
		duration => 0.2,
		first_value => 0,
		last_value => $self->size - 1,
	));
}

sub reset_appearing {
	my $self = shift;
	$_->appearing(0) for $self->each_tile;
	$self->appearing(undef);
}

sub reset_moving {
	my $self = shift;
	for ($self->each_tile) {
		$_->moving_from(undef);
		$_->merging_tiles(undef);
	}
	$self->moving(undef);
}

sub reset_animations {
	my $self = shift;
	$self->reset_moving;
	$self->reset_appearing;
}

sub draw {
	my ($self, $redraw) = @_;

	return if $redraw and !$self->needs_redraw;

	$self->hide_cursor;
	$self->restore_cursor if $redraw;
	$self->needs_redraw(0);

	say "" if !$redraw;

	$self->draw_hud;
	$self->draw_border_horizontal;

	# set if anything is *actually* moving or appearing
	my $moving;
	my $appearing;

	for my $y (0..$self->size-1) {
		for my $line (0..$self->cell_height-1) {
			$self->draw_border_vertical;

			for my $x (0..$self->size-1) {
				my $tile = $self->tile([$x, $y]);

				my $string;
				my $value = $tile ? $tile->value : undef;
				my $color = $self->tile_color($value);
				my $bgcolor = $self->tile_color(undef);

				if (defined $value and length($value) > $self->cell_width * $self->cell_height) {
					$value = int($value/1000) . "k";
				}

				my $lines = min(ceil(length($value // '') / $self->cell_width), $self->cell_height);
				my $first_line = floor(($self->cell_height - $lines) / 2);
				my $this_line = $line - $first_line;

				if ($this_line >= 0 and $this_line < $lines) {
					my $cols = min(ceil(length($value) / $lines), $self->cell_width);
					my $string_offset = $this_line * $cols;
					my $string_length = min($cols, length($value) - $string_offset, $self->cell_width);
					my $cell_offset = floor(($self->cell_width - $string_length) / 2);

					$string = " " x $cell_offset;

					$string .= substr($value, $string_offset, $string_length);

					$string .= " " x ($self->cell_width - $cell_offset - $string_length);
				}
				else {
					$string = " " x $self->cell_width;
				}

				if ($tile and $tile->appearing and $self->appearing) {
					# if any animation is going we need to keep redrawing
					$self->needs_redraw(1);

					my $value = $self->appearing->value;
					$appearing = 1;

					my $x_center = ($self->cell_width  - 1) / 2;
					my $y_center = ($self->cell_height - 1) / 2;

					my $on = 0;
					my $extra = 0;
					for my $col (0..$self->cell_width-1) {
						my $x_distance = $col  / $x_center - 1;
						my $y_distance = $line / $y_center - 1;
						my $distance = $x_distance**2 + $y_distance**2;

						my $within = $distance <= 2 * $value**2;

						if ($within xor $on) {
							$on = $within;

							my $insert = $on
								? $color
								: $bgcolor;

							substr($string, $col + $extra, 0) = $insert;
							$extra += length($insert);
						}
					}
					if ($on) {
						$string .= $bgcolor;
					}
				}
				else {
					$string = $color . $string . $bgcolor;
				}

				print $string;
			}

			$self->draw_border_vertical;
			say color("reset");
		}
	}

	# update animations
	$self->reset_appearing if $appearing and !$self->appearing->update;
	$self->reset_moving if $self->moving and !$moving || !$self->moving->update;

	$self->draw_border_horizontal;
	$self->show_cursor if !$self->needs_redraw;
}

sub draw_win {
	my $self = shift;
	return if !$self->win and !$self->lose;
	my $message =
		$self->win ? "You win!"
		           : "Game over!";
	my $offset = ceil(($self->board_width - length($message)) / 2);

	say " " x $offset, colored(uc $message, "bold"), "\n";
}

sub draw_win_question {
	my $self = shift;
	print $self->win ? "Keep going?" : "Try again?", " (Y/n) ";
	STDOUT->flush;
}

sub draw_win_answer {
	my ($self, $yes) = @_;
	say $yes ? "y" : "n";
}

sub draw_hud {
	my $self = shift;

	$self->draw_options;
	$self->draw_score;
}

sub draw_options {
	my $self = shift;

	$self->draw_option("( Q ) Quit        " . "( R ) New Game");
	$self->draw_option("( A ) Animations  " . bold_if("On", !$self->no_animations)."/".bold_if("Off", $self->no_animations));
	$self->draw_option("( C ) Colors      " . bold_if("16", $self->colors == 0)."/".bold_if("256", $self->colors == 1)."/".bold_if("24-bit", $self->colors == 2));
	$self->draw_option("(+/-) Zoom        " . colored(floor(($self->cell_height + 1) / 4 * 100)."%", "bold"));

	say "";
}

sub bold_if {
	my ($string, $condition) = @_;
	$condition ? colored($string, "bold") : $string;
}

sub draw_option {
	my ($self, $line) = @_;
	$line =~ s/(\(.*?\))/colored($1, "bold")/ge;
	say $line;
}

sub draw_score {
	my $self = shift;

	my $score = "Score:";
	my $best_score = "Best:";

	my $blank_width = $self->board_width - length($score) - length($best_score);
	my $score_width = min(floor(($blank_width - 1) / 2), $self->score_width);
	my $inner_padding = $blank_width - $score_width * 2;

	$self->draw_sub_score($score, $score_width, $self->score);

	print " " x $inner_padding;

	$self->draw_sub_score($best_score, $score_width, $self->best_score);

	say "";
}

sub draw_sub_score {
	my ($self, $string, $score_width, $score) = @_;
	printf "%s%*d", colored($string, "bold"), $score_width, $score;
}

sub tile_color {
	my ($self, $value) = @_;
    if ($self->colors == 2) {
        return
		!defined $value ? color("reset") . "\e[38;2;187;173;160m" . "\e[48;2;204;192;179m"
		: $value < 4    ? color("reset") . "\e[38;2;119;110;101m" . "\e[48;2;238;228;218m"
		: $value < 8    ? color("reset") . "\e[38;2;119;110;101m" . "\e[48;2;237;224;200m"
		: $value < 16   ? color("reset") . "\e[38;2;249;246;242m" . "\e[48;2;242;177;121m"
		: $value < 32   ? color("reset") . "\e[38;2;249;246;242m" . "\e[48;2;245;149;99m"
		: $value < 64   ? color("reset") . "\e[38;2;249;246;242m" . "\e[48;2;246;124;95m"
		: $value < 128  ? color("reset") . "\e[38;2;249;246;242m" . "\e[48;2;246;94;59m"
		: $value < 256  ? color("bold")  . "\e[38;2;249;246;242m" . "\e[48;2;237;207;114m"
		: $value < 512  ? color("bold")  . "\e[38;2;249;246;242m" . "\e[48;2;237;204;97m"
		: $value < 1024 ? color("bold")  . "\e[38;2;249;246;242m" . "\e[48;2;237;200;80m"
		: $value < 2048 ? color("bold")  . "\e[38;2;249;246;242m" . "\e[48;2;237;197;63m"
		: $value < 4096 ? color("bold")  . "\e[38;2;249;246;242m" . "\e[48;2;237;194;46m"
		                : color("bold")  . "\e[38;2;249;246;242m" . "\e[48;2;60;58;50m";
	}
	if ($self->colors == 1) {
        return
		!defined $value ? color("reset") . "\e[38;5;249m" . "\e[48;5;251m"
		: $value < 4    ? color("reset") . "\e[38;5;243m" . "\e[48;5;231m"
		: $value < 8    ? color("reset") . "\e[38;5;243m" . "\e[48;5;230m"
		: $value < 16   ? color("reset") . "\e[38;5;231m" . "\e[48;5;215m"
		: $value < 32   ? color("reset") . "\e[38;5;231m" . "\e[48;5;209m"
		: $value < 64   ? color("reset") . "\e[38;5;231m" . "\e[48;5;203m"
		: $value < 128  ? color("reset") . "\e[38;5;231m" . "\e[48;5;196m"
		: $value < 256  ? color("bold")  . "\e[38;5;231m" . "\e[48;5;227m"
		: $value < 512  ? color("bold")  . "\e[38;5;231m" . "\e[48;5;227m"
		: $value < 1024 ? color("bold")  . "\e[38;5;231m" . "\e[48;5;226m"
		: $value < 2048 ? color("bold")  . "\e[38;5;231m" . "\e[48;5;226m"
		: $value < 4096 ? color("bold")  . "\e[38;5;231m" . "\e[48;5;220m"
		                : color("bold")  . "\e[38;5;231m" . "\e[48;5;237m";
	}
	my $bright = $^O eq "MSWin32" ? "underline " : "bright_";
	my $bold   = $^O eq "MSWin32" ? "underline"  : "bold";
	return color (
		!defined $value ? "reset"
		: $value < 4    ? "reset reverse cyan"
		: $value < 8    ? "reset reverse ${bright}blue"
		: $value < 16   ? "reset reverse blue"
		: $value < 32   ? "reset reverse green"
		: $value < 64   ? "reset reverse magenta"
		: $value < 128  ? "reset reverse red"
		: $value < 4096 ? "reset reverse yellow"
		                : "reset reverse $bold"
	);
}

sub border_color {
	my $self = shift;
	$self->tile_color(undef) . color("reverse");
}

sub board_width {
	my $self = shift;
	return $self->size * $self->cell_width + $self->border_width * 2;
}

sub board_height {
	my $self = shift;
	return $self->size * $self->cell_height + $self->border_height * 2 + $self->hud_height;
}

sub hud_height {
	my $self = shift;
	return $self->score_height + $self->options_height;
}

sub draw_border_horizontal {
	my $self = shift;
	say $self->border_color, " " x $self->board_width, color("reset") for 1..$self->border_height;
}
sub draw_border_vertical {
	my $self = shift;
	print $self->border_color, " " x $self->border_width, $self->tile_color(undef);
}

sub restore_cursor {
	my $self = shift;
	printf "\e[%dA", $self->board_height;
}

sub draw_welcome {
	my $logo = colored(<<'LOGO', "bold");
__  _     _
 _)/ \|_|(_)
/__\_/  |(_)
LOGO

	my $message = <<'MESSAGE';

Join the numbers and get to the 2048 tile!

HOW TO PLAY: Use your arrow keys to move the tiles. When two tiles with the same number touch, they merge into one!
MESSAGE

	local $Text::Wrap::columns = Games::2048::Util::window_size;
	$message = wrap "", "", $message;
	$message =~ s/(2048\s+tile!|HOW\s+TO\s+PLAY:|arrow\s+keys|merge\s+into\s+one!)/colored $1, "bold"/ge;

	print $logo, $message;
}

sub hide_cursor {
	my $self = shift;
	state $once = eval 'END { $self->show_cursor }';
	print "\e[?25l";
}
sub show_cursor {
	my $self = shift;
	print "\e[?25h";
}

around no_animations => sub {
	my $orig = shift;
	my $self = shift;

	my $no_anim = $self->$orig(@_);

	if (@_) {
		$self->reset_animations if $self->no_animations;
		$self->needs_redraw(1);
	}
	else {
		$no_anim = 1 if $self->cell_height <= 1 or $self->cell_width <= 1;
	}

	$no_anim;
};

sub _coerce_zoom {
	my ($zoom) = @_;
	$zoom = $#zooms if $zoom > $#zooms;
	$zoom = 0 if $zoom < 0;
	$zoom;
}

sub _trigger_zoom {
	my ($self, $zoom, $old) = @_;
	$self->zoom($zoom, undef); # hack because we have no old value FUUUUUU
}

around zoom => sub {
	my $orig = shift;
	my $self = shift;

	return $self->$orig if !@_;

	my $old = $self->$orig;
	my $zoom = @_ == 1 ? $self->$orig(@_) : $old;

	$self->cell_width($zooms[$zoom][0]);
	$self->cell_height($zooms[$zoom][1]);
	$self->draw if defined $old and $zoom != $old;

	$zoom;
};

sub _build_colors {
	return 2 if $ENV{KONSOLE_DBUS_SERVICE};
	return 1 if 0;
	return 0;
}

sub _coerce_colors {
	my ($colors) = @_;
	$colors //= 0;
	$colors = 0 if $colors > 2;
	$colors = 2 if $colors < 0;
	$colors;
}

around colors => sub {
	my $orig = shift;
	my $self = shift;

	my $colors = $self->$orig(@_);

	if (@_) {
		$self->needs_redraw(1);
	}

	$colors;
};

1;
