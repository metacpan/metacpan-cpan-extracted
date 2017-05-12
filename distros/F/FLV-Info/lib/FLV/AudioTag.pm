package FLV::AudioTag;

use warnings;
use strict;
use 5.008;
use Carp;
use English qw(-no_match_vars);

use base 'FLV::Base';

use FLV::Util;
use FLV::Tag;

our $VERSION = '0.24';

=head1 NAME

FLV::AudioTag - Flash video file data structure

=head1 LICENSE

See L<FLV::Info>

=head1 METHODS

This is a subclass of FLV::Base.

=over

=item $self->parse($fileinst)

Takes a FLV::File instance and extracts an FLV audio tag from the file
stream.  This method throws exceptions if the stream is not a valid
FLV v1.0 or v1.1 file.

There is no return value.

Note: this method needs more work to extract the format-specific data.

=cut

sub parse
{
   my $self     = shift;
   my $file     = shift;
   my $datasize = shift;

   my $flags = unpack 'C', $file->get_bytes(1);

   my $format = (($flags >> 4) & 0x0f);
   my $rate   = (($flags >> 2) & 0x03);
   my $size   = (($flags >> 1) & 0x01);
   my $type   = $flags & 0x01;

   if (!exists $AUDIO_FORMATS{$format})
   {
      die "Unknown audio format $format at byte " . $file->get_pos(-1);
   }

   $self->{format} = $format;
   $self->{rate}   = $rate;
   $self->{size}   = $size;
   $self->{type}   = $type;

   $self->{data} = $file->get_bytes($datasize - 1);

   return;
}

=item $self->clone()

Create an independent copy of this instance.

=cut

sub clone
{
   my $self = shift;

   my $copy = FLV::AudioTag->new;
   FLV::Tag->copy_tag($self, $copy);
   for my $key (qw( format rate size type data )) {
      $copy->{$key} = $self->{$key};
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

   my $flags = pack 'C',
       ($self->{format} << 4) | ($self->{rate} << 2) | ($self->{size} << 1) |
       $self->{type};
   return $flags . $self->{data};
}

=item $self->get_info()

Returns a hash of FLV metadata.  See FLV::Info for more details.

=cut

sub get_info
{
   my ($pkg, @args) = @_;
   return $pkg->_get_info(
      'audio',
      {
         format => \%AUDIO_FORMATS,
         rate   => \%AUDIO_RATES,
         size   => \%AUDIO_SIZES,
         type   => \%AUDIO_TYPES,
      },
      \@args
   );
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
