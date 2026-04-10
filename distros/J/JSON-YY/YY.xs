#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

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

/* magic vtable for json_yy_t stored on HV */
static int
json_yy_magic_free(pTHX_ SV *sv, MAGIC *mg) {
    PERL_UNUSED_ARG(sv);
    if (mg->mg_ptr)
        Safefree(mg->mg_ptr);
    return 0;
}

static MGVTBL json_yy_vtbl = {
    NULL, NULL, NULL, NULL,
    json_yy_magic_free,
    NULL, NULL, NULL
};

static inline json_yy_t *
get_self(pTHX_ SV *self_sv) {
    if (!SvROK(self_sv))
        croak("not a JSON::YY object");
    MAGIC *mg = mg_findext(SvRV(self_sv), PERL_MAGIC_ext, &json_yy_vtbl);
    if (!mg)
        croak("corrupted JSON::YY object");
    return (json_yy_t *)mg->mg_ptr;
}

static MGVTBL empty_vtbl = {0};

/* forward declarations */
static inline int is_ascii(const char *s, size_t len);
/* doc holder magic: frees yyjson_doc when SV is destroyed */
static int
docholder_magic_free(pTHX_ SV *sv, MAGIC *mg) {
    PERL_UNUSED_ARG(sv);
    yyjson_doc *doc = (yyjson_doc *)mg->mg_ptr;
    if (doc)
        yyjson_doc_free(doc);
    return 0;
}

/* also used as a guard for yyjson_mut_doc* via mg_ptr cast */
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
    NULL, NULL, NULL
};

static MGVTBL mut_docholder_vtbl = {
    NULL, NULL, NULL, NULL,
    mut_docholder_magic_free,
    NULL, NULL, NULL
};
static SV * yyjson_val_to_sv(pTHX_ yyjson_val *val);
static SV * yyjson_val_to_sv_ro(pTHX_ yyjson_val *val, SV *doc_sv);
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
    NULL, NULL, NULL
};

static inline json_yy_doc_t *
get_doc(pTHX_ SV *sv) {
    if (!SvROK(sv))
        croak("not a JSON::YY::Doc object");
    MAGIC *mg = mg_findext(SvRV(sv), PERL_MAGIC_ext, &json_yy_doc_vtbl);
    if (!mg)
        croak("corrupted JSON::YY::Doc object");
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
    sv_magicext((SV *)hv, NULL, PERL_MAGIC_ext, &json_yy_doc_vtbl,
                (const char *)d, 0);
    return sv_bless(newRV_noinc((SV *)hv),
                    gv_stashpvs("JSON::YY::Doc", GV_ADD));
}

/* resolve a path on a Doc, returning the yyjson_mut_val* or NULL.
   path must be UTF-8 encoded (use SvPVutf8 on caller side). */
static inline yyjson_mut_val *
doc_resolve_path(pTHX_ json_yy_doc_t *d, const char *path, STRLEN path_len) {
    if (path_len == 0)
        return d->root;
    return yyjson_mut_ptr_getn(d->root, path, path_len);
}


/* forward decl */
static SV * yyjson_mut_val_to_sv(pTHX_ yyjson_mut_val *val);

/* ---- keyword plugin: Doc keyword ops ---- */

/* pp_jdoc: parse JSON string → Doc */
static OP * pp_jdoc_impl(pTHX) {
    dSP;
    SV *json_sv = POPs;
    STRLEN len;
    const char *json = SvPVutf8(json_sv, len);

    yyjson_read_err err;
    yyjson_doc *idoc = yyjson_read_opts((char *)json, len, YYJSON_READ_NOFLAG, NULL, &err);
    if (!idoc)
        croak("jdoc: JSON parse error: %s at byte offset %zu", err.msg, err.pos);

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
    const char *path = SvPVutf8(path_sv, path_len);

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
    const char *path = SvPVutf8(path_sv, path_len);

    yyjson_mut_val *val = doc_resolve_path(aTHX_ d, path, path_len);
    if (!val) {
        XPUSHs(&PL_sv_undef);
        RETURN;
    }

    SV *result = yyjson_mut_val_to_sv(aTHX_ val);
    XPUSHs(sv_2mortal(result));
    RETURN;
}

