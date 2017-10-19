/* These things are common between the validation and the parsing
   routines. This is #included into "Json3.xs". */

/* The following matches bytes which are not allowed in JSON
   strings. "All Unicode characters may be placed within the quotation
   marks except for the characters that must be escaped: quotation
   mark, reverse solidus, and the control characters (U+0000 through
   U+001F)." - from section 2.5 of RFC 4627 */

#define BADBYTES				\
      '\0':case 0x01:case 0x02:case 0x03:	\
 case 0x04:case 0x05:case 0x06:case 0x07:	\
 case 0x08:case 0x09:case 0x0A:case 0x0B:	\
 case 0x0C:case 0x0D:case 0x0E:case 0x0F:	\
 case 0x10:case 0x11:case 0x12:case 0x13:	\
 case 0x14:case 0x15:case 0x16:case 0x17:	\
 case 0x18:case 0x19:case 0x1A:case 0x1B:	\
 case 0x1C:case 0x1D:case 0x1E:case 0x1F

/* Match whitespace. Whitespace is as defined by the JSON standard,
   not by Perl. 

   "Insignificant whitespace is allowed before or after any of the six
   structural characters.

      ws = *(
                %x20 /              ; Space
                %x09 /              ; Horizontal tab
                %x0A /              ; Line feed or New line
                %x0D                ; Carriage return
            )"
    
   From JSON RFC.
*/

#define WHITESPACE         \
    '\n':                  \
    parser->line++;	   \
    /* Fallthrough. */	   \
 case ' ':                 \
 case '\t':                \
 case '\r'

/* Match digits. */

#define DIGIT \
      '0':    \
 case '1':    \
 case '2':    \
 case '3':    \
 case '4':    \
 case '5':    \
 case '6':    \
 case '7':    \
 case '8':    \
 case '9'

/* Match digits from 1-9. This is handled differently because JSON
   disallows leading zeros in numbers. */

#define DIGIT19 \
      '1':	\
 case '2':	\
 case '3':	\
 case '4':	\
 case '5':	\
 case '6':	\
 case '7':	\
 case '8':	\
 case '9'

/* Hexadecimal, in upper and lower case. */

#define UHEX  'A': case 'B': case 'C': case 'D': case 'E': case 'F'
#define LHEX  'a': case 'b': case 'c': case 'd': case 'e': case 'f'

/* As of version 0.45 of JSON::Parse, most of the UTF-8 switches are
   now in "unicode.c", but the following one is JSON-specific. */

/* This excludes '"' and '\'. */

#define BYTE_20_7F \
      0x20: case 0x21:\
 case 0x23: case 0x24: case 0x25: case 0x26: case 0x27: case 0x28: case 0x29:\
 case 0x2A: case 0x2B: case 0x2C: case 0x2D: case 0x2E: case 0x2F: case 0x30:\
 case 0x31: case 0x32: case 0x33: case 0x34: case 0x35: case 0x36: case 0x37:\
 case 0x38: case 0x39: case 0x3A: case 0x3B: case 0x3C: case 0x3D: case 0x3E:\
 case 0x3F: case 0x40: case 0x41: case 0x42: case 0x43: case 0x44: case 0x45:\
 case 0x46: case 0x47: case 0x48: case 0x49: case 0x4A: case 0x4B: case 0x4C:\
 case 0x4D: case 0x4E: case 0x4F: case 0x50: case 0x51: case 0x52: case 0x53:\
 case 0x54: case 0x55: case 0x56: case 0x57: case 0x58: case 0x59: case 0x5A:\
 case 0x5B: case 0x5D: case 0x5E: case 0x5F: case 0x60: case 0x61:\
 case 0x62: case 0x63: case 0x64: case 0x65: case 0x66: case 0x67: case 0x68:\
 case 0x69: case 0x6A: case 0x6B: case 0x6C: case 0x6D: case 0x6E: case 0x6F:\
 case 0x70: case 0x71: case 0x72: case 0x73: case 0x74: case 0x75: case 0x76:\
 case 0x77: case 0x78: case 0x79: case 0x7A: case 0x7B: case 0x7C: case 0x7D:\
 case 0x7E: case 0x7F

/* A "string_t" is a pointer into the input, which lives in
   "parser->input". The "string_t" structure is used for copying
   strings when the string does not contain any escapes. When a string
   contains escapes, it is copied into "parser->buffer". */

typedef struct string {

    unsigned char * start;
#ifdef NOPERL
    int length;
#else /* def NOPERL */
    STRLEN length;
#endif /* def NOPERL */
    /* The "contains_escapes" flag is set if there are backslash escapes in
       the string like "\r", so that it needs to be cleaned up before
       using it. That means we use "parser->buffer". This is to speed
       things up, by not doing the cleanup when it isn't necessary. */

    unsigned contains_escapes : 1;
}
string_t;

typedef enum 
{
    json_invalid,
    json_initial_state,
    json_string,
    json_number,
    json_literal,
    json_object,
    json_array,
    json_unicode_escape,
    json_overflow
}
json_type_t;

