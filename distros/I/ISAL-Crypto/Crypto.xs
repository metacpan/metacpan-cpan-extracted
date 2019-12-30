#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "Crypto.h"

/************ xmap: translation map for hexadecimal encoding ***********/
static const char xmap[] = "0123456789abcdef";

/************* Constant value of available cpu features: ***************/

unsigned has_sse  = 0;
unsigned has_avx  = 0;
unsigned has_avx2 = 0;

unsigned has_avx512f  = 0;
unsigned has_avx512vl = 0;
unsigned has_avx512bw = 0;
unsigned has_avx512cd = 0;
unsigned has_avx512dq = 0;
unsigned has_avx512   = 0;

#define CHECK_AND_STORE_FEATURE_SUPPORT(hv, REG, F) STMT_START {	\
	has ## F = ((REG) & (						\
		PPCAT(bit_, NAME_CPU_FEATURE(F))			\
	)) ? 1 : 0;							\
	hv_store(							\
		(hv),							\
		"HAS_" TOSTR(NAME_CPU_FEATURE(F)),			\
		sizeof("HAS_" TOSTR(NAME_CPU_FEATURE(F))) - 1,		\
		(has ## F) ? &PL_sv_yes : &PL_sv_no,			\
		0							\
	);								\
} STMT_END

#define STORE_AVX512_FEATURE(hv, num) STMT_START {			\
	has_avx512 = (num);						\
	hv_store(							\
		(hv),							\
		"HAS_AVX512",						\
		sizeof("HAS_AVX512") - 1,				\
		has_avx512 ? &PL_sv_yes : &PL_sv_no,			\
		0							\
	);								\
} STMT_END

/********** Setting lane to `mgr->unused_lanes` functions: *************/

#define MGR_SET_EMPTY_LANE_SHA1(mgr, lane) STMT_START {			\
	(mgr)->unused_lanes <<= 4;					\
	(mgr)->unused_lanes |= (lane);					\
} STMT_END

#define MGR_SET_EMPTY_LANE_SHA256(mgr, lane) STMT_START {		\
	(mgr)->unused_lanes <<= 4;					\
	(mgr)->unused_lanes |= (lane);					\
} STMT_END

#define MGR_SET_EMPTY_LANE_SHA512(mgr, lane) STMT_START {		\
	(mgr)->unused_lanes <<= 8;					\
	(mgr)->unused_lanes |= (lane);					\
} STMT_END

/*
 * This is very unhealthy behaviour is a consiquence of anavailability
 * to say what exactly type of cpu_featured mgr we have now
 * and how exactly we have to work with it unused_lanes object.
 * It depends on cpu_feature's type and algo which we are calculating now
 * (eg MD5 hash mgr has different from SHA hashes structure
 * and all types of cpu_featured mgrs have different
 * rules for formatting unused_lanes field in avx512)
 *
 * XXX May be would be better to rewrite isa-l_crypto to much more consistent
 * API and much less codebase to more easily fixes, but it will require
 * a titanic efforts and time.
 */

#define MGR_SET_EMPTY_LANE_MD5(mgr, lane) STMT_START {			\
	/* This value was set before */					\
	if ((mgr)->unused_lanes[3] != 0xffffffffffffffff) {		\
		memmove(						\
			((char *)(mgr)->unused_lanes) + 1,		\
			(mgr)->unused_lanes,				\
			sizeof((mgr)->unused_lanes) - 1			\
		);							\
		(mgr)->unused_lanes[0] &= 0xffffffffffffff00;		\
	} else {							\
		(mgr)->unused_lanes[0] <<= 4;				\
	}								\
	(mgr)->unused_lanes[0] |= (lane);				\
} STMT_END

/************************* BYTESWAP functions: *************************/

ISAALWAYSINLINE unsigned int byteswap32(unsigned int x)
{
	return (x >> 24) | (x >> 8 & 0xff00) | (x << 8 & 0xff0000) | (x << 24);
}