/* pp_jset: set value at path */
static OP * pp_jset_impl(pTHX) {
    dSP;
    SV *value_sv = POPs;
    SV *path_sv = POPs;
    SV *doc_sv = POPs;
    json_yy_doc_t *d = get_doc(aTHX_ doc_sv);
    STRLEN path_len;
    const char *path = SvPVutf8(path_sv, path_len);

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
        self_stack.flags = F_UTF8 | F_ALLOW_NONREF | F_ALLOW_BLESSED;
        self_stack.max_depth = MAX_DEPTH_DEFAULT;
        new_val = sv_to_yyjson_val(aTHX_ d->doc, value_sv, &self_stack, 0);
    }

    if (path_len == 0) {
        if (d->owner)
            croak("jset: cannot replace root of a borrowed Doc; jclone it first");
        yyjson_mut_doc_set_root(d->doc, new_val);
        d->root = new_val;
    } else {
        yyjson_ptr_err perr;
        /* try set first; if path ends with /- (array append), use add instead */
        bool ok = yyjson_mut_doc_ptr_setx(d->doc, path, path_len, new_val,
                                           true, NULL, &perr);
        if (!ok) {
            /* retry with add (handles /- array append) */
            perr = (yyjson_ptr_err){0};
            ok = yyjson_mut_doc_ptr_addx(d->doc, path, path_len, new_val,
                                          true, NULL, &perr);
        }
        if (!ok)
            croak("jset: failed to set path %.*s: %s",
                  (int)path_len, path, perr.msg ? perr.msg : "unknown error");
    }

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
    const char *path = SvPVutf8(path_sv, path_len);

    if (path_len == 0)
        croak("jdel: cannot delete root");

    yyjson_ptr_ctx ctx = {0};
    yyjson_ptr_err perr;
    yyjson_mut_val *removed = yyjson_mut_doc_ptr_removex(d->doc, path, path_len,
                                                          &ctx, &perr);
    if (!removed) {
        XPUSHs(&PL_sv_undef);
        RETURN;
    }

    /* deep copy removed val into independent doc (safe from parent mutations) */
    yyjson_mut_doc *new_doc = yyjson_mut_doc_new(NULL);
    yyjson_mut_val *copy = yyjson_mut_val_mut_copy(new_doc, removed);
    yyjson_mut_doc_set_root(new_doc, copy);
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
    const char *path = SvPVutf8(path_sv, path_len);

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
    const char *path = SvPVutf8(path_sv, path_len);

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
    const char *path = SvPVutf8(path_sv, path_len);

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

    SV *result = newSVpvn(json, json_len);
    free(json);
    XPUSHs(sv_2mortal(result));
    RETURN;
}

/* pp_jstr: create JSON string value */
static OP * pp_jstr_impl(pTHX) {
    dSP;
    SV *val_sv = POPs;
    STRLEN len;
    const char *str = SvPVutf8(val_sv, len);
    yyjson_mut_doc *doc = yyjson_mut_doc_new(NULL);
    yyjson_mut_val *root = yyjson_mut_strncpy(doc, str, len);
    yyjson_mut_doc_set_root(doc, root);
    XPUSHs(sv_2mortal(new_doc_sv(aTHX_ doc, root, NULL)));
    RETURN;
}

/* pp_jnum: create JSON number value */
static OP * pp_jnum_impl(pTHX) {
    dSP;
    SV *val_sv = POPs;
    yyjson_mut_doc *doc = yyjson_mut_doc_new(NULL);
    yyjson_mut_val *root;
    if (SvIOK(val_sv)) {
        if (SvIsUV(val_sv))
            root = yyjson_mut_uint(doc, (uint64_t)SvUVX(val_sv));
        else
            root = yyjson_mut_sint(doc, (int64_t)SvIVX(val_sv));
    } else {
        root = yyjson_mut_real(doc, SvNV(val_sv));
    }
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
    const char *path = SvPVutf8(path_sv, path_len);

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
    const char *path = SvPVutf8(path_sv, path_len);

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
    const char *path = SvPVutf8(path_sv, path_len);

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
    NULL, NULL, NULL
};

static inline json_yy_iter_t *
get_iter(pTHX_ SV *sv) {
    if (!SvROK(sv))
        croak("not a JSON::YY::Iter object");
    MAGIC *mg = mg_findext(SvRV(sv), PERL_MAGIC_ext, &json_yy_iter_vtbl);
    if (!mg)
        croak("corrupted JSON::YY::Iter object");
    return (json_yy_iter_t *)mg->mg_ptr;
}

