/* 
   This is the main part of JSON::Create.

   It's kept in a separate file but #included into the main file,
   Create.xs.
*/

#ifdef __GNUC__
#define INLINE inline
#else
#define INLINE
#endif /* __GNUC__ */

/* These are return statuses for the types of failures which can
   occur. */

typedef enum {
    json_create_ok,

    /* The following set of exceptions indicate something went wrong
       in JSON::Create's code, in other words bugs. */

    /* An error from the unicode.c library. */
    json_create_unicode_error,
    /* A printed number turned out to be longer than MARGIN bytes. */
    json_create_number_too_long,
    /* Unknown type of floating point number. */
    json_create_unknown_floating_point,
    /* Bad format for floating point. */
    json_create_bad_floating_format,

    /* The following set of exceptions indicate bad input, in other
       words these are user-generated exceptions. */

    /* Badly-formatted UTF-8. */
    json_create_unicode_bad_utf8,
    /* Unknown Perl svtype within the structure. */
    json_create_unknown_type,
    /* User's routine returned invalid stuff. */
    json_create_invalid_user_json,
    /* User gave us an undefined value from a user subroutine. */
    json_create_undefined_return_value,
    /* Rejected non-ASCII, non-character string in strict mode. */
    json_create_non_ascii_byte,
    /* Rejected scalar reference in strict mode. */
    json_create_scalar_reference,
    /* Rejected non-finite number in strict mode. */
    json_create_non_finite_number,
}
json_create_status_t;

#define BUFSIZE 0x4000

/* MARGIN is the size of the "spillover" area where we can print
   numbers or Unicode UTF-8 whole characters (runes) into the buffer
   without having to check the printed length after each byte. */

#define MARGIN 0x40

typedef struct json_create {
    /* The length of the input string. */
    int length;
    unsigned char * buffer;
    /* Place to write the buffer to. */
    SV * output;
    /* Format for floating point numbers. */
    char * fformat;
    /* Memory leak counter. */
    int n_mallocs;
    /* Handlers for objects and booleans. If there are no handlers,
       this is zero (a NULL pointer). */
    HV * handlers;
    /* User reference handler. */
    SV * type_handler;
    /* User obj handler. */
    SV * obj_handler;
    /* User non-finite-float handler. */
    SV * non_finite_handler;
    /* Do any of the SVs have a Unicode flag? */
    unsigned int unicode : 1;
    /* Should we convert / into \/? */
    unsigned int escape_slash : 1;
    /* Should Unicode be upper case? */
    unsigned int unicode_upper : 1;
    /* Should we escape all non-ascii? */
    unsigned int unicode_escape_all : 1;
    /* Should we validate user-defined JSON? */
    unsigned int validate : 1;
    /* Do not escape U+2028 and U+2029. */
    unsigned int no_javascript_safe : 1;
    /* Make errors fatal. */
    unsigned int fatal_errors : 1;
    /* Replace bad UTF-8 with the "replacement character". */
    unsigned int replace_bad_utf8 : 1;
    /* Never upgrade the output to "utf8". */
    unsigned int downgrade_utf8 : 1;
    /* Output may contain invalid UTF-8. */
    unsigned int utf8_dangerous : 1;
    /* Strict mode, reject lots of things. */
    unsigned int strict : 1;
}
json_create_t;

/* Check the length of the buffer, and if we don't have more than
   MARGIN bytes left to write into, then we put "jc->buffer" into the
   Perl scalar "jc->output" via "json_create_buffer_fill". We always
   want to be at least MARGIN bytes from the end of "jc->buffer" after
   every write operation, so that we always have room to put a number
   or a UTF-8 "rune" in the buffer without checking the length
   excessively. */

#define CHECKLENGTH				\
    if (jc->length >= BUFSIZE - MARGIN) {	\
	CALL (json_create_buffer_fill (jc));	\
    }

/* Print an error to stderr. */

static int
json_create_error_handler_default (const char * file, int line_number, const char * msg, ...)
{
    int printed;
    va_list vargs;
    va_start (vargs, msg);
    printed = 0;
    printed += fprintf (stderr, "%s:%d: ", file, line_number);
    printed += vfprintf (stderr, msg, vargs);
    printed += fprintf (stderr, "\n");
    va_end (vargs);
    return printed;
}

static int (* json_create_error_handler) (const char * file, int line_number, const char * msg, ...) = json_create_error_handler_default;

#define JCEH json_create_error_handler

#define HANDLE_STATUS(x,status) {				\
	switch (status) {					\
	    /* These exceptions indicate a user error. */	\
	case json_create_unknown_type:				\
	case json_create_unicode_bad_utf8:			\
	case json_create_invalid_user_json:			\
	case json_create_undefined_return_value:		\
	case json_create_non_ascii_byte:			\
	case json_create_scalar_reference:			\
	case json_create_non_finite_number:			\
	    break;						\
	    							\
	    /* All other exceptions are our bugs. */		\
	default:						\
	    if (JCEH) {						\
		(*JCEH) (__FILE__, __LINE__,			\
			 "call to %s failed with status %d",	\
			 #x, status);				\
	    }							\
	}							\
    }

#define CALL(x) {							\
	json_create_status_t status;					\
	status = x;							\
	if (status != json_create_ok) {					\
	    HANDLE_STATUS (x,status);					\
	    return status;						\
	}								\
    }

static void
json_create_user_message (json_create_t * jc, json_create_status_t status, const char * format, ...)
{
    va_list a;
    /* Check the status. */
    va_start (a, format);
    if (jc->fatal_errors) {
	vcroak (format, & a);
    }
    else {
	vwarn (format, & a);
    }
}

/* Everything else in this file is ordered from callee at the top to
   caller at the bottom, but because of the recursion as we look at
   JSON values within arrays or hashes, we need to forward-declare
   "json_create_recursively". */

static json_create_status_t
json_create_recursively (json_create_t * jc, SV * input);

/* Copy the jc buffer into its SV. */

