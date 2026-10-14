#ifndef HAMT_XS_H
#define HAMT_XS_H

/* Between the XSUBs and the core: what a handle is, what a key is, and how
 * a value goes in. Comes after every core header. */

/* ---- the handle --------------------------------------------------------
 *
 * A container is a blessed reference to a scalar that carries the C struct
 * in ext magic, marked by the address of a vtable in this file.
 *
 * Not a blessed integer. A class whose objects are an address in an IV, with
 * a destructor that frees it, will free whatever integer a caller blesses
 * into it - and a deserialiser fed somebody else's bytes will do that
 * blessing for them. Magic cannot be forged from Perl or carried through a
 * serialiser: an object without it is simply not a container, and every
 * method says so.
 *
 * The struct is released when the scalar is freed, by the vtable, so there
 * is no DESTROY method to call twice or to shadow in a subclass.
 *
 * A new thread does not get the handle. CLONE_SKIP on each class keeps the
 * object from being cloned at all; and if a clone is made some other way,
 * the dup hook empties its magic, so it is dead rather than a second owner
 * of nodes that hold the first interpreter's scalars. */

static int hamt_handle_free(pTHX_ SV *sv, MAGIC *mg) {
    hamt_map *m = (hamt_map *)mg->mg_ptr;
    PERL_UNUSED_ARG(sv);
    if (m) {
        hamt_node *root = m->root;
        mg->mg_ptr = NULL;
        /* The struct goes before the trie: releasing the trie can run a
         * value's DESTROY, and by then there must be nothing half-gone. */
        HAMT_FREE(HAMT_CX, m, sizeof(hamt_map));
        if (root) hamt_node_release(HAMT_CX, root);
    }
    return 0;
}

static int hamt_handle_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param) {
    PERL_UNUSED_CONTEXT;
    PERL_UNUSED_ARG(param);
    mg->mg_ptr = NULL;
    return 0;
}

static MGVTBL hamt_map_vtbl = {
    NULL, NULL, NULL, NULL, hamt_handle_free, NULL, hamt_handle_dup, NULL
};

/* A set is the same struct over the same trie, with entries that carry no
 * value. It has a vtable of its own so that a set is not a map: each class's
 * methods look for their own, and refuse the other's objects by name. */
static MGVTBL hamt_set_vtbl = {
    NULL, NULL, NULL, NULL, hamt_handle_free, NULL, hamt_handle_dup, NULL
};

/* The struct behind an object, or a croak that names the method. `what` is
 * the method, "HAMT::Map::get"; `kind` is the word for the thing, "map". */
static hamt_map *hamt_handle(pTHX_ SV *sv, const MGVTBL *vt, const char *what,
                             const char *kind) {
    if (SvROK(sv) && SvTYPE(SvRV(sv)) >= SVt_PVMG) {
        MAGIC *mg;
        for (mg = SvMAGIC(SvRV(sv)); mg; mg = mg->mg_moremagic) {
            if (mg->mg_type != PERL_MAGIC_ext || mg->mg_virtual != vt) continue;
            if (!mg->mg_ptr)
                croak("%s: this %s belongs to another thread", what, kind);
            return (hamt_map *)mg->mg_ptr;
        }
    }
    croak("%s: not a %s", what, kind);
    return NULL;
}

/* A new object of the class behind `stash`, mortal, holding its own
 * reference to `root`. */
static SV *hamt_handle_new(pTHX_ const MGVTBL *vt, HV *stash, hamt_node *root,
                           size_t count, hamt_map **out, const char *what) {
    hamt_map *m = (hamt_map *)HAMT_ALLOC(HAMT_CX, sizeof(hamt_map));
    SV *inner, *rv;
    MAGIC *mg;

    if (!m) croak("%s: out of memory", what);
    m->root  = root ? hamt_node_retain(root) : NULL;
    m->count = count;

    inner = newSV(0);
    mg = sv_magicext(inner, NULL, PERL_MAGIC_ext, (MGVTBL *)vt, (const char *)m, 0);
    mg->mg_flags |= MGf_DUP;
    rv = sv_2mortal(newRV_noinc(inner));
    sv_bless(rv, stash);
    *out = m;
    return rv;
}

/* The class to bless into: the one named, or the one an object is in. */
static HV *hamt_class_stash(pTHX_ SV *klass) {
    if (SvROK(klass) && SvOBJECT(SvRV(klass))) return SvSTASH(SvRV(klass));
    return gv_stashsv(klass, GV_ADD);
}

