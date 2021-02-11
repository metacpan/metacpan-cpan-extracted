/* The C part is broken into three pieces, "json-common.c",
   "json-perl.c", and "json-entry-points.c". This file contains the
   "Perl" stuff, for example if we have a string, the stuff to convert
   it into a Perl hash key or a Perl scalar is in this file. */

/* There are two routes through the code, the PERLING route and the
   non-PERLING route. If we go via the non-PERLING route, we never
   create or alter any Perl-related stuff, we just parse each byte and
   possibly throw an error. This makes validation faster. */

#ifdef PERLING

/* We are creating Perl structures from the JSON. */

#define PREFIX(x) x
#define SVPTR SV *
#define SETVALUE value =

#elif defined(TOKENING)

/* We are just tokenizing the JSON. */

#define PREFIX(x) tokenize_ ## x
#define SVPTR json_token_t *
#define SETVALUE value =

#else /* not def PERLING/TOKENING */

/* Turn off everything to do with creating Perl things. */

#define PREFIX(x) valid_ ## x
#define SVPTR void
#define SETVALUE

#endif /* def PERLING */

/*

This is what INT_MAX_DIGITS is, but #defining it like this causes huge
amounts of unnecessary calculation, so this is commented out.

#define INT_MAX_DIGITS ((int) (log (INT_MAX) / log (10)) - 1)

*/

/* The maximum digits we allow an integer before throwing in the towel
   and returning a Perl string type. */

#define INT_MAX_DIGITS 8

#define USEDIGIT guess = guess * 10 + (c - '0')

