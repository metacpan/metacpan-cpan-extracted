#ifdef __cplusplus
extern "C" {
#endif
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

/* Hack to work around "error: declaration of 'Perl___notused' has a different */
/* language linkage" error on Clang */
#ifdef dNOOP
# undef dNOOP
# define dNOOP
#endif

#ifdef do_open
#undef do_open
#endif
#ifdef do_close
#undef do_close
#endif

#include "ppport.h"
#include "farmhash.h"

using namespace NAMESPACE_FOR_HASH_FUNCTIONS;

MODULE = Digest::FarmHash PACKAGE = Digest::FarmHash

PROTOTYPES: DISABLE

uint32_t
farmhash32(const char* data, size_t length(data), ...)
CODE:
    if (items == 1) {
        RETVAL = Hash32(data, STRLEN_length_of_data);
    } else if (items == 2) {
        RETVAL = Hash32WithSeed(data, STRLEN_length_of_data, SvUV(ST(1)));
    } else {
        croak("usage: farmhash32($data [, $seed])");
    }
OUTPUT:
    RETVAL

uint64_t
farmhash64(const char* data, size_t length(data), ...)
CODE:
    if (items == 1) {
        RETVAL = Hash64(data, STRLEN_length_of_data);
    } else if (items == 2) {
        RETVAL = Hash64WithSeed(data, STRLEN_length_of_data, SvUV(ST(1)));
    } else if (items == 3) {
        RETVAL = Hash64WithSeeds(data, STRLEN_length_of_data, SvUV(ST(1)), SvUV(ST(2)));
    } else {
        croak("usage: farmhash64($data [, $seed1, $seed2])");
    }
OUTPUT:
    RETVAL

void
farmhash128(const char* data, size_t length(data), ...)
PREINIT:
    uint128_t ret;
PPCODE:
    if (items == 1) {
        ret = Hash128(data, STRLEN_length_of_data);
    } else if (items == 3) {
        ret = Hash128WithSeed(data, STRLEN_length_of_data, Uint128(SvUV(ST(1)), SvUV(ST(2))));
    } else {
        croak("usage: farmhash128($data [, $seed])");
    }
    EXTEND(SP, 2);
    mPUSHu(Uint128Low64(ret));
    mPUSHu(Uint128High64(ret));

#define farmhash_fingerprint32 Fingerprint32
uint32_t farmhash_fingerprint32(const char* data, size_t length(data))

#define farmhash_fingerprint64 Fingerprint64
uint64_t farmhash_fingerprint64(const char* data, size_t length(data))

void
farmhash_fingerprint128(const char* data, size_t length(data))
PREINIT:
    uint128_t ret;
PPCODE:
    ret = Fingerprint128(data, STRLEN_length_of_data);
    EXTEND(SP, 2);
    mPUSHu(Uint128Low64(ret));
    mPUSHu(Uint128High64(ret));
