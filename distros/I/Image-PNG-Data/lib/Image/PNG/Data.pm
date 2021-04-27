package Image::PNG::Data;
use warnings;
use strict;
use Carp;
use utf8;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/
    alpha_unused
    any2gray8
    bwpng
    pngback
    pngpixelate
    pngmono
    rgb2gray
    rmalpha
/;

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

our $VERSION = '0.01';
require XSLoader;
XSLoader::load ('Image::PNG::Data', $VERSION);

use Image::PNG::Libpng ':all';
use Image::PNG::Const ':all';

# White background for either RGB or grayscale.

my %white = (red => 0xff, green => 0xff, blue => 0xff, gray => 0xff);

sub alpha_unused
{
    my ($png) = @_;
    my $data = png_to_data ($png);
    return alpha_unused_data ($data);
}

sub any2gray8
{
    my ($file, %options) = @_;
    my $reader = create_reader ($file);
    $reader->set_verbosity (1);
    $reader->read_info ();
    my $ihdr = $reader->get_IHDR ();
    my $bd = $ihdr->{bit_depth};
    my $ct = $ihdr->{color_type};
    if ($bd != 8) {
	if ($bd == 16) {
	    $reader->set_scale_16 ();
	}
	elsif ($bd < 8) {
	    # There is no GRAY_ALPHA with less than 8 bits, so don't
	    # worry about that.
	    if ($ct == PNG_COLOR_TYPE_GRAY) {
		$reader->set_expand_gray_1_2_4_to_8 ();
	    }
	    elsif ($ct == PNG_COLOR_TYPE_PALETTE) {
		$reader->set_palette_to_rgb ();
		$reader->set_rgb_to_gray ();
	    }
	    else {
		croak "Unknown color type $ct and bit-depth $bd combination in $file";
	    }
	}
	else {
	    croak "Unknown bit depth $bd in $file";
	}
    }
    if ($ct & PNG_COLOR_MASK_ALPHA) {
	# We need to add a background color.
	my $bkgd = $reader->get_bKGD ();
	if ($bkgd) {
	    $reader->set_background ($bkgd, PNG_BACKGROUND_GAMMA_SCREEN, 1);
	}
	elsif ($options{bkgd}) {
	    $reader->set_background ($bkgd, PNG_BACKGROUND_GAMMA_SCREEN, 1);
	}
	else {
	    $reader->set_background (\%white, PNG_BACKGROUND_GAMMA_SCREEN, 1);
	}
    }
    if ($ct & PNG_COLOR_MASK_COLOR) {
	$reader->set_rgb_to_gray ();
    }
    elsif ($ct == PNG_COLOR_TYPE_PALETTE) {
	$reader->set_palette_to_rgb ();
	$reader->set_rgb_to_gray ();
    }
    $reader->read_image ();
    $reader->read_end ();
    my $rows = $reader->get_rows ();
    my $wpng = create_write_struct ();
    my %ihdr = (
	height => $ihdr->{height},
	width => $ihdr->{width},
	color_type => PNG_COLOR_TYPE_GRAY,
	bit_depth => 8,
	interlace_type => $ihdr->{interlace_type},
    );
    $wpng->set_IHDR (\%ihdr);
    $wpng->set_rows ($rows);
    return $wpng;
}

sub pngmono
{
}

sub pngback
{
}

sub pngpixelate
{
}

