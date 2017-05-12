/* -*- Mode: XS -*- */

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include <gmp.h>

static void
my_neg(mp_limb_t *rp, mp_limb_t *s1p, mp_size_t s1n) {
    mp_size_t i;
    for (i = 0; i < s1n; i++) rp[i] = ~s1p[i];
    mpn_add_1(rp, rp, s1n, 1);
}

static void
my_addmul(mp_limb_t *rp, mp_limb_t *s1p, mp_size_t s1n, mp_limb_t *s2p, mp_size_t s2n) {
    if (s1n && s2n) {
        mp_size_t i = s2n;
        while (i--)
            mpn_addmul_1(rp + i, s1p, s1n - i, s2p[i]);
    }
}

static void
my_submul(mp_limb_t *rp, mp_limb_t *s1p, mp_size_t s1n, mp_limb_t *s2p, mp_size_t s2n) {
    if (s1n && s2n) {
        mp_size_t i = s2n;
        while (i--)
            mpn_submul_1(rp + i, s1p, s1n - i, s2p[i]);
    }
}

static void
my_mul(mp_limb_t *rp, mp_limb_t *s1p, mp_size_t s1n, mp_limb_t *s2p, mp_size_t s2n) {
    if (s1n && s2n) {
        mp_size_t i = s2n;
        mpn_mul_1(rp, s1p, s1n, *s2p);
        while (--i)
            mpn_addmul_1(rp + i, s1p, s1n - i, s2p[i]);
    }
    else
        while (s1n--) rp[s1n] = 0;
}

static void
my_sqr(mp_limb_t *rp, mp_limb_t *s1p, mp_size_t s1n) {
    if (s1n) {
        mp_size_t i = s1n;
        mpn_mul_1(rp, s1p, s1n, *s1p);
        while (--i)
            mpn_addmul_1(rp + i, s1p, s1n - i, s1p[i]);
    }
}

static void
my_set_bitlen(pTHX_ SV *sv, int bitlen, int sign_extend) {
    STRLEN len;
    mp_size_t n;
    n = bitlen / GMP_NUMB_BITS;
    if (n * GMP_NUMB_BITS != bitlen)
        Perl_croak(aTHX_ "invalid bit length %d, on this machine a multiple of %d is required",
                   bitlen, GMP_NUMB_BITS);
    len = n * sizeof(mp_limb_t);
    if (!SvPOK(sv) || (len > SvCUR(sv))) {
        mp_limb_t *p;
        mp_size_t i;
        SvUPGRADE(sv, SVt_PV);
        SvPOK_on(sv);
        i = SvCUR(sv) / sizeof(mp_limb_t);
        p = (mp_limb_t*)SvGROW(sv, len);
        if (sign_extend && i && (p[i - 1] & (((mp_limb_t)1)<< (GMP_NUMB_BITS -1))))
            for (; i < n; i++) p[i] = ~0;  
        else
            for (; i < n; i++) p[i] = 0;  

    }
    SvCUR_set(sv, len);
}

#define CHECK_OUTPUT(r) (SvTHINKFIRST(r) ? Perl_croak(aTHX_ "read only scalar used as output argument") : 0)

#define ALIGNEDP(spi) (((spi) & (sizeof(mp_limb_t) - 1)) ? Perl_croak(aTHX_ "some argument is unaligned") : 0)
#define ALIGNED1(a) (ALIGNEDP((IV)a ## p))
#define ALIGNED2(a, b) (ALIGNEDP(((IV)a ## p) | ((IV)b ## p)))
#define ALIGNED3(a, b, c) (ALIGNEDP(((IV)a ## p) | ((IV)b ## p) | ((IV)c ## p)))

static mp_limb_t *prepare_output(pTHX_ SV *r, STRLEN l) {
    mp_limb_t *rp;
    CHECK_OUTPUT(r);
    SvUPGRADE(r, SVt_PV);
    rp = (mp_limb_t*)SvGROW(r, (l ? l : 1));
    SvCUR_set(r, l);
    SvPOK_on(r);
    return rp;
}

#define PREPARE_OUTPUT(r, l) ((((SvFLAGS(r) & (SVf_THINKFIRST | SVf_POK)) == SVf_POK) && l == SvCUR(r)) ? (mp_limb_t *)SvPV_nolen(r) : prepare_output(aTHX_ r, l))

#define ARG(sv) ((sv ## p = (mp_limb_t*)SvPV_nolen(sv)), (sv ## l = SvCUR(sv)))
#define OUTPUT(sv, len) (sv ## p = PREPARE_OUTPUT(sv, (len)))
#define CHECK(r, s) (s ## p = (r == s ? r ## p : s ## p))
#define OUTPUT_AND_CHECK(r, len, s) (OUTPUT(r, len), CHECK(r, s))
#define N(sv) (sv ## l / sizeof(mp_limb_t))