/* An update's result was thrown away. Lexical, category `void`. */
static void hamt_void_warn(pTHX_ const char *what) {
    if (ckWARN(WARN_VOID))
        Perl_warner(aTHX_ packWARN(WARN_VOID),
                    "Useless use of %s in void context", what);
}

/* ---- keys --------------------------------------------------------------
 *
 * A key is a string, and two keys are one key exactly when a Perl hash
 * would say so. A hash treats the Latin-1 and the UTF-8 spelling of a
 * string as the same key, by downgrading every key that can be; so does
 * this. What reaches the core is bytes and a flag, and the flag is set only
 * for a key with a character above 0xFF, which cannot be bytes.
 *
 * The scalar is read once: get magic runs, an object's string overload
 * runs, undef warns as it does anywhere. */

typedef struct hamt_key {
    const char *p;
    STRLEN      len;
    int         utf8;
    uint64_t    hash;
} hamt_key;

static void hamt_key_from_sv(pTHX_ SV *sv, hamt_key *k) {
    STRLEN len;
    const char *p = SvPV(sv, len);
    int utf8 = 0;

    if (SvUTF8(sv)) {
        const U8 *s = (const U8 *)p, *e = s + len;
        while (s < e && !(*s & 0x80)) s++;
        if (s < e) {
            /* A copy, because downgrading in place would change the
             * caller's scalar. Mortal, so a croak later cannot leak it. */
            SV *tmp = sv_2mortal(newSVpvn(p, len));
            SvUTF8_on(tmp);
            if (sv_utf8_downgrade(tmp, TRUE))
                p = SvPV(tmp, len);
            else
                utf8 = 1;
        }
    }
    k->p    = p;
    k->len  = len;
    k->utf8 = utf8;
    k->hash = hamt_hash(p, (size_t)len, utf8);
}

/* HeUTF8 arrived in 5.10.1 and the floor is 5.10.0. This is ppport.h's. */
#ifndef HeUTF8
#  define HeUTF8(he) ((HeKLEN(he) == HEf_SVKEY) ? SvUTF8(HeKEY_sv(he)) : (U32)HeKUTF8(he))
#endif

/* The key of a hash entry. A hash already keeps its keys by the rule this
 * library keeps them by - downgraded wherever they can be - so the bytes
 * and the flag are taken as they stand, with no scalar made to hold them.
 * A tied hash hands its key over as a scalar, and that goes the long way. */
static void hamt_key_from_he(pTHX_ HV *hv, HE *he, hamt_key *k) {
    PERL_UNUSED_ARG(hv);
    if (HeKLEN(he) == HEf_SVKEY) { hamt_key_from_sv(aTHX_ HeKEY_sv(he), k); return; }
    k->p    = HeKEY(he);
    k->len  = (STRLEN)HeKLEN(he);
    k->utf8 = HeKUTF8(he) ? 1 : 0;
    k->hash = hamt_hash(k->p, (size_t)k->len, k->utf8);
}

static SV *hamt_key_to_sv(pTHX_ const hamt_entry *e) {
    SV *sv = newSVpvn(e->key, (STRLEN)e->klen);
    if (e->utf8) SvUTF8_on(sv);
    return sv;
}

/* ---- values ------------------------------------------------------------
 *
 * A value is copied on the way in and the copy is made read-only. Every
 * version of the container that holds the entry shares that one scalar, and
 * `get` hands out the scalar itself, so the flag is what makes "this map
 * never changes" true for a caller holding an alias to a value.
 *
 * It is shallow. A stored reference is a read-only reference to something
 * the caller can still change.
 *
 * Before 5.20 a copy-on-write string was marked with the read-only flag
 * and another beside it, and a scalar carrying both was WRITABLE: perl
 * unshared it at the first write. If the copy made here could come back
 * like that, the flag would already be on and would mean nothing. It cannot:
 * newSVsv gives the copy a buffer of its own even when the source is a
 * shared hash key, on every perl from 5.10. That was measured rather than
 * assumed, and t/04-readonly.t reads the stored scalar's flags so that it
 * stays measured. */
static SV *hamt_sv_copy_in(pTHX_ SV *in) {
    SV *c = newSVsv(in);
    SvREADONLY_on(c);
    return c;
}

/* One pair into a handle the caller owns outright: one nobody else has seen
 * yet, or a transient. The trie is changed where it stands wherever the
 * handle is its only holder, and copied where it is shared, so a handle
 * that starts out sharing a root with the map it came from leaves that map
 * alone. The entry it displaces is released last, when the handle already
 * holds the new root: releasing it can run a value's DESTROY, and that may
 * use this very handle.
 *
 * A value that IS the scalar already stored under the key - which is what
 * `$m->set(k => $m->get('k'))` passes - is recognised before anything is
 * copied, and nothing changes. A member already in a set is recognised by
 * the trie itself, which gives the same root back. */
