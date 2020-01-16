package Image::PNG;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/display_text/;
use Image::PNG::Const ':all';
use Image::PNG::Libpng;
use Image::PNG::Container;
use warnings;
use strict;
use Carp;

our $VERSION = '0.24';


sub error
{
    my ($png) = @_;
    return $png->{error_string};
}

sub fatal_error
{
    my ($png) = @_;
    return $png->{error_string};
}

my %IHDR_fields = (
    width => {
    },
    height => {
    },
    bit_depth => {
        default => 8,
    },
    color_type => {
    },
    interlace_type => {
        default => PNG_INTERLACE_NONE,
    },
);


sub write_info_error
{
    my @unset;
    for my $field (sort keys %IHDR_fields) {
        if (!$IHDR_fields{$field}{default}) {
            push @unset, $field;
        }
        print "Set the following fields: ", join ", ", @unset;
    }
}

# Return the verbosity.

sub verbose
{
    my ($png) = @_;
    return $png->{verbosity};
}

# Set the verbosity.

sub verbosity
{
    my ($png, $verbosity) = @_;
    if ($verbosity) {
        printf "I am a %s. I am going to print messages about what I'm doing. You can surprsss this by calling \$me->verbosity () or by using an option %s->new ({verbosity} = 0);.\n", (__PACKAGE__) x 2;
    }
    $png->{verbosity} = 1;
}

# Make the object.

sub new
{
    my ($package, $options) = @_;
    my $png = {};
    bless $png;
    # The marker "error_string" contains the most recent error.
    $png->{error_string} = '';
    if ($options && ref $options eq 'HASH') {
        if ($options->{verbosity}) {
            $png->verbosity ($options->{verbosity});
        }
        if ($options->{file}) {
            $png->read ($options->{file});
        }
    }
    return $png;
}

# Read a file

sub Image::PNG::read
{
    my ($png, $file_name) = @_;
    if ($png->verbose) {
        print "I am going to try to read a file called '$file_name'.\n";
    }
    if (! defined $file_name) {
        carp __PACKAGE__, ": You called 'read' without giving a file name";
        return;
    }
    my $read = Image::PNG::Container->new ({read_only => 1});
    $read->set_file_name ($file_name);
    $read->open ();
    $read->read ();
    if ($png->verbose) {
        my $ihdr = Image::PNG::Libpng::get_IHDR ($read->png ());
        printf ("The size of the image is %d X %d; its colour type is %s; its bit depth is %d\n", $ihdr->{width}, $ihdr->{height}, Image::PNG::Libpng::color_type_name ($ihdr->{color_type}), $ihdr->{bit_depth});
    }
    $png->{read} = $read;
    return 1;
}

sub handle_error
{
    my ($png, $message) = @_;
    croak $message;
}