const char * type_names[json_overflow] = {
    "invalid",
    "initial state",
    "string",
    "number",
    "literal",
    "object",
    "array",
    "unicode escape"
};

/* The maximum value of bytes to check for. */

#define JSON3MAXBYTE 0x100

// uncomment this when running random test to terminal otherwise the
// random characters will mess up the terminal.

//#define JSON3MAXBYTE 0x80

#include "errors.c"

/* Anything which could be the start of a value. */

#define VALUE_START (XARRAYOBJECTSTART|XSTRING_START|XDIGIT|XMINUS|XLITERAL)

typedef struct parser {

    /* The length of "input". */

    unsigned int length;

    /* The input. */

    unsigned char * input;

    /* The end-point of the parsing. This increments through
       "input". */

    unsigned char * end;

    /* The last byte of "input", "parser->input +
       parser->length". This is used to detect overflows. */

    unsigned char * last_byte;

    /* Allocated size of "buffer". */

    int buffer_size;

    /* Buffer to stick strings into temporarily. */

    unsigned char * buffer;

    /* Line number. */

    int line;

    /* Where the beginning of the series of unfortunate events
       was. For example if we are parsing an array, this points to the
       "[" at the start of the array, or if we are parsing a string,
       this points to the byte after the '"' at the start of the
       string. */

    unsigned char * bad_beginning;

    /* The bad type itself. */

    json_type_t bad_type;

    /* What we were expecting to see when the error occurred. */

    int expected;

    /* The byte which caused the parser to fail. */

    unsigned char * bad_byte;
    unsigned bad_length;

    /* The type of error encountered. */

    json_error_t error;

    /* If we were parsing a literal and found a bad character, what
       were we expecting? */
    
    unsigned char literal_char;

    /* The end expected. */

    int end_expected;

    /* Number of mallocs. */

    int n_mallocs;

    /* Bytes we accept. */

    int valid_bytes[JSON3MAXBYTE];

    /* Perl SV * pointers to copy for our true, false, and null
       values. */
    void * user_true;
    void * user_false;
    void * user_null;
    /* If this is 1, we copy the literals into new SVs. */
    unsigned int copy_literals : 1;
    /* If this is 1, we don't die on errors. */
    unsigned int warn_only : 1;
    /* If this is 1, we check for hash collisions before inserting values. */
    unsigned int detect_collisions : 1;
    /* Don't warn the user about non-false false and untrue true
       values, etc. */
    unsigned int no_warn_literals : 1;
    /* Are we tokenizing the input? */
    unsigned int tokenizing : 1;


#ifdef TESTRANDOM

    /* Return point for longjmp. */

    jmp_buf biscuit;

    char * last_error;

#endif

    /* Unicode? */

    unsigned int unicode : 1;

    /* Force unicode. This happens when we hit "\uxyzy". */

    unsigned int force_unicode : 1;

    /* Top-level value? We need to know this for the case when we are
       parsing a number and suddenly meet a '\0' byte. If it's a top
       level value then we can assume that is just the end of the
       JSON, but if it's not a top-level value then that is an error,
       since the end array or end object at least are missing. */

    unsigned int top_level_value : 1;

    /* Produce diagnostics as a hash rather than a string. */

    unsigned int diagnostics_hash : 1;

#ifdef TESTRANDOM

    /* This is true if we are testing with random bytes. */

    unsigned randomtest : 1;

#endif /* def TESTRANDOM */
}
json_parse_t;

#ifndef NOPERL
static SV * error_to_hash (json_parse_t * parser, char * error_as_string);
#endif /* ndef NOPERL */

#ifdef __GNUC__
#define INLINE inline
#else
#define INLINE
#endif /* def __GNUC__ */

/* The size of the buffer for printing errors. */

#define ERRORMSGBUFFERSIZE 0x1000

/* Declare all bad inputs as non-returning. */

#ifdef __GNUC__
#if 0
static void failbadinput_json (json_parse_t * parser) __attribute__ ((noreturn));
#endif /* 0 */
static void failbadinput (json_parse_t * parser) __attribute__ ((noreturn));
static INLINE void
failbug (char * file, int line, json_parse_t * parser, const char * format, ...)
__attribute__ ((noreturn));
#endif

/* Assert failure handler. Coming here means there is a bug in the
   code rather than in the JSON input. We still send it to Perl via
   "croak". */

static INLINE void
failbug (char * file, int line, json_parse_t * parser, const char * format, ...)
{
    char buffer[ERRORMSGBUFFERSIZE];
    va_list a;
    va_start (a, format);
    vsnprintf (buffer, ERRORMSGBUFFERSIZE, format, a);
    va_end (a);
    croak ("JSON::Parse: %s:%d: Internal error at line %d: %s",
	   file, line, parser->line, buffer);
}

/* This is a test for whether the string has ended, which we use when
   we catch a zero byte in an unexpected part of the input. Here we
   use ">" rather than ">=" because "parser->end" is incremented by
   one after each access. See the NEXTBYTE macro. */

#define STRINGEND (parser->end > parser->last_byte)

/* One of the types which demands a specific next byte. */

#define SPECIFIC(c) (((c) & XIN_LITERAL) || ((c) & XIN_SURROGATE_PAIR))

/* Make the list of valid bytes. */

static void make_valid_bytes (json_parse_t * parser)
{
    int i;
    for (i = 0; i < JSON3MAXBYTE; i++) {
	parser->valid_bytes[i] = 0;
    }
    for (i = 0; i < n_expectations; i++) {
	int X;
	X = 1<<i;
	if (SPECIFIC (X)) {
	    continue;
	}
	if (parser->expected & X) {
	    int j;
	    for (j = 0; j < JSON3MAXBYTE; j++) {
		parser->valid_bytes[j] |= allowed[i][j];
	    }
	}
    }
    if (SPECIFIC (parser->expected)) {
	parser->valid_bytes[parser->literal_char] = 1;
    }
}

/* Repeated arguments to snprintf. */

#define SNEND buffer + string_end
#define SNSIZE ERRORMSGBUFFERSIZE - string_end
/*

Disabled due to clash with Darwin compiler:

http://www.cpantesters.org/cpan/report/7c69e0f0-70c0-11e3-95aa-bcf4d95af652
http://www.cpantesters.org/cpan/report/6cde36da-6fd1-11e3-946f-2b87da5af652

#define SNEND, SNSIZE buffer + string_end, ERRORMSGBUFFERSIZE - string_end

*/

#define EROVERFLOW							\
    if (string_end >= ERRORMSGBUFFERSIZE - 0x100) {			\
	failbug (__FILE__, __LINE__, parser,				\
		 "Error string length is %d"				\
		 " of maximum %d. Bailing out.",			\
		 string_end, ERRORMSGBUFFERSIZE);			\
    }


#if 0

/* Coming in to this routine, we have checked the error for validity
   and converted at failbadinput. If this is called directly the bug
   traps won't work. */

static void
failbadinput_json (json_parse_t * parser)
{
    char buffer[ERRORMSGBUFFERSIZE];
    int string_end;

    string_end = 0;
    string_end +=
	snprintf (SNEND, SNSIZE,
		  "{"
		  "\"input length\":%d"
		  ",\"bad type\":\"%s\""
		  ",\"error\":\"%s\"",
		  parser->length,
		  type_names[parser->bad_type],
		  json_errors[parser->error]);
    EROVERFLOW;
    if (parser->bad_byte) {
	int position;
	position = (int) (parser->bad_byte - parser->input) + 1,

	string_end += snprintf (SNEND, SNSIZE,
				",\"bad byte position\":%d"
				",\"bad byte contents\":%d",
				position,
				* parser->bad_byte);
	EROVERFLOW;
    }
    if (parser->bad_beginning) {
	int bcstart;
	bcstart = (int) (parser->bad_beginning - parser->input) + 1;
	string_end +=
	    snprintf (SNEND, SNSIZE, ",\"start of broken component\":%d",
		      bcstart);
	EROVERFLOW;
    }
    if (parser->error == json_error_unexpected_character) {
	int j;
	make_valid_bytes (parser);
	string_end +=
	    snprintf (SNEND, SNSIZE, ",\"valid bytes\":[%d",
		      parser->valid_bytes[0]);
	EROVERFLOW;
	for (j = 1; j < JSON3MAXBYTE; j++) {
	    string_end += snprintf (SNEND, SNSIZE, ",%d",
				    parser->valid_bytes[j]);
	}
	EROVERFLOW;
	string_end += snprintf (SNEND, SNSIZE, "]");
	EROVERFLOW;
    }
    string_end += snprintf (SNEND, SNSIZE, "}\n");
    EROVERFLOW;
    croak (buffer);
}

#endif /* 0 */

