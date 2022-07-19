/* Empty input was provided. */

static void fail_empty (json_parse_t * parser)
{
    parser->bad_type = json_initial_state;
    parser->expected = 0;
    parser->error = json_error_empty_input;
    failbadinput (parser);
}

/* Check for stray non-whitespace after the end and free memory. */

static void check_end (json_parse_t * parser)
{
    int c;
 end:
    switch (NEXTBYTE) {

    case WHITESPACE:
	goto end;

    case '\0':
	parser_free (parser);
	return;

    default:
	parser->bad_type = json_initial_state;
	parser->bad_byte = parser->end - 1;
	parser->expected = XWHITESPACE;
	parser->error = json_error_unexpected_character;
	failbadinput (parser);
    }
}

#define ENTRYDECL				\
    /* Our collection of bits and pieces. */	\
						\
    json_parse_t parser_o = {0};		\
    json_parse_t * parser = & parser_o;		\
    json_parse_init (parser)

#ifndef NOPERL

/* Set up "parser" with the string from "json". */

static void getstring (SV * json, json_parse_t * parser)
{
    STRLEN length;
    parser->input = (unsigned char *) SvPV (json, length);
    parser->end = parser->input;
    parser->length = (unsigned int) length;
    parser->unicode = SvUTF8 (json) ? 1 : 0;
}

#endif /* ndef NOPERL */

#define SETUPPARSER							\
    parser->line = 1;							\
    parser->last_byte = parser->input + parser->length

/* Error to throw if there is a character other than whitespace, "["
   or "{" at the start of the JSON. */

#define BADCHAR								\
    parser->bad_byte = parser->end - 1;					\
    parser->bad_type = json_initial_state;				\
    parser->expected = XARRAYOBJECTSTART | VALUE_START | XWHITESPACE;	\
    parser->error = json_error_unexpected_character;			\
    failbadinput (parser)

#ifndef NOPERL

static SV *
json_parse_run (json_parse_t * parser, SV * json)
{
    /* The currently-parsed character. */	
						
    char c;					
						
    /* The returned object. */

    SV * r = & PL_sv_undef;

    getstring (json, parser);

    if (parser->length == 0) {
	fail_empty (parser);
    }

    SETUPPARSER;

 parse_start:

    switch (NEXTBYTE) {

    case '{':
	INCDEPTH;
	r = object (parser);
	break;

    case '[':
	INCDEPTH;
	r = array (parser);
	break;

    case '-':
    case '0':
    case DIGIT19:
	parser->top_level_value = 1;
	r = number (parser);
	break;

    case '"':
	parser->top_level_value = 1;
	r = string (parser);
	break;

    case 't':
	parser->top_level_value = 1;
	r = literal_true (parser);
	break;

    case 'f':
	parser->top_level_value = 1;
	r = literal_false (parser);
	break;

    case 'n':
	parser->top_level_value = 1;
	r = literal_null (parser);
	break;

    case WHITESPACE:
	goto parse_start;

    case '\0':

	/* We have an empty string. */

	fail_empty (parser);

    default:
	BADCHAR;
    }

    check_end (parser);

    return r;
}

/* This is the entry point for non-object parsing. */

SV *
parse (SV * json)
{
    /* Make our own parser object on the stack. */
    ENTRYDECL;
    /* Run it. */
    return json_parse_run (parser, json);
}


/* This is the entry point for "safe" non-object parsing. */

SV *
parse_safe (SV * json)
{
    /* Make our own parser object on the stack. */
    ENTRYDECL;
    parser_o.detect_collisions = 1;
    parser_o.copy_literals = 1;
    parser_o.warn_only = 1;
    parser_o.diagnostics_hash = 1;
    /* Run it. */
    return json_parse_run (parser, json);
}


#endif /* ndef NOPERL */

/* Validation without Perl structures. */

