#line 2 "perl-libpng.c.tmpl"

/* Coding style note: use "color" in code & variables, not "colour",
   as per libpng. 2020-12-09 08:03:03 */

#ifndef PNG_FLOATING_POINT_SUPPORTED
#  error libpng support requires libpng to export the floating point APIs
#endif

/* What to do if the chunk is not supported by the libpng we compiled
   against. */

#define UNSUPPORTED(block)						\
    warn ("The %s chunk is not supported in this libpng", #block);

/* sCAL block support. This is complicated, see PNG mailing list
   archives. */

#ifdef PNG_sCAL_SUPPORTED
#if PNG_LIBPNG_VER >= 10500 ||				\
    (defined (PNG_FIXED_POINT_SUPPORTED) &&		\
     ! defined (PNG_FLOATING_POINT_SUPPORTED))
#define PERL_PNG_sCAL_s_SUPPORTED
#endif /* version or fixed point */
#endif /* PNG_sCAL_SUPPORTED */

/* Container for PNG information. This corresponds to an
   "Image::PNG::Libpng" in Perl. */

typedef struct perl_libpng
{
    png_structp png;
    png_infop info;
    png_infop end_info;
    enum {
	perl_png_unknown_obj,
	perl_png_read_obj,
	perl_png_write_obj,
    } type;
    /* Allocated memory which holds the rows. */
    png_bytepp  row_pointers;
    /* Allocated memory which holds the image data. */
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
    /* If the following variable is set to a true value, the module
       prints messages about what it is doing. */
    int verbosity : 1;
    /* If the following variable is set to a true value, the module
       raises an error (die) if there is an error other than something
       being undefined. */
    int raise_errors : 1;
    /* Print error messages. */
    int print_errors : 1;
    /* Print a message on STDERR if something is undefined. */
    int print_undefined : 1;
    /* Has input/output been initiated? */
    int init_io_done : 1;
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
                                         

/* The following things are used to handle errors from libpng. See the
   create_read_struct and create_write_struct calls below. */


/* Error handler for libpng. */

static void
perl_png_error_fn (png_structp png_ptr, png_const_charp error_msg)
{
    perl_libpng_t * png = png_get_error_ptr (png_ptr);
    /* An error from libpng sent via Perl's warning handler. */
    croak ("libpng error: %s\n", error_msg);
}

/* Warning handler for libpng. */

static void
perl_png_warning_fn (png_structp png_ptr, png_const_charp warning_msg)
{
    perl_libpng_t * png = png_get_error_ptr (png_ptr);
    /* A warning from libpng sent via Perl's warning handler. */
    warn ( "libpng warning: %s\n", warning_msg);
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
                                                 


/* Get memory using the following in order to keep count of the number
   of objects in use at the end of execution, to ensure that there are
   no memory leaks. All allocation is done via Newxz ("calloc") rather
   than "malloc". */

#define GET_MEMORY(thing, number, type) {	\
        Newxz (thing, number, type);		\
        png->memory_gets++;                     \
    }

/* Free memory using the following in order to keep count of the
   number of objects still in use. */

#define PERL_PNG_FREE(thing) {   \
        png->memory_gets--;      \
        Safefree (thing);	 \
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
    if (png->row_pointers) {
        PERL_PNG_FREE (png->row_pointers);
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
#ifdef PNG_tEXt_SUPPORTED
    int num_text = 0;
    png_textp text_ptr;

    png_get_text (pngi, & text_ptr, & num_text);
    if (num_text > 0) {
        int i;
        SV * text_ref;
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
        return text_ref;
    }
    else {
        MESSAGE ("There is no text:");
        return & PL_sv_undef;
    }
#else
    UNSUPPORTED(tEXt);
    return & PL_sv_undef;
#endif
}

/* Set a PNG text from "chunk". The return value is true if
   successful. */

static int
perl_png_set_text_from_hash (perl_libpng_t * png,
                             png_text * text_out, HV * chunk)
{
    int compression;
    char * key;
    STRLEN key_length;
#ifdef PNG_iTXt_SUPPORTED
    char * lang;
    STRLEN lang_length;
    char * lang_key;
    STRLEN lang_key_length;
#endif /* PNG_iTXt_SUPPORTED */
    int is_itxt = 0;
    char * text;
    STRLEN text_length;
    /* The return value of this function. */
    int ok = 1;
    SV ** compression_sv_ptr;

    MESSAGE ("Putting it into something.");

    /* Check the compression field of the chunk */

    compression_sv_ptr =
	hv_fetch (chunk, "compression", strlen ("compression"), 0);
    if (compression_sv_ptr) {
	compression = SvIV (* compression_sv_ptr);
    }
    else {
	MESSAGE ("Using default compression PNG_TEXT_COMPRESSION_NONE");
	compression = PNG_TEXT_COMPRESSION_NONE;
    }
    switch (compression) {
    case PNG_TEXT_COMPRESSION_NONE:
        break;
    case PNG_TEXT_COMPRESSION_zTXt:
        break;
    case PNG_ITXT_COMPRESSION_NONE:
        is_itxt = 1;
        break;
    case PNG_ITXT_COMPRESSION_zTXt: 
        is_itxt = 1;
        break;
    default:
        ok = 0;
        fprintf (stderr, "Unknown compression %d\n", 
                 compression);
        return 0;
        break;
    }

    MESSAGE ("Getting key.");
    HASH_FETCH_PV (chunk, key);
    if (key_length < 1 || key_length > 79) {
        /* Key is too long or empty */
        MESSAGE ("Bad length of key.");

        ok = 0;
        return 0;
    }
    MESSAGE ("Getting text.");
    HASH_FETCH_PV (chunk, text);
    if (ok) {
        MESSAGE ("Copying.");
        text_out->compression = compression;
        text_out->key = (char *) key;
        text_out->text = (char *) text;
        text_out->text_length = text_length;
#ifdef PNG_iTXt_SUPPORTED
        if (is_itxt) {
            HASH_FETCH_PV (chunk, lang);
            HASH_FETCH_PV (chunk, lang_key);
            text_out->lang = (char *) lang;
            text_out->lang_key = (char *) lang_key;
        }
#endif
    }
    else {
            /* Compression method unknown. */
        ;
    }

    return ok;
}

/* Set the text chunks in the PNG. This actually pushes text chunks
   into the object rather than setting them (so it does not destroy
   already-set ones). */

static void
perl_png_set_text (perl_libpng_t * png, AV * text_chunks)
{
    int num_text;
    int num_ok = 0;
    int i;
    png_text * png_texts;

    num_text = av_len (text_chunks) + 1;
    MESSAGE ("You have %d text chunks.\n", num_text);
    if (num_text <= 0) {
        /* Complain to the user */
        return;
    }
    GET_MEMORY (png_texts, num_text, png_text);
    for (i = 0; i < num_text; i++) {
        int ok = 0;
        SV ** chunk_pointer;

        MESSAGE ("Fetching chunk %d.\n", i);
        chunk_pointer = av_fetch (text_chunks, i, 0);
        if (! chunk_pointer) {
            /* Complain */
            MESSAGE ("Chunk pointer null.");
            continue;
        }
        if (SvROK (* chunk_pointer) && 
            SvTYPE (SvRV (* chunk_pointer)) == SVt_PVHV) {
            MESSAGE ("Looks like a hash.");
            ok = perl_png_set_text_from_hash (png, & png_texts[num_ok],
                                              (HV *) SvRV (* chunk_pointer));
            if (ok) {
                MESSAGE ("This chunk is OK.");
                num_ok++;
            }
            else {
                MESSAGE ("The chunk is not OK.");
            }
        }
    }
    if (num_ok > 0) {
        MESSAGE ("Writing %d text chunks to your PNG.\n",
                num_ok);
        png_set_text (pngi, png_texts, num_ok);
    }
    else {
        /* The user tried to set some text chunks in the image but
           they were not allowed. */
        warn ( "None of your text chunks was allowed");
    }
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
       See PNG specification "4.2.4.6. tIME Image last-modification time"
    */
    png_time mod_time = {0,1,1,0,0,0};
    int time_ok = 0;
    if (input_time) {
	SV * ref;
        ref = SvRV(input_time);
        if (ref && SvTYPE (ref) == SVt_PVHV) {
            HV * time_hash = (HV *) SvRV (input_time);
            MESSAGE ("Setting time from a hash.");
#define SET_TIME(field) {                                               \
                SV ** field_sv_ptr = hv_fetch (time_hash, #field,       \
                                               strlen (#field), 0);     \
                if (field_sv_ptr) {                                     \
                    SV * field_sv = * field_sv_ptr;                     \
                    MESSAGE ("OK for %s\n", #field);                    \
                    mod_time.field = SvIV (field_sv);                   \
                }                                                       \
            }
            SET_TIME(year);
            SET_TIME(month);
            SET_TIME(day);
            SET_TIME(hour);
            SET_TIME(minute);
            SET_TIME(second);
#undef SET_TIME    
            time_ok = 1;
        }
    }
    if (! time_ok) {
        /* There is no valid time argument, so just set it to the time
           now, according to the system clock. */
        time_t now;

        MESSAGE ("The modification time doesn't look OK so I am going to set the modification time to the time now instead.");
        now = time (0);
        png_convert_from_time_t (& mod_time, now);
    }
    png_set_tIME (pngi, & mod_time);
}

int
perl_png_sig_cmp (SV * png_header, int start, int num_to_check)
{
    unsigned char * header;
    STRLEN length;
    int ret_val;
    header = (unsigned char *) SvPV (png_header, length);
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

typedef struct {
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

/* Write a PNG. */

static void
perl_png_write_png (perl_libpng_t * png, int transforms)
{
    MESSAGE ("Trying to write a PNG.");

    GET_TRANSFORMS;

    if (! png->init_io_done) {
        /* write_png was called before a file handle was associated
           with the PNG. */
        croak ("Attempt to write PNG without calling init_io");
    }
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
    /*
    int compression_method;
    int filter_method;
    */
    /* libpng return value */
    int status;
    /* The return value. */
    HV * IHDR;

    IHDR = newHV ();
    status = png_get_IHDR (pngi, & width, & height,
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

/* Convert a PNG colour type number into its name. */

const char * perl_png_color_type_name (int color_type)
{
    const char * name;

    switch (color_type) {
        PERL_PNG_COLOR_TYPE (GRAY);
        PERL_PNG_COLOR_TYPE (PALETTE);
        PERL_PNG_COLOR_TYPE (RGB);
        PERL_PNG_COLOR_TYPE (RGB_ALPHA);
        PERL_PNG_COLOR_TYPE (GRAY_ALPHA);
    default:
        /* Moan about not knowing this colour type. */
        name = "";
    }
    return name;
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
        PERL_PNG_TEXT_COMP(TEXT,NONE);
        PERL_PNG_TEXT_COMP(TEXT,zTXt);
        PERL_PNG_TEXT_COMP(ITXT,NONE);
        PERL_PNG_TEXT_COMP(ITXT,zTXt);
    default:
        /* Moan about not knowing this text compression type. */
        name = "";
    }
    return name;
}

#undef PERL_PNG_COLOR_TYPE

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

/* Return an array of hashes containing the colour values of the palette. */

static SV *
perl_png_get_PLTE (perl_libpng_t * png)
{
    png_colorp colors;
    int n_colors;
    png_uint_32 status;
    AV * perl_colors;

    status = png_get_PLTE (pngi, & colors, & n_colors);
    if (status != PNG_INFO_PLTE) {
        return & PL_sv_undef;
    }
    perl_colors = perl_png_colors_to_av (colors, n_colors);
    return newRV_noinc ((SV *) perl_colors);
}

/* Set the palette chunk of a PNG image to the palette described in
   "perl_colors". */

static void
perl_png_set_PLTE (perl_libpng_t * png, AV * perl_colors)
{
    int n_colors;
    png_colorp colors;
    int i;

    n_colors = av_len (perl_colors) + 1;
    if (n_colors == 0) {
        /* The user tried to set an empty palette of colours. */
        croak ("set_PLTE: Empty array of colors in set_PLTE");
    }
    MESSAGE ("There are %d colours in the palette.\n", n_colors);

    GET_MEMORY (colors, n_colors, png_color);

    /* Put the colours from Perl into the libpng structure. */

#define PERL_PNG_FETCH_COLOR(x) {                                       \
        SV * rgb_sv = * (hv_fetch (palette_entry, #x, strlen (#x), 0)); \
        colors[i].x = SvIV (rgb_sv);                                    \
    }
    for (i = 0; i < n_colors; i++) {
        HV * palette_entry;
        SV * color_i;

        color_i = * av_fetch (perl_colors, i, 0);
        palette_entry = (HV *) SvRV (color_i);

        PERL_PNG_FETCH_COLOR (red);
        PERL_PNG_FETCH_COLOR (green);
        PERL_PNG_FETCH_COLOR (blue);
    }

#undef PERL_PNG_FETCH_COLOR

    png_set_PLTE (pngi, colors, n_colors);
    PERL_PNG_FREE (colors);
}

/* Set the palette directly, using a pointer. */

static void
perl_png_set_PLTE_pointer (perl_libpng_t * png, png_colorp colors, int n_colors){
    png_set_PLTE (pngi, colors, n_colors);
}

/* Create a hash containing the colour values of a pointer to a
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

/* Turn a hash into the colour values of a pointer to a png_color_16
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
   image. This currently does nothing. */

static SV * perl_png_get_pCAL (perl_libpng_t * png)
{
#ifdef PNG_pCAL_SUPPORTED
    HV * ice;
    char * purpose;
    int x0;
    int x1;
    int type;
    int n_params;
    char * units;
    char ** png_params;

    if (! VALID (pCAL)) {
	return & PL_sv_undef;
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
	/* Looks like a memory leak here. */
	GET_MEMORY (png_params, n_params, char *);
	for (i = 0; i < n_params; i++) {
	    ARRAY_STORE_PV (params, png_params[i]);
	}
	HASH_STORE_AV (ice, params);
    }
    return newRV_noinc ((SV *) ice);
#else
    UNSUPPORTED(pCAL);
    return & PL_sv_undef;
#endif
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

static SV * perl_png_get_iCCP (perl_libpng_t * png)
{
#ifdef PNG_iCCP_SUPPORTED
    if (VALID (iCCP)) {
	char * name;
	unsigned char * profile;
	int compression_method;
	unsigned int proflen;
        HV * ice;
	SV * profile_sv;
	png_get_iCCP (pngi, & name, & compression_method, & profile,
		      & proflen);
        ice = newHV ();
	HASH_STORE_PV (ice, name);
	profile_sv = newSVpv ((char *) profile, proflen);
	(void) hv_store (ice, "profile", strlen ("profile"), profile_sv, 0);
        return newRV_noinc ((SV *) ice);
    }
    return & PL_sv_undef;
#else /* PNG_iCCP_SUPPORTED */
    UNSUPPORTED(iCCP);
    return & PL_sv_undef;
#endif /* PNG_iCCP_SUPPORTED */
}

static void perl_png_set_iCCP (perl_libpng_t * png, HV * iCCP)
{
#ifdef PNG_iCCP_SUPPORTED
    char * name;
    STRLEN name_length;
    char * profile;
    STRLEN profile_length;
    int compression_method;

    compression_method = PNG_COMPRESSION_TYPE_BASE;

    HASH_FETCH_PV (iCCP, profile);
    HASH_FETCH_PV (iCCP, name);

    png_set_iCCP (pngi, name, compression_method,
		  (unsigned char *) profile, profile_length);
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
#line 1450 "/usr/home/ben/projects/image-png-libpng/build/../perl-libpng.c"
        
	HASH_STORE_IV_MEMBER (trans_hv, red, trans_values);
	
	HASH_STORE_IV_MEMBER (trans_hv, green, trans_values);
	
	HASH_STORE_IV_MEMBER (trans_hv, blue, trans_values);
	
	HASH_STORE_IV_MEMBER (trans_hv, gray, trans_values);
	
#line 1455 "perl-libpng.c.tmpl"
	return newRV_noinc ((SV *) trans_hv);
    }
#else
    /* libpng was compiled without this option. */
    UNSUPPORTED(tRNS);
    return & PL_sv_undef;
#endif
}

/* Empty code. */

static void perl_png_set_tRNS (perl_libpng_t * png, SV * tRNS)
{
#ifdef PNG_tRNS_SUPPORTED
    png_byte color_type;
    png_byte trans[256] = {0};
    int num_trans;
    png_uint_32 status;
    png_color_16 trans_values = {0};
    color_type = png_get_color_type (pngi);
    if (color_type & PNG_COLOR_MASK_PALETTE) {
	AV * trans_av;
	int i;
	if (SvTYPE (SvRV (tRNS)) != SVt_PVAV) {
	    /* unhandled error */
	}
	trans_av = (AV *) SvRV (tRNS);
	num_trans = av_len (trans_av) + 1;
	if (num_trans > 256) {
	    /* unhandled error */
	}
	for (i = 0; i < num_trans; i++) {
	    int ti;
	    SV ** ti_sv;
	    ti_sv = av_fetch (trans_av, i, 0); 
	    if (! ti_sv) {
		/* unhandled error */
	    }
	    ti = SvIV (* ti_sv);
	    if (ti < 0 || ti > 0xFF) {
		/* unhandled error */
	    }
	    trans[i] = ti;
	}

	png_set_tRNS (pngi, trans, num_trans, & trans_values); 

    }
    else {
	HV * trans_hv;
	if (SvTYPE (SvRV (tRNS)) != SVt_PVHV) {
	    /* unhandled error */
	}
	trans_hv = (HV *) SvRV (tRNS);
#line 1515 "/usr/home/ben/projects/image-png-libpng/build/../perl-libpng.c"
        
	    HASH_FETCH_IV_MEMBER (trans_hv, red, (& trans_values));
	
	    HASH_FETCH_IV_MEMBER (trans_hv, green, (& trans_values));
	
	    HASH_FETCH_IV_MEMBER (trans_hv, blue, (& trans_values));
	
	    HASH_FETCH_IV_MEMBER (trans_hv, gray, (& trans_values));
	
#line 1514 "perl-libpng.c.tmpl"
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
#line 1553 "/usr/home/ben/projects/image-png-libpng/build/../perl-libpng.c"
		HASH_STORE_IV_MEMBER (perl_entry, red, entry);
		HASH_STORE_IV_MEMBER (perl_entry, green, entry);
		HASH_STORE_IV_MEMBER (perl_entry, blue, entry);
		HASH_STORE_IV_MEMBER (perl_entry, alpha, entry);
		HASH_STORE_IV_MEMBER (perl_entry, frequency, entry);
	
#line 1546 "perl-libpng.c.tmpl"
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
#line 1664 "/usr/home/ben/projects/image-png-libpng/build/../perl-libpng.c"
 	    	    HASH_FETCH_IV_MEMBER (perl_entry, red, e);
	    	    HASH_FETCH_IV_MEMBER (perl_entry, green, e);
	    	    HASH_FETCH_IV_MEMBER (perl_entry, blue, e);
	    	    HASH_FETCH_IV_MEMBER (perl_entry, alpha, e);
	    	    HASH_FETCH_IV_MEMBER (perl_entry, frequency, e);
	    
#line 1654 "perl-libpng.c.tmpl"
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

static void perl_png_set_hIST (perl_libpng_t * png, AV * hIST)
{
#ifdef PNG_hIST_SUPPORTED
    int hist_size;
    png_uint_16p hist;
    int i;
    hist_size = av_len (hIST) + 1;
    GET_MEMORY (hist, hist_size, png_uint_16);
    for (i = 0; i < hist_size; i++) {
	ARRAY_FETCH_IV (hIST, i, hist[i]);
    }
    png_set_hIST (pngi, hist);
    PERL_PNG_FREE (hist);
#else
    UNSUPPORTED(hIST);
#endif
}

static SV * perl_png_get_hIST (perl_libpng_t * png)
{
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
	return newRV_noinc ((SV *) hist_av);
    }
    return & PL_sv_undef;
#else
    UNSUPPORTED(hIST);
    return & PL_sv_undef;
#endif
}

/* Should this be a hash value or an array? */

/* "4.2.4.3. sBIT Significant bits" */

static SV * perl_png_get_sBIT (perl_libpng_t * png)
{
#ifdef PNG_sBIT_SUPPORTED
    if (VALID (sBIT)) {
        HV * sig_bit;
        png_color_8p colors;
	png_uint_32 status;
        sig_bit = newHV ();
	status = png_get_sBIT (pngi, & colors);
	if (status != PNG_INFO_sBIT) {
	    /* error */
	}
#line 1784 "/usr/home/ben/projects/image-png-libpng/build/../perl-libpng.c"
        
	HASH_STORE_IV_MEMBER (sig_bit, red, colors);
	
	HASH_STORE_IV_MEMBER (sig_bit, green, colors);
	
	HASH_STORE_IV_MEMBER (sig_bit, blue, colors);
	
	HASH_STORE_IV_MEMBER (sig_bit, gray, colors);
	
	HASH_STORE_IV_MEMBER (sig_bit, alpha, colors);
	
#line 1771 "perl-libpng.c.tmpl"
        return newRV_noinc ((SV *) sig_bit);
    }
    return & PL_sv_undef;
#else
    /* libpng was compiled without this option. */
    UNSUPPORTED(sBIT);
    return & PL_sv_undef;
#endif
}

static void perl_png_set_sBIT (perl_libpng_t * png, HV * sBIT)
{
#ifdef PNG_sBIT_SUPPORTED
    png_color_8 colors;
     HASH_FETCH_IV_MEMBER (sBIT,red,(&colors)); HASH_FETCH_IV_MEMBER (sBIT,green,(&colors)); HASH_FETCH_IV_MEMBER (sBIT,blue,(&colors)); HASH_FETCH_IV_MEMBER (sBIT,gray,(&colors)); HASH_FETCH_IV_MEMBER (sBIT,alpha,(&colors));
    png_set_sBIT (pngi, & colors);
#else
    /* libpng was compiled without this option. */
    UNSUPPORTED(sBIT);
#endif
}

static SV * perl_png_get_oFFs (perl_libpng_t * png)
{
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
        return newRV_noinc ((SV *) offset);
    }
    return & PL_sv_undef;
#else
    /* libpng was compiled without this option. */
    UNSUPPORTED(oFFs);
    return & PL_sv_undef;
#endif
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
    /* libpng was compiled without this option. */
    UNSUPPORTED(oFFs);
#endif
}

static SV * perl_png_get_pHYs (perl_libpng_t * png)
{
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
        return newRV_noinc ((SV *) phys);
    }
    return & PL_sv_undef;
#else
    /* libpng was compiled without this option. */
    UNSUPPORTED(pHYs);
    return & PL_sv_undef;
#endif
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

static SV * perl_png_get_tRNS_palette (perl_libpng_t * png)
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
#line 1978 "/usr/home/ben/projects/image-png-libpng/build/../perl-libpng.c"
V(bKGD);V(cHRM);V(gAMA);V(hIST);V(iCCP);V(IDAT);V(oFFs);V(pCAL);V(pHYs);V(PLTE);V(sBIT);V(sCAL);V(sPLT);V(sRGB);V(tIME);V(tRNS);
#line 1955 "perl-libpng.c.tmpl"
#undef V

    return newRV_noinc ((SV *) perl_valid);
}

/*  ___                                  _       _        
   |_ _|_ __ ___   __ _  __ _  ___    __| | __ _| |_ __ _ 
    | || '_ ` _ \ / _` |/ _` |/ _ \  / _` |/ _` | __/ _` |
    | || | | | | | (_| | (_| |  __/ | (_| | (_| | || (_| |
   |___|_| |_| |_|\__,_|\__, |\___|  \__,_|\__,_|\__\__,_|
                        |___/                              */


static SV *
perl_png_get_rows (perl_libpng_t * png)
{
    png_bytepp rows;
    int rowbytes;
    int height;
    SV ** row_svs;
    int r;
    AV * perl_rows;

    /* Get the information from the PNG. */

    height = png_get_image_height (pngi);
    if (height == 0) {
        /* The height of the image is zero. */
        croak ("Image has zero height");
    }
    else {
        MESSAGE ("Image has height %d\n", height);
    }
    rows = png_get_rows (pngi);
    if (rows == 0) {
        /* The image does not have any rows of image data. */
        croak ("Image has no rows");
    }
    else {
        MESSAGE ("Image has some rows");
    }
    rowbytes = png_get_rowbytes (pngi);
    if (rowbytes == 0) {
        /* The rows of image data have zero length. */
        croak ("Image rows have zero length");
    }
    else {
        MESSAGE ("Image rows are length %d bytes\n", rowbytes);
    }

    /* Create Perl stuff to put the row info into. */

    perl_rows = newAV ();
    MESSAGE ("Making %d scalars.\n", height);
    for (r = 0; r < height; r++) {
	SV * row_sv = newSVpv ((char *) rows[r], rowbytes);
	av_push (perl_rows, row_sv);
    }
    MESSAGE ("There are %d elements in the array.\n",
	     (int) av_len (perl_rows) + 1);
    return newRV_noinc ((SV *) perl_rows);
}

static void
perl_png_read_png (perl_libpng_t * png, int transforms)
{
    GET_TRANSFORMS;
    png_read_png (pngi, transforms, 0);
}

/* Read the image data into allocated memory */

static void
perl_png_read_image (perl_libpng_t * png)
{
    int n_rows;
    int rowbytes;
    int i;

    n_rows = png_get_image_height (pngi);
    rowbytes = png_get_rowbytes (pngi);
    if (! n_rows) {
        /* The image we are trying to read has zero height. */
        croak ("Image has zero height");
    }
    GET_MEMORY (png->row_pointers, n_rows, png_bytep);
    Newx (png->image_data, rowbytes * n_rows, png_byte);
    if (! png->image_data) {
        /* We were refused the memory we want to read the image into. */
        croak ("Out of memory allocating %d bytes for image",
                        rowbytes * n_rows);
    }
    png->memory_gets++;
    for (i = 0; i < n_rows; i++) {
        png->row_pointers[i] = png->image_data + rowbytes * i;
    }
    png_read_image (png->png, png->row_pointers);
    /* Set the row_pointers pointers to point into the allocated
       memory. */
}

/* Get the row pointers directly. */

static void *
perl_png_get_row_pointers (perl_libpng_t * png)
{
    png_bytepp rows;
    if (png->row_pointers) {
        rows = png->row_pointers;
    }
    else {
        rows = png_get_rows (pngi);
    }
    return rows;
}

/* Set the rows of the image to "rows". */

static void perl_png_set_rows (perl_libpng_t * png, AV * rows)
{
    unsigned char ** row_pointers;
    int i;
    int n_rows;
    png_uint_32 height;
    png_uint_32 width;
    int bit_depth;
    int channels;

    /* All of the following are ignored. */
    int color_type;
    int interlace_method;
    int compression_method;
    int filter_method;
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
                           & bit_depth, & color_type, & interlace_method,
                           & compression_method, & filter_method);

    channels = png_get_channels (pngi);
    rbytes = width * bit_depth * channels;
    if (rbytes % 8 == 0) {
	rbytes /= 8;
    }
    else {
	rbytes = rbytes / 8 + 1;
    }

    if (png->row_pointers) {
        /* There was an attempt to set the rows of an image after they
           had already been set. */
        croak ("Row pointers already set");
    }
    /* Check that this is the same as the height of the image. */
    n_rows = av_len (rows) + 1;
    if (n_rows != height) {
        /* set_rows was called with an array of the wrong size. */
        croak ("array has %d rows but PNG image requires %d rows",
	       n_rows, height);
    }
    MESSAGE ("%d rows.\n", n_rows);
    GET_MEMORY (row_pointers, n_rows, unsigned char *);
    arbytes = height * rbytes;
    GET_MEMORY (ar, arbytes, unsigned char); 
    r = ar;
    for (i = 0; i < n_rows; i++) {
        /* Need to check that this is the same as the width of the image. */
        STRLEN length;
        SV * row_i;
	/* The data from Perl's row. */
	unsigned char * pr;
        row_i = * av_fetch (rows, i, 0);
	pr = (unsigned char *) SvPV (row_i, length);
	if (length > rbytes) {
	    warn ("Row %d is %zu bytes, which is too long; truncating to %d",
		  i, length, rbytes);
	    length = rbytes;
	}
	memcpy (r, pr, length);
        row_pointers[i] = r;
        MESSAGE ("Copying row %d, length %d", i, length);
	r += rbytes;
    }
    if (r != ar + arbytes) {
	croak ("%s:%d: Mismatch %p != %p", __FILE__, __LINE__,
	       r, ar + arbytes);
    }
    png_set_rows (pngi, row_pointers);
    /* "png" keeps a record of the allocated memory in order to free
       it. */
    png->row_pointers = row_pointers;
    png->all_rows = ar;
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

/* Set private chunks in the PNG. */

static void perl_png_set_unknown_chunks (perl_libpng_t * png, AV * chunk_list)
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
    MESSAGE ("OK.");
    for (i = 0; i < n_chunks; i++) {
        HV * perl_chunk = 0;
	SV ** chunk_pointer;
        png_unknown_chunk * png_chunk = 0;
        char * name;
        STRLEN name_length;
        char * data;
        STRLEN data_length;

        MESSAGE ("%d.\n", i);
        /* Get the chunk name and check it is four bytes long. */

	chunk_pointer = av_fetch (chunk_list, i, 0);
	if (! SvROK (* chunk_pointer) ||
	    SvTYPE(SvRV(*chunk_pointer)) != SVt_PVHV) {
            warn ( "Non-hash in chunk array");
            continue;
	}
	perl_chunk = (HV*) SvRV (*chunk_pointer);

        HASH_FETCH_PV (perl_chunk, name);
        if (name_length != PERL_PNG_CHUNK_NAME_LENGTH) {
            /* The user's name for a private chunk was not a valid
               length. In this case the chunk is ignored. */
            warn ( "Illegal PNG chunk name length, "
                           "chunk names must be %d characters long",
                           PERL_PNG_CHUNK_NAME_LENGTH);
            continue;
        }
        png_chunk = unknown_chunks + n_ok_chunks;
        strncpy ((char *) png_chunk->name, (char *) name,
                 PERL_PNG_CHUNK_NAME_LENGTH);

        /* Get the data part of the unknown chunk. */

        HASH_FETCH_PV (perl_chunk, data);
        
        png_chunk->data = (unsigned char *) data;
        png_chunk->size = data_length;
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

/* Does the libpng support "what"? */

int perl_png_libpng_supports (const char * what)
{
#line 2354 "/usr/home/ben/projects/image-png-libpng/build/../perl-libpng.c"
    if (strcmp (what, "iTXt") == 0) {
#ifdef PNG_iTXt_SUPPORTED
        return 1;
#else
        return 0;
#endif /* iTXt */
    }
    if (strcmp (what, "UNKNOWN_CHUNKS") == 0) {
#ifdef PNG_UNKNOWN_CHUNKS_SUPPORTED
        return 1;
#else
        return 0;
#endif /* UNKNOWN_CHUNKS */
    }
    if (strcmp (what, "zTXt") == 0) {
#ifdef PNG_zTXt_SUPPORTED
        return 1;
#else
        return 0;
#endif /* zTXt */
    }
    if (strcmp (what, "tEXt") == 0) {
#ifdef PNG_tEXt_SUPPORTED
        return 1;
#else
        return 0;
#endif /* tEXt */
    }
    if (strcmp (what, "pCAL") == 0) {
#ifdef PNG_pCAL_SUPPORTED
        return 1;
#else
        return 0;
#endif /* pCAL */
    }
    if (strcmp (what, "iCCP") == 0) {
#ifdef PNG_iCCP_SUPPORTED
        return 1;
#else
        return 0;
#endif /* iCCP */
    }
    if (strcmp (what, "sPLT") == 0) {
#ifdef PNG_sPLT_SUPPORTED
        return 1;
#else
        return 0;
#endif /* sPLT */
    }
    if (strcmp (what, "USER_LIMITS") == 0) {
#ifdef PNG_USER_LIMITS_SUPPORTED
        return 1;
#else
        return 0;
#endif /* USER_LIMITS */
    }
    if (strcmp (what, "tIME") == 0) {
#ifdef PNG_tIME_SUPPORTED
        return 1;
#else
        return 0;
#endif /* tIME */
    }
    if (strcmp (what, "TEXT") == 0) {
#ifdef PNG_TEXT_SUPPORTED
        return 1;
#else
        return 0;
#endif /* TEXT */
    }
    if (strcmp (what, "HANDLE_AS_UNKNOWN") == 0) {
#ifdef PNG_HANDLE_AS_UNKNOWN_SUPPORTED
        return 1;
#else
        return 0;
#endif /* HANDLE_AS_UNKNOWN */
    }
    if (strcmp (what, "USER_CHUNKS") == 0) {
#ifdef PNG_USER_CHUNKS_SUPPORTED
        return 1;
#else
        return 0;
#endif /* USER_CHUNKS */
    }
    if (strcmp (what, "CONVERT_tIME") == 0) {
#ifdef PNG_CONVERT_tIME_SUPPORTED
        return 1;
#else
        return 0;
#endif /* CONVERT_tIME */
    }
    if (strcmp (what, "bKGD") == 0) {
#ifdef PNG_bKGD_SUPPORTED
        return 1;
#else
        return 0;
#endif /* bKGD */
    }
    if (strcmp (what, "cHRM") == 0) {
#ifdef PNG_cHRM_SUPPORTED
        return 1;
#else
        return 0;
#endif /* cHRM */
    }
    if (strcmp (what, "gAMA") == 0) {
#ifdef PNG_gAMA_SUPPORTED
        return 1;
#else
        return 0;
#endif /* gAMA */
    }
    if (strcmp (what, "hIST") == 0) {
#ifdef PNG_hIST_SUPPORTED
        return 1;
#else
        return 0;
#endif /* hIST */
    }
    if (strcmp (what, "oFFs") == 0) {
#ifdef PNG_oFFs_SUPPORTED
        return 1;
#else
        return 0;
#endif /* oFFs */
    }
    if (strcmp (what, "pHYs") == 0) {
#ifdef PNG_pHYs_SUPPORTED
        return 1;
#else
        return 0;
#endif /* pHYs */
    }
    if (strcmp (what, "sBIT") == 0) {
#ifdef PNG_sBIT_SUPPORTED
        return 1;
#else
        return 0;
#endif /* sBIT */
    }
    if (strcmp (what, "sRGB") == 0) {
#ifdef PNG_sRGB_SUPPORTED
        return 1;
#else
        return 0;
#endif /* sRGB */
    }
    if (strcmp (what, "tRNS") == 0) {
#ifdef PNG_tRNS_SUPPORTED
        return 1;
#else
        return 0;
#endif /* tRNS */
    }
    if (strcmp (what, "WRITE_CUSTOMIZE_ZTXT_COMPRESSION") == 0) {
#ifdef PNG_WRITE_CUSTOMIZE_ZTXT_COMPRESSION_SUPPORTED
        return 1;
#else
        return 0;
#endif /* WRITE_CUSTOMIZE_ZTXT_COMPRESSION */
    }
    if (strcmp (what, "WRITE_CUSTOMIZE_COMPRESSION") == 0) {
#ifdef PNG_WRITE_CUSTOMIZE_COMPRESSION_SUPPORTED
        return 1;
#else
        return 0;
#endif /* WRITE_CUSTOMIZE_COMPRESSION */
    }
#line 2343 "perl-libpng.c.tmpl"

    /* sCAL is a special case. */

    if (strcmp (what, "sCAL") == 0) {
#ifdef PERL_PNG_sCAL_s_SUPPORTED
        return 1;
#else
        return 0;
#endif /* sCAL */
    }
    /* The user asked whether something was supported, but we don't
       know what that thing is. */
    warn ( "Unknown whether '%s' is supported", what);
    return 0;
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

static void
perl_png_set_expand (perl_libpng_t * png)
{
    png_set_expand (png->png);
}

static void
perl_png_set_gray_to_rgb (perl_libpng_t * png)
{
    png_set_gray_to_rgb(png->png);
}

static void
perl_png_set_filler (perl_libpng_t * png, int filler, int flags)
{
    png_set_filler (png->png, filler, flags);
}

static void
perl_png_set_strip_16 (perl_libpng_t * png)
{
    png_set_strip_16 (png->png);
}

static SV * perl_png_get_cHRM (perl_libpng_t * png)
{
#ifdef PNG_cHRM_SUPPORTED
    if (VALID (cHRM)) {
        HV * ice;
#line 2629 "/usr/home/ben/projects/image-png-libpng/build/../perl-libpng.c"
        double white_x;
        double white_y;
        double red_x;
        double red_y;
        double green_x;
        double green_y;
        double blue_x;
        double blue_y;
#line 2453 "perl-libpng.c.tmpl"
        png_get_cHRM (pngi , & white_x, & white_y, & red_x, & red_y, & green_x, & green_y, & blue_x, & blue_y);
        ice = newHV ();
#line 2641 "/usr/home/ben/projects/image-png-libpng/build/../perl-libpng.c"
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
#line 2462 "perl-libpng.c.tmpl"
        return newRV_noinc ((SV *) ice);
    }
    return & PL_sv_undef;
#else
    /* libpng was compiled without this option. */
    UNSUPPORTED(cHRM);
    return & PL_sv_undef;
#endif
}

static void perl_png_set_cHRM (perl_libpng_t * png, HV * cHRM)
{
#ifdef PNG_cHRM_SUPPORTED
    SV ** key_sv_ptr;
#line 2673 "/usr/home/ben/projects/image-png-libpng/build/../perl-libpng.c"
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
#line 2487 "perl-libpng.c.tmpl"
    png_set_cHRM (pngi, white_x, white_y, red_x, red_y, green_x, green_y, blue_x, blue_y);
#line 2490 "perl-libpng.c.tmpl"
#else
    /* libpng was compiled without this option. */
    UNSUPPORTED(cHRM);
#endif
}

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
    for (i = 0; i < height; i++) {
	png->row_pointers[i] = crow_pointers[i];
    }
    png_set_rows (pngi, png->row_pointers);
}

#line 2750 "/usr/home/ben/projects/image-png-libpng/build/../perl-libpng.c"

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

#line 2532 "perl-libpng.c.tmpl"


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


static SV *
perl_png_split_alpha (perl_libpng_t * png)
{
    HV * split;
    SV * split_ref;
    SV * data;
    SV * alpha;
    int datapix;
    png_uint_32 width;
    png_uint_32 height;
    int bit_depth;
    int color_type;
    int interlace_method;
    int rowbytes;
    int alphapix;
    int npixels;
    unsigned char * databytes;
    unsigned char * alphabytes;
    int i;
    png_bytepp rows;
    int rowpixels;
    int bytes;

    alphapix = 1;
    png_get_IHDR (pngi, & width, & height,
		  & bit_depth, & color_type, & interlace_method,
		  0, 0);
    rows = png_get_rows (pngi);
    rowbytes = png_get_rowbytes (pngi);
    rowpixels = rowbytes;
    switch (bit_depth) {
    case 8:
	bytes = 1;
	break;
    case 16:
	bytes = 2;
	break;
    default:
	return &PL_sv_undef;
    }
    switch (color_type) {
    case PNG_COLOR_TYPE_RGB_ALPHA:
	datapix = 3;
	rowpixels /= 4;
	break;
    case PNG_COLOR_TYPE_GRAY_ALPHA:
	datapix = 1;
	rowpixels /= 2;
	break;
    default:
	return &PL_sv_undef;
    }
    npixels = height * rowpixels;
    alphapix = npixels;
    datapix *= npixels;
    Newx (alphabytes, alphapix, unsigned char); 
    Newx (databytes, datapix, unsigned char); 
    int p;
    for (i = 0; i < height; i++) {
	int j;
	png_bytep row;
	row = rows[i];
	switch (bytes) {
	case 1:
	    for (j = 0; j < width; j++) {
		int k;
		int o;
		o = i*width + j;
		switch (color_type) {
		case PNG_COLOR_TYPE_RGB_ALPHA:
		    for (k = 0; k < 3; k++) {
			p = 3*o+k;
			databytes[p] = row[4*j + k];
		    }
		    alphabytes[o] = row[4*j+3];
		    break;
		    break;
		case PNG_COLOR_TYPE_GRAY_ALPHA:
		    databytes[o] = row[2*j];
		    alphabytes[o] = row[2*j+1];
		    break;
		default:
		    break;
		}
	    }
	    break;
	case 2:
	    for (j = 0; j < width; j++) {
		int k;
		int o;
		int byte;
		o = i*width + j;
		switch (color_type) {
		case PNG_COLOR_TYPE_RGB_ALPHA:
		    for (k = 0; k < 3; k++) {
			for (byte = 0; byte < 2; byte++) {
			    databytes[6*o + 2*k + byte] = row[8*j + 2*k + byte];
			}
		    }
		    for (byte = 0; byte < 2; byte++) {
			alphabytes[2*o+byte] = row[8*j+6+byte];
		    }
		    break;
		case PNG_COLOR_TYPE_GRAY_ALPHA:
		    for (byte = 0; byte < 2; byte++) {
			databytes[2*o+byte] = row[4*j+byte];
			alphabytes[2*o+byte] = row[4*j+2+byte];
		    }
		    break;
		default:
		    break;
		}
	    }
	    break;
	}
    }
    data = newSVpv ((const char *) databytes, datapix);
    alpha = newSVpv ((const char *) alphabytes, alphapix);
    Safefree (alphabytes);
    Safefree (databytes);
    split = newHV ();
    hv_store (split, "data", strlen ("data"), data, 0);
    hv_store (split, "alpha", strlen ("alpha"), alpha, 0);
    split_ref = newRV_noinc ((SV*) split);
    return split_ref;
}

#undef pngi

/*
   Local Variables:
   mode: c
   end: 
*/