static INLINE json_create_status_t
json_create_buffer_fill (json_create_t * jc)
{
    /* There is nothing to put in the output. */
    if (jc->length == 0) {
	if (jc->output == 0) {
	    /* And there was not anything before either. */
	    jc->output = & PL_sv_undef;
	}
	/* Either way, we don't need to do anything more. */
	return json_create_ok;
    }
    if (! jc->output) {
	jc->output = newSVpvn ((char *) jc->buffer, (STRLEN) jc->length);
    }
    else {
	sv_catpvn (jc->output, (char *) jc->buffer, (STRLEN) jc->length);
    }
    /* "Empty" the buffer, we don't bother cleaning out the old
       values, so "jc->length" is our only clue as to the clean/dirty
       state of the buffer. */
    jc->length = 0;
    return json_create_ok;
}

/* Add one character to the end of jc. */

static INLINE json_create_status_t
add_char (json_create_t * jc, unsigned char c)
{
    jc->buffer[jc->length] = c;
    jc->length++;
    /* The size we have to use before we write the buffer out. */
    CHECKLENGTH;
    return json_create_ok;
}

/* Add a nul-terminated string to "jc", up to the nul byte. This
   should not be used unless it's strictly necessary, prefer to use
   "add_str_len" instead. Basically, don't use this. This is not
   intended to be Unicode-safe, it is only to be used for strings
   which we know do not need to be checked for Unicode validity (for
   example sprintf'd numbers or something). */

static INLINE json_create_status_t
add_str (json_create_t * jc, const char * s)
{
    int i;
    for (i = 0; s[i]; i++) {
	unsigned char c;
	c = (unsigned char) s[i];
	CALL (add_char (jc, c));
    }
    return json_create_ok;
}

/* Add a string "s" with length "slen" to "jc". This does not test for
   nul bytes, but just copies "slen" bytes of the string.  This is not
   intended to be Unicode-safe, it is only to be used for strings we
   know do not need to be checked for Unicode validity. */

static INLINE json_create_status_t
add_str_len (json_create_t * jc, const char * s, unsigned int slen)
{
    int i;
    /* We know that (BUFSIZE - jc->length) is always bigger than
       MARGIN going into this, but the compiler doesn't. Hopefully,
       the compiler optimizes the following "if" statement away to a
       true value for almost all cases when this is inlined and slen
       is known to be smaller than MARGIN. */
    if (slen < MARGIN || slen < BUFSIZE - jc->length) {
	for (i = 0; i < slen; i++) {
	    jc->buffer[jc->length + i] = s[i];
	}
	jc->length += slen;
	CHECKLENGTH;
    }
    else {
	/* A very long string which may overflow the buffer, so use
	   checking routines. */
	for (i = 0; i < slen; i++) {
	    CALL (add_char (jc, (unsigned char) s[i]));
	}
    }
    return json_create_ok;
}

/* "Add a string" macro, this just saves cut and pasting a string and
   typing "strlen" over and over again. For ASCII values only, not
   Unicode safe. */

#define ADD(x) CALL (add_str_len (jc, x, strlen (x)));

static const char *uc_hex = "0123456789ABCDEF";
static const char *lc_hex = "0123456789abcdef";

static INLINE json_create_status_t
add_one_u (json_create_t * jc, unsigned int u)
{
    char * spillover;
    const char * hex;
    hex = lc_hex;
    if (jc->unicode_upper) {
	hex = uc_hex;
    }
    spillover = (char *) (jc->buffer) + jc->length;
    spillover[0] = '\\';
    spillover[1] = 'u';
    // Method poached from https://metacpan.org/source/CHANSEN/Unicode-UTF8-0.60/UTF8.xs#L196
    spillover[5] = hex[u & 0xf];
    u >>= 4;
    spillover[4] = hex[u & 0xf];
    u >>= 4;
    spillover[3] = hex[u & 0xf];
    u >>= 4;
    spillover[2] = hex[u & 0xf];
    jc->length += 6;
    CHECKLENGTH;
    return json_create_ok;
}

/* Add a "\u3000" or surrogate pair if necessary. */

static INLINE json_create_status_t
add_u (json_create_t * jc, unsigned int u)
{
    if (u > 0xffff) {
	unsigned hi;
	unsigned lo;
	int status = unicode_to_surrogates (u, & hi, & lo);
	if (status != UNICODE_OK) {
	    if (JCEH) {
		(*JCEH) (__FILE__, __LINE__,
			 "Error %d making surrogate pairs from %X",
			 status, u);
	    }
	    return json_create_unicode_error;
	}
	CALL (add_one_u (jc, hi));
	/* Backtrace fallthrough. */
	return add_one_u (jc, lo);
    }
    else {
	/* Backtrace fallthrough. */
	return add_one_u (jc, u);
    }
}

#define BADUTF8								\
    if (jc->replace_bad_utf8) {						\
	/* We have to switch on Unicode otherwise the replacement */	\
	/* characters don't work as intended. */			\
	jc->unicode = 1;						\
	CALL (add_str_len (jc, "\xEF\xBF\xBD", 3));			\
    }									\
    else {								\
	json_create_user_message (jc, json_create_unicode_bad_utf8,	\
				  "Invalid UTF-8");			\
	return json_create_unicode_bad_utf8;				\
    }

/* Jump table. Doing it this way is not the fastest possible way, but
   it's also very difficult for a compiler to mess this
   up. Theoretically, it would be faster to make a jump table by the
   compiler from the switch statement, but some compilers sometimes
   cannot do that. */

/* In this enum, I use three letters as a compromise between
   readability and formatting. The control character names are from
   "man ascii" with an X tagged on the end. */

typedef enum {
    CTL,  // control char, escape to \u
    BSX,  // backslash b
    HTX,  // Tab character
    NLX,  // backslash n, new line
    NPX,  // backslash f
    CRX,  // backslash r
    ASC,  // Non-special ASCII
    QUO,  // double quote
    BSL,  // backslash
    FSL,  // forward slash, "/" 
    BAD,  // Invalid UTF-8 value.
    UT2,  // UTF-8, two bytes
    UT3,  // UTF-8, three bytes
    UT4,  // UTF-8, four bytes
}
jump_t;

