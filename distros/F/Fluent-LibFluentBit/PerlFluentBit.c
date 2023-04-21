#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlFluentBit.h"

SV* PerlFluentBit_set_mg(SV *obj, MGVTBL *mg_vtbl, void *ptr) {
	MAGIC *mg= NULL;
	
	if (!sv_isobject(obj))
		croak("Can't add magic to non-object");
	
	/* Search for existing Magic that would hold this pointer */
	for (mg = SvMAGIC(SvRV(obj)); mg; mg = mg->mg_moremagic) {
		if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == mg_vtbl) {
			mg->mg_ptr= ptr;
			return obj;
		}
	}
	sv_magicext(SvRV(obj), NULL, PERL_MAGIC_ext, mg_vtbl, (const char *) ptr, 0);
	return obj;
}

void* PerlFluentBit_get_mg(SV *obj, MGVTBL *mg_vtbl) {
	MAGIC *mg= NULL;
	if (sv_isobject(obj)) {
		for (mg = SvMAGIC(SvRV(obj)); mg; mg = mg->mg_moremagic) {
			if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == mg_vtbl)
				return (void*) mg->mg_ptr;
		}
	}
	return NULL;
}

SV * PerlFluentBit_wrap_ctx(flb_ctx_t *ctx) {
	SV *self;
	if (!ctx) return &PL_sv_undef;
	self= newRV_noinc((SV*)newHV());
	sv_bless(self, gv_stashpv("Fluent::LibFluentBit", GV_ADD));
	PerlFluentBit_set_ctx_mg(self, ctx);
	return self;
}

/*------------------------------------------------------------------------------------------------
 * Set up the vtable structs for applying magic
 */

static int PerlFluentBit_mg_nodup(pTHX_ MAGIC *mg, CLONE_PARAMS *param) {
	croak("Can't share LibFluentBit objects across perl iThreads");
	return 0;
}
#ifdef MGf_LOCAL
static int PerlFluentBit_mg_nolocal(pTHX_ SV *var, MAGIC* mg) {
	croak("Can't share LibFluentBit objects across perl iThreads");
	return 0;
}
#endif

int PerlFluentBit_ctx_mg_free(pTHX_ SV *inst_sv, MAGIC *mg) {
	flb_ctx_t *ctx= (flb_ctx_t *) mg->mg_ptr;
	if (ctx) {
		flb_destroy(ctx);
		mg->mg_ptr= NULL;
	}
	return 0;
}

MGVTBL PerlFluentBit_ctx_mg_vtbl= {
	0, /* get */ 0, /* write */ 0, /* length */ 0, /* clear */
	PerlFluentBit_ctx_mg_free,
	0, PerlFluentBit_mg_nodup
#ifdef MGf_LOCAL
	, PerlFluentBit_mg_nolocal
#endif
};