static INLINE SVPTR
PREFIX (number) (json_parse_t * parser)
{
    /* End marker for strtod. */

    char * end;

    /* Start marker for strtod. */

    char * start;

    /* A guess for integer numbers. */

    int guess;

    /* The parsed character itself, the cause of our motion. */

    unsigned char c;

    /* If it has exp or dot in it. */

    double d;

    /* Negative number. */

    int minus;

    /* When this is called, it means that a byte indicating a number
       was found. We need to re-examine that byte as a number. */

    parser->end--;
    start = (char *) parser->end;

#define FAILNUMBER(err)				\
    if (STRINGEND &&				\
	parser->top_level_value &&		\
	c == '\0') {				\
	goto exp_number_end;			\
    }						\
    parser->bad_byte = parser->end - 1;		\
    parser->error = json_error_ ## err;		\
    parser->bad_type = json_number;		\
    parser->bad_beginning =			\
	(unsigned char*) start;			\
    failbadinput (parser)

#define NUMBEREND				\
         WHITESPACE:				\
    case ']':					\
    case '}':					\
    case ','

#define XNUMBEREND (XCOMMA|XWHITESPACE|parser->end_expected)

    guess = 0;
    minus = 0;

    switch (NEXTBYTE) {
    case DIGIT19:
	guess = c - '0';
	goto leading_digit19;
    case '0':
	goto leading_zero;
    case '-':
	minus = 1;
	goto leading_minus;
    default:
	parser->expected = XDIGIT | XMINUS;
	FAILNUMBER (unexpected_character);
    }

 leading_digit19:

    switch (NEXTBYTE) {
    case DIGIT:
	USEDIGIT;
	goto leading_digit19;
    case '.':
	goto dot;
    case 'e':
    case 'E':
	goto exp;
    case NUMBEREND:
        goto int_number_end;
    default:
	parser->expected = XDIGIT | XDOT | XEXPONENTIAL | XNUMBEREND;
	if (parser->top_level_value) {
	    parser->expected &= ~XCOMMA;
	}
	FAILNUMBER (unexpected_character);
    }

 leading_zero:
    switch (NEXTBYTE) {
    case '.':
	/* "0." */
	goto dot;
    case 'e':
    case 'E':
	/* "0e" */
	goto exp;
    case NUMBEREND:
	/* "0" */
        goto int_number_end;
    default:
	parser->expected = XDOT | XEXPONENTIAL | XNUMBEREND;
	if (parser->top_level_value) {
	    parser->expected &= ~XCOMMA;
	}
	FAILNUMBER (unexpected_character);
    }

 leading_minus:
    switch (NEXTBYTE) {
    case DIGIT19:
	USEDIGIT;
	goto leading_digit19;
    case '0':
	goto leading_zero;
    default:
	parser->expected = XDIGIT;
	FAILNUMBER (unexpected_character);
    }

    /* Things like "5." are not allowed so there is no NUMBEREND
       here. */

 dot:
    switch (NEXTBYTE) {
    case DIGIT:
	goto dot_digits;
    default:
	parser->expected = XDIGIT;
	FAILNUMBER (unexpected_character);
    }

    /* We have as much as 5.5 so we can stop. */

 dot_digits:
    switch (NEXTBYTE) {
    case DIGIT:
	goto dot_digits;
    case 'e':
    case 'E':
	goto exp;
    case NUMBEREND:
        goto exp_number_end;
    default:
	parser->expected = XDIGIT | XNUMBEREND | XEXPONENTIAL;
	if (parser->top_level_value) {
	    parser->expected &= ~XCOMMA;
	}
	FAILNUMBER (unexpected_character);
    }

    /* Things like "10E" are not allowed so there is no NUMBEREND
       here. */

 exp:
    switch (NEXTBYTE) {
    case '-':
    case '+':
	goto exp_sign;
    case DIGIT:
	goto exp_digits;
    default:
	parser->expected = XDIGIT | XMINUS | XPLUS;
	FAILNUMBER (unexpected_character);
    }

 exp_sign:

    switch (NEXTBYTE) {
    case DIGIT:
	goto exp_digits;
    default:
	parser->expected = XDIGIT;
	FAILNUMBER (unexpected_character);
    }

    /* We have as much as "3.0e1" or similar. */

 exp_digits:
    switch (NEXTBYTE) {
    case DIGIT:
	goto exp_digits;
    case NUMBEREND:
        goto exp_number_end;
    default:
	parser->expected = XDIGIT | XNUMBEREND;
	if (parser->top_level_value) {
	    parser->expected &= ~XCOMMA;
	}
	FAILNUMBER (unexpected_character);
    }

 exp_number_end:
    parser->end--;
#ifdef PERLING
    d = strtod (start, & end);
#else
    strtod (start, & end);
#endif
    if ((unsigned char *) end == parser->end) {
	/* Success, strtod worked as planned. */
#ifdef PERLING
	return newSVnv (d);
#elif defined (TOKENING)
	return json_token_new (parser, (unsigned char *) start,
			       parser->end,
			       json_token_number);
#else
	return;
#endif
    }
    else {
	/* Failure, strtod rejected the number. */
	goto string_number_end;
    }

 int_number_end:

    parser->end--;
    if (parser->end - (unsigned char *) start < INT_MAX_DIGITS + minus) {
	if (minus) {
	    guess = -guess;
	}
	/*
	printf ("number debug: '%.*s': %d\n",
		parser->end - (unsigned char *) start, start, guess);
	*/
#ifdef PERLING
	return newSViv (guess);
#elif defined (TOKENING)
	return json_token_new (parser, (unsigned char *) start,
			       parser->end - 1, json_token_number);
#else
	return;
#endif
    }
    else {
	goto string_number_end;
    }

string_number_end:

    /* We could not convert this number using a number conversion
       routine, so we are going to convert it to a string.  This might
       happen with ridiculously long numbers or something. The JSON
       standard doesn't explicitly disallow integers with a million
       digits. */

#ifdef PERLING
    return newSVpv (start, (STRLEN) ((char *) parser->end - start));
#elif defined (TOKENING)
    return json_token_new (parser, (unsigned char *) start,
			   parser->end - 1, json_token_number);
#else
    return;
#endif
}

#ifdef PERLING

/* This copies our on-stack buffer "buffer" of size "size" into the
   end of a Perl SV called "string". */

#define COPYBUFFER {					\
	if (! string) {					\
	    string = newSVpvn ((char *) buffer, size);	\
	}						\
	else {						\
	    char * svbuf;				\
	    STRLEN cur = SvCUR (string);		\
	    if (SvLEN (string) <= cur + size) {		\
		SvGROW (string, cur + size);		\
	    }						\
	    svbuf = SvPVX (string);			\
	    memcpy (svbuf + cur, buffer, size);		\
	    SvCUR_set (string, cur + size);		\
	}						\
    }