static void
failbadinput (json_parse_t * parser)
{
    char buffer[ERRORMSGBUFFERSIZE];
    int string_end;
    int i;
    int l;
    const char * format;

    /* If the error is "unexpected character", and we are at the end
       of the input, change to "unexpected end of input". This is
       probably triggered by reading a byte with value '\0', but we
       don't check the value of "* parser->bad_byte" in the following
       "if" statement, since it's an error to go past the expected end
       of the string regardless of whether the byte is '\0'. */

    if (parser->error == json_error_unexpected_character &&
	STRINGEND) {
	parser->error = json_error_unexpected_end_of_input;
	/* We don't care about what byte it was, we went past the end
	   of the string, which is already a failure. */
	parser->bad_byte = 0;
	/* It trips an assertion if "parser->expected" is set for
	   anything other than an "unexpected character" error. */
	parser->expected = 0;
    }
    /* Array bounds check for error message. */
    if (parser->error <= json_error_invalid &&
	parser->error >= json_error_overflow) {
	failbug (__FILE__, __LINE__, parser,
		 "Bad value for parser->error: %d\n", parser->error);
    }

    format = json_errors[parser->error];
    l = strlen (format);
    if (l >= ERRORMSGBUFFERSIZE - 1) {
	l = ERRORMSGBUFFERSIZE - 1;
    }
    for (i = 0; i < l; i++) {
	buffer[i] = format[i];
    }
    buffer[l] = '\0';
    string_end = l;

    /* If we got an unexpected character somewhere, append the exact
       value of the character to the error message. */

    if (parser->error == json_error_unexpected_character) {

	/* This contains the unexpected character itself, from the
	   "parser->bad_byte" pointer. */

	unsigned char bb;

	/* Make sure that we were told where the unexpected character
	   was. Unlocated unexpected characters are a bug. */

	if (! parser->bad_byte) {
	    failbug (__FILE__, __LINE__, parser,
		     "unexpected character error but "
		     "parser->bad_byte is invalid");
	}

	bb = * parser->bad_byte;

	/* We have to check what kind of character. For example
	   printing '\0' with %c will just give a message which
	   suddenly ends when printed to the terminal, and other
	   control characters will be invisible. So display the
	   character in a different way depending on whether it's
	   printable or not. */

	/* Don't use "isprint" because on Windows it seems to think
	   that 0x80 is printable:
	   http://www.cpantesters.org/cpan/report/d6438b68-6bf4-1014-8647-737bdb05e747 */

	if (bb >= 0x20 && bb < 0x7F) {
	    /* Printable character, print the character itself. */
	    string_end += snprintf (SNEND, SNSIZE, " '%c'", bb);
	    EROVERFLOW;
	}
	else {
	    /* Unprintable character, print its hexadecimal value. */
	    string_end += snprintf (SNEND, SNSIZE, " 0x%02x", bb);
	    EROVERFLOW;
	}
    }
    else if (parser->error == json_error_name_is_not_unique) {
	string_end += snprintf (SNEND, SNSIZE, ": \"%.*s\"",
				parser->bad_length,
				parser->bad_byte);
    }
    /* "parser->bad_type" contains what was being parsed when the
       error occurred. This should never be undefined. */
    if (parser->bad_type <= json_invalid ||
	parser->bad_type >= json_overflow) {
	failbug (__FILE__, __LINE__, parser,
		 "parsing type set to invalid value %d in error message",
		 parser->bad_type);
    }
    string_end += snprintf (SNEND, SNSIZE, " parsing %s",
			    type_names[parser->bad_type]);
    EROVERFLOW;
    if (parser->bad_beginning) {
	int bad_byte;
	bad_byte = (parser->bad_beginning - parser->input) + 1;
	string_end += snprintf (SNEND, SNSIZE, " starting from byte %d",
				bad_byte);
	EROVERFLOW;
    }

    /* "parser->expected" is set for the "unexpected character" error
       and it tells the user what kind of input was expected. It
       contains various flags or'd together, so this goes through each
       possible flag and prints a message for it. */

    if (parser->expected) {
	if (parser->error == json_error_unexpected_character) {
	    int i;
	    int joined;
	    unsigned char bb;
	    bb = * parser->bad_byte;

	    string_end += snprintf (SNEND, SNSIZE, ": expecting ");
	    EROVERFLOW;
	    joined = 0;

	    if (SPECIFIC (parser->expected)) {
		if (! parser->literal_char) {
		    failbug (__FILE__, __LINE__, parser,
			     "expected literal character unset");
		}
		string_end += snprintf (SNEND, SNSIZE, "'%c'", parser->literal_char);
		EROVERFLOW;
	    }
	    for (i = 0; i < n_expectations; i++) {
		int X;
		X = 1<<i;
		if (SPECIFIC (X)) {
		    continue;
		}
		if (i == xin_literal) {
		    failbug (__FILE__, __LINE__, parser,
			     "Literal passed through \"if SPECIFIC(X)\" test");
		}
		if (parser->expected & X) {

		    /* Check that this really is disallowed. */
		    
		    if (allowed[i][bb]) {
			failbug (__FILE__, __LINE__, parser,
				 "mismatch parsing %s: got %X "
				 "but it's allowed by %s (%d)",
				 type_names[parser->bad_type], bb,
				 input_expectation[i], i);
		    }
		    if (joined) {
			string_end += snprintf (SNEND, SNSIZE, " or ");
			EROVERFLOW;
		    }
		    string_end += snprintf (SNEND, SNSIZE, "%s", input_expectation[i]);
		    EROVERFLOW;
		    joined = 1;
		}
	    }
	}
	else {
	    failbug (__FILE__, __LINE__, parser,
		     "'expected' is set but error %s != unexp. char",
		     json_errors[parser->error]);
	}
    }
    else if (parser->error == json_error_unexpected_character) {
	failbug (__FILE__, __LINE__, parser,
		 "unexpected character error for 0X%02X at byte %d "
		 "with no expected value set", * parser->bad_byte,
		 parser->bad_byte - parser->input);
    }

#undef SNEND
#undef SNSIZE

#ifdef TESTRANDOM

    /* Go back to where we came from. */

    if (parser->randomtest) {
	parser->last_error = buffer;
	make_valid_bytes (parser);
	longjmp (parser->biscuit, 1);
    }

#endif /* def TESTRANDOM */

#ifndef NOPERL
    if (parser->diagnostics_hash) {
#if PERL_VERSION > 12
	croak_sv (error_to_hash (parser, buffer));
#endif /* PERL_VERSION > 12 */
    }
#endif /* ndef NOPERL */

    if (parser->length > 0) {
	if (parser->end - parser->input > parser->length) {
	    croak ("JSON error at line %d: %s", parser->line,
		   buffer);
	}
	else if (parser->bad_byte) {
	    croak ("JSON error at line %d, byte %d/%d: %s",
		   parser->line,
		   parser->bad_byte - parser->input + 1,
		   parser->length, buffer);
	}
	else {
	    croak ("JSON error at line %d: %s",
		   parser->line, buffer);
	}
    }
    else {
	croak ("JSON error: %s", buffer);
    }
}

