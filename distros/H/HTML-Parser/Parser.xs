/*
 * Copyright 1999-2016, Gisle Aas.
 * Copyright 1999-2000, Michael A. Chase.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the same terms as Perl itself.
 */

#define PERL_NO_GET_CONTEXT     /* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#define DOWARN  (PL_dowarn & G_WARN_ON)
#define RETHROW croak(Nullch)

/*
 * Include stuff.  We include .c files instead of linking them,
 * so that they don't have to pollute the external dll name space.
 */

#ifdef EXTERN
  #undef EXTERN
#endif

#define EXTERN static /* Don't pollute */

#include "hparser.h"
#include "util.c"
#include "hparser.c"


/*
 * Support functions for the XS glue
 */

static SV*
check_handler(pTHX_ SV* h)
{
    SvGETMAGIC(h);
    if (SvROK(h)) {
	SV* myref = SvRV(h);
	if (SvTYPE(myref) == SVt_PVCV)
	    return newSVsv(h);
	if (SvTYPE(myref) == SVt_PVAV)
	    return SvREFCNT_inc(myref);
	croak("Only code or array references allowed as handler");
    }
    return SvOK(h) ? newSVsv(h) : 0;
}


static PSTATE*
get_pstate_iv(pTHX_ SV* sv)
{
    PSTATE *p;
    MAGIC *mg = SvMAGICAL(sv) ? mg_find(sv, '~') : NULL;

    if (!mg)
	croak("Lost parser state magic");
    p = (PSTATE *)mg->mg_ptr;
    if (!p)
	croak("Lost parser state magic");
    if (p->signature != P_SIGNATURE)
	croak("Bad signature in parser state object at %p", p);
    return p;
}


static PSTATE*
get_pstate_hv(pTHX_ SV* sv)                               /* used by XS typemap */
{
    HV* hv;
    SV** svp;

    sv = SvRV(sv);
    if (!sv || SvTYPE(sv) != SVt_PVHV)
	croak("Not a reference to a hash");
    hv = (HV*)sv;
    svp = hv_fetchs(hv, "_hparser_xs_state", 0);
    if (svp) {
	if (SvROK(*svp))
	    return get_pstate_iv(aTHX_ SvRV(*svp));
	else
	    croak("_hparser_xs_state element is not a reference");
    }
    croak("Can't find '_hparser_xs_state' element in HTML::Parser hash");
    return 0;
}


static void
free_pstate(pTHX_ PSTATE* pstate)
{
    int i;
    SvREFCNT_dec(pstate->buf);
    SvREFCNT_dec(pstate->pend_text);
    SvREFCNT_dec(pstate->skipped_text);
#ifdef MARKED_SECTION
    SvREFCNT_dec(pstate->ms_stack);
#endif
    SvREFCNT_dec(pstate->bool_attr_val);
    for (i = 0; i < EVENT_COUNT; i++) {
	SvREFCNT_dec(pstate->handlers[i].cb);
	SvREFCNT_dec(pstate->handlers[i].argspec);
    }

    SvREFCNT_dec(pstate->report_tags);
    SvREFCNT_dec(pstate->ignore_tags);
    SvREFCNT_dec(pstate->ignore_elements);
    SvREFCNT_dec(pstate->ignoring_element);

    SvREFCNT_dec(pstate->tmp);

    pstate->signature = 0;
    Safefree(pstate);
}

static int
magic_free_pstate(pTHX_ SV *sv, MAGIC *mg)
{
    free_pstate(aTHX_ (PSTATE *)mg->mg_ptr);
    return 0;
}

#if defined(USE_ITHREADS)

