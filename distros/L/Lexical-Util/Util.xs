/*------------------------------------------------------------------------------
 * Lexical::Util.xs - XSUBs for the Lexical::Util package
 *------------------------------------------------------------------------------
 * $Id: Util.xs,v 1.5 2004/07/29 02:48:17 kevin Exp $
 *------------------------------------------------------------------------------
 * $Log: Util.xs,v $
 * Revision 1.5  2004/07/29 02:48:17  kevin
 * Add lexical_alias routine.
 *
 * Revision 1.4  2004/07/25 04:39:28  kevin
 * Pull out common code into find_var_in_pad function.
 *
 * Revision 1.3  2004/07/10 01:09:58  kevin
 * Add ref_to_lexical function.
 *----------------------------------------------------------------------------*/
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/*------------------------------------------------------------------------------
 * dopoptosub_at - find the index to the specified stack frame
 *----------------------------------------------------------------------------*/
I32
dopoptosub_at(pTHX_ PERL_CONTEXT *cxstk, I32 start)
{
	dTHR;
	I32 i;
	I32 type;

	for (i = start;
		 i >= 0
		  && (type = CxTYPE(&cxstk[i])) != CXt_SUB
#ifdef CXt_FORMAT
		  && type != CXt_FORMAT
#endif
		 ;
		 i--
	)
		;

	return i;
}

/*------------------------------------------------------------------------------
 * find_var_in_pad - looks for variable named 'name' in the pad associated
 * with 'cv'. If the return value is >= 0, then *padvalues is set to the
 * AV * of the proper pad to use.  If the return value is < 0, the specified
 * variable was not found.
 *----------------------------------------------------------------------------*/
I32
find_var_in_pad(pTHX_ SV *cvref, const char *name, AV **padvalues)
{
	dTHR;
	int i;
	AV *padv, *padn;
	CV *cv;

	if (SvROK(cvref)) {
		cv = (CV*)SvRV(cvref);
	} else if (SvIOK(cvref) && SvIV(cvref) == 0) {
		cv = NULL;
	} else {
		croak("'cvref' argument must be code ref or 0");
	}

	padn = cv ? (AV*)AvARRAY(CvPADLIST(cv))[0]           : PL_comppad_name;
	padv = cv ? (AV*)AvARRAY(CvPADLIST(cv))[CvDEPTH(cv)] : PL_comppad;

	for (i = 0; i <= av_len(padn); ++i) {
		SV **nameptr = av_fetch(padn, i, 0);
		if (nameptr) {
			SV *name_sv = *nameptr;
			if (SvPOKp(name_sv)) {
				const char *name_str = SvPVX(name_sv);
				if (strcmp(name, name_str) == 0) {
					*padvalues = padv;
					break;
				}
			}
		}
	}
	return i >= av_len(padn) ? -1 : i;
}

MODULE = Lexical::Util		PACKAGE = Lexical::Util
PROTOTYPES: ENABLE

##==============================================================================
## lexalias - create a lexical alias, possibly in another stack frame.
##==============================================================================
void
lexalias(SV* cvref, const char *name, SV* value)
  CODE:
	AV* padv;				/* Pad values */
	SV* new_sv;				/* Item referenced by value */
	I32 i;					/* index variable */

	if (!SvROK(value))
		croak("third argument to lexalias is supposed to be a reference");

	new_sv = SvRV(value);

	/*
	 * Go through the pad name list and find the one corresponding to 'name'.
	 */
	i = find_var_in_pad(aTHX_ cvref, name, &padv);
	if (i < 0)
		croak("Variable '%s' not found in lexalias", name);

	av_store(padv, i, new_sv);
	SvREFCNT_inc(new_sv);

##==============================================================================
## lexical_alias - like above, but doesn't die
##==============================================================================
SV *
lexical_alias(SV *cvref, const char *name, SV* value)
	CODE:
		AV *padv;			/* Pad values */
		SV *new_sv;			/* Item referenced by value */
		I32 i;				/* index variable */

		if (!SvROK(value)) {
			RETVAL = newSVpvf(
				"for variable %s, invalid reference passed to lexical_alias",
				name
			);
		} else {
			new_sv = SvRV(value);

			i = find_var_in_pad(aTHX_ cvref, name, &padv);
			if (i < 0) {
				RETVAL = newSVpvf(
					"variable %s not found in lexical_alias",
					name
				);
			} else {
				av_store(padv, i, new_sv);
				SvREFCNT_inc(new_sv);
				RETVAL = &PL_sv_undef;
			}
		}
	OUTPUT:
		RETVAL

##==============================================================================
## ref_to_lexical - return a reference to a lexical variable in another
## stack frame, by name.
##==============================================================================
SV*
ref_to_lexical(SV *cvref, const char *name)
  CODE:
	AV *padv;				/* Pad values */
	SV *new_sv;				/* The reference we're creating */
	SV **ref_to_var;		/* The variable we're looking for */
	I32 i;					/* index variable */

	i = find_var_in_pad(aTHX_ cvref, name, &padv);
	if (i < 0)
		croak("variable '%s' not found in ref_to_lexical");

	ref_to_var = av_fetch(padv, i, 0);
	RETVAL = newRV_inc(*ref_to_var);
  OUTPUT:
  	RETVAL

##==============================================================================
## frame_to_cvref - return the code reference corresponding to the given
## stack frame.
##==============================================================================
SV*
frame_to_cvref(I32 level)
  CODE:
	PERL_CONTEXT *cx = (PERL_CONTEXT *)0;
	PERL_SI *top_si = PL_curstackinfo;
	I32 cxix = dopoptosub_at(aTHX_ cxstack, cxstack_ix);
	PERL_CONTEXT *ccstack = cxstack;
	CV *cur_cv;

	/*
	 * First, find the Perl context for the given level.
	 */
	for (;;) {
		while (cxix < 0 && top_si->si_type != PERLSI_MAIN) {
			top_si  = top_si->si_prev;
			ccstack = top_si->si_cxstack;
			cxix    = dopoptosub_at(aTHX_ ccstack, top_si->si_cxix);
		}
		if (cxix < 0) {
			if (level != 0) {
				cx = (PERL_CONTEXT *)-1;
			}
			break;
		}
		if (PL_DBsub && cxix >= 0 && ccstack[cxix].blk_sub.cv == GvCV(PL_DBsub))
			level++;
		if (level-- == 0) {
			cx = &ccstack[cxix];
			break;
		}
		cxix = dopoptosub_at(aTHX_ ccstack, cxix - 1);
	}
	/*
	 * Perl context is in cx.
	 * Find the associated code reference.
	 */
	if (cx != (PERL_CONTEXT *)-1) {
		if (cx != (PERL_CONTEXT *)0) {
			if (cx->cx_type != CXt_SUB) {
				croak(
					"invalid cx_type in frame_to_cvref: is %d, should be %d",
					cx->cx_type, CXt_SUB
				);
			}
			if ((cur_cv = cx->blk_sub.cv) == 0) {
				croak("frame_to_cvref: context has no associated CV!");
			}
			RETVAL = (SV*)newRV_inc((SV*)cur_cv);
		} else {
			RETVAL = (SV*)newSViv(0);
		}
	} else {
		RETVAL = (SV*)newSV(0);
	}
  OUTPUT:
	RETVAL
