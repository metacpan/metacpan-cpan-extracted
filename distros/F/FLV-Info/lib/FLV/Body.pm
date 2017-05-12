package FLV::Body;

use warnings;
use strict;
use 5.008;
use Carp;
use English qw(-no_match_vars);
use File::Temp qw();

use base 'FLV::Base';

use FLV::Header;
use FLV::Tag;
use FLV::VideoTag;
use FLV::AudioTag;
use FLV::MetaTag;

our $VERSION = '0.24';

=for stopwords keyframe zeroth

=head1 NAME

FLV::Body - Flash video file data structure

=head1 LICENSE

See L<FLV::Info>

=head1 METHODS

This is a subclass of FLV::Base.

=over

=item $self->parse($fileinst)

Takes a FLV::File instance and extracts the FLV body from the file
stream.  This method throws exceptions if the stream is not a valid
FLV v1.0 or v1.1 file.

There is no return value.

=cut

sub parse
{
   my $self = shift;
   my $file = shift;
   my $opts = shift;
   $opts ||= {};

   my @tags;

TAGS:
   while (1)
   {
      my $lastsize = $file->get_bytes(4);

      if ($file->at_end())
      {
         last TAGS;
      }

      my $tag = FLV::Tag->new();
      $tag->parse($file, $opts);    # might throw exception
      push @tags, $tag->get_payload();
   }

   my %tagorder = (
      'FLV::MetaTag'  => 1,
      'FLV::AudioTag' => 2,
      'FLV::VideoTag' => 3,
   );
   @tags = sort {
             $a->{start} <=> $b->{start}
          || $tagorder{ ref $a } <=> $tagorder{ ref $b }
   } @tags;
   $self->{tags} = \@tags;
   return;
}

=item $self->clone()

Create an independent copy of this instance.

=cut

sub clone
{
   my $self = shift;

   my $copy = FLV::Body->new;
   $copy->{tags} = [ map { $_->clone } @{$self->{tags}} ];
   return $copy;
}

=item $self->serialize($filehandle)

Serializes the in-memory FLV body.  If that representation is not
complete, this throws an exception via croak().  Returns a boolean
indicating whether writing to the file handle was successful.

=cut

sub serialize
{
   my $self       = shift;
   my $filehandle = shift || croak 'Please specify a filehandle';
   my $headersize = shift || 9;

   return if (!print {$filehandle} pack 'V', 0);
   return if (!$self->{tags});

   my $size_so_far = $headersize + 4;
   for my $i (0 .. $#{ $self->{tags} })
   {
      my $tag = $self->{tags}->[$i];
      if (
         $tag->isa('FLV::MetaTag')
         && (  defined $tag->get_value('keyframes')
            || defined $tag->get_value('filesize'))
          )
      {
         return $self->_serialize_with_sizes($filehandle, $i, $size_so_far);
      }
      my $size = FLV::Tag->serialize($tag, $filehandle);
      if (!$size)
      {
         return;
      }
      print {$filehandle} pack 'V', $size;
      $size_so_far += $size + 4;
   }
   return 1;
}

sub _serialize_with_sizes
{
   my $self        = shift;
   my $filehandle  = shift;
   my $i           = shift;
   my $size_so_far = shift;

   my $meta = $self->{tags}->[$i];

   my $keyframes = $meta->get_value('keyframes');
   my $filesize  = $meta->get_value('filesize');

   # Write the REST of the tags out to a tempfile
   my ($media_fh, $media_filename) = File::Temp::tempfile();
   my $success = 1;
   my $pos     = 0;
   my @filepositions;
   for my $tag (@{ $self->{tags} }[$i + 1 .. $#{ $self->{tags} }])
   {
      if ($tag->isa('FLV::VideoTag') && $tag->is_keyframe())
      {
         push @filepositions, $pos;
      }
      my $size = FLV::Tag->serialize($tag, $media_fh);
      if (!$size)
      {
         $success = 0;
         last;
      }
      print {$media_fh} pack 'V', $size;
      $pos += $size + 4;
   }
   close $media_fh or warn 'Unexpected error closing filehandle';

   if (!$success)
   {

      # Abort, write out without file positions
      delete $keyframes->{filepositions};
      $meta->set_value('filesize', undef);
      my $size = FLV::Tag->serialize($meta, $filehandle);
      if (!$size)
      {
         unlink $media_filename;
         return;
      }
      print {$filehandle} pack 'V', $size;
      $self->_copy_file_to_fh($media_filename, $filehandle);
      unlink $media_filename;
      return;
   }

   # Problem: changing the file positions in the metatag changes the
   # size of the metatag and, thus, the filepositions.

   # Solution: set file positions in metadata, write out as temp file
   # to get resulting size, and iterate until sizes converge.  This
   # should happen on the second iteration if the sizes are written
   # out as numbers and not as strings.

   # Start with a (wrong) guess of zero bytes
   my ($meta_fh, $meta_filename) = File::Temp::tempfile();
   close $meta_fh or warn 'Unexpected error closing filehandle';

   my $tries = 0;
   while ($tries++ < 10)
   {
      my $meta_size = -s $meta_filename;

      # Put in corrected sizes
      my $offset = $size_so_far + $meta_size;
      if ($keyframes)
      {
         $keyframes->{filepositions} = [map { $offset + $_ } @filepositions];
      }
      $meta->set_value('filesize', $offset + -s $media_filename);

      # Write out meta tag to tempfile
      # Warning: I'm ignoring the case of a failure to write out the
      #    metatag at all
      my ($try_fh, $try_filename) = File::Temp::tempfile();
      my $size = FLV::Tag->serialize($meta, $try_fh);
      if ($size)
      {
         print {$try_fh} pack 'V', $size;
      }
      close $try_fh or warn 'Unexpected error closing filehandle';

      # Clean up last try.  This try becomes "last try" for the next iteration
      unlink $meta_filename;
      $meta_filename = $try_filename;

      # Did we converge?
      if ($meta_size == -s $meta_filename)
      {

         # Yes!
         last;
      }

      # Otherwise do another iteration
   }

   $self->_copy_file_to_fh($meta_filename, $filehandle);
   unlink $meta_filename;
   $self->_copy_file_to_fh($media_filename, $filehandle);
   unlink $media_filename;
   return 1;
}

sub _copy_file_to_fh
{
   my $self       = shift;
   my $filename   = shift;
   my $filehandle = shift;

   open my $fh, '<', $filename or die 'Failed to open temporary file';
   binmode $fh or die 'Failed to set binary mode on file';
   my $buf;
   while (read $fh, $buf, 4096)
   {
      print {$filehandle} $buf;
   }
   close $fh or warn 'Unexpected error closing filehandle';
   return;
}

=item $self->get_info()

Returns a hash of FLV metadata.  See File::Info for more details.

=cut

sub get_info
{
   my $self = shift;

   my %info = (
      duration => $self->last_start_time(),
      FLV::VideoTag->get_info(
         grep { $_->isa('FLV::VideoTag') } @{ $self->{tags} }
      ),
      FLV::AudioTag->get_info(
         grep { $_->isa('FLV::AudioTag') } @{ $self->{tags} }
      ),
      FLV::MetaTag->get_info(
         grep { $_->isa('FLV::MetaTag') } @{ $self->{tags} }
      ),
   );

   return %info;
}

=item $self->get_tags()

Returns an array of tag instances.

=cut

sub get_tags
{
   my $self = shift;

   return @{ $self->{tags} || [] };
}

=item $self->set_tags(@tags)

Replace all of the existing tags with new ones.  For example, you can
remove all audio from a movie like so:

  $body->set_tags(grep {!$_->isa('FLV::AudioTag')} $body->get_tags);

=cut

sub set_tags
{
   my $self = shift;
   my @tags = @_;
   $self->{tags} = \@tags;
   return;
}

=item $self->get_video_frames()

Returns the video tags (FLV::VideoTag instances) in the FLV stream.

=cut

sub get_video_frames
{
   my $self = shift;

   return grep { $_->isa('FLV::VideoTag') } @{ $self->{tags} };
}

=item $self->get_video_keyframes()

Returns just the video tags which contain keyframe data.

=cut

sub get_video_keyframes
{
   my $self = shift;

   return
       grep { $_->isa('FLV::VideoTag') && $_->is_keyframe() }
       @{ $self->{tags} };
}

=item $self->get_audio_packets()

Returns the audio tags (FLV::AudioTag instances) in the FLV stream.

=cut

sub get_audio_packets
{
   my $self = shift;

   return grep { $_->isa('FLV::AudioTag') } @{ $self->{tags} };
}

=item $self->get_meta_tags()

Returns the meta tags (FLV::MetaTag instances) in the FLV stream.

=cut

sub get_meta_tags
{
   my $self = shift;

   return grep { $_->isa('FLV::MetaTag') } @{ $self->{tags} };
}

=item $self->last_start_time()

Returns the start timestamp of the last tag, in milliseconds.

=cut

sub last_start_time
{
   my $self = shift;

   my $tag = $self->{tags}->[-1]
       or die 'No tags found';
   return $tag->{start};
}

=item $self->get_meta($key);

=item $self->set_meta($key, $value, ...);

These are convenience functions for interacting with an C<onMetadata>
tag at time 0, which is a common convention in FLV files.  If the zeroth
tag is not an L<FLV::MetaTag> instance, one is created and prepended
to the tag list.

See also C<get_value> and C<set_value> in L<FLV::MetaTag>.

=cut

sub get_meta
{
   my $self = shift;
   my $key  = shift;

   return if (!$self->{tags});
   for my $meta (grep { $_->isa('FLV::MetaTag') } @{ $self->{tags} })
   {
      my $value = $meta->get_value($key);
      return $value if (defined $value);
   }
   return;
}

sub set_meta
{
   my ($self, @keyvalues) = @_;

   $self->{tags} ||= [];
   my @metatags = grep { $_->isa('FLV::MetaTag') } @{ $self->{tags} };
   if (!@metatags)
   {

      # no metatags at all!  Create one.
      my $new_meta = FLV::MetaTag->new();
      $new_meta->{start} = 0;
      unshift @{ $self->{tags} }, $new_meta;
      @metatags = ($new_meta);
   }

KEYVALUE:
   while (@keyvalues)
   {
      my ($key, $value) = splice @keyvalues, 0, 2;

      # Check all existing meta tags for that key
      for my $meta (@metatags)
      {
         if (defined $meta->get_value($key))
         {
            $meta->set_value($key => $value);
            next KEYVALUE;
         }
      }

      # key not found
      $metatags[0]->set_value($key => $value);
   }

   return;
}

=item $self->merge_meta()

Consolidate zero or more meta tags into a single tag.  If there are
more than one tags and there are any duplicate keys, the first key
takes precedence.

=cut

sub merge_meta
{
   my $self = shift;

   $self->{tags} ||= [];

   # Remove all meta tags
   my @meta = grep { $_->isa('FLV::MetaTag') } @{ $self->{tags} };
   @{ $self->{tags} } = grep { !$_->isa('FLV::MetaTag') } @{ $self->{tags} };

   # Merge all metadata
   my %meta = map { $_->get_values() } reverse @meta;

   # Insert a new metatag
   $self->set_meta(%meta);
   return;
}

=item $self->make_header()

Create a new header from the body data.

=cut

sub make_header
{
   my $self = shift;
   my $header = FLV::Header->new;

   for my $tag (@{$self->{tags}})
   {
      if ($tag->isa('FLV::VideoTag'))
      {
         $header->{has_video} = 1;
      }
      elsif ($tag->isa('FLV::AudioTag'))
      {
         $header->{has_audio} = 1;
      }
   }
   return $header;
}

1;

__END__

=back

=head1 AUTHOR

See L<FLV::Info>

=cut
