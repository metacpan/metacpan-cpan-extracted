package Games::Rezrov::ZIO_test;
# z-machine i/o for test model - meant for capturing output as part of a test
# - contributed by Neil Bowers, Aug 2004
# - modified by Michael Edmonson:
#    - stripped down even further.
#    - avoid using ANY local system calls or external modules (GetKey/GetSize).
#      This means single-key input will not work, but also "make test"
#      might stop crashing in unusual configurations!  :P

use strict;

use Games::Rezrov::ZIO_Generic;
@Games::Rezrov::ZIO_test::ISA = qw(Games::Rezrov::ZIO_Generic);

my $rows = 25;
my $columns = 80;
my $abs_x = 0;
my $abs_y = 0;

$|=1;

sub new {
  my ($type, %options) = @_;
  my $self = new Games::Rezrov::ZIO_Generic(%options);
  bless $self, $type;

  $columns = $options{columns} if $options{columns};
  $self->zio_options(\%options);
  ($columns, $rows) = get_size();

  return $self;
}

sub get_size {
    return ($columns, $rows);
}

sub get_key {
    # single-key input disabled!
    return "";
}

sub write_string {
  my ($self, $string, $x, $y) = @_;
  # $self->absolute_move($x, $y) if defined($x) and defined($y);
  print $string;
  $abs_x += length($string);
}

sub clear_to_eol {
    # do nothing
}

sub update {
}

sub can_split {
  # true or false: can this zio split the screen?
  return 0;
}

sub set_version {
  my ($self, $status_needed, $callback) = @_;
  Games::Rezrov::StoryFile::rows($rows);
  Games::Rezrov::StoryFile::columns($columns);
  return 0;
}

sub absolute_move {
  ($abs_x, $abs_y) = @_[1,2];
}

sub newline {
  print "\n";
  $abs_x = 0;
#  Games::Rezrov::StoryFile::register_newline();
  # never register newlines to the interpreter, 
  # so [MORE] prompt will never appear.
}

sub write_zchar {
  if ($_[0]->current_window() == Games::Rezrov::ZConst::LOWER_WIN) {
    print chr($_[1]);
    $abs_x++;
  } else {
     # upper window character, ignore
#    printf STDERR "ignoring char: %s\n", chr($_[1]);
  }
}

sub get_input {
  my ($self, $max, $single_char, %options) = @_;
  if ($single_char) {
    return get_key();
  } else {
    my $line;
    if ($self->listening) {
      # speech recognition; disable for this interface?
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
    # do nothing
}

sub set_window {
  my ($self, $window) = @_;
  $self->SUPER::set_window($window);
}

sub erase_chars {
    # do nothing
}

1;
