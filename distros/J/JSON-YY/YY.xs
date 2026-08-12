#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Under PERL_IMPLICIT_SYS (Windows/Strawberry Perl) perl.h remaps the libc
   allocator names to function-like PerlMem_* macros. yyjson's allocator
   struct has members literally named malloc/realloc/free, and yyjson.h's
   inline code calls them as `alc.free(ctx, ptr)` -- the macro then sees two
   args and the build dies ("PerlMem_free passed 2 arguments"). Restore the
   real libc names before including yyjson; the bundled yyjson uses the libc
   allocator and yyjson_free_buf() below releases its buffers with libc free(),
   so the names must agree. */
#undef malloc
#undef realloc
#undef calloc
#undef free

#include "yyjson.h"
#include "XSParseKeyword.h"

#include <string.h>

/* flags stored in the JSON::YY object (IV inside the hash) */
#define F_UTF8            0x01
#define F_PRETTY          0x02
#define F_CANONICAL       0x04
#define F_ALLOW_NONREF    0x08
#define F_ALLOW_UNKNOWN   0x10
#define F_ALLOW_BLESSED   0x20
#define F_CONVERT_BLESSED 0x40

#define MAX_DEPTH_DEFAULT 512

typedef struct {
    U32 flags;
    U32 max_depth;
} json_yy_t;

/* ---- ithreads ----
   perl_clone() copies mg_ptr verbatim, so without an svt_dup a live handle is
   owned by two interpreters and freed twice. Coders are copied; docs and
   iterators cannot be, so their clones are emptied and using one croaks. */
static int
json_yy_dup_disown(pTHX_ MAGIC *mg, CLONE_PARAMS *param) {
    PERL_UNUSED_ARG(param);
    mg->mg_ptr = NULL;
    return 0;
}

/* handle that came out of a thread clone */
#define CHECK_CLONED(mg, what)                                  \
    STMT_START {                                                \
        if (!(mg)->mg_ptr)                                      \
            croak(what " cannot be shared between threads");    \
    } STMT_END

/* sv_magicext() does not derive MGf_DUP from the vtable, and perl_clone()
   only calls svt_dup when it is set. */
static inline MAGIC *
attach_ext_magic(pTHX_ SV *sv, const MGVTBL *vtbl, void *ptr) {
    MAGIC *mg = sv_magicext(sv, NULL, PERL_MAGIC_ext, vtbl,
                            (const char *)ptr, 0);
    mg->mg_flags |= MGf_DUP;
    return mg;
}

/* magic vtable for json_yy_t stored on HV */
static int
json_yy_magic_free(pTHX_ SV *sv, MAGIC *mg) {
    PERL_UNUSED_ARG(sv);
    if (mg->mg_ptr)
        Safefree(mg->mg_ptr);
    return 0;
}

static int
json_yy_magic_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param) {
    PERL_UNUSED_ARG(param);
    if (mg->mg_ptr) {
        json_yy_t *copy;
        Newx(copy, 1, json_yy_t);
        *copy = *(json_yy_t *)mg->mg_ptr;
        mg->mg_ptr = (char *)copy;
    }
    return 0;
}

static MGVTBL json_yy_vtbl = {
    NULL, NULL, NULL, NULL,
    json_yy_magic_free,
    NULL, json_yy_magic_dup, NULL
};

static inline json_yy_t *
get_self(pTHX_ SV *self_sv) {
    if (!SvROK(self_sv))
        croak("not a JSON::YY object");
    MAGIC *mg = mg_findext(SvRV(self_sv), PERL_MAGIC_ext, &json_yy_vtbl);
    if (!mg)
        croak("not a JSON::YY object");
    CHECK_CLONED(mg, "JSON::YY object");
    return (json_yy_t *)mg->mg_ptr;
}

static MGVTBL empty_vtbl = {0};

/* forward declarations */
static inline int is_ascii(const char *s, size_t len);

/* Characters of `sv` as UTF-8 without touching the caller's scalar: SvPVutf8()
   upgrades in place, so `jdoc $body` would leave $body a character string and
   break a later decode_json($body). Only latin-1 high bytes need the copy. */
static const char *
sv_pv_utf8_nomod(pTHX_ SV *sv, STRLEN *lenp) {
    SvGETMAGIC(sv);
    const char *s = SvPV_nomg(sv, *lenp);
    if (SvUTF8(sv) || is_ascii(s, *lenp))
        return s;
    SV *tmp = sv_2mortal(newSVpvn(s, *lenp));
    sv_utf8_upgrade(tmp);
    return SvPV_const(tmp, *lenp);
}

/* Immutable parse buffer behind decode_json_ro, refcounted: its SVs are
   zero-copy (SvLEN 0) and perl_clone() shares those PV pointers rather than
   copying, so an emptied clone would read freed memory. Deliberately shared
   between interpreters, so it uses libc malloc/free rather than perl's
   per-interpreter pool -- Newx/Safefree here is "Free to wrong pool" under
   PERL_IMPLICIT_SYS. */
typedef struct {
    yyjson_doc *doc;
    U32 refcnt;
} json_yy_ro_t;

#ifdef USE_ITHREADS
static perl_mutex json_yy_ro_mutex;
static int json_yy_ro_mutex_ready = 0;
#  define RO_LOCK()   MUTEX_LOCK(&json_yy_ro_mutex)
#  define RO_UNLOCK() MUTEX_UNLOCK(&json_yy_ro_mutex)
#else
#  define RO_LOCK()   NOOP
#  define RO_UNLOCK() NOOP
#endif

/* doc holder magic: frees yyjson_doc when the last reference goes */
static int
docholder_magic_free(pTHX_ SV *sv, MAGIC *mg) {
    PERL_UNUSED_ARG(sv);
    json_yy_ro_t *h = (json_yy_ro_t *)mg->mg_ptr;
    if (h) {
        int last;
        RO_LOCK();
        last = (--h->refcnt == 0);
        RO_UNLOCK();
        if (last) {
            yyjson_doc_free(h->doc);
            free(h);
        }
    }
    return 0;
}

static int
docholder_magic_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param) {
    PERL_UNUSED_ARG(param);
    json_yy_ro_t *h = (json_yy_ro_t *)mg->mg_ptr;
    if (h) {
        RO_LOCK();
        h->refcnt++;
        RO_UNLOCK();
    }
    return 0;
}

/* magic free for a yyjson_mut_doc holder: frees the doc when its SV dies */
static int
mut_docholder_magic_free(pTHX_ SV *sv, MAGIC *mg) {
    PERL_UNUSED_ARG(sv);
    yyjson_mut_doc *doc = (yyjson_mut_doc *)mg->mg_ptr;
    if (doc)
        yyjson_mut_doc_free(doc);
    return 0;
}

static MGVTBL docholder_magic_vtbl = {
    NULL, NULL, NULL, NULL,
    docholder_magic_free,
    NULL, docholder_magic_dup, NULL
};

static MGVTBL mut_docholder_vtbl = {
    NULL, NULL, NULL, NULL,
    mut_docholder_magic_free,
    NULL, json_yy_dup_disown, NULL
};

/* free() a yyjson-allocated (libc malloc) buffer at scope exit, so the buffer
   is released even if the newSVpvn that copies it croaks on OOM. Used via
   ENTER/SAVEDESTRUCTOR_X(...)/LEAVE around the copy. */
static void yyjson_free_buf(pTHX_ void *p) { free(p); }

/* yyjson parses integers as 64-bit. On 32-bit-IV perls a straight cast to
   IV/UV truncates, so fall back to an NV when the value doesn't fit. The #if
   compiles this out on 64-bit-IV builds (the common case). */
static inline SV * sv_from_u64(pTHX_ uint64_t u) {
#if UVSIZE < 8
    if (u > (uint64_t)UV_MAX) return newSVnv((NV)u);
#endif
    return newSVuv((UV)u);
}
static inline SV * sv_from_i64(pTHX_ int64_t i) {
#if IVSIZE < 8
    if (i < (int64_t)IV_MIN || i > (int64_t)IV_MAX) return newSVnv((NV)i);
#endif
    return newSViv((IV)i);
}

/* Decode a yyjson number (UINT/SINT/REAL) to a fresh SV via the width-safe int
   helpers above. Two variants for immutable and mutable yyjson values. */
static inline SV * yyjson_num_to_sv(pTHX_ yyjson_val *val) {
    yyjson_subtype st = yyjson_get_subtype(val);
    if (st == YYJSON_SUBTYPE_UINT) return sv_from_u64(aTHX_ yyjson_get_uint(val));
    if (st == YYJSON_SUBTYPE_SINT) return sv_from_i64(aTHX_ yyjson_get_sint(val));
    return newSVnv(yyjson_get_real(val));
}
static inline SV * yyjson_mut_num_to_sv(pTHX_ yyjson_mut_val *val) {
    yyjson_subtype st = yyjson_mut_get_subtype(val);
    if (st == YYJSON_SUBTYPE_UINT) return sv_from_u64(aTHX_ yyjson_mut_get_uint(val));
    if (st == YYJSON_SUBTYPE_SINT) return sv_from_i64(aTHX_ yyjson_mut_get_sint(val));
    return newSVnv(yyjson_mut_get_real(val));
}

/* Reject a parsed document nested deeper than `limit`: our materialisers
   recurse, as do the copy/equals routines behind jclone/jwrite/jeq. Immutable
   values sit flat in document order (uni.ofs skips a subtree), so one linear
   pass with a stack of end pointers measures depth without recursing. */
static int
doc_too_deep(pTHX_ yyjson_doc *doc, U32 limit) {
    yyjson_val *val = doc->root;
    if (!val || !unsafe_yyjson_is_ctn(val))
        return 0;

    yyjson_val *end = unsafe_yyjson_get_next(val);
    yyjson_val **stack;
    U32 cap = 64, depth = 0;
    int too_deep = 0;

    Newx(stack, cap, yyjson_val *);
    for (; val < end; val++) {
        while (depth && val >= stack[depth - 1]) depth--;
        if (unsafe_yyjson_is_ctn(val)) {
            if (depth >= limit) { too_deep = 1; break; }
            yyjson_val *sub_end = unsafe_yyjson_get_next(val);
            /* an n-slot subtree cannot nest deeper than n levels, so small
               ones are provably fine and get skipped whole */
            if ((size_t)(sub_end - val) <= (size_t)(limit - depth)) {
                val = sub_end - 1;   /* the loop's ++ lands on sub_end */
                continue;
            }
            if (depth == cap) { cap *= 2; Renew(stack, cap, yyjson_val *); }
            stack[depth++] = sub_end;
        }
    }
    Safefree(stack);
    return too_deep;
}

/* frees the document before croaking */
#define CHECK_DOC_DEPTH(doc, limit, what)          \
    STMT_START {                                   \
        if (doc_too_deep(aTHX_ (doc), (limit))) {  \
            yyjson_doc_free(doc);                  \
            croak(what ": maximum nesting depth exceeded"); \
        }                                          \
    } STMT_END

/* The materialisers return NULL when the depth budget runs out rather than
   croaking mid-build, so the caller drops the partial structure with one
   SvREFCNT_dec. */
static SV * yyjson_val_to_sv(pTHX_ yyjson_val *val, U32 budget);
static SV * yyjson_val_to_sv_ro(pTHX_ yyjson_val *val, SV *doc_sv, U32 budget);
static yyjson_mut_val * sv_to_yyjson_val(pTHX_ yyjson_mut_doc *doc, SV *sv,
                                          json_yy_t *self, U32 depth);

/* ---- JSON::YY::Doc -- opaque yyjson mutable document handle ---- */

typedef struct {
    yyjson_mut_doc *doc;   /* the mutable document */
    yyjson_mut_val *root;  /* value this handle points at (may be subtree) */
    SV *owner;             /* NULL=owns doc, non-NULL=RV to parent Doc (borrowed) */
} json_yy_doc_t;

static int
json_yy_doc_magic_free(pTHX_ SV *sv, MAGIC *mg) {
    PERL_UNUSED_ARG(sv);
    json_yy_doc_t *d = (json_yy_doc_t *)mg->mg_ptr;
    if (d) {
        if (d->owner) {
            SvREFCNT_dec(d->owner);
        } else {
            if (d->doc)
                yyjson_mut_doc_free(d->doc);
        }
        Safefree(d);
    }
    return 0;
}

static MGVTBL json_yy_doc_vtbl = {
    NULL, NULL, NULL, NULL,
    json_yy_doc_magic_free,
    NULL, json_yy_dup_disown, NULL
};

static inline json_yy_doc_t *
get_doc(pTHX_ SV *sv) {
    if (!SvROK(sv))
        croak("not a JSON::YY::Doc object");
    MAGIC *mg = mg_findext(SvRV(sv), PERL_MAGIC_ext, &json_yy_doc_vtbl);
    if (!mg)
        croak("not a JSON::YY::Doc object");
    CHECK_CLONED(mg, "JSON::YY::Doc");
    return (json_yy_doc_t *)mg->mg_ptr;
}

/* create a new Doc SV. if owner is non-NULL, this is a borrowing ref. */
static SV *
new_doc_sv(pTHX_ yyjson_mut_doc *doc, yyjson_mut_val *root, SV *owner) {
    json_yy_doc_t *d;
    HV *hv = newHV();
    Newxz(d, 1, json_yy_doc_t);
    d->doc = doc;
    d->root = root;
    if (owner) {
        d->owner = owner;
        SvREFCNT_inc_simple_void_NN(owner);
    }
    attach_ext_magic(aTHX_ (SV *)hv, &json_yy_doc_vtbl, d);
    return sv_bless(newRV_noinc((SV *)hv),
                    gv_stashpvs("JSON::YY::Doc", GV_ADD));
}

/* resolve a path on a Doc, returning the yyjson_mut_val* or NULL.
   path must be UTF-8 encoded (use sv_pv_utf8_nomod on caller side). */
static inline yyjson_mut_val *
doc_resolve_path(pTHX_ json_yy_doc_t *d, const char *path, STRLEN path_len) {
    if (path_len == 0)
        return d->root;
    return yyjson_mut_ptr_getn(d->root, path, path_len);
}


/* forward decl */
static SV * yyjson_mut_val_to_sv(pTHX_ yyjson_mut_val *val, U32 budget);

/* ---- keyword plugin: Doc keyword ops ---- */

/* pp_jdoc: parse JSON string → Doc */
static OP * pp_jdoc_impl(pTHX) {
    dSP;
    SV *json_sv = POPs;
    STRLEN len;
    const char *json = sv_pv_utf8_nomod(aTHX_ json_sv, &len);

    yyjson_read_err err;
    yyjson_doc *idoc = yyjson_read_opts((char *)json, len, YYJSON_READ_NOFLAG, NULL, &err);
    if (!idoc)
        croak("jdoc: JSON parse error: %s at byte offset %zu", err.msg, err.pos);
    CHECK_DOC_DEPTH(idoc, MAX_DEPTH_DEFAULT, "jdoc");

    yyjson_mut_doc *mdoc = yyjson_doc_mut_copy(idoc, NULL);
    yyjson_doc_free(idoc);
    if (!mdoc)
        croak("jdoc: failed to create mutable document");

    yyjson_mut_val *root = yyjson_mut_doc_get_root(mdoc);
    SV *result = new_doc_sv(aTHX_ mdoc, root, NULL);
    XPUSHs(sv_2mortal(result));
    RETURN;
}