/* pp_jiter: create iterator for array/object at path */
static OP * pp_jiter_impl(pTHX) {
    dSP;
    SV *path_sv = POPs;
    SV *doc_sv = POPs;
    json_yy_doc_t *d = get_doc(aTHX_ doc_sv);
    STRLEN path_len;
    const char *path = SvPVutf8(path_sv, path_len);

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
    sv_magicext((SV *)hv, NULL, PERL_MAGIC_ext, &json_yy_iter_vtbl,
                (const char *)it, 0);
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
    self_stack.flags = F_UTF8 | F_ALLOW_NONREF | F_ALLOW_BLESSED;
    self_stack.max_depth = MAX_DEPTH_DEFAULT;

    /* wrap doc in a holder SV so it's freed on croak */
    SV *guard = newSV(0);
    sv_magicext(guard, NULL, PERL_MAGIC_ext, &mut_docholder_vtbl,
                (const char *)doc, 0);
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
    const char *path = SvPVutf8(path_sv, path_len);

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
    const char *path = SvPVutf8(path_sv, path_len);

    yyjson_mut_val *val = doc_resolve_path(aTHX_ d, path, path_len);
    if (!val)
        croak("jpp: path not found: %.*s", (int)path_len, path);

    size_t json_len;
    yyjson_write_err werr;
    char *json = yyjson_mut_val_write_opts(val, YYJSON_WRITE_PRETTY, NULL,
                                            &json_len, &werr);
    if (!json)
        croak("jpp: write error: %s", werr.msg);
    SV *result = newSVpvn(json, json_len);
    free(json);
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
    const char *path = SvPVutf8(path_sv, path_len);
    STRLEN json_len;
    const char *json = SvPVutf8(json_sv, json_len);

    /* parse the raw JSON fragment */
    yyjson_doc *idoc = yyjson_read(json, json_len, YYJSON_READ_NOFLAG);
    if (!idoc)
        croak("jraw: invalid JSON fragment");

    /* copy into mutable doc */
    yyjson_val *iroot = yyjson_doc_get_root(idoc);
    yyjson_mut_val *new_val = yyjson_val_mut_copy(d->doc, iroot);
    yyjson_doc_free(idoc);

    if (!new_val)
        croak("jraw: failed to copy value");

    if (path_len == 0) {
        if (d->owner)
            croak("jraw: cannot replace root of a borrowed Doc; jclone it first");
        yyjson_mut_doc_set_root(d->doc, new_val);
        d->root = new_val;
    } else {
        yyjson_ptr_err perr;
        bool ok = yyjson_mut_doc_ptr_setx(d->doc, path, path_len, new_val,
                                           true, NULL, &perr);
        if (!ok) {
            perr = (yyjson_ptr_err){0};
            ok = yyjson_mut_doc_ptr_addx(d->doc, path, path_len, new_val,
                                          true, NULL, &perr);
        }
        if (!ok)
            croak("jraw: failed to set path %.*s: %s",
                  (int)path_len, path, perr.msg ? perr.msg : "unknown error");
    }

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
    const char *path = SvPVutf8(path_sv, path_len); \
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
    yyjson_mut_val *copy = yyjson_mut_val_mut_copy(tmp_doc, d->root);
    yyjson_mut_doc_set_root(tmp_doc, copy);

    bool ok = yyjson_mut_write_file(path, tmp_doc, YYJSON_WRITE_PRETTY, NULL, &werr);
    yyjson_mut_doc_free(tmp_doc);

    if (!ok)
        croak("jwrite: %s: %s", path, werr.msg ? werr.msg : "write failed");

    XPUSHs(doc_sv);
    RETURN;
}

/* pp_jpaths: enumerate all leaf paths */

