#line 2 "tmpl/perl-libpng.c.tmpl"

/* This is the main file of Image::PNG::Libpng. This file is included
   in Libpng.xs when compiling. It is separated out from Libpng.xs to
   avoid the problems of editing a Perl XS file. */

/*
  Coding style:

  Use "color", "gray", etc. in code, documentation & variables, not
  "colour", "grey", as per libpng.

  2020-12-09 08:03:03 
*/

/*
  Coding style:

  Going forward, use the following variable naming: Perl variables are
  named using Hungarian notation with lower case and an underscore
  with a suffix indicating the Perl role, like 'hist_av' or 'phys_sv' or
  'sv_ptr'; libpng variables use native names like 'hist'.

  This avoids confusion with the macro/valid chunk argument names like
  'hIST'. This style is not fully implemented in this file yet.

  2020-12-19 09:03:41
*/

/*
  Coding style: 

  Going forward, as far as possible, use libpng types for all libpng
  variables, so use png_bytep etc rather than unsigned char *.

  2020-12-19 09:05:18 
*/

#if PNG_LIBPNG_VER_MAJOR >= 1 && PNG_LIBPNG_VER_MINOR >= 4 && PNG_LIBPNG_VER_RELEASE >= 0
#define PNG_CHUNK_CACHE_MAX_SUPPORTED
#define PNG_CHUNK_MALLOC_MAX_SUPPORTED
#endif /* version >= 1.4.0 */

/* The cHRM_XYZ functions are protected by the cHRM_SUPPORTED macro,
   but this doesn't actually apply since cHRM_SUPPORTED is defined
   even when png_(g|s)et_cHRM_XYZ are not available. */

#if PNG_LIBPNG_VER_MAJOR >= 1 && PNG_LIBPNG_VER_MINOR >= 5 && PNG_LIBPNG_VER_RELEASE >= 5
#ifdef PNG_cHRM_SUPPORTED
#define PNG_cHRM_XYZ_SUPPORTED
#endif /* PNG_cHRM_SUPPORTED */
#endif /* version >= 1.5.5 */

#ifndef PNG_FLOATING_POINT_SUPPORTED
#  error libpng support requires libpng to export the floating point APIs
#endif

/* What to do if the chunk is not supported by the libpng we compiled
   against. */

#define UNSUPPORTED(block)						\
    warn ("'%s' is not supported in this libpng", #block);

/* sCAL block support. This is complicated, see PNG mailing list
   archives. */

#ifdef PNG_sCAL_SUPPORTED
#if PNG_LIBPNG_VER >= 10500 ||				\
    (defined (PNG_FIXED_POINT_SUPPORTED) &&		\
     ! defined (PNG_FLOATING_POINT_SUPPORTED))
#define PERL_PNG_sCAL_s_SUPPORTED
#endif /* version or fixed point */
#endif /* PNG_sCAL_SUPPORTED */

/* The maximum value we put into a png_uint_16. */

#define PNG_UINT_16_MAX 65535

typedef struct
{
    int gray;
    int index;
    int red;
    int green;
    int blue;
    int alpha;
}
perl_png_pixel_t;

/* Container for PNG information. This corresponds to an
   "Image::PNG::Libpng" in Perl. */

typedef struct perl_libpng
{
    png_structp png;
    png_infop info;
    /* Member "end_info" is not used by Image::PNG::Libpng. */
    png_infop end_info;
    /* It is not easy for user programs to find out whether a
       png_structp is a read or write structure, and yet we do need to
       know that, so we keep our own information here. */
    enum {
	perl_png_unknown_obj,
	perl_png_read_obj,
	perl_png_write_obj,
    }
    type;
    /* Allocated memory which holds pointers to the start of the
       rows in the image. */
    png_bytepp row_pointers;
    /* Allocated memory which holds the image data itself. */
    png_bytep image_data;
    /* Number of times we have called "calloc"-like functions, for
       detecting memory leaks. */
    int memory_gets;
    /* Transforms to apply. */
    int transforms;

    /* Items for reading from a scalar */

    /* "scalar_data" points to the data from a PV. */
    char * scalar_data;
    /* "data_length" contains the length of the data in "scalar_data"
       is. */
    STRLEN data_length;
    /* How much of the data in "image_data" we have read. */
    int read_position;
    unsigned char * all_rows;

    size_t rowbytes;
    png_uint_32 width;
    png_uint_32 height;
    int bit_depth;
    int color_type;
    int channels;
    png_colorp palette;
    int n_palette;

    /* init_io file handle holder, we need this for "create_reader"
       and "create_writer" otherwise our FILE * gets closed by Perl
       when the SV goes out of scope. This holds the SV we got in
       "init_io" and increments its reference count so that the file
       doesn't get closed after the filehandle goes out of scope. Then
       when the "perl_libpng_t" object is destroyed by
       "perl_png_destroy", this gets its reference count
       decremented. */
    SV * io_sv;
    /* If the following variable is set to a true value, the module
       prints messages about what it is doing. */
    unsigned int verbosity : 1;
    /* Has input/output been initiated? We protect ourselves from
       crashes caused by dereferencing the FILE * pointer using
       this. */
    unsigned int init_io_done : 1;

    unsigned int row_pointers_ours : 1;

    unsigned int palette_checked : 1;

    unsigned int image_data_ok : 1;
}
perl_libpng_t;

typedef perl_libpng_t * Image__PNG__Libpng;

/* Convenient macro for libpng function arguments. */

#define pngi png->png, png->info

/* Get the transforms from the function argument or from the set value
   inside the PNG. */

#define GET_TRANSFORMS				\
    if (png->transforms) {			\
	if (! transforms) {			\
	    transforms = png->transforms;	\
	}					\
    }

/* The following macro is used to indicate to programmers reading this
   which arguments are "useless" (ignored) arguments from libpng which
   are always set to zero. It is not used for arguments which are set
   to zero for some other reason than because they are useless
   (e.g. flush functions which are set to zero because we don't need
   them). */

#define UNUSED_ZERO_ARG 0

//#define PERL_PNG_MESSAGES
#undef PERL_PNG_MESSAGES

/* Send a message. */

#ifdef PERL_PNG_MESSAGES
#define MESSAGE(x...) {                                 \
        if (png->verbosity) {                           \
            printf ("%s:%d: ", __FILE__, __LINE__);     \
            printf (x);                                 \
            printf ("\n");                              \
        }                                               \
    }
#else
#define MESSAGE(x...)
#endif

/*  _ _ _                                                  
   | (_) |__  _ __  _ __   __ _    ___ _ __ _ __ ___  _ __ 
   | | | '_ \| '_ \| '_ \ / _` |  / _ \ '__| '__/ _ \| '__|
   | | | |_) | |_) | | | | (_| | |  __/ |  | | | (_) | |   
   |_|_|_.__/| .__/|_| |_|\__, |  \___|_|  |_|  \___/|_|   
             |_|          |___/                            
    _                     _ _               
   | |__   __ _ _ __   __| | | ___ _ __ ___ 
   | '_ \ / _` | '_ \ / _` | |/ _ \ '__/ __|
   | | | | (_| | | | | (_| | |  __/ |  \__ \
   |_| |_|\__,_|_| |_|\__,_|_|\___|_|  |___/ */
                                         

/* The following functions are used to handle errors from libpng. See
   the create_read_struct and create_write_struct calls below. */

/* Error handler for libpng. */

static void
perl_png_error_fn (png_structp png_ptr, png_const_charp error_msg)
{
    /* An error from libpng sent via Perl's warning handler. */
    croak ("libpng error: %s\n", error_msg);
}

/* Warning handler for libpng. */

static void
perl_png_warning_fn (png_structp png_ptr, png_const_charp warning_msg)
{
    /* A warning from libpng sent via Perl's warning handler. */
    warn ("libpng warning: %s\n", warning_msg);
}


/*   ____      _      ___      __               
    / ___| ___| |_   ( _ )    / _|_ __ ___  ___ 
   | |  _ / _ \ __|  / _ \/\ | |_| '__/ _ \/ _ \
   | |_| |  __/ |_  | (_>  < |  _| | |  __/  __/
    \____|\___|\__|  \___/\/ |_| |_|  \___|\___|
                                                
        _                   _                       
    ___| |_ _ __ _   _  ___| |_ _   _ _ __ ___  ___ 
   / __| __| '__| | | |/ __| __| | | | '__/ _ \/ __|
   \__ \ |_| |  | |_| | (__| |_| |_| | | |  __/\__ \
   |___/\__|_|   \__,_|\___|\__|\__,_|_|  \___||___/ */
                                                 


/* The following is a debugging construction which is usually "off". */

#if 0
#define GABBLE_IN(x)			       \
    fprintf (stderr, "%s:%d: Get #%d of %s\n", \
	     __FILE__, __LINE__,	       \
	     png->memory_gets, #x)

#define GABBLE_OUT(x)				\
    fprintf (stderr, "%s:%d: Free #%d of %s\n",	\
	     __FILE__, __LINE__,		\
	     png->memory_gets, #x)
#else
#define GABBLE_IN(x)
#define GABBLE_OUT(x)
#endif /* 0 */

/* Get memory using the following in order to keep count of the number
   of objects in use at the end of execution, to ensure that there are
   no memory leaks. All allocation is done via Newxz ("calloc") rather
   than "malloc". */

#define GET_MEMORY(thing, number, type) {	\
        Newxz (thing, number, type);		\
        png->memory_gets++;                     \
	GABBLE_IN(thing);			\
    }

/* Free memory using the following in order to keep count of the
   number of objects still in use. */

#define PERL_PNG_FREE(thing) {   \
        png->memory_gets--;      \
        Safefree (thing);	 \
	GABBLE_OUT(thing);	 \
    }

static perl_libpng_t *
perl_png_allocate ()
{
    perl_libpng_t * png;
    GET_MEMORY (png, 1, perl_libpng_t);
    return png;
}

# define CREATE_ARGS                                            \
    PNG_LIBPNG_VER_STRING,                                      \
    png,                                                        \
    perl_png_error_fn,                                          \
    perl_png_warning_fn

perl_libpng_t *
perl_png_create_write_struct ()
{
    perl_libpng_t * png = perl_png_allocate ();
    png->png = png_create_write_struct (CREATE_ARGS);
    png->info = png_create_info_struct (png->png);
    png->end_info = 0;
    png->row_pointers = 0;
    png->type = perl_png_write_obj;
    return png;
}

perl_libpng_t *
perl_png_create_read_struct ()
{
    perl_libpng_t * png = perl_png_allocate ();
    png->png = png_create_read_struct (CREATE_ARGS);
    png->info = png_create_info_struct (png->png);
    png->row_pointers = 0;
    png->type = perl_png_read_obj;
    return png;
}

#undef CREATE_ARGS

/* Free the structure and do a simple memory leak check. */

static void free_png (perl_libpng_t * png)
{
    MESSAGE ("Freeing PNG memory.");
    if (png->row_pointers && png->row_pointers_ours) {
        PERL_PNG_FREE (png->row_pointers);
	png->row_pointers = 0;
	png->row_pointers_ours = 0;
    }
    if (png->image_data) {
        PERL_PNG_FREE (png->image_data);
    }
    if (png->memory_gets != 1) {
        /* The module's internal check for memory errors was tripped
           somehow. This probably indicates a bug in the module. */
        warn ("Memory leak detected: there are %d "
	      "allocated pieces of memory which have not "
	      "been freed.\n", png->memory_gets - 1);
    }
    Safefree (png);
}

static void
perl_png_destroy_write_struct (perl_libpng_t * png)
{
    return;

    /* See the documentation under "No destructors" for why this is
       commented out. */

    /*
    png_destroy_write_struct (& png->png, & png->info);
    free_png (png);
    */
}

static void
perl_png_destroy_read_struct (perl_libpng_t * png)
{
    return;

    /* See the documentation under "No destructors" for why this is
       commented out. */

    /*
    png_destroy_read_struct (& png->png, & png->info, & png->end_info);
    free_png (png);
    */
}

static void
perl_png_destroy (perl_libpng_t * png)
{
    if (! png) {
        return;
    }
    /* Free row data. */
    if (png->all_rows) {
	PERL_PNG_FREE (png->all_rows);
	png->all_rows = 0;
    }
    /* The io_sv holds any FILE * which we got from "init_io". We keep
       that scalar until now because otherwise Perl automatically
       closes the FILE * when the scalar goes out of scope. */
    if (png->io_sv) {
	SvREFCNT_dec (png->io_sv);
	png->io_sv = 0;
	png->memory_gets--;
    }
    if (png->type == perl_png_write_obj) {
        png_destroy_write_struct (& png->png, & png->info);
	png->png = 0;
	png->info = 0;
        free_png (png);
	png = 0;
    }
    else if (png->type == perl_png_read_obj) {
        png_destroy_read_struct (& png->png, & png->info, & png->end_info);
	png->png = 0;
	png->info = 0;
	png->end_info = 0;
        free_png (png);
	png = 0;
    }
    else {
        /* There was an attempt to free some corrupted memory. */
        croak ("Attempt to destroy an object of unknown type");
    }
}

/*  _____         _   
   |_   _|____  _| |_ 
     | |/ _ \ \/ / __|
     | |  __/>  <| |_ 
     |_|\___/_/\_\\__| */
                   

/* Create a scalar value from the "text" field of the PNG text chunk
   contained in "text_ptr". */

static SV * make_text_sv (perl_libpng_t * png, const png_textp text_ptr)
{
    SV * sv;
    char * text = 0;
    int length = 0;

    if (text_ptr->text) {
        text = text_ptr->text;
        if (text_ptr->text_length != 0) {
            length = text_ptr->text_length;
        }
#ifdef PNG_iTXt_SUPPORTED
        else if (text_ptr->itxt_length != 0) {
            length = text_ptr->itxt_length;
        }
#endif /* iTXt */
    }
    if (text && length) {

        /* "is_itxt" contains a true value if the text claims to be
           ITXT (international text) and also validates as UTF-8
           according to Perl. The PNG specifications require that ITXT
           text is UTF-8 encoded, but this routine checks that here
           using Perl's "is_utf8_string" function. */

        int is_itxt = 0;

        sv = newSVpvn (text, length);
        
        if (text_ptr->compression == PNG_ITXT_COMPRESSION_NONE ||
            text_ptr->compression == PNG_ITXT_COMPRESSION_zTXt) {

            is_itxt = 1;

            if (! is_utf8_string ((unsigned char *) text, length)) {
                warn ("According to its compression type, a text chunk "
		      "in the current PNG file claims to be ITXT but "
		      "Perl's 'is_utf8_string' says that its encoding "
		      "is invalid.");
                is_itxt = 0;
            }
        }
        if (is_itxt) {
            SvUTF8_on (sv);
        }
    }
    else {
        sv = newSV (0);
    }
    return sv;
}

#ifdef PNG_iTXt_SUPPORTED

/* Convert the "lang_key" field of a "png_text" structure into a Perl
   scalar. */

static SV * lang_key_to_sv (perl_libpng_t * png, const char * lang_key)
{
    SV * sv;
    if (lang_key) {
        int length;
        /* "lang_key" is supposed to be UTF-8 encoded. */
        int is_itxt = 1;

        length = strlen (lang_key);
        sv = newSVpv (lang_key, length);
        if (! is_utf8_string ((unsigned char *) lang_key, length)) {
            warn ( "A language key 'lang_key' member of a 'png_text' "
		   "structure in the file failed Perl's 'is_utf8_string' "
		   "test, which says that its encoding is invalid.");
            is_itxt = 0;
        }
        if (is_itxt) {
            SvUTF8_on (sv);
        }
    }
    else {
        sv = newSV (0);
    }
    return sv;
}

#endif /* #ifdef PNG_iTXt_SUPPORTED */

/* "text_fields" contains the names of the various fields in a
   "png_text" structure. The following routine uses these names to put
   the values of the png_text structure into a Perl hash. */

static const char * text_fields[] = {
    "compression",
    "key",
    "text",
    "lang",
    "lang_key",
    "text_length",
    "itxt_length",
};

/* "N_TEXT_FIELDS" is the number of text fields in a "png_text"
   structure which we want to preserve. */

#define N_TEXT_FIELDS (sizeof (text_fields) / sizeof (const char *))

/* "perl_png_textp_to_hash" creates a new Perl associative array from
   the PNG text values in "text_ptr". */

#ifdef PNG_tEXt_SUPPORTED

static HV *
perl_png_textp_to_hash (perl_libpng_t * png, const png_textp text_ptr)
{
    int i;
    /* Scalar values which will be added to elements of "text_hash". */
    SV * f[N_TEXT_FIELDS];
    HV * text_hash;

    text_hash = newHV ();
    f[0] = newSViv (text_ptr->compression);
    f[1] = newSVpv (text_ptr->key, strlen (text_ptr->key));
    /* Depending on whether the "text" field of "text_ptr" is a string
       or a null value, create an SV copy of it or create an SV which
       contains the undefined value. */
    f[2] = make_text_sv (png, text_ptr);
#ifdef PNG_iTXt_SUPPORTED
    if (text_ptr->lang) {
        /* According to section 4.2.3.3 of the PNG specification, the
           "lang" field of the "png_text" structure contains a
           language code according to the conventions of RFC 1766 (now
           superceded by RFC 3066), which is an ASCII based standard
           for describing languages, so it is not necessary to mark
           this as being in UTF-8. */
        f[3] = newSVpv (text_ptr->lang, strlen (text_ptr->lang));
    }
    else {
        /* The language code may be empty. */
        f[3] = &PL_sv_undef;
    }
    f[4] = lang_key_to_sv (png, text_ptr->lang_key);
#else
    f[3] = &PL_sv_undef;
    f[4] = &PL_sv_undef;
#endif /* iTXt */
    f[5] = newSViv (text_ptr->text_length);
#ifdef PNG_iTXt_SUPPORTED
    f[6] = newSViv (text_ptr->itxt_length);
#else
    f[6] = &PL_sv_undef;
#endif /* iTXt */

    for (i = 0; i < N_TEXT_FIELDS; i++) {
        if (!hv_store (text_hash, text_fields[i],
                       strlen (text_fields[i]), f[i], 0)) {
            fprintf (stderr, "hv_store failed.\n");
        }
    }

    return text_hash;
}
#endif /* tEXt_SUPPORTED */