/* pp_jget: get subtree ref (borrowing) */
static OP * pp_jget_impl(pTHX) {
    dSP;
    SV *path_sv = POPs;
    SV *doc_sv = POPs;
    json_yy_doc_t *d = get_doc(aTHX_ doc_sv);
    STRLEN path_len;
    const char *path = sv_pv_utf8_nomod(aTHX_ path_sv, &path_len);

    yyjson_mut_val *val = doc_resolve_path(aTHX_ d, path, path_len);
    if (!val)
        croak("jget: path not found: %.*s", (int)path_len, path);

    SV *result = new_doc_sv(aTHX_ d->doc, val, doc_sv);
    XPUSHs(sv_2mortal(result));
    RETURN;
}

/* pp_jgetp: get as Perl value */
static OP * pp_jgetp_impl(pTHX) {
    dSP;
    SV *path_sv = POPs;
    SV *doc_sv = POPs;
    json_yy_doc_t *d = get_doc(aTHX_ doc_sv);
    STRLEN path_len;
    const char *path = sv_pv_utf8_nomod(aTHX_ path_sv, &path_len);

    yyjson_mut_val *val = doc_resolve_path(aTHX_ d, path, path_len);
    if (!val) {
        XPUSHs(&PL_sv_undef);
        RETURN;
    }

    SV *result = yyjson_mut_val_to_sv(aTHX_ val, MAX_DEPTH_DEFAULT);
    if (!result)
        croak("jgetp: maximum nesting depth exceeded");
    XPUSHs(sv_2mortal(result));
    RETURN;
}

/* Place new_val at path within Doc d. The path is resolved from d->root, so on
   a borrowed subtree Doc (from jget) it stays subtree-relative; for a
   non-borrowed Doc d->root is the doc root. An empty path replaces the root
   (forbidden on a borrowed Doc). Tries set first, then add (for "/-" array
   append). Croaks "<op>: ..." on failure. Shared by jset and jraw. */
static void
doc_set_at_path(pTHX_ json_yy_doc_t *d, const char *path, STRLEN path_len,
                yyjson_mut_val *new_val, const char *op) {
    /* Each component becomes a nested parent, so a long path would build a
       document deeper than jclone/jeq/jwrite can walk. ('/' is always a
       separator; a slash inside a key is spelled ~1.) */
    {
        STRLEN i, comps = 0;
        for (i = 0; i < path_len; i++)
            if (path[i] == '/') comps++;
        if (comps > MAX_DEPTH_DEFAULT)
            croak("%s: path nests deeper than the maximum depth", op);
    }

    if (path_len == 0) {
        if (d->owner)
            croak("%s: cannot replace root of a borrowed Doc; jclone it first", op);
        yyjson_mut_doc_set_root(d->doc, new_val);
        d->root = new_val;
        return;
    }
    yyjson_ptr_err perr;
    bool ok = yyjson_mut_ptr_setx(d->root, path, path_len, new_val,
                                   d->doc, true, NULL, &perr);
    if (!ok) {
        perr = (yyjson_ptr_err){0};
        ok = yyjson_mut_ptr_addx(d->root, path, path_len, new_val,
                                  d->doc, true, NULL, &perr);
    }
    if (!ok)
        croak("%s: failed to set path %.*s: %s", op,
              (int)path_len, path, perr.msg ? perr.msg : "unknown error");
}

/* pp_jset: set value at path */
static OP * pp_jset_impl(pTHX) {
    dSP;
    SV *value_sv = POPs;
    SV *path_sv = POPs;
    SV *doc_sv = POPs;
    json_yy_doc_t *d = get_doc(aTHX_ doc_sv);
    STRLEN path_len;
    const char *path = sv_pv_utf8_nomod(aTHX_ path_sv, &path_len);

    yyjson_mut_val *new_val;

    /* check if value is a Doc */
    if (SvROK(value_sv) && sv_derived_from(value_sv, "JSON::YY::Doc")) {
        json_yy_doc_t *vd = get_doc(aTHX_ value_sv);
        new_val = yyjson_mut_val_mut_copy(d->doc, vd->root);
        if (!new_val)
            croak("jset: failed to copy Doc value");
    } else {
        /* convert Perl value to yyjson_mut_val */
        json_yy_t self_stack;
        self_stack.flags = F_UTF8 | F_ALLOW_NONREF | F_ALLOW_BLESSED
                         | F_CONVERT_BLESSED;
        self_stack.max_depth = MAX_DEPTH_DEFAULT;
        new_val = sv_to_yyjson_val(aTHX_ d->doc, value_sv, &self_stack, 0);
    }

    doc_set_at_path(aTHX_ d, path, path_len, new_val, "jset");

    XPUSHs(doc_sv);
    RETURN;
}

/* pp_jdel: delete at path, return removed subtree as Doc */
static OP * pp_jdel_impl(pTHX) {
    dSP;
    SV *path_sv = POPs;
    SV *doc_sv = POPs;
    json_yy_doc_t *d = get_doc(aTHX_ doc_sv);
    STRLEN path_len;
    const char *path = sv_pv_utf8_nomod(aTHX_ path_sv, &path_len);

    if (path_len == 0)
        croak("jdel: cannot delete root");

    /* Resolve from d->root (subtree-relative on a borrowed Doc, matching
       jget/jgetp reads). Copy BEFORE removing, so an OOM while building the
       returned Doc leaves the parent unmodified -- jdel stays transactional. */
    yyjson_mut_val *target = yyjson_mut_ptr_getn(d->root, path, path_len);
    if (!target) {
        XPUSHs(&PL_sv_undef);
        RETURN;
    }

    /* deep copy into an independent doc (safe from later parent mutations) */
    yyjson_mut_doc *new_doc = yyjson_mut_doc_new(NULL);
    if (!new_doc)
        croak("jdel: out of memory");
    yyjson_mut_val *copy = yyjson_mut_val_mut_copy(new_doc, target);
    if (!copy) {
        yyjson_mut_doc_free(new_doc);
        croak("jdel: out of memory copying removed value");
    }
    yyjson_mut_doc_set_root(new_doc, copy);

    /* copy secured; now remove from the parent */
    yyjson_ptr_ctx ctx = {0};
    yyjson_ptr_err perr = {0};
    if (!yyjson_mut_ptr_removex(d->root, path, path_len, &ctx, &perr)) {
        /* the path resolved a moment ago; returning the subtree while the
           parent still holds it would be a lie */
        yyjson_mut_doc_free(new_doc);
        croak("jdel: failed to remove path %.*s: %s", (int)path_len, path,
              perr.msg ? perr.msg : "unknown error");
    }
    SV *result = new_doc_sv(aTHX_ new_doc, copy, NULL);
    XPUSHs(sv_2mortal(result));
    RETURN;
}

/* pp_jhas: check if path exists */
static OP * pp_jhas_impl(pTHX) {
    dSP;
    SV *path_sv = POPs;
    SV *doc_sv = POPs;
    json_yy_doc_t *d = get_doc(aTHX_ doc_sv);
    STRLEN path_len;
    const char *path = sv_pv_utf8_nomod(aTHX_ path_sv, &path_len);

    yyjson_mut_val *val = doc_resolve_path(aTHX_ d, path, path_len);
    XPUSHs(val ? &PL_sv_yes : &PL_sv_no);
    RETURN;
}

/* pp_jclone: deep copy doc/subtree → new independent Doc */
static OP * pp_jclone_impl(pTHX) {
    dSP;
    SV *path_sv = POPs;
    SV *doc_sv = POPs;
    json_yy_doc_t *d = get_doc(aTHX_ doc_sv);
    STRLEN path_len;
    const char *path = sv_pv_utf8_nomod(aTHX_ path_sv, &path_len);

    yyjson_mut_val *src = doc_resolve_path(aTHX_ d, path, path_len);
    if (!src)
        croak("jclone: path not found: %.*s", (int)path_len, path);

    yyjson_mut_doc *new_doc = yyjson_mut_doc_new(NULL);
    if (!new_doc)
        croak("jclone: failed to create document");

    yyjson_mut_val *new_root = yyjson_mut_val_mut_copy(new_doc, src);
    if (!new_root) {
        yyjson_mut_doc_free(new_doc);
        croak("jclone: failed to copy value");
    }
    yyjson_mut_doc_set_root(new_doc, new_root);

    SV *result = new_doc_sv(aTHX_ new_doc, new_root, NULL);
    XPUSHs(sv_2mortal(result));
    RETURN;
}

/* pp_jencode: serialize doc/subtree to JSON bytes */
static OP * pp_jencode_impl(pTHX) {
    dSP;
    SV *path_sv = POPs;
    SV *doc_sv = POPs;
    json_yy_doc_t *d = get_doc(aTHX_ doc_sv);
    STRLEN path_len;
    const char *path = sv_pv_utf8_nomod(aTHX_ path_sv, &path_len);

    yyjson_mut_val *val = doc_resolve_path(aTHX_ d, path, path_len);
    if (!val)
        croak("jencode: path not found: %.*s", (int)path_len, path);

    size_t json_len;
    yyjson_write_err werr;
    char *json;

    if (val == d->root && !d->owner) {
        /* full doc -- use doc write */
        json = yyjson_mut_write_opts(d->doc, YYJSON_WRITE_NOFLAG, NULL, &json_len, &werr);
    } else {
        /* subtree -- use val write */
        json = yyjson_mut_val_write_opts(val, YYJSON_WRITE_NOFLAG, NULL, &json_len, &werr);
    }
    if (!json)
        croak("jencode: write error: %s", werr.msg);

    ENTER;
    SAVEDESTRUCTOR_X(yyjson_free_buf, json);
    SV *result = newSVpvn(json, json_len);
    LEAVE;
    XPUSHs(sv_2mortal(result));
    RETURN;
}

/* pp_jstr: create JSON string value */
static OP * pp_jstr_impl(pTHX) {
    dSP;
    SV *val_sv = POPs;
    STRLEN len;
    const char *str = sv_pv_utf8_nomod(aTHX_ val_sv, &len);
    yyjson_mut_doc *doc = yyjson_mut_doc_new(NULL);
    yyjson_mut_val *root = yyjson_mut_strncpy(doc, str, len);
    yyjson_mut_doc_set_root(doc, root);
    XPUSHs(sv_2mortal(new_doc_sv(aTHX_ doc, root, NULL)));
    RETURN;
}

/* pp_jnum: a string argument is grokked rather than run through SvNV, so
   jnum "42" is an integer and jnum "abc" croaks. */
static OP * pp_jnum_impl(pTHX) {
    dSP;
    SV *val_sv = POPs;
    SvGETMAGIC(val_sv);

    /* settle the value first: a document allocated before the croaks below
       would leak on the unwind */
    enum { NUM_UINT, NUM_SINT, NUM_REAL } kind = NUM_REAL;
    uint64_t uval = 0;
    int64_t  ival = 0;
    NV       nval = 0;

    if (SvIOK(val_sv)) {
        if (SvIsUV(val_sv)) { kind = NUM_UINT; uval = (uint64_t)SvUVX(val_sv); }
        else                { kind = NUM_SINT; ival = (int64_t)SvIVX(val_sv); }
    } else if (SvNOK(val_sv)) {
        nval = SvNVX(val_sv);
        /* narrowed: a JSON real is a C double, so a value that is finite only
           as a long double still cannot be represented */
        if (Perl_isnan((double)nval) || Perl_isinf((double)nval))
            croak("jnum: cannot use NaN or Infinity as a JSON number");
    } else if (SvPOKp(val_sv)) {
        STRLEN nlen;
        const char *nstr = SvPV_const(val_sv, nlen);
        UV uv;
        int m_int_ok = 0;
        int t = grok_number(nstr, nlen, &uv);
        if (!t || (t & (IS_NUMBER_NAN | IS_NUMBER_INFINITY)))
            croak("jnum: not a number: \"%.*s\"", (int)nlen, nstr);
        if (!(t & IS_NUMBER_NOT_INT) && (t & IS_NUMBER_IN_UV)) {
            /* widened to uint64_t: (UV)INT64_MAX truncates on a 32-bit UV */
            uint64_t u = (uint64_t)uv;
            if (!(t & IS_NUMBER_NEG))                       { kind = NUM_UINT; uval = u; m_int_ok = 1; }
            else if (u <= (uint64_t)INT64_MAX)              { kind = NUM_SINT; ival = -(int64_t)u; m_int_ok = 1; }
            else if (u == (uint64_t)INT64_MAX + 1)          { kind = NUM_SINT; ival = INT64_MIN; m_int_ok = 1; }
            else                                              nval = SvNV(val_sv);
        } else {
            nval = SvNV(val_sv);
        }
        /* "1e999" groks fine but overflows to Inf as a double; reject it here
           rather than building a document that only fails later on write */
        if (!m_int_ok && (Perl_isnan((double)nval) || Perl_isinf((double)nval)))
            croak("jnum: not a number: \"%.*s\"", (int)nlen, nstr);
    } else {
        croak("jnum: not a number: %s", SvOK(val_sv) ? "reference" : "undef");
    }

    yyjson_mut_doc *doc = yyjson_mut_doc_new(NULL);
    yyjson_mut_val *root = kind == NUM_UINT ? yyjson_mut_uint(doc, uval)
                         : kind == NUM_SINT ? yyjson_mut_sint(doc, ival)
                                            : yyjson_mut_real(doc, nval);
    yyjson_mut_doc_set_root(doc, root);
    XPUSHs(sv_2mortal(new_doc_sv(aTHX_ doc, root, NULL)));
    RETURN;
}

/* pp_jbool: create JSON boolean */
static OP * pp_jbool_impl(pTHX) {
    dSP;
    SV *val_sv = POPs;
    yyjson_mut_doc *doc = yyjson_mut_doc_new(NULL);
    yyjson_mut_val *root = yyjson_mut_bool(doc, SvTRUE(val_sv));
    yyjson_mut_doc_set_root(doc, root);
    XPUSHs(sv_2mortal(new_doc_sv(aTHX_ doc, root, NULL)));
    RETURN;
}

/* pp_jnull: create JSON null */
static OP * pp_jnull_impl(pTHX) {
    dSP;
    yyjson_mut_doc *doc = yyjson_mut_doc_new(NULL);
    yyjson_mut_val *root = yyjson_mut_null(doc);
    yyjson_mut_doc_set_root(doc, root);
    XPUSHs(sv_2mortal(new_doc_sv(aTHX_ doc, root, NULL)));
    RETURN;
}

/* pp_jarr: create empty JSON array */
static OP * pp_jarr_impl(pTHX) {
    dSP;
    yyjson_mut_doc *doc = yyjson_mut_doc_new(NULL);
    yyjson_mut_val *root = yyjson_mut_arr(doc);
    yyjson_mut_doc_set_root(doc, root);
    XPUSHs(sv_2mortal(new_doc_sv(aTHX_ doc, root, NULL)));
    RETURN;
}

/* pp_jobj: create empty JSON object */
static OP * pp_jobj_impl(pTHX) {
    dSP;
    yyjson_mut_doc *doc = yyjson_mut_doc_new(NULL);
    yyjson_mut_val *root = yyjson_mut_obj(doc);
    yyjson_mut_doc_set_root(doc, root);
    XPUSHs(sv_2mortal(new_doc_sv(aTHX_ doc, root, NULL)));
    RETURN;
}

