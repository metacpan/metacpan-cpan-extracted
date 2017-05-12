package Language::Zcode::Runtime::IO;

use strict;
use warnings;

use IO::File; # for opening transcripts

use vars qw(@EXPORT @ISA);
use Exporter;
@ISA=qw(Exporter);
# TODO move these to Language::Zcode::Runtime::Opcodes?
# Export Z-functions called by translated Z-program
@EXPORT = qw(
    &input_stream &output_stream
    &newline &read_command &show_status 
    &write_text &write_zchar
    &split_window &set_window &erase_window
    &get_cursor &set_cursor 
    &set_text_style
);

use Language::Zcode::Runtime::Input;
use Language::Zcode::Runtime::Text;

=pod

=head1 NAME

Language::Zcode::Runtime::IO - IO for Perl runtimes created by L::Z translations

=head1 DESCRIPTION

This package contains a number of different packages that support
the IO features needed for a running Z-machine. This includes
windows, input and output streams, cursors, lines, and fonts.
See the Z-machine Spec for descriptions of what all these things means.

This package supports more than one "terminal", i.e., Perl toolkit for handling
the I/O into and out of the Z-machine.  OK, right now, it only supports 2:
dumb, which is just regular print statements; and win32, which
involves Win32::Console tools. But in theory, it won't be hard to add support
for Tk, Curses, and others. Why? Because I stole nearly all the code in these
packages from Games::Rezrov, which already does support multiple terminal
types.

This package implements many of the Z-machine I/O opcodes,
things like print, output_stream, and read. It also handles the header,
which mostly deals with I/O.

This package is currently the most hacked of all the packages in 
the Language::Zcode distribution. I hope it gets cleaner eventually.

=cut

# TODO get rid of lots of global variables.
# In general, localize things. Less calling back & forth between
# Perl IO & ZIO packages, if possible.
# Divide Language::Zcode::Runtime::IO into separate classes if possible to handle
# e.g., streams & maybe windows.

{
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
    # XXX STATUS_WIN => 2?

    use constant STYLE_ROMAN => 0;
    use constant STYLE_REVERSE => 1;
    use constant STYLE_BOLD => 2;
    use constant STYLE_ITALIC => 4;
    use constant STYLE_FIXED => 8;
    # sect15.html#set_text_style

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

}

# TODO XXX There's some ugly hacks here. These used to be separate modules.
# Now they're combined which makes exporting weird. Once the code has
# settled down, I should make it prettier.
##################################

# location of various flags in the header
use constant FLAGS_1 => 0x01;  # one byte
use constant FLAGS_2 => 0x10;  # TWO BYTES

# Flags 1, v1-3
use constant IS_TIME_GAME => 0x02;  # bit 1
# bit 2 - story split across two disks
use constant TANDY => 0x08; # bit 3
use constant STATUS_NOT_AVAILABLE => 0x10;  # bit 4
use constant SCREEN_SPLITTING_AVAILABLE => 0x20; # bit 5
use constant VARIABLE_FONT_DEFAULT => 0x40; # bit 6

# Flags 1, v4+
use constant COLOURS_AVAILABLE => 0x01;  # bit 0
use constant PICTURES_AVAILABLE => 0x02;  # bit 1
use constant BOLDFACE_AVAILABLE => 0x04;  # bit 2
use constant ITALIC_AVAILABLE => 0x08;  # bit 3
use constant FIXED_FONT_AVAILABLE => 0x10; # bit 4
use constant SOUND_EFFECTS_AVAILABLE => 0x20; # bit 5 - v6+
use constant TIMED_INPUT_AVAILABLE => 0x80; # bit 7

# Flags 2
use constant TRANSCRIPT_ON => 0x01;            # bit 0
use constant FORCE_FIXED => 0x02;              # bit 1
use constant REQUEST_STATUS_REDRAW => 0x04;    # bit 2 - v6+

# Flags 2, v5+:
# Spec 11: "For bits 3,4,5,7 and 8, Int clears again if it cannot provide the
# requested effect"
use constant WANTS_PICTURES => 0x08;
use constant WANTS_UNDO => 0x10;
use constant WANTS_MOUSE => 0x20;
use constant WANTS_COLOR => 0x40;
use constant WANTS_SOUND => 0x80;
# Flags 2, v6+:
use constant WANTS_MENUS => 0x0100;  # v6+

use constant BACKGROUND_COLOR => 0x2c;
use constant FOREGROUND_COLOR => 0x2d;
# 8.3.2, 8.3.3

use constant SCREEN_HEIGHT_LINES => 0x20;
use constant SCREEN_WIDTH_CHARS => 0x21;
use constant SCREEN_WIDTH_UNITS => 0x22;
use constant SCREEN_HEIGHT_UNITS => 0x24;

use constant FONT_WIDTH_UNITS_V5 => 0x26;
use constant FONT_WIDTH_UNITS_V6 => 0x27;

use constant FONT_HEIGHT_UNITS_V5 => 0x27;
use constant FONT_HEIGHT_UNITS_V6 => 0x26;

my $zio;
my $prompt_buffer;
my ($Rows, $Columns);
# Save position in each window
my $window_cursors;

my $current_window = Games::Rezrov::ZConst::LOWER_WIN;
# XXX get rid of this
sub current_window { $current_window }

# HACKS, FIX ME [ADK: No kidding]
#my ($upper_lines, $lower_lines);
# Need to use from other packages
use vars qw($upper_lines $lower_lines);

# Call once when starting the program
sub start_IO {
    my ($r, $c, $t) = @_;
    # TODO intelligently figure out which terminal to use if none was given
    $t = "dumb" unless defined $t;

    # XXX These two lines mean I don't need to input -r/-c while
    # testing with the ZIO_dumb interface.
#    warn "For now, I'm ignoring -r and -c options\n" if $r || $c;
    if ($t eq "dumb") {$r ||= 24; $c ||= 80}

    if ($t eq "dumb") {
	$zio = new Games::Rezrov::ZIO_dumb(rows=>$r, columns =>$c);
    } elsif ($t eq "win32") {
	$zio = new Games::Rezrov::ZIO_Win32(rows=>$r, columns =>$c);
    } else {
	die "Unknown terminal '$t'\n";
    }
    $zio->set_window(Games::Rezrov::ZConst::LOWER_WIN);
    PlotzPerl::Output::start_output($zio);
# erase_window call in setup_IO calls clear_screen
#    $zio->clear_screen();
}

# Call again for restart
sub setup_IO {
  # XXX I don't handle undo yet ADK
#  $undo_slots = [];
    # cursor positions for individual windows
    $window_cursors = [];
  
    PlotzPerl::Output::setup();
    Language::Zcode::Runtime::Input::setup();

  
  # HACKS, FIX ME
#  $zio->set_version($self);
    # collapses the upper window
    # XXX do we really want to clear screen on a restart?
    erase_window(-1);

    # Centralized management of the status line.
    # Perform a split_window(), we'll use the "upper window" 
    # for the status line.
    # This is BROKEN: Seastalker is a v3 game that uses the upper window!

=pod
  
    # So [ADK] split to a SECOND window. This split will be internal to
    # the Z-machine emulator: the Z-machine isn't able to split to more
    # than one window (in v5), but presumably any I/O that can split once
    # can split more than once. Put status in that window.
    #
    # Tk already does that. Just use manual_status_line for
    # everything.
=cut

    if ($main::Constants{version} <= 3 &&
            $zio->can_split() &&
            !$zio->manual_status_line()) {
        split_window(1);
    }

    #  XXX ADK I think we don't need the $current_window line below - that
    #  is taken care of by set_window
    #  $current_window = Games::Rezrov::ZConst::LOWER_WIN;
    set_window(Games::Rezrov::ZConst::LOWER_WIN);
}

# Read IO stuff from header, write some back depending on interpreter/IO
sub update_header {
    my $version = $main::Constants{version};

    # First do flags1 stuff
    # a "time" game: 8.2.3.2
    #my $f1 = PlotzMemory::get_byte_at(FLAGS_1);
    my $f1 = $PlotzMemory::Memory[FLAGS_1];

    my $start_rows = rows();
    my $start_columns = columns();

    #  $f1 |= TANDY if Games::Rezrov::ZOptions::TANDY_BIT();
    # turn on the "tandy bit"

    if ($version <= 3) {
	if ($zio->can_split()) {
	  $f1 |= SCREEN_SPLITTING_AVAILABLE;
	  $f1 &= ~ STATUS_NOT_AVAILABLE;
	} else {
	  $f1 &= ~ SCREEN_SPLITTING_AVAILABLE;
	  $f1 |= STATUS_NOT_AVAILABLE;
	}

	# XXX copied from Games::Rezrov::ZHeader. Isn't this backwards?!
	if ($zio->fixed_font_default()) {
	  $f1 |= VARIABLE_FONT_DEFAULT;
	} else {
	  $f1 &= ~VARIABLE_FONT_DEFAULT;
	}

    # versions 4+
    } else {
	  # Are they always available? Even for dumb term?
	$f1 |= BOLDFACE_AVAILABLE;
	$f1 |= ITALIC_AVAILABLE;
	$f1 |= FIXED_FONT_AVAILABLE;

	#      $f1 |= 0x80;
	$f1 &= ~TIMED_INPUT_AVAILABLE; # timed input NOT available

	set_header_columns($start_columns);
	set_header_rows($start_rows);
	if ($version >= 5) {
	    if ($zio->can_use_color()) {
		$f1 |= COLOURS_AVAILABLE;
	    }
	}
    }
    # write back flag1
    PlotzMemory::set_byte_at(FLAGS_1, $f1);
    
    # Now do flags2 stuff
    if ($version >= 5) {
	# 8.3.3: default foreground and background
	# FIX ME!

	my $f2 = PlotzMemory::get_word_at(FLAGS_2);
	#      if ($zio->groks_font_3() and
	#	  !Games::Rezrov::StoryFile::font_3_disabled()) {
	    # ZIO can decode font 3 characters
	#	$f2 |= WANTS_PICTURES;
	#      } else {
	    # nope
	#	$f2 &= ~ WANTS_PICTURES;
	#      }
	  
	#      $f2 |= WANTS_UNDO;
	$f2 &= ~ WANTS_UNDO;
	  # FIX ME: should we never use this???

	#      if ($f2 & WANTS_COLOR) {
	    # 8.3.4: the game wants to use colors
	#	print "wants color!\n";
	# }
	PlotzMemory::set_word_at(FLAGS_2, $f2);
    }

    # Other
    # XXX ADK Why isn't this default/default?!
    if ($version >= 5) {
	PlotzMemory::set_byte_at(BACKGROUND_COLOR, Games::Rezrov::ZConst::COLOR_BLACK);
	PlotzMemory::set_byte_at(FOREGROUND_COLOR, Games::Rezrov::ZConst::COLOR_WHITE);
    }

    # Now read bits that get saved during restart/restore
    Language::Zcode::Runtime::IO::restore_restart_bits();
}