static void
c_validate (json_parse_t * parser)
{
    /* The currently-parsed character. */	
						
    char c;					

    /* If the string is empty, throw an exception. */

    if (parser->length == 0) {
	fail_empty (parser);
    }

    SETUPPARSER;

 validate_start:

    switch (NEXTBYTE) {

    case '{':
	INCDEPTH;
	valid_object (parser);
	break;

    case '[':
	INCDEPTH;
	valid_array (parser);
	break;

    case '-':
    case '0':
    case DIGIT19:
	parser->top_level_value = 1;
	valid_number (parser);
	break;

    case '"':
	parser->top_level_value = 1;
	valid_string (parser);
	break;

    case 't':
	parser->top_level_value = 1;
	valid_literal_true (parser);
	break;

    case 'f':
	parser->top_level_value = 1;
	valid_literal_false (parser);
	break;

    case 'n':
	parser->top_level_value = 1;
	valid_literal_null (parser);
	break;

    case WHITESPACE:
	goto validate_start;

    default:
	BADCHAR;
    }

    check_end (parser);
}

static INLINE void
print_tokens (json_token_t * t)
{
    printf ("Start: %d End: %d: Type: %s\n", t->start, t->end,
	    token_names[t->type]);
    if (t->child) {
	printf ("Children:\n");
	print_tokens (t->child);
    }
    if (t->next) {
	printf ("Next:\n");
	print_tokens (t->next);
    }
}

#ifndef NOPERL

static json_token_t *
c_tokenize (json_parse_t * parser)
{
    /* The currently-parsed character. */	
						
    char c;					
    json_token_t * r;

    SETUPPARSER;

 tokenize_start:

    switch (NEXTBYTE) {

    case '{':
	r = tokenize_object (parser);
	break;

    case '[':
	r = tokenize_array (parser);
	break;

    case WHITESPACE:
	goto tokenize_start;

    default:
	BADCHAR;
    }

    check_end (parser);
    return r;
}

static void
tokenize_free (json_token_t * token)
{
    json_token_t * next;
    next = token->child;
    if (next) {
	if (! next->blessed) {
	    tokenize_free (next);
	}
	token->child = 0;
    }
    next = token->next;
    if (next) {
	if (! next->blessed) {
	    tokenize_free (next);
	}
	token->next = 0;
    }
    if (! token->blessed) {
	Safefree (token);
    }
}

/* This is the entry point for validation. */

static void
validate (SV * json, unsigned int flags)
{
    ENTRYDECL;

    getstring (json, parser);

    if (parser->length == 0) {
	fail_empty (parser);
    }
    c_validate (& parser_o);
}

static void
check (json_parse_t * parser, SV * json)
{
    getstring (json, parser);
    c_validate (parser);
}

static json_token_t *
tokenize (SV * json)
{
    ENTRYDECL;

    getstring (json, parser);

    /* Mark this parser as being used for tokenizing to bypass the
       checks for memory leaks when the parser is freed. */

    parser_o.tokenizing = 1;

    return c_tokenize (& parser_o);
}

/* Make a hash containing a diagnostic error from the parser. */

static SV * error_to_hash (json_parse_t * parser, char * error_as_string)
{
    HV * error;
    error = newHV ();

#ifdef HK
#warn "Redefinition of macro HK"
#endif /* def HK */
#undef HK
#define HK(x, val) (void) hv_store (error, x, strlen (x), val, 0)

    HK("length", newSViv (parser->length));
    HK("bad type", newSVpv (type_names[parser->bad_type], 0));
    HK("error", newSVpv (json_errors[parser->error], 0));
    HK("error as string", newSVpv (error_as_string, 0));
    if (parser->bad_byte) {
	int position;
	position = (int) (parser->bad_byte - parser->input) + 1;
	HK("bad byte position", newSViv (position));
	HK("bad byte contents", newSViv (* parser->bad_byte));
    }
    if (parser->bad_beginning) {
	int bcstart;
	bcstart = (int) (parser->bad_beginning - parser->input) + 1;
	HK("start of broken component", newSViv (bcstart));
    }
    if (parser->error == json_error_unexpected_character) {
	int j;
	AV * valid_bytes;
	valid_bytes = newAV ();
	make_valid_bytes (parser);
	for (j = 0; j < JSON3MAXBYTE; j++) {
	    av_push (valid_bytes, newSViv (parser->valid_bytes[j]));
	}
	HK("valid bytes", newRV_inc ((SV *) valid_bytes));
    }
    return newRV_inc ((SV *) error);

#undef HK
}

#endif /* ndef NOPERL */

