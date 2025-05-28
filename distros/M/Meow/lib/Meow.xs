#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdlib.h>
#include <string.h>

#ifndef sv_sethek
#	define sv_sethek(a, b)  Perl_sv_sethek(aTHX_ a, b)
#endif

static SV * _new(SV *class, HV *hash) {
	dTHX;
	if (SvTYPE(class) != SVt_PV) {
		char *name = HvNAME(SvSTASH(SvRV(class)));
		class = newSVpv(name, strlen(name));
	}
	return sv_bless(newRV_noinc((SV*)hash), gv_stashsv(class, 0));
}

char *substr(const char *input, size_t start, size_t len) {
	dTHX;
	char *ret = (char *)malloc(len - start + 1);
	memcpy(ret, input + start, len - start);
	ret[len - start] = '\0';
	return ret;
}

int find_last(const char *str, const char word) {
	dTHX;
	int lastIndex = -1, i = 0;
	for (i = 0; str[i] != '\0'; i++) {
		if (str[i] == word) {
			lastIndex = i;
		}
	}
	return lastIndex;
}

char *get_ex_method(const char *name) {
	dTHX;
	SV *caller = newSV(0);
	HEK *stash_hek = HvNAME_HEK((HV*)CopSTASH(PL_curcop));
	sv_sethek(caller, stash_hek);
	STRLEN retlen;
	char *callr = SvPV(caller, retlen);
	size_t ex_len = strlen(name) + 2 + retlen + 1;
	char *ex_out = (char *)malloc(ex_len);
	if (!ex_out) croak("Out of memory in get_ex_method");
	snprintf(ex_out, ex_len, "%s::%s", callr, name);
	SvREFCNT_dec(caller);
	return ex_out;
}

char *get_caller(void) {
	dTHX;
	SV *caller = newSV(0);
	HEK *stash_hek = HvNAME_HEK((HV*)CopSTASH(PL_curcop));
	sv_sethek(caller, stash_hek);
	STRLEN retlen;
	char *callr = SvPV(caller, retlen);
	char *ex_out = strdup(callr);
	SvREFCNT_dec(caller);
	return ex_out;
}

void get_class_and_method(SV *cv_name_sv, char **class_out, char **method_out) {
	dTHX;
	STRLEN len;
	char *full = SvPV(cv_name_sv, len);
	int idx = find_last(full, ':');
	if (idx == -1 || idx < 1) {
		*class_out = strdup("");
		*method_out = strdup(full);
		return;
	}
	int sep = idx;
	if (sep > 0 && full[sep-1] == ':') sep--;
	*class_out = substr(full, 0, sep);
	*method_out = substr(full, idx+1, len);
}

void register_attribute(CV *cv, char *name, SV *attr, XSUBADDR_t xsub_addr) {
	dTHX;
	SV *newcv = (SV *)CvXSUBANY(cv).any_ptr;
	SV *spec = (SV *)CvXSUBANY(newcv).any_ptr;

	if (!SvROK(attr)) {
		HV *n = newHV();
		hv_store(n, "name", 4, newSVpv(name, strlen(name)), 0);
		attr = newRV_noinc((SV*)newHV());
	} else {
		SV *rv = SvRV(attr);
		if (SvTYPE(rv) != SVt_PVHV || !hv_exists((HV*)rv, "isa", 3)) {
			HV *n = newHV();
			hv_store(n, "name", 4, newSVpv(name, strlen(name)), 0);
			hv_store(n, "isa", 3, newSVsv(attr), 0);
			attr = newRV_noinc((SV*)n);
		} else {
			hv_store((HV*)rv, "name", 4, newSVpv(name, strlen(name)), 0);
		}
	}

	hv_store((HV*)SvRV(spec), name, strlen(name), newSVsv(attr), 0);

	char *ex = get_ex_method(name);
	CV *new_attr_cv = newXS(ex, xsub_addr, __FILE__);
	SvREFCNT_inc(attr);
	CvXSUBANY(new_attr_cv).any_ptr = (void *)attr;
	free(ex);
}