/* The size of the on-stack buffer. */

#define BUFSIZE 0x1000

/* We need a safety margin when dealing with the buffer, for example
   if we hit a Unicode \uabcd escape which needs to be decoded, we
   need to have enough bytes to write into the buffer. */

#define MARGIN 0x10

/* Speedup hack, a special "get_string" for Perl parsing which doesn't
   use parser->buffer but its own buffer on the stack. */

static INLINE SV *
perl_get_string (json_parse_t * parser, STRLEN prefixlen)
{
    unsigned char * b;
    unsigned char c;
    unsigned char * start;
    unsigned char buffer[BUFSIZE];
    STRLEN size;
    SV * string;
    string = 0;
    start = parser->end;
    b = buffer;

    if (prefixlen > 0) {

	/* The string from parser->end to parser->end + prefixlen has
	   already been checked and found not to contain the end of
	   the string or any escapes, so we just copy the memory
	   straight into the buffer. This was supposed to speed things
	   up, but it didn't seem to. However this presumably cannot
	   hurt either. */

	if (prefixlen > BUFSIZE - MARGIN) {
	    /* This is to account for the very unlikely case that the
	       key of the JSON object is more than BUFSIZE - MARGIN
	       bytes long and has an escape after more than BUFSIZE -
	       MARGIN bytes. */
	    prefixlen = BUFSIZE - MARGIN;
	}

	memcpy (buffer, parser->end, prefixlen);
	start += prefixlen;
    }

 string_start:

    size = b - buffer;
    if (size >= BUFSIZE - MARGIN) {
	/* Spot-check for an overflow. */
	if (STRINGEND) {
	    STRINGFAIL (unexpected_end_of_input);
	}
	/* "string_start" is a label for a goto which is applied until
	   we get to the end of the string, so size keeps getting
	   larger and larger.  Now the string being parsed has proved
	   to be too big for our puny BUFSIZE buffer, so we copy the
	   contents of the buffer into the nice Perl scalar. */
	COPYBUFFER;
	/* Set the point of copying bytes back to the beginning of
	   buffer. We don't reset the memory in buffer. */
	b = buffer;
	size = b - buffer;
    }
    NEXTBYTE;

    /* "if" statements seem to compile to something marginally faster
       than "switch" statements, for some reason. */

    if (c < 0x20) {
	ILLEGALBYTE;
    }
    else if (c >= 0x20 && c <= 0x80) {
	/* For some reason or another, putting the following "if"
	   statements after the above one results in about 4% faster
	   code than putting them before it. */
	if (c == '"') {
	    goto string_end;
	}
	if (c == '\\') {
	    HANDLE_ESCAPES (parser->end, start - 1);
	    goto string_start;
	}
	* b++ = c;
	goto string_start;
    }
    else {

	/* Resort to switch statements for the UTF-8 stuff. This
	   actually also contains statements to handle ASCII but they
	   will never be executed. */

	switch (c) {
#define ADDBYTE * b = c; b++
#define startofutf8string start
#include "utf8-byte-one.c"

	default:

	    /* We have to give up, this byte is too mysterious for our
	       weak minds. */

	    ILLEGALBYTE;
	}
    }

 string_end:

    if (STRINGEND) {
	STRINGFAIL (unexpected_end_of_input);
    }

    COPYBUFFER;
    return string;

/* The rest of the UTF-8 stuff goes in here. */

#include "utf8-next-byte.c"
#undef ADDBYTE

    goto string_end;
}

#endif /* PERLING */