/* pp_jtype: get type string */
static OP * pp_jtype_impl(pTHX) {
    dSP;
    SV *path_sv = POPs;
    SV *doc_sv = POPs;
    json_yy_doc_t *d = get_doc(aTHX_ doc_sv);
    STRLEN path_len;
    const char *path = sv_pv_utf8_nomod(aTHX_ path_sv, &path_len);

    yyjson_mut_val *val = doc_resolve_path(aTHX_ d, path, path_len);
    if (!val) {
        XPUSHs(&PL_sv_undef);
        RETURN;
    }

    const char *type;
    switch (yyjson_mut_get_type(val)) {
        case YYJSON_TYPE_OBJ:  type = "object";  break;
        case YYJSON_TYPE_ARR:  type = "array";   break;
        case YYJSON_TYPE_STR:  type = "string";  break;
        case YYJSON_TYPE_NUM:  type = "number";  break;
        case YYJSON_TYPE_BOOL: type = "boolean"; break;
        case YYJSON_TYPE_NULL: type = "null";    break;
        default:               type = "unknown"; break;
    }
    XPUSHs(sv_2mortal(newSVpv(type, 0)));
    RETURN;
}

/* pp_jlen: get array length or object key count */
static OP * pp_jlen_impl(pTHX) {
    dSP;
    SV *path_sv = POPs;
    SV *doc_sv = POPs;
    json_yy_doc_t *d = get_doc(aTHX_ doc_sv);
    STRLEN path_len;
    const char *path = sv_pv_utf8_nomod(aTHX_ path_sv, &path_len);

    yyjson_mut_val *val = doc_resolve_path(aTHX_ d, path, path_len);
    if (!val)
        croak("jlen: path not found: %.*s", (int)path_len, path);

    size_t len;
    if (yyjson_mut_is_arr(val))
        len = yyjson_mut_arr_size(val);
    else if (yyjson_mut_is_obj(val))
        len = yyjson_mut_obj_size(val);
    else if (yyjson_mut_is_str(val))
        len = yyjson_mut_get_len(val);
    else
        croak("jlen: value at path is not a container or string");

    XPUSHs(sv_2mortal(newSViv((IV)len)));
    RETURN;
}

/* pp_jkeys: get object keys as list */
static OP * pp_jkeys_impl(pTHX) {
    dSP;
    SV *path_sv = POPs;
    SV *doc_sv = POPs;
    json_yy_doc_t *d = get_doc(aTHX_ doc_sv);
    STRLEN path_len;
    const char *path = sv_pv_utf8_nomod(aTHX_ path_sv, &path_len);

    yyjson_mut_val *val = doc_resolve_path(aTHX_ d, path, path_len);
    if (!val || !yyjson_mut_is_obj(val))
        croak("jkeys: path does not point to an object");

    size_t idx, max;
    yyjson_mut_val *key, *v;
    EXTEND(SP, (SSize_t)yyjson_mut_obj_size(val));
    yyjson_mut_obj_foreach(val, idx, max, key, v) {
        const char *kstr = yyjson_mut_get_str(key);
        size_t klen = yyjson_mut_get_len(key);
        SV *ksv = newSVpvn(kstr, klen);
        if (!is_ascii(kstr, klen))
            SvUTF8_on(ksv);
        PUSHs(sv_2mortal(ksv));
    }
    RETURN;
}

/* ---- Iterator: pull-style for arrays and objects ---- */

typedef struct {
    union {
        yyjson_mut_arr_iter arr;
        yyjson_mut_obj_iter obj;
    } it;
    int is_obj;
    yyjson_mut_val *cur_key;   /* for objects: key from last jnext */
    yyjson_mut_doc *doc;
    SV *owner;                 /* refcounted parent Doc SV */
} json_yy_iter_t;

static int
json_yy_iter_magic_free(pTHX_ SV *sv, MAGIC *mg) {
    PERL_UNUSED_ARG(sv);
    json_yy_iter_t *it = (json_yy_iter_t *)mg->mg_ptr;
    if (it) {
        if (it->owner)
            SvREFCNT_dec(it->owner);
        Safefree(it);
    }
    return 0;
}

static MGVTBL json_yy_iter_vtbl = {
    NULL, NULL, NULL, NULL,
    json_yy_iter_magic_free,
    NULL, json_yy_dup_disown, NULL
};

static inline json_yy_iter_t *
get_iter(pTHX_ SV *sv) {
    if (!SvROK(sv))
        croak("not a JSON::YY::Iter object");
    MAGIC *mg = mg_findext(SvRV(sv), PERL_MAGIC_ext, &json_yy_iter_vtbl);
    if (!mg)
        croak("not a JSON::YY::Iter object");
    CHECK_CLONED(mg, "JSON::YY::Iter");
    return (json_yy_iter_t *)mg->mg_ptr;
}

/* pp_jiter: create iterator for array/object at path */
static OP * pp_jiter_impl(pTHX) {
    dSP;
    SV *path_sv = POPs;
    SV *doc_sv = POPs;
    json_yy_doc_t *d = get_doc(aTHX_ doc_sv);
    STRLEN path_len;
    const char *path = sv_pv_utf8_nomod(aTHX_ path_sv, &path_len);

    yyjson_mut_val *val = doc_resolve_path(aTHX_ d, path, path_len);
    if (!val)
        croak("jiter: path not found: %.*s", (int)path_len, path);
    if (!yyjson_mut_is_arr(val) && !yyjson_mut_is_obj(val))
        croak("jiter: value at path is not an array or object");

    json_yy_iter_t *it;
    Newxz(it, 1, json_yy_iter_t);
    it->doc = d->doc;
    it->owner = doc_sv;
    SvREFCNT_inc_simple_void_NN(doc_sv);
    it->cur_key = NULL;

    if (yyjson_mut_is_obj(val)) {
        it->is_obj = 1;
        yyjson_mut_obj_iter_init(val, &it->it.obj);
    } else {
        it->is_obj = 0;
        yyjson_mut_arr_iter_init(val, &it->it.arr);
    }

    HV *hv = newHV();
    attach_ext_magic(aTHX_ (SV *)hv, &json_yy_iter_vtbl, it);
    SV *result = sv_bless(newRV_noinc((SV *)hv),
                          gv_stashpvs("JSON::YY::Iter", GV_ADD));
    XPUSHs(sv_2mortal(result));
    RETURN;
}

/* pp_jnext: advance iterator, return next value as Doc or undef */
static OP * pp_jnext_impl(pTHX) {
    dSP;
    SV *iter_sv = POPs;
    json_yy_iter_t *it = get_iter(aTHX_ iter_sv);

    yyjson_mut_val *val = NULL;

    if (it->is_obj) {
        if (yyjson_mut_obj_iter_has_next(&it->it.obj)) {
            it->cur_key = yyjson_mut_obj_iter_next(&it->it.obj);
            val = yyjson_mut_obj_iter_get_val(it->cur_key);
        }
    } else {
        if (yyjson_mut_arr_iter_has_next(&it->it.arr)) {
            val = yyjson_mut_arr_iter_next(&it->it.arr);
        }
    }

    if (!val) {
        XPUSHs(&PL_sv_undef);
        RETURN;
    }

    /* return value as borrowing Doc */
    SV *result = new_doc_sv(aTHX_ it->doc, val, it->owner);
    XPUSHs(sv_2mortal(result));
    RETURN;
}

/* pp_jkey: get current key from object iterator */
static OP * pp_jkey_impl(pTHX) {
    dSP;
    SV *iter_sv = POPs;
    json_yy_iter_t *it = get_iter(aTHX_ iter_sv);

    if (!it->is_obj)
        croak("jkey: iterator is not over an object");
    if (!it->cur_key) {
        XPUSHs(&PL_sv_undef);
        RETURN;
    }

    const char *kstr = yyjson_mut_get_str(it->cur_key);
    size_t klen = yyjson_mut_get_len(it->cur_key);
    SV *sv = newSVpvn(kstr, klen);
    if (!is_ascii(kstr, klen))
        SvUTF8_on(sv);
    XPUSHs(sv_2mortal(sv));
    RETURN;
}

/* pp_jpatch: apply RFC 6902 JSON Patch */
static OP * pp_jpatch_impl(pTHX) {
    dSP;
    SV *patch_sv = POPs;
    SV *doc_sv = POPs;
    json_yy_doc_t *d = get_doc(aTHX_ doc_sv);
    if (d->owner)
        croak("jpatch: cannot patch a borrowed Doc; jclone it first");
    json_yy_doc_t *p = get_doc(aTHX_ patch_sv);

    yyjson_patch_err perr = {0};
    yyjson_mut_val *result = yyjson_mut_patch(d->doc, d->root, p->root, &perr);
    if (!result)
        croak("jpatch: %s at index %zu", perr.msg ? perr.msg : "patch failed", perr.idx);

    yyjson_mut_doc_set_root(d->doc, result);
    d->root = result;
    XPUSHs(doc_sv);
    RETURN;
}

/* pp_jmerge: apply RFC 7386 JSON Merge Patch */
static OP * pp_jmerge_impl(pTHX) {
    dSP;
    SV *patch_sv = POPs;
    SV *doc_sv = POPs;
    json_yy_doc_t *d = get_doc(aTHX_ doc_sv);
    if (d->owner)
        croak("jmerge: cannot merge into a borrowed Doc; jclone it first");
    json_yy_doc_t *p = get_doc(aTHX_ patch_sv);

    yyjson_mut_val *result = yyjson_mut_merge_patch(d->doc, d->root, p->root);
    if (!result)
        croak("jmerge: merge patch failed");

    yyjson_mut_doc_set_root(d->doc, result);
    d->root = result;
    XPUSHs(doc_sv);
    RETURN;
}

/* pp_jfrom: create Doc from Perl data (not JSON string) */
static OP * pp_jfrom_impl(pTHX) {
    dSP;
    SV *data = POPs;

    yyjson_mut_doc *doc = yyjson_mut_doc_new(NULL);
    if (!doc) croak("jfrom: failed to create document");

    json_yy_t self_stack;
    self_stack.flags = F_UTF8 | F_ALLOW_NONREF | F_ALLOW_BLESSED
                     | F_CONVERT_BLESSED;
    self_stack.max_depth = MAX_DEPTH_DEFAULT;

    /* wrap doc in a holder SV so it's freed on croak */
    SV *guard = newSV(0);
    attach_ext_magic(aTHX_ guard, &mut_docholder_vtbl, doc);
    sv_2mortal(guard);

    yyjson_mut_val *root = sv_to_yyjson_val(aTHX_ doc, data, &self_stack, 0);
    yyjson_mut_doc_set_root(doc, root);

    /* transfer doc ownership to the Doc SV; disarm the guard */
    mg_findext(guard, PERL_MAGIC_ext, &mut_docholder_vtbl)->mg_ptr = NULL;
    SV *result = new_doc_sv(aTHX_ doc, root, NULL);
    XPUSHs(sv_2mortal(result));
    RETURN;
}

/* pp_jvals: get object values as list */
static OP * pp_jvals_impl(pTHX) {
    dSP;
    SV *path_sv = POPs;
    SV *doc_sv = POPs;
    json_yy_doc_t *d = get_doc(aTHX_ doc_sv);
    STRLEN path_len;
    const char *path = sv_pv_utf8_nomod(aTHX_ path_sv, &path_len);

    yyjson_mut_val *val = doc_resolve_path(aTHX_ d, path, path_len);
    if (!val || !yyjson_mut_is_obj(val))
        croak("jvals: path does not point to an object");

    size_t idx, max;
    yyjson_mut_val *key, *v;
    EXTEND(SP, (SSize_t)yyjson_mut_obj_size(val));
    yyjson_mut_obj_foreach(val, idx, max, key, v) {
        SV *vsv = new_doc_sv(aTHX_ d->doc, v, doc_sv);
        PUSHs(sv_2mortal(vsv));
    }
    RETURN;
}

/* pp_jeq: deep equality comparison */
static OP * pp_jeq_impl(pTHX) {
    dSP;
    SV *b_sv = POPs;
    SV *a_sv = POPs;
    json_yy_doc_t *a = get_doc(aTHX_ a_sv);
    json_yy_doc_t *b = get_doc(aTHX_ b_sv);
    bool eq = yyjson_mut_equals(a->root, b->root);
    XPUSHs(eq ? &PL_sv_yes : &PL_sv_no);
    RETURN;
}

/* pp_jpp: pretty-print encode */
static OP * pp_jpp_impl(pTHX) {
    dSP;
    SV *path_sv = POPs;
    SV *doc_sv = POPs;
    json_yy_doc_t *d = get_doc(aTHX_ doc_sv);
    STRLEN path_len;
    const char *path = sv_pv_utf8_nomod(aTHX_ path_sv, &path_len);

    yyjson_mut_val *val = doc_resolve_path(aTHX_ d, path, path_len);
    if (!val)
        croak("jpp: path not found: %.*s", (int)path_len, path);

    size_t json_len;
    yyjson_write_err werr;
    char *json = yyjson_mut_val_write_opts(val, YYJSON_WRITE_PRETTY, NULL,
                                            &json_len, &werr);
    if (!json)
        croak("jpp: write error: %s", werr.msg);
    ENTER;
    SAVEDESTRUCTOR_X(yyjson_free_buf, json);
    SV *result = newSVpvn(json, json_len);
    LEAVE;
    XPUSHs(sv_2mortal(result));
    RETURN;
}

/* pp_jraw: insert raw JSON string at path */
static OP * pp_jraw_impl(pTHX) {
    dSP;
    SV *json_sv = POPs;
    SV *path_sv = POPs;
    SV *doc_sv = POPs;
    json_yy_doc_t *d = get_doc(aTHX_ doc_sv);
    STRLEN path_len;
    const char *path = sv_pv_utf8_nomod(aTHX_ path_sv, &path_len);
    STRLEN json_len;
    const char *json = sv_pv_utf8_nomod(aTHX_ json_sv, &json_len);

    /* parse the raw JSON fragment */
    yyjson_doc *idoc = yyjson_read(json, json_len, YYJSON_READ_NOFLAG);
    if (!idoc)
        croak("jraw: invalid JSON fragment");
    CHECK_DOC_DEPTH(idoc, MAX_DEPTH_DEFAULT, "jraw");

    /* copy into mutable doc */
    yyjson_val *iroot = yyjson_doc_get_root(idoc);
    yyjson_mut_val *new_val = yyjson_val_mut_copy(d->doc, iroot);
    yyjson_doc_free(idoc);

    if (!new_val)
        croak("jraw: failed to copy value");

    doc_set_at_path(aTHX_ d, path, path_len, new_val, "jraw");

    XPUSHs(doc_sv);
    RETURN;
}

/* type predicate macros -- all follow same pattern */
#define PP_JIS(name, check_fn) \
static OP * pp_##name##_impl(pTHX) { \
    dSP; \
    SV *path_sv = POPs; \
    SV *doc_sv = POPs; \
    json_yy_doc_t *d = get_doc(aTHX_ doc_sv); \
    STRLEN path_len; \
    const char *path = sv_pv_utf8_nomod(aTHX_ path_sv, &path_len); \
    yyjson_mut_val *val = doc_resolve_path(aTHX_ d, path, path_len); \
    XPUSHs(val && check_fn(val) ? &PL_sv_yes : &PL_sv_no); \
    RETURN; \
}

static inline bool is_mut_int(yyjson_mut_val *v) {
    return yyjson_mut_is_uint(v) || yyjson_mut_is_sint(v);
}