static void hamt_xs_put_key(pTHX_ hamt_map *m, const hamt_key *kp, SV *valsv,
                            const char *what) {
    hamt_key k = *kp;
    hamt_entry *e, *old, *dead;
    SV *copy;
    int added, rc;

    /* Is this the very scalar already stored under the key? Only a scalar
     * that is read-only can be, since every stored one is; so only then is
     * it worth a walk of the trie to find out. */
    if (valsv && SvREADONLY(valsv)) {
        old = hamt_map_find(m->root, k.p, (size_t)k.len, k.utf8, k.hash);
        if (old && old->val == (void *)valsv) return;
    }

    copy = valsv ? hamt_sv_copy_in(aTHX_ valsv) : NULL;
    e = hamt_entry_new(HAMT_CX, k.p, (size_t)k.len, k.utf8, k.hash, (void *)copy);
    if (copy) SvREFCNT_dec(copy);
    if (!e) croak("%s: out of memory", what);

    rc = hamt_map_put_mut(HAMT_CX, &m->root, e, &added, &dead);
    hamt_entry_release(HAMT_CX, e);
    if (rc) croak("%s: out of memory", what);

    m->count += (size_t)added;
    if (dead) hamt_entry_release(HAMT_CX, dead);
}

static void hamt_xs_put(pTHX_ hamt_map *m, SV *keysv, SV *valsv, const char *what) {
    hamt_key k;
    hamt_key_from_sv(aTHX_ keysv, &k);
    hamt_xs_put_key(aTHX_ m, &k, valsv, what);
}

/* One key out of a handle the caller owns outright, the same way. */
static void hamt_xs_del(pTHX_ hamt_map *m, SV *keysv, const char *what) {
    hamt_key k;
    hamt_entry *dead;
    int status;

    hamt_key_from_sv(aTHX_ keysv, &k);
    status = hamt_map_del_mut(HAMT_CX, &m->root, k.p, (size_t)k.len, k.utf8, k.hash, &dead);
    if (status == HAMT_DEL_OOM) croak("%s: out of memory", what);
    if (status == HAMT_DEL_DONE) m->count--;
    if (dead) hamt_entry_release(HAMT_CX, dead);
}

/* ---- calling back into Perl -------------------------------------------
 *
 * A method that calls a sub while it walks holds its own reference to every
 * root it is walking, released by the save stack. The receiver's reference
 * is not enough: the argument stack does not own what is on it, so a
 * callback that drops the last variable holding the map would free the trie
 * under the walk; and the save stack rather than code after the call,
 * because the sub may die.
 *
 * Each call gets a temps frame of its own, so a walk over a million entries
 * holds one call's mortals at a time and not a million calls'. */

static void hamt_xs_root_unref(pTHX_ void *p) {
    hamt_node_release(HAMT_CX, (hamt_node *)p);
}

/* Between an ENTER and its LEAVE. */
static void hamt_xs_hold_root(pTHX_ hamt_node *root) {
    if (!root) return;
    hamt_node_retain(root);
    SAVEDESTRUCTOR_X(hamt_xs_root_unref, root);
}

/* A walk hands its sub a key, or an index, in a scalar. Making a new one
 * for every call is most of what a walk costs beyond the call itself, so
 * one is made for the walk and written over each time - unless the sub
 * kept hold of it, or did something to it that writing over would not
 * undo, in which case that one is the sub's and the walk takes another. So
 * a sub always sees a scalar that is its own to keep or change, as it
 * would if each were fresh. The scalar is a temporary of the walk's frame. */
static SV *hamt_xs_scratch(pTHX_ SV *sv) {
    if (sv && SvREFCNT(sv) == 1 && !SvMAGICAL(sv) && !SvREADONLY(sv) && !SvROK(sv)) return sv;
    return sv_2mortal(newSV(0));
}

static void hamt_xs_need_code(pTHX_ SV *code, const char *what) {
    SvGETMAGIC(code);
    if (!SvROK(code) || SvTYPE(SvRV(code)) != SVt_PVCV)
        croak("%s: not a code reference", what);
}

static SV *hamt_xs_val_sv(pTHX_ const hamt_entry *e) {
    return (e && e->val) ? (SV *)e->val : sv_newmortal();
}