static SV *
perl_png_get_text (perl_libpng_t * png)
{
    SV * text_ref;

    text_ref = & PL_sv_undef;

#ifdef PNG_tEXt_SUPPORTED
    int num_text = 0;
    png_textp text_ptr;

    png_get_text (pngi, & text_ptr, & num_text);
    if (num_text > 0) {
        int i;
        AV * text_chunks;

        MESSAGE ("Got some text:");
        text_chunks = newAV ();
        for (i = 0; i < num_text; i++) {
            HV * hash;
            SV * hash_ref;

            MESSAGE ("text %d:\n", i);
            
            hash = perl_png_textp_to_hash (png, text_ptr + i);
            hash_ref = newRV_noinc ((SV *) hash);
            av_push (text_chunks, hash_ref);
        }
        text_ref = newRV_noinc ((SV *) text_chunks);
    }
    else {
        MESSAGE ("There is no text:");
    }
#else
    UNSUPPORTED(tEXt);
#endif
    return text_ref;
}

/* The macro which SvPV consists of fouls things up with the STRLEN
   pointer if we try to use a function. */

#define SOFT_HASH_FETCH_PV(chunk, key) {			\
	SV ** sv_ptr;						\
	sv_ptr = hv_fetch (chunk, #key, strlen (#key), 0);	\
	if (sv_ptr) {						\
	    key = SvPV(*sv_ptr, key ## _length);		\
	} else {						\
	    key = 0;						\
	    key ## _length = 0;					\
	}							\
    }

/* Set a PNG text "text_out" from "chunk". */

static void
perl_png_set_text_from_hash (perl_libpng_t * png,
                             png_text * png_texts, int i, HV * chunk)
{
    png_text * text_out;
    int compression;
    char * key;
    STRLEN key_length;
    char * text = 0;
    STRLEN text_length;
    SV ** c_sv_ptr;
#ifdef PNG_iTXt_SUPPORTED
    char * lang = 0;
    STRLEN lang_length;
    char * lang_key = 0;
    STRLEN lang_key_length;
    int is_itxt = 0;
#endif /* PNG_iTXt_SUPPORTED */

    text_out = & png_texts[i];

    /* Check the compression field of the chunk */

    c_sv_ptr = hv_fetch (chunk, "compression", strlen ("compression"), 0);
    if (c_sv_ptr) {
	compression = SvIV (* c_sv_ptr);
    }
    else {
	MESSAGE ("Using default compression PNG_TEXT_COMPRESSION_NONE");
	compression = PNG_TEXT_COMPRESSION_NONE;
    }
    switch (compression) {
    case PNG_TEXT_COMPRESSION_NONE:
    case PNG_TEXT_COMPRESSION_zTXt:
        break;
#ifdef PNG_iTXt_SUPPORTED
    case PNG_ITXT_COMPRESSION_NONE:
    case PNG_ITXT_COMPRESSION_zTXt: 
        is_itxt = 1;
        break;
#endif /* PNG_iTXt_SUPPORTED */
    default:
	PERL_PNG_FREE(png_texts);
	croak ("Unknown compression %d", compression);
    }
    text_out->compression = compression;

    MESSAGE ("Getting key.");
    SOFT_HASH_FETCH_PV (chunk, key);
    if (key == 0) {
	PERL_PNG_FREE(png_texts);
	croak ("Text chunk %d has no 'key' field", i);
    }
    if (key_length < 1) {
	PERL_PNG_FREE(png_texts);
	croak ("Text chunk %d key field is empty", i);
    }
    if (key_length > 79) {
	PERL_PNG_FREE(png_texts);
	croak ("Text chunk %d key field is too long %d > 79",
	       i, (int) key_length);
    }
    text_out->key = (char *) key;
    /* Libpng documentation says it is OK to send NULLs here. */
    SOFT_HASH_FETCH_PV (chunk, text);
    text_out->text = (char *) text;
    text_out->text_length = text_length;
#ifdef PNG_iTXt_SUPPORTED
    if (is_itxt) {
	/* Set this in case it starts to be required by future
	   versions of libpng. */
	text_out->itxt_length = text_length;
	SOFT_HASH_FETCH_PV (chunk, lang);
	text_out->lang = (char *) lang;
	SOFT_HASH_FETCH_PV (chunk, lang_key);
	text_out->lang_key = (char *) lang_key;
    }
#endif /* PNG_iTXt_SUPPORTED */
}

/* Set the text chunks in the PNG. This actually pushes text chunks
   into the object rather than setting them (so it does not destroy
   already-set ones). */

static void
perl_png_set_text (perl_libpng_t * png, AV * text_chunks)
{
    int num_text;
    int i;
    png_text * png_texts;

#ifndef PNG_tEXt_SUPPORTED
    UNSUPPORTED(tEXt);
    return;
#endif

    num_text = av_len (text_chunks) + 1;
    MESSAGE ("You have %d text chunks.\n", num_text);
    if (num_text <= 0) {
        return;
    }
    /* This memory needs to be freed before we call "croak", hence we
        have to free this and then croak. */
    GET_MEMORY (png_texts, num_text, png_text);
    for (i = 0; i < num_text; i++) {
        SV ** chunk_pointer;

        MESSAGE ("Fetching chunk %d.\n", i);
        chunk_pointer = av_fetch (text_chunks, i, 0);
        if (! chunk_pointer) {
	    PERL_PNG_FREE(png_texts);
	    croak ("Null chunk pointer");
        }
        if (SvROK (* chunk_pointer) && 
            SvTYPE (SvRV (* chunk_pointer)) == SVt_PVHV) {
	    perl_png_set_text_from_hash (png, png_texts, i,
					 (HV *) SvRV (* chunk_pointer));
        }
	else {
	    PERL_PNG_FREE(png_texts);
	    croak ("Element %d of text_chunks is not a hash reference", i);
	}
    }
    png_set_text (pngi, png_texts, num_text);
    PERL_PNG_FREE (png_texts);
}

/*  _____ _                
   |_   _(_)_ __ ___   ___ 
     | | | | '_ ` _ \ / _ \
     | | | | | | | | |  __/
     |_| |_|_| |_| |_|\___| */
                        


/* The following time fields are used in "perl_png_timep_to_hash" for
   converting the PNG modification time structure ("png_time") into a
   Perl associative array. */

static const char * time_fields[] = {
    "year",
    "month",
    "day",
    "hour",
    "minute",
    "second"
};

#define N_TIME_FIELDS (sizeof (time_fields) / sizeof (const char *))

/* "perl_png_timep_to_hash" converts a PNG time structure to a Perl
   associative array with named fields of the same name as the members
   of the C structure. */

static void perl_png_timep_to_hash (const png_timep mod_time, HV * time_hash)
{
    int i;
    SV * f[N_TIME_FIELDS];
    f[0] = newSViv (mod_time->year);
    f[1] = newSViv (mod_time->month);
    f[2] = newSViv (mod_time->day);
    f[3] = newSViv (mod_time->hour);
    f[4] = newSViv (mod_time->minute);
    f[5] = newSViv (mod_time->second);
    for (i = 0; i < N_TIME_FIELDS; i++) {
        if (!hv_store (time_hash, time_fields[i],
                       strlen (time_fields[i]), f[i], 0)) {
            fprintf (stderr, "hv_store failed.\n");
        }
    }
}

/* If the PNG contains a valid time, put the time into a Perl
   associative array. */

static SV *
perl_png_get_tIME (perl_libpng_t * png)
{
    png_timep mod_time = 0;
    int status;
    status = png_get_tIME (pngi, & mod_time);
    if (status && mod_time) {
        HV * time;
        time = newHV ();
        perl_png_timep_to_hash (mod_time, time);
        return newRV_noinc ((SV *) time);
    }
    else {
        return & PL_sv_undef;
    }
}

/* Set the time in the PNG from "input_time". */

static void
perl_png_set_tIME (perl_libpng_t * png, SV * input_time)
{
    /* The PNG month and day fields shouldn't be equal to zero.
       See PNG specification "4.2.4.6. tIME Image
       last-modification time". */
    png_time mod_time = {0,1,1,0,0,0};
    if (input_time) {
	SV * ref;
	HV * time_hash;
        ref = SvRV(input_time);
        if (! ref || SvTYPE (ref) != SVt_PVHV) {
	    croak ("Argument to set_tIME should be a hash reference");
	}
	time_hash = (HV *) ref;

	MESSAGE ("Setting time from a hash.");
#define SET_TIME(field) {					\
	    SV ** field_sv_ptr = hv_fetch (time_hash, #field,	\
					   strlen (#field), 0);	\
	    if (field_sv_ptr) {					\
		SV * field_sv = * field_sv_ptr;			\
		MESSAGE ("OK for %s\n", #field);		\
		mod_time.field = SvIV (field_sv);		\
	    }							\
	}
	SET_TIME(year);
	SET_TIME(month);
	SET_TIME(day);
	SET_TIME(hour);
	SET_TIME(minute);
	SET_TIME(second);
#undef SET_TIME    
    }
    else {
	/* Use the current time. */
	time_t now;
	
	now = time (0);
	png_convert_from_time_t (& mod_time, now);
    }
    png_set_tIME (pngi, & mod_time);
}

int
perl_png_sig_cmp (SV * png_header, int start, int num_to_check)
{
    const unsigned char * header;
    STRLEN length;
    int ret_val;
    header = (const unsigned char *) SvPV (png_header, length);
    ret_val = png_sig_cmp (header, start, num_to_check);
    return ret_val;
}

/*  ___                   _      __          _               _   
   |_ _|_ __  _ __  _   _| |_   / /__  _   _| |_ _ __  _   _| |_ 
    | || '_ \| '_ \| | | | __| / / _ \| | | | __| '_ \| | | | __|
    | || | | | |_) | |_| | |_ / / (_) | |_| | |_| |_) | |_| | |_ 
   |___|_| |_| .__/ \__,_|\__/_/ \___/ \__,_|\__| .__/ \__,_|\__|
             |_|                                |_|               */


/* Scalar as image stores information for the conversion of Perl
   scalar data into or out of the PNG structure. */

typedef struct
{
    SV * png_image;
    const char * data; 
    int read_position;
    unsigned int length;
    perl_libpng_t * png;
}
scalar_as_image_t;

/* Read a number of bytes given by "byte_count_to_read" from a Perl
   scalar into a png->png as requested. This is a callback set by
   "png_set_read_fn" and used by "png_read_png" to read data from a
   Perl scalar. The Perl scalar is passed to this function as part of
   "pngstruct" and retrieved by "png_get_io_ptr". */

static void
perl_png_scalar_read (png_structp pngstruct,
                      png_bytep out_bytes,
                      png_size_t byte_count_to_read)
{
    const char * read_point;
    perl_libpng_t * png;

    png = png_get_io_ptr (pngstruct);
    if (! png->scalar_data) {
        /* Something went wrong trying to read a PNG from a Perl
           scalar. This probably indicates a bug in the program. */
        croak ("Trying to read from a PNG in memory but there is no PNG in memory");
    }

    MESSAGE ("Length of data is %zu. "
             "Read position is %d. "
             "Length to read is %zu. ",
             png->data_length, png->read_position,
             byte_count_to_read);
    if (png->read_position + byte_count_to_read > png->data_length) {
        /* There was an attempt to read some data from a Perl scalar
           which went beyond the expected end of the scalar in
           memory. */
        croak ("Request for too many bytes %zu on a scalar "
                        "of length %zu at read position %d.\n",
                        byte_count_to_read, png->data_length,
                        png->read_position);
        return;
    }
    read_point = png->scalar_data + png->read_position;
    memcpy (out_bytes, read_point, byte_count_to_read);
    png->read_position += byte_count_to_read;
}

static void
perl_png_scalar_as_input (perl_libpng_t * png,
                          SV * image_data,
                          int transforms)
{
    MESSAGE ("Setting input from a scalar");

    GET_TRANSFORMS;

    /* We don't need the following anywhere. However we probably
       should keep track of where the data comes from. */
    png->scalar_data = SvPV (image_data, png->data_length);

    MESSAGE ("Length of data is %d. "
            "Read position is %d.",
            png->data_length, png->read_position);


    MESSAGE ("Length of the scalar data is %d", png->data_length);
    /* Set the reader for png->png to our function. */
    png_set_read_fn (png->png, png, perl_png_scalar_read);
}

/* Read a PNG from a Perl scalar "image_data". */

perl_libpng_t *
perl_png_read_from_scalar (SV * image_data,
                           int transforms)
{
    perl_libpng_t * png;
                           
    png = perl_png_create_read_struct ();
    perl_png_scalar_as_input (png, image_data, transforms);
    png_read_png (png->png, png->info, transforms, UNUSED_ZERO_ARG);
    return png;
}

/* Write "bytes_to_write" bytes of PNG information into a Perl
   scalar. The Perl scalar is passed in as part of "png" and retrieved
   using "png_get_io_ptr". */

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


/* Write the PNG image data into a Perl scalar. */

static SV *
perl_png_write_to_scalar (perl_libpng_t * png, int transforms)
{
    scalar_as_image_t * si;
    SV * image_data;
    if (png->type != perl_png_write_obj) {
	croak ("This is a read object, use copy_png to copy it");
    }

    GET_TRANSFORMS;

    GET_MEMORY (si, 1, scalar_as_image_t);
    MESSAGE ("Setting up the image.");
    /* Set the writer for png->png to our function. */
    png_set_write_fn (png->png, si, perl_png_scalar_write,
                      0 /* No flush function */);
    png_write_png (pngi, transforms, UNUSED_ZERO_ARG);
    image_data = si->png_image;
    PERL_PNG_FREE (si);
    return image_data;
}

static void
check_init_io (perl_libpng_t * png)
{
    if (! png->init_io_done) {
	croak ("No call to init_io before read/write");
    }
}

/* Write a PNG. */

static void
perl_png_write_png (perl_libpng_t * png, int transforms)
{
    MESSAGE ("Trying to write a PNG.");

    GET_TRANSFORMS;

    check_init_io (png);
    png_write_png (pngi, transforms, UNUSED_ZERO_ARG);
}

/*  _   _                _           
   | | | | ___  __ _  __| | ___ _ __ 
   | |_| |/ _ \/ _` |/ _` |/ _ \ '__|
   |  _  |  __/ (_| | (_| |  __/ |   
   |_| |_|\___|\__,_|\__,_|\___|_|    */
                                  


/* Get the IHDR from a PNG image. */

static SV *
perl_png_get_IHDR (perl_libpng_t * png)
{
    png_uint_32 width;
    png_uint_32 height;
    int bit_depth;
    int color_type;
    int interlace_method;
    /* The return value. */
    HV * IHDR;

    IHDR = newHV ();
    png_get_IHDR (pngi, & width, & height,
		  & bit_depth, & color_type, & interlace_method,
		  UNUSED_ZERO_ARG, UNUSED_ZERO_ARG);
    /*& compression_method, & filter_method);*/
    HASH_STORE_IV (IHDR, width);
    HASH_STORE_IV (IHDR, height);
    HASH_STORE_IV (IHDR, bit_depth);
    HASH_STORE_IV (IHDR, color_type);
    HASH_STORE_IV (IHDR, interlace_method);
    /*
    HASH_STORE_IV (IHDR, compression_method);
    HASH_STORE_IV (IHDR, filter_method);
    */
    png->height = height;
    png->width = width;
    png->bit_depth = bit_depth;
    png->color_type = color_type;
    return newRV_noinc ((SV *) IHDR);
}

/* Set the IHDR of a PNG image from the values specified in a Perl
   hash, "IHDR". */

static void 
perl_png_set_IHDR (perl_libpng_t * png, HV * IHDR)
{
    /* The first four are set to illegal values. We really should
       check the values going in to this routine. */
    png_uint_32 width = 0;
    png_uint_32 height = 0;
    int bit_depth = 0;
    int color_type = 0;
    int interlace_method = PNG_INTERLACE_NONE;
/*
    const int compression_type = PNG_COMPRESSION_TYPE_DEFAULT;
    const int filter_type = PNG_FILTER_TYPE_DEFAULT;
*/

#define FETCH(x) {                                              \
        SV ** fetched = hv_fetch (IHDR, #x, strlen (#x), 0);    \
        if (fetched) {                                          \
            x = SvIV (*fetched);                                \
        }                                                       \
    }
    FETCH (width);
    FETCH (height);
    FETCH (bit_depth);
    FETCH (color_type);
    FETCH (interlace_method);
    if (width == 0 || height == 0 || bit_depth == 0) {
        /* The user tried to set a PNG header with unacceptable values,
           as indicated. */
        croak ("set_IHDR: Bad values for width (%d), height (%d), or bit depth (%d)",
                        width, height, bit_depth);
        return;
    }
    png_set_IHDR (pngi, width, height, bit_depth, color_type,
                  interlace_method, UNUSED_ZERO_ARG, UNUSED_ZERO_ARG);
    png->width = width;
    png->height = height;
    png->bit_depth = bit_depth;
    png->color_type = color_type;
}



/*  _   _      _                     
   | | | | ___| |_ __   ___ _ __ ___ 
   | |_| |/ _ \ | '_ \ / _ \ '__/ __|
   |  _  |  __/ | |_) |  __/ |  \__ \
   |_| |_|\___|_| .__/ \___|_|  |___/
                |_|                   */


#define PERL_PNG_COLOR_TYPE(x)                  \
 case PNG_COLOR_TYPE_ ## x:                     \
     name = #x;                                 \
     break

/* Convert a PNG color type number into its name. */

static const char *
perl_png_color_type_name (int color_type)
{
    const char * name;

    switch (color_type) {
        PERL_PNG_COLOR_TYPE (GRAY);
        PERL_PNG_COLOR_TYPE (PALETTE);
        PERL_PNG_COLOR_TYPE (RGB);
        PERL_PNG_COLOR_TYPE (RGB_ALPHA);
        PERL_PNG_COLOR_TYPE (GRAY_ALPHA);
    default:
        /* Moan about not knowing this color type. */
        name = "unknown";
    }
    return name;
}

#undef PERL_PNG_COLOR_TYPE

/* Retrieve the number of channels of a PNG color type. */

static int
perl_png_color_type_channels (int color_type)
{
    switch (color_type) {
    case PNG_COLOR_TYPE_GRAY:
	return 1;
    case PNG_COLOR_TYPE_PALETTE:
	return 1;
    case PNG_COLOR_TYPE_RGB:
	return 3;
    case PNG_COLOR_TYPE_RGB_ALPHA:
	return 4;
    case PNG_COLOR_TYPE_GRAY_ALPHA:
	return 2;
    default:
	warn ("Unknown color type %d", color_type);
	return 0;
    }
}

#define PERL_PNG_TEXT_COMP(x,y)                  \
    case PNG_ ## x ## _COMPRESSION_ ## y:        \
    name = #x "_" #y;                            \
    break

/* Convert a libpng text compression number into its name. */

const char * perl_png_text_compression_name (int text_compression)
{
    const char * name;
    switch (text_compression) {
#ifdef PNG_tEXt_SUPPORTED
        PERL_PNG_TEXT_COMP(TEXT,NONE);
        PERL_PNG_TEXT_COMP(TEXT,zTXt);
#ifdef PNG_iTXt_SUPPORTED
        PERL_PNG_TEXT_COMP(ITXT,NONE);
        PERL_PNG_TEXT_COMP(ITXT,zTXt);
#endif /* iTXt */
#endif /* PNG_tEXt_SUPPORTED */
    default:
	warn ("Unknown compression type %d", text_compression);
        name = "";
    }
    return name;
}


/*  ____       _      _   _       
   |  _ \ __ _| | ___| |_| |_ ___ 
   | |_) / _` | |/ _ \ __| __/ _ \
   |  __/ (_| | |  __/ |_| ||  __/
   |_|   \__,_|_|\___|\__|\__\___| */
                               


/* This is a helper for get_PLTE. */

static AV *
perl_png_colors_to_av (png_colorp colors, int n_colors)
{
    int i;
    AV * perl_colors;
    perl_colors = newAV ();
    for (i = 0; i < n_colors; i++) {
        HV * palette_entry;

        palette_entry = newHV ();
#define PERL_PNG_STORE_COLOR(x)                        \
        (void) hv_store (palette_entry,                 \
                         #x, strlen (#x),               \
                         newSViv (colors[i].x), 0)
        PERL_PNG_STORE_COLOR (red);
        PERL_PNG_STORE_COLOR (green);
        PERL_PNG_STORE_COLOR (blue);
#undef PERL_PNG_STORE_COLOR
        av_push (perl_colors, newRV_noinc ((SV *) palette_entry));
    }
    return perl_colors;
}

static void
perl_png_palette (perl_libpng_t * png)
{
    int status;

    status = png_get_PLTE (pngi, & png->palette, & png->n_palette);
    png->palette_checked = 1;
    if (status != PNG_INFO_PLTE) {
        png->palette = 0;
    }
}

/* Return an array of hashes containing the color values of the palette. */

static SV *
perl_png_get_PLTE (perl_libpng_t * png)
{
    AV * perl_colors;

    if (! png->palette_checked) {
	perl_png_palette (png);
    }
    if (! png->palette) {
        return & PL_sv_undef;
    }
    perl_colors = perl_png_colors_to_av (png->palette, png->n_palette);
    return newRV_noinc ((SV *) perl_colors);
}


static void
perl_png_av_to_colors (perl_libpng_t * png, AV * perl_colors,
		       png_colorpp colors_ptr, int * n_colors_ptr)
{
    int n_colors;
    png_colorp colors;
    int i;

    *n_colors_ptr = 0;
    *colors_ptr = 0;

    if (! perl_colors) {
	return;
    }

    n_colors = av_len (perl_colors) + 1;
    if (n_colors == 0) {
	return;
    }
    MESSAGE ("There are %d colors in the palette.\n", n_colors);
    GET_MEMORY (colors, n_colors, png_color);
    /* Put the colors from Perl into the libpng structure. */

#define PERL_PNG_FETCH_COLOR(x) {                                       \
        SV ** rgb_sv = hv_fetch (palette_entry, #x, strlen (#x), 0);    \
	if (! rgb_sv) {							\
	    warn ("Palette entry %d is missing color %s",		\
		  i, #x);						\
    	    PERL_PNG_FREE (colors);					\
	    return;							\
	}								\
        colors[i].x = SvIV (*rgb_sv);					\
    }
    for (i = 0; i < n_colors; i++) {
        HV * palette_entry;
        SV ** color_i;

        color_i = av_fetch (perl_colors, i, 0);
	if (! color_i) {
	    warn ("Palette entry %d is empty", i);
	    PERL_PNG_FREE (colors);
	    return;
	}

	if (! SvOK (* color_i) ||
	    ! SvROK (* color_i) ||
	    SvTYPE (SvRV (* color_i)) != SVt_PVHV) {
	    warn ("Palette entry %d is not a hash reference", i);
	    PERL_PNG_FREE (colors);
	    return;
	}
        palette_entry = (HV *) SvRV (*color_i);

        PERL_PNG_FETCH_COLOR (red);
        PERL_PNG_FETCH_COLOR (green);
        PERL_PNG_FETCH_COLOR (blue);
    }
#undef PERL_PNG_FETCH_COLOR
    * colors_ptr = colors;
    * n_colors_ptr = n_colors;
}

/* Set the palette chunk of a PNG image to the palette described in
   "perl_colors". */

static void
perl_png_set_PLTE (perl_libpng_t * png, AV * perl_colors)
{
    int n_colors;
    png_colorp colors;

    perl_png_av_to_colors (png, perl_colors, & colors, & n_colors);
    if (n_colors == 0) {
        /* The user tried to set an empty palette of colors. */
        croak ("set_PLTE: Empty array of colors in set_PLTE");
    }
    MESSAGE ("There are %d colors in the palette.\n", n_colors);
    png_set_PLTE (pngi, colors, n_colors);
    PERL_PNG_FREE (colors);
}

/* Create a hash containing the color values of a pointer to a
   png_color_16 structure. */

static HV * perl_png_color_16_to_hv (png_color_16p color)
{
    HV * perl_color;
    perl_color = newHV ();
#define PERL_COLOR(x) \
    (void) hv_store (perl_color, #x, strlen (#x), newSViv (color->x), 0)
    PERL_COLOR(index);
    PERL_COLOR(red);
    PERL_COLOR(green);
    PERL_COLOR(blue);
    PERL_COLOR(gray);
#undef PERL_COLOR
    return perl_color;
}

/* Turn a hash into the color values of a pointer to a png_color_16
   structure. */

static void perl_png_hv_to_color_16 (HV * perl_color, png_color_16p color)
{
#define PERL_COLOR(x) \
    HASH_FETCH_IV_MEMBER (perl_color, x, color)
    PERL_COLOR(index);
    PERL_COLOR(red);
    PERL_COLOR(green);
    PERL_COLOR(blue);
    PERL_COLOR(gray);
#undef PERL_COLOR
}

/*   ___  _   _                      _                 _        
    / _ \| |_| |__   ___ _ __    ___| |__  _   _ _ __ | | _____ 
   | | | | __| '_ \ / _ \ '__|  / __| '_ \| | | | '_ \| |/ / __|
   | |_| | |_| | | |  __/ |    | (__| | | | |_| | | | |   <\__ \
    \___/ \__|_| |_|\___|_|     \___|_| |_|\__,_|_| |_|_|\_\___/ */
                                                             


#define VALID(x) png_get_valid (pngi, PNG_INFO_ ## x)

/* Get the background chunk of a PNG image and return it as a hash
   reference. */

static SV * perl_png_get_bKGD (perl_libpng_t * png)
{
    if (VALID(bKGD)) {
        png_color_16p background;
        if (png_get_bKGD (pngi, & background)) {
            return newRV_noinc ((SV *) perl_png_color_16_to_hv (background));
        }
    }
    return & PL_sv_undef;
}

/* Set the bKGD chunk of the image from values in a hash
   "bKGD". Values not set in the hash are set to zero. */

static void perl_png_set_bKGD (perl_libpng_t * png, HV * bKGD)
{
    /* Default is all zeros. */
    png_color_16 background = {0};
    perl_png_hv_to_color_16 (bKGD, & background);
    png_set_bKGD (pngi, & background);
}

/* Get the pCAL (calibration of pixel values) chunk from a PNG
   image. */

static SV * perl_png_get_pCAL (perl_libpng_t * png)
{
    SV * pcal = & PL_sv_undef;
#ifdef PNG_pCAL_SUPPORTED
    HV * ice;
    char * purpose;
    png_int_32 x0;
    png_int_32 x1;
    int type;
    int n_params;
    char * units;
    char ** png_params;

    if (! VALID (pCAL)) {
	return pcal;
    }
    png_get_pCAL (pngi, & purpose, & x0, & x1, & type,
		  & n_params, & units, & png_params);
    ice = newHV ();
    HASH_STORE_PV (ice, purpose);
    HASH_STORE_IV (ice, x0);
    HASH_STORE_IV (ice, x1);
    HASH_STORE_IV (ice, type);
    HASH_STORE_PV (ice, units);
    if (n_params) {
	AV * params;
	int i;
	params = newAV ();
	for (i = 0; i < n_params; i++) {
	    ARRAY_STORE_PV (params, png_params[i]);
	}
	HASH_STORE_AV (ice, params);
    }
    pcal = newRV_noinc ((SV *) ice);
#else
    UNSUPPORTED(pCAL);
#endif
    return pcal;
}

/* Set the pCAL (calibration of pixel values) chunk of a PNG
   image. */

static void perl_png_set_pCAL (perl_libpng_t * png, HV * pCAL)
{
#ifdef PNG_pCAL_SUPPORTED
    char * purpose;
    STRLEN purpose_length;
    int x0;
    int x1;
    int type;
    int n_params;
    char * units;
    STRLEN units_length;
    AV * params;
    char ** png_params;
    HASH_FETCH_PV (pCAL, purpose);
    HASH_FETCH_IV (pCAL, x0);
    HASH_FETCH_IV (pCAL, x1);
    HASH_FETCH_IV (pCAL, type);
    HASH_FETCH_PV (pCAL, units);
    HASH_FETCH_AV (pCAL, params);
    n_params = 0;
    png_params = 0;
    if (params) {
	n_params = av_len (params) + 1;
	if (n_params) {
	    int i;
	    STRLEN length;
	    GET_MEMORY (png_params, n_params, char *);
	    for (i = 0; i < n_params; i++) {
		ARRAY_FETCH_PV (params, i, png_params[i], length);
	    }
	}
    }
    png_set_pCAL (pngi, purpose, x0, x1, type, n_params, units, png_params);
    if (png_params) {
	PERL_PNG_FREE (png_params);
    }
#else
    UNSUPPORTED(pCAL);
#endif
}

/* Get the gAMA of a PNG image. */

static SV * perl_png_get_gAMA (perl_libpng_t * png)
{
#ifdef PNG_gAMA_SUPPORTED
    if (VALID (gAMA)) {
        SV * perl_gamma;
        double gamma;
        png_get_gAMA (pngi, & gamma);
        perl_gamma = newSVnv (gamma);
        return perl_gamma;
    }
    return & PL_sv_undef;
#else
    /* libpng was compiled without this option. */
    UNSUPPORTED(gAMA);
    return & PL_sv_undef;
#endif
}

/* Set the gAMA of a PNG image. */

static void perl_png_set_gAMA (perl_libpng_t * png, double gamma)
{
#ifdef PNG_gAMA_SUPPORTED
    png_set_gAMA (pngi, gamma);
#else
    /* libpng was compiled without this option. */
    UNSUPPORTED(gAMA);
#endif
}

#if PNG_LIBPNG_VER_MINOR <= 4
typedef png_charp perl_png_profile_t;
#else
    /* Modern version */
typedef png_bytep perl_png_profile_t;
#endif /* minor <= 2 */


static SV * perl_png_get_iCCP (perl_libpng_t * png)
{
    SV * iccp = & PL_sv_undef;
#ifdef PNG_iCCP_SUPPORTED
    png_charp name;
    int compression_type = UNUSED_ZERO_ARG;
    png_uint_32 proflen;
    HV * ice;
    SV * profile_sv;
    perl_png_profile_t profile;

    if (! VALID (iCCP)) {
	return iccp;
    }
    png_get_iCCP (pngi, & name, & compression_type, & profile,
		  & proflen);
    ice = newHV ();
    HASH_STORE_PV (ice, name);
    profile_sv = newSVpv ((char *) profile, proflen);
    (void) hv_store (ice, "profile", strlen ("profile"), profile_sv, 0);
    iccp = newRV_noinc ((SV *) ice);
#else /* PNG_iCCP_SUPPORTED */
    UNSUPPORTED(iCCP);
#endif /* PNG_iCCP_SUPPORTED */
    return iccp;
}

static void perl_png_set_iCCP (perl_libpng_t * png, HV * iCCP)
{
#ifdef PNG_iCCP_SUPPORTED
    char * name;
    STRLEN name_length;
    STRLEN profile_length;
    /* If we set profile to be char * (png_charp), we get warnings
       from version 1.2 and version 1.4 of libpng, but if we set
       profile to be unsigned char * (png_bytep) we get warnings from
       Perl when fetching from the hash. Here it is called "profile"
       due to economising of typing in the HASH_FETCH_PV macro, then
       we copy that pointer into "p". */
    char * profile;
    perl_png_profile_t p;

    HASH_FETCH_PV (iCCP, profile);
    HASH_FETCH_PV (iCCP, name);
    p = (perl_png_profile_t) profile;
    png_set_iCCP (pngi, name, UNUSED_ZERO_ARG, p,
		  (png_uint_32) profile_length);
#else /* PNG_iCCP_SUPPORTED */
    UNSUPPORTED(iCCP);
#endif /* PNG_iCCP_SUPPORTED */
}

static void
perl_png_set_tRNS_pointer (perl_libpng_t * png, png_bytep trans, int num_trans)
{
#ifdef PNG_tRNS_SUPPORTED
    png_set_tRNS (pngi, trans, num_trans, 0);
#else
    /* libpng was compiled without this option. */
    UNSUPPORTED(tRNS);
#endif
}

static SV * perl_png_get_tRNS (perl_libpng_t * png)
{
#ifdef PNG_tRNS_SUPPORTED
    png_byte color_type;
    png_bytep trans;
    int num_trans;
    png_uint_32 status;
    png_color_16p trans_values;
    if (! VALID (tRNS)) {
	return & PL_sv_undef;
    }
    status = png_get_tRNS (pngi, & trans, & num_trans, & trans_values);
    color_type = png_get_color_type (pngi);
    if (color_type & PNG_COLOR_MASK_PALETTE) {
	AV * trans_av;
	int i;

	trans_av = newAV ();

	for (i = 0; i < num_trans; i++) {
	    av_push (trans_av, newSViv (trans[i]));
	}
	return newRV_noinc ((SV *) trans_av);
    }
    else {
	HV * trans_hv;
	trans_hv = newHV ();
#line 1662 "/usr/home/ben/projects/image-png-libpng/build/../perl-libpng.c"
        
	HASH_STORE_IV_MEMBER (trans_hv, red, trans_values);
	
	HASH_STORE_IV_MEMBER (trans_hv, green, trans_values);
	
	HASH_STORE_IV_MEMBER (trans_hv, blue, trans_values);
	
	HASH_STORE_IV_MEMBER (trans_hv, gray, trans_values);
	
#line 1667 "tmpl/perl-libpng.c.tmpl"
	return newRV_noinc ((SV *) trans_hv);
    }
#else
    /* libpng was compiled without this option. */
    UNSUPPORTED(tRNS);
    return & PL_sv_undef;
#endif
}

static void perl_png_set_tRNS (perl_libpng_t * png, SV * tRNS)
{
#ifdef PNG_tRNS_SUPPORTED
    png_byte color_type;
    png_byte trans[256] = {0};
    int num_trans;
    png_color_16 trans_values = {0};

    color_type = png_get_color_type (pngi);
    if (color_type & PNG_COLOR_MASK_PALETTE) {
	AV * trans_av;
	int i;
	if (SvTYPE (SvRV (tRNS)) != SVt_PVAV) {
	    croak ("set_tRNS: argument must be an array reference with palette color types");
	}
	trans_av = (AV *) SvRV (tRNS);
	num_trans = av_len (trans_av) + 1;
	if (num_trans > 256) {
	    croak ("set_tRNS: palette has too many entries %d > 256", num_trans);
	}
	for (i = 0; i < num_trans; i++) {
	    int ti;
	    SV ** ti_sv;
	    ti_sv = av_fetch (trans_av, i, 0); 
	    if (! ti_sv) {
		croak ("set_tRNS: empty entry at offset %d into tRNS", i);
	    }
	    ti = SvIV (* ti_sv);
	    if (ti < 0 || ti > 0xFF) {
		croak ("set_tRNS: tRNS value at offset %d %d < 0 or >= 256",
		       i, ti);
	    }
	    trans[i] = ti;
	}

	png_set_tRNS (pngi, trans, num_trans, & trans_values); 

    }
    else {
	HV * trans_hv;
	if (SvTYPE (SvRV (tRNS)) != SVt_PVHV) {
	    croak ("set_tRNS: argument must be a hash reference for non-palette images");
	}
	trans_hv = (HV *) SvRV (tRNS);
#line 1726 "/usr/home/ben/projects/image-png-libpng/build/../perl-libpng.c"
        
	HASH_FETCH_IV_MEMBER (trans_hv, red, (& trans_values));
	
	HASH_FETCH_IV_MEMBER (trans_hv, green, (& trans_values));
	
	HASH_FETCH_IV_MEMBER (trans_hv, blue, (& trans_values));
	
	HASH_FETCH_IV_MEMBER (trans_hv, gray, (& trans_values));
	
#line 1725 "tmpl/perl-libpng.c.tmpl"
	num_trans = 1;
	png_set_tRNS (pngi, trans, num_trans, & trans_values); 
    }
#else
    /* libpng was compiled without this option. */
    UNSUPPORTED(tRNS);
#endif
}

static HV *
perl_png_spalette_to_hv (png_sPLT_tp spalette)
{
    HV * perl_spalette;
    AV * entries;
    int nentries;
    int i;
    perl_spalette = newHV ();
    HASH_STORE_PV_MEMBER (perl_spalette, name, spalette);
    HASH_STORE_IV_MEMBER (perl_spalette, depth, spalette);
    nentries = spalette->nentries;
    HASH_STORE_IV (perl_spalette, nentries);
    entries = newAV ();
    for (i = 0; i < nentries; i++) {
	HV * perl_entry;
	png_sPLT_entry * entry;
	entry = spalette->entries + i;
	perl_entry = newHV ();
#line 1764 "/usr/home/ben/projects/image-png-libpng/build/../perl-libpng.c"
		HASH_STORE_IV_MEMBER (perl_entry, red, entry);
		HASH_STORE_IV_MEMBER (perl_entry, green, entry);
		HASH_STORE_IV_MEMBER (perl_entry, blue, entry);
		HASH_STORE_IV_MEMBER (perl_entry, alpha, entry);
		HASH_STORE_IV_MEMBER (perl_entry, frequency, entry);
	
#line 1757 "tmpl/perl-libpng.c.tmpl"
	av_push (entries, newRV_noinc ((SV *) perl_entry));
    }
    HASH_STORE_AV (perl_spalette, entries);
    return perl_spalette;
}

/* Get the sPLT chunk(s) of a PNG image. */

static SV * perl_png_get_sPLT (perl_libpng_t * png)
{
#ifdef PNG_sPLT_SUPPORTED
    if (! VALID (sPLT)) {
	return & PL_sv_undef;
    }
    png_sPLT_tp spalettes;
    int num_spalettes;
    AV * perl_spalettes;
    int i;

    num_spalettes = png_get_sPLT (pngi, & spalettes);
    MESSAGE ("Got %d suggested palettes", num_spalettes);
    if (num_spalettes == 0) {
	return & PL_sv_undef;
    }
    perl_spalettes = newAV ();
    for (i = 0; i < num_spalettes; i++) {
	png_sPLT_tp spalette;
	HV * perl_spalette;

	spalette = spalettes + i;
	MESSAGE ("Getting suggested palette %d", i);
	perl_spalette = perl_png_spalette_to_hv (spalette);
	av_push (perl_spalettes, newRV_noinc ((SV *) perl_spalette));
    }
    return newRV_noinc ((SV *) perl_spalettes);
#else
    UNSUPPORTED (sPLT);
    return & PL_sv_undef;
#endif /* PNG_sPLT_SUPPORTED */
}

/* Set an sPLT chunk(s) of a PNG image. */

static void perl_png_set_sPLT (perl_libpng_t * png, AV * sPLT_entries)
{
#ifdef PNG_sPLT_SUPPORTED
    int i;
    int num_spalettes;
    png_sPLT_tp entries;
    STRLEN name_length;

    num_spalettes = av_len (sPLT_entries) + 1;
    MESSAGE ("There are %d palettes", num_spalettes);
    if (num_spalettes == 0) {
	return;
    }
    GET_MEMORY (entries, num_spalettes, png_sPLT_t);
    for (i = 0; i < num_spalettes; i++) {
	png_sPLT_t * entry;
	HV * perl_spalette;
	SV ** sv;
	AV * perl_entries;
	int nentries;
	int j;
	entry = entries + i;
	MESSAGE ("Copying palette %d", i);
	sv = av_fetch (sPLT_entries, i, 0);
	if (SvOK (* sv) && SvROK (* sv) && SvTYPE (SvRV (* sv)) == SVt_PVHV) {
	    perl_spalette = (HV *) SvRV (* sv);
	}
	else {
	    warn ( "Not a hash reference at position %d", i);
	    continue;
	}
	HASH_FETCH_PV_MEMBER (perl_spalette, name, entry);
	HASH_FETCH_IV_MEMBER (perl_spalette, depth, entry);
	MESSAGE ("name = %s depth = %d", entry->name, entry->depth);
	sv = hv_fetch (perl_spalette, "entries", strlen ("entries"), 0);
	if (SvOK (* sv) && SvROK (* sv) && SvTYPE (SvRV (* sv)) == SVt_PVAV) {
	    perl_entries = (AV *) SvRV (* sv);
	}
	else {
	    warn ( "Could not get entries at position %d", i);
	    continue;
	}
	nentries = av_len (perl_entries) + 1;
	entry->nentries = nentries;
	GET_MEMORY (entry->entries, nentries, png_sPLT_entry);
	MESSAGE ("Copying %d entries", nentries);
	for (j = 0; j < nentries; j++) {
	    png_sPLT_entry * e;
	    HV * perl_entry;
	    sv = av_fetch (perl_entries, j, 0);
	    if (SvOK (* sv) && SvROK (* sv) &&
		SvTYPE (SvRV (* sv)) == SVt_PVHV) {
		perl_entry = (HV *) SvRV (* sv);
	    }
	    else {
		warn ( "Could not get entry %d", j);
		continue;
	    }
	    MESSAGE ("Copying entry %d", j);
	    e = entry->entries + j;
#line 1875 "/usr/home/ben/projects/image-png-libpng/build/../perl-libpng.c"
 	    	    HASH_FETCH_IV_MEMBER (perl_entry, red, e);
	    	    HASH_FETCH_IV_MEMBER (perl_entry, green, e);
	    	    HASH_FETCH_IV_MEMBER (perl_entry, blue, e);
	    	    HASH_FETCH_IV_MEMBER (perl_entry, alpha, e);
	    	    HASH_FETCH_IV_MEMBER (perl_entry, frequency, e);
	    
#line 1865 "tmpl/perl-libpng.c.tmpl"
	}
    }
    MESSAGE ("Setting the entries");
    png_set_sPLT (pngi, entries, num_spalettes);
    for (i = 0; i < num_spalettes; i++) {
	PERL_PNG_FREE (entries[i].entries);
    }
    PERL_PNG_FREE (entries);
#else
    UNSUPPORTED (sPLT);
#endif /* PNG_sPLT_SUPPORTED */
}

static SV * perl_png_get_sCAL (perl_libpng_t * png)
{
#ifdef PERL_PNG_sCAL_s_SUPPORTED
    if (VALID (sCAL)) {
        HV * ice;
	int unit;
	char * width;
	char * height;
        ice = newHV ();
	png_get_sCAL_s (pngi, & unit, & width, & height);
	HASH_STORE_IV (ice, unit);
	HASH_STORE_PV (ice, width);
	HASH_STORE_PV (ice, height);
        return newRV_noinc ((SV *) ice);
    }
    return & PL_sv_undef;
#else /* PERL_PNG_sCAL_s_SUPPORTED */
    UNSUPPORTED(sCAL);
    return & PL_sv_undef;
#endif /* PERL_PNG_sCAL_s_SUPPORTED */
}

static void perl_png_set_sCAL (perl_libpng_t * png, HV * sCAL)
{
#ifdef PERL_PNG_sCAL_s_SUPPORTED
    int unit;
    char * width;
    char * height;
    STRLEN width_length;
    STRLEN height_length;
    HASH_FETCH_IV (sCAL, unit);
    HASH_FETCH_PV (sCAL, width);
    HASH_FETCH_PV (sCAL, height);
    png_set_sCAL_s (pngi, unit, width, height);
#else /* PERL_PNG_sCAL_s_SUPPORTED */
    warn ( "sCAL chunk not supported in this libpng");
#endif /* PERL_PNG_sCAL_s_SUPPORTED */
}

#if 0

/* TODO: Take the contents of get_hIST & put them here. 2020-12-19
   08:59:55 */

static void
hist_to_av (png_uint_16p hist, AV * hIST)
{

}

#endif /* 0 */

/* AV * to libpng histogram. This is used by set_hIST and by
   set_quantize. Failure is indicated by setting "* size_ptr" to
   zero. */

static void
av_to_hist (perl_libpng_t * png, AV * hist_av, png_uint_16p * hist_ptr,
	    int * size_ptr, int n_colors)
{
    int size;
    png_uint_16p hist;
    int i;

    * hist_ptr = 0;
    /* The returned size is also used to indicate success or
       failure. */
    * size_ptr = 0;

    size = av_len (hist_av) + 1;
    if (size != n_colors) {
	warn ("Size of histogram %d != colors in palette %d", size, n_colors);
	return;
    }
	
    GET_MEMORY (hist, size, png_uint_16);
    for (i = 0; i < size; i++) {
	SV * sv;
	SV ** sv_ptr;
	IV iv;
	
	/* We use continue to break out of the loop so make sure
	   hist[i] is set to something or another. */

	hist[i] = (png_uint_16) 0;

	iv = 0;
	sv_ptr = av_fetch (hist_av, i, 0);
	if (! sv_ptr) {
	    /* If this warning is changed to "croak", "hist" needs to
	       be freed here. */
	    warn ("Empty value in histogram array at offset %d", i);
	    continue;
	}
	sv = * sv_ptr;
	if (! SvIOK(sv)) {
	    warn ("Non-integer value in histogram array at offset %d", i);
	    continue;
	}
	iv = SvIV (sv);
	if (iv < 0 || iv > PNG_UINT_16_MAX) {
	    warn ("Value %d of histogram array at offset %d < 0 or > %d",
		  (int) iv, i, (int) PNG_UINT_16_MAX);
	    continue;
	}
	hist[i] = (png_uint_16) iv;
    }
    * hist_ptr = hist;
    * size_ptr = size;
}

static void
perl_png_set_hIST (perl_libpng_t * png, AV * hist_av)
{
#ifdef PNG_hIST_SUPPORTED
    int hist_size;
    png_uint_16p hist;
    png_colorp colors;
    int n_colors;

    /* The reason why it doesn't need the histogram size seems to be
       that it assumes that it is the same as the palette size. */
    png_get_PLTE (pngi, & colors, & n_colors);
    av_to_hist (png, hist_av, & hist, & hist_size, n_colors);
    if (hist_size > 0) {
	png_set_hIST (pngi, hist);
	PERL_PNG_FREE (hist);
    }
#else
    UNSUPPORTED(hIST);
#endif
}

static SV *
perl_png_get_hIST (perl_libpng_t * png)
{
    SV * hist_sv;

    hist_sv = & PL_sv_undef;
#ifdef PNG_hIST_SUPPORTED
    if (VALID (hIST)) {
	png_colorp colors;
	int n_colors;
	AV * hist_av;
	png_uint_16p hist;
	int i;

	png_get_PLTE (pngi, & colors, & n_colors);
	hist_av = newAV ();
	png_get_hIST (pngi, & hist);

	for (i = 0; i < n_colors; i++) {
	    av_push (hist_av, newSViv (hist[i]));
	}
	hist_sv = newRV_noinc ((SV *) hist_av);
    }
#else
    UNSUPPORTED(hIST);
#endif
    return hist_sv;
}

/* Should this be a hash value or an array? */

/* "4.2.4.3. sBIT Significant bits" */

static SV * perl_png_get_sBIT (perl_libpng_t * png)
{
    SV * sbit = & PL_sv_undef;
#ifdef PNG_sBIT_SUPPORTED
    if (VALID (sBIT)) {
        HV * sig_bit;
        png_color_8p colors;
	png_uint_32 status;
	int color_type;

	color_type = png_get_color_type (pngi);
        sig_bit = newHV ();
	status = png_get_sBIT (pngi, & colors);
	if (status != PNG_INFO_sBIT) {
	    return sbit;
	}
	if ((color_type & PNG_COLOR_MASK_COLOR) != 0) {
	    
	    HASH_STORE_IV_MEMBER (sig_bit, red, colors);
	    
	    HASH_STORE_IV_MEMBER (sig_bit, green, colors);
	    
	    HASH_STORE_IV_MEMBER (sig_bit, blue, colors);
	    
	}
	else {
	    HASH_STORE_IV_MEMBER (sig_bit, gray, colors);
	}
	if ((color_type & PNG_COLOR_MASK_ALPHA) != 0) {
	    HASH_STORE_IV_MEMBER (sig_bit, alpha, colors);
	}
        sbit = newRV_noinc ((SV *) sig_bit);
    }
#else
    /* libpng was compiled without this option. */
    UNSUPPORTED(sBIT);
#endif
    return sbit;
}

static void perl_png_set_sBIT (perl_libpng_t * png, HV * sBIT)
{
#ifdef PNG_sBIT_SUPPORTED
    png_color_8 colors;
    
    HASH_FETCH_IV_MEMBER (sBIT, red, (& colors));
    
    HASH_FETCH_IV_MEMBER (sBIT, green, (& colors));
    
    HASH_FETCH_IV_MEMBER (sBIT, blue, (& colors));
    
    HASH_FETCH_IV_MEMBER (sBIT, gray, (& colors));
    
    HASH_FETCH_IV_MEMBER (sBIT, alpha, (& colors));
    
    png_set_sBIT (pngi, & colors);
#else
    UNSUPPORTED(sBIT);
#endif
}

static SV * perl_png_get_oFFs (perl_libpng_t * png)
{
    SV * offs = & PL_sv_undef;
#ifdef PNG_oFFs_SUPPORTED
    if (VALID (oFFs)) {
        HV * offset;
	png_int_32 x_offset;
        png_int_32 y_offset;
        int unit_type;

        offset = newHV ();
        png_get_oFFs (pngi, & x_offset, & y_offset, & unit_type);
        HASH_STORE_IV (offset, x_offset);
        HASH_STORE_IV (offset, y_offset);
        HASH_STORE_IV (offset, unit_type);
        offs = newRV_noinc ((SV *) offset);
    }
#else
    UNSUPPORTED(oFFs);
#endif
    return offs;
}

/* set oFFs of PNG image. */
 
static void perl_png_set_oFFs (perl_libpng_t * png, HV * oFFs)
{
#ifdef PNG_oFFs_SUPPORTED
    png_uint_32 x_offset;
    png_uint_32 y_offset;
    int unit_type;
    HASH_FETCH_IV (oFFs, x_offset);
    HASH_FETCH_IV (oFFs, y_offset);
    HASH_FETCH_IV (oFFs, unit_type);
    png_set_oFFs (pngi, x_offset, y_offset, unit_type);
#else
    UNSUPPORTED(oFFs);
#endif
}

static SV * perl_png_get_pHYs (perl_libpng_t * png)
{
    SV * phys_sv = & PL_sv_undef;
#ifdef PNG_pHYs_SUPPORTED
    if (VALID (pHYs)) {
        png_uint_32 res_x;
        png_uint_32 res_y;
        int unit_type;
        HV * phys;
        phys = newHV ();
        png_get_pHYs (pngi, & res_x, & res_y, & unit_type);
        HASH_STORE_IV (phys, res_x);
        HASH_STORE_IV (phys, res_y);
        HASH_STORE_IV (phys, unit_type);
        phys_sv = newRV_noinc ((SV *) phys);
    }
#else
    /* libpng was compiled without this option. */
    UNSUPPORTED(pHYs);
#endif
    return phys_sv;
}

static void perl_png_set_pHYs (perl_libpng_t * png, HV * pHYs)
{
#ifdef PNG_pHYs_SUPPORTED
    png_uint_32 res_x;
    png_uint_32 res_y;
    int unit_type;
    HASH_FETCH_IV (pHYs, res_x);
    HASH_FETCH_IV (pHYs, res_y);
    HASH_FETCH_IV (pHYs, unit_type);
    png_set_pHYs (pngi, res_x, res_y, unit_type);
#else
    /* libpng was compiled without this option. */
    UNSUPPORTED(pHYs);
#endif
}

/* Get the transparency information for a paletted image. */

static SV *
perl_png_get_tRNS_palette (perl_libpng_t * png)
{
#ifdef PNG_tRNS_SUPPORTED
    if (VALID (tRNS) && VALID (PLTE)) {
        AV * perl_trans;
        png_bytep png_trans;
        int num_trans;
        int i;

        png_get_tRNS (pngi, & png_trans, & num_trans, 0);

        if (num_trans == 0) {
            return & PL_sv_undef;
        }
        if (num_trans > 0x100) {
            /* The user tried to set more than the maximum possible
               number of transparencies for a paletted image. */
            croak ("Too many transparencies %d supplied",
                            num_trans);
        }
        perl_trans = newAV ();
        for (i = 0; i < num_trans; i++) {
            SV * trans_i = newSViv (png_trans[i]);
            av_push (perl_trans, trans_i);
        }
        return newRV_noinc ((SV *) perl_trans);
    }
    return & PL_sv_undef;
#else
    /* libpng was compiled without this option. */
    UNSUPPORTED(tRNS);
    return & PL_sv_undef;
#endif
}

/* Get the sRGB */

int perl_png_get_sRGB (perl_libpng_t * png)
{
#ifdef PNG_sRGB_SUPPORTED
    /* I'm not sure what to return if there is no valid sRGB value. */

    int intent = 0;

    if (VALID (sRGB)) {
        png_get_sRGB (pngi, & intent);
    }
    return intent;
#else
    /* libpng was compiled without this option. */
    UNSUPPORTED(sRGB);
    return 0;
#endif
}

/* Set the sRGB. */

static void perl_png_set_sRGB (perl_libpng_t * png, int sRGB)
{
#ifdef PNG_sRGB_SUPPORTED
    png_set_sRGB (pngi, sRGB);
#else
    /* libpng was compiled without this option. */
    UNSUPPORTED(sRGB);
#endif
}

static SV * perl_png_get_valid (perl_libpng_t * png)
{
    HV * perl_valid;
    unsigned int valid;

    perl_valid = newHV ();
    valid = png_get_valid (pngi, 0xFFFFFFFF);
#define V(x) \
    (void) hv_store (perl_valid, #x, strlen (#x), newSViv (valid & PNG_INFO_ ## x), 0)
#line 2281 "/usr/home/ben/projects/image-png-libpng/build/../perl-libpng.c"
V(bKGD);V(cHRM);V(gAMA);V(hIST);V(iCCP);V(IDAT);V(oFFs);V(pCAL);V(pHYs);V(PLTE);V(sBIT);V(sCAL);V(sPLT);V(sRGB);V(tIME);V(tRNS);
#line 2254 "tmpl/perl-libpng.c.tmpl"
#undef V

    return newRV_noinc ((SV *) perl_valid);
}

/*  ___                                  _       _        
   |_ _|_ __ ___   __ _  __ _  ___    __| | __ _| |_ __ _ 
    | || '_ ` _ \ / _` |/ _` |/ _ \  / _` |/ _` | __/ _` |
    | || | | | | | (_| | (_| |  __/ | (_| | (_| | || (_| |
   |___|_| |_| |_|\__,_|\__, |\___|  \__,_|\__,_|\__\__,_|
                        |___/                              */


static void
get_check_height (perl_libpng_t * png)
{
    png->height = png_get_image_height (pngi);
    if (png->height == 0) {
        /* The image we are trying to read has zero height. */
        croak ("Image has zero height");
    }
}

static SV *
rows_to_av (perl_libpng_t * png)
{
    AV * perl_rows;
    int r;
    STRLEN rb;

    rb = (STRLEN) png->rowbytes;
    perl_rows = newAV ();
    av_extend (perl_rows, png->height - 1);
    for (r = 0; r < png->height; r++) {
	SV * row_sv;
	const char * c;

	c = (const char *) png->row_pointers[r];
	row_sv = newSVpv (c, rb);
	av_store (perl_rows, (SSize_t) r, row_sv);
    }
    return newRV_noinc ((SV *) perl_rows);
}

static SV *
perl_png_get_rows (perl_libpng_t * png)
{
    /* Get the information from the PNG. */

    get_check_height (png);
    if (! png->row_pointers) {
	png->row_pointers = png_get_rows (pngi);
	png->row_pointers_ours = 0;
	if (png->row_pointers == 0) {
	    /* The image does not have any rows of image data. */
	    croak ("Image has no rows");
	}
	else {
	    MESSAGE ("Image has some rows");
	}
    }
    png->rowbytes = png_get_rowbytes (pngi);
    if (png->rowbytes == 0) {
        /* The rows of image data have zero length. */
        croak ("Image rows have zero length");
    }
    else {
        MESSAGE ("Image rows are length %d bytes\n", png->rowbytes);
    }

    /* Create Perl stuff to put the row info into. */

    return rows_to_av (png);
}

static void
perl_png_read_png (perl_libpng_t * png, int transforms)
{
    GET_TRANSFORMS;
    check_init_io (png);
    png_read_png (pngi, transforms, 0);
}

/* Read the image data into allocated memory */

static SV *
perl_png_read_image (perl_libpng_t * png)
{
    int i;

    check_init_io (png);
    png_read_update_info (pngi);
    get_check_height (png);
    png->rowbytes = png_get_rowbytes (pngi);
    GET_MEMORY (png->row_pointers, png->height, png_bytep);
    png->row_pointers_ours = 1;
    GET_MEMORY (png->image_data, png->rowbytes * png->height, png_byte);
    for (i = 0; i < png->height; i++) {
        png->row_pointers[i] = png->image_data + png->rowbytes * i;
    }
    png_set_rows(pngi, png->row_pointers);
    png_read_image (png->png, png->row_pointers);
    return rows_to_av (png);
}

static int
bytes_for_bits (int bits)
{
    return (bits + 7)/8;
}

/* Set the rows of the image to "rows". */

static void perl_png_set_rows (perl_libpng_t * png, AV * rows)
{
    int i;
    int n_rows;
    png_uint_32 height;
    png_uint_32 width;
    int bit_depth;
    int channels;
    /* Older libpngs, e.g. version 1.2.59, need png_get_IHDR to be
       passed a valid pointer for "color_type", otherwise png_get_IHDR
       fails. We don't need it here at all. This is no longer the case
       for libpng version 1.6.37, but we support the old versions
       too. */
    int color_type;

    /* libpng return value */
    int status;
    /* Minimum number of bytes we need to store one row. */
    int rbytes;
    /* Number of bytes in all the rows. */
    int arbytes;
    /* All the rows. */
    unsigned char * ar;
    /* Our row. */
    unsigned char * r;

    status = png_get_IHDR (pngi, & width, & height,
                           & bit_depth,
			   & color_type, /* Unused, see comment above. */
			   0,
                           UNUSED_ZERO_ARG, UNUSED_ZERO_ARG);
    if (status == 0) {
	/* The return value of png_get_IHDR is either 0 or 1, 0 means
	   error, 1 means success. */
	croak ("Image::PNG::Libpng: error from png_get_IHDR");
    }
    if (width == 0 || height == 0) {
	/* This was for catching the bug with png_get_IHDR, it doesn't
	   do any harm and it might catch another bug later so it can
	   stay here. */
	croak ("Image::PNG::Libpng: image width (%u) or height (%u) zero",
	       (unsigned) width, (unsigned) height);
    }

    channels = png_get_channels (pngi);
    rbytes = bytes_for_bits (width * bit_depth * channels);
    if (png->row_pointers) {
        /* There was an attempt to set the rows of an image after they
           had already been set. */
        croak ("This PNG object already contains image data");
    }
    /* Check that this is the same as the height of the image. */
    n_rows = av_len (rows) + 1;
    if (n_rows != height) {
        /* set_rows was called with an array of the wrong size. */
        croak ("array has %d rows but PNG image requires %d rows",
	       n_rows, height);
    }
    MESSAGE ("%d rows.\n", n_rows);
    GET_MEMORY (png->row_pointers, n_rows, unsigned char *);
    png->row_pointers_ours = 1;
    arbytes = height * rbytes;
    GET_MEMORY (ar, arbytes, unsigned char); 
    r = ar;
    for (i = 0; i < n_rows; i++) {
        /* Need to check that this is the same as the width of the image. */
        STRLEN length;
	SV ** row_i_ptr;
	/* The data from Perl's row. */
	const unsigned char * pr;

        row_i_ptr = av_fetch (rows, i, 0);
	if (! row_i_ptr) {
	    croak ("NULL pointer at offset %d of rows", i);
	}
	pr = (const unsigned char *) SvPV (*row_i_ptr, length);
	if (length > rbytes) {
	    warn ("Row %d is %zu bytes, which is too long; truncating to %d",
		  i, length, rbytes);
	    length = rbytes;
	}
	memcpy (r, pr, length);
        png->row_pointers[i] = r;
        MESSAGE ("Copying row %d, length %d", i, length);
	r += rbytes;
    }
    if (r != ar + arbytes) {
	/* Final check after writing row data. */
	croak ("%s:%d: Mismatch %p != %p", __FILE__, __LINE__,
	       r, ar + arbytes);
    }
    png_set_rows (pngi, png->row_pointers);
    png->all_rows = ar;
}

static void
perl_png_write_image (perl_libpng_t * png, AV * rows)
{
    check_init_io (png);
    perl_png_set_rows (png, rows);
    png_write_image (png->png, png->row_pointers);
}

/*  __  __                                                                      
   |  \/  | ___  ___ ___  __ _  __ _  ___  ___      ___ _ __ _ __ ___  _ __ ___ 
   | |\/| |/ _ \/ __/ __|/ _` |/ _` |/ _ \/ __|    / _ \ '__| '__/ _ \| '__/ __|
   | |  | |  __/\__ \__ \ (_| | (_| |  __/\__ \_  |  __/ |  | | | (_) | |  \__ \
   |_|  |_|\___||___/___/\__,_|\__, |\___||___( )  \___|_|  |_|  \___/|_|  |___/
                               |___/          |/                                
                    _                            _                 
     __ _ _ __   __| | __      ____ _ _ __ _ __ (_)_ __   __ _ ___ 
    / _` | '_ \ / _` | \ \ /\ / / _` | '__| '_ \| | '_ \ / _` / __|
   | (_| | | | | (_| |  \ V  V / (_| | |  | | | | | | | | (_| \__ \
    \__,_|_| |_|\__,_|   \_/\_/ \__,_|_|  |_| |_|_|_| |_|\__, |___/
                                                         |___/      */

static void perl_png_set_verbosity (perl_libpng_t * png, int verbosity)
{
    png->verbosity = verbosity;
    MESSAGE ("You have asked me to print messages saying what I'm doing.");
}

/* PNG chunk names have to be four bytes in length. The following
   macro is to make this readable to humans. */

#define PERL_PNG_CHUNK_NAME_LENGTH 4

/*  ____       _            _              _                 _        
   |  _ \ _ __(_)_   ____ _| |_ ___    ___| |__  _   _ _ __ | | _____ 
   | |_) | '__| \ \ / / _` | __/ _ \  / __| '_ \| | | | '_ \| |/ / __|
   |  __/| |  | |\ V / (_| | ||  __/ | (__| | | | |_| | | | |   <\__ \
   |_|   |_|  |_| \_/ \__,_|\__\___|  \___|_| |_|\__,_|_| |_|_|\_\___/ */
                                                                   


/* Get any unknown chunks from the program. */

static SV * perl_png_get_unknown_chunks (perl_libpng_t * png)
{
#ifdef PNG_READ_UNKNOWN_CHUNKS_SUPPORTED
    png_unknown_chunkp unknown_chunks;
    int n_chunks;
    n_chunks = png_get_unknown_chunks (pngi, & unknown_chunks);
    MESSAGE ("There are %d private chunks.\n", n_chunks);
    if (n_chunks == 0) {
        return & PL_sv_undef;
    }
    else {
        AV * chunk_list;
        int i;

        chunk_list = newAV ();
        for (i = 0; i < n_chunks; i++) {
            HV * perl_chunk;
            SV * perl_chunk_ref;
            png_unknown_chunk * png_chunk;
            /* These hold the chunk info from the PNG chunk */
            SV * name;
            SV * data;
            SV * location;

            png_chunk = unknown_chunks + i;
            perl_chunk = newHV ();

	    /* Make Perl scalars from the chunk name and the PNG data
	       segment. */

            name = newSVpvn (((char *) png_chunk->name),
                             PERL_PNG_CHUNK_NAME_LENGTH);
            data = newSVpvn (((char *) png_chunk->data),
                             png_chunk->size);
            location = newSViv (png_chunk->location);

	    /* Put the scalars into the hash. */

#define STORE(x) (void) hv_store (perl_chunk, #x, strlen (#x), x, 0);
            STORE(name);
            STORE(data);
            STORE(location);
#undef STORE
            perl_chunk_ref = newRV_noinc ((SV *) perl_chunk);
            av_push (chunk_list, perl_chunk_ref);
        }
        return newRV_noinc ((SV *) chunk_list);
    }
#else
    UNSUPPORTED(READ_UNKNOWN_CHUNKS);
    return & PL_sv_undef;
#endif
}

static const char * bad_chunk_names[] = {
    "IHDR",
    "IEND",
};

static int n_bad_chunk_names =
    (sizeof (bad_chunk_names) / sizeof (const char *));

/* Set private chunks in the PNG. */

static void
perl_png_set_unknown_chunks (perl_libpng_t * png, AV * chunk_list)
{
#ifdef PNG_WRITE_UNKNOWN_CHUNKS_SUPPORTED
    /* n_chunks is the number of chunks the user proposes to add to
       the PNG. */
    int n_chunks;
    /* n_ok_chunks is the number of chunks which are acceptable to add
       to the PNG. */
    int n_ok_chunks;
    int i;
    png_unknown_chunkp unknown_chunks;

    n_chunks = av_len (chunk_list) + 1;
   
    if (n_chunks == 0) {
        /* The user tried to set an empty list of unknown chunks. */
        croak ("Number of unknown chunks is zero");
    }
    GET_MEMORY (unknown_chunks, n_chunks, png_unknown_chunk);
    n_ok_chunks = 0;
    for (i = 0; i < n_chunks; i++) {
        HV * perl_chunk = 0;
	SV ** chunk_pointer;
        png_unknown_chunk * png_chunk = 0;
        char * name;
        STRLEN name_length;
        char * data;
        STRLEN data_length;
	int location;
	int j;
	int bad;

        MESSAGE ("%d.\n", i);
        /* Get the chunk name and check it is four bytes long. */

	chunk_pointer = av_fetch (chunk_list, i, 0);
	if (! chunk_pointer ||
	    ! SvROK (* chunk_pointer) ||
	    SvTYPE(SvRV(*chunk_pointer)) != SVt_PVHV) {
            warn ( "Non-hash in chunk array");
            continue;
	}
	perl_chunk = (HV*) SvRV (*chunk_pointer);

        HASH_FETCH_PV (perl_chunk, name);
        if (name_length != PERL_PNG_CHUNK_NAME_LENGTH) {
            /* The user's name for a private chunk was not a valid
               length. In this case the chunk is ignored. */
            warn ( "Illegal PNG chunk name length %d, "
		   "chunk names must be %d characters long",
		   (int) name_length, PERL_PNG_CHUNK_NAME_LENGTH);
            continue;
        }
	bad = 0;
	for (j = 0; j < n_bad_chunk_names; j++) {
	    if (strcmp (name, bad_chunk_names[j]) == 0) {
		warn ("Cannot use name '%s' for private chunk", name);
	    }
	}
	if (bad) {
	    continue;
	}
        png_chunk = unknown_chunks + n_ok_chunks;
        strncpy ((char *) png_chunk->name, (char *) name,
                 PERL_PNG_CHUNK_NAME_LENGTH);

        /* Get the data part of the unknown chunk. */

        HASH_FETCH_PV (perl_chunk, data);
        
        png_chunk->data = (unsigned char *) data;
        png_chunk->size = data_length;

	HASH_FETCH_IV (perl_chunk, location);
	png_chunk->location = location;
        n_ok_chunks++;
    }
    png_set_keep_unknown_chunks(png->png, 3,
				NULL, 0);

    MESSAGE ("sending %d chunks.\n", n_ok_chunks);
    png_set_unknown_chunks (pngi, unknown_chunks, n_ok_chunks);
    for (i = 0; i < n_ok_chunks; i++) {
       	png_set_unknown_chunk_location (pngi, i, PNG_AFTER_IDAT);
    }
    PERL_PNG_FREE (unknown_chunks);
#else
    UNSUPPORTED (WRITE_UNKNOWN_CHUNKS);
#endif
}

static void
perl_png_set_keep_unknown_chunks (perl_libpng_t * png, int keep,
                                  SV * chunk_list)
{
#if defined(PNG_UNKNOWN_CHUNKS_SUPPORTED)
    if (chunk_list && 
        SvROK (chunk_list) && 
        SvTYPE (SvRV (chunk_list)) == SVt_PVAV) {
        int num_chunks;
        char * chunk_list_text;
        AV * chunk_list_av;
        int i;
        const int len = (PERL_PNG_CHUNK_NAME_LENGTH + 1);

        chunk_list_av = (AV *) SvRV (chunk_list);
        num_chunks = av_len (chunk_list_av) + 1;
        MESSAGE ("There are %d chunks in your list.\n", num_chunks);
        if (num_chunks == 0) {
            goto empty_chunk_list;
        }
	Newxz (chunk_list_text, len * num_chunks, char);
        png->memory_gets++;
        for (i = 0; i < num_chunks; i++) {
            const char * chunk_i_name;
            STRLEN chunk_i_length;
            SV ** chunk_i_sv_ptr;
            int j;
            chunk_i_sv_ptr = av_fetch (chunk_list_av, i, 0);
            if (! chunk_i_sv_ptr) {
                /* The chunk name was not defined.  */
                croak ("undefined chunk name at offset %d in chunk list", i);
            }
            chunk_i_name = SvPV (*chunk_i_sv_ptr, chunk_i_length);
            if (chunk_i_length != PERL_PNG_CHUNK_NAME_LENGTH) {
                croak ("chunk %i has bad length %zu: should be %d in chunk list", i, chunk_i_length, PERL_PNG_CHUNK_NAME_LENGTH);
            }
            MESSAGE ("Keeping chunk '%s'\n", chunk_i_name);
            for (j = 0; j < PERL_PNG_CHUNK_NAME_LENGTH; j++) {
                chunk_list_text [ i * len + j ] = chunk_i_name [ j ];
            }
            chunk_list_text [ i * len + PERL_PNG_CHUNK_NAME_LENGTH ] = '\0';
        }
        png_set_keep_unknown_chunks (png->png, keep,
                                     (unsigned char *) chunk_list_text,
				     num_chunks);
        Safefree (chunk_list_text);
        png->memory_gets--;
    }
    else {
        MESSAGE ("There is no valid chunk list.");
    empty_chunk_list:
        png_set_keep_unknown_chunks (png->png, keep, 0, 0);
    }
#else
    /* libpng was compiled without this option. */
    UNSUPPORTED (UNKNOWN_CHUNKS);
    return & PL_sv_undef;
#endif
}

/*  ____                               _       
   / ___| _   _ _ __  _ __   ___  _ __| |_ ___ 
   \___ \| | | | '_ \| '_ \ / _ \| '__| __/ __|
    ___) | |_| | |_) | |_) | (_) | |  | |_\__ \
   |____/ \__,_| .__/| .__/ \___/|_|   \__|___/
               |_|   |_|                        */

/* Does the libpng support "what"? */

int perl_png_libpng_supports (const char * what)
{
    if (strcmp (what, "sCAL") == 0) {
#ifdef PERL_PNG_sCAL_s_SUPPORTED
        return 1;
#else
        return 0;
#endif /* PERL_PNG_sCAL_s_SUPPORTED */
    }

    if (strcmp (what, "CHUNK_CACHE_MAX") == 0) {
#ifdef PNG_CHUNK_CACHE_MAX_SUPPORTED
        return 1;
#else
        return 0;
#endif /* PNG_CHUNK_CACHE_MAX_SUPPORTED */
    }

    if (strcmp (what, "CHUNK_MALLOC_MAX") == 0) {
#ifdef PNG_CHUNK_MALLOC_MAX_SUPPORTED
        return 1;
#else
        return 0;
#endif /* PNG_CHUNK_MALLOC_MAX_SUPPORTED */
    }

    if (strcmp (what, "cHRM_XYZ") == 0) {
#ifdef PNG_cHRM_XYZ_SUPPORTED
        return 1;
#else
        return 0;
#endif /* PNG_cHRM_XYZ_SUPPORTED */
    }

#line 2793 "/usr/home/ben/projects/image-png-libpng/build/../perl-libpng.c"
    if (strcmp (what, "16BIT") == 0) {
#ifdef PNG_16BIT_SUPPORTED
        return 1;
#else
        return 0;
#endif /* 16BIT */
    }
    if (strcmp (what, "ALIGNED_MEMORY") == 0) {
#ifdef PNG_ALIGNED_MEMORY_SUPPORTED
        return 1;
#else
        return 0;
#endif /* ALIGNED_MEMORY */
    }
    if (strcmp (what, "ARM_NEON_API") == 0) {
#ifdef PNG_ARM_NEON_API_SUPPORTED
        return 1;
#else
        return 0;
#endif /* ARM_NEON_API */
    }
    if (strcmp (what, "BENIGN_ERRORS") == 0) {
#ifdef PNG_BENIGN_ERRORS_SUPPORTED
        return 1;
#else
        return 0;
#endif /* BENIGN_ERRORS */
    }
    if (strcmp (what, "BENIGN_READ_ERRORS") == 0) {
#ifdef PNG_BENIGN_READ_ERRORS_SUPPORTED
        return 1;
#else
        return 0;
#endif /* BENIGN_READ_ERRORS */
    }
    if (strcmp (what, "BENIGN_WRITE_ERRORS") == 0) {
#ifdef PNG_BENIGN_WRITE_ERRORS_SUPPORTED
        return 1;
#else
        return 0;
#endif /* BENIGN_WRITE_ERRORS */
    }
    if (strcmp (what, "bKGD") == 0) {
#ifdef PNG_bKGD_SUPPORTED
        return 1;
#else
        return 0;
#endif /* bKGD */
    }
    if (strcmp (what, "BUILD_GRAYSCALE_PALETTE") == 0) {
#ifdef PNG_BUILD_GRAYSCALE_PALETTE_SUPPORTED
        return 1;
#else
        return 0;
#endif /* BUILD_GRAYSCALE_PALETTE */
    }
    if (strcmp (what, "BUILTIN_BSWAP16") == 0) {
#ifdef PNG_BUILTIN_BSWAP16_SUPPORTED
        return 1;
#else
        return 0;
#endif /* BUILTIN_BSWAP16 */
    }
    if (strcmp (what, "CHECK_FOR_INVALID_INDEX") == 0) {
#ifdef PNG_CHECK_FOR_INVALID_INDEX_SUPPORTED
        return 1;
#else
        return 0;
#endif /* CHECK_FOR_INVALID_INDEX */
    }
    if (strcmp (what, "cHRM") == 0) {
#ifdef PNG_cHRM_SUPPORTED
        return 1;
#else
        return 0;
#endif /* cHRM */
    }
    if (strcmp (what, "cHRM_XYZ") == 0) {
#ifdef PNG_cHRM_XYZ_SUPPORTED
        return 1;
#else
        return 0;
#endif /* cHRM_XYZ */
    }
    if (strcmp (what, "CHUNK_CACHE_MAX") == 0) {
#ifdef PNG_CHUNK_CACHE_MAX_SUPPORTED
        return 1;
#else
        return 0;
#endif /* CHUNK_CACHE_MAX */
    }
    if (strcmp (what, "CHUNK_MALLOC_MAX") == 0) {
#ifdef PNG_CHUNK_MALLOC_MAX_SUPPORTED
        return 1;
#else
        return 0;
#endif /* CHUNK_MALLOC_MAX */
    }
    if (strcmp (what, "COLORSPACE") == 0) {
#ifdef PNG_COLORSPACE_SUPPORTED
        return 1;
#else
        return 0;
#endif /* COLORSPACE */
    }
    if (strcmp (what, "CONSOLE_IO") == 0) {
#ifdef PNG_CONSOLE_IO_SUPPORTED
        return 1;
#else
        return 0;
#endif /* CONSOLE_IO */
    }
    if (strcmp (what, "CONVERT_tIME") == 0) {
#ifdef PNG_CONVERT_tIME_SUPPORTED
        return 1;
#else
        return 0;
#endif /* CONVERT_tIME */
    }
    if (strcmp (what, "CONVERT_tIME") == 0) {
#ifdef PNG_CONVERT_tIME_SUPPORTED
        return 1;
#else
        return 0;
#endif /* CONVERT_tIME */
    }
    if (strcmp (what, "EASY_ACCESS") == 0) {
#ifdef PNG_EASY_ACCESS_SUPPORTED
        return 1;
#else
        return 0;
#endif /* EASY_ACCESS */
    }
    if (strcmp (what, "ERROR_NUMBERS") == 0) {
#ifdef PNG_ERROR_NUMBERS_SUPPORTED
        return 1;
#else
        return 0;
#endif /* ERROR_NUMBERS */
    }
    if (strcmp (what, "ERROR_TEXT") == 0) {
#ifdef PNG_ERROR_TEXT_SUPPORTED
        return 1;
#else
        return 0;
#endif /* ERROR_TEXT */
    }
    if (strcmp (what, "eXIf") == 0) {
#ifdef PNG_eXIf_SUPPORTED
        return 1;
#else
        return 0;
#endif /* eXIf */
    }
    if (strcmp (what, "FIXED_POINT") == 0) {
#ifdef PNG_FIXED_POINT_SUPPORTED
        return 1;
#else
        return 0;
#endif /* FIXED_POINT */
    }
    if (strcmp (what, "FIXED_POINT_MACRO") == 0) {
#ifdef PNG_FIXED_POINT_MACRO_SUPPORTED
        return 1;
#else
        return 0;
#endif /* FIXED_POINT_MACRO */
    }
    if (strcmp (what, "FLOATING_ARITHMETIC") == 0) {
#ifdef PNG_FLOATING_ARITHMETIC_SUPPORTED
        return 1;
#else
        return 0;
#endif /* FLOATING_ARITHMETIC */
    }
    if (strcmp (what, "FLOATING_POINT") == 0) {
#ifdef PNG_FLOATING_POINT_SUPPORTED
        return 1;
#else
        return 0;
#endif /* FLOATING_POINT */
    }
    if (strcmp (what, "FORMAT_AFIRST") == 0) {
#ifdef PNG_FORMAT_AFIRST_SUPPORTED
        return 1;
#else
        return 0;
#endif /* FORMAT_AFIRST */
    }
    if (strcmp (what, "FORMAT_BGR") == 0) {
#ifdef PNG_FORMAT_BGR_SUPPORTED
        return 1;
#else
        return 0;
#endif /* FORMAT_BGR */
    }
    if (strcmp (what, "gAMA") == 0) {
#ifdef PNG_gAMA_SUPPORTED
        return 1;
#else
        return 0;
#endif /* gAMA */
    }
    if (strcmp (what, "GAMMA") == 0) {
#ifdef PNG_GAMMA_SUPPORTED
        return 1;
#else
        return 0;
#endif /* GAMMA */
    }
    if (strcmp (what, "GET_PALETTE_MAX") == 0) {
#ifdef PNG_GET_PALETTE_MAX_SUPPORTED
        return 1;
#else
        return 0;
#endif /* GET_PALETTE_MAX */
    }
    if (strcmp (what, "HANDLE_AS_UNKNOWN") == 0) {
#ifdef PNG_HANDLE_AS_UNKNOWN_SUPPORTED
        return 1;
#else
        return 0;
#endif /* HANDLE_AS_UNKNOWN */
    }
    if (strcmp (what, "HANDLE_AS_UNKNOWN") == 0) {
#ifdef PNG_HANDLE_AS_UNKNOWN_SUPPORTED
        return 1;
#else
        return 0;
#endif /* HANDLE_AS_UNKNOWN */
    }
    if (strcmp (what, "hIST") == 0) {
#ifdef PNG_hIST_SUPPORTED
        return 1;
#else
        return 0;
#endif /* hIST */
    }
    if (strcmp (what, "iCCP") == 0) {
#ifdef PNG_iCCP_SUPPORTED
        return 1;
#else
        return 0;
#endif /* iCCP */
    }
    if (strcmp (what, "INCH_CONVERSIONS") == 0) {
#ifdef PNG_INCH_CONVERSIONS_SUPPORTED
        return 1;
#else
        return 0;
#endif /* INCH_CONVERSIONS */
    }
    if (strcmp (what, "INFO_IMAGE") == 0) {
#ifdef PNG_INFO_IMAGE_SUPPORTED
        return 1;
#else
        return 0;
#endif /* INFO_IMAGE */
    }
    if (strcmp (what, "IO_STATE") == 0) {
#ifdef PNG_IO_STATE_SUPPORTED
        return 1;
#else
        return 0;
#endif /* IO_STATE */
    }
    if (strcmp (what, "iTXt") == 0) {
#ifdef PNG_iTXt_SUPPORTED
        return 1;
#else
        return 0;
#endif /* iTXt */
    }
    if (strcmp (what, "MIPS_MSA_API") == 0) {
#ifdef PNG_MIPS_MSA_API_SUPPORTED
        return 1;
#else
        return 0;
#endif /* MIPS_MSA_API */
    }
    if (strcmp (what, "MNG_FEATURES") == 0) {
#ifdef PNG_MNG_FEATURES_SUPPORTED
        return 1;
#else
        return 0;
#endif /* MNG_FEATURES */
    }
    if (strcmp (what, "oFFs") == 0) {
#ifdef PNG_oFFs_SUPPORTED
        return 1;
#else
        return 0;
#endif /* oFFs */
    }
    if (strcmp (what, "pCAL") == 0) {
#ifdef PNG_pCAL_SUPPORTED
        return 1;
#else
        return 0;
#endif /* pCAL */
    }
    if (strcmp (what, "PEDANTIC_WARNINGS") == 0) {
#ifdef PNG_PEDANTIC_WARNINGS_SUPPORTED
        return 1;
#else
        return 0;
#endif /* PEDANTIC_WARNINGS */
    }
    if (strcmp (what, "pHYs") == 0) {
#ifdef PNG_pHYs_SUPPORTED
        return 1;
#else
        return 0;
#endif /* pHYs */
    }
    if (strcmp (what, "POINTER_INDEXING") == 0) {
#ifdef PNG_POINTER_INDEXING_SUPPORTED
        return 1;
#else
        return 0;
#endif /* POINTER_INDEXING */
    }
    if (strcmp (what, "POWERPC_VSX_API") == 0) {
#ifdef PNG_POWERPC_VSX_API_SUPPORTED
        return 1;
#else
        return 0;
#endif /* POWERPC_VSX_API */
    }
    if (strcmp (what, "PROGRESSIVE_READ") == 0) {
#ifdef PNG_PROGRESSIVE_READ_SUPPORTED
        return 1;
#else
        return 0;
#endif /* PROGRESSIVE_READ */
    }
    if (strcmp (what, "READ") == 0) {
#ifdef PNG_READ_SUPPORTED
        return 1;
#else
        return 0;
#endif /* READ */
    }
    if (strcmp (what, "READ_16_TO_8") == 0) {
#ifdef PNG_READ_16_TO_8_SUPPORTED
        return 1;
#else
        return 0;
#endif /* READ_16_TO_8 */
    }
    if (strcmp (what, "READ_ALPHA_MODE") == 0) {
#ifdef PNG_READ_ALPHA_MODE_SUPPORTED
        return 1;
#else
        return 0;
#endif /* READ_ALPHA_MODE */
    }
    if (strcmp (what, "READ_BACKGROUND") == 0) {
#ifdef PNG_READ_BACKGROUND_SUPPORTED
        return 1;
#else
        return 0;
#endif /* READ_BACKGROUND */
    }
    if (strcmp (what, "READ_BGR") == 0) {
#ifdef PNG_READ_BGR_SUPPORTED
        return 1;
#else
        return 0;
#endif /* READ_BGR */
    }
    if (strcmp (what, "READ_COMPOSITE_NODIV") == 0) {
#ifdef PNG_READ_COMPOSITE_NODIV_SUPPORTED
        return 1;
#else
        return 0;
#endif /* READ_COMPOSITE_NODIV */
    }
    if (strcmp (what, "READ_COMPRESSED_TEXT") == 0) {
#ifdef PNG_READ_COMPRESSED_TEXT_SUPPORTED
        return 1;
#else
        return 0;
#endif /* READ_COMPRESSED_TEXT */
    }
    if (strcmp (what, "READ_EXPAND") == 0) {
#ifdef PNG_READ_EXPAND_SUPPORTED
        return 1;
#else
        return 0;
#endif /* READ_EXPAND */
    }
    if (strcmp (what, "READ_EXPAND_16") == 0) {
#ifdef PNG_READ_EXPAND_16_SUPPORTED
        return 1;
#else
        return 0;
#endif /* READ_EXPAND_16 */
    }
    if (strcmp (what, "READ_FILLER") == 0) {
#ifdef PNG_READ_FILLER_SUPPORTED
        return 1;
#else
        return 0;
#endif /* READ_FILLER */
    }
    if (strcmp (what, "READ_GAMMA") == 0) {
#ifdef PNG_READ_GAMMA_SUPPORTED
        return 1;
#else
        return 0;
#endif /* READ_GAMMA */
    }
    if (strcmp (what, "READ_GRAY_TO_RGB") == 0) {
#ifdef PNG_READ_GRAY_TO_RGB_SUPPORTED
        return 1;
#else
        return 0;
#endif /* READ_GRAY_TO_RGB */
    }
    if (strcmp (what, "READ_INTERLACING") == 0) {
#ifdef PNG_READ_INTERLACING_SUPPORTED
        return 1;
#else
        return 0;
#endif /* READ_INTERLACING */
    }
    if (strcmp (what, "READ_INT_FUNCTIONS") == 0) {
#ifdef PNG_READ_INT_FUNCTIONS_SUPPORTED
        return 1;
#else
        return 0;
#endif /* READ_INT_FUNCTIONS */
    }
    if (strcmp (what, "READ_INVERT") == 0) {
#ifdef PNG_READ_INVERT_SUPPORTED
        return 1;
#else
        return 0;
#endif /* READ_INVERT */
    }
    if (strcmp (what, "READ_INVERT_ALPHA") == 0) {
#ifdef PNG_READ_INVERT_ALPHA_SUPPORTED
        return 1;
#else
        return 0;
#endif /* READ_INVERT_ALPHA */
    }
    if (strcmp (what, "READ_OPT_PLTE") == 0) {
#ifdef PNG_READ_OPT_PLTE_SUPPORTED
        return 1;
#else
        return 0;
#endif /* READ_OPT_PLTE */
    }
    if (strcmp (what, "READ_PACK") == 0) {
#ifdef PNG_READ_PACK_SUPPORTED
        return 1;
#else
        return 0;
#endif /* READ_PACK */
    }
    if (strcmp (what, "READ_PACKSWAP") == 0) {
#ifdef PNG_READ_PACKSWAP_SUPPORTED
        return 1;
#else
        return 0;
#endif /* READ_PACKSWAP */
    }
    if (strcmp (what, "READ_QUANTIZE") == 0) {
#ifdef PNG_READ_QUANTIZE_SUPPORTED
        return 1;
#else
        return 0;
#endif /* READ_QUANTIZE */
    }
    if (strcmp (what, "READ_RGB_TO_GRAY") == 0) {
#ifdef PNG_READ_RGB_TO_GRAY_SUPPORTED
        return 1;
#else
        return 0;
#endif /* READ_RGB_TO_GRAY */
    }
    if (strcmp (what, "READ_SCALE_16_TO_8") == 0) {
#ifdef PNG_READ_SCALE_16_TO_8_SUPPORTED
        return 1;
#else
        return 0;
#endif /* READ_SCALE_16_TO_8 */
    }
    if (strcmp (what, "READ_SHIFT") == 0) {
#ifdef PNG_READ_SHIFT_SUPPORTED
        return 1;
#else
        return 0;
#endif /* READ_SHIFT */
    }
    if (strcmp (what, "READ_STRIP_16_TO_8") == 0) {
#ifdef PNG_READ_STRIP_16_TO_8_SUPPORTED
        return 1;
#else
        return 0;
#endif /* READ_STRIP_16_TO_8 */
    }
    if (strcmp (what, "READ_STRIP_ALPHA") == 0) {
#ifdef PNG_READ_STRIP_ALPHA_SUPPORTED
        return 1;
#else
        return 0;
#endif /* READ_STRIP_ALPHA */
    }
    if (strcmp (what, "READ_SWAP") == 0) {
#ifdef PNG_READ_SWAP_SUPPORTED
        return 1;
#else
        return 0;
#endif /* READ_SWAP */
    }
    if (strcmp (what, "READ_SWAP_ALPHA") == 0) {
#ifdef PNG_READ_SWAP_ALPHA_SUPPORTED
        return 1;
#else
        return 0;
#endif /* READ_SWAP_ALPHA */
    }
    if (strcmp (what, "READ_tEXt") == 0) {
#ifdef PNG_READ_tEXt_SUPPORTED
        return 1;
#else
        return 0;
#endif /* READ_tEXt */
    }
    if (strcmp (what, "READ_TRANSFORMS") == 0) {
#ifdef PNG_READ_TRANSFORMS_SUPPORTED
        return 1;
#else
        return 0;
#endif /* READ_TRANSFORMS */
    }
    if (strcmp (what, "READ_USER_TRANSFORM") == 0) {
#ifdef PNG_READ_USER_TRANSFORM_SUPPORTED
        return 1;
#else
        return 0;
#endif /* READ_USER_TRANSFORM */
    }
    if (strcmp (what, "READ_zTXt") == 0) {
#ifdef PNG_READ_zTXt_SUPPORTED
        return 1;
#else
        return 0;
#endif /* READ_zTXt */
    }
    if (strcmp (what, "SAVE_INT_32") == 0) {
#ifdef PNG_SAVE_INT_32_SUPPORTED
        return 1;
#else
        return 0;
#endif /* SAVE_INT_32 */
    }
    if (strcmp (what, "SAVE_UNKNOWN_CHUNKS") == 0) {
#ifdef PNG_SAVE_UNKNOWN_CHUNKS_SUPPORTED
        return 1;
#else
        return 0;
#endif /* SAVE_UNKNOWN_CHUNKS */
    }
    if (strcmp (what, "sBIT") == 0) {
#ifdef PNG_sBIT_SUPPORTED
        return 1;
#else
        return 0;
#endif /* sBIT */
    }
    if (strcmp (what, "sCAL") == 0) {
#ifdef PNG_sCAL_SUPPORTED
        return 1;
#else
        return 0;
#endif /* sCAL */
    }
    if (strcmp (what, "SEQUENTIAL_READ") == 0) {
#ifdef PNG_SEQUENTIAL_READ_SUPPORTED
        return 1;
#else
        return 0;
#endif /* SEQUENTIAL_READ */
    }
    if (strcmp (what, "SETJMP") == 0) {
#ifdef PNG_SETJMP_SUPPORTED
        return 1;
#else
        return 0;
#endif /* SETJMP */
    }
    if (strcmp (what, "SET_OPTION") == 0) {
#ifdef PNG_SET_OPTION_SUPPORTED
        return 1;
#else
        return 0;
#endif /* SET_OPTION */
    }
    if (strcmp (what, "SET_UNKNOWN_CHUNKS") == 0) {
#ifdef PNG_SET_UNKNOWN_CHUNKS_SUPPORTED
        return 1;
#else
        return 0;
#endif /* SET_UNKNOWN_CHUNKS */
    }
    if (strcmp (what, "SET_USER_LIMITS") == 0) {
#ifdef PNG_SET_USER_LIMITS_SUPPORTED
        return 1;
#else
        return 0;
#endif /* SET_USER_LIMITS */
    }
    if (strcmp (what, "SIMPLIFIED_READ") == 0) {
#ifdef PNG_SIMPLIFIED_READ_SUPPORTED
        return 1;
#else
        return 0;
#endif /* SIMPLIFIED_READ */
    }
    if (strcmp (what, "SIMPLIFIED_READ_AFIRST") == 0) {
#ifdef PNG_SIMPLIFIED_READ_AFIRST_SUPPORTED
        return 1;
#else
        return 0;
#endif /* SIMPLIFIED_READ_AFIRST */
    }
    if (strcmp (what, "SIMPLIFIED_WRITE") == 0) {
#ifdef PNG_SIMPLIFIED_WRITE_SUPPORTED
        return 1;
#else
        return 0;
#endif /* SIMPLIFIED_WRITE */
    }
    if (strcmp (what, "SIMPLIFIED_WRITE_AFIRST") == 0) {
#ifdef PNG_SIMPLIFIED_WRITE_AFIRST_SUPPORTED
        return 1;
#else
        return 0;
#endif /* SIMPLIFIED_WRITE_AFIRST */
    }
    if (strcmp (what, "SIMPLIFIED_WRITE_BGR") == 0) {
#ifdef PNG_SIMPLIFIED_WRITE_BGR_SUPPORTED
        return 1;
#else
        return 0;
#endif /* SIMPLIFIED_WRITE_BGR */
    }
    if (strcmp (what, "SIMPLIFIED_WRITE_STDIO") == 0) {
#ifdef PNG_SIMPLIFIED_WRITE_STDIO_SUPPORTED
        return 1;
#else
        return 0;
#endif /* SIMPLIFIED_WRITE_STDIO */
    }
    if (strcmp (what, "sPLT") == 0) {
#ifdef PNG_sPLT_SUPPORTED
        return 1;
#else
        return 0;
#endif /* sPLT */
    }
    if (strcmp (what, "sRGB") == 0) {
#ifdef PNG_sRGB_SUPPORTED
        return 1;
#else
        return 0;
#endif /* sRGB */
    }
    if (strcmp (what, "STDIO") == 0) {
#ifdef PNG_STDIO_SUPPORTED
        return 1;
#else
        return 0;
#endif /* STDIO */
    }
    if (strcmp (what, "STORE_UNKNOWN_CHUNKS") == 0) {
#ifdef PNG_STORE_UNKNOWN_CHUNKS_SUPPORTED
        return 1;
#else
        return 0;
#endif /* STORE_UNKNOWN_CHUNKS */
    }
    if (strcmp (what, "TEXT") == 0) {
#ifdef PNG_TEXT_SUPPORTED
        return 1;
#else
        return 0;
#endif /* TEXT */
    }
    if (strcmp (what, "tEXt") == 0) {
#ifdef PNG_tEXt_SUPPORTED
        return 1;
#else
        return 0;
#endif /* tEXt */
    }
    if (strcmp (what, "tIME") == 0) {
#ifdef PNG_tIME_SUPPORTED
        return 1;
#else
        return 0;
#endif /* tIME */
    }
    if (strcmp (what, "TIME_RFC1123") == 0) {
#ifdef PNG_TIME_RFC1123_SUPPORTED
        return 1;
#else
        return 0;
#endif /* TIME_RFC1123 */
    }
    if (strcmp (what, "tRNS") == 0) {
#ifdef PNG_tRNS_SUPPORTED
        return 1;
#else
        return 0;
#endif /* tRNS */
    }
    if (strcmp (what, "UNKNOWN_CHUNKS") == 0) {
#ifdef PNG_UNKNOWN_CHUNKS_SUPPORTED
        return 1;
#else
        return 0;
#endif /* UNKNOWN_CHUNKS */
    }
    if (strcmp (what, "USER_CHUNKS") == 0) {
#ifdef PNG_USER_CHUNKS_SUPPORTED
        return 1;
#else
        return 0;
#endif /* USER_CHUNKS */
    }
    if (strcmp (what, "USER_LIMITS") == 0) {
#ifdef PNG_USER_LIMITS_SUPPORTED
        return 1;
#else
        return 0;
#endif /* USER_LIMITS */
    }
    if (strcmp (what, "USER_LIMITS") == 0) {
#ifdef PNG_USER_LIMITS_SUPPORTED
        return 1;
#else
        return 0;
#endif /* USER_LIMITS */
    }
    if (strcmp (what, "USER_MEM") == 0) {
#ifdef PNG_USER_MEM_SUPPORTED
        return 1;
#else
        return 0;
#endif /* USER_MEM */
    }
    if (strcmp (what, "USER_TRANSFORM_INFO") == 0) {
#ifdef PNG_USER_TRANSFORM_INFO_SUPPORTED
        return 1;
#else
        return 0;
#endif /* USER_TRANSFORM_INFO */
    }
    if (strcmp (what, "USER_TRANSFORM_PTR") == 0) {
#ifdef PNG_USER_TRANSFORM_PTR_SUPPORTED
        return 1;
#else
        return 0;
#endif /* USER_TRANSFORM_PTR */
    }
    if (strcmp (what, "WARNINGS") == 0) {
#ifdef PNG_WARNINGS_SUPPORTED
        return 1;
#else
        return 0;
#endif /* WARNINGS */
    }
    if (strcmp (what, "WRITE") == 0) {
#ifdef PNG_WRITE_SUPPORTED
        return 1;
#else
        return 0;
#endif /* WRITE */
    }
    if (strcmp (what, "WRITE_BGR") == 0) {
#ifdef PNG_WRITE_BGR_SUPPORTED
        return 1;
#else
        return 0;
#endif /* WRITE_BGR */
    }
    if (strcmp (what, "WRITE_COMPRESSED_TEXT") == 0) {
#ifdef PNG_WRITE_COMPRESSED_TEXT_SUPPORTED
        return 1;
#else
        return 0;
#endif /* WRITE_COMPRESSED_TEXT */
    }
    if (strcmp (what, "WRITE_CUSTOMIZE_COMPRESSION") == 0) {
#ifdef PNG_WRITE_CUSTOMIZE_COMPRESSION_SUPPORTED
        return 1;
#else
        return 0;
#endif /* WRITE_CUSTOMIZE_COMPRESSION */
    }
    if (strcmp (what, "WRITE_CUSTOMIZE_ZTXT_COMPRESSION") == 0) {
#ifdef PNG_WRITE_CUSTOMIZE_ZTXT_COMPRESSION_SUPPORTED
        return 1;
#else
        return 0;
#endif /* WRITE_CUSTOMIZE_ZTXT_COMPRESSION */
    }
    if (strcmp (what, "WRITE_FILLER") == 0) {
#ifdef PNG_WRITE_FILLER_SUPPORTED
        return 1;
#else
        return 0;
#endif /* WRITE_FILLER */
    }
    if (strcmp (what, "WRITE_FILTER") == 0) {
#ifdef PNG_WRITE_FILTER_SUPPORTED
        return 1;
#else
        return 0;
#endif /* WRITE_FILTER */
    }
    if (strcmp (what, "WRITE_FLUSH") == 0) {
#ifdef PNG_WRITE_FLUSH_SUPPORTED
        return 1;
#else
        return 0;
#endif /* WRITE_FLUSH */
    }
    if (strcmp (what, "WRITE_FLUSH_AFTER_IEND") == 0) {
#ifdef PNG_WRITE_FLUSH_AFTER_IEND_SUPPORTED
        return 1;
#else
        return 0;
#endif /* WRITE_FLUSH_AFTER_IEND */
    }
    if (strcmp (what, "WRITE_INTERLACING") == 0) {
#ifdef PNG_WRITE_INTERLACING_SUPPORTED
        return 1;
#else
        return 0;
#endif /* WRITE_INTERLACING */
    }
    if (strcmp (what, "WRITE_INT_FUNCTIONS") == 0) {
#ifdef PNG_WRITE_INT_FUNCTIONS_SUPPORTED
        return 1;
#else
        return 0;
#endif /* WRITE_INT_FUNCTIONS */
    }
    if (strcmp (what, "WRITE_INVERT") == 0) {
#ifdef PNG_WRITE_INVERT_SUPPORTED
        return 1;
#else
        return 0;
#endif /* WRITE_INVERT */
    }
    if (strcmp (what, "WRITE_INVERT_ALPHA") == 0) {
#ifdef PNG_WRITE_INVERT_ALPHA_SUPPORTED
        return 1;
#else
        return 0;
#endif /* WRITE_INVERT_ALPHA */
    }
    if (strcmp (what, "WRITE_OPTIMIZE_CMF") == 0) {
#ifdef PNG_WRITE_OPTIMIZE_CMF_SUPPORTED
        return 1;
#else
        return 0;
#endif /* WRITE_OPTIMIZE_CMF */
    }
    if (strcmp (what, "WRITE_PACK") == 0) {
#ifdef PNG_WRITE_PACK_SUPPORTED
        return 1;
#else
        return 0;
#endif /* WRITE_PACK */
    }
    if (strcmp (what, "WRITE_PACKSWAP") == 0) {
#ifdef PNG_WRITE_PACKSWAP_SUPPORTED
        return 1;
#else
        return 0;
#endif /* WRITE_PACKSWAP */
    }
    if (strcmp (what, "WRITE_SHIFT") == 0) {
#ifdef PNG_WRITE_SHIFT_SUPPORTED
        return 1;
#else
        return 0;
#endif /* WRITE_SHIFT */
    }
    if (strcmp (what, "WRITE_SWAP") == 0) {
#ifdef PNG_WRITE_SWAP_SUPPORTED
        return 1;
#else
        return 0;
#endif /* WRITE_SWAP */
    }
    if (strcmp (what, "WRITE_SWAP_ALPHA") == 0) {
#ifdef PNG_WRITE_SWAP_ALPHA_SUPPORTED
        return 1;
#else
        return 0;
#endif /* WRITE_SWAP_ALPHA */
    }
    if (strcmp (what, "WRITE_TRANSFORMS") == 0) {
#ifdef PNG_WRITE_TRANSFORMS_SUPPORTED
        return 1;
#else
        return 0;
#endif /* WRITE_TRANSFORMS */
    }
    if (strcmp (what, "WRITE_USER_TRANSFORM") == 0) {
#ifdef PNG_WRITE_USER_TRANSFORM_SUPPORTED
        return 1;
#else
        return 0;
#endif /* WRITE_USER_TRANSFORM */
    }
    if (strcmp (what, "WRITE_WEIGHTED_FILTER") == 0) {
#ifdef PNG_WRITE_WEIGHTED_FILTER_SUPPORTED
        return 1;
#else
        return 0;
#endif /* WRITE_WEIGHTED_FILTER */
    }
    if (strcmp (what, "zTXt") == 0) {
#ifdef PNG_zTXt_SUPPORTED
        return 1;
#else
        return 0;
#endif /* zTXt */
    }
#line 2774 "tmpl/perl-libpng.c.tmpl"

    /* sCAL is a special case. */

    if (strcmp (what, "sCAL") == 0) {
#ifdef PERL_PNG_sCAL_s_SUPPORTED
        return 1;
#else
        return 0;
#endif /* sCAL */
    }
    /* These were in the module prior to 0.50, even though there is no
       such macro in libpng. */
    if (strcmp (what, "zTXt") == 0) {
#if defined(PNG_READ_zTXt_SUPPORTED) && defined(PNG_WRITE_zTXt_SUPPORTED)
	return 1;
#else
	return 0;
#endif
    }
    if (strcmp (what, "tEXt") == 0) {
#if defined(PNG_READ_tEXt_SUPPORTED) && defined(PNG_WRITE_tEXt_SUPPORTED)
	return 1;
#else
	return 0;
#endif
    }
    /* The user asked whether something was supported, but we don't
       know what that thing is. */
    warn ("Unknown whether '%s' is supported", what);
    return 0;
}

/*       _   _ ____  __  __ 
     ___| | | |  _ \|  \/  |
    / __| |_| | |_) | |\/| |
   | (__|  _  |  _ <| |  | |
    \___|_| |_|_| \_\_|  |_| */
                         


static SV * perl_png_get_cHRM (perl_libpng_t * png)
{
    SV * chrm = & PL_sv_undef; 
#ifdef PNG_cHRM_SUPPORTED
    if (VALID (cHRM)) {
        HV * ice;
#line 3779 "/usr/home/ben/projects/image-png-libpng/build/../perl-libpng.c"
        double white_x;
        double white_y;
        double red_x;
        double red_y;
        double green_x;
        double green_y;
        double blue_x;
        double blue_y;
#line 2820 "tmpl/perl-libpng.c.tmpl"
        png_get_cHRM (pngi , & white_x, & white_y, & red_x, & red_y, & green_x, & green_y, & blue_x, & blue_y);
        ice = newHV ();
#line 3791 "/usr/home/ben/projects/image-png-libpng/build/../perl-libpng.c"
        (void) hv_store (ice, "white_x", strlen ("white_x"),
                         newSVnv (white_x), 0);
        (void) hv_store (ice, "white_y", strlen ("white_y"),
                         newSVnv (white_y), 0);
        (void) hv_store (ice, "red_x", strlen ("red_x"),
                         newSVnv (red_x), 0);
        (void) hv_store (ice, "red_y", strlen ("red_y"),
                         newSVnv (red_y), 0);
        (void) hv_store (ice, "green_x", strlen ("green_x"),
                         newSVnv (green_x), 0);
        (void) hv_store (ice, "green_y", strlen ("green_y"),
                         newSVnv (green_y), 0);
        (void) hv_store (ice, "blue_x", strlen ("blue_x"),
                         newSVnv (blue_x), 0);
        (void) hv_store (ice, "blue_y", strlen ("blue_y"),
                         newSVnv (blue_y), 0);
#line 2829 "tmpl/perl-libpng.c.tmpl"
        chrm = newRV_noinc ((SV *) ice);
    }
#else
    /* libpng was compiled without this option. */
    UNSUPPORTED(cHRM);
#endif
    return chrm;
}

static void perl_png_set_cHRM (perl_libpng_t * png, HV * cHRM)
{
#ifdef PNG_cHRM_SUPPORTED
    SV ** key_sv_ptr;
#line 3822 "/usr/home/ben/projects/image-png-libpng/build/../perl-libpng.c"
    double white_x = 0.0;
    double white_y = 0.0;
    double red_x = 0.0;
    double red_y = 0.0;
    double green_x = 0.0;
    double green_y = 0.0;
    double blue_x = 0.0;
    double blue_y = 0.0;
    key_sv_ptr = hv_fetch (cHRM, "white_x", strlen ("white_x"), 0);
    if (key_sv_ptr) {
        white_x = SvNV (* key_sv_ptr);
    }
    key_sv_ptr = hv_fetch (cHRM, "white_y", strlen ("white_y"), 0);
    if (key_sv_ptr) {
        white_y = SvNV (* key_sv_ptr);
    }
    key_sv_ptr = hv_fetch (cHRM, "red_x", strlen ("red_x"), 0);
    if (key_sv_ptr) {
        red_x = SvNV (* key_sv_ptr);
    }
    key_sv_ptr = hv_fetch (cHRM, "red_y", strlen ("red_y"), 0);
    if (key_sv_ptr) {
        red_y = SvNV (* key_sv_ptr);
    }
    key_sv_ptr = hv_fetch (cHRM, "green_x", strlen ("green_x"), 0);
    if (key_sv_ptr) {
        green_x = SvNV (* key_sv_ptr);
    }
    key_sv_ptr = hv_fetch (cHRM, "green_y", strlen ("green_y"), 0);
    if (key_sv_ptr) {
        green_y = SvNV (* key_sv_ptr);
    }
    key_sv_ptr = hv_fetch (cHRM, "blue_x", strlen ("blue_x"), 0);
    if (key_sv_ptr) {
        blue_x = SvNV (* key_sv_ptr);
    }
    key_sv_ptr = hv_fetch (cHRM, "blue_y", strlen ("blue_y"), 0);
    if (key_sv_ptr) {
        blue_y = SvNV (* key_sv_ptr);
    }
#line 2853 "tmpl/perl-libpng.c.tmpl"
    png_set_cHRM (pngi, white_x, white_y, red_x, red_y, green_x, green_y, blue_x, blue_y);
#line 2856 "tmpl/perl-libpng.c.tmpl"
#else
    /* libpng was compiled without this option. */
    UNSUPPORTED(cHRM);
#endif
}

#ifdef PNG_cHRM_XYZ_SUPPORTED

/* The following two functions are already protected within
   Libpng.XS.tmpl, so we don't need a protector or UNSUPPORTED call
   within these functions. */

static SV * perl_png_get_cHRM_XYZ (perl_libpng_t * png)
{
    SV * chrm = & PL_sv_undef; 
    if (VALID (cHRM)) {
        HV * ice;
#line 3883 "/usr/home/ben/projects/image-png-libpng/build/../perl-libpng.c"
        double red_x;
        double red_y;
        double red_z;
        double green_x;
        double green_y;
        double green_z;
        double blue_x;
        double blue_y;
        double blue_z;
#line 2878 "tmpl/perl-libpng.c.tmpl"
        png_get_cHRM_XYZ (pngi , & red_x, & red_y, & red_z, & green_x, & green_y, & green_z, & blue_x, & blue_y, & blue_z);
        ice = newHV ();
#line 3896 "/usr/home/ben/projects/image-png-libpng/build/../perl-libpng.c"
        (void) hv_store (ice, "red_x", strlen ("red_x"),
                         newSVnv (red_x), 0);
        (void) hv_store (ice, "red_y", strlen ("red_y"),
                         newSVnv (red_y), 0);
        (void) hv_store (ice, "red_z", strlen ("red_z"),
                         newSVnv (red_z), 0);
        (void) hv_store (ice, "green_x", strlen ("green_x"),
                         newSVnv (green_x), 0);
        (void) hv_store (ice, "green_y", strlen ("green_y"),
                         newSVnv (green_y), 0);
        (void) hv_store (ice, "green_z", strlen ("green_z"),
                         newSVnv (green_z), 0);
        (void) hv_store (ice, "blue_x", strlen ("blue_x"),
                         newSVnv (blue_x), 0);
        (void) hv_store (ice, "blue_y", strlen ("blue_y"),
                         newSVnv (blue_y), 0);
        (void) hv_store (ice, "blue_z", strlen ("blue_z"),
                         newSVnv (blue_z), 0);
#line 2887 "tmpl/perl-libpng.c.tmpl"
        chrm = newRV_noinc ((SV *) ice);
    }
    return chrm;
}

static void perl_png_set_cHRM_XYZ (perl_libpng_t * png, HV * cHRM_XYZ)
{
    SV ** key_sv_ptr;
#line 3924 "/usr/home/ben/projects/image-png-libpng/build/../perl-libpng.c"
    double red_x = 0.0;
    double red_y = 0.0;
    double red_z = 0.0;
    double green_x = 0.0;
    double green_y = 0.0;
    double green_z = 0.0;
    double blue_x = 0.0;
    double blue_y = 0.0;
    double blue_z = 0.0;
    key_sv_ptr = hv_fetch (cHRM_XYZ, "red_x", strlen ("red_x"), 0);
    if (key_sv_ptr) {
        red_x = SvNV (* key_sv_ptr);
    }
    key_sv_ptr = hv_fetch (cHRM_XYZ, "red_y", strlen ("red_y"), 0);
    if (key_sv_ptr) {
        red_y = SvNV (* key_sv_ptr);
    }
    key_sv_ptr = hv_fetch (cHRM_XYZ, "red_z", strlen ("red_z"), 0);
    if (key_sv_ptr) {
        red_z = SvNV (* key_sv_ptr);
    }
    key_sv_ptr = hv_fetch (cHRM_XYZ, "green_x", strlen ("green_x"), 0);
    if (key_sv_ptr) {
        green_x = SvNV (* key_sv_ptr);
    }
    key_sv_ptr = hv_fetch (cHRM_XYZ, "green_y", strlen ("green_y"), 0);
    if (key_sv_ptr) {
        green_y = SvNV (* key_sv_ptr);
    }
    key_sv_ptr = hv_fetch (cHRM_XYZ, "green_z", strlen ("green_z"), 0);
    if (key_sv_ptr) {
        green_z = SvNV (* key_sv_ptr);
    }
    key_sv_ptr = hv_fetch (cHRM_XYZ, "blue_x", strlen ("blue_x"), 0);
    if (key_sv_ptr) {
        blue_x = SvNV (* key_sv_ptr);
    }
    key_sv_ptr = hv_fetch (cHRM_XYZ, "blue_y", strlen ("blue_y"), 0);
    if (key_sv_ptr) {
        blue_y = SvNV (* key_sv_ptr);
    }
    key_sv_ptr = hv_fetch (cHRM_XYZ, "blue_z", strlen ("blue_z"), 0);
    if (key_sv_ptr) {
        blue_z = SvNV (* key_sv_ptr);
    }
#line 2906 "tmpl/perl-libpng.c.tmpl"
    png_set_cHRM_XYZ (pngi, red_x, red_y, red_z, green_x, green_y, green_z, blue_x, blue_y, blue_z);
#line 2909 "tmpl/perl-libpng.c.tmpl"
}

#endif /* PNG_cHRM_XYZ_SUPPORTED */

static void perl_png_set_transforms (perl_libpng_t * png, int transforms)
{
    png->transforms = transforms;
}

/* Copy "row_pointers" from malloced memory from elsewhere. */

static void perl_png_copy_row_pointers (perl_libpng_t * png, SV * row_pointers)
{
    png_byte ** crow_pointers;
    int i;
    int height;

    /* We didn't store the image's height in png so we have to
       retrieve it from the header again. */

    height = png_get_image_height (pngi);

    crow_pointers = INT2PTR (png_byte **, SvIV (row_pointers));

    GET_MEMORY (png->row_pointers, height, png_byte *);
    png->row_pointers_ours = 1;
    for (i = 0; i < height; i++) {
	png->row_pointers[i] = crow_pointers[i];
    }
    png_set_rows (pngi, png->row_pointers);
}

#line 4005 "/usr/home/ben/projects/image-png-libpng/build/../perl-libpng.c"

static int
perl_png_get_image_width (perl_libpng_t * png)
{
    return png_get_image_width (pngi);
}

static int
perl_png_get_image_height (perl_libpng_t * png)
{
    return png_get_image_height (pngi);
}

#line 2950 "tmpl/perl-libpng.c.tmpl"


static void
perl_png_set_rgb_to_gray (perl_libpng_t * png, int error_action,
			  int red_weight, int green_weight)
{
    png_set_rgb_to_gray_fixed (png->png, error_action, red_weight, green_weight);
}


static int
perl_png_get_channels (perl_libpng_t * png)
{
    return png_get_channels (pngi);
}


static void
perl_png_set_user_limits (perl_libpng_t * png,
			  unsigned int user_width_max,
			  unsigned int user_height_max)
{
#ifdef PNG_USER_LIMITS_SUPPORTED
    png_set_user_limits (png->png, user_width_max, user_height_max);
#else
    UNSUPPORTED (USER_LIMITS);
#endif
}



static SV *
perl_png_get_user_width_max (perl_libpng_t * png)
{
#ifdef PNG_USER_LIMITS_SUPPORTED
    int uwm;

    uwm = png_get_user_width_max (png->png);
    return newSViv (uwm);
#else
    UNSUPPORTED (USER_LIMITS);
    return & PL_sv_undef;
#endif
}

static SV *
perl_png_get_user_height_max (perl_libpng_t * png)
{
#ifdef PNG_USER_LIMITS_SUPPORTED
    int uwm;

    uwm = png_get_user_height_max (png->png);
    return newSViv (uwm);
#else
    UNSUPPORTED (USER_LIMITS);
    return & PL_sv_undef;
#endif
}

#line 2996 "tmpl/perl-libpng.c.tmpl"

static SV *
perl_png_get_eXIf (perl_libpng_t * png)
{
    SV * exif = & PL_sv_undef;
#ifdef PNG_eXIf_SUPPORTED
    if (VALID (eXIf)) {
	png_uint_32 num_exif;
	png_bytep exif_buf;
	
	png_get_eXIf_1 (png->png, png->info, & num_exif, & exif_buf);
	exif = newSVpvn ((const char *) exif_buf, (STRLEN) num_exif);
    }
#else /*  PNG_eXIf_SUPPORTED */
    UNSUPPORTED (eXIf);
#endif /*  PNG_eXIf_SUPPORTED */
    return exif;
}

static void
perl_png_set_eXIf (perl_libpng_t * png, SV * exif)
{
#ifdef PNG_eXIf_SUPPORTED
    png_uint_32 num_exif;
    png_const_bytep exif_buf;
    STRLEN exif_len;
    
    exif_buf = (const png_bytep) SvPV (exif, exif_len);
    num_exif = (png_uint_32) exif_len;

    png_set_eXIf_1 (png->png, png->info, num_exif, (png_bytep) exif_buf);
#else /*  PNG_eXIf_SUPPORTED */
    UNSUPPORTED (eXIf);
#endif /*  PNG_eXIf_SUPPORTED */
}

/*
  Make a new entry in "split" using "name" as the key, with "len"
  bytes of memory. We tried newSV(len) but it didn't work,
  because we didn't know how to turn that into anything other
  than "undef", but assigning with an empty string but with the
  length of data that we need seems to work to get us the length
  of data we want, and the string value of the data that we
  insert is also accessible by Perl. 
*/

static void
perl_png_set_back(perl_libpng_t * png, HV * perl_color, int gamma_code,
		  int need_expand, double background_gamma)
{
    png_color_16 color;
#ifdef PNG_READ_BACKGROUND_SUPPORTED
    perl_png_hv_to_color_16 (perl_color, & color);
    png_set_background (png->png, & color, gamma_code,
			need_expand, background_gamma);
#else
    UNSUPPORTED("READ_BACKGROUND");
#endif /* READ_BACKGROUND */
}

static void
perl_png_init_io_x (perl_libpng_t * Png, SV * fpsv)
{
    FILE * fp;
    PerlIO *io;
    
    io = IoIFP (sv_2io (fpsv));
    if (io) {
	Png->io_sv = SvREFCNT_inc (fpsv);
	Png->memory_gets++;
	fp = PerlIO_findFILE (io);
	png_init_io (Png->png, fp);
	Png->init_io_done = 1;
    }
    else {
	croak ("Error doing init_io: unopened file handle?");
    }
}

static void
perl_png_set_quantize (perl_libpng_t * png, AV * palette,
		       int max_screen_colors, AV * histogram,
		       int full_quantize)
{
#ifdef PNG_READ_QUANTIZE_SUPPORTED
    int n_colors;
    png_colorp colors;
    png_uint_16p hist;

    perl_png_av_to_colors (png, palette, & colors, & n_colors);
    if (n_colors == 0) {
	croak ("set_quantize: empty palette");
    }
    hist = 0;
    if (av_len (histogram) + 1 > 0) {
	int hist_size;
	av_to_hist (png, histogram, & hist, & hist_size, n_colors);
    }
    png_set_quantize (png->png, colors, n_colors, max_screen_colors,
		      hist, full_quantize);
    PERL_PNG_FREE (colors);
    if (hist != 0) {
	PERL_PNG_FREE (hist);
    }
#else
    UNSUPPORTED(READ_QUANTIZE);
#endif /* #ifdef PNG_READ_QUANTIZE_SUPPORTED */
}


static void
perl_png_check_x_y (perl_libpng_t * png, int x, int y)
{
    if (x < 0 || y < 0) {
	croak ("x (%d) or y (%d) < 0", x, y);
    }
    if (x >= png->width) {
	croak ("x (%d) > width %d", x, png->width);
    }
    if (y >= png->height) {
	croak ("y (%d) > height %d", y, png->height);
    }
}

static void
perl_png_get_image_data (perl_libpng_t * png)
{
    png_get_IHDR (pngi, &png->width, &png->height,
		  &png->bit_depth, &png->color_type, 0,
		  UNUSED_ZERO_ARG, UNUSED_ZERO_ARG);
    if (!png->row_pointers) {
    	png->row_pointers = png_get_rows (pngi);
	png->row_pointers_ours = 0;
    }
    png->rowbytes = png_get_rowbytes (pngi);
    if (png->type != perl_png_read_obj) {
	warn ("Reading a pixel from a write object");
    }
    png->channels = perl_png_color_type_channels (png->color_type);
    if (png->color_type == PNG_COLOR_TYPE_PALETTE) {
	if (! png->palette_checked) {
	    perl_png_palette (png);
	}
    }
    png->image_data_ok = 1;
}

static void
palette_to_pixel (perl_libpng_t * png, perl_png_pixel_t * pixel)
{
    png_colorp color;

    color = & png->palette[pixel->index];
    pixel->red = color->red;
    pixel->green = color->green;
    pixel->blue = color->blue;
}

static void
get_bit_pixel (perl_libpng_t * png, int x, int y, perl_png_pixel_t * pixel)
{
    png_bytep row;
    unsigned int mask;
    unsigned int shift;
    unsigned int value;
    unsigned n;
    int offset;
    int b;

    b = png->bit_depth;

    row = png->row_pointers[y];
    offset = (int) ((x * b) / 8);
    n = x % (8 / b);
    shift = 8 - (n+1) * b;
    mask = 2 * b - 1;
    value = (row[offset] >> shift) & mask;

    switch (png->color_type) {
    case PNG_COLOR_TYPE_GRAY:
	pixel->gray = value;
	return;
    case PNG_COLOR_TYPE_PALETTE:
	pixel->index = value;
	if (pixel->index >= png->n_palette) {
	    croak ("index %d > colors in palette %d",
		   pixel->index, png->n_palette);
	}
	palette_to_pixel (png, pixel);
	return;
    default:
	croak ("Bit depth %d and color type %d mismatch",
	       png->bit_depth, png->color_type);
    }
    return;
}

static int
sixteen (png_bytep row, int offset)
{
    return row[offset] * 256 + row[offset+1];
}

static void
get_any_pixel (perl_libpng_t * png, int x, int y,
	       perl_png_pixel_t * pixel)
{
    png_bytep row;
    int offset;

    if (! png->image_data_ok) {
	perl_png_get_image_data (png);
    }
    perl_png_check_x_y (png, x, y);
    if (png->bit_depth < 8) {
	get_bit_pixel (png, x, y, pixel);
	return;
    }
    row = png->row_pointers[y];
    offset = x * (png->bit_depth / 8) * png->channels;
    
    if (png->bit_depth == 8) {
	switch (png->color_type) {
	case PNG_COLOR_TYPE_PALETTE:
	    pixel->index = row[offset];
	    palette_to_pixel (png, pixel);
	    break;
	case PNG_COLOR_TYPE_GRAY_ALPHA:
	    pixel->alpha = row[offset+1];
	    /* Fall through. */
	case PNG_COLOR_TYPE_GRAY:
	    pixel->gray = row[offset];
	    break;
	case PNG_COLOR_TYPE_RGB_ALPHA:
	    pixel->alpha = row[offset+3];
	    /* Fall through. */
	case PNG_COLOR_TYPE_RGB:
	    pixel->red = row[offset];
	    pixel->green = row[offset+1];
	    pixel->blue = row[offset+2];
	    break;
	default:
	    croak ("Unknown color type %d", png->color_type);
	}
    }
    else if (png->bit_depth == 16) {
	switch (png->color_type) {
	case PNG_COLOR_TYPE_GRAY_ALPHA:
	    pixel->alpha = sixteen(row, offset+2);
	    /* Fall through. */
	case PNG_COLOR_TYPE_GRAY:
	    pixel->gray = sixteen(row, offset);
	    break;
	case PNG_COLOR_TYPE_RGB_ALPHA:
	    pixel->alpha = sixteen (row, offset+6);
	    /* Fall through. */
	case PNG_COLOR_TYPE_RGB:
	    pixel->red = sixteen (row, offset);
	    pixel->green = sixteen (row, offset+2);
	    pixel->blue = sixteen (row, offset+4);
	    break;
	default:
	    croak ("Unknown color type %d", png->color_type);
	}
    }
    else {
	croak ("Bit depth %d is not handled", png->bit_depth);
    }
}

SV *
perl_png_get_pixel (perl_libpng_t * png, int x, int y)
{
    HV * pixel_hv;
    perl_png_pixel_t pixel = {0};

    get_any_pixel (png, x, y, & pixel);

    pixel_hv = newHV ();
    if (png->color_type & PNG_COLOR_MASK_ALPHA) {
	hv_store (pixel_hv, "alpha", strlen ("alpha"),
		  newSViv (pixel.alpha), 0);
    }
    if ((png->color_type & PNG_COLOR_MASK_COLOR) == 0) {
	hv_store (pixel_hv, "gray", strlen ("gray"),
		  newSViv (pixel.gray), 0);
    }
    else {
	hv_store (pixel_hv, "red", strlen ("red"), newSViv (pixel.red), 0);
	hv_store (pixel_hv, "blue", strlen ("blue"), newSViv (pixel.blue), 0);
	hv_store (pixel_hv, "green", strlen ("green"), newSViv (pixel.green), 0);
    }
    if (png->color_type == PNG_COLOR_TYPE_PALETTE) {
	hv_store (pixel_hv, "index", strlen ("index"),
		  newSViv (pixel.index), 0);
    }
    return newRV_noinc ((SV *) pixel_hv);
}

static unsigned char *
sv_memory (HV * split, char * name, int name_length, int len)
{
    SV * sv;
    unsigned char * retval;
    STRLEN sv_len;

    sv_len = (STRLEN) len;
    /* newSVpv with "" and this length caused some kind of problem,
       detectable on a few people's computers and with valgrind, which
       said it was an invalid read, so we switched to this method
       based on Perl source code and the perlguts. In fact newSVpv
       copies "len" bytes of the string it is given, and I was giving
       it a zero length string, so that was wrong. */
    sv = newSV (sv_len);
    SvPOK_on (sv);
    SvCUR_set (sv, sv_len);
    if (! hv_store (split, name, name_length, sv, 0)) {
	croak ("%s:%d: hv_store %s, %d bytes failed",
	       __FILE__, __LINE__, name, len);
    }
    retval = (unsigned char *) SvPVX (sv);
    if (! retval) {
	croak ("%s:%d: newSVpv/SvPVX %s, %d bytes failed",
	       __FILE__, __LINE__, name, len);
    }
    return retval;
}

static SV *
perl_png_split_alpha (perl_libpng_t * png)
{
    HV * split;
    SV * split_ref;
    int datapix;
    int alphapix;
    unsigned char * databytes;
    unsigned char * alphabytes;
    int i;
    int bytes;
    int colors;

    if (! png->image_data_ok) {
	perl_png_get_image_data (png);
    }
    if (png->bit_depth == 8 || png->bit_depth == 16) {
	bytes = png->bit_depth / 8;
    }
    else {
	warn ("Bit depth of %d is not handled by split_alpha",
	      png->bit_depth);
	return &PL_sv_undef;
    }
    if ((png->color_type & PNG_COLOR_MASK_ALPHA) == 0) {
	warn ("Color type %s (%d) has no alpha channel",
	      perl_png_color_type_name (png->color_type), png->color_type);
	return &PL_sv_undef;
    }
    colors = png->channels - 1;
    alphapix = bytes * png->height * png->width;
    datapix = colors * alphapix;
    split = newHV ();
    alphabytes = sv_memory (split, "alpha", strlen ("alpha"), alphapix);
    databytes = sv_memory (split, "data", strlen ("data"), datapix);
    for (i = 0; i < png->height; i++) {
	int j;
	png_bytep row;
	row = png->row_pointers[i];
	for (j = 0; j < png->width; j++) {
	    int byte;
	    int o;
	    int p;
	    int q;
	    // Offset into "alphabytes"
	    o = bytes * (i * png->width + j);
	    // Offset into "databytes"
	    p = colors * o;
	    // Offset into "row"
	    q = bytes * png->channels * j;
	    for (byte = 0; byte < bytes; byte++) {
		int c;
		for (c = 0; c < colors; c++) {
		    int r;
		    r = bytes*c + byte;
		    databytes[p + r] = row[q + r];
		}
		alphabytes[o + byte] = row[q + bytes*colors + byte];
	    }
	}
    }
    split_ref = newRV_noinc ((SV*) split);
    return split_ref;
}

#undef pngi

/*
   Local Variables:
   mode: c
   End: 
*/
