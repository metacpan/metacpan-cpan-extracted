
# This file is just a list of exports and documentation. The source
# code for this file is in Libpng.xs in the top directory.

package Image::PNG::Libpng;
use warnings;
use strict;

require Exporter;
use Carp;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/
	access_version_number
	color_type_channels
	color_type_name
	copy_row_pointers
	create_read_struct
	create_write_struct
	destroy_read_struct
	destroy_write_struct
	get_IHDR
	get_PLTE
	get_bKGD
	get_bit_depth
	get_cHRM
	get_cHRM_XYZ
	get_channels
	get_chunk_cache_max
	get_chunk_malloc_max
	get_color_type
	get_compression_buffer_size
	get_eXIf
	get_gAMA
	get_hIST
	get_iCCP
	get_interlace_type
	get_internals
	get_libpng_ver
	get_oFFs
	get_pCAL
	get_pHYs
	get_palette_max
	get_pixel
	get_rgb_to_gray_status
	get_rowbytes
	get_rows
	get_sBIT
	get_sCAL
	get_sPLT
	get_sRGB
	get_tIME
	get_tRNS
	get_tRNS_palette
	get_text
	get_unknown_chunks
	get_valid
	init_io
	init_io_x
	libpng_supports
	permit_mng_features
	read_end
	read_from_scalar
	read_image
	read_info
	read_png
	read_struct
	read_update_info
	scalar_as_input
	set_IHDR
	set_PLTE
	set_add_alpha
	set_alpha_mode
	set_bKGD
	set_back
	set_background
	set_bgr
	set_cHRM
	set_cHRM_XYZ
	set_chunk_cache_max
	set_chunk_malloc_max
	set_compression_buffer_size
	set_compression_level
	set_compression_mem_level
	set_compression_method
	set_compression_strategy
	set_compression_window_bits
	set_crc_action
	set_eXIf
	set_expand
	set_expand_16
	set_expand_gray_1_2_4_to_8
	set_filler
	set_filter
	set_gAMA
	set_gamma
	set_gray_to_rgb
	set_hIST
	set_iCCP
	set_image_data
	set_invert_alpha
	set_invert_mono
	set_keep_unknown_chunks
	set_oFFs
	set_pCAL
	set_pHYs
	set_packing
	set_packswap
	set_palette_to_rgb
	set_quantize
	set_rgb_to_gray
	set_row_pointers
	set_rows
	set_sBIT
	set_sCAL
	set_sPLT
	set_sRGB
	set_scale_16
	set_strip_16
	set_strip_alpha
	set_swap
	set_swap_alpha
	set_tIME
	set_tRNS
	set_tRNS_pointer
	set_tRNS_to_alpha
	set_text
	set_text_compression_level
	set_text_compression_mem_level
	set_text_compression_strategy
	set_text_compression_window_bits
	set_transforms
	set_unknown_chunks
	set_user_limits
	set_verbosity
	sig_cmp
	split_alpha
	text_compression_name
	write_end
	write_image
	write_info
	write_png
	write_to_scalar
	copy_png
	create_reader
	create_writer
	get_contents
	get_internals
	image_data_diff
	png_compare
	read_png_file
	split_alpha
	write_png_file
/;

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

require XSLoader;
our $VERSION = '0.57';

XSLoader::load('Image::PNG::Libpng', $VERSION);

use Image::PNG::Const ':all';

# Old undocumented function name

sub read_file
{
    goto & read_png_file;
}

# Old undocumented function name

sub write_file
{
    goto & write_png_file;
}

sub read_png_file
{
    my ($file_name, %options) = @_;
    my $png = create_read_struct ();
    if ($options{transforms}) {
	$png->set_transforms ($options{transforms});
    }
    if ($options{verbosity}) {
	$png->set_verbosity ($options{verbosity});
    }
    open my $in, "<:raw", $file_name
        or croak "Cannot open '$file_name' for reading: $!";
    $png->init_io ($in);
    $png->read_png ();
    close $in or croak $!;
    return $png;
}

sub write_png_file
{
    my ($png, $file_name) = @_;
    if ($png->read_struct ()) {

	# The following is more convenient but might not work in some
	# cases, depending on how libpng handles different
	# transformations and so on, so I don't really want to risk
	# it.

	# my $copy = $png->copy_png ();
	# write_png_file ($copy, $file_name);
	# return;

	croak "The png is a read structure, use copy_png to copy it to a write structure";
    }
    if (! $file_name) {
	croak "Supply a file name";
    }
    open my $in, ">:raw", $file_name
        or croak "Cannot open '$file_name' for writing: $!";
    $png->init_io ($in);
    $png->write_png ();
    close $in or croak $!;
}

my %known_chunks = (

bKGD => 1,

cHRM => 1,





gAMA => 1,

hIST => 1,



iCCP => 1,

IDAT => 1,





oFFs => 1,

pCAL => 1,

pHYs => 1,

PLTE => 1,

sBIT => 1,

sCAL => 1,

sPLT => 1,

sRGB => 1,



tIME => 1,

tRNS => 1,



);

sub get_chunk
{
    my ($png, $chunk) = @_;
    if ($chunk eq 'IDAT') {
	croak "Use get_rows";
    }
    if ($known_chunks{$chunk}) {
	no strict 'refs';
	my $sub = "get_$chunk";
	return &$sub ($png); 
    }
    return undef;
}

