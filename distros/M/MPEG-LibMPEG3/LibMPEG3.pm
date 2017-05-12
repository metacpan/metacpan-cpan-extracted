#!/usr/bin/perl -w

package MPEG::LibMPEG3;
use strict;
require DynaLoader;
our @ISA = qw(DynaLoader);
bootstrap MPEG::LibMPEG3;

##------------------------------------------------------------------------
## Be careful running swig on libmpeg3.i because it will trash this
## module. :)  The dynamic loading above is from SWIG, everything else is
## from me.
##------------------------------------------------------------------------
our $VERSION = 0.01;
1;

##------------------------------------------------------------------------
## Override superclass constructor
##------------------------------------------------------------------------
sub new {
    my $proto = shift;
    my $class = ref( $proto ) || $proto;
    my $self = { 'filename' => scalar @_ == 1 ? shift : undef,
		 @_, };
    bless( $self, $class );

    $self->probe if defined $self->{filename};
    
    return $self;
}

##------------------------------------------------------------------------
## Probe
##------------------------------------------------------------------------
sub probe {
    my $self     = shift;
    my $filename = shift || $self->{filename};

    if ( !defined $filename || !-e $filename  ) { 
	return 0;
    }

    if ( !mpeg3_check_sig( $filename ) ) {
	return 0;
    }

    if ( !defined $self->{file} ) {
	## print "case1\n";
        $self->{file} = mpeg3_open( $filename );
    }
    else {
	## print "case2\n";
        $self->close_movie();
	$self->{file} = mpeg3_open_copy( $filename, $self->{file} );
    }
    return $self->{file};
}

##------------------------------------------------------------------------
## close_movie()
##
## Close the mpeg_t file object.
##------------------------------------------------------------------------
sub close_movie { my $self = shift; mpeg3_close( $self->{file} ) if defined $self->{file} }

sub has_audio   { my $self = shift; !$self->{file} ? 0 : return $self->mpeg3_has_audio }
sub has_video   { my $self = shift; !$self->{file} ? 0 : return $self->mpeg3_has_video }

##------------------------------------------------------------------------
## Performance
##------------------------------------------------------------------------
sub set_cpus    { my $self = shift; !$self->{file} ? 0 : return mpeg3_set_cpus( $self->{file}, shift || 1 ) }
sub set_mmx     { my $self = shift; !$self->{file} ? 0 : return  mpeg3_set_mmx( $self->{file}, shift || 1 ) }

##------------------------------------------------------------------------
## Audio
##------------------------------------------------------------------------
sub astreams    { my $self = shift; !$self->{file} ? 0 : return mpeg3_total_astreams( $self->{file} )             }
sub achans      { my $self = shift; !$self->{file} ? 0 : return mpeg3_audio_channels( $self->{file}, shift || 0 ) }
sub arate       { my $self = shift; !$self->{file} ? 0 : return mpeg3_sample_rate   ( $self->{file}, shift || 0 ) } 
sub acodec      { my $self = shift; !$self->{file} ? 0 : return mpeg3_audio_format  ( $self->{file}, shift || 0 ) }

##------------------------------------------------------------------------
## Video
##------------------------------------------------------------------------
sub vstreams    { my $self = shift; !$self->{file} ? 0 : return mpeg3_total_vstreams( $self->{file} )             }
sub width       { my $self = shift; !$self->{file} ? 0 : return mpeg3_video_width ( $self->{file}, shift || 0 )   }
sub height      { my $self = shift; !$self->{file} ? 0 : return mpeg3_video_height( $self->{file}, shift || 0 )   }
sub aspect      { my $self = shift; !$self->{file} ? 0 : return mpeg3_aspect_ratio( $self->{file}, shift || 0 )   }
sub fps         { my $self = shift; !$self->{file} ? 0 : return mpeg3_frame_rate  ( $self->{file}, shift || 0 )   }
sub vframes     { my $self = shift; !$self->{file} ? 0 : return mpeg3_video_frames( $self->{file}, shift || 0 )   }
sub colormodel  { my $self = shift; !$self->{file} ? 0 : return mpeg3_colormodel  ( $self->{file}, shift || 0 )   }

