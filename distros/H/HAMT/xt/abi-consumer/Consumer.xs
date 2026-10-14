#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* The only thing this file knows about HAMT. */
#include "hamt_abi.h"

static const hamt_abi *HAMT = NULL;

#define NEED_ABI(what) do { if (!HAMT) croak("%s: no HAMT ABI", what); } while (0)

static int sum_pair(pTHX_ void *ud, const char *key, STRLEN klen, int utf8, SV *value) {
    PERL_UNUSED_ARG(key); PERL_UNUSED_ARG(klen); PERL_UNUSED_ARG(utf8);
    if (value && SvOK(value)) *(IV *)ud += SvIV(value);
    return 0;
}

static int join_member(pTHX_ void *ud, const char *key, STRLEN klen, int utf8, SV *value) {
    SV *out = (SV *)ud;
    PERL_UNUSED_ARG(utf8);
    if (value) return 1;                    /* a set's entries have none */
    if (SvCUR(out)) sv_catpvs(out, ",");
    sv_catpvn(out, key, klen);
    return 0;
}

static SV *pick_larger(pTHX_ void *ud, const char *key, STRLEN klen, int utf8, SV *mine, SV *theirs) {
    PERL_UNUSED_ARG(ud); PERL_UNUSED_ARG(key); PERL_UNUSED_ARG(klen); PERL_UNUSED_ARG(utf8);
    return SvIV(mine) >= SvIV(theirs) ? mine : theirs;
}

MODULE = HAMT::ABI::Consumer    PACKAGE = HAMT::ABI::Consumer

PROTOTYPES: DISABLE

BOOT:
{
    SV *err;
    SV *sv = eval_pv("require HAMT; HAMT::_abi_ptr()", 0);
    err = get_sv("@", 0);
    if (sv && SvOK(sv) && (!err || !SvTRUE(err))) {
        const hamt_abi *t = INT2PTR(const hamt_abi *, SvUV(sv));
        if (t && t->abi_version >= HAMT_ABI_VERSION) HAMT = t;
    }
}

IV
abi_version()
    CODE:
        RETVAL = HAMT ? HAMT->abi_version : 0;
    OUTPUT:
        RETVAL

# The sum of a map's values, without a Perl call for any of them.
IV
sum_values(obj)
        SV *obj
    PREINIT:
        const hamt_map *m;
    CODE:
        NEED_ABI("sum_values");
        m = (HAMT->map_from_sv)(aTHX_ obj);
        if (!m) croak("sum_values: not a HAMT::Map");
        RETVAL = 0;
        (HAMT->map_walk)(aTHX_ m, sum_pair, &RETVAL);
    OUTPUT:
        RETVAL

# A map with one more pair, the way a persistent update is made in C: copy
# the struct, change the copy, hand it to Perl.
SV *
with_pair(obj, key, value)
        SV *obj
        SV *key
        SV *value
    PREINIT:
        const hamt_map *m;
        hamt_map *n;
        STRLEN len;
        const char *p;
    CODE:
        NEED_ABI("with_pair");
        m = (HAMT->map_from_sv)(aTHX_ obj);
        if (!m) croak("with_pair: not a HAMT::Map");
        p = SvPV(key, len);
        n = (HAMT->map_copy)(aTHX_ m);
        if (!n) croak("with_pair: out of memory");
        if ((HAMT->map_store)(aTHX_ n, p, len, SvUTF8(key) ? 1 : 0, value) != HAMT_ABI_OK) {
            (HAMT->map_release)(aTHX_ n);
            croak("with_pair: out of memory");
        }
        RETVAL = (HAMT->map_to_sv)(aTHX_ n, NULL);
    OUTPUT:
        RETVAL

# Fills a Perl transient in place.
IV
fill(txn, n)
        SV *txn
        IV n
    PREINIT:
        hamt_map *m;
        IV i;
    CODE:
        NEED_ABI("fill");
        m = (HAMT->map_txn_from_sv)(aTHX_ txn);
        if (!m) croak("fill: not an open HAMT::Map::Transient");
        for (i = 0; i < n; i++) {
            char k[32];
            int len = my_snprintf(k, sizeof k, "c%" IVdf, i);
            if ((HAMT->map_store)(aTHX_ m, k, (STRLEN)len, 0, sv_2mortal(newSViv(i))) != HAMT_ABI_OK)
                croak("fill: out of memory");
        }
        RETVAL = (IV)(HAMT->map_count)(aTHX_ m);
    OUTPUT:
        RETVAL