static void
collect_paths(pTHX_ yyjson_mut_val *val, SV *prefix, AV *result) {
    if (yyjson_mut_is_obj(val)) {
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
                collect_paths(aTHX_ v, path, result);
                SvREFCNT_dec(path);  /* path was used as prefix, not pushed */
            } else {
                av_push(result, path);  /* transfers ownership */
            }
        }
    } else if (yyjson_mut_is_arr(val)) {
        size_t idx, max;
        yyjson_mut_val *item;
        yyjson_mut_arr_foreach(val, idx, max, item) {
            SV *path = newSVsv(prefix);
            sv_catpvs(path, "/");
            char idxbuf[24];
            int idxlen = snprintf(idxbuf, sizeof(idxbuf), "%zu", idx);
            sv_catpvn(path, idxbuf, idxlen);
            if (yyjson_mut_is_obj(item) || yyjson_mut_is_arr(item)) {
                collect_paths(aTHX_ item, path, result);
                SvREFCNT_dec(path);
            } else {
                av_push(result, path);
            }
        }
    } else {
        /* leaf -- the prefix itself is the path */
        av_push(result, newSVsv(prefix));
    }
}

static OP * pp_jpaths_impl(pTHX) {
    dSP;
    SV *path_sv = POPs;
    SV *doc_sv = POPs;
    json_yy_doc_t *d = get_doc(aTHX_ doc_sv);
    STRLEN path_len;
    const char *path = SvPVutf8(path_sv, path_len);

    yyjson_mut_val *val = doc_resolve_path(aTHX_ d, path, path_len);
    if (!val)
        croak("jpaths: path not found: %.*s", (int)path_len, path);

    AV *paths = newAV();
    SV *prefix = newSVpvn(path, path_len);
    collect_paths(aTHX_ val, prefix, paths);
    SvREFCNT_dec(prefix);

    SSize_t count = av_len(paths) + 1;
    EXTEND(SP, count);
    for (SSize_t i = 0; i < count; i++) {
        SV **svp = av_fetch(paths, i, 0);
        PUSHs(sv_2mortal(SvREFCNT_inc(*svp)));
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
    const char *path = SvPVutf8(path_sv, path_len);
    const char *key = SvPVutf8(key_sv, key_len);
    const char *match = SvPVutf8(match_sv, match_len);

    yyjson_mut_val *arr = doc_resolve_path(aTHX_ d, path, path_len);
    if (!arr || !yyjson_mut_is_arr(arr)) {
        XPUSHs(&PL_sv_undef);
        RETURN;
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
        /* compare: number match (convert match string to number) */
        else if (yyjson_mut_is_num(field)) {
            NV match_nv = SvNV(match_sv);
            NV field_nv = yyjson_mut_get_num(field);
            if (match_nv == field_nv) {
                SV *result = new_doc_sv(aTHX_ d->doc, item, doc_sv);
                XPUSHs(sv_2mortal(result));
                RETURN;
            }
        }
        /* compare: bool/null -- match against string "true"/"false"/"null" */
        else if (yyjson_mut_is_bool(field)) {
            bool bval = yyjson_mut_get_bool(field);
            if ((bval && match_len == 4 && memcmp(match, "true", 4) == 0) ||
                (!bval && match_len == 5 && memcmp(match, "false", 5) == 0)) {
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

/* ---- zero-copy string SV (no per-SV magic, minimal overhead) ---- */
/* SvLEN=0 tells Perl it doesn't own the buffer.
   Perl will allocate+copy if someone does sv_setsv from this SV,
   so extracted values are always safe.
   The yyjson_doc lifetime is managed by magic on the ROOT container only. */
static inline SV *
new_sv_zerocopy(pTHX_ const char *str, size_t len) {
    SV *sv = newSV_type(SVt_PV);
    SvPV_set(sv, (char *)str);
    SvCUR_set(sv, len);
    SvLEN_set(sv, 0);
    SvPOK_on(sv);
    if (!is_ascii(str, len))
        SvUTF8_on(sv);
    SvREADONLY_on(sv);
    return sv;
}

/* ---- DECODE: yyjson value -> Perl SV ---- */

static SV *
yyjson_val_to_sv(pTHX_ yyjson_val *val) {
    switch (yyjson_get_type(val)) {
        case YYJSON_TYPE_NULL:
            return SvREFCNT_inc_simple_NN(&PL_sv_undef);

        case YYJSON_TYPE_BOOL:
            return yyjson_get_bool(val)
                ? SvREFCNT_inc_simple_NN(&PL_sv_yes)
                : SvREFCNT_inc_simple_NN(&PL_sv_no);

        case YYJSON_TYPE_NUM: {
            yyjson_subtype st = yyjson_get_subtype(val);
            if (st == YYJSON_SUBTYPE_UINT)
                return newSVuv((UV)yyjson_get_uint(val));
            else if (st == YYJSON_SUBTYPE_SINT)
                return newSViv((IV)yyjson_get_sint(val));
            else
                return newSVnv(yyjson_get_real(val));
        }

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
            size_t count = yyjson_arr_size(val);
            AV *av = newAV();
            if (count > 0)
                av_extend(av, (SSize_t)count - 1);
            SV *rv = newRV_noinc((SV *)av);
            size_t idx, max;
            yyjson_val *item;
            yyjson_arr_foreach(val, idx, max, item) {
                av_push(av, yyjson_val_to_sv(aTHX_ item));
            }
            return rv;
        }

        case YYJSON_TYPE_OBJ: {
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
                SV *val_sv = yyjson_val_to_sv(aTHX_ value);
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
yyjson_mut_val_to_sv(pTHX_ yyjson_mut_val *val) {
    switch (yyjson_mut_get_type(val)) {
        case YYJSON_TYPE_NULL:
            return SvREFCNT_inc_simple_NN(&PL_sv_undef);

        case YYJSON_TYPE_BOOL:
            return yyjson_mut_get_bool(val)
                ? SvREFCNT_inc_simple_NN(&PL_sv_yes)
                : SvREFCNT_inc_simple_NN(&PL_sv_no);

        case YYJSON_TYPE_NUM: {
            yyjson_subtype st = yyjson_mut_get_subtype(val);
            if (st == YYJSON_SUBTYPE_UINT)
                return newSVuv((UV)yyjson_mut_get_uint(val));
            else if (st == YYJSON_SUBTYPE_SINT)
                return newSViv((IV)yyjson_mut_get_sint(val));
            else
                return newSVnv(yyjson_mut_get_real(val));
        }

        case YYJSON_TYPE_STR: {
            const char *str = yyjson_mut_get_str(val);
            size_t len = yyjson_mut_get_len(val);
            SV *sv = newSVpvn(str, len);
            if (!is_ascii(str, len))
                SvUTF8_on(sv);
            return sv;
        }

        case YYJSON_TYPE_ARR: {
            size_t count = yyjson_mut_arr_size(val);
            AV *av = newAV();
            if (count > 0)
                av_extend(av, (SSize_t)count - 1);
            SV *rv = newRV_noinc((SV *)av);
            size_t idx, max;
            yyjson_mut_val *item;
            yyjson_mut_arr_foreach(val, idx, max, item) {
                av_push(av, yyjson_mut_val_to_sv(aTHX_ item));
            }
            return rv;
        }

        case YYJSON_TYPE_OBJ: {
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
                SV *val_sv = yyjson_mut_val_to_sv(aTHX_ value);
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
yyjson_val_to_sv_ro(pTHX_ yyjson_val *val, SV *doc_sv) {
    switch (yyjson_get_type(val)) {
        case YYJSON_TYPE_NULL:
            return SvREFCNT_inc_simple_NN(&PL_sv_undef);

        case YYJSON_TYPE_BOOL:
            return yyjson_get_bool(val)
                ? SvREFCNT_inc_simple_NN(&PL_sv_yes)
                : SvREFCNT_inc_simple_NN(&PL_sv_no);

        case YYJSON_TYPE_NUM: {
            SV *nsv;
            yyjson_subtype st = yyjson_get_subtype(val);
            if (st == YYJSON_SUBTYPE_UINT)
                nsv = newSVuv((UV)yyjson_get_uint(val));
            else if (st == YYJSON_SUBTYPE_SINT)
                nsv = newSViv((IV)yyjson_get_sint(val));
            else
                nsv = newSVnv(yyjson_get_real(val));
            SvREADONLY_on(nsv);
            return nsv;
        }

        case YYJSON_TYPE_STR:
            /* zero-copy: SV borrows string memory from yyjson_doc */
            return new_sv_zerocopy(aTHX_
                yyjson_get_str(val), yyjson_get_len(val));

        case YYJSON_TYPE_ARR: {
            size_t count = yyjson_arr_size(val);
            AV *av = newAV();
            if (count > 0)
                av_extend(av, (SSize_t)count - 1);
            SV *rv = newRV_noinc((SV *)av);
            size_t idx, max;
            yyjson_val *item;
            yyjson_arr_foreach(val, idx, max, item) {
                av_push(av, yyjson_val_to_sv_ro(aTHX_ item, doc_sv));
            }
            SvREADONLY_on((SV *)av);
            return rv;
        }

        case YYJSON_TYPE_OBJ: {
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
                SV *val_sv = yyjson_val_to_sv_ro(aTHX_ value, doc_sv);
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

/* create a doc-holder SV: an opaque SV that frees yyjson_doc when destroyed */
static SV *
new_doc_holder(pTHX_ yyjson_doc *doc) {
    SV *sv = newSV(0);
    sv_magicext(sv, NULL, PERL_MAGIC_ext, &docholder_magic_vtbl,
                (const char *)doc, 0);
    return sv;
}

/* ---- DIRECT ENCODE: single-pass SV -> JSON bytes ---- */
/* Bypasses yyjson_mut_doc entirely for maximum throughput */

/* escape table: 0 = passthrough, 1+ = needs escaping */
static const uint8_t escape_table[256] = {
    /* 0x00-0x1f: control characters need \uXXXX */
    1,1,1,1,1,1,1,1, 'b','t','n',1,'f','r',1,1,
    1,1,1,1,1,1,1,1, 1,1,1,1,1,1,1,1,
    /* 0x20-0x7f */
    0,0,'"',0,0,0,0,0, 0,0,0,0,0,0,0,0,  /* " at 0x22 */
    0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,  /* 0x30-0x3f */
    0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,  /* 0x40-0x4f */
    0,0,0,0,0,0,0,0, 0,0,0,0,'\\',0,0,0, /* \\ at 0x5c */
    0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
    /* 0x80-0xff: high bytes, pass through (valid UTF-8) */
    0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
};

/* ensure buf SV has room for `need` more bytes */
static inline void
buf_ensure(pTHX_ SV *buf, size_t need) {
    STRLEN cur = SvCUR(buf);
    STRLEN avail = SvLEN(buf) - cur - 1;
    if (avail < need) {
        STRLEN newlen = (cur + need + 1) * 2;
        SvGROW(buf, newlen);
    }
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

/* check if string needs any escaping */
static inline int
needs_escape(const char *s, size_t len) {
    /* check 8 bytes at a time for common case (no control chars, no " or \) */
    /* bytes needing escape: 0x00-0x1f, 0x22 ("), 0x5c (\) */
    const unsigned char *p = (const unsigned char *)s;
    size_t i = 0;
    for (; i + 7 < len; i += 8) {
        /* any byte < 0x20? */
        uint64_t chunk;
        memcpy(&chunk, p + i, 8);
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
        if (escape_table[p[i]])
            return 1;
    }
    return 0;
}

static void
buf_cat_escaped_str(pTHX_ SV *buf, const char *s, size_t len) {
    /* fast path: no escaping needed (very common for JSON keys/values) */
    if (!needs_escape(s, len)) {
        buf_ensure(aTHX_ buf, len + 2);
        char *out = SvPVX(buf) + SvCUR(buf);
        *out++ = '"';
        memcpy(out, s, len);
        out += len;
        *out++ = '"';
        SvCUR_set(buf, out - SvPVX(buf));
        return;
    }

    /* slow path: need escaping */
    static const char hex_digits[] = "0123456789abcdef";
    buf_ensure(aTHX_ buf, len + 2 + 16); /* some headroom */
    char *out = SvPVX(buf) + SvCUR(buf);
    char *out_end = SvPVX(buf) + SvLEN(buf) - 1;
    *out++ = '"';

    const char *end = s + len;
    while (s < end) {
        /* ensure we have room for at least one escaped char */
        if (out + 8 > out_end) {
            SvCUR_set(buf, out - SvPVX(buf));
            buf_ensure(aTHX_ buf, (end - s) * 2 + 8);
            out = SvPVX(buf) + SvCUR(buf);
            out_end = SvPVX(buf) + SvLEN(buf) - 1;
        }

        unsigned char c = *s;
        uint8_t esc = escape_table[c];
        if (!esc) {
            /* scan for run of safe chars */
            const char *safe = s + 1;
            while (safe < end && !escape_table[(unsigned char)*safe])
                safe++;
            size_t n = safe - s;
            if (out + n > out_end) {
                SvCUR_set(buf, out - SvPVX(buf));
                buf_ensure(aTHX_ buf, n + (end - safe) * 2 + 8);
                out = SvPVX(buf) + SvCUR(buf);
                out_end = SvPVX(buf) + SvLEN(buf) - 1;
            }
            memcpy(out, s, n);
            out += n;
            s = safe;
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
    buf_ensure(aTHX_ buf, 40);
    char *p = SvPVX(buf) + SvCUR(buf);
    Gconvert(val, NV_DIG, 0, p);
    int len = strlen(p);
    SvCUR_set(buf, SvCUR(buf) + len);
}

static json_yy_t default_self = { F_UTF8 | F_ALLOW_NONREF, MAX_DEPTH_DEFAULT };

static void
direct_encode_sv(pTHX_ SV *buf, SV *sv, U32 depth, json_yy_t *self) {
    if (depth > self->max_depth)
        croak("maximum nesting depth exceeded");

    if (!SvOK(sv)) {
        buf_cat_mem(aTHX_ buf, "null", 4);
        return;
    }

    if (SvROK(sv)) {
        SV *deref = SvRV(sv);

        if (SvOBJECT(deref)) {
            if (self->flags & F_CONVERT_BLESSED) {
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
                direct_encode_sv(aTHX_ buf, result, depth, self);
                SvREFCNT_dec(result);
                return;
            }
            if (self->flags & F_ALLOW_BLESSED) {
                buf_cat_mem(aTHX_ buf, "null", 4);
                return;
            }
            croak("encountered object '%s', but allow_blessed/convert_blessed is not enabled",
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
            buf_cat_c(aTHX_ buf, '{');
            hv_iterinit(hv);
            HE *he;
            int first = 1;
            while ((he = hv_iternext(hv))) {
                if (!first) buf_cat_c(aTHX_ buf, ',');
                first = 0;
                STRLEN klen;
                const char *kstr = HePV(he, klen);
                buf_cat_escaped_str(aTHX_ buf, kstr, klen);
                buf_cat_c(aTHX_ buf, ':');
                direct_encode_sv(aTHX_ buf, HeVAL(he), depth + 1, self);
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

    if (SvIOK(sv)) {
        if (SvIsUV(sv))
            buf_cat_uv(aTHX_ buf, SvUVX(sv));
        else
            buf_cat_iv(aTHX_ buf, SvIVX(sv));
        return;
    }

    if (SvNOK(sv)) {
        NV nv = SvNVX(sv);
        if (Perl_isnan(nv) || Perl_isinf(nv))
            croak("cannot encode NaN or Infinity as JSON");
        buf_cat_nv(aTHX_ buf, nv);
        return;
    }

    if (SvPOK(sv)) {
        STRLEN len;
        const char *str = SvPV(sv, len);
        buf_cat_escaped_str(aTHX_ buf, str, len);
        return;
    }

    buf_cat_mem(aTHX_ buf, "null", 4);
}

/* ---- ENCODE: Perl SV -> yyjson mutable value (used for OO API) ---- */

static yyjson_mut_val *
sv_to_yyjson_val(pTHX_ yyjson_mut_doc *doc, SV *sv, json_yy_t *self, U32 depth) {
    if (depth > self->max_depth)
        croak("maximum nesting depth exceeded");

    if (!SvOK(sv))
        return yyjson_mut_null(doc);

    if (SvROK(sv)) {
        SV *deref = SvRV(sv);

        /* check for blessed objects */
        if (SvOBJECT(deref)) {
            /* convert_blessed: call TO_JSON */
            if (self->flags & F_CONVERT_BLESSED) {
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
                yyjson_mut_val *ret = sv_to_yyjson_val(aTHX_ doc, result, self, depth);
                SvREFCNT_dec(result);
                return ret;
            }
            /* allow_blessed: encode as null */
            if (self->flags & F_ALLOW_BLESSED)
                return yyjson_mut_null(doc);
            croak("encountered object '%s', but allow_blessed/convert_blessed is not enabled",
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
                yyjson_mut_val *obj = yyjson_mut_obj(doc);
                hv_iterinit(hv);
                HE *he;
                while ((he = hv_iternext(hv))) {
                    STRLEN klen;
                    const char *kstr = HePV(he, klen);
                    SV *val = HeVAL(he);
                    yyjson_mut_val *k = yyjson_mut_strncpy(doc, kstr, klen);
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

    /* check for boolean (JSON::PP::Boolean, Types::Serialiser::Boolean, etc.) */
    /* SvIOK first for speed */
    if (SvIOK(sv)) {
        if (SvIsUV(sv))
            return yyjson_mut_uint(doc, (uint64_t)SvUVX(sv));
        return yyjson_mut_sint(doc, (int64_t)SvIVX(sv));
    }

    if (SvNOK(sv)) {
        NV nv = SvNVX(sv);
        if (Perl_isnan(nv) || Perl_isinf(nv))
            croak("cannot encode NaN or Infinity as JSON");
        return yyjson_mut_real(doc, nv);
    }

    if (SvPOK(sv)) {
        STRLEN len;
        const char *str = SvPV(sv, len);
        return yyjson_mut_strncpy(doc, str, len);
    }

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

    yyjson_val *root = yyjson_doc_get_root(doc);
    if (!root) {
        yyjson_doc_free(doc);
        croak("JSON decode error: empty document");
    }

    SV *result = yyjson_val_to_sv(aTHX_ root);
    yyjson_doc_free(doc);

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
    direct_encode_sv(aTHX_ result, data, 0, &default_self);
    *(SvPVX(result) + SvCUR(result)) = '\0';

    XPUSHs(sv_2mortal(result));
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

    yyjson_val *root = yyjson_doc_get_root(doc);
    if (!root) {
        yyjson_doc_free(doc);
        croak("JSON decode error: empty document");
    }

    SV *doc_sv = new_doc_holder(aTHX_ doc);
    SV *result = yyjson_val_to_sv_ro(aTHX_ root, doc_sv);

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
    PERL_UNUSED_ARG(args); PERL_UNUSED_ARG(nargs); PERL_UNUSED_ARG(hookdata); \
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
    sv_magicext((SV *)hv, NULL, PERL_MAGIC_ext, &json_yy_vtbl,
                (const char *)self, 0);
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
        json = SvPVutf8(json_sv, len);   /* character mode: encode to UTF-8 */
    }

    yyjson_read_err err;
    yyjson_doc *doc = yyjson_read_opts((char *)json, len, YYJSON_READ_NOFLAG, NULL, &err);
    if (!doc)
        croak("JSON decode error: %s at byte offset %zu", err.msg, err.pos);

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

    RETVAL = yyjson_val_to_sv(aTHX_ root);
    yyjson_doc_free(doc);
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
        json = SvPVutf8(json_sv, len);
    }

    yyjson_read_err err;
    yyjson_doc *idoc = yyjson_read_opts((char *)json, len, YYJSON_READ_NOFLAG, NULL, &err);
    if (!idoc)
        croak("JSON decode error: %s at byte offset %zu", err.msg, err.pos);

    yyjson_mut_doc *mdoc = yyjson_doc_mut_copy(idoc, NULL);
    yyjson_doc_free(idoc);
    if (!mdoc)
        croak("decode_doc: failed to create mutable document");

    yyjson_mut_val *root = yyjson_mut_doc_get_root(mdoc);
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

    /* hybrid: use direct encoder when no yyjson-specific features needed.
       note: F_CANONICAL is accepted but not yet implemented (yyjson has no sort-keys).
       canonical mode falls through to yyjson path which also doesn't sort,
       so at least the output is consistent. */
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
        sv_magicext(doc_guard, NULL, PERL_MAGIC_ext, &mut_docholder_vtbl,
                    (const char *)doc, 0);
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

        if (self->flags & F_UTF8) {
            RETVAL = newSVpvn(json, json_len);
        } else {
            RETVAL = newSVpvn_utf8(json, json_len, 1);
        }
        free(json);
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

    yyjson_val *root = yyjson_doc_get_root(doc);
    if (!root) {
        yyjson_doc_free(doc);
        croak("JSON decode error: empty document");
    }

    RETVAL = yyjson_val_to_sv(aTHX_ root);
    yyjson_doc_free(doc);
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

    yyjson_val *root = yyjson_doc_get_root(doc);
    if (!root) {
        yyjson_doc_free(doc);
        croak("JSON decode error: empty document");
    }

    /* doc ownership transfers to the holder SV */
    SV *doc_sv = new_doc_holder(aTHX_ doc);

    RETVAL = yyjson_val_to_sv_ro(aTHX_ root, doc_sv);

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
    RETVAL = newSVpvn(json, json_len);
    free(json);
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
