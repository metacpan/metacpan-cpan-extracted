package FLV::VideoTag;

use warnings;
use strict;
use 5.008;
use Carp;
use English qw(-no_match_vars);

use base 'FLV::Base';

use FLV::Util;
use FLV::Tag;

our $VERSION = '0.24';

=for stopwords codec

=head1 NAME

FLV::VideoTag - Flash video file data structure

=head1 LICENSE

See L<FLV::Info>

=head1 METHODS

This is a subclass of L<FLV::Base>.

=over

=item $self->parse($fileinst)

Takes a FLV::File instance and extracts an FLV video tag from the file
stream.  This method throws exceptions if the
stream is not a valid FLV v1.0 or v1.1 file.

There is no return value.

Note: this method needs more work to extract the codec specific data.

=cut

sub parse
{
   my $self     = shift;
   my $file     = shift;
   my $datasize = shift;

   my $flags = unpack 'C', $file->get_bytes(1);

   # The spec PDF is wrong -- type comes first, then codec
   my $type  = ($flags >> 4) & 0x0f;
   my $codec = $flags & 0x0f;

   if (!exists $VIDEO_CODEC_IDS{$codec})
   {
      die 'Unknown video codec ' . $codec . ' at byte ' . $file->get_pos(-1);
   }
   if (!exists $VIDEO_FRAME_TYPES{$type})
   {
      die 'Unknown video frame type at byte ' . $file->get_pos(-1);
   }

   $self->{codec} = $codec;
   $self->{type}  = $type;

   my $pos = $file->get_pos();

   $self->{data} = $file->get_bytes($datasize - 1);

   my $result
       = 2 == $self->{codec} ? $self->_parse_h263($pos)
       : 3 == $self->{codec} ? $self->_parse_screen_video($pos)
       : 4 == $self->{codec} ? $self->_parse_on2vp6($pos)
       : 5 == $self->{codec} ? $self->_parse_on2vp6_alpha($pos)
       : 6 == $self->{codec} ? $self->_parse_screen_video($pos)
       : 7 == $self->{codec} ? $self->_parse_avc($pos)
       :                       die 'Unknown video type';

   return;
}

sub _parse_h263
{
   my $self = shift;
   my $pos  = shift;

   # Surely there's a better way than this....
   my $bits = unpack 'B67', $self->{data};
   my $sizecode = substr $bits, 30, 3;
   my @d = (
      (ord pack 'B8', substr $bits, 33, 8),
      (ord pack 'B8', substr $bits, 41, 8),
      (ord pack 'B8', substr $bits, 49, 8),
      (ord pack 'B8', substr $bits, 57, 8),
   );
   my ($width, $height, $offset)
       = '000' eq $sizecode ? ($d[0], $d[1], 16)
       : '001' eq $sizecode ? ($d[0] * 256 + $d[1], $d[2] * 256 + $d[3], 32)
       : '010' eq $sizecode ? (352, 288, 0)
       : '011' eq $sizecode ? (176, 144, 0)
       : '100' eq $sizecode ? (128, 96,  0)
       : '101' eq $sizecode ? (320, 240, 0)
       : '110' eq $sizecode ? (160, 120, 0)
       :   die 'Illegal value for H.263 size code at byte ' . $pos;

   $self->{width}  = $width;
   $self->{height} = $height;

   my $typebits = substr $bits, 33 + $offset, 2;
   my @typebits = split m//xms, $typebits;
   my $type     = 1 + $typebits[0] * 2 + $typebits[1];
   if (!defined $self->{type})
   {
      $self->{type} = $type;
   }
   elsif ($type != $self->{type})
   {
      warn "Type mismatch: header says $VIDEO_FRAME_TYPES{$self->{type}}, "
          . "data says $VIDEO_FRAME_TYPES{$type}";
   }

   return;
}

sub _parse_screen_video
{
   my $self = shift;
   my $pos  = shift;

   # Extract 4 bytes, big-endian
   my ($width, $height) = unpack 'nn', $self->{data};

   # Only use the lower 12 bits of each
   $width  &= 0x3fff;
   $height &= 0x3fff;

   $self->{width}  = $width;
   $self->{height} = $height;

   $self->{type} ||= 1;

   return;
}

sub _parse_on2vp6
{
   my $self = shift;
   my $pos  = shift;

   if (!$self->{type})
   {

      # Bit 7 of the header (after 8 bits of offset) distinguishes
      # keyframe from interframe
      # See: http://use.perl.org/~ChrisDolan/journal/30427
      my @bytes = unpack 'CC', $self->{data};
      $self->{type} = 0 == ($bytes[1] & 0x80) ? 1 : 2;
   }

   return;
}

sub _parse_on2vp6_alpha
{
   my $self = shift;
   my $pos  = shift;

   if (!$self->{type})
   {

      # Bit 7 of the header (after 32 bits of offset) distinguishes
      # keyframe from interframe
      my @bytes = unpack 'CCCCC', $self->{data};
      $self->{type} = 0 == ($bytes[4] & 0x80) ? 1 : 2;
   }

   return;
}

sub _parse_avc
{
   my $self = shift;
   my $pos  = shift;

   my @time;
   ($self->{avc_packet_type}, $time[0], $time[1], $time[2]) = unpack 'CCCC', $self->{data};
   $self->{composition_time} = ($time[0] * 256 + $time[1]) * 256 + $time[2];

   return;
}

=item $self->clone()

Create an independent copy of this instance.

=cut

sub clone
{
   my $self = shift;

   my $copy = FLV::VideoTag->new;
   FLV::Tag->copy_tag($self, $copy);
   for my $key (qw( codec type width height data avc_packet_type composition_time )) {
      if (exists $self->{$key}) {
         $copy->{$key} = $self->{$key};
      }
   }
   return $copy;
}

=item $self->serialize()

Returns a byte string representation of the tag data.  Throws an
exception via croak() on error.

=cut

sub serialize
{
   my $self = shift;

   my $flags = pack 'C', ($self->{type} << 4) | $self->{codec};
   return $flags . $self->{data};
}

=item $self->get_info()

Returns a hash of FLV metadata.  See FLV::Info for more details.

=cut

sub get_info
{
   my ($pkg, @args) = @_;

   return $pkg->_get_info(
      'video',
      {
         type   => \%VIDEO_FRAME_TYPES,
         codec  => \%VIDEO_CODEC_IDS,
         width  => undef,
         height => undef,
      },
      \@args
   );
}

=item $self->is_keyframe()

Returns a boolean.

=cut

sub is_keyframe
{
   my $self = shift;
   return $self->{type} && 1 == $self->{type} ? 1 : undef;
}

=item $self->get_time()

Returns the time in milliseconds for this tag.

=cut

sub get_time
{
   my $self = shift;
   return $self->{start};
}

1;

__END__

=back

=head1 AUTHOR

See L<FLV::Info>

=cut
