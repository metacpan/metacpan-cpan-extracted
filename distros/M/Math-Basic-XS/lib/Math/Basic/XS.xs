#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdlib.h>
#include <string.h>

static NV call_nv (pTHX_ SV * cb, SV * arg) {
	dSP;
	NV ret;
	DEFSV_set(sv_mortalcopy(arg));
	PUSHMARK(SP);
	PUTBACK;
	call_sv(cb, G_SCALAR);
	SPAGAIN;
	ret = POPn;
	PUTBACK;
	return ret;
}

static NV * collect (pTHX_ SV * cb, I32 first, int count) {
	NV * vals;
	int i;
	Newx(vals, count, NV);
	SAVEFREEPV(vals);
	for (i = 0; i < count; i++) {
		vals[i] = call_nv(aTHX_ cb, PL_stack_base[first + i]);
	}
	return vals;
}

static NV mode (NV * arr, int size) {
	NV max_value = 0;
	int max_count = 0, i, j;
	for (i = 0; i < size; ++i) {
		int cnt = 0;
		for (j = 0; j < size; ++j) {
			if (arr[j] == arr[i])
				++cnt;
		}
		if (cnt > max_count) {
			max_count = cnt;
			max_value = arr[i];
		}
	}
	return max_value;
}

static int compare (const void * a, const void * b) {
	NV na = *(const NV *)a;
	NV nb = *(const NV *)b;
	return na < nb ? -1 : na > nb ? 1 : 0;
}


MODULE = Math::Basic::XS  PACKAGE = Math::Basic::XS
PROTOTYPES: ENABLE

void
import(...)
	PROTOTYPE: DISABLE
	CODE:
		HV * tags = get_hv("Math::Basic::XS::EXPORT_TAGS", 0);
		AV * args = (AV *)sv_2mortal((SV *)newAV());
		SSize_t i, top;
		for (i = 0; i < items; i++) {
			SV * arg = ST(i);
			STRLEN len;
			const char * name;
			if (i > 0 && tags && SvOK(arg) && !SvROK(arg)) {
				name = SvPV_const(arg, len);
				if (len && isIDFIRST(name[0]) && hv_exists(tags, name, len)) {
					arg = newSVpvs_flags(":", SVs_TEMP);
					sv_catpvn(arg, name, len);
				}
			}
			av_push(args, SvREFCNT_inc_simple_NN(arg));
		}
		top = av_len(args);
		SP = MARK;
		PUSHMARK(SP);
		EXTEND(SP, top + 1);
		for (i = 0; i <= top; i++)
			PUSHs(*av_fetch(args, i, 0));
		PUTBACK;
		call_pv("Ex::Op::import", G_VOID | G_DISCARD);
		XSRETURN_EMPTY;

SV *
sum(...)
	PROTOTYPE: &@
	CODE:
		NV sum = 0;
		int i;
		ENTER;
		SAVE_DEFSV;
		for (i = 1; i < items; i++) {
			sum += call_nv(aTHX_ ST(0), ST(i));
		}
		LEAVE;
		RETVAL = newSVnv(sum);
	OUTPUT:
		RETVAL

SV *
min(...)
	PROTOTYPE: &@
	CODE:
		NV min = 0;
		int i;
		if (items < 2) XSRETURN_UNDEF;
		ENTER;
		SAVE_DEFSV;
		for (i = 1; i < items; i++) {
			NV ret = call_nv(aTHX_ ST(0), ST(i));
			if (i == 1 || ret < min) min = ret;
		}
		LEAVE;
		RETVAL = newSVnv(min);
	OUTPUT:
		RETVAL

SV *
max(...)
	PROTOTYPE: &@
	CODE:
		NV max = 0;
		int i;
		if (items < 2) XSRETURN_UNDEF;
		ENTER;
		SAVE_DEFSV;
		for (i = 1; i < items; i++) {
			NV ret = call_nv(aTHX_ ST(0), ST(i));
			if (i == 1 || ret > max) max = ret;
		}
		LEAVE;
		RETVAL = newSVnv(max);
	OUTPUT:
		RETVAL

SV *
mean(...)
	PROTOTYPE: &@
	CODE:
		NV sum = 0;
		int i;
		if (items < 2) XSRETURN_UNDEF;
		ENTER;
		SAVE_DEFSV;
		for (i = 1; i < items; i++) {
			sum += call_nv(aTHX_ ST(0), ST(i));
		}
		LEAVE;
		RETVAL = newSVnv(sum / (items - 1));
	OUTPUT:
		RETVAL

SV *
median(...)
	PROTOTYPE: &@
	CODE:
		NV * vals;
		int count = items - 1;
		if (count < 1) XSRETURN_UNDEF;
		ENTER;
		SAVE_DEFSV;
		vals = collect(aTHX_ ST(0), ax + 1, count);
		qsort(vals, count, sizeof(NV), compare);
		RETVAL = newSVnv(vals[count / 2]);
		LEAVE;
	OUTPUT:
		RETVAL

SV *
mode(...)
	PROTOTYPE: &@
	CODE:
		NV * vals;
		int count = items - 1;
		if (count < 1) XSRETURN_UNDEF;
		ENTER;
		SAVE_DEFSV;
		vals = collect(aTHX_ ST(0), ax + 1, count);
		RETVAL = newSVnv(mode(vals, count));
		LEAVE;
	OUTPUT:
		RETVAL