PP_JIS(jis_obj,     yyjson_mut_is_obj)
PP_JIS(jis_arr,     yyjson_mut_is_arr)
PP_JIS(jis_str,     yyjson_mut_is_str)
PP_JIS(jis_num,     yyjson_mut_is_num)
PP_JIS(jis_int,     is_mut_int)
PP_JIS(jis_real,    yyjson_mut_is_real)
PP_JIS(jis_bool,    yyjson_mut_is_bool)
PP_JIS(jis_null,    yyjson_mut_is_null)

#undef PP_JIS

/* pp_jread: read JSON file → Doc */
static OP * pp_jread_impl(pTHX) {
    dSP;
    SV *path_sv = POPs;
    STRLEN len;
    const char *path = SvPV(path_sv, len);

    yyjson_read_err err;
    yyjson_doc *idoc = yyjson_read_file(path, YYJSON_READ_NOFLAG, NULL, &err);
    if (!idoc)
        croak("jread: %s: %s", path, err.msg ? err.msg : "read failed");
    CHECK_DOC_DEPTH(idoc, MAX_DEPTH_DEFAULT, "jread");

    yyjson_mut_doc *mdoc = yyjson_doc_mut_copy(idoc, NULL);
    yyjson_doc_free(idoc);
    if (!mdoc)
        croak("jread: failed to create mutable document");

    yyjson_mut_val *root = yyjson_mut_doc_get_root(mdoc);
    SV *result = new_doc_sv(aTHX_ mdoc, root, NULL);
    XPUSHs(sv_2mortal(result));
    RETURN;
}

/* pp_jwrite: write Doc to JSON file */
static OP * pp_jwrite_impl(pTHX) {
    dSP;
    SV *path_sv = POPs;
    SV *doc_sv = POPs;
    json_yy_doc_t *d = get_doc(aTHX_ doc_sv);
    STRLEN len;
    const char *path = SvPV(path_sv, len);

    yyjson_write_err werr;
    /* write the subtree root, not necessarily the full doc */
    yyjson_mut_doc *tmp_doc = yyjson_mut_doc_new(NULL);
    if (!tmp_doc)
        croak("jwrite: out of memory");
    yyjson_mut_val *copy = yyjson_mut_val_mut_copy(tmp_doc, d->root);
    if (!copy) {
        yyjson_mut_doc_free(tmp_doc);
        croak("jwrite: out of memory");
    }
    yyjson_mut_doc_set_root(tmp_doc, copy);

    bool ok = yyjson_mut_write_file(path, tmp_doc, YYJSON_WRITE_PRETTY, NULL, &werr);
    yyjson_mut_doc_free(tmp_doc);

    if (!ok)
        croak("jwrite: %s: %s", path, werr.msg ? werr.msg : "write failed");

    XPUSHs(doc_sv);
    RETURN;
}

/* pp_jpaths: enumerate all leaf paths */

/* returns 0, or 1 if the value nests deeper than the budget allows */
static int
collect_paths(pTHX_ yyjson_mut_val *val, SV *prefix, AV *result, U32 budget) {
    if (yyjson_mut_is_obj(val)) {
        if (!budget) return 1;
        size_t idx, max;
        yyjson_mut_val *key, *v;
        yyjson_mut_obj_foreach(val, idx, max, key, v) {
            const char *kstr = yyjson_mut_get_str(key);
            size_t klen = yyjson_mut_get_len(key);
            SV *path = newSVsv(prefix);
            sv_catpvs(path, "/");
            /* escape ~ and / in key per RFC 6901 */
            const char *p = kstr;
            const char *end = kstr + klen;
            while (p < end) {
                const char *special = p;
                while (special < end && *special != '~' && *special != '/')
                    special++;
                if (special > p)
                    sv_catpvn(path, p, special - p);
                if (special < end) {
                    if (*special == '~') sv_catpvs(path, "~0");
                    else                 sv_catpvs(path, "~1");
                    special++;
                }
                p = special;
            }
            if (yyjson_mut_is_obj(v) || yyjson_mut_is_arr(v)) {
                int deep = collect_paths(aTHX_ v, path, result, budget - 1);
                SvREFCNT_dec(path);  /* path was used as prefix, not pushed */
                if (deep) return 1;
            } else {
                av_push(result, path);  /* transfers ownership */
            }
        }
    } else if (yyjson_mut_is_arr(val)) {
        if (!budget) return 1;
        size_t idx, max;
        yyjson_mut_val *item;
        yyjson_mut_arr_foreach(val, idx, max, item) {
            SV *path = newSVsv(prefix);
            sv_catpvs(path, "/");
            char idxbuf[24];
            int idxlen = snprintf(idxbuf, sizeof(idxbuf), "%zu", idx);
            sv_catpvn(path, idxbuf, idxlen);
            if (yyjson_mut_is_obj(item) || yyjson_mut_is_arr(item)) {
                int deep = collect_paths(aTHX_ item, path, result, budget - 1);
                SvREFCNT_dec(path);
                if (deep) return 1;
            } else {
                av_push(result, path);
            }
        }
    } else {
        /* leaf -- the prefix itself is the path */
        av_push(result, newSVsv(prefix));
    }
    return 0;
}

static OP * pp_jpaths_impl(pTHX) {
    dSP;
    SV *path_sv = POPs;
    SV *doc_sv = POPs;
    json_yy_doc_t *d = get_doc(aTHX_ doc_sv);
    STRLEN path_len;
    const char *path = sv_pv_utf8_nomod(aTHX_ path_sv, &path_len);

    yyjson_mut_val *val = doc_resolve_path(aTHX_ d, path, path_len);
    if (!val)
        croak("jpaths: path not found: %.*s", (int)path_len, path);

    AV *paths = newAV();
    SV *prefix = newSVpvn(path, path_len);
    int deep = collect_paths(aTHX_ val, prefix, paths, MAX_DEPTH_DEFAULT);
    SvREFCNT_dec(prefix);
    if (deep) {
        SvREFCNT_dec((SV *)paths);
        croak("jpaths: maximum nesting depth exceeded");
    }

    SSize_t count = av_len(paths) + 1;
    EXTEND(SP, count);
    for (SSize_t i = 0; i < count; i++) {
        SV **svp = av_fetch(paths, i, 0);
        SV *pv = *svp;
        /* a path with a non-ASCII key must come back flagged, or feeding it to
           jget/jencode re-reads those bytes as latin-1 (jkeys does the same) */
        if (!SvUTF8(pv) && !is_ascii(SvPVX(pv), SvCUR(pv)))
            SvUTF8_on(pv);
        PUSHs(sv_2mortal(SvREFCNT_inc(pv)));
    }
    SvREFCNT_dec((SV *)paths);
    RETURN;
}

/* pp_jfind: find first array element where key == value */
static OP * pp_jfind_impl(pTHX) {
    dSP;
    SV *match_sv = POPs;   /* value to match */
    SV *key_sv = POPs;     /* key path within each element */
    SV *path_sv = POPs;    /* array path */
    SV *doc_sv = POPs;
    json_yy_doc_t *d = get_doc(aTHX_ doc_sv);
    STRLEN path_len, key_len, match_len;
    const char *path = sv_pv_utf8_nomod(aTHX_ path_sv, &path_len);
    const char *key = sv_pv_utf8_nomod(aTHX_ key_sv, &key_len);
    const char *match = sv_pv_utf8_nomod(aTHX_ match_sv, &match_len);

    yyjson_mut_val *arr = doc_resolve_path(aTHX_ d, path, path_len);
    if (!arr || !yyjson_mut_is_arr(arr)) {
        XPUSHs(&PL_sv_undef);
        RETURN;
    }

    /* Classify the match once: a non-numeric string must not compare equal to
       a numeric field (SvNV("abc") is 0.0), and an integer must compare as
       64-bit so large ids do not collide through double rounding. */
    int m_num = 0, m_int = 0, m_neg = 0;
    UV m_uv = 0;
    NV m_nv = 0;
    if (SvIOK(match_sv)) {
        m_num = m_int = 1;
        if (SvIsUV(match_sv)) m_uv = SvUVX(match_sv);
        else {
            IV iv = SvIVX(match_sv);
            if (iv < 0) { m_neg = 1; m_uv = (UV)(-(iv + 1)) + 1; } else m_uv = (UV)iv;
        }
    } else if (SvNOK(match_sv)) {
        m_num = 1; m_nv = SvNVX(match_sv);
    } else {
        int t = grok_number(match, match_len, &m_uv);
        if (t && !(t & (IS_NUMBER_NAN | IS_NUMBER_INFINITY))) {
            m_num = 1;
            m_neg = (t & IS_NUMBER_NEG) ? 1 : 0;
            if (!(t & IS_NUMBER_NOT_INT) && (t & IS_NUMBER_IN_UV)) m_int = 1;
            else m_nv = SvNV(match_sv);
        }
    }

    size_t idx, max;
    yyjson_mut_val *item;
    yyjson_mut_arr_foreach(arr, idx, max, item) {
        /* look up key within this element */
        yyjson_mut_val *field = NULL;
        if (key_len == 0)
            field = item;
        else if (yyjson_mut_is_obj(item) || yyjson_mut_is_arr(item))
            field = yyjson_mut_ptr_getn(item, key, key_len);

        if (!field) continue;

        /* compare: string match */
        if (yyjson_mut_is_str(field)) {
            if (yyjson_mut_equals_strn(field, match, match_len)) {
                SV *result = new_doc_sv(aTHX_ d->doc, item, doc_sv);
                XPUSHs(sv_2mortal(result));
                RETURN;
            }
        }
        /* compare: number. Integer matches use 64-bit compares so values above
           2^53 (e.g. Snowflake IDs) don't collide through double rounding. */
        else if (yyjson_mut_is_num(field) && m_num) {
            yyjson_subtype st = yyjson_mut_get_subtype(field);
            int eq;
            if (m_int && st != YYJSON_SUBTYPE_REAL) {
                if (!m_neg || m_uv == 0)   /* -0 is 0 */
                    eq = (st == YYJSON_SUBTYPE_UINT)
                         ? (yyjson_mut_get_uint(field) == (uint64_t)m_uv)
                         : (yyjson_mut_get_sint(field) >= 0 &&
                            (uint64_t)yyjson_mut_get_sint(field) == (uint64_t)m_uv);
                else if ((uint64_t)m_uv <= (uint64_t)INT64_MAX)
                    eq = (st == YYJSON_SUBTYPE_SINT) &&
                         (yyjson_mut_get_sint(field) == -(int64_t)m_uv);
                else   /* INT64_MIN is representable, -(int64_t)m_uv is not */
                    eq = (st == YYJSON_SUBTYPE_SINT) &&
                         ((uint64_t)m_uv == (uint64_t)INT64_MAX + 1) &&
                         (yyjson_mut_get_sint(field) == INT64_MIN);
            } else {
                /* narrowed to double: yyjson stores reals as C double, and on a
                   long-double perl a bare == would never be equal */
                NV nv = m_int ? (m_neg ? -(NV)m_uv : (NV)m_uv) : m_nv;
                eq = ((double)nv == yyjson_mut_get_num(field));
            }
            if (eq) {
                SV *result = new_doc_sv(aTHX_ d->doc, item, doc_sv);
                XPUSHs(sv_2mortal(result));
                RETURN;
            }
        }
        /* compare: bool -- match against string "true"/"false" */
        else if (yyjson_mut_is_bool(field)) {
            bool bval = yyjson_mut_get_bool(field);
            if ((bval && match_len == 4 && memcmp(match, "true", 4) == 0) ||
                (!bval && match_len == 5 && memcmp(match, "false", 5) == 0)) {
                SV *result = new_doc_sv(aTHX_ d->doc, item, doc_sv);
                XPUSHs(sv_2mortal(result));
                RETURN;
            }
        }
        /* compare: null -- match against the string "null" */
        else if (yyjson_mut_is_null(field)) {
            if (match_len == 4 && memcmp(match, "null", 4) == 0) {
                SV *result = new_doc_sv(aTHX_ d->doc, item, doc_sv);
                XPUSHs(sv_2mortal(result));
                RETURN;
            }
        }
    }

    XPUSHs(&PL_sv_undef);
    RETURN;
}

/* ---- end Doc keyword ops ---- */

/* check if a string is pure ASCII (no bytes >= 0x80) */
static inline int
is_ascii(const char *s, size_t len) {
    const unsigned char *p = (const unsigned char *)s;
    size_t i = 0;
    for (; i + 7 < len; i += 8) {
        uint64_t chunk;
        memcpy(&chunk, p + i, 8);
        if (chunk & UINT64_C(0x8080808080808080))
            return 0;
    }
    for (; i < len; i++) {
        if (p[i] >= 0x80)
            return 0;
    }
    return 1;
}

/* ---- zero-copy string SV ---- */
/* SvLEN=0 tells Perl it doesn't own the buffer; the bytes live inside the
   yyjson_doc. Each borrowing SV carries magic holding a (refcounted) ref to
   the doc holder, so the doc outlives every value that points into it --
   including a reference taken to a nested value (e.g. \$data->[0]) that
   outlives the root container. sv_setsv still copies, so values extracted by
   assignment remain independent. */
static inline SV *
new_sv_zerocopy(pTHX_ const char *str, size_t len, SV *doc_sv) {
    SV *sv = newSV_type(SVt_PV);
    SvPV_set(sv, (char *)str);
    SvCUR_set(sv, len);
    SvLEN_set(sv, 0);
    SvPOK_on(sv);
    if (!is_ascii(str, len))
        SvUTF8_on(sv);
    sv_magicext(sv, doc_sv, PERL_MAGIC_ext, &empty_vtbl, NULL, 0);
    SvREADONLY_on(sv);
    return sv;
}

/* ---- DECODE: yyjson value -> Perl SV ---- */

static SV *
yyjson_val_to_sv(pTHX_ yyjson_val *val, U32 budget) {
    switch (yyjson_get_type(val)) {
        case YYJSON_TYPE_NULL:
            return SvREFCNT_inc_simple_NN(&PL_sv_undef);

        case YYJSON_TYPE_BOOL:
            return yyjson_get_bool(val)
                ? SvREFCNT_inc_simple_NN(&PL_sv_yes)
                : SvREFCNT_inc_simple_NN(&PL_sv_no);

        case YYJSON_TYPE_NUM:
            return yyjson_num_to_sv(aTHX_ val);

        case YYJSON_TYPE_STR: {
            const char *str = yyjson_get_str(val);
            size_t len = yyjson_get_len(val);
            SV *sv = newSVpvn(str, len);
            /* only set UTF-8 flag if non-ASCII */
            if (!is_ascii(str, len))
                SvUTF8_on(sv);
            return sv;
        }

        case YYJSON_TYPE_ARR: {
            if (!budget) return NULL;
            size_t count = yyjson_arr_size(val);
            AV *av = newAV();
            if (count > 0)
                av_extend(av, (SSize_t)count - 1);
            SV *rv = newRV_noinc((SV *)av);
            size_t idx, max;
            yyjson_val *item;
            yyjson_arr_foreach(val, idx, max, item) {
                SV *item_sv = yyjson_val_to_sv(aTHX_ item, budget - 1);
                if (!item_sv) { SvREFCNT_dec(rv); return NULL; }
                av_push(av, item_sv);
            }
            return rv;
        }

        case YYJSON_TYPE_OBJ: {
            if (!budget) return NULL;
            size_t count = yyjson_obj_size(val);
            HV *hv = newHV();
            if (count > 0)
                hv_ksplit(hv, count);
            SV *rv = newRV_noinc((SV *)hv);
            size_t idx, max;
            yyjson_val *key, *value;
            yyjson_obj_foreach(val, idx, max, key, value) {
                const char *kstr = yyjson_get_str(key);
                STRLEN klen = (STRLEN)yyjson_get_len(key);
                SV *val_sv = yyjson_val_to_sv(aTHX_ value, budget - 1);
                if (!val_sv) { SvREFCNT_dec(rv); return NULL; }
                if (!is_ascii(kstr, klen))
                    hv_store(hv, kstr, -(I32)klen, val_sv, 0);
                else
                    hv_store(hv, kstr, (I32)klen, val_sv, 0);
            }
            return rv;
        }

        default:
            return SvREFCNT_inc_simple_NN(&PL_sv_undef);
    }
}

