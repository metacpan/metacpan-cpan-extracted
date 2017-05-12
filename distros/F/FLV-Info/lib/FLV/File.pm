package FLV::File;

use warnings;
use strict;
use 5.008;
use Carp;
use English qw(-no_match_vars);

use base 'FLV::Base';
use FLV::Header;
use FLV::Body;
use FLV::MetaTag;
use FLV::Util;

our $VERSION = '0.24';

=for stopwords zeroth

=head1 NAME

FLV::File - Parse Flash Video files

=head1 LICENSE

See L<FLV::Info>

=head1 METHODS

This is a subclass of FLV::Base.

=head2 READ/WRITE METHODS

=over

=item $self->empty()

Prepare an empty FLV.  This is only needed if you do not plan to call
the parse() method.

=cut

sub empty
{
   my $self = shift;

   $self->{header}       = FLV::Header->new();
   $self->{body}         = FLV::Body->new();
   $self->{body}->{tags} = [];
   return;
}

=item $self->parse($filename)

=item $self->parse($filehandle)

Reads the specified file.  If the file does not exist or is an invalid
FLV stream, an exception will be thrown via croak().

There is no return value.

=cut

sub parse
{
   my $self  = shift;
   my $input = shift;
   my $opts  = shift;
   $opts ||= {};

   $self->{header}     = undef;
   $self->{body}       = undef;
   $self->{filename}   = undef;
   $self->{filehandle} = undef;
   $self->{pos}        = 0;

   my $eval_result = eval {
      if (ref $input)
      {
         $self->{filehandle} = $input;
      }
      else
      {
         $self->{filename} = $input;
         ## no critic (RequireBriefOpen)
         open my $fh, '<', $self->{filename} or croak q{} . $OS_ERROR;
         binmode $fh or croak 'Failed to set binary mode on file';
         $self->{filehandle} = $fh;
      }

      $self->{header} = FLV::Header->new();
      $self->{header}->parse($self);    # might throw exception

      $self->{body} = FLV::Body->new();
      $self->{body}->parse($self, $opts);    # might throw exception
      1;
   };
   if (!$eval_result)
   {
      die 'Failed to read FLV file: ' . $EVAL_ERROR;
   }

   $self->{filehandle} = undef;              # implicitly close the filehandle
   $self->{pos}        = 0;

   return;
}

=item $self->clone()

Create an independent copy of this instance.

=cut

sub clone
{
   my $self = shift;

   my $copy = FLV::File->new;
   $copy->{header} = $self->{header}->clone;
   $copy->{body} = $self->{body}->clone;
   return $copy;
}

=item $self->populate_meta()

Fill in various C<onMetadata> fields if they are not already present.

=cut

sub populate_meta    ## no critic(ProhibitExcessComplexity)
{
   my $self = shift;

   $self->{body} ||= FLV::Body->new();
   $self->{body}->merge_meta();

   my %info = (
      vidtags       => 0,
      audtags       => 0,
      vidbytes      => 0,
      audbytes      => 0,
      lasttime      => 0,     # millisec
      keyframetimes => [],    # millisec
   );

   my $invalid = '-1';
   for my $tag ($self->{body}->get_tags())
   {
      if ($tag->isa('FLV::VideoTag'))
      {
         $info{vidtags}++;
         $info{vidbytes} += length $tag->{data};
         my $time = $tag->get_time;
         if ($info{lasttime} < $time)
         {
            $info{lasttime} = $time;
         }
         for my $key (qw(width height type codec))
         {
            if (!defined $info{ 'vid' . $key })
            {
               $info{ 'vid' . $key } = $tag->{$key};
            }
            elsif ($tag->{$key} != $info{ 'vid' . $key })
            {
               $info{ 'vid' . $key } = $invalid;
            }
         }
         if ($tag->is_keyframe())
         {
            push @{ $info{keyframetimes} }, $time;
         }
      }
      elsif ($tag->isa('FLV::AudioTag'))
      {
         $info{audtags}++;
         $info{audbytes} += length $tag->{data};
         for my $key (qw(format rate codec type size))
         {
            if (!defined $info{ 'aud' . $key })
            {
               $info{ 'aud' . $key } = $tag->{$key};
            }
            elsif ($tag->{$key} != $info{ 'aud' . $key })
            {
               $info{ 'aud' . $key } = $invalid;
            }
         }
      }
   }
   my $lasttime = $info{lasttime} * 0.001;
   my $duration
       = 1 < $info{vidtags}
       ? $lasttime * $info{vidtags} / ($info{vidtags} - 1)
       : 0;

   my $audrate = defined $info{audrate}
       && $info{audrate} ne $invalid ? $AUDIO_RATES{ $info{audrate} } : 0;
   $audrate =~ s/\D//gxms;

   my %meta = (
      canSeekToEnd    => 1,
      metadatacreator => __PACKAGE__ . " v$VERSION",
      metadatadate    => scalar gmtime,
      filesize        => 0,
   );

   if (0 < $duration)
   {
      $meta{duration} = $duration;
      if ($info{vidbytes})
      {
         my $kbps = $info{vidbytes} * 8 / (1024 * $duration);

         $meta{videodatarate} = $kbps;
         $meta{framerate}     = $info{vidtags} / $duration;
         $meta{videosize}     = $info{vidbytes};
      }
      if ($info{audbytes})
      {
         my $kbps = $info{audbytes} * 8 / (1024 * $duration);

         $meta{audiodatarate} = $kbps;
         $meta{audiosize}     = $info{audbytes};
      }
   }
   if ($audrate)
   {
      $meta{audiosamplerate} = $audrate;
   }
   if (defined $info{audformat} && $info{audformat} ne $invalid)
   {
      $meta{audiocodecid} = $info{audformat};
   }
   if (defined $info{vidcodec} && $info{vidcodec} ne $invalid)
   {
      $meta{videocodecid} = $info{vidcodec};
   }
   if (defined $info{vidwidth} && $info{vidwidth} ne $invalid)
   {
      $meta{width} = $info{vidwidth};
   }
   if (defined $info{vidheight} && $info{vidheight} ne $invalid)
   {
      $meta{height} = $info{vidheight};
   }
   if ($lasttime)
   {
      $meta{lasttimestamp} = $lasttime;
   }
   if (@{ $info{keyframetimes} })
   {
      $meta{keyframes} = {
         times => [map { $_ * 0.001 } @{ $info{keyframetimes} }],
         millis => $info{keyframetimes},
      };
   }

   $self->set_meta(%meta);

   return;
}

