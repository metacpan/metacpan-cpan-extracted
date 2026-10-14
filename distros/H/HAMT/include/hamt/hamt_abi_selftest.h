#ifndef HAMT_ABI_SELFTEST_H
#define HAMT_ABI_SELFTEST_H

/* Walks the table. Every entry is called THROUGH the table, with its answer
 * checked, so an entry that points at the wrong function, or sits in the
 * wrong place, fails here by number and not in some consumer's hands.
 *
 * A table is a list of addresses, and nothing about compiling one proves
 * that an entry points where its declaration says. */

#define HAMT_ST(n, cond) do { if (!(cond)) { step = (n); goto done; } } while (0)

typedef struct hamt_st_walk {
    size_t calls, with_value, stop_at;
    IV     sum;
} hamt_st_walk;

static int hamt_st_pair(pTHX_ void *ud, const char *key, STRLEN klen, int utf8, SV *value) {
    hamt_st_walk *w = (hamt_st_walk *)ud;
    PERL_UNUSED_ARG(key); PERL_UNUSED_ARG(klen); PERL_UNUSED_ARG(utf8);
    w->calls++;
    if (value) { w->with_value++; if (SvIOK(value)) w->sum += SvIV(value); }
    return w->stop_at && w->calls == w->stop_at;
}
static int hamt_st_item(pTHX_ void *ud, size_t index, SV *value) {
    hamt_st_walk *w = (hamt_st_walk *)ud;
    if (index != w->calls) w->sum = -1000000;        /* out of order */
    w->calls++;
    if (value && SvIOK(value) && w->sum >= 0) w->sum += SvIV(value);
    return w->stop_at && w->calls == w->stop_at;
}
static int hamt_st_numeric(pTHX_ void *ud, SV *a, SV *b) {
    (*(int *)ud)++;
    return SvNV(a) == SvNV(b);
}
static int hamt_st_never(pTHX_ void *ud, SV *a, SV *b) {
    PERL_UNUSED_CONTEXT; PERL_UNUSED_ARG(ud); PERL_UNUSED_ARG(a); PERL_UNUSED_ARG(b);
    return -1;
}
static SV *hamt_st_sum(pTHX_ void *ud, const char *key, STRLEN klen, int utf8, SV *mine, SV *theirs) {
    PERL_UNUSED_ARG(key); PERL_UNUSED_ARG(klen); PERL_UNUSED_ARG(utf8);
    (*(int *)ud)++;
    return sv_2mortal(newSViv(SvIV(mine) + SvIV(theirs)));
}
static SV *hamt_st_refuse(pTHX_ void *ud, const char *key, STRLEN klen, int utf8, SV *mine, SV *theirs) {
    PERL_UNUSED_CONTEXT; PERL_UNUSED_ARG(ud); PERL_UNUSED_ARG(key); PERL_UNUSED_ARG(klen);
    PERL_UNUSED_ARG(utf8); PERL_UNUSED_ARG(mine); PERL_UNUSED_ARG(theirs);
    return NULL;
}
static SV *hamt_st_bump(pTHX_ void *ud, SV *current) {
    PERL_UNUSED_ARG(ud);
    return sv_2mortal(newSViv(current ? SvIV(current) + 1 : 100));
}
static SV *hamt_st_same(pTHX_ void *ud, SV *current) {
    PERL_UNUSED_CONTEXT; PERL_UNUSED_ARG(ud);
    return current;
}
static SV *hamt_st_stop(pTHX_ void *ud, SV *current) {
    PERL_UNUSED_CONTEXT; PERL_UNUSED_ARG(ud); PERL_UNUSED_ARG(current);
    return NULL;
}
typedef struct hamt_st_diffs { int add, remove, change, bad; } hamt_st_diffs;
static int hamt_st_diff(pTHX_ void *ud, int kind, const char *key, STRLEN klen, int utf8, SV *was, SV *now) {
    hamt_st_diffs *d = (hamt_st_diffs *)ud;
    PERL_UNUSED_CONTEXT; PERL_UNUSED_ARG(key); PERL_UNUSED_ARG(utf8);
    if (!klen) d->bad = 1;
    if (kind == HAMT_ABI_ADD)         { d->add++;    if (was || !now) d->bad = 1; }
    else if (kind == HAMT_ABI_REMOVE) { d->remove++; if (!was || now) d->bad = 1; }
    else if (kind == HAMT_ABI_CHANGE) { d->change++; if (!was || !now) d->bad = 1; }
    else d->bad = 1;
    return 0;
}

/* 0, or the number of the first check that failed. On success the three
 * objects are a map, a set and a vector built here and handed to Perl, so
 * that the Perl surface can be asked what C built: a table can be wrong in
 * a way that agrees with itself, and the Perl surface is what cannot be
 * wrong in the same direction. */
static int hamt_abi_selftest(pTHX_ SV **map_out, SV **set_out, SV **vec_out) {
    const hamt_abi *A = &HAMT_ABI;
    hamt_map *m = NULL, *m2 = NULL, *m3 = NULL, *s = NULL, *s2 = NULL, *s3 = NULL;
    hamt_vec *v = NULL, *v2 = NULL, *v3 = NULL;
    SV *one, *obj = NULL, *tmp;
    HV *hv = NULL;
    AV *av = NULL;
    hamt_st_walk w;
    hamt_st_diffs d;
    static const char e_utf8[]   = { (char)0xc3, (char)0xa9 };   /* e-acute, as UTF-8 */
    static const char e_latin1[] = { (char)0xe9 };               /* and as one byte   */
    static const char wide[]     = { (char)0xc4, (char)0x80 };   /* U+0100 */
    int step = 0, status = 12345, calls = 0, i;
    size_t n;
    long before = hamt_live_blocks;

    *map_out = *set_out = *vec_out = NULL;
    ENTER;
    SAVETMPS;
    one = sv_2mortal(newSViv(1));

    HAMT_ST(1, A->abi_version == HAMT_ABI_VERSION);

    /* ---- values ---- */
    HAMT_ST(2, (A->value_equal)(aTHX_ one, one) == 1);
    HAMT_ST(3, (A->value_equal)(aTHX_ one, sv_2mortal(newSVpvs("1"))) == 1);
    HAMT_ST(4, (A->value_equal)(aTHX_ one, sv_2mortal(newSVpvs("1.0"))) == 0);
    HAMT_ST(5, (A->value_equal)(aTHX_ &PL_sv_undef, sv_2mortal(newSV(0))) == 1);

    /* ---- a map: new, store, fetch, has, count ---- */
    m = (A->map_new)(aTHX);
    HAMT_ST(10, m != NULL && (A->map_count)(aTHX_ m) == 0);
    HAMT_ST(11, (A->map_fetch)(aTHX_ m, "alpha", 5, 0) == NULL && (A->map_has)(aTHX_ m, "alpha", 5, 0) == 0);
    HAMT_ST(12, (A->map_store)(aTHX_ m, "alpha", 5, 0, one) == HAMT_ABI_OK);
    HAMT_ST(13, (A->map_store)(aTHX_ m, "beta", 4, 0, sv_2mortal(newSViv(2))) == HAMT_ABI_OK);
    HAMT_ST(14, (A->map_store)(aTHX_ m, "gone", 4, 0, NULL) == HAMT_ABI_OK);
    HAMT_ST(15, (A->map_count)(aTHX_ m) == 3);
    tmp = (A->map_fetch)(aTHX_ m, "alpha", 5, 0);
    HAMT_ST(16, tmp && tmp != one && SvIV(tmp) == 1 && SvREADONLY(tmp));    /* a copy, read-only */
    tmp = (A->map_fetch)(aTHX_ m, "gone", 4, 0);
    HAMT_ST(17, tmp && !SvOK(tmp) && (A->map_has)(aTHX_ m, "gone", 4, 0) == 1);   /* a stored undef */
    HAMT_ST(18, !SvREADONLY(one));                                           /* the caller's is untouched */

    /* ---- keys: the hash-key rule ---- */
    HAMT_ST(20, (A->map_store)(aTHX_ m, e_utf8, 2, 1, sv_2mortal(newSViv(3))) == HAMT_ABI_OK);
    HAMT_ST(21, (A->map_has)(aTHX_ m, e_latin1, 1, 0) == 1);     /* one key, two spellings */
    HAMT_ST(22, (A->map_store)(aTHX_ m, e_latin1, 1, 0, sv_2mortal(newSViv(3))) == HAMT_ABI_OK
                && (A->map_count)(aTHX_ m) == 4);
    HAMT_ST(23, (A->map_store)(aTHX_ m, wide, 2, 1, sv_2mortal(newSViv(4))) == HAMT_ABI_OK);
    HAMT_ST(24, (A->map_has)(aTHX_ m, wide, 2, 1) == 1 && (A->map_has)(aTHX_ m, wide, 2, 0) == 0);
    HAMT_ST(25, (A->map_store)(aTHX_ m, "ascii", 5, 1, one) == HAMT_ABI_OK
                && (A->map_has)(aTHX_ m, "ascii", 5, 0) == 1);   /* a flag on plain ASCII is nothing */
    HAMT_ST(26, (A->map_remove)(aTHX_ m, "ascii", 5, 0) == HAMT_ABI_OK && (A->map_count)(aTHX_ m) == 5);
    HAMT_ST(27, (A->map_check)(aTHX_ m) == 0);

    /* ---- copy, and the two going their own ways ---- */
    m2 = (A->map_copy)(aTHX_ m);
    HAMT_ST(30, m2 != NULL && (A->map_count)(aTHX_ m2) == 5);
    HAMT_ST(31, (A->map_store)(aTHX_ m2, "alpha", 5, 0, sv_2mortal(newSViv(10))) == HAMT_ABI_OK);
    HAMT_ST(32, (A->map_remove)(aTHX_ m2, "gone", 4, 0) == HAMT_ABI_OK);
    HAMT_ST(33, (A->map_remove)(aTHX_ m2, "never there", 11, 0) == HAMT_ABI_OK);
    HAMT_ST(34, (A->map_store)(aTHX_ m2, "new", 3, 0, sv_2mortal(newSViv(7))) == HAMT_ABI_OK);
    HAMT_ST(35, SvIV((A->map_fetch)(aTHX_ m, "alpha", 5, 0)) == 1 && (A->map_has)(aTHX_ m, "gone", 4, 0)
                && !(A->map_has)(aTHX_ m, "new", 3, 0) && (A->map_count)(aTHX_ m) == 5);
    HAMT_ST(36, SvIV((A->map_fetch)(aTHX_ m2, "alpha", 5, 0)) == 10 && (A->map_count)(aTHX_ m2) == 5);
    HAMT_ST(37, (A->map_check)(aTHX_ m) == 0 && (A->map_check)(aTHX_ m2) == 0);
    /* The very scalar already stored: nothing changes. */
    tmp = (A->map_fetch)(aTHX_ m2, "beta", 4, 0);
    HAMT_ST(38, (A->map_store)(aTHX_ m2, "beta", 4, 0, tmp) == HAMT_ABI_OK
                && (A->map_fetch)(aTHX_ m2, "beta", 4, 0) == tmp);

    /* ---- update ---- */
    HAMT_ST(40, (A->map_update)(aTHX_ m2, "beta", 4, 0, hamt_st_bump, NULL) == HAMT_ABI_OK
                && SvIV((A->map_fetch)(aTHX_ m2, "beta", 4, 0)) == 3);
    HAMT_ST(41, (A->map_update)(aTHX_ m2, "fresh", 5, 0, hamt_st_bump, NULL) == HAMT_ABI_OK
                && SvIV((A->map_fetch)(aTHX_ m2, "fresh", 5, 0)) == 100 && (A->map_count)(aTHX_ m2) == 6);
    tmp = (A->map_fetch)(aTHX_ m2, "beta", 4, 0);
    HAMT_ST(42, (A->map_update)(aTHX_ m2, "beta", 4, 0, hamt_st_same, NULL) == HAMT_ABI_OK
                && (A->map_fetch)(aTHX_ m2, "beta", 4, 0) == tmp);
    HAMT_ST(43, (A->map_update)(aTHX_ m2, "beta", 4, 0, hamt_st_stop, NULL) == HAMT_ABI_STOPPED
                && (A->map_fetch)(aTHX_ m2, "beta", 4, 0) == tmp);
    HAMT_ST(44, SvIV((A->map_fetch)(aTHX_ m, "beta", 4, 0)) == 2);

    /* ---- walk ---- */
    Zero(&w, 1, hamt_st_walk);
    HAMT_ST(50, (A->map_walk)(aTHX_ m, hamt_st_pair, &w) == HAMT_ABI_OK);
    HAMT_ST(51, w.calls == 5 && w.with_value == 5 && w.sum == 1 + 2 + 3 + 4);
    Zero(&w, 1, hamt_st_walk);
    w.stop_at = 2;
    HAMT_ST(52, (A->map_walk)(aTHX_ m, hamt_st_pair, &w) == HAMT_ABI_STOPPED && w.calls == 2);

    /* ---- merge, equal, diff ---- */
    m3 = (A->map_merge)(aTHX_ m, m2, NULL, NULL, &status);
    HAMT_ST(60, m3 != NULL && status == HAMT_ABI_OK && (A->map_count)(aTHX_ m3) == 7);
    HAMT_ST(61, SvIV((A->map_fetch)(aTHX_ m3, "alpha", 5, 0)) == 10      /* the second's wins */
                && (A->map_has)(aTHX_ m3, "gone", 4, 0) && (A->map_has)(aTHX_ m3, "new", 3, 0)
                && (A->map_check)(aTHX_ m3) == 0);
    (A->map_release)(aTHX_ m3);
    calls = 0;
    m3 = (A->map_merge)(aTHX_ m, m2, hamt_st_sum, &calls, &status);
    HAMT_ST(62, m3 != NULL && status == HAMT_ABI_OK && calls == 2);       /* alpha and beta differ */
    HAMT_ST(63, SvIV((A->map_fetch)(aTHX_ m3, "alpha", 5, 0)) == 11
                && SvIV((A->map_fetch)(aTHX_ m3, "beta", 4, 0)) == 5);
    (A->map_release)(aTHX_ m3);
    status = 12345;
    m3 = (A->map_merge)(aTHX_ m, m2, hamt_st_refuse, NULL, &status);
    HAMT_ST(64, m3 == NULL && status == HAMT_ABI_STOPPED);
    m3 = (A->map_merge)(aTHX_ m, m2, hamt_st_refuse, NULL, NULL);         /* a NULL status is allowed */
    HAMT_ST(65, m3 == NULL);

    HAMT_ST(70, (A->map_equal)(aTHX_ m, m, NULL, NULL) == 1 && (A->map_equal)(aTHX_ m, m2, NULL, NULL) == 0);
    m3 = (A->map_copy)(aTHX_ m);
    HAMT_ST(71, m3 && (A->map_store)(aTHX_ m3, "alpha", 5, 0, sv_2mortal(newSVpvs("1.0"))) == HAMT_ABI_OK);
    calls = 0;
    HAMT_ST(72, (A->map_equal)(aTHX_ m, m3, NULL, NULL) == 0
                && (A->map_equal)(aTHX_ m, m3, hamt_st_numeric, &calls) == 1 && calls == 1);
    HAMT_ST(73, (A->map_equal)(aTHX_ m, m3, hamt_st_never, NULL) == HAMT_ABI_STOPPED);
    (A->map_release)(aTHX_ m3);
    m3 = NULL;

    Zero(&d, 1, hamt_st_diffs);
    n = 999;
    HAMT_ST(74, (A->map_diff)(aTHX_ m, m2, hamt_st_diff, &d, &n) == HAMT_ABI_OK);
    /* m2 has alpha and beta changed, gone removed, new and fresh added. */
    HAMT_ST(75, !d.bad && d.change == 2 && d.remove == 1 && d.add == 2 && n == 5);
    n = 999;
    HAMT_ST(76, (A->map_diff)(aTHX_ m, m, NULL, NULL, &n) == HAMT_ABI_OK && n == 0);
    HAMT_ST(77, (A->map_diff)(aTHX_ m, m2, NULL, NULL, &n) == HAMT_ABI_OK && n == 5);

    /* ---- to and from a hash; to and from objects ---- */
    hv = (A->map_to_hv)(aTHX_ m);
    HAMT_ST(80, hv != NULL && HvUSEDKEYS(hv) == 5);
    m3 = (A->map_from_hv)(aTHX_ hv);
    HAMT_ST(81, m3 != NULL && (A->map_equal)(aTHX_ m, m3, NULL, NULL) == 1 && (A->map_check)(aTHX_ m3) == 0);
    HAMT_ST(82, (A->map_has)(aTHX_ m3, wide, 2, 1) && (A->map_has)(aTHX_ m3, e_latin1, 1, 0));

    obj = (A->map_to_sv)(aTHX_ m3, NULL);                 /* m3 is the object's now */
    m3 = NULL;
    HAMT_ST(83, obj && sv_derived_from(obj, "HAMT::Map") && SvREFCNT(obj) == 1);
    HAMT_ST(84, (A->map_from_sv)(aTHX_ obj) != NULL && (A->map_count)(aTHX_ (A->map_from_sv)(aTHX_ obj)) == 5);
    HAMT_ST(85, (A->map_from_sv)(aTHX_ one) == NULL && (A->set_from_sv)(aTHX_ obj) == NULL
                && (A->map_txn_from_sv)(aTHX_ obj) == NULL && (A->vec_from_sv)(aTHX_ obj) == NULL);
    SvREFCNT_dec(obj);
    obj = NULL;

    m3 = (A->map_copy)(aTHX_ m);
    obj = (A->map_to_txn_sv)(aTHX_ m3, NULL);
    m3 = NULL;
    HAMT_ST(86, obj && sv_derived_from(obj, "HAMT::Map::Transient") && (A->map_from_sv)(aTHX_ obj) == NULL);
    m3 = (A->map_txn_from_sv)(aTHX_ obj);                 /* borrowed, and may be changed */
    HAMT_ST(87, m3 != NULL && (A->map_store)(aTHX_ m3, "in place", 8, 0, one) == HAMT_ABI_OK
                && (A->map_count)(aTHX_ (A->map_txn_from_sv)(aTHX_ obj)) == 6 && (A->map_count)(aTHX_ m) == 5);
    m3 = NULL;
    SvREFCNT_dec(obj);
    obj = NULL;

    /* ---- a map's keys as a set ---- */
    s = (A->map_key_set)(aTHX_ m);
    HAMT_ST(90, s != NULL && (A->set_count)(aTHX_ s) == 5 && (A->set_has)(aTHX_ s, "alpha", 5, 0) == 1
                && (A->set_check)(aTHX_ s) == 0);
    Zero(&w, 1, hamt_st_walk);
    HAMT_ST(91, (A->set_walk)(aTHX_ s, hamt_st_pair, &w) == HAMT_ABI_OK && w.calls == 5 && w.with_value == 0);
    (A->set_release)(aTHX_ s);
    s = NULL;

    /* ---- sets ---- */
    s = (A->set_new)(aTHX);
    s2 = (A->set_new)(aTHX);
    HAMT_ST(100, s && s2 && (A->set_count)(aTHX_ s) == 0);
    for (i = 0; i < 100 && !step; i++) {
        char k[16];
        int len = my_snprintf(k, sizeof k, "m%d", i);
        if ((A->set_add)(aTHX_ s, k, (STRLEN)len, 0) != HAMT_ABI_OK) step = 101;
        if (i >= 50 && (A->set_add)(aTHX_ s2, k, (STRLEN)len, 0) != HAMT_ABI_OK) step = 101;
    }
    if (step) goto done;
    for (i = 100; i < 130 && !step; i++) {
        char k[16];
        int len = my_snprintf(k, sizeof k, "m%d", i);
        if ((A->set_add)(aTHX_ s2, k, (STRLEN)len, 0) != HAMT_ABI_OK) step = 102;
    }
    if (step) goto done;
    HAMT_ST(103, (A->set_count)(aTHX_ s) == 100 && (A->set_count)(aTHX_ s2) == 80);
    HAMT_ST(104, (A->set_add)(aTHX_ s, "m7", 2, 0) == HAMT_ABI_OK && (A->set_count)(aTHX_ s) == 100);
    HAMT_ST(105, (A->set_has)(aTHX_ s, "m7", 2, 0) == 1 && (A->set_has)(aTHX_ s, "m107", 4, 0) == 0);

    s3 = (A->set_union)(aTHX_ s, s2);
    HAMT_ST(110, s3 && (A->set_count)(aTHX_ s3) == 130 && (A->set_check)(aTHX_ s3) == 0);
    HAMT_ST(111, (A->set_is_subset)(aTHX_ s, s3) == 1 && (A->set_is_subset)(aTHX_ s3, s) == 0);
    (A->set_release)(aTHX_ s3);
    s3 = (A->set_intersect)(aTHX_ s, s2);
    HAMT_ST(112, s3 && (A->set_count)(aTHX_ s3) == 50 && (A->set_check)(aTHX_ s3) == 0
                 && (A->set_has)(aTHX_ s3, "m50", 3, 0) == 1 && (A->set_has)(aTHX_ s3, "m49", 3, 0) == 0);
    (A->set_release)(aTHX_ s3);
    s3 = (A->set_difference)(aTHX_ s, s2);
    HAMT_ST(113, s3 && (A->set_count)(aTHX_ s3) == 50 && (A->set_check)(aTHX_ s3) == 0
                 && (A->set_has)(aTHX_ s3, "m49", 3, 0) == 1 && (A->set_has)(aTHX_ s3, "m50", 3, 0) == 0);
    HAMT_ST(114, (A->set_is_disjoint)(aTHX_ s3, s2) == 1 && (A->set_is_disjoint)(aTHX_ s, s2) == 0);
    HAMT_ST(115, (A->set_equal)(aTHX_ s, s) == 1 && (A->set_equal)(aTHX_ s, s3) == 0);
    (A->set_release)(aTHX_ s3);
    s3 = (A->set_difference)(aTHX_ s, s);                  /* empty is a set, not NULL */
    HAMT_ST(116, s3 != NULL && (A->set_count)(aTHX_ s3) == 0);
    (A->set_release)(aTHX_ s3);
    s3 = (A->set_copy)(aTHX_ s);
    HAMT_ST(117, s3 && (A->set_remove)(aTHX_ s3, "m7", 2, 0) == HAMT_ABI_OK && (A->set_count)(aTHX_ s3) == 99
                 && (A->set_count)(aTHX_ s) == 100 && (A->set_has)(aTHX_ s, "m7", 2, 0) == 1);

    obj = (A->set_to_sv)(aTHX_ s3, NULL);
    s3 = NULL;
    HAMT_ST(120, obj && sv_derived_from(obj, "HAMT::Set") && (A->set_from_sv)(aTHX_ obj) != NULL
                 && (A->map_from_sv)(aTHX_ obj) == NULL);      /* a set is not a map */
    SvREFCNT_dec(obj);
    obj = NULL;
    s3 = (A->set_copy)(aTHX_ s);
    obj = (A->set_to_txn_sv)(aTHX_ s3, NULL);
    s3 = (A->set_txn_from_sv)(aTHX_ obj);
    HAMT_ST(121, obj && s3 && sv_derived_from(obj, "HAMT::Set::Transient")
                 && (A->set_add)(aTHX_ s3, "in place", 8, 0) == HAMT_ABI_OK
                 && (A->set_count)(aTHX_ s3) == 101 && (A->set_count)(aTHX_ s) == 100
                 && (A->map_txn_from_sv)(aTHX_ obj) == NULL);
    s3 = NULL;
    SvREFCNT_dec(obj);
    obj = NULL;

    /* ---- vectors ---- */
    v = (A->vec_new)(aTHX);
    HAMT_ST(130, v != NULL && (A->vec_count)(aTHX_ v) == 0 && (A->vec_fetch)(aTHX_ v, 0) == NULL);
    HAMT_ST(131, (A->vec_pop)(aTHX_ v) == HAMT_ABI_OK && (A->vec_count)(aTHX_ v) == 0);
    for (i = 0; i < 1100 && !step; i++)
        if ((A->vec_push)(aTHX_ v, sv_2mortal(newSViv(i))) != HAMT_ABI_OK) step = 132;
    if (step) goto done;
    HAMT_ST(133, (A->vec_count)(aTHX_ v) == 1100 && (A->vec_check)(aTHX_ v) == 0);
    HAMT_ST(134, SvIV((A->vec_fetch)(aTHX_ v, 0)) == 0 && SvIV((A->vec_fetch)(aTHX_ v, 1099)) == 1099
                 && SvIV((A->vec_fetch)(aTHX_ v, 555)) == 555 && (A->vec_fetch)(aTHX_ v, 1100) == NULL);
    HAMT_ST(135, SvREADONLY((A->vec_fetch)(aTHX_ v, 5)));

    v2 = (A->vec_copy)(aTHX_ v);
    HAMT_ST(140, v2 && (A->vec_store)(aTHX_ v2, 555, sv_2mortal(newSViv(-1))) == HAMT_ABI_OK);
    HAMT_ST(141, (A->vec_store)(aTHX_ v2, 1100, one) == HAMT_ABI_RANGE);
    HAMT_ST(142, (A->vec_pop)(aTHX_ v2) == HAMT_ABI_OK && (A->vec_push)(aTHX_ v2, NULL) == HAMT_ABI_OK);
    HAMT_ST(143, SvIV((A->vec_fetch)(aTHX_ v2, 555)) == -1 && !SvOK((A->vec_fetch)(aTHX_ v2, 1099))
                 && SvIV((A->vec_fetch)(aTHX_ v, 555)) == 555 && SvIV((A->vec_fetch)(aTHX_ v, 1099)) == 1099);
    HAMT_ST(144, (A->vec_check)(aTHX_ v2) == 0 && (A->vec_check)(aTHX_ v) == 0);

    Zero(&w, 1, hamt_st_walk);
    HAMT_ST(150, (A->vec_walk)(aTHX_ v, hamt_st_item, &w) == HAMT_ABI_OK && w.calls == 1100
                 && w.sum == 1099 * 1100 / 2);
    Zero(&w, 1, hamt_st_walk);
    w.stop_at = 40;
    HAMT_ST(151, (A->vec_walk)(aTHX_ v, hamt_st_item, &w) == HAMT_ABI_STOPPED && w.calls == 40);

    HAMT_ST(155, (A->vec_equal)(aTHX_ v, v, NULL, NULL) == 1 && (A->vec_equal)(aTHX_ v, v2, NULL, NULL) == 0);
    HAMT_ST(156, (A->vec_equal)(aTHX_ v, v2, hamt_st_never, NULL) == HAMT_ABI_STOPPED);
    (A->vec_release)(aTHX_ v2);
    v2 = NULL;

    v2 = (A->vec_concat)(aTHX_ v, v);
    HAMT_ST(160, v2 && (A->vec_count)(aTHX_ v2) == 2200 && (A->vec_check)(aTHX_ v2) == 0
                 && SvIV((A->vec_fetch)(aTHX_ v2, 1100)) == 0 && SvIV((A->vec_fetch)(aTHX_ v2, 2199)) == 1099);
    status = 12345;
    v3 = (A->vec_slice)(aTHX_ v2, 1090, 20, &status);
    HAMT_ST(161, v3 && status == HAMT_ABI_OK && (A->vec_count)(aTHX_ v3) == 20 && (A->vec_check)(aTHX_ v3) == 0
                 && SvIV((A->vec_fetch)(aTHX_ v3, 0)) == 1090 && SvIV((A->vec_fetch)(aTHX_ v3, 10)) == 0);
    (A->vec_release)(aTHX_ v3);
    v3 = (A->vec_slice)(aTHX_ v2, 2190, 20, &status);
    HAMT_ST(162, v3 == NULL && status == HAMT_ABI_RANGE);
    v3 = (A->vec_slice)(aTHX_ v2, 2201, 0, NULL);
    HAMT_ST(163, v3 == NULL);
    v3 = (A->vec_slice)(aTHX_ v2, 2200, 0, &status);          /* nothing, at the very end */
    HAMT_ST(164, v3 != NULL && status == HAMT_ABI_OK && (A->vec_count)(aTHX_ v3) == 0);
    (A->vec_release)(aTHX_ v3);
    (A->vec_release)(aTHX_ v2);
    v2 = v3 = NULL;

    v2 = (A->vec_new)(aTHX);
    HAMT_ST(170, v2 && (A->vec_push)(aTHX_ v2, sv_2mortal(newSVpvs("x"))) == HAMT_ABI_OK
                 && (A->vec_push)(aTHX_ v2, sv_2mortal(newSVpvs("y"))) == HAMT_ABI_OK);
    v3 = (A->vec_insert)(aTHX_ v, 500, v2, &status);
    HAMT_ST(171, v3 && status == HAMT_ABI_OK && (A->vec_count)(aTHX_ v3) == 1102 && (A->vec_check)(aTHX_ v3) == 0
                 && SvIV((A->vec_fetch)(aTHX_ v3, 499)) == 499 && strEQ(SvPV_nolen((A->vec_fetch)(aTHX_ v3, 500)), "x")
                 && strEQ(SvPV_nolen((A->vec_fetch)(aTHX_ v3, 501)), "y") && SvIV((A->vec_fetch)(aTHX_ v3, 502)) == 500);
    (A->vec_release)(aTHX_ v3);
    v3 = (A->vec_insert)(aTHX_ v, 1100, v2, &status);         /* at the end is allowed */
    HAMT_ST(172, v3 && (A->vec_count)(aTHX_ v3) == 1102 && strEQ(SvPV_nolen((A->vec_fetch)(aTHX_ v3, 1101)), "y"));
    (A->vec_release)(aTHX_ v3);
    v3 = (A->vec_insert)(aTHX_ v, 1101, v2, &status);
    HAMT_ST(173, v3 == NULL && status == HAMT_ABI_RANGE);
    v3 = (A->vec_remove)(aTHX_ v, 10, 1000, &status);
    HAMT_ST(174, v3 && status == HAMT_ABI_OK && (A->vec_count)(aTHX_ v3) == 100 && (A->vec_check)(aTHX_ v3) == 0
                 && SvIV((A->vec_fetch)(aTHX_ v3, 9)) == 9 && SvIV((A->vec_fetch)(aTHX_ v3, 10)) == 1010);
    (A->vec_release)(aTHX_ v3);
    v3 = (A->vec_remove)(aTHX_ v, 1000, 101, &status);
    HAMT_ST(175, v3 == NULL && status == HAMT_ABI_RANGE);
    (A->vec_release)(aTHX_ v2);
    v2 = v3 = NULL;
    HAMT_ST(176, (A->vec_count)(aTHX_ v) == 1100 && (A->vec_check)(aTHX_ v) == 0);   /* v never moved */

    av = (A->vec_to_av)(aTHX_ v);
    HAMT_ST(180, av != NULL && av_len(av) == 1099 && SvIV(*av_fetch(av, 777, 0)) == 777
                 && !SvREADONLY(*av_fetch(av, 777, 0)));
    v2 = (A->vec_from_av)(aTHX_ av);
    calls = 0;
    HAMT_ST(181, v2 != NULL && (A->vec_equal)(aTHX_ v, v2, NULL, NULL) == 1
                 && (A->vec_equal)(aTHX_ v, v2, hamt_st_numeric, &calls) == 1 && calls == 1100);

    obj = (A->vec_to_sv)(aTHX_ v2, NULL);
    v2 = NULL;
    HAMT_ST(182, obj && sv_derived_from(obj, "HAMT::Vector") && (A->vec_from_sv)(aTHX_ obj) != NULL
                 && (A->vec_count)(aTHX_ (A->vec_from_sv)(aTHX_ obj)) == 1100
                 && (A->vec_txn_from_sv)(aTHX_ obj) == NULL && (A->map_from_sv)(aTHX_ obj) == NULL);
    SvREFCNT_dec(obj);
    obj = NULL;
    v2 = (A->vec_copy)(aTHX_ v);
    obj = (A->vec_to_txn_sv)(aTHX_ v2, NULL);
    v2 = (A->vec_txn_from_sv)(aTHX_ obj);
    HAMT_ST(183, obj && v2 && sv_derived_from(obj, "HAMT::Vector::Transient")
                 && (A->vec_push)(aTHX_ v2, one) == HAMT_ABI_OK && (A->vec_count)(aTHX_ v2) == 1101
                 && (A->vec_count)(aTHX_ v) == 1100 && (A->vec_from_sv)(aTHX_ obj) == NULL);
    v2 = NULL;
    SvREFCNT_dec(obj);
    obj = NULL;

  done:
    if (obj) SvREFCNT_dec(obj);
    if (hv) SvREFCNT_dec((SV *)hv);
    if (av) SvREFCNT_dec((SV *)av);
    if (m2) (A->map_release)(aTHX_ m2);
    if (m3) (A->map_release)(aTHX_ m3);
    if (s2) (A->set_release)(aTHX_ s2);
    if (s3) (A->set_release)(aTHX_ s3);
    if (v2) (A->vec_release)(aTHX_ v2);
    if (v3) (A->vec_release)(aTHX_ v3);

    /* What is left is the three that go to Perl. Everything else the walk
     * made has to be gone: m, s and v are three structs and their trees, so
     * let go of copies of those and see that the count comes back to what
     * they alone account for. */
    if (!step) {
        long kept = hamt_live_blocks;
        hamt_map *mc = (A->map_copy)(aTHX_ m), *sc = (A->set_copy)(aTHX_ s);
        hamt_vec *vc = (A->vec_copy)(aTHX_ v);
        (A->map_release)(aTHX_ m);
        (A->set_release)(aTHX_ s);
        (A->vec_release)(aTHX_ v);
        m = mc; s = sc; v = vc;
        if (hamt_live_blocks != kept) step = 190;
    }
    if (!step) {
        *map_out = (A->map_to_sv)(aTHX_ m, NULL);
        *set_out = (A->set_to_sv)(aTHX_ s, NULL);
        *vec_out = (A->vec_to_sv)(aTHX_ v, NULL);
        m = s = NULL;
        v = NULL;
    }
    if (m) (A->map_release)(aTHX_ m);
    if (s) (A->set_release)(aTHX_ s);
    if (v) (A->vec_release)(aTHX_ v);
    FREETMPS;
    LEAVE;
    /* With nothing handed out, the library holds what it held on the way in. */
    if (step && step != 190 && hamt_live_blocks != before) step = -step;
    return step;
}

#undef HAMT_ST

#endif