static jump_t jump[0x100] = {
    CTL,CTL,CTL,CTL,CTL,CTL,CTL,CTL,BSX,HTX,NLX,CTL,NPX,CRX,CTL,CTL,
    CTL,CTL,CTL,CTL,CTL,CTL,CTL,CTL,CTL,CTL,CTL,CTL,CTL,CTL,CTL,CTL,
    ASC,ASC,QUO,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,FSL,
    ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,
    ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,
    ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,BSL,ASC,ASC,ASC,
    ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,
    ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,ASC,
    BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,
    BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,
    BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,
    BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,
    BAD,BAD,UT2,UT2,UT2,UT2,UT2,UT2,UT2,UT2,UT2,UT2,UT2,UT2,UT2,UT2,
    UT2,UT2,UT2,UT2,UT2,UT2,UT2,UT2,UT2,UT2,UT2,UT2,UT2,UT2,UT2,UT2,
    UT3,UT3,UT3,UT3,UT3,UT3,UT3,UT3,UT3,UT3,UT3,UT3,UT3,UT3,UT3,UT3,
    UT4,UT4,UT4,UT4,UT4,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,
};

/* Need this twice, once within the ASCII handler and once within the
   Unicode handler. */

#define ASCII \
	case CTL:\
	    CALL (add_one_u (jc, (unsigned int) c));\
	    i++;\
	    break;\
\
	case BSX:\
	    ADD ("\\b");\
	    i++;\
	    break;\
\
	case HTX:\
	    ADD ("\\t");\
	    i++;\
	    break;\
\
	case NLX:\
	    ADD ("\\n");\
	    i++;\
	    break;\
\
	case NPX:\
	    ADD ("\\f");\
	    i++;\
	    break;\
\
	case CRX:\
	    ADD ("\\r");\
	    i++;\
	    break;\
\
	case ASC:\
	    CALL (add_char (jc, c));\
	    i++;\
	    break;\
\
	case QUO:\
	    ADD ("\\\"");\
	    i++;\
	    break;\
\
	case FSL:\
	    if (jc->escape_slash) {\
		ADD ("\\/");\
	    }\
	    else {\
		CALL (add_char (jc, c));\
	    }\
	    i++;\
	    break;\
\
	case BSL:\
	    ADD ("\\\\");\
	    i++;\
	    break;


static INLINE json_create_status_t
json_create_add_ascii_key_len (json_create_t * jc, const unsigned char * key, STRLEN keylen)
{
    int i;

    CALL (add_char (jc, '"'));
    for (i = 0; i < keylen; ) {
	char c;
	c = key[i];
	switch (jump[c]) {

	ASCII;

	default:
	    json_create_user_message (jc, json_create_non_ascii_byte,
				      "Non-ASCII byte in non-utf8 string: %X",
				      key[i]);
	    return json_create_non_ascii_byte;
	}
    }
    CALL (add_char (jc, '"'));
    return json_create_ok;
}


/* Add a string to the buffer with quotes around it and escapes for
   the escapables. */

static INLINE json_create_status_t
json_create_add_key_len (json_create_t * jc, const unsigned char * key, STRLEN keylen)
{
    int i;

    CALL (add_char (jc, '"'));
    for (i = 0; i < keylen; ) {
	unsigned char c, d, e, f;
	c = key[i];

	switch (jump[c]) {

	ASCII;

	case BAD:
	    BADUTF8;
	    i++;
	    break;

	case UT2:
	    d = key[i + 1];
	    if (d < 0x80 || d > 0xBF) {
		BADUTF8;
		i++;
		break;
	    }
	    if (jc->unicode_escape_all) {
		unsigned int u;
		u = (c & 0x1F)<<6
		  | (d & 0x3F);
		CALL (add_u (jc, u));
	    }
	    else {
		CALL (add_str_len (jc, (const char *) key + i, 2));
	    }
	    // Increment i
	    i += 2;
	    break;

	case UT3:
	    d = key[i + 1];
	    e = key[i + 2];
	    if (d < 0x80 || d > 0xBF ||
		e < 0x80 || e > 0xBF) {
		BADUTF8;
		i++;
		break;
	    }
	    if (! jc->no_javascript_safe &&
		c == 0xe2 && d == 0x80 && 
		(e == 0xa8 || e == 0xa9)) {
		CALL (add_one_u (jc, 0x2028 + e - 0xa8));
	    }
	    else {
		if (jc->unicode_escape_all) {
		    unsigned int u;
		    u = (c & 0x0F)<<12
		      | (d & 0x3F)<<6
		      | (e & 0x3F);
		    CALL (add_u (jc, u));
		}
		else {
		    CALL (add_str_len (jc, (const char *) key + i, 3));
		}
	    }
	    // Increment i
	    i += 3;
	    break;

	case UT4:
           d = key[i + 1];
           e = key[i + 2];
           f = key[i + 3];
           if (
               // These byte values are copied from
               // https://github.com/htacg/tidy-html5/blob/768ad46968b43e29167f4d1394a451b8c6f40b7d/src/utf8.c

               // 0x40000 - 0xfffff
               (c < 0xf4 &&
                (d < 0x80 || d > 0xBF ||
                 e < 0x80 || e > 0xBF ||
                 f < 0x80 || f > 0xBF))
               ||
               // 0x100000 - 0x10ffff
               (c == 0xf4 && 
                (d < 0x80 || d > 0x8F ||
                 e < 0x80 || e > 0xBF ||
                 f < 0x80 || f > 0xBF))
               ) {
               BADUTF8;
               i++;
               break;
           }
	    if (jc->unicode_escape_all) {
		unsigned int u;
		const unsigned char * input;
		input = key + i;
		u = (c & 0x07) << 18
		  | (d & 0x3F) << 12
                  | (e & 0x3F) <<  6
                  | (f & 0x3F);
		add_u (jc, u);
	    }
	    else {
		CALL (add_str_len (jc, (const char *) key + i, 4));
	    }
	    // Increment i
	    i += 4;
	    break;
	}
    }
    CALL (add_char (jc, '"'));
    return json_create_ok;
}

