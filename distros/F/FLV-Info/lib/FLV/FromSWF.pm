package FLV::FromSWF;

use warnings;
use strict;
use 5.008;

use SWF::File;
use SWF::Parser;
use SWF::Element;
use FLV::File;
use FLV::Util;
use FLV::AudioTag;
use FLV::VideoTag;
use English qw(-no_match_vars);
use Carp;

our $VERSION = '0.24';

=for stopwords SWF transcodes

=head1 NAME

FLV::FromSWF - Convert a SWF file into an FLV file

=head1 LICENSE

See L<FLV::Info>

=head1 SYNOPSIS

   use FLV::FromSwf;
   my $converter = FLV::FromSWF->new();
   $converter->parse_swf($swf_filename);
   $converter->save($flv_filename);

See also L<swf2flv>.

=head1 DESCRIPTION

Transcodes SWF files into FLV files.  See the L<swf2flv> command-line
program for a nice interface and a detailed list of caveats and
limitations.

=head1 METHODS

=over

=item $pkg->new()

Instantiate a converter and prepare an empty FLV.

=cut

sub new
{
   my $pkg = shift;

   my $self = bless { flv => FLV::File->new() }, $pkg;
   $self->{flv}->empty();
   $self->{flv}->set_meta(canSeekToEnd => 1);
   return $self;
}

=item $self->parse_swf($swf_filename)

Open and traverse the specified SWF file, creating FLV data as we find
video and audio nodes.

=cut

sub parse_swf
{
   my $self   = shift;
   my $infile = shift;

   $self->{framenumber} = 0;
   $self->{samples}     = 0;
   $self->{videobytes}  = 0;
   $self->{audiobytes}  = 0;

   my $parser = SWF::Parser->new(
      header_callback => sub { $self->_header(@_); },
      tag_callback    => sub { $self->_tag(@_); },
   );
   $parser->parse_file($infile);

   # This is a rough approximation, but should be good enough
   my $duration = $self->{flv}->get_meta('duration');
   my $vidrate  = $self->{videobytes} * 8 / (1024 * $duration);    # kbps
   my $audrate  = $self->{audiobytes} * 8 / (1024 * $duration);    # kbps
   $self->{flv}->set_meta(videodatarate => $vidrate);
   $self->{flv}->set_meta(audiodatarate => $audrate);

   return;
}

=item $self->save($flv_filename)

Write out an FLV file.  Note: this should be called only after
C<parse_swf()>.  Throws an exception upon error.

=cut

sub save
{
   my $self    = shift;
   my $outfile = shift;

   my $outfh = FLV::Util->get_write_filehandle($outfile);
   if (!$outfh)
   {
      die 'Failed to write FLV: ' . $OS_ERROR;
   }

   $self->{flv}->set_meta(creationdate => scalar gmtime);
   if (!$self->{flv}->serialize($outfh))
   {
      die 'Failed to write FLV';
   }
   close $outfh or die 'Failed to finish writing FLV';
   return;
}

sub _header
{
   my ($self, $parser, @r) = @_;

   my %header;
   @header{qw(signature version filelen xmin ymin xmax ymax rate count)} = @r;
   $self->{header} = \%header;

   $self->{flv}->set_meta(framerate => $header{rate});
   $self->{flv}->set_meta(duration  => $header{count} / $header{rate});
   return;
}

my %tag_subs = (
   DefineVideoStream => \&_video_stream,
   VideoFrame        => \&_video_frame,
   SoundStreamHead   => \&_audio_stream,
   SoundStreamHead2  => \&_audio_stream,
   SoundStreamBlock  => \&_audio_block,
   ShowFrame         => \&_show_frame,
);

sub _tag
{
   my $self   = shift;
   my $parser = shift;
   my $tagid  = shift;
   my $length = shift;
   my $stream = shift;

   # Naughty code: we use a private method from SWF::Element::Tag to
   # save ourselves the trouble of maintaining a mapping of tag ID to
   # human-readable name.
   # TODO: rewrite to use SWF::Element::Tag methods

   ## no critic(ProtectPrivateSubs)
   my $tagname = SWF::Element::Tag->_tag_class($tagid);
   $tagname =~ s/SWF::Element::Tag:://xms;

   my $tag_sub = $tag_subs{$tagname};
   if ($tag_sub)
   {
      $self->$tag_sub($stream, $length);
   }

   return;
}

sub _show_frame
{
   my $self   = shift;
   my $stream = shift;
   my $length = shift;

   $self->{framenumber}++;
   return;
}

sub _audio_stream
{
   my $self   = shift;
   my $stream = shift;
   my $length = shift;

   my $streamhead = $stream->get_string(4);
   my ($playflags, $streamflags, $count) = unpack 'CCv', $streamhead;
   $self->{audiocodec} = ($streamflags >> 4) & 0xf;
   $self->{audiorate}  = ($streamflags >> 2) & 0x3;
   $self->{audiosize}  = ($streamflags >> 1) & 0x1;
   $self->{stereo}     = $streamflags & 0x1;

   if (2 == $self->{audiocodec} && 4 < $length)
   {
      my ($latency) = unpack 'v', $stream->get_string(2);

      # unsigned -> signed conversion
      $self->{audiolatency} = unpack 's', pack 'S', $latency;
   }
   $self->{flv}->{header}->{has_audio} = 1;
   $self->{flv}->set_meta(audiocodecid => $self->{audiocodec});

   return;
}

