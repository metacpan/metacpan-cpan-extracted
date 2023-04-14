#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "rv2cvopcv_callchecker0.h"
#include "XSUB.h"

#define Q_PERL_VERSION_DECIMAL(r,v,s) ((r)*1000000 + (v)*1000 + (s))
#define Q_PERL_DECIMAL_VERSION \
	Q_PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define Q_PERL_VERSION_GE(r,v,s) \
	(Q_PERL_DECIMAL_VERSION >= Q_PERL_VERSION_DECIMAL(r,v,s))
#define Q_PERL_VERSION_LT(r,v,s) \
	(Q_PERL_DECIMAL_VERSION < Q_PERL_VERSION_DECIMAL(r,v,s))

#if (Q_PERL_VERSION_GE(5,17,6) && Q_PERL_VERSION_LT(5,17,11)) || \
	(Q_PERL_VERSION_GE(5,19,3) && Q_PERL_VERSION_LT(5,21,1))
PERL_STATIC_INLINE void suppress_unused_warning(void)
{
	(void) S_croak_memory_wrap;
}
#endif /* (>=5.17.6 && <5.17.11) || (>=5.19.3 && <5.21.1) */

#if Q_PERL_VERSION_LT(5,7,2)
# undef dNOOP
# define dNOOP extern int Perl___notused_func(void)
#endif /* <5.7.2 */

#define Q_RV2CV_CONST_REF_RESOLVES Q_PERL_VERSION_GE(5,11,2)

MODULE = t::rv2cvopcv PACKAGE = t::rv2cvopcv

PROTOTYPES: DISABLE

void
test_rv2cv_op_cv()
PROTOTYPE:
PREINIT:
	GV *troc_gv;
	CV *troc_cv;
	OP *o;
CODE:
#define croak_fail() croak("fail at %s line %d", __FILE__, __LINE__)
	troc_gv = gv_fetchpv("t::rv2cvopcv::test_rv2cv_op_cv", 0, SVt_PVGV);
	troc_cv = get_cv("t::rv2cvopcv::test_rv2cv_op_cv", 0);
	(void) gv_fetchpv("t::rv2cvopcv::wibble", 0, SVt_PVGV);
	o = newCVREF(0, newGVOP(OP_GV, 0, troc_gv));
	if (rv2cv_op_cv(o, 0) != troc_cv) croak_fail();
	if (rv2cv_op_cv(o, RV2CVOPCV_RETURN_NAME_GV) != (CV*)troc_gv)
		croak_fail();
	o->op_private |= OPpENTERSUB_AMPER;
	if (rv2cv_op_cv(o, 0)) croak_fail();
	if (rv2cv_op_cv(o, RV2CVOPCV_RETURN_NAME_GV)) croak_fail();
	o->op_private &= ~OPpENTERSUB_AMPER;
	if (cUNOPx(o)->op_first->op_private & OPpEARLY_CV) croak_fail();
	if (rv2cv_op_cv(o, RV2CVOPCV_MARK_EARLY) != troc_cv) croak_fail();
	if (cUNOPx(o)->op_first->op_private & OPpEARLY_CV) croak_fail();
	op_free(o);
	o = newSVOP(OP_CONST, 0, newSVpv("t::rv2cvopcv::test_rv2cv_op_cv", 0));
	o->op_private = OPpCONST_BARE;
	o = newCVREF(0, o);
	if (rv2cv_op_cv(o, 0) != troc_cv) croak_fail();
	if (rv2cv_op_cv(o, RV2CVOPCV_RETURN_NAME_GV) != (CV*)troc_gv)
		croak_fail();
	o->op_private |= OPpENTERSUB_AMPER;
	if (rv2cv_op_cv(o, 0)) croak_fail();
	if (rv2cv_op_cv(o, RV2CVOPCV_RETURN_NAME_GV)) croak_fail();
	op_free(o);
	o = newCVREF(0, newSVOP(OP_CONST, 0, newRV_inc((SV*)troc_cv)));
#if Q_RV2CV_CONST_REF_RESOLVES
	if (rv2cv_op_cv(o, 0) != troc_cv) croak_fail();
	if (rv2cv_op_cv(o, RV2CVOPCV_RETURN_NAME_GV) != (CV*)troc_gv)
		croak_fail();
#else /* !Q_RV2CV_CONST_REF_RESOLVES */
	if (rv2cv_op_cv(o, 0)) croak_fail();
	if (rv2cv_op_cv(o, RV2CVOPCV_RETURN_NAME_GV)) croak_fail();
#endif /* !Q_RV2CV_CONST_REF_RESOLVES */
	o->op_private |= OPpENTERSUB_AMPER;
	if (rv2cv_op_cv(o, 0)) croak_fail();
	if (rv2cv_op_cv(o, RV2CVOPCV_RETURN_NAME_GV)) croak_fail();
	o->op_private &= ~OPpENTERSUB_AMPER;
	if (cUNOPx(o)->op_first->op_private & OPpEARLY_CV) croak_fail();
#if Q_RV2CV_CONST_REF_RESOLVES
	if (rv2cv_op_cv(o, RV2CVOPCV_MARK_EARLY) != troc_cv) croak_fail();
#else /* !Q_RV2CV_CONST_REF_RESOLVES */
	if (rv2cv_op_cv(o, RV2CVOPCV_MARK_EARLY)) croak_fail();
#endif /* !Q_RV2CV_CONST_REF_RESOLVES */
	if (cUNOPx(o)->op_first->op_private & OPpEARLY_CV) croak_fail();
	op_free(o);
	o = newCVREF(0, newUNOP(OP_RAND, 0, newSVOP(OP_CONST, 0, newSViv(0))));
	if (rv2cv_op_cv(o, 0)) croak_fail();
	if (rv2cv_op_cv(o, RV2CVOPCV_RETURN_NAME_GV)) croak_fail();
	o->op_private |= OPpENTERSUB_AMPER;
	if (rv2cv_op_cv(o, 0)) croak_fail();
	if (rv2cv_op_cv(o, RV2CVOPCV_RETURN_NAME_GV)) croak_fail();
	o->op_private &= ~OPpENTERSUB_AMPER;
	if (cUNOPx(o)->op_first->op_private & OPpEARLY_CV) croak_fail();
	if (rv2cv_op_cv(o, RV2CVOPCV_MARK_EARLY)) croak_fail();
	if (cUNOPx(o)->op_first->op_private & OPpEARLY_CV) croak_fail();
	op_free(o);
	o = newUNOP(OP_RAND, 0, newSVOP(OP_CONST, 0, newSViv(0)));
	if (rv2cv_op_cv(o, 0)) croak_fail();
	if (rv2cv_op_cv(o, RV2CVOPCV_RETURN_NAME_GV)) croak_fail();
	op_free(o);
#undef croak_fail
