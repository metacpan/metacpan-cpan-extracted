
# This file is just a list of exports and documentation. The source
# code for this file is in Libpng.xs in the top directory.

package Image::PNG::Libpng;
use warnings;
use strict;

require Exporter;
use Carp;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/
	create_read_struct
	create_write_struct
	destroy_read_struct
	destroy_write_struct
	write_png
	init_io
	read_info
	read_update_info
	read_image
	read_png
	get_text
	set_text
	sig_cmp
	scalar_as_input
	read_from_scalar
	color_type_name
	text_compression_name
	get_libpng_ver
	access_version_number
	get_row_pointers
	get_rows
	get_rowbytes
	get_valid
	set_tRNS_pointer
	set_rows
	write_to_scalar
	set_filter
	set_verbosity
	set_unknown_chunks
	get_unknown_chunks
	libpng_supports
	set_keep_unknown_chunks
	get_tRNS_palette
	set_PLTE_pointer
	set_expand
	set_gray_to_rgb
	set_filler
	get_sRGB
	set_sRGB
	set_packing
	set_strip_16
	get_internals
	set_transforms
	copy_row_pointers
	get_bKGD
	set_bKGD
	get_cHRM
	set_cHRM
	get_gAMA
	set_gAMA
	get_hIST
	set_hIST
	get_iCCP
	set_iCCP
	get_IHDR
	set_IHDR
	get_oFFs
	set_oFFs
	get_pCAL
	set_pCAL
	get_pHYs
	set_pHYs
	get_PLTE
	set_PLTE
	get_sBIT
	set_sBIT
	get_sCAL
	set_sCAL
	get_sPLT
	set_sPLT
	get_tIME
	set_tIME
	get_tRNS
	set_tRNS
read_png_file
write_png_file
color_type_name
get_internals
copy_png
image_data_diff
png_compare
/;

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

require XSLoader;
our $VERSION = '0.43';

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
	croak "Use get_rows";
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
    my $png1 = read_png_file ($file1, transforms => PNG_TRANSFORM_EXPAND);
    my $png2 = read_png_file ($file2, transforms => PNG_TRANSFORM_EXPAND);
    my $ihdr1 = $png1->get_IHDR ();
    my $ihdr2 = $png2->get_IHDR ();
    my @fields = qw/height width/;
    for my $field (@fields) {
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
		    printf ("%02X,%02X ", $bytes1[$byte], $bytes2[$byte]);
		}
		print "\n";
	    }
	    return "Row $r of image data differs";
	}
    }
    # No difference.
    return;
}

sub png_compare
{
    my ($file1, $file2, %options) = @_;
    my $png1 = read_png_file ($file1, transforms => PNG_TRANSFORM_EXPAND);
    my $png2 = read_png_file ($file2, transforms => PNG_TRANSFORM_EXPAND);
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

1;

# Local Variables:
# mode: perl
# End:
