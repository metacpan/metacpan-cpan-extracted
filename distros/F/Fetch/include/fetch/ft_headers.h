#ifndef FT_HEADERS_H
#define FT_HEADERS_H

/* Fetch::Headers - an ordered, case-insensitive, multi-valued set of HTTP
 * header fields, stored as a blessed [k, v, k, v, ...] arrayref so it still
 * behaves as the flat pair list older code dereferences (@$h) while offering
 * get/get_all/set/add/remove/names/merge on top. Duplicate field names are
 * kept in order (Set-Cookie et al). All operations are these C helpers driven
 * from xs/headers.xs; the same helpers back Fetch::Response's header lookup. */

#include <ctype.h>
#include <string.h>

/* case-insensitive byte compare of two field names */
static int ft_ci_eq(const char *a, STRLEN al, const char *b, STRLEN bl) {
    STRLEN i;
    if (al != bl) return 0;
    for (i = 0; i < al; i++)
        if (tolower((unsigned char)a[i]) != tolower((unsigned char)b[i]))
            return 0;
    return 1;
}

/* index of the key SV of the first pair whose name matches case-insensitively,
 * or -1. The value sits at the following slot. */
static SSize_t ft_hdr_find(pTHX_ AV *av, const char *name, STRLEN nl) {
    SSize_t n = av_len(av) + 1, i;
    for (i = 0; i + 1 < n; i += 2) {
        SV **k = av_fetch(av, i, 0);
        if (k && *k) {
            STRLEN kl;
            const char *ks = SvPV_const(*k, kl);
            if (ft_ci_eq(ks, kl, name, nl)) return i;
        }
    }
    return -1;
}

/* sort helper for the hashref constructor path (matches Perl's `sort keys`) */
typedef struct { const char *k; STRLEN kl; SV *v; } ft_kv;
static int ft_kv_cmp(const void *a, const void *b) {
    const ft_kv *x = (const ft_kv *)a, *y = (const ft_kv *)b;
    STRLEN m = x->kl < y->kl ? x->kl : y->kl;
    int c = m ? memcmp(x->k, y->k, m) : 0;
    if (c) return c;
    return (x->kl > y->kl) - (x->kl < y->kl);
}

static void ft_hdr_from_hv(pTHX_ AV *dst, HV *h) {
    SSize_t n = (SSize_t)HvUSEDKEYS(h), i = 0, j;
    ft_kv *kv;
    HE *he;
    if (n <= 0) return;
    Newx(kv, n, ft_kv);
    hv_iterinit(h);
    while ((he = hv_iternext(h)) && i < n) {
        I32 klen;
        kv[i].k  = hv_iterkey(he, &klen);
        kv[i].kl = (STRLEN)(klen < 0 ? -klen : klen);
        kv[i].v  = hv_iterval(h, he);
        i++;
    }
    qsort(kv, (size_t)i, sizeof(ft_kv), ft_kv_cmp);
    for (j = 0; j < i; j++) {
        av_push(dst, newSVpvn(kv[j].k, kv[j].kl));
        av_push(dst, newSVsv(kv[j].v));
    }
    Safefree(kv);
}

/* is $name present (case-insensitive)? */
static int ft_hdr_exists(pTHX_ AV *av, const char *name, STRLEN nl) {
    return ft_hdr_find(aTHX_ av, name, nl) >= 0 ? 1 : 0;
}

/* Append the flat name => value list from $src to $dst: a Fetch::Headers or a
 * plain arrayref is copied element-wise; a hashref becomes sorted key/value
 * pairs; undef contributes nothing. */
static void ft_hdr_pairs_into(pTHX_ AV *dst, SV *src) {
    SV *rv;
    if (!src || !SvOK(src)) return;
    if (!SvROK(src))
        croak("Fetch::Headers: cannot build headers from 'scalar'");
    rv = SvRV(src);
    if (SvTYPE(rv) == SVt_PVAV) {
        AV *s = (AV *)rv;
        SSize_t n = av_len(s) + 1, i;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(s, i, 0);
            av_push(dst, (e && *e) ? newSVsv(*e) : newSV(0));
        }
    } else if (SvTYPE(rv) == SVt_PVHV) {
        ft_hdr_from_hv(aTHX_ dst, (HV *)rv);
    } else {
        croak("Fetch::Headers: cannot build headers from '%s'",
              sv_reftype(rv, 0));
    }
}

/* lowercase a name into a freshly malloc'd buffer (caller frees) */
static char *ft_lc_dup(const char *s, STRLEN n) {
    char *r = (char *)malloc(n + 1);   /* +1: NUL-terminate so callers that
                                        * treat the result as a C string (the
                                        * URL scheme) do not read past it */
    STRLEN i;
    if (r) {
        for (i = 0; i < n; i++) r[i] = (char)tolower((unsigned char)s[i]);
        r[n] = '\0';
    }
    return r;
}

/* Overlay $other on the flat [k,v,...] list $av in place: each field name it
 * carries replaces all of $av's values for that name; names present only in
 * $av are kept, in order; the overlay is appended. */
static void ft_hdr_merge(pTHX_ AV *av, SV *other) {
    AV *ov, *kept;
    HV *repl;
    SSize_t on, n, i;
    if (!SvOK(other)) return;
    ov   = newAV();
    repl = newHV();
    kept = newAV();
    sv_2mortal((SV *)ov);
    sv_2mortal((SV *)repl);
    ft_hdr_pairs_into(aTHX_ ov, other);
    on = av_len(ov) + 1;
    for (i = 0; i + 1 < on; i += 2) {
        SV **k = av_fetch(ov, i, 0);
        if (k && *k) {
            STRLEN kl;
            const char *ks = SvPV_const(*k, kl);
            char *lc = ft_lc_dup(ks, kl);
            (void)hv_store(repl, lc, (I32)kl, &PL_sv_yes, 0);
            free(lc);
        }
    }
    n = av_len(av) + 1;
    for (i = 0; i + 1 < n; i += 2) {
        SV **k = av_fetch(av, i, 0);
        int drop = 0;
        if (k && *k) {
            STRLEN kl;
            const char *ks = SvPV_const(*k, kl);
            char *lc = ft_lc_dup(ks, kl);
            drop = hv_exists(repl, lc, (I32)kl);
            free(lc);
        }
        if (!drop) {
            SV **v = av_fetch(av, i + 1, 0);
            av_push(kept, (k && *k) ? newSVsv(*k) : newSV(0));
            av_push(kept, (v && *v) ? newSVsv(*v) : newSV(0));
        }
    }
    on = av_len(ov) + 1;
    for (i = 0; i < on; i++) {
        SV **e = av_fetch(ov, i, 0);
        av_push(kept, (e && *e) ? newSVsv(*e) : newSV(0));
    }
    av_clear(av);
    n = av_len(kept) + 1;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(kept, i, 0);
        av_push(av, (e && *e) ? SvREFCNT_inc(*e) : newSV(0));
    }
    SvREFCNT_dec((SV *)kept);
}

#endif /* FT_HEADERS_H */