/* ---- calling a sub -------------------------------------------------------
 *
 * Every sub HAMT is given is called on a stack of its own, as perl's sort
 * calls its comparison. Without that, `last` or `next` inside the sub finds
 * the caller's loop on the context stack and jumps to it straight through
 * this C, which never gets control back. On a stack of its own there is no
 * loop to find, so either is an error, caught by G_EVAL like a die; a walk
 * reads it as "stop" or "skip", and anything else throws it again.
 *
 * hamt_xs_call_enter switches to the stack, with $@ localised so that calls
 * that work leave the caller's $@ as it was; hamt_xs_call_leave switches
 * back. A walk does that once around all its calls. */
#define HAMT_XS_RETURNED 0
#define HAMT_XS_LAST     1
#define HAMT_XS_NEXT     2
#define HAMT_XS_DIED     3

static void hamt_xs_call_enter(pTHX) {
    dSP;
    ENTER;
    save_scalar(PL_errgv);
    PUSHSTACKi(PERLSI_UNKNOWN);
    PERL_UNUSED_VAR(sp);
}

static void hamt_xs_call_leave(pTHX) {
    dSP;
    POPSTACK;
    PERL_UNUSED_VAR(sp);
    LEAVE;
}

/* A walk takes `last` and `next` from its sub, so it enters with a warning
 * filter in $SIG{__WARN__}: perl warns "Exiting eval via last" about the
 * G_EVAL frame, which is this library's and not the sub's. The filter drops
 * that and hands everything else to the hook it replaced, kept in
 * $HAMT::_warn_prev, or to perl. "Exiting subroutine via last" is perl's
 * warning for any sub that does it, and is kept. */
#ifndef PERL_WARNHOOK_FATAL
#  define PERL_WARNHOOK_FATAL (&PL_sv_placeholder)
#endif

static void hamt_xs_walk_enter(pTHX) {
    CV *filter = get_cv("HAMT::_warn_filter", 0);
    hamt_xs_call_enter(aTHX);
    if (filter && PL_warnhook != PERL_WARNHOOK_FATAL
        && !(PL_warnhook && SvROK(PL_warnhook) && SvRV(PL_warnhook) == (SV *)filter)) {
        GV *gv = gv_fetchpvs("HAMT::_warn_prev", GV_ADD, SVt_PV);
        save_scalar(gv);
        if (PL_warnhook) sv_setsv(GvSV(gv), PL_warnhook);
        SAVEGENERICSV(PL_warnhook);
        PL_warnhook = newRV_inc((SV *)filter);
    }
}

static int hamt_xs_loop_error(pTHX_ SV *err, const char *what, STRLEN len) {
    STRLEN elen;
    const char *p;
    if (SvROK(err)) return 0;
    p = SvPV(err, elen);
    return elen >= len && memEQ(p, what, len);
}

#define HAMT_XS_ERR_LAST "Can't \"last\" outside a loop block"
#define HAMT_XS_ERR_NEXT "Can't \"next\" outside a loop block"

/* Calls the sub with the arguments, between hamt_xs_call_enter and _leave.
 * When `res` is given the call is in scalar context and the result is put
 * there, a temporary of the caller's frame. A die leaves its error in $@. */
static int hamt_xs_call(pTHX_ SV *code, SV **args, int nargs, SV **res) {
    dSP;
    I32 n;
    int i;
    SV *err;

    PUSHMARK(SP);
    EXTEND(SP, nargs);
    for (i = 0; i < nargs; i++) PUSHs(args[i]);
    PUTBACK;
    n = call_sv(code, (res ? G_SCALAR : G_DISCARD | G_VOID) | G_EVAL);
    SPAGAIN;
    if (res) *res = n > 0 ? *SP : &PL_sv_undef;
    SP -= n;
    PUTBACK;
    err = ERRSV;
    if (!SvTRUE(err)) return HAMT_XS_RETURNED;
    if (hamt_xs_loop_error(aTHX_ err, HAMT_XS_ERR_LAST, sizeof(HAMT_XS_ERR_LAST) - 1))
        return HAMT_XS_LAST;
    if (hamt_xs_loop_error(aTHX_ err, HAMT_XS_ERR_NEXT, sizeof(HAMT_XS_ERR_NEXT) - 1))
        return HAMT_XS_NEXT;
    return HAMT_XS_DIED;
}

/* A copy of $@ that outlives hamt_xs_call_leave, or NULL when the call
 * returned or a walk takes `last` and `next` as stop and skip. */
static SV *hamt_xs_call_err(pTHX_ int how, int walk) {
    if (how == HAMT_XS_RETURNED || (walk && how != HAMT_XS_DIED)) return NULL;
    return newSVsv(ERRSV);
}

/* Throws a copy from hamt_xs_call_err, object or string, exactly as it was. */
static void hamt_xs_rethrow(pTHX_ SV *err) {
    sv_setsv(ERRSV, err);
    SvREFCNT_dec(err);
    croak(NULL);
}

/* equals with a comparison sub: called with the two values, true or false.
 * Nothing is allocated across the call, so an error is thrown again from
 * here, through the comparison. */
static int hamt_xs_eq_cb(void *ud, void *cx, void *va, void *vb) {
    dTHXa(cx);
    SV *args[2], *res, *err;
    int truth;

    PERL_UNUSED_ARG(cx);
    args[0] = (SV *)va;
    args[1] = (SV *)vb;
    ENTER;
    SAVETMPS;
    hamt_xs_call_enter(aTHX);
    err = hamt_xs_call_err(aTHX_ hamt_xs_call(aTHX_ (SV *)ud, args, 2, &res), 0);
    truth = !err && SvTRUE(res) ? 1 : 0;
    hamt_xs_call_leave(aTHX);
    FREETMPS;
    LEAVE;
    if (err) hamt_xs_rethrow(aTHX_ err);
    return truth;
}

/* merge with a resolver: called with the key and the two values, and what
 * it returns is the value the result holds.
 *
 * This one runs under G_EVAL. The merge is half way through building nodes
 * when it calls, and a die that jumped out past it would leak every one of
 * them; so the error is caught and kept, the merge is told to stop and
 * unwinds what it built, and the caller dies again with the same error.
 * diff keeps its error the same way. */
typedef struct hamt_xs_sub {
    SV *code;
    SV *err;
} hamt_xs_sub;

static int hamt_xs_resolve_cb(void *ud, void *cx, hamt_entry *ea, hamt_entry *eb,
                              hamt_entry **out) {
    dTHXa(cx);
    hamt_xs_sub *r = (hamt_xs_sub *)ud;
    SV *args[3], *res;
    int rc = HAMT_OK;

    ENTER;
    SAVETMPS;
    args[0] = sv_2mortal(hamt_key_to_sv(aTHX_ ea));
    args[1] = hamt_xs_val_sv(aTHX_ ea);
    args[2] = hamt_xs_val_sv(aTHX_ eb);
    hamt_xs_call_enter(aTHX);
    r->err = hamt_xs_call_err(aTHX_ hamt_xs_call(aTHX_ r->code, args, 3, &res), 0);
    hamt_xs_call_leave(aTHX);

    if (r->err) {
        rc = HAMT_ERR_ABORT;
    }
    /* What a sub returns is always a copy, so "it gave back the one it was
     * handed" cannot be seen by address. It is seen by value, as `equals`
     * compares values, and then the entry already there is kept: that is
     * what lets a merge that changes nothing return the map it started from. */
    else if (ea->val && hamt_sv_eq_cx(cx, res, (SV *)ea->val)) *out = hamt_entry_retain(ea);
    else if (eb->val && hamt_sv_eq_cx(cx, res, (SV *)eb->val)) *out = hamt_entry_retain(eb);
    else {
        SV *copy = hamt_sv_copy_in(aTHX_ res);
        *out = hamt_entry_new(cx, ea->key, ea->klen, ea->utf8, ea->hash, (void *)copy);
        SvREFCNT_dec(copy);
        if (!*out) rc = HAMT_ERR_OOM;
    }

    FREETMPS;
    LEAVE;
    return rc;
}

/* diff: called with the key, the value it had, the value it has, and one of
 * 'add', 'remove', 'change'. A walk: `last` stops it, `next` goes on. The
 * caller is between hamt_xs_call_enter and _leave; an error stops the walk
 * and is kept for the caller to throw once it has left. */
static int hamt_xs_diff_cb(void *ud, void *cx, int kind, hamt_entry *ea,
                           hamt_entry *eb) {
    dTHXa(cx);
    static const char *const name[4] = { "", "add", "remove", "change" };
    hamt_xs_sub *r = (hamt_xs_sub *)ud;
    SV *args[4];
    int how;

    PERL_UNUSED_ARG(cx);
    ENTER;
    SAVETMPS;
    args[0] = sv_2mortal(hamt_key_to_sv(aTHX_ ea ? ea : eb));
    args[1] = hamt_xs_val_sv(aTHX_ ea);
    args[2] = hamt_xs_val_sv(aTHX_ eb);
    args[3] = sv_2mortal(newSVpv(name[kind], 0));
    how = hamt_xs_call(aTHX_ r->code, args, 4, NULL);
    r->err = hamt_xs_call_err(aTHX_ how, 1);
    FREETMPS;
    LEAVE;
    return how == HAMT_XS_LAST || r->err;
}