static AV *get_avf(const char *fmt, ...) {
	dTHX;
	va_list ap;
	char buf[256];

	va_start(ap, fmt);
	vsnprintf(buf, sizeof(buf), fmt, ap);
	va_end(ap);

	return get_av(buf, GV_ADD);
}

static CV *get_cvf(const char *fmt, ...) {
	dTHX;
	va_list ap;
	char buf[256];

	va_start(ap, fmt);
	vsnprintf(buf, sizeof(buf), fmt, ap);
	va_end(ap);

	return get_cv(buf, GV_ADD);
}

static SV *normalise_attr(SV *attr) {
	dTHX;
	if (!SvROK(attr)) {
		HV *n = newHV();
		attr = newRV_noinc((SV*)newHV());
	} else {
		SV *rv = SvRV(attr);
		if (SvTYPE(rv) != SVt_PVHV || !hv_exists((HV*)rv, "isa", 3)) {
			HV *n = newHV();
			hv_store(n, "isa", 3, newSVsv(attr), 0);
			attr = newRV_noinc((SV*)n);
		}
	}
	return attr;
}

MODULE = Meow  PACKAGE = Meow
PROTOTYPES: ENABLE

SV *
new(pkg, ...)
	SV *pkg
	CODE:
		SV *spec = (SV *)CvXSUBANY(cv).any_ptr;
		HV *args;
		int i;
		if (items > 2) {
			if ((items - 1) % 2 != 0) {
				croak("Odd number of elements in hash assignment");
			}
			args = newHV();
			for (i = 1; i < items; i += 2) {
				STRLEN retlen;
				char *key = SvPV(ST(i), retlen);
				SV *value = newSVsv(ST(i + 1));
				hv_store(args, key, retlen, value, 0);
			}
		} else {
			if (!SvOK(ST(1))) {
				args = newHV();
			} else if (!SvROK(ST(1)) || SvTYPE(SvRV(ST(1))) != SVt_PVHV) {
				croak("Not a hash assignment");
			} else {
				args = (HV*)SvRV(newSVsv(ST(1)));
			}
		}
		RETVAL = _new(newSVsv(ST(0)), args);
		HV *right = (HV*)SvRV(spec);
		HE *entry;
		(void)hv_iterinit(right);
		while ((entry = hv_iternext(right))) {
			STRLEN retlen;
			char *key = SvPV(hv_iterkeysv(entry), retlen);
			SV **valp = hv_fetch(args, key, retlen, 0);
			SV *value;
			if (!valp) {
				value = &PL_sv_undef;
			} else{
				value = *valp;
			}
			if (hv_exists(right, key, retlen)) {
				SV **spec_sv = hv_fetch(right, key, retlen, 0);

				if (spec_sv && SvROK(*spec_sv) && SvTYPE(SvRV(*spec_sv)) == SVt_PVHV) {
					HV *spec_hv = (HV*)SvRV(*spec_sv);
					if (!SvOK(value) && hv_exists(spec_hv, "default", 7)) {
						SV **default_sv = hv_fetch(spec_hv, "default", 7, 0);
						if (default_sv) {
							if (SvROK(*default_sv) && SvTYPE(SvRV(*default_sv)) == SVt_PVCV) {
								dSP;
								PUSHMARK(SP);
								XPUSHs(newSVsv(pkg));
								PUTBACK;
								call_sv(*default_sv, G_SCALAR);
								SPAGAIN;
								value = POPs;
								PUTBACK;
							} else {
								value = newSVsv(*default_sv);
							}
						} else {
							croak("No default value for '%s'", key);
						}
					}

					if (hv_exists(spec_hv, "coerce", 6)) {
						SV *coerce_sv = *hv_fetch(spec_hv, "coerce", 6, 0);
						dSP;
						PUSHMARK(SP);
						XPUSHs(newSVsv(value));
						PUTBACK;
						call_sv(coerce_sv, G_SCALAR);
						SPAGAIN;
						value = POPs;
						PUTBACK;
					}

					if (SvOK(value) && hv_exists(spec_hv, "isa", 3)) {
						SV *sv = *hv_fetch(spec_hv, "isa", 3, 0);
						dSP;
						PUSHMARK(SP);
						XPUSHs(newSVsv(value));
						PUTBACK;
						call_sv(sv, G_SCALAR);
						SPAGAIN;
						value = POPs;
						PUTBACK;
					}
				}
			}
			hv_store(args, key, retlen, value, 0);
		}

		(void)hv_iterinit(right);
		while ((entry = hv_iternext(right))) {
			STRLEN retlen;
			char *key = SvPV(hv_iterkeysv(entry), retlen);
			SV *value = *hv_fetch(args, key, retlen, 0);
			HV *spec_hv = (HV*)SvRV((*hv_fetch(right, key, retlen, 0)));
			if (!SvOK(value) && hv_exists(spec_hv, "builder", 7)) {
				SV *builder_sv = *hv_fetch(spec_hv, "builder", 7, 0);
				dSP;
				PUSHMARK(SP);
				XPUSHs(newSVsv(RETVAL));
				PUTBACK;
				call_sv(builder_sv, G_SCALAR);
				SPAGAIN;
				value = POPs;
				PUTBACK;
				if (SvOK(value) && hv_exists(spec_hv, "isa", 3)) {
						SV *sv = *hv_fetch(spec_hv, "isa", 3, 0);
						dSP;
						PUSHMARK(SP);
						XPUSHs(newSVsv(value));
						PUTBACK;
						call_sv(sv, G_SCALAR);
						SPAGAIN;
						value = POPs;
						PUTBACK;
				}
				hv_store(args, key, retlen, value, 0);
			}

			if (hv_exists(spec_hv, "trigger", 7)) {
				SV *trigger_sv = *hv_fetch(spec_hv, "trigger", 7, 0);
				dSP;
				PUSHMARK(SP);
				XPUSHs(newSVsv(RETVAL));
				XPUSHs(newSVsv(value));
				PUTBACK;
				call_sv(trigger_sv, G_SCALAR);
				SPAGAIN;
				POPs;
				PUTBACK;
			}
		}

	OUTPUT:
		RETVAL