##------------------------------------------------------------------------
## Duration
##------------------------------------------------------------------------
sub aduration   { my $self = shift; my $stream = shift || 0; 
		  return mpeg3_audio_samples( $self->{file}, $stream ) / $self->arate( $stream ); }

sub vduration   { my $self = shift; my $stream = shift || 0; 
		  return mpeg3_video_frames ( $self->{file}, $stream ) / $self->fps  ( $stream ); }

sub duration    { my $self = shift; return 0 if !$self->{file};
		  return $self->vstreams ? $self->vduration( shift ) : $self->aduration( shift ); }

sub get_yuv         { my $self = shift; return get_yuvframe( $self->{file}, $self->width, $self->height ) }
sub seek_percentage { my $self = shift; return mpeg3_seek_percentage( $self->{file}, shift ) }
sub drop_frames     { my $self = shift; return mpeg3_drop_frames( $self->{file}, shift, shift ) };
sub set_frame       { my $self = shift; return mpeg3_set_frame( $self->{file}, shift, shift ) };

##------------------------------------------------------------------------
## Make sure to close the file when we're done with it.  
## Are there any unforseen problems with doing this?
##------------------------------------------------------------------------
#sub DESTROY {
#    my $self = shift;
#    $self->close_movie;
#}

__END__

=head1 NAME

MPEG::LibMPEG3 - Perl interface to libmpeg3 module

=head1 SYNOPSIS

  use strict;
  use MPEG::LibMPEG3;

  my $mpeg = MPEG::LibMPEG3->new( $filename );

  $mpeg->set_cpus(1);   ## I only have 1 cpu but you can put whatever
  $mpeg->set_mmx(1);    ## but it has mmx instructions

  printf "Audio Streams: %d\n", $mpeg->astreams;
  for ( 0..$mpeg->astreams() - 1 ) {
      print  "  Stream #$_\n";
      printf "\tachans  : %d\n", $mpeg->achans( $_ );
      printf "\tarate   : %d\n", $mpeg->arate( $_ );
      printf "\taformat : %s\n", $mpeg->acodec( $_ );
      printf "\tduration: %0.2f\n", $mpeg->aduration( $_ );
      print "\n";
  }

  printf "Video Streams: %d\n", $mpeg->vstreams;
  for ( 0..$mpeg->vstreams() - 1 ) {
      print  "  Stream #$_\n";
      printf "\tWidth        : %d\n"   , $mpeg->width( $_ );
      printf "\tHeight       : %d\n"   , $mpeg->height( $_ );
      printf "\tAspect Ratio : %d\n"   , $mpeg->aspect( $_ );
      printf "\tFrame Rate   : %0.2f\n", $mpeg->fps( $_ );
      printf "\tTotal Frames : %d\n"   , $mpeg->vframes( $_ );
      printf "\tColor Model  : %d\n"   , $mpeg->colormodel( $_ );
      printf "\tDuration     : %0.2f\n", $mpeg->vduration( $_ );

      print "Dumping frames as YUV\n";
      for ( my $i = 0; $i < $mpeg->vframes; $i++ ) {
          my $output_rows = $mpeg->get_yuv;
	  my $frame_yuv   = sprintf( "%s-%05d.yuv", $file, $i );
	  # printf "Opening $frame_yuv\n";
	  print '.';
	  open OUT, "> $frame_yuv" or 
	      die "Can't open file $frame_yuv for output: $!\n";

	  print OUT $output_rows;
	
	  close OUT;

	  if ( $i > 1 && $i % $mpeg->fps($_) == 0 ) {
	      printf " %0.0f sec/s\n", $i/$mpeg->fps($_);
	  }
      }
      printf " %0.2f sec/s\n", $mpeg->duration;  
  }

=head1 DESCRIPTION

The Moving Picture Experts Group (MPEG) is a working group in 
charge of the development of standards for coded representation 
of digital audio and video.

MPEG audio and video clips are ubiquitous but using Perl to 
programmatically collect information about these bitstreams 
has to date been a kludge at best.  

