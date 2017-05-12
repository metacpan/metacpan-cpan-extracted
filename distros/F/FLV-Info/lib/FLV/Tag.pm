package FLV::Tag;

use warnings;
use strict;
use 5.008;
use Carp;
use English qw(-no_match_vars);

use base 'FLV::Base';

use FLV::Util;
use FLV::AudioTag;
use FLV::VideoTag;
use FLV::MetaTag;

our $VERSION = '0.24';

=for stopwords subtag

=head1 NAME

FLV::Tag - Flash video file data structure

=head1 LICENSE

See L<FLV::Info>

=head1 METHODS

This is a subclass of L<FLV::Base>.

=over

=item $self->parse($fileinst)

=item $self->parse($fileinst, {opt => $optvalue, ...})

Takes a FLV::File instance and extracts an FLV tag from the file
stream.  This method then multiplexes that tag into one of the
subtypes: video, audio or meta.  This method throws exceptions if the
stream is not a valid FLV v1.0 or v1.1 file.

At the end, this method stores the subtag instance, which can be
retrieved with get_payload().

There is no return value.

An option of C<record_positions => 1> causes the byte offset of the
tag to be stored in the instance.  This is intended for testing and/or
debugging, so there is no public accessor for that property.

=cut

sub parse
{
   my $self = shift;
   my $file = shift;
   my $opts = shift;
   $opts ||= {};

   my $content = $file->get_bytes(11);

   my ($type, @datasize, @timestamp);
   (
      $type,         $datasize[0],  $datasize[1],  $datasize[2],
      $timestamp[1], $timestamp[2], $timestamp[3], $timestamp[0]
   ) = unpack 'CCCCCCCC', $content;

   my $datasize = ($datasize[0] * 256 + $datasize[1]) * 256 + $datasize[2];
   my $timestamp
       = (($timestamp[0] * 256 + $timestamp[1]) * 256 + $timestamp[2]) * 256 +
       $timestamp[3];

   if ($timestamp > 4_000_000_000 || $timestamp < 0)
   {
      warn "Funny timestamp: @timestamp -> $timestamp\n";
   }

   if ($datasize < 11)
   {
      die "Tag size is too small ($datasize) at byte " . $file->get_pos(-10);
   }

   my $payload_class = $TAG_CLASSES{$type};
   if (!$payload_class)
   {
      die "Unknown tag type $type at byte " . $file->get_pos(-11);
   }

   $self->{payload} = $payload_class->new();
   $self->{payload}->{start} = $timestamp;    # millisec
   if ($opts->{record_positions})
   {

      # for testing/debugging only!
      $self->{payload}->{_pos} = $file->get_pos(-11);
      $self->{payload}->{_pos} =~ s/\D.*\z//xms;
   }
   $self->{payload}->parse($file, $datasize);    # might throw exception

   return;
}

=item $self->get_payload()

Returns the subtag instance found by parse().  This will be instance
of FLV::VideoTag, FLV::AudioTag or FLV::MetaTag.

=cut

sub get_payload
{
   my $self = shift;
   return $self->{payload};
}

=item $pkg->copy_tag($old_tag, $new_tag)

Perform a generic part of the clone behavior for the tag subtypes.

=cut

sub copy_tag {
   my $pkg_or_self = shift;
   my $old_tag     = shift || croak 'Please specify a tag';
   my $new_tag     = shift || croak 'Please specify a tag';
   for my $key (qw( start )) {
      $new_tag->{$key} = $old_tag->{$key};
   }
   return;
}

=item $pkg->serialize($tag, $filehandle)

=item $self->serialize($tag, $filehandle)

Serializes the specified video, audio or meta tag.  If that
representation is not complete, this throws an exception via croak().
Returns a boolean indicating whether writing to the file handle was
successful.

=cut

sub serialize
{
   my $pkg_or_self = shift;
   my $tag         = shift || croak 'Please specify a tag';
   my $filehandle  = shift || croak 'Please specify a filehandle';

   my $tag_type = { reverse %TAG_CLASSES }->{ ref $tag };
   if (!$tag_type)
   {
      die 'Unknown tag class ' . ref $tag;
   }

   my @timestamp = (
      $tag->{start} >> 24 & 0xff,
      $tag->{start} >> 16 & 0xff,
      $tag->{start} >> 8 & 0xff,
      $tag->{start} & 0xff,
   );
   my $data     = $tag->serialize();
   my $datasize = length $data;
   my @datasize
       = ($datasize >> 16 & 0xff, $datasize >> 8 & 0xff, $datasize & 0xff);

   my $header = pack 'CCCCCCCCCCC', $tag_type, @datasize, @timestamp[1 .. 3],
       $timestamp[0], 0, 0, 0;
   return if (!print {$filehandle} $header);
   return if (!print {$filehandle} $data);
   return 11 + $datasize;
}

1;

__END__

=back

=head1 AUTHOR

See L<FLV::Info>

=cut