static PSTATE *
dup_pstate(pTHX_ PSTATE *pstate, CLONE_PARAMS *params)
{
    PSTATE *pstate2;
    int i;

    Newz(56, pstate2, 1, PSTATE);
    pstate2->signature = pstate->signature;

    pstate2->buf = SvREFCNT_inc(sv_dup(pstate->buf, params));
    pstate2->offset = pstate->offset;
    pstate2->line = pstate->line;
    pstate2->column = pstate->column;
    pstate2->start_document = pstate->start_document;
    pstate2->parsing = pstate->parsing;
    pstate2->eof = pstate->eof;

    pstate2->literal_mode = pstate->literal_mode;
    pstate2->is_cdata = pstate->is_cdata;
    pstate2->no_dash_dash_comment_end = pstate->no_dash_dash_comment_end;
    pstate2->pending_end_tag = pstate->pending_end_tag;

    pstate2->pend_text = SvREFCNT_inc(sv_dup(pstate->pend_text, params));
    pstate2->pend_text_is_cdata = pstate->pend_text_is_cdata;
    pstate2->pend_text_offset = pstate->pend_text_offset;
    pstate2->pend_text_line = pstate->pend_text_offset;
    pstate2->pend_text_column = pstate->pend_text_column;

    pstate2->skipped_text = SvREFCNT_inc(sv_dup(pstate->skipped_text, params));

#ifdef MARKED_SECTION
    pstate2->ms = pstate->ms;
    pstate2->ms_stack =
	(AV *)SvREFCNT_inc(sv_dup((SV *)pstate->ms_stack, params));
    pstate2->marked_sections = pstate->marked_sections;
#endif

    pstate2->strict_comment = pstate->strict_comment;
    pstate2->strict_names = pstate->strict_names;
    pstate2->strict_end = pstate->strict_end;
    pstate2->xml_mode = pstate->xml_mode;
    pstate2->unbroken_text = pstate->unbroken_text;
    pstate2->attr_encoded = pstate->attr_encoded;
    pstate2->case_sensitive = pstate->case_sensitive;
    pstate2->closing_plaintext = pstate->closing_plaintext;
    pstate2->utf8_mode = pstate->utf8_mode;
    pstate2->empty_element_tags = pstate->empty_element_tags;
    pstate2->xml_pic = pstate->xml_pic;
    pstate2->backquote = pstate->backquote;

    pstate2->bool_attr_val =
	SvREFCNT_inc(sv_dup(pstate->bool_attr_val, params));
    for (i = 0; i < EVENT_COUNT; i++) {
	pstate2->handlers[i].cb =
	    SvREFCNT_inc(sv_dup(pstate->handlers[i].cb, params));
	pstate2->handlers[i].argspec =
	    SvREFCNT_inc(sv_dup(pstate->handlers[i].argspec, params));
    }
    pstate2->argspec_entity_decode = pstate->argspec_entity_decode;

    pstate2->report_tags =
	(HV *)SvREFCNT_inc(sv_dup((SV *)pstate->report_tags, params));
    pstate2->ignore_tags =
	(HV *)SvREFCNT_inc(sv_dup((SV *)pstate->ignore_tags, params));
    pstate2->ignore_elements =
	(HV *)SvREFCNT_inc(sv_dup((SV *)pstate->ignore_elements, params));

    pstate2->ignoring_element =
	SvREFCNT_inc(sv_dup(pstate->ignoring_element, params));
    pstate2->ignore_depth = pstate->ignore_depth;

    if (params->flags & CLONEf_JOIN_IN) {
	pstate2->entity2char =
	    get_hv("HTML::Entities::entity2char", GV_ADD);
    } else {
	pstate2->entity2char = (HV *)sv_dup((SV *)pstate->entity2char, params);
    }
    pstate2->tmp = SvREFCNT_inc(sv_dup(pstate->tmp, params));

    return pstate2;
}

static int
magic_dup_pstate(pTHX_ MAGIC *mg, CLONE_PARAMS *params)
{
    mg->mg_ptr = (char *)dup_pstate(aTHX_ (PSTATE *)mg->mg_ptr, params);
    return 0;
}

#endif

const MGVTBL vtbl_pstate =
{
    0,
    0,
    0,
    0,
    MEMBER_TO_FPTR(magic_free_pstate),
#if defined(USE_ITHREADS)
    0,
    MEMBER_TO_FPTR(magic_dup_pstate),
#endif
};


/*
 *  XS interface definition.
 */

MODULE = HTML::Parser		PACKAGE = HTML::Parser

PROTOTYPES: DISABLE

void
_alloc_pstate(self)
	SV* self;
    PREINIT:
	PSTATE* pstate;
	SV* sv;
	HV* hv;
        MAGIC* mg;

    CODE:
	sv = SvRV(self);
        if (!sv || SvTYPE(sv) != SVt_PVHV)
            croak("Not a reference to a hash");
	hv = (HV*)sv;

	Newz(56, pstate, 1, PSTATE);
	pstate->signature = P_SIGNATURE;
	pstate->entity2char = get_hv("HTML::Entities::entity2char", GV_ADD);
	pstate->tmp = NEWSV(0, 20);

	sv = newSViv(PTR2IV(pstate));
	sv_magic(sv, 0, '~', (char *)pstate, 0);
	mg = mg_find(sv, '~');
        assert(mg);
        mg->mg_virtual = (MGVTBL*)&vtbl_pstate;
#if defined(USE_ITHREADS)
        mg->mg_flags |= MGf_DUP;
#endif
	SvREADONLY_on(sv);

	hv_stores(hv, "_hparser_xs_state", newRV_noinc(sv));