/* The struct behind an object, or NULL: for a method that takes "something
 * that may be a map" and has an answer when it is not. */
static hamt_map *hamt_handle_try(pTHX_ SV *sv, const MGVTBL *vt) {
    if (SvROK(sv) && SvTYPE(SvRV(sv)) >= SVt_PVMG) {
        MAGIC *mg;
        for (mg = SvMAGIC(SvRV(sv)); mg; mg = mg->mg_moremagic)
            if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == vt)
                return (hamt_map *)mg->mg_ptr;
    }
    return NULL;
}

/* ---- transients ---------------------------------------------------------
 *
 * A transient is a handle that IS updated in place: the same put and delete
 * as everywhere else, on a handle that lives across calls. It starts out
 * sharing its root with the map it was opened from, so its first updates
 * copy and that map is untouched; `persistent` hands the root to a new map
 * and closes the transient, so nothing can reach the root through it again.
 *
 * It remembers the class of the map it came from, to make its result one. */

typedef struct hamt_txn {
    hamt_map m;         /* first, so a transient can be updated as a map is */
    HV      *origin;    /* the class `persistent` blesses into */
    int      open;
} hamt_txn;

static int hamt_txn_free(pTHX_ SV *sv, MAGIC *mg) {
    hamt_txn *t = (hamt_txn *)mg->mg_ptr;
    PERL_UNUSED_ARG(sv);
    if (t) {
        hamt_node *root = t->m.root;
        HV *origin = t->origin;
        mg->mg_ptr = NULL;
        HAMT_FREE(HAMT_CX, t, sizeof(hamt_txn));
        if (origin && !PL_dirty) SvREFCNT_dec((SV *)origin);
        if (root) hamt_node_release(HAMT_CX, root);
    }
    return 0;
}

static MGVTBL hamt_map_txn_vtbl = {
    NULL, NULL, NULL, NULL, hamt_txn_free, NULL, hamt_handle_dup, NULL
};

static MGVTBL hamt_set_txn_vtbl = {
    NULL, NULL, NULL, NULL, hamt_txn_free, NULL, hamt_handle_dup, NULL
};

/* The struct behind a transient that is still open, or a croak. */
static hamt_txn *hamt_txn_handle(pTHX_ SV *sv, const MGVTBL *vt, const char *what) {
    if (SvROK(sv) && SvTYPE(SvRV(sv)) >= SVt_PVMG) {
        MAGIC *mg;
        for (mg = SvMAGIC(SvRV(sv)); mg; mg = mg->mg_moremagic) {
            hamt_txn *t;
            if (mg->mg_type != PERL_MAGIC_ext || mg->mg_virtual != vt) continue;
            t = (hamt_txn *)mg->mg_ptr;
            if (!t) croak("%s: this transient belongs to another thread", what);
            if (!t->open) croak("%s: this transient is closed", what);
            return t;
        }
    }
    croak("%s: not a transient", what);
    return NULL;
}

static SV *hamt_txn_new(pTHX_ const MGVTBL *vt, const char *klass, HV *origin,
                        hamt_node *root, size_t count, const char *what) {
    hamt_txn *t = (hamt_txn *)HAMT_ALLOC(HAMT_CX, sizeof(hamt_txn));
    SV *inner, *rv;
    MAGIC *mg;

    if (!t) croak("%s: out of memory", what);
    t->m.root  = root ? hamt_node_retain(root) : NULL;
    t->m.count = count;
    t->origin  = (HV *)SvREFCNT_inc_simple_NN((SV *)origin);
    t->open    = 1;

    inner = newSV(0);
    mg = sv_magicext(inner, NULL, PERL_MAGIC_ext, (MGVTBL *)vt, (const char *)t, 0);
    mg->mg_flags |= MGf_DUP;
    rv = sv_2mortal(newRV_noinc(inner));
    sv_bless(rv, gv_stashpv(klass, GV_ADD));
    return rv;
}

/* ---- the vector's handle -------------------------------------------------
 *
 * The same arrangement as a map's, around a hamt_vec: a blessed reference
 * whose scalar carries the struct in magic marked by a vtable of its own. */

static int hamt_vec_handle_free(pTHX_ SV *sv, MAGIC *mg) {
    hamt_vec *v = (hamt_vec *)mg->mg_ptr;
    PERL_UNUSED_ARG(sv);
    if (v) {
        hamt_vec gone = *v;
        mg->mg_ptr = NULL;
        HAMT_FREE(HAMT_CX, v, sizeof(hamt_vec));
        hamt_vec_clear(HAMT_CX, &gone);
    }
    return 0;
}