/* ---- DECODE: yyjson mutable value -> Perl SV ---- */

static SV *
yyjson_mut_val_to_sv(pTHX_ yyjson_mut_val *val, U32 budget) {
    switch (yyjson_mut_get_type(val)) {
        case YYJSON_TYPE_NULL:
            return SvREFCNT_inc_simple_NN(&PL_sv_undef);

        case YYJSON_TYPE_BOOL:
            return yyjson_mut_get_bool(val)
                ? SvREFCNT_inc_simple_NN(&PL_sv_yes)
                : SvREFCNT_inc_simple_NN(&PL_sv_no);

        case YYJSON_TYPE_NUM:
            return yyjson_mut_num_to_sv(aTHX_ val);

        case YYJSON_TYPE_STR: {
            const char *str = yyjson_mut_get_str(val);
            size_t len = yyjson_mut_get_len(val);
            SV *sv = newSVpvn(str, len);
            if (!is_ascii(str, len))
                SvUTF8_on(sv);
            return sv;
        }

        case YYJSON_TYPE_ARR: {
            if (!budget) return NULL;
            size_t count = yyjson_mut_arr_size(val);
            AV *av = newAV();
            if (count > 0)
                av_extend(av, (SSize_t)count - 1);
            SV *rv = newRV_noinc((SV *)av);
            size_t idx, max;
            yyjson_mut_val *item;
            yyjson_mut_arr_foreach(val, idx, max, item) {
                SV *item_sv = yyjson_mut_val_to_sv(aTHX_ item, budget - 1);
                if (!item_sv) { SvREFCNT_dec(rv); return NULL; }
                av_push(av, item_sv);
            }
            return rv;
        }

        case YYJSON_TYPE_OBJ: {
            if (!budget) return NULL;
            size_t count = yyjson_mut_obj_size(val);
            HV *hv = newHV();
            if (count > 0)
                hv_ksplit(hv, count);
            SV *rv = newRV_noinc((SV *)hv);
            size_t idx, max;
            yyjson_mut_val *key, *value;
            yyjson_mut_obj_foreach(val, idx, max, key, value) {
                const char *kstr = yyjson_mut_get_str(key);
                STRLEN klen = (STRLEN)yyjson_mut_get_len(key);
                SV *val_sv = yyjson_mut_val_to_sv(aTHX_ value, budget - 1);
                if (!val_sv) { SvREFCNT_dec(rv); return NULL; }
                if (!is_ascii(kstr, klen))
                    hv_store(hv, kstr, -(I32)klen, val_sv, 0);
                else
                    hv_store(hv, kstr, (I32)klen, val_sv, 0);
            }
            return rv;
        }

        default:
            return SvREFCNT_inc_simple_NN(&PL_sv_undef);
    }
}

/* ---- zero-copy readonly decoder ---- */
/* doc_sv: an SV holding the yyjson_doc* (refcounted, freed on DESTROY) */

static SV *
yyjson_val_to_sv_ro(pTHX_ yyjson_val *val, SV *doc_sv, U32 budget) {
    switch (yyjson_get_type(val)) {
        case YYJSON_TYPE_NULL:
            return SvREFCNT_inc_simple_NN(&PL_sv_undef);

        case YYJSON_TYPE_BOOL:
            return yyjson_get_bool(val)
                ? SvREFCNT_inc_simple_NN(&PL_sv_yes)
                : SvREFCNT_inc_simple_NN(&PL_sv_no);

        case YYJSON_TYPE_NUM: {
            SV *nsv = yyjson_num_to_sv(aTHX_ val);
            SvREADONLY_on(nsv);
            return nsv;
        }

        case YYJSON_TYPE_STR:
            /* zero-copy: SV borrows string memory from yyjson_doc */
            return new_sv_zerocopy(aTHX_
                yyjson_get_str(val), yyjson_get_len(val), doc_sv);

        case YYJSON_TYPE_ARR: {
            if (!budget) return NULL;
            size_t count = yyjson_arr_size(val);
            AV *av = newAV();
            if (count > 0)
                av_extend(av, (SSize_t)count - 1);
            SV *rv = newRV_noinc((SV *)av);
            size_t idx, max;
            yyjson_val *item;
            yyjson_arr_foreach(val, idx, max, item) {
                SV *item_sv = yyjson_val_to_sv_ro(aTHX_ item, doc_sv, budget - 1);
                if (!item_sv) { SvREFCNT_dec(rv); return NULL; }
                av_push(av, item_sv);
            }
            SvREADONLY_on((SV *)av);
            return rv;
        }

        case YYJSON_TYPE_OBJ: {
            if (!budget) return NULL;
            size_t count = yyjson_obj_size(val);
            HV *hv = newHV();
            if (count > 0)
                hv_ksplit(hv, count);
            SV *rv = newRV_noinc((SV *)hv);
            size_t idx, max;
            yyjson_val *key, *value;
            yyjson_obj_foreach(val, idx, max, key, value) {
                const char *kstr = yyjson_get_str(key);
                STRLEN klen = (STRLEN)yyjson_get_len(key);
                SV *val_sv = yyjson_val_to_sv_ro(aTHX_ value, doc_sv, budget - 1);
                if (!val_sv) { SvREFCNT_dec(rv); return NULL; }
                if (!is_ascii(kstr, klen))
                    hv_store(hv, kstr, -(I32)klen, val_sv, 0);
                else
                    hv_store(hv, kstr, (I32)klen, val_sv, 0);
            }
            SvREADONLY_on((SV *)hv);
            return rv;
        }

        default:
            return SvREFCNT_inc_simple_NN(&PL_sv_undef);
    }
}

/* opaque SV releasing the yyjson_doc when the last reference across all
   interpreters goes */
static SV *
new_doc_holder(pTHX_ yyjson_doc *doc) {
    json_yy_ro_t *h;
    SV *sv = newSV(0);
    h = (json_yy_ro_t *)malloc(sizeof(json_yy_ro_t));
    if (!h) croak("out of memory");
    h->doc = doc;
    h->refcnt = 1;
    attach_ext_magic(aTHX_ sv, &docholder_magic_vtbl, h);
    return sv;
}

/* ---- DIRECT ENCODE: single-pass SV -> JSON bytes ---- */
/* Bypasses yyjson_mut_doc entirely for maximum throughput */

/* 0 = passthrough, 1 = \uXXXX, other = the char after a backslash,
   ESC_WIDEN = latin-1 byte to widen. The ASCII half is shared. */
#define ESC_WIDEN 0xff

#define ESCAPE_TABLE_ASCII_HALF                                     \
    /* 0x00-0x1f: control characters need \uXXXX */                 \
    1,1,1,1,1,1,1,1, 'b','t','n',1,'f','r',1,1,                     \
    1,1,1,1,1,1,1,1, 1,1,1,1,1,1,1,1,                               \
    /* 0x20-0x7f */                                                 \
    0,0,'"',0,0,0,0,0, 0,0,0,0,0,0,0,0,  /* " at 0x22 */            \
    0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,  /* 0x30-0x3f */              \
    0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,  /* 0x40-0x4f */              \
    0,0,0,0,0,0,0,0, 0,0,0,0,'\\',0,0,0, /* \\ at 0x5c */           \
    0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,                               \
    0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0

#define ESCAPE_TABLE_HIGH_HALF(v)                                   \
    v,v,v,v,v,v,v,v, v,v,v,v,v,v,v,v,                               \
    v,v,v,v,v,v,v,v, v,v,v,v,v,v,v,v,                               \
    v,v,v,v,v,v,v,v, v,v,v,v,v,v,v,v,                               \
    v,v,v,v,v,v,v,v, v,v,v,v,v,v,v,v,                               \
    v,v,v,v,v,v,v,v, v,v,v,v,v,v,v,v,                               \
    v,v,v,v,v,v,v,v, v,v,v,v,v,v,v,v,                               \
    v,v,v,v,v,v,v,v, v,v,v,v,v,v,v,v,                               \
    v,v,v,v,v,v,v,v, v,v,v,v,v,v,v,v

/* source is UTF-8: high bytes pass through untouched */
static const uint8_t escape_table[256] = {
    ESCAPE_TABLE_ASCII_HALF,
    ESCAPE_TABLE_HIGH_HALF(0)
};

/* no UTF8 flag: high bytes are latin-1 and must be widened. A table rather
   than an extra test keeps the run scan at one lookup per byte. */
static const uint8_t escape_table_latin1[256] = {
    ESCAPE_TABLE_ASCII_HALF,
    ESCAPE_TABLE_HIGH_HALF(ESC_WIDEN)
};

/* Room for `need` more bytes plus the NUL. Compared additively: the
   subtractive form underflows once cur reaches SvLEN, disabling all growth. */
static inline void
buf_ensure(pTHX_ SV *buf, size_t need) {
    STRLEN cur = SvCUR(buf);
    if (SvLEN(buf) < cur + need + 1)
        SvGROW(buf, (cur + need + 1) * 2);
}

static inline void
buf_cat_c(pTHX_ SV *buf, char c) {
    buf_ensure(aTHX_ buf, 1);
    char *p = SvPVX(buf) + SvCUR(buf);
    *p = c;
    SvCUR_set(buf, SvCUR(buf) + 1);
}

static inline void
buf_cat_mem(pTHX_ SV *buf, const char *s, size_t n) {
    buf_ensure(aTHX_ buf, n);
    char *p = SvPVX(buf) + SvCUR(buf);
    memcpy(p, s, n);
    SvCUR_set(buf, SvCUR(buf) + n);
}

/* Does the string need escaping? high_too also reports bytes >= 0x80 (latin-1
   needing widening), riding along in the same scan. */
static inline int
needs_escape(const char *s, size_t len, int high_too) {
    /* check 8 bytes at a time for common case (no control chars, no " or \) */
    /* bytes needing escape: 0x00-0x1f, 0x22 ("), 0x5c (\) */
    const unsigned char *p = (const unsigned char *)s;
    /* masks rather than branches, so the ASCII case is unchanged */
    const uint64_t hi_mask = high_too ? UINT64_C(0x8080808080808080) : 0;
    const unsigned char hi_byte = high_too ? 0x80 : 0;
    size_t i = 0;
    for (; i + 7 < len; i += 8) {
        uint64_t chunk;
        memcpy(&chunk, p + i, 8);
        if (chunk & hi_mask)
            return 1;
        /* any byte < 0x20? subtract 0x20 from each byte; underflow sets high bit */
        if ((chunk - UINT64_C(0x2020202020202020)) & ~chunk & UINT64_C(0x8080808080808080))
            return 1;
        /* check for " (0x22) or \ (0x5c) byte by byte in chunk */
        uint64_t xor_quote = chunk ^ UINT64_C(0x2222222222222222);
        uint64_t xor_bslash = chunk ^ UINT64_C(0x5c5c5c5c5c5c5c5c);
        /* a byte is zero iff (v - 0x01) & ~v & 0x80 */
        #define HAS_ZERO(v) (((v) - UINT64_C(0x0101010101010101)) & ~(v) & UINT64_C(0x8080808080808080))
        if (HAS_ZERO(xor_quote) || HAS_ZERO(xor_bslash))
            return 1;
        #undef HAS_ZERO
    }
    for (; i < len; i++) {
        if (escape_table[p[i]] | (p[i] & hi_byte))
            return 1;
    }
    return 0;
}

/* latin1: the source had no UTF8 flag, so bytes >= 0x80 are latin-1 characters
   needing widening to UTF-8. Callers pass 0 for UTF-8 or ASCII input. */
/* the body is big enough that a plain `inline` hint is ignored, and the two
   instantiations below are only worth anything if `latin1` folds away */
#if defined(__GNUC__) || defined(__clang__)
#  define JSON_YY_FORCE_INLINE inline __attribute__((always_inline))
#elif defined(_MSC_VER)
#  define JSON_YY_FORCE_INLINE __forceinline
#else
#  define JSON_YY_FORCE_INLINE inline
#endif

static JSON_YY_FORCE_INLINE void
buf_cat_escaped_impl(pTHX_ SV *buf, const char *s, size_t len, const int latin1) {
    /* fast path: no escaping needed (very common for JSON keys/values).
       With latin1 set the scan also rejects high bytes, so reaching here
       means the memcpy below is byte-identical UTF-8. */
    if (!needs_escape(s, len, latin1)) {
        buf_ensure(aTHX_ buf, len + 2);
        char *out = SvPVX(buf) + SvCUR(buf);
        *out++ = '"';
        memcpy(out, s, len);
        out += len;
        *out++ = '"';
        SvCUR_set(buf, out - SvPVX(buf));
        return;
    }

    /* slow path: need escaping (and/or widening) */
    static const char hex_digits[] = "0123456789abcdef";
    const uint8_t *tbl = latin1 ? escape_table_latin1 : escape_table;
    buf_ensure(aTHX_ buf, len + 2 + 16); /* some headroom */
    char *out = SvPVX(buf) + SvCUR(buf);
    /* SvLEN-1 is reserved for the NUL the callers write at SvPVX[SvCUR];
       reaching it would push SvCUR to SvLEN and defeat buf_ensure */
    char *out_end = SvPVX(buf) + SvLEN(buf) - 2;
    *out++ = '"';

    const char *end = s + len;
    while (s < end) {
        /* ensure we have room for at least one escaped char */
        if (out + 8 > out_end) {
            SvCUR_set(buf, out - SvPVX(buf));
            buf_ensure(aTHX_ buf, (end - s) * 2 + 8);
            out = SvPVX(buf) + SvCUR(buf);
            out_end = SvPVX(buf) + SvLEN(buf) - 2;
        }

        unsigned char c = *s;
        uint8_t esc = tbl[c];
        if (!esc) {
            /* scan for run of safe chars */
            const char *safe = s + 1;
            while (safe < end && !tbl[(unsigned char)*safe])
                safe++;
            size_t n = safe - s;
            if (out + n > out_end) {
                SvCUR_set(buf, out - SvPVX(buf));
                buf_ensure(aTHX_ buf, n + (end - safe) * 2 + 8);
                out = SvPVX(buf) + SvCUR(buf);
                out_end = SvPVX(buf) + SvLEN(buf) - 2;
            }
            memcpy(out, s, n);
            out += n;
            s = safe;
        } else if (esc == ESC_WIDEN) {
            /* latin-1 character: re-encode as two UTF-8 bytes */
            *out++ = (char)(0xc0 | (c >> 6));
            *out++ = (char)(0x80 | (c & 0x3f));
            s++;
        } else if (esc > 1) {
            *out++ = '\\';
            *out++ = (char)esc;
            s++;
        } else {
            *out++ = '\\'; *out++ = 'u'; *out++ = '0'; *out++ = '0';
            *out++ = hex_digits[c >> 4];
            *out++ = hex_digits[c & 0x0f];
            s++;
        }
    }
    *out++ = '"';
    SvCUR_set(buf, out - SvPVX(buf));
}

