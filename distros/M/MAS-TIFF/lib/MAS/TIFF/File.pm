#
# http://partners.adobe.com/public/developer/en/tiff/TIFF6.pdf
#

use strict;
use warnings;

package MAS::TIFF::File;

use Filehandle;
use MAS::TIFF::IO;
use MAS::TIFF::IFD;
use MAS::TIFF::DataType;

our $VERSION = '0.4';

sub new {
  my $class = shift;
  my $path = shift;

  my $io = MAS::TIFF::IO->new($path);
  
  my $absolute_ifd_offset = $io->read_dword;

  my @ifds = ( );
  while ($absolute_ifd_offset != 0) {
    my $ifd = MAS::TIFF::IFD->new($io, $absolute_ifd_offset);
    
    push @ifds, $ifd;

    $absolute_ifd_offset = $ifd->next_ifd_offset();
  }

  my $self = bless {
    PATH => $path,
    IO => $io,
    IFDS => [ @ifds ],
  }, $class;
  
  return $self;
}

sub path { return shift->{PATH} }
sub io { return shift->{IO} }
sub ifds { return @{shift->{IFDS}} }

sub close {
  my $self = shift;
  $self->io->close;
  delete $self->{IO};
}

sub dump {
  my $self = shift;
  
  if ($self->io->byte_order eq 'M') {
      print "TIF: Motorola byte-order\n";
  }
  elsif ($self->io->byte_order eq 'I') {
    print "TIF: Intel byte-order\n";
  }
  else {
    die "Unexpected byte order '" . $self->io->byte_order . "'!";
  }

  foreach my $ifd ($self->ifds) {
    printf("  IFD: At offset %d\n", $ifd->offset);
    
    foreach my $field ($ifd->fields) {
      if ($field->size > 4) {
        printf("    FIELD: TAG %d (%s), TYPE %s, COUNT %d, SIZE %d, TEMPLATE %s, RAW 0x%s, OFFSET %d\n", $field->id, $field->name,
          $field->type->name, $field->count, $field->size, $field->template,  unpack('H*', $field->raw), $field->offset);
      }
      else {
        printf("    FIELD: TAG %d (%s), TYPE %s, COUNT %d, SIZE %d, TEMPLATE %s, RAW 0x%s, VALUES (%s)\n", $field->id, $field->name,
          $field->type->name, $field->count, $field->size, $field->template, unpack('H*', $field->raw), join(', ', @{$field->all_values}));
      }
    }
    
    printf("    Size: %d x %d\n", $ifd->image_width, $ifd->image_length);
    printf("    Bits per sample: %d\n", $ifd->bits_per_sample);
    printf("    Samples per pixel: %d\n", $ifd->samples_per_pixel);
    printf("    Compression: '%s'\n", $ifd->compression);
    printf("    Photometric Interpretation: '%s'\n", $ifd->photometric_interpretation);
    printf("    Rows per strip: %d\n", $ifd->rows_per_strip);
    printf("    Strip count: %d\n", $ifd->strip_count);
    printf("    Strip offsets: (%s)\n", join(', ', $ifd->strip_offsets));
    printf("    Strip byte counts: (%s)\n", join(', ', $ifd->strip_byte_counts));
    printf("    Is Image: %d\n", $ifd->is_image);
    printf("    Is Reduced Image: %d\n", $ifd->is_reduced_image);
    printf("    Is Page: %d\n", $ifd->is_page);
    printf("    Is Mask: %d\n", $ifd->is_mask);
    printf("    Resolution: %s x %s PIXELS / %s\n", $ifd->x_resolution->to_string, $ifd->y_resolution->to_string, $ifd->resolution_unit);
    printf("    Software: '%s'\n", $ifd->software) if defined $ifd->software;
    printf("    Datetime: '%s'\n", $ifd->datetime) if defined $ifd->datetime;
    
#    my $index = 0;
#    my $bytes = $ifd->strip($index);   
#    my $dump = unpack('H*', $bytes);
#   print "\nStrip 0:\n";
#   print $dump, "\n\n";
  }
}

1;
