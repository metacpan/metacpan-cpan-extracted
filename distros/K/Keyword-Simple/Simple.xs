/*
Copyright 2012, 2013 Lukas Mai.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
 */

#ifdef __GNUC__
 #if (__GNUC__ == 4 && __GNUC_MINOR__ >= 6) || __GNUC__ >= 5
  #define PRAGMA_GCC_(X) _Pragma(#X)
  #define PRAGMA_GCC(X) PRAGMA_GCC_(GCC X)
 #endif
#endif

#ifndef PRAGMA_GCC
 #define PRAGMA_GCC(X)
#endif

#ifdef DEVEL
 #define WARNINGS_RESET PRAGMA_GCC(diagnostic pop)
 #define WARNINGS_ENABLEW(X) PRAGMA_GCC(diagnostic warning #X)
 #define WARNINGS_ENABLE \
 	WARNINGS_ENABLEW(-Wall) \
 	WARNINGS_ENABLEW(-Wextra) \
 	WARNINGS_ENABLEW(-Wundef) \
 	/* WARNINGS_ENABLEW(-Wshadow) :-( */ \
 	WARNINGS_ENABLEW(-Wbad-function-cast) \
 	WARNINGS_ENABLEW(-Wcast-align) \
 	WARNINGS_ENABLEW(-Wwrite-strings) \
 	/* WARNINGS_ENABLEW(-Wnested-externs) wtf? */ \
 	WARNINGS_ENABLEW(-Wstrict-prototypes) \
 	WARNINGS_ENABLEW(-Wmissing-prototypes) \
 	WARNINGS_ENABLEW(-Winline) \
 	WARNINGS_ENABLEW(-Wdisabled-optimization)

#else
 #define WARNINGS_RESET
 #define WARNINGS_ENABLE
#endif


#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <string.h>
#include <assert.h>
#include <stdlib.h>


WARNINGS_ENABLE


#define HAVE_PERL_VERSION(R, V, S) \
	(PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))


#define MY_PKG "Keyword::Simple"

#define HINTK_KEYWORDS MY_PKG "/keywords"


#ifndef PL_rsfp_filters
#define PL_rsfp_filters (PL_parser->rsfp_filters)
#endif

static int (*next_keyword_plugin)(pTHX_ char *, STRLEN, OP **);

static long kw_index(pTHX_ const char *kw_ptr, STRLEN kw_len) {
	HV *hints;
	SV *sv, **psv;
	char *p, *pv;
	STRLEN pv_len;

	if (!(hints = GvHV(PL_hintgv))) {
		return -1;
	}
	if (!(psv = hv_fetchs(hints, HINTK_KEYWORDS, 0))) {
		return -1;
	}
	sv = *psv;

	pv = SvPV(sv, pv_len);
	if (pv_len < 4 || pv_len - 2 <= kw_len) {
		return -1;
	}

	for (
		p = pv;
		(p = strchr(p + 1, *kw_ptr)) &&
		p < pv + pv_len - 1 - kw_len;
	) {
		if (
			p[-1] == ' ' &&
			p[kw_len] == ':' &&
			memcmp(kw_ptr, p, kw_len) == 0
		) {
			if (p[kw_len + 1] == '-') {
				return -1;
			}
			assert(p[kw_len + 1] >= '0' && p[kw_len + 1] <= '9');
			return strtol(p + kw_len + 1, NULL, 10);
		}
	}

	return -1;
}

static I32 playback(pTHX_ int idx, SV *buf, int n) {
	char *ptr;
	STRLEN len, d;
	SV *sv = FILTER_DATA(idx);

	ptr = SvPV(sv, len);
	if (!len) {
		return 0;
	}

	if (!n) {
		char *nl = memchr(ptr, '\n', len);
		d = nl ? (STRLEN)(nl - ptr + 1) : len;
	} else {
		d = n < 0 ? INT_MAX : n;
		if (d > len) {
			d = len;
		}
	}

	sv_catpvn(buf, ptr, d);
	sv_chop(sv, ptr + d);
	return 1;
}

static void total_recall(pTHX_ I32 n) {
	SV *sv, *cb;
	AV *meta;
	dSP;

	ENTER;
	SAVETMPS;

	meta = get_av(MY_PKG "::meta", GV_ADD);
	cb = *av_fetch(meta, n, 0);

	sv = sv_2mortal(newSVpvs(""));
	if (lex_bufutf8()) {
		SvUTF8_on(sv);
	}

	/* sluuuuuurrrrp */

	sv_setpvn(sv, PL_parser->bufptr, PL_parser->bufend - PL_parser->bufptr);
	lex_unstuff(PL_parser->bufend); /* you saw nothing */

	if (!PL_rsfp_filters) {
		/* because FILTER_READ fails with filters=null but DTRT with filters=[] */
		PL_rsfp_filters = newAV();
	}
	while (FILTER_READ(0, sv, 4096) > 0)
		;

	PUSHMARK(SP);
	mXPUSHs(newRV_inc(sv));
	PUTBACK;

	call_sv(cb, G_VOID);
	SPAGAIN;

	{ /* $sv .= "\n" */
		char *p;
		STRLEN n;
		SvPV_force(sv, n);
		p = SvGROW(sv, n + 2);
		p[n] = '\n';
		p[n + 1] = '\0';
		SvCUR_set(sv, n + 1);
	}

	filter_add(playback, SvREFCNT_inc_simple_NN(sv));

	CopLINE_dec(PL_curcop);

	PUTBACK;
	FREETMPS;
	LEAVE;
}

static int my_keyword_plugin(pTHX_ char *keyword_ptr, STRLEN keyword_len, OP **op_ptr) {
	long n;

	if ((n = kw_index(aTHX_ keyword_ptr, keyword_len)) >= 0) {
		total_recall(aTHX_ n);
		*op_ptr = newOP(OP_NULL, 0);
		return KEYWORD_PLUGIN_STMT;
	}

	return next_keyword_plugin(aTHX_ keyword_ptr, keyword_len, op_ptr);
}


WARNINGS_RESET

MODULE = Keyword::Simple   PACKAGE = Keyword::Simple
PROTOTYPES: ENABLE

BOOT:
WARNINGS_ENABLE {
	HV *const stash = gv_stashpvs(MY_PKG, GV_ADD);
	/**/
	newCONSTSUB(stash, "HINTK_KEYWORDS", newSVpvs(HINTK_KEYWORDS));
	/**/
	next_keyword_plugin = PL_keyword_plugin;
	PL_keyword_plugin = my_keyword_plugin;
} WARNINGS_RESET
