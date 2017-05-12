#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#undef NDEBUG
#include <assert.h>

static int duphook(pTHX_ MAGIC *mg, CLONE_PARAMS *param);
static MGVTBL vtbl = {
    .svt_dup = &duphook
};

static int duphook(pTHX_ MAGIC *mg, CLONE_PARAMS *param)
{
    /*Make sure our CLONE gets called first*/
    av_unshift(param->stashes, 1);
    HV *mystash = gv_stashpv("Devel::PtrTable", 0);
    SvREFCNT_inc(mystash);
    av_store(param->stashes, 0, (SV*)mystash);
    mg->mg_ptr = (char*)ptr_table_new();
}

void _PtrTable_init(SV *self)
{
    MAGIC *mg = sv_magicext(SvRV(self), NULL, PERL_MAGIC_ext, &vtbl, NULL, 0);
    mg->mg_flags |= MGf_DUP;
}

static inline PTR_TBL_t*
get_our_table(SV *self)
{
    MAGIC *mg;
    for(mg = mg_find(SvRV(self), PERL_MAGIC_ext);
        mg;
        mg = mg->mg_moremagic
    ) {
        if(mg->mg_virtual == &vtbl) {
            break;
        }
    }
    
    if(!mg) {
        sv_dump(self);
        die("Couldn't find our magic!");
    }
    return (PTR_TBL_t*)mg->mg_ptr;
}

void _PtrTable_make_our_table(SV *self)
{    
    PTR_TBL_t *our_table = get_our_table(self);
    assert(PL_ptr_table);
    UV max = PL_ptr_table->tbl_max;
    UV i = 0;
    PTR_TBL_ENT_t *head_ent;
    for(i = 0; i <= max; i++) {
        for(head_ent = PL_ptr_table->tbl_ary[i];
            head_ent;
            head_ent = head_ent->next)
        {
            ptr_table_store(our_table, head_ent->oldval, head_ent->newval);
        }
    }
}

SV *_PtrTable_get(SV *self, UV addr)
{
    PTR_TBL_t *our_table = get_our_table(self);
    SV *ret = ptr_table_fetch(our_table, (void*)addr);
    if(!ret) {
        ret = &PL_sv_undef;
    } else {
        ret = newRV_inc(ret);
    }
    /*else*/
    return ret;
}

void _PtrTable_freecopied(SV *self)
{
    PTR_TBL_t *our_table = get_our_table(self);
    ptr_table_free(our_table);
}
MODULE = Devel::PtrTable	PACKAGE = Devel::PtrTable	

PROTOTYPES: DISABLE


void
_PtrTable_init (self)
	SV *	self
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	_PtrTable_init(self);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

void
_PtrTable_make_our_table (self)
	SV *	self
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	_PtrTable_make_our_table(self);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

SV *
_PtrTable_get (self, addr)
	SV *	self
	UV	addr

void
_PtrTable_freecopied (self)
	SV *	self
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	_PtrTable_freecopied(self);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