static SVPTR
PREFIX (string) (json_parse_t * parser)
{
    unsigned char c;
#ifdef PERLING
    SV * string;
    STRLEN len;
    STRLEN prefixlen;
#elif defined (TOKENING)
    json_token_t * string;
    int len;
#else
    int len;
#endif

    unsigned char * start;

    start = parser->end;
    len = 0;

    /* First of all, we examine the string to work out how long it is
       and to look for escapes. If we find them, we go to "contains_escapes"
       and go back and do all the hard work of converting the escapes
       into the right things. If we don't find any escapes, we just
       use "start" and "len" and copy the string from inside
       "input". This is a trick to increase the speed of
       processing. */

 string_start:
    switch (NEXTBYTE) {
    case '"':
	goto string_end;
    case '\\':
	goto contains_escapes;

#define ADDBYTE len++
#include "utf8-byte-one.c"

	/* Not a fall through. */
    case BADBYTES:
	ILLEGALBYTE;
    }
    /* Parsing of the string ended due to a \0 byte flipping the
       "while" switch and we dropped into this section before
       reaching the string's end. */
    ILLEGALBYTE;

#include "utf8-next-byte.c"
#undef ADDBYTE

 string_end:

#ifdef PERLING

    /* Our string didn't contain any escape sequences, so we can just
       make a new SV * by copying the string from "start", the old
       position within the thing we're parsing to start + len. */

    string = newSVpvn ((char *) start, len);

#elif defined (TOKENING)

    string = json_token_new (parser, start - 1,
			     start + len,
			     json_token_string);

#endif

    goto string_done;

 contains_escapes:

#ifdef PERLING

    /* Use "perl_get_string" which keeps the buffer on the
       stack. Results in a minor speed increase. */
    parser->end = start;
    prefixlen = (STRLEN) (parser->end - start);
    string = perl_get_string (parser, prefixlen);

#elif defined (TOKENING)
    /* Don't use "len" here since it subtracts the escapes. */
    parser->end = start;
    len = get_string (parser);
    string = json_token_new (parser,
			     /* Location of first quote. */
			     start - 1,
			     /* Location of last quote. */
			     parser->end,
			     json_token_string);
#else
    parser->end = start;
    len = get_string (parser);
#endif

 string_done:

#ifdef PERLING
    if (parser->unicode || parser->force_unicode || parser->upgrade_utf8) {
	SvUTF8_on (string);
	parser->force_unicode = 0;
    }
#endif

#if defined (PERLING) || defined (TOKENING)
    return string;
#else
    return;
#endif
}

#define FAILLITERAL(c)					\
    parser->expected = XIN_LITERAL;			\
    parser->literal_char = c;				\
    parser->bad_beginning = start;			\
    parser->error = json_error_unexpected_character;	\
    parser->bad_type = json_literal;			\
    parser->bad_byte = parser->end - 1;			\
    failbadinput (parser)

static SVPTR
PREFIX (literal_true) (json_parse_t * parser)
{
    unsigned char * start;
    start = parser->end - 1;
    if (* parser->end++ == 'r') {
	if (* parser->end++ == 'u') {
	    if (* parser->end++ == 'e') {
#ifdef PERLING
		if (parser->user_true) {
		    return newSVsv (parser->user_true);
		}
		else if (parser->copy_literals) {
		    return newSVsv (&PL_sv_yes);
		}
		else {
		    return &PL_sv_yes;
		}
#elif defined (TOKENING)
		return json_token_new (parser, start, parser->end - 1,
				       json_token_literal);
#else
		return;
#endif
	    }
	    FAILLITERAL ('e');
	}
	FAILLITERAL ('u');
    }
    FAILLITERAL ('r');
}

static SVPTR
PREFIX (literal_false) (json_parse_t * parser)
{
    unsigned char * start;
    start = parser->end - 1;
    if (* parser->end++ == 'a') {
	if (* parser->end++ == 'l') {
	    if (* parser->end++ == 's') {
		if (* parser->end++ == 'e') {
#ifdef PERLING
		if (parser->user_false) {
		    return newSVsv (parser->user_false);
		}
		else if (parser->copy_literals) {
		    return newSVsv (&PL_sv_no);
		}
		else {
		    return &PL_sv_no;
		}
#elif defined (TOKENING)
		return json_token_new (parser, start, parser->end - 1,
				       json_token_literal);
#else
		return;
#endif
		}
		FAILLITERAL ('e');
	    }
	    FAILLITERAL ('s');
	}
	FAILLITERAL ('l');
    }
    FAILLITERAL ('a');
}