{
    my $restart_bits;
    # Get the bits that stay even when you do a restart
    # Namely, transcript and force-fixed-font bits in Flags 2
    sub store_restart_bits {
	my $f2 = PlotzMemory::get_word_at(FLAGS_2);
	$restart_bits = $f2 & 3;
	return;
    }
    # Write the bits that stay even when you do a restart
    # Namely, transcript and force-fixed-font bits in Flags 2
    sub restore_restart_bits {
	# Doesn't do anything if we're starting program for the first time
	return unless defined $restart_bits;
	my $f2 = PlotzMemory::get_word_at(FLAGS_2);
	$f2 &= ~3; # clear bits
	PlotzMemory::set_word_at(FLAGS_2, $f2 || $restart_bits);
	return;
    }
}

sub set_header_columns {
  # 8.4: set the dimensions of the screen.
  # only needed in v4+
  my $columns = shift;
  my $version = $main::Constants{version};
  PlotzMemory::set_byte_at(SCREEN_WIDTH_CHARS, $columns);
  if ($version >= 5) {
      PlotzMemory::set_byte_at($version >= 6 ?
	  FONT_WIDTH_UNITS_V6 : FONT_WIDTH_UNITS_V5, 1);
      PlotzMemory::set_word_at(SCREEN_WIDTH_UNITS, $columns);
    # ?
  }
}

sub set_header_rows {
  my $rows = shift;
  my $version = $main::Constants{version};
  PlotzMemory::set_byte_at(SCREEN_HEIGHT_LINES, $rows);
  if ($version >= 5) {
      PlotzMemory::set_byte_at($version >= 6 ?
	FONT_HEIGHT_UNITS_V6 : FONT_HEIGHT_UNITS_V5, 1);
      PlotzMemory::set_word_at(SCREEN_HEIGHT_UNITS, $rows);
  }
}

sub rows {
    if (defined $_[0]) {
	$Rows = $_[0];
	if ($zio) {
	    set_header_rows($Rows);
	    PlotzPerl::Output::reset_write_count();
	}
	$lower_lines = $Rows - $upper_lines if defined $upper_lines;
    }
    return $Rows;
}

sub columns {
    if (defined $_[0]) {
	# ZIO notifies us of its columns
	$Columns = $_[0];
	set_header_columns($_[0]) if $zio;
	show_status() if $main::Constants{version} <= 3 and $zio;
    }
    return $Columns;
}

sub is_time_game {
    my $f1 = $PlotzMemory::Memory[FLAGS_1];
    return $f1 & IS_TIME_GAME;
}

# The I/O-heavy part of the "read" opcode
sub read_command {
    my ($max_text_length, $time, $routine, $initial_buf) = @_;
    # XXX can initial_buf affect read from script, too?
    # Does game set initial buf or do we?!
    my $version = $main::Constants{version};

    # flush any buffered output (e.g. the '>') before the prompt.
    PlotzPerl::Output::flush();

    # Get commands from a script file? Returns undef if not
    # currently reading from a file OR if that file ended
    # (newline at end of command is NOT returned)
    my ($s, $textref);
    if (defined ($s = Language::Zcode::Runtime::Input::get_line_from_file())) {
	$textref = new Language::Zcode::Runtime::Text::Input::File::Line $s;

    } else { # read from keyboard
	show_status() if $version <= 3;
	# Restart the counter for [MORE] prompts. Note: do this only when
	# reading from the screen, not from a file.
	PlotzPerl::Output::reset_write_count();

	$s = $zio->get_input($max_text_length, 0,
				"-time" => $time,
				"-routine" => $routine,
				"-preloaded" => $initial_buf,
			    );
	$textref = new Language::Zcode::Runtime::Text::Input::Screen::Line $s;
    }
    # Record command to transcript/command file(s)
    $$textref .= chr Games::Rezrov::ZConst::Z_NEWLINE; # we chomped $s
    PlotzPerl::Output->output($textref);
    #  printf STDERR "cmd: $s\n";

    return $s;
}

=pod

# ascii
use constant LINEFEED => 10;

# Stolen from Games::Rezrov. I don't know what rezrov did with $zi arg.
# read a single character
# 10.7: only return characters defined in input stream
# 3.8: character "10" (linefeed) only defined for output.
sub read_char {
    my ($useless, $time, $routine) = @_; #my ($argv, $zi) = @_;
    PlotzPerl::Output::reset_write_count();
    PlotzPerl::Output::flush();
    die("read_char: 1st arg must be 1") unless $useless == 1;
    my $result = screen_zio()->get_input(1, 1,
					    "-time" => $time,
					    "-routine" => $routine,
					    #"-zi" => $zi
					);
    # remap keyboard "linefeed" to what the Z-machine will recognize as a
    # "carriage return".  Required for startup form in "Bureaucracy"
    # XXX - does keyboard ever return 13 (non-IBM-clones)?
    # XXX can we just do s/\n/chr(Z_NEWLINE)/e?
    my $code = ord(substr($result,0,1));
    $code = Games::Rezrov::ZConst::Z_NEWLINE if ($code == LINEFEED);
    return $code;
}

=cut

sub show_status {
    # only called if needed; see spec 8.2
    # Spec15 "show_status": In theory this opcode is illegal in later Versions
    # but an interpreter should treat it as nop, because Version 5 Release 23
    # of 'Wishbringer' contains this opcode by accident.) 
    return unless $main::Constants{version} <= 3;
    return unless $zio->can_split();

    # get the current location. (test for valid object id 8.2.2.1)
    # XXX Move preliminary stuff to Language::Zcode::Runtime::Opcodes::show_status
    # which calls this to do the IO?
    my $room = Language::Zcode::Runtime::Opcodes::global_var(0);
    my $loc = Language::Zcode::Runtime::Opcodes::thing_location($room, 'name');
    my $room_name = defined $loc
       ? Language::Zcode::Runtime::Opcodes::decode_text($loc) 
       : "[Unknown location]";
    #  die "loc = $room_name";

    my $g1 = Language::Zcode::Runtime::Opcodes::global_var(1);
    my $g2 = Language::Zcode::Runtime::Opcodes::global_var(2);
    my $right_chunk;
    if (&is_time_game()) {
	my ($hours, $minutes) = ($g1, $g2);
	my $m = $hours >= 12 ? "pm" : "am"; # 12:30 pm is lunchtime, not bedtime
	if ($hours > 12) {
	    $hours -=12;
	} elsif ($hours == 0) {
	    $hours = 12;
	}
        $right_chunk = "$hours:$minutes $m"
    } else {
	my $score = unpack('s', pack('s', $g1));
	my $moves = $g2;
	$right_chunk = "$score/$moves";
    }

    $zio->show_status($room_name, $right_chunk);
    return;
}

# Write a newline to currently selected streams
# TODO Is this always PP::Text::Output("\n")?
sub newline { PlotzPerl::Output::newline(); }

# get the ZIO for the screen
sub screen_zio {
  return $zio;
}

# write a given string to (0 or more streams of) output
sub write_text{PlotzPerl::Output->output(new Language::Zcode::Runtime::Text::Output shift)}

sub write_zchar { PlotzPerl::Output->write_zchar($_[0]); }

sub output_stream { PlotzPerl::Output::output_stream(@_); }

sub input_stream { Language::Zcode::Runtime::Input::input_stream($_[0]); }

sub clean_IO { 
    &Language::Zcode::Runtime::Input::cleanup();
    &PlotzPerl::Output::cleanup();
}

########################################
#
{

package PlotzPerl::Output;

=pod

This package handles (some) output from the game.

That output may go to various streams, one of which is the screen
(which includes windows et al.)

=cut

# 7.1.1
use constant STREAM_SCREEN => 1;
# transcript of user input and game output
use constant STREAM_TRANSCRIPT => 2;
# 7.1.2.1 - memory
use constant STREAM_MEMORY => 3;
# 7.1.2.3 - user input
use constant STREAM_USER_INPUT => 4;

# Mike Edmonson's extra stream for fancy stuff
# local: when redirecting screen output; when active send
# output here instead of to screen
#use constant STREAM_STEAL => 5;

my $Output; # singleton object handling this class

sub new {
    my ($class, $zio) = @_;
    my @streams;
    # Create all streams, even if we don't end up using them.
    $streams[STREAM_SCREEN] = new PlotzPerl::OutputStream::Screen "UI" => $zio;
    $streams[STREAM_TRANSCRIPT] = new PlotzPerl::OutputStream::Transcript;
    $streams[STREAM_MEMORY] = new PlotzPerl::OutputStream::Memory;
    $streams[STREAM_USER_INPUT] = new PlotzPerl::OutputStream::UserInput;
    my $self = {
	streams => \@streams,
    };
    bless $self, $class;
    return $self;
}

# array ref of currently selected streams
# Gets called at start but not restart
sub start_output {
    my ($zio) = @_; # object that does UI for screen I/O
    $Output = new PlotzPerl::Output $zio;
}

# Gets called at start AND restart
sub setup {
    reset_write_count();
    output_stream(STREAM_SCREEN);
}

sub get_streams { 
    my $self = shift;
    # Don't return streams[0]
    grep {ref} @{$self->{"streams"}};
}

sub get_stream {
    my ($self, $str) = @_;
    die "Bad args to get_stream" unless $#_ == 1;
    # XXX late night hack - allow calling this sub w/ object or class
    if (!ref $self) { $self = $Output; } # print "hi $self\n" }
    my $ret = $self->{"streams"}[$str] 
	or die "Illegal arg '$str' to get_stream\n";
    return $ret;
}

# Try writing to each stream. Each stream decides whether to output
# $text depending on whether that stream is selected, whether
# the current window echoes its text to that stream, and
# what kind of text $text is (e.g., input vs. output).
sub output {
    my ($self, $text) = @_;
    die "Output::output expects a self/class arg\n" unless defined $text;
    # XXX call current_window in &output?
    my $window = Language::Zcode::Runtime::IO::current_window();
    # (Pass $window even to streams that don't really need it. Let them
    # worry about whether they need it.)
    # If we output to stream 3, don't output to any other stream.
    $self->get_stream(STREAM_MEMORY)->output($text, $window) and return;

    # Note: try writing to transcript before screen, because if someone
    # sneakily modified the Z-machine transcript bit, then Transcript's
    # output() needs to figure that out and prompt (on the screen!) for a 
    # transcript filename before printing the current $text to the screen.
    $self->get_stream(STREAM_TRANSCRIPT)->output($text, $window);
    $self->get_stream(STREAM_SCREEN)->output($text, $window);
    $self->get_stream(STREAM_USER_INPUT)->output($text, $window);
}


# write a decoded z-char to selected output streams.
sub write_zchar {
    my ($self, $char) = @_;
    # 3.8.2.1: "null" has no effect on any output stream
    return unless $char;

    # TODO support ZSCII
    my $trans = chr $char;

    # TODO support graphics codes
=pod

    if (($char >= 179 and $char <= 218) or
      ($char >= 0x18 and $char <= 0x1b)) {
	# sect16.html; convert IBM PC graphics codes
	$trans = $Z_TRANSLATIONS{$char} || "*";
	#    print STDERR "trans for $char => $trans\n";
    }

=cut

    my $textref = new Language::Zcode::Runtime::Text::Output $trans;
    $self->output($textref);
}

# Write to the screen's lower window whether or not 
# stream 1 is currently selected.
# (Used for error messages, e.g.)
sub write_to_screen {
    my ($self, $text) = @_;
    my $window = Games::Rezrov::ZConst::LOWER_WIN;
    # I.e., don't test whether it's selected or whatever else, just write to it
    $self->get_stream(STREAM_SCREEN)->stream($text, $window);
}

sub newline { PlotzPerl::Output->write_zchar(Games::Rezrov::ZConst::Z_NEWLINE); }

sub register_newline { $Output->get_stream(STREAM_SCREEN)->register_newline }
sub reset_write_count { $Output->get_stream(STREAM_SCREEN)->reset_write_count }

=pod

 wrote_something should only be set when doing stream 1? Also stream 2
 will always be fixed font. In fact we will need to store x position
 for stream 2 (but not y because we dont have to worry about scrolling)

=cut

# flush and format the characters buffered by the ZIO
sub flush {
    my $screen = PlotzPerl::Output->get_stream(STREAM_SCREEN);
    my $transcript = PlotzPerl::Output->get_stream(STREAM_TRANSCRIPT);
    $_->flush for ($screen, $transcript);
}


#
# output streams
#

# select/deselect output streams. Spec 7
# XXX Handle selecting an already open stream, closing a closed one
sub output_stream {
    # $str will be a signed number
    my ($str, $table_start) = @_;

    # selecting stream 0 does nothing
    return if $str == 0;

    #  print STDERR "output_stream $str\n";
    my $astr = abs($str);
    my $selecting = $str > 0;

    # XXX This is all we'll need in this sub!
    my $stream = PlotzPerl::Output->get_stream($astr);
    if ($selecting) {
	# (Stream 3 needs table_start arg)
	# Unset $selecting if we didn't successfully open file, e.g.
	$selecting = $stream->select($table_start);
    } else {
	$stream->deselect();
    }
}

# End of program cleanup
# XXX Eventually, the whole big "if" goes away
sub cleanup { $_->cleanup() for $Output->get_streams }

} # end package PlotzPerl::Output

