typedef struct {
    png_struct * png;
    png_info * info;
    png_uint_32 width;
    png_uint_32 height;
    int bit_depth;
    int color_type;
    int interlace_type;
    int channels;
    png_uint_32 rowbytes;
    png_bytepp rows;
}
image_png_data_t;

static SV *
image_png_data_alpha_unused (image_png_data_t * data)
{
    int i;
    int bytes;
    int max;
    int ch = data->channels;

    if (data->bit_depth == 8) {
	bytes = 1;
	max = 0xFF;
    }
    else if (data->bit_depth == 16) {
	bytes = 2;
	max = 0xFFFF;
    }
    else {
	croak ("Alpha channel not possible in image with bit depth %d",
	       data->bit_depth);
    }
    if ((data->color_type & PNG_COLOR_MASK_ALPHA) == 0) {
	return &PL_sv_undef;
    }
    
    for (i = 0; i < data->height; i++) {
	int j;
	png_bytep row;
	row = data->rows[i];
	for (j = 0; j < data->width; j++) {
	    int q;
	    int alpha = 0;
	    int byte;
	    q = bytes * ch * j;
	    for (byte = 0; byte < bytes; byte++) {
		alpha *= 256;
		alpha += row[q + bytes * (ch - 1) + byte];
	    }
	    if (alpha != max) {
		/* At least one pixel has a non-opaque value for alpha,
		   so the alpha channel is being used. */
		return newSViv(0);
	    }
	}
    }
    /* We looked at all of the alpha pixels, and they were all equal
       to "max", so the alpha channel is unused. */
    return newSViv (1);
}

static void
image_png_data_bwpng (image_png_data_t * data)
{

}
