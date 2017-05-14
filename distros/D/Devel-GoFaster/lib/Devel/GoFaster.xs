#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#define PERL_DECIMAL_VERSION \
	PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define PERL_VERSION_GE(r,v,s) \
	(PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))

#ifndef EXPECT
# ifdef __GNUC__
#  define EXPECT(e, v) __builtin_expect(e, v)
# else /* !__GNUC__ */
#  define EXPECT(e, v) (e)
# endif /* !__GNUC__ */
#endif /* !EXPECT */

#define likely(t) EXPECT(!!(t), 1)
#define unlikely(t) EXPECT(!!(t), 0)

#ifndef PERL_STATIC_INLINE
# define PERL_STATIC_INLINE static
#endif /* !PERL_STATIC_INLINE */

#ifndef newSVpvs_share
# ifdef newSVpvn_share
#  define newSVpvs_share(STR) newSVpvn_share(""STR"", sizeof(STR)-1, 0)
# else /* !newSVpvn_share */
#  define newSVpvs_share(STR) newSVpvn(""STR"", sizeof(STR)-1)
#  define SvSHARED_HASH(SV) 0
# endif /* !newSVpvn_share */
#endif /* !newSVpvs_share */

#ifndef TAINTING_get
# define TAINTING_get PL_tainting
#endif /* !TAINTING_get */

#ifndef TAINT_get
# define TAINT_get PL_tainted
#endif /* !TAINT_get */

#ifndef op_clear
# define op_clear(o) Perl_op_clear(aTHX_ o)
#endif /* !op_clear */

#ifndef SvSHARED_HASH
# define SvSHARED_HASH(SV) SvUVX(SV)
#endif /* !SvSHARED_HASH */

#ifndef SvREFCNT_inc_NN
# define SvREFCNT_inc_NN SvREFCNT_inc
#endif /* !SvREFCNT_inc_NN */

#ifndef SvREFCNT_inc_simple
# define SvREFCNT_inc_simple SvREFCNT_inc
#endif /* !SvREFCNT_inc_simple */

#ifndef SvREFCNT_inc_simple_NN
# define SvREFCNT_inc_simple_NN SvREFCNT_inc_NN
#endif /* !SvREFCNT_inc_simple_NN */

#ifndef SvREFCNT_inc_void
# define SvREFCNT_inc_void(sv) ((void) SvREFCNT_inc(sv))
#endif /* !SvREFCNT_inc_void */

#ifndef SvREFCNT_inc_void_NN
# define SvREFCNT_inc_void_NN(sv) ((void) SvREFCNT_inc_NN(sv))
#endif /* !SvREFCNT_inc_void_NN */

#ifndef SvREFCNT_inc_simple_void
# define SvREFCNT_inc_simple_void(sv) ((void) SvREFCNT_inc_simple(sv))
#endif /* !SvREFCNT_inc_simple_void */

#ifndef SvREFCNT_inc_simple_void_NN
# define SvREFCNT_inc_simple_void_NN(sv) ((void) SvREFCNT_inc_simple_NN(sv))
#endif /* !SvREFCNT_inc_simple_void_NN */

#ifndef SvREFCNT_dec_NN
# define SvREFCNT_dec_NN SvREFCNT_dec
#endif /* !SvREFCNT_dec_NN */

#ifndef MY_CXT_CLONE
# ifdef PERL_IMPLICIT_CONTEXT
#  define MY_CXT_CLONE \
	dMY_CXT_SV; \
	my_cxt_t *my_cxtp = (my_cxt_t*)SvPVX(newSV(sizeof(my_cxt_t)-1)); \
	Copy(INT2PTR(my_cxt_t*, SvUV(my_cxt_sv)), my_cxtp, 1, my_cxt_t); \
	sv_setuv(my_cxt_sv, PTR2UV(my_cxtp))
# else /* !PERL_IMPLICIT_CONTEXT */
#  define MY_CXT_CLONE NOOP
# endif /* !PERL_IMPLICIT_CONTEXT */
#endif /* !MY_CXT_CLONE */

