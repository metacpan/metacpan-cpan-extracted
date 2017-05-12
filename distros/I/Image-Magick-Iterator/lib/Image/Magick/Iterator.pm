=head1 NAME

Image::Magick::Iterator - sequentially read Image::Magick object from
a filehandle.

=head1 SYNOPSIS

  use strict;
  use Image::Magick::Iterator;

  my $iter = Image::Magick::Iterator->new();

  #assume PPM stream is coming from STDIN;
  $iter->handle(\*STDIN);

  #explicitly set format to PPM, there is no auto-detection built in
  $iter->format('PPM');

  while(my $image = $iter->next){
    print $image->Get('height'),"\n"; #access height attribute of each
                                      #Image::Magick object
  }

=head1 DESCRIPTION

Image::Magick::Iterator adds iteration support to
L<Image::Magick|Image::Magick>.  This means that if you have a stream
of concatenated images, you can access each image in the stream as an
independent L<Image::Magick|Image::Magick> object.

Iteration functionality is not present in
L<Image::Magick|Image::Magick> itself as of version 5.56.  Passing a
stream of concatenated images would result in essentially a "stack" of
images which would all be manipulated in parallel by any
L<Image::Magick|Image::Magick> calls.  Calls to Write() either output
an animated series of image (a la animated GIFs), or the first image
in the series.

Image::Magick::Iterator is extensible to support many different image
filetypes.  Currently only PPM support is implemented.  See
L</SYNOPSIS|SYOPSIS> for an example.

=head1 SUPPORTED FORMATS

Currently only PPM images can be iterated.  It's not difficult to add
new image types though, and I'm receptive to new classes for handling
more formats.  To add another format:

1. Have a look at the source of
L<Image::Magick::Iterator::PPM|Image::Magick::Iterator::PPM> to get an
idea of how to write a new format handling class.  It is basically a
class with one method, B<read_image>, that when given a filehandle
reference reads an image from it and passes back the raw data.

2. add a mapping to L</_delegate()> that maps the desired value of
L</format()> to your image reading class.

=head1 FEEDBACK

Email the author.

=head1 AUTHOR

Allen Day E<lt>allenday@ucla.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Allen Day, allenday@ucla.edu

This library is released under GPL, the GNU General Public License

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a '_'.  Methods are
in alphabetical order for the most part.

=cut


# Let the code begin...


package Image::Magick::Iterator;
use strict;
use base qw();
our $VERSION = '0.01';

use File::Temp;
use Image::Magick;

=head2 new()

=over

=item Usage

  my $obj = new Image::Magick::Iterator();

=item Function

Builds a new Image::Magick::Iterator object

=item Returns

an instance of Image::Magick::Iterator

=item Arguments

None

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

Internal method to initialize a new Image::Magick::Iterator object

=item Returns

true on success

=item Arguments

Arguments passed to L</new()>

=back

=cut

sub init {
  my($self,%arg) = @_;

  foreach my $arg (keys %arg){
    $self->$arg($arg{$arg}) if $self->can($arg);
  }

  return 1;
}

=head2 format()

=over

=item Usage

  $obj->format();        #get existing value

  $obj->format($newval); #set new value

=item Function

stores a scalar value of the fileformat to be read from
L</handle()>. currently supported formats are:

  * PPM

=item Returns

value of format (a scalar)

=item Arguments

(optional) on set, a scalar

=back

=cut

sub format {
  my($self,$val) = @_;
  $self->{'format'} = $val if defined($val);
  return $self->{'format'};
}

=head2 handle()

=over

=item Usage

  $obj->handle();        #get existing value

  $obj->handle($newval); #set new value

=item Function

stores a filehandle reference (eg \*STDIN, or an
L<IO::Handle|IO::Handle>.

=item Returns

value of handle (a scalar)

=item Arguments

(optional) on set, a scalar

=back

=cut

sub handle {
  my($self,$val) = @_;
  $self->{'handle'} = $val if defined($val);
  return $self->{'handle'};
}

=head2 next()

=over

=item Usage

  $obj->next(); #get next Image::Magick from stream

=item Function

reads an L<Image::Magick|Image::Magick> object from a filehandle.

=item Returns

a L<Image::Magick|Image::Magick> object, or undef if the filehandle is
EOF or contains only a partial image.

=item Arguments

none, read-only

=back

=cut

sub next {
  my $self = shift;

  my $image = undef;

  my $delegate = $self->_delegate($self->format());

  eval "require $delegate";
  if($@){ die "couldn't load delegate class '$delegate': $@" }

  my $raw = $delegate->read_image($self->handle);

  return undef unless $raw;

  my $tmp = File::Temp->new(UNLINK => 1);
  print $tmp $raw;

  $image = Image::Magick->new();

  close($tmp);

  open(IN,"$tmp");
  $image->Read(file => \*IN);
  close(IN);

  return $image;
}

=head2 _delegate()

=over

=item Usage

  $obj->_delegate($format);

=item Function

internal method, maps format names to class names

=item Returns

class to be delegated to for reading an image of the specified format

=item Arguments

name of an image format

=back

=cut

sub _delegate {
  my ($self,$format) = @_;

  my %map = (
             PPM => 'Image::Magick::Iterator::PPM',
            );

  return $map{$format};
}


1;
