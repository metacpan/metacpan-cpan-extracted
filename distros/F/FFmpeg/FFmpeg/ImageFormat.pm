=head1 NAME

FFmpeg::ImageFormat - Image formats supported by FFmpeg's image codecs.

=head1 SYNOPSIS

  $ff = FFmpeg->new(); #see FFmpeg
  $if = $ff->image_format('jpeg');
  #...do something with $if

=head1 DESCRIPTION

Objects of this class are not intended to be
instantiated directly by the end user.  Access
L<FFmpeg::ImageFormat|FFmpeg::ImageFormat> objects using L<FFmpeg/image_format()>
or L<FFmpeg/image_formats()>.

Instances of this class represent a image formats supported by
B<FFmpeg-C>.  If an image format exists, it means that
B<FFmpeg-C> can use it to do at least one of:

=over

=item convert a series of images of that type into
a video stream

=item convert a video stream into a series of images
of that type

=back

Call L</can_read()> and L</can_write()> to see what
functionality is supported for a given image format.

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


package FFmpeg::ImageFormat;
use strict;
use base qw();
our $VERSION = '0.01';

=head2 new()

=over

=item Usage

my $obj = new L<FFmpeg::ImageFormat|FFmpeg::ImageFormat>();

=item Function

Builds a new L<FFmpeg::ImageFormat|FFmpeg::ImageFormat> object

=item Returns

an instance of L<FFmpeg::ImageFormat|FFmpeg::ImageFormat>

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

Internal method to initialize a new L<FFmpeg::ImageFormat|FFmpeg::ImageFormat> object

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

B<FFmpeg-C> can use this format for input?

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

B<FFmpeg-C> can use this format for output?

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

=head2 name()

=over

=item Usage

$obj->name(); #get existing value

=item Function

image format's name

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