/* Instantiated twice so `latin1` folds to a constant in each: the UTF-8
   variant loses the widening branch, the mask and the table indirection. */
static void
buf_cat_escaped_utf8(pTHX_ SV *buf, const char *s, size_t len) {
    buf_cat_escaped_impl(aTHX_ buf, s, len, 0);
}
static void
buf_cat_escaped_latin1(pTHX_ SV *buf, const char *s, size_t len) {
    buf_cat_escaped_impl(aTHX_ buf, s, len, 1);
}
static inline void
buf_cat_escaped_str(pTHX_ SV *buf, const char *s, size_t len, int latin1) {
    if (latin1) buf_cat_escaped_latin1(aTHX_ buf, s, len);
    else        buf_cat_escaped_utf8(aTHX_ buf, s, len);
}

/* fast unsigned integer to buffer */
static void
buf_cat_uv(pTHX_ SV *buf, UV val) {
    char tmp[24];
    char *p = tmp + sizeof(tmp);
    if (val == 0) {
        *--p = '0';
    } else {
        while (val) {
            *--p = '0' + (val % 10);
            val /= 10;
        }
    }
    buf_cat_mem(aTHX_ buf, p, (tmp + sizeof(tmp)) - p);
}

static void
buf_cat_iv(pTHX_ SV *buf, IV val) {
    if (val < 0) {
        buf_cat_c(aTHX_ buf, '-');
        /* handle IV_MIN carefully */
        buf_cat_uv(aTHX_ buf, (UV)(-(val + 1)) + 1);
    } else {
        buf_cat_uv(aTHX_ buf, (UV)val);
    }
}

static void
buf_cat_nv(pTHX_ SV *buf, NV val) {
    /* Stringify via Perl's NV->PV: sv_2pv does the correct per-nvtype thing
       (Gconvert for double/long double, quadmath_snprintf for __float128) and
       forces a C-locale '.' radix -- avoiding both the quadmath Gconvert
       garbage (2.5 -> "0") and the LC_NUMERIC "2,5" bug. NaN/Inf are rejected
       by the caller. */
    STRLEN len;
    SV *tmp = sv_2mortal(newSVnv(val));
    const char *s = SvPV_const(tmp, len);
    /* NV_DIG digits can round a finite value past the largest double, giving
       a number our own decoder rejects as infinity. Only huge values can. */
    if (UNLIKELY(val > (NV)1.0e308 || val < (NV)-1.0e308)) {
        SV *back = sv_2mortal(newSVpvn(s, len));
        if (Perl_isinf(SvNV(back))) {
            sv_setpvs(tmp, "");
            Perl_sv_catpvf(aTHX_ tmp, "%.*" NVgf, (int)NV_DIG + 3, val);
            s = SvPV_const(tmp, len);
        }
    }
    buf_cat_mem(aTHX_ buf, s, len);
}

static json_yy_t default_self = { F_UTF8 | F_ALLOW_NONREF, MAX_DEPTH_DEFAULT };

/* A scalar can hold a string and a number at once. Encode as a number only
   when the number's own text is exactly the string: "42" stays 42, while
   "007", "42\n" and $! stay strings. Matches Cpanel::JSON::XS. */
static int
sv_num_is_faithful(pTHX_ SV *sv, const char *str, STRLEN len) {
    if (SvIOK(sv)) {
        char buf[32];
        char *end = buf + sizeof(buf);
        char *p = end;
        UV uv;
        int neg = 0;
        if (SvIsUV(sv))
            uv = SvUVX(sv);
        else {
            IV iv = SvIVX(sv);
            if (iv < 0) { neg = 1; uv = (UV)(-(iv + 1)) + 1; }
            else          uv = (UV)iv;
        }
        if (!uv) *--p = '0';
        else while (uv) { *--p = (char)('0' + (uv % 10)); uv /= 10; }
        if (neg) *--p = '-';
        return (STRLEN)(end - p) == len && memcmp(p, str, len) == 0;
    }
    if (SvNOK(sv)) {
        /* same stringification the encoder would emit (see buf_cat_nv) */
        STRLEN nlen;
        SV *tmp = sv_2mortal(newSVnv(SvNVX(sv)));
        const char *n = SvPV_const(tmp, nlen);
        return nlen == len && memcmp(n, str, len) == 0;
    }
    return 0;
}

/* true/false decode to PL_sv_yes/PL_sv_no and re-encode as 1/0; PL_sv_no's PV
   is "", which would otherwise fail the test above and emit an empty string. */
#ifdef SvIsBOOL
#  define SV_IS_BOOL(sv) (SvIsBOOL(sv) || (sv) == &PL_sv_yes || (sv) == &PL_sv_no)
#else
/* no bool flag before 5.36: match the shape perl gives a copy of !!1 / !!0 --
   all three slots set, with PV "1"/IV 1 or PV ""/IV 0. An ordinary string that
   was merely used numerically does not get all three. */
#  define SV_IS_BOOL(sv)                                                   \
     ((sv) == &PL_sv_yes || (sv) == &PL_sv_no ||                           \
      (SvIOK(sv) && SvNOK(sv) && SvPOK(sv) &&                              \
       ((SvCUR(sv) == 0 && SvIVX(sv) == 0) ||                              \
        (SvCUR(sv) == 1 && SvPVX(sv)[0] == '1' && SvIVX(sv) == 1))))
#endif

static void
direct_encode_sv(pTHX_ SV *buf, SV *sv, U32 depth, json_yy_t *self) {
    if (depth > self->max_depth)
        croak("maximum nesting depth exceeded");

    SvGETMAGIC(sv);   /* tied values arrive unresolved and would encode as null */

    if (!SvOK(sv)) {
        buf_cat_mem(aTHX_ buf, "null", 4);
        return;
    }

    if (SvROK(sv)) {
        SV *deref = SvRV(sv);

        if (SvOBJECT(deref)) {
            /* convert_blessed applies only if the class has a TO_JSON;
               otherwise fall through to allow_blessed, as JSON::XS does */
            if ((self->flags & F_CONVERT_BLESSED) &&
                gv_fetchmethod_autoload(SvSTASH(deref), "TO_JSON", 0)) {
                dSP;
                ENTER; SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(sv);
                PUTBACK;
                int count = call_method("TO_JSON", G_SCALAR | G_EVAL);
                SPAGAIN;
                if (SvTRUE(ERRSV)) {
                    SV *err = ERRSV;
                    PUTBACK; FREETMPS; LEAVE;
                    croak("TO_JSON method failed: %" SVf, SVfARG(err));
                }
                SV *result = count > 0 ? POPs : &PL_sv_undef;
                SvREFCNT_inc(result);
                PUTBACK; FREETMPS; LEAVE;
                /* mortalize rather than an explicit dec: if the recursive
                   encode croaks on an unencodable TO_JSON result, the mortal
                   is still freed on unwind (an explicit dec would be skipped). */
                sv_2mortal(result);
                /* depth+1: a TO_JSON returning its own object would otherwise
                   recurse forever past max_depth */
                direct_encode_sv(aTHX_ buf, result, depth + 1, self);
                return;
            }
            if (self->flags & F_ALLOW_BLESSED) {
                buf_cat_mem(aTHX_ buf, "null", 4);
                return;
            }
            croak("encountered object '%s', but neither allow_blessed nor "
                  "convert_blessed is enabled (or the TO_JSON method is missing)",
                  sv_reftype(deref, 1));
        }

        /* scalar ref: boolean */
        if (SvTYPE(deref) < SVt_PVAV) {
            if (SvTRUE(deref))
                buf_cat_mem(aTHX_ buf, "true", 4);
            else
                buf_cat_mem(aTHX_ buf, "false", 5);
            return;
        }

        if (SvTYPE(deref) == SVt_PVAV) {
            AV *av = (AV *)deref;
            SSize_t len = av_len(av) + 1;
            if (depth >= self->max_depth)   /* count containers, as decode does */
                croak("maximum nesting depth exceeded");
            buf_cat_c(aTHX_ buf, '[');
            for (SSize_t i = 0; i < len; i++) {
                if (i) buf_cat_c(aTHX_ buf, ',');
                SV **elem = av_fetch(av, i, 0);
                direct_encode_sv(aTHX_ buf, elem ? *elem : &PL_sv_undef,
                                 depth + 1, self);
            }
            buf_cat_c(aTHX_ buf, ']');
            return;
        }

        if (SvTYPE(deref) == SVt_PVHV) {
            HV *hv = (HV *)deref;
            if (depth >= self->max_depth)   /* count containers, as decode does */
                croak("maximum nesting depth exceeded");
            buf_cat_c(aTHX_ buf, '{');
            hv_iterinit(hv);
            HE *he;
            int first = 1;
            /* HeVAL() is NULL on a tied hash; hv_iterval() runs FETCH.
               Guarded so plain hashes keep the inline fast path. */
            const bool magical = cBOOL(SvRMAGICAL(hv));
            while ((he = hv_iternext(hv))) {
                if (!first) buf_cat_c(aTHX_ buf, ',');
                first = 0;
                STRLEN klen;
                const char *kstr = HePV(he, klen);
                buf_cat_escaped_str(aTHX_ buf, kstr, klen, !HeUTF8(he));
                buf_cat_c(aTHX_ buf, ':');
                direct_encode_sv(aTHX_ buf,
                                 magical ? hv_iterval(hv, he) : HeVAL(he),
                                 depth + 1, self);
            }
            buf_cat_c(aTHX_ buf, '}');
            return;
        }

        if (self->flags & F_ALLOW_UNKNOWN) {
            buf_cat_mem(aTHX_ buf, "null", 4);
            return;
        }
        croak("cannot encode reference to %s", sv_reftype(deref, 0));
    }

    if (SvNOK(sv) && (Perl_isnan(SvNVX(sv)) || Perl_isinf(SvNVX(sv))))
        croak("cannot encode NaN or Infinity as JSON");

    if (SV_IS_BOOL(sv)) {
        buf_cat_c(aTHX_ buf, SvTRUE(sv) ? '1' : '0');
        return;
    }

    /* SvPOKp, not SvPOK: stringifying a number leaves only the private flag */
    if (SvPOKp(sv)) {
        STRLEN len;
        const char *str = SvPV_nomg(sv, len);   /* get magic ran on entry */
        if ((SvIOK(sv) || SvNOK(sv)) && sv_num_is_faithful(aTHX_ sv, str, len)) {
            /* NVs go through buf_cat_nv even so, for the near-DBL_MAX fixup */
            if (SvIOK(sv)) buf_cat_mem(aTHX_ buf, str, len);
            else           buf_cat_nv(aTHX_ buf, SvNVX(sv));
            return;
        }
        buf_cat_escaped_str(aTHX_ buf, str, len, !SvUTF8(sv));
        return;
    }

    if (SvIOK(sv)) {
        if (SvIsUV(sv))
            buf_cat_uv(aTHX_ buf, SvUVX(sv));
        else
            buf_cat_iv(aTHX_ buf, SvIVX(sv));
        return;
    }

    if (SvNOK(sv)) {
        buf_cat_nv(aTHX_ buf, SvNVX(sv));
        return;
    }

    buf_cat_mem(aTHX_ buf, "null", 4);
}

/* ---- ENCODE: Perl SV -> yyjson mutable value (used for OO API) ---- */

static yyjson_mut_val *
sv_to_yyjson_val(pTHX_ yyjson_mut_doc *doc, SV *sv, json_yy_t *self, U32 depth) {
    if (depth > self->max_depth)
        croak("maximum nesting depth exceeded");

    SvGETMAGIC(sv);   /* see direct_encode_sv() */

    if (!SvOK(sv))
        return yyjson_mut_null(doc);

    if (SvROK(sv)) {
        SV *deref = SvRV(sv);

        /* check for blessed objects */
        if (SvOBJECT(deref)) {
            /* convert_blessed: call TO_JSON, if the class has one (see
               direct_encode_sv) */
            if ((self->flags & F_CONVERT_BLESSED) &&
                gv_fetchmethod_autoload(SvSTASH(deref), "TO_JSON", 0)) {
                dSP;
                ENTER; SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(sv);
                PUTBACK;
                int count = call_method("TO_JSON", G_SCALAR | G_EVAL);
                SPAGAIN;
                if (SvTRUE(ERRSV)) {
                    SV *err = ERRSV;
                    PUTBACK; FREETMPS; LEAVE;
                    croak("TO_JSON method failed: %" SVf, SVfARG(err));
                }
                SV *result = count > 0 ? POPs : &PL_sv_undef;
                SvREFCNT_inc(result);
                PUTBACK; FREETMPS; LEAVE;
                /* mortalize rather than an explicit dec: if the recursive
                   encode croaks on an unencodable TO_JSON result, the mortal
                   is still freed on unwind (an explicit dec would be skipped). */
                sv_2mortal(result);
                /* depth+1: see direct_encode_sv() */
                return sv_to_yyjson_val(aTHX_ doc, result, self, depth + 1);
            }
            /* allow_blessed: encode as null */
            if (self->flags & F_ALLOW_BLESSED)
                return yyjson_mut_null(doc);
            croak("encountered object '%s', but neither allow_blessed nor "
                  "convert_blessed is enabled (or the TO_JSON method is missing)",
                  sv_reftype(deref, 1));
        }

        /* scalar ref: \1 = true, \0 = false */
        if (SvTYPE(deref) < SVt_PVAV) {
            return SvTRUE(deref)
                ? yyjson_mut_bool(doc, 1)
                : yyjson_mut_bool(doc, 0);
        }

        switch (SvTYPE(deref)) {
            case SVt_PVAV: {
                AV *av = (AV *)deref;
                if (depth >= self->max_depth)   /* see direct_encode_sv() */
                    croak("maximum nesting depth exceeded");
                yyjson_mut_val *arr = yyjson_mut_arr(doc);
                SSize_t len = av_len(av) + 1;
                for (SSize_t i = 0; i < len; i++) {
                    SV **elem = av_fetch(av, i, 0);
                    yyjson_mut_val *v = sv_to_yyjson_val(aTHX_ doc, elem ? *elem : &PL_sv_undef, self, depth + 1);
                    yyjson_mut_arr_append(arr, v);
                }
                return arr;
            }

            case SVt_PVHV: {
                HV *hv = (HV *)deref;
                if (depth >= self->max_depth)   /* see direct_encode_sv() */
                    croak("maximum nesting depth exceeded");
                yyjson_mut_val *obj = yyjson_mut_obj(doc);
                hv_iterinit(hv);
                HE *he;
                const bool magical = cBOOL(SvRMAGICAL(hv));  /* see direct_encode_sv() */
                while ((he = hv_iternext(hv))) {
                    STRLEN klen;
                    const char *kstr = HePV(he, klen);
                    if (!HeUTF8(he) && !is_ascii(kstr, klen)) {
                        /* latin-1 key: widen, or yyjson rejects it on write */
                        SV *ktmp = sv_2mortal(newSVpvn(kstr, klen));
                        sv_utf8_upgrade(ktmp);
                        kstr = SvPV_const(ktmp, klen);
                    }
                    /* copy the key before hv_iterval() runs FETCH, which
                       could invalidate the entry kstr points into */
                    yyjson_mut_val *k = yyjson_mut_strncpy(doc, kstr, klen);
                    SV *val = magical ? hv_iterval(hv, he) : HeVAL(he);
                    yyjson_mut_val *v = sv_to_yyjson_val(aTHX_ doc, val, self, depth + 1);
                    yyjson_mut_obj_add(obj, k, v);
                }
                return obj;
            }

            default:
                if (self->flags & F_ALLOW_UNKNOWN)
                    return yyjson_mut_null(doc);
                croak("cannot encode reference to %s", sv_reftype(deref, 0));
        }
    }

    if (SvNOK(sv) && (Perl_isnan(SvNVX(sv)) || Perl_isinf(SvNVX(sv))))
        croak("cannot encode NaN or Infinity as JSON");

    if (SV_IS_BOOL(sv))
        return yyjson_mut_sint(doc, SvTRUE(sv) ? 1 : 0);

    /* see sv_num_is_faithful(). One SvPV for the whole branch: fetching twice
       could emit a different string than the one just tested. */
    if (SvPOKp(sv)) {
        STRLEN len;
        const char *str = SvPV_nomg(sv, len);   /* get magic ran on entry */
        if ((SvIOK(sv) || SvNOK(sv)) && sv_num_is_faithful(aTHX_ sv, str, len)) {
            if (SvIOK(sv))
                return SvIsUV(sv) ? yyjson_mut_uint(doc, (uint64_t)SvUVX(sv))
                                  : yyjson_mut_sint(doc, (int64_t)SvIVX(sv));
            return yyjson_mut_real(doc, SvNVX(sv));
        }
        if (!SvUTF8(sv) && !is_ascii(str, len)) {
            /* latin-1: widen on a copy, never in the caller's SV */
            SV *tmp = sv_2mortal(newSVpvn(str, len));
            sv_utf8_upgrade(tmp);
            str = SvPV_const(tmp, len);
        }
        return yyjson_mut_strncpy(doc, str, len);
    }

    if (SvIOK(sv)) {
        if (SvIsUV(sv))
            return yyjson_mut_uint(doc, (uint64_t)SvUVX(sv));
        return yyjson_mut_sint(doc, (int64_t)SvIVX(sv));
    }

    if (SvNOK(sv))
        return yyjson_mut_real(doc, SvNVX(sv));

    return yyjson_mut_null(doc);
}