#ifndef Newx
# define Newx(v,n,t) New(0,v,n,t)
#endif /* !Newx */

#define QHAVE_RPEEPP PERL_VERSION_GE(5,13,5)
#define QHAVE_PEEPP PERL_VERSION_GE(5,7,3)
#define QCAN_PEEP (QHAVE_PEEPP || QHAVE_RPEEPP)
#define QSHIFT_HANDLES_SPECIAL PERL_VERSION_GE(5,13,1)

#if defined(pp_dor) || PERL_VERSION_GE(5,9,0)
# define QHAVE_DOR 1
# define case_OP_DOR_ case OP_DOR:
# define case_OP_DORASSIGN_ case OP_DORASSIGN:
#else /* !pp_dor && <5.9.0 */
# define QHAVE_DOR 0
# define case_OP_DOR_
# define case_OP_DORASSIGN_
#endif /* !pp_dor && <5.9.0 */
#if PERL_VERSION_GE(5,9,3)
# define case_OP_ENTERWHEN_ case OP_ENTERWHEN:
#else /* <5.9.3 */
# define case_OP_ENTERWHEN_
#endif /* <5.9.3 */
#if PERL_VERSION_GE(5,10,0)
# define case_OP_ONCE_ case OP_ONCE:
#else /* <5.10.0 */
# define case_OP_ONCE_
#endif /* <5.10.0 */

#if QCAN_PEEP

# define is_std_op(o, type) \
	((o)->op_type == (type) && (o)->op_ppaddr == PL_ppaddr[(type)])

# ifdef OPpPAD_STATE
#  define is_simple_padsv_op(o) \
	(is_std_op((o), OP_PADSV) && \
		!((o)->op_private & (OPpDEREF|OPpPAD_STATE)))
# else /* !OPpPAD_STATE */
#  define is_simple_padsv_op(o) \
	(is_std_op((o), OP_PADSV) && !((o)->op_private & OPpDEREF))
# endif /* !OPpPAD_STATE */

# ifdef OPpASSIGN_CV_TO_GV
#  define is_simple_sassign_op(o) \
	(is_std_op((o), OP_SASSIGN) && \
		!((o)->op_private & (OPpASSIGN_BACKWARDS|OPpASSIGN_CV_TO_GV)))
# else /* !OPpASSIGN_CV_TO_GV */
#  define is_simple_sassign_op(o) \
	(is_std_op((o), OP_SASSIGN) && !((o)->op_private & OPpASSIGN_BACKWARDS))
# endif /* !OPpASSIGN_CV_TO_GV */

# if QSHIFT_HANDLES_SPECIAL
#  define is_shift_defav_op(o) \
	(is_std_op((o), OP_SHIFT) && ((o)->op_flags & OPf_SPECIAL))
# else /* !QSHIFT_HANDLES_SPECIAL */
static OP *THX_pp_shift_defav(pTHX)
{
	AV *argav = GvAV(PL_defgv);
	SV *valsv = av_shift(argav);
	if(unlikely(AvREAL(argav))) sv_2mortal(valsv);
	if(GIMME_V != G_VOID) {
		dSP;
		XPUSHs(valsv);
		PUTBACK;
	}
	return PL_op->op_next;
}
#  define is_shift_defav_op(o) \
	((o)->op_type == OP_CUSTOM && (o)->op_ppaddr == THX_pp_shift_defav)
# endif /* !QSHIFT_HANDLES_SPECIAL */

static OP *THX_pp_padsv_from_shift(pTHX)
{
	OP *op = PL_op;
	AV *argav = GvAV(PL_defgv);
	SV *valsv = av_shift(argav);
	SV **padentry = &PAD_SVl(op->op_targ);
	SV *padsv = *padentry;
	U8 altval;
	if(unlikely(AvREAL(argav))) sv_2mortal(valsv);
	if(likely(op->op_flags & OPf_SPECIAL)) save_clearsv(padentry);
	if(unlikely(GIMME_V != G_VOID)) {
		dSP;
		XPUSHs(padsv);
		PUTBACK;
	}
	if(unlikely(TAINTING_get) && unlikely(TAINT_get) && !SvTAINTED(valsv))
		TAINT_NOT;
	altval = op->op_private;
	SvGETMAGIC(valsv);
	if(unlikely(altval != 0x80) && unlikely(!SvOK(valsv))) {
		sv_setiv(padsv, (altval & 0x80) ? ((IV)altval) - 0x100 :
						(IV)altval);
	} else {
		sv_setsv_nomg(padsv, valsv);
	}
	SvSETMAGIC(padsv);
	return op->op_next;
}

