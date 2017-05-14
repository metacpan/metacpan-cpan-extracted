package Games::Rezrov::ZIO_Termcap;
#
# z-machine I/O for perls with Term::Cap
#

BEGIN {
#  $ENV{"PERL_RL"} = 'Gnu';
#  $ENV{"PERL_RL"} = 'Perl';
  # don't set unless debugging: if requested readline isn't
  # present, may default to useless "Stub" version
}

use strict;
use Term::Cap;
use POSIX;

use Games::Rezrov::GetKey;
use Games::Rezrov::GetSize;
use Games::Rezrov::ZConst;
use Games::Rezrov::ZIO_Tools;
use Games::Rezrov::ZIO_Generic;

@Games::Rezrov::ZIO_Termcap::ISA = qw(Games::Rezrov::ZIO_Generic);

#
# termcap(5) capabilities:
#
use constant ATTR_OFF => 'me';
use constant ATTR_REVERSE => 'mr';
use constant ATTR_BOLD => 'md';
use constant ATTR_UNDERLINE => 'us';

use constant CURSOR_MOVE => 'cm';
use constant CURSOR_UP => 'up';

use constant CLEAR_TO_EOL => 'ce';
use constant CLEAR_SCREEN => 'cl';
use constant DELETE_LINE => 'dl';
use constant DELETE_CHAR => 'dc';

use constant AUDIO_BELL => 'bl';
use constant VISIBLE_BELL => 'vb';

use constant SET_SCROLL_REGION => 'cs';
use constant SCROLL_ONE_LINE => 'sf';

use constant BACKSPACE_BOOLEAN => 'bs';
use constant BACKSPACE_ALTERNATE => 'bc';
#
# end termcap
#

use constant MANUAL_BACKSPACE => 0x08;
# ^H

use constant SCROLL_STYLE_CS => 1;
use constant SCROLL_STYLE_DEL => 2;

use Games::Rezrov::MethodMaker qw(
  scrolling_style
  backspace_sequence
  read_own_lines
			  );

#my $HAVE_STATUS_LINE;

# again, a lot of statics for speed...
my $UPPER_LINES;
my $terminal;

my ($abs_x, $abs_y) = (0,0);
# current cursor position

# in v4/v5, we have a "lower" and an "upper" window.
# in <= v3, we have a window and a status line; status line will be
# considered "upper".  BROKEN: seastalker!

my ($rows, $columns);

sub new {
  my ($type, %options) = @_;
  my $self = new Games::Rezrov::ZIO_Generic();
  bless $self, $type;

  $self->zio_options(\%options);
  $self->readline_init();

  # set up Term::Cap
  my $termios = new POSIX::Termios();
  $termios->getattr();
  my $ospeed = $termios->getospeed();
  $terminal = Tgetent Term::Cap { TERM => undef, OSPEED => $ospeed };
  
  $terminal->Trequire(
#		      CURSOR_X,
#		      CURSOR_LOWER_LEFT,
		      CLEAR_TO_EOL,
		     );

  $self->init_scrolling_style();

#  die join "---", $terminal->Tputs("cs"), $terminal->Tgoto("cs", 42, 1);


  attr_off();

  if (0) {
    # boolean testing code
    my @booleans = ("5i","am","bs","bw","da","db","eo","es","gn","hc","HC","hs","hz","in","km","mi","ms","NP","NR","nx","os","ul","xb","xn","xo","xs","xt");
    foreach my $b (@booleans) {
      my $v = $terminal->Tputs($b, 0);
      printf "%s: '%s'\n", $b, defined $v ? "defined" : "undef";
    }
    die;
  }

  #
  #  find backspace sequence
  #
  my $backspace;
  if (defined $terminal->Tputs(BACKSPACE_BOOLEAN, 0)) {
    # boolean -- only defined, not an actual value  :/
    # if set, ctrl-H performs backspace
    $backspace = pack "c", MANUAL_BACKSPACE;
  } else {
    my $alt = $terminal->Tputs(BACKSPACE_ALTERNATE, 0);
    # "Backspace, if not ^H"
    if ($alt) {
      $backspace = $alt;
    } else {
      print STDERR "WARNING: can't get backspace sequence!\n";
      $backspace = pack "c", MANUAL_BACKSPACE;
      # shouldn't happen
    }
  }
  $self->backspace_sequence($backspace);

  if ($options{"columns"} and $options{"rows"}) {
    $columns = $options{"columns"};
    $rows = $options{"rows"};
  } else {
    ($columns, $rows) = get_size();
    if ($columns and $rows) {
      if ($options{"flaky"} and Games::Rezrov::GetKey::can_read_single()) {
	$self->read_own_lines(1);
      } else {
	$rows-- if $self->scrolling_style() == SCROLL_STYLE_DEL;
	# hack: steal the last line on the display.
	# a newline on the last line causes the window to scroll
	# automatically, adding an unrequested newline and erasing
	# the status line.  Fixable without "cs"?
      }
    } else {
      print "I couldn't guess the number of rows and columns in your display,\n";
      print "so you must use -rows and -columns to specify them manually.\n";
      exit;
    }
  }

  $self->set_upper_lines(0);

  return $self;
}

