package Image::ValidJpeg;

use 5.006002;
use strict;
use warnings;
use Carp;

require Exporter;

our $VERSION = '1.002001';

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Image::ValidJpeg ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 
    all => [ qw(
check_tail
check_jpeg
check_all
GOOD
BAD
SHORT
EXTRA
) ], 

constants => [ qw(
GOOD
BAD
SHORT
EXTRA
) ],

);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT;


require XSLoader;
XSLoader::load('Image::ValidJpeg', $VERSION);

__END__

=head1 NAME

Image::ValidJpeg - Perl extension for validating JPEG files.

=head1 SYNOPSIS

 use Image::ValidJpeg;

 open $fh, 'FILE.jpg';

 if( Image::ValidJpeg::check_jpeg($fh) ) {
    print "FILE.jpg is bad\n";
 }

=head1 DESCRIPTION

This module parses JPEG files to look for errors, such as truncated files.

The methods return 0 if the file is valid, nonzero if an error is detected.

=head2 METHODS

=over

=item B<check_tail>(I<$fh>)

Look for an end of image marker in the last few bytes of I<$fh>.  

This is slightly faster than I<check_jpeg> and should catch most truncated
images, unless they happen to be truncated at the end of an embedded JPEG.

=item B<check_jpeg>(I<$fh>)

Scan through the basic structure of the file, validating that it is correct,
until it gets to the main image data.  Then, look for an end of image marker
in the last few bytes of I<$fh>.  

This can detect some problems that I<check_tail> cannot, without being
noticeably slower, making it useful for scanning a large number of image
files.

=item B<check_all>(I<$fh>)

Scan through the basic structure of the file, validating that it is correct;
also scan the main image data byte by byte.  Verify that the file ends with
end of image marker in the last few bytes of I<$fh>.  

This it the most thorough method, but also the slowest, so it's
useful for checking a small number of images.  It's the only one that can
differentiate between a bad image and a valid image with extra data
appended, or between a valid jpeg and two jpegs concatenated together.

=back

=head2 CONSTANTS

The following contants are defined, to match the return values of the
validation functions:

=over

=item B<GOOD>

Returned for a valid JPEG.  This is guaranteed to be 0.

=item B<SHORT>

Returned if we ran out of data before the end marker was found (i.e. a
truncated file).  Can only be returned by I<check_all>, since we can't
detect this condition without fully parsing the file.

=item B<EXTRA>

Returned if the jpeg was otherwsie valid, there was more data in the file
after the end marker was found.  Can only be returned by I<check_all>, since
we can't detect this condition without fully parsing the file.

=item B<BAD>

Returned if validation failed for other reasons, such as an invalid marker.
Errors from I<check_jpeg> always return I<BAD>.

=back

=head2 EXPORT

None by default.

The I<check_*> methods and constants can be imported individually, or they
call all be imported via the I<':all'> tag.

=head1 AUTHOR

Steve Sanbeg

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Steve Sanbeg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
