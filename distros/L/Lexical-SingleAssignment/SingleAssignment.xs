#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_ptr_table_new
#define NEED_ptr_table_fetch
#define NEED_ptr_table_store
#define NEED_ptr_table_free
#include "ppport.h"

#ifndef ptr_table_new
#include "ptable.h"
#define ptr_table_new PTABLE_new
#define ptr_table_fetch PTABLE_fetch
#define ptr_table_store PTABLE_store
#define ptr_table_free PTABLE_free
#endif


#include "hook_op_check.h"


#define MY_CXT_KEY "Lexical::SingleAssignment::_guts" XS_VERSION

typedef struct {
	PTR_TBL_t *padop_table;
	int padop_table_refcount;
} my_cxt_t;

START_MY_CXT



/* post hook for sassign that marks SVs as readonly */
STATIC OP *
pp_sassign_readonly (pTHX) {
	dSP;

	OP *ret = PL_ppaddr[OP_SASSIGN](aTHXR);

	SPAGAIN;

	assert(SvPADMY(TOPs));

	SvREADONLY_on(TOPs);

	return ret;
}

/* post hook for aassign that marks SVs as readonly */
STATIC OP *
pp_aassign_readonly (pTHX) {
	dSP;
	SV **lvalues;
	SV **first = &PL_stack_base[TOPMARK + 1];
	int items = 1 + ( SP - first );

	/* save pointers to all the SVs being assigned to*/
	Newx(lvalues, items, SV *);
	save_freepv(lvalues);

	Copy(first, lvalues, items, SV *);

	/* perform the assignment */
	OP *ret = PL_ppaddr[OP_AASSIGN](aTHXR);

	/* make all the values readonly, including all child elements for container
	 * types */
	while ( items ) {
		SV *sv = lvalues[--items];

		assert(SvPADMY(sv));

		if ( SvTYPE(sv) == SVt_PVAV ) {
			AV *av = (AV *)sv;
			SV **array = AvARRAY(av);
			int i;

			for ( i = 0; i < AvMAX(av); i++ ) {
				SvREADONLY_on(array[i]);
			}
		} else if ( SvTYPE(sv) == SVt_PVHV ) {
			/* this is like Hash::Util::lock_hash */
			HV *hv = (HV *)sv;
			HE *he;
			SV *val;

			hv_iterinit(hv);

			while ( he = hv_iternext(hv) ) {
				SvREADONLY_on(hv_iterval(hv, he));
			}
		}

		SvREADONLY_on(sv);
	}

	return ret;
}




STATIC OP *
lsa_ck_sassign(pTHX_ OP *o, void *ud) {
	OP *rvalue = cBINOPo->op_first;

	if ( rvalue ) {
		OP *lvalue = rvalue->op_sibling;

		if ( lvalue ) {
			switch ( lvalue->op_type ) {
				case OP_PADSV:
				case OP_PADHV:
				case OP_PADAV:
					/* the op for the lvalue SV is a pad op */
					if ( lvalue->op_private & OPpLVAL_INTRO ) {
						/* this is the first instance of the variable, where it's declared */
						if ( o->op_ppaddr == PL_ppaddr[OP_SASSIGN] ) {
							o->op_ppaddr = pp_sassign_readonly;
						} else {
							warn("Not overriding assignment op (already augmented)");
						}

						/* mark this op as accounted for, see delayed_ck_padany */
						assert(MY_CXT.padop_table != NULL);
						ptr_table_store(MY_CXT.padop_table, lvalue, NULL);
					} else if ( ptr_table_fetch(MY_CXT.padop_table, lvalue) ) {
						croak("Assignment to lexical allowed only in declaration");
					}
			}
		}
	}

	return o;
}

