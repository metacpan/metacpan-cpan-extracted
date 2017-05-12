#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "magical_hooker_decorate.h"



STATIC MGVTBL null_mg_vtbl = {
    NULL, /* get */
    NULL, /* set */
    NULL, /* len */
    NULL, /* clear */
    NULL, /* free */
#if MGf_COPY
    NULL, /* copy */
#endif /* MGf_COPY */
#if MGf_DUP
    NULL, /* dup */
#endif /* MGf_DUP */
#if MGf_LOCAL
    NULL, /* local */
#endif /* MGf_LOCAL */
};



MAGIC *magical_hooker_decoration_set (pTHX_ SV *sv, SV *obj, void *ptr) {
    MAGIC *mg = sv_magicext(sv, obj, PERL_MAGIC_ext, &null_mg_vtbl, ptr, 0 );

    mg->mg_flags |= MGf_REFCOUNTED;

    return mg;
}


/* since we have multiple possible values then we can't use the normal API,
 * otherwise that'll modify all of the PERL_MAGIC_ext entries */

MAGIC *magical_hooker_decoration_get_mg (pTHX_ SV *sv, void *ptr) {
    MAGIC *mg;

    if (SvTYPE(sv) >= SVt_PVMG) {
        for (mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic) {
			if (
				(mg->mg_type == PERL_MAGIC_ext)
					&&
				(mg->mg_virtual == &null_mg_vtbl)
					&&
				(mg->mg_ptr == ptr)
			) {
				return mg;
			}
        }
    }

    return NULL;
}

SV *magical_hooker_decoration_get (pTHX_ SV *sv, void *ptr) {
	MAGIC *mg = magical_hooker_decoration_get_mg(aTHX_ sv, ptr);

	if ( mg )
		return sv_2mortal(SvREFCNT_inc(mg->mg_obj));
	else
		return NULL;
}

SV *magical_hooker_decoration_clear (pTHX_ SV *sv, void *ptr) {
	MAGIC *zap_mg = magical_hooker_decoration_get_mg(aTHX_ sv, ptr);

	if ( zap_mg ) {
		SV *obj = zap_mg->mg_obj;
		MAGIC *mg;

		if ( SvMAGIC(sv) == zap_mg ) {
			SvMAGIC(sv) = zap_mg->mg_moremagic;

			sv_2mortal(obj);
			Safefree(zap_mg);

			return obj;
		}

        for (mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic) {
			if ( mg->mg_moremagic == zap_mg ) {
				mg->mg_moremagic = zap_mg->mg_moremagic;
				
				sv_2mortal(obj);
				Safefree(zap_mg);

				return obj;
			}
		}

		croak("wtf");
	}

	return NULL;
}


MODULE = Magical::Hooker::Decorate	PACKAGE = Magical::Hooker::Decorate
PROTOTYPES: DISABLE

void
set (SV *self, SV *target, SV *value)
	CODE:
		magical_hooker_decoration_set(aTHX_ SvRV(target), value, SvRV(self));

SV *
get (SV *self, SV *target)
	PREINIT:
		SV *sv;
	CODE:
		sv = magical_hooker_decoration_get(aTHX_ SvRV(target), SvRV(self));
		if ( sv ) {
			RETVAL = SvREFCNT_inc(sv); /* retval mortalizes */
		} else {
			XSRETURN_EMPTY;
		}
	OUTPUT: RETVAL

SV *
clear (SV *self, SV *target)
	PREINIT:
		SV *sv;
	CODE:
	   	sv = magical_hooker_decoration_clear(aTHX_ SvRV(target), SvRV(self));
		if ( sv ) {
			RETVAL = SvREFCNT_inc(sv); /* retval mortalizes */
		} else {
			XSRETURN_EMPTY;
		}
	OUTPUT: RETVAL
