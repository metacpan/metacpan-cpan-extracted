/* Fetch a value "field" from a hash. */

#define HASH_FETCH_PV(hash,field) {                             \
        SV * field_sv;                                          \
	SV ** field_sv_ptr = hv_fetch (hash, #field,		\
				       strlen (#field), 0);	\
	if (! field_sv_ptr) {					\
	    fprintf (stderr, "%s:%d: "				\
		     "Field '%s' in '%s' not valid.\n",		\
		     __FILE__, __LINE__,			\
		     #field, #hash);				\
	    return;						\
	}							\
	field_sv = * field_sv_ptr;				\
        field = SvPV (field_sv, field ## _length);              \
    }


typedef struct
{
    SV * png_image;
}
scalar_as_image_t;

static void
perl_png_scalar_write (png_structp png, png_bytep bytes_to_write,
                       png_size_t byte_count_to_write)
{
    scalar_as_image_t * si;

    si = png_get_io_ptr (png);
    if (si->png_image == 0) {
        si->png_image = newSVpv ((char *) bytes_to_write, byte_count_to_write);
    }
    else {
        sv_catpvn (si->png_image, (char *) bytes_to_write, byte_count_to_write);
    }
}


void
qrpng_internal (HV * options)
{
    char * text;
    unsigned text_length;
    qr_t qr = {0};
    qrpng_t qrpng = {0};
    SV ** sv_ptr;
    qrpng_status_t qrpng_status;
    SV ** size_ptr;

    /* Get the text. This is assumed to exist. */
    
    HASH_FETCH_PV (options, text);

    qr.input = text;
    qr.input_length = text_length;

    qr.level = 1;

    sv_ptr = hv_fetch (options, "level", strlen ("level"), 0);
    if (sv_ptr) {
	qr.level = SvUV (* sv_ptr);
    }
    if (qr.level < 1 || qr.level > 4) {
	croak ("Bad level %d; this is between 1 and 4", qr.level);
    }

    sv_ptr = hv_fetch (options, "version", strlen ("version"), 0);
    if (sv_ptr) {
	qr.version = SvUV (* sv_ptr);
	if (qr.version < 1 || qr.version > 40) {
	    croak ("Bad version %d; this is between 1 and 40", qr.version);
	}
	initecc (& qr);
    }
    else {
	initeccsize (& qr);
    }
    initframe(& qr);

    qrencode (& qr);
    
    sv_ptr = hv_fetch (options, "quiet", strlen ("quiet"), 0);
    if (sv_ptr) {
	SV * quiet_sv;
	quiet_sv = * sv_ptr;
	qrpng.quietzone = SvUV (quiet_sv);
    }
    else {
	qrpng.quietzone = QUIETZONE;
    }

    sv_ptr = hv_fetch (options, "scale", strlen ("scale"), 0);
    if (sv_ptr) {
	SV * scale_sv;
	scale_sv = * sv_ptr;
	qrpng.scale = SvUV (scale_sv);
    }
    else {
	qrpng.scale = 3;
    }

    qrpng_status = qrpng_make_png (& qr, & qrpng);

    if (qrpng_status != qrpng_ok) {
	croak ("bad status %d from qrpng_make_png", qrpng_status);
    }
    sv_ptr = hv_fetch (options, "out_sv", strlen ("out_sv"), 0);
    if (sv_ptr) {

	/* Write it as a scalar. The code is copied out of
	   Image::PNG::Libpng, but we don't depend on that. */

	scalar_as_image_t si = {0};

	png_set_write_fn (qrpng.png, & si, perl_png_scalar_write,
			  0 /* No flush function */);

	/* Write using our function. */

	png_write_png (qrpng.png, qrpng.info,
		       PNG_TRANSFORM_INVERT_MONO, NULL);

	/* Put the data into %options as $options{png_data}. */

	(void) hv_store (options, "png_data", strlen ("png_data"),
			 si.png_image, 0);
    }
    else {
	char * out;
	unsigned int out_length;
	HASH_FETCH_PV (options, out);
	qrpng.filename = out;
	qrpng_write (& qrpng);
    }
    size_ptr = hv_fetch (options, "size", strlen ("size"), 0);
    if (size_ptr) {
//	fprintf (stderr, "%s:%d: OK baby.\n", __FILE__, __LINE__);
	if (SvROK (* size_ptr) && SvTYPE (SvRV (* size_ptr)) < SVt_PVAV) {
	    SV * sv = SvRV (* size_ptr);
//	    fprintf (stderr, "%s:%d: OK baby.\n", __FILE__, __LINE__);
	    sv_setuv (sv, (UV) qrpng.img_size);
	}
    }
    qrfree (& qr);
    qrpng_free (& qrpng);
}
