#ifndef __MRO_COMPAT_XS__
#define __MRO_COMPAT_XS__

/*
 * chocolateboy 2009-02-07:
 *
 * this is copied, with a few minor modifications, from perl 5.10's mro.c, which in turn is:
 */

/*
 *    mro.c
 *
 *    Copyright (c) 2007 Brandon L Black
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 */

/* chocolateboy: these two are from sv.h - only tested back to 5.8.1 */

/* If I give every macro argument a different name, then there won't be bugs
   where nested macros get confused. Been there, done that.  */
#define SVpgv_GP        SVp_SCREAM  /* GV has a valid GP */
#define isGV_with_GP(pwadak) \
        (((SvFLAGS(pwadak) & (SVp_POK|SVpgv_GP)) == SVpgv_GP)   \
        && (SvTYPE(pwadak) == SVt_PVGV || SvTYPE(pwadak) == SVt_PVLV))

/* chocolateboy: ignore the stash on older perls as the generation counter is global */
#ifndef mro_get_pkg_gen
#define mro_get_pkg_gen(stash) PL_sub_generation
#endif

/* chocolateboy: emulate the default (i.e. only) MRO on older perls (and still the default on 5.10) */
#ifndef mro_get_linear_isa
#define mro_get_linear_isa(stash) mro_get_linear_isa_dfs(stash, 0)

#include "assert.h"

STATIC AV*
mro_get_linear_isa_dfs(pTHX_ HV *stash, I32 level) {
    AV* retval;
    GV** gvp;
    GV* gv;
    AV* av;
    const char * stashname;

    assert(stash);

    stashname = HvNAME(stash);

    if (!stashname)
        Perl_croak(aTHX_ "Can't linearize anonymous symbol table");

    if (level > 100)
        Perl_croak(aTHX_ "Recursive inheritance detected in package '%s'", stashname);

    /* not in cache, make a new one */
    retval = (AV*)sv_2mortal((SV *)newAV());
    av_push(retval, newSVpv(stashname, 0)); /* add ourselves at the top */

    /* fetch our @ISA */
    gvp = (GV**)hv_fetchs(stash, "ISA", FALSE);
    av = (gvp && (gv = *gvp) && isGV_with_GP(gv)) ? GvAV(gv) : NULL;

    if(av && AvFILLp(av) >= 0) {

        /* "stored" is used to keep track of all of the classnames
           we have added to the MRO so far, so we can do a quick
           exists check and avoid adding duplicate classnames to
           the MRO as we go. */

        HV* const stored = (HV*)sv_2mortal((SV*)newHV());
        SV **svp = AvARRAY(av);
        I32 items = AvFILLp(av) + 1;

        /* foreach(@ISA) */
        while (items--) {
            SV* const sv = *svp++;
            HV* const basestash = gv_stashsv(sv, 0);
            SV *const *subrv_p;
            I32 subrv_items;

            if (!basestash) {
                /* if no stash exists for this @ISA member,
                   simply add it to the MRO and move on */
                subrv_p = &sv;
                subrv_items = 1;
            }
            else {
                /* otherwise, recurse into ourselves for the MRO
                   of this @ISA member, and append their MRO to ours.
                   The recursive call could throw an exception, which
                   has memory management implications here, hence the use of
                   the mortal.  */
                const AV *const subrv = mro_get_linear_isa_dfs(aTHX_ basestash, level + 1);
                subrv_p = AvARRAY(subrv);
                subrv_items = AvFILLp(subrv) + 1;
            }

            while(subrv_items--) {
                SV *const subsv = *subrv_p++;
                if(!hv_exists_ent(stored, subsv, 0)) {
                    (void)hv_store_ent(stored, subsv, &PL_sv_undef, 0);
                    av_push(retval, newSVsv(subsv));
                }
            }
        }
    }

    /* now that we're past the exception dangers, grab our own reference to
       the AV we're about to use for the result. The reference owned by the
       mortals' stack will be released soon, so everything will balance.  */
    SvREFCNT_inc_simple_void_NN(retval);
    SvTEMP_off(retval);

    /* we don't want anyone modifying the cache entry but us,
       and we do so by replacing it completely */
    SvREADONLY_on(retval);

    return retval;
}

#endif /* ifndef mro_get_linear_isa */
#endif /* ifndef __MRO_COMPAT_XS__ */