MODULE = Math::GMPn		PACKAGE = Math::GMPn		

int
GMP_LIMB_BYTES()
CODE:
    RETVAL = sizeof(mp_limb_t);
OUTPUT:
    RETVAL

int
GMP_LIMB_BITS()
CODE:
    RETVAL = GMP_NUMB_BITS;
OUTPUT:
    RETVAL

void
mpn_neg(r, s1)
    SV *r
    SV *s1
PREINIT:
    mp_limb_t *s1p, *rp;
    STRLEN s1l;
    mp_size_t s1n, i;
CODE:
    ARG(s1);
    OUTPUT_AND_CHECK(r, s1l, s1);
    ALIGNED2(r, s1);
    my_neg(rp, s1p, N(s1));

void
mpn_not(r, s1)
    SV *r
    SV *s1
PREINIT:
    mp_limb_t *s1p, *rp;
    STRLEN s1l;
    mp_size_t i;
CODE:
    ARG(s1);
    OUTPUT_AND_CHECK(r, s1l, s1);
    ALIGNED2(r, s1);
    for (i = N(s1); i--;) rp[i] = ~s1p[i];

void
mpn_add(r, s1, s2)
    SV *r
    SV *s1
    SV *s2
PREINIT:
    mp_limb_t *s1p, *s2p, *rp;
    STRLEN s1l, s2l, rl;
CODE:
    ARG(s1);
    ARG(s2);
    if (s1l < s2l) {
        OUTPUT_AND_CHECK(r, s2l, s1);
        ALIGNED3(s1, s2, r);
        mpn_add(rp, s2p, N(s2), s1p, N(s1));
    }
    else {
        OUTPUT_AND_CHECK(r, s1l, s2);
        ALIGNED3(r, s1, s2);
        mpn_add(rp, s1p, N(s1), s2p, N(s2));
    }

void
mpn_add_uint(r, s1, s2)
    SV *r;
    SV *s1;
    UV s2;
PREINIT:
    mp_limb_t *s1p, *rp;
    STRLEN s1l;
CODE:
    ARG(s1);
    OUTPUT(r, s1l);
    ALIGNED2(r, s1);
    mpn_add_1(rp, s1p, N(s1), s2);

void
mpn_sub_uint(r, s1, s2)
    SV *r
    SV *s1
    UV s2
PREINIT:
    mp_limb_t *s1p, *rp;
    STRLEN s1l;
CODE:
    ARG(s1);
    OUTPUT(r, s1l);
    ALIGNED2(r, s1);
    mpn_sub_1(rp, s1p, N(s1), s2);

UV
mpn_mod_uint(s1, s2)
    SV *s1
    UV s2
PREINIT:
    mp_limb_t *s1p, *rp;
    STRLEN s1l;
CODE:
    ARG(s1);
    ALIGNED1(s1);
    RETVAL = mpn_mod_1(s1p, N(s1), s2);
OUTPUT:
    RETVAL

void
mpn_lshift(r, s1, s2)
    SV *r
    SV *s1
    UV s2
PREINIT:
    mp_limb_t *s1p, *rp;
    STRLEN s1l;
    mp_size_t s2off;
CODE:
    ARG(s1);
    OUTPUT(r, s1l);
    s2off = s2 / GMP_NUMB_BITS;
    ALIGNED2(r, s1);
    if (s2off) {
        mp_size_t i = N(s1);
        if (s2off >= i)
            while (i--) rp[i] = 0;
        else {
            while(i > s2off) {
                --i;
                rp[i] = rp[i - s2off];
            }
            mpn_lshift(rp + i, rp + i, N(s1) - i, s2 - i * GMP_NUMB_BITS);
            while (i--) rp[i] = 0;
        }
    }
    else
        mpn_lshift(rp, s1p, N(s1), s2);

void
mpn_rshift(r, s1, s2)
    SV *r
    SV *s1
    UV s2
PREINIT:
    mp_limb_t *s1p, *rp;
    STRLEN s1l;
    mp_size_t s2off;
CODE:
    ARG(s1);
    OUTPUT(r, s1l);
    s2off = s2 / GMP_NUMB_BITS;
    ALIGNED2(r, s1);
    if (s2off) {
        mp_size_t s1n = N(s1), i;
        if (s2off >= i)
            while (i--) rp[i] = 0;
        else {
            for (i = s2off; i < s1n; i++) rp[i - s2off] = rp[i];
            mpn_rshift(rp, rp, s1n - s2off, s2 - s2off * GMP_NUMB_BITS);
            for (i = s1n - s2off; i < s1n; i++) rp[i] = 0;
        }
    }
    else
        mpn_rshift(rp, s1p, N(s1), s2);

void
mpn_ior(r, s1, s2)
    SV *r
    SV *s1
    SV *s2