sub set_chunk
{
    my ($png, $chunk, $value) = @_;
    if ($chunk eq 'IDAT') {
	croak "Use set_rows";
    }
    if ($known_chunks{$chunk}) {
	no strict 'refs';
	my $sub = "set_$chunk";
	return &$sub ($png, $value); 
    }
    croak "Unknown chunk $chunk";
}

sub copy_png
{
    my ($png, %options) = @_;
    my $opng = create_write_struct ();
    if ($options{verbosity}) {
	$opng->set_verbosity ($options{verbosity});
    }
    my $strip = $options{strip};
    my $strip_all;
    if ($strip) {
	if ($strip eq 'all') {
	    $strip_all = 1;
	}
    }
    my $valid = $png->get_valid ();
    $opng->set_IHDR ($png->get_IHDR ());
    my $rows = $png->get_rows ();
    $opng->set_rows ($rows);

    # Set PLTE up first because hIST needs it to be set.
    if ($valid->{PLTE}) {
	$opng->set_chunk ('PLTE', $png->get_chunk ('PLTE'));
    }
    if (! $strip_all) {
	# Make a list of valid chunks excluding IHDR (header), IDAT
	# (image data), and PLTE (palette).
	my @valid = grep {!/IHDR|IDAT|PLTE/ && $valid->{$_}} sort keys %$valid;
	for my $chunk (@valid) {
	    $opng->set_chunk ($chunk, $png->get_chunk ($chunk));
	}
    }
    return $opng;
}


sub width
{
    goto & get_image_width;
}

sub height
{
    goto & get_image_height;
}


sub image_data_diff
{
    my ($file1, $file2, %options) = @_;
    my $transforms = PNG_TRANSFORM_EXPAND | PNG_TRANSFORM_GRAY_TO_RGB;
    my $png1 = read_png_file ($file1, transforms => $transforms);
    my $png2 = read_png_file ($file2, transforms => $transforms);
    my $ihdr1 = $png1->get_IHDR ();
    my $ihdr2 = $png2->get_IHDR ();
    my @fields = qw/height width/;
    for my $field (@fields) {
	print "$field: $ihdr1->{$field} != $ihdr2->{$field}\n";
	if ($ihdr1->{$field} != $ihdr2->{$field}) {
	    return "$field differs: $file1: ".
	    "$ihdr1->{field}; $file2: $ihdr2->{field}";
	}
    }
    my $h = $ihdr1->{height};
    my $rows1 = $png1->get_rows ();
    my $rows2 = $png2->get_rows ();
    for my $r (0..$h - 1) {
 	my $row1 = $rows1->[$r];
	my $row2 = $rows2->[$r];
	if ($row1 ne $row2) {
	    if ($options{print_bytes}) {
		my @bytes1 = unpack "C*", $row1;
		my @bytes2 = unpack "C*", $row2;
		for my $byte (0..$#bytes1) {
		    if ($bytes1[$byte] != $bytes2[$byte]) {
			printf 'byte %0d: %02X,%02X' . "\n", $byte,
				$bytes1[$byte], $bytes2[$byte];
		    }
		}
		print "\n";
	    }
	    return "Row $r of image data differs";
	}
    }
    # No difference.
    return undef;
}

sub png_compare
{
    my ($file1, $file2, %options) = @_;
    my $transforms = PNG_TRANSFORM_EXPAND | PNG_TRANSFORM_GRAY_TO_RGB;
    my $png1 = read_png_file ($file1, transforms => $transforms);
    my $png2 = read_png_file ($file2, transforms => $transforms);
    my $ihdr1 = $png1->get_IHDR ();
    my $ihdr2 = $png2->get_IHDR ();
    my @fields = qw/height width/;
    for my $field (@fields) {
	if ($ihdr1->{$field} != $ihdr2->{$field}) {
	    return 1;
	}
    }
    my $h = $ihdr1->{height};
    my $rows1 = $png1->get_rows ();
    my $rows2 = $png2->get_rows ();
    for my $r (0..$h - 1) {
 	my $row1 = $rows1->[$r];
	my $row2 = $rows2->[$r];
	if ($row1 ne $row2) {
	    return 1;
	}
    }
    # No difference.
    return 0;
}

sub create_reader
{
    my ($file) = @_;
    open my $in, "<:raw", $file or croak "Can't open '$file': $!";
    my $png = create_read_struct ();
    $png->init_io ($in);
    return $png;
}

sub create_writer
{
    my ($file) = @_;
    open my $in, ">:raw", $file or croak "Can't open '$file': $!";
    my $png = create_write_struct ();
    $png->init_io ($in);
    return $png;
}

# This is a helper for pnginspect which pulls out the information from
# a PNG file and sticks it into a hash. 

sub get_contents
{
    # The PNG "file" might also be some data pulled from the web and
    # not saved to a file, so the fields $name and $size in the
    # argument list might be a URL and the size of a bit of binary
    # data in Perl's memory.
    my ($png, $name, $size) = @_;
    if (! $name) {
	croak "No name";
    }
    if (! $size || $size !~ /^[0-9]+$/) {
	croak "No size or bad size";
    }
    my %contents;
    $contents{name} = $name;
    $contents{size} = $size;
    $contents{ihdr} = $png->get_IHDR ();
    my $valid = $png->get_valid ();
    for my $key (%$valid) {
	if ($key eq 'IDAT') {
	    $contents{IDAT} = 'OK';
	}
	else {
	    $contents{$key} = $png->get_chunk ($key);
	}
    }
    $contents{text} = $png->get_text ();
    return \%contents;
}

1;

# Local Variables:
# mode: perl
# End:
