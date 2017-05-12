#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef PERL_MAGIC_uvar
#  define PERL_MAGIC_uvar                'U'
#endif
#ifndef PERL_MG_UFUNC
#  define PERL_MG_UFUNC(name,ix,sv) I32 name(IV ix, SV *sv)
#endif

#define MY_MAGIC_SIG_INDEX 708736475
#define MY_MAGIC_ERRNO_VALUE 458513437


static PERL_MG_UFUNC(my_get_fn, index, sv)
{
    SV *hkey_sv, **h_entry;
    char *kstr;
    int was_iok, was_iokp, was_nok, was_nokp;
    STRLEN klen;
    HV *errno_hash;
    IV num;

    was_iokp = SvIOKp(sv);
    was_nokp = SvNOKp(sv);
    was_iok  = SvIOK(sv);
    was_nok  = SvNOK(sv);
    if (!was_iokp && !was_nokp) {
        /* that's unexpected, native $! magic should have sorted that out */
        return 0;
    }

    errno_hash = get_hv("Errno::AnyString::Errno2Errstr", FALSE);
    if (! errno_hash) {
        /* can't find the hash, give up */
        return 0;
    }
        
    /* stringify the number for use as a hash key */
    num = (was_iokp ? SvIVX(sv) : SvNVX(sv));
    hkey_sv = newSViv(num);
    kstr = SvPV(hkey_sv, klen);

    h_entry = hv_fetch(errno_hash, kstr, klen, 0);
    if (! h_entry) {
        /* no custom error string for this errno value */
        return 0;
    }

    /* copy the custom error string into the pv slot */
    sv_setpv(sv, SvPV_nolen(*h_entry));

    /* preserve string/number duality */
    if (was_iok) SvIOK_on(sv);
    if (was_nok) SvNOK_on(sv);
    if (was_iokp) SvIOKp_on(sv);
    if (was_nokp) SvNOKp_on(sv);
    SvPOK_on(sv);

    return 0;
}

static PERL_MG_UFUNC(my_set_fn, index, sv)
{
    SV *hkey_sv, *hval_sv;
    char *kstr;
    STRLEN klen;
    HV *errno_hash;

    if ((SvIOKp(sv) || SvNOKp(sv)) && SvPOKp(sv)) {
        IV num = (SvIOKp(sv) ? SvIVX(sv) : SvNVX(sv));

        if ( num != MY_MAGIC_ERRNO_VALUE )
            return 0;
        /* This is a dualvar scalar with the magic errno value in its
         * number slot. Replace the current %Errno2Errstr entry for the
         * magic errno value with the string value. */

        errno_hash = get_hv("Errno::AnyString::Errno2Errstr", FALSE);
        if (! errno_hash) {
            /* can't find the hash, give up */
            return 0;
        }
        
        /* stringify the number for use as a hash key */
        hkey_sv = newSViv(num);
        kstr = SvPV(hkey_sv, klen);

        /* store the string in a non-dualvar scalar for use as the hash value */
        hval_sv = newSVpvn(SvPVX(sv), SvCUR(sv));

        if (! hv_store(errno_hash, kstr, klen, hval_sv, 0))
            SvREFCNT_dec(hval_sv);
        SvREFCNT_dec(hkey_sv);
    }
    return 0;
}

static void
do_install_magic(SV* sv)
{
    struct ufuncs uf;

    uf.uf_val   = &my_get_fn;
    uf.uf_set   = &my_set_fn;
    uf.uf_index = MY_MAGIC_SIG_INDEX;

#ifdef sv_magicext
    sv_magicext(sv, 0, PERL_MAGIC_uvar, &PL_vtbl_uvar, (char*)&uf, sizeof(uf));
#else
    sv_magic(sv, 0, PERL_MAGIC_uvar, (char*)&uf, sizeof(uf));
#endif
}

MODULE = Errno::AnyString		PACKAGE = Errno::AnyString		

void
_install_my_magic(sv)
    SV *sv;
PROTOTYPE: $
PREINIT:
    MAGIC *mg, *lastmg;
    struct ufuncs uf;
CODE:

    if (SvTYPE(sv) >= SVt_PVMG) {
        for ( mg=SvMAGIC(sv) ; mg ; mg=mg->mg_moremagic ) {
            if ( mg->mg_type == PERL_MAGIC_uvar && mg->mg_len == sizeof(uf) ) {
                memcpy( &uf, mg->mg_ptr, sizeof(uf) );
                if ( uf.uf_index == MY_MAGIC_SIG_INDEX ) {
                    /* my magic already in place, nothing to do */
                    return;
                }
            }
        }
    }
 
    do_install_magic(sv);
 
    /* My get magic needs to run after the native $! get magic, move it 
      to the tail of the list */
    mg = SvMAGIC(sv);
    if (mg && mg->mg_moremagic) {
        SvMAGIC(sv) = mg->mg_moremagic;
        for ( lastmg = mg->mg_moremagic ; lastmg->mg_moremagic ; lastmg = lastmg->mg_moremagic )
            ;
        lastmg->mg_moremagic = mg;
        mg->mg_moremagic = NULL;
    }

    /* Operations that copy the magic to a new SV (eg "local $!") can reverse
       the order of the magic linked list. To ensure that my get magic runs
       after $!'s, need an instance of it at each end of the list. */
    do_install_magic(sv);