################################################################################
{

package PlotzPerl::OutputStream;

=head2 PlotzPerl::OutputStream

This class handles a single output stream, like the screen or a transcript
file.

=cut

@PlotzPerl::OutputStream::ISA = (); # No parents

sub new {
    my ($class, %arg) = @_;
    my $self = {};
    bless $self, $class;
    $self->init(%arg);
    return $self;
}

sub init {
    my ($self) = @_;
    # I originally wanted to say "call all your parents' init()s
    # and have this sub inherited. But it doesn't work. (Child classes
    # can't loop over their own @ISA and call those classes' init()s.)
    # Simplest solution is just to explicitly loop
    # over each parent class' $self->parent::init sub in each class.
    #     foreach my $parent (@$name) {${parent}::init($self, %arg)}
    # Or, even simpler, explicitly list the names of the parents & call
    # their inits

    # By default, don't select (but don't call deselect: it does more stuff)
    $self->{"selected"} = 0;
}

sub is_selected { return shift->{"selected"} }

# Start writing to this stream
# XXX For all streams but 3, error to open when already open?
sub select { shift->{"selected"} = 1 }

# Stop writing to this stream
# (Use 0, not "", because for Transcript we need to set a bit to this value)
sub deselect { shift->{"selected"} = 0 }

# Is this OutputStream willing to accept the given text (in the given window)?
sub accept_stream { 1; }

# stream given text (in given window) to this stream, which may
# choose not to accept the stream for a number of reasons
# (e.g., the stream's not selected, or text in the given window
# isn't echoed to this stream)
sub output {
    my ($self, $text, $window) = @_;
    if ($self->is_selected() && $self->accept_stream($text, $window)) {
	$self->stream($text, $window);
	return 1;
    } else {
        return 0;
    }
}

# Send given text (in given window) to this stream.
# Stream decides whether to buffer text or write it, and whether writing
# means writing to a file, screen, or memory.
# Subclasses will override this to do fancy buffering with newlines.
sub stream {
    my ($self, $text, $window) = @_;
    #my $nl = chr(Games::Rezrov::ZConst::Z_NEWLINE);
    #$text =~ s/(.*?)($nl)?/something/g);
    $self->write($text);
}

# End of program cleanup: make sure stream is deselected
sub cleanup { 
    my $self = shift;
    $self->deselect if $self->is_selected();
}

} # end package PlotzPerl::OutputStream

#######################################

{

package PlotzPerl::OutputStream::File;

=head2 PlotzPerl::OutputStream::File

This abstract class handles output streams that write to files.

=cut
use vars qw(@ISA);
@ISA= qw(PlotzPerl::OutputStream);

sub init {
    my ($self, %arg) = @_;
    $self->PlotzPerl::OutputStream::init(%arg);
    # Don't actually open the file yet
    $self->filehandle(new IO::File);
    $self->filename("");
    return $self;
}

sub filename {
    my ($self, $fn) = @_;
    $self->{"filename"} = $fn if defined $fn;
    return shift->{"filename"};
}

sub filehandle {
    my ($self, $fh) = @_;
    $self->{"filehandle"} = $fh if defined $fh;
    return shift->{"filehandle"};
}

sub open {
    my ($self) = @_;
    my $fn = $self->filename() or die "No filename for stream\n";
    # Should be IO::File object
    my $fh = $self->filehandle() or die "No filehandle for stream\n";
    if ($fh->open(">$fn")) {
	return 1;
    } else {
	Language::Zcode::Runtime::IO::write_text("Can't open file $fn: $!\n");
	return 0;
    }
}

sub deselect {
    my $self = shift;
    if ($self->is_selected()) {
	$self->SUPER::deselect;
	my $fh = $self->filehandle();
	$fh->close();
    }
}

sub stream {
    my ($self, $text, $window) = @_;
#    warn "Streaming $$text\n";
    # No need to buffer
    $self->write($$text);
}

# Write a string: may have ZSCII newlines AND \n's.
sub write {
    my ($self, $text) = @_;
    my $nl = chr(Games::Rezrov::ZConst::Z_NEWLINE);
    $text =~ s/$nl/\n/g;
    $self->write_line($text);
}

# Write a string: guaranteed no ZSCII newlines
sub write_line {
    my ($self, $text) = @_;
#    warn "printing $text to file $self->filename\n";
    my $fh = $self->filehandle() 
	or die "Can't find filehandle for file ",$self->filename,"\n";
    print $fh $text;
}


# Print Perl newlines to files. Spec says output chr 13, but that's
# probably for the screen only.
sub newline {
#    warn "printing newline to transcript\n";
    shift->write_line("\n");
}

# End of program cleanup
# (Close on closed filehandle complains, but undef'ing it does close if nec.)
#sub cleanup { undef shift->{"filehandle"} }
# Just use parent's cleanup, which will call deselect

} # end package PlotzPerl::OutputStream::File

#######################################