=item $self->serialize($filehandle)

Serializes the in-memory FLV data.  If that representation is not
complete, this throws an exception via croak().  Returns a boolean
indicating whether writing to the file handle was successful.

=cut

sub serialize
{
   my $self = shift;
   my $filehandle = shift || croak 'Please specify a filehandle';

   if (!$self->{body})
   {
      die 'Missing FLV body';
   }
   $self->{header} = FLV::Header->create_from_body($self->{body});
   my $headersize = $self->{header}->serialize($filehandle);
   return if !$headersize;
   return $self->{body}->serialize($filehandle, $headersize);
}

=back

=head2 ACCESSORS

=over

=item $self->get_info()

Returns a hash of FLV metadata.  See File::Info for more details.

=cut

sub get_info
{
   my $self = shift;

   my %info = (
      filename => $self->{filename},
      filesize => -s $self->{filename},
      $self->{body}->get_info(),
   );
   return %info;
}

=item $self->get_filename()

Returns the filename, if any.

=cut

sub get_filename
{
   my $self = shift;
   return $self->{filename};
}

=item $self->get_meta($key);

=item $self->set_meta($key, $value, ...);

These are convenience functions for interacting with an C<onMetadata>
tag at time 0, which is a common convention in FLV files.  If the zeroth
tag is not an L<FLV::MetaTag> instance, one is created and prepended
to the tag list.

See also C<get_meta> and C<set_meta> in L<FLV::Body>.

=cut

sub get_meta
{
   my $self = shift;
   my $key  = shift;

   return if (!$self->{body});
   return $self->{body}->get_meta($key);
}

sub set_meta
{
   my ($self, @args) = @_;

   $self->{body} ||= FLV::Body->new();
   $self->{body}->set_meta(@args);
   return;
}

=item $self->get_header()

=item $self->get_body()

These methods return the FLV::Header and FLV::Body instance,
respectively.  Those will be C<undef> until you call either empty() or
parse().

=cut

sub get_header
{
   my $self = shift;
   return $self->{header};
}

sub get_body
{
   my $self = shift;
   return $self->{body};
}

=back

=head2 PARSING UTILITIES

The following methods are only used during the parsing phase.

=over

=item $self->get_bytes($n)

Reads C<$n> bytes off the active filehandle and returns them as a
string.  Throws an exception if the filehandle is closed or hits EOF
before all the bytes can be read.

=cut

sub get_bytes
{
   my $self = shift;
   my $n = shift || 0;

   return q{} if ($n <= 0);

   my $fh = $self->{filehandle};
   if (!$fh)
   {
      die 'Internal error: attempt to read a closed filehandle';
   }

   my $buf;
   my $bytes = read $fh, $buf, $n;
   if ($bytes != $n)
   {
      die "Unexpected end of file (byte $self->{pos} + $bytes)";
   }
   $self->{pos} += $bytes;
   return $buf;
}

=item $self->get_pos()

=item $self->get_pos($offset)

Returns a string representing the current position in the filehandle.
This is intended for use in debugging or exceptions.  An example of
use: indicate that an input value five bytes behind the read head is
erroneous.

    die 'Error parsing version number at byte '.$self->get_pos(-5);

=cut

sub get_pos
{
   my $self = shift;
   my $offset = shift || 0;

   my $pos = $self->{pos} + $offset;
   return sprintf '%d (0x%x)', $pos, $pos;
}

=item $self->at_end()

Returns a boolean indicating if the FLV stream is exhausted.  Throws
an exception if the filehandle is closed.

=cut

sub at_end
{
   my $self = shift;

   my $fh = $self->{filehandle};
   if (!$fh)
   {
      die 'Internal error: attempt to read a closed filehandle';
   }
   return eof $fh;
}

1;

__END__

=back

=head1 AUTHOR

See L<FLV::Info>

=cut