SV *
rw_attribute(...)
	CODE:
		SV *spe = (SV *)CvXSUBANY(cv).any_ptr;
		SvREFCNT_inc(spe);
		HV *spec = (HV*)SvRV(spe);
		STRLEN retlen;
		SV **name_sv = hv_fetch(spec, "name", 4, 0);
		if (!name_sv) croak("No 'name' in spec");
		char *method = SvPV(*name_sv, retlen);
		SV *val;
		HV *self = (HV*)SvRV(ST(0));
		if (items > 1) {
			if (hv_exists(spec, "coerce", 6)) {
				SV *coerce_sv = *hv_fetch(spec, "coerce", 6, 0);
				dSP;
				PUSHMARK(SP);
				XPUSHs(newSVsv(ST(1)));
				PUTBACK;
				call_sv(coerce_sv, G_SCALAR);
				SPAGAIN;
				ST(1) = POPs;
				PUTBACK;
			}
			if (hv_exists(spec, "isa", 3)) {
				SV *sv = *hv_fetch(spec, "isa", 3, 0);
				dSP;
				PUSHMARK(SP);
				XPUSHs(newSVsv(ST(1)));
				PUTBACK;
				call_sv(sv, G_SCALAR);
				SPAGAIN;
				ST(1) = POPs;
				PUTBACK;
			}
			if (hv_exists(spec, "trigger", 7)) {
				SV *coerce_sv = *hv_fetch(spec, "trigger", 7, 0);
				dSP;
				PUSHMARK(SP);
				XPUSHs(newSVsv(ST(0)));
				XPUSHs(newSVsv(ST(1)));
				PUTBACK;
				call_sv(coerce_sv, G_SCALAR);
				SPAGAIN;
				POPs;
				PUTBACK;
			}
			val = newSVsv(ST(1));
			hv_store(self, method, strlen(method), newSVsv(val), 0);
		} else {
			val = newSVsv(hv_exists(self, method, strlen(method)) ? *hv_fetch(self, method, strlen(method), 0) : NULL);
		}
		RETVAL = val;
	OUTPUT:
		RETVAL