void
parse(self, chunk)
	SV* self;
	SV* chunk
    PREINIT:
	PSTATE* p_state = get_pstate_hv(aTHX_ self);
    PPCODE:
    (void)sv_2mortal(SvREFCNT_inc(SvRV(self)));
	if (p_state->parsing)
    	    croak("Parse loop not allowed");
        p_state->parsing = 1;
	if (SvROK(chunk) && SvTYPE(SvRV(chunk)) == SVt_PVCV) {
	    SV* generator = chunk;
	    STRLEN len;
	    do {
                int count;
		PUSHMARK(SP);
	        count = call_sv(generator, G_SCALAR|G_EVAL);
		SPAGAIN;
		chunk = count ? POPs : 0;
	        PUTBACK;

	        if (SvTRUE(ERRSV)) {
		    p_state->parsing = 0;
		    p_state->eof = 0;
		    RETHROW;
                }

		if (chunk && SvOK(chunk)) {
		    (void)SvPV(chunk, len);  /* get length */
		}
		else {
		    len = 0;
                }
		parse(aTHX_ p_state, len ? chunk : 0, self);
	        SPAGAIN;

            } while (len && !p_state->eof);
        }
	else {
	    parse(aTHX_ p_state, chunk, self);
            SPAGAIN;
        }
        p_state->parsing = 0;
	if (p_state->eof) {
	    p_state->eof = 0;
            PUSHs(sv_newmortal());
        }
	else {
	    PUSHs(self);
	}

void
eof(self)
    SV* self;
    PREINIT:
    PSTATE* p_state = get_pstate_hv(aTHX_ self);
    PPCODE:
        if (p_state->parsing)
            p_state->eof = 1;
        else {
            p_state->parsing = 1;
            parse(aTHX_ p_state, 0, self); /* flush */
            SPAGAIN;
            p_state->parsing = 0;
        }
        PUSHs(self);

SV*
strict_comment(pstate,...)
	PSTATE* pstate
    ALIAS:
	HTML::Parser::strict_comment = 1
	HTML::Parser::strict_names = 2
        HTML::Parser::xml_mode = 3
	HTML::Parser::unbroken_text = 4
        HTML::Parser::marked_sections = 5
        HTML::Parser::attr_encoded = 6
        HTML::Parser::case_sensitive = 7
	HTML::Parser::strict_end = 8
	HTML::Parser::closing_plaintext = 9
        HTML::Parser::utf8_mode = 10
        HTML::Parser::empty_element_tags = 11
        HTML::Parser::xml_pic = 12
	HTML::Parser::backquote = 13
    PREINIT:
	bool *attr;
    CODE:
        switch (ix) {
	case  1: attr = &pstate->strict_comment;       break;
	case  2: attr = &pstate->strict_names;         break;
	case  3: attr = &pstate->xml_mode;             break;
	case  4: attr = &pstate->unbroken_text;        break;
        case  5:
#ifdef MARKED_SECTION
		 attr = &pstate->marked_sections;      break;
#else
	         croak("marked sections not supported"); break;
#endif
	case  6: attr = &pstate->attr_encoded;         break;
	case  7: attr = &pstate->case_sensitive;       break;
	case  8: attr = &pstate->strict_end;           break;
	case  9: attr = &pstate->closing_plaintext;    break;
        case 10: attr = &pstate->utf8_mode;            break;
	case 11: attr = &pstate->empty_element_tags;   break;
        case 12: attr = &pstate->xml_pic;              break;
	case 13: attr = &pstate->backquote;            break;
	default:
	    croak("Unknown boolean attribute (%d)", (int)ix);
        }
	RETVAL = boolSV(*attr);
	if (items > 1)
	    *attr = SvTRUE(ST(1));
    OUTPUT:
	RETVAL

SV*
boolean_attribute_value(pstate,...)
        PSTATE* pstate
    CODE:
	RETVAL = pstate->bool_attr_val ? newSVsv(pstate->bool_attr_val)
				       : &PL_sv_undef;
	if (items > 1) {
	    SvREFCNT_dec(pstate->bool_attr_val);
	    pstate->bool_attr_val = newSVsv(ST(1));
        }
    OUTPUT:
	RETVAL

