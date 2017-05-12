=head1 NAME

Image::Magick::Iterator::PPM - read PPM images

=head1 DESCRIPTION

Image::Magick::Iterator delegates to this class for
low level image byte read()s.  Don't use this class
directly.

=head1 FEEDBACK

See L<Image::Magick::Iterator>.

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


package Image::Magick::Iterator::PPM;
use strict;
use base qw();
use Image::PBMlib;
our $VERSION = '0.01';

=head2 read_image()

=over

=item Usage

  $obj->read_image($filehandle);

=item Function

reads an image from a filehandle.

=item Returns

raw data for one PPM image.  this is complete,
including header and pixels.

=item Arguments

a filehandle reference

=back

=cut

sub read_image {
  my $pack = shift;
  my $handle = shift;

  my $bytes_per_pixel = 3;

  my $header = readppmheader($handle);

  return undef unless defined($header->{width}) and defined($header->{height});

  my $buf;

  my $rc = read($handle,$buf, $header->{width} * $header->{height} * $bytes_per_pixel);

  return undef unless( $rc == ($header->{width} * $header->{height}) * $bytes_per_pixel);
  return makeppmheader($header).$buf;
}

1;