SV *
rw(name, attr)
	char *name
	SV *attr
	CODE:
		register_attribute(cv, name, attr, XS_Meow_rw_attribute);

		RETVAL = newSViv(1);
	OUTPUT:
		RETVAL

SV *
ro_attribute(...)
	CODE:
		if (items > 1) {
			croak("Read only attributes cannot be set");
		}
		SV *spe = (SV *)CvXSUBANY(cv).any_ptr;
		SvREFCNT_inc(spe);
		HV *spec = (HV*)SvRV(spe);
		STRLEN retlen;
		SV **name_sv = hv_fetch(spec, "name", 4, 0);
		if (!name_sv) croak("No 'name' in spec");
		char *method = SvPV(*name_sv, retlen);
		HV *self = (HV*)SvRV(ST(0));
		SV *val = newSVsv(hv_exists(self, method, strlen(method)) ? *hv_fetch(self, method, strlen(method), 0) : NULL);
		RETVAL = val;
	OUTPUT:
		RETVAL

SV *
ro(name, attr)
	char *name
	SV *attr
	CODE:
		register_attribute(cv, name, attr, XS_Meow_ro_attribute);

		RETVAL = newSViv(1);
	OUTPUT:
		RETVAL

SV *
Default(...)
	CODE:
		if (items < 2) {
			croak("Default requires an attribute name and a value");
		}
		SV * attr = ST(0);
		attr = normalise_attr(attr);
		HV *spec = (HV*)SvRV(attr);
		hv_store(spec, "default", 7, newSVsv(ST(1)), 0);
		SvREFCNT_inc(attr);
		RETVAL = attr;
	OUTPUT:
		RETVAL

SV *
Coerce(...)
	CODE:
		if (items < 2) {
			croak("Coerce requires an attribute name and a value");
		}
		if (!SvROK(ST(1)) || SvTYPE(SvRV(ST(1))) != SVt_PVCV) {
			croak("Coerce requires a code reference as the second argument");
		}
		SV * attr = ST(0);
		attr = normalise_attr(attr);
		HV *spec = (HV*)SvRV(attr);
		hv_store(spec, "coerce", 6, newSVsv(ST(1)), 0);
		SvREFCNT_inc(attr);
		RETVAL = attr;
	OUTPUT:
		RETVAL
	
SV *
Trigger(...)
	CODE:
		if (items < 2) {
			croak("Trigger requires an attribute name and a value");
		}
		if (!SvROK(ST(1)) || SvTYPE(SvRV(ST(1))) != SVt_PVCV) {
			croak("Trigger requires a code reference as the second argument");
		}
		SV * attr = ST(0);
		attr = normalise_attr(attr);
		HV *spec = (HV*)SvRV(attr);
		hv_store(spec, "trigger", 7, newSVsv(ST(1)), 0);
		SvREFCNT_inc(attr);
		RETVAL = attr;
	OUTPUT:
		RETVAL

SV *
Builder(...)
	CODE:
		if (items < 2) {
			croak("Builder requires an attribute name and a value");
		}
		if (!SvROK(ST(1)) || SvTYPE(SvRV(ST(1))) != SVt_PVCV) {
			croak("Builder requires a code reference as the second argument");
		}
		SV * attr = ST(0);
		attr = normalise_attr(attr);
		HV *spec = (HV*)SvRV(attr);
		hv_store(spec, "builder", 7, newSVsv(ST(1)), 0);
		SvREFCNT_inc(attr);
		RETVAL = attr;
	OUTPUT:
		RETVAL