#undef SPECIFIC

/* This is for failures not due to errors in the input or to bugs but
   to exhaustion of resources, i.e. out of memory, or file errors
   would go here if there were any C file opening things anywhere. */

static INLINE void failresources (json_parse_t * parser, const char * format, ...)
{
    char buffer[ERRORMSGBUFFERSIZE];
    va_list a;
    va_start (a, format);
    vsnprintf (buffer, ERRORMSGBUFFERSIZE, format, a);
    va_end (a);
    croak ("Parsing failed at line %d, byte %d/%d: %s", parser->line,
	   parser->end - parser->input,
	   parser->length, buffer);
}

#undef ERRORMSGBUFFERSIZE

/* Get more memory for "parser->buffer". */

static void
expand_buffer (json_parse_t * parser, int length)
{
    if (parser->buffer_size < 2 * length + 0x100) {
	parser->buffer_size = 2 * length + 0x100;
	if (parser->buffer) {
	    Renew (parser->buffer, parser->buffer_size, unsigned char);
	}
	else {
	    Newx (parser->buffer, parser->buffer_size, unsigned char);
	    parser->n_mallocs++;
	}
	if (! parser->buffer) {
	    failresources (parser, "out of memory");
	}
    }
}

#define UNIFAIL(err)						\
    parser->bad_type = json_unicode_escape;			\
    parser->error = json_error_ ## err;				\
    failbadinput (parser)

/* Parse the hex bit of a \uXYZA escape. */

static INLINE int
parse_hex_bytes (json_parse_t * parser, unsigned char * p)
{
    int k;
    int unicode;

    unicode = 0;

    for (k = 0; k < strlen ("ABCD"); k++) {

	unsigned char c;

	c = p[k];

	switch (c) {

	case DIGIT:
	    unicode = unicode * 16 + c - '0';
	    break;

	case UHEX:
	    unicode = unicode * 16 + c - 'A' + 10;
	    break;

	case LHEX:
	    unicode = unicode * 16 + c - 'a' + 10;
	    break;

	case '\0':
	    if (p + k - parser->input >= parser->length) {
		UNIFAIL (unexpected_end_of_input);
	    }
	    break;

	default:
	    parser->bad_byte = p + k;
	    parser->expected = XHEXADECIMAL_CHARACTER;
	    UNIFAIL (unexpected_character);
	}
    }
    return unicode;
}

/* STRINGFAIL applies for any kind of failure within a string, not
   just unexpected character errors. */

#define STRINGFAIL(err)				\
    parser->error = json_error_ ## err;		\
    parser->bad_type = json_string;		\
    failbadinput (parser)

#define FAILSURROGATEPAIR(c)				\
    parser->expected = XIN_SURROGATE_PAIR;		\
    parser->literal_char = c;				\
    parser->bad_beginning = start - 2;			\
    parser->error = json_error_unexpected_character;	\
    parser->bad_type = json_unicode_escape;		\
    parser->bad_byte = p - 1;				\
    failbadinput (parser)

