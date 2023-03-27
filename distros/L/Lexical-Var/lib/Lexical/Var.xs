#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define Q_PERL_VERSION_DECIMAL(r,v,s) ((r)*1000000 + (v)*1000 + (s))
#define Q_PERL_DECIMAL_VERSION \
	Q_PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define Q_PERL_VERSION_GE(r,v,s) \
	(Q_PERL_DECIMAL_VERSION >= Q_PERL_VERSION_DECIMAL(r,v,s))
#define Q_PERL_VERSION_LT(r,v,s) \
	(Q_PERL_DECIMAL_VERSION < Q_PERL_VERSION_DECIMAL(r,v,s))

#if Q_PERL_VERSION_LT(5,7,2)
# undef dNOOP
# define dNOOP extern int Perl___notused_func(void)
#endif /* <5.7.2 */

#if Q_PERL_VERSION_LT(5,37,11)
# undef NOOP
# define NOOP ((void)0)
#endif /* <5.37.11 */

#ifndef PERL_UNUSED_VAR
# define PERL_UNUSED_VAR(x) ((void)(x))
#endif /* !PERL_UNUSED_VAR */

#ifndef PERL_UNUSED_ARG
# define PERL_UNUSED_ARG(x) PERL_UNUSED_VAR(x)
#endif /* !PERL_UNUSED_ARG */

#if Q_PERL_VERSION_GE(5,7,3)
# define PERL_UNUSED_THX() NOOP
#else /* <5.7.3 */
# define PERL_UNUSED_THX() ((void)(aTHX+0))
#endif /* <5.7.3 */

#if Q_PERL_VERSION_LT(5,9,3)
# define SVt_LAST (SVt_PVIO+1)
#endif /* <5.9.3 */

#ifdef SVf_PROTECT
# define SvREADONLY_fully_on(sv) (SvFLAGS(sv) |= SVf_READONLY|SVf_PROTECT)
# define SvREADONLY_fully_off(sv) (SvFLAGS(sv) &= ~(SVf_READONLY|SVf_PROTECT))
# define SvREADONLY_slightly_on(sv) (SvFLAGS(sv) |= SVf_READONLY)
# define SvREADONLY_slightly_off(sv) (SvFLAGS(sv) &= ~SVf_READONLY)
#else /* !SVf_PROTECT */
# define SvREADONLY_fully_on(sv) SvREADONLY_on(sv)
# define SvREADONLY_fully_off(sv) SvREADONLY_off(sv)
# define SvREADONLY_slightly_on(sv) SvREADONLY_on(sv)
# define SvREADONLY_slightly_off(sv) SvREADONLY_off(sv)
#endif /* !SVf_PROTECT */

#ifndef sv_setpvs
# define sv_setpvs(SV, STR) sv_setpvn(SV, "" STR "", sizeof(STR)-1)
#endif /* !sv_setpvs */

#ifndef gv_stashpvs
# define gv_stashpvs(name, flags) gv_stashpvn("" name "", sizeof(name)-1, flags)
#endif /* !gv_stashpvs */

#ifndef newSV_type
# define newSV_type(type) THX_newSV_type(aTHX_ type)
static SV *THX_newSV_type(pTHX_ svtype type)
{
	SV *sv = newSV(0);
	(void) SvUPGRADE(sv, type);
	return sv;
}
#endif /* !newSV_type */

#ifndef PadnameIsOUR
# ifdef SvPAD_OUR
#  define PadnameIsOUR(pn) SvPAD_OUR(pn)
# else /* !SvPAD_OUR */
#  define PadnameIsOUR(pn) (SvFLAGS(pn) & SVpad_OUR)
# endif /* !SvPAD_OUR */
#endif /* !PadnameIsOUR */

#ifndef PadnameIsOUR_on
# ifdef SvPAD_OUR_on
#  define PadnameIsOUR_on(pn) SvPAD_OUR_on(pn)
# else /* !SvPAD_OUR_on */
#  define PadnameIsOUR_on(pn) (SvFLAGS(pn) |= SVpad_OUR)
# endif /* !SvPAD_OUR_on */
#endif /* !PadnameIsOUR_on */

#ifndef PadnameOURSTASH
# ifdef SvOURSTASH
#  define PadnameOURSTASH(pn) SvOURSTASH(pn)
# elif defined(OURSTASH)
#  define PadnameOURSTASH(pn) OURSTASH(pn)
# else /* !SvOURSTASH && !OURSTASH */
#  define PadnameOURSTASH(pn) GvSTASH(pn)
# endif /* !SvOURSTASH && !OURSTASH */
#endif /* !PadnameOURSTASH */

#ifndef PadnameOURSTASH_set
# ifdef SvOURSTASH_set
#  define PadnameOURSTASH_set(pn, st) SvOURSTASH_set(pn, st)
# elif defined(OURSTASH_set)
#  define PadnameOURSTASH_set(pn, st) OURSTASH_set(pn, st)
# else /* !SvOURSTASH_set && !OURSTASH_set */
#  define PadnameOURSTASH_set(pn, st) (GvSTASH(pn) = (st))
# endif /* !SvOURSTASH_set && !OURSTASH_set */
#endif /* !PadnameOURSTASH_set */

#ifndef PadnameIsSTATE
# ifdef SvPAD_STATE
#  define PadnameIsSTATE(pn) SvPAD_STATE(pn)
# else /* !SvPAD_STATE */
#  define PadnameIsSTATE(pn) 0
# endif /* !SvPAD_STATE */
#endif /* !PadnameIsSTATE */