sub _audio_block
{
   my $self   = shift;
   my $stream = shift;
   my $length = shift;

   if (0 == $length)    # empty block
   {
      warn 'Skipping empty audio block';
      return;
   }

   my $audiotag = FLV::AudioTag->new();

   # time calculation will be redone for MP3...
   my $millisec = 1000 * $self->{framenumber} / $self->{header}->{rate};

   $audiotag->{format} = $self->{audiocodec};
   $audiotag->{rate}   = $self->{audiorate};
   $audiotag->{size}   = $self->{audiosize};
   $audiotag->{type}   = $self->{stereo};

   if (2 == $self->{audiocodec})
   {
      if (4 == $length)    # empty block
      {
         warn 'Skipping empty audio block';
         return;
      }

      my ($samples) = unpack 'v', $stream->get_string(2);
      my ($seek)    = unpack 'v', $stream->get_string(2);

      # unsigned -> signed conversion
      $seek = unpack 's', pack 'S', $seek;

      $audiotag->{data} = $stream->get_string($length - 4);

      (my $rate = $AUDIO_RATES{ $self->{audiorate} }) =~ s/\D//gxms;

      if (0 == $self->{samples})
      {
         my $frame = $self->{framenumber};
         if (1 == $frame)
         {

            # Often audio skips one frame.
            # This is true for On2 SWFs, but not Sorenson.
            $frame = 0;
         }

         $self->{samples} = $rate * $frame / $self->{header}->{rate};
      }

      $millisec = 1000 * $self->{samples} / $rate;
      if (4_000_000_000 < $millisec || 0 > $millisec)
      {
         warn 'Funny output timestamp: '
             . "$millisec ($self->{samples}, $samples, $rate)";
      }
      $self->{samples} += $samples;
   }
   else
   {
      $audiotag->{data} = $stream->get_string($length);
   }
   $audiotag->{start} = int $millisec;

   push @{ $self->{flv}->{body}->{tags} }, $audiotag;
   $self->{audiobytes} += $length;

   return;
}

sub _video_stream
{
   my $self   = shift;
   my $stream = shift;
   my $length = shift;

   my ($streamid, $nframes, $width, $height, $flags, $codec)
       = unpack 'vvvvCC', $stream->get_string(10);
   if ($self->{streamid})
   {
      warn 'Found multiple video streams in this SWF, ignoring all but one';
      return;
   }
   $self->{streamid} = $streamid;
   $self->{codec}    = $codec;

   $self->{flv}->{header}->{has_video} = 1;

   $self->{flv}->set_meta(videocodecid => $codec);
   $self->{flv}->set_meta(width        => $width);
   $self->{flv}->set_meta(height       => $height);

   return;
}

sub _video_frame
{
   my $self   = shift;
   my $stream = shift;
   my $length = shift;

   if (0 == $length)    # empty block
   {
      warn 'Skipping empty video block';
      return;
   }

   my ($streamid, $framenum) = unpack 'vv', $stream->get_string(4);
   return if ($self->{streamid} != $streamid);
   my $videotag = FLV::VideoTag->new();
   my $millisec = 1000 * $self->{framenumber} / $self->{header}->{rate};
   $videotag->{start} = int $millisec;
   $videotag->{data}  = $stream->get_string($length - 4);
   $videotag->{codec} = $self->{codec};

   ## no critic(ControlStructures::ProhibitCascadingIfElse)

   if (2 == $self->{codec})
   {
      $videotag->_parse_h263(0);
   }
   elsif (3 == $self->{codec} || 6 == $self->{codec})
   {

      # zeroth frame is a key frame, all others are deltas.  Right???
      $videotag->_parse_screen_video(0);
      $videotag->{type} = $framenum ? 2 : 1;
   }
   elsif (4 == $self->{codec})
   {

      # prepend pixel offsets present in FLV, but absent in SWF
      my $offset = pack 'C', 0;
      $videotag->{data} = $offset . $videotag->{data};
      $videotag->_parse_on2vp6(0);
   }
   elsif (5 == $self->{codec})
   {

      # prepend pixel offsets present in FLV, but absent in SWF
      my $offset = pack 'C', 0;
      $videotag->{data} = $offset . $videotag->{data};
      $videotag->_parse_on2vp6_alpha(0);
   }

   push @{ $self->{flv}->{body}->{tags} }, $videotag;
   $self->{videobytes} += $length;

   return;
}

1;

__END__

=back

=head1 CAVEATS

Content in the SWF other than audio or video data is currently ignored
silently.  I should add warning messages when significant
non-audio/video content appears.  For example, I've seen some screen
video which mixes video, bitmaps and shapes to optimize the SWF file
size.  L<http://rt.cpan.org/Ticket/Display.html?id=22095>

=head1 AUTHOR

See L<FLV::Info>

=cut
