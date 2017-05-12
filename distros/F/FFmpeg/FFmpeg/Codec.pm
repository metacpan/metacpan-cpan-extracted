=head1 NAME

FFmpeg::Codec - A media stream (co)mpression / (dec)ompression algorithm

=head1 SYNOPSIS

  $codec = FFmpeg->codec('msmpeg4');

  #or perhaps
  $ff = FFmpeg->new();
  #...
  $sg = $ff->create_streamgroup(); #see FFmpeg::StreamGroup
  $st = ($sg->streams())[0];       #see FFmpeg::Stream
  $codec = $st->codec

=head1 DESCRIPTION

Objects of this class are not intended to be
instantiated directly by the end user.  Access
L<FFmpeg::Codec|FFmpeg::Codec> objects using methods in
the L<FFmpeg|FFmpeg> class.

Instances of this class represent a compression/decompression
algorithm, or codec, that is supported by B<FFmpeg-C>.  Audio and
video streams use separate codecs.  If a codec exists, it means
that B<FFmpeg-C> can use it to do at least one of:

=over

=item read audio or video in the codec's format

=item write audio or video in the codec's format

=back

Call L</can_read()> and L</can_write()> to see what functionality
is supported for a given codec.  Call L</is_video()> and L</is_audio()>
to determine if a codec is capable of encoding/decoding audio or video.

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


package FFmpeg::Codec;
use strict;
use base qw();
our $VERSION = '0.01';

=head2 new()

=over

=item Usage

my $obj = new L<FFmpeg::Codec|FFmpeg::Codec>();

=item Function

Builds a new L<FFmpeg::Codec|FFmpeg::Codec> object

=item Returns

an instance of L<FFmpeg::Codec|FFmpeg::Codec>

=item Arguments

All optional, refer to the documentation of L<FFmpeg/new()>, this constructor
operates in the same way.

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

Internal method to initialize a new L<FFmpeg::Codec|FFmpeg::Codec> object

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

=head2 can_read()

=over

=item Usage

$obj->can_read(); #get existing value

=item Function

B<FFmpeg-C> can decode this codec?

=item Returns

a boolean

=item Arguments

none, read-only

=back

=cut

sub can_read {
  my $self = shift;

  return $self->{'can_read'};
}

=head2 can_write()

=over

=item Usage

$obj->can_write(); #get existing value

=item Function

B<FFmpeg-C> can encode this codec?

=item Returns

a boolean

=item Arguments

none, read-only

=back

=cut

sub can_write {
  my $self = shift;

  return $self->{'can_write'};
}

=head2 id()

=over

=item Usage

$obj->id(); #get existing value

=item Function

B<FFmpeg-C>'s internal ID for this codec

=item Returns

value of id (a scalar)

=item Arguments

none, read-only

=back

=cut

sub id {
  my $self = shift;

  return $self->{'id'};
}

=head2 is_audio()

=over

=item Usage

$obj->is_audio(); #get existing value

=item Function

does this codec encode/decode audio streams?

=item Returns

a boolean

=item Arguments

none, read-only

=back

=cut

sub is_audio {
  my $self = shift;

  return $self->{'is_audio'};
}

=head2 is_video()

=over

=item Usage

$obj->is_video(); #get existing value

=item Function

does this codec encode/decode video streams?

=item Returns

a boolean

=item Arguments

none, read-only

=back

=cut

sub is_video {
  my $self = shift;
  return $self->{'is_video'};
}

=head2 name()

=over

=item Usage

$obj->name(); #get existing value

=item Function

codec's name

=item Returns

value of name (a scalar)

=item Arguments

none, read-only

=back

=cut

sub name {
  my $self = shift;

  return $self->{'name'};
}

1;