# Two maps merged, the larger value winning.
SV *
merge_larger(a, b)
        SV *a
        SV *b
    PREINIT:
        const hamt_map *ma, *mb;
        hamt_map *r;
        int status;
    CODE:
        NEED_ABI("merge_larger");
        ma = (HAMT->map_from_sv)(aTHX_ a);
        mb = (HAMT->map_from_sv)(aTHX_ b);
        if (!ma || !mb) croak("merge_larger: not a HAMT::Map");
        r = (HAMT->map_merge)(aTHX_ ma, mb, pick_larger, NULL, &status);
        if (!r) croak("merge_larger: failed with %d", status);
        RETVAL = (HAMT->map_to_sv)(aTHX_ r, NULL);
    OUTPUT:
        RETVAL

# A set of the strings given.
SV *
set_of(...)
    PREINIT:
        hamt_map *s;
        I32 i;
    CODE:
        NEED_ABI("set_of");
        s = (HAMT->set_new)(aTHX);
        if (!s) croak("set_of: out of memory");
        for (i = 0; i < items; i++) {
            STRLEN len;
            const char *p = SvPV(ST(i), len);
            if ((HAMT->set_add)(aTHX_ s, p, len, SvUTF8(ST(i)) ? 1 : 0) != HAMT_ABI_OK) {
                (HAMT->set_release)(aTHX_ s);
                croak("set_of: out of memory");
            }
        }
        RETVAL = (HAMT->set_to_sv)(aTHX_ s, NULL);
    OUTPUT:
        RETVAL

# What two sets share, as a new set; and the members of one, joined.
SV *
common(a, b)
        SV *a
        SV *b
    PREINIT:
        const hamt_map *sa, *sb;
        hamt_map *r;
    CODE:
        NEED_ABI("common");
        sa = (HAMT->set_from_sv)(aTHX_ a);
        sb = (HAMT->set_from_sv)(aTHX_ b);
        if (!sa || !sb) croak("common: not a HAMT::Set");
        r = (HAMT->set_intersect)(aTHX_ sa, sb);
        if (!r) croak("common: out of memory");
        RETVAL = (HAMT->set_to_sv)(aTHX_ r, NULL);
    OUTPUT:
        RETVAL

SV *
members(obj)
        SV *obj
    PREINIT:
        const hamt_map *s;
    CODE:
        NEED_ABI("members");
        s = (HAMT->set_from_sv)(aTHX_ obj);
        if (!s) croak("members: not a HAMT::Set");
        RETVAL = newSVpvs("");
        if ((HAMT->set_walk)(aTHX_ s, join_member, RETVAL) != HAMT_ABI_OK) {
            SvREFCNT_dec(RETVAL);
            croak("members: a set entry carried a value");
        }
    OUTPUT:
        RETVAL

# A vector with its values in the other order.
SV *
reversed(obj)
        SV *obj
    PREINIT:
        const hamt_vec *v;
        hamt_vec *r;
        size_t i, n;
    CODE:
        NEED_ABI("reversed");
        v = (HAMT->vec_from_sv)(aTHX_ obj);
        if (!v) croak("reversed: not a HAMT::Vector");
        r = (HAMT->vec_new)(aTHX);
        if (!r) croak("reversed: out of memory");
        n = (HAMT->vec_count)(aTHX_ v);
        for (i = n; i > 0; i--) {
            if ((HAMT->vec_push)(aTHX_ r, (HAMT->vec_fetch)(aTHX_ v, i - 1)) != HAMT_ABI_OK) {
                (HAMT->vec_release)(aTHX_ r);
                croak("reversed: out of memory");
            }
        }
        RETVAL = (HAMT->vec_to_sv)(aTHX_ r, NULL);
    OUTPUT:
        RETVAL

# The middle of a vector moved to its end: a slice, a removal and a join.
SV *
rotate(obj, from, len)
        SV *obj
        UV from
        UV len
    PREINIT:
        const hamt_vec *v;
        hamt_vec *cut, *rest, *out;
        int status;
    CODE:
        NEED_ABI("rotate");
        v = (HAMT->vec_from_sv)(aTHX_ obj);
        if (!v) croak("rotate: not a HAMT::Vector");
        cut = (HAMT->vec_slice)(aTHX_ v, (size_t)from, (size_t)len, &status);
        if (!cut) croak("rotate: slice failed with %d", status);
        rest = (HAMT->vec_remove)(aTHX_ v, (size_t)from, (size_t)len, &status);
        if (!rest) { (HAMT->vec_release)(aTHX_ cut); croak("rotate: remove failed with %d", status); }
        out = (HAMT->vec_concat)(aTHX_ rest, cut);
        (HAMT->vec_release)(aTHX_ cut);
        (HAMT->vec_release)(aTHX_ rest);
        if (!out) croak("rotate: out of memory");
        RETVAL = (HAMT->vec_to_sv)(aTHX_ out, NULL);
    OUTPUT:
        RETVAL