static MGVTBL hamt_vec_vtbl = {
    NULL, NULL, NULL, NULL, hamt_vec_handle_free, NULL, hamt_handle_dup, NULL
};

static hamt_vec *hamt_vec_handle(pTHX_ SV *sv, const char *what) {
    if (SvROK(sv) && SvTYPE(SvRV(sv)) >= SVt_PVMG) {
        MAGIC *mg;
        for (mg = SvMAGIC(SvRV(sv)); mg; mg = mg->mg_moremagic) {
            if (mg->mg_type != PERL_MAGIC_ext || mg->mg_virtual != &hamt_vec_vtbl) continue;
            if (!mg->mg_ptr) croak("%s: this vector belongs to another thread", what);
            return (hamt_vec *)mg->mg_ptr;
        }
    }
    croak("%s: not a vector", what);
    return NULL;
}

static hamt_vec *hamt_vec_handle_try(pTHX_ SV *sv) {
    if (SvROK(sv) && SvTYPE(SvRV(sv)) >= SVt_PVMG) {
        MAGIC *mg;
        for (mg = SvMAGIC(SvRV(sv)); mg; mg = mg->mg_moremagic)
            if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == &hamt_vec_vtbl)
                return (hamt_vec *)mg->mg_ptr;
    }
    return NULL;
}

/* A new object, mortal, onto the same vector as `src`, or onto an empty one. */
static SV *hamt_vec_handle_new(pTHX_ HV *stash, const hamt_vec *src, hamt_vec **out,
                               const char *what) {
    hamt_vec *v = (hamt_vec *)HAMT_ALLOC(HAMT_CX, sizeof(hamt_vec));
    SV *inner, *rv;
    MAGIC *mg;

    if (!v) croak("%s: out of memory", what);
    if (src) hamt_vec_share(v, src);
    else     hamt_vec_init(v);

    inner = newSV(0);
    mg = sv_magicext(inner, NULL, PERL_MAGIC_ext, &hamt_vec_vtbl, (const char *)v, 0);
    mg->mg_flags |= MGf_DUP;
    rv = sv_2mortal(newRV_noinc(inner));
    sv_bless(rv, stash);
    *out = v;
    return rv;
}

/* A walk that calls Perl holds a struct of its own onto the vector, released
 * by the save stack: what the sub does to the object, or to the last
 * variable holding it, cannot reach the nodes being walked. Between an
 * ENTER and its LEAVE. */
static void hamt_xs_vec_unhold(pTHX_ void *p) {
    hamt_vec *v = (hamt_vec *)p;
    hamt_vec gone = *v;
    HAMT_FREE(HAMT_CX, v, sizeof(hamt_vec));
    hamt_vec_clear(HAMT_CX, &gone);
}

static hamt_vec *hamt_xs_hold_vec(pTHX_ const hamt_vec *src, const char *what) {
    hamt_vec *v = (hamt_vec *)HAMT_ALLOC(HAMT_CX, sizeof(hamt_vec));
    if (!v) croak("%s: out of memory", what);
    hamt_vec_share(v, src);
    SAVEDESTRUCTOR_X(hamt_xs_vec_unhold, v);
    return v;
}

/* An index as an array takes one: negative counts from the end. 1 and the
 * position when it names an element, 0 when it does not. */
static int hamt_xs_index(pTHX_ SV *sv, size_t count, size_t *out) {
    IV i = SvIV(sv);
    if (i < 0) {
        if ((UV)(-(i + 1)) >= (UV)count) return 0;
        *out = count - (size_t)(-(i + 1)) - 1;
        return 1;
    }
    if ((UV)i >= (UV)count) return 0;
    *out = (size_t)i;
    return 1;
}

/* One value onto the end of a vector the caller owns outright. Copied and
 * made read-only on the way in, as a map's values are. */
static void hamt_xs_vec_push(pTHX_ hamt_vec *v, SV *valsv, const char *what) {
    SV *copy = hamt_sv_copy_in(aTHX_ valsv);
    int rc = hamt_vec_push(HAMT_CX, v, (void *)copy);
    SvREFCNT_dec(copy);
    if (rc) croak("%s: out of memory", what);
}

/* One value replaced, likewise. A value that IS the scalar already there
 * changes nothing. The scalar it displaces is released last. */