ALIAS:
    mpn_xor  = 1
    mpn_and  = 2
    mpn_andn = 3
    mpn_iorn = 4
    mpn_nand = 5
    mpn_nior = 6
    mpn_xnor = 7
PREINIT:
    mp_limb_t *s1p, *s2p, *rp;
    STRLEN s1l, s2l, rl;
    mp_size_t i, s1n, s2n;
CODE:
    ARG(s1);
    ARG(s2);
    s1n = N(s1);
    s2n = N(s2);
    if (s1l < s2l) {
        OUTPUT_AND_CHECK(r, s2l, s1);
        ALIGNED3(r, s1, s2);
        switch(ix) {
        case 0:
            for (i = 0; i < s1n; i++) rp[i] = s1p[i] | s2p[i];
            for (; i < s2n; i++) rp[i] = s2p[i];
            break;
        case 1:
            for (i = 0; i < s1n; i++) rp[i] = s1p[i] ^ s2p[i];
            for (; i < s2n; i++) rp[i] = s2p[i];
            break;
        case 2:
            for (i = 0; i < s1n; i++) rp[i] = s1p[i] & s2p[i];
            for (; i < s2n; i++) rp[i] = 0;
            break;
        case 3:
            for (i = 0; i < s1n; i++) rp[i] = s1p[i] & ~s2p[i];
            for (; i < s2n; i++) rp[i] = 0;
            break;
        case 4:
            for (i = 0; i < s1n; i++) rp[i] = s1p[i] | ~s2p[i];
            for (; i < s2n; i++) rp[i] = ~s2p[i];
            break;
        case 5:
            for (i = 0; i < s1n; i++) rp[i] = ~(s1p[i] & s2p[i]);
            for (; i < s2n; i++) rp[i] = ~(mp_limb_t)0;
            break;
        case 6:
            for (i = 0; i < s1n; i++) rp[i] = ~(s1p[i] & s2p[i]);
            for (; i < s2n; i++) rp[i] = ~s2p[i];
            break;
        case 7:
            for (i = 0; i < s1n; i++) rp[i] = ~(s1p[i] ^ s2p[i]);
            for (; i < s2n; i++) rp[i] = ~s2p[i];
            break;
        default:
            Perl_croak(aTHX_ "Internal error: bad ix %d", ix);
        }

    }
    else {
        OUTPUT_AND_CHECK(r, s1l, s2);
        ALIGNED3(r, s1, s2);
        switch(ix) {
        case 0:
            for (i = 0; i < s2n; i++) rp[i] = s1p[i] | s2p[i];
            for (; i < s1n; i++) rp[i] = s1p[i];
           break;
        case 1:
            for (i = 0; i < s2n; i++) rp[i] = s1p[i] ^ s2p[i];
            for (; i < s1n; i++) rp[i] = s1p[i];
            break;
        case 2:
            for (i = 0; i < s2n; i++) rp[i] = s1p[i] & s2p[i];
            for (; i < s1n; i++) rp[i] = 0;
            break;
        case 3:
            for (i = 0; i < s2n; i++) rp[i] = s1p[i] & ~s2p[i];
            for (; i < s1n; i++) rp[i] = 0;
            break;
        case 4:
            for (i = 0; i < s2n; i++) rp[i] = s1p[i] | ~s2p[i];
            for (; i < s1n; i++) rp[i] = s1p[i];
            break;
        case 5:
            for (i = 0; i < s2n; i++) rp[i] = ~(s1p[i] & s2p[i]);
            for (; i < s1n; i++) rp[i] = ~(mp_limb_t)0;
            break;
        case 6:
            for (i = 0; i < s2n; i++) rp[i] = ~(s1p[i] & s2p[i]);
            for (; i < s1n; i++) rp[i] = ~s1p[i];
            break;
        case 7:
            for (i = 0; i < s2n; i++) rp[i] = ~(s1p[i] ^ s2p[i]);
            for (; i < s1n; i++) rp[i] = ~s1p[i];
            break;
        default:
            Perl_croak(aTHX_ "Internal error: bad ix %d", ix);
        }
    }

void
mpn_sub(r, s1, s2)
    SV *r
    SV *s1
    SV *s2
PREINIT:
    mp_limb_t *s1p, *s2p, *rp;
    STRLEN s1l, s2l;
CODE:
    ARG(s1);
    ARG(s2);
    if (s1l < s2l) {
        OUTPUT_AND_CHECK(r, s2l, s1);
        ALIGNED3(r, s1, s2);
        mpn_sub(rp, s2p, N(s2), s1p, N(s1));
        my_neg(rp, rp, N(s2));
    }
    else {
        OUTPUT_AND_CHECK(r, s1l, s2);
        ALIGNED3(r, s1, s2);
        mpn_sub(rp, s1p, N(s1), s2p, N(s2));
    }

void
mpn_mul_ext(r, s1, s2)
    SV *r
    SV *s1       
    SV *s2