static INLINE json_create_status_t
json_create_add_string (json_create_t * jc, SV * input)
{
    char * istring;
    STRLEN ilength;
    istring = SvPV (input, ilength);
    if (SvUTF8 (input)) {
	/* "jc->unicode" is true if Perl says that anything in the
	   whole of the input to "json_create" is a "SvUTF8"
	   scalar. We have to force everything in the whole output to
	   Unicode. */
	jc->unicode = 1;
    }
    else if (jc->strict) {
	/* Backtrace fall through, remember to check the caller's line. */
	return json_create_add_ascii_key_len (jc, (unsigned char *) istring,
					      (STRLEN) ilength);
    }
    /* Backtrace fall through, remember to check the caller's line. */
    return json_create_add_key_len (jc, (unsigned char *) istring,
				    (STRLEN) ilength);
}

/* Extract the remainder of x when divided by ten and then turn it
   into the equivalent ASCII digit. '0' in ASCII is 0x30, and (x)%10
   is guaranteed not to have any of the high bits set. */

#define DIGIT(x) (((x)%10)|0x30)

static INLINE json_create_status_t
json_create_add_integer (json_create_t * jc, SV * sv)
{
    long int iv;
    int ivlen;
    char * spillover;

    iv = SvIV (sv);
    ivlen = 0;

    /* Pointer arithmetic. */

    spillover = ((char *) jc->buffer) + jc->length;

    /* Souped-up integer printing for small integers. The following is
       all just souped up versions of snprintf ("%d", iv);. */

    if (iv < 0) {
	spillover[ivlen] = '-';
	ivlen++;
	iv = -iv;
    }
    if (iv < 10) {
	/* iv has exactly one digit. The first digit may be zero. */
	spillover[ivlen] = DIGIT (iv);
	ivlen++;
    }
    else if (iv < 100) {
	/* iv has exactly two digits. The first digit is not zero. */
	spillover[ivlen] = DIGIT (iv/10);
	ivlen++;
	spillover[ivlen] = DIGIT (iv);
	ivlen++;
    }
    else if (iv < 1000) {
	/* iv has exactly three digits. The first digit is not
	   zero. */
	spillover[ivlen] = DIGIT (iv/100);
	ivlen++;
	spillover[ivlen] = DIGIT (iv/10);
	ivlen++;
	spillover[ivlen] = DIGIT (iv);
	ivlen++;
    }
    else if (iv < 10000) {
	/* etc. */
	spillover[ivlen] = DIGIT (iv/1000);
	ivlen++;
	spillover[ivlen] = DIGIT (iv/100);
	ivlen++;
	spillover[ivlen] = DIGIT (iv/10);
	ivlen++;
	spillover[ivlen] = DIGIT (iv);
	ivlen++;
    }
    else if (iv < 100000) {
	spillover[ivlen] = DIGIT (iv/10000);
	ivlen++;
	spillover[ivlen] = DIGIT (iv/1000);
	ivlen++;
	spillover[ivlen] = DIGIT (iv/100);
	ivlen++;
	spillover[ivlen] = DIGIT (iv/10);
	ivlen++;
	spillover[ivlen] = DIGIT (iv);
	ivlen++;
    }
    else if (iv < 1000000) {
	spillover[ivlen] = DIGIT (iv/100000);
	ivlen++;
	spillover[ivlen] = DIGIT (iv/10000);
	ivlen++;
	spillover[ivlen] = DIGIT (iv/1000);
	ivlen++;
	spillover[ivlen] = DIGIT (iv/100);
	ivlen++;
	spillover[ivlen] = DIGIT (iv/10);
	ivlen++;
	spillover[ivlen] = DIGIT (iv);
	ivlen++;
    }
    else if (iv < 10000000) {
	spillover[ivlen] = DIGIT (iv/1000000);
	ivlen++;
	spillover[ivlen] = DIGIT (iv/100000);
	ivlen++;
	spillover[ivlen] = DIGIT (iv/10000);
	ivlen++;
	spillover[ivlen] = DIGIT (iv/1000);
	ivlen++;
	spillover[ivlen] = DIGIT (iv/100);
	ivlen++;
	spillover[ivlen] = DIGIT (iv/10);
	ivlen++;
	spillover[ivlen] = DIGIT (iv);
	ivlen++;
    }
    else if (iv < 100000000) {
	spillover[ivlen] = DIGIT (iv/10000000);
	ivlen++;
	spillover[ivlen] = DIGIT (iv/1000000);
	ivlen++;
	spillover[ivlen] = DIGIT (iv/100000);
	ivlen++;
	spillover[ivlen] = DIGIT (iv/10000);
	ivlen++;
	spillover[ivlen] = DIGIT (iv/1000);
	ivlen++;
	spillover[ivlen] = DIGIT (iv/100);
	ivlen++;
	spillover[ivlen] = DIGIT (iv/10);
	ivlen++;
	spillover[ivlen] = DIGIT (iv);
	ivlen++;
    }
    else if (iv < 1000000000) {
	spillover[ivlen] = DIGIT (iv/100000000);
	ivlen++;
	spillover[ivlen] = DIGIT (iv/10000000);
	ivlen++;
	spillover[ivlen] = DIGIT (iv/1000000);
	ivlen++;
	spillover[ivlen] = DIGIT (iv/100000);
	ivlen++;
	spillover[ivlen] = DIGIT (iv/10000);
	ivlen++;
	spillover[ivlen] = DIGIT (iv/1000);
	ivlen++;
	spillover[ivlen] = DIGIT (iv/100);
	ivlen++;
	spillover[ivlen] = DIGIT (iv/10);
	ivlen++;
	spillover[ivlen] = DIGIT (iv);
	ivlen++;
    }
    else {
	/* The number is one billion (1000,000,000) or more, so we're
	   just going to print it into "jc->buffer" with snprintf. */
	ivlen += snprintf (spillover + ivlen, MARGIN - ivlen, "%ld", iv);
	if (ivlen >= MARGIN) {
	    if (JCEH) {
		(*JCEH) (__FILE__, __LINE__,
			 "A printed integer number %ld was "
			 "longer than MARGIN=%d bytes",
			 SvIV (sv), MARGIN);
	    }
	    return json_create_number_too_long;
	}
    }
    jc->length += ivlen;
    CHECKLENGTH;
    return json_create_ok;
}