static void hamt_xs_vec_set(pTHX_ hamt_vec *v, size_t i, SV *valsv, const char *what) {
    SV *copy;
    void *dead;
    int rc;

    if (hamt_vec_get(v, i) == (void *)valsv) return;
    copy = hamt_sv_copy_in(aTHX_ valsv);
    rc = hamt_vec_set(HAMT_CX, v, i, (void *)copy, &dead);
    SvREFCNT_dec(copy);
    if (rc) croak("%s: out of memory", what);
    if (dead) HAMT_VAL_RELEASE(HAMT_CX, dead);
}

static void hamt_xs_vec_pop(pTHX_ hamt_vec *v, const char *what) {
    void *dead;
    if (hamt_vec_pop(HAMT_CX, v, &dead)) croak("%s: out of memory", what);
    if (dead) HAMT_VAL_RELEASE(HAMT_CX, dead);
}

/* `out`, which must be empty, becomes `v` with the `drop` values from `at`
 * taken out and everything in `mid` put in their place: the one operation
 * behind insert and remove. `mid` may be NULL. It is two cuts and two
 * joins, and no Perl runs in it, so the pieces are plain structs cleaned up
 * here. */
static void hamt_xs_vec_splice(pTHX_ hamt_vec *out, const hamt_vec *v, size_t at,
                               size_t drop, const hamt_vec *mid, const char *what) {
    hamt_vec left, right, joined, res;
    size_t after = at + drop;
    int rc = 0;

    hamt_vec_init(&left);
    hamt_vec_init(&right);
    hamt_vec_init(&joined);
    hamt_vec_init(&res);

    if (at > 0) rc = hamt_vec_slice(HAMT_CX, &left, v, 0, at);
    if (!rc && after < v->count) rc = hamt_vec_slice(HAMT_CX, &right, v, after, v->count - after);
    if (!rc) {
        if (mid) rc = hamt_vec_concat(HAMT_CX, &joined, &left, mid);
        else     hamt_vec_share(&joined, &left);
    }
    if (!rc) rc = hamt_vec_concat(HAMT_CX, &res, &joined, &right);

    hamt_vec_clear(HAMT_CX, &left);
    hamt_vec_clear(HAMT_CX, &right);
    hamt_vec_clear(HAMT_CX, &joined);
    if (rc) croak("%s: out of memory", what);
    *out = res;
}

/* Where an insert goes: 0 up to the count itself, which is the end; a
 * negative one counts from the end, so that -1 is before the last value,
 * as splice has it. 1 and the position, or 0. */
static int hamt_xs_gap(pTHX_ SV *sv, size_t count, size_t *out) {
    IV i = SvIV(sv);
    if (i < 0) {
        if ((UV)(-(i + 1)) >= (UV)count) return 0;
        *out = count - (size_t)(-(i + 1)) - 1;
        return 1;
    }
    if ((UV)i > (UV)count) return 0;
    *out = (size_t)i;
    return 1;
}

/* The vector's transient: the struct, the class it closes into, and whether
 * it is still open. */
typedef struct hamt_vtxn {
    hamt_vec v;
    HV      *origin;
    int      open;
} hamt_vtxn;

static int hamt_vtxn_free(pTHX_ SV *sv, MAGIC *mg) {
    hamt_vtxn *t = (hamt_vtxn *)mg->mg_ptr;
    PERL_UNUSED_ARG(sv);
    if (t) {
        hamt_vec gone = t->v;
        HV *origin = t->origin;
        mg->mg_ptr = NULL;
        HAMT_FREE(HAMT_CX, t, sizeof(hamt_vtxn));
        if (origin && !PL_dirty) SvREFCNT_dec((SV *)origin);
        hamt_vec_clear(HAMT_CX, &gone);
    }
    return 0;
}

static MGVTBL hamt_vec_txn_vtbl = {
    NULL, NULL, NULL, NULL, hamt_vtxn_free, NULL, hamt_handle_dup, NULL
};

static hamt_vtxn *hamt_vtxn_handle(pTHX_ SV *sv, const char *what) {
    if (SvROK(sv) && SvTYPE(SvRV(sv)) >= SVt_PVMG) {
        MAGIC *mg;
        for (mg = SvMAGIC(SvRV(sv)); mg; mg = mg->mg_moremagic) {
            hamt_vtxn *t;
            if (mg->mg_type != PERL_MAGIC_ext || mg->mg_virtual != &hamt_vec_txn_vtbl) continue;
            t = (hamt_vtxn *)mg->mg_ptr;
            if (!t) croak("%s: this transient belongs to another thread", what);
            if (!t->open) croak("%s: this transient is closed", what);
            return t;
        }
    }
    croak("%s: not a transient", what);
    return NULL;
}

#endif