/* ---- custom ops for keyword API ---- */

/* pp function for decode_json keyword */
static OP *
pp_decode_json_impl(pTHX) {
    dSP;
    SV *json_sv = POPs;
    STRLEN len;
    const char *json = SvPV(json_sv, len);

    yyjson_read_err err;
    yyjson_doc *doc = yyjson_read_opts((char *)json, len, YYJSON_READ_NOFLAG, NULL, &err);
    if (!doc)
        croak("JSON decode error: %s at byte offset %zu", err.msg, err.pos);
    CHECK_DOC_DEPTH(doc, MAX_DEPTH_DEFAULT, "JSON decode error");

    yyjson_val *root = yyjson_doc_get_root(doc);
    if (!root) {
        yyjson_doc_free(doc);
        croak("JSON decode error: empty document");
    }

    SV *result = yyjson_val_to_sv(aTHX_ root, MAX_DEPTH_DEFAULT);
    yyjson_doc_free(doc);
    if (!result)
        croak("JSON decode error: maximum nesting depth exceeded");

    XPUSHs(sv_2mortal(result));
    RETURN;
}

/* pp function for encode_json keyword */
static OP *
pp_encode_json_impl(pTHX) {
    dSP;
    SV *data = POPs;

    SV *result = newSV(64);
    SvPOK_on(result);
    SvCUR_set(result, 0);
    /* mortalize before encoding: direct_encode_sv can croak (max depth,
       NaN/Inf, unencodable ref) and an unguarded result would leak.
       The OO encoders use SAVEFREESV for the same reason. */
    sv_2mortal(result);
    direct_encode_sv(aTHX_ result, data, 0, &default_self);
    *(SvPVX(result) + SvCUR(result)) = '\0';

    XPUSHs(result);
    RETURN;
}

/* pp function for decode_json_ro keyword */
static OP *
pp_decode_json_ro_impl(pTHX) {
    dSP;
    SV *json_sv = POPs;
    STRLEN len;
    const char *json = SvPV(json_sv, len);

    yyjson_read_err err;
    yyjson_doc *doc = yyjson_read_opts((char *)json, len, YYJSON_READ_NOFLAG, NULL, &err);
    if (!doc)
        croak("JSON decode error: %s at byte offset %zu", err.msg, err.pos);
    CHECK_DOC_DEPTH(doc, MAX_DEPTH_DEFAULT, "JSON decode error");

    yyjson_val *root = yyjson_doc_get_root(doc);
    if (!root) {
        yyjson_doc_free(doc);
        croak("JSON decode error: empty document");
    }

    SV *doc_sv = new_doc_holder(aTHX_ doc);
    SV *result = yyjson_val_to_sv_ro(aTHX_ root, doc_sv, MAX_DEPTH_DEFAULT);
    if (!result) {
        SvREFCNT_dec(doc_sv);
        croak("JSON decode error: maximum nesting depth exceeded");
    }

    /* attach doc_sv to keep yyjson_doc alive while zero-copy SVs exist.
       skip for null/bool roots -- they return immortal globals that must
       not accumulate magic. */
    yyjson_type rtype = yyjson_get_type(root);
    if (rtype != YYJSON_TYPE_NULL && rtype != YYJSON_TYPE_BOOL) {
        SV *anchor = SvROK(result) ? SvRV(result) : result;
        sv_magicext(anchor, doc_sv, PERL_MAGIC_ext, &empty_vtbl, NULL, 0);
    }
    SvREFCNT_dec(doc_sv);

    XPUSHs(sv_2mortal(result));
    RETURN;
}

/* ---- XS::Parse::Keyword op builders ---- */

static OP *
make_custom_unop(pTHX_ Perl_ppaddr_t ppfunc, OP *arg) {
    OP *o = newUNOP(OP_NULL, 0, arg);
    o->op_type = OP_CUSTOM;
    o->op_ppaddr = ppfunc;
    return o;
}

static OP *
make_custom_binop(pTHX_ Perl_ppaddr_t ppfunc, OP *a, OP *b) {
    OP *o = newBINOP(OP_NULL, 0, a, b);
    o->op_type = OP_CUSTOM;
    o->op_ppaddr = ppfunc;
    return o;
}

static OP *
make_custom_3op(pTHX_ Perl_ppaddr_t ppfunc, OP *a, OP *b, OP *c) {
    OP *ab = newBINOP(OP_NULL, 0, a, b);
    OP *o = newBINOP(OP_NULL, 0, ab, c);
    o->op_type = OP_CUSTOM;
    o->op_ppaddr = ppfunc;
    return o;
}

static OP *
make_custom_4op(pTHX_ Perl_ppaddr_t ppfunc, OP *a, OP *b, OP *c, OP *d) {
    OP *ab = newBINOP(OP_NULL, 0, a, b);
    OP *cd = newBINOP(OP_NULL, 0, c, d);
    OP *o = newBINOP(OP_NULL, 0, ab, cd);
    o->op_type = OP_CUSTOM;
    o->op_ppaddr = ppfunc;
    return o;
}

/* ---- XS::Parse::Keyword hooks ---- */

/* macro to define build callback + hooks for 0-arg keyword */
#define XPK_KW0(name, ppfunc) \
static int build_kw_##name(pTHX_ OP **out, XSParseKeywordPiece *args[], \
                           size_t nargs, void *hookdata) { \
    (void)args; PERL_UNUSED_ARG(nargs); PERL_UNUSED_ARG(hookdata); \
    OP *o = newOP(OP_NULL, 0); o->op_type = OP_CUSTOM; o->op_ppaddr = ppfunc; \
    *out = o; return KEYWORD_PLUGIN_EXPR; \
} \
static const struct XSParseKeywordHooks hooks_##name = { \
    .permit_hintkey = "JSON::YY/" #name, \
    .pieces = (const struct XSParseKeywordPieceType []){ {0} }, \
    .build = &build_kw_##name, \
};

/* macro for 1-arg keyword */
#define XPK_KW1(name, ppfunc) \
static int build_kw_##name(pTHX_ OP **out, XSParseKeywordPiece *args[], \
                           size_t nargs, void *hookdata) { \
    PERL_UNUSED_ARG(nargs); PERL_UNUSED_ARG(hookdata); \
    *out = make_custom_unop(aTHX_ ppfunc, args[0]->op); \
    return KEYWORD_PLUGIN_EXPR; \
} \
static const struct XSParseKeywordHooks hooks_##name = { \
    .permit_hintkey = "JSON::YY/" #name, \
    .pieces = (const struct XSParseKeywordPieceType []){ XPK_TERMEXPR, {0} }, \
    .build = &build_kw_##name, \
};

/* macro for 2-arg keyword */
#define XPK_KW2(name, ppfunc) \
static int build_kw_##name(pTHX_ OP **out, XSParseKeywordPiece *args[], \
                           size_t nargs, void *hookdata) { \
    PERL_UNUSED_ARG(nargs); PERL_UNUSED_ARG(hookdata); \
    *out = make_custom_binop(aTHX_ ppfunc, args[0]->op, args[1]->op); \
    return KEYWORD_PLUGIN_EXPR; \
} \
static const struct XSParseKeywordHooks hooks_##name = { \
    .permit_hintkey = "JSON::YY/" #name, \
    .pieces = (const struct XSParseKeywordPieceType []){ \
        XPK_TERMEXPR, XPK_COMMA, XPK_TERMEXPR, {0} }, \
    .build = &build_kw_##name, \
};

/* macro for 3-arg keyword */
#define XPK_KW3(name, ppfunc) \
static int build_kw_##name(pTHX_ OP **out, XSParseKeywordPiece *args[], \
                           size_t nargs, void *hookdata) { \
    PERL_UNUSED_ARG(nargs); PERL_UNUSED_ARG(hookdata); \
    *out = make_custom_3op(aTHX_ ppfunc, args[0]->op, args[1]->op, args[2]->op); \
    return KEYWORD_PLUGIN_EXPR; \
} \
static const struct XSParseKeywordHooks hooks_##name = { \
    .permit_hintkey = "JSON::YY/" #name, \
    .pieces = (const struct XSParseKeywordPieceType []){ \
        XPK_TERMEXPR, XPK_COMMA, XPK_TERMEXPR, XPK_COMMA, XPK_TERMEXPR, {0} }, \
    .build = &build_kw_##name, \
};

/* macro for 4-arg keyword */
#define XPK_KW4(name, ppfunc) \
static int build_kw_##name(pTHX_ OP **out, XSParseKeywordPiece *args[], \
                           size_t nargs, void *hookdata) { \
    PERL_UNUSED_ARG(nargs); PERL_UNUSED_ARG(hookdata); \
    *out = make_custom_4op(aTHX_ ppfunc, args[0]->op, args[1]->op, \
                           args[2]->op, args[3]->op); \
    return KEYWORD_PLUGIN_EXPR; \
} \
static const struct XSParseKeywordHooks hooks_##name = { \
    .permit_hintkey = "JSON::YY/" #name, \
    .pieces = (const struct XSParseKeywordPieceType []){ \
        XPK_TERMEXPR, XPK_COMMA, XPK_TERMEXPR, XPK_COMMA, \
        XPK_TERMEXPR, XPK_COMMA, XPK_TERMEXPR, {0} }, \
    .build = &build_kw_##name, \
};

/* functional API */
XPK_KW1(encode_json,    pp_encode_json_impl)
XPK_KW1(decode_json,    pp_decode_json_impl)
XPK_KW1(decode_json_ro, pp_decode_json_ro_impl)

/* doc creation */
XPK_KW1(jdoc,   pp_jdoc_impl)
XPK_KW1(jfrom,  pp_jfrom_impl)
XPK_KW1(jread,  pp_jread_impl)

/* value constructors */
XPK_KW1(jstr,   pp_jstr_impl)
XPK_KW1(jnum,   pp_jnum_impl)
XPK_KW1(jbool,  pp_jbool_impl)
XPK_KW0(jnull,  pp_jnull_impl)
XPK_KW0(jarr,   pp_jarr_impl)
XPK_KW0(jobj,   pp_jobj_impl)

/* path ops */
XPK_KW2(jget,     pp_jget_impl)
XPK_KW2(jgetp,    pp_jgetp_impl)
XPK_KW3(jset,     pp_jset_impl)
XPK_KW2(jdel,     pp_jdel_impl)
XPK_KW2(jhas,     pp_jhas_impl)
XPK_KW2(jclone,   pp_jclone_impl)
XPK_KW2(jwrite,   pp_jwrite_impl)
XPK_KW2(jencode,  pp_jencode_impl)
XPK_KW2(jpp,      pp_jpp_impl)
XPK_KW3(jraw,     pp_jraw_impl)

/* inspection */
XPK_KW2(jtype,    pp_jtype_impl)
XPK_KW2(jlen,     pp_jlen_impl)
XPK_KW2(jkeys,    pp_jkeys_impl)
XPK_KW2(jvals,    pp_jvals_impl)
XPK_KW2(jpaths,   pp_jpaths_impl)
XPK_KW4(jfind,    pp_jfind_impl)

/* iteration */
XPK_KW2(jiter,    pp_jiter_impl)
XPK_KW1(jnext,    pp_jnext_impl)
XPK_KW1(jkey,     pp_jkey_impl)

/* patching */
XPK_KW2(jpatch,   pp_jpatch_impl)
XPK_KW2(jmerge,   pp_jmerge_impl)

/* comparison */
XPK_KW2(jeq,      pp_jeq_impl)

/* type predicates */
XPK_KW2(jis_obj,  pp_jis_obj_impl)
XPK_KW2(jis_arr,  pp_jis_arr_impl)
XPK_KW2(jis_str,  pp_jis_str_impl)
XPK_KW2(jis_num,  pp_jis_num_impl)
XPK_KW2(jis_int,  pp_jis_int_impl)
XPK_KW2(jis_real, pp_jis_real_impl)
XPK_KW2(jis_bool, pp_jis_bool_impl)
XPK_KW2(jis_null, pp_jis_null_impl)

/* alias: jdecode = jgetp */
XPK_KW2(jdecode,  pp_jgetp_impl)

MODULE = JSON::YY    PACKAGE = JSON::YY