#define UNKNOWN_TYPE_FAIL(t)				\
    if (JCEH) {						\
	(*JCEH) (__FILE__, __LINE__,			\
		 "Unknown Perl type %d", t);		\
    }							\
    return json_create_unknown_type

//#define DEBUGOBJ

static json_create_status_t
json_create_validate_user_json (json_create_t * jc, SV * json)
{
    SV * error;
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK (SP);
    XPUSHs (sv_2mortal (newSVsv (json)));
    PUTBACK;
    call_pv ("JSON::Parse::assert_valid_json",
	     G_EVAL|G_DISCARD);
    FREETMPS;
    LEAVE;  
    error = get_sv ("@", 0);
    if (! error) {
	return json_create_ok;
    }
    if (SvOK (error) && SvCUR (error) > 0) {
	json_create_user_message (jc, json_create_invalid_user_json,
				  "JSON::Parse::assert_valid_json failed for '%s': %s",
				  SvPV_nolen (json), SvPV_nolen (error));
	return json_create_invalid_user_json;
    }
    return json_create_ok;
}

static json_create_status_t
json_create_call_to_json (json_create_t * jc, SV * cv, SV * r)
{
    SV * json;
    char * jsonc;
    STRLEN jsonl;
    // https://metacpan.org/source/AMBS/Math-GSL-0.35/swig/gsl_typemaps.i#L438
    dSP;
    
    ENTER;
    SAVETMPS;
    
    PUSHMARK (SP);
    //https://metacpan.org/source/AMBS/Math-GSL-0.35/swig/gsl_typemaps.i#L482
    XPUSHs (sv_2mortal (newRV (r)));
    PUTBACK;
    call_sv (cv, 0);
    json = POPs;
    SvREFCNT_inc (json);
    FREETMPS;
    LEAVE;  

    if (! SvOK (json)) {
	/* User returned an undefined value. */
	SvREFCNT_dec (json);
	json_create_user_message (jc, json_create_undefined_return_value,
				  "Undefined value from user routine");
	return json_create_undefined_return_value;
    }
    if (SvUTF8 (json)) {
	/* We have to force everything in the whole output to
	   Unicode. */
	jc->unicode = 1;
    }
    jsonc = SvPV (json, jsonl);
    if (jc->validate) {
	CALL (json_create_validate_user_json (jc, json));
    }
    else {
	/* This string may contain invalid UTF-8. */
	jc->utf8_dangerous = 1;
    }
    CALL (add_str_len (jc, jsonc, jsonl));
    SvREFCNT_dec (json);
    return json_create_ok;
}

static INLINE json_create_status_t
json_create_add_float (json_create_t * jc, SV * sv)
{
    double fv;
    STRLEN fvlen;
    fv = SvNV (sv);
    if (isfinite (fv)) {
	if (jc->fformat) {
	    fvlen = snprintf ((char *) jc->buffer + jc->length, MARGIN, jc->fformat, fv);
	}
	else {
	    fvlen = snprintf ((char *) jc->buffer + jc->length, MARGIN,
			      "%g", fv);
	}
	if (fvlen >= MARGIN) {
	    return json_create_number_too_long;
	}
	jc->length += fvlen;
	CHECKLENGTH;
    }
    else {
	if (jc->non_finite_handler) {
	    CALL (json_create_call_to_json (jc, jc->non_finite_handler, sv));
	}
	else {
	    if (jc->strict) {
		json_create_user_message (jc, json_create_non_finite_number,
					  "Non-finite number in input");
		return json_create_non_finite_number;
	    }
	    if (isnan (fv)) {
		ADD ("\"nan\"");
	    }
	    else if (isinf (fv)) {
		if (fv < 0.0) {
		    ADD ("\"-inf\"");
		}
		else {
		    ADD ("\"inf\"");
		}
	    }
	    else {
		return json_create_unknown_floating_point;
	    }
	}
    }
    return json_create_ok;
}

/* Add a number which is already stringified. This bypasses snprintf
   and just copies the Perl string straight into the buffer. */

static INLINE json_create_status_t
json_create_add_stringified (json_create_t * jc, SV *r)
{
    /* Stringified number. */
    char * s;
    /* Length of "r". */
    STRLEN rlen;
    s = SvPV (r, rlen);
    /* If the stringified number has leading zeros, don't skip those,
       but put the string in quotes. It can happen that something like
       a Huffman code has leading zeros and should be treated as a
       string, yet Perl also thinks it is a number. */
     if (s[0] == '0' && rlen > 1 && isdigit (s[1])) {
	 CALL (add_char (jc, '"'));
	 CALL (add_str_len (jc, s, (unsigned int) rlen));
	 CALL (add_char (jc, '"'));
	 return json_create_ok;
     } /**/
     /* This doesn't backtrace correctly, but the calling routine
       should print out that it was calling "add_stringified", so as
       long as we're careful not to ignore the caller line, it
       shouldn't matter. */
    return add_str_len (jc, s, (unsigned int) rlen);
}

/* Add a comma where necessary. This is shared between objects and
   arrays. */

#define COMMA					\
    if (i > 0) {				\
	CALL (add_char (jc, ','));		\
    }

/* Given a reference to a hash in "input_hv", recursively process it
   into JSON. "object" here means "JSON object", not "Perl object". */