This module uses the libmpeg3 library to parse and extract information
from the bitstraems.  It supports the following types of files:

	MPEG-1 Layer II Audio
	MPEG-1 Layer III Audio
	MPEG-2 Layer III Audio
	MPEG-1 program streams
	MPEG-2 program streams
	MPEG-2 transport streams
	AC3 Audio
	MPEG-2 Video
	MPEG-1 Video
	IFO files
	VOB files

=head1 METHODS

While MPEG::LibMPEG3 uses libmpeg3, the interface has been simplified
for your programming (and viewing) pleasure.  

=over 4

=item new( [ [ filename => ] FILE ] )

Constructor.  Takes an optional filename argument and returns an MPEG::LibMPEG3 object.

=item probe( [( FILE )] )

If a filename wasn't provided to the constructor, it must be passed to
probe.  In this way an MPEG::LibMPEG3 object can be instantiated and probe()
can be called multiple times with different filenames.  

This method calls the libmpeg3 mpeg3_open() or mpeg3_open_copy() function as
appropriate.  Returns an mpeg3_t structure on success.  

=item set_cpus( n )

Optional.  Sets the number of threads to spawn while decoding a bitstream.  If you 
have multiple CPUs, you may benefit by increasing this.  By default, a thread is 
created for each video and audio stream.  

=item set_mmx( n )

If your CPU has MMX instructions, passing a 1 to this method will enable MMX decoding
which may provide faster decoding.  I have not profiled this though I can not think of
a reason it wouldn't work.

=head2 INFORMATIONAL

=item astreams()

Returns the number of audio streams.

=item vstreams()

Returns the number of video streams.

=item has_video()

Returns true if the MPEG has video.

=item has_audio()

Returns true if the MPEG has audio.

=item close_movie()

Closes the currently opened MPEG file.

=back

The following methods take an optional STREAM argument.  If not provided, defaults to the
first stream (0).

=over 4 

=item achans( [ STREAM ] )

Returns the number of channels in an audio stream.

=item arate( [ STREAM ] )

Returns the sampling rate (e.g. 22050, 44100, 48000 )

=item acodec( [ STREAM ] )

Returns the audio codec used to encode the stream.  This is usually either MPEG, AC3, or ''.

=item aduration( [ STREAM ] )

Returns the duration of the audio stream in seconds.

=item width( [ STREAM ] )

Returns the width of the video stream in pixels.

=item height( [ STREAM ] )

Returns the height of the video stream in pixels.

=item aspect( [ STREAM ] )

Returns the aspect ratio of the video stream.  I've only ever seen this return 0.

=item fps( [ STREAM ] )

Returns the number of frames per second as a floating point number.

=item vframes( [ STREAM ] )

Returns the number of frames in the video stream.

=item colormodel( [ STREAM ] )

Returns the color model of the video stream.  This is either
12 for YUV420 or 13 for YUV422.  Never have seen a YUV422.

=item vduration( [ STREAM ] )

Returns the duration of the video stream in seconds.

=item duration( [ STREAM ] )

Returns the video duration if it exists, otherwise the audio duration.

=back

=head2 SEEKING

The follow methods provide absolute or percentage seeking.  Note that once you perform 
one type of seeking, libmpeg3 doesn't let you change to the other method.  

=over 4

=item seek_percentage( n.nn )

Seeks to a percentage of the file.  E.g. 0.50 == 50% of the file.

=item set_frame( FRAME, STREAM )

Seeks to a particular FRAME number of STREAM.

=back

=head2 HOLY GRAIL

And the method everyone has been waiting for... *drumroll*

=over 4

=item get_yuv()

Returns a YUV coded frame.  This is returned as a single scalar though you
can break out the individual planes of the image if you know how a YUV file is 
composed.

  Y plane = width x height
  U plane = width x height / 4
  V plane = width x height / 4


=back

=head1 EXPORT

None.

=head1 AUTHORS

Benjamin R. Ginter, <bginter@asicommunications.com>

=head1 COPYRIGHT

Copyright (c) 2002 Benjamin R. Ginter

=head1 LICENSE

Free for non-commercial use.

=head1 SEE ALSO

L<MPEG::Info>

L<Video::Info>

L<RIFF::Info>

L<ASF::Info>

=cut
