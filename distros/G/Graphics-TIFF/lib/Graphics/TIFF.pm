package Graphics::TIFF;

use 5.008005;
use strict;
use warnings;
use Exporter ();
use base qw(Exporter);
use Readonly;
Readonly my $MINOR => 1000;
Readonly my $MICRO => 1_000_000;

# This allows declaration	use Graphics::TIFF ':all';
our %EXPORT_TAGS = (
    'all' => [
        qw(
          TIFFLIB_VERSION

          TIFFTAG_SUBFILETYPE
          FILETYPE_REDUCEDIMAGE
          FILETYPE_PAGE
          FILETYPE_MASK

          TIFFTAG_OSUBFILETYPE
          OFILETYPE_IMAGE
          OFILETYPE_REDUCEDIMAGE
          OFILETYPE_PAGE

          TIFFTAG_IMAGEWIDTH
          TIFFTAG_IMAGELENGTH

          TIFFTAG_BITSPERSAMPLE
          TIFFTAG_COMPRESSION
          COMPRESSION_NONE
          COMPRESSION_CCITTRLE
          COMPRESSION_CCITTFAX3
          COMPRESSION_CCITT_T4
          COMPRESSION_CCITTFAX4
          COMPRESSION_CCITT_T6
          COMPRESSION_LZW
          COMPRESSION_OJPEG
          COMPRESSION_JPEG
          COMPRESSION_T85
          COMPRESSION_T43
          COMPRESSION_NEXT
          COMPRESSION_CCITTRLEW
          COMPRESSION_PACKBITS
          COMPRESSION_THUNDERSCAN
          COMPRESSION_IT8CTPAD
          COMPRESSION_IT8LW
          COMPRESSION_IT8MP
          COMPRESSION_IT8BL
          COMPRESSION_PIXARFILM
          COMPRESSION_PIXARLOG
          COMPRESSION_DEFLATE
          COMPRESSION_ADOBE_DEFLATE
          COMPRESSION_DCS
          COMPRESSION_JBIG
          COMPRESSION_SGILOG
          COMPRESSION_SGILOG24
          COMPRESSION_JP2000
          COMPRESSION_LZMA

          TIFFTAG_PHOTOMETRIC
          PHOTOMETRIC_MINISWHITE
          PHOTOMETRIC_MINISBLACK
          PHOTOMETRIC_RGB
          PHOTOMETRIC_PALETTE
          PHOTOMETRIC_MASK
          PHOTOMETRIC_SEPARATED
          PHOTOMETRIC_YCBCR
          PHOTOMETRIC_CIELAB
          PHOTOMETRIC_ICCLAB
          PHOTOMETRIC_ITULAB
          PHOTOMETRIC_LOGL
          PHOTOMETRIC_LOGLUV

          TIFFTAG_FILLORDER
          FILLORDER_MSB2LSB
          FILLORDER_LSB2MSB

          TIFFTAG_DOCUMENTNAME
          TIFFTAG_IMAGEDESCRIPTION
          TIFFTAG_STRIPOFFSETS

          TIFFTAG_ORIENTATION
          ORIENTATION_TOPLEFT
          ORIENTATION_TOPRIGHT
          ORIENTATION_BOTRIGHT
          ORIENTATION_BOTLEFT
          ORIENTATION_LEFTTOP
          ORIENTATION_RIGHTTOP
          ORIENTATION_RIGHTBOT
          ORIENTATION_LEFTBOT

          TIFFTAG_SAMPLESPERPIXEL
          TIFFTAG_ROWSPERSTRIP
          TIFFTAG_STRIPBYTECOUNTS

          TIFFTAG_XRESOLUTION
          TIFFTAG_YRESOLUTION

          TIFFTAG_PLANARCONFIG
          PLANARCONFIG_CONTIG
          PLANARCONFIG_SEPARATE

          TIFFTAG_GROUP3OPTIONS
          TIFFTAG_T4OPTIONS
          GROUP3OPT_2DENCODING
          GROUP3OPT_UNCOMPRESSED
          GROUP3OPT_FILLBITS

          TIFFTAG_GROUP4OPTIONS
          TIFFTAG_T6OPTIONS
          GROUP4OPT_UNCOMPRESSED

          TIFFTAG_RESOLUTIONUNIT
          RESUNIT_NONE
          RESUNIT_INCH
          RESUNIT_CENTIMETER

          TIFFTAG_PAGENUMBER

          TIFFTAG_TRANSFERFUNCTION

          TIFFTAG_SOFTWARE
          TIFFTAG_DATETIME

          TIFFTAG_ARTIST

          TIFFTAG_PREDICTOR
          PREDICTOR_NONE
          PREDICTOR_HORIZONTAL
          PREDICTOR_FLOATINGPOINT

          TIFFTAG_WHITEPOINT
          TIFFTAG_PRIMARYCHROMATICITIES
          TIFFTAG_COLORMAP

          TIFFTAG_TILEWIDTH
          TIFFTAG_TILELENGTH

          TIFFTAG_INKSET
          INKSET_CMYK
          INKSET_MULTIINK

          TIFFTAG_EXTRASAMPLES
          EXTRASAMPLE_UNSPECIFIED
          EXTRASAMPLE_ASSOCALPHA
          EXTRASAMPLE_UNASSALPHA

          TIFFTAG_SAMPLEFORMAT
          SAMPLEFORMAT_UINT
          SAMPLEFORMAT_INT
          SAMPLEFORMAT_IEEEFP
          SAMPLEFORMAT_VOID
          SAMPLEFORMAT_COMPLEXINT
          SAMPLEFORMAT_COMPLEXIEEEFP

          TIFFTAG_INDEXED
          TIFFTAG_JPEGTABLES

          TIFFTAG_JPEGPROC
          JPEGPROC_BASELINE
          JPEGPROC_LOSSLESS

          TIFFTAG_JPEGIFOFFSET
          TIFFTAG_JPEGIFBYTECOUNT

          TIFFTAG_JPEGLOSSLESSPREDICTORS
          TIFFTAG_JPEGPOINTTRANSFORM
          TIFFTAG_JPEGQTABLES
          TIFFTAG_JPEGDCTABLES
          TIFFTAG_JPEGACTABLES

          TIFFTAG_YCBCRSUBSAMPLING

          TIFFTAG_REFERENCEBLACKWHITE

          TIFFTAG_OPIIMAGEID

          TIFFTAG_COPYRIGHT

          TIFFTAG_EXIFIFD

          TIFFTAG_ICCPROFILE

          TIFFTAG_JPEGQUALITY

          TIFFTAG_JPEGCOLORMODE
          JPEGCOLORMODE_RAW
          JPEGCOLORMODE_RGB

          TIFFTAG_JPEGTABLESMODE
          JPEGTABLESMODE_QUANT
          JPEGTABLESMODE_HUFF

          TIFFTAG_ZIPQUALITY

          TIFFPRINT_STRIPS
          TIFFPRINT_CURVES
          TIFFPRINT_COLORMAP
          TIFFPRINT_JPEGQTABLES
          TIFFPRINT_JPEGACTABLES
          TIFFPRINT_JPEGDCTABLES
        )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = 18;

require XSLoader;
XSLoader::load( 'Graphics::TIFF', $VERSION );

sub get_version {
    my ($version) = Graphics::TIFF->GetVersion;
    if ( $version =~ /LIBTIFF,[ ]Version[ ](\d+)[.](\d+)[.](\d+)/xsm ) {
        return $1, $2, $3;
    }
    return;
}

sub get_version_scalar {
    my (@version) = Graphics::TIFF->get_version;
    if ( defined $version[0] and defined $version[1] and defined $version[2] ) {
        return $version[0] + $version[1] / $MINOR + $version[2] / $MICRO;
    }
    return;
}

sub Open {    ## no critic (Capitalization)
    my ( $class, $path, $flags ) = @_;
    my $self =
      Graphics::TIFF->_Open( $path, $flags );  ## no critic (ProtectPrivateSubs)
    bless \$self, $class;
    return \$self;
}

1;
__END__

=head1 NAME

Graphics::TIFF - Perl extension for the libtiff library

=head1 VERSION

18

=head1 SYNOPSIS

Perl bindings for the libtiff library.
This module allows you to access TIFF images in a Perlish and
object-oriented way, freeing you from the casting and memory management in C,
yet remaining very close in spirit to original API.

The following snippet can be used to read the image data from a TIFF:

 use Graphics::TIFF ':all';
 my $tif = Graphics::TIFF->Open( 'test.tif', 'r' );
 my $stripsize = $tif->StripSize;
 for my $stripnum ( 0 .. $tif->NumberOfStrips - 1 ) {
     my $buffer = $tif->ReadEncodedStrip( $stripnum, $stripsize );
     # do something with $buffer
 }
 $tif->Close;

=head1 DESCRIPTION

The Graphics::TIFF module allows a Perl developer to access TIFF images.
Find out more about libtiff at L<http://www.libtiff.org>.

=for readme stop

=head1 SUBROUTINES/METHODS

=head2 Graphics::TIFF->get_version

Returns an array with the LIBTIFF_VERSION_(MAJOR|MINOR|MICRO) versions:

  join('.',Graphics::TIFF->get_version)

=head2 Graphics::TIFF->get_version_scalar

Returns an scalar with the LIBTIFF_VERSION_(MAJOR|MINOR|MICRO) versions combined
as per the Perl version numbering, i.e. libtiff 4.0.6 gives 4.000006. This allows
simple version comparisons.

=head2 Graphics::TIFF->GetVersion

Returns a string with the format "LIBTIFF, Version MAJOR.MINOR.MICRO"

=head2 Graphics::TIFF->IsCODECConfigured(compression)

Returns a boolean if libtiff was configured with the given compression method.
See the possible values for the TIFFTAG_COMPRESSION tag for valid compression
methods.

=head2 Graphics::TIFF->Open(filename, flags)

Returns a TIFF object. 'r' and 'w' are valid flags.

=head2 $tif->Close

Closes the tiff given TIFF object.

=head2 $tif->FileName

Returns the filename associated with the given TIFF object.

=head2 $tif->ReadDirectory

Read the next directory in the specified file and make it the current directory.
Applications only need to call ReadDirectory to read multiple subfiles in a
single TIFF file - the first directory in a file is automatically read when
Open is called.

=head3 Notes

If the library is compiled with STRIPCHOP_SUPPORT enabled, then images that have
a single uncompressed strip or tile of data are automatically treated as if they
were made up of multiple strips or tiles of approximately 8 kilobytes each. This
operation is done only in-memory; it does not alter the contents of the file.
However, the construction of the ''chopped strips'' is visible to the
application through the number of strips [tiles] returned by NumberOfStrips
[NumberOfTiles].

=head3 Return Values

If the next directory was successfully read, 1 is returned. Otherwise, 0 is
returned if an error was encountered, or if there are no more directories to be
read.

=head2 $tif->WriteDirectory

WriteDirectory will write the contents of the current directory to the file and
setup to create a new subfile in the same file. Applications only need to call
WriteDirectory when writing multiple subfiles to a single TIFF file.
WriteDirectory is automatically called by Close and Flush to write a
modified directory if the file is open for writing.

The RewriteDirectory function operates similarly to WriteDirectory, but can be
called with directories previously read or written that already have an
established location in the file. It will rewrite the directory, but instead of
place it at it's old location (as TIFFWriteDirectory would) it will place them
at the end of the file, correcting the pointer from the preceding directory or
file header to point to it's new location. This is particularly important in
cases where the size of the directory and pointed to data has grown, so it won't
fit in the space available at the old location.

The CheckpointDirectory writes the current state of the tiff directory into the
file to make what is currently in the file readable. Unlike WriteDirectory,
CheckpointDirectory does not free up the directory data structures in memory, so
they can be updated (as strips/tiles are written) and written again. Reading
such a partial file you will at worst get a tiff read error for the first
strip/tile encountered that is incomplete, but you will at least get all the
valid data in the file before that. When the file is complete, just use
WriteDirectory as usual to finish it off cleanly.

=head3 Return Values

1 is returned when the contents are successfully written to the file. Otherwise,
0 is returned if an error was encountered when writing the directory contents.

=head2 $tif->ReadEXIFDirectory(diroff)

Required before reading EXIF tags.

=head2 $tif->NumberOfDirectories

Returns the number of directory in the given TIFF object.

=head2 $tif->SetDirectory(dirnum)

Changes the current directory and reads its contents with
ReadDirectory. The parameter dirnum specifies the subfile/directory as an
integer number, with the first directory numbered zero.

=head3 Return Values

On successful return 1 is returned. Otherwise, 0 is returned if dirnum or diroff
specifies a non-existent directory, or if an error was encountered while reading
the directory's contents.

=head2 $tif->SetSubDirectory(diroff)

Acts like SetDirectory, except the directory is specified as a
file offset instead of an index; this is required for accessing subdirectories
linked through a SubIFD tag.

=head2 $tif->GetField(tag)

Returns the value of a tag or pseudo-tag associated with the the
current directory of the open TIFF file tif. (A pseudo-tag is a parameter that
is used to control the operation of the TIFF library but whose value is not read
or written to the underlying file.) The file must have been previously opened
with Open. The type and number of values returned is dependent on the tag being
requested.

The tags understood by libtiff are shown below. Consult the TIFF specification
for information on the meaning of each tag and their possible values.

TIFFTAG_ARTIST
TIFFTAG_BADFAXLINES
TIFFTAG_BITSPERSAMPLE
TIFFTAG_CLEANFAXDATA
TIFFTAG_COLORMAP
TIFFTAG_COMPRESSION (COMPRESSION_NONE
COMPRESSION_CCITTRLE
COMPRESSION_CCITTFAX3
COMPRESSION_CCITT_T4
COMPRESSION_CCITTFAX4
COMPRESSION_CCITT_T6
COMPRESSION_LZW
COMPRESSION_OJPEG
COMPRESSION_JPEG
COMPRESSION_T85
COMPRESSION_T43
COMPRESSION_NEXT
COMPRESSION_CCITTRLEW
COMPRESSION_PACKBITS
COMPRESSION_THUNDERSCAN
COMPRESSION_IT8CTPAD
COMPRESSION_IT8LW
COMPRESSION_IT8MP
COMPRESSION_IT8BL
COMPRESSION_PIXARFILM
COMPRESSION_PIXARLOG
COMPRESSION_DEFLATE
COMPRESSION_ADOBE_DEFLATE
COMPRESSION_DCS
COMPRESSION_JBIG
COMPRESSION_SGILOG
COMPRESSION_SGILOG24
COMPRESSION_JP2000
COMPRESSION_LZMA)
TIFFTAG_CONSECUTIVEBADFAXLINES
TIFFTAG_COPYRIGHT
TIFFTAG_DATATYPE
TIFFTAG_DATETIME
TIFFTAG_DOCUMENTNAME
TIFFTAG_DOTRANGE
TIFFTAG_EXTRASAMPLES (EXTRASAMPLE_UNSPECIFIED
EXTRASAMPLE_ASSOCALPHA
EXTRASAMPLE_UNASSALPHA)
TIFFTAG_FAXMODE
TIFFTAG_FAXFILLFUNC
TIFFTAG_FILLORDER (FILLORDER_MSB2LSB
FILLORDER_LSB2MSB)
TIFFTAG_GROUP3OPTIONS (GROUP3OPT_2DENCODING
GROUP3OPT_UNCOMPRESSED
GROUP3OPT_FILLBITS)
TIFFTAG_GROUP4OPTIONS (GROUP4OPT_UNCOMPRESSED)
TIFFTAG_HALFTONEHINTS
TIFFTAG_HOSTCOMPUTER
TIFFTAG_IMAGEDEPTH
TIFFTAG_IMAGEDESCRIPTION
TIFFTAG_IMAGELENGTH
TIFFTAG_IMAGEWIDTH
TIFFTAG_INKNAMES
TIFFTAG_INKSET (INKSET_CMYK
INKSET_MULTIINK)
TIFFTAG_JPEGTABLES
TIFFTAG_JPEGQUALITY
TIFFTAG_JPEGCOLORMODE (JPEGCOLORMODE_RAW
JPEGCOLORMODE_RGB)
TIFFTAG_JPEGPROC (JPEGPROC_BASELINE
JPEGPROC_LOSSLESS)
TIFFTAG_JPEGTABLESMODE (JPEGTABLESMODE_QUANT
JPEGTABLESMODE_HUFF)
TIFFTAG_MAKE
TIFFTAG_MATTEING
TIFFTAG_MAXSAMPLEVALUE
TIFFTAG_MINSAMPLEVALUE
TIFFTAG_MODEL
TIFFTAG_ORIENTATION (ORIENTATION_TOPLEFT
ORIENTATION_TOPRIGHT
ORIENTATION_BOTRIGHT
ORIENTATION_BOTLEFT
ORIENTATION_LEFTTOP
ORIENTATION_RIGHTTOP
ORIENTATION_RIGHTBOT
ORIENTATION_LEFTBOT)
TIFFTAG_OSUBFILETYPE (OFILETYPE_IMAGE
OFILETYPE_REDUCEDIMAGE
OFILETYPE_PAGE)
TIFFTAG_PAGENAME
TIFFTAG_PAGENUMBER
TIFFTAG_PHOTOMETRIC (PHOTOMETRIC_MINISWHITE
PHOTOMETRIC_MINISBLACK
PHOTOMETRIC_RGB
PHOTOMETRIC_PALETTE
PHOTOMETRIC_MASK
PHOTOMETRIC_SEPARATED
PHOTOMETRIC_YCBCR
PHOTOMETRIC_CIELAB
PHOTOMETRIC_ICCLAB
PHOTOMETRIC_ITULAB
PHOTOMETRIC_LOGL
PHOTOMETRIC_LOGLUV)
TIFFTAG_PLANARCONFIG (PLANARCONFIG_CONTIG
PLANARCONFIG_SEPARATE)
TIFFTAG_PREDICTOR (PREDICTOR_NONE
PREDICTOR_HORIZONTAL
PREDICTOR_FLOATINGPOINT)
TIFFTAG_PRIMARYCHROMATICITIES
TIFFTAG_REFERENCEBLACKWHITE
TIFFTAG_RESOLUTIONUNIT (RESUNIT_NONE
RESUNIT_INCH
RESUNIT_CENTIMETER)
TIFFTAG_ROWSPERSTRIP
TIFFTAG_SAMPLEFORMAT (SAMPLEFORMAT_UINT
SAMPLEFORMAT_INT
SAMPLEFORMAT_IEEEFP
SAMPLEFORMAT_VOID
SAMPLEFORMAT_COMPLEXINT
SAMPLEFORMAT_COMPLEXIEEEFP)
TIFFTAG_SAMPLESPERPIXEL
TIFFTAG_SMAXSAMPLEVALUE
TIFFTAG_SMINSAMPLEVALUE
TIFFTAG_SOFTWARE
TIFFTAG_STONITS
TIFFTAG_STRIPBYTECOUNTS
TIFFTAG_STRIPOFFSETS
TIFFTAG_SUBFILETYPE (FILETYPE_REDUCEDIMAGE
FILETYPE_PAGE
FILETYPE_MASK)
TIFFTAG_SUBIFD
TIFFTAG_TARGETPRINTER
TIFFTAG_THRESHHOLDING
TIFFTAG_TILEBYTECOUNTS
TIFFTAG_TILEDEPTH
TIFFTAG_TILELENGTH
TIFFTAG_TILEOFFSETS
TIFFTAG_TILEWIDTH
TIFFTAG_TRANSFERFUNCTION
TIFFTAG_WHITEPOINT
TIFFTAG_XPOSITION
TIFFTAG_XRESOLUTION
TIFFTAG_YCBCRCOEFFICIENTS
TIFFTAG_YCBCRPOSITIONING
TIFFTAG_YCBCRSUBSAMPLING
TIFFTAG_YPOSITION
TIFFTAG_YRESOLUTION
TIFFTAG_ICCPROFILE

=head2 $tif->GetFieldDefaulted(tag)

Identical to GetField, except that if a tag is not defined
in the current directory and it has a default value, then the default value is
returned.

=head2 $tif->SetField(tag, ...)

Sets the value of a field or pseudo-tag in the current directory
associated with the open TIFF file tif. Set GetField for Possible values for#
tag.

=head2 $tif->IsTiled

Returns a non-zero value if the image data has a tiled organisation.
Zero is returned if the image data is organised in strips.

=head2 $tif->ScanlineSize

Returns the size in bytes of a row of data as it would be returned
in a call to ReadScanline, or as it would be expected in a call to
WriteScanline.

=head2 $tif->StripSize

Returns the equivalent size for a strip of data as it would be
returned in a call to ReadEncodedStrip or as it would be expected in a call to
WriteEncodedStrip.

=head2 $tif->NumberOfStrips

Returns the number of strips in the image.

=head2 $tif->TileSize

Returns the equivalent size for a tile of data as it would be returned
in a call to ReadTile or as it would be expected in a call to WriteTile.

=head2 $tif->TileRowSize

Returns the number of bytes of a row of data in a tile.

=head2 $tif->ComputeStrip(row, sample)

Returns the strip that contains the specified coordinates. A valid strip is
always returned; out-of-range coordinate values are clamped to the bounds of the
image. The row parameter is always used in calculating a strip. The sample
parameter is used only if data are organised in separate planes
(PlanarConfiguration=2).

=head2 $tif->ReadEncodedStrip(strip, size)

Returns a buffer of up to size bytes of decompressed information.

The value of strip is a ``raw strip number.'' That is, the caller must take into
account whether or not the data are organised in separate planes
(PlanarConfiguration=2). To read a full strip of data the data buffer should
typically be at least as large as the number returned by StripSize.

The library attempts to hide bit- and byte-ordering differences between the
image and the native machine by converting data to the native machine order.
Bit reversal is done if the FillOrder tag is opposite to the native machine bit
order. 16- and 32-bit samples are automatically byte-swapped if the file was
written with a byte order opposite to the native machine byte order.

=head2 $tif->WriteEncodedStrip(strip, data, size)

Compress size bytes of raw data from buf and write the result to the specified
strip; replacing any previously written data. Note that the value of strip is a
``raw strip number.'' That is, the caller must take into account whether or not
the data are organised in separate places (PlanarConfiguration=2).

The library writes encoded data using the native machine byte order. Correctly
implemented TIFF readers are expected to do any necessary byte-swapping to
correctly process image data with BitsPerSample greater than 8.

The strip number must be valid according to the current settings of the
ImageLength and RowsPerStrip tags. An image may be dynamically grown by
increasing the value of ImageLength prior to each call to TIFFWriteEncodedStrip.

-1 is returned if an error was encountered. Otherwise, the value of size is
returned.

=head2 $tif->ReadRawStrip(strip, size)

Returns the contents of the specified strip. Note that the value of strip is a
''raw strip number.'' That is, the caller must take into account whether or not
the data is organised in separate planes (PlanarConfiguration=2). To read a full
strip of data the data buffer should typically be at least as large as the
number returned by StripSize.

=head2 $tif->ReadTile(x, y, z, s)

Returns the data for the tile containing the specified coordinates. The data is
returned decompressed and, typically, in the native byte- and bit-ordering, but
are otherwise packed (see further below). The buffer must be large enough to
hold an entire tile of data. Applications should call the routine TIFFTileSize
to find out the size (in bytes) of a tile buffer. The x and y parameters are
always used by ReadTile. The z parameter is used if the image is deeper than 1
slice (ImageDepth>1). The sample parameter is used only if data are organised in
separate planes (PlanarConfiguration=2).

The library attempts to hide bit- and byte-ordering differences between the
image and the native machine by converting data to the native machine order. Bit
reversal is done if the FillOrder tag is opposite to the native machine bit
order. 16- and 32-bit samples are automatically byte-swapped if the file was
written with a byte order opposite to the native machine byte order.

=head2 $tif->PrintDirectory(file, flags)

Prints a description of the current directory in the specified TIFF file to the
standard I/O output stream fd. The flags parameter is used to control the level
of detail of the printed information, and is a bitwise or of the following
values:

TIFFPRINT_NONE
TIFFPRINT_STRIPS
TIFFPRINT_CURVES
TIFFPRINT_COLORMAP
TIFFPRINT_JPEGQTABLES
TIFFPRINT_JPEGACTABLES
TIFFPRINT_JPEGDCTABLES

=head2 Graphics::TIFF::ReverseBits(data, size)

Replaces each byte in data with the equivalent bit-reversed value. This
operation is done with a lookup table.

=for readme continue

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head2 Runtime

The runtime dependencies are just libtiff itself. In Windows this is satisfied
by Alien::libtiff.

=head2 Build

The build dependencies are additionally the development headers for libtiff
and Perl.

=head2 Test

In addition to the above, the Perl module Image::Magick is required to run some
of the tests.

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 SEE ALSO

The LIBTIFF Standard Reference L<http://www.libtiff.org/libtiff.html> is a handy
companion. The Perl bindings follow the C API very closely, and the C reference
documentation should be considered the canonical source.

=head1 AUTHOR

Jeffrey Ratcliffe, E<lt>jffry@posteo.netE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2017--2021 by Jeffrey Ratcliffe

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