static INLINE json_create_status_t
json_create_add_object (json_create_t * jc, HV * input_hv)
{
    I32 n_keys;
    int i;
    SV * value;
    char * key;
    I32 keylen;

    CALL (add_char (jc, '{'));
    n_keys = hv_iterinit (input_hv);
    for (i = 0; i < n_keys; i++) {
	HE * he;

	/* Get the information from the hash. */
	/* The following is necessary because "hv_iternextsv" doesn't
	   tell us whether the key is "SvUTF8" or not. */
	he = hv_iternext (input_hv);
	key = hv_iterkey (he, & keylen);
	value = hv_iterval (input_hv, he);

	/* Write the information into the buffer. */

	COMMA;
	if (HeUTF8 (he)) {
	    jc->unicode = 1;
	    CALL (json_create_add_key_len (jc, (const unsigned char *) key,
					   (STRLEN) keylen));
	}
	else if (jc->strict) {
	    CALL (json_create_add_ascii_key_len (jc, (unsigned char *) key,
						 (STRLEN) keylen));
	}
	else {
	    CALL (json_create_add_key_len (jc, (const unsigned char *) key,
					   (STRLEN) keylen));
	}
	CALL (add_char (jc, ':'));
#ifdef JCDEBUGTYPES
	fprintf (stderr, "Creating value of hash.\n");
#endif /* JCDEBUGTYPES */
	CALL (json_create_recursively (jc, value));
    }
    CALL (add_char (jc, '}'));
    return json_create_ok;
}

/* Given an array reference in "av", recursively process it into
   JSON. */

static INLINE json_create_status_t
json_create_add_array (json_create_t * jc, AV * av)
{
    I32 n_keys;
    int i;
    SV * value;

    CALL (add_char (jc, '['));
    n_keys = av_len (av) + 1;
    /* This deals correctly with empty arrays, since av_len is -1 if
       the array is empty, so we do not test for a valid n_keys value
       before entering the loop. */
    for (i = 0; i < n_keys; i++) {
	COMMA;
	value = * (av_fetch (av, i, 0 /* don't delete the array value */));
	CALL (json_create_recursively (jc, value));
    }
    CALL (add_char (jc, ']'));
    return json_create_ok;
}


static INLINE json_create_status_t
json_create_handle_unknown_type (json_create_t * jc, SV * r)
{
    if (jc->type_handler) {
	CALL (json_create_call_to_json (jc, jc->type_handler, r));
    }
    else {
	json_create_user_message (jc, json_create_unknown_type,
				  "Input's type cannot be serialized to JSON");
	return json_create_unknown_type;
    }
    return json_create_ok;
}

#define STRICT_NO_SCALAR						\
    if (jc->strict) {							\
	goto handle_type;						\
    }

//#define JCDEBUGTYPES

static INLINE json_create_status_t
json_create_handle_ref (json_create_t * jc, SV * input)
{
    svtype t;
    SV * r;
    r = SvRV (input);
    t = SvTYPE (r);
#ifdef JCDEBUGTYPES
    fprintf (stderr, "%s:%d: type is %d\n", __FILE__, 
	     __LINE__, t);
#endif /* JCDEBUGTYPES */
    switch (t) {
    case SVt_PVAV:
#ifdef JCDEBUGTYPES
	fprintf (stderr, "array\n");
#endif /* JCDEBUGTYPES */
	CALL (json_create_add_array (jc, (AV *) r));
	break;

    case SVt_PVHV:
#ifdef JCDEBUGTYPES
	fprintf (stderr, "hash\n");
#endif /* JCDEBUGTYPES */
	CALL (json_create_add_object (jc, (HV *) r));
	break;

    case SVt_NV:
    case SVt_PVNV:
#ifdef JCDEBUGTYPES
	fprintf (stderr, "NV/PVNV\n");
#endif /* JCDEBUGTYPES */
	STRICT_NO_SCALAR;
	CALL (json_create_add_float (jc, r));
	break;

    case SVt_IV:
    case SVt_PVIV:
#ifdef JCDEBUGTYPES
	fprintf (stderr, "IV/PVIV\n");
#endif /* JCDEBUGTYPES */
	STRICT_NO_SCALAR;
	CALL (json_create_add_integer (jc, r));
	break;

    case SVt_PV:
	STRICT_NO_SCALAR;
	CALL (json_create_add_string (jc, r));
	break;

    case SVt_PVMG:
	STRICT_NO_SCALAR;
	/* There are some edge cases with blessed references
	   containing numbers which we need to handle correctly. */
	if (SvIOK (r)) {
	    CALL (json_create_add_integer (jc, r));
	}
	else if (SvNOK (r)) {
	    CALL (json_create_add_float (jc, r));
	}
	else {
	    CALL (json_create_add_string (jc, r));
	}
	break;

    default:
    handle_type:
	CALL (json_create_handle_unknown_type (jc, r));
    }
    return json_create_ok;
}

/* In strict mode, if no object handlers exist, then we reject the
   object. */

#define REJECT_OBJECT(objtype)						\
    json_create_user_message (jc, json_create_unknown_type,		\
			      "Object cannot be "			\
			      "serialized to JSON: %s",			\
			      objtype);					\
    return json_create_unknown_type;


