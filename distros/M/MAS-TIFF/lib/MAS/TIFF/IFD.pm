use strict;
use warnings;

package MAS::TIFF::IFD;

use MAS::TIFF::Field;
use MAS::TIFF::Compression::LZW;

use constant {
  TAG_NEW_SUBFILE_TYPE => 254,
  TAG_SUBFILE_TYPE     => 255,
  TAG_IMAGE_WIDTH      => 256,
  TAG_IMAGE_LENGTH     => 257,
  
  TAG_BITS_PER_SAMPLE   => 258,
  TAG_COMPRESSION       => 259,
  TAG_PHOTOMETRIC_INTERPRETATION => 262,
  TAG_STRIP_OFFSETS     => 273,
  TAG_SAMPLES_PER_PIXEL => 277,
  TAG_ROWS_PER_STRIP    => 278,
  TAG_STRIP_BYTE_COUNTS => 279,
  
  TAG_X_RESOLUTION     => 282,
  TAG_Y_RESOLUTION     => 283,
  TAG_RESOLUTION_UNIT  => 296,

  TAG_SOFTWARE         => 305,
  TAG_DATETIME         => 306,
};

use constant {
  FILE_TYPE_REDUCED_IMAGE => 1,
  FILE_TYPE_PAGE          => 2,
  FILE_TYPE_MASK          => 4,
};

use constant {
  OLD_FILE_TYPE_IMAGE         => 1,
  OLD_FILE_TYPE_REDUCED_IMAGE => 2,
  OLD_FILE_TYPE_PAGE          => 3,
};

sub new {
  my $class = shift;
  my ($io, $offset) = @_;
  
  my $num_dir_entries = $io->read_word($offset);

  my @field_ids = ( );
  my %fields = ( );

  for (my $i = 0; $i < $num_dir_entries; ++$i) {
    my $field = MAS::TIFF::Field->read_from_io($io);
    push @field_ids, $field->id;
    $fields{$field->id} = $field;
  }

  my $next_offset = $io->read_dword;

  my $self = bless {
    IO => $io,
    OFFSET => $offset,
    FIELD_IDS => [ @field_ids ],
    FIELDS => { %fields },
    NEXT_IFD_OFFSET => $next_offset,
  }, $class;
  
  return $self;
}

sub io { return shift->{IO} }
sub offset { return shift->{OFFSET} }

sub fields {
  my $self = shift;
  
  return map { $self->{FIELDS}{$_} } @{$self->{FIELD_IDS}};
}

sub next_ifd_offset { return shift->{NEXT_IFD_OFFSET} }

sub field {
  my $self = shift;
  my $tag_id = shift;

  return $self->{FIELDS}{$tag_id};
}

sub image_width {
  my $self = shift;
  
  if (exists $self->{IMAGE_WIDTH}) {
    return $self->{IMAGE_WIDTH};
  }
  
  my $value = $self->field(TAG_IMAGE_WIDTH)->value_at(0);
  
  $self->{IMAGE_WIDTH} = $value;
  
  return $value;
}

sub image_length {
  my $self = shift;
  
  if (exists $self->{IMAGE_LENGTH}) {
    return $self->{IMAGE_LENGTH};
  }
  
  my $value = $self->field(TAG_IMAGE_LENGTH)->value_at(0);
  
  $self->{IMAGE_LENGTH} = $value;
  
  return $value;
}

sub bits_per_sample {
  my $self = shift;
    
  if (exists $self->{BITS_PER_SAMPLE}) {
    return $self->{BITS_PER_SAMPLE};
  }

  my $spp = $self->samples_per_pixel;
  
  my $field = $self->field(TAG_BITS_PER_SAMPLE);
  
  my $value;
  
  if (not defined $field) {
    if ($spp == 1) {
      $value = 1; # OK to default to 1 if only expecting a single value
    }
    else {
      die "Cannot omit bits_per_sample tag when samples_per_pixel > 1!";
    }
  }
  else {
    if ($spp == 1) {
      $value = $field->value_at(0);
    }
    else {
      die "Not supported yet -- Need better tag reading code";
    }
  }
  
  $self->{BITS_PER_SAMPLE} = $value;

  return $value;
}

sub samples_per_pixel {
  my $self = shift;
  
  if (exists $self->{SAMPLES_PER_PIXEL}) {
    return $self->{SAMPLES_PER_PIXEL};
  }
  
  my $field = $self->field(TAG_SAMPLES_PER_PIXEL);
  
  my $value;
  
  if (defined $field) {
    $value = $field->value_at(0);
  }
  else {
    $value = 1;
  }
  
  $self->{SAMPLES_PER_PIXEL} = $value;

  return $value;
}