static INLINE unsigned char *
do_unicode_escape (json_parse_t * parser, unsigned char * p,
		   unsigned char ** b_ptr)
{
    int unicode;
    unsigned int plus;
    unsigned char * start;
    start = p;
    unicode = parse_hex_bytes (parser, p);
    p += 4;
    plus = ucs2_to_utf8 (unicode, *b_ptr);
    if (plus == UTF8_BAD_LEADING_BYTE ||
	plus == UTF8_BAD_CONTINUATION_BYTE) {
	failbug (__FILE__, __LINE__, parser,
		 "Failed to parse unicode input %.4s", start);
    }
    else if (plus == UNICODE_SURROGATE_PAIR) {
	int unicode2;
	int plus2;
	if (parser->last_byte - p < 6) {
	    parser->bad_beginning = start - 2;
	    parser->bad_type = json_unicode_escape;
	    parser->error = json_error_unexpected_end_of_input;
	    failbadinput (parser);
	}
	if (*p++ == '\\') {
	    if (*p++ == 'u') {
		unicode2 = parse_hex_bytes (parser, p);
		p += 4;
		plus2 = surrogate_to_utf8 (unicode, unicode2, * b_ptr);
		if (plus2 <= 0) {
		    if (plus2 == UNICODE_NOT_SURROGATE_PAIR) {
			parser->bad_byte = 0;
			parser->bad_beginning = p - 4;
			UNIFAIL (not_surrogate_pair);
		    }
		    else {
			failbug (__FILE__, __LINE__, parser,
				 "unhandled error %d from surrogate_to_utf8",
				 plus2);
		    }
		}
		* b_ptr += plus2;
		goto end;
	    }
	    else {
		FAILSURROGATEPAIR ('u');
	    }
	}
	else {
	    FAILSURROGATEPAIR ('\\');
	}
    }
    else if (plus <= 0) {
	failbug (__FILE__, __LINE__, parser, 
		 "unhandled error code %d while decoding unicode escape",
		 plus);
    }
    * b_ptr += plus;
 end:
    if (unicode >= 0x80 && ! parser->unicode) {
	/* Force the UTF-8 flag on for this string. */
	parser->force_unicode = 1;
    }
    return p;
}

/* Handle backslash escapes. We can't use the NEXTBYTE macro here for
   the reasons outlined below. */

#if 0

/* I expected a switch statement to compile to faster code, but it
   doesn't seem to. */

#define HANDLE_ESCAPES(p,start)				\
    switch (c = * ((p)++)) {				\
							\
    case '\\':						\
    case '/':						\
    case '"':						\
	*b++ = c;					\
	break;						\
							\
    case 'b':						\
	*b++ = '\b';					\
	break;						\
							\
    case 'f':						\
	*b++ = '\f';					\
	break;						\
							\
    case 'n':						\
	*b++ = '\n';					\
	break;						\
							\
    case 'r':						\
	*b++ = '\r';					\
	break;						\
							\
    case 't':						\
	*b++ = '\t';					\
	break;						\
							\
    case 'u':						\
	p = do_unicode_escape (parser, p, & b);		\
	break;						\
							\
    default:						\
	parser->bad_beginning = start;			\
	parser->bad_byte = p - 1;			\
        parser->expected = XESCAPE;			\
	STRINGFAIL (unexpected_character);		\
    }

#else

/* This is identical to the above macro, but it uses if statements
   rather than a switch statement. Using the Clang compiler, this
   results in about 2.5% faster code, for some reason or another. */

#define HANDLE_ESCAPES(p,start)				\
    c = * ((p)++);					\
    if (c == '\\' || c == '/' || c == '"') {		\
	*b++ = c;					\
    }							\
    else if (c == 'b') {				\
	*b++ = '\b';					\
    }							\
    else if (c == 'f') {				\
	*b++ = '\f';					\
    }							\
    else if (c == 'n') {				\
	*b++ = '\n';					\
    }							\
    else if (c == 'r') {				\
	*b++ = '\r';					\
    }							\
    else if (c == 't') {				\
	*b++ = '\t';					\
    }							\
    else if (c == 'u') {				\
	p = do_unicode_escape (parser, p, & b);		\
    }							\
    else {						\
	parser->bad_beginning = start;			\
	parser->bad_byte = p - 1;			\
        parser->expected = XESCAPE;			\
	STRINGFAIL (unexpected_character);		\
    }
#endif
/* Resolve "s" by converting escapes into the appropriate things. Put
   the result into "parser->buffer". The return value is the length of
   the string. */

static INLINE int
resolve_string (json_parse_t * parser, string_t * s)
{
    /* The pointer where we copy the string. This points into
       "parser->buffer". */

    unsigned char * b;

    /* "p" is the pointer into "parser->input", using "s->start" to
       get the start point. We don't use "parser->end" for this job
       because "resolve_string" is called only after the value of the
       object is resolved. E.g. if the object goes like

       {"hot":{"potatoes":"tomatoes"}}

       then this routine is called first for "potatoes" and then for
       "hot" as each sub-element of the hashes is resolved. We don't
       want to mess around with the value of "parser->end", which is
       always pointing to one after the last byte viewed. */

    unsigned char * p;

    p = s->start;

    /* Ensure we have enough memory to fit the string. */

    expand_buffer (parser, s->length);

    b = parser->buffer;

    while (p - s->start < s->length) {
	unsigned char c;

	c = *p++;
	if (c == '\\') {
	    HANDLE_ESCAPES (p, s->start - 1);
	}
	else {
	    *b++ = c;
	}
    }

    /* This is the length of the string in bytes. */

    return b - parser->buffer;
}

#define NEXTBYTE (c = *parser->end++)

/* Get an object key value and put it into "key". Check for
   escapes. */