#ifndef PadnameIsSTATE_on
# ifdef SvPAD_STATE_on
#  define PadnameIsSTATE_on(pn) SvPAD_STATE_on(pn)
# endif /* SvPAD_STATE_on */
#endif /* !PadnameIsSTATE_on */

#ifndef PadMAX
# define PadlistARRAY(pl) ((PAD**)AvARRAY(pl))
# define PadlistNAMES(pl) (PadlistARRAY(pl)[0])
# define PadMAX(p) AvFILLp(p)
# define PadARRAY(p) AvARRAY(p)
typedef SV PADNAME;
typedef AV PADNAMELIST;
#endif /* !PadMAX */

#ifndef PadnamePV
# define PadnamePV(pn) (SvPOK(pn) ? SvPVX(pn) : NULL)
#endif /* !PadnamePV */

#ifndef PadnameLEN
# define PadnameLEN(pn) SvCUR(pn)
#endif /* !PadnameLEN */

#ifndef PadnameOUTER
# define PadnameOUTER(pn) SvFAKE(pn)
#endif /* !PadnameOUTER */

#if Q_PERL_VERSION_LT(5,8,1)
typedef AV PADLIST;
typedef AV PAD;
#endif /* <5.8.1 */

#ifndef newPADNAMEpvn
# if Q_PERL_VERSION_GE(5,9,4)
#  define SVt_PADNAME SVt_PVMG
# else /* <5.9.4 */
#  define SVt_PADNAME SVt_PVGV
# endif /* <5.9.4 */
# define newPADNAMEpvn(pv, len) THX_newPADNAMEpvn(aTHX_ pv, len)
static PADNAME *THX_newPADNAMEpvn(pTHX_ char const *pv, STRLEN len)
{
	PADNAME *name = newSV_type(SVt_PADNAME);
	sv_setpvn(name, pv, len);
	return name;
}
#endif /* !newPADNAMEpvn */

#ifndef padnamelist_store
# define padnamelist_store av_store
#endif /* !padnamelist_store */

#ifndef padnamelist_fetch
# define padnamelist_fetch(pnl, off) THX_padnamelist_fetch(aTHX_ pnl, off)
static PADNAME *THX_padnamelist_fetch(pTHX_ PADNAMELIST *pnl, PADOFFSET off)
{
	SV **rp = av_fetch(pnl, off, 0);
	return rp ? *rp : NULL;
}
#endif /* !padnamelist_fetch */

#ifndef COP_SEQ_RANGE_LOW
# if Q_PERL_VERSION_GE(5,9,5)
#  define COP_SEQ_RANGE_LOW(sv) ((XPVNV*)SvANY(sv))->xnv_u.xpad_cop_seq.xlow
#  define COP_SEQ_RANGE_HIGH(sv) ((XPVNV*)SvANY(sv))->xnv_u.xpad_cop_seq.xhigh
# else /* <5.9.5 */
#  define COP_SEQ_RANGE_LOW(sv) ((U32)SvNVX(sv))
#  define COP_SEQ_RANGE_HIGH(sv) ((U32)SvIVX(sv))
# endif /* <5.9.5 */
#endif /* !COP_SEQ_RANGE_LOW */

#ifndef COP_SEQ_RANGE_LOW_set
# if Q_PERL_VERSION_GE(5,21,7)
#  define COP_SEQ_RANGE_LOW_set(pn,val) \
	do { (pn)->xpadn_low = (val); } while(0)
#  define COP_SEQ_RANGE_HIGH_set(pn,val) \
	do { (pn)->xpadn_high = (val); } while(0)
# elif Q_PERL_VERSION_GE(5,9,5)
#  define COP_SEQ_RANGE_LOW_set(sv,val) \
	do { ((XPVNV*)SvANY(sv))->xnv_u.xpad_cop_seq.xlow = (val); } while(0)
#  define COP_SEQ_RANGE_HIGH_set(sv,val) \
	do { ((XPVNV*)SvANY(sv))->xnv_u.xpad_cop_seq.xhigh = (val); } while(0)
# else /* <5.9.5 */
#  define COP_SEQ_RANGE_LOW_set(sv,val) SvNV_set(sv, val)
#  define COP_SEQ_RANGE_HIGH_set(sv,val) SvIV_set(sv, val)
# endif /* <5.9.5 */
#endif /* !COP_SEQ_RANGE_LOW_set */

#ifndef PadnameIN_SCOPE
# define PadnameIN_SCOPE(pn, seq) THX_PadnameIN_SCOPE(aTHX_ pn, seq)
static int THX_PadnameIN_SCOPE(pTHX_ PADNAME const *pn, U32 seq)
{
	U32 lowseq = COP_SEQ_RANGE_LOW(pn);
	U32 highseq = COP_SEQ_RANGE_HIGH(pn);
	PERL_UNUSED_THX();
# if Q_PERL_VERSION_GE(5,13,10)
	if(lowseq == PERL_PADSEQ_INTRO) {
		return 0;
	} else if(highseq == PERL_PADSEQ_INTRO) {
		return seq > lowseq ?
			(seq - lowseq) < (U32_MAX>>1) :
			(lowseq - seq) > (U32_MAX>>1);
	} else {
		return lowseq > highseq ?
			seq > lowseq || seq <= highseq :
			seq > lowseq && seq <= highseq;
	}
# else /* <5.13.10 */
	return seq > lowseq && seq <= highseq;
# endif /* <5.13.10 */
}
#endif /* !PadnameIN_SCOPE */

#ifndef COP_SEQMAX_INC
# if Q_PERL_VERSION_GE(5,13,10)
#  define COP_SEQMAX_INC \
	do { \
		PL_cop_seqmax++; \
		if(PL_cop_seqmax == PERL_PADSEQ_INTRO) PL_cop_seqmax++; \
	} while(0)
