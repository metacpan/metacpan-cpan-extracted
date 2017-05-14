package Games::Rezrov::ZIO_Win32;
# z-machine i/o for perls with Win32::Console
# TO DO:
# - handle scrollbars/buffering properly...it would be nice
#   if old game text could be seen via an existing scrollbar.
#   But this requires untangling screen Size() mess.
# - can we set hourglass when busy?

use strict;
use Win32::Console;

use Games::Rezrov::ZIO_Generic;
use Games::Rezrov::ZIO_Color;
use Games::Rezrov::ZConst;

use Carp qw(cluck);

use constant DEBUG => 0;

@Games::Rezrov::ZIO_Win32::ISA = qw(Games::Rezrov::ZIO_Generic
				    Games::Rezrov::ZIO_Color
				    );

my ($upper_lines, $rows, $columns, $in_status);
# number of lines in upper window, geometry

my ($IN, $OUT);
# Win32::Console instances

my @ORIG_SIZE;

if (DEBUG) {
  # debugging; tough to redirect STDERR under win32 :(
  open(LOG, ">zio.log") || die;
  select(LOG);
  $|=1;
  select(STDOUT);
}

my %KEYCODES = (
		38 => Games::Rezrov::ZConst::Z_UP,
		40 => Games::Rezrov::ZConst::Z_DOWN,
		37 => Games::Rezrov::ZConst::Z_LEFT,
		39 => Games::Rezrov::ZConst::Z_RIGHT,
		);

my (%FOREGROUND, %BACKGROUND);
foreach (qw(black
	    blue
	    lightblue
	    red
	    lightred
	    green
	    lightgreen
	    magenta
	    lightmagenta
	    cyan
	    lightcyan
	    brown
	    yellow
	    gray
	    white)) {
    # make hash translating names to color codes exported by Win32::Console
    no strict "refs";
    $FOREGROUND{$_} = ${"main::FG_" . uc($_)};
    $BACKGROUND{$_} = ${"main::BG_" . uc($_)};
}

sub new {
    my ($type, %options) = @_;
    my $self = new Games::Rezrov::ZIO_Generic(%options);
    bless $self, $type;

    if ($options{fg}) {
	$options{fg} = "gray" if $options{fg} eq "white";
	# since INTENSITY mode has no effect "white",
	# use gray instead.  Feh.
	# How to get *true* bold here???
    } else {
	$options{fg} = "gray" unless $options{fg};
	$options{bg} = "blue" unless $options{bg};
	$options{sfg} = "black" unless $options{sfg};
	$options{sbg} = "cyan" unless $options{sbg};
    }

    $self->parse_color_options(\%options);

    foreach ("bg", "fg", "sfg", "sbg") {
      next unless exists $options{$_};
      my $c = $self->$_() || next;
      die sprintf "Unknown color \"%s\"; available colors: %s\n", $c, join(", ", sort keys %FOREGROUND)
	  unless exists $FOREGROUND{$c};
    }
    
    # set up i/o
    $IN = new Win32::Console(STD_INPUT_HANDLE);
    $OUT = new Win32::Console(STD_OUTPUT_HANDLE);

    @ORIG_SIZE = $OUT->Size();
    # save original buffer geometry to restore on exit

    my ($top_row, $bottom_row, $left_col, $right_col);
    ($columns, $left_col, $top_row, $right_col, $bottom_row) = ($OUT->Info())[0,5,6,7,8];
#    die $bottom_row;
    my $visible_rows = ($bottom_row - $top_row) + 1;
    my $visible_columns = ($right_col - $left_col) + 1;

    $OUT->Size($visible_columns, $visible_rows);
    # 11/2004: set the screen buffer to be the same size as the visible area
    # of the window.  Has the effect of removing any scrollbars, etc.
    #
    # Under XP the default number of rows in the buffer is generally
    # larger than the number of visible rows (under Windows 98
    # the two were generally the same).  So without this change we'd be 
    # drawing the status window and/or upper window lines somewhere
    # way up in the buffer, which won't be visible...this is because
    # the Cursor() method moves within the *buffer* rather than the
    # visible area.
    #
    # It's probably possible to finesse this module to only draw to
    # the visible area while leaving the buffers and scrollbars
    # alone, but for now I Don't Care.
    
    my @size = $OUT->Size();
    $columns = $options{"columns"} || $size[0] || die "need columns!";
    $rows = $options{"rows"} || $size[1] || die "need rows!";

    $OUT->Size($columns, $rows);
    # resize again (possible user override limiting rows/cols)

    $upper_lines = 0;
    return $self;
}

sub update {
  $OUT->Flush();
}

sub set_version {
  # called by the game
  my ($self, $status_needed, $callback) = @_;
  Games::Rezrov::StoryFile::rows($rows);
  Games::Rezrov::StoryFile::columns($columns);
  return 0;
}

sub absolute_move {
  # move to X, Y
  $OUT->Cursor($_[1], $_[2]);
}

sub write_string {
  my ($self, $string, $x, $y) = @_;
  $self->absolute_move($x, $y) if defined($x) and defined($y);
#  $OUT->Attr($current_attr);
  $OUT->Attr($self->get_attr());
  $OUT->Write($string);
}

sub newline {
  # newline/scroll
  my ($x, $y) = $OUT->Cursor();
  if (++$y >= $rows) {
      # scroll needed
      my $last_line = $rows - 1;
      $y = $last_line;
      my $top = $upper_lines;
    #	$OUT->Write(sprintf "before: at %d,%d, top=%d last=%d\n", $x, $y, $top, $last_line);
#    log_it(sprintf "before: at %d,%d, top=%d last=%d\n", $x, $y, $top, $last_line);
    #	sleep(1);
      $OUT->Scroll(0, $top + 1, $columns - 1, $last_line,
		   0, $top, Games::Rezrov::ZConst::ASCII_SPACE, $_[0]->get_attr(0),
		   0, $top, $columns - 1, $last_line);
      # ugh: we have to specify the clipping region, or else
      # Win32::Console barfs about uninitialized variables (with -w)
  }
  Games::Rezrov::StoryFile::register_newline();
  $_[0]->absolute_move(0, $y);
}

sub write_zchar {
#    log_it("wzchar: " . chr($_[1]));
  $OUT->Attr($_[0]->get_attr());
  $OUT->Write(chr($_[1]));
}

sub status_hook {
  my ($self, $type) = @_;
  # 0 = before
  # 1 = after
  if ($type == 0) {
    # before printing status line
    $OUT->Cursor(0,0);
    $in_status = 1;
    $OUT->FillAttr($self->get_attr(), $columns, 0, 0);
  } else {
    # after printing status line
    $in_status = 0;
  }
}

sub get_input {
    my ($self, $max, $single_char, %options) = @_;
#    $IN->Flush();
    # don't flush input (allow buffered keystrokes)
    
    my ($start_x, $y) = $OUT->Cursor();
    my $buf = $options{"-preloaded"} || "";
    # preloaded text in the buffer, but already displayed by the game; ugh.
    my @event;
    my ($code, $char);

    if ($self->listening) {
      $buf = $self->recognize_line();
      $OUT->Write($buf);
    } else {
      while (1) {
	@event = $IN->Input();
	next unless defined $event[0];
	my $known;
	if ($event[0] == 1 and $event[1]) {
	  # a key pressed
	  $code = $event[5];
	  if ($code == 0) {
	    # non-character key pressed
	    if ($KEYCODES{$event[3]}) {
	      $code = $KEYCODES{$event[3]};
	      $known = 1;
	    } else {
	      log_it(sprintf "got unknown non-char: %s", join ",", @event);
	    }
	  }

	  if ($single_char and ($known or ($code >= 1 and $code <= 127))) {
	    return chr($code);
	  } elsif ($code == Games::Rezrov::ZConst::ASCII_BS) {
	    if (length($buf) > 0) {
	      #	  log_it("backsp " . length($buf) . " " . $buf);
	      my ($x, $y) = $OUT->Cursor();
	      $OUT->Cursor($x - 1, $y);
	      $OUT->Write(" ");
	      $OUT->Cursor($x - 1, $y);
	      $buf = substr($buf, 0, length($buf) - 1);
	    }
	  } elsif ($code == Games::Rezrov::ZConst::ASCII_CR) {
	    last;
	  } else {
	    if ($code >= 32 and $code <= 127) {
	      $char = chr($code);
	      $buf .= $char;
	      $OUT->Attr($self->get_attr(0));
	      $OUT->Write($char);
	    }
	  }
	}
      }
    }
    $self->newline();
    return $buf;
}

sub clear_screen {
    $OUT->Cls($_[0]->get_attr(0));
#    log_it("cls");
}

sub clear_to_eol {
    $OUT->Attr($_[0]->get_attr(0));
    $OUT->Write(' ' x ($columns - ($OUT->Cursor())[1]));
}

sub split_window {
  # split upper window to specified number of lines
  my ($self, $lines) = @_;
  #  $w_main->setscrreg($lines, $rows - 1);
  $upper_lines = $lines;
  #  print STDERR "split_window to $lines\n";
}

sub can_change_title {
  return 1;
}

sub can_use_color {
  return 1;
}

sub set_game_title {
  $OUT->Title($_[1]);
}

sub log_it {
  if (DEBUG) {
    print LOG $_[0] . "\n";
  }
}

sub get_attr {
    # return attribute code for color/style currently in effect.
    my ($self, $mask) = @_;
    
    $mask = Games::Rezrov::StoryFile::font_mask() unless defined($mask);
    # might be called with an override
    my ($fg, $bg);
    if ($in_status) {
	$fg = $self->sfg();
	$bg = $self->sbg();
    } else {
	if ($mask & Games::Rezrov::ZConst::STYLE_REVERSE) {
	  $fg = $self->bg();
	  $bg = $self->fg();
	} else {
	  $fg = $self->fg();
	  $bg = $self->bg();
	}
    }

    my $code = $BACKGROUND{$bg} | $FOREGROUND{$fg};
    $code |= main::FOREGROUND_INTENSITY if 
	($mask & (Games::Rezrov::ZConst::STYLE_BOLD|Games::Rezrov::ZConst::STYLE_ITALIC));
    return $code;
}

sub get_position {
  # with no arguments, return absolute X and Y coordinates.
  # With an argument, return a sub that will restore the current cursor
  # position.
  my ($self, $sub) = @_;
  my ($x, $y) = $OUT->Cursor();
  if ($sub) {
    return sub { $OUT->Cursor($x, $y); };
  } else {
    return ($x, $y);
  }
}

sub cleanup {
    $OUT->Size(@ORIG_SIZE) if $OUT;
    # restore original window buffer sizes
}

1;
