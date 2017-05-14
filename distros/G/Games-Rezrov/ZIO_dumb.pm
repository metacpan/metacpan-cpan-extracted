package Games::Rezrov::ZIO_dumb;
# z-machine i/o for dumb/semi-dumb terminals.

# to do: get rid of absolute Y (untrackable)

use strict;
use Carp qw(cluck);

use Games::Rezrov::GetKey;
use Games::Rezrov::GetSize;
use Games::Rezrov::ZIO_Tools;
use Games::Rezrov::ZIO_Generic;

@Games::Rezrov::ZIO_dumb::ISA = qw(Games::Rezrov::ZIO_Generic);

my $have_term_readkey;
my ($rows, $columns);
my ($clear_prog);

my $abs_x = 0;
my $abs_y = 0;

$|=1;

sub new {
  my ($type, %options) = @_;
  my $self = new Games::Rezrov::ZIO_Generic(%options);
  bless $self, $type;

  $self->zio_options(\%options);
  $self->readline_init();

  $self->io_setup();
  
  $columns = $options{columns} if $options{columns};
  $rows = $options{rows} if $options{rows};
  ($columns, $rows) = get_size() unless $columns and $rows;
  # don't attempt to detect terminal size if manually set;
  # ("make test" crashes in Term::ReadKey if not run on a tty!)
  
  unless ($columns and $rows) {
    print "I couldn't guess the number of rows and columns in your display,\n";
    print "so you must use -rows and -columns to specify them manually.\n";
    exit;
  }
  return $self;
}

sub io_setup {
  my ($self) = @_;

  if (find_module('Term::ReadKey')) {
    require Term::ReadKey;
    import Term::ReadKey;
    $have_term_readkey = 1;
#    ReadMode(3);
    # disable echoing
#    ReadLine(-1);
    # make sure we don't buffer any (invisible) characters
  }

  $clear_prog = find_prog("clear");
}

sub write_string {
  my ($self, $string, $x, $y) = @_;
  $self->absolute_move($x, $y) if defined($x) and defined($y);
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

sub find_prog {
  # don't look
  foreach ("/bin/", "/usr/bin/") {
    my $fn = $_ . $_[0];
    return $fn if -x $fn;
  }
  return undef;
}

sub can_split {
  # true or false: can this zio split the screen?
  return 0;
}

sub set_version {
  my ($self, $status_needed, $callback) = @_;
  Games::Rezrov::StoryFile::rows($rows);
  Games::Rezrov::StoryFile::columns($columns);
#  print STDERR "$columns\n";
  $self->clear_screen();
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
#  cluck "nl\n";
  $abs_x = 0;
  Games::Rezrov::StoryFile::register_newline();
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
    return get_key();
  } else {
    if ($have_term_readkey) {
      # re-enable terminal before prompt
      ReadMode(0);
#      ReadLine(0);
    }
    my $line;
    if ($self->listening) {
      # speech recognition
      $line = $self->recognize_line();
      print "$line\n";
    } elsif ($self->using_term_readline()) {
      # Term::ReadLine enabled
      $line = $self->readline($options{"-preloaded"});
    } else {
      $line = <STDIN>;
      # also doesn't work with v5+ preloaded input
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
#  cluck "clear: $rows";
  for (my $i=0; $i < $rows; $i++) {
    # move cursor to lower left
    print "\n";
  }
}

sub set_window {
  my ($self, $window) = @_;
  $self->SUPER::set_window($window);
  if ($window != Games::Rezrov::ZConst::LOWER_WIN) {
    # ignore output except on lower window
    unless ($self->warned()) {
      $self->warned(1);
      my $pb = Games::Rezrov::StoryFile::prompt_buffer();
      $self->newline();
      Games::Rezrov::StoryFile::set_window(Games::Rezrov::ZConst::LOWER_WIN);
      my $message = "WARNING: this game is attempting to use multiple windows, which this interface can't handle. The game may be unplayable using this interface.  You should probably use the Tk, Curses, Termcap, or Win32 interfaces if you can; see the documentation.";
      $self->SUPER::buffer_zchunk(\$message);
      Games::Rezrov::StoryFile::flush();
      $self->newline();
      Games::Rezrov::StoryFile::prompt_buffer($pb) if $pb;
      Games::Rezrov::StoryFile::set_window($window);
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

sub warned {
  return (defined $_[1] ? $_[0]->{"warned"} = $_[1] : $_[0]->{"warned"});
}


1;