ISAALWAYSINLINE uint64_t byteswap64(uint64_t x)
{
#if defined (__ICC)
	return _bswap64(x);
#elif defined (__GNUC__) && (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 3))
	return __builtin_bswap64(x);
#else
	return (((x & (0xffull << 0)) << 56)
		| ((x & (0xffull << 8)) << 40)
		| ((x & (0xffull << 16)) << 24)
		| ((x & (0xffull << 24)) << 8)
		| ((x & (0xffull << 32)) >> 8)
		| ((x & (0xffull << 40)) >> 24)
		| ((x & (0xffull << 48)) >> 40)
		| ((x & (0xffull << 56)) >> 56));
#endif
}

#define BYTESWAP_MD5(WHERE) NOOP

#define BYTESWAP_SHA1(WHERE) STMT_START {				\
	unsigned int *convert = (unsigned int *)(WHERE);		\
	for (int i = 0; i < (SHA1_DIGEST_NWORDS); i++) {		\
		convert[i] = byteswap32(convert[i]);			\
	}								\
} STMT_END

/* same as BYTESWAP_SHA1 */
#define BYTESWAP_SHA256(WHERE) STMT_START {				\
	unsigned int *convert = (unsigned int *)(WHERE);		\
	for (int i = 0; i < (SHA256_DIGEST_NWORDS); i++) {		\
		convert[i] = byteswap32(convert[i]);			\
	}								\
} STMT_END

#define BYTESWAP_SHA512(WHERE) STMT_START {				\
	uint64_t *convert = (uint64_t *)(WHERE);			\
	for (int i = 0; i < (SHA512_DIGEST_NWORDS); i++) {		\
		convert[i] = byteswap64(convert[i]);			\
	}								\
} STMT_END

/*************************** MGR functions: ****************************/