# else /* <5.13.10 */
#  define COP_SEQMAX_INC ((void)(PL_cop_seqmax++))
# endif /* <5.13.10 */
#endif /* !COP_SEQMAX_INC */

#ifndef SvRV_set
# define SvRV_set(SV, VAL) (SvRV(SV) = (VAL))
#endif /* !SvRV_set */

#ifndef SVfARG
# define SVfARG(p) ((void *)(p))
#endif /* !SVfARG */

#ifndef GV_NOTQUAL
# define GV_NOTQUAL 0
#endif /* !GV_NOTQUAL */

#if Q_PERL_VERSION_LT(5,9,3)
typedef OP *(*Perl_check_t)(pTHX_ OP *);
#endif /* <5.9.3 */

#if Q_PERL_VERSION_LT(5,10,1)
typedef unsigned Optype;
#endif /* <5.10.1 */

#ifndef wrap_op_checker
# define wrap_op_checker(c,n,o) THX_wrap_op_checker(aTHX_ c,n,o)
static void THX_wrap_op_checker(pTHX_ Optype opcode,
	Perl_check_t new_checker, Perl_check_t *old_checker_p)
{
	PERL_UNUSED_THX();
	if(*old_checker_p) return;
	OP_REFCNT_LOCK;
	if(!*old_checker_p) {
		*old_checker_p = PL_check[opcode];
		PL_check[opcode] = new_checker;
	}
	OP_REFCNT_UNLOCK;
}
#endif /* !wrap_op_checker */

/*
 * scalar classification
 *
 * Logic borrowed from Params::Classify.
 */

#define sv_is_glob(sv) (SvTYPE(sv) == SVt_PVGV)

#if Q_PERL_VERSION_GE(5,11,0)
# define sv_is_regexp(sv) (SvTYPE(sv) == SVt_REGEXP)
#else /* <5.11.0 */
# define sv_is_regexp(sv) 0
#endif /* <5.11.0 */

#define sv_is_string(sv) \
	(!sv_is_glob(sv) && !sv_is_regexp(sv) && \
	 (SvFLAGS(sv) & (SVf_IOK|SVf_NOK|SVf_POK|SVp_IOK|SVp_NOK|SVp_POK)))

#define Q_CODE_AS_STATE_IN_PAD Q_PERL_VERSION_GE(5,19,1)
#define Q_CODE_OUTSIDE_PAD Q_PERL_VERSION_LT(5,17,4)
#define Q_CODE_CLASHES_WITH_PAD (!Q_CODE_OUTSIDE_PAD && !Q_CODE_AS_STATE_IN_PAD)

/*
 * newOP_const_identity()
 *
 * This function generate op that evaluates to a fixed object identity
 * and can also participate in constant folding.
 *
 * Lexical::Var generally needs to make ops that evaluate to fixed
 * identities, that being what a name that it handles represents.
 * Normally it can do this by means of an rv2xv op applied to a const op,
 * where the const op holds an RV that references the object of interest.
 * However, rv2xv can't undergo constant folding.  Where the object is
 * a readonly scalar, we'd like it to take part in constant folding.
 * The obvious way to make it work as a constant for folding is to use a
 * const op that directly holds the object.  However, in a Perl built for
 * ithreads, the value in a const op gets moved into the pad to achieve
 * clonability, and in the process the value may be copied rather than the
 * object merely rereferenced.  Generally, the const op only guarantees
 * to provide a fixed *value*, not a fixed object identity.
 *
 * Where a const op might not preserve object identity, we can achieve
 * preservation by means of a customised variant of the const op.  The op
 * directly holds an RV that references the object of interest, and its
 * variant pp function dereferences it (as rv2sv would).  The pad logic
 * operates on the op structure as normal, and may copy the RV without
 * preserving its identity, which is OK because the RV isn't what we
 * need to preserve.  Being labelled as a const op, it is eligible for
 * constant folding.  When actually executed, it evaluates to the object
 * of interest, providing both fixed value and fixed identity.
 */

#ifdef USE_ITHREADS
# define Q_USE_ITHREADS 1
#else /* !USE_ITHREADS */
# define Q_USE_ITHREADS 0
#endif /* !USE_ITHREADS */

#define Q_CONST_COPIES Q_USE_ITHREADS

#if Q_CONST_COPIES
static OP *THX_pp_const_via_ref(pTHX)
{
	dSP;
	SV *reference_sv = cSVOPx_sv(PL_op);
	SV *referent_sv = SvRV(reference_sv);
	XPUSHs(referent_sv);
	RETURN;
}
#endif /* Q_CONST_COPIES */

#define newOP_const_identity(sv) THX_newOP_const_identity(aTHX_ sv)
static OP *THX_newOP_const_identity(pTHX_ SV *sv)
{
#if Q_CONST_COPIES
	OP *op = newSVOP(OP_CONST, 0, newRV_noinc(sv));
	op->op_ppaddr = THX_pp_const_via_ref;
	return op;
#else /* !Q_CONST_COPIES */
	return newSVOP(OP_CONST, 0, sv);
#endif /* !Q_CONST_COPIES */
}

/*
 * %^H key names
 */

#define KEYPREFIX "Lexical::Var/"
#define KEYPREFIXLEN (sizeof(KEYPREFIX)-1)

#define LVOURPREFIX "Lexical::Var::<LVOUR>"
#define LVOURPREFIXLEN (sizeof(LVOURPREFIX)-1)

#define CHAR_IDSTART 0x01
#define CHAR_IDCONT  0x02
#define CHAR_SIGIL   0x10
#define CHAR_USEPAD  0x20

static U8 const char_attr[256] = {
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* NUL to BEL */
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* BS to SI */
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* DLE to ETB */
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* CAN to US */
	0x00, 0x00, 0x00, 0x00, 0x30, 0x30,
		Q_CODE_AS_STATE_IN_PAD ? 0x30 : 0x10,
		0x00, /* SP to ' */
	0x00, 0x00, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, /* ( to / */
	0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, /* 0 to 7 */
	0x02, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* 8 to ? */
	0x30, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, /* @ to G */
	0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, /* H to O */
	0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, /* P to W */
	0x03, 0x03, 0x03, 0x00, 0x00, 0x00, 0x00, 0x03, /* X to _ */
	0x00, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, /* ` to g */
	0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, /* h to o */
	0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, /* p to w */
	0x03, 0x03, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, /* x to DEL */
	0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
	0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
	0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
	0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
	0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
	0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
	0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
	0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
};

#define name_key(sigil, name) THX_name_key(aTHX_ sigil, name)
static SV *THX_name_key(pTHX_ char sigil, SV *name)
{
	char const *p, *q, *end;
	STRLEN len;
	SV *key;
	p = SvPV(name, len);
	end = p + len;
	if(sigil == 'N') {
		sigil = *p++;
		if(!(char_attr[(U8)sigil] & CHAR_SIGIL)) return NULL;
	} else if(sigil == 'P') {
		if(strnNE(p, LVOURPREFIX, LVOURPREFIXLEN)) return NULL;
		p += LVOURPREFIXLEN;
		sigil = *p++;
		if(!(char_attr[(U8)sigil] & CHAR_SIGIL)) return NULL;
		if(p[0] != ':' || p[1] != ':') return NULL;
		p += 2;
	}
	if(!(char_attr[(U8)*p] & CHAR_IDSTART)) return NULL;
	for(q = p+1; q != end; q++) {
		if(!(char_attr[(U8)*q] & CHAR_IDCONT)) return NULL;
	}
	key = sv_2mortal(newSV(KEYPREFIXLEN + 1 + (end-p)));
	sv_setpvs(key, KEYPREFIX "?");
	SvPVX(key)[KEYPREFIXLEN] = sigil;
	sv_catpvn(key, p, end-p);
	return key;
}

/*
 * compiling code that uses Lexical::Var lexical variables
 */

#define gv_mark_multi(name) THX_gv_mark_multi(aTHX_ name)
static void THX_gv_mark_multi(pTHX_ SV *name)
{
	GV *gv;
#ifdef gv_fetchsv
	gv = gv_fetchsv(name, GV_NOADD_NOINIT|GV_NOEXPAND|GV_NOTQUAL,
			SVt_PVGV);
#else /* !gv_fetchsv */
	gv = gv_fetchpv(SvPVX(name), 0, SVt_PVGV);
#endif /* !gv_fetchsv */
	if(gv && SvTYPE(gv) == SVt_PVGV) GvMULTI_on(gv);
}

#define Q_NEED_FAKE_REFERENT Q_PERL_VERSION_LT(5,21,4)

#if Q_NEED_FAKE_REFERENT
# if Q_USE_THREADS
#  define fakeSV_inc() newSV(0)
#  define fakeAV_inc() ((SV*)newAV())
#  define fakeHV_inc() ((SV*)newHV())
# else /* !Q_USE_THREADS */
static SV *fake_sv, *fake_av, *fake_hv;
#  define fakeSV_inc() SvREFCNT_inc(fake_sv)
#  define fakeAV_inc() SvREFCNT_inc(fake_av)
#  define fakeHV_inc() SvREFCNT_inc(fake_hv)
# endif /* !Q_USE_THREADS */
#endif /* Q_NEED_FAKE_REFERENT */

#define myck_rv2xv(o, sigil, THX_nxck) THX_myck_rv2xv(aTHX_ o, sigil, THX_nxck)
static OP *THX_myck_rv2xv(pTHX_ OP *o, char sigil, OP *(*THX_nxck)(pTHX_ OP *o))
{
	OP *c;
	SV *ref, *key;
	HE *he;
	if((o->op_flags & OPf_KIDS) && (c = cUNOPx(o)->op_first) &&
			c->op_type == OP_CONST &&
			(c->op_private & (OPpCONST_ENTERED|OPpCONST_BARE)) &&
			(ref = cSVOPx(c)->op_sv) && SvPOK(ref) &&
			(key = name_key(sigil, ref))) {
		if((he = hv_fetch_ent(GvHV(PL_hintgv), key, 0, 0))) {
			SV *hintref, *referent, *newref;
#if Q_NEED_FAKE_REFERENT
			SV *fake_referent;
#endif /* Q_NEED_FAKE_REFERENT */
			OP *newop;
			U16 type, flags;
#if Q_PERL_VERSION_LT(5,11,2)
			if(sigil == '&' && (c->op_private & OPpCONST_BARE))
				croak("can't reference Lexical::Var "
					"lexical subroutine "
					"without & sigil on this perl");
#endif /* <5.11.2 */
			if(sigil != 'P' || Q_PERL_VERSION_LT(5,8,0)) {
				/*
				 * A bogus symbol lookup has already been
				 * done (by the tokeniser) based on the name
				 * we're using, to support the package-based
				 * interpretation that we're about to
				 * replace.  This can cause bogus "used only
				 * once" warnings.  The best we can do here
				 * is to flag the symbol as multiply-used to
				 * suppress that warning, though this is at
				 * the risk of muffling an accurate warning.
				 */
				gv_mark_multi(ref);
			}
			/*
			 * The base checker for rv2Xv checks that the
			 * item being pointed to by the constant ref is of
			 * an appropriate type.  There are two problems with
			 * this check.  Firstly, it rejects GVs as a scalar
			 * target, whereas they are in fact valid.  (This
			 * is in RT as bug #69456 so may be fixed.)  Second,
			 * and more serious, sometimes a reference is being
			 * constructed through the wrong op type.  An array
			 * indexing expression "$foo[0]" gets constructed as
			 * an rv2sv op, because of the "$" sigil, and then
			 * gets munged later.  We have to detect the real
			 * intended type through the pad entry, which the
			 * tokeniser has worked out in advance, and then
			 * work through the wrong op.  So it's a bit cheeky
			 * for perl to complain about the wrong type here.
			 * We work around it by making the constant ref
			 * initially point to an innocuous item to pass the
			 * type check, then changing it to the real
			 * reference later.
			 */
			hintref = HeVAL(he);
			if(!SvROK(hintref))
				croak("non-reference hint for Lexical::Var");
			referent = SvREFCNT_inc(SvRV(hintref));
			type = o->op_type;
			flags = o->op_flags | (((U16)o->op_private) << 8);
			if(type == OP_RV2SV && sigil == 'P' &&
					SvPVX(ref)[LVOURPREFIXLEN] == '$' &&
					SvREADONLY(referent)) {
				op_free(o);
				return newOP_const_identity(referent);
			}
#if Q_NEED_FAKE_REFERENT
			switch(type) {
				case OP_RV2SV:
					fake_referent = fakeSV_inc();
					break;
				case OP_RV2AV:
					fake_referent = fakeAV_inc();
					break;
				case OP_RV2HV:
					fake_referent = fakeHV_inc();
					break;
				default: fake_referent = NULL; break;
			}
			if(fake_referent) {
				newref = newRV_noinc(fake_referent);
				SvREFCNT_inc(newref);
				newop = newUNOP(type, flags,
						newSVOP(OP_CONST, 0, newref));
				fake_referent = SvRV(newref);
				SvREADONLY_fully_off(newref);
				SvRV_set(newref, referent);
				SvREADONLY_fully_on(newref);
				SvREFCNT_dec(fake_referent);
				SvREFCNT_dec(newref);
			} else
#endif /* Q_NEED_FAKE_REFERENT */
			{
				newref = newRV_noinc(referent);
				newop = newUNOP(type, flags,
						newSVOP(OP_CONST, 0, newref));
			}
			op_free(o);
			return newop;
		} else if(sigil == 'P') {
			SV *newref;
			U16 type, flags;
			/*
			 * Not a name that we have a defined meaning for,
			 * but it has the form of the "our" hack, implying
			 * that we did put an entry in the pad for it.
			 * Munge this back to what it would have been
			 * without the pad entry.  This should mainly
			 * happen due to explicit unimportation, but it
			 * might also happen if the scoping of the pad and
			 * %^H ever get out of synch.
			 */
			newref = newSVpvn(SvPVX(ref)+LVOURPREFIXLEN+3,
						SvCUR(ref)-LVOURPREFIXLEN-3);
			if(SvUTF8(ref)) SvUTF8_on(newref);
			type = o->op_type;
			flags = o->op_flags | (((U16)o->op_private) << 8);
			op_free(o);
			return newUNOP(type, flags,
				newSVOP(OP_CONST, 0, newref));
		}
	}
	return THX_nxck(aTHX_ o);
}

static OP *(*THX_nxck_rv2sv)(pTHX_ OP *o);
static OP *(*THX_nxck_rv2av)(pTHX_ OP *o);
static OP *(*THX_nxck_rv2hv)(pTHX_ OP *o);
static OP *(*THX_nxck_rv2cv)(pTHX_ OP *o);
static OP *(*THX_nxck_rv2gv)(pTHX_ OP *o);

static OP *THX_myck_rv2sv(pTHX_ OP *o) {
	return myck_rv2xv(o, 'P', THX_nxck_rv2sv);
}
static OP *THX_myck_rv2av(pTHX_ OP *o) {
	return myck_rv2xv(o, 'P', THX_nxck_rv2av);
}
static OP *THX_myck_rv2hv(pTHX_ OP *o) {
	return myck_rv2xv(o, 'P', THX_nxck_rv2hv);
}
static OP *THX_myck_rv2cv(pTHX_ OP *o) {
	return myck_rv2xv(o, Q_CODE_AS_STATE_IN_PAD ? 'P' : '&',
		THX_nxck_rv2cv);
}
static OP *THX_myck_rv2gv(pTHX_ OP *o) {
	return myck_rv2xv(o, '*', THX_nxck_rv2gv);
}

/*
 * setting up Lexical::Var lexical names
 */

#if !Q_USE_THREADS
static HV *lvour_sv_stash, *lvour_av_stash, *lvour_hv_stash;
# if Q_CODE_AS_STATE_IN_PAD
static HV *lvour_cv_stash;
# endif /* Q_CODE_AS_STATE_IN_PAD */
#endif /* !Q_USE_THREADS */

#define lvour_stash(sigil) THX_lvour_stash(aTHX_ sigil)
static HV *THX_lvour_stash(pTHX_ char sigil)
{
#if Q_USE_THREADS
	if(sigil == '$' || sigil == '@' || sigil == '%' ||
			(Q_CODE_AS_STATE_IN_PAD && sigil == '&')) {
		char sname[LVOURPREFIXLEN+2];
		memcpy(sname, LVOURPREFIX, LVOURPREFIXLEN);
		sname[LVOURPREFIXLEN] = sigil;
		sname[LVOURPREFIXLEN+1] = 0;
		return gv_stashpvn(sname, LVOURPREFIXLEN+1, GV_ADD);
	} else {
		return NULL;
	}
#else /* !Q_USE_THREADS */
	PERL_UNUSED_THX();
# if Q_CODE_AS_STATE_IN_PAD
	if(sigil == '&') return lvour_cv_stash;
# endif /* Q_CODE_AS_STATE_IN_PAD */
	return sigil == '$' ? lvour_sv_stash : sigil == '@' ? lvour_av_stash :
		sigil == '%' ? lvour_hv_stash : NULL;
#endif /* !Q_USE_THREADS */
}

#define padseq_intro() THX_padseq_intro(aTHX)
static U32 THX_padseq_intro(pTHX)
{
#if Q_PERL_VERSION_GE(5,13,10)
	PERL_UNUSED_THX();
	return PERL_PADSEQ_INTRO;
#elif Q_PERL_VERSION_GE(5,9,5)
	PERL_UNUSED_THX();
	return I32_MAX;
#elif Q_PERL_VERSION_GE(5,9,0)
	PERL_UNUSED_THX();
	return 999999999;
#elif Q_PERL_VERSION_GE(5,8,0)
	static U32 max;
	if(!max) {
		SV *versv = get_sv("]", 0);
		char *verp = SvPV_nolen(versv);
		max = strGE(verp, "5.008009") ? I32_MAX : 999999999;
	}
	return max;
#else /* <5.8.0 */
	PERL_UNUSED_THX();
	return 999999999;
#endif /* <5.8.0 */
}

#define find_compcv(vari_word) THX_find_compcv(aTHX_ vari_word)
static CV *THX_find_compcv(pTHX_ char const *vari_word)
{
	CV *compcv;
#if Q_PERL_VERSION_GE(5,17,5)
	if(!((compcv = PL_compcv) && CvPADLIST(compcv)))
		compcv = NULL;
#else /* <5.17.5 */
	GV *compgv;
	/*
	 * Given that we're being invoked from a BEGIN block,
	 * PL_compcv here doesn't actually point to the sub
	 * being compiled.  Instead it points to the BEGIN block.
	 * The code that we want to affect is the parent of that.
	 * Along the way, better check that we are actually being
	 * invoked that way: PL_compcv may be null, indicating
	 * runtime, or it can be non-null in a couple of
	 * other situations (require, string eval).
	 */
	if(!(PL_compcv && CvSPECIAL(PL_compcv) &&
			(compgv = CvGV(PL_compcv)) &&
			strEQ(GvNAME(compgv), "BEGIN") &&
			(compcv = CvOUTSIDE(PL_compcv)) &&
			CvPADLIST(compcv)))
		compcv = NULL;
#endif /* <5.17.5 */
	if(!compcv)
		croak("can't set up Lexical::Var lexical %s "
			"outside compilation",
			vari_word);
	return compcv;
}

#define setup_pad(compcv, name, referent) \
	THX_setup_pad(aTHX_ compcv, name, referent)
static void THX_setup_pad(pTHX_ CV *compcv, char const *name, SV *referent)
{
	PADLIST *padlist = CvPADLIST(compcv);
	PADNAMELIST *padname = PadlistNAMES(padlist);
	PAD *padvar = PadlistARRAY(padlist)[1];
	PADOFFSET ouroffset;
	PADNAME *ourname;
	SV *ourvar;
#if !Q_CODE_AS_STATE_IN_PAD
	PERL_UNUSED_ARG(referent);
#endif /* !Q_CODE_AS_STATE_IN_PAD */
	ourname = newPADNAMEpvn(name, strlen(name));
	COP_SEQ_RANGE_LOW_set(ourname, PL_cop_seqmax);
	COP_SEQ_RANGE_HIGH_set(ourname, padseq_intro());
	COP_SEQMAX_INC;
#if Q_CODE_AS_STATE_IN_PAD
	if(referent) {
		PadnameIsSTATE_on(ourname);
		ourvar = SvREFCNT_inc(referent);
	} else
#endif /* Q_CODE_AS_STATE_IN_PAD */
	{
		HV *stash = lvour_stash(name[0]);
		PadnameIsOUR_on(ourname);
		PadnameOURSTASH_set(ourname, (HV*)SvREFCNT_inc((SV*)stash));
		ourvar = newSV(0);
		SvPADMY_on(ourvar);
	}
	ouroffset = PadMAX(padvar) + 1;
	padnamelist_store(padname, ouroffset, ourname);
#ifdef PadnamelistMAXNAMED
	PadnamelistMAXNAMED(padname) = ouroffset;
#endif /* PadnamelistMAXNAMED */
	av_store(padvar, ouroffset, ourvar);
	if(PL_comppad == padvar) PL_curpad = PadARRAY(padvar);
}

static int svt_scalar(svtype t)
{
        switch(t) {
		case SVt_NULL: case SVt_IV: case SVt_NV:
#if Q_PERL_VERSION_LT(5,11,0)
		case SVt_RV:
#endif /* <5.11.0 */
		case SVt_PV: case SVt_PVIV: case SVt_PVNV:
		case SVt_PVMG: case SVt_PVLV: case SVt_PVGV:
#if Q_PERL_VERSION_GE(5,11,0)
                case SVt_REGEXP:
#endif /* >=5.11.0 */
			return 1;
		default:
			return 0;
	}
}

enum { PADLOOKUP_NOTHING, PADLOOKUP_STATE, PADLOOKUP_LVOUR, PADLOOKUP_OTHER };

#define pad_lookup(compcv, name, value_ptr) \
	THX_pad_lookup(aTHX_ compcv, name, value_ptr)
static int THX_pad_lookup(pTHX_ CV *compcv, char const *name, SV **value_ptr)
{
	STRLEN namelen = strlen(name);
	CV *cv = compcv;
	U32 seq = PL_cop_seqmax;
	for(; cv;
#ifdef CvOUTSIDE_SEQ
			seq = CvOUTSIDE_SEQ(cv),
#endif /* CvOUTSIDE_SEQ */
			cv = CvOUTSIDE(cv)) {
		PADLIST *padlist = CvPADLIST(cv);
		PADNAMELIST *padname;
		PAD *pad;
		PADOFFSET off;
#ifdef CvOUTSIDE_SEQ
		PADOFFSET outer_off = 0;
#endif /* CvOUTSIDE_SEQ */
		PADNAME *pname;
		if(!padlist) continue;
		padname = PadlistNAMES(padlist);
		pad = PadlistARRAY(padlist)[1];
#ifdef PadnamelistMAXNAMED
		off = PadnamelistMAXNAMED(padname);
#else /* !PadnamelistMAXNAMED */
		off = PadMAX(pad);
#endif /* PadnamelistMAXNAMED */
		for(; off != 0; off--) {
			char *pnamepv;
			pname = padnamelist_fetch(padname, off);
			if(!pname) continue;
#if Q_PERL_VERSION_LT(5,19,3)
			if(pname == &PL_sv_undef) continue;
#endif /* <5.19.3 */
			pnamepv = PadnamePV(pname);
			if(!(pnamepv && PadnameLEN(pname) == namelen &&
					memcmp(pnamepv, name, namelen) == 0))
				continue;
#ifdef CvOUTSIDE_SEQ
			if(PadnameOUTER(pname)) {
				outer_off = off;
				continue;
			}
#endif /* CvOUTSIDE_SEQ */
			if(!PadnameIN_SCOPE(pname, seq)) continue;
#ifdef CvOUTSIDE_SEQ
			found:
#endif /* CvOUTSIDE_SEQ */
			if(PadnameIsSTATE(pname)) {
				*value_ptr = *av_fetch(pad, off, 0);
				return PADLOOKUP_STATE;
			} else if(PadnameIsOUR(pname) &&
					PadnameOURSTASH(pname) ==
						lvour_stash(name[0])) {
				return PADLOOKUP_LVOUR;
			} else {
				return PADLOOKUP_OTHER;
			}
		}
#ifdef CvOUTSIDE_SEQ
		if(outer_off) {
			off = outer_off;
			pname = padnamelist_fetch(padname, off);
			goto found;
		}
#endif /* CvOUTSIDE_SEQ */
	}
	return PADLOOKUP_NOTHING;
}

#define current_referent(key) THX_current_referent(aTHX_ compcv, key)
static SV *THX_current_referent(pTHX_ CV *compcv, SV *key)
{
	static SV sv_other;
	char *keypv = SvPVX(key);
	char sigil = keypv[KEYPREFIXLEN];
	if(!(sigil == '*' || (Q_CODE_OUTSIDE_PAD && sigil == '&'))) {
		SV *state_value;
		int padstate =
			pad_lookup(compcv, keypv+KEYPREFIXLEN, &state_value);
		if(Q_CODE_CLASHES_WITH_PAD && sigil == '&') {
			if(padstate != PADLOOKUP_NOTHING)
				return &sv_other;
		} else {
			if(padstate == PADLOOKUP_NOTHING) return NULL;
			if(Q_CODE_AS_STATE_IN_PAD && sigil == '&' &&
					padstate == PADLOOKUP_STATE)
				return state_value;
			if(padstate != PADLOOKUP_LVOUR)
				return &sv_other;
		}
	}
	{
		SV *cref;
		HE *he = hv_fetch_ent(GvHV(PL_hintgv), key, 0, 0);
		if(!he) return NULL;
		cref = HeVAL(he);
		if(!SvROK(cref)) return &sv_other;
		return SvRV(cref);
	}
}

#if Q_CODE_CLASHES_WITH_PAD
# define check_for_pad_clash(compcv, name) \
	THX_check_for_pad_clash(aTHX_ compcv, name)
static void THX_check_for_pad_clash(pTHX_ CV *compcv, char const *name)
{
	SV *state_value;
	if(name[0] == '&' &&
			pad_lookup(compcv, name, &state_value) !=
				PADLOOKUP_NOTHING)
		croak("can't shadow core lexical subroutine");
}
#else /* !Q_CODE_CLASHES_WITH_PAD */
# define check_for_pad_clash(compcv, name) ((void) 0)
#endif /* !Q_CODE_CLASHES_WITH_PAD */

#define import(base_sigil, vari_word) THX_import(aTHX_ base_sigil, vari_word)
static void THX_import(pTHX_ char base_sigil, char const *vari_word)
{
	dXSARGS;
	CV *compcv;
	int i;
	SP -= items;
	if(items < 1)
		croak("too few arguments for import");
	if(items == 1)
		croak("%" SVf " does no default importation", SVfARG(ST(0)));
	if(!(items & 1))
		croak("import list for %" SVf
			" must alternate name and reference", SVfARG(ST(0)));
	compcv = find_compcv(vari_word);
	PL_hints |= HINT_LOCALIZE_HH;
	gv_HVadd(PL_hintgv);
	for(i = 1; i != items; i += 2) {
		SV *name = ST(i), *ref = ST(i+1), *key, *val, *referent;
		svtype rt;
		bool rok;
		char const *vt;
		char sigil;
		HE *he;
		if(!sv_is_string(name))
			croak("%s name is not a string", vari_word);
		key = name_key(base_sigil, name);
		if(!key) croak("malformed %s name", vari_word);
		sigil = SvPVX(key)[KEYPREFIXLEN];
		rt = SvROK(ref) ? SvTYPE(SvRV(ref)) : SVt_LAST;
		switch(sigil) {
			case '$': rok = svt_scalar(rt); vt="scalar"; break;
			case '@': rok = rt == SVt_PVAV; vt="array";  break;
			case '%': rok = rt == SVt_PVHV; vt="hash";   break;
			case '&': rok = rt == SVt_PVCV; vt="code";   break;
			case '*': rok = rt == SVt_PVGV; vt="glob";   break;
			default:  rok = 0; vt = "wibble"; break;
		}
		if(!rok) croak("%s is not %s reference", vari_word, vt);
		check_for_pad_clash(compcv, SvPVX(key)+KEYPREFIXLEN);
		referent = SvRV(ref);
		if(char_attr[(U8)sigil] & CHAR_USEPAD)
			setup_pad(compcv, SvPVX(key)+KEYPREFIXLEN,
				Q_CODE_AS_STATE_IN_PAD && sigil == '&' ?
					referent : NULL);
		val = newRV_inc(referent);
		he = hv_store_ent(GvHV(PL_hintgv), key, val, 0);
		if(he) {
			val = HeVAL(he);
			SvSETMAGIC(val);
		} else {
			SvREFCNT_dec(val);
		}
	}
	PUTBACK;
}

#define unimport(base_sigil, vari_word) \
	THX_unimport(aTHX_ base_sigil, vari_word)
static void THX_unimport(pTHX_ char base_sigil, char const *vari_word)
{
	dXSARGS;
	CV *compcv;
	int i;
	SP -= items;
	if(items < 1)
		croak("too few arguments for unimport");
	if(items == 1)
		croak("%" SVf " does no default unimportation", SVfARG(ST(0)));
	compcv = find_compcv(vari_word);
	PL_hints |= HINT_LOCALIZE_HH;
	gv_HVadd(PL_hintgv);
	for(i = 1; i != items; i++) {
		SV *name = ST(i), *ref, *key;
		char sigil;
		if(!sv_is_string(name))
			croak("%s name is not a string", vari_word);
		key = name_key(base_sigil, name);
		if(!key) croak("malformed %s name", vari_word);
		sigil = SvPVX(key)[KEYPREFIXLEN];
		if(i != items && (ref = ST(i+1), SvROK(ref))) {
			i++;
			if(current_referent(key) != SvRV(ref))
				continue;
		}
		check_for_pad_clash(compcv, SvPVX(key)+KEYPREFIXLEN);
		(void) hv_delete_ent(GvHV(PL_hintgv), key, G_DISCARD, 0);
		if(char_attr[(U8)sigil] & CHAR_USEPAD)
			setup_pad(compcv, SvPVX(key)+KEYPREFIXLEN, NULL);
	}
	PUTBACK;
}

MODULE = Lexical::Var PACKAGE = Lexical::Var

PROTOTYPES: DISABLE

BOOT:
#if !Q_USE_THREADS
# if Q_NEED_FAKE_REFERENT
	fake_sv = newSV(0);
	fake_av = (SV*)newAV();
	fake_hv = (SV*)newHV();
# endif /* Q_NEED_FAKE_REFERENT */
	lvour_sv_stash = gv_stashpvs(LVOURPREFIX "$", 1);
	lvour_av_stash = gv_stashpvs(LVOURPREFIX "@", 1);
	lvour_hv_stash = gv_stashpvs(LVOURPREFIX "%", 1);
# if Q_CODE_AS_STATE_IN_PAD
	lvour_cv_stash = gv_stashpvs(LVOURPREFIX "&", 1);
# endif /* Q_CODE_AS_STATE_IN_PAD */
#endif /* !Q_USE_THREADS */
	wrap_op_checker(OP_RV2SV, THX_myck_rv2sv, &THX_nxck_rv2sv);
	wrap_op_checker(OP_RV2AV, THX_myck_rv2av, &THX_nxck_rv2av);
	wrap_op_checker(OP_RV2HV, THX_myck_rv2hv, &THX_nxck_rv2hv);
	wrap_op_checker(OP_RV2CV, THX_myck_rv2cv, &THX_nxck_rv2cv);
	wrap_op_checker(OP_RV2GV, THX_myck_rv2gv, &THX_nxck_rv2gv);

void
import(SV *classname, ...)
PPCODE:
	PERL_UNUSED_VAR(classname);
	PUSHMARK(SP);
	/* the modified SP is intentionally lost here */
	import('N', "variable");
	SPAGAIN;

void
unimport(SV *classname, ...)
PPCODE:
	PERL_UNUSED_VAR(classname);
	PUSHMARK(SP);
	/* the modified SP is intentionally lost here */
	unimport('N', "variable");
	SPAGAIN;

MODULE = Lexical::Var PACKAGE = Lexical::Sub

void
import(SV *classname, ...)
PPCODE:
	PERL_UNUSED_VAR(classname);
	PUSHMARK(SP);
	/* the modified SP is intentionally lost here */
	import('&', "subroutine");
	SPAGAIN;

void
unimport(SV *classname, ...)
PPCODE:
	PERL_UNUSED_VAR(classname);
	PUSHMARK(SP);
	/* the modified SP is intentionally lost here */
	unimport('&', "subroutine");
	SPAGAIN;
