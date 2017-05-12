package FLV::ToSWF;

use warnings;
use strict;
use 5.008;

use SWF::File;
use SWF::Element;
use FLV::File;
use FLV::Util;
use FLV::AudioTag;
use FLV::VideoTag;
use English qw(-no_match_vars);
use Carp;

our $VERSION = '0.24';

=for stopwords SWF transcodes framerate

=head1 NAME

FLV::ToSWF - Convert an FLV file into a SWF file

=head1 LICENSE

See L<FLV::Info>

=head1 SYNOPSIS

   use FLV::ToSwf;
   my $converter = FLV::ToSWF->new();
   $converter->parse_flv($flv_filename);
   $converter->save($swf_filename);

See also L<flv2swf>.

=head1 DESCRIPTION

Transcodes FLV files into SWF files.  See the L<flv2swf> command-line
program for a nice interface and a detailed list of caveats and
limitations.

=head1 METHODS

=over

=item $pkg->new()

Instantiate a converter and prepare an empty SWF.

=cut

sub new
{
   my $pkg = shift;

   my $self = bless {
      flv              => FLV::File->new(),
      background_color => [0, 0, 0],          # RGB, black
   }, $pkg;
   $self->{flv}->empty();
   return $self;
}

=item $self->parse_flv($flv_filename)

Open and parse the specified FLV file.  If the FLV file lacks
C<onMetadata> details, that tag is populated with duration,
framerate, video dimensions, etc.

=cut

sub parse_flv
{
   my $self   = shift;
   my $infile = shift;

   $self->{flv}->parse($infile);
   $self->{flv}->populate_meta();

   $self->_validate();

   return;
}

sub _validate
{
   my $self = shift;

   my $acodec = $self->{flv}->get_meta('audiocodecid');
   if (defined $acodec && $acodec != 2)
   {
      die "Audio format $AUDIO_FORMATS{$acodec} not supported; "
          . "only MP3 audio allowed\n";
   }
   return;
}

=item $self->save($swf_filename)

Write out a SWF file.  Note: this is usually called only after
C<parse_flv()>.  Throws an exception upon error.

=cut

