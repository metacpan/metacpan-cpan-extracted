package Image::PNG;
use warnings;
use strict;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/display_text/;
use Image::PNG::Const ':all';
use Image::PNG::Libpng ':all';
use Image::PNG::Container;
use Carp;

our $VERSION = '0.25';


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
    # This contains the most recent error.
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
        return undef;
    }
    my $read = Image::PNG::Container->new ({read_only => 1});
    $read->set_file_name ($file_name);
    $read->open ();
    $read->read ();
    if ($png->verbose) {
        my $ihdr = get_IHDR ($read->png ());
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
            my $ihdr = get_IHDR ($png->{read}->png ());
            if ($png->verbose) {
                print "I've got a header and now I'm going to try to put it into the output.\n";
            }
            set_IHDR ($write->{png}, $ihdr);
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
            my $rows = get_rows ($png->{read}->png ());
            if ($png->verbose) {
                print "I've got the data from the read image and now I'm going to set up the writing to write that data.\n";
            }
            set_rows ($write->{png}, $rows);
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
    init_io ($write->{png}, $output);
    write_png ($write->{png});
}

# Private

sub do_not_write
{
    my ($png, $chunk) = @_;
    push @{$png->{write}{ignored_chunks}}, $chunk;
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
    $png->{write}{$key} = $value;
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
    $png->{write}{png} = create_write_struct ();
    $png->{write_ok} = 1;
}

# Public

sub IHDR
{
    my ($png, $ihdr) = @_;
    if ($ihdr) {
        set_IHDR ($png->{write}{png}, $ihdr);
        $png->{write}{ihdr_set} = 1;
	return;
    }
    return _get_IHDR ($png->{read}->png ());
}

# Private

sub _get_IHDR
{
    my ($png) = @_;
    if ($png->{IHDR}) {
        carp __PACKAGE__, ": I was requested to read the IHDR of the PNG data, but I have already read it.";
        return;
    }
    $png->{IHDR} = get_IHDR ($png->{read}->png ());
}

# Get $key from the PNG.

sub get
{
    my ($png, $key) = @_;
    if (! $png->{IHDR}) {
        $png->_get_IHDR ();
    }
    return $png->{IHDR}{$key};
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
	return;
    }
    return color_type_name (get ($png, 'color_type'));
}

sub bit_depth
{
    my ($png, $bit_depth) = @_;
    if ($bit_depth) {
        write_set ($png, 'bit_depth', $bit_depth);
	return undef;
    }
    return get ($png, 'bit_depth')
}

sub rows
{
    my ($png, $rows) = @_;
    if ($rows) {
        # Set the rows
        if (! $png->{write_ok}) {
            $png->init_write ();
        }
	my $w = $png->{write};
        if (! $w->{set_IHDR}) {
            $w->{set_IHDR} = 1;
            set_IHDR ($w->{png}, $w->{IHDR});
        }
        set_rows ($png->{write_png}, $rows);
        $png->{write}{rows_set} = 1;
	return undef;
    }
    if (! $png->{read}) {
	carp "There is no PNG data in this object";
	return undef;
    }
    return get_rows ($png->{read}->png ());
}

sub rowbytes
{
    my ($png) = @_;
    if (! $png->{read}) {
        return undef;
    }
    return get_rowbytes ($png->{read}->png ());
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
    return @{$png->{text}};
}

sub time
{
    my ($png) = @_;
    if (! $png->{read}) {
        return undef;
    }
    return get_tIME ($png->{read}{png});
}

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
    my $ihdr = get_IHDR ($png->{read}->png);
    if ($ihdr->{interlace_method} == PNG_INTERLACE_NONE) {
	return 'none';
    }
    if ($ihdr->{interlace_method} == PNG_INTERLACE_ADAM7) {
	return 'adam7';
    }
    return undef;
}

1;