sub Image::PNG::write
{
    my ($png, $file_name) = @_;
    if ($png->verbose) {
        print "I am going to try to write a PNG file called '$file_name'.\n";
    }
    if (! $png->{write_ok}) {
        if (! $png->{read}) {
            $png->write_info_error ();
        }
        $png->init_write ();
    }
    my $write = $png->{write};
    $write->{file_name} = $file_name;
    # Check whether the image to be written has all of its IHDR information.
    if (! $write->{ihdr_set}) {
        if ($png->verbose) {
            print "The image to be written doesn't seem to know what its header is supposed to be, so I'm going to try to find a substitute.\n";
        }
        if ($png->{read}) {
            if ($png->verbose) {
                print "I am copying the header from the image which I read in.\n";
            }
            my $ihdr = Image::PNG::Libpng::get_IHDR ($png->{read}->png ());
            if ($png->verbose) {
                print "I've got a header and now I'm going to try to put it into the output.\n";
            }
            Image::PNG::Libpng::set_IHDR ($write->{png}, $ihdr);
            $write->{ihdr} = $ihdr;
        }
        else {
            $png->handle_error ("I have no IHDR (header) data for the image; use the 'IHDR' method to set the IHDR values");
        }
    }
    if ($png->verbose) {
        print "I've got a header to write. Now I'm going to check the image data before writing it out.\n";
    }
    # Check whether the image data (the rows of the image) exist in
    # some form or other.
    if (! $write->{rows_set}) {
        if ($png->verbose) {
            print "You haven't specified what data you want me to write.\n";
        }
        # If the user has not specified what rows to write, assume
        # that he wants to use the rows from a PNG object which has
        # already been read in.
        if ($png->{read}) {
            if ($png->verbose) {
                print "I am setting the image data for the image to write to data which I read in from another image.";
            }
            my $rows = Image::PNG::Libpng::get_rows ($png->{read}->png ());
            if ($png->verbose) {
                print "I've got the data from the read image and now I'm going to set up the writing to write that data.\n";
            }
            Image::PNG::Libpng::set_rows ($write->{png}, $rows);
        }
        else {
            # There is no row data for the image.
            $png->handle_error ("I have no row data for the image; use the 'rows' method to set the rows.");
            return;
        }
    }
    if ($png->verbose) {
        printf ("Its colour type is %s.\n", Image::PNG::Libpng::color_type_name ($write->{ihdr}->{color_type}));
    }
    if ($write->{ihdr}->{color_type} == PNG_COLOR_TYPE_PALETTE) {
        if ($png->verbose) {
            print "The image you want to write has a palette, so I am going to check whether the palette is ready to be written.\n";
        }
        if (! $write->{palette_set}) {
            print "The image doesn't have a palette set.\n";
            if ($png->{read}) {
                print "I am going to try to get one from the image I read in.\n";
                my $palette = Image::PNG::Libpng::get_PLTE ($png->{read}->png ());
                for my $color (@$palette) {
                    for my $hue (qw/red green blue/) {
                        printf "%s: %d ", $hue, $color->{$hue};
                    }
                    print "\n";
                }
                Image::PNG::Libpng::set_PLTE ($write->{png}, $palette);
            }
            else {
                $png->handle_error ("You asked me to write an image with a palette, but I don't have any information about the palette for the image.");
            }
        }
    }

    if ($png->verbose) {
        print "I've got the data for the header and the image now so I can write a minimal PNG.\n";
    }
    # Now the rows are set.
    open my $output, ">:raw", $write->{file_name}
        or $png->handle_error ("opening file '$write->{file_name}' failed: $!'");
    Image::PNG::Libpng::init_io ($write->{png}, $output);
    Image::PNG::Libpng::write_png ($write->{png});
}

# Private

sub do_not_write
{
    my ($png, $chunk) = @_;
    push @{$png->{write}->{ignored_chunks}}, $chunk;
}

# Public

sub Image::PNG::delete
{
    my ($png, @chunks) = @_;
    if (! $png->{write_ok}) {
        if (! $png->{read}) {
            $png->write_info_error ();
        }
        $png->init_write ();
    }
    for my $chunk (@chunks) {
        $png->do_not_write ($chunk);
    }
}

sub write_set
{
    my ($png, $key, $value) = @_;
    if (! $png->{write_ok}) {
        $png->init_write ();
    }
    $png->{write}->{$key} = $value;
}

# Initialize the object $png for writing (get the libpng things we
# need to write an image, set a flag "write_ok" in the image.).

sub init_write
{
    my ($png) = @_;
    if ($png->{write_ok}) {
        $png->error ("Writing already initialized");
        return;
    }
    $png->{write} = {};
    $png->{write}->{png} =
        Image::PNG::Libpng::create_write_struct ();
    $png->{write_ok} = 1;
}

sub raise_error
{
    my ($png, $error_level) = @_;
}

sub print_error
{
    my ($png, $error_level) = @_;
}

sub data
{
    my ($png, $data) = @_;
    if (! $data) {
        # Return the existing data
    }
    else {
        # Put $data into the PNG
        if ($png->{data}) {
            carp __PACKAGE__, ": you have asked me to put a scalar value as the PNG data, but I already have PNG data inside me. Please use a fresh object.";
        }
        elsif ($png->{read_file_name}) {
            carp __PACKAGE__, ": you have asked me to put a scalar value as the PNG data, but I already contain PNG data from a file called '$png->{read_file_name}. Please use a fresh object.";
        }
    }
    return $png->{data};
}

# Public