void
extends(...)
	CODE:
		dTHX;
		HV *stash = (HV*)CopSTASH(PL_curcop);
		const char *child = HvNAME(stash);
		int i;
		for (i = 0; i < items; i++) {
			char *parent = SvPV_nolen(ST(i));
			AV *isa = get_avf("%s::ISA", child);
			int found = 0;
			SV **svp;
			SSize_t j, len = isa ? av_len(isa) + 1 : 0;
			for (j = 0; j < len; j++) {
				svp = av_fetch(isa, j, 0);
				if (svp && SvPOK(*svp) && strcmp(SvPV_nolen(*svp), parent) == 0) {
					found = 1;
					break;
				}
			}
			if (!found) {
				av_push(isa, newSVpv(parent, 0));
			}

			CV *child_cv = get_cvf("%s::new", child);
			CV *parent_cv = get_cvf("%s::new", parent);
	  
			if (!child_cv || !parent_cv)
				croak("Could not find new() for child or parent class");
			SV *child_spec = (SV *)CvXSUBANY(child_cv).any_ptr;
			SV *parent_spec = (SV *)CvXSUBANY(parent_cv).any_ptr;
			if (!child_spec || !parent_spec)
				croak("Missing spec in child or parent");
			HV *child_hv = (HV*)SvRV(child_spec);
			HV *parent_hv = (HV*)SvRV(parent_spec);
			HE *entry;
			hv_iterinit(parent_hv);
			while ((entry = hv_iternext(parent_hv))) {
				SV *keysv = hv_iterkeysv(entry);
				STRLEN klen;
				const char *key = SvPV(keysv, klen);
				if (!hv_exists(child_hv, key, klen)) {
					SV *val = newSVsv(hv_iterval(parent_hv, entry));
					hv_store(child_hv, key, klen, val, 0);
				}
			}
		}

void
import(pkg, ...)
	char *pkg
	CODE:
		char *callr = get_caller();
		const char *export[] = { "new", "rw", "ro", "extends", "Default", "Coerce", "Trigger", "Builder" };
		int i;
		CV *newcv = NULL;
		for (i = 0; i < 8; i++) {
			const char *ex = export[i];
			size_t name_len = strlen(callr) + 2 + strlen(ex) + 1;
			char *name = (char *)malloc(name_len);
			if (!name) croak("Out of memory in import");
			snprintf(name, name_len, "%s::%s", callr, ex);
			if (strcmp(ex, "new") == 0) {
				newcv = newXS(name, XS_Meow_new, __FILE__);
				SV *spec = newRV_noinc((SV*)newHV());
				CvXSUBANY(newcv).any_ptr = (void *)spec;
			} else if (strcmp(ex, "rw") == 0) {
				CV *rwcv = newXS(name, XS_Meow_rw, __FILE__);
				CvXSUBANY(rwcv).any_ptr = (void *)newcv;
			} else if (strcmp(ex, "ro") == 0) {
				CV *rwcv = newXS(name, XS_Meow_ro, __FILE__);
				CvXSUBANY(rwcv).any_ptr = (void *)newcv;
			} else if (strcmp(ex, "extends") == 0) {
				CV *extends_cv = newXS(name, XS_Meow_extends, __FILE__);
			} else if (strcmp(ex, "Default") == 0) {
				CV *default_cv = newXS(name, XS_Meow_Default, __FILE__);
			} else if (strcmp(ex, "Coerce") == 0){
				CV *coerce_cv = newXS(name, XS_Meow_Coerce, __FILE__);
			} else if (strcmp(ex, "Trigger") == 0) {
				CV *trigger_cv = newXS(name, XS_Meow_Trigger, __FILE__);
			} else if (strcmp(ex, "Builder") == 0) {
				CV *builder_cv = newXS(name, XS_Meow_Builder, __FILE__);
			}
		}
