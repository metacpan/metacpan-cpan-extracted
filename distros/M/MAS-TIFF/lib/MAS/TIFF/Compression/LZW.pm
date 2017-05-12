use strict;
use warnings;

package MAS::TIFF::Compression::LZW::State;

use strict;
use warnings;

use Carp qw(confess);

sub new {
  my $class = shift;
  my $bytes = shift;
  
  return bless {
    BYTES => $bytes // '',
    BYTE_INDEX => 0,
    BIT_INDEX => 0,
    BYTE => undef,
    DICT => { },
    CODES => [ ],
  }, $class;
}

sub bytes { return shift->{BYTES} }

sub initialize_table {
  my $self = shift;
  
#  print "  Initializing table...\n";
  
  $self->{DICT} = { };
  $self->{CODES} = [ ];
}

sub string_from_code {
  my $self = shift;
  my $code = shift;
  
  return chr($code) if ($code < 256);
  
  confess "Attempt to get string for CLEAR code (256)!" if $code == 256;
  confess "Attempt to get string for EOI code (257)!" if $code == 257;
  
  my $string = $self->{CODES}[$code - 258];
  
  confess "Attempt to get string for undefined code $code!" unless defined $string;
  
#  printf "  => %s\n", $code, unpack('H*', $string);
  
  return $string;
}

sub code_from_string {
  my $self = shift;
  my $string = shift;
  
  confess "Attempt to get code for undefined string!" unless defined $string;
  confess "Attempt to get code for empty string!" if $string eq '';

  return ord($string) if length($string) == 1;
  
  my $code = $self->{DICT}{$string};
  
  confess "Attempt to get code for string '" . unpack('H*', $string) . "' failed!" unless defined $code;
  
  return $code;
}

sub is_code_in_table {
  my $self = shift;
  my $code = shift;
  
  return (scalar(@{$self->{CODES}}) + 258) > $code;
}

sub is_string_in_table {
  my $self = shift;
  my $value = shift;
  
  return 1 if length($value) == 1;
    
  return exists $self->{DICT}{$value};
}

sub add_string_to_table {
  my $self = shift;
  my $string = shift;

  if (length($string) == 1) {
    # Why bother adding length-one strings to the table beyond entries 0..255?
    # return
  }
  else {
    confess "Attempt to add '" . unpack('H*', $string) . "' to table, but it is already there!" if $self->is_string_in_table($string);
  }
  
  my $code = scalar(@{$self->{CODES}}) + 258;
  
#  printf "  Code %d => %s\n", $code, unpack('H*', $string);
  
  $self->{CODES}[$code - 258] = $string;
  $self->{DICT}{$string} = $code;
}

my @write_masks = (0x00, 0x01, 0x03, 0x07, 0x0f, 0x1f, 0x3f, 0x7f, 0xff);

sub write_code {
  my $self = shift;
  my $code = (shift) + 0;
  
  my $code_count = 258 + scalar(@{$self->{CODES}});
  
  my $size;
  
  if ($code_count >= 2048) {
    $size = 12;
  }
  elsif ($code_count >= 1024) {
    $size = 11;
  }
  elsif ($code_count >= 512) {
    $size = 10;
  }
  else {
    $size = 9;
  }
  
#  printf "Writing %d bit code %s\n", $size, $code;

  my $byte = $self->{BYTE} // 0;
  my $bit_index = $self->{BIT_INDEX};

  my $remaining = $size;
  
  while ($remaining > 0) {
    my $available = 8 - $bit_index;
    
    my $writing;
    my $extra;
    if ($remaining <= $available) {
      $writing = $remaining;
      $extra = $available - $writing;
    }
    else {
      $writing = $available;
      $extra = 0;
    }
        
    my $bits = ($write_masks[$writing] & ($code >> ($remaining - $writing))) << $extra;
        
    $byte |= $bits;
    $bit_index += $writing;
    
    if ($bit_index == 8) {
      $self->{BYTES} .= chr($byte);
      $self->{BYTE} = undef;
      $self->{BIT_INDEX} = 0;
      $byte = 0;
      $bit_index = 0;
    }
    else {
      $self->{BYTE} = $byte;
      $self->{BIT_INDEX} = $bit_index;
    }
    
    $remaining -= $writing;
  }
}

sub finish_write {
  my $self = shift;
  
  if (defined $self->{BYTE}) {
    $self->{BYTES} .= chr($self->{BYTE});
    $self->{BIT_INDEX} = 0;
    $self->{BYTE} = undef;
  }
}

my @read_masks = (0xff, 0x7f, 0x3f, 0x1f, 0x0f, 0x07, 0x03, 0x01);

