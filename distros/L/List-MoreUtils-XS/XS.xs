/**
 * List::MoreUtils::XS
 * Copyright 2004 - 2010 by by Tassilo von Parseval
 * Copyright 2013 - 2017 by Jens Rehsack
 *
 * All code added with 0.417 or later is licensed under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except in compliance
 * with the License. You may obtain a copy of the License at
 * 
 *  http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * 
 * All code until 0.416 is licensed under the same terms as Perl itself,
 * either Perl version 5.8.4 or, at your option, any later version of
 * Perl 5 you may have available.
 */

#include "LMUconfig.h"

#ifdef HAVE_TIME_H
# include <time.h>
#endif
#ifdef HAVE_SYS_TIME_H
# include <sys/time.h>
#endif

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "multicall.h"

#define NEED_gv_fetchpvn_flags
#include "ppport.h"

#ifndef MAX
# define MAX(a,b) ((a)>(b)?(a):(b))
#endif
#ifndef MIN
# define MIN(a,b) (((a)<(b))?(a):(b))
#endif

#ifndef aTHX
#  define aTHX
#  define pTHX
#endif

#ifndef croak_xs_usage

# ifndef PERL_ARGS_ASSERT_CROAK_XS_USAGE
#  define PERL_ARGS_ASSERT_CROAK_XS_USAGE assert(cv); assert(params)
# endif

static void
S_croak_xs_usage(pTHX_ const CV *const cv, const char *const params)
{
    const GV *const gv = CvGV(cv);

    PERL_ARGS_ASSERT_CROAK_XS_USAGE;

    if (gv) {
        const char *const gvname = GvNAME(gv);
        const HV *const stash = GvSTASH(gv);
        const char *const hvname = stash ? HvNAME(stash) : NULL;

        if (hvname)
            Perl_croak_nocontext("Usage: %s::%s(%s)", hvname, gvname, params);
        else
            Perl_croak_nocontext("Usage: %s(%s)", gvname, params);
    } else {
        /* Pants. I don't think that it should be possible to get here. */
        Perl_croak_nocontext("Usage: CODE(0x%"UVxf")(%s)", PTR2UV(cv), params);
    }
}

# define croak_xs_usage(a,b)     S_croak_xs_usage(aTHX_ a,b)
#endif

#ifdef SVf_IVisUV
#  define slu_sv_value(sv) (SvIOK(sv)) ? (SvIOK_UV(sv)) ? (NV)(SvUVX(sv)) : (NV)(SvIVX(sv)) : (SvNV(sv))
#else
#  define slu_sv_value(sv) (SvIOK(sv)) ? (NV)(SvIVX(sv)) : (SvNV(sv))
#endif

/*
 * Perl < 5.18 had some kind of different SvIV_please_nomg
 */
#if PERL_VERSION_LE(5,18,0)
#undef SvIV_please_nomg
#  define SvIV_please_nomg(sv) \
        (!SvIOKp(sv) && (SvNOK(sv) || SvPOK(sv)) \
            ? (SvIV_nomg(sv), SvIOK(sv))          \
            : SvIOK(sv))
#endif

#ifndef MUTABLE_GV
# define MUTABLE_GV(a) (GV *)(a)
#endif

#if !defined(HAS_BUILTIN_EXPECT) && defined(HAVE_BUILTIN_EXPECT)
# ifdef LIKELY
#  undef LIKELY
# endif
# ifdef UNLIKELY
#  undef UNLIKELY
# endif
# define LIKELY(x) __builtin_expect(!!(x), 1)
# define UNLIKELY(x) __builtin_expect(!!(x), 0)
#endif

#ifndef LIKELY
# define LIKELY(x) (x)
#endif
#ifndef UNLIKELY
# define UNLIKELY(x) (x)
#endif
#ifndef GV_NOTQUAL
# define GV_NOTQUAL 0
#endif

#ifdef _MSC_VER
# define inline __inline
#endif

#ifndef HAVE_SIZE_T
# if SIZEOF_PTR == SIZEOF_LONG_LONG
typedef unsigned long long size_t;
# elif SIZEOF_PTR == SIZEOF_LONG
typedef unsigned long size_t;
# elif SIZEOF_PTR == SIZEOF_INT
typedef unsigned int size_t;
# else
#  error "Can't determine type for size_t"
# endif
#endif

#ifndef HAVE_SSIZE_T
# if SIZEOF_PTR == SIZEOF_LONG_LONG
typedef signed long long ssize_t;
# elif SIZEOF_PTR == SIZEOF_LONG
typedef signed long ssize_t;
# elif SIZEOF_PTR == SIZEOF_INT
typedef signed int ssize_t;
# else
#  error "Can't determine type for ssize_t"
# endif
#endif


/* compare left and right SVs. Returns:
 * -1: <
 *  0: ==
 *  1: >
 *  2: left or right was a NaN
 */
static I32
LMUncmp(pTHX_ SV* left, SV * right)
{
    /* Fortunately it seems NaN isn't IOK */
    if(SvAMAGIC(left) || SvAMAGIC(right))
        return SvIVX(amagic_call(left, right, ncmp_amg, 0));

    if (SvIV_please_nomg(right) && SvIV_please_nomg(left))
    {
        if (!SvUOK(left))
        {
            const IV leftiv = SvIVX(left);
            if (!SvUOK(right))
            {
                /* ## IV <=> IV ## */
                const IV rightiv = SvIVX(right);
                return (leftiv > rightiv) - (leftiv < rightiv);
            }
            /* ## IV <=> UV ## */
            if (leftiv < 0)
                /* As (b) is a UV, it's >=0, so it must be < */
                return -1;

            return ((UV)leftiv > SvUVX(right)) - ((UV)leftiv < SvUVX(right));
        }

        if (SvUOK(right))
        {
            /* ## UV <=> UV ## */
            const UV leftuv = SvUVX(left);
            const UV rightuv = SvUVX(right);
            return (leftuv > rightuv) - (leftuv < rightuv);
        }

        /* ## UV <=> IV ## */
        if (SvIVX(right) < 0)
            /* As (a) is a UV, it's >=0, so it cannot be < */
            return 1;

        return (SvUVX(left) > SvUVX(right)) - (SvUVX(left) < SvUVX(right));
    }
    else
    {
#ifdef SvNV_nomg
        NV const rnv = SvNV_nomg(right);
        NV const lnv = SvNV_nomg(left);
#else
        NV const rnv = slu_sv_value(right);
        NV const lnv = slu_sv_value(left);
#endif

#if defined(NAN_COMPARE_BROKEN) && defined(Perl_isnan)
        if (Perl_isnan(lnv) || Perl_isnan(rnv))
            return 2;
        return (lnv > rnv) - (lnv < rnv);
#else
        if (lnv < rnv)
            return -1;
        if (lnv > rnv)
            return 1;
        if (lnv == rnv)
            return 0;
        return 2;
#endif
    }
}

#define ncmp(left,right) LMUncmp(aTHX_ left,right)

#define FUNC_NAME GvNAME(GvEGV(ST(items)))

/* shameless stolen from PadWalker */
#ifndef PadARRAY
typedef AV PADNAMELIST;
typedef SV PADNAME;
# if PERL_VERSION_LE(5,8,0)
typedef AV PADLIST;
typedef AV PAD;
# endif
# define PadlistARRAY(pl)       ((PAD **)AvARRAY(pl))
# define PadlistMAX(pl)         av_len(pl)
# define PadlistNAMES(pl)       (*PadlistARRAY(pl))
# define PadnamelistARRAY(pnl)  ((PADNAME **)AvARRAY(pnl))
# define PadnamelistMAX(pnl)    av_len(pnl)
# define PadARRAY               AvARRAY
# define PadnameIsOUR(pn)       !!(SvFLAGS(pn) & SVpad_OUR)
# define PadnameOURSTASH(pn)    SvOURSTASH(pn)
# define PadnameOUTER(pn)       !!SvFAKE(pn)
# define PadnamePV(pn)          (SvPOKp(pn) ? SvPVX(pn) : NULL)
#endif

static int 
in_pad (pTHX_ SV *code)
{
    GV *gv;
    HV *stash;
    CV *cv = sv_2cv(code, &stash, &gv, 0);
    PADLIST *pad_list = (CvPADLIST(cv));
    PADNAMELIST *pad_namelist = PadlistNAMES(pad_list);
    int i;

    for (i=PadnamelistMAX(pad_namelist); i>=0; --i)
    {
        PADNAME* name_sv = PadnamelistARRAY(pad_namelist)[i];
        if (name_sv)
        {
            char *name_str = PadnamePV(name_sv);
            if (name_str) {

                /* perl < 5.6.0 does not yet have our */
#               ifdef SVpad_OUR
                if(PadnameIsOUR(name_sv))
                    continue;
#               endif

#if PERL_VERSION_LT(5,21,7)
                if (!SvOK(name_sv))
                    continue;
#endif

                if (strEQ(name_str, "$a") || strEQ(name_str, "$b"))
                    return 1;
            }
        }
    }
    return 0;
}

#define WARN_OFF \
    SV *oldwarn = PL_curcop->cop_warnings; \
    PL_curcop->cop_warnings = pWARN_NONE;

#define WARN_ON \
    PL_curcop->cop_warnings = oldwarn;

#define EACH_ARRAY_BODY \
        int i;                                                                          \
        arrayeach_args * args;                                                          \
        HV *stash = gv_stashpv("List::MoreUtils::XS_ea", TRUE);                         \
        CV *closure = newXS(NULL, XS_List__MoreUtils__XS__array_iterator, __FILE__);    \
                                                                                        \
        /* prototype */                                                                 \
        sv_setpv((SV*)closure, ";$");                                                   \
                                                                                        \
        New(0, args, 1, arrayeach_args);                                                \
        New(0, args->avs, items, AV*);                                                  \
        args->navs = items;                                                             \
        args->curidx = 0;                                                               \
                                                                                        \
        for (i = 0; i < items; i++) {                                                   \
            if(UNLIKELY(!arraylike(ST(i))))                                             \
               croak_xs_usage(cv,  "\\@;\\@\\@...");                                    \
            args->avs[i] = (AV*)SvRV(ST(i));                                            \
            SvREFCNT_inc(args->avs[i]);                                                 \
        }                                                                               \
                                                                                        \
        CvXSUBANY(closure).any_ptr = args;                                              \
        RETVAL = newRV_noinc((SV*)closure);                                             \
                                                                                        \
        /* in order to allow proper cleanup in DESTROY-handler */                       \
        sv_bless(RETVAL, stash)

#define LMUFECPY(a) (a)
#define dMULTICALLSVCV                          \
        HV *stash;                              \
        GV *gv;                                 \
        I32 gimme = G_SCALAR;                   \
        CV *mc_cv = sv_2cv(code, &stash, &gv, 0)


#define FOR_EACH(on_item)                       \
    if(!codelike(code))                         \
       croak_xs_usage(cv,  "code, ...");        \
                                                \
    if (items > 1) {                            \
        dMULTICALL;                             \
        dMULTICALLSVCV;                         \
        int i;                                  \
        SV **args = &PL_stack_base[ax];         \
        PUSH_MULTICALL(mc_cv);                  \
        SAVESPTR(GvSV(PL_defgv));               \
                                                \
        for(i = 1 ; i < items ; ++i) {          \
            GvSV(PL_defgv) = LMUFECPY(args[i]); \
            MULTICALL;                          \
            on_item;                            \
        }                                       \
        POP_MULTICALL;                          \
    }

#define TRUE_JUNCTION                             \
    FOR_EACH(if (SvTRUE(*PL_stack_sp)) ON_TRUE)   \
    else ON_EMPTY;

#define FALSE_JUNCTION                            \
    FOR_EACH(if (!SvTRUE(*PL_stack_sp)) ON_FALSE) \
    else ON_EMPTY;

#define ROF_EACH(on_item)                       \
    if(!codelike(code))                         \
       croak_xs_usage(cv,  "code, ...");        \
                                                \
    if (items > 1) {                            \
        dMULTICALL;                             \
        dMULTICALLSVCV;                         \
        int i;                                  \
        SV **args = &PL_stack_base[ax];         \
        PUSH_MULTICALL(mc_cv);                  \
        SAVESPTR(GvSV(PL_defgv));               \
                                                \
        for(i = items-1; i > 0; --i) {          \
            GvSV(PL_defgv) = LMUFECPY(args[i]); \
            MULTICALL;                          \
            on_item;                            \
        }                                       \
        POP_MULTICALL;                          \
    }

#define REDUCE_WITH(init)                            \
    dMULTICALL;                                      \
    dMULTICALLSVCV;                                  \
    SV *rc, **args = &PL_stack_base[ax];             \
    IV i;                                            \
                                                     \
    if(!codelike(code))                              \
       croak_xs_usage(cv,  "code, list, list");      \
                                                     \
    if (in_pad(aTHX_ code)) {                        \
        croak("Can't use lexical $a or $b in pairwise code block"); \
    }                                                \
                                                     \
    rc = (init);                                     \
    sv_2mortal(newRV_noinc(rc));                     \
                                                     \
    PUSH_MULTICALL(mc_cv);                           \
    SAVESPTR(GvSV(PL_defgv));                        \
                                                     \
    /* Following code is stolen on request of */     \
    /* Zefram from pp_sort.c of perl core 16ada23 */ \
    /* I have no idea why it's necessary and there */\
    /* is no reasonable documentation regarding */   \
    /* deal with localized $a/$b/$_ */               \
    SAVEGENERICSV(PL_firstgv);                       \
    SAVEGENERICSV(PL_secondgv);                      \
    PL_firstgv = MUTABLE_GV(SvREFCNT_inc(            \
        gv_fetchpvs("a", GV_ADD|GV_NOTQUAL, SVt_PV)  \
    ));                                              \
    PL_secondgv = MUTABLE_GV(SvREFCNT_inc(           \
        gv_fetchpvs("b", GV_ADD|GV_NOTQUAL, SVt_PV)  \
    ));                                              \
    save_gp(PL_firstgv, 0); save_gp(PL_secondgv, 0); \
    GvINTRO_off(PL_firstgv);                         \
    GvINTRO_off(PL_secondgv);                        \
    SAVEGENERICSV(GvSV(PL_firstgv));                 \
    SvREFCNT_inc(GvSV(PL_firstgv));                  \
    SAVEGENERICSV(GvSV(PL_secondgv));                \
    SvREFCNT_inc(GvSV(PL_secondgv));                 \
                                                     \
    for (i = 1; i < items; ++i)                      \
    {                                                \
        SV *olda, *oldb;                             \
        sv_setiv(GvSV(PL_defgv), i-1);               \
                                                     \
        olda = GvSV(PL_firstgv);                     \
        oldb = GvSV(PL_secondgv);                    \
        GvSV(PL_firstgv) = SvREFCNT_inc_simple_NN(rc); \
        GvSV(PL_secondgv) = SvREFCNT_inc_simple_NN(args[i]); \
        SvREFCNT_dec(olda);                          \
        SvREFCNT_dec(oldb);                          \
        MULTICALL;                                   \
                                                     \
        SvSetMagicSV(rc, *PL_stack_sp);              \
    }                                                \
                                                     \
    POP_MULTICALL;                                   \
                                                     \
    EXTEND(SP, 1);                                   \
    ST(0) = sv_2mortal(newSVsv(rc));                 \
    XSRETURN(1)


#define COUNT_ARGS                                    \
    for (i = 0; i < items; i++) {                     \
        SvGETMAGIC(args[i]);                          \
        if(SvOK(args[i])) {                           \
            HE *he;                                   \
            SvSetSV_nosteal(tmp, args[i]);            \
            he = hv_fetch_ent(hv, tmp, 0, 0);         \
            if (NULL == he) {                         \
                args[count++] = args[i];              \
                hv_store_ent(hv, tmp, newSViv(1), 0); \
            }                                         \
            else {                                    \
                SV *v = HeVAL(he);                    \
                IV how_many = SvIVX(v);               \
                sv_setiv(v, ++how_many);              \
            }                                         \
        }                                             \
        else if(0 == seen_undef++) {                  \
            args[count++] = args[i];                  \
        }                                             \
    }

#define COUNT_ARGS_MAX                                    \
    do {                                                  \
        for (i = 0; i < items; i++) {                     \
            SvGETMAGIC(args[i]);                          \
            if(SvOK(args[i])) {                           \
                HE *he;                                   \
                SvSetSV_nosteal(tmp, args[i]);            \
                he = hv_fetch_ent(hv, tmp, 0, 0);         \
                if (NULL == he) {                         \
                    args[count++] = args[i];              \
                    hv_store_ent(hv, tmp, newSViv(1), 0); \
                }                                         \
                else {                                    \
                    SV *v = HeVAL(he);                    \
                    IV how_many = SvIVX(v);               \
                    if(UNLIKELY(max < ++how_many))        \
                        max = how_many;                   \
                    sv_setiv(v, how_many);                \
                }                                         \
            }                                             \
            else if(0 == seen_undef++) {                  \
                args[count++] = args[i];                  \
            }                                             \
        }                                                 \
        if(UNLIKELY(max < seen_undef)) max = seen_undef;  \
    } while(0)


/* need this one for array_each() */
typedef struct
{
    AV **avs;       /* arrays over which to iterate in parallel */
    int navs;       /* number of arrays */
    int curidx;     /* the current index of the iterator */
} arrayeach_args;

/* used for natatime */
typedef struct
{
    SV **svs;
    int nsvs;
    int curidx;
    int natatime;
} natatime_args;

static void
insert_after (pTHX_ int idx, SV *what, AV *av)
{
    int i, len;
    av_extend(av, (len = av_len(av) + 1));

    for (i = len; i > idx+1; i--)
    {
        SV **sv = av_fetch(av, i-1, FALSE);
        SvREFCNT_inc(*sv);
        av_store(av, i, *sv);
    }

    if (!av_store(av, idx+1, what))
        SvREFCNT_dec(what);
}

static int
is_like(pTHX_ SV *sv, const char *like)
{
    int likely = 0;
    if( sv_isobject( sv ) )
    {
        dSP;
        int count;

        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs( sv_2mortal( newSVsv( sv ) ) );
        XPUSHs( sv_2mortal( newSVpv( like, strlen(like) ) ) );
        PUTBACK;

        if( ( count = call_pv("overload::Method", G_SCALAR) ) )
        {
            I32 ax;
            SPAGAIN;

            SP -= count;
            ax = (SP - PL_stack_base) + 1;
            if( SvTRUE(ST(0)) )
                ++likely;
        }

        FREETMPS;
        LEAVE;
    }

    return likely;
}

static int
is_array(SV *sv)
{
    return SvROK(sv) && ( SVt_PVAV == SvTYPE(SvRV(sv) ) );
}

static int
LMUcodelike(pTHX_ SV *code)
{
    SvGETMAGIC(code);
    return SvROK(code) && ( ( SVt_PVCV == SvTYPE(SvRV(code)) ) || ( is_like(aTHX_ code, "&{}" ) ) );
}

#define codelike(code) LMUcodelike(aTHX_ code)

static int
LMUarraylike(pTHX_ SV *array)
{
    SvGETMAGIC(array);
    return is_array(array) || is_like(aTHX_ array, "@{}" );
}

#define arraylike(array) LMUarraylike(aTHX_ array)

static void
LMUav2flat(pTHX_ AV *tgt, AV *args)
{
    I32 k = 0, j = av_len(args) + 1;

    av_extend(tgt, AvFILLp(tgt) + j);

    while( --j >= 0 )
    {
        SV *sv = *av_fetch(args, k++, FALSE);
        if(arraylike(sv))
        {
            AV *av = (AV *)SvRV(sv);
            LMUav2flat(aTHX_ tgt, av);
        }
        else
        {
            // av_push(tgt, newSVsv(sv));
            av_push(tgt, SvREFCNT_inc(sv));
        }
    }
}

/*-
 * Copyright (c) 1992, 1993
 *      The Regents of the University of California.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

/*
 * FreeBSD's Qsort routine from Bentley & McIlroy's "Engineering a Sort Function".
 * Modified for using Perl Sub (no XSUB) via MULTICALL and all values are SV **
 */
static inline void
swapfunc(SV **a, SV **b, size_t n)
{
    SV **pa = a;
    SV **pb = b;
    while(n-- > 0)
    {
        SV *t = *pa;
        *pa++ = *pb;
        *pb++ = t;
    }
}

#define swap(a, b)    \
    do {              \
        SV *t = *(a); \
        *(a) = *(b);  \
        *(b) = t;     \
    } while(0)

#define vecswap(a, b, n)  \
    if ((n) > 0) swapfunc(a, b, n)

#if HAVE_FEATURE_STATEMENT_EXPRESSION
# define CMP(x, y) ({ \
        GvSV(PL_firstgv) = *(x); \
        GvSV(PL_secondgv) = *(y); \
        MULTICALL; \
        SvIV(*PL_stack_sp); \
    })
#else
static inline int _cmpsvs(pTHX_ SV *x, SV *y, OP *multicall_cop )
{
    GvSV(PL_firstgv) = x;
    GvSV(PL_secondgv) = y;
    MULTICALL;
    return SvIV(*PL_stack_sp);
}
# define CMP(x, y) _cmpsvs(aTHX_ *(x), *(y), multicall_cop)
#endif

#define MED3(a, b, c) ( \
    CMP(a, b) < 0 ? \
       (CMP(b, c) < 0 ? b : (CMP(a, c) < 0 ? c : a )) \
      :(CMP(b, c) > 0 ? b : (CMP(a, c) < 0 ? a : c )) \
)

static void
bsd_qsort_r(pTHX_ SV **ary, size_t nelem, OP *multicall_cop)
{
    SV **pa, **pb, **pc, **pd, **pl, **pm, **pn;
    size_t d1, d2;
    int cmp_result, swap_cnt = 0;

loop:
    if (nelem < 7)
    {
        for (pm = ary + 1; pm < ary + nelem; ++pm)
            for (pl = pm; 
                 pl > ary && CMP(pl - 1, pl) > 0;
                 pl -= 1)
                swap(pl, pl - 1);

        return;
    }

    pm = ary + (nelem / 2);
    if (nelem > 7)
    {
        pl = ary;
        pn = ary + (nelem - 1);
        if (nelem > 40)
        {
            size_t d = (nelem / 8);

            pl = MED3(pl, pl + d, pl + 2 * d);
            pm = MED3(pm - d, pm, pm + d);
            pn = MED3(pn - 2 * d, pn - d, pn);
        }
        pm = MED3(pl, pm, pn);
    }
    swap(ary, pm);
    pa = pb = ary + 1;

    pc = pd = ary + (nelem - 1);
    for (;;)
    {
        while (pb <= pc && (cmp_result = CMP(pb, ary)) <= 0)
        {
            if (cmp_result == 0)
            {
                swap_cnt = 1;
                swap(pa, pb);
                pa += 1;
            }

            pb += 1;
        }

        while (pb <= pc && (cmp_result = CMP(pc, ary)) >= 0)
        {
            if (cmp_result == 0)
            {
                swap_cnt = 1;
                swap(pc, pd);
                pd -= 1;
            }
            pc -= 1;
        }

        if (pb > pc)
            break;

        swap(pb, pc);
        swap_cnt = 1;
        pb += 1;
        pc -= 1;
    }
    if (swap_cnt == 0)
    {  /* Switch to insertion sort */
        for (pm = ary + 1; pm < ary + nelem; pm += 1)
            for (pl = pm; 
                 pl > ary && CMP(pl - 1, pl) > 0;
                 pl -= 1)
                swap(pl, pl - 1);
        return;
    }

    pn = ary + nelem;
    d1 = MIN(pa - ary, pb - pa);
    vecswap(ary, pb - d1, d1);
    d1 = MIN(pd - pc, pn - pd - 1);
    vecswap(pb, pn - d1, d1);

    d1 = pb - pa;
    d2 = pd - pc;
    if (d1 <= d2)
    {
        /* Recurse on left partition, then iterate on right partition */
        if (d1 > 1)
            bsd_qsort_r(aTHX_ ary, d1, multicall_cop);

        if (d2 > 1)
        {
            /* Iterate rather than recurse to save stack space */
            /* qsort(pn - d2, d2, multicall_cop); */
            ary = pn - d2;
            nelem = d2;
            goto loop;
        }
    }
    else
    {
        /* Recurse on right partition, then iterate on left partition */
        if (d2 > 1)
            bsd_qsort_r(aTHX_ pn - d2, d2, multicall_cop);

        if (d1 > 1)
        {
            /* Iterate rather than recurse to save stack space */
            /* qsort(ary, d1, multicall_cop); */
            nelem = d1;
            goto loop;
        }
    }
}

/* lower_bound algorithm from STL - see http://en.cppreference.com/w/cpp/algorithm/lower_bound */
#define LOWER_BOUND(at)               \
    while (count > 0) {               \
        ssize_t step = count / 2;     \
        ssize_t it = first + step;    \
                                      \
        GvSV(PL_defgv) = at;          \
        MULTICALL;                    \
        cmprc = SvIV(*PL_stack_sp);   \
        if (cmprc < 0) {              \
            first = ++it;             \
            count -= step + 1;        \
        }                             \
        else                          \
            count = step;             \
    }

#define LOWER_BOUND_QUICK(at)         \
    while (count > 0) {               \
        ssize_t step = count / 2;     \
        ssize_t it = first + step;    \
                                      \
        GvSV(PL_defgv) = at;          \
        MULTICALL;                    \
        cmprc = SvIV(*PL_stack_sp);   \
        if(UNLIKELY(0 == cmprc)) {    \
            first = it;               \
            break;                    \
        }                             \
        if (cmprc < 0) {              \
            first = ++it;             \
            count -= step + 1;        \
        }                             \
        else                          \
            count = step;             \
    }

/* upper_bound algorithm from STL - see http://en.cppreference.com/w/cpp/algorithm/upper_bound */
#define UPPER_BOUND(at)                 \
    while (count > 0) {                 \
        ssize_t step = count / 2;       \
        ssize_t it = first + step;      \
                                        \
        GvSV(PL_defgv) = at;            \
        MULTICALL;                      \
        cmprc = SvIV(*PL_stack_sp); \
        if (cmprc <= 0) {               \
            first = ++it;               \
            count -= step + 1;          \
        }                               \
        else                            \
            count = step;               \
    }


MODULE = List::MoreUtils::XS_ea             PACKAGE = List::MoreUtils::XS_ea

void
DESTROY(sv)
SV *sv;
CODE:
{
    int i;
    CV *code = (CV*)SvRV(sv);
    arrayeach_args *args = (arrayeach_args *)(CvXSUBANY(code).any_ptr);
    if (args)
    {
        for (i = 0; i < args->navs; ++i)
            SvREFCNT_dec(args->avs[i]);

        Safefree(args->avs);
        Safefree(args);
        CvXSUBANY(code).any_ptr = NULL;
    }
}


MODULE = List::MoreUtils::XS_na             PACKAGE = List::MoreUtils::XS_na

void
DESTROY(sv)
SV *sv;
CODE:
{
    int i;
    CV *code = (CV*)SvRV(sv);
    natatime_args *args = (natatime_args *)(CvXSUBANY(code).any_ptr);
    if (args)
    {
        for (i = 0; i < args->nsvs; ++i)
            SvREFCNT_dec(args->svs[i]);

        Safefree(args->svs);
        Safefree(args);
        CvXSUBANY(code).any_ptr = NULL;
    }
}

MODULE = List::MoreUtils::XS            PACKAGE = List::MoreUtils::XS

void
any (code,...)
    SV *code;
PROTOTYPE: &@
CODE:
{
#define ON_TRUE { POP_MULTICALL; XSRETURN_YES; }
#define ON_EMPTY XSRETURN_NO
    TRUE_JUNCTION;
    XSRETURN_NO;
#undef ON_EMPTY
#undef ON_TRUE
}

void
all (code, ...)
    SV *code;
PROTOTYPE: &@
CODE:
{
#define ON_FALSE { POP_MULTICALL; XSRETURN_NO; }
#define ON_EMPTY XSRETURN_YES
    FALSE_JUNCTION;
    XSRETURN_YES;
#undef ON_EMPTY
#undef ON_FALSE
}


void
none (code, ...)
    SV *code;
PROTOTYPE: &@
CODE:
{
#define ON_TRUE { POP_MULTICALL; XSRETURN_NO; }
#define ON_EMPTY XSRETURN_YES
    TRUE_JUNCTION;
    XSRETURN_YES;
#undef ON_EMPTY
#undef ON_TRUE
}

void
notall (code, ...)
    SV *code;
PROTOTYPE: &@
CODE:
{
#define ON_FALSE { POP_MULTICALL; XSRETURN_YES; }
#define ON_EMPTY XSRETURN_NO
    FALSE_JUNCTION;
    XSRETURN_NO;
#undef ON_EMPTY
#undef ON_FALSE
}

void
one (code, ...)
    SV *code;
PROTOTYPE: &@
CODE:
{
    int found = 0;
#define ON_TRUE { if (found++) { POP_MULTICALL; XSRETURN_NO; }; }
#define ON_EMPTY XSRETURN_NO
    TRUE_JUNCTION;
    if (found)
        XSRETURN_YES;
    XSRETURN_NO;
#undef ON_EMPTY
#undef ON_TRUE
}

void
any_u (code,...)
    SV *code;
PROTOTYPE: &@
CODE:
{
#define ON_TRUE { POP_MULTICALL; XSRETURN_YES; }
#define ON_EMPTY XSRETURN_UNDEF
    TRUE_JUNCTION;
    XSRETURN_NO;
#undef ON_EMPTY
#undef ON_TRUE
}

void
all_u (code, ...)
    SV *code;
PROTOTYPE: &@
CODE:
{
#define ON_FALSE { POP_MULTICALL; XSRETURN_NO; }
#define ON_EMPTY XSRETURN_UNDEF
    FALSE_JUNCTION;
    XSRETURN_YES;
#undef ON_EMPTY
#undef ON_FALSE
}


void
none_u (code, ...)
    SV *code;
PROTOTYPE: &@
CODE:
{
#define ON_TRUE { POP_MULTICALL; XSRETURN_NO; }
#define ON_EMPTY XSRETURN_UNDEF
    TRUE_JUNCTION;
    XSRETURN_YES;
#undef ON_EMPTY
#undef ON_TRUE
}

void
notall_u (code, ...)
    SV *code;
PROTOTYPE: &@
CODE:
{
#define ON_FALSE { POP_MULTICALL; XSRETURN_YES; }
#define ON_EMPTY XSRETURN_UNDEF
    FALSE_JUNCTION;
    XSRETURN_NO;
#undef ON_EMPTY
#undef ON_FALSE
}

void
one_u (code, ...)
    SV *code;
PROTOTYPE: &@
CODE:
{
    int found = 0;
#define ON_TRUE { if (found++) { POP_MULTICALL; XSRETURN_NO; }; }
#define ON_EMPTY XSRETURN_UNDEF
    TRUE_JUNCTION;
    if (found)
        XSRETURN_YES;
    XSRETURN_NO;
#undef ON_EMPTY
#undef ON_TRUE
}

void
reduce_u(code, ...)
    SV *code;
PROTOTYPE: &@
CODE:
{
    REDUCE_WITH(newSVsv(&PL_sv_undef));
}

void
reduce_0(code, ...)
    SV *code;
PROTOTYPE: &@
CODE:
{
    REDUCE_WITH(newSViv(0));
}

void
reduce_1(code, ...)
    SV *code;
PROTOTYPE: &@
CODE:
{
    REDUCE_WITH(newSViv(1));
}

int
true (code, ...)
    SV *code;
PROTOTYPE: &@
CODE:
{
    I32 count = 0;
    FOR_EACH(if (SvTRUE(*PL_stack_sp)) count++);
    RETVAL = count;
}
OUTPUT:
    RETVAL

int
false (code, ...)
    SV *code;
PROTOTYPE: &@
CODE:
{
    I32 count = 0;
    FOR_EACH(if (!SvTRUE(*PL_stack_sp)) count++);
    RETVAL = count;
}
OUTPUT:
    RETVAL

int
firstidx (code, ...)
    SV *code;
PROTOTYPE: &@
CODE:
{
    RETVAL = -1;
    FOR_EACH(if (SvTRUE(*PL_stack_sp)) { RETVAL = i-1; break; });
}
OUTPUT:
    RETVAL

SV *
firstval (code, ...)
    SV *code;
PROTOTYPE: &@
CODE:
{
    RETVAL = &PL_sv_undef;
    FOR_EACH(if (SvTRUE(*PL_stack_sp)) { SvREFCNT_inc(RETVAL = args[i]); break; });
}
OUTPUT:
    RETVAL

SV *
firstres (code, ...)
    SV *code;
PROTOTYPE: &@
CODE:
{
    RETVAL = &PL_sv_undef;
    FOR_EACH(if (SvTRUE(*PL_stack_sp)) { SvREFCNT_inc(RETVAL = *PL_stack_sp); break; });
}
OUTPUT:
    RETVAL

int
onlyidx (code, ...)
    SV *code;
PROTOTYPE: &@
CODE:
{
    int found = 0;
    RETVAL = -1;
    FOR_EACH(if (SvTRUE(*PL_stack_sp)) { if (found++) {RETVAL = -1; break;} RETVAL = i-1; });
}
OUTPUT:
    RETVAL

SV *
onlyval (code, ...)
    SV *code;
PROTOTYPE: &@
CODE:
{
    int found = 0;
    RETVAL = &PL_sv_undef;
    FOR_EACH(if (SvTRUE(*PL_stack_sp)) { if (found++) {SvREFCNT_dec(RETVAL); RETVAL = &PL_sv_undef; break;} SvREFCNT_inc(RETVAL = args[i]); });
}
OUTPUT:
    RETVAL

SV *
onlyres (code, ...)
    SV *code;
PROTOTYPE: &@
CODE:
{
    int found = 0;
    RETVAL = &PL_sv_undef;
    FOR_EACH(if (SvTRUE(*PL_stack_sp)) { if (found++) {SvREFCNT_dec(RETVAL); RETVAL = &PL_sv_undef; break;}SvREFCNT_inc(RETVAL = *PL_stack_sp); });
}
OUTPUT:
    RETVAL

int
lastidx (code, ...)
    SV *code;
PROTOTYPE: &@
CODE:
{
    RETVAL = -1;
    ROF_EACH(if (SvTRUE(*PL_stack_sp)){RETVAL = i-1;break;})
}
OUTPUT:
    RETVAL

SV *
lastval (code, ...)
    SV *code;
PROTOTYPE: &@
CODE:
{
    RETVAL = &PL_sv_undef;
    ROF_EACH(if (SvTRUE(*PL_stack_sp)) { /* see comment in indexes() */ SvREFCNT_inc(RETVAL = args[i]); break; });
}
OUTPUT:
    RETVAL

SV *
lastres (code, ...)
    SV *code;
PROTOTYPE: &@
CODE:
{
    RETVAL = &PL_sv_undef;
    ROF_EACH(if (SvTRUE(*PL_stack_sp)) { SvREFCNT_inc(RETVAL = *PL_stack_sp); break; });
}
OUTPUT:
    RETVAL

int
insert_after (code, val, avref)
    SV *code;
    SV *val;
    SV *avref;
PROTOTYPE: &$\@
CODE:
{
    dMULTICALL;
    dMULTICALLSVCV;
    int i;
    int len;
    AV *av;

    if(!codelike(code))
       croak_xs_usage(cv,  "code, val, \\@area_of_operation");
    if(!arraylike(avref))
       croak_xs_usage(cv,  "code, val, \\@area_of_operation");

    av = (AV*)SvRV(avref);
    len = av_len(av);
    RETVAL = 0;

    PUSH_MULTICALL(mc_cv);
    SAVESPTR(GvSV(PL_defgv));

    for (i = 0; i <= len ; ++i)
    {
        GvSV(PL_defgv) = *av_fetch(av, i, FALSE);
        MULTICALL;
        if (SvTRUE(*PL_stack_sp))
        {
            RETVAL = 1;
            break;
        }
    }

    POP_MULTICALL;

    if (RETVAL)
    {
        SvREFCNT_inc(val);
        insert_after(aTHX_ i, val, av);
    }
}
OUTPUT:
    RETVAL

int
insert_after_string (string, val, avref)
    SV *string;
    SV *val;
    SV *avref;
PROTOTYPE: $$\@
CODE:
{
    int i, len;
    AV *av;
    RETVAL = 0;

    if(!arraylike(avref))
       croak_xs_usage(cv,  "string, val, \\@area_of_operation");

    av = (AV*)SvRV(avref);
    len = av_len(av);

    for (i = 0; i <= len ; i++)
    {
        SV **sv = av_fetch(av, i, FALSE);
        if((SvFLAGS(*sv) & (SVf_OK & ~SVf_ROK)) && (0 == sv_cmp_locale(string, *sv)))
        {
            RETVAL = 1;
            break;
        }
    }

    if (RETVAL)
    {
        SvREFCNT_inc(val);
        insert_after(aTHX_ i, val, av);
    }
}
OUTPUT:
    RETVAL

void
apply (code, ...)
    SV *code;
PROTOTYPE: &@
CODE:
{
    if(!codelike(code))
       croak_xs_usage(cv,  "code, ...");

    if (items > 1) {
        dMULTICALL;
        dMULTICALLSVCV;
        int i;
        SV **args = &PL_stack_base[ax];
        AV *rc = newAV();

        sv_2mortal(newRV_noinc((SV*)rc));
        av_extend(rc, items-1);

        PUSH_MULTICALL(mc_cv);
        SAVESPTR(GvSV(PL_defgv));

        for(i = 1 ; i < items ; ++i) {
            av_push(rc, newSVsv(args[i]));
            GvSV(PL_defgv) = AvARRAY(rc)[AvFILLp(rc)];
            MULTICALL;
        }
        POP_MULTICALL;

        for(i = items - 1; i > 0; --i)
        {
            ST(i-1) = sv_2mortal(AvARRAY(rc)[i-1]);
            AvARRAY(rc)[i-1] = NULL;
        }

        AvFILLp(rc) = -1;
    }

    XSRETURN(items-1);
}

void
after (code, ...)
    SV *code;
PROTOTYPE: &@
CODE:
{
    int k = items, j;
    FOR_EACH(if (SvTRUE(*PL_stack_sp)) {k=i; break;});
    for (j = k + 1; j < items; ++j)
        ST(j-k-1) = ST(j);

    j = items-k-1;
    XSRETURN(j > 0 ? j : 0);
}

void
after_incl (code, ...)
    SV *code;
PROTOTYPE: &@
CODE:
{
    int k = items, j;
    FOR_EACH(if (SvTRUE(*PL_stack_sp)) {k=i; break;});
    for (j = k; j < items; j++)
        ST(j-k) = ST(j);

    XSRETURN(items-k);
}

void
before (code, ...)
    SV *code;
PROTOTYPE: &@
CODE:
{
    int k = items - 1;
    FOR_EACH(if (SvTRUE(*PL_stack_sp)) {k=i-1; break;}; args[i-1] = args[i];);

    XSRETURN(k);
}

void
before_incl (code, ...)
    SV *code;
PROTOTYPE: &@
CODE:
{
    int k = items - 1;
    FOR_EACH(args[i-1] = args[i]; if (SvTRUE(*PL_stack_sp)) {k=i; break;});

    XSRETURN(k);
}

void
indexes (code, ...)
    SV *code;
PROTOTYPE: &@
CODE:
{
    if(!codelike(code))
       croak_xs_usage(cv,  "code, ...");

    if (items > 1) {
        dMULTICALL;
        dMULTICALLSVCV;
        int i;
        SV **args = &PL_stack_base[ax];
        AV *rc = newAV();

        sv_2mortal(newRV_noinc((SV*)rc));
        av_extend(rc, items-1);

        PUSH_MULTICALL(mc_cv);
        SAVESPTR(GvSV(PL_defgv));

        for(i = 1 ; i < items ; ++i)
        {
            GvSV(PL_defgv) = args[i];
            MULTICALL;
            if (SvTRUE(*PL_stack_sp))
                av_push(rc, newSViv(i-1));
        }
        POP_MULTICALL;

        for(i = av_len(rc); i >= 0; --i)
        {
            ST(i) = sv_2mortal(AvARRAY(rc)[i]);
            AvARRAY(rc)[i] = NULL;
        }

        i = AvFILLp(rc) + 1;
        AvFILLp(rc) = -1;

        XSRETURN(i);
    }

    XSRETURN_EMPTY;
}

void
_array_iterator (method = "")
    const char *method;
PROTOTYPE: ;$
CODE:
{
    int i;
    int exhausted = 1;

    /* 'cv' is the hidden argument with which XS_List__MoreUtils__array_iterator (this XSUB)
     * is called. The closure_arg struct is stored in this CV. */

    arrayeach_args *args = (arrayeach_args *)(CvXSUBANY(cv).any_ptr);

    if (strEQ(method, "index"))
    {
        EXTEND(SP, 1);
        ST(0) = args->curidx > 0 ? sv_2mortal(newSViv(args->curidx-1)) : &PL_sv_undef;
        XSRETURN(1);
    }

    EXTEND(SP, args->navs);

    for (i = 0; i < args->navs; i++)
    {
        AV *av = args->avs[i];
        if (args->curidx <= av_len(av))
        {
            ST(i) = sv_2mortal(newSVsv(*av_fetch(av, args->curidx, FALSE)));
            exhausted = 0;
            continue;
        }
        ST(i) = &PL_sv_undef;
    }

    if (exhausted)
        XSRETURN_EMPTY;

    args->curidx++;
    XSRETURN(args->navs);
}

SV *
each_array (...)
PROTOTYPE: \@;\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@
CODE:
{
    EACH_ARRAY_BODY;
}
OUTPUT:
    RETVAL

SV *
each_arrayref (...)
CODE:
{
    EACH_ARRAY_BODY;
}
OUTPUT:
    RETVAL

void
pairwise (code, list1, list2)
    SV *code;
    AV *list1;
    AV *list2;
PROTOTYPE: &\@\@
PPCODE:
{
    dMULTICALL;
    dMULTICALLSVCV;
    int i, maxitems;
    AV *rc = newAV();
    sv_2mortal(newRV_noinc((SV*)rc));

    if(!codelike(code))
       croak_xs_usage(cv,  "code, list, list");

    if (in_pad(aTHX_ code)) {
        croak("Can't use lexical $a or $b in pairwise code block");
    }

    /* deref AV's for convenience and
     * get maximum items */
    maxitems = MAX(av_len(list1),av_len(list2))+1;
    av_extend(rc, maxitems);

    gimme = G_ARRAY;
    PUSH_MULTICALL(mc_cv);

    if (!PL_firstgv || !PL_secondgv)
    {
        SAVESPTR(PL_firstgv);
        SAVESPTR(PL_secondgv);
        PL_firstgv = gv_fetchpv("a", TRUE, SVt_PV);
        PL_secondgv = gv_fetchpv("b", TRUE, SVt_PV);
    }

    for (i = 0; i < maxitems; ++i)
    {
        SV **j;
        SV **svp = av_fetch(list1, i, FALSE);
        GvSV(PL_firstgv) = svp ? *svp : &PL_sv_undef;
        svp = av_fetch(list2, i, FALSE);
        GvSV(PL_secondgv) = svp ? *svp : &PL_sv_undef;
        MULTICALL;

        for (j = PL_stack_base+1; j <= PL_stack_sp; ++j)
            av_push(rc, newSVsv(*j));
    }

    POP_MULTICALL;

    SPAGAIN;
    EXTEND(SP, AvFILLp(rc) + 1);

    for(i = AvFILLp(rc); i >= 0; --i)
    {
        ST(i) = sv_2mortal(AvARRAY(rc)[i]);
        AvARRAY(rc)[i] = NULL;
    }

    i = AvFILLp(rc) + 1;
    AvFILLp(rc) = -1;

    XSRETURN(i);
}

void
_natatime_iterator ()
PROTOTYPE:
CODE:
{
    int i, nret;

    /* 'cv' is the hidden argument with which XS_List__MoreUtils__array_iterator (this XSUB)
     * is called. The closure_arg struct is stored in this CV. */

    natatime_args *args = (natatime_args*)CvXSUBANY(cv).any_ptr;
    nret = args->natatime;

    EXTEND(SP, nret);

    for (i = 0; i < args->natatime; i++)
        if (args->curidx < args->nsvs)
            ST(i) = sv_2mortal(newSVsv(args->svs[args->curidx++]));
        else
            XSRETURN(i);

    XSRETURN(nret);
}

SV *
natatime (n, ...)
int n;
PROTOTYPE: $@
CODE:
{
    int i;
    natatime_args *args;
    HV *stash = gv_stashpv("List::MoreUtils::XS_na", TRUE);

    CV *closure = newXS(NULL, XS_List__MoreUtils__XS__natatime_iterator, __FILE__);

    /* must NOT set prototype on iterator:
     * otherwise one cannot write: &$it */
    /* !! sv_setpv((SV*)closure, ""); !! */

    New(0, args, 1, natatime_args);
    New(0, args->svs, items-1, SV*);
    args->nsvs = items-1;
    args->curidx = 0;
    args->natatime = n;

    for (i = 1; i < items; i++)
        SvREFCNT_inc(args->svs[i-1] = ST(i));

    CvXSUBANY(closure).any_ptr = args;
    RETVAL = newRV_noinc((SV*)closure);

    /* in order to allow proper cleanup in DESTROY-handler */
    sv_bless(RETVAL, stash);
}
OUTPUT:
    RETVAL

void
arrayify(...)
CODE:
{
    I32 i;
    AV *rc = newAV();
    AV *args = av_make(items, &PL_stack_base[ax]);
    sv_2mortal(newRV_noinc((SV *)rc));
    sv_2mortal(newRV_noinc((SV *)args));

    LMUav2flat(aTHX_ rc, args);

    i = AvFILLp(rc);
    EXTEND(SP, i+1);
    for(; i >= 0; --i)
    {
        ST(i) = sv_2mortal(AvARRAY(rc)[i]);
        AvARRAY(rc)[i] = NULL;
    }

    i = AvFILLp(rc) + 1;
    AvFILLp(rc) = -1;

    XSRETURN(i);
}

void
mesh (...)
PROTOTYPE: \@\@;\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@
CODE:
{
    int i, j, maxidx = -1;
    AV **avs;
    New(0, avs, items, AV*);

    for (i = 0; i < items; i++)
    {
        if(!arraylike(ST(i)))
           croak_xs_usage(cv,  "\\@\\@;\\@...");

        avs[i] = (AV*)SvRV(ST(i));
        if (av_len(avs[i]) > maxidx)
            maxidx = av_len(avs[i]);
    }

    EXTEND(SP, items * (maxidx + 1));
    for (i = 0; i <= maxidx; i++)
        for (j = 0; j < items; j++)
        {
            SV **svp = av_fetch(avs[j], i, FALSE);
            ST(i*items + j) = svp ? sv_2mortal(newSVsv(*svp)) : &PL_sv_undef;
        }

    Safefree(avs);
    XSRETURN(items * (maxidx + 1));
}

void
zip6 (...)
PROTOTYPE: \@\@;\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@
CODE:
{
    int i, j, maxidx = -1;
    AV **src;
    New(0, src, items, AV*);

    for (i = 0; i < items; i++)
    {
        if(!arraylike(ST(i)))
           croak_xs_usage(cv,  "\\@\\@;\\@...");

        src[i] = (AV*)SvRV(ST(i));
        if (av_len(src[i]) > maxidx)
            maxidx = av_len(src[i]);
    }

    EXTEND(SP, maxidx + 1);
    for (i = 0; i <= maxidx; i++)
    {
        AV *av;
        ST(i) = sv_2mortal(newRV_noinc((SV *)(av = newAV())));

        for (j = 0; j < items; j++)
        {
            SV **svp = av_fetch(src[j], i, FALSE);
            av_push(av, newSVsv( svp ? *svp : &PL_sv_undef ));
        }
    }

    Safefree(src);
    XSRETURN(maxidx + 1);
}

void
listcmp (...)
PROTOTYPE: \@\@;\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@\@
CODE:
{
    I32 i;
    SV *tmp = sv_newmortal();
    HV *rc = newHV();
    SV *ret = sv_2mortal (newRV_noinc((SV *)rc));
    HV *distinct = newHV();
    sv_2mortal(newRV_noinc((SV*)distinct));

    for (i = 0; i < items; i++)
    {
        AV *av;
        I32 j;

        if(!arraylike(ST(i)))
           croak_xs_usage(cv,  "\\@\\@;\\@...");
        av = (AV*)SvRV(ST(i));

        hv_clear(distinct);

        for(j = 0; j <= av_len(av); ++j)
        {
            SV **sv = av_fetch(av, j, FALSE);
            AV *store;

            if(NULL == sv)
                continue;

            SvGETMAGIC(*sv);
            if(SvOK(*sv))
            {
                SvSetSV_nosteal(tmp, *sv);
                if(hv_exists_ent(distinct, tmp, 0))
                    continue;

                hv_store_ent(distinct, tmp, &PL_sv_yes, 0);

                if(hv_exists_ent(rc, *sv, 0))
                {
                    HE *he = hv_fetch_ent(rc, *sv, 1, 0);
                    store = (AV*)SvRV(HeVAL(he));
                    av_push(store, newSViv(i));
                }
                else
                {
                    store = newAV();
                    av_push(store, newSViv(i));
                    hv_store_ent(rc, tmp, newRV_noinc((SV *)store), 0);
                }
            }
        }
    }

    i = HvUSEDKEYS(rc);
    EXTEND(SP, i * 2);

    i = 0;
    hv_iterinit(rc);
    for(;;)
    {
        HE *he = hv_iternext(rc);
        SV *key, *val;
        if(NULL == he)
            break;

        if(UNLIKELY(( NULL == (key = HeSVKEY_force(he)) ) || ( NULL == (val = HeVAL(he)) )))
            continue;

        ST(i++) = key;
        ST(i++) = val;
    }

    XSRETURN(i);
}

void
uniq (...)
PROTOTYPE: @
CODE:
{
    I32 i;
    IV count = 0, seen_undef = 0;
    HV *hv = newHV();
    SV **args = &PL_stack_base[ax];
    SV *tmp = sv_newmortal();
    sv_2mortal(newRV_noinc((SV*)hv));

    /* don't build return list in scalar context */
    if (GIMME_V == G_SCALAR)
    {
        for (i = 0; i < items; i++)
        {
            SvGETMAGIC(args[i]);
            if(SvOK(args[i]))
            {
                sv_setsv_nomg(tmp, args[i]);
                if (!hv_exists_ent(hv, tmp, 0))
                {
                    ++count;
                    hv_store_ent(hv, tmp, &PL_sv_yes, 0);
                }
            }
            else if(0 == seen_undef++)
                ++count;
        }
        ST(0) = sv_2mortal(newSVuv(count));
        XSRETURN(1);
    }

    /* list context: populate SP with mortal copies */
    for (i = 0; i < items; i++)
    {
        SvGETMAGIC(args[i]);
        if(SvOK(args[i]))
        {
            SvSetSV_nosteal(tmp, args[i]);
            if (!hv_exists_ent(hv, tmp, 0))
            {
                /*ST(count) = sv_2mortal(newSVsv(ST(i)));
                ++count;*/
                args[count++] = args[i];
                hv_store_ent(hv, tmp, &PL_sv_yes, 0);
            }
        }
        else if(0 == seen_undef++)
            args[count++] = args[i];
    }

    XSRETURN(count);
}

void
singleton (...)
PROTOTYPE: @
CODE:
{
    I32 i;
    IV cnt = 0, count = 0, seen_undef = 0;
    HV *hv = newHV();
    SV **args = &PL_stack_base[ax];
    SV *tmp = sv_newmortal();

    sv_2mortal(newRV_noinc((SV*)hv));

    COUNT_ARGS

    /* don't build return list in scalar context */
    if (GIMME_V == G_SCALAR)
    {
        for (i = 0; i < count; i++)
        {
            if(SvOK(args[i]))
            {
                HE *he;
                sv_setsv_nomg(tmp, args[i]);
                he = hv_fetch_ent(hv, tmp, 0, 0);
                if (he)
                    if( 1 == SvIVX(HeVAL(he)) )
                        ++cnt;
            }
            else if(1 == seen_undef)
                ++cnt;
        }
        ST(0) = sv_2mortal(newSViv(cnt));
        XSRETURN(1);
    }

    /* list context: populate SP with mortal copies */
    for (i = 0; i < count; i++)
    {
        if(SvOK(args[i]))
        {
            HE *he;
            SvSetSV_nosteal(tmp, args[i]);
            he = hv_fetch_ent(hv, tmp, 0, 0);
            if (he)
                if( 1 == SvIVX(HeVAL(he)) )
                    args[cnt++] = args[i];
        }
        else if(1 == seen_undef)
            args[cnt++] = args[i];
    }

    XSRETURN(cnt);
}

void
duplicates (...)
PROTOTYPE: @
CODE:
{
    I32 i;
    IV cnt = 0, count = 0, seen_undef = 0;
    HV *hv = newHV();
    SV **args = &PL_stack_base[ax];
    SV *tmp = sv_newmortal();

    sv_2mortal(newRV_noinc((SV*)hv));

    COUNT_ARGS

    /* don't build return list in scalar context */
    if (GIMME_V == G_SCALAR)
    {
        for (i = 0; i < count; i++)
        {
            if(SvOK(args[i]))
            {
                HE *he;
                sv_setsv_nomg(tmp, args[i]);
                he = hv_fetch_ent(hv, tmp, 0, 0);
                if (he)
                    if( 1 < SvIVX(HeVAL(he)) )
                        ++cnt;
            }
            else if(1 < seen_undef)
                ++cnt;
        }
        ST(0) = sv_2mortal(newSViv(cnt));
        XSRETURN(1);
    }

    /* list context: populate SP with mortal copies */
    for (i = 0; i < count; i++)
    {
        if(SvOK(args[i]))
        {
            HE *he;
            SvSetSV_nosteal(tmp, args[i]);
            he = hv_fetch_ent(hv, tmp, 0, 0);
            if (he)
                if( 1 < SvIVX(HeVAL(he)) )
                    args[cnt++] = args[i];
        }
        else if(1 < seen_undef) {
            args[cnt++] = args[i];
        }
    }

    XSRETURN(cnt);
}

void
frequency (...)
PROTOTYPE: @
CODE:
{
    I32 i;
    IV count = 0, seen_undef = 0;
    HV *hv = newHV();
    SV **args = &PL_stack_base[ax];
    SV *tmp = sv_newmortal();

    sv_2mortal(newRV_noinc((SV*)hv));

    COUNT_ARGS

    i = HvUSEDKEYS(hv);
    if(seen_undef)
        ++i;

    /* don't build return list in scalar context */
    if (GIMME_V == G_SCALAR)
    {
        ST(0) = sv_2mortal(newSViv(i));
        XSRETURN(1);
    }

    EXTEND(SP, i * 2);

    i = 0;
    hv_iterinit(hv);
    for(;;)
    {
        HE *he = hv_iternext(hv);
        SV *key, *val;
        if(NULL == he)
            break;

        if(UNLIKELY(( NULL == (key = HeSVKEY_force(he)) ) || ( NULL == (val = HeVAL(he)) )))
            continue;

        ST(i++) = key;
        ST(i++) = val;
    }

    if(seen_undef)
    {
        ST(i++) = sv_2mortal(newRV(newSVsv(&PL_sv_undef)));
        ST(i++) = sv_2mortal(newSViv(seen_undef));;
    }

    XSRETURN(i);
}

void
occurrences (...)
PROTOTYPE: @
CODE:
{
    I32 i;
    IV count = 0, seen_undef = 0, max = items > 0 ? 1 : 0;
    HV *hv = newHV();
    SV **args = &PL_stack_base[ax];
    SV *tmp = sv_newmortal();

    sv_2mortal(newRV_noinc((SV*)hv));

    COUNT_ARGS_MAX;

    /* don't build return list in scalar context */
    if (GIMME_V == G_SCALAR)
    {
        ST(0) = sv_2mortal(newSViv(i));
        XSRETURN(1);
    }

    EXTEND(SP, max + 1);
    for(i = 0; i <= max; ++i)
        ST(i) = &PL_sv_undef;

    hv_iterinit(hv);
    for(;;)
    {
        HE *he = hv_iternext(hv);
        SV *key, *val;
        AV *store;
        if(NULL == he)
            break;

        if(UNLIKELY(( NULL == (key = HeSVKEY_force(he)) ) || ( NULL == (val = HeVAL(he)) )))
            continue;

        i = SvIVX(val);
        if(ST(i) == &PL_sv_undef)
        {
            store = newAV();
            ST(i) = sv_2mortal(newRV_noinc((SV *)store));
        }
        else
            store = (AV *)SvRV(ST(i));
        av_push(store, newSVsv(key));
    }

    if(seen_undef)
    {
        AV *store;
        if(ST(seen_undef) == &PL_sv_undef)
        {
            store = newAV();
            ST(seen_undef) = sv_2mortal(newRV_noinc((SV *)store));
        }
        else
        {
            store = (AV *)SvRV(ST(seen_undef));
        }
        av_push(store, &PL_sv_undef);
    }

    XSRETURN(max+1);
}

void
mode (...)
PROTOTYPE: @
CODE:
{
    I32 i;
    IV count = 0, seen_undef = 0, max = items > 0 ? 1 : 0;
    HV *hv = newHV();
    SV **args = &PL_stack_base[ax];
    SV *tmp = sv_newmortal();

    sv_2mortal(newRV_noinc((SV*)hv));

    COUNT_ARGS_MAX;

    EXTEND(SP, count = 1);
    ST(0) = sv_2mortal(newSViv(max));

    /* don't build return list in scalar context */
    if (GIMME_V == G_SCALAR)
        XSRETURN(1);


    hv_iterinit(hv);
    for(;;)
    {
        HE *he = hv_iternext(hv);
        SV *key, *val;
        if(NULL == he)
            break;

        if(UNLIKELY(( NULL == (key = HeSVKEY_force(he)) ) || ( NULL == (val = HeVAL(he)) )))
            continue;

        i = SvIVX(val);
        if(max == i)
        {
            ++count;
            EXTEND(SP, count);
            ST(count-1) = sv_mortalcopy(key);
        }
    }

    if(seen_undef == max)
    {
        ++count;
        EXTEND(SP, count);
        ST(count-1) = &PL_sv_undef;
    }

    XSRETURN(count);
}

void
samples (k, ...)
  I32 k;
PROTOTYPE: $@
CODE:
{
    I32 i;

    if( k > (items - 1) )
        croak("Cannot get %" IVdf " samples from %" IVdf " elements", (IV)k, (IV)(items-1));

    /* Initialize Drand01 unless rand() or srand() has already been called */
    if(!PL_srand_called)
    {
#ifdef HAVE_TIME
        /* using time(NULL) as seed seems to get better random numbers ... */
        (void)seedDrand01((Rand_seed_t)time(NULL));
#else
        (void)seedDrand01((Rand_seed_t)Perl_seed(aTHX));
#endif
        PL_srand_called = TRUE;
    }

    /* optimzed Knuth-Shuffle since we move our stack one item downwards
       with each exchange */
    for (i = items ; items - i < k ; )
    {
        I32 index = items - i + 1;
        I32 swap = index + (I32)(Drand01() * (double)(--i));
        ST(index-1) = ST(swap);
        ST(swap) = ST(index);
    }

    XSRETURN(k);
}

void
minmax (...)
PROTOTYPE: @
CODE:
{
    I32 i;
    SV *minsv, *maxsv;

    if (!items)
        XSRETURN_EMPTY;

    if (items == 1)
    {
        EXTEND(SP, 1);
        ST(1) = sv_2mortal(newSVsv(ST(0)));
        XSRETURN(2);
    }

    minsv = maxsv = ST(0);

    for (i = 1; i < items; i += 2)
    {
        SV *asv = ST(i-1);
        SV *bsv = ST(i);
        int cmp = ncmp(asv, bsv);
        if (cmp < 0)
        {
            int min_cmp = ncmp(minsv, asv);
            int max_cmp = ncmp(maxsv, bsv);
            if (min_cmp > 0)
                minsv = asv;
            if (max_cmp < 0)
                maxsv = bsv;
        }
        else
        {
            int min_cmp = ncmp(minsv, bsv);
            int max_cmp = ncmp(maxsv, asv);
            if (min_cmp > 0)
                minsv = bsv;
            if (max_cmp < 0)
                maxsv = asv;
        }
    }

    if (items & 1)
    {
        SV *rsv = ST(items-1);
        if (ncmp(minsv, rsv) > 0)
            minsv = rsv;
        else if (ncmp(maxsv, rsv) < 0)
            maxsv = rsv;
    }

    ST(0) = minsv;
    ST(1) = maxsv;

    XSRETURN(2);
}

void
minmaxstr (...)
PROTOTYPE: @
CODE:
{
    I32 i;
    SV *minsv, *maxsv;

    if (!items)
        XSRETURN_EMPTY;

    if (items == 1)
    {
        EXTEND(SP, 1);
        ST(1) = sv_2mortal(newSVsv(ST(0)));
        XSRETURN(2);
    }

    minsv = maxsv = ST(0);

    for (i = 1; i < items; i += 2)
    {
        SV *asv = ST(i-1);
        SV *bsv = ST(i);
        int cmp = sv_cmp_locale(asv, bsv);
        if (cmp < 0)
        {
            int min_cmp = sv_cmp_locale(minsv, asv);
            int max_cmp = sv_cmp_locale(maxsv, bsv);
            if (min_cmp > 0)
                minsv = asv;
            if (max_cmp < 0)
                maxsv = bsv;
        }
        else
        {
            int min_cmp = sv_cmp_locale(minsv, bsv);
            int max_cmp = sv_cmp_locale(maxsv, asv);
            if (min_cmp > 0)
                minsv = bsv;
            if (max_cmp < 0)
                maxsv = asv;
        }
    }

    if (items & 1)
    {
        SV *rsv = ST(items-1);
        if (sv_cmp_locale(minsv, rsv) > 0)
            minsv = rsv;
        else if (sv_cmp_locale(maxsv, rsv) < 0)
            maxsv = rsv;
    }

    ST(0) = minsv;
    ST(1) = maxsv;

    XSRETURN(2);
}

void
part (code, ...)
    SV *code;
PROTOTYPE: &@
CODE:
{
    dMULTICALL;
    dMULTICALLSVCV;
    int i;
    SV **args = &PL_stack_base[ax];
    AV *tmp = newAV();
    sv_2mortal(newRV_noinc((SV*)tmp));

    if(!codelike(code))
       croak_xs_usage(cv,  "code, ...");

    if (items == 1)
        XSRETURN_EMPTY;

    PUSH_MULTICALL(mc_cv);
    SAVESPTR(GvSV(PL_defgv));

    for(i = 1 ; i < items ; ++i)
    {
        IV idx;
        SV **inner;
        AV *av;

        GvSV(PL_defgv) = args[i];
        MULTICALL;
        idx = SvIV(*PL_stack_sp);

        if (UNLIKELY(idx < 0 && (idx += (AvFILLp(tmp)+1)) < 0))
            croak("Modification of non-creatable array value attempted, subscript %" IVdf, idx);

        if(UNLIKELY(NULL == (inner = av_fetch(tmp, idx, FALSE))))
        {
            av = newAV();
            av_push(av, newSVsv(args[i]));
            av_store(tmp, idx, newRV_noinc((SV *)av));
        }
        else
        {
            av = (AV*)SvRV(*inner);
            av_push(av, newSVsv(args[i]));
        }
    }
    POP_MULTICALL;

    EXTEND(SP, AvFILLp(tmp)+1);
    for(i = AvFILLp(tmp); i >= 0; --i)
    {
        SV *v = AvARRAY(tmp)[i];
        ST(i) = v && is_array(v) ? sv_2mortal(v) : &PL_sv_undef;
        AvARRAY(tmp)[i] = NULL;
    }

    i = AvFILLp(tmp) + 1;
    AvFILLp(tmp) = -1;

    XSRETURN(i);
}

void
bsearch (code, ...)
    SV *code;
PROTOTYPE: &@
CODE:
{
    I32 ret_gimme = GIMME_V;
    if(!codelike(code))
       croak_xs_usage(cv,  "code, ...");

    if (items > 1)
    {
        dMULTICALL;
        dMULTICALLSVCV;
        ssize_t count = items - 1, first = 1;
        int cmprc = -1;
        SV **args = &PL_stack_base[ax];

        PUSH_MULTICALL(mc_cv);
        SAVESPTR(GvSV(PL_defgv));

        LOWER_BOUND_QUICK(args[it])

        if(cmprc < 0 && first < items)
        {
            GvSV(PL_defgv) = args[first];
            MULTICALL;
            cmprc = SvIV(*PL_stack_sp);
        }

        POP_MULTICALL;

        if(0 == cmprc)
        {
            if (ret_gimme != G_ARRAY)
                XSRETURN_YES;
            ST(0) = args[first];
            XSRETURN(1);
        }
    }

    if(ret_gimme == G_ARRAY)
        XSRETURN_EMPTY;
    XSRETURN_UNDEF;
}

int
bsearchidx (code, ...)
    SV *code;
PROTOTYPE: &@
CODE:
{
    I32 ret_gimme = GIMME_V;
    if(!codelike(code))
       croak_xs_usage(cv,  "code, ...");

    RETVAL = -1;
    if (items > 1)
    {
        dMULTICALL;
        dMULTICALLSVCV;
        ssize_t count = items - 1, first = 1;
        int cmprc = -1;
        SV **args = &PL_stack_base[ax];

        PUSH_MULTICALL(mc_cv);
        SAVESPTR(GvSV(PL_defgv));

        LOWER_BOUND_QUICK(args[it])

        if(cmprc < 0 && first < items)
        {
            GvSV(PL_defgv) = args[first];
            MULTICALL;
            cmprc = SvIV(*PL_stack_sp);
        }

        POP_MULTICALL;

        if(0 == cmprc)
            RETVAL = --first;
    }
}
OUTPUT:
    RETVAL

int
lower_bound (code, ...)
    SV *code;
PROTOTYPE: &@
CODE:
{
    if(!codelike(code))
       croak_xs_usage(cv,  "code, ...");

    if (items > 1)
    {
        dMULTICALL;
        dMULTICALLSVCV;
        ssize_t count = items - 1, first = 1;
        int cmprc = -1;
        SV **args = &PL_stack_base[ax];

        PUSH_MULTICALL(mc_cv);
        SAVESPTR(GvSV(PL_defgv));

        LOWER_BOUND(args[it])

        POP_MULTICALL;

        RETVAL = --first;
    }
    else
        RETVAL = -1;
}
OUTPUT:
    RETVAL

int
upper_bound (code, ...)
    SV *code;
PROTOTYPE: &@
CODE:
{
    if(!codelike(code))
       croak_xs_usage(cv,  "code, ...");

    if (items > 1)
    {
        dMULTICALL;
        dMULTICALLSVCV;
        ssize_t count = items - 1, first = 1;
        int cmprc = -1;
        SV **args = &PL_stack_base[ax];

        PUSH_MULTICALL(mc_cv);
        SAVESPTR(GvSV(PL_defgv));

        UPPER_BOUND(args[it])

        POP_MULTICALL;

        RETVAL = --first;
    }
    else
        RETVAL = -1;
}
OUTPUT:
    RETVAL

void
equal_range (code, ...)
    SV *code;
PROTOTYPE: &@
CODE:
{
    if(!codelike(code))
       croak_xs_usage(cv,  "code, ...");

    if (items > 1)
    {
        dMULTICALL;
        dMULTICALLSVCV;
        ssize_t count = items - 1, first = 1;
        ssize_t lb;
        int cmprc = -1;
        SV **args = &PL_stack_base[ax];

        PUSH_MULTICALL(mc_cv);
        SAVESPTR(GvSV(PL_defgv));

        LOWER_BOUND(args[it])
        lb = first - 1;

        count = items - first;
        UPPER_BOUND(args[it])

        POP_MULTICALL;

        EXTEND(SP, 2);
        ST(0) = sv_2mortal(newSViv(lb));
        ST(1) = sv_2mortal(newSViv(first - 1));
        XSRETURN(2);
    }

    XSRETURN_EMPTY;
}

int
binsert(code, item, list)
    SV *code;
    SV *item;
    AV *list;
PROTOTYPE: &$\@
CODE:
{
    if(!codelike(code))
       croak_xs_usage(cv,  "code, val, list");

    RETVAL = -1;

    if (AvFILLp(list) == -1)
    {
        av_push(list, newSVsv(item));
        RETVAL = 0;
    }
    else if (AvFILLp(list) >= 0)
    {
        dMULTICALL;
        dMULTICALLSVCV;
        ssize_t count = AvFILLp(list) + 1, first = 0;
        int cmprc = -1;
        SV **btree = AvARRAY(list);

        PUSH_MULTICALL(mc_cv);
        SAVESPTR(GvSV(PL_defgv));

        LOWER_BOUND(btree[it])

        POP_MULTICALL;

        SvREFCNT_inc(item);
        insert_after(aTHX_ (RETVAL = first) - 1, item, list);
    }
}
OUTPUT:
    RETVAL

void
bremove(code, list)
    SV *code;
    AV *list;
PROTOTYPE: &\@
CODE:
{
    I32 ret_gimme = GIMME_V;
    if(!codelike(code))
       croak_xs_usage(cv,  "code, ...");

    if (AvFILLp(list) >= 0)
    {
        dMULTICALL;
        dMULTICALLSVCV;
        ssize_t count = AvFILLp(list) + 1, first = 0;
        int cmprc = -1;
        SV **btree = AvARRAY(list);

        PUSH_MULTICALL(mc_cv);
        SAVESPTR(GvSV(PL_defgv));

        LOWER_BOUND_QUICK(btree[it])

        if(cmprc < 0 && first < items)
        {
            GvSV(PL_defgv) = btree[first];
            MULTICALL;
            cmprc = SvIV(*PL_stack_sp);
        }

        POP_MULTICALL;

        if(0 == cmprc)
        {
            if(AvFILLp(list) == first)
            {
                ST(0) = sv_2mortal(av_pop(list));
                XSRETURN(1);
            }

            if(0 == first)
            {
                ST(0) = sv_2mortal(av_shift(list));
                XSRETURN(1);
            }

            ST(0) = av_delete(list, first, 0);
            count = AvFILLp(list);
            while(first < count)
            {
                btree[first] = btree[first+1];
                ++first;
            }
            SvREFCNT_inc(btree[count]);
            av_delete(list, count, G_DISCARD);
#if PERL_VERSION_LE(5,8,5)
            sv_2mortal(ST(0));
#endif
            XSRETURN(1);
        }
    }

    if (ret_gimme == G_ARRAY)
        XSRETURN_EMPTY;
    else
        XSRETURN_UNDEF;
}

void
qsort(code, list)
    SV *code;
    AV *list;
PROTOTYPE: &\@
CODE:
{
    I32 gimme = GIMME_V; /* perl-5.5.4 bus-errors out later when using GIMME
                            therefore we save its value in a fresh variable */
    dMULTICALL;

    if(!codelike(code))
       croak_xs_usage(cv,  "code, ...");

    if (in_pad(aTHX_ code))
        croak("Can't use lexical $a or $b in qsort's cmp code block");
    
    if (av_len(list) > 0)
    {
        HV *stash;
        GV *gv;
        CV *_cv = sv_2cv(code, &stash, &gv, 0);

        PUSH_MULTICALL(_cv);

        SAVEGENERICSV(PL_firstgv);
        SAVEGENERICSV(PL_secondgv);
        PL_firstgv = MUTABLE_GV(SvREFCNT_inc(
            gv_fetchpvs("a", GV_ADD|GV_NOTQUAL, SVt_PV)
        ));
        PL_secondgv = MUTABLE_GV(SvREFCNT_inc(
            gv_fetchpvs("b", GV_ADD|GV_NOTQUAL, SVt_PV)
        ));
        /* make sure the GP isn't removed out from under us for
         * the SAVESPTR() */
        save_gp(PL_firstgv, 0);
        save_gp(PL_secondgv, 0);
        /* we don't want modifications localized */
        GvINTRO_off(PL_firstgv);
        GvINTRO_off(PL_secondgv);
        SAVESPTR(GvSV(PL_firstgv));
        SAVESPTR(GvSV(PL_secondgv));

        bsd_qsort_r(aTHX_ AvARRAY(list), av_len(list) + 1, multicall_cop);
        POP_MULTICALL;
    }
}

void
_XScompiled ()
    CODE:
       XSRETURN_YES;
