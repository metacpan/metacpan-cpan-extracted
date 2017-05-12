#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT /* we want efficiency */
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#ifdef __cplusplus
} /* extern "C" */
#endif

MODULE = Hash::BulkKeyCopy    PACKAGE = Hash::BulkKeyCopy

PROTOTYPES: DISABLE

void
hash_bulk_keycopy(hash_target, hash_src, hash_target_keyarr, hash_src_keyarr)
    HV* hash_target;
    HV* hash_src;
    AV* hash_target_keyarr;
    AV* hash_src_keyarr;
PREINIT:
    int ht_kl,hs_kl,i;
    char *k1, *k2;
    SV **ptr1, **ptr2, **src_value;
    STRLEN k1size,k2size;
PPCODE:
    ht_kl = av_len(hash_target_keyarr) + 1;
    hs_kl = av_len(hash_src_keyarr) + 1;
    if (hs_kl == 0 || (ht_kl > 0 && hs_kl != ht_kl)) return;
    for(i=0;i<hs_kl;i++) {
        ptr1 = av_fetch(hash_target_keyarr, i, 0);
        ptr2 = av_fetch(hash_src_keyarr, i, 0);
        k1 = ptr1 == NULL ? NULL : SvPV(*ptr1, k1size);
        k2 = SvPV(*ptr2, k2size);
        src_value = hv_fetch(hash_src, k2, k2size, 0);
        if (src_value) {
            (void)hv_store(hash_target, k1?k1:k2, k1?k1size:k2size, newSVsv(*src_value), 0);
        }
    }