sub get_next_code {
  my $self = shift;
  
  my $code_count = 258 + scalar(@{$self->{CODES}});
  
  my $size;
  
  if ($code_count >= 2047) { # Really? Not 2048?
    $size = 12;
  }
  elsif ($code_count >= 1023) { # Really? Not 1024?
    $size = 11;
  }
  elsif ($code_count >= 511) { # Really? Not 512?
    $size = 10;
  }
  else {
    $size = 9;
  }
  
  my $bytes = $self->{BYTES};
  my $bit_index = $self->{BIT_INDEX};
  my $byte_index = $self->{BYTE_INDEX};

  my $input_length = length($bytes);
  my $bytes_remaining = $input_length - $byte_index - 1;
  my $bits_remaining = (8 - $bit_index) + (8 * $bytes_remaining);
  
  return undef if ($size > $bits_remaining);
  
  my $result = 0;
  my $remaining = $size;
  
  while ($remaining > 0) {
    my $available = 8 - $bit_index;
    
    my $reading;
    my $extra;
    if ($remaining <= $available) {
      $reading = $remaining;
      $extra = $available - $remaining;
    }
    else {
      $reading = $available;
      $extra = 0;
    }
    
#    my $byte = unpack('C', substr($bytes, $byte_index, 1));
    my $byte = ord(substr($bytes, $byte_index, 1));
    my $mask = $read_masks[$bit_index];
    
    my $new_bits = ($mask & $byte) >> $extra;
    $result = ($result << $reading) | $new_bits;
    $remaining -= $reading;
    $bit_index += $reading;
    if ($bit_index == 8) {
      $bit_index = 0;
      $byte_index++;
      if (($byte_index == $input_length) && ($remaining > 0)) {
        die "Input of $input_length bytes exhausted before finished reading $size bits. There are $remaining left to read!";
      }
    }
  }
  
  $self->{BIT_INDEX} = $bit_index;
  $self->{BYTE_INDEX} = $byte_index;

#  if ($result == 256) {
#    printf "There are %d codes. Read a %d bit code: CLEAR (256)\n", $code_count, $size;
#  }
#  elsif ($result == 257) {
#    printf "There are %d codes. Read a %d bit code: EOI (257)\n", $code_count, $size;
#  }
#  elsif ($result < 256) {
#    printf "There are %d codes. Read a %d bit code: 0x%02x\n", $code_count, $size, $result;
#  }
#  else {
#    printf "There are %d codes. Read a %d bit code: %d\n", $code_count, $size, $result;
#  }
  
  return $result;
}

package MAS::TIFF::Compression::LZW;

use constant {
  CLEAR => 256,
  EOI => 257,
};

sub encode {
  my $bytes = shift;
  my $output = '';
  
  my $state = MAS::TIFF::Compression::LZW::State->new();

  $state->write_code(CLEAR);
  my $omega = '';
  my $l = length($bytes);
  for (my $i = 0; $i < $l; ++$i) {
    my $k = substr($bytes, $i, 1);
    my $key = $omega . $k;
    if ($state->is_string_in_table($key)) {
      $omega = $key;
    }
    else {
      my $code = $state->code_from_string($omega);
      $state->write_code($code);
      my $new_code = $state->add_string_to_table($key);
      $omega = $k;
      
      if ($new_code == 4096) {
        $state->write_code(CLEAR);
        $state->initialize_table;
      }
    }
  }
  my $code = $state->code_from_string($omega);
  $state->write_code($code);
  $state->write_code(EOI);
  
  $state->finish_write;
  
  return $state->bytes;
}

sub decode {
  my $bytes = shift;
  my $output = '';
  
  my $state = MAS::TIFF::Compression::LZW::State->new($bytes);

  my $code;  
  my $old_code;
  
  while (1) {
    $code = $state->get_next_code;
    die "Unexpected end of input while reading!" unless defined $code;
    last if $code == EOI;
    
    if ($code == CLEAR) {
      $state->initialize_table;
      $code = $state->get_next_code;
      last if ($code == EOI);
      $output .= $state->string_from_code($code);
      $old_code = $code;
    }
    else {
      if ($state->is_code_in_table($code)) {
        my $string = $state->string_from_code($code);
        $output .= $string;
        my $new_string = $state->string_from_code($old_code) . substr($string, 0, 1);
        $state->add_string_to_table($new_string);
        $old_code = $code;
      }
      else {
        my $old_string = $state->string_from_code($old_code);
        my $out_string = $old_string . substr($old_string, 0, 1); # Why append first char of string from old_code?
        $output .= $out_string;
        $state->add_string_to_table($out_string);
        $old_code = $code;
      }
    }
  }
  
#  print "Got EOI.\n";
  
  return $output;
}


1;