PREINIT:
    mp_limb_t *s1p, *s2p, *rp;
    STRLEN s1l, s2l;
CODE:
    if ((r == s1) || (r == s2))
        Perl_croak(aTHX_ "mpn_emul arguments must not overlap");
    ARG(s1);
    ARG(s2);
    OUTPUT(r, s1l + s2l);
    ALIGNED3(r, s1, s2);
    if (s1l < s2l)
        mpn_mul(rp, s2p, N(s2), s1p, N(s1));
    else 
        mpn_mul(rp, s1p, N(s1), s2p, N(s2));

void
mpn_mul(r, s1, s2)
    SV *r
    SV *s1       
    SV *s2
PREINIT:
    mp_limb_t *s1p, *s2p, *rp;
    STRLEN s1l, s2l;
CODE:
    if ((r == s1) || (r == s2))
        Perl_croak(aTHX_ "mpn_mul arguments must not overlap");
    ARG(s1);
    ARG(s2);
    if (s1l < s2l) {
        OUTPUT(r, s2l);
        ALIGNED3(r, s1, s2);
        my_mul(rp, s2p, N(s2), s1p, N(s1));
    }
    else {
        OUTPUT(r, s1l);
        ALIGNED3(r, s1, s2);
        my_mul(rp, s1p, N(s1), s2p, N(s2));
    }
 
void
mpn_mul_uint(r, s1, s2)
    SV *r
    SV *s1
    UV s2
PREINIT:
    mp_limb_t *s1p, *rp;
    STRLEN s1l;
CODE:
    if (r == s1)
        Perl_croak(aTHX_ "mpn_mul_uint arguments must not overlap");
    ARG(s1);
    OUTPUT(r, s1l);
    ALIGNED2(r, s1);
    mpn_mul_1(rp, s1p, N(s1), s2);
       
void
mpn_addmul(r, s1, s2)
    SV *r
    SV *s1
    SV *s2
ALIAS:
    mpn_submul = 1
PREINIT:
    mp_limb_t *s1p, *s2p, *rp;
    STRLEN s1l, s2l, rl;
    mp_size_t i;
CODE:
    if ((r == s1) || (r == s2))
        Perl_croak(aTHX_ "mpn_addmul arguments must not overlap");
    ARG(r);
    ARG(s1);
    ARG(s2);
    if (s1l < s2l) {
        OUTPUT(r, s2l);
        ALIGNED3(r, s1, s2);
        if (rl < s2l) for (i = N(r); i < N(s2); i++) rp[i] = 0;
        if (ix)
            my_submul(rp, s2p, N(s2), s1p, N(s1));
        else
            my_addmul(rp, s2p, N(s2), s1p, N(s1));
    }
    else {
        OUTPUT(r, s1l);
        ALIGNED3(r, s1, s2);
        if (rl < s1l) for (i = N(r); i < N(s1); i++) rp[i] = 0;
        if (ix)
            my_addmul(rp, s1p, N(s1), s2p, N(s2));
        else
            my_submul(rp, s1p, N(s1), s2p, N(s2));
    }

void
mpn_addmul_uint(r, s1, s2)
    SV *r
    SV *s1
    UV s2
PREINIT:
    mp_limb_t *s1p, *rp;
    STRLEN s1l, rl;
    mp_size_t i;
CODE:
    if (r == s1)
        Perl_croak(aTHX_ "mpn_mul_uint arguments must not overlap");
    ARG(r);
    ARG(s1);
    OUTPUT(r, s1l);
    ALIGNED2(r, s1);
    if (rl < s1l) for (i = N(r); i < N(s1); i++) rp[i] = 0;
    mpn_addmul_1(rp, s1p, N(s1), s2);

void
mpn_sqr_ext(r, s1)
    SV *r
    SV *s1
PREINIT:
    mp_limb_t *s1p, *rp;
    STRLEN s1l;
CODE:
    if (r == s1)
        Perl_croak(aTHX_ "mpn_esqr arguments must not overlap");
    ARG(s1);
    OUTPUT(r, s1l * 2);
    ALIGNED2(r, s1);
    mpn_sqr(rp, s1p, N(s1));

void
mpn_sqr(r, s1)
    SV *r
    SV *s1
PREINIT:
    mp_limb_t *s1p, *rp;
    STRLEN s1l, s1l2, rl;
CODE:
    if (r == s1)
        Perl_croak(aTHX_ "mpn_esqr arguments must not overlap");
    ARG(s1);
    OUTPUT(r, s1l);
    ALIGNED2(r, s1);
    my_sqr(rp, s1p, N(s1));

void
mpn_divrem(q, r, n, d)
    SV *q
    SV *r
    SV *n
    SV *d
PREINIT:
    mp_limb_t *np, *dp, *qp, *rp;
    STRLEN nl, dl, ql;
    mp_size_t dn, nn;