static INLINE json_create_status_t
json_create_handle_object (json_create_t * jc, SV * input)
{
    const char * objtype;
    SV * r;

    r = SvRV (input);
    /* The second argument to sv_reftype is true if we
       look it up in the object table, false
       otherwise. Undocumented, reported as
       https://rt.perl.org/Ticket/Display.html?id=126469. */
    objtype = sv_reftype (r, 1);
    if (objtype) {
	if (jc->obj_handler) {
	    CALL (json_create_call_to_json (jc, jc->obj_handler, r));
	}
	else {
	    SV ** sv_ptr;
	    I32 olen;
#ifdef DEBUGOBJ
	    fprintf (stderr, "Have found an object of type %s.\n", objtype);
#endif
	    olen = strlen (objtype);
	    sv_ptr = hv_fetch (jc->handlers, objtype, olen, 0);
	    if (sv_ptr) {
		char * pv;
		STRLEN pvlen;
		pv = SvPV (*sv_ptr, pvlen);
#ifdef DEBUGOBJ
		fprintf (stderr, "Have found a handler %s for %s.\n", pv, objtype);
#endif
		if (pvlen == strlen ("bool") &&
		    strncmp (pv, "bool", 4) == 0) {
		    if (SvTRUE (r)) {
			ADD ("true");
		    }
		    else {
			ADD ("false");
		    }
		}
		else if (SvROK (*sv_ptr)) {
		    SV * what;
		    what = SvRV (*sv_ptr);
		    switch (SvTYPE (what)) {
		    case SVt_PVCV:
			CALL (json_create_call_to_json (jc, what, r));
			break;
		    default:
			/* Weird handler, not a code reference. */
			goto nothandled;
		    }
		}
		else {
		    /* It's an object, it's in our handlers, but we don't
		       have any code to deal with it, so we'll print an
		       error and then stringify it. */
		    if (JCEH) {
			(*JCEH) (__FILE__, __LINE__, "Unhandled handler %s.\n",
				 pv);
			goto nothandled;
		    }
		}
	    }
	    else {
#ifdef DEBUGOBJ
		/* Leaving this debugging code here since this is liable
		   to change a lot. */
		I32 hvnum;
		SV * s;
		char * key;
		I32 retlen;
		fprintf (stderr, "Nothing in handlers for %s.\n", objtype);
		hvnum = hv_iterinit (jc->handlers);

		fprintf (stderr, "There are %ld keys in handlers.\n", hvnum);
		while (1) {
		    s = hv_iternextsv (jc->handlers, & key, & retlen);
		    if (! s) {
			break;
		    }
		    fprintf (stderr, "%s: %s\n", key, SvPV_nolen (s));
		}
#endif /* 0 */
	    nothandled:
		if (jc->strict) {
		    REJECT_OBJECT(objtype);
		}
		CALL (json_create_handle_ref (jc, input));
	    }
	}
    }
    return json_create_ok;
}

/* This is the core routine, it is called recursively as hash values
   and array values containing array or hash references are
   handled. */

static json_create_status_t
json_create_recursively (json_create_t * jc, SV * input)
{
    if (! SvOK (input)) {
	/* We were told to add an undefined value, so put the literal
	   'null' (without quotes) at the end of "jc" then return. */
	ADD ("null");
	return json_create_ok;
    }
    /* JSON::Parse inserts pointers to &PL_sv_yes and no as literal
       "true" and "false" markers. */
    if (input == &PL_sv_yes) {
	ADD ("true");
	return json_create_ok;
    }
    if (input == &PL_sv_no) {
	ADD ("false");
	return json_create_ok;
    }
    if (SvROK (input)) {
#ifdef JCDEBUGTYPES
	fprintf (stderr, "A reference.\n");
#endif /* JCDEBUGTYPES */

	/* We have a reference, so decide what to do with it. */
	if (sv_isobject (input)) {
	    if (jc->handlers || jc->obj_handler) {
		CALL (json_create_handle_object (jc, input));
	    }
	    else if (jc->strict) {
		REJECT_OBJECT (sv_reftype (SvRV (input), 1));
	    }
	    else {
#ifdef JCDEBUGTYPES
		fprintf (stderr, "create handle eferences\n");
#endif /* JCDEBUGTYPES */
		CALL (json_create_handle_ref (jc, input));
	    }
	}
	else {
#ifdef JCDEBUGTYPES
	    fprintf (stderr, "create handle eferences\n");
#endif /* JCDEBUGTYPES */
	    CALL (json_create_handle_ref (jc, input));
	}
    }
    else {
	/* Not a reference, think about what to do. */
	SV * r = input;
	svtype t;
#ifdef JCDEBUGTYPES
	fprintf (stderr, "Not a reference.\n");
#endif /* JCDEBUGTYPES */
	t = SvTYPE (r);
	switch (t) {

	case SVt_NULL:
	    ADD ("null");
	    break;

	case SVt_PVMG:
	case SVt_PV:
#ifdef JCDEBUGTYPES
	    fprintf (stderr, "SVt_PV/PVMG %s\n", SvPV_nolen (r));
#endif /* JCDEBUGTYPES */
	    CALL (json_create_add_string (jc, r));
	    break;

	case SVt_IV:
#ifdef JCDEBUGTYPES
	    fprintf (stderr, "SVt_IV %ld\n", SvIV (r));
#endif /* JCDEBUGTYPES */
	    CALL (json_create_add_integer (jc, r));
	    break;

	case SVt_NV:
//	    fprintf (stderr, "%lu %d %lu %lu\n", SvIOK (r), SvIOK_UV (r), SvNOK (r), SvNIOK (r));
#ifdef JCDEBUGTYPES
	    fprintf (stderr, "SVt_NV %g\n", SvNV (r));
#endif /* JCDEBUGTYPES */
	    CALL (json_create_add_float (jc, r));
	    break;

	case SVt_PVNV:
#ifdef JCDEBUGTYPES
	    fprintf (stderr, "SVt_PVNV %g\n", SvNV (r));
#endif /* JCDEBUGTYPES */
	    /* We need to handle non-finite numbers without using
	       Perl's stringified forms, because we need to put quotes
	       around them, whereas Perl will just print 'nan' the
	       same way it will print '0.01'. 'nan' is not valid JSON,
	       so we have to convert to '"nan"'. */
	    CALL (json_create_add_float (jc, r));
	    break;

	case SVt_PVIV:
	    /* Add numbers with a string version using the strings
	       which Perl contains. */
#ifdef JCDEBUGTYPES
	    fprintf (stderr, "SVt_PV %s\n", SvPV_nolen (r));
#endif /* JCDEBUGTYPES */
	    CALL (json_create_add_stringified (jc, r));
	    break;
	    
	default:
	    CALL (json_create_handle_unknown_type (jc, r));
	}
    }
    return json_create_ok;
}

