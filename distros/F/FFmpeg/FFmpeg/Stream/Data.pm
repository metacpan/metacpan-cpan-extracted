=head1 NAME

FFmpeg::Stream::Data - A non-media data stream from a (multi)media file.

=head1 SYNOPSIS

  $ff = FFmpeg->new();             #see FFmpeg
  #...
  $sg = $ff->create_streamgroup(); #see FFmpeg
  $st = ($sg->streams())[0];       #this is a FFmpeg::Stream

=head1 DESCRIPTION

Objects of this class are not intended to be
instantiated directly by the end user.  Access
L<FFmpeg::Stream|FFmpeg::Stream> objects using methods in
L<FFmpeg::StreamGroup|FFmpeg::StreamGroup>.  See
L<FFmpeg::StreamGroup> for more information.

This class represents a media stream in a multimedia
file.  B<FFmpeg-Perl> represents multimedia file
information in a L<FFmpeg::StreamGroup|FFmpeg::StreamGroup> object, which is
a composite of L<FFmpeg::Stream|FFmpeg::Stream> objects.

L<FFmpeg::Stream|FFmpeg::Stream> objects don't do much.  They just keep
track of the media stream's ID within the multimedia
file, and hold an instance to a L<FFmpeg::Codec|FFmpeg::Codec> object
if the codec of the stream was deducible.  See
L<FFmpeg::Codec> for more information about how
codecs are represented.

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


package FFmpeg::Stream::Data;
use strict;
use base qw(FFmpeg::Stream);
our $VERSION = '0.01';

=head1 Note

This is currently an unused, empty class.

=cut

=head2 new()

This class inherits from L<FFmpeg::Stream|FFmpeg::Stream>.  See
L<FFmpeg::Stream/new()|FFmpeg::Stream::new()>

=cut

=head2 init()

This class inherits from L<FFmpeg::Stream|FFmpeg::Stream>.  See
L<FFmpeg::Stream/init()|FFmpeg::Stream::init()>

=cut

1;