sub IHDR
{
    my ($png, $ihdr) = @_;
    if ($ihdr) {
        Image::PNG::Libpng::set_IHDR ($png->{write}->{png},
                                             $ihdr);
        $png->{write}->{ihdr_set} = 1;
    }
    else {
        $ihdr = Image::PNG::Libpng::get_IHDR ($png->{read}->png ());
    }
    return $ihdr;
}

# Private

sub get_IHDR
{
    my ($png) = @_;
    if ($png->{IHDR}) {
        carp __PACKAGE__, ": I was requested to read the IHDR of the PNG data, but I have already read it.";
        return;
    }
    $png->{IHDR} = Image::PNG::Libpng::get_IHDR ($png->{read}->png ());
}

# Get $key from the PNG.

sub get
{
    my ($png, $key) = @_;
    if (! $png->{IHDR}) {
        $png->get_IHDR ();
    }
    return $png->{IHDR}->{$key};
}

# Get/set width of PNG

sub width
{
    my ($png, $width) = @_;
    if ($width) {
        write_set ($png, 'width', $width);
    }
    else {
        return get ($png, 'width');
    }
}

# Get/set height of PNG

sub height
{
    my ($png, $height) = @_;
    if ($height) {
        write_set ($png, 'height', $height);
    }
    else {
        return get ($png, 'height');
    }
}

sub color_type
{
    my ($png, $color_type) = @_;
    if ($color_type) {
        write_set ($png, 'color_type', $color_type);
    }
    else {
        return 
            Image::PNG::Libpng::color_type_name (
                get ($png, 'color_type')
            );
    }
}

sub bit_depth
{
    my ($png, $bit_depth) = @_;
    if ($bit_depth) {
        write_set ($png, 'bit_depth', $bit_depth);
    }
    else {
        return get ($png, 'bit_depth')
    }
}

sub rows
{
    my ($png, $rows) = @_;
    if ($rows) {
        # Set the rows
        if (! $png->{write_ok}) {
            $png->init_write ();
        }
        if (! $png->{write}->{set_IHDR}) {
            $png->{write}->{set_IHDR} = 1;
            Image::PNG::Libpng::set_IHDR ($png->{write}->{png},
                                                 $png->{write}->{IHDR});
        }
        Image::PNG::Libpng::set_rows ($png->{write_png}, $rows);
        $png->{write}->{rows_set} = 1;
    }
    else {
        # Read the rows
        if (! $png->{read}) {
            #        $png->handle_error ("");
            return;
        }
        return Image::PNG::Libpng::get_rows ($png->{read}->png ());
    }
}

sub rowbytes
{
    my ($png) = @_;
    if (! $png->{read}) {
#        $png->handle_error ("");
        return;
    }
    return Image::PNG::Libpng::get_rowbytes ($png->{read}->png ());
}

sub text
{
    my ($png) = @_;
    if (! $png->{text}) {
        my $text_ref =
            Image::PNG::Libpng::get_text ($png->{read}->png ());
        $png->{text} = $text_ref;
        # Change the text compression field to words rather than numbers.
        for my $text (@{$png->{text}}) {
            $text->{compression} =
                Image::PNG::Libpng::text_compression_name ($text->{compression});
        }
    }
    if (! wantarray) {
        carp __PACKAGE__, ": the 'text' method returns an array";
    }
    return @{$png->{text}};
}

sub time
{
    my ($png) = @_;
    if (! $png->{read}) {
        return undef;
    }
    return Image::PNG::Libpng::get_tIME ($png->{read}->{png});
}

# The text segment of the PNG should probably be an object in its own
# right.

sub display_text
{
    my ($text) = @_;
    if (! $text || ref $text ne 'HASH' || ! $text->{key}) {
        carp __PACKAGE__, "::display_text called with something which doesn't seem to be a PNG text chunk";
        return;
    }
    print "\n";
    print "Key: $text->{key}";
    if ($text->{translated_keyword}) {
        print " [$text->{translated_keyword}";
        if ($text->{lang}) {
            print " in language $text->{lang}";
        }
        print "]";
    }
    print "\n";
    print "Compression: $text->{compression}\n";
    if ($text->{text}) {
        printf "Text";
        if (defined $text->{text_length}) {
            printf " (length %d)", $text->{text_length};
        }
        print ":\n$text->{text}\n"
    }
    else {
        print "Text is empty.\n";
    }
}