static SVPTR
PREFIX (literal_null) (json_parse_t * parser)
{
    unsigned char * start;
    start = parser->end - 1;
    if (* parser->end++ == 'u') {
	if (* parser->end++ == 'l') {
	    if (* parser->end++ == 'l') {
#ifdef PERLING
		if (parser->user_null) {
		    return newSVsv (parser->user_null);
		}
		else if (parser->copy_literals) {
		    return newSVsv (&PL_sv_undef);
		}
		else {
		    SvREFCNT_inc (json_null);
		    return json_null;
		}
#elif defined (TOKENING)
		return json_token_new (parser, start, parser-> end - 1,
				       json_token_literal);
#else
		return;
#endif
	    }
	    FAILLITERAL ('l');
	}
	FAILLITERAL ('l');
    }
    FAILLITERAL ('u');
}

static SVPTR PREFIX (object) (json_parse_t * parser);

/* Given one character, decide what to do next. This goes in the
   switch statement in both "object ()" and "array ()". */

#define PARSE(start,expected)			\
						\
 case WHITESPACE:				\
 goto start;					\
						\
 case '"':					\
 SETVALUE PREFIX (string) (parser);		\
 break;						\
						\
 case '-':					\
 case DIGIT:					\
 parser->end_expected = expected;	        \
 SETVALUE PREFIX (number) (parser);		\
 break;						\
						\
 case '{':					\
 INCDEPTH;					\
 SETVALUE PREFIX (object) (parser);		\
 break;						\
						\
 case '[':					\
 INCDEPTH;					\
 SETVALUE PREFIX (array) (parser);		\
 break;						\
						\
 case 'f':					\
 SETVALUE PREFIX (literal_false) (parser);	\
 break;			                        \
						\
 case 'n':					\
 SETVALUE PREFIX (literal_null) (parser);	\
 break;			                        \
						\
 case 't':					\
 SETVALUE PREFIX (literal_true) (parser);	\
 break

#define FAILARRAY(err)				\
    parser->bad_byte = parser->end - 1;		\
    parser->bad_type = json_array;		\
    parser->bad_beginning = start;		\
    parser->error = json_error_ ## err;		\
    failbadinput (parser)

/* We have seen "[", so now deal with the contents of an array. At the
   end of this routine, "parser->end" is pointing one beyond the final
   "]" of the array. */

static SVPTR
PREFIX (array) (json_parse_t * parser)
{
    unsigned char c;
    unsigned char * start;
#ifdef PERLING
    AV * av;
    SV * value = & PL_sv_undef;
#elif defined (TOKENING)
    json_token_t * av;
    json_token_t * prev;
    json_token_t * value;
#endif

    start = parser->end - 1;
#ifdef PERLING
    av = newAV ();
#elif defined (TOKENING)
    av = json_token_new (parser, start, 0, json_token_array);
    prev = 0;
#endif

 array_start:

    switch (NEXTBYTE) {

	PARSE (array_start, XARRAY_END);

    case ']':
	goto array_end;

    default:
	parser->expected = VALUE_START | XWHITESPACE | XARRAY_END;
	FAILARRAY (unexpected_character);
    }

#ifdef PERLING
    av_push (av, value);
#elif defined (TOKENING)
    prev = json_token_set_child (parser, av, value);
#endif

    /* Accept either a comma or whitespace or the end of the array. */

 array_middle:

    switch (NEXTBYTE) {

    case WHITESPACE:
	goto array_middle;

    case ',':
#ifdef TOKENING
	value = json_token_new (parser, parser->end - 1,
				parser->end - 1,
				json_token_comma);
	prev = json_token_set_next (prev, value);
#endif
	goto array_next;

    case ']':
	/* Array with at least one element. */
	goto array_end;

    default:

	parser->expected = XWHITESPACE | XCOMMA | XARRAY_END;
	FAILARRAY (unexpected_character);
    }

 array_next:

    switch (NEXTBYTE) {

	PARSE (array_next, XARRAY_END);

    default:
	parser->expected = VALUE_START | XWHITESPACE;
	FAILARRAY (unexpected_character);
    }

#ifdef PERLING
    av_push (av, value);
#elif defined (TOKENING)
    prev = json_token_set_next (prev, value);
#endif

    goto array_middle;

 array_end:
    DECDEPTH;

#ifdef PERLING
    return newRV_noinc ((SV *) av);
#elif defined (TOKENING)
    /* We didn't know where the end was until now. */
    json_token_set_end (parser, av, parser->end - 1);
    return av;
#else
    return;
#endif
}

