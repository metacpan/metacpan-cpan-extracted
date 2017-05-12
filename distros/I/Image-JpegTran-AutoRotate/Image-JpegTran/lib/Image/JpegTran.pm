package Image::JpegTran;

use 5.008008;
use strict;
use warnings;
use base 'Exporter';
use Carp;

our @EXPORT_OK = our @EXPORT = qw( jpegtran );
our $VERSION = '0.02';

use XSLoader;
XSLoader::load('Image::JpegTran', $VERSION);

sub jpegtran($$;%) {
	my $src = shift;
	-e( $src ) or croak "Can't find source file `$src'";
	my $dst = shift;
	# TODO: more sugar options
	my %args = (
		@_==1 && ref $_[0] ? %{$_[0]} : @_
	);
	_jpegtran($src,$dst,\%args);
}


1;
__END__
__END__
=head1 NAME

Image::JpegTran - XS wrapper around lossless JPEG transformation utility - jpegtran

=head1 SYNOPSIS

    use Image::JpegTran;
    
    jpegtran 'source.jpg','result.jpg', rotate => 90, trim => 1, perfect => 1;
    jpegtran 'source.jpg','result.jpg', transpose => 1;
    jpegtran 'source.jpg','result.jpg', transverse => 1;
    jpegtran 'source.jpg','result.jpg', flip => 'horizontal';

=head1 DESCRIPTION

Use lossless jpeg transformations, like when using C<jpegtran> utility, from Perl

=head1 OPTIONS

=over4

=item copy => 'none'

Copy no extra markers from source file

=item copy => 'comments'

Copy only comment markers

=item copy => 'all'

Copy all extra markers (comments and EXIF) (default)

=item optimize => 0 | 1

Optimize Huffman table (smaller file, but slow compression), default = 0

=item progressive => 0 | 1

Create progressive JPEG file (default = 0)

=item grayscale => 0 | 1

Reduce to grayscale (omit color data) (default = 0)

=item flip => 'horizontal' | 'vertical'

Mirror image (left-right or top-bottom)

=item rotate => 90 | 180 | 270

Rotate image (degrees clockwise)

=item transpose => 1

Transpose image

=item transverse => 1

Transverse transpose image

=item trim => 1

Drop non-transformable edge blocks or

=item perfect

Fail if there is non-transformable edge blocks

=item maxmemory => N

Maximum memory to use (in kbytes)

=item arithmetic => 1

Use arithmetic coding

=back

=for todo

  -restart N     Set restart interval in rows, or in blocks with B
  -verbose  or  -debug   Emit debug output
  -scans file    Create multi-scan JPEG per script file

=head1 AUTHOR

Mons Anderson, E<lt>mons@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

The main part of this module is copyright (C) 1991-2010

The Independent JPEG Group's JPEG software

Thomas G. Lane, Guido Vollbeding.

See README.IJG

=cut
