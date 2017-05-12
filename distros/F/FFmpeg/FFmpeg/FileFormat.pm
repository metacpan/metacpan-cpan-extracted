=head1 NAME

FFmpeg::FileFormat - A multimedia file format supported by FFmpeg
(eg avi, mov, mpeg, mp3, &c)

=head1 SYNOPSIS

  $ff = FFmpeg->new(); #see FFmpeg
  $xx = $ff->file_format('mov');
  #...do something with $xx

=head1 DESCRIPTION

Objects of this class are not intended to be
instantiated directly by the end user.  Access
L<FFmpeg::FileFormat|FFmpeg::FileFormat> objects using L<FFmpeg/file_format()>
or L<FFmpeg/filee_formats()>.

Instances of this class represent a file formats supported by
B<FFmpeg-C>.  If a file format exists, it means that
B<FFmpeg-C> can use it to do at least one of:

=over

=item read files of this type

=item write files of this type

=back

Call L</can_read()> and L</can_write()> to see what
functionality is supported for a given file format.

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


package FFmpeg::FileFormat;
use strict;
use base qw();
our $VERSION = '0.01';

=head2 new()

=over

=item Usage

my $obj = new L<FFmpeg::FileFormat|FFmpeg::FileFormat>();

=item Function

Builds a new L<FFmpeg::FileFormat|FFmpeg::FileFormat> object

=item Returns

an instance of L<FFmpeg::FileFormat|FFmpeg::FileFormat>

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

Internal method to initialize a new L<FFmpeg::FileFormat|FFmpeg::FileFormat> object

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

=head2 description()

=over

=item Usage

$obj->description(); #get existing value

=item Function

file format's description (long name)

=item Returns

value of description (a scalar)

=item Arguments

none, read-only

=back

=cut

sub description {
  my $self = shift;

  return $self->{'description'};
}

=head2 mime_type()

=over

=item Usage

$obj->mime_type(); #get existing value

=item Function

MIME type associated with this file type (eg video/mpeg)

=item Returns

value of mime_type (a scalar)

=item Arguments

none, read-only

=back

=cut

sub mime_type {
  my $self = shift;

  return $self->{'mime_type'};
}

=head2 extensions()

=over

=item Usage

$obj->extensions(); #get existing value

=item Function

File extensions (following last '.') associated with format (eg mpg,mpeg)

=item Returns

value of extensions (a list)

=item Arguments

none, read-only

=back

=cut

sub extensions {
  my $self = shift;
  return $self->{'extensions'} ? @{ $self->{'extensions'} } : ();
}

=head2 name()

=over

=item Usage

$obj->name(); #get existing value

=item Function

file format's name

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