#define MY_CXT_KEY "Devel::GoFaster::_guts"XS_VERSION
typedef struct {
	SV *hint_on_key_sv;
	U32 hint_on_key_hash;
	SV *global_on_sv;
# if QHAVE_RPEEPP
	void (*THX_next_rpeep)(pTHX_ OP*);
# else /* !QHAVE_RPEEPP */
	void (*THX_next_peep)(pTHX_ OP*);
# endif /* !QHAVE_RPEEPP */
} my_cxt_t;
START_MY_CXT

# define going_faster() THX_going_faster(aTHX_ aMY_CXT)
PERL_STATIC_INLINE bool THX_going_faster(pTHX_ pMY_CXT)
{
	HE *ent = hv_fetch_ent(GvHV(PL_hintgv), MY_CXT.hint_on_key_sv, 0,
			MY_CXT.hint_on_key_hash);
	SV *on_sv = ent ? HeVAL(ent) : MY_CXT.global_on_sv;
	return !!SvTRUE(on_sv);
}

PERL_STATIC_INLINE OP *skip_null_ops(OP *o)
{
	while(o && o->op_type == OP_NULL)
		o = o->op_next;
	return o;
}

# define make_op_faster(o) THX_make_op_faster(aTHX_ o)
static void THX_make_op_faster(pTHX_ OP *first)
{
# if QHAVE_DOR
	SV *csv;
	IV civ;
	OP *other, *fourth;
# endif /* QHAVE_DOR */
	OP *second = skip_null_ops(first->op_next);
	OP *third = second ? skip_null_ops(second->op_next) : NULL;
	/*
	 * Turn explicit shift(@_) into an op that has the use of @_
	 * built in.  On sufficiently new Perls that's a standard shift
	 * op using the OPf_SPECIAL flag, which can also be generated
	 * by shift().	(Note that shift() meaning shift(@ARGV) in
	 * the main program is implemented in the shift op checker;
	 * OPf_SPECIAL on shift always refers to @_.)  On older Perls we
	 * supply a custom op, and this optimisation will apply not only
	 * to explicit shift(@_) but also to shift() which expands to it.
	 */
	if(third && is_std_op(first, OP_GV) && cGVOPx_gv(first) == PL_defgv &&
			is_std_op(second, OP_RV2AV) &&
			(second->op_flags & OPf_REF) &&
			!(second->op_private & OPpLVAL_INTRO) &&
			is_std_op(third, OP_SHIFT) &&
			!(third->op_flags & OPf_SPECIAL)) {
		op_clear(first);
# if QSHIFT_HANDLES_SPECIAL
		first->op_type = OP_SHIFT;
		first->op_ppaddr = PL_ppaddr[OP_SHIFT];
		first->op_flags = (first->op_flags & OPf_KIDS) |
			(third->op_flags & ~OPf_KIDS) | OPf_SPECIAL;
# else /* !QSHIFT_HANDLES_SPECIAL */
		first->op_type = OP_CUSTOM;
		first->op_ppaddr = THX_pp_shift_defav;
		first->op_flags = (first->op_flags & OPf_KIDS) |
			(third->op_flags & ~OPf_KIDS);
# endif /* !QSHIFT_HANDLES_SPECIAL */
		first->op_private = 0;
		first->op_targ = third->op_targ;
		second = first->op_next = skip_null_ops(third->op_next);
		third = second ? skip_null_ops(second->op_next) : NULL;
	}
	/*
	 * Turn "my $x = shift" into custom op that avoids putting
	 * anything on the stack.
	 */
	if(third && is_shift_defav_op(first) && is_simple_padsv_op(second) &&
			is_simple_sassign_op(third)) {
		first->op_type = OP_CUSTOM;
		first->op_ppaddr = THX_pp_padsv_from_shift;
		first->op_flags = (first->op_flags & OPf_KIDS) |
			((second->op_flags & OPf_MOD) &&
					(second->op_private & OPpLVAL_INTRO) ?
				OPf_SPECIAL : 0) |
			(third->op_flags & (OPf_MOD|OPf_WANT));
		first->op_private = 0x80;
		first->op_targ = second->op_targ;
		second = first->op_next = skip_null_ops(third->op_next);
		third = second ? skip_null_ops(second->op_next) : NULL;
	}
# if QHAVE_DOR
	/*
	 * Turn "my $x = shift // 1" (for any sufficiently small constant
	 * IV) into custom op that avoids putting anything on the stack.
	 */
	if(third && (fourth = skip_null_ops(third->op_next)) &&
			is_shift_defav_op(first) && is_std_op(second, OP_DOR) &&
			((other = cLOGOPx(second)->op_other),
				is_std_op(other, OP_CONST)) &&
			skip_null_ops(other->op_next) == third &&
			((csv = cSVOPx_sv(other)),
				(SvFLAGS(csv) & (SVf_OK|SVs_GMG)) ==
					(SVf_IOK|SVp_IOK)) &&
			((civ = SvIVX(csv)), civ < 0x80) && civ > -0x80 &&
			(civ >= 0 || !SvIsUV(csv)) &&
			is_simple_padsv_op(third) &&
			is_simple_sassign_op(fourth)) {
		first->op_type = OP_CUSTOM;
		first->op_ppaddr = THX_pp_padsv_from_shift;
		first->op_flags = (first->op_flags & OPf_KIDS) |
			((third->op_flags & OPf_MOD) &&
					(third->op_private & OPpLVAL_INTRO) ?
				OPf_SPECIAL : 0) |
			(fourth->op_flags & (OPf_MOD|OPf_WANT));
		first->op_private = civ & 0xff;
		first->op_targ = third->op_targ;
		second = first->op_next = skip_null_ops(fourth->op_next);
		third = second ? skip_null_ops(second->op_next) : NULL;
	}
# endif /* QHAVE_DOR */
}