sub bwpng
{
    my ($data, %o) = @_;
    if (ref $data ne 'ARRAY') {
	carp "bwpng needs an array reference as its argument";
	return undef;
    }
    my $png = create_write_struct ();
    my $ybits = scalar (@$data);
    my $xbits = 0;
    for (@$data) {
	my $l = length ($_) * 8;
	if ($l > $xbits)  {
	    $xbits = $l;
	}
    }
    my $ymultiple = 1;
    my $xmultiple = 1;
    if ($o{yblock}) {
	$ymultiple *= $o{yblock};
    }
    if ($o{xblock}) {
	$xmultiple *= $o{xblock};
    }
    if ($o{block}) {
	$xmultiple *= $o{block};
	$ymultiple *= $o{block};
    }
    my $color_type = PNG_COLOR_TYPE_GRAY;
    my $bit_depth = 1;
    my $palette;
    if ($o{fg} || $o{bg}) {
	$palette = 1;
	$color_type = PNG_COLOR_TYPE_PALETTE;
    }
    my $height = $ymultiple * $ybits;
    my $width = $xmultiple * $xbits;
    $png->set_IHDR ({height => $height, width => $width,
		     bit_depth => $bit_depth, color_type => $color_type});
    if ($o{invert}) {
	if ($palette) {
	    my $bg = $o{bg};
	    $o{bg} = $o{fg};
	    $o{fg} = $bg;
	}
	else {
	    $png->set_invert_mono ();
	}
    }
    if ($o{lsb_left}) {
	$png->set_packswap ();
    }
    if ($palette) {
	$png->set_PLTE ([color ($o{bg}), color ($o{fg})]);
    }
    if ($xmultiple > 1 || $ymultiple > 1) {
	my $rows = multiply_rows ($data, $xbits, $xmultiple, $ymultiple);
	$png->set_rows ($rows);
    }
    else {
	$png->set_rows ($data);
    }
    return $png;
}

sub multiply_rows
{
    my ($data, $xbits, $xm, $ym) = @_;
    my @mrows;
    # The number of bytes in each row of the data.
    my $xbytes = $xbits / 8;
    # The number of bytes in each row of the output.
    my $mbytes = $xbytes * $xm;
    my $ybits = scalar (@$data);
    for my $y (0..$ybits-1) {
	my $row = $data->[$y];
	my @xrow = (0) x $mbytes;
	for my $byte (0..$xbytes-1) {
	    my $char = ord (substr ($row, $byte, 1));
	    for my $bit (0..7) {
		my $x = $byte*8 + $bit;
		# The reason for the 7-$bit in the following is that
		# the default for pngs with bit depths less than 8 is
		# that the leftmost pixels correspond to the most
		# significant bits, and the rightmost pixels
		# correspond to the least significant bits.
		my $pixel = ($char >> (7-$bit)) & 1;
		if ($pixel) {
		    for my $c (0..$xm - 1) {
			# Offset of the pixel in the output in bits.
			my $offset = $x*$xm + $c;
			my $cbyte = int ($offset / 8);
			my $cbit = $offset % 8;
			# See comment above my $pixel for why the 7
			# here.
			$xrow[$cbyte] |= 1<<(7-$cbit);
		    }
		}
	    }
	}
	my $xrow;
	for (@xrow) {
	    $xrow .= chr ($_);
	}
	for (0..$ym-1) {
	    push @mrows, $xrow;
	}
    }
    return \@mrows;
}


sub color
{
    my ($color) = @_;
    if (ref $color eq 'HASH') {
	return $color;
    }
    return css2color ($color);
}

sub oneletter
{
    my ($letter) = @_;
    return hex ($letter . $letter);
}

sub css2color
{
    my ($color) = @_;
    my $orig = $color;
    $color =~ s/^#//;
    my %color;
    if (length ($color) == 3) {
	my ($r, $g, $b) = split '', $color;
	$color{red} = oneletter ($r);
	$color{green} = oneletter ($g);
	$color{blue} = oneletter ($b);
    }
    elsif (length ($color) == 6) {
	$color{red} = hex (substr ($color, 0, 2));
	$color{green} = hex (substr ($color, 2, 4));
	$color{blue} = hex (substr ($color, 4, 6));
    }
    else {
	carp "Failed to deal with CSS color '$orig'";
    }
    return \%color;
}

sub color2css
{

}

# Private

