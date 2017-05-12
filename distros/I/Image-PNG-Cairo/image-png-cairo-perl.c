
static png_byte **
fill_png_from_cairo_surface (cairo_surface_t * surface,
			     png_structp png, png_infop info)
{
    int format;
    int width;
    int height;
    png_byte ** row_pointers = NULL;
    int y;
    const int pixel_bytes = 4;
    unsigned char * data;

    //    printf ("%p %p %p\n", surface, png, info);
    
    format = cairo_image_surface_get_format (surface);
    if (format != CAIRO_FORMAT_ARGB32) {
	croak ("unhandled format %d", format);
	// die, we don't know what to do with the other formats.
    }
    cairo_surface_flush (surface);
    width = cairo_image_surface_get_width (surface);
    height = cairo_image_surface_get_height (surface);
    if (! width || ! height) {
	croak ("zero width %d or height %d", width, height);
    }
    data = cairo_image_surface_get_data (surface);
    png_set_IHDR (png, info, width, height, 8, PNG_COLOR_TYPE_RGB_ALPHA,
		  PNG_INTERLACE_NONE, PNG_COMPRESSION_TYPE_DEFAULT,
		  PNG_FILTER_TYPE_DEFAULT);
    Newx (row_pointers, height, png_byte *);
    for (y = 0; y < height; ++y) {
        row_pointers[y] = data
                        + width * pixel_bytes * y;
    }
    return row_pointers;
}