STATIC OP *
lsa_ck_aassign(pTHX_ OP *o, void *ud) {
	LISTOP *lvalues = (LISTOP *)cBINOPo->op_first->op_sibling;
	OP *lvalue;
	bool augment_readonly = FALSE;

	for ( lvalue = lvalues->op_first->op_sibling; lvalue; lvalue = lvalue->op_sibling ) {
		switch ( lvalue->op_type ) {
			case OP_PADSV:
			case OP_PADHV:
			case OP_PADAV:
				if ( lvalue->op_private & OPpLVAL_INTRO ) {
					augment_readonly = TRUE;
					assert(MY_CXT.padop_table != NULL);
					ptr_table_store(MY_CXT.padop_table, lvalue, NULL);
				} else if ( ptr_table_fetch(MY_CXT.padop_table, lvalue) ) {
					croak("Assignment to lexical allowed only in declaration");
				}
		}
	}

	if ( augment_readonly ) {
		if ( o->op_ppaddr == PL_ppaddr[OP_AASSIGN] ) {
			o->op_ppaddr = pp_aassign_readonly;
		} else {
			warn("Not overriding assignment op (already augmented)");
		}
	}

	return o;
}

/* since the pad op is not yet ready at padany check time, SAVEDESTRUCTOR_X is
 * used to defer a check until later
 *
 * if by the time delayed_ck_padany is invoked on the pad op no sassign or
 * aassign opcheck has marked this op as accounted for in an assignment, this
 * means the op is declaring a variable but there is no initialization. */
STATIC void
delayed_ck_padany(pTHX_ OP *o) {
	assert(MY_CXT.padop_table != NULL);

	switch ( o->op_type ) {
		case OP_PADSV:
		case OP_PADHV:
		case OP_PADAV:
			if ( o->op_private & OPpLVAL_INTRO ) {
				if ( ptr_table_fetch(MY_CXT.padop_table, o) ) {
					/* FIXME the table contains PL_curcup at check time, use it
					 * for a better error message */
					if ( PL_in_eval && !(PL_in_eval & EVAL_KEEPERR) ) {
						/* only die if we're not already dying due to some
						 * other error */
						croak("Declaration of lexical without assignment");
					}
				}

				break;
			}

			/* fall through */
		default:
			ptr_table_store(MY_CXT.padop_table, o, NULL);
	}
}

STATIC OP *
lsa_ck_padany(pTHX_ OP *o, void *ud) {
	assert(MY_CXT.padop_table != NULL);

	ptr_table_store(MY_CXT.padop_table, (void *)o, (void *)&PL_curcop);
	SAVEDESTRUCTOR_X(delayed_ck_padany, (void *)o);
	return o;
}

MODULE = Lexical::SingleAssignment	PACKAGE = Lexical::SingleAssignment

PROTOTYPES: ENABLE

BOOT:
{
	MY_CXT.padop_table = NULL;
	MY_CXT.padop_table_refcount = 0;
}

hook_op_check_id
setup_sassign (class)
        SV *class;
    CODE:
        RETVAL = hook_op_check (OP_SASSIGN, lsa_ck_sassign, NULL);
    OUTPUT:
        RETVAL

void
teardown_sassign (class, hook)
        hook_op_check_id hook
    CODE:
        (void)hook_op_check_remove (OP_SASSIGN, hook);


hook_op_check_id
setup_aassign (class)
        SV *class;
    CODE:
        RETVAL = hook_op_check (OP_AASSIGN, lsa_ck_aassign, NULL);
    OUTPUT:
        RETVAL

void
teardown_aassign (class, hook)
        hook_op_check_id hook
    CODE:
        (void)hook_op_check_remove (OP_AASSIGN, hook);




hook_op_check_id
setup_padany (class)
        SV *class;
    CODE:

        RETVAL = hook_op_check (OP_PADANY, lsa_ck_padany, NULL);
    OUTPUT:
        RETVAL

void
teardown_padany (class, hook)
        hook_op_check_id hook
    CODE:
        (void)hook_op_check_remove (OP_PADANY, hook);



void ptable_refcount_inc (class)
		SV *class;
	CODE:
		if ( !MY_CXT.padop_table ) {
			assert( MY_CXT.ptable_refcount == 0 );
			MY_CXT.padop_table = ptr_table_new();
		}

		MY_CXT.padop_table_refcount++;
		assert( MY_CXT.padop_table_refcount > 0 );

void ptable_refcount_dec (class)
		SV *class;
	CODE:
		assert( MY_CXT.padop_table != NULL );
		assert( MY_CXT.padop_table_refcount > 0 );

		if ( MY_CXT.padop_table_refcount-- == 0 ) {
			ptr_table_free(MY_CXT.padop_table);
			MY_CXT.padop_table = NULL;
		}