CODE:
    if ((q == n) || (q == d) || (r == n) || (r == d))
        Perl_croak(aTHX_ "mpn_divrem arguments must not overlap");
    ARG(n);
    nn = nl / sizeof(mp_limb_t);
    ARG(d);
    dn = dl / sizeof(mp_limb_t);
    ql = (nl > dl ? nl : dl);
    OUTPUT(q, ql);
    ALIGNED3(q, n, d);
    while(1) {
        if (dn == 0)
            Perl_croak(aTHX_ "division by zero");
        if (dp[dn - 1]) break;
        dn--;
    }
    if (dn > nn) {
        sv_setpvn(r, (char*)np, nl);
        Zero(qp, ql, char);
    }
    else {
        mp_size_t i, qn = ql / sizeof(mp_limb_t);
        OUTPUT(r, dl);
        ALIGNED1(r);
        mpn_tdiv_qr(qp, rp, 0, np, nn, dp, dn);
        for (i = nn - dn + 1; i < qn; i++)
            qp[i] = 0;
    }

void
mpn_sqrtrem(r1, r2, s1)
    SV *r1;
    SV *r2;
    SV *s1;
PREINIT:
    mp_limb_t *r1p, *r2p, *s1p;
    STRLEN s1l;
    mp_size_t r2n, s1n, rn, i;
CODE:
    if ((r1 == r2) || (r1 == s1) || (r2 == s1))
        Perl_croak(aTHX_ "mpn_sqrtrem arguments must not overlap");
    ARG(s1);
    rn = s1n = N(s1);
    OUTPUT(r1, s1l);
    OUTPUT(r2, s1l);
    ALIGNED3(r1, r2, s1);
    while (s1n && (s1p[s1n - 1] == 0)) s1n--;
    if (s1n) {
        r2n = mpn_sqrtrem(r1p, r2p, s1p, s1n);
        for (i = (s1n + 1) / 2; i < rn; i++) r1p[i] = 0;
        for (i = r2n; i < rn; i++) r2p[i] = 0;
    }
    else
        while (rn--) r1p[rn] = r2p[rn] = 0;

void
mpn_divexact_by3(r, s1)
    SV *r;
    SV *s1;
PREINIT:
    mp_limb_t *rp, *s1p;
    STRLEN s1l;
CODE:
    if (r == s1)
        Perl_croak(aTHX_ "mpn_divexact_by3 arguments must not overlap");
    ARG(s1);
    OUTPUT(r, s1l);
    ALIGNED2(r, s1);
    if (!mpn_divexact_by3(rp, s1p, N(s1)))
        Perl_croak(aTHX_ "mpn_divexact_by3 requires s1 to be a multiple of 3");

void
mpn_ior_uint(r, s1, s2)
    SV *r
    SV *s1
    UV s2
ALIAS:
    mpn_xor_uint  = 1
    mpn_and_uint  = 2
    mpn_andn_uint = 3
    mpn_iorn_uint = 4
    mpn_nand_uint = 5
    mpn_nior_uint = 6
    mpn_xnor_uint = 7
PREINIT:
    mp_limb_t *rp, *s1p;
    STRLEN s1l;
    mp_limb_t s1n;
CODE:
    ARG(s1);
    s1n = N(s1);
    if (s1n) {
        OUTPUT(r, s1l);
        ALIGNED2(r, s1);
        switch (ix) {
        case 0:
            rp[0] = s1p[0] | s2;
            if (r != s1) while (--s1n) rp[s1n] = s1p[s1n];
            break;
        case 1:
            rp[0] = s1p[0] ^ s2;
            if (r != s1) while (--s1n) rp[s1n] = s1p[s1n];
            break;
        case 2:
            rp[0] = s1p[0] & s2;
            while (--s1n) rp[s1n] = 0;
            break;
        case 3:
            rp[0] = s1p[0] & ~s2;
            while (--s1n) rp[s1n] = 0;
            break;
        case 4:
            rp[0] = s1p[0] | ~s2;
            if (r != s1) while (--s1n) rp[s1n] = s1p[s1n];
            break;
        case 5:
            rp[0] = ~(s1p[0] & s2);
            while (--s1n) rp[s1n] = ~(mp_limb_t)0;
            break;
        case 6:
            rp[0] = ~(s1p[0] | s2);
            while (--s1n) rp[s1n] = ~s1p[s1n];
            break;
        case 7:
            rp[0] = ~(s1p[0] ^ s2);
            while (--s1n) rp[s1n] = ~s1p[s1n];
            break;
        default:
            Perl_croak(aTHX_ "Internal error: bad ix %d", ix);
        }
    }
    else {
        OUTPUT(r, sizeof(mp_limb_t));
        ALIGNED1(r);
        switch (ix) {
        case 0:
        case 1:
            rp[0] = s2;
            break;
        case 2:
        case 3:
            rp[0] = 0;
            break;
        case 4:
        case 6:
        case 7:
            rp[0] = ~s2;
            break;
        case 5:
            rp[0] = ~(mp_limb_t)0;
            break;
        default:
            Perl_croak(aTHX_ "Internal error: bad ix %d", ix);
        }
    }

