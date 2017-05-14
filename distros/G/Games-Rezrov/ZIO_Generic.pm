package Games::Rezrov::ZIO_Generic;
#
# shared/skeleton z-machine i/o, options, and speech
#
# FIX ME: provide abstract stub methods which die() w/message
#         requiring implementation
#

use strict;

use Games::Rezrov::ZIO_Tools;
use Games::Rezrov::ZConst;
use Games::Rezrov::Speech;
use Games::Rezrov::MethodMaker qw(
			   current_window
                           zio_options
                           using_term_readline
			  );

@Games::Rezrov::ZIO_Generic::ISA = qw(Games::Rezrov::Speech);
# additional ZIO methods

my $buffer = "";

sub new {
  my ($type, %options) = @_;
  my $self = {};
  bless $self, $type;
  $self->zio_options(\%options);
  $self->init_speech_synthesis() if $options{"speak"};
  $self->init_speech_recognition() if $options{"listen"};
  return $self;
}

sub can_split {
  # true or false: can this zio split the screen?
  return 1;
}

sub groks_font_3 {
  # true or false: can this zio handle graphical "font 3" z-characters?
  return 0;
}

sub fixed_font_default {
  # true or false: does this zio use a fixed-width font?
  return 1;
}

sub can_change_title {
  # true or false: can this zio change title?
  return set_xterm_title();
}

sub can_use_color {
  return 0;
}

sub split_window {}
sub set_text_style {}
sub clear_screen {}
sub color_change_notify {}

sub set_game_title {
  set_xterm_title($_[1]);
}

sub manual_status_line {
  # true or false: does this zio want to draw the status line itself?
  return 0;
}

sub get_buffer {
  # get buffered text; fix me: return a ref?
#  print STDERR "get_buf: $buffer\n";
  return $buffer;
}

sub reset_buffer {
  $buffer = "";
}

sub buffer_zchunk {
  # receive a z-code string; newlines may be present.
  my $nl = chr(Games::Rezrov::ZConst::Z_NEWLINE);
  foreach (unpack "a" x length ${$_[1]}, ${$_[1]}) {
    # this unpack() seems a little faster than a split().
    # Any better way ???
    if ($_ eq $nl) {
      Games::Rezrov::StoryFile::flush();
      $_[0]->newline();
    } else {
      $buffer .= $_;
    }
  }
}

sub buffer_zchar {
  $buffer .= chr($_[1]);
}

sub set_font {
#  print STDERR "set_font $_[1]\n";
  return 0;
}

sub play_sound_effect {
  my ($self, $effect) = @_;
#  flash();
}

sub set_window {
  $_[0]->current_window($_[1]);
}

sub cleanup {
}

sub DESTROY {
  # in case of a crash, make sure we exit politely
  $_[0]->cleanup();
}

sub fatal_error {
  my ($self, $msg) = @_;
  $self->write_string("Fatal error: " . $msg);
  $self->newline();
  $self->get_input(1,1);
  $self->cleanup();
  exit 1;
}

sub set_background_color {
  # set the background to the current background color.
  # That's the *whole* background, not just for the next characters
  # to print (some games switch background colors before clearing
  # the screen, which should reset the entire background to that
  # color); eg "photopia.z5".
  #
  # "That's the *whole* bass..."
  1;
}

sub readline_init {
  #
  # try to initialize Term::Readline if desired and available
  #
  # FIX ME: rather than ->{readline}, ZOptions.pm?
  my ($self) = @_;
  if ($self->zio_options->{readline} and find_module('Term::ReadLine')) {
    require Term::ReadLine;
    my $tr = new Term::ReadLine "what?", \*main::STDIN, \*main::STDOUT;
    unless (ref $tr eq "Term::ReadLine::Stub") {
      $tr->ornaments(0);
      $self->using_term_readline($tr);
      # only set if available and active
    }
  }
}

sub readline {
  # read a line via Term::ReadLine
  # readline insists on resetting the line so we need to give it
  # everything up to the cursor position.
  my ($self, $preloaded) = @_;
  # FIX ME: preloaded input does NOT work with Term::ReadLine!

  my $line;
  {
    local $SIG{__WARN__} = sub {};
    # disable warnings for readline call.
    # Term::ReadLine::Perl spews undef messages when passed an
    # undef prompt (e.g. when "Plundered Hearts" starts)
    my $rl_ref = $_[0]->using_term_readline();
    my $prompt = Games::Rezrov::StoryFile::prompt_buffer();

    if ($prompt and $rl_ref->ReadLine eq "Term::ReadLine::Gnu") {
      # HACK:
      # Term::ReadLine::Perl seems to erase line before prompt, 
      # but Term::ReadLine::Gnu doesn't.  Since the prompt has already
      # been displayed before ReadLine is called, when using Gnu
      # version we need to erase it so we don't wind up with two.
      $self->write_string(pack('c', Games::Rezrov::ZConst::ASCII_BS) x
			  length($prompt));
    }
    
    $line = $rl_ref->readline($prompt);
    # this doesn't work with v5+ preloaded input
  }
  return $line;
}

1;
