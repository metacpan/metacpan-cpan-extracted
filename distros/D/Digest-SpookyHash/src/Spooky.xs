#define PERL_NO_GET_CONTEXT
#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#ifdef __cplusplus
}
#endif
 
#include "SpookyV2.h"
 
MODULE = Digest::SpookyHash PACKAGE = Digest::SpookyHash
 
PROTOTYPES: DISABLE
 
U32
spooky32(const char * key, UV seed = 0, IV length(key))
CODE:
{
    RETVAL = SpookyHash::Hash32(key, STRLEN_length_of_key, seed);
}
OUTPUT:
    RETVAL

void
spooky64(const char * key, UV seed_ = 0, IV length(key))
PREINIT:
    uint64_t hash;
    uint64_t seed;
PPCODE:
{
    seed = seed_;
    hash = SpookyHash::Hash64(key, STRLEN_length_of_key,seed);
    EXTEND(SP, 1);
    mXPUSHu( hash );
}

void
spooky128(const char * key, UV seed1 = 0, UV seed2 = 0, IV length(key))
PREINIT:
    uint64_t hash1;
    uint64_t hash2;
PPCODE:
{
    hash1 = seed1;
    hash2 = seed2;
    SpookyHash::Hash128(key, STRLEN_length_of_key, &hash1, &hash2);
    EXTEND(SP, 2);
    mXPUSHu( hash1 );
    mXPUSHu( hash2 );
}