int
mpn_cmp(s1, s2)
    SV *s1
    SV *s2
PREINIT:
    mp_limb_t *s1p, *s2p;
    STRLEN s1l, s2l;
    mp_size_t s1n, s2n;
CODE:
    ARG(s1);
    ARG(s2);
    ALIGNED2(s1, s2);
    s1n = N(s1);
    s2n = N(s2);
    if (s1n < s2n) {
        while (s2n-- > s1n)
            if (s2p[s2n]) {
                RETVAL = -1;
                goto end;
            }
        RETVAL = mpn_cmp(s1p, s2p, s1n);
    }
    else {
        while (s1n-- > s2n)
            if (s1p[s1n]) {
                RETVAL = 1;
                goto end;
            }
        RETVAL = mpn_cmp(s1p, s2p, s2n);
    }
  end:
    ;
OUTPUT:
    RETVAL

UV
mpn_gcd_uint(s1, s2)
    SV *s1
    UV s2
PREINIT:
    mp_limb_t *s1p;
    STRLEN s1l;
    mp_size_t s1n;
CODE:
    ARG(s1);
    ALIGNED1(s1);
    s1n = N(s1);
    while (s1n) {
        if (s1p[s1n - 1]) break;
        s1n--;
    }
    if (s1n && s2)
        RETVAL = mpn_gcd_1(s1p, s1n, s2);
    else
        Perl_croak(aTHX_ "division by zero error");

void
mpn_gcd_dest(r, s1, s2)
    SV *r;
    SV *s1;
    SV *s2;
PREINIT:
    mp_limb_t *rp, *s1p, *s2p;
    STRLEN s1l, s2l, rl;
    mp_size_t s1n, s2n, rn, rn1;
CODE:
    if ((s1 == r) || (s2 == r) || (s1 == s2))
        Perl_croak(aTHX_ "mpn_gcd_dest arguments must not overlap");
    ARG(s1);
    ARG(s2);
    s1n = N(s1);
    s2n = N(s2);
    rn = (s1n >= s2n ? s1n : s2n);
    rl = rn / sizeof(mp_limb_t);
    OUTPUT(r, rl);
    OUTPUT(s1, rl);
    OUTPUT(s2, rl);
    ALIGNED3(r, s1, s2);
    while (s1n) {
        if (s1p[s1n - 1]) break;
        s1n--;
    }
    while (s2n) {
        if (s2p[s2n - 1]) break;
        s2n--;
    }
    if (s1n && s2n) {
        if (!(s2p[0] & 1))
            Perl_croak(aTHX_ "mpn_gcd_dest third argument must be odd");
        rn1 = mpn_gcd(rp, s1p, s1n, s2p, s2n);
        for (; rn1 < rn; rn1++) rp[rn1] = 0;
    }
    else
        Perl_croak(aTHX_ "division by zero error");

void
mpn_set_random(r, bitlen)
    SV *r;
    UV bitlen;
PREINIT:
    mp_limb_t *rp;
    mp_size_t rn = bitlen / GMP_NUMB_BITS;
    STRLEN rl = rn * sizeof(mp_limb_t);
CODE:
    if (rn * GMP_NUMB_BITS != bitlen)
        Perl_croak(aTHX_ "invalid bit length %d, on this machine a multiple of %d is required",
                   bitlen, GMP_NUMB_BITS);
    OUTPUT(r, rl);
    ALIGNED1(r);
    mpn_random(rp, rn);

UV
mpn_popcount(s1)
    SV *s1;
PREINIT:
    mp_limb_t *s1p;
    STRLEN s1l;
CODE:
    ARG(s1);
    ALIGNED1(s1);
    RETVAL = mpn_popcount(s1p, N(s1));
OUTPUT:
    RETVAL

UV
mpn_hamdist(s1, s2)
    SV *s1;
    SV *s2;
PREINIT:
    mp_limb_t *s1p, *s2p;
    STRLEN s1l, s2l;
    mp_size_t s1n, s2n;
CODE:
    ARG(s1);
    ARG(s2);
    ALIGNED2(s1, s2);
    s1n = N(s1);
    s2n = N(s2);
    if (s1n < s2n)
        RETVAL = mpn_hamdist(s1p, s2p, s1n) + mpn_popcount(s2p + s1n, s2n - s1n);
    else if (s1n > s2n)
        RETVAL = mpn_hamdist(s1p, s2p, s2n) + mpn_popcount(s1p + s2n, s1n - s2n);
    else
        RETVAL = mpn_hamdist(s1p, s2p, s2n);
OUTPUT:
    RETVAL

SV *
mpn_perfect_square_p(s1)
    SV *s1;
