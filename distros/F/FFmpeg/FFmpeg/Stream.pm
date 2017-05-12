=head1 NAME

FFmpeg::Stream - An audio or video stream from a (multi)media file.

=head1 SYNOPSIS

  $ff = FFmpeg->new();             #see FFmpeg
  #...
  $sg = $ff->create_streamgroup(); #see FFmpeg
  $st = ($sg->streams())[0];       #this is a FFmpeg::Stream

=head1 DESCRIPTION

FFmpeg::Stream objects are not instantiated.  Rather, objects are
instantiated from FFmpeg::Stream's subclasses
L<FFmpeg::Stream::Video|FFmpeg::Stream::Video> for video streams,
L<FFmpeg::Stream::Audio|FFmpeg::Stream::Audio> for audio streams, and
L<FFmpeg::Stream::Data|FFmpeg::Stream::Data> for streams containing
neither audio nor video data.  Streams identified in the file whose
content type cannot be determined are represented by
L<FFmpeg::Stream::Unknown|FFmpeg::Stream::Unknown> objects.

Access L<FFmpeg::Stream|FFmpeg::Stream> objects using methods in
L<FFmpeg::StreamGroup|FFmpeg::StreamGroup>.  See
L<FFmpeg::StreamGroup> for more information.

This class has attributes applicable to any stream type in a
multimedia stream, or stream group.  B<FFmpeg-Perl> represents multimedia
stream group information in a L<FFmpeg::StreamGroup|FFmpeg::StreamGroup>
object, which is a composite of L<FFmpeg::Stream|FFmpeg::Stream>
objects.

L<FFmpeg::Stream|FFmpeg::Stream> objects don't do much.  They just
keep track of the media stream's ID within the multimedia stream group, and
hold an instance to a L<FFmpeg::Codec|FFmpeg::Codec> object if the
codec of the stream was deducible.  See L<FFmpeg::Codec> for more
information about how codecs are represented.

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


package FFmpeg::Stream;
use strict;
use base qw();
our $VERSION = '0.01';

=head2 new()

=over

=item Usage

my $obj = new L<FFmpeg::Stream|FFmpeg::Stream>();

=item Function

Builds a new L<FFmpeg::Stream|FFmpeg::Stream> object

=item Returns

an instance of L<FFmpeg::Stream|FFmpeg::Stream>

=item Arguments

=over

=item fourcc (optional)

the four-character-code of the stream's codec.  this is
not used in any way by FFmpeg.

=item codec (optional)

a L<FFmpeg::Codec|FFmpeg::Codec> object used to decode this stream.
currently this is only used for decoding purposes, but
when transcoding/encoding is implemented in
B<FFmpeg-Perl>, this will be used to set an encoding codec.

=item codec_tag (optional)

fourcc converted to an unsigned int.

=back

=back

=cut

sub new {
  my($class,%arg) = @_;

  my $self = bless {}, $class;
  $self->init(%arg);

  return $self;
}

=head2 init()

=over

=item Usage

$obj->init(%arg);

=item Function

Internal method to initialize a new L<FFmpeg::Stream|FFmpeg::Stream> object

=item Returns

true on success

=item Arguments

Arguments passed to new

=back

=cut

sub init {
  my($self,%arg) = @_;

  foreach my $arg (keys %arg){
    $self->{$arg} = $arg{$arg};
  }

  return 1;
}

=head2 bit_rate()

=over

=item Usage

 $obj->bit_rate();        #get existing value

=item Function

average bit rate of stream, in bits/second.

=item Returns

value of bit_rate (a scalar)

=item Arguments

none, read-only

=item Notes

There are sticky issues here, please refer to
L<FFmpeg::StreamGroup/bit_rate()> for details.

=back

=cut

sub bit_rate {
  my $self = shift;
  return $self->{'bit_rate'};
}

=head2 bit_rate_tolerance()

=over

=item Usage

 $obj->bit_rate_tolerance();        #get existing value

=item Function

variance, essentially, of L</bit_rate()|bit_rate()>.

=item Returns

value of bit_rate_tolerance (a scalar)

=item Arguments

none, read-only

=back

=cut

sub bit_rate_tolerance {
  my $self = shift;
  return $self->{'bit_rate_tolerance'};
}

=head2 codec()

=over

=item Usage

 $obj->codec();        #get existing FFmpeg::Codec
 $obj->codec($newval); #set new FFmpeg::Codec

=item Function


=item Returns

an object of class L<FFmpeg::Codec|FFmpeg::Codec>

=item Arguments

(optional) on set, an object of class L<FFmpeg::Codec|FFmpeg::Codec>

=back

=cut

sub codec {
  my($self,$obj) = @_;

  if(defined($obj)){
    $self->throw($obj . "must be or inherit from FFmpeg::Codec, but does not")
      unless ref($obj) and $obj->isa('FFmpeg::Codec');
    $self->{'codec'} = $obj;
  }
  return $self->{'codec'};
}

=head2 codec_tag()

=over

=item Usage

 $obj->codec_tag();        #get existing value

 $obj->codec_tag($newval); #set new value

=item Function

store the codec tag associated with the stream.  this
is similar to the value of fourcc(), but is an unsigned
int conversion of the fourcc.  this attribute is not used
in any way.

=item Returns

value of codec_tag (a scalar)

=item Arguments

none, read-only

=back

=cut

sub codec_tag {
  my $self = shift;
  return $self->{'codec_tag'};
}


=head2 duration()

=over

=item Usage

  $obj->duration(); #get existing value
  $obj->duration(format=>'HMS'); #get existing value in HH::MM::SS format

=item Function

duration of stream in seconds.  a stream may not have the
same duration as its L<FFmpeg::StreamGroup|FFmpeg::StreamGroup>
container.

=item Returns

value of duration (a float), or a formatted time string.

=item Arguments

none, read-only

=back

=cut

sub duration {
  my $self = shift;
  my %arg = @_;

  if(defined($arg{format})){
    if($arg{format} eq 'HMS'){
      return $self->_ffmpeg->format_duration_HMS($self->{'duration'});
    }
  }

  return $self->{'duration'};
}

=head2 fourcc()

=over

=item Usage

 $obj->fourcc();        #get existing value

=item Function

stores the fourcc (four character code) of the stream's codec

=item Returns

value of fourcc (a scalar)

=item Arguments

none, read-only

=back

=cut

sub fourcc {
  my $self = shift;
  return $self->{'fourcc'};
}

=head2 start_time()

=over

=item Usage

  $obj->start_time(); #get existing value

=item Function

start time of stream in seconds.  a stream may not begin
at the same time as its L<FFmpeg::StreamGroup|FFmpeg::StreamGroup>
container.

=item Returns

value of start_time (a float)

=item Arguments

none, read-only

=back

=cut

sub start_time {
  my $self = shift;

  return $self->{'start_time'};
}

1;