static INLINE void
get_key_string (json_parse_t * parser, string_t * key)
{
    unsigned char c;
    int i;

    key->start = parser->end;
    key->contains_escapes = 0;

 key_string_next:

    switch (NEXTBYTE) {

    case '"':
	/* Go on eating bytes until we find a ". */

	break;

    case '\\':
	/* Mark this string as containing escapes. */
	key->contains_escapes = 1;

	switch (NEXTBYTE) {

	case '\\':
	case '/': 
	case '"': 
	case 'b':
	case 'f': 
	case 'n': 
	case 'r': 
	case 't': 
	    /* Eat another byte. */
	    goto key_string_next;

	case 'u': 

	    /* i counts the bytes, from 0 to 3. */
	    i = 0;
	unitunes:
	    switch (NEXTBYTE) {
	    case DIGIT:
	    case UHEX:
	    case LHEX:
		i++;
		if (i >= strlen ("ABCD")) {
		    goto key_string_next;
		}
		else {
		    goto unitunes;
		}
		/* not a fall through, we always "goto" above. */
	    default:
		parser->bad_beginning = parser->end - 1 - i;
		parser->expected = XHEXADECIMAL_CHARACTER;
		parser->bad_byte = parser->end - 1;
		UNIFAIL (unexpected_character);
	    }
	    /* not a fall through, we either UNIFAIL or goto above. */

	default:
	    parser->bad_beginning = key->start - 1;
	    parser->expected = XESCAPE;
	    parser->bad_byte = parser->end - 1;
	    STRINGFAIL (unexpected_character);
	}
	/* Not a fall through, we never arrive here. */

    case BADBYTES:

	parser->bad_beginning = key->start - 1;
	parser->expected = XSTRINGCHAR;
	parser->bad_byte = parser->end - 1;
	STRINGFAIL (unexpected_character);
	/* Not a fall through, STRINGFAIL does not return. */

#define ADDBYTE 
#define string_start key_string_next
#define startofutf8string (key->start)
#include "utf8-byte-one.c"
	/* Not a fall through. */
    default:

	parser->bad_beginning = key->start - 1;
	parser->expected = XSTRINGCHAR;
	parser->bad_byte = parser->end - 1;
	STRINGFAIL (unexpected_character);
    }
    key->length = parser->end - key->start - 1;
    return;

#include "utf8-next-byte.c"
#undef startofutf8string
#undef string_start
#undef ADDBYTE
}

/* "start - 1" puts the start on the " rather than after it. "start"
   is usually after the quote because the quote is eaten on the way
   here. */

#define ILLEGALBYTE							\
    parser->bad_beginning = start - 1;					\
    parser->bad_byte = parser->end - 1;					\
    parser->expected = XSTRINGCHAR;					\
    STRINGFAIL (unexpected_character)


/* Resolve the string pointed to by "parser->end" into
   "parser->buffer". The return value is the length of the
   string. This is only called if the string has \ escapes in it. */

static INLINE int
get_string (json_parse_t * parser)
{
    unsigned char * b;
    unsigned char c;
    unsigned char * start;

    start = parser->end;

    if (! parser->buffer) {
	expand_buffer (parser, 0x1000);
    }
    b = parser->buffer;

 string_start:

    if (b - parser->buffer >= parser->buffer_size - 0x100) {
	/* Save our offset in parser->buffer, because "realloc" is
	   called by "expand_buffer", and "b" may no longer point
	   to a meaningful location. */
	int size = b - parser->buffer;
	expand_buffer (parser, 2 * parser->buffer_size);
	b = parser->buffer + size;
    }
    switch (NEXTBYTE) {

    case '"':
	goto string_end;
	break;

    case '\\':
	HANDLE_ESCAPES (parser->end, start - 1);
	goto string_start;

#define ADDBYTE (* b++ = c)
#define startofutf8string start
#include "utf8-byte-one.c"

	/* Not a fall through. */
    default:
	/* fall through */
    case BADBYTES:
	ILLEGALBYTE;
    }

    if (STRINGEND) {
	STRINGFAIL (unexpected_end_of_input);
    }

 string_end:
    return b - parser->buffer;

#include "utf8-next-byte.c"
#undef ADDBYTE

    goto string_end;
}

static void
parser_free (json_parse_t * parser)
{
    if (parser->buffer) {
	Safefree (parser->buffer);
	parser->n_mallocs--;
    }
    /* There is a discrepancy between the number of things used and
       the number freed. */
    if (parser->n_mallocs != 0) {
	/* The tokenizing parser is freed before the tokens themselves
	   are freed. Whether or not the tokens are freed correctly
	   can be checked in "tokenize_free" in
	   "json-entry-points.c". */
	if (! parser->tokenizing) {
	    fprintf (stderr, "%s:%d: %d pieces of unfreed memory remain.\n",
		     __FILE__, __LINE__, parser->n_mallocs);
	}
    }
    parser->buffer = 0;
    parser->buffer_size = 0;
}


typedef enum json_token_type {
    json_token_invalid,
    json_token_number,
    json_token_string,
    json_token_key,
    json_token_literal,
    json_token_comma,
    json_token_colon,
    json_token_object,
    json_token_array,
    n_json_tokens
}
json_token_type_t;