void
ignore_tags(pstate,...)
	PSTATE* pstate
    ALIAS:
	HTML::Parser::report_tags = 1
	HTML::Parser::ignore_tags = 2
	HTML::Parser::ignore_elements = 3
    PREINIT:
	HV** attr;
	int i;
    CODE:
	switch (ix) {
	case  1: attr = &pstate->report_tags;     break;
	case  2: attr = &pstate->ignore_tags;     break;
	case  3: attr = &pstate->ignore_elements; break;
	default:
	    croak("Unknown tag-list attribute (%d)", (int)ix);
	}
	if (GIMME_V != G_VOID)
	    croak("Can't report tag lists yet");

	items--;  /* pstate */
	if (items) {
	    if (*attr)
		hv_clear(*attr);
	    else
		*attr = newHV();

	    for (i = 0; i < items; i++) {
		SV* sv = ST(i+1);
		if (SvROK(sv)) {
		    sv = SvRV(sv);
		    if (SvTYPE(sv) == SVt_PVAV) {
			AV* av = (AV*)sv;
			STRLEN j;
			STRLEN top = av_top_index(av);
			for (j = 0; j <= top; j++) {
			    SV**svp = av_fetch(av, j, 0);
			    if (svp) {
				hv_store_ent(*attr, *svp, newSViv(0), 0);
			    }
			}
		    }
		    else
			croak("Tag list must be plain scalars and arrays");
		}
		else {
		    hv_store_ent(*attr, sv, newSViv(0), 0);
		}
	    }
	}
	else if (*attr) {
	    SvREFCNT_dec(*attr);
            *attr = 0;
	}

void
handler(pstate, eventname,...)
	PSTATE* pstate
	SV* eventname
    PREINIT:
	STRLEN name_len;
	char *name = SvPV(eventname, name_len);
        int event = -1;
        int i;
        struct p_handler *h;
    PPCODE:
	/* map event name string to event_id */
	for (i = 0; i < EVENT_COUNT; i++) {
	    if (strEQ(name, event_id_str[i])) {
	        event = i;
	        break;
	    }
	}
        if (event < 0)
	    croak("No handler for %s events", name);

	h = &pstate->handlers[event];

	/* set up return value */
	if (h->cb) {
	    PUSHs((SvTYPE(h->cb) == SVt_PVAV)
	                 ? sv_2mortal(newRV_inc(h->cb))
	                 : sv_2mortal(newSVsv(h->cb)));
	}
        else {
	    PUSHs(&PL_sv_undef);
        }

        /* update */
        if (items > 3) {
	    SvREFCNT_dec(h->argspec);
	    h->argspec = 0;
	    h->argspec = argspec_compile(ST(3), pstate);
	}
        if (items > 2) {
	    SvREFCNT_dec(h->cb);
            h->cb = 0;
	    h->cb = check_handler(aTHX_ ST(2));
	}


MODULE = HTML::Parser		PACKAGE = HTML::Entities

void
decode_entities(...)
    PREINIT:
        int i;
	HV *entity2char = get_hv("HTML::Entities::entity2char", 0);
    PPCODE:
	if (GIMME_V == G_SCALAR && items > 1)
            items = 1;
	for (i = 0; i < items; i++) {
	    if (GIMME_V != G_VOID)
	        ST(i) = sv_2mortal(newSVsv(ST(i)));
	    else {
#ifdef SV_CHECK_THINKFIRST
                SV_CHECK_THINKFIRST(ST(i));
#endif
                if (SvREADONLY(ST(i)))
		    croak("Can't inline decode readonly string in decode_entities()");
            }
	    decode_entities(aTHX_ ST(i), entity2char, 0);
	}
	SP += items;

void
_decode_entities(string, entities, ...)
    SV* string
    SV* entities
    PREINIT:
	HV* entities_hv;
        bool expand_prefix = (items > 2) ? SvTRUE(ST(2)) : 0;
    CODE:
        if (SvOK(entities)) {
	    if (SvROK(entities) && SvTYPE(SvRV(entities)) == SVt_PVHV) {
		entities_hv = (HV*)SvRV(entities);
	    }
            else {
		croak("2nd argument must be hash reference");
            }
        }
        else {
            entities_hv = 0;
        }
#ifdef SV_CHECK_THINKFIRST
        SV_CHECK_THINKFIRST(string);
#endif
	if (SvREADONLY(string))
	    croak("Can't inline decode readonly string in _decode_entities()");
	decode_entities(aTHX_ string, entities_hv, expand_prefix);

bool
_probably_utf8_chunk(string)
    SV* string
    PREINIT:
        STRLEN len;
        char *s;
    CODE:
        sv_utf8_downgrade(string, 0);
	s = SvPV(string, len);
        RETVAL = probably_utf8_chunk(aTHX_ s, len);
    OUTPUT:
        RETVAL

int
UNICODE_SUPPORT()
    PROTOTYPE:
    CODE:
       RETVAL = 1;
    OUTPUT:
       RETVAL


MODULE = HTML::Parser		PACKAGE = HTML::Parser