sub interlacing_method
{
    my ($png) = @_;
    my $ihdr = Image::PNG::Libpng::get_IHDR ($png->{read}->png);
    if ($ihdr->{interlace_method} == PNG_INTERLACE_NONE) {
	return 'none';
    }
    if ($ihdr->{interlace_method} == PNG_INTERLACE_ADAM7) {
	return 'adam7';
    }
    return undef;
}

1;

=head1 NAME

Image::PNG - Read and write PNG files



=head1 SYNOPSIS

    my $png = Image::PNG->new ();
    $png->read ("example.png");
    printf "Your PNG is %d x %d\n", $png->width, $png->height;

=head1 VERSION

This documents version 0.24 of Image::PNG corresponding
to git commit L<ddd4a5ff61dc35830859846754cd091ba4491fc1|https://github.com/benkasminbullock/Image-PNG/commit/ddd4a5ff61dc35830859846754cd091ba4491fc1> made on Tue Jan 14 08:49:00 2020 +0900.

=head1 DESCRIPTION

This module is an attempt to make a simple interface for dealing with
images in the PNG format. See L</About the PNG format> for details of
the format.

Image::PNG is a layer on top of L<Image::PNG::Libpng>. Whereas
L<Image::PNG::Libpng> copies the interface of the C library C<libpng>,
Image::PNG is intended to be a more intuitive way to handle PNG
images. 

This module is not completed, so its interface is likely to
change. It's also open to suggestions for improvements.

=head1 General methods

=head2 new

    my $png = Image::PNG->new ();

Create a new PNG-file reading or writing object.

Options are

=over

=item read

    my $png = Image::PNG->new ({read => 'some.png'});

Set the file to read. The file is then read at the time of object
creation.

=item verbosity

    my $png = Image::PNG->new ({verbosity => 1});

If C<verbosity> is set to a true value, print verbose messages about
what the module is doing.

=back

=head2 read

    $png->read ("crazy.png")
        or die "Can't read it: " . $png->error ();

Read the PNG from the file name specified as the argument. This dies
if there is an error.

=head2 write

    $png->write ("crazy.png")
        or die "Can't write it: " . $png->error ();

Write the PNG to the file name specified as the argument. This dies
if there is an error.

=head2 data

     my $data = $png->data ();

Get the PNG image data as a Perl scalar.

=head2 error

Print the most recent error message.

=head1 PNG header-related methods

These methods are related to the PNG header (the IHDR chunk of the PNG
file). 

=head2 width

    my $height = $png->width ();

Get the width of the current PNG image.

=head2 height

    my $height = $png->height ();

Get the height of the current PNG image.

=head2 color_type

    my $color_type = $png->color_type ();

Get the name of the colour type of the current PNG image. The possible
return values are

=over

=item PALETTE

=item GRAY

=item GRAY_ALPHA

=item RGB

=item RGB_ALPHA

=back

=head2 bit_depth

    my $bit_depth = $png->bit_depth ();

Get the bit depth of the current PNG image.

=head2 interlacing_method

    my $interlacing_method = $png->interlacing_method ();

Get the name of the method of interlacing of the current PNG
image. This may be either C<none> or C<adam7>.

There is no method for dealing with the compression method
field of the header, since this only has one possible value.

=head1 Image data-related methods

=head2 rowbytes

    my $rowbytes = $png->rowbytes;

This method returns the number of bytes in each row of the image. If
no image has been read yet, it returns the undefined value.

=head2 rows

    my $rows = $png->rows;

This method returns the rows of the image as an array reference,
C<$rows>. The array reference is a size equal to the height of the
image. Each element has the length of the number of bytes in one row
(as given by L</rowbytes>) plus one final zero byte. 

The row data returned is binary data and may contain several bytes
with the value zero.

=head1 Non-image chunks

=head2 text

    my @text = $png->text;

Get the text chunks of the image. Each element of the return value is
a hash reference. The keys are the fields of the PNG text chunk, and
the values are the values of those fields in the text chunk. The size
of the array is equal to the number of text chunks.

=head2 time

    my $time_ref = $png->time;
    print "The PNG was last modified in $time_ref->{year}.\n";

Get the last modified time of the image. The return value is a hash
reference containing the following six fields,

=over

=item year

=item month

=item day