sub update {
  # force screen refresh
  $|=1;
  print "";
  $|=0;
}

sub set_version {
  # called by the game
  my ($self, $status_needed, $callback) = @_;
#  $HAVE_STATUS_LINE = $status_needed;
  $self->set_upper_lines();
  # hack
  Games::Rezrov::StoryFile::rows($rows);
  Games::Rezrov::StoryFile::columns($columns);
  return 0;
}

sub write_string {
  my ($self, $string, $x, $y) = @_;
  $self->absolute_move($x, $y) if defined($x) and defined($y);
#  printf STDERR "ws: %s at (%d,%d)\n", $string, $abs_x, $abs_y;
  print $string;
  $abs_x += length($string);
}

sub newline {
  if (++$abs_y >= $rows) {
    # scroll needed
    if ($_[0]->scrolling_style() == SCROLL_STYLE_CS) {
      $_[0]->absolute_move(0, $rows);
      # saw a ref somewhere that said cursor had to be in
      # the lower left corner for scroll cmd to work
#      print $terminal->Tputs(SCROLL_ONE_LINE);
      do_term(SCROLL_ONE_LINE);
      $abs_y = $rows;
    } else {
      #    print STDERR "scrolling!\n";
      my $restore = $_[0]->get_position(1);
      $_[0]->absolute_move(0, $UPPER_LINES);
      do_term(DELETE_LINE);
      # scroll the lower window by deleting the first line
      # FIX ME: ONLY IN LOWER WINDOW
      #    &$restore();
      $abs_y = $rows - 1;
    }
  }
  $_[0]->absolute_move(0, $abs_y);

  Games::Rezrov::StoryFile::register_newline();
}

sub write_zchar {
  print chr($_[1]);
  $abs_x++;
}

sub absolute_move {
  # col, row
  my $self = shift;
  ($abs_x, $abs_y) = @_;
  print $terminal->Tgoto(CURSOR_MOVE, $abs_x, $abs_y);
}

sub get_position {
  # with no arguments, return absolute X and Y coordinates.
  # With an argument, return a sub that will restore the current cursor
  # position.
  my ($self, $sub) = @_;
  my ($x, $y) = ($abs_x, $abs_y);
  if ($sub) {
    return sub { $self->absolute_move($x, $y); };
  } else {
    return ($abs_x, $abs_y);
  }
}

sub status_hook {
  my ($self, $type) = @_;
  # 0 = before
  # 1 = after
  if ($type == 0) {
    # before printing status line
    attr_reverse();
  } else {
    # after printing status line
    attr_off();
  }
}

sub get_input {
  my ($self, $max, $single_char, %options) = @_;
  my $result;
  if ($single_char) {
    $result = get_key();
  } else {
    if ($self->read_own_lines()) {
      # manual
      $result = $self->manual_read_line($options{"-preloaded"});
    } elsif ($self->using_term_readline()) {
      # Term::ReadLine enabled
      $result = $self->readline($options{"-preloaded"});
    } else {
#      system "stty -echo";
      $result = <STDIN>;
      # this doesn't work with v5+ preloaded input
      unless (defined $result) {
	$result = "";
	print "\n";
      }
    }
    chomp $result;
    $result = "" unless defined($result);

    $self->newline() if $self->scrolling_style() == SCROLL_STYLE_DEL;
    # ugh, FIX ME

  }
  return $result;
}