sub rows_per_strip {
  my $self = shift;
  
  if (exists $self->{ROWS_PER_STRIP}) {
    return $self->{ROWS_PER_STRIP};
  }
  
  my $field = $self->field(TAG_ROWS_PER_STRIP);
  
  my $value;
  
  if (defined $field) {
    $value = $field->value_at(0);
  }
  else {
    $value = 1;
  }
  
  $self->{ROWS_PER_STRIP} = $value;

  return $value;
}

sub strip_offsets {
  my $self = shift;
    
  if (exists $self->{STRIP_OFFSETS}) {
    return @{$self->{STRIP_OFFSETS}};
  }

  my $field = $self->field(TAG_STRIP_OFFSETS);
  
  my $values;
  
  if (defined $field) {
    $values = $field->all_values
  }
  else {
    $values = [ ];
  }

  $self->{STRIP_OFFSETS} = $values; 
  
  return @{$values};
}

sub strip_byte_counts {
  my $self = shift;
  
  if (exists $self->{STRIP_BYTE_COUNTS}) {
    return @{$self->{STRIP_BYTE_COUNTS}};
  }
   
  my $field = $self->field(TAG_STRIP_BYTE_COUNTS);
  
  my $values;
  
  if (defined $field) {
    $values = $field->all_values
  }
  else {
    $values = [ ];
  }

  $self->{STRIP_BYTE_COUNTS} = $values; 
  
  return @{$values};
}

sub strip_count {
  my $self = shift;
  
  if (exists $self->{STRIP_COUNT}) {
    return $self->{STRIP_COUNT};
  }
  
  my $field = $self->field(TAG_STRIP_OFFSETS);

  
  my $value;
  
  if (defined $field) {
    $value = $field->count;
  }
  else {
    $value = 1;
  }
  
  $self->{STRIP_COUNT} = $value;

  return $value;
}

sub strip_reader {
  my $self = shift;
  
  if (exists $self->{STRIP_READER}) {
    return $self->{STRIP_READER};
  }
  
  if ($self->compression ne 'LZW') {
    die "Only LZW compression is supported";
  }
  
  my @sizes = $self->strip_byte_counts;
  my @offsets = $self->strip_offsets;
  
  my @cache = ( );
  
  my $reader = sub {
    my $index = shift;
    
    return $cache[$index] if exists $cache[$index];
    
    my $size = $sizes[$index];
    my $offset = $offsets[$index];
    
    my $bytes = $self->io->read($size, $offset);
    $bytes = MAS::TIFF::Compression::LZW::decode($bytes);
    
    $cache[$index] = $bytes;
    
    return $bytes;
  };
  
  $self->{STRIP_READER} = $reader;
  
  return $reader;
}

sub scan_line_reader {
  my $self = shift;
  
  if (exists $self->{SCAN_LINE_READER}) {
    return $self->{SCAN_LINE_READER};
  }
  
  if ($self->samples_per_pixel != 1) {
    die "Sorry, only images with one sample per pixel are supported!";
  }
  
  if ($self->bits_per_sample != 1) {
    die "Sorry, only images with one bit per sample are supported!";
  }
  
  my $image_width = $self->image_width;
  my $image_length = $self->image_length;
  
  my $bytes_per_row = $image_width / 8 + (($image_width % 8) != 0 ? 1 : 0);
    
  my $rows_per_strip = $self->rows_per_strip;
  my $pi = $self->photometric_interpretation;

  my $invert;
  
  if ($pi eq 'MinIsWhite') {
    $invert = 1;
  }
  elsif ($pi eq 'MinIsBlack') {
    $invert = 0;
  }
  else {
    die "Sorry, only MinIsWhite and MinIsBlack are supported photometric interpretations!";
  }
  
  my $strip_reader = $self->strip_reader;
  
  my $last_strip_index = undef;
  my $last_strip = undef;

  my $reader = sub {
    use integer;
    
    my $y = shift;
  
    if (($y < 0) || ($y >= $image_length)) {
      die "y must be in range 0.." . ($image_length - 1) . ", but was $y!";
    }
    
    my $index = $y / $rows_per_strip;
    my $strip;
    
    if (defined($last_strip_index) && ($last_strip_index == $index)) {
      $strip = $last_strip;
    }
    else {
      $strip = &$strip_reader($index);
      
      $last_strip_index = $index;
      $last_strip = $strip;
    }

    my $row_index = $y % $rows_per_strip;

    my $row = substr($strip, $row_index * $bytes_per_row, $bytes_per_row);

    if ($invert) {
      $row = ~$row;
    }

    return $row;
  };
  
  $self->{SCAN_LINE_READER} = $reader;
  
  return $reader;  
  
  
}

#
# With the strip, each row is stored in a contiguous byte sequence, with possibly some
# unused bits at the end.
#
# Returns zero for black, one for white.
#

sub pixel_reader {
  my $self = shift;
  
  if (exists $self->{PIXEL_READER}) {
    return $self->{PIXEL_READER};
  }
  
  if ($self->samples_per_pixel != 1) {
    die "Sorry, only images with one sample per pixel are supported!";
  }
  
  if ($self->bits_per_sample != 1) {
    die "Sorry, only images with one bit per sample are supported!";
  }
  
  my $image_width = $self->image_width;
  my $image_length = $self->image_length;
  my $rows_per_strip = $self->rows_per_strip;
  my $pi = $self->photometric_interpretation;
  
  my $scan_line_reader = $self->scan_line_reader;
  
  my $last_y = undef;
  my $last_scan_line = undef;

  my $reader = sub {
    use integer;
    
    my $x = shift;
    my $y = shift;

    if (($x < 0) || ($x >= $image_width)) {
      die "x must be in range 0.." . ($image_width - 1) . ", but was $x.!";
    }
  
    if (($y < 0) || ($y >= $image_length)) {
      die "y must be in range 0.." . ($image_length - 1) . ", but was $y!";
    }
    
    my $scan_line;
    
    if (defined($last_y) && ($last_y == $y)) {
      $scan_line = $last_scan_line;
    }
    else {
      $scan_line = &$scan_line_reader($y);
      
      $last_y = $y;
      $last_scan_line = $scan_line;
    }

    my $byte_index = $x / 8;
    
    my $byte = vec($scan_line, $byte_index, 8);
    my $bit_index = 7 - ($x % 8);
    my $bit = ($byte >> $bit_index) & 0x01;

    return $bit;
  };
  
  $self->{PIXEL_READER} = $reader;
  
  return $reader;
}

sub is_image {
  my $self = shift;

  my $field = $self->field(TAG_NEW_SUBFILE_TYPE);

  # First try TAG_NEW_SUBFILE_TYPE, else TAG_SUBFILE_TYPE
  if (defined $field) {
    # If none of bits 0, 1 or 2 is set, this is a regular image
    return ($field->value_at(0) & (FILE_TYPE_REDUCED_IMAGE | FILE_TYPE_PAGE | FILE_TYPE_MASK)) == 0;
  }
  else {
    $field = $self->field(TAG_SUBFILE_TYPE);

    if (defined $field) {
      return $field->value_at(0) == OLD_FILE_TYPE_IMAGE;
    }
    else {
      return 1;
    }
  }
}

sub is_reduced_image {
  my $self = shift;

  my $field = $self->field(TAG_NEW_SUBFILE_TYPE);

  # First try TAG_NEW_SUBFILE_TYPE, else TAG_SUBFILE_TYPE
  if (defined $field) {
    # If none of bits 0, 1 or 2 is set, this is a regular image
    return ($field->value_at(0) & FILE_TYPE_REDUCED_IMAGE) != 0;
  }
  else {
    $field = $self->field(TAG_SUBFILE_TYPE);

    if (defined $field) {
      return $field->value_at(0) == OLD_FILE_TYPE_REDUCED_IMAGE;
    }
    else {
      return 0;
    }
  }
}

sub is_page {
  my $self = shift;

  my $field = $self->field(TAG_NEW_SUBFILE_TYPE);

  # First try TAG_NEW_SUBFILE_TYPE, else TAG_SUBFILE_TYPE
  if (defined $field) {
    # If none of bits 0, 1 or 2 is set, this is a regular image
    return ($field->value_at(0) & FILE_TYPE_PAGE) != 0;
  }
  else {
    $field = $self->field(TAG_SUBFILE_TYPE);

    if (defined $field) {
      return $field->value_at(0) == OLD_FILE_TYPE_PAGE;
    }
    else {
      return 0;
    }
  }
}

sub is_mask {
  my $self = shift;

  my $field = $self->field(TAG_NEW_SUBFILE_TYPE);

  # First try TAG_NEW_SUBFILE_TYPE, else TAG_SUBFILE_TYPE
  if (defined $field) {
    # If none of bits 0, 1 or 2 is set, this is a regular image
    return ($field->value_at(0) & FILE_TYPE_MASK) != 0;
  }
  else {
    return 0;
  }
}

my %resolution_units = (
  1 => 'NONE',
  2 => 'INCH',
  3 => 'CM',
);

my $default_resolution_units = 2;

sub resolution_unit {
  my $self = shift;

  my $field = $self->field(TAG_RESOLUTION_UNIT);

  unless (defined $field) {
    my $temp = $resolution_units{$default_resolution_units};
    
    return $temp;
  }

  my $unit = $resolution_units{$field->value_at(0)};

  die("Unrecognized resolution unit '" . $field->value_at(0) . "'. Expected one of: " . join(', ', map { $_ = "'$_'" } sort keys %resolution_units)) unless defined $unit;

  return $unit;
}

# http://www.fileformat.info/format/tiff/egff.htm
my %compression = (
      1 => 'Uncompressed', # baseline
      2 => 'CCITT 1D', # baseline
      3 => 'CCITT Group 3',
      4 => 'CCITT Group 4',
      5 => 'LZW',
      6 => 'JPEG (Old)',
      7 => 'JPEG (Technote2)',
  32771 => 'CCITT RLEW', # http://www.awaresystems.be/imaging/tiff/tifftags/compression.html
  32773 => 'Packbits', # baseline
);

my $default_compression = 1;

sub compression {
  my $self = shift;

  if (exists $self->{COMPRESSION}) {
    return $self->{COMPRESSION};
  }
  
  my $field = $self->field(TAG_COMPRESSION);

  my $value;
  
  if (defined $field) {
    $value = $compression{$field->value_at(0)};

    die("Unrecognized compression '" . $field->value_at(0) . "'. Expected one of: " . join(', ', map { $_ = "'$_'" } sort keys %compression)) unless defined $value;
  }
  else {
    $value = $compression{$default_compression};
  }

  $self->{COMPRESSION} = $value;

  return $value;
}

# http://www.awaresystems.be/imaging/tiff/tifftags/photometricinterpretation.html
my %photometric_interpretation = (
      0 => 'MinIsWhite', # WhiteIsZero
      1 => 'MinIsBlack', # BlackIsZero
      2 => 'RGB',
      3 => 'Palette', # RGB Palette
      4 => 'Mask', # Transparency Mask
      5 => 'Separated', # CMYK
      6 => 'YCbCr',
      8 => 'CIELab',
      9 => 'ICCLab',
     10 => 'ITULab',
  32844 => 'LogL', # Pixar
  32845 => 'LogLuv', # Pixar
);

sub photometric_interpretation {
  my $self = shift;
  
  if (exists $self->{PHOTOMETRIC_INTERPRETATION}) {
    return $self->{PHOTOMETRIC_INTERPRETATION};
  }

  my $field = $self->field(TAG_PHOTOMETRIC_INTERPRETATION);

  unless (defined $field) {
    $self->{PHOTOMETRIC_INTERPRETATION} = undef;
    return undef;
  }

  my $value = $photometric_interpretation{$field->value_at(0)};

  die("Unrecognized photometric interpretation '" . $field->value_at(0) . "'. Expected one of: " . join(', ', map { $_ = "'$_'" } sort keys %photometric_interpretation)) unless defined $value;

  $self->{PHOTOMETRIC_INTERPRETATION} = $value;
  
  return $value;
}

sub datetime {
  my $self = shift;

  return $self->{DATETIME} if exists $self->{DATETIME};

  my $datetime = undef;

  my $field = $self->field(TAG_DATETIME);

  if (defined $field) {
    $datetime = $field->value_at(0);
  }

  $self->{DATETIME} = $datetime;

  return $datetime;
}

sub software {
  my $self = shift;

  return $self->{SOFTWARE} if exists $self->{SOFTWARE};

  my $software = undef;

  my $field = $self->field(TAG_SOFTWARE);

  if (defined $field) {
    $software = $field->value_at(0);
  }

  $self->{SOFTWARE} = $software;

  return $software;
}

sub x_resolution {
  my $self = shift;

  return $self->{X_RESOLUTION} if exists $self->{X_RESOLUTION};

  my $field = $self->field(TAG_X_RESOLUTION);

  return undef unless defined $field;

  my $rat = $field->value_at(0);

  $self->{X_RESOLUTION} = $rat;

  return $rat;
}

sub y_resolution {
  my $self = shift;

  return $self->{Y_RESOLUTION} if exists $self->{Y_RESOLUTION};

  my $field = $self->field(TAG_Y_RESOLUTION);

  return undef unless defined $field;

  my $rat = $field->value_at(0);

  $self->{Y_RESOLUTION} = $rat;

  return $rat;
}

1;