{

package PlotzPerl::OutputStream::Buffered;

=head2 PlotzPerl::OutputStream::Buffered

This abstract class handles output streams that write buffered
(word-wrapped) output. We handle this by buffering output instead of
writing it, and whenever we flush, we replace spaces near the edge of
the current line with newlines.

=cut

use vars qw(@ISA);
@ISA = qw(PlotzPerl::OutputStream);

sub init {
    my ($self, %arg) = @_;
    $self->PlotzPerl::OutputStream::init(%arg);
    $self->clear_buffer();
    # 7.2.1: buffering is always on for v1-3, on by default for v4+.
    $self->buffering(1);
    $self->x_pos(0);
    return $self;
}


sub x_pos {
    my ($self, $x_pos) = @_;
    $self->{"x_pos"} = $x_pos if defined $x_pos;
    return shift->{"x_pos"};
}

sub buffer {
    my ($self, $buffer) = @_;
    $self->{"buffer"} = $buffer if defined $buffer;
    return shift->{"buffer"};
}
sub clear_buffer { shift->{"buffer"} = "" }

sub add_to_buffer {
    my ($self, $str) = @_;
    my $buffer = $self->buffer();
    $buffer .= $str;
    # Put in actual buffer
    $self->buffer($buffer);
    # Word-wrap buffer and flush it if necessary
    $self->maybe_flush();
    
}

=pod

 Note that changing screen size, font changes the number of chars needed to
 finish the line so I need to call maybe_flush (which flushes only if nec.)
 from add_to_buffer as well as any time I change one of the above.
 
 I need to call flush for sure any time I switch windows OR from, e.g.,
 filename_prompt or read_command, where I want to make sure the user sees
 something so that they can input. (Just call it from get_input instead?)
 I shouldn't need to call word_wrap, tho, cuz anything that went into
 buffer should already be wrapped.

=cut

# whether text buffering is active
sub buffering {
    # XXX If they turn off buffer, do we flush it?
    my ($self, $val) = @_;
    if (defined $val) { $self->{"buffering"} = $val }
    $self->{"buffering"};
#    die "buffer _[1]\n";
}

# Send a string to this stream. Buffer and/or write it.
sub stream {
    my ($self, $text, $window) = @_;
#    warn "Streaming $$text\n";
    if ($self->buffering() && $window != Games::Rezrov::ZConst::UPPER_WIN) {
    # XXX v6: && $window->buffering
	# Add the string to the buffer, possibly causing a buffer flush
	$self->add_to_buffer($$text);
    } else { # just write whatever string we have
	$self->write($$text, $window);
    }
}

# Write the given string to the stream. May have ZSCII newlines in it
sub write {
    my ($self, $str) = @_;
    # Print one line at a time 
    # (split() behaves too strangely with empty pre/post fields to use here)
    my $nl = chr(Games::Rezrov::ZConst::Z_NEWLINE);
    while ($str =~ s/(.*?)$nl//) { 
	$self->write_line($1);
	$self->newline();
    }
    $self->write_line($str);

    # XXX Added by ADK, not tested. Breaks transcript.
    Language::Zcode::Runtime::IO::prompt_buffer($str);
    # Add string to current position (which might be non-zero if no \n's
    # in this string).
    $self->x_pos($self->x_pos + length $str);
}

# No "write_line" method here, because different buffered streams will
# write differently (to file/screen, e.g.)

# Word-wrap buffer. If there's any NEWLINEs in it (before or because
# of word-wrap) then flush it.
# Wrapping depends on current screen size, window, etc. So we need to
# call maybe_flush to re-wrap any time one of those things changes.
#my $z = new IO::File('>zzz.txt');
sub maybe_flush {
    my $self = shift;
    my $buffer = $self->buffer; 
    my $cw = &Language::Zcode::Runtime::IO::current_window;
    my $nl = chr(Games::Rezrov::ZConst::Z_NEWLINE);
    # Word-wrap each line (including anything after last NEWLINE)
    # Add NEWLINE if string (plus anything already printed, for first line!)
    # is too long
    $buffer =~ s/(.*?)(?=$nl|$)/$self->word_wrap($1, $cw)/ge;

    # Flush all finished lines (if any) out of the buffer
    if ($buffer =~ s/(.*$nl)//) {
	my $to_flush = $1;
	# XXX if there's newlines in here, change to \n and call
	# $zio->register_newlines. Are we doing that?
	$self->write($to_flush);
    }
    # Put any remaining string back in the buffer
    $self->buffer($buffer);
}

# XXX Move $flushing check to maybe_flush?
# Flush this stream's buffer, wordwrap
my $flushing; # Needs to be object-specific?
sub flush {
    # this can happen w/combinations of attributes and pausing
    return if $flushing;
    my $self = shift;
    my $buffer = $self->buffer();
    #  printf STDERR "flush: buffer= ->%s<-\n", $buffer;
    $self->clear_buffer();
    # In theory, if this stream isn't selected, $buffer will be empty.
    # But check just in case.
    return unless length $buffer && $self->is_selected();

    #  print "fs\n";
    $flushing = 1;
    my $current_window = &Language::Zcode::Runtime::IO::current_window;
    # print out the string in a word-wrapped fashion
    $self->write($self->word_wrap($buffer, $current_window));
    $flushing = 0;
    #  print "done flushing\n";
}

# Word-wrap a string, adding newlines when we get to line's end,
# knowing we're in fixed font
sub fixed_word_wrap {
    my ($self, $str, $window) = @_;

    my $x;
    if ($self->isa("PlotzPerl::OutputStream::Screen")) {
	# XXX change this to $self->x_pos once it's working
	my $zio = $self->UI or die "No UI found in fixed_word_wrap";
	($x) = $zio->get_position(); # discard $y
#	(my$q=$str)=~s/\cM/\n/g;print("buffer is '$q' at pos $x\n");
    } else { # transcript
	$x = $self->x_pos();
    }
    # Get start column position; we can't be sure we're starting at
    # column 0.  This is an issue when flush() is called when changing
    # attributes.  Example: "bureaucracy" intro paragraphs ("But
    # Happitec is going to be _much_ more fun...")
    # XXX columns() shouldn't be used for the transcript
    my $have_left = (Language::Zcode::Runtime::IO::columns() - $x);

    # We may go through this loop several times, once per line of output
    my $build_string = "";
    my $nl = chr(Games::Rezrov::ZConst::Z_NEWLINE);
    while (my $len = length($str)) {
	# No need to put in more newlines
	if ($len < $have_left) {
	    last;

	# Go up to space (or last column), then NEWLINE
	} else {
	    # Space before the end of the line?
	    # XXX Are we supposed to wordwrap on periods too? In games,
	    # it shouldn't matter, cuz there's always a space after a period.
	    # Spec 7.2 just says "new-lines are automatically printed to ensure
	    # that no word (of length less than the width of the screen)
	    # spreads across two lines." Hm. Define 'word'.
	    my $first_space = rindex($str, " ", $have_left-1);

	    # watch out for spaceless string > number of columns left
	    # In that case, do the best we can and force a newline
	    my $print_size = $first_space == -1 ? $have_left - 1 : $first_space;
	    # Remove first N characters from string,
	    # add them to string we're building, plus a NEWLINE
	    my $s = substr($str, 0, $print_size, "") . $nl;
	    $str =~ s/^ //;
	    $build_string .= $s;
	  #	  printf STDERR "wrapping: %d, %d, %s x:$x y:$y col:$columns\n",
	  #	      length $str, $have_left, $str;
	    $have_left = Language::Zcode::Runtime::IO::columns(); # for next run through loop
	}
    }

    $build_string .= $str; # add on whatever's left
    return $build_string;
}

# Reset X x_pos
sub newline { shift->x_pos(0) }

sub deselect { 
    my $self = shift;
    $self->flush; 
    $self->SUPER::deselect();
}

} # end package PlotzPerl::OutputStream::Buffered

#######################################

{

package PlotzPerl::OutputStream::Screen;

=head2 PlotzPerl::OutputStream::Screen

This class handles the screen output stream.

=cut

use vars qw(@ISA);
@ISA = qw(PlotzPerl::OutputStream::Buffered);
use File::Basename;

sub init {
    my ($self, %arg) = @_;
    $self->PlotzPerl::OutputStream::Buffered::init(%arg);
    # actual UI screen object
    my $zio = $arg{"UI"};
    die "Need UI object to create a ", ref $self,"object\n"
        unless ref($zio)&& $zio->isa("Games::Rezrov::ZIO_Generic");
    $self->{"UI"} = $zio;
    $self->reset_write_count(); # didn't write anything yet
    my $gamename = basename($0);
    $zio->set_game_title("Plotz - $gamename");

    return $self;
}

sub UI { shift->{"UI"} }

sub reset_write_count {
    my $self = shift;
    $self->lines_wrote(0);
    $self->wrote_something(0);
}

sub lines_wrote { 
    my ($self, $val) = @_;
    $self->{"lines_wrote"} = $val if (defined $val);
    $self->{"lines_wrote"};
}

sub wrote_something { 
    my ($self, $val) = @_;
    $self->{"wrote_something"} = $val if (defined $val);
    $self->{"wrote_something"};
}

# Note: select and deselect subs don't DO anything, except set the
# "selected" attribute, so just inherit the parent class version of the subs

sub accept_stream {
    my ($self, $text, $window) = @_;
    !$text->isa("Language::Zcode::Runtime::Text::Input::Keypress") && # read_char doesn't echo
    !$text->isa("Language::Zcode::Runtime::Text::Input::Screen"); # Already echoed to screen
}

sub newline {
    my ($self) = @_; # don't need $window
    $self->SUPER::newline(); # reset X cursor in $self
    my $screen = $self->UI(); # Tk, Win32, etc. Screen object
    Language::Zcode::Runtime::IO::prompt_buffer("");
    $screen->newline;
}

# Write given string (which has no ZSCII newlines) to the stream
sub write_line {
    my ($self, $str) = @_;
    my $screen = $self->UI(); # Tk, Win32, etc. Screen object
    $screen->write_string($str);
}

# Print [MORE] if we've written a whole page
# Stream 1 is the only stream that does "y-buffering"
# XXX BUG!
# XXX Spec 10.2.4: When the the current stream is stream 1, the interpreter
# should not hold up long passages of text (by printing "[MORE]" and waiting
# for a keypress, for instance).  input_stream(1) should call
# PlotzPerl::Output::no_y_buffering, which should set something that
# this checks. Actually, frotz ASKS if you want [MORE]s. Maybe do that
# with a -M option or something. Even if we are printing [MORE]s, we should
# still not reset_write_count whenever we do a @read from a file.
# 8.4.1: screen height of 255 means never print [MORE]
sub register_newline {
    my $self = shift;
    my $lower_lines = $Language::Zcode::Runtime::IO::lower_lines;
    #  print "rn1 $wrote_something $current_window $lower_lines\n";
#      print " rn1 $lower_lines ";
    return unless (Language::Zcode::Runtime::IO::rows() != 255 &&
	 $self->wrote_something() &&
	 # don't count newlines that occur before any text; 
	 # example: start of "plundered hearts", after initial RETURN
	 defined(&Language::Zcode::Runtime::IO::current_window) &&
	 $lower_lines &&
	 $current_window == Games::Rezrov::ZConst::LOWER_WIN
    );
    my $wrote = $self->lines_wrote() + 1;
#      print " rn2 $wrote ";
    #  printf STDERR "rn: %d/%d\n", $wrote, $lower_lines;

    if ($wrote + 1 >= $lower_lines - 1) {
	# need to pause; show prompt.
	#    print STDERR "pausing...\n";
	# XXX more_prompt really does NOT belong in ZIO package.
	# Move it back to this package (once I'm handling cursor &
	# some more stuff in OutputStream::Screen package).
	$self->UI->more_prompt($lower_lines);
	$wrote = 0;
    }
    $self->lines_wrote($wrote);
}

sub word_wrap {
    my ($self, $str, $window) = @_;
    my $ret = "";
    $self->wrote_something(1); # XXX shouldn't be in word_wrap? Put in write()?
    my $zio = $self->UI;

    my ($i, $have_left, $len);
    if ($window != Games::Rezrov::ZConst::LOWER_WIN) {
	# buffering in upper window: nonstandard hack in effect.
	# assume we know what we're doing :)
	#      print STDERR "hack! \"$buffer\"\n";
	#$zio->write_string($str);
	$ret = $str;

    # Only stream 1 can print in variable font
    # XXX Does this test font_mask too?
    } elsif (!$zio->fixed_font_default()) {
	die "Not yet handling variable font\n";

=pod

 Need to change this to just add newlines, not actually print!
      #
      #  Variable font; graphical wrapping
      #
      my ($x, $y) = $zio->get_pixel_position();
      my $total_width = ($zio->get_pixel_geometry())[0];
      my $pixels_left = $total_width - $x;
      my $plen;
      while ($len = length($str)) {
	$plen = $zio->string_width($str);
	if ($plen < $pixels_left) {
	  # it'll fit; we're done
    #	  print STDERR "fits: $str\n";
   Add $str to $ret
	  $zio->write_string($str);
	  last;
	} else {
	  my $wrapped = 0;
	  my $i = int(length($str) * ($pixels_left / $plen));
    #	  print STDERR "pl=$pixels_left, plen=$plen i=$i\n";
    # Do this with rindex
	  while (substr($str,$i,1) ne " ") {
	    # move ahead to a word boundary
    #	    print STDERR "boundarizing\n";
	    last if ++$i >= $len;
	  }

	  while (1) {
	    $plen = $zio->string_width(substr($str,0,$i));
    #	    printf STDERR "%s = %s\n", substr($str,0,$i), $plen;
	    if ($plen < $pixels_left) {
	      # it'll fit
     Change this to add to $ret
	      $zio->write_string(substr($str,0,$i));
	      $zio->newline();
	      $str = substr($str, $i + 1);
	      $wrapped = 1;
	      last;
	    } else {
	      # retreat back a word
	      while (--$i >= 0 and substr($str,$i,1) ne " ") { }
	      last if ($i < 0);
	    }
	  }

	  $zio->newline() unless ($wrapped);
	  # if couldn't wrap at all on this line
	  $pixels_left = $total_width;
	}
      }

=cut

    } else {
	#
	# Fixed font; do line/column wrapping
	$ret = $self->fixed_word_wrap($str, $window);
    }
    Language::Zcode::Runtime::IO::prompt_buffer($ret);
    return $ret;
}

# End of program cleanup
sub cleanup { 
    my $self = shift;
    # First flush buffer. Then cleanup the GUI
    $self->PlotzPerl::OutputStream::Buffered::cleanup();
    $self->UI->cleanup();
}

} # end package PlotzPerl::OutputStream::Screen

