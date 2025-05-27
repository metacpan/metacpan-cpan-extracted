#define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros

#ifndef sv_sethek
#    define sv_sethek(a, b)  Perl_sv_sethek(aTHX_ a, b)
#endif

static SV * _new (SV * class, HV * hash) {
	dTHX;
	if (SvTYPE(class) != SVt_PV) {
                char * name = HvNAME(SvSTASH(SvRV(class)));
                class = newSVpv(name, strlen(name));
	}
	return sv_bless(newRV_noinc((SV*)hash), gv_stashsv(class, 0));
}

char *substr(char const *input, size_t start, size_t len) { 
	dTHX;
	char *ret = malloc(len+1-start);
	memcpy(ret, input+start, len);
	return ret;
}

int find_last( const char *str,  const char *word ) {
	dTHX;
	const char *p = str;
	int found = !*word;
	if (!found) {
		while (*p) ++p;
		const char *q = word;
		while (*q) ++q;
		while (!found && !( p - str < q - word )) {
			const char *s = p;
			const char *t = q;
			while (t != word && *( s - 1 ) == *( t - 1)) {
				--s;
				--t;
			}
			found = t == word;
			if ( found ) p = s;
			else --p;
		}
	}
	return found ? p - str : -1; 
}

MODULE = Meow  PACKAGE = Meow
PROTOTYPES: ENABLE

SV *
new(pkg, ...)
	SV * pkg
	CODE:
		HV * args;
		if (items > 2) {
			if ((items - 1) % 2 != 0) {
				croak("Odd number of elements in hash assignment");
			}
			args = newHV();
			int i = 1;
                        for (i = 1; i < items; i += 2) {
                                STRLEN retlen;
                                char * key = SvPV(ST(i), retlen);
                                SV * value = newSVsv(ST(i + 1));
                                hv_store(args, key, retlen, value, 0);
                        }
		} else {
			if (! SvOK(ST(1))) {
				args = newHV();
			} else if (! SvROK(ST(1)) || SvTYPE(SvRV(ST(1))) != SVt_PVHV) {
				croak("Not a hash assignment");
			} else {
				args = (HV*)SvRV(newSVsv(ST(1)));
			}
		}

                char * class;
		if (SvTYPE(pkg) != SVt_PV) {
        	        class = HvNAME(SvSTASH(SvRV(pkg)));
		} else {
			STRLEN retlen;
 			class = SvPV(pkg, retlen);
		}

		char meta[strlen(class) + 10];
		sprintf(meta, "%s::METADATA", class);	
		HV * right = get_hv(meta, GV_ADD);
		
		HE * entry;
		(void)hv_iterinit(args);
		while ((entry = hv_iternext(args)))  {
			STRLEN retlen;
			char * key =  SvPV(hv_iterkeysv(entry), retlen);
			SV * value = *hv_fetch(args, key, retlen, 0);

			if ( hv_exists(right, key, retlen) ) {
				HV * spec = (HV*)SvRV(*hv_fetch(right, key, retlen, 0));
				if (hv_exists(spec, "isa", 3)) {
					SV * sv = *hv_fetch(spec, "isa", 3, 0);
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

			hv_store(args, key, retlen, value, 0);
		}

		RETVAL = _new(newSVsv(ST(0)), args);
	OUTPUT:
		RETVAL

SV *
attribute(...)
	CODE:
		STRLEN retlen;
		char * caller = SvPV((SV*)cv_name((CV*)ST(items), 0, 0), retlen);
		int last = find_last(caller, ":");	
		char * class = substr(caller, 0, last + 1);
    		char * method = substr(caller, last + 1, 10);
		char meta[strlen(class) + 10];
		sprintf(meta, "%sMETADATA", class);	
		HV * right = get_hv(meta, GV_ADD);
		HV * okay = (HV*)SvRV(*hv_fetch(right, method, strlen(method), 0));

		HV * self = (HV*)SvRV(ST(0));
		SV * val;
		if (items > 1) {
			if (hv_exists(okay, "isa", 3)) {
				SV * sv = *hv_fetch(okay, "isa", 3, 0);
				dSP;
				PUSHMARK(SP);
				XPUSHs(newSVsv(ST(1)));
				PUTBACK;
				call_sv(sv, G_SCALAR);
				SPAGAIN;
				ST(1) = POPs;
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
	char * name
	SV * attr
	CODE:
		SV * caller = newSV(0);
    		HEK * stash_hek = HvNAME_HEK((HV*)CopSTASH(PL_curcop));
		sv_sethek(caller, stash_hek);
		STRLEN retlen;
		char * callr = SvPV(caller, retlen);
                char ex [strlen(name) + 2 + retlen];
                sprintf(ex, "%s::%s", callr, name);

		if (!SvROK(attr)) {
			attr = newRV_noinc((SV*)newHV());
		} else {
			SV * rv = SvRV(attr);

			if (SvTYPE(rv) != SVt_PVHV ||  ! hv_exists((HV*)rv, "isa", 3)) {
				HV * n = newHV();
				hv_store(n, "isa", 3, newSVsv(attr), 0);
				attr = newRV_noinc((SV*)n);
			}
		}

		HV * right = get_hv("Foo::METADATA", GV_ADD);
		hv_store(right, name, strlen(name), newSVsv(attr), 0);

		CV * cv = newXS(ex, XS_Meow_attribute, __FILE__);

		RETVAL = caller;
	OUTPUT:
		RETVAL

void
import(pkg, ...)
	char * pkg
	CODE:
		int i = 0;
		SV * caller = newSV(0);
    		HEK * stash_hek = HvNAME_HEK((HV*)CopSTASH(PL_curcop));
		sv_sethek(caller, stash_hek);
		STRLEN retlen;
		pkg = SvPV(caller, retlen);
		char * export[] = { "new", "rw" };
		for (i = 0; i < 2; i++) {
			char * ex = export[i];
                        char name [strlen(pkg) + 2 + strlen(ex)];
                        sprintf(name, "%s::%s", pkg, ex);
			if (strcmp(ex, "new") == 0) {
				newXS(name, XS_Meow_new, __FILE__);
			} else if (strcmp(ex, "rw") == 0) {
				newXS(name, XS_Meow_rw, __FILE__);
			}
		}
