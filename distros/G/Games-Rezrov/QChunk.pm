package Games::Rezrov::QChunk;

use strict;

#use SelfLoader;
#use Carp qw(confess);
1;

#__DATA__

sub new {
  my ($type, $chunk_type) = @_;
  my $self = {};
  bless $self, $type;
  $self->id($chunk_type) if $chunk_type;
  my $buf = "";
  $self->buffer(\$buf);
  return $self;
}

sub pointer {
  # return the current pointer position.
  # with argument, increments the pointer that number of bytes
  # (does NOT affect return value).
  if (defined $_[1]) {
    my $value = $_[0]->{"pointer"};
    $_[0]->{"pointer"} = $value + $_[1];
    return $value;
  } else {
    return $_[0]->{"pointer"};
  }
}

sub load {
  # load a chunk from file.
  my ($self, $fh) = @_;
  $self->id(read_chunk_id($fh));
  my $len = read_int_4($fh);
  $self->reset_read_pointer();
  my $buf;
  my $read = read($fh, $buf, $len);
  if ($read != $len) {
    # error
    print STDERR "Read $read, expected $len\n";
    return -1;
  } else {
    $self->buffer(\$buf);
  }
  return $len;
}

sub read_chunk_id {
  my ($fh) = @_;
  my $buf;
  read($fh, $buf, 4);
  return $buf;
}

sub read_int_4 {
  # read a signed 4-byte int
  my ($fh) = @_;
  my $buf;
  read($fh, $buf, 4);
  return unpack 'N', $buf;
}

sub get_word {
  # 1.2: 16-bit unsigned
  my ($self) = @_;
  my $buffer = $self->buffer();
  my $pointer = $self->pointer(2);
  my $result = unpack "x${pointer}n", $$buffer;
#  $self->pointer($pointer + 2);
  return $result;
}

sub get_byte {
  # get a single byte, incrementing pointer
  return unpack "x" . $_[0]->pointer(1) . "C", ${$_[0]->buffer()};
}

sub get_word_3 {
  my ($self) = @_;
  return ($self->get_byte() << 16 | $self->get_byte() << 8 | $self->get_byte());
}

sub get_string {
  my ($self, $length) = @_;
  my $buffer = $self->buffer();
  my $pointer = $self->pointer();
  my $result = unpack "x${pointer}a$length", $$buffer;
#  $self->pointer($pointer + $length);
  $self->pointer($length);
  return $result;
}

sub reset_read_pointer {
  $_[0]->{"pointer"} = 0;
}

sub eof {
  # return true if pointer at end of data
  return ($_[0]->pointer() >= length(${$_[0]->buffer()}) ? 1 : 0);
}

sub id {
  return (defined $_[1] ? $_[0]->{"id"} = $_[1] : $_[0]->{"id"});
}

sub buffer {
  return (defined $_[1] ? $_[0]->{"buffer"} = $_[1] : $_[0]->{"buffer"});
}

sub add_byte {
  my $buf = $_[0]->{"buffer"};
  $$buf .= pack 'C', $_[1];
}

sub add_word {
  my ($self, $value) = @_;
  my $buf = $_[0]->{"buffer"};
#  confess unless defined $value;
  $$buf .= pack 'n', $value;
}

sub add_string {
  my ($self, $value, $length) = @_;
  my $buf = $_[0]->{"buffer"};
  die if length($value) > $length;
  $$buf .= sprintf "%${length}s", $value;
}

sub add_word_3 {
  # add a 3-byte unsigned word
  my ($self, $value) = @_;
  $self->add_byte($value >> 16 & 0xff);
  $self->add_byte($value >> 8 & 0xff);
  $self->add_byte($value & 0xff);
}

sub add_data {
  # add an arbitrary chunk
  my ($self, $value) = @_;
  my $buf = $_[0]->{"buffer"};
  $$buf .= $value;
}

sub get_chunk_length {
  # return length of chunk, including id, byte count, and any required pad
  my ($self) = @_;
  my $buf = $self->buffer();
  my $size = length $$buf;
  return $size + 4 + 4 + ($size % 2);
  # 4 for byte count, 4 for ID, plus optional pad byte
}

sub get_data_length {
  # return length of just the data
  return length(${$_[0]->buffer()});
}

sub get_data {
  # return all data
  return $_[0]->buffer();
}

sub write {
  # write this chunk to stream
  my ($self, $fh) = @_;
  
  my ($i, $len, $data_len);
  
  my $buf = $self->buffer();
  $data_len = length $$buf;
  
  # write chunk id:
  my $id = $self->id();
  die if length($id) != 4;
  print $fh $id;
  
  # write data size (any pad is not included in length)
  print $fh pack('N', $data_len);
  
  print $fh $$buf;
  
  if ($data_len % 2) {
    # pad byte required; spec 8.4.1
    print $fh pack('C', 0);
  }
}

1;