#######################################

{

package PlotzPerl::OutputStream::Transcript;

=head2 PlotzPerl::OutputStream::Transcript

This class handles the output stream that stores the
user's commands (to @read) as well as the game's screen output.

=cut

use vars qw(@ISA);
@ISA = qw(PlotzPerl::OutputStream::Buffered PlotzPerl::OutputStream::File);

sub init {
    my ($self, %arg) = @_;
    $self->PlotzPerl::OutputStream::Buffered::init(%arg);
    $self->PlotzPerl::OutputStream::File::init(%arg);
    return $self;
}

# Either always look at Flags1 before trying to write to transcript,
#    or change set_word_at to check if we are setting Flags1.
#Former seems a *bit* less messy. Especially because we sometimes
#set using direct access to $PlotzMemory::Memory

# Anytime you're trying to figure out if transcript is selected
# also check/update transcript bit of Flags2
# If someone sets the bit explicitly, then the transcript won't turn on
# right away, BUT we're guaranteed that this sub will be called any time
# a person is thinking of writing to the transcript file, so as soon as it's
# important for them to be in synch, we'll synch them.
#
# One problem: If we call select() here, then when we prompt for a filename,
# system will try to print that prompt string to the transcript, which will
# call this sub, and since ->{"selected"} hasn't changed yet (and shouldn't
# change until we're sure the file exists) it'll recurse. HACK around it.
my $beware_recursion = "";
sub is_selected {
    my $self = shift;
    my $is_selected = $self->SUPER::is_selected();
    my $mem = PlotzMemory::get_word_at(Language::Zcode::Runtime::IO::FLAGS_2); # memory says should be on
    # If FLAGS2 and selected are inconsistent, then the interpreter
    # set/unset FLAGS2 behind our back, so select or deselect the stream
    my $mem_on = $mem & Language::Zcode::Runtime::IO::TRANSCRIPT_ON;
    if ($mem_on != $is_selected && !$beware_recursion) {
	$beware_recursion = 1; # this is the case that can cause it
	$mem_on ? $self->select() : $self->deselect();
	$is_selected = $mem_on;
	$beware_recursion = ""; # don't worry anymore
    }
    return $is_selected;
}

sub select {
    my $self = shift;
    my $success = 1;
    #      print STDERR "opening transcript\n";
    # 7.1.1.2: only ask once per session
    my $filename = $self->filename();
    if (!$filename) {
	$filename = Language::Zcode::Runtime::IO::filename_prompt("-check"=>1, "-ext"=>"txt");
	$self->filename($filename);
    }
    if ($filename && $self->open()) {
	my $fh = $self->filehandle();
	# Only write this to screen?
	Language::Zcode::Runtime::IO::write_text("Writing transcript to $filename.");

	$self->SUPER::select();
	# Update FLAGS2 any time interpreter selects
	my $mem = PlotzMemory::get_word_at(Language::Zcode::Runtime::IO::FLAGS_2);
	PlotzMemory::set_word_at(Language::Zcode::Runtime::IO::FLAGS_2, 
	    $mem | Language::Zcode::Runtime::IO::TRANSCRIPT_ON);

    } else {
	# I.e., write newline to screen etc., not just to transcript
	PlotzPerl::Output::newline();
	$success = 0;
    }
    PlotzPerl::Output::newline();
    PlotzPerl::Output::newline();
    return $success;
}

sub deselect {
    my $self = shift;
    # Update FLAGS2 any time interpreter deselects
    # Do this BEFORE SUPER::select. Otherwise, tests for is_selected
    # in base classes cause us to think transcript bit is on, and
    # this stream gets re-selected!
    my $mem = PlotzMemory::get_word_at(Language::Zcode::Runtime::IO::FLAGS_2);
    PlotzMemory::set_word_at(Language::Zcode::Runtime::IO::FLAGS_2, 
        $mem & ~Language::Zcode::Runtime::IO::TRANSCRIPT_ON);

    # flush buffer
    $self->PlotzPerl::OutputStream::Buffered::deselect();
    # Close file
    $self->PlotzPerl::OutputStream::File::deselect();
}

# Stream 2 doesn't write text from upper window OR keypresses
sub accept_stream {
    my ($self, $text, $window) = @_;
    # Better to use: #$window->echo_to_transcript() ??
    #or maybe: $window->echo(STREAM_TRANSCRIPT)
    return $window != Games::Rezrov::ZConst::UPPER_WIN &&
	!$text->isa("Language::Zcode::Runtime::Text::Input::Keypress");
}

# Use Buffered::stream, not File::stream
sub stream {
    my $self = shift;
    $self->PlotzPerl::OutputStream::Buffered::stream(@_);
}

sub word_wrap {
    my ($self, $str, $window) = @_;
    return $self->fixed_word_wrap($str, $window);
}

# XXX There's probably a cleaner way to do this than dictating which 
# base class to use for each sub!
sub write { shift->PlotzPerl::OutputStream::Buffered::write(@_) }

sub newline {
    my ($self) = @_; # don't need $window
    $self->PlotzPerl::OutputStream::Buffered::newline(); # reset position
    $self->PlotzPerl::OutputStream::File::newline(); # write \n to file
}

# End of program cleanup
sub cleanup { 
    my $self = shift;
    # FIRST flush buffer, THEN close filehandle
    $self->PlotzPerl::OutputStream::Buffered::cleanup();
    $self->PlotzPerl::OutputStream::File::cleanup();
}

} # end package PlotzPerl::OutputStream::Transcript

#######################################

{

package PlotzPerl::OutputStream::Memory;

=head2 PlotzPerl::OutputStream::Memory

This class handles the output stream that stores game output to memory.

=cut

@PlotzPerl::OutputStream::Memory::ISA= qw(PlotzPerl::OutputStream);

sub init {
    my ($self, %arg) = @_;
    $self->SUPER::init(%arg);
    $self->{"streams"} = [];
    return $self;
}

sub new_buffer {
    my ($self, $table_start) = @_;
    my $buf = new PlotzPerl::OutputStream::Table $table_start;
    push @{$self->{"streams"}}, $buf;
	# XXX ADK steal code from GR::ZReceiver so table stream works like file
	# my $buf = new Games::Rezrov::ZReceiver();

    # 7.1.2.1.1: max 16 legal redirects
    die "illegal number of stream3 opens!" if @{$self->{"streams"}} > 16;
}

sub select {
    my ($self, $table_start) = @_;
	die "Not supporting redirect stream yet\n";

    $self->new_buffer($table_start);
    return 1;
}

# deselecting: copy table to memory
sub deselect {
    my $self = shift;
    die "Not yet supporting stream 3\n";
# XXX BUG Newlines are written to output stream 3 as ZSCII 13.  7.1.2.2.1

    my $stack;
    my $buf = pop @{$stack};
    my $table_start = $buf->misc();
    my $pointer = $table_start + 2;
    my $buffer = $buf->buffer();
#  printf STDERR "Writing redirected chunk %s to %d\n", $buffer, $pointer;
    set_byte_at($pointer++, ord) for split //, $buffer;
  #for (my $i=0; $i < length($buffer); $i++) {
  #  set_byte_at($pointer++, ord substr($buffer,$i,1));
  #}
    # record number of bytes written
    set_word_at($table_start, ($pointer - $table_start - 2));

    if (!@{$stack}) {  # no streams left
	$self->SUPER::deselect();
    }

    if ($main::Constants{version} == 6) {
      # 7.1.2.1
      fatal_error("stream 3 close under v6, needs a-fixin");
    }

}

# Stream 3 doesn't store anything the user input, only game output
sub accept_stream {
    my ($self, $text) = @_;
    !$text->isa("Language::Zcode::Runtime::Text::Input");
}

sub stream {
#	my $stack = $zios->[STREAM_MEMORY];
	#    printf STDERR "redirected chunk: %s\n", $$text;
#	$stack->[$#$stack]->buffer_zchunk($text);
}

sub write {
    die "OutputStream::Memory::write not yet implemented\n";
#    write chars to memory
}

} # end package PlotzPerl::OutputStream::Memory

#######################################

{

package PlotzPerl::OutputStream::UserInput;

=head2 PlotzPerl::OutputStream::UserInput

This class handles the output stream that stores the
user's commands (to @read) as well as the game's screen output.

=cut

@PlotzPerl::OutputStream::UserInput::ISA= qw(PlotzPerl::OutputStream::File);

# No init sub here

sub select {
    my $self = shift;
    my $success = 1;
    my $filename = Language::Zcode::Runtime::IO::filename_prompt("-ext"=>"cmd", "-check" => 1);
    if ($filename) {
	$self->filename($filename);
	if ($self->open()) {
	    Language::Zcode::Runtime::IO::write_text("Recording commands to $filename.");
	    $self->SUPER::select();
	} else {
	    Language::Zcode::Runtime::IO::write_text("Can't write to $filename: $!");
	    $success = 0;
	}
    } else {
	$success = 0;
    }
    PlotzPerl::Output::newline();
    PlotzPerl::Output::newline();
    return $success;
}

sub deselect {
    my $self = shift;
    if ($self->is_selected()) {
	$self->SUPER::deselect();
	Language::Zcode::Runtime::IO::write_text("Command recording stopped.");
    } else {
	Language::Zcode::Runtime::IO::write_text("Um, I'm not recording commands now.");
    }
    PlotzPerl::Output::newline();
    PlotzPerl::Output::newline();
}

# Stream 4 prints ALL user input - including @read and @read_char -
# whether from a file or the screen
sub accept_stream { $_[1]->isa("Language::Zcode::Runtime::Text::Input") }

# cleanup: Just do OS::File->cleanup

} # end package PlotzPerl::OutputStream::UserInput

################################################################################