const char * token_names[n_json_tokens] = {
    "invalid",
    "number",
    "string",
    "key",
    "literal",
    "comma",
    "colon",
    "object",
    "array"
};

typedef struct json_token json_token_t;

struct json_token {
    json_token_t * child;
    json_token_t * next;
    unsigned int start;
    unsigned int end;
    json_token_type_t type;
    unsigned int parent;
    unsigned blessed : 1;
};

#define JSON_TOKEN_PARENT_INVALID 0

/* "start" is the first character of the thing. "end" is the last
   character of the thing. If the thing only takes one character then
   "start == end" should be true. */

static json_token_t *
json_token_new (json_parse_t * parser, unsigned char * start,
		unsigned char * end, json_token_type_t type)
{
    json_token_t * new;

    /* Check the token in various ways. */

    switch (type) {
    case json_token_string:
    case json_token_key:
	if (* start != '"') {
	    if (end) {
		failbug (__FILE__, __LINE__, parser,
			 "no quotes at start of string '%.*s'",
			 end - start, start);
	    }
	    else {
		failbug (__FILE__, __LINE__, parser,
			 "no quotes at start of string '%.10s'",
			 start);
	    }
	}
	if (end && * end != '"') {
	    failbug (__FILE__, __LINE__, parser,
		     "'%c' is not a quote at end of string '%.*s'",
		     * end, end - start, start);
	}
	break;
    case json_token_number:
	if (* start - '0' > 9 && * start != '-') {
	    failbug (__FILE__, __LINE__, parser,
		     "bad character %c at start of number",
		     * start);
	}
	if (* end - '0' > 9) {
	    failbug (__FILE__, __LINE__, parser,
		     "bad character %c at end of number",
		     * end);
	}
	break;
    case json_token_object:
	if (* start != '{' || (end && * end != '}')) {
	    failbug (__FILE__, __LINE__, parser,
		     "no { or } in object %.*s: char %X",
		     end ? end - start : strlen ((char *) start),
		     start, * start);
	}
	break;
    case json_token_array:
	if (* start != '[' || (end && * end != ']')) {
	    failbug (__FILE__, __LINE__, parser,
		     "no [ or ] in array");
	}
	break;
    case json_token_comma:
	if (end - start != 0 || * start != ',') {
	    failbug (__FILE__, __LINE__, parser,
		     "not a comma %.*s",
		     end - start);
	}
	break;
    case json_token_colon:
	if (end - start != 0 || * start != ':') {
	    failbug (__FILE__, __LINE__, parser,
		     "not a colon %.*s",
		     end - start);
	}
	break;
    case json_token_literal:
	break;
    default:
	croak ("%s:%d: bad type %d\n", __FILE__, __LINE__, type);
    }
    Newx (new, 1, json_token_t);
//    static int nnew;
//    nnew++;
//    fprintf (stderr, "New %d %p\n", nnew, new);
    parser->n_mallocs++;
#if 0
    fprintf (stderr, "%s:%d: parser->n_mallocs = %d\n",
	     __FILE__, __LINE__, parser->n_mallocs);
#endif /* 0 */
    new->start = start - parser->input;
    if (end) {
	new->end = end - parser->input + 1;
    }
    else {
	new->end = 0;
    }
    new->type = type;
    new->parent = JSON_TOKEN_PARENT_INVALID;
    new->child = 0;
    new->next = 0;
    return new;
}

static void
json_token_set_end (json_parse_t * parser, json_token_t * jt, unsigned char * end)
{
    if (jt->end != 0) {
	int offset = (int) (end - parser->input);
	failbug (__FILE__, __LINE__, parser,
		 "attempt to set end as %d is now %d\n",
		 offset, jt->end);
    }

    switch (jt->type) {
    case json_token_string:
    case json_token_key:
	if (* end != '"') {
	    failbug (__FILE__, __LINE__, parser,
		     "no quotes at end of string");
	}
	break;
    case json_token_object:
	if (* end != '}') {
	    failbug (__FILE__, __LINE__, parser,
		     "no } at end of object");
	}
	break;
    case json_token_array:
	if (* end != ']') {
	    failbug (__FILE__, __LINE__, parser,
		     "no ] at end of array");
	}
	break;
    default:
	failbug (__FILE__, __LINE__, parser,
		 "set end for unknown type %d", jt->type);
	break;
    }
    jt->end = end - parser->input + 1;
}

static json_token_t *
json_token_set_child (json_parse_t * parser, json_token_t * parent,
		      json_token_t * child)
{
    switch (parent->type) {
    case json_token_object:
    case json_token_array:
	break;
    default:
	failbug (__FILE__, __LINE__, parser,
		 "bad parent type %d\n",
		 parent->type);
    }
    parent->child = child;
    return child;
}

static json_token_t *
json_token_set_next (json_token_t * prev, json_token_t * next)
{
    prev->next = next;
    return next;
}

