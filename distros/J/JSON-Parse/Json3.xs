#include "EXTERN.h"
#include "perl.h"
#include <stdint.h>
#include "XSUB.h"

/* TESTRANDOM should never be defined in the code released to
   CPAN. That this is not defined is tested in
   "xt/testrandom-invalid.t". */

//#define TESTRANDOM

#ifdef TESTRANDOM
#include <setjmp.h>
#endif /* def TESTRANDOM */

/* A structure representing the "null" in JSON. Although we're now
   using PL_sv_yes and PL_sv_no, we don't use PL_sv_undef, because
   perldoc perlguts says it's a bad idea. */

static SV * json_null;

/* Code starts here. */

#include "unicode.h"
#include "unicode.c"
#include "json-common.c"
#define PERLING
#include "json-perl.c"
#undef PERLING
#define TOKENING
#include "json-perl.c"
#undef TOKENING
#include "json-perl.c"
#include "json-entry-points.c"
#ifdef TESTRANDOM
#include "json-random-test.c"
#endif /* def TESTRANDOM */
#include "json-whitespace.c"
#ifdef NOPERL
#error "Cannot define NOPERL error when compiling Perl version"
#endif /* def NOPERL */

typedef json_parse_t * JSON__Parse;
typedef json_token_t * JSON__Tokenize;

MODULE=JSON::Parse PACKAGE=JSON::Parse

PROTOTYPES: DISABLE
BOOT:
{
       json_null = get_sv ("JSON::Parse::null", GV_ADD);
       SvREADONLY_on (json_null);
}

SV * parse_json (json)
	SV * json;
CODE:
	RETVAL = parse (json);
OUTPUT:
	RETVAL

SV * parse_json_safer (json)
	SV * json;
CODE:
	RETVAL = parse_safe (json);
OUTPUT:
	RETVAL

void assert_valid_json (json)
	SV * json;
CODE:
	validate (json, 0);

JSON::Parse
new (char * class, ...)
CODE:
	if (! class) {
	    croak ("no class");
	}
	Newxz (RETVAL, 1, json_parse_t);
	json_parse_init (RETVAL);
OUTPUT:
	RETVAL

SV * run_internal (parser, json)
	JSON::Parse parser
	SV * json
CODE:
	RETVAL = json_parse_run (parser, json);
OUTPUT:
	RETVAL

void
check (parser, json)
	JSON::Parse parser
	SV * json
CODE:
	check (parser, json);

void
DESTROY (parser)
	JSON::Parse parser;
CODE:
	json_parse_free (parser);

void
set_true (parser, user_true)
	JSON::Parse parser;
	SV * user_true;
CODE:
	json_parse_set_true (parser, user_true);

void
set_false (parser, user_false)
	JSON::Parse parser;
	SV * user_false;
CODE:
	json_parse_set_false (parser, user_false);

void
set_null (parser, user_null)
	JSON::Parse parser;
	SV * user_null;
CODE:
	json_parse_set_null (parser, user_null);

void
delete_true (parser)
	JSON::Parse parser;
CODE:
	json_parse_delete_true (parser);

void
delete_false (parser)
	JSON::Parse parser;
CODE:
	json_parse_delete_false (parser);

void
delete_null (parser)
	JSON::Parse parser;
CODE:
	json_parse_delete_null (parser);

void
copy_literals (parser, onoff)
	JSON::Parse parser;
	SV * onoff;
CODE:
	json_parse_copy_literals (parser, onoff);

void
no_warn_literals (parser, onoff)
	JSON::Parse parser;
	SV * onoff;
CODE:
	parser->no_warn_literals = SvTRUE (onoff) ? 1 : 0;

void
diagnostics_hash (parser, onoff)
	JSON::Parse parser;
	SV * onoff;
CODE:
#if PERL_VERSION > 12
	parser->diagnostics_hash = SvTRUE (onoff) ? 1 : 0;
#else
        warn ("diagnostics_hash () requires Perl 5.14 or later; this is 5.%d",
	      PERL_VERSION);
#endif

void
warn_only (parser, onoff)
	JSON::Parse parser;
	SV * onoff;
CODE:
	parser->warn_only = SvTRUE (onoff) ? 1 : 0;

int
get_warn_only (parser)
	JSON::Parse parser;
CODE:
	if (parser->warn_only) {
		RETVAL = 1;
	}
	else {
		RETVAL = 0;
	}
OUTPUT:
	RETVAL


void
detect_collisions (parser, onoff)
	JSON::Parse parser;
	SV * onoff;
CODE:
	parser->detect_collisions = SvTRUE (onoff) ? 1 : 0;

void
set_max_depth (json, max_depth)
	JSON::Parse json;
	int max_depth;
CODE:
	if (max_depth < 0) {
		croak ("Invalid max depth %d", max_depth);
	}
	json->max_depth = max_depth;

int
get_max_depth (json)
	JSON::Parse json;
CODE:
	RETVAL = json->max_depth;
	if (json->max_depth == 0) {
		RETVAL = JSON_PARSE_DEFAULT_MAX_DEPTH;
	}
OUTPUT:
	RETVAL

#ifdef TESTRANDOM

int random_json ()
CODE:
	RETVAL = random_json ();
OUTPUT:
	RETVAL

#endif /* def TESTRANDOM */

MODULE=JSON::Parse PACKAGE=JSON::Tokenize

JSON::Tokenize tokenize_json (json)
	SV * json;
CODE:
	RETVAL = tokenize (json);
	RETVAL->blessed = 1;
OUTPUT:
	RETVAL

JSON::Tokenize tokenize_child (token)
 	JSON::Tokenize token
CODE:
	RETVAL = token;
	if (token->child) {
		RETVAL = token->child;
		RETVAL->blessed = 1;
	}
OUTPUT:
    	RETVAL

JSON::Tokenize tokenize_next (token)
	JSON::Tokenize token
CODE:
	if (token->next) {
		RETVAL = token->next;
		RETVAL->blessed = 1;
	}
	else {
       		RETVAL = 0;
	}
OUTPUT:
    	RETVAL

int tokenize_start (token)
	JSON::Tokenize token
CODE:
	RETVAL = token->start;
OUTPUT:
    	RETVAL

int tokenize_end (token)
	JSON::Tokenize token
CODE:
	RETVAL = token->end;
OUTPUT:
    	RETVAL

SV * tokenize_type (token)
	JSON::Tokenize token
CODE:
	/* Only set this to the real value if everything is OK. */
	RETVAL = & PL_sv_undef;
	if (token->type > json_token_invalid &&
	    token->type < n_json_tokens) {
		RETVAL = newSVpv (token_names[token->type], 0);
	}
	else {
		warn ("Invalid JSON token type %d", token->type);
	}
OUTPUT:
	RETVAL

void DESTROY (token)
	JSON::Tokenize token
CODE:
	tokenize_free (token);

MODULE=JSON::Parse PACKAGE=JSON::Whitespace

SV * strip_whitespace (tokens, json)
	JSON::Tokenize tokens;
	SV * json;
CODE:
	RETVAL = strip_whitespace (tokens, json);
OUTPUT:
	RETVAL