/* Master-caller macro. Calls to subsystems from "json_create" cannot
   be handled using the CALL macro above, because we need to return a
   non-status value from json_create. If things go wrong somewhere, we
   return "undef". */

#define FINALCALL(x) {						\
	json_create_status_t status;				\
	status = x;						\
	if (status != json_create_ok) {				\
	    HANDLE_STATUS (x, status);				\
	    /* Free the memory of "output". */			\
	    if (jc->output) {					\
		SvREFCNT_dec (jc->output);			\
		jc->output = 0;					\
	    }							\
	    /* return undef; */					\
	    return & PL_sv_undef;				\
	}							\
    }

/* Dog run. */

static INLINE SV *
json_create_run (json_create_t * jc, SV * input)
{
    unsigned char buffer[BUFSIZE];

    /* Set up all the transient variables for reading. */

    /* "jc.buffer" is dirty here, we have not initialized it, we are
       just writing to uninitialized stack memory. "jc.length" is the
       only thing we know is OK at this point. */
    jc->buffer = buffer;

    jc->length = 0;
    /* Tell json_create_buffer_fill that it needs to allocate an
       SV. */
    jc->output = 0;
    /* Not Unicode. */
    jc->unicode = 0;

    /* Unleash the dogs. */
    FINALCALL (json_create_recursively (jc, input));
    /* Copy the remaining text in jc's buffer into "jc->output". */
    FINALCALL (json_create_buffer_fill (jc));

    if (jc->unicode && ! jc->downgrade_utf8) {
	if (jc->utf8_dangerous) {
	    if (is_utf8_string ((U8 *) SvPV_nolen (jc->output), SvCUR (jc->output))) {
		SvUTF8_on (jc->output);
	    }
	    else {
		json_create_user_message (jc, json_create_unicode_bad_utf8,
					  "Invalid UTF-8 from user routine");
		return & PL_sv_undef;
	    }
	}
	else {
	    SvUTF8_on (jc->output);
	}
    }

    /* We didn't allocate any memory except for the SV, all our memory
       is on the stack, so there is nothing to free here. */

    return jc->output;
}

/* Entry point for "create_json_strict". */

static INLINE SV *
json_create_strict (SV * input)
{
    json_create_t jc = {0};
    jc.strict = 1;
    return json_create_run (& jc, input);
}

/* Entry point for "create_json". */

static INLINE SV *
json_create (SV * input)
{
    json_create_t jc = {0};
    return json_create_run (& jc, input);
}

/*  __  __      _   _               _     
   |  \/  | ___| |_| |__   ___   __| |___ 
   | |\/| |/ _ \ __| '_ \ / _ \ / _` / __|
   | |  | |  __/ |_| | | | (_) | (_| \__ \
   |_|  |_|\___|\__|_| |_|\___/ \__,_|___/ */
                                       

static json_create_status_t
json_create_new (json_create_t ** jc_ptr)
{
    json_create_t * jc;
    Newxz (jc, 1, json_create_t);
    jc->n_mallocs = 0;
    jc->n_mallocs++;
    jc->fformat = 0;
    jc->type_handler = 0;
    jc->handlers = 0;
    * jc_ptr = jc;
    return json_create_ok;
}

static json_create_status_t
json_create_free_fformat (json_create_t * jc)
{
    if (jc->fformat) {
	Safefree (jc->fformat);
	jc->fformat = 0;
	jc->n_mallocs--;
    }
    return json_create_ok;
}

static json_create_status_t
json_create_set_fformat (json_create_t * jc, SV * fformat)
{
    char * ff;
    STRLEN fflen;
    int i;

    CALL (json_create_free_fformat (jc));
    if (! SvTRUE (fformat)) {
	jc->fformat = 0;
	return json_create_ok;
    }

    ff = SvPV (fformat, fflen);
    if (! strchr (ff, '%')) {
	return json_create_bad_floating_format;
    }
    Newx (jc->fformat, fflen + 1, char);
    jc->n_mallocs++;
    for (i = 0; i < fflen; i++) {
	/* We could also check the format in this loop. */
	jc->fformat[i] = ff[i];
    }
    jc->fformat[fflen] = '\0';
    return json_create_ok;
}

static json_create_status_t
json_create_remove_handlers (json_create_t * jc)
{
    if (jc->handlers) {
	SvREFCNT_dec ((SV *) jc->handlers);
	jc->handlers = 0;
	jc->n_mallocs--;
    }
    return json_create_ok;
}

static json_create_status_t
json_create_remove_type_handler (json_create_t * jc)
{
    if (jc->type_handler) {
	SvREFCNT_dec (jc->type_handler);
	jc->type_handler = 0;
	jc->n_mallocs--;
    }
    return json_create_ok;
}

static json_create_status_t
json_create_remove_obj_handler (json_create_t * jc)
{
    if (jc->obj_handler) {
	SvREFCNT_dec (jc->obj_handler);
	jc->obj_handler = 0;
	jc->n_mallocs--;
    }
    return json_create_ok;
}

static json_create_status_t
json_create_remove_non_finite_handler (json_create_t * jc)
{
    if (jc->non_finite_handler) {
	SvREFCNT_dec (jc->non_finite_handler);
	jc->non_finite_handler = 0;
	jc->n_mallocs--;
    }
    return json_create_ok;
}

static json_create_status_t
json_create_free (json_create_t * jc)
{
    CALL (json_create_free_fformat (jc));
    CALL (json_create_remove_handlers (jc));
    CALL (json_create_remove_type_handler (jc));
    CALL (json_create_remove_obj_handler (jc));
    CALL (json_create_remove_non_finite_handler (jc));

    /* Finished, check we have no leaks before freeing. */

    jc->n_mallocs--;
    if (jc->n_mallocs != 0) {
	fprintf (stderr, "%s:%d: n_mallocs = %d\n",
		 __FILE__, __LINE__, jc->n_mallocs);
    }
    Safefree (jc);
    return json_create_ok;
}
