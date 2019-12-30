#ifndef ISAL_CRYPTO_H_
#define ISAL_CRYPTO_H_

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <cpuid.h> /* __get_cpuid_max __get_cpuid */

#include "isa-l_crypto.h"
#include "assert.h"

#ifndef LIKELY
# define LIKELY(x)   __builtin_expect((x),1)
# define UNLIKELY(x) __builtin_expect((x),0)
#endif

#define ISAALWAYSINLINE inline __attribute__((always_inline))
#define ISANOINLINE inline __attribute__((noinline))

#define ALC(ALGO) LOWCASE_ ## ALGO
#define AUC(ALGO) UPCASE_  ## ALGO

#define NAME_CPU_FEATURE(F)    NAME_CPU_F    ## F
#define NAME_CPU_FEATURE_LC(F) NAME_CPU_F_LC ## F

#define UPCASE_SHA1   SHA1
#define UPCASE_SHA256 SHA256
#define UPCASE_SHA512 SHA512
#define UPCASE_MD5    MD5

#define LOWCASE_SHA1   sha1
#define LOWCASE_SHA256 sha256
#define LOWCASE_SHA512 sha512
#define LOWCASE_MD5    md5

/* Not sure that this is really necessary */
#define SHA1_DEFAULT_LEN(lane)   0
#define SHA256_DEFAULT_LEN(lane) 0
#define SHA512_DEFAULT_LEN(lane) (lane) /* XXX MB it used only in avx512? */
#define MD5_DEFAULT_LEN(lane)    0xFFFFFFFF

#define NAME_CPU_F_sse      SSE
#define NAME_CPU_F_avx      AVX
#define NAME_CPU_F_avx2     AVX2
#define NAME_CPU_F_avx512f  AVX512F
#define NAME_CPU_F_avx512vl AVX512VL
#define NAME_CPU_F_avx512bw AVX512BW
#define NAME_CPU_F_avx512cd AVX512CD
#define NAME_CPU_F_avx512dq AVX512DQ
#define NAME_CPU_F_avx512   AVX512

#define NAME_CPU_F_LC_sse      sse
#define NAME_CPU_F_LC_avx      avx
#define NAME_CPU_F_LC_avx2     avx2
#define NAME_CPU_F_LC_avx512f  avx512f
#define NAME_CPU_F_LC_avx512vl avx512vl
#define NAME_CPU_F_LC_avx512bw avx512bw
#define NAME_CPU_F_LC_avx512cd avx512cd
#define NAME_CPU_F_LC_avx512dq avx512dq
#define NAME_CPU_F_LC_avx512   avx512

/* Concatenate preprocessor tokens without expanding macro definitions */
#define PPCAT_NX(prefix, type) prefix ## type

/* Concatenate preprocessor tokens after macro-expanding them */
#define PPCAT(prefix, type) PPCAT_NX(prefix, type)

/* Turn A into a string literal without expanding macro definitions */
#define TOSTR_NX(A) #A
/* Turn A into a string literal after macro-expanding it */
#define TOSTR(A) TOSTR_NX(A)

#define CNCT(a, ...) PRIMITIVE_CNCT(a, __VA_ARGS__)
#define PRIMITIVE_CNCT(a, ...) a ## __VA_ARGS__

#define BUILD_DESTROY(OBJ, ALGO) STMT_START {				\
	xsub = newXS(							\
		"ISAL::Crypto::" #OBJ "::" #ALGO "::DESTROY",		\
		XS_ISAL__Crypto__ ## OBJ ## __ ## ALGO ## _DESTROY,	\
		__FILE__						\
	);								\
} STMT_END

#define BUILD_FUNC(OBJ, func_name, ALGO, CPUF) STMT_START {		\
	xsub = newXS(							\
		"ISAL::Crypto::" #OBJ "::" #ALGO			\
			"::" #func_name #CPUF,				\
		PPCAT(							\
			XS_ISAL__Crypto__ ## OBJ ## __ ## ALGO ## _,	\
			func_name ## CPUF				\
		),							\
		__FILE__						\
	);								\
} STMT_END

#define NAME(OBJ, func_name, ALGO, CPUF) PPCAT(				\
	XS_ISAL__Crypto__ ## OBJ ## __ ## ALGO ## _,			\
	func_name ## CPUF						\
)

#define CHECK_CPUF(OBJ, func_name, ALGO, CPUF) STMT_START {		\
	if (UNLIKELY(							\
		/* has_FEATURE_NAME is global variable			\
		 * which defines on BOOT				\
		 */							\
		PPCAT(has_, NAME_CPU_FEATURE_LC(CPUF)) == 0		\
	)) {								\
		croak("CPU feature "					\
			TOSTR(NAME_CPU_FEATURE(CPUF))			\
			" required to call "				\
			"ISAL::Crypto::" #OBJ "::" #ALGO		\
			"::" #func_name #CPUF				\
		);							\
	}								\
} STMT_END

#endif /* !ISAL_CRYPTO_H_ */
