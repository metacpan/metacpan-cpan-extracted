package Image::LibExif;

use 5.006002;
use strict;
use warnings;

our $VERSION = '0.04';

sub import {
	my $me = shift;
	no strict 'refs';
	for (!@_ || $_[0] eq ':all' ? grep {$_ ne 'import' && defined &$_ } keys %Image::LibExif:: : @_) {
		if (defined \&{ $_ }) {
			*{caller().'::image_exif'} = \&image_exif;
		} else {
			require Carp;
			Carp::croak( "$_[0] is not imported from $me" );
		}
	}
}

require XSLoader;
XSLoader::load('Image::LibExif', $VERSION);

1;
__END__
=head1 NAME

Image::LibExif - Read EXIF. Efficiently

=head1 SYNOPSIS

    use Image::LibExif;
    
    my $exif = image_exif("source.jpg");
    if (defined $exif) {
        print Dumper $exif;
    } else {
        print "Exif not found\n";
    }

=head1 DESCRIPTION

Very simple and very fast (about 30 times faster than L<Image::ExifTool>) EXIF extractor, based on libexif.

=head2 EXPORT

image_exif

=head1 SEE ALSO

=over 4

=item * L<Image::ExifTool> - Very powerful EXIF manipulation module, but a bit slow

=item * L<Image::EXIF> - Another EXIF reader, that is an implementation of exiftags in XS. I've encounter a lot segfaults there.

=item * L<Image::JpegTran> - Lossless JPEG transformation utility. XS wrap of jpegtran from libjpeg

=back

=head1 AUTHOR

Mons Anderson <<<mons@cpan.org>>>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Mons Anderson

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself

=cut