#define FAILOBJECT(err)				\
    parser->bad_byte = parser->end - 1;		\
    parser->bad_type = json_object;		\
    parser->bad_beginning = start;		\
    parser->error = json_error_ ## err;		\
    failbadinput (parser)

/* We have seen "{", so now deal with the contents of an object. At
   the end of this routine, "parser->end" is pointing one beyond the
   final "}" of the object. */

static SVPTR
PREFIX (object) (json_parse_t * parser)
{
    char c;
#ifdef PERLING
    HV * hv;
    SV * value;
    /* This is set to -1 if we want a Unicode key. See "perldoc
       perlapi" under "hv_store". */
    int uniflag;
#elif defined (TOKENING)
    json_token_t * hv;
    json_token_t * value;
    json_token_t * prev;
#endif
    string_t key;
    /* Start of parsing. */
    unsigned char * start;

    start = parser->end - 1;

#ifdef PERLING
    if (parser->unicode || parser->upgrade_utf8) {
	/* Keys are unicode. */
	uniflag = -1;
    }
    else {
	/* Keys are not unicode. */
	uniflag = 1;
    }
    hv = newHV ();
#elif defined (TOKENING)
    hv = json_token_new (parser, start, 0, json_token_object);
    prev = 0;
#endif

 hash_start:

    switch (NEXTBYTE) {
    case WHITESPACE:
	goto hash_start;
    case '}':
	goto hash_end;
    case '"':
#ifdef TOKENING
	value = json_token_new (parser, parser->end - 1, 0,
				json_token_string);
	/* We only come past the label "hash_start" once, so we don't
	   need to check that there is not already a child. */
	json_token_set_child (parser, hv, value);
	prev = value;
#endif
	get_key_string (parser, & key);
#ifdef TOKENING
	/* We didn't know where the end of the string was until now so
	   we wait until after "get_key_string" to set the end. */
	json_token_set_end (parser, value, parser->end - 1);
#endif
	goto hash_next;
    default:
	parser->expected = XWHITESPACE | XSTRING_START | XOBJECT_END;
	FAILOBJECT (unexpected_character);
    }

 hash_middle:

    /* We are in the middle of a hash. We have seen a key:value pair,
       and now we're looking for either a comma and then another
       key-value pair, or a closing curly brace and the end of the
       hash. */

    switch (NEXTBYTE) {
    case WHITESPACE:
	goto hash_middle;
    case '}':
	goto hash_end;
    case ',':
#ifdef TOKENING
	value = json_token_new (parser, parser->end - 1,
				parser->end - 1,
				json_token_comma);
	prev = json_token_set_next (prev, value);
#endif
	goto hash_key;
    default:
	parser->expected = XWHITESPACE | XCOMMA | XOBJECT_END;
	FAILOBJECT (unexpected_character);
    }

 hash_key:

    /* We're looking for a key in the hash, which is a string starting
       with a double quotation mark. */

    switch (NEXTBYTE) {
    case WHITESPACE:
	goto hash_key;
    case '"':
#ifdef TOKENING
	value = json_token_new (parser, parser->end - 1, 0,
				json_token_string);
	prev = json_token_set_next (prev, value);
#endif
	get_key_string (parser, & key);
#ifdef TOKENING
	/* We didn't know where the end of the string was until now so
	   we wait until after "get_key_string" to set the end. */
	json_token_set_end (parser, value, parser->end - 1);
#endif
	goto hash_next;
    default:
	parser->expected = XWHITESPACE | XSTRING_START;
	FAILOBJECT (unexpected_character);
    }

 hash_next:

    /* We've seen a key, now we're looking for a colon. */

    switch (NEXTBYTE) {
    case WHITESPACE:
	goto hash_next;
    case ':':
#ifdef TOKENING
	value = json_token_new (parser, parser->end - 1,
				parser->end - 1,
				json_token_colon);
	prev = json_token_set_next (prev, value);
#endif
	goto hash_value;
    default:
	parser->expected = XWHITESPACE | XVALUE_SEPARATOR;
	FAILOBJECT (unexpected_character);
    }

 hash_value:

    /* We've seen a colon, now we're looking for a value, which can be
       anything at all, including another hash. Most of the cases are
       dealt with in the PARSE macro. */

    switch (NEXTBYTE) {
	PARSE (hash_value, XOBJECT_END);
    default:
	parser->expected = XWHITESPACE | VALUE_START;
	FAILOBJECT (unexpected_character);
    }

    if (key.contains_escapes) {

	/* The key had something like "\n" in it, so we can't just
	   copy the value but have to process it to remove the
	   escapes. */

#ifdef PERLING
	int klen;
	klen = resolve_string (parser, & key);
	key.start = parser->buffer;
	key.length = klen;
#else
	resolve_string (parser, & key);
#endif
    }
#ifdef PERLING
    if (parser->detect_collisions) {
	/* Look in hv for an existing key with our values. */
	SV ** sv_ptr;
	sv_ptr = hv_fetch (hv, (char *) key.start, key.length * uniflag, 0);
	if (sv_ptr) {
	    parser->bad_byte = key.start;
	    parser->bad_length = key.length;
	    parser->bad_type = json_object;
	    parser->bad_beginning = start;
	    parser->error = json_error_name_is_not_unique;
	    failbadinput (parser);
	}
    }
    (void) hv_store (hv, (char *) key.start, key.length * uniflag, value, 0);
#endif

#if defined(TOKENING)
    prev = json_token_set_next (prev, value);
#endif
    goto hash_middle;

 hash_end:
    DECDEPTH;

#ifdef PERLING
    return newRV_noinc ((SV *) hv);
#elif defined (TOKENING)
    json_token_set_end (parser, hv, parser->end - 1);
    return hv;
#else
    return;
#endif
}

