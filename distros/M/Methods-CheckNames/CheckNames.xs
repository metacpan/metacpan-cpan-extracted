#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_sv_2pv_flags_GLOBAL
#include "ppport.h"

#ifndef SvPAD_TYPED
#define SvPAD_TYPED(sv) \
	(SvFLAGS(sv) & SVpad_TYPED)
#endif

#if PERL_VERSION < 6
#ifdef PERL_OBJECT
#define PL_check this->check
#else
#define PL_check check
#endif
#endif

#if PERL_REVISION == 5 && PERL_VERSION >= 10
#define HAS_HINTS_HASH
#endif

#include "hook_op_check.h"
#include "hook_op_ppaddr.h"

typedef struct userdata_St {
    hook_op_check_id eval_hook;
    SV *class;
} userdata_t;

STATIC char *
get_method_op_name(pTHX_ OP *cvop) {
#if PERL_VERSION >= 6
	if (cvop->op_type == OP_METHOD_NAMED) {
		SV *method_name = ((SVOP *)cvop)->op_sv;
		return SvPV_nolen(method_name);
	} else {
		return NULL;
	}
#else
	if ( cvop->op_type == OP_METHOD ) {
		OP *constop = ((UNOP*)cvop)->op_first;
		if ( constop->op_type == OP_CONST ) {
			SV *method_name = ((SVOP *)constop)->op_sv;
			if ( SvPOK(method_name) )
				return SvPV_nolen(method_name);
		}
	}
	return NULL;
#endif
}

STATIC SV *
get_inv_sv(pTHX_ OP *o2) {
	if (o2->op_type == OP_PADSV) {
		SV **lexname = av_fetch(PL_comppad_name, o2->op_targ, TRUE);
		return lexname ? *lexname : NULL;
	}

	return NULL;
}

STATIC HV *
get_inv_stash(pTHX_ SV *lexname) {
#ifdef SVpad_TYPED
	if (SvPAD_TYPED(lexname))
#endif
		return SvSTASH(lexname);
	return NULL;
}

OP *
mcn_ck_entersub(pTHX_ OP *o, void *ud) {
	OP *prev = ((cUNOPo->op_first->op_sibling) ? cUNOPo : ((UNOP*)cUNOPo->op_first))->op_first;
	OP *o2 = prev->op_sibling;
	OP *cvop;
	char *name;

    PERL_UNUSED_ARG (ud);

	for (cvop = o2; cvop->op_sibling; cvop = cvop->op_sibling);

	if ((name = get_method_op_name(aTHX_ cvop))) {
		SV *lexname = get_inv_sv(aTHX_ o2);

		if ( lexname ) {
			HV *stash = get_inv_stash(aTHX_ lexname);

			if ( stash ) {
				/* FIXME add a hook if SvSTASH has meta, to let roles, metaclasses
				 * etc verify themselves */
				GV *gv = gv_fetchmethod(stash, name);

				if (!gv)
					Perl_croak(aTHX_ "No such method \"%s\" " 
							"for variable %s of type %s", 
							name, SvPV_nolen(lexname), HvNAME(stash));
			}
		}
	}

	return o;
}

STATIC OP *
before_eval (pTHX_ OP *op, void *user_data)
{
    dSP;
    SV *sv, **stack;
    SV *class = (SV *)user_data;

#ifdef HAS_HINTS_HASH
    if (PL_op->op_private & OPpEVAL_HAS_HH) {
        stack = &SP[-1];
    }
    else {
        stack = &SP[0];
    }
#else
    stack = &SP[0];
#endif

    sv = *stack;

    if (SvPOK (sv)) {
        /* FIXME: leak */
        SV *new = newSVpvs ("use ");
        sv_catsv (new, class);
        sv_catpvs (new, ";");
        sv_catsv (new, sv);
        *stack = new;
    }

    return op;
}

STATIC OP *
mangle_eval (pTHX_ OP *op, void *user_data)
{
    userdata_t *ud = (userdata_t *)user_data;

    /* there isn't a good way of attaching free hooks to ops yet, so we'll just
     * leak this scalar */
    hook_op_ppaddr_around (op, before_eval, NULL, newSVsv (ud->class));

    return op;
}

MODULE = Methods::CheckNames	PACKAGE = Methods::CheckNames

PROTOTYPES: ENABLE

hook_op_check_id
setup (class)
        SV *class;
    PREINIT:
        userdata_t *ud;
    INIT:
        Newx (ud, 1, userdata_t);
    CODE:
        ud->class = newSVsv (class);
        ud->eval_hook = hook_op_check (OP_ENTEREVAL, mangle_eval, ud);
        RETVAL = hook_op_check (OP_ENTERSUB, mcn_ck_entersub, ud);
    OUTPUT:
        RETVAL

void
teardown (class, hook)
        hook_op_check_id hook
    PREINIT:
        userdata_t *ud;
    CODE:
        ud = (userdata_t *)hook_op_check_remove (OP_ENTERSUB, hook);
        if (ud) {
            (void)hook_op_check_remove (OP_ENTEREVAL, ud->eval_hook);
            SvREFCNT_dec (ud->class);
            Safefree (ud);
        }
