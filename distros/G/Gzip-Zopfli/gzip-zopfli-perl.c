typedef struct {
    /* Gzip, zlib or libdeflate. */
    int type;
    /* See zopfli.h. */
    ZopfliOptions options;
    unsigned int no_warn : 1;
}
gzip_zopfli_t;

void
gzip_zopfli_init (gzip_zopfli_t * gz)
{
    gz->type = ZOPFLI_FORMAT_GZIP;
    ZopfliInitOptions (& gz->options);
}

#define CMP(x, y) strlen(#y) == x ## _len && strcmp(#y, x) == 0
#define TYPE(x) strlen (#x) == type_len && strcmp (#x, type) == 0

static void
gzip_zopfli_set (gzip_zopfli_t * gz, SV * key_sv, SV * value)
{
    char * key;
    STRLEN key_len;
    key = SvPV (key_sv, key_len);
	
    if (CMP(key, no_warn)) {
	if (SvTRUE (value)) {
	    gz->no_warn = 1;
	}
	else {
	    gz->no_warn = 0;
	}
	return;
    }

    if (CMP(key, numiterations)) {
	int n;
	if (! SvIOK (value)) {
	    warn ("numiterations requires a number");
	}
	n = SvIV (value);
	// Check values
	gz->options.numiterations = n;
	return;
    }
    if (CMP (key, blocksplitting)) {
	gz->options.blocksplitting = SvTRUE (value);
	return;
    }
    if (CMP (key, blocksplittingmax)) {
	if (! SvIOK (value)) {
	    warn ("blocksplittingmax requires a number");
	}
	gz->options.blocksplittingmax = SvIV (value);
	return;
    }
    if (CMP (key, type)) {
	char * type;
	STRLEN type_len;
	type = SvPV (value, type_len);
	if (TYPE(gzip)) {
	    gz->type = ZOPFLI_FORMAT_GZIP;
	    return;
	}
	if (TYPE(deflate)) {
	    gz->type = ZOPFLI_FORMAT_DEFLATE;
	    return;
	}
	if (TYPE(zlib)) {
	    gz->type = ZOPFLI_FORMAT_ZLIB;
	    return;
	}
	warn ("Unknown compression type '%s'", type);
	return;
    }
    if (! gz->no_warn) {
	warn ("Unknown option '%s'", key);
    }
    return;
}

#undef CMP
#undef TYPE

SV *
gzip_zopfli (gzip_zopfli_t * gz, SV * in_sv)
{
    SV * out_sv;
    const unsigned char * in;
    STRLEN inl;
    unsigned char * out;
    size_t out_size;
    in = (const unsigned char *) SvPV(in_sv, inl);
    out = 0;
    out_size = 0;
    ZopfliCompress(& gz->options, gz->type,
		   in, (size_t) inl,
		   & out, & out_size);
    out_sv = newSVpv ((const char *) out, out_size);
    return out_sv;
}