# Tools for streams
sub filename_prompt {
    my (%options) = @_;

    my $ext = $options{"-ext"} || die "No extension given to filename_prompt";
    my $default;
    $default = $options{"-default"} or ($default = $0) =~ s/(\b\..*|)$/.$ext/;

    my $zio = screen_zio();
    PlotzPerl::Output::flush(); # print leftover buffered stuff before prompting
    newline();
    my $prompt = "Filename [$default]: ";
    # XXX write this to any open streams
    $zio->write_string($prompt);
    $prompt_buffer = $prompt;
    #  write_text(sprintf "Filename [%s]: ", $default);
    my $filename = $zio->get_input(50, 0) || $default;
    if ($filename) {
	if ($options{"-check"} and -f $filename) {
	    $zio->write_string($filename . " exists, overwrite? [y/n]: ");
	    my $proceed = $zio->get_input(1, 1);
	    if ($proceed =~ /^y/i) {
		# XXX Should this be a special kind of text that doesn't
		# get echoed to transcript?
		write_text("Yes.");
		# In theory, don't need to do this. open ">" will overwrite.
		unlink($filename);
	    } else {
		write_text("No.");
		$filename = "";
	    }
	    newline();
	}
    }

    return $filename;
}

########################################
#
# Cursor
#
# XXX ADK Need to check out font_mask, set_cursor, set_text_style,
# erase_window, set_window
sub set_cursor {
    my ($line, $column, $win) = @_;
    my $zio = screen_zio();
    $zio->fatal_error("set_cursor on window $win not supported") if $win;

    $line--;
    $column--;
    # given starting at 1, not 0

    #  print STDERR "set_cursor\n";
    if ($current_window == Games::Rezrov::ZConst::UPPER_WIN) {
	# upper window: use offsets as specified
	$zio->absolute_move($column, $line);
    } else {
	# XXX Huh? Spec 8.7.2.3: "The opcode has no effect when the lower
	# window is selected." Maybe we need to have a z_set_cursor,
	# which does nothing if in lower window, but calls this if in
	# upper window - because we need to call set_cursor from
	# inside the program when we do things like erase the screen.
	# lower window: map coordinates given upper window size
	$zio->absolute_move($column, $line + $upper_lines);
    }
}

sub get_cursor {
    # put cursor coordinates at given offset
    untested();
    my ($x, $y) = screen_zio()->get_position();
    PlotzMemory::set_word_at($_[0], $y);
    PlotzMemory::set_word_at($_[1], $x);
}

########################################
#
# Fonts
#
my $fm;
my $fm2;
sub font_mask {
  $fm = $_[0] if defined $_[0];
  my $fm2 = $fm || 0;
  $fm2 |= Games::Rezrov::ZConst::STYLE_FIXED
    if $current_window == Games::Rezrov::ZConst::UPPER_WIN;
  # 8.7.2.4:
  # An interpreter should use a fixed-pitch font when printing on the
  # upper window.

=pod
  if (0 and $header and $header->fixed_font_forced()) {
    # 8.1: game forcing use of fixed-width font
    # DISABLED: something seems to be wrong here...
    # photopia (all v5 games?) turn on this bit after 1 move?
    $fm2 |= Games::Rezrov::ZConst::STYLE_FIXED;
  }
=cut

  return $fm2;
}

sub set_text_style {
  my $text_style = $_[0];
  PlotzPerl::Output::flush();
  my $mask = font_mask();
  if ($text_style == Games::Rezrov::ZConst::STYLE_ROMAN) {
    # turn off all
    $mask = 0;
  } else {
    $mask |= $text_style;
  }
  $mask = font_mask($mask);
  # might be modified for upper window
  
  screen_zio()->set_text_style($mask);
}

########################################
#
# Windows
#
sub split_window {
    my ($lines) = @_;
    my $zio = screen_zio();

    $upper_lines = $lines;
    $lower_lines = rows() - $lines;
    #  print STDERR "split_window to $lines, ll=$lower_lines ul=$upper_lines\n";

    my ($x, $y) = $zio->get_position();
    if ($y < $upper_lines) {
	# 8.7.2.2
	$zio->absolute_move($x, $upper_lines);
    }
    screen_zio()->split_window($lines);
    # any local housekeeping
}

sub set_window {
    my ($window) = @_;
    my $version = $main::Constants{version};
    my $rows = rows();
    #  print STDERR "set_window $window\n";
    PlotzPerl::Output::flush();
    my $zio = screen_zio();

    $window_cursors->[$current_window] = $zio->get_position(1);
    # save callback to restore cursor position when we return to
    # this window

    $current_window = $window;
    # set current window

    if ($version >= 4) {
	if ($current_window == Games::Rezrov::ZConst::UPPER_WIN) {
	  # 8.7.2: whenever upper window selected, cursor goes to top left
	  set_cursor(1,1);
	} else {
	    # restore old cursor position
	    my $restore;
	    if (defined $window_cursors->[$current_window]) {
		# restore former cursor position
		&{$window_cursors->[$current_window]};
	    } else {
		# first switch to window
		# 8.7.2.2: in v4 lower window cursor is always on last line.
		$zio->absolute_move(0, $rows - 1);
	    }
	}

    } else {
	# in v3, cursor always in lower left
	$zio->absolute_move(0, $rows - 1);
    }

    # for any local housekeeping
    $zio->set_window($window);
    # since we always print in fixed font in the upper window,
    # make sure the zio gets a chance to turn this on/off as we enter/leave;
    # example: photopia.
    $zio->set_text_style(font_mask());
}

sub erase_window {
    # $window will be signed
    my ($window) = @_;
    my $zio = screen_zio();
    my $version = $main::Constants{version};
    my $rows = rows();
    if ($window == -1) {
	# 8.7.3.3:
	#    $self->split_window(Games::Rezrov::ZConst::UPPER_WIN, 0);
	# WRONG!
	split_window(0);
	# collapse upper window to size 0
	clear_screen();
	# erase the entire screen
	PlotzPerl::Output::reset_write_count();
	set_window(Games::Rezrov::ZConst::LOWER_WIN);
	set_cursor(($version == 4 ? $rows : 1), 1);
	# move cursor to the appropriate line for this version;
	# hack: at least it\'s abstracted :)
    } elsif ($window < 0 or $window > 1) {
	$zio->fatal_error("erase_window $window !");

    } else {
	#
	#  erase specified window
	#
	my $restore = $zio->get_position(1);
	my ($start, $end);
	if ($window == Games::Rezrov::ZConst::UPPER_WIN) {
	    $start = 0;
	    $end = $upper_lines;
	} elsif ($window == Games::Rezrov::ZConst::LOWER_WIN) {
	    $start = $upper_lines;
	    $end = $rows;
	    PlotzPerl::Output::reset_write_count();
	} else {
	    die "clear window $window!";
	}
	for (my $i = $start; $i < $end; $i++) {
	#      $zio->erase_line($i);
	    $zio->absolute_move(0, $i);
	    $zio->clear_to_eol();
	}
	&$restore();
	# restore cursor position
    }
}

sub clear_screen {
    my $zio = screen_zio();

    if ($zio->can_use_color()) {
	my $fg = $zio->fg() || "";
	my $bg = $zio->bg() || "";
	my $dbg = $zio->default_bg() || "";
	# FIX ME!

	#  printf STDERR "fg=%s/%s bg=%s/%s\n",$fg,$zio->default_fg, $bg, $zio->default_bg;
	if ($bg ne $dbg) {
	  # the background color has changed; change the cursor color
	  # to the current foreground color so we don't run the risk of it 
	  # "disappearing".
	  $zio->cc($fg);
	}
	$zio->default_bg($bg);
	$zio->default_fg($fg);
	$zio->set_background_color();
    }

    $zio->clear_screen();
}

sub prompt_buffer {
  $prompt_buffer = $_[0] if defined $_[0];
  return $prompt_buffer;
}

################################################################################

package Games::Rezrov::ZIO_Generic;
#
# shared z-machine i/o
#
use strict;

#use Games::Rezrov::ZIO_Tools;
#use Games::Rezrov::ZConst;

sub new {
  return bless {}, $_[0];
}