BOOT:
{
#ifdef USE_ITHREADS
    /* guards the decode_json_ro buffer refcount; the flag keeps a second
       interpreter loading the module from re-initialising a live mutex */
    if (!json_yy_ro_mutex_ready) {
        MUTEX_INIT(&json_yy_ro_mutex);
        json_yy_ro_mutex_ready = 1;
    }
#endif

    boot_xs_parse_keyword(0.40);

    /* functional API keywords */
    register_xs_parse_keyword("encode_json",    &hooks_encode_json,    NULL);
    register_xs_parse_keyword("decode_json",    &hooks_decode_json,    NULL);
    register_xs_parse_keyword("decode_json_ro", &hooks_decode_json_ro, NULL);

    /* doc creation */
    register_xs_parse_keyword("jdoc",   &hooks_jdoc,   NULL);
    register_xs_parse_keyword("jfrom",  &hooks_jfrom,  NULL);
    register_xs_parse_keyword("jread",  &hooks_jread,  NULL);

    /* value constructors */
    register_xs_parse_keyword("jstr",   &hooks_jstr,   NULL);
    register_xs_parse_keyword("jnum",   &hooks_jnum,   NULL);
    register_xs_parse_keyword("jbool",  &hooks_jbool,  NULL);
    register_xs_parse_keyword("jnull",  &hooks_jnull,  NULL);
    register_xs_parse_keyword("jarr",   &hooks_jarr,   NULL);
    register_xs_parse_keyword("jobj",   &hooks_jobj,   NULL);

    /* path operations */
    register_xs_parse_keyword("jget",     &hooks_jget,     NULL);
    register_xs_parse_keyword("jgetp",    &hooks_jgetp,    NULL);
    register_xs_parse_keyword("jset",     &hooks_jset,     NULL);
    register_xs_parse_keyword("jdel",     &hooks_jdel,     NULL);
    register_xs_parse_keyword("jhas",     &hooks_jhas,     NULL);
    register_xs_parse_keyword("jclone",   &hooks_jclone,   NULL);
    register_xs_parse_keyword("jwrite",   &hooks_jwrite,   NULL);
    register_xs_parse_keyword("jencode",  &hooks_jencode,  NULL);
    register_xs_parse_keyword("jpp",      &hooks_jpp,      NULL);
    register_xs_parse_keyword("jraw",     &hooks_jraw,     NULL);

    /* inspection */
    register_xs_parse_keyword("jtype",    &hooks_jtype,    NULL);
    register_xs_parse_keyword("jlen",     &hooks_jlen,     NULL);
    register_xs_parse_keyword("jkeys",    &hooks_jkeys,    NULL);
    register_xs_parse_keyword("jvals",    &hooks_jvals,    NULL);
    register_xs_parse_keyword("jpaths",   &hooks_jpaths,   NULL);
    register_xs_parse_keyword("jfind",    &hooks_jfind,    NULL);

    /* iteration */
    register_xs_parse_keyword("jiter",    &hooks_jiter,    NULL);
    register_xs_parse_keyword("jnext",    &hooks_jnext,    NULL);
    register_xs_parse_keyword("jkey",     &hooks_jkey,     NULL);

    /* patching */
    register_xs_parse_keyword("jpatch",   &hooks_jpatch,   NULL);
    register_xs_parse_keyword("jmerge",   &hooks_jmerge,   NULL);

    /* comparison */
    register_xs_parse_keyword("jeq",      &hooks_jeq,      NULL);

    /* type predicates */
    register_xs_parse_keyword("jis_obj",  &hooks_jis_obj,  NULL);
    register_xs_parse_keyword("jis_arr",  &hooks_jis_arr,  NULL);
    register_xs_parse_keyword("jis_str",  &hooks_jis_str,  NULL);
    register_xs_parse_keyword("jis_num",  &hooks_jis_num,  NULL);
    register_xs_parse_keyword("jis_int",  &hooks_jis_int,  NULL);
    register_xs_parse_keyword("jis_real", &hooks_jis_real, NULL);
    register_xs_parse_keyword("jis_bool", &hooks_jis_bool, NULL);
    register_xs_parse_keyword("jis_null", &hooks_jis_null, NULL);

    /* alias */
    register_xs_parse_keyword("jdecode",  &hooks_jdecode,  NULL);
}

SV *
new(const char *klass)
CODE:
{
    json_yy_t *self;
    HV *hv = newHV();
    Newxz(self, 1, json_yy_t);
    self->flags = F_ALLOW_NONREF;
    self->max_depth = MAX_DEPTH_DEFAULT;
    attach_ext_magic(aTHX_ (SV *)hv, &json_yy_vtbl, self);
    RETVAL = sv_bless(newRV_noinc((SV *)hv), gv_stashpv(klass, GV_ADD));
}
OUTPUT:
    RETVAL

void
_set_utf8(SV *self_sv, int val)
CODE:
    if (val) get_self(aTHX_ self_sv)->flags |= F_UTF8;
    else     get_self(aTHX_ self_sv)->flags &= ~F_UTF8;

void
_set_pretty(SV *self_sv, int val)
CODE:
    if (val) get_self(aTHX_ self_sv)->flags |= F_PRETTY;
    else     get_self(aTHX_ self_sv)->flags &= ~F_PRETTY;

void
_set_canonical(SV *self_sv, int val)
CODE:
    if (val) get_self(aTHX_ self_sv)->flags |= F_CANONICAL;
    else     get_self(aTHX_ self_sv)->flags &= ~F_CANONICAL;

void
_set_allow_nonref(SV *self_sv, int val)
CODE:
    if (val) get_self(aTHX_ self_sv)->flags |= F_ALLOW_NONREF;
    else     get_self(aTHX_ self_sv)->flags &= ~F_ALLOW_NONREF;

void
_set_allow_unknown(SV *self_sv, int val)
CODE:
    if (val) get_self(aTHX_ self_sv)->flags |= F_ALLOW_UNKNOWN;
    else     get_self(aTHX_ self_sv)->flags &= ~F_ALLOW_UNKNOWN;

void
_set_allow_blessed(SV *self_sv, int val)
CODE:
    if (val) get_self(aTHX_ self_sv)->flags |= F_ALLOW_BLESSED;
    else     get_self(aTHX_ self_sv)->flags &= ~F_ALLOW_BLESSED;

void
_set_convert_blessed(SV *self_sv, int val)
CODE:
    if (val) get_self(aTHX_ self_sv)->flags |= F_CONVERT_BLESSED;
    else     get_self(aTHX_ self_sv)->flags &= ~F_CONVERT_BLESSED;

void
_set_max_depth(SV *self_sv, U32 val)
CODE:
{
    json_yy_t *self = get_self(aTHX_ self_sv);
    self->max_depth = val;
}

SV *
decode(SV *self_sv, SV *json_sv)
CODE:
{
    json_yy_t *self = get_self(aTHX_ self_sv);
    STRLEN len;
    const char *json;

    if (self->flags & F_UTF8) {
        json = SvPV(json_sv, len);       /* utf8 mode: input is raw bytes */
    } else {
        json = sv_pv_utf8_nomod(aTHX_ json_sv, &len);   /* character mode: encode to UTF-8 */
    }

    yyjson_read_err err;
    yyjson_doc *doc = yyjson_read_opts((char *)json, len, YYJSON_READ_NOFLAG, NULL, &err);
    if (!doc)
        croak("JSON decode error: %s at byte offset %zu", err.msg, err.pos);
    CHECK_DOC_DEPTH(doc, self->max_depth, "JSON decode error");

    yyjson_val *root = yyjson_doc_get_root(doc);
    if (!root) {
        yyjson_doc_free(doc);
        croak("JSON decode error: empty document");
    }

    /* check nonref */
    if (!(self->flags & F_ALLOW_NONREF)) {
        yyjson_type t = yyjson_get_type(root);
        if (t != YYJSON_TYPE_ARR && t != YYJSON_TYPE_OBJ) {
            yyjson_doc_free(doc);
            croak("JSON text must be an object or array (but found number, string, true, false or null)");
        }
    }

    RETVAL = yyjson_val_to_sv(aTHX_ root, self->max_depth);
    yyjson_doc_free(doc);
    if (!RETVAL)
        croak("JSON decode error: maximum nesting depth exceeded");
}
OUTPUT:
    RETVAL

SV *
decode_doc(SV *self_sv, SV *json_sv)
CODE:
{
    json_yy_t *self = get_self(aTHX_ self_sv);
    STRLEN len;
    const char *json;

    if (self->flags & F_UTF8) {
        json = SvPV(json_sv, len);
    } else {
        json = sv_pv_utf8_nomod(aTHX_ json_sv, &len);
    }

    yyjson_read_err err;
    yyjson_doc *idoc = yyjson_read_opts((char *)json, len, YYJSON_READ_NOFLAG, NULL, &err);
    if (!idoc)
        croak("JSON decode error: %s at byte offset %zu", err.msg, err.pos);
    CHECK_DOC_DEPTH(idoc, self->max_depth, "decode_doc");

    yyjson_mut_doc *mdoc = yyjson_doc_mut_copy(idoc, NULL);
    yyjson_doc_free(idoc);
    if (!mdoc)
        croak("decode_doc: failed to create mutable document");

    yyjson_mut_val *root = yyjson_mut_doc_get_root(mdoc);
    if (!(self->flags & F_ALLOW_NONREF)) {
        yyjson_type t = yyjson_mut_get_type(root);
        if (t != YYJSON_TYPE_ARR && t != YYJSON_TYPE_OBJ) {
            yyjson_mut_doc_free(mdoc);
            croak("JSON text must be an object or array (but found number, string, true, false or null)");
        }
    }
    RETVAL = new_doc_sv(aTHX_ mdoc, root, NULL);
}
OUTPUT:
    RETVAL

SV *
encode(SV *self_sv, SV *data)
CODE:
{
    json_yy_t *self = get_self(aTHX_ self_sv);

    /* check nonref */
    if (!(self->flags & F_ALLOW_NONREF)) {
        if (!SvROK(data) || (SvTYPE(SvRV(data)) != SVt_PVAV && SvTYPE(SvRV(data)) != SVt_PVHV))
            croak("hash- or arrayref expected (not a simple scalar)");
    }

    /* hybrid: use the direct encoder unless a yyjson-only feature (pretty) is
       requested. F_CANONICAL is accepted for JSON::XS compatibility but ignored
       by both paths -- yyjson has no sorted-key writer. */
    if (!(self->flags & F_PRETTY)) {
        RETVAL = newSV(64);
        SvPOK_on(RETVAL);
        SvCUR_set(RETVAL, 0);
        SAVEFREESV(RETVAL);
        direct_encode_sv(aTHX_ RETVAL, data, 0, self);
        SvREFCNT_inc_simple_void_NN(RETVAL);
        *(SvPVX(RETVAL) + SvCUR(RETVAL)) = '\0';
        if (!(self->flags & F_UTF8))
            SvUTF8_on(RETVAL);
    } else {
        /* yyjson path for pretty */
        yyjson_mut_doc *doc = yyjson_mut_doc_new(NULL);
        SV *doc_guard = sv_2mortal(newSV(0));
        attach_ext_magic(aTHX_ doc_guard, &mut_docholder_vtbl, doc);
        yyjson_mut_val *root = sv_to_yyjson_val(aTHX_ doc, data, self, 0);
        yyjson_mut_doc_set_root(doc, root);

        size_t json_len;
        yyjson_write_err werr;
        char *json = yyjson_mut_write_opts(doc, YYJSON_WRITE_PRETTY, NULL, &json_len, &werr);
        /* disarm guard before explicit free */
        mg_findext(doc_guard, PERL_MAGIC_ext, &mut_docholder_vtbl)->mg_ptr = NULL;
        yyjson_mut_doc_free(doc);

        if (!json)
            croak("JSON encode error: %s", werr.msg);

        ENTER;
        SAVEDESTRUCTOR_X(yyjson_free_buf, json);
        if (self->flags & F_UTF8) {
            RETVAL = newSVpvn(json, json_len);
        } else {
            RETVAL = newSVpvn_utf8(json, json_len, 1);
        }
        LEAVE;
    }
}
OUTPUT:
    RETVAL

SV *
_xs_encode_json(SV *data)
CODE:
{
    RETVAL = newSV(64);
    SvPOK_on(RETVAL);
    SvCUR_set(RETVAL, 0);
    SAVEFREESV(RETVAL);
    direct_encode_sv(aTHX_ RETVAL, data, 0, &default_self);
    SvREFCNT_inc_simple_void_NN(RETVAL);
    *(SvPVX(RETVAL) + SvCUR(RETVAL)) = '\0';
}
OUTPUT:
    RETVAL

SV *
_xs_decode_json(SV *json_sv)
CODE:
{
    STRLEN len;
    const char *json = SvPV(json_sv, len);

    yyjson_read_err err;
    yyjson_doc *doc = yyjson_read_opts((char *)json, len, YYJSON_READ_NOFLAG, NULL, &err);
    if (!doc)
        croak("JSON decode error: %s at byte offset %zu", err.msg, err.pos);
    CHECK_DOC_DEPTH(doc, MAX_DEPTH_DEFAULT, "JSON decode error");

    yyjson_val *root = yyjson_doc_get_root(doc);
    if (!root) {
        yyjson_doc_free(doc);
        croak("JSON decode error: empty document");
    }

    RETVAL = yyjson_val_to_sv(aTHX_ root, MAX_DEPTH_DEFAULT);
    yyjson_doc_free(doc);
    if (!RETVAL)
        croak("JSON decode error: maximum nesting depth exceeded");
}
OUTPUT:
    RETVAL

SV *
_xs_decode_json_ro(SV *json_sv)
CODE:
{
    STRLEN len;
    const char *json = SvPV(json_sv, len);

    yyjson_read_err err;
    yyjson_doc *doc = yyjson_read_opts((char *)json, len, YYJSON_READ_NOFLAG, NULL, &err);
    if (!doc)
        croak("JSON decode error: %s at byte offset %zu", err.msg, err.pos);
    CHECK_DOC_DEPTH(doc, MAX_DEPTH_DEFAULT, "JSON decode error");

    yyjson_val *root = yyjson_doc_get_root(doc);
    if (!root) {
        yyjson_doc_free(doc);
        croak("JSON decode error: empty document");
    }

    /* doc ownership transfers to the holder SV */
    SV *doc_sv = new_doc_holder(aTHX_ doc);

    RETVAL = yyjson_val_to_sv_ro(aTHX_ root, doc_sv, MAX_DEPTH_DEFAULT);
    if (!RETVAL) {
        SvREFCNT_dec(doc_sv);
        croak("JSON decode error: maximum nesting depth exceeded");
    }

    /* attach doc_sv to keep yyjson_doc alive while zero-copy SVs exist.
       skip for null/bool -- they return immortal globals. */
    {
        yyjson_type rtype = yyjson_get_type(root);
        if (rtype != YYJSON_TYPE_NULL && rtype != YYJSON_TYPE_BOOL) {
            SV *anchor = SvROK(RETVAL) ? SvRV(RETVAL) : RETVAL;
            sv_magicext(anchor, doc_sv, PERL_MAGIC_ext, &empty_vtbl, NULL, 0);
        }
    }
    SvREFCNT_dec(doc_sv);
}
OUTPUT:
    RETVAL


# XS helpers for Doc overloading

SV *
_doc_stringify(SV *self_sv)
CODE:
{
    json_yy_doc_t *d = get_doc(aTHX_ self_sv);
    size_t json_len;
    yyjson_write_err werr;
    char *json = yyjson_mut_val_write_opts(d->root, YYJSON_WRITE_NOFLAG, NULL, &json_len, &werr);
    if (!json)
        croak("JSON::YY::Doc: stringify error: %s", werr.msg);
    ENTER;
    SAVEDESTRUCTOR_X(yyjson_free_buf, json);
    RETVAL = newSVpvn(json, json_len);
    LEAVE;
}
OUTPUT:
    RETVAL

SV *
_doc_eq(SV *a_sv, SV *b_sv)
CODE:
{
    if (!SvROK(b_sv) || !sv_derived_from(b_sv, "JSON::YY::Doc"))
        XSRETURN_NO;
    json_yy_doc_t *a = get_doc(aTHX_ a_sv);
    json_yy_doc_t *b = get_doc(aTHX_ b_sv);
    RETVAL = yyjson_mut_equals(a->root, b->root)
        ? &PL_sv_yes : &PL_sv_no;
    SvREFCNT_inc_simple_void_NN(RETVAL);
}
OUTPUT:
    RETVAL