PREINIT:
    mp_limb_t *s1p;
    STRLEN s1l;
CODE:
    RETVAL = (mpn_perfect_square_p(s1p, N(s1)) ? &PL_sv_yes : &PL_sv_no);

IV
mpn_scan0(s1, offset = 0)
    SV *s1;
    UV offset;
PREINIT:
    mp_limb_t *s1p;
    STRLEN s1l;
    mp_size_t s1n;
CODE:
    ARG(s1);
    ALIGNED1(s1);
    s1n = N(s1);
    *((char*)(s1p + s1n)) = 0;
    if (offset < s1n * GMP_NUMB_BITS) {
        RETVAL = mpn_scan0(s1p, offset);
        if (RETVAL >= s1l * 8) RETVAL = -1;
    }
    else RETVAL = -1;
OUTPUT:
    RETVAL

IV
mpn_scan1(s1, offset = 0)
    SV *s1;
    UV offset;
PREINIT:
    mp_limb_t *s1p;
    STRLEN s1l;
    mp_size_t s1n;
CODE:
    ARG(s1);
    ALIGNED1(s1);
    s1n = N(s1);
    *((char*)(s1p + s1n)) = ~0;
    if (offset < s1n * GMP_NUMB_BITS) {
        RETVAL = mpn_scan1(s1p, offset);
        if (RETVAL >= s1l * 8) RETVAL = -1;
    }
    else RETVAL = -1;
    *((char*)(s1p + s1n)) = 0;
OUTPUT:
    RETVAL

SV *
mpn_get_str0(s1, base = 10)
    SV *s1
    UV base;
ALIAS:
    mpn_get_str = 1
PREINIT:
    mp_limb_t *s1p;
    STRLEN s1l, rl, scale, i;
    mp_size_t s1n;
    char *rp;
CODE:
    if ((base < 2) || (base > (ix ? 36 : 256)))
        Perl_croak(aTHX_ "base is out of range");
    s1 = sv_2mortal(newSVsv(s1));
    ARG(s1);
    ALIGNED1(s1);
    s1n = N(s1);
    while (s1n && !s1p[s1n - 1]) s1n--; /* discard high limbs equal to 0 */
    s1l = s1n * sizeof(mp_limb_t);
    scale = ( (base ==  2) ? 8 :
              (base ==  3) ? 6 :
              (base <=  6) ? 4 :
              (base <= 16) ? 3 :
                             2 );
    RETVAL = newSV(s1l * scale + 1);
    SvPOK_on(RETVAL);
    rp = SvPV_nolen(RETVAL);
    if (s1n) {
        rl = mpn_get_str(rp, base, s1p, N(s1));
        for (i = 0; (i < rl - 1) && (rp[i] == 0); i++);
        if (i) {
            rl -= i;
            Move(rp + i, rp, rl, char);
        }
    }
    else {
        rp[0] = 0;
        rl = 1;
    }
    rp[rl] = 0;
    SvCUR_set(RETVAL, rl);
    if (ix) {
        STRLEN i;
        char *pv = SvPV_nolen(RETVAL);
        for (i = 0; i < rl; i++) {
            char c = pv[i];
            pv[i] = (c < 10 ? c + '0' : c + ('a' - 10));
        }
    }
OUTPUT:
    RETVAL

void
mpn_set_str0(r, s, base = 0, bitlen = 0)
    SV *r
    SV *s
    UV base
    UV bitlen
ALIAS:
    mpn_set_str = 1
PREINIT:
    mp_limb_t *rp;
    STRLEN rl, sl, scale;
    mp_size_t rn;
    unsigned char *spv;
CODE:
    if (r == s)
        Perl_croak(aTHX_ "mpn_set_str arguments must not overlap");
    if (((ix != 1) || (base != 0)) &&
        ((base < 2) || (base > (ix ? 36 : 256))))
        Perl_croak(aTHX_ "base is out of range");
    if (ix) {
        STRLEN i;
        s = sv_2mortal(newSVsv(s));
        spv = SvPV(s, sl);
        if (base == 0) {
            if ((sl >= 2) && (spv[0] == '0')) {
                switch (spv[1]) {
                case 'x':
                    base = 16;
                    break;
                case 'o':
                    base = 8;
                    break;
                case 'b':
                    base = 2;
                    break;
                }
            }
            if (base) {
                spv += 2;
                sl -= 2;
            }
            else base = 10;
            fprintf(stderr, "base set to %d\n", (int)base); fflush(stderr);
        }
        for (i = 0; i < sl; i++) {
            char c = spv[i];
            if ((c >= '0') && (c <= '9'))
                spv[i] = c - '0';
            else if ((c >= 'a') && (c <= 'z'))
                spv[i] = c - 'a' + 10;
            else if ((c >= 'A') && (c <= 'Z'))
                spv[i] = c - 'A' + 10;
            else
                Perl_croak(aTHX_ "bad digit, ascii code: %d", c);
            if (spv[i] >= base)
                Perl_croak(aTHX_ "digit out of range, ascii code: %d", c);
        }
    }
    else
        spv = SvPV(s, sl);
    scale = ( (base ==  2) ? 8 :
              (base ==  3) ? 5 :
              (base ==  4) ? 4 :
              (base <=  6) ? 3 :
              (base <= 16) ? 2 :
                             1 );
    rl = sl / scale + 2 * sizeof(mp_limb_t);
    OUTPUT(r, rl);
    ALIGNED1(r);
    rn = mpn_set_str(rp, spv, sl, base);
    SvCUR_set(r, rn * sizeof(mp_limb_t));
    if (bitlen)
        my_set_bitlen(aTHX_ r, bitlen, 0);

