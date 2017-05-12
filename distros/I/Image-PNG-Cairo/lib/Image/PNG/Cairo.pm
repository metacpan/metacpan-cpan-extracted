package Image::PNG::Cairo;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/cairo_to_png/;
%EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
use warnings;
use strict;
use Carp;
our $VERSION = '0.08';
require XSLoader;
XSLoader::load ('Image::PNG::Cairo', $VERSION);
use Cairo;
use Image::PNG::Libpng qw/create_write_struct get_internals/;
use Image::PNG::Const qw/PNG_TRANSFORM_BGR/;

sub cairo_to_png
{
    my ($surface) = @_;
    if (ref $surface ne 'Cairo::ImageSurface') {
	croak "Bad input " . ref ($surface) . ": require Cairo::ImageSurface";
    }
    my $png = create_write_struct ();
    my ($pngs, $info) = get_internals ($png);
    my $row_pointers = fill_png_from_cairo_surface ($surface, $pngs, $info);
    # Set up the transforms of data.
    $png->set_transforms (PNG_TRANSFORM_BGR);
    $png->copy_row_pointers ($row_pointers);
    free_row_pointers ($row_pointers);
    return $png;
}

1;
