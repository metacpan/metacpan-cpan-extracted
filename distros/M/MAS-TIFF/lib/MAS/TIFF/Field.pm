use strict;
use warnings;

package MAS::TIFF::Field;

# http://www.fileformat.info/format/tiff/egff.htm
my %tags = (
    254 => 'NewSubFileType',
    255 => 'SubFileType',
    256 => 'ImageWidth',
    257 => 'ImageLength', # aka ImageHeight
    258 => 'BitsPerSample',
    259 => 'Compression',
    262 => 'PhotometricInterpretation',
    263 => 'Thresholding',
    264 => 'CellWidth',
    265 => 'CellLength',
    266 => 'FillOrder',
    269 => 'DocumentName',
    270 => 'ImageDescription',
    271 => 'Make',
    272 => 'Model',
    273 => 'StripOffsets',
    274 => 'Orientation',
    277 => 'SamplesPerPixel',
    278 => 'RowsPerStrip',
    279 => 'StripByteCounts',
    280 => 'MinSampleValue',
    281 => 'MaxSampleValue',
    282 => 'XResolution',
    283 => 'YResolution',
    284 => 'PlanarConfiguration',
    285 => 'PageName',
    286 => 'XPosition',
    287 => 'YPosition',
    288 => 'FreeOffsets',
    289 => 'FreeByteCounts',
    290 => 'GrayResponseUnit',
    291 => 'GrayResponseCurve',
    292 => 'T4Options', # Before TIFF 6.0, was called Group3Options
    293 => 'T6Options', # Before TIFF 6.0, was called Group3Options
    296 => 'ResolutionUnit',
    297 => 'PageNumber',
    300 => 'ColorResponseUnit',
    301 => 'TransferFunction', # Before TIFF 6.0, was called ColorResponseCurve
    305 => 'Software',
    306 => 'DateTime',
    315 => 'Artist',
    316 => 'HostComputer',
    317 => 'Predictor',
    318 => 'WhitePoint',
    319 => 'PrimaryChromaticities',
    320 => 'ColorMap',
    321 => 'HalftoneHints',
    322 => 'TileWidth',
    323 => 'TileLength',
    324 => 'TileOffsets',
    325 => 'TileByteCounts',

    # TIFF Class F, not TIFF 6.0
    326 => 'BadFaxLines',
    327 => 'CleanFaxData',
    328 => 'ConsecutiveBadFaxLines',

    332 => 'InkSet',
    333 => 'InkNames',
    334 => 'NumberOfInks',
    336 => 'DotRange',
    337 => 'TargetPrinter',
    338 => 'ExtraSamples',
    339 => 'SampleFormat',
    340 => 'SMinSampleValue',
    341 => 'SMaxSampleValue',
    342 => 'TransferRange',
    512 => 'JPEGProc',
    513 => 'JPEGInterchangeFormat',
    514 => 'JPEGInterchangeFormatLength',
    515 => 'JPEGRestartInterval',
    517 => 'JPEGLosslessPredictors',
    518 => 'JPEGPointTransforms',
    519 => 'JPEGQTables',
    520 => 'JPEGDCTTables',
    521 => 'JPEGACTTables',
    529 => 'YCbCrCoefficiets',
    530 => 'YCbCrSubSampling',
    531 => 'YCbCrPositioning',
    532 => 'ReferenceBlackAndWhite',
    700 => 'XMP', # http://www.awaresystems.be/imaging/tiff/tifftags/extension.html
  33432 => 'Copyright',
  34377 => 'Photoshop Image Resource Blocks', # http://www.digitalpreservation.gov/formats/content/tiff_tags.shtml
  34665 => 'Exif IFD', # http://www.digitalpreservation.gov/formats/content/tiff_tags.shtml
);

sub read_from_io {
  my $class = shift;
  my $io = shift;
  
  my $tag_id = $io->read_word;
  my $tag_name = $tags{$tag_id};

  my $data_type = MAS::TIFF::DataType->read_from_io($io);
  my $data_count = $io->read_dword;
  my $data_raw = $io->read(4);
  
  my $self = bless {
    IO     => $io,
    ID     => $tag_id,
    NAME   => $tag_name,
    TYPE   => $data_type,
    COUNT  => $data_count,
    RAW    => $data_raw,
  }, $class;
  
  return $self;
}

sub id { return shift->{ID} }
sub name { return shift->{NAME} }
sub type { return shift->{TYPE} }
sub count { return shift->{COUNT} }
sub raw { return shift->{RAW} }

sub size {
  my $self = shift;
  
  if (exists $self->{SIZE}) {
    return $self->{SIZE};
  }
  
  my $size = $self->type->size * $self->count;
  
  $self->{SIZE} = $size;
  
  return $size;
}

sub offset {
  my $self = shift;
  
  if (exists $self->{OFFSET}) {
    return $self->{OFFSET};
  }
    
  my $offset;
  
  if ($self->size <= 4) {
    $offset = undef;
  }
  else {
    if ($self->{IO}->byte_order eq 'I') {
      $offset = unpack('L<', $self->raw);
    }
    else {
      $offset = unpack('L>', $self->raw);
    }
  }
  
  $self->{OFFSET} = $offset;
  
  return $offset;
}

sub template {
  my $self = shift;
  return $self->type->template($self->count, $self->{IO}->byte_order);
}

sub value_at {
  my $self = shift;
  my $index = shift;
  
  die "Index must be defined" unless defined $index;
  
  my $values = $self->all_values;
  
  return $values->[$index];
}

sub all_values {
  my $self = shift;
  
  my $values;
  
  if (not exists $self->{VALUES}) {
    my $size = $self->type->size * $self->count;
  
    my $bytes;
  
    if ($size <= 4) {
      $bytes = $self->{RAW};
    }
    else {
      $bytes = $self->{IO}->read($size, $self->offset);
    }

    my $unpacked = [ unpack($self->template, $bytes) ];
    
    $values = $self->type->post_process($unpacked);
  
    $self->{VALUES} = $values;
  }
  else {
    $values = $self->{VALUES};
  }
  
  return $values;
}

1;