#define MAKE_MGR_FUN(ALGO, CPUF)					\
static XSPROTO(NAME(Mgr, init, ALGO, CPUF))				\
{									\
	dVAR;								\
	dXSARGS;							\
	if (items != 1)							\
		croak_xs_usage(cv, "pk");				\
									\
	CHECK_CPUF(Mgr, init, ALGO, CPUF);				\
									\
	ALGO ## _HASH_CTX_MGR *mgr = NULL;				\
	if (UNLIKELY(posix_memalign(					\
		(void *)&mgr, 16, sizeof(ALGO ## _HASH_CTX_MGR)		\
	))) {								\
		croak("Alligned malloc failed. Init mgr aborted.");	\
	}								\
	/* special marked unused_lanes[1..3] for MD5 hash not avx512 */	\
	memset(&mgr->mgr.unused_lanes, 0xff,				\
		sizeof(mgr->mgr.unused_lanes));				\
									\
	PPCAT(ALC(ALGO), _ctx_mgr_init ## CPUF) (mgr);			\
									\
	SV *sv_mgr = newSViv(PTR2IV(mgr));				\
	ST(0) = sv_2mortal(sv_bless(					\
		newRV_noinc(sv_mgr), gv_stashpv(SvPV_nolen(ST(0)), TRUE)\
	));								\
	XSRETURN(1);							\
}									\
									\
static XSPROTO(NAME(Mgr, submit, ALGO, CPUF))				\
{									\
	dVAR;								\
	dXSARGS;							\
	if (items != 4)							\
		croak_xs_usage(cv, "sv_mgr, sv_ctx, sv_buf, sv_mask");	\
									\
	CHECK_CPUF(Mgr, submit, ALGO, CPUF);				\
									\
	ALGO ## _HASH_CTX_MGR *mgr = NULL;				\
	ALGO ## _HASH_CTX *ctx = NULL;					\
	char *buf = NULL;						\
	Size_t len = 0, mask = 0;					\
									\
	if (ST(0) == &PL_sv_undef)					\
		croak("field #1 have to contain mgr object");		\
	mgr = (ALGO ## _HASH_CTX_MGR *)SvIV(SvRV(ST(0)));		\
									\
	if (ST(1) == &PL_sv_undef)					\
		croak("field #2 have to contain ctx object");		\
	ctx = (ALGO ## _HASH_CTX *)SvIV(SvRV(ST(1)));			\
									\
	if (!SvPOK(ST(2)))						\
		croak("field #3 have to contain valid string");		\
	buf = SvPV(ST(2), len);						\
									\
	if (!SvIOK(ST(3)))						\
		croak("field #4 have to be integer");			\
	mask = SvIV(ST(3));						\
									\
	ALGO ## _HASH_CTX *ret_ctx = NULL;				\
	uint32_t old_num_used_lns = mgr->mgr.num_lanes_inuse;		\
	ret_ctx = PPCAT(ALC(ALGO), _ctx_mgr_submit ## CPUF)(		\
		mgr, ctx, buf, len, mask				\
	);								\
	/* job was submited ? */					\
	if (old_num_used_lns < mgr->mgr.num_lanes_inuse) {		\
		/* set reference to JOB's manager to clean up it later	\
		 * on destruction if necessary */			\
		ctx->job.user_data = &mgr->mgr;				\
		ST(0) = &PL_sv_undef;					\
	}								\
	else if (ret_ctx) {						\
		if (ret_ctx == ctx) {					\
			/* Fail to submit ctx */			\
			ST(0) = ST(1);					\
		} else {						\
			/* return after inside flush and resubmit */	\
			/* job was submitted after all flush */		\
			ctx->job.user_data = &mgr->mgr;			\
									\
			SV *ret_sv_ctx = ret_ctx->user_data;		\
			/* delete manager reference from finished job */\
			ret_ctx->job.user_data = NULL;			\
			ST(0) = sv_2mortal(newRV_inc(ret_sv_ctx));	\
		}							\
	} else {							\
		assert(0 &&						\
			"Num lanes wasn't increase"			\
			" but no context to return"			\
		);							\
	}								\
	XSRETURN(1);							\
}									\
									\
static XSPROTO(NAME(Mgr, flush, ALGO, CPUF))				\
{									\
	dVAR;								\
	dXSARGS;							\
	if (items != 1)							\
		croak_xs_usage(cv, "sv_mgr");				\
									\
	CHECK_CPUF(Mgr, flush, ALGO, CPUF);				\
									\
	ALGO ## _HASH_CTX_MGR *mgr = NULL;				\
	ALGO ## _HASH_CTX *ctx = NULL;					\
	mgr = (ALGO ## _HASH_CTX_MGR *)SvIV(SvRV(ST(0)));		\
	ctx = PPCAT(ALC(ALGO), _ctx_mgr_flush ## CPUF)(mgr);		\
									\
	if (!ctx) {							\
		ST(0) = &PL_sv_undef;					\
	} else {							\
		SV *sv_ctx = ctx->user_data;				\
		/* delete manager reference from finished job */	\
		ctx->job.user_data = NULL;				\
		ST(0) = sv_2mortal(newRV_inc(sv_ctx));			\
	}								\
	XSRETURN(1);							\
}

#define MAKE_MGR_NON_CPU_FUN(ALGO)					\
static XSPROTO(NAME(Mgr, get_num_lanes_inuse, ALGO, ))			\
{									\
	dVAR;								\
	dXSARGS;							\
	if (items != 1)							\
		croak_xs_usage(cv, "sv_mgr");				\
									\
	ST(0) = sv_2mortal(newSViv(					\
			((ALGO ## _HASH_CTX_MGR *)SvIV(SvRV(ST(0)))	\
	)->mgr.num_lanes_inuse));					\
									\
	XSRETURN(1);							\
}									\
									\
static XSPROTO(XS_ISAL__Crypto__Mgr__ ## ALGO ## _DESTROY)		\
{									\
	dVAR;								\
	dXSARGS;							\
	if (items != 1)							\
		croak_xs_usage(cv, "sv_mgr");				\
									\
	aligned_free((ALGO ## _HASH_CTX_MGR *)SvIV(SvRV(ST(0))));	\
}

/*************************** CTX functions: ****************************/

#define MAKE_CTX_NON_CPU_FUN(ALGO)					\
static XSPROTO(NAME(Ctx, init, ALGO, ))					\
{									\
	dVAR;								\
	dXSARGS;							\
	if (items != 1)							\
		croak_xs_usage(cv, "pk");				\
									\
	ALGO ## _HASH_CTX *ctx = NULL;					\
	if (UNLIKELY(posix_memalign(					\
		(void *)&ctx, 16, sizeof(ALGO ## _HASH_CTX)		\
	))) {								\
		croak("Alligned malloc failed. Init ctx aborted.");	\
	}								\
	ctx->job.user_data = NULL;					\
	hash_ctx_init(ctx);						\
									\
	SV *sv_ctx = newSViv(PTR2IV(ctx));				\
	ctx->user_data = sv_ctx;					\
	ST(0) = sv_2mortal(sv_bless(					\
		newRV_noinc(sv_ctx), gv_stashpv(SvPV_nolen(ST(0)), TRUE)\
	));								\
	XSRETURN(1);							\
}									\
									\
static XSPROTO(NAME(Ctx, get_digest, ALGO, ))				\
{									\
	dVAR;								\
	dXSARGS;							\
	if (items != 1)							\
		croak_xs_usage(cv, "sv_ctx");				\
									\
	ST(0) = sv_2mortal(newSVpvn(					\
		(char *) (						\
			(ALGO ## _HASH_CTX *)SvIV(SvRV(ST(0)))		\
		)->job.result_digest,					\
		sizeof(ALGO ## _WORD_T) * (ALGO ## _DIGEST_NWORDS)	\
	));								\
									\
	/* Byteswap string inside ST(0) */				\
	BYTESWAP_ ## ALGO(SvPVX(ST(0)));				\
	XSRETURN(1);							\
}									\
									\
static XSPROTO(NAME(Ctx, get_digest_hex, ALGO, ))			\
{									\
	dVAR;								\
	dXSARGS;							\
	if (items != 1)							\
		croak_xs_usage(cv, "sv_ctx");				\
									\
	char tmpstr[sizeof(ALGO ## _WORD_T) * (ALGO ## _DIGEST_NWORDS)];\
	memcpy(								\
		tmpstr,							\
		(							\
			(ALGO ## _HASH_CTX *)SvIV(SvRV(ST(0)))		\
		)->job.result_digest,					\
		sizeof(tmpstr)						\
	);								\
	BYTESWAP_ ## ALGO(tmpstr);					\
									\
	SV *ret_sv = newSV(2 * sizeof(tmpstr));				\
	SvUPGRADE(ret_sv, SVt_PV);					\
	SvPOKp_on(ret_sv);						\
	char *res_str = SvPVX(ret_sv);					\
	char *c = tmpstr;						\
	for (int i = 0; i < sizeof(tmpstr); i++) {			\
		*res_str++ = xmap[(*c >> 4) & 0x0f];			\
		*res_str++ = xmap[(*c++   ) & 0x0f];			\
	}								\
	*res_str = '\0';						\
	SvCUR_set(ret_sv, 2 * sizeof(tmpstr));				\
									\
	ST(0) = sv_2mortal(ret_sv);					\
	XSRETURN(1);							\
}									\
									\
static XSPROTO(NAME(Ctx, get_status, ALGO, ))				\
{									\
	dVAR;								\
	dXSARGS;							\
	if (items != 1)							\
		croak_xs_usage(cv, "sv_ctx");				\
									\
	ST(0) = sv_2mortal(newSViv((					\
			(ALGO ## _HASH_CTX *)SvIV(SvRV(ST(0)))		\
	)->status));							\
									\
	XSRETURN(1);							\
}									\
									\
static XSPROTO(NAME(Ctx, get_error, ALGO, ))				\
{									\
	dVAR;								\
	dXSARGS;							\
	if (items != 1)							\
		croak_xs_usage(cv, "sv_ctx");				\
									\
	ST(0) = sv_2mortal(newSViv(					\
			((ALGO ## _HASH_CTX *)SvIV(SvRV(ST(0)))		\
	)->error));							\
									\
	XSRETURN(1);							\
}									\
									\
static XSPROTO(XS_ISAL__Crypto__Ctx__ ## ALGO ## _DESTROY)		\
{									\
	dVAR;								\
	dXSARGS;							\
	if (items != 1)							\
		croak_xs_usage(cv, "sv_ctx");				\
									\
	/* cancel job from manager if it was submited */		\
	/* XXX May be it is not the best way to do it. Think about it */\
	ALGO ## _HASH_CTX *ctx = (ALGO ## _HASH_CTX *)SvIV(SvRV(ST(0)));\
	ALGO ## _MB_JOB_MGR *mgr = ctx->job.user_data;			\
	if (mgr) {							\
		int lane_to_clear = -1;					\
		for (int i = 0; i < (ALGO ## _MAX_LANES); i++) {	\
			if (mgr->ldata[i].job_in_lane == &ctx->job) {	\
				lane_to_clear = i;			\
				break;					\
			}						\
		}							\
		assert(lane_to_clear != -1				\
			&& "Try to clear unsubmited job"		\
		);							\
		/* job will be destroyed with ctx later */		\
		mgr->ldata[lane_to_clear].job_in_lane = NULL;		\
		MGR_SET_EMPTY_LANE_ ## ALGO(mgr, lane_to_clear);	\
		mgr->lens[lane_to_clear] =				\
			ALGO ## _DEFAULT_LEN(lane_to_clear);		\
									\
		--mgr->num_lanes_inuse;					\
	}								\
									\
	aligned_free(ctx);						\
}

/*************************** Generic macros ****************************/

#define MAKE_ALL(ALGO)							\
	MAKE_MGR_FUN(ALGO, _avx512)					\
	MAKE_MGR_FUN(ALGO, _avx2)					\
	MAKE_MGR_FUN(ALGO, _avx)					\
	MAKE_MGR_FUN(ALGO, _sse)					\
	MAKE_MGR_NON_CPU_FUN(ALGO)					\
	MAKE_CTX_NON_CPU_FUN(ALGO)

#define BUILD_MGR_CPU(ALGO, CPUF) STMT_START {				\
	BUILD_FUNC(Mgr, init,   ALGO, CPUF);				\
	BUILD_FUNC(Mgr, submit, ALGO, CPUF);				\
	BUILD_FUNC(Mgr, flush,  ALGO, CPUF);				\
} STMT_END

#define BUILD_MGR_ALL(ALGO) STMT_START {				\
	CV *xsub;							\
	BUILD_FUNC(Mgr, get_num_lanes_inuse, ALGO,);			\
	BUILD_MGR_CPU(ALGO, _avx512);					\
	BUILD_MGR_CPU(ALGO, _avx2);					\
	BUILD_MGR_CPU(ALGO, _avx);					\
	BUILD_MGR_CPU(ALGO, _sse);					\
	BUILD_DESTROY(Mgr, ALGO);					\
	PERL_UNUSED_VAR(xsub);						\
} STMT_END

#define BUILD_CTX_ALL(ALGO) STMT_START {				\
	CV *xsub;							\
	BUILD_FUNC(Ctx, init,           ALGO,);				\
	BUILD_FUNC(Ctx, get_digest,     ALGO,);				\
	BUILD_FUNC(Ctx, get_digest_hex, ALGO,);				\
	BUILD_FUNC(Ctx, get_status,     ALGO,);				\
	BUILD_FUNC(Ctx, get_error,      ALGO,);				\
	BUILD_DESTROY(Ctx, ALGO);					\
	PERL_UNUSED_VAR(xsub);						\
} STMT_END

/************************* Make and build all **************************/

MAKE_ALL(SHA1)
MAKE_ALL(SHA256)
MAKE_ALL(SHA512)
MAKE_ALL(MD5)

MODULE = ISAL::Crypto		PACKAGE = ISAL::Crypto::Mgr::SHA256

BOOT:
{
	BUILD_MGR_ALL(SHA256);
}

MODULE = ISAL::Crypto		PACKAGE = ISAL::Crypto::Ctx::SHA256

BOOT:
{
	BUILD_CTX_ALL(SHA256);
}

MODULE = ISAL::Crypto		PACKAGE = ISAL::Crypto::Mgr::SHA512

BOOT:
{
	BUILD_MGR_ALL(SHA512);
}

MODULE = ISAL::Crypto		PACKAGE = ISAL::Crypto::Ctx::SHA512

BOOT:
{
	BUILD_CTX_ALL(SHA512);
}

MODULE = ISAL::Crypto		PACKAGE = ISAL::Crypto::Mgr::SHA1

BOOT:
{
	BUILD_MGR_ALL(SHA1);
}

MODULE = ISAL::Crypto		PACKAGE = ISAL::Crypto::Ctx::SHA1

BOOT:
{
	BUILD_CTX_ALL(SHA1);
}

MODULE = ISAL::Crypto		PACKAGE = ISAL::Crypto::Mgr::MD5

BOOT:
{
	BUILD_MGR_ALL(MD5);
}

MODULE = ISAL::Crypto		PACKAGE = ISAL::Crypto::Ctx::MD5

BOOT:
{
	BUILD_CTX_ALL(MD5);
}

MODULE = ISAL::Crypto		PACKAGE = ISAL::Crypto		

BOOT:
{
	if (__get_cpuid_max(0, 0) < 7) {
		croak("Required cpuid level 7 is not supported\n");
	}
	
	HV *hv_features = newHV();
	unsigned eax = 0, ebx = 0, ecx = 0, edx = 0;
	/* Processor Info and Feature Bits */
	__get_cpuid(1, &eax, &ebx, &ecx, &edx);
	CHECK_AND_STORE_FEATURE_SUPPORT(hv_features, edx, _sse);
	CHECK_AND_STORE_FEATURE_SUPPORT(hv_features, ecx, _avx);
	/* Extended Features */
	__get_cpuid_count(7, 0, &eax, &ebx, &ecx, &edx);
	CHECK_AND_STORE_FEATURE_SUPPORT(hv_features, ebx, _avx2);
	CHECK_AND_STORE_FEATURE_SUPPORT(hv_features, ebx, _avx512f);
	CHECK_AND_STORE_FEATURE_SUPPORT(hv_features, ebx, _avx512vl);
	CHECK_AND_STORE_FEATURE_SUPPORT(hv_features, ebx, _avx512bw);
	CHECK_AND_STORE_FEATURE_SUPPORT(hv_features, ebx, _avx512cd);
	CHECK_AND_STORE_FEATURE_SUPPORT(hv_features, ebx, _avx512dq);
	
	if (
		has_avx512f
		| has_avx512vl
		| has_avx512bw
		| has_avx512cd
		| has_avx512dq
	) {
		STORE_AVX512_FEATURE(hv_features, 1);
	} else {
		STORE_AVX512_FEATURE(hv_features, 0);
	}
	HV *stash = gv_stashpv("ISAL::Crypto", TRUE);
	newCONSTSUB(stash, "CPU_FEATURES", newRV_noinc((SV *)hv_features));
}