sub open_png
{
    my ($me, $file, $verbose) = @_;
    my $rpng;
    if (-f $file) {
	if ($verbose) {
	    vmsg ("opening '$file'");
	}
	$rpng = create_reader ($file);
	if (! $rpng) {
	    carp "$me: Image::PNG::Libpng::create_reader('$file') failed";
	    return undef;
	}
	return $rpng;
    }
    if (ref $file eq 'Image::PNG::Libpng') {
	if ($verbose) {
	    vmsg ("reading from an existing object");
	}
	return $file;
    }
    carp "$me: first argument not a file or an Image::PNG::Libpng object";
    return undef;
}

# Chunks which are only useful for RGB

my @rgbchunks = qw!cHRM iCCP!;

# Public

sub rgb2gray
{
    my $me = 'rgb2gray';
    my ($file, %options) = @_;
    my $verbose = $options{verbose};
    if ($verbose) {
	vmsg ("messages are on");
    }
    my $rpng = open_png ($me, $file, $verbose);
    if ($verbose) {
	vmsg ("reading color type");
    }
    $rpng->read_info ();
    my $ihdr = $rpng->get_IHDR ();
    my $ct = $ihdr->{color_type};
    if (! ($ct & PNG_COLOR_MASK_COLOR)) {
	carp "$me: '$file' does not contain RGB colors";
	return undef;
    }
    if ($verbose) {
	vmsg ("input color type is " . color_type_name ($ct));
    }
    if ($verbose) {
	vmsg ("reading image data");
    }
    $rpng->set_rgb_to_gray ();
    $rpng->read_image ();
    $rpng->read_end ();
    if ($options{grayonly}) {
	my $was_colorful = $rpng->get_rgb_to_gray_status ();
	if ($was_colorful) {
	    carp ("$me: option 'grayonly' but '$file' was RGB");
	    return undef;
	}
    }
    my $wpng = copy_png ($rpng);
    $ihdr->{color_type} = $ct & ~PNG_COLOR_MASK_COLOR;
    if ($verbose) {
	vmsg ("output color type is " . color_type_name ($ihdr->{color_type}));
    }
    $wpng->set_IHDR ($ihdr);
    if ($verbose) {
	vmsg ("finished creating PNG for writing");
    }
    return $wpng;
}

# Turn an Image::PNG::Libpng structure into an Image::PNG::Data
# structure.

sub png_to_data
{
    my ($png) = @_;
    my ($png_s, $png_i) = get_internals ($png);
    my $data = from_png ($png_s, $png_i);
    return $data;
}

# Public

sub rmalpha
{
    my $me = 'rmalpha';
    my ($file, %options) = @_;
    my $verbose = $options{verbose};
    if ($verbose) {
	vmsg ("messages are on");
    }
    my $rpng = open_png ($me, $file, $verbose);
    $rpng->read_info ();
    my $ihdr = $rpng->get_IHDR ();
    my $ct = $ihdr->{color_type};
    if (! ($ct & PNG_COLOR_MASK_ALPHA)) {
	carp "image does not contain an alpha channel";
	return undef;
    }
    $rpng->read_image ();
    my $rows = $rpng->get_rows ();
    my $alpha_used = alpha_used ($rpng, $rows);
    if (! $alpha_used) {
	if ($verbose) {
	    vmsg ("alpha channel is present but unused");
	}
	if ($verbose) {
	    vmsg ("re-reading $file");
	}
	$rpng = open_png ($me, $file, $verbose);
	$rpng->read_info ();
	$rpng->set_strip_alpha ();
	$rpng->read_image ();
	$rpng->read_end ();
	return copy_png ($rpng);
    }
    if ($options{unusedonly}) {
	carp "not all the pixels in '$file' are opaque";
	return undef;
    }
}

sub vmsg
{
    my ($msg) = @_;
    my @caller = caller (0);
    my (undef, $file, $line) = @caller;
    print "$file:$line: $msg\n";
}

1;