sub current_window {
  return (defined $_[1] ? 
      $_[0]->{"current_window"} = $_[1] : 
      $_[0]->{"current_window"});
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

sub can_use_color {
  return 0;
}

# I/O part of show_status opcode
sub show_status {
    # right_chunk is scores/moves or hours:minutes
    my ($self, $room_name, $right_chunk) = @_;

    my $columns = Language::Zcode::Runtime::IO::columns();
    if ($self->manual_status_line()) {
	# the ZIO wants to handle it
	$self->status_hook($room_name, $right_chunk);
    } else {
	# "generic" status line handling; broken for screen-splitting v3 games
	my $restore = $self->get_position(1);
	$self->status_hook(0);
	# erase
	$self->write_string((" " x $columns), 0, 0);
	$self->write_string($room_name, 0, 0);

	$self->write_string($right_chunk, $columns - length($right_chunk), 0);
	$self->status_hook(1);
	&$restore();
    }
}

sub split_window {}
sub set_text_style {}
sub clear_screen {}
sub color_change_notify {}

sub set_game_title {
    Games::Rezrov::ZIO_Tools::set_xterm_title($_[1]);
}

sub manual_status_line {
  # true or false: does this zio want to draw the status line itself?
  return 0;
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

# write [MORE] at end of page
sub more_prompt {
    my ($self, $lower_lines) = @_;
    # Don't even bother doing Language::Zcode::Runtime::IO::font_mask, since we just
    # reset it. I guess we do need to 
    # call Language::Zcode::Runtime::IO::set_cursor, but prob. only at end
    # (other call can be an internal ZIO call)
    my $restore = $self->get_position(1);

    # XXX Change these to internal ZIO calls (absolute move)
    Language::Zcode::Runtime::IO::set_cursor($lower_lines, 1);
    my $more_prompt = "[MORE]";
    my $old = Language::Zcode::Runtime::IO::font_mask();
    $self->set_text_style(Games::Rezrov::ZConst::STYLE_REVERSE);
    $self->write_string($more_prompt);
    $self->set_text_style(Games::Rezrov::ZConst::STYLE_ROMAN);
    Language::Zcode::Runtime::IO::font_mask($old);
    $self->update();
    $self->get_input(1,1);
    Language::Zcode::Runtime::IO::set_cursor($lower_lines, 1);
    $self->clear_to_eol();
    #    $zio->erase_line($lower_lines);
    #    $zio->erase_line($lower_lines - 1);

    # restore old position
    &$restore();
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


1;

################################################################################
package Games::Rezrov::ZIO_dumb;
# z-machine i/o for dumb/semi-dumb terminals.

BEGIN {
  $ENV{"PERL_RL"} = 'Perl';
}

use strict;

#use Games::Rezrov::GetKey;
#use Games::Rezrov::GetSize;
#use Games::Rezrov::ZIO_Tools;
#use Games::Rezrov::ZIO_Generic;

@Games::Rezrov::ZIO_dumb::ISA = qw(Games::Rezrov::ZIO_Generic);

my $have_term_readline = 0;
my $tr;

my $have_term_readkey;
my ($rows, $columns);
my ($clear_prog);

my $abs_x = 0;
my $abs_y = 0;

$|=1;

sub new {
  my ($type, %options) = @_;
  my $self = new Games::Rezrov::ZIO_Generic();
  bless $self, $type;
  $self->io_setup($options{"readline"});
  
  ($columns, $rows) = Games::Rezrov::GetSize::get_size();
  $columns = $options{columns} if $options{columns};
  $rows = $options{rows} if $options{rows};
  
  unless ($columns and $rows) {
   #print "I couldn't guess the number of rows and columns in your display,\n";
   #print "so you must use -r and -c to specify them manually.\n";
   #exit;
   # XXX HACK!
    $columns = 80; $rows = 250;
  }
  Language::Zcode::Runtime::IO::rows($rows);
  Language::Zcode::Runtime::IO::columns($columns);
  return $self;
}

sub io_setup {
  my ($self, $readline_ok) = @_;

  if (eval('require Term::ReadKey')) {
    import Term::ReadKey;
    $have_term_readkey = 1;
#    ReadMode(3);
    # disable echoing
#    ReadLine(-1);
    # make sure we don't buffer any (invisible) characters
  }

  if ($readline_ok && eval('require Term::ReadLine')) {
      require Term::ReadLine;
    $have_term_readline = 1;
    $tr = new Term::ReadLine 'what?', \*main::STDIN, \*main::STDOUT;
    $tr->ornaments(0);
  }

  # TODO if $^O == windows, "cls". If unix, `which clear`
  $clear_prog = undef; # find_prog("clear");
}

sub write_string {
  my ($self, $string, $x, $y) = @_;
  $self->absolute_move($x, $y) if defined($x) && defined($y);
  print $string;
#  print STDERR "ws: $string\n";
  $abs_x += length($string);
}

sub clear_to_eol {
#  print STDERR "clear to eol; at $abs_x\n";
  my $diff = $columns - $abs_x;
  if ($diff > 0) {
    print " " x $diff;
    # erase
    print pack("c", 0x08) x $diff;
    # restore cursor
  }
}

sub update {
}

#sub find_prog {
#  foreach ("/bin/", "/usr/bin/") {
#    my $fn = $_ . $_[0];
#    return $fn if -x $fn;
#  }
#  return undef;
#}

sub can_split {
  # true or false: can this zio split the screen?
  return 0;
}

sub set_version {
    die "Not using set_version any more";
#  my ($self, $status_needed, $callback) = @_;
#  Games::Rezrov::StoryFile::rows($rows);
#  Games::Rezrov::StoryFile::columns($columns);
#  print STDERR "$columns\n";
#  $self->clear_screen();
  return 0;
}

sub absolute_move {
  my ($nx, $ny) = @_[1,2];
#  printf STDERR "move X to $nx from $abs_x\n";
  if (0 and $nx < $abs_x) {
    # DISABLED
    # "this sidewalk's for regular walkin', not fancy walkin'..."
    my $diff = $abs_x - $nx;
#    printf STDERR "going back %d\n", $abs_x - $nx;
    print pack("c", 0x08) x $diff;
    # go back
    print " " x $diff;
    # erase
    print pack("c", 0x08) x $diff;
    # go back again
  }
  $abs_x = $nx;
  $abs_y = $ny;
}

sub newline {
  # check to see if we need to pause
  print "\n";
  $abs_x = 0;
  PlotzPerl::Output::register_newline();
}

sub write_zchar {
  if ($_[0]->current_window() == Games::Rezrov::ZConst::LOWER_WIN) {
    print chr($_[1]);
#    printf STDERR "wc: %s\n", chr($_[1]);
    $abs_x++;
  } else {
#    printf STDERR "ignoring char: %s\n", chr($_[1]);
  }
}

sub get_input {
  my ($self, $max, $single_char, %options) = @_;
  if ($single_char) {
      # XXX ADK put in explicit package name cuz I'm not use'ing GetSize
    return Games::Rezrov::GetKey::get_key();
  } else {
    if ($have_term_readkey) {
      # re-enable terminal before prompt
      ReadMode(0);
#      ReadLine(0);
    }
    my $line;
    if ($have_term_readline) {
      # readline insists on resetting the line so we need to give it
      # everything up to the cursor position.
      $line = $tr->readline(Language::Zcode::Runtime::IO::prompt_buffer());
      # this doesn't work with v5+ preloaded input
    } else {
      $line = <STDIN>;
      # this doesn't work with v5+ preloaded input
    }
    unless (defined $line) {
      $line = "";
      print "\n";
    }
    chomp $line;
    if ($have_term_readkey) {
      ReadMode(3);
#      ReadLine(-1);
    }
    return $line;
  }
}

sub get_position {
  my ($self, $sub) = @_;
  if ($sub) {
    return sub { };
  } else {
    return ($abs_x, $abs_y);
  }
}

sub clear_screen {
  system($clear_prog) if $clear_prog;
  for (my $i=0; $i < $rows; $i++) {
    # move cursor to lower left
    print "\n";
  }
}

my $warned;
sub set_window {
  my ($self, $window) = @_;
  $self->SUPER::set_window($window);
  if ($window != Games::Rezrov::ZConst::LOWER_WIN) {
    # ignore output except on lower window
    unless ($warned++) {
      my $pb = Language::Zcode::Runtime::IO::prompt_buffer();
      $self->newline();
      Language::Zcode::Runtime::IO::set_window(Games::Rezrov::ZConst::LOWER_WIN);
      my $message = "WARNING: this game is attempting to use multiple windows, which this interface can't handle. The game may be unplayable using this interface.  You should probably use the Tk, Curses, Termcap, or Win32 interfaces if you can; see the documentation.";
      # XXX ADK my replacement might not be 100% compatible to buffer_zchunk
#      $self->SUPER::buffer_zchunk(\$message);
      PlotzPerl::Output->write_to_screen(\$message);
      PlotzPerl::Output::flush();
      $self->newline();
      Language::Zcode::Runtime::IO::prompt_buffer($pb) if $pb;
      Language::Zcode::Runtime::IO::set_window($window);
    }
  }
}

sub erase_chars {
  my $count = shift;

  print pack 'c', 0x0d;		# carriage return
  print ' ' x $count;		# erase
  print pack 'c', 0x0d;		# carriage return
  # 2nd pass required in case of user input on same line as more prompt;
  # example: start "enchanter" in 80x36 terminal.
  # I'm not sure why just sending $count 0x08's (backspace) doesn't
  # work in this case, but it doesn't.
}

sub cleanup {
  if ($have_term_readkey) {
    ReadMode(0);
#    ReadLine(0);
  }
}


1;

################################################################################
#
#  Try as hard as we can to guess the number of rows and columns
#  in the display.
#
#  Use a "nice" approach if available, wallow if we must.
#  Michael Edmonson 10/1/98
#

package Games::Rezrov::GetSize;

use strict;
use Exporter;

@Games::Rezrov::GetSize::ISA = qw(Exporter);
@Games::Rezrov::GetSize::EXPORT = qw(get_size);

$Games::Rezrov::GetSize::DEBUG = 0;

eval 'use Term::ReadKey';
if (!$@) {
  #
  # use Term::ReadKey
  # 
  print STDERR "term::readkey\n" if $Games::Rezrov::GetSize::DEBUG;

  eval << 'DONE'
  sub get_size {
    my @terminal = GetTerminalSize();
    return @terminal ? ($terminal[0], $terminal[1]) : undef;
  }
DONE
} elsif ($ENV{"COLUMNS"} and $ENV{"ROWS"}) {
  #
  # use environment variables
  #
  print STDERR "environment vars\n" if $Games::Rezrov::GetSize::DEBUG;
  eval << 'DONE'
    sub get_size {
      return ($ENV{"COLUMNS"}, $ENV{"ROWS"});
    }
DONE
} else {
    foreach ("/bin/", "/usr/bin/") {
      my $fn = $_ . "/stty";
      $Games::Rezrov::GetSize::stty_prog = $fn, last if -x $fn;
    }
    if ($Games::Rezrov::GetSize::stty_prog) {
      #
      # use stty
      #
      print STDERR "stty\n" if $Games::Rezrov::GetSize::DEBUG;
      eval << 'DONE'
	sub get_size {
	  my ($columns, $rows);
	  my $data = `$Games::Rezrov::GetSize::stty_prog -a`;
	  foreach (["rows", \$rows],
		   ["columns", \$columns]) {
	    my ($what, $ref) = @{$_};
	    if ($data =~ /$what\s+=*\s*(\d+)/) {
	      $$ref = $1;
	    } elsif ($data =~ /(\d+)\s+$what/) {
	      $$ref = $1;
	    }
	  }
	  return ($columns, $rows);
	}
DONE
      } else {
      #
      # give up
      #
      print STDERR "giving up\n" if $Games::Rezrov::GetSize::DEBUG;
      eval << 'DONE'
	sub get_size {
	  return undef;
	}
DONE
      }
    }


1;

################################################################################

package Games::Rezrov::GetKey;
#  Try as hard as we can to read a single key from the keyboard.
#  Use a "nice" approach if available, wallow if we must.
#  Michael Edmonson 9/29/98
#
#  POSIX code taken from Tom Christiansen's "HotKey.pm", see
#  perlfaq8, or <6k403m$r1l$9@csnews.cs.colorado.edu>
#
#  TO DO: add DOS and other OS-specific code if Term::ReadKey not available

use strict;
use Exporter;

@Games::Rezrov::GetKey::ISA = qw(Exporter);
@Games::Rezrov::GetKey::EXPORT = qw(get_key);

use constant DEBUG => 0;

$Games::Rezrov::GetKey::STTY = "";

my $CAN_READ_SINGLE = 1;

sub can_read_single {
  return $CAN_READ_SINGLE;
}

eval 'use Term::ReadKey';
if (!$@) {
  #
  # use Term::ReadKey
  # 
  print STDERR "term::readkey\n" if DEBUG;
  eval << 'DONE'
  sub get_key {
    ReadMode(3);
    my $z;
    read(STDIN, $z, 1);
    ReadMode(0);
    return $z;
  }

  sub END {
    ReadMode(0);
  }
DONE

} else {
    my $posix_ok = 0;
   eval 'use POSIX qw(:termios_h)';
   if (!$@) { 
       eval 'my $term = POSIX::Termios->new();';
       if ($@) {
         # we have the POSIX module but Termios doesn't work!
#	 die "aha";
       } else {
         $posix_ok = 1;
       } 
   } 

   if ($posix_ok) {
    #
    # use POSIX termios
    # 
    print STDERR "posix\n" if DEBUG;

    eval << 'DONE'

    my $fd_stdin = fileno(STDIN);
    my $term = POSIX::Termios->new();
    $term->getattr($fd_stdin);
    my $oterm     = $term->getlflag();
    my $echo     = ECHO | ECHOK | ICANON;
    my $noecho   = $oterm & ~$echo;

    sub cbreak {
      $term->setlflag($noecho);
      $term->setcc(VTIME, 1);
      $term->setattr($fd_stdin, TCSANOW);
    }
    
    sub cooked {
      $term->setlflag($oterm);
      $term->setcc(VTIME, 0);
      $term->setattr($fd_stdin, TCSANOW);
    }

    sub get_key {
      my $key = '';
      cbreak();
      sysread(STDIN, $key, 1);
      cooked();
      return $key;
    }

    sub END {
      cooked();
    }
DONE
  } else {
    #
    #  Ugh, hopefully it won't come to this :)
    # 
      my $prog;
    foreach ("/bin/", "/usr/bin/") {
      my $fn = $_ . "stty";
      $Games::Rezrov::GetKey::STTY = $fn, last if -x $fn;
    }
    
    if ($Games::Rezrov::GetKey::STTY) {
      # use stty program
      print STDERR "stty\n" if DEBUG;
      
      eval << 'DONE'
	sub get_key {
	  my $z;
	  system "$Games::Rezrov::GetKey::STTY -icanon -echo";
	  read(STDIN, $z, 1);
	  system "$Games::Rezrov::GetKey::STTY icanon echo";
	  return $z;
	}
	
	sub END {
	  system "$Games::Rezrov::GetKey::STTY icanon echo";
	}
DONE
      } else {
	$CAN_READ_SINGLE = 0;
	print STDERR "giving up" if DEBUG;
	eval << 'DONE'
	  sub get_key {
	    my $z;
	    read(STDIN, $z, 1);
	    return $z;
	  }
DONE
	}
      }
  }

1;


################################################################################
package Games::Rezrov::ZIO_Tools;

use strict;
use Exporter;

@Games::Rezrov::ZIO_Tools::ISA = qw(Exporter);
@Games::Rezrov::ZIO_Tools::EXPORT = qw(set_xterm_title
			       find_module);

sub set_xterm_title {
  # if title is not defined, return whether or not the title *can* be
  # changed.
  my $title = shift;
  # see the comp.windows.x FAQ.
  if ($ENV{"DISPLAY"}) {
    # these are X-specific, so...
    my $term = $ENV{"TERM"};
    my $esc = pack 'c', 27;
    # escape

    if ($term =~ /xterm/i) {
      # XTerm
      if (defined $title) {
	printf "%s]2;%s%s", $esc, $title, pack('c', 7);  # bell
      } else {
	return 1;
      }
    } elsif ($term eq "vt300") {
      # DECTerm?
      if (defined $title) {
	printf '%s]21;%s%s\\', $esc, $title, $esc;
      } else {
	return 1;
      }
    }
  }

  return 0;
}

sub find_module {
  #
  #  Determine whether or not a given Perl module or library is installed
  #
  my $cmd = 'use ' . $_[0];
  eval $cmd;
  return $@ ? 0 : 1;
}

1;

################################################################################


package Games::Rezrov::ZIO_Color;
#
#  stuff for ZIOs that have color support
#

use strict;

my %Color;
sub cc {$Color{cc} = $_[1] if defined $_[1]; return $Color{cc}}
sub fg {$Color{fg} = $_[1] if defined $_[1]; return $Color{fg}}
sub bg {$Color{bg} = $_[1] if defined $_[1]; return $Color{bg}}
sub sfg {$Color{sfg} = $_[1] if defined $_[1]; return $Color{sfg}}
sub sbg {$Color{sbg} = $_[1] if defined $_[1]; return $Color{sbg}}
sub default_fg {$Color{default_fg} = $_[1] if defined $_[1]; return $Color{default_fg}}
sub default_bg {$Color{default_bg} = $_[1] if defined $_[1]; return $Color{default_bg}}

use constant DEFAULT_BACKGROUND_COLOR => 'blue';
use constant DEFAULT_FOREGROUND_COLOR => 'white';
use constant DEFAULT_CURSOR_COLOR => 'black';

sub parse_color_options {
  # - interpret standard command-line options for colors
  # - set up defaults
  my ($self, $options) = @_;
  my $fg = lc($options->{"fg"} || DEFAULT_FOREGROUND_COLOR);
  my $bg = lc($options->{"bg"} || DEFAULT_BACKGROUND_COLOR);
  my $sfg = lc($options->{"sfg"} || $bg);
  my $sbg = lc($options->{"sbg"} || $fg);
  # status line: default to inverse of foreground/background colors

  $self->fg($fg);
  $self->bg($bg);
  $self->default_fg($fg);
  $self->default_bg($bg);
  $self->sfg($sfg);
  $self->sbg($sbg);

  my $cc = lc($options->{"cc"} || DEFAULT_CURSOR_COLOR);
  $self->cc($cc eq $bg ? $fg : $cc);
  # if cursor color is the same as the background color,
  # change it to the foreground color
}

1;

################################################################################
# UNBELIEVABLY UGLY HACK TO ALLOW RUNNING ON NON-WIN32 OSes.
# TODO Move to LZ::Term::Win32 and require it only if we're on win32
# Note: can't split it now because Games::Rezrov::ZConst constants are
# needed in this package (and others). We need to separate out GR::ZConst
# and export all those constants or something, then use from here and other
# LZ::Term packages.
eval <<'ENDWIN32';
package Games::Rezrov::ZIO_Win32;
# z-machine i/o for perls with Win32::Console
# TO DO:
# - can we set hourglass when busy?

use strict;
use Win32::Console;

#use Games::Rezrov::ZIO_Generic;
#use Games::Rezrov::ZIO_Color;
#use Games::Rezrov::ZConst;


use constant WIN32_DEBUG => 0;

@Games::Rezrov::ZIO_Win32::ISA = qw(Games::Rezrov::ZIO_Generic
				    Games::Rezrov::ZIO_Color
				    );

my ($orig_columns, $orig_rows);
my ($s_upper_lines, $s_rows, $s_columns, $in_status);
# number of lines in upper window, geometry

my ($IN, $OUT);
# Win32::Console instances

if (WIN32_DEBUG) {
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
    my $self = new Games::Rezrov::ZIO_Generic();
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
    
    my @size = $OUT->Size();
    $s_columns = $options{"-columns"} || $size[0] || die "need columns!";
    $s_rows = $options{"-rows"} || $size[1] || die "need rows!";
    ($orig_columns, $orig_rows) = @size;

###########
    # ADK XXX I have no idea if this is right, but it shrinks the Windows
    # buffer to be the same size as the screen, so that the status line
    # on row zero is visible without scrolling upward!
    # Seems like there should be a way to keep the scrollbar and to
    # allow the lower window to scroll up, always rewriting the upper
    # window. But maybe Win32::Console doesn't play nice with that.
    my @w = $OUT->Window();
    my ($c, $r) = ($w[2]-$w[0]+1, $w[3]-$w[1]+1);
#    $OUT->Write($size[0]." "); $OUT->Write($size[1]." "); $OUT->Write("$r $c");
    $OUT->Size($c, $r);
    $s_columns = $options{"-columns"} || $c || die "need columns!";
    $s_rows = $options{"-rows"} || $r || die "need rows!";
###########

    Language::Zcode::Runtime::IO::rows($s_rows);
    Language::Zcode::Runtime::IO::columns($s_columns);
    $s_upper_lines = 0;
    return $self;
}

sub update {
  $OUT->Flush();
}

sub set_version {
  # called by the game
  my ($self, $status_needed, $callback) = @_;
  Games::Rezrov::StoryFile::rows($s_rows);
  Games::Rezrov::StoryFile::columns($s_columns);
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
  if (++$y >= $s_rows) {
      # scroll needed
      my $last_line = $s_rows - 1;
      $y = $last_line;
      my $top = $s_upper_lines;
    #	$OUT->Write(sprintf "before: at %d,%d, top=%d last=%d\n", $x, $y, $top, $last_line);
#    log_it(sprintf "before: at %d,%d, top=%d last=%d\n", $x, $y, $top, $last_line);
    #	sleep(1);
      $OUT->Scroll(0, $top + 1, $s_columns - 1, $last_line,
		   0, $top, Games::Rezrov::ZConst::ASCII_SPACE, $_[0]->get_attr(0),
		   0, $top, $s_columns - 1, $last_line);
      # ugh: we have to specify the clipping region, or else
      # Win32::Console barfs about uninitialized variables (with -w)
  }
  PlotzPerl::Output::register_newline();
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
    $OUT->FillAttr($self->get_attr(), $s_columns, 0, 0);
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
    # TODO More keys F1, num lock, etc.- see NOTES.txt
    # Event type (1 keyboard, 2 mouse), key down or up (1,0)
    # repeat count, virtual keycode, virtual scan code (?)
    # char (if ASCII, otherwise 0), control key state
    while (1) {
	@event = $IN->Input() or next; # ignore changing window focus
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
    $self->newline();
    return $buf;
}

sub clear_screen {
    $OUT->Cls($_[0]->get_attr(0));
#    log_it("cls");
}

sub clear_to_eol {
    $OUT->Attr($_[0]->get_attr(0));
    $OUT->Write(" " x ($s_columns - ($OUT->Cursor())[1]));
}

sub split_window {
  # split upper window to specified number of lines
  my ($self, $lines) = @_;
  #  $w_main->setscrreg($lines, $s_rows - 1);
  $s_upper_lines = $lines;
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
  if (WIN32_DEBUG) {
    print LOG $_[0] . "\n";
  }
}

sub get_attr {
    # return attribute code for color/style currently in effect.
    my ($self, $mask) = @_;
    
    $mask = Language::Zcode::Runtime::IO::font_mask() unless defined($mask);
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

    # ADK What's main::FOREGROUND_INTENSITY? Couldn't find it in
    # any Games::Rezrov file!
=pod
    $code |= main::FOREGROUND_INTENSITY if 
	($mask & (Games::Rezrov::ZConst::STYLE_BOLD|Games::Rezrov::ZConst::STYLE_ITALIC));
=cut

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

my $is_clean = "";
sub cleanup {
    my $self = shift;
    return if $is_clean++; # only clean once!
    if (defined $OUT) {
	$self->write_string("[Hit any key to exit]");
	$self->get_input(1,1);
	# TODO save Attr so user gets back exactly the window they started with
	$OUT->Attr($main::ATTR_NORMAL);
	#print "rows is $orig_rows\n";
	$OUT->Size($orig_columns, $orig_rows);
    } else {warn "cleanup called with undefined zio\n"}
    print "Cleaned IO\n";
}
ENDWIN32

1;
