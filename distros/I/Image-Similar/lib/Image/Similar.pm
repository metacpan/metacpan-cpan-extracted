package Image::Similar;
use warnings;
use strict;
use base 'Exporter';
our @EXPORT_OK = qw/
		       load_image
		       load_signature
		   /;
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

use Image::PNG::Libpng;
use Image::PNG::Const ':all';
use Scalar::Util 'looks_like_number';
use Carp;

our $VERSION = '0.05';
require XSLoader;
XSLoader::load ('Image::Similar', $VERSION);

use constant {
    # Constants used for combining red, green, and blue values. These
    # values are taken from the L<Imager> source code.
    red => 0.222,
    green => 0.707,
    blue => 0.071,
    # png bit depth
    png_bit_depth => 8,
    # bytes per pixel for rgb
    rgb_bytes => 3,
    # bytes per pixel for rgba
    rgba_bytes => 4,
    # Maximum possible grey pixel
    maxgreypixel => 255,
    # For "round".
    half => 0.5,
};


sub round
{
    my ($float) = @_;
    return int ($float + half);
}

sub new
{
    my ($class, %options) = @_;
    my $is = {};
    for my $field (qw/height width/) {
	if ($options{$field}) {
	    if (! looks_like_number ($options{$field})) {
		carp "$field value doesn't look like a number";
	    }
	    $is->{$field} = $options{$field};
	}
	else {
	    carp "Missing option $field";
	    return;
	}
    }
    #    print "$is->{height} $is->{width}\n";
    $is->{image} = Image::Similar::Image::isnew ($is->{width}, $is->{height});
    #    print "Finished isnew with $is->{image}\n";
    bless $is, $class;
    return $is;
}

sub fill_grid
{
    my ($s) = @_;
    $s->{image}->fill_grid ();
    return;
}

# Load an image assuming it's from GD.

sub load_image_gd
{
    my ($gd, %options) = @_;
    my ($width, $height) = $gd->getBounds ();
    my $is = Image::Similar->new (height => $height, width => $width);
    my $image = $is->{image};
    for my $y (0..$height - 1) {
	for my $x (0..$width - 1) {
	    my $index = $gd->getPixel ($x, $y);
	    my ($r, $g, $b) = $gd->rgb ($index);
	    my $greypixel = round (red * $r + green * $g + blue * $b);
#	    print "$x $y $r $g $b $greypixel\n";
	    $image->set_pixel ($x, $y, $greypixel);
	}
    }
    return $is;
}

# Load an image assuming it's from Imager.

sub load_image_imager
{
    my ($imager, %options) = @_;
    my $grey = $imager->convert (preset => 'gray');
    if ($options{make_grey_png}) {
	$grey->write (file => $options{make_grey_png});
    }
    my $height = $grey->getheight ();
    my $width = $grey->getwidth ();
    my $is = Image::Similar->new (height => $height, width => $width);
    for my $y (0..$height - 1) {
	#	print "$y\n";
	my @scanline = $grey->getscanline (y => $y);
	for my $x (0..$width - 1) {
	    # Dunno a better way to do this, please shout if you do.
	    my ($greypixel, undef, undef, undef) = $scanline[$x]->rgba ();
	    if ($greypixel < 0 || $greypixel > maxgreypixel) {
		carp "Pixel value $greypixel at $x, $y is not allowed, need 0-255 here";
		next;
	    }
	    #	    print "x, y, grey = $x $y $greypixel\n";
	    $is->{image}->set_pixel ($x, $y, $greypixel);
	}
    }
    return $is;
}

# # C<$libpng_ok> is set to a true value if Image::PNG::Libpng has
# # already successfully been loaded.

# my $libpng_ok;

# # Load Image::PNG::Libpng.

# sub load_libpng
# {
#     if ($libpng_ok) {
# 	return 1;
#     }
#     my $use_ok = eval "use Image::PNG::Libpng;";
#     if (! $use_ok || $@) {
# 	carp "Error loading Image::PNG::Libpng: $@";
# 	return;
#     }
#     $libpng_ok = 1;
#     return 1;
# }

sub rgb_to_grey
{
    my ($r, $g, $b) = @_;
    my $grey = red * $r + green * $g + blue * $b;
    $grey = round ($grey);
    return $grey;
}