#undef PREFIX
#undef SVPTR
#undef SETVALUE

#ifdef PERLING

/* Set and delete user-defined literals. */

static void
json_parse_delete_true (json_parse_t * parser)
{
    if (parser->user_true) {
	SvREFCNT_dec (parser->user_true);
	parser->user_true = 0;
    }
}

static void
json_parse_set_true (json_parse_t * parser, SV * user_true)
{
    json_parse_delete_true (parser);
    if (! SvTRUE (user_true) && ! parser->no_warn_literals) {
	warn ("User-defined value for JSON true evaluates as false");
    }
    if (parser->copy_literals && ! parser->no_warn_literals) {
	warn ("User-defined value overrules copy_literals");
    }
    parser->user_true = user_true;
    SvREFCNT_inc (user_true);
}

static void
json_parse_delete_false (json_parse_t * parser)
{
    if (parser->user_false) {
	SvREFCNT_dec (parser->user_false);
	parser->user_false = 0;
    }
}

static void
json_parse_set_false (json_parse_t * parser, SV * user_false)
{
    json_parse_delete_false (parser);
    if (SvTRUE (user_false) && ! parser->no_warn_literals) {
	warn ("User-defined value for JSON false evaluates as true");
    }
    if (parser->copy_literals && ! parser->no_warn_literals) {
	warn ("User-defined value overrules copy_literals");
    }
    parser->user_false = user_false;
    SvREFCNT_inc (user_false);
}

static void
json_parse_delete_null (json_parse_t * parser)
{
    if (parser->user_null) {
	SvREFCNT_dec (parser->user_null);
	parser->user_null = 0;
    }
}

static void
json_parse_set_null (json_parse_t * parser, SV * user_null)
{
    if (parser->copy_literals && ! parser->no_warn_literals) {
	warn ("User-defined value overrules copy_literals");
    }
    json_parse_delete_null (parser);
    parser->user_null = user_null;
    SvREFCNT_inc (user_null);
}

static void
json_parse_free (json_parse_t * parser)
{
    /* We can get here with depth > 0 if the parser fails and then the
       error is caught. */
    if (parser->depth < 0) {
	warn ("Parser depth underflow %d", parser->depth);
    }
    json_parse_delete_true (parser);
    json_parse_delete_false (parser);
    json_parse_delete_null (parser);
    Safefree (parser);
}

static void
json_parse_copy_literals (json_parse_t * parser, SV * onoff)
{
    if (! parser->no_warn_literals &&
	(parser->user_true || parser->user_false || parser->user_null)) {
	warn ("User-defined value overrules copy_literals");
    }
    parser->copy_literals = SvTRUE (onoff) ? 1 : 0;
}

#endif /* def PERLING */
