=head1 NAME

FFmpeg::Stream::Video - A video stream from a (multi)media stream group.

=head1 SYNOPSIS

  $ff = FFmpeg->new();             #see FFmpeg
  #...
  $sg = $ff->create_streamgroup(); #see FFmpeg
  $st = ($sg->streams())[0];       #this is a FFmpeg::Stream

=head1 DESCRIPTION

Objects of this class are not intended to be
instantiated directly by the end user.  Access
L<FFmpeg::Stream::Video|FFmpeg::Stream::Video> objects using methods in
L<FFmpeg::StreamGroup|FFmpeg::StreamGroup>.  See
L<FFmpeg::StreamGroup> for more information.

This class represents a video stream in a multimedia stream group.
General stream attributes can be found in the
L<FFmpeg::Stream|FFmpeg::Stream> class.


=head1 FEEDBACK

See L<FFmpeg/FEEDBACK> for details.

=head1 AUTHOR

Allen Day E<lt>allenday@ucla.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003-2004 Allen Day

This library is released under GPL, the Gnu Public License

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a '_'.  Methods are
in alphabetical order for the most part.

=cut


# Let the code begin...


package FFmpeg::Stream::Video;
use strict;
use base qw(FFmpeg::Stream);
our $VERSION = '0.01';

=head2 new()

This class inherits from L<FFmpeg::Stream|FFmpeg::Stream>.  See
L<FFmpeg::Stream/new()|FFmpeg::Stream::new()>

=cut

=head2 init()

This class inherits from L<FFmpeg::Stream|FFmpeg::Stream>.  See
L<FFmpeg::Stream/init()|FFmpeg::Stream::init()>

=cut

=head2 video_rate()

=over

=item Usage

 $obj->video_rate();        #get existing value

=item Function

video rate (frame rate) in frames/second.  this only applies to video streams

=item Returns

value of video_rate (a scalar)

=item Arguments

none, read-only

=back

=cut

sub video_rate {
  my $self = shift;
  return $self->{'video_rate'};
}


=head2 height()

=over

=item Usage

  $obj->height(); #get existing value

=item Function

height of the stream, in pixels

=item Returns

value of height (a scalar)

=item Arguments

none, read-only

=back

=cut

sub height {
  my $self = shift;

  return $self->{'height'};
}

=head2 quality()

=over

=item Usage

  $obj->quality(); #get existing value

=item Function

stores a quantitative metric of the video codec "encoding quality".
this is not comparable between different codecs.

=item Returns

value of quality (a scalar)

=item Arguments

none, read-only

=back

=cut

sub quality {
  my $self = shift;

  return $self->{'quality'};
}

=head2 width()

=over

=item Usage

  $obj->width(); #get existing value

=item Function

width of the stream, in pixels

=item Returns

value of width (a scalar)

=item Arguments

none, read-only

=back

=cut

sub width {
  my $self = shift;

  return $self->{'width'};
}

1;
