/* XS part of JSON::Create. */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <stdint.h>
#include "unicode.h"
#include "qsort-r.c"
#include "json-create-perl.c"

#define PERLJCCALL(x) {					\
	json_create_status_t jcs;			\
	jcs = x;					\
	if (jcs != json_create_ok) {			\
	    warn ("%s:%d: bad status %d from %s",	\
		  __FILE__, __LINE__, jcs, #x);		\
	}						\
    }

typedef json_create_t * JSON__Create;

#define JCSET						\
    if (items > 1) {					\
	if ((items - 1) % 2 != 0) {			\
	    warn ("odd number of arguments ignored");	\
	}						\
	else {						\
	    int i;					\
	    for (i = 1; i < items; i += 2) {		\
		json_create_set (jc, ST(i), ST(i+1));	\
	    }						\
	}						\
    }


MODULE=JSON::Create PACKAGE=JSON::Create

PROTOTYPES: DISABLE

SV *
create_json (input, ...)
	SV * input;
PREINIT:
	json_create_t jc_stack = {0};
	json_create_t * jc = & jc_stack;
CODE:
	JCSET;
	RETVAL = json_create_create (jc, input);
OUTPUT:
	RETVAL

SV *
create_json_strict (input, ...)
	SV * input;
PREINIT:
	json_create_t jc_stack = {0};
	json_create_t * jc = & jc_stack;
CODE:
	JCSET;
	jc_stack.strict = 1;
	RETVAL = json_create_create (jc, input);
OUTPUT:
	RETVAL

void
DESTROY (jc)
	JSON::Create jc;
CODE:
	PERLJCCALL (json_create_free (jc));

JSON::Create
jcnew ()
CODE:
	PERLJCCALL (json_create_new (& RETVAL));
OUTPUT:
	RETVAL

SV *
create (jc, input)
	JSON::Create jc;
	SV * input
CODE:
	RETVAL = json_create_create (jc, input);
OUTPUT:
	RETVAL

void
sort (jc, onoff)
	JSON::Create jc;
	SV * onoff;
CODE:
#ifdef INDENT
	jc->sort = SvTRUE (onoff) ? 1 : 0;
#endif

void
cmp (jc, cmp)
	JSON::Create jc;
	SV * cmp;
CODE:
	PERLJCCALL (json_create_remove_cmp (jc));
	if (SvTRUE (cmp)) {
	    jc->cmp = cmp;
	    SvREFCNT_inc (cmp);
	    jc->n_mallocs++;
	}

void
set_fformat_unsafe (jc, fformat)
	JSON::Create jc;
	SV * fformat;
CODE:
	PERLJCCALL (json_create_set_fformat (jc, fformat));
OUTPUT:

void
escape_slash (jc, onoff)
	JSON::Create jc;
	SV * onoff;
CODE:
	jc->escape_slash = SvTRUE (onoff) ? 1 : 0;

void
unicode_upper (jc, onoff)
	JSON::Create jc;
	SV * onoff;
CODE:
	jc->unicode_upper = SvTRUE (onoff) ? 1 : 0;

void
unicode_escape_all (jc, onoff)
	JSON::Create jc;
	SV * onoff;
CODE:
	jc->unicode_escape_all = SvTRUE (onoff) ? 1 : 0;

void
set_validate (jc, onoff)
	JSON::Create jc;
	SV * onoff;
CODE:
	jc->validate = SvTRUE (onoff) ? 1 : 0;

void
no_javascript_safe (jc, onoff)
	JSON::Create jc;
	SV * onoff;
CODE:
	jc->no_javascript_safe = SvTRUE (onoff) ? 1 : 0;

void
fatal_errors (jc, onoff)
	JSON::Create jc;
	SV * onoff;
CODE:
	jc->fatal_errors = SvTRUE (onoff) ? 1 : 0;

void
replace_bad_utf8 (jc, onoff)
	JSON::Create jc;
	SV * onoff;
CODE:
	jc->replace_bad_utf8 = SvTRUE (onoff) ? 1 : 0;

void
downgrade_utf8 (jc, onoff)
	JSON::Create jc;
	SV * onoff;
CODE:
	jc->downgrade_utf8 = SvTRUE (onoff) ? 1 : 0;

void
strict (jc, onoff)
	JSON::Create jc;
	SV * onoff;
CODE:
	jc->strict = SvTRUE (onoff) ? 1 : 0;

void
indent (jc, onoff)
	JSON::Create jc;
	SV * onoff;
CODE:
#ifdef INDENT
	jc->indent = SvTRUE (onoff) ? 1 : 0;
#endif

HV *
get_handlers (jc)
	JSON::Create jc
CODE:
	if (! jc->handlers) {
		jc->handlers = newHV();
		jc->n_mallocs++;
	}
	RETVAL = jc->handlers;
OUTPUT:
	RETVAL

void
obj_handler (jc, oh = & PL_sv_undef)
	JSON::Create jc;
	SV * oh;
CODE:
	/* Remove a previous ref handler, if it exists. */
	PERLJCCALL (json_create_remove_obj_handler (jc));
	if (SvTRUE (oh)) {
		set_object_handler (jc, oh);
	}

void
non_finite_handler (jc, oh = & PL_sv_undef)
	JSON::Create jc;
	SV * oh;
CODE:
	/* Remove a previous ref handler, if it exists. */
	PERLJCCALL (json_create_remove_non_finite_handler (jc));
	if (SvTRUE (oh)) {
		set_non_finite_handler (jc, oh);
	}

void
set (jc, ...)
	JSON::Create jc;
CODE:
	JCSET;

void
set_handlers (jc, handlers)
	JSON::Create jc
	HV * handlers
CODE:
        PERLJCCALL (json_create_remove_handlers (jc));
	SvREFCNT_inc ((SV*) handlers);
	jc->n_mallocs++;
	jc->handlers = handlers;

void
type_handler (jc, crh = & PL_sv_undef)
	JSON::Create jc;
	SV * crh;
CODE:
	/* Remove a previous ref handler, if it exists. */
	PERLJCCALL (json_create_remove_type_handler (jc));
	if (SvTRUE (crh)) {
		set_type_handler (jc, crh);
	}