void
mpn_set_bitlen(r, bitlen, sign_extend = 0)
    SV *r
    int bitlen
    int sign_extend
CODE:
    CHECK_OUTPUT(r);
    my_set_bitlen(aTHX_ r, bitlen, sign_extend);

UV
mpn_get_bitlen(s1)
    SV *s1
PREINIT:
    mp_limb_t *s1p;
    STRLEN s1l;
CODE:
    ARG(s1);
    RETVAL = GMP_NUMB_BITS * N(s1);

void
mpn_shorten(r, s1)
    SV *r;
    SV *s1;
PREINIT:
    mp_limb_t *rp, *s1p;
    STRLEN s1l;
    mp_limb_t s1n;
CODE:
    ARG(s1);
    ALIGNED1(s1);
    s1n = N(s1);
    while (s1n && s1p[s1n - 1]) s1n--;
    OUTPUT(r, s1n * sizeof(mp_limb_t));
    ALIGNED1(r);
    while(s1n--) rp[s1n] = s1p[s1n];

void
mpn_set_uint(r, s1, bitlen = GMP_NUMB_BITS)
    SV *r;
    UV s1;
    UV bitlen;
PREINIT:
    mp_limb_t *rp;
    mp_size_t rn, i;
CODE:
    rn = bitlen / GMP_NUMB_BITS;
    if (rn * GMP_NUMB_BITS != bitlen)
        Perl_croak(aTHX_ "invalid bit length %d, on this machine a multiple of %d is required",
                   bitlen, GMP_NUMB_BITS);
    OUTPUT(r, rn * sizeof(mp_limb_t));
    ALIGNED1(r);
    if (rn > 0) {
        rp[0] = s1;
        for (i = 1; i < rn; i++) rp[i] = 0;
    }

UV
mpn_setior_uint(r, s1, bitix = 0, bitlen = 0)
    SV *r;
    UV s1;
    UV bitix;
    UV bitlen;
PREINIT:
mp_limb_t *rp, high, low;
    STRLEN rl;
mp_size_t rn, rn1, limbix, smallix,top, i;
CODE:
    ARG(r);
    rn = N(r);
    limbix = bitix / GMP_NUMB_BITS;
    smallix = bitix - limbix * GMP_NUMB_BITS;
    high = s1 >> (GMP_NUMB_BITS - smallix);
    low = (s1 << smallix) & ~(mp_limb_t)0;
    top = limbix + (high ? 2 : 1);
    if (bitlen) {
        rn1 = bitlen / GMP_NUMB_BITS;
        if (rn1 * GMP_NUMB_BITS != bitlen)
            Perl_croak(aTHX_ "invalid bit length %d, on this machine a multiple of %d is required",
                       bitlen, GMP_NUMB_BITS);
        if (top > rn1)
            Perl_croak(aTHX_ "bitix is out of the range given bitlen");
    }
    else
        rn1 = (rn >= top ? rn : top);
    OUTPUT(r, rn1 * sizeof(mp_limb_t));
    ALIGNED1(r);
    while (rn < rn1) {
        rp[rn++] = 0;
    }
    rp[limbix] |= low;
    if (high)
        rp[limbix + 1] |= high;

UV
mpn_get_uint(s1, bitix = 0, mask = ~(IV)0)
    SV *s1;
    UV bitix;
    UV mask;
PREINIT:
    mp_limb_t *s1p, high, low;
    STRLEN s1l;
    mp_size_t s1n, limbix, smallix;
CODE:
    ARG(s1);
    ALIGNED1(s1);
    s1n = N(s1);
    limbix = bitix / GMP_NUMB_BITS;
    smallix = bitix - limbix * GMP_NUMB_BITS;
    if (limbix < s1n) {
        low = s1p[limbix];
        if (limbix + 1 < s1n)
            high = s1p[limbix + 1];
        else
            high = 0;
    }
    else {
        low = 0;
        high = 0;
    }
    RETVAL = ((low >> smallix) | (high << (GMP_NUMB_BITS - smallix))) & mask;
OUTPUT:
    RETVAL