sub load_image_libpng
{
    my ($image) = @_;
    #    load_libpng () or return;
    my $ihdr = $image->get_IHDR ();
    my $height = $ihdr->{height};
    my $width = $ihdr->{width};
    my $is = Image::Similar->new (height => $height,
				  width => $width);
    my $rows = $image->get_rows ();
    if ($ihdr->{bit_depth} != png_bit_depth) {
	carp "Cannot handle PNG images of bit depth $ihdr->{bit_depth}";
	return undef;
    }
    if ($ihdr->{color_type} == PNG_COLOR_TYPE_GRAY) {
	# GRAY
	for my $y (0..$height-1) {
	    for my $x (0..$width-1) {
		my $grey = ord (substr ($rows->[$y], $x, 1));
		$is->{image}->set_pixel ($x, $y, $grey);
	    }
	}
    }
    elsif ($ihdr->{color_type} == PNG_COLOR_TYPE_GRAY_ALPHA) {
	# GRAY_ALPHA
	carp 'Discarding alpha channel and ignoring background';
	for my $y (0..$height-1) {
	    for my $x (0..$width-1) {
		my $grey = ord (substr ($rows->[$y], $x * 2, 1));
		$is->{image}->set_pixel ($x, $y, $grey);
	    }
	}
    }
    elsif ($ihdr->{color_type} == PNG_COLOR_TYPE_RGB ||
	   $ihdr->{color_type} == PNG_COLOR_TYPE_RGB_ALPHA) {
	# RGB or RGBA

	# $offset is the number of bytes per pixel.
	my $offset = rgb_bytes;
	if ($ihdr->{color_type} == PNG_COLOR_TYPE_RGB_ALPHA) {
	    $offset = rgba_bytes;
	    # We should try to use the alpha channel to blend in a
	    # background colour here, but we don't.
	    carp 'Discarding alpha channel and ignoring background';
	}
	for my $y (0..$height-1) {
	    for my $x (0..$width-1) {
		my $r = ord (substr ($rows->[$y], $x * $offset, 1));
		my $g = ord (substr ($rows->[$y], $x * $offset + 1, 1));
		my $b = ord (substr ($rows->[$y], $x * $offset + 2, 1));
		# https://metacpan.org/pod/distribution/Imager/lib/Imager/Transformations.pod
		my $grey = rgb_to_grey ($r, $g, $b);
		$is->{image}->set_pixel ($x, $y, $grey);
	    }
	}
    }
    elsif ($ihdr->{color_type} == PNG_COLOR_TYPE_PALETTE) {
	my $palette = $image->get_PLTE ();
	my @grey;
	my $i = 0;
	for my $colour (@{$palette}) {
	    my $r = $colour->{red};
	    my $g = $colour->{green};
	    my $b = $colour->{blue};
	    $grey[$i] = rgb_to_grey ($r, $g, $b);
	    $i++;
	}
	for my $y (0..$height-1) {
	    for my $x (0..$width-1) {
		my $grey = $grey [ord (substr ($rows->[$y], $x, 1))];
		$is->{image}->set_pixel ($x, $y, $grey);
	    }
	}
    }
    else {
	carp "Cannot handle image of colour type $ihdr->{color_type}";
	return undef;
    }
    return $is;
}

sub load_image
{
    my ($image) = @_;
    my $is;
    my $imtype = ref $image;
    if ($imtype eq 'Imager') {
	$is = load_image_imager ($image);
    }
    elsif ($imtype eq 'Image::PNG::Libpng') {
	$is = load_image_libpng ($image);
    }
    elsif ($imtype eq 'GD::Image') {
	$is = load_image_gd ($image);
    }
    else {
	carp "Unknown object type $imtype, cannot load this image";
	return undef;
    }
    $is->fill_grid ();
    return $is;
}

sub load_signature
{
    my ($sig) = @_;
    my $is = bless {}, 'Image::Similar';
    $is->{image} = Image::Similar::Image::fill_from_sig ($sig);
    return $is;
}

sub sig_diff
{
    my ($is, $sig) = @_;
    # Get the signature out of the image
    my $image1 = $is->{image};
    my $image2 = Image::Similar::Image::fill_from_sig ($sig);
    # Compare the two signatures and put the result in "diff".
    my $diff = Image::Similar::Image::image_diff ($image1, $image2);
    return $diff;
}

sub Image::Similar::write_png
{
    my ($is, $filename) = @_;
    if ($is->{image}->valid_image ()) {
	#    load_libpng () or return;
	my $png = Image::PNG::Libpng::create_write_struct ();
	$png->set_IHDR ({
	    height => $is->{height},
	    width => $is->{width},
	    bit_depth => 8,
	    color_type => 0, # Image::PNG::Const::PNG_COLOR_TYPE_GRAY,
	});
	my $rows = $is->{image}->get_rows ();
	if (scalar (@{$rows}) != $is->{height}) {
	    die "Error: bad numbers: $is->{height} != " . scalar (@{$rows});
	}
	$png->set_rows ($rows);
	$png->write_png_file ($filename);
    }
    else {
	carp 'This object does not contain valid image data';
    }
    return;
}

sub diff
{
    my ($s1, $s2) = @_;
    return $s1->{image}->image_diff ($s2->{image});
}

sub signature
{
    my ($s) = @_;
    return $s->{image}->signature ();
}

1;