=item hour

=item minute

=item second

=back

These represent the last modification time of the image. The
modification time of a PNG file is meant to be in the GMT (UCT) time
zone so there is no time zone information.

If there is no last modification time, the undefined value is returned
instead of a hash reference.

=head1 FUNCTIONS

There are some convenience functions in this module, exported on request.

=head2 display_text

     use Image::PNG qw/display_text/;
     my @text = $png->text;
     display_text ($text[3]);

Display the text chunk given as an argument on C<STDOUT>.

This is a convenience function for debugging rather than a
general-purpose routine.

=head1 SEE ALSO

=head2 About the PNG format

=over

=item Libpng.org website

L<http://www.libpng.org/> is the website for PNG and for the libpng
implementation. To download libpng, see
L<http://www.libpng.org/pub/png/libpng.html>. See also L</Alien::PNG>.

=item Wikipedia article

There is L<an article on the format on Wikipedia|http://en.wikipedia.org/wiki/Portable_Network_Graphics>.

=item The PNG specification

L<The PNG specification|http://www.w3.org/TR/PNG/> (link to W3
consortium) explains the details of the PNG format.


=item PNG The Definitive Guide by Greg Roelofs

The book "PNG - The Definitive Guide" by Greg Roelofs, published in
1999 by O'Reilly is available online at
L<http://www.faqs.org/docs/png/>. 

=back

=head1 DEPENDENCIES

=over

=item L<Image::PNG::Libpng>

=back

=head2 Other CPAN modules

=over

=item Image::PNG::Const

L<Image::PNG::Const> contains the libpng constants taken from the libpng
header file "png.h".

=item Image::PNG::Libpng

L<Image::PNG::Libpng> provides a Perl mirror of the interface of the C
PNG library "libpng". Image::PNG is built on top of this module.

=item Image::ExifTool

L<Image::ExifTool> is a pure Perl (doesn't require a C compiler)
solution for accessing the text segments of images. It has extensive
support for PNG text segments.

=item Alien::PNG

L<Alien::PNG> claims to be a way of "building, finding and using PNG
binaries". It may help in installing libpng. I didn't use it as a
dependency for this module because it seems not to work in batch mode,
but stop and prompt the user. I'm interested in hearing feedback from
users whether this works or not on various platforms.

=item Image::PNG::Rewriter

L<Image::PNG::Rewriter> is a utility for unpacking and recompressing
the IDAT (image data) part of a PNG image. The main purpose seems to
be to recompress the image data with the module author's other module
L<Compress::Deflate7>. Unfortunately that only works with Perl
versions 5.12.

=item Image::Pngslimmer

L<Image::Pngslimmer> reduces the size of dynamically created PNG
images. It's very, very slow at reading PNG data, but seems to work
OK.

=item Image::Info

L<Image::Info> is a module for getting information out of various
types of images. It has good support for PNG and is written in pure
Perl (doesn't require a C compiler). As well as basics such as height,
width, and colour type, it can get text chunks, modification time,
palette, gamma (gAMA chunk), resolution (pHYs chunk), and significant
bits (sBIT chunk). At the time of writing (version 1.31) it doesn't
support other chunks.

=item Image::Size

If you only need to find the size of an image, L<Image::Size> can give
you the size of PNG and various other image formats.

=item Image::PNGwriter

L<Image::PNGwriter> is an interface to a project called
"PNGwriter". At the time of writing (2013-12-01), only one version has
been released, in 2005. The most recent version of PNGwriter itself is
from 2009.

=item Image::PNG::Write::BW

L<Image::PNG::Write::BW> is a pure-Perl module to write minimal black
and white PNG images.




=back

=head1 AUTHOR

Ben Bullock, <bkb@cpan.org>

=head1 COPYRIGHT & LICENCE

The Image::PNG package and associated files are copyright (C)
2020 Ben Bullock.

You can use, copy, modify and redistribute Image::PNG and
associated files under the Perl Artistic Licence or the GNU General
Public Licence.

=head1 FOR PROGRAMMERS

The distributed files are not the source code of the module. The
source code lives in the "tmpl" directory of the distribution and the
distribution is created via scripts.



=cut

# Local Variables:
# mode: perl
# End:


# Local Variables:
# mode: perl
# End:
