#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#define PERL_DECIMAL_VERSION \
	PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define PERL_VERSION_GE(r,v,s) \
	(PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))

#ifndef cBOOL
# define cBOOL(x) ((bool)!!(x))
#endif /* !cBOOL */

#ifndef newSVpvs
# define newSVpvs(s) newSVpvn(""s"", (sizeof(""s"")-1))
#endif /* !newSVpvs */

#ifndef OpMORESIB_set
# define OpMORESIB_set(o, sib) ((o)->op_sibling = (sib))
# define OpLASTSIB_set(o, parent) ((o)->op_sibling = NULL)
# define OpMAYBESIB_set(o, sib, parent) ((o)->op_sibling = (sib))
#endif /* !OpMORESIB_set */
#ifndef OpSIBLING
# define OpHAS_SIBLING(o) (cBOOL((o)->op_sibling))
# define OpSIBLING(o) (0 + (o)->op_sibling)
#endif /* !OpSIBLING */

#define QPFX xAd8NP3gxZglovQRL5Hn_
#define QPFXS STRINGIFY(QPFX)
#define QCONCAT0(a,b) a##b
#define QCONCAT1(a,b) QCONCAT0(a,b)
#define QPFXD(name) QCONCAT1(QPFX, name)

#if defined(WIN32) && PERL_VERSION_GE(5,13,6)
# define MY_BASE_CALLCONV EXTERN_C
# define MY_BASE_CALLCONV_S "EXTERN_C"
#else /* !(WIN32 && >= 5.13.6) */
# define MY_BASE_CALLCONV PERL_CALLCONV
# define MY_BASE_CALLCONV_S "PERL_CALLCONV"
#endif /* !(WIN32 && >= 5.13.6) */

#define MY_EXPORT_CALLCONV MY_BASE_CALLCONV

#if defined(WIN32) || defined(__CYGWIN__)
# define MY_IMPORT_CALLCONV_S MY_BASE_CALLCONV_S" __declspec(dllimport)"
#else
# define MY_IMPORT_CALLCONV_S MY_BASE_CALLCONV_S
#endif

#ifndef rv2cv_op_cv

# define RV2CVOPCV_MARK_EARLY     0x00000001
# define RV2CVOPCV_RETURN_NAME_GV 0x00000002

# define Perl_rv2cv_op_cv QPFXD(roc0)
# define rv2cv_op_cv(cvop, flags) Perl_rv2cv_op_cv(aTHX_ cvop, flags)
MY_EXPORT_CALLCONV CV *QPFXD(roc0)(pTHX_ OP *cvop, U32 flags)
{
	OP *rvop;
	CV *cv;
	GV *gv;
	if(!(cvop->op_type == OP_RV2CV &&
			!(cvop->op_private & OPpENTERSUB_AMPER) &&
			(cvop->op_flags & OPf_KIDS)))
		return NULL;
	rvop = cUNOPx(cvop)->op_first;
	switch(rvop->op_type) {
		case OP_GV: {
			gv = cGVOPx_gv(rvop);
			cv = GvCVu(gv);
			if(!cv) {
				if(flags & RV2CVOPCV_MARK_EARLY)
					rvop->op_private |= OPpEARLY_CV;
				return NULL;
			}
		} break;
#if PERL_VERSION_GE(5,11,2)
		case OP_CONST: {
			SV *rv = cSVOPx_sv(rvop);
			if(!SvROK(rv)) return NULL;
			cv = (CV*)SvRV(rv);
			gv = NULL;
		} break;
#endif /* >=5.11.2 */
		default: {
			return NULL;
		} break;
	}
	if(SvTYPE((SV*)cv) != SVt_PVCV) return NULL;
	if(flags & RV2CVOPCV_RETURN_NAME_GV) {
		if(!CvANON(cv) || !gv) gv = CvGV(cv);
		return (CV*)gv;
	} else {
		return cv;
	}
}

# define Q_PROVIDE_RV2CV_OP_CV 1

#endif /* !rv2cv_op_cv */

#ifndef ck_entersub_args_proto_or_list

# ifndef newSV_type
#  define newSV_type(type) THX_newSV_type(aTHX_ type)
static SV *THX_newSV_type(pTHX_ svtype type)
{
	SV *sv = newSV(0);
	(void) SvUPGRADE(sv, type);
	return sv;
}
# endif /* !newSV_type */

# ifndef GvCV_set
#  define GvCV_set(gv, cv) (GvCV(gv) = (cv))
# endif /* !GvCV_set */

# ifndef CvGV_set
#  define CvGV_set(cv, gv) (CvGV(cv) = (gv))
# endif /* !CvGV_set */

# define entersub_extract_args(eo) THX_entersub_extract_args(aTHX_ eo)
static OP *THX_entersub_extract_args(pTHX_ OP *entersubop)
{
	OP *pushop, *aop, *bop, *cop;
	if(!(entersubop->op_flags & OPf_KIDS)) return NULL;
	pushop = cUNOPx(entersubop)->op_first;
	if(!OpHAS_SIBLING(pushop)) {
		if(!(pushop->op_flags & OPf_KIDS)) return NULL;
		pushop = cUNOPx(pushop)->op_first;
		if(!OpHAS_SIBLING(pushop)) return NULL;
	}
	for(bop = pushop; (cop = OpSIBLING(bop), OpHAS_SIBLING(cop));
			bop = cop) ;
	if(bop == pushop) return NULL;
	aop = OpSIBLING(pushop);
	OpMORESIB_set(pushop, cop);
	OpLASTSIB_set(bop, NULL);
	return aop;
}

# define entersub_inject_args(eo, ao) THX_entersub_inject_args(aTHX_ eo, ao)
static void THX_entersub_inject_args(pTHX_ OP *entersubop, OP *aop)
{
	OP *pushop, *bop, *cop;
	if(!aop) return;
	if(!(entersubop->op_flags & OPf_KIDS)) {
		abort:
		while(aop) {
			bop = OpSIBLING(aop);
			op_free(aop);
			aop = bop;
		}
		return;
	}
	pushop = cUNOPx(entersubop)->op_first;
	if(!OpHAS_SIBLING(pushop)) {
		if(!(pushop->op_flags & OPf_KIDS)) goto abort;
		pushop = cUNOPx(pushop)->op_first;
		if(!OpHAS_SIBLING(pushop)) goto abort;
	}
	for(bop = aop; (cop = OpSIBLING(bop)); bop = cop) ;
	OpMORESIB_set(bop, OpSIBLING(pushop));
	OpMORESIB_set(pushop, aop);
}

# define ck_entersub_args_stalk(eo, so) THX_ck_entersub_args_stalk(aTHX_ eo, so)
static OP *THX_ck_entersub_args_stalk(pTHX_ OP *entersubop, OP *stalkcvop)
{
	OP *stalkenterop = newLISTOP(OP_LIST, 0, newCVREF(0, stalkcvop), NULL);
	entersub_inject_args(stalkenterop, entersub_extract_args(entersubop));
	stalkenterop = newUNOP(OP_ENTERSUB, OPf_STACKED, stalkenterop);
	entersub_inject_args(entersubop, entersub_extract_args(stalkenterop));
	op_free(stalkenterop);
	return entersubop;
}

# define Perl_ck_entersub_args_list QPFXD(eal0)
# define ck_entersub_args_list(o) Perl_ck_entersub_args_list(aTHX_ o)
MY_EXPORT_CALLCONV OP *QPFXD(eal0)(pTHX_ OP *entersubop)
{
	return ck_entersub_args_stalk(entersubop, newOP(OP_PADANY, 0));
}

# define Perl_ck_entersub_args_proto QPFXD(eap0)
# define ck_entersub_args_proto(o, gv, sv) \
	Perl_ck_entersub_args_proto(aTHX_ o, gv, sv)
MY_EXPORT_CALLCONV OP *QPFXD(eap0)(pTHX_ OP *entersubop, GV *namegv,
	SV *protosv)
{
	const char *proto;
	STRLEN proto_len;
	CV *stalkcv;
	GV *stalkgv;
	if(SvTYPE(protosv) == SVt_PVCV ? !SvPOK(protosv) : !SvOK(protosv))
		croak("panic: ck_entersub_args_proto CV with no proto");
	proto = SvPV(protosv, proto_len);
	stalkcv = (CV*)newSV_type(SVt_PVCV);
	sv_setpvn((SV*)stalkcv, proto, proto_len);
	stalkgv = (GV*)sv_2mortal(newSV(0));
	gv_init(stalkgv, GvSTASH(namegv), GvNAME(namegv), GvNAMELEN(namegv), 0);
	GvCV_set(stalkgv, stalkcv);
	CvGV_set(stalkcv, stalkgv);
	return ck_entersub_args_stalk(entersubop, newGVOP(OP_GV, 0, stalkgv));
}

# define Perl_ck_entersub_args_proto_or_list QPFXD(ean0)
# define ck_entersub_args_proto_or_list(o, gv, sv) \
	Perl_ck_entersub_args_proto_or_list(aTHX_ o, gv, sv)
MY_EXPORT_CALLCONV OP *QPFXD(ean0)(pTHX_ OP *entersubop, GV *namegv,
	SV *protosv)
{
	if(SvTYPE(protosv) == SVt_PVCV ? SvPOK(protosv) : SvOK(protosv))
		return ck_entersub_args_proto(entersubop, namegv, protosv);
	else
		return ck_entersub_args_list(entersubop);
}

# define Q_PROVIDE_CK_ENTERSUB_ARGS_PROTO_OR_LIST 1

#endif /* !ck_entersub_args_proto_or_list */

#ifndef cv_set_call_checker

# ifndef Newxz
#  define Newxz(v,n,t) Newz(0,v,n,t)
# endif /* !Newxz */

# ifndef SvMAGIC_set
#  define SvMAGIC_set(sv, mg) (SvMAGIC(sv) = (mg))
# endif /* !SvMAGIC_set */

# ifndef DPTR2FPTR
#  define DPTR2FPTR(t,x) ((t)(UV)(x))
# endif /* !DPTR2FPTR */

# ifndef FPTR2DPTR
#  define FPTR2DPTR(t,x) ((t)(UV)(x))
# endif /* !FPTR2DPTR */

# ifndef op_null
#  define op_null(o) THX_op_null(aTHX_ o)
static void THX_op_null(pTHX_ OP *o)
{
	if(o->op_type == OP_NULL) return;
	/* must not be used on any op requiring non-trivial clearing */
	o->op_targ = o->op_type;
	o->op_type = OP_NULL;
	o->op_ppaddr = PL_ppaddr[OP_NULL];
}
# endif /* !op_null */

# ifndef mg_findext
#  define mg_findext(sv, type, vtbl) THX_mg_findext(aTHX_ sv, type, vtbl)
static MAGIC *THX_mg_findext(pTHX_ SV *sv, int type, MGVTBL const *vtbl)
{
	MAGIC *mg;
	if(sv)
		for(mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic)
			if(mg->mg_type == type && mg->mg_virtual == vtbl)
				return mg;
	return NULL;
}
# endif /* !mg_findext */

# ifndef sv_unmagicext
#  define sv_unmagicext(sv, type, vtbl) THX_sv_unmagicext(aTHX_ sv, type, vtbl)
static int THX_sv_unmagicext(pTHX_ SV *sv, int type, MGVTBL const *vtbl)
{
	MAGIC *mg, **mgp;
	if((vtbl && vtbl->svt_free)
#  ifdef PERL_MAGIC_regex_global
			|| type == PERL_MAGIC_regex_global
#  endif /* PERL_MAGIC_regex_global */
			)
		/* exceeded intended usage of this reserve implementation */
		return 0;
	if(SvTYPE(sv) < SVt_PVMG || !SvMAGIC(sv)) return 0;
	mgp = NULL;
	for(mg = mgp ? *mgp : SvMAGIC(sv); mg; mg = mgp ? *mgp : SvMAGIC(sv)) {
		if(mg->mg_type == type && mg->mg_virtual == vtbl) {
			if(mgp)
				*mgp = mg->mg_moremagic;
			else
				SvMAGIC_set(sv, mg->mg_moremagic);
			if(mg->mg_flags & MGf_REFCOUNTED)
				SvREFCNT_dec(mg->mg_obj);
			Safefree(mg);
		} else {
			mgp = &mg->mg_moremagic;
		}
	}
	SvMAGICAL_off(sv);
	mg_magical(sv);
	return 0;
}
# endif /* !sv_unmagicext */

# ifndef sv_magicext
#  define sv_magicext(sv, obj, type, vtbl, name, namlen) \
	THX_sv_magicext(aTHX_ sv, obj, type, vtbl, name, namlen)
static MAGIC *THX_sv_magicext(pTHX_ SV *sv, SV *obj, int type,
	MGVTBL const *vtbl, char const *name, I32 namlen)
{
	MAGIC *mg;
	if(!(obj == &PL_sv_undef && !name && !namlen))
		/* exceeded intended usage of this reserve implementation */
		return NULL;
	Newxz(mg, 1, MAGIC);
	mg->mg_virtual = (MGVTBL*)vtbl;
	mg->mg_type = type;
	mg->mg_obj = &PL_sv_undef;
	(void) SvUPGRADE(sv, SVt_PVMG);
	mg->mg_moremagic = SvMAGIC(sv);
	SvMAGIC_set(sv, mg);
	SvMAGICAL_off(sv);
	mg_magical(sv);
	return mg;
}
# endif /* !sv_magicext */

# ifndef PERL_MAGIC_ext
#  define PERL_MAGIC_ext '~'
# endif /* !PERL_MAGIC_ext */

# if !PERL_VERSION_GE(5,9,3)
typedef OP *(*Perl_check_t)(pTHX_ OP *);
# endif /* <5.9.3 */

# if !PERL_VERSION_GE(5,10,1)
typedef unsigned Optype;
# endif /* <5.10.1 */

# ifndef wrap_op_checker
#  define wrap_op_checker(c,n,o) THX_wrap_op_checker(aTHX_ c,n,o)
static void THX_wrap_op_checker(pTHX_ Optype opcode,
	Perl_check_t new_checker, Perl_check_t *old_checker_p)
{
	if(*old_checker_p) return;
	OP_REFCNT_LOCK;
	if(!*old_checker_p) {
		*old_checker_p = PL_check[opcode];
		PL_check[opcode] = new_checker;
	}
	OP_REFCNT_UNLOCK;
}
# endif /* !wrap_op_checker */

static MGVTBL mgvtbl_checkcall;

typedef OP *(*Perl_call_checker)(pTHX_ OP *, GV *, SV *);

# define Perl_cv_get_call_checker QPFXD(gcc0)
# define cv_get_call_checker(cv, THX_ckfun_p, ckobj_p) \
	Perl_cv_get_call_checker(aTHX_ cv, THX_ckfun_p, ckobj_p)
MY_EXPORT_CALLCONV void QPFXD(gcc0)(pTHX_ CV *cv,
	Perl_call_checker *THX_ckfun_p, SV **ckobj_p)
{
	MAGIC *callmg = SvMAGICAL((SV*)cv) ?
		mg_findext((SV*)cv, PERL_MAGIC_ext, &mgvtbl_checkcall) : NULL;
	if(callmg) {
		*THX_ckfun_p = DPTR2FPTR(Perl_call_checker, callmg->mg_ptr);
		*ckobj_p = callmg->mg_obj;
	} else {
		*THX_ckfun_p = Perl_ck_entersub_args_proto_or_list;
		*ckobj_p = (SV*)cv;
	}
}

# define Perl_cv_set_call_checker QPFXD(scc0)
# define cv_set_call_checker(cv, THX_ckfun, ckobj) \
	Perl_cv_set_call_checker(aTHX_ cv, THX_ckfun, ckobj)
MY_EXPORT_CALLCONV void QPFXD(scc0)(pTHX_ CV *cv,
	Perl_call_checker THX_ckfun, SV *ckobj)
{
	if(THX_ckfun == Perl_ck_entersub_args_proto_or_list &&
			ckobj == (SV*)cv) {
		if(SvMAGICAL((SV*)cv))
			sv_unmagicext((SV*)cv, PERL_MAGIC_ext,
				&mgvtbl_checkcall);
	} else {
		MAGIC *callmg =
			mg_findext((SV*)cv, PERL_MAGIC_ext, &mgvtbl_checkcall);
		if(!callmg)
			callmg = sv_magicext((SV*)cv, &PL_sv_undef,
				PERL_MAGIC_ext, &mgvtbl_checkcall, NULL, 0);
		if(callmg->mg_flags & MGf_REFCOUNTED) {
			SvREFCNT_dec(callmg->mg_obj);
			callmg->mg_flags &= ~MGf_REFCOUNTED;
		}
		callmg->mg_ptr = FPTR2DPTR(char *, THX_ckfun);
		callmg->mg_obj = ckobj;
		if(ckobj != (SV*)cv) {
			SvREFCNT_inc(ckobj);
			callmg->mg_flags |= MGf_REFCOUNTED;
		}
	}
}

static OP *(*THX_nxck_entersub)(pTHX_ OP *);

static OP *THX_myck_entersub(pTHX_ OP *entersubop)
{
	OP *aop, *cvop;
	CV *cv;
	GV *namegv;
	Perl_call_checker THX_ckfun;
	SV *ckobj;
	aop = cUNOPx(entersubop)->op_first;
	if(!OpHAS_SIBLING(aop)) aop = cUNOPx(aop)->op_first;
	aop = OpSIBLING(aop);
	for(cvop = aop; OpHAS_SIBLING(cvop); cvop = OpSIBLING(cvop)) ;
	if(!(cv = rv2cv_op_cv(cvop, 0)))
		return THX_nxck_entersub(aTHX_ entersubop);
	cv_get_call_checker(cv, &THX_ckfun, &ckobj);
	if(THX_ckfun == Perl_ck_entersub_args_proto_or_list && ckobj == (SV*)cv)
		return THX_nxck_entersub(aTHX_ entersubop);
	namegv = (GV*)rv2cv_op_cv(cvop,
			RV2CVOPCV_MARK_EARLY|RV2CVOPCV_RETURN_NAME_GV);
	entersubop->op_private |= OPpENTERSUB_HASTARG;
	entersubop->op_private |= (PL_hints & HINT_STRICT_REFS);
	if(PERLDB_SUB && PL_curstash != PL_debstash)
		entersubop->op_private |= OPpENTERSUB_DB;
	op_null(cvop);
	return THX_ckfun(aTHX_ entersubop, namegv, ckobj);
}

# define Q_PROVIDE_CV_SET_CALL_CHECKER 1

#endif /* !cv_set_call_checker */

MODULE = Devel::CallChecker PACKAGE = Devel::CallChecker

PROTOTYPES: DISABLE

BOOT:
#if Q_PROVIDE_CV_SET_CALL_CHECKER
	wrap_op_checker(OP_ENTERSUB, THX_myck_entersub, &THX_nxck_entersub);
#endif /* Q_PROVIDE_CV_SET_CALL_CHECKER */

SV *
callchecker0_h()
CODE:
	RETVAL = newSVpvs(
		"/* DO NOT EDIT -- generated "
			"by Devel::CallChecker version "XS_VERSION" */\n"
		"#ifndef "QPFXS"INCLUDED\n"
		"#define "QPFXS"INCLUDED 1\n"
		"#ifndef PERL_VERSION\n"
		" #error you must include perl.h before callchecker0.h\n"
		"#elif !(PERL_REVISION == "STRINGIFY(PERL_REVISION)
			" && PERL_VERSION == "STRINGIFY(PERL_VERSION)
#if PERL_VERSION & 1
			" && PERL_SUBVERSION == "STRINGIFY(PERL_SUBVERSION)
#endif /* PERL_VERSION & 1 */
			")\n"
		" #error this callchecker0.h is for Perl "
			STRINGIFY(PERL_REVISION)"."STRINGIFY(PERL_VERSION)
#if PERL_VERSION & 1
			"."STRINGIFY(PERL_SUBVERSION)
#endif /* PERL_VERSION & 1 */
			" only\n"
		"#endif /* Perl version mismatch */\n"
#define DEFFN(RETTYPE, PUBNAME, PRIVNAME, ARGTYPES, ARGNAMES) \
	MY_IMPORT_CALLCONV_S" "RETTYPE" "QPFXS PRIVNAME"(pTHX_ "ARGTYPES");\n" \
	"#define Perl_"PUBNAME" "QPFXS PRIVNAME"\n" \
	"#define "PUBNAME"("ARGNAMES") Perl_"PUBNAME"(aTHX_ "ARGNAMES")\n"
#if Q_PROVIDE_RV2CV_OP_CV
		"#define RV2CVOPCV_MARK_EARLY     0x00000001\n"
		"#define RV2CVOPCV_RETURN_NAME_GV 0x00000002\n"
		DEFFN("CV *", "rv2cv_op_cv", "roc0", "OP *, U32", "cvop, flags")
#endif /* Q_PROVIDE_RV2CV_OP_CV */
#if Q_PROVIDE_CK_ENTERSUB_ARGS_PROTO_OR_LIST
		DEFFN("OP *", "ck_entersub_args_list", "eal0", "OP *", "o")
		DEFFN("OP *", "ck_entersub_args_proto", "eap0",
			"OP *, GV *, SV *", "o, gv, sv")
		DEFFN("OP *", "ck_entersub_args_proto_or_list", "ean0",
			"OP *, GV *, SV *", "o, gv, sv")
#endif /* Q_PROVIDE_CK_ENTERSUB_ARGS_PROTO_OR_LIST */
#if Q_PROVIDE_CV_SET_CALL_CHECKER
		"typedef OP *(*Perl_call_checker)(pTHX_ OP *, GV *, SV *);\n"
		DEFFN("void", "cv_get_call_checker", "gcc0",
			"CV *, Perl_call_checker *, SV **", "cv, fp, op")
		DEFFN("void", "cv_set_call_checker", "scc0",
			"CV *, Perl_call_checker, SV *", "cv, f, o")
#endif /* Q_PROVIDE_CV_SET_CALL_CHECKER */
		"#endif /* !"QPFXS"INCLUDED */\n"
	);
OUTPUT:
	RETVAL