# if QHAVE_RPEEPP

static void THX_my_rpeep(pTHX_ OP *first)
{
	dMY_CXT;
	if(going_faster()) {
		OP *o, *t;
		for(t = o = first; o; o = o->op_next, t = t->op_next) {
			make_op_faster(o);
			o = o->op_next;
			if(!o || o == t) break;
			make_op_faster(o);
		}
	}
	return MY_CXT.THX_next_rpeep(aTHX_ first);
}

# else /* !QHAVE_RPEEPP */

#  ifndef ptr_table_new

struct q_ptr_tbl_ent {
	struct q_ptr_tbl_ent *next;
	void *from, *to;
};

#  undef PTR_TBL_t
#  define PTR_TBL_t struct q_ptr_tbl_ent *

#  define ptr_table_new() THX_ptr_table_new(aTHX)
static PTR_TBL_t *THX_ptr_table_new(pTHX)
{
	PTR_TBL_t *tbl;
	Newx(tbl, 1, PTR_TBL_t);
	*tbl = NULL;
	return tbl;
}

#  define ptr_table_free(tbl) THX_ptr_table_free(aTHX_ tbl)
static void THX_ptr_table_free(pTHX_ PTR_TBL_t *tbl)
{
	struct q_ptr_tbl_ent *ent = *tbl;
	Safefree(tbl);
	while(ent) {
		struct q_ptr_tbl_ent *nent = ent->next;
		Safefree(ent);
		ent = nent;
	}
}

#  define ptr_table_store(tbl, from, to) \
	THX_ptr_table_store(aTHX_ tbl, from, to)