sub save
{
   my $self    = shift;
   my $outfile = shift;

   # Collect FLV info
   my $flvinfo = $self->_flvinfo();

   # Create a new SWF
   my $swf = $self->_startswf($flvinfo);

   $self->{audsamples} = 0;

   for my $i (0 .. $#{ $flvinfo->{vidtags} })
   {
      my $vidtag = $flvinfo->{vidtags}->[$i];
      my $data   = $vidtag->{data};
      if (4 == $vidtag->{codec} || 5 == $vidtag->{codec})
      {

         # On2 VP6 is different in FLV vs. SWF!
         if ($data !~ s/\A(.)//xms || $1 ne pack 'C', 0)
         {
            warn 'This FLV has a non-zero video size adjustment. '
                . "It may not play properly as a SWF...\n";
         }
      }
      SWF::Element::Tag::VideoFrame->new(
         StreamID  => 1,
         FrameNum  => $i,
         VideoData => $data,
      )->pack($swf);

      if (0 == $i)
      {
         SWF::Element::Tag::PlaceObject2->new(
            Flags       => 22,    # matrix, tween ratio and characterID
            CharacterID => 1,
            Matrix => SWF::Element::MATRIX->new(
               ScaleX      => 1,
               ScaleY      => 1,
               RotateSkew0 => 0,
               RotateSkew1 => 0,
               TranslateX  => 0,
               TranslateY  => 0,
            ),
            Ratio => $i,
            Depth => 4,
         )->pack($swf);
      }
      else
      {
         SWF::Element::Tag::PlaceObject2->new(
            Flags => 17,    # move and tween ratio
            Ratio => $i,
            Depth => 4,
         )->pack($swf);
      }

      $self->_add_audio($swf, $flvinfo, $vidtag->{start},
         $i == $#{ $flvinfo->{vidtags} });

      SWF::Element::Tag::ShowFrame->new()->pack($swf);
   }

   # Save to disk
   $swf->close(q{-} eq $outfile ? \*STDOUT : $outfile);

   return;
}

sub _add_audio
{
   my $self    = shift;
   my $swf     = shift;
   my $flvinfo = shift;
   my $start   = shift;
   my $islast  = shift;

   if (@{ $flvinfo->{audtags} })
   {
      my $data     = q{};
      my $any_tag  = $flvinfo->{audtags}->[0];
      my $audstart = $any_tag->{start};
      my $format   = $any_tag->{format};
      my $stereo   = $any_tag->{type};
      my $ratecode = $any_tag->{rate};

      if ($format != 2)
      {
         die 'Only MP3 audio supported so far...';
      }

      (my $rate = $AUDIO_RATES{$ratecode}) =~ s/\D//gxms;
      my $bytes_per_sample = ($stereo ? 2 : 1) * ($any_tag->{size} ? 2 : 1);

      my $needsamples  = int 0.001 * $start * $rate;
      my $startsamples = $self->{audsamples};

      while (@{ $flvinfo->{audtags} }
         && ($islast || $self->{audsamples} < $needsamples))
      {
         my $atag = shift @{ $flvinfo->{audtags} };
         $data .= $atag->{data};
         $self->{audsamples} = $self->_round_to_samples(
            @{ $flvinfo->{audtags} }
            ? 0.001 * $flvinfo->{audtags}->[0]->{start} * $rate
            : 1_000_000_000
         );
      }
      if (0 < length $data)
      {
         my $samples = $self->{audsamples} - $startsamples;

         my $seek = $startsamples ? int $needsamples - $startsamples : 0;

         # signed -> unsigned conversion
         $seek = unpack 'S', pack 's', $seek;

         my $head = pack 'vv', $samples, $seek;
         SWF::Element::Tag::SoundStreamBlock->new(
            StreamSoundData => $head . $data)->pack($swf);
      }
   }
   return;
}

sub _flvinfo
{
   my $self = shift;

   my %flvinfo = (
      duration  => $self->{flv}->get_meta('duration')     || 0,
      vcodec    => $self->{flv}->get_meta('videocodecid') || 0,
      acodec    => $self->{flv}->get_meta('audiocodecid') || 0,
      width     => $self->{flv}->get_meta('width')        || 320,
      height    => $self->{flv}->get_meta('height')       || 240,
      framerate => $self->{flv}->get_meta('framerate')    || 12,
      vidbytes  => 0,
      audbytes  => 0,
      vidtags   => [],
      audtags   => [],
   );
   $flvinfo{swfversion} = $flvinfo{vcodec} >= 4 ? 8 : 6;

   if ($self->{flv}->{body})
   {
      for my $tag ($self->{flv}->{body}->get_tags())
      {
         if ($tag->isa('FLV::VideoTag'))
         {
            push @{ $flvinfo{vidtags} }, $tag;
            $flvinfo{vidbytes} += length $tag->{data};
         }
         elsif ($tag->isa('FLV::AudioTag'))
         {
            push @{ $flvinfo{audtags} }, $tag;
            $flvinfo{audbytes} += length $tag->{data};
         }
      }
   }

   return \%flvinfo;
}

sub _startswf
{
   my $self    = shift;
   my $flvinfo = shift;

   # SWF header
   my $twp = 20;               # 20 twips per pixel
   my $swf = SWF::File->new(
      undef,
      Version => $flvinfo->{swfversion},
      FrameSize =>
          [0, 0, $twp * $flvinfo->{width}, $twp * $flvinfo->{height}],
      FrameRate => $flvinfo->{framerate},
   );

   ## Populate the SWF

   # Generic stuff...
   my $bg = $self->{background_color};
   SWF::Element::Tag::SetBackgroundColor->new(
      BackgroundColor => [
         Red   => $bg->[0],
         Green => $bg->[1],
         Blue  => $bg->[2],
      ],
   )->pack($swf);

   # Add the audio stream header
   if (@{ $flvinfo->{audtags} })
   {
      my $tag = $flvinfo->{audtags}->[0];
      (my $arate = $AUDIO_RATES{ $tag->{rate} }) =~ s/\D//gxms;
      SWF::Element::Tag::SoundStreamHead->new(
         StreamSoundCompression => $tag->{format},
         PlaybackSoundRate      => $tag->{rate},
         StreamSoundRate        => $tag->{rate},
         PlaybackSoundSize      => $tag->{size},
         StreamSoundSize        => $tag->{size},
         PlaybackSoundType      => $tag->{type},
         StreamSoundType        => $tag->{type},
         StreamSoundSampleCount => $arate / $flvinfo->{framerate},
      )->pack($swf);
   }

   # Add the video stream header
   if (@{ $flvinfo->{vidtags} })
   {
      my $tag = $flvinfo->{vidtags}->[0];
      SWF::Element::Tag::DefineVideoStream->new(
         CharacterID => 1,
         NumFrames   => scalar @{ $flvinfo->{vidtags} },
         Width       => $flvinfo->{width},
         Height      => $flvinfo->{height},
         VideoFlags  => 1,                                 # Smoothing on
         CodecID     => $tag->{codec},
      )->pack($swf);
   }

   return $swf;
}

sub _round_to_samples
{
   my $pkg_or_self = shift;
   my $samples     = shift;

   return 576 * int $samples / 576 + 0.5;
}

1;

__END__

=back

=head1 AUTHOR

See L<FLV::Info>

=cut