sub clear_to_eol {
  do_term(CLEAR_TO_EOL);
}

sub clear_screen {
  do_term(CLEAR_SCREEN);
}

sub split_window {
  # split upper window to specified number of lines
  my ($self, $lines) = @_;
  $self->set_upper_lines($lines);
  # needed for scrolling the lower window
}

sub do_term {
  print $terminal->Tputs($_[0], 0) if $terminal;
}

sub attr_off {
  do_term(ATTR_OFF);
}

sub attr_reverse {
  do_term(ATTR_REVERSE);
}

sub attr_bold {
  do_term(ATTR_BOLD);
}

sub attr_underline {
  do_term(ATTR_UNDERLINE);
}

sub set_text_style {
  # sect15.html#set_text_style
  my ($self, $text_style) = @_;
  attr_off();
  attr_reverse() if ($text_style & Games::Rezrov::ZConst::STYLE_REVERSE);
  attr_bold() if ($text_style & Games::Rezrov::ZConst::STYLE_BOLD);
  attr_underline() if ($text_style & Games::Rezrov::ZConst::STYLE_ITALIC);
}

sub cleanup {
  # don't just rely on DESTROY, doesn't work for interrupts
  attr_off();
  $_[0]->set_upper_lines(0);
  # reset scrolling if necessary
#  $_[0]->clear_screen();
  $_[0]->absolute_move(0, $rows) if $terminal;
  # move to last line
}

sub story {
  return (defined $_[1] ? $_[0]->{"story"} = $_[1] : $_[0]->{"story"});
}

sub manual_read_line {
  # read a line manually
  # incompatible with ReadLine, but compatible with preloaded input
  my ($self, $buf) = @_;
  $buf = "" unless defined $buf;
  my ($ord, $char);
  while (1) {
    $char = get_key();
    $ord = ord($char);
    if ($ord == Games::Rezrov::ZConst::ASCII_DEL or
	$ord == Games::Rezrov::ZConst::ASCII_BS) {
      if (my $len = length($buf)) {
	print $self->backspace_sequence();
	do_term(DELETE_CHAR);
	$buf = substr($buf, 0, $len - 1);
      }
    } elsif ($ord == Games::Rezrov::ZConst::ASCII_LF or
	     $ord == Games::Rezrov::ZConst::ASCII_CR) {
      return $buf;
    } elsif ($ord >= 32 and $ord <=127) {
      $buf .= $char;
      print $char;
    }
  }
}

sub set_upper_lines {
  my ($self, $ul) = @_;
  $UPPER_LINES = $ul if defined $ul;
  if ($self->scrolling_style() == SCROLL_STYLE_CS) {
    # set the scroll region (protect upper window)

#    my $reserve = $UPPER_LINES + ($HAVE_STATUS_LINE ? 1 : 0);
    my $reserve = $UPPER_LINES;
    # I forget why we don't need to include the status line...
    # ...or is this an ominous sign? :/

    print $terminal->Tgoto(SET_SCROLL_REGION, $rows, $reserve) if $terminal;
    # HACK
    # this "kind of" works, but args are reversed (1st=col 2nd=row)
    # might this break on some systems?
    # Seems to work under Linux but I don't think Tgoto is meant
    # to be used this way.  The "correct" way?
  }
}

sub test_terminal_capabilities {
  # return 1 if given list of capabilities available
  eval {
    local $SIG{__WARN__} = sub {};
    $terminal->Trequire(@_);
  };
  return $@ ? 0 : 1;
}

sub init_scrolling_style {
  # if terminal has "cs" attribute we can use all lines on the screen.
  # the "del" style is still buggy.

  $_[0]->scrolling_style(test_terminal_capabilities(SET_SCROLL_REGION) ?
			 SCROLL_STYLE_CS : SCROLL_STYLE_DEL);
#  $_[0]->scrolling_style(SCROLL_STYLE_DEL);
}

1;