static void THX_ptr_table_store(pTHX_ PTR_TBL_t *tbl, void *from, void *to)
{
	struct q_ptr_tbl_ent *ent;
	Newx(ent, 1, struct q_ptr_tbl_ent);
	ent->next = *tbl;
	ent->from = from;
	ent->to = to;
	*tbl = ent;
}

#  define ptr_table_fetch(tbl, from) THX_ptr_table_fetch(aTHX_ tbl, from)
static void *THX_ptr_table_fetch(pTHX_ PTR_TBL_t *tbl, void *from)
{
	struct q_ptr_tbl_ent *ent;
	for(ent = *tbl; ent; ent = ent->next) {
		if(ent->from == from) return ent->to;
	}
	return NULL;
}

# endif /* !ptr_table_new */


# define my_peep_rec(seen, o) THX_my_peep_rec(aTHX_ seen, o)
static void THX_my_peep_rec(pTHX_ PTR_TBL_t *seen, OP *o)
{
	for(; o && !ptr_table_fetch(seen, o); o = o->op_next) {
		ptr_table_store(seen, o, o);
		make_op_faster(o);
		switch(o->op_type) {
			case OP_AND:
			case OP_OR:
			case_OP_DOR_
			case OP_COND_EXPR:
			case OP_MAPWHILE:
			case OP_GREPWHILE:
			case OP_ANDASSIGN:
			case OP_ORASSIGN:
			case_OP_DORASSIGN_
			case OP_RANGE:
			case_OP_ONCE_
			case_OP_ENTERWHEN_
			case OP_ENTERTRY: {
				my_peep_rec(seen, cLOGOPx(o)->op_other);
			} break;
			case OP_ENTERLOOP:
			case OP_ENTERITER: {
				my_peep_rec(seen, cLOOPx(o)->op_redoop);
				my_peep_rec(seen, cLOOPx(o)->op_nextop);
				my_peep_rec(seen, cLOOPx(o)->op_lastop);
			} break;
			case OP_SUBST: {
				my_peep_rec(seen, cPMOPx(o)->
# if PERL_VERSION_GE(5,9,5)
					op_pmstashstartu.
# endif /* >=5.9.5 */
					op_pmreplstart);
			} break;
		}
	}
}

static void THX_my_peep(pTHX_ OP *first)
{
	dMY_CXT;
	if(going_faster()) {
		PTR_TBL_t *seen = ptr_table_new();
		my_peep_rec(seen, first);
		ptr_table_free(seen);
	}
	return MY_CXT.THX_next_peep(aTHX_ first);
}

# endif /* !QHAVE_RPEEPP */

#endif /* QCAN_PEEP */

MODULE = Devel::GoFaster PACKAGE = Devel::GoFaster

PROTOTYPES: DISABLE

BOOT:
{
#if QCAN_PEEP
	MY_CXT_INIT;
	MY_CXT.hint_on_key_sv = newSVpvs_share("Devel::GoFaster/on");
	MY_CXT.hint_on_key_hash = SvSHARED_HASH(MY_CXT.hint_on_key_sv);
	MY_CXT.global_on_sv =
		SvREFCNT_inc_NN(get_sv("Devel::GoFaster::global_on", GV_ADD));
# if QHAVE_RPEEPP
	MY_CXT.THX_next_rpeep = PL_rpeepp;
	PL_rpeepp = THX_my_rpeep;
# else /* !QHAVE_RPEEPP */
	MY_CXT.THX_next_peep = PL_peepp;
	PL_peepp = THX_my_peep;
# endif /* !QHAVE_RPEEPP */
#endif /* QCAN_PEEP */
}

#ifdef USE_ITHREADS

void CLONE(....)
CODE:
	PERL_UNUSED_VAR(items);
# if QCAN_PEEP
	{
		MY_CXT_CLONE;
		MY_CXT.hint_on_key_sv = newSVpvs_share("Devel::GoFaster/on");
		MY_CXT.global_on_sv =
			SvREFCNT_inc_NN(get_sv("Devel::GoFaster::global_on",
				GV_ADD));
	}
# endif /* QCAN_PEEP */

#endif /* USE_ITHREADS */
