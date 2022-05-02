#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "tomcrypt.h"

MODULE = File::KDBX::XS  PACKAGE = File::KDBX::XS

PROTOTYPES: DISABLE

SV*
CowREFCNT(SV* sv)
    CODE:
#ifdef SV_COW_REFCNT_MAX
        if (SvIsCOW(sv)) XSRETURN_IV(0 < SvLEN(sv) ? CowREFCNT(sv) : 0);
#endif
        XSRETURN_UNDEF;
    OUTPUT:
        RETVAL

SV*
kdf_aes_transform_half(const char* key, const char* seed, unsigned int rounds)
    CODE:
        symmetric_key skey;

        unsigned char work[] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
        Copy(seed, work, 1, work);

        aes_setup(key, 32, 14, &skey);
        for (unsigned int i = 0; i < rounds; ++i) {
            aes_ecb_encrypt(work, work, &skey);
        }

        SV* result = newSVpvn(work, sizeof(work));

        Zero(&skey, 1, skey);
        Zero(work,  1, work);

        RETVAL = result;
    OUTPUT:
        RETVAL
