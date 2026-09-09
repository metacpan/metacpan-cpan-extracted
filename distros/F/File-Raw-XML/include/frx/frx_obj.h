#ifndef FRX_OBJ_H
#define FRX_OBJ_H

/* The SV layer: blessing, the owner reference, the invocant checks, the
 * options, and strings across the seam.
 *
 * THE DOCUMENT is a blessed IV whose referent carries PERL_MAGIC_ext with
 * the frx_doc * in mg_ptr and a vtable whose free hook calls frx_doc_free.
 * Scope exit, undef and global destruction are all covered with no Perl
 * DESTROY, the way Markdown::Simple holds its session.
 *
 * THE NODE is a blessed IV whose referent carries PERL_MAGIC_ext with the
 * frx_node * in mg_ptr AND THE DOCUMENT'S INNER IV AS mg_obj. This is the
 * owner reference, and it is the pattern no other dist in the family has:
 *
 *     sv_magicext(iv, doc_iv, PERL_MAGIC_ext, &frx_node_vtbl, (const char *)node, 0);
 *
 * sv_magicext with a non-NULL obj that is not the SV itself increments
 * the obj's reference count and sets MGf_REFCOUNTED, and mg_free
 * decrements it when the node's referent is freed. So a node holds its
 * document at +1 with no DESTROY, no AV to carry, and a free order the
 * reference counts enforce: the document cannot be freed while a node is
 * alive, because the node is what keeps it alive. $node->doc is
 * newRV_inc(mg->mg_obj): the referent is what sv_bless blessed, so the RV
 * is the same object. PDF::Make blesses child nodes into a tree with
 * nothing keeping the tree alive, and that is the use after free this
 * exists to make impossible.
 *
 * ithreads: the magic is not marked MGf_DUP, so a cloned interpreter's
 * copy of a document or node is an IV with no magic, and every method on
 * it croaks "not a File::Raw::XML::Document". The objects are not
 * shareable across threads, and the POD says so.
 *
 * STRINGS: names, attribute values and text cross the seam as character
 * strings, SvUTF8 on, because they are validated UTF-8 and a Perl caller
 * expects characters. Canonical output crosses as bytes, flag off,
 * because a signature is over bytes, not characters. Input is
 * taken as the SV's UTF-8 bytes when flagged and its raw bytes otherwise;
 * the lexer refuses anything that is not UTF-8, with an offset.
 *
 * Needs the perl headers, frx_abi.h, frx_tree.h, frx_parse.h. */

#define FRX_DOC_CLASS  "File::Raw::XML::Document"
#define FRX_NODE_CLASS "File::Raw::XML::Node"

static int
frx_doc_mg_free(pTHX_ SV *sv, MAGIC *mg)
{
    frx_doc *d = (frx_doc *)mg->mg_ptr;
    PERL_UNUSED_ARG(sv);
    if (d) {
        frx_doc_free(d);
        mg->mg_ptr = NULL;
    }
    return 0;
}

static MGVTBL frx_doc_vtbl  = { NULL, NULL, NULL, NULL, frx_doc_mg_free, NULL, NULL, NULL };
/* a node frees nothing of its own; mg_free releases mg_obj, the document */
static MGVTBL frx_node_vtbl = { NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL };

/* the document, +1, blessed */
static SV *
frx_doc_bless(pTHX_ frx_doc *d)
{
    SV *iv = newSViv(0);
    sv_magicext(iv, NULL, PERL_MAGIC_ext, &frx_doc_vtbl, (const char *)d, 0);
    return sv_bless(newRV_noinc(iv), gv_stashpv(FRX_DOC_CLASS, GV_ADD));
}

/* a node of the document whose inner IV is doc_iv, +1, blessed */
static SV *
frx_node_bless(pTHX_ SV *doc_iv, const frx_node *n)
{
    SV *iv = newSViv(0);
    sv_magicext(iv, doc_iv, PERL_MAGIC_ext, &frx_node_vtbl, (const char *)n, 0);
    return sv_bless(newRV_noinc(iv), gv_stashpv(FRX_NODE_CLASS, GV_ADD));
}

static MAGIC *
frx_obj_magic(pTHX_ SV *sv, const MGVTBL *vtbl)
{
    if (!sv || !SvROK(sv)) return NULL;
    sv = SvRV(sv);
    if (!SvOBJECT(sv) || SvTYPE(sv) >= SVt_PVAV) return NULL;
    return mg_findext(sv, PERL_MAGIC_ext, vtbl);
}

/* the frx_doc behind a Document invocant; croaks naming the method */
static frx_doc *
frx_doc_from_sv(pTHX_ SV *sv, const char *meth)
{
    MAGIC *mg = frx_obj_magic(aTHX_ sv, &frx_doc_vtbl);
    if (!mg || !mg->mg_ptr)
        croak("File::Raw::XML: %s: the invocant is not a " FRX_DOC_CLASS, meth);
    return (frx_doc *)mg->mg_ptr;
}

/* the frx_node behind a Node invocant, and its document's inner IV */
static const frx_node *
frx_node_from_sv(pTHX_ SV *sv, const char *meth, SV **doc_iv)
{
    MAGIC *mg = frx_obj_magic(aTHX_ sv, &frx_node_vtbl);
    if (!mg || !mg->mg_ptr || !mg->mg_obj)
        croak("File::Raw::XML: %s: the invocant is not a " FRX_NODE_CLASS, meth);
    if (doc_iv) *doc_iv = mg->mg_obj;
    return (const frx_node *)mg->mg_ptr;
}

/* the document behind a node, as a +1 blessed RV */
static SV *
frx_node_doc_rv(pTHX_ SV *doc_iv)
{
    return newRV_inc(doc_iv);
}

/* ---- the C ABI's SV bridge ------------------------------------------------
 *
 * Declared in frx_abi_impl.h, which the table needs and which is included
 * before this file. These are the entries a consumer crosses between a
 * handle and a blessed object with.
 *
 * The two unwrapping entries answer NULL where the invocant forms above
 * croak. A consumer uses them as the type test - Punk asks "is this thing a
 * document?" of every object a handler returns - and a croak is the wrong
 * answer to a question. It is also the rule the whole table keeps: the core
 * fills an frx_err and returns NULL, it does not longjmp through a
 * consumer's C. */

static SV *
frx_abi_doc_to_sv(pTHX_ frx_doc *d)
{
    if (!d) return NULL;
    return frx_doc_bless(aTHX_ d);   /* takes ownership; magic frees it */
}

static frx_doc *
frx_abi_doc_from_sv(pTHX_ SV *sv)
{
    MAGIC *mg = frx_obj_magic(aTHX_ sv, &frx_doc_vtbl);
    return (mg && mg->mg_ptr) ? (frx_doc *)mg->mg_ptr : NULL;
}

static const frx_node *
frx_abi_node_from_sv(pTHX_ SV *sv, frx_doc **owner)
{
    MAGIC *mg = frx_obj_magic(aTHX_ sv, &frx_node_vtbl);
    if (owner) *owner = NULL;
    if (!mg || !mg->mg_ptr || !mg->mg_obj) return NULL;
    if (owner) {
        /* mg_obj is the document's inner IV, which carries the doc magic */
        MAGIC *dm = mg_findext(mg->mg_obj, PERL_MAGIC_ext, &frx_doc_vtbl);
        if (!dm || !dm->mg_ptr) return NULL;
        *owner = (frx_doc *)dm->mg_ptr;
    }
    return (const frx_node *)mg->mg_ptr;
}

static SV *
frx_abi_node_to_sv(pTHX_ SV *doc_sv, const frx_node *n)
{
    MAGIC *mg;
    if (!n) return NULL;
    mg = frx_obj_magic(aTHX_ doc_sv, &frx_doc_vtbl);
    if (!mg || !mg->mg_ptr) return NULL;
    /* the node's magic holds the document's inner IV, not the RV, which is
     * what keeps the document alive for exactly as long as the node */
    return frx_node_bless(aTHX_ SvRV(doc_sv), n);
}

/* a string across the seam: characters */
static SV *
frx_str_sv(pTHX_ const frx_str *s)
{
    SV *sv = newSVpvn(s->p ? s->p : "", s->len);
    SvUTF8_on(sv);
    return sv;
}

/* the bytes of an input SV: UTF-8 when flagged, raw otherwise; the lexer
 * refuses what is not UTF-8 */
static const char *
frx_input(pTHX_ SV *sv, STRLEN *len)
{
    if (SvUTF8(sv)) return SvPVutf8(sv, *len);
    return SvPV(sv, *len);
}

/* the tail of an XSUB's arguments as an options HV, mortal; odd croaks */
static HV *
frx_opts_hv(pTHX_ SV **st, I32 first, I32 items, const char *who)
{
    HV *hv;
    I32 i;
    if (((items - first) & 1) != 0)
        croak("File::Raw::XML: %s: options must be key/value pairs", who);
    hv = (HV *)sv_2mortal((SV *)newHV());
    for (i = first; i < items; i += 2) {
        STRLEN klen;
        const char *k = SvPV(st[i], klen);
        (void)hv_store(hv, k, (I32)klen, newSVsv(st[i + 1]), 0);
    }
    return hv;
}

/* ---- resolvers ---------------------------------------------------------
 *
 * The core fetches nothing: an external subset or entity reaches it as
 * bytes only through frx_opts_ex.resolve, a C function the caller
 * supplies. Two live here. The coderef resolver calls a Perl sub with
 * kind, public_id, system_id and base and takes the string it returns as
 * the bytes; a die inside it becomes the refusal, with the message, at
 * the reference's offset, and undef is a refusal too. The file resolver
 * is confined to the document's own directory: the system identifier
 * (already resolved against the document's path) must have no scheme or
 * the file scheme, must be a regular file, and its real path, symbolic
 * links followed, must lie under the real path of the document's
 * directory. It exists only for file_slurp, which has a path; the codec
 * has none and refuses it. */

typedef struct frx_resolver_ud {
#ifdef PERL_IMPLICIT_CONTEXT
    PerlInterpreter *my_perl;
#endif
    SV    *cv;                  /* the coderef; NULL for the file resolver */
    char  *dir;                 /* the document's directory, real path, malloc'd; file resolver */
    size_t dir_len;
    char   msg[512];            /* a refusal message built here; static for the parse's life */
} frx_resolver_ud;

typedef struct frx_fetch_holder {
    frx_resolver_ud *ud;
    SV              *sv;        /* the bytes, +1 */
} frx_fetch_holder;

static void
frx_perl_release(void *vh, frx_fetched *f)
{
    frx_fetch_holder *h = (frx_fetch_holder *)vh;
#ifdef PERL_IMPLICIT_CONTEXT
    dTHXa(h->ud->my_perl);
#endif
    PERL_UNUSED_ARG(f);
    SvREFCNT_dec(h->sv);
    free(h);
}

static const char *
frx_kind_name(int kind)
{
    switch (kind) {
    case FRX_REF_SUBSET:   return "subset";
    case FRX_REF_XINCLUDE: return "xinclude";
    default:               return "entity";
    }
}

/* a C string as a character SV, or undef for NULL */
static SV *
frx_cstr_sv(pTHX_ const char *p)
{
    SV *sv;
    if (!p) return newSV(0);
    sv = newSVpv(p, 0);
    SvUTF8_on(sv);
    return sv;
}

static const char *
frx_perl_resolve(void *vud, const char *pub, const char *sys, const char *base,
                 int kind, frx_fetched *out)
{
    frx_resolver_ud *ud = (frx_resolver_ud *)vud;
#ifdef PERL_IMPLICIT_CONTEXT
    dTHXa(ud->my_perl);
#endif
    dSP;
    int   count;
    SV   *ret = NULL, *keep = NULL;
    const char *result = NULL;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    mXPUSHs(newSVpvs("kind"));      mXPUSHs(newSVpv(frx_kind_name(kind), 0));
    mXPUSHs(newSVpvs("public_id")); mXPUSHs(frx_cstr_sv(aTHX_ pub));
    mXPUSHs(newSVpvs("system_id")); mXPUSHs(frx_cstr_sv(aTHX_ sys));
    mXPUSHs(newSVpvs("base"));      mXPUSHs(frx_cstr_sv(aTHX_ base));
    PUTBACK;
    count = call_sv(ud->cv, G_SCALAR | G_EVAL);
    SPAGAIN;
    if (count) ret = POPs;
    if (SvTRUE(ERRSV)) {
        STRLEN n;
        const char *m = SvPV(ERRSV, n);
        while (n && (m[n - 1] == '\n' || m[n - 1] == '\r')) n--;
        my_snprintf(ud->msg, sizeof ud->msg, "the resolver died: %.*s", (int)(n > 400 ? 400 : n), m);
        result = ud->msg;
    } else if (!ret || !SvOK(ret)) {
        my_snprintf(ud->msg, sizeof ud->msg, "the resolver returned undef");
        result = ud->msg;
    } else {
        keep = newSVsv(ret);
    }
    PUTBACK;
    FREETMPS;
    LEAVE;
    if (result) return result;
    {
        frx_fetch_holder *h = (frx_fetch_holder *)malloc(sizeof *h);
        STRLEN n;
        if (!h) { SvREFCNT_dec(keep); return "out of memory"; }
        h->ud = ud;
        h->sv = keep;
        out->bytes   = SvUTF8(keep) ? SvPVutf8(keep, n) : SvPV(keep, n);
        out->len     = (size_t)n;
        out->release = frx_perl_release;
        out->ud      = h;
    }
    return NULL;
}

static void
frx_file_release(void *vp, frx_fetched *f)
{
    PERL_UNUSED_ARG(f);
    free(vp);
}

#ifndef PATH_MAX
#define PATH_MAX 4096
#endif

/* the real, absolute path of p into a malloc'd string, or NULL */
static char *
frx_realpath(const char *p)
{
#ifdef _WIN32
    char *buf = (char *)malloc(4096);
    if (!buf) return NULL;
    if (!_fullpath(buf, p, 4096)) { free(buf); return NULL; }
    return buf;
#else
    char *buf = (char *)malloc(PATH_MAX + 1);
    if (!buf) return NULL;
    if (!realpath(p, buf)) { free(buf); return NULL; }
    return buf;
#endif
}

static int
frx_is_dir_sep(char c)
{
#ifdef _WIN32
    return c == '/' || c == '\\';
#else
    return c == '/';
#endif
}

/* "C:" and what follows it: an absolute path with its drive, on the one
 * platform that has drives */
static int
frx_is_drive(const char *p)
{
#ifdef _WIN32
    return ((p[0] >= 'A' && p[0] <= 'Z') || (p[0] >= 'a' && p[0] <= 'z')) && p[1] == ':';
#else
    PERL_UNUSED_ARG(p);
    return 0;
#endif
}

/* the real path of p as a base a URI join can use (RFC 3986 section 5.2).
 * A POSIX path already is one. A Windows path is not: its drive letter
 * parses as a scheme, and its separators are not the path separator a
 * merge looks for, so "doc.dtd" against "C:\d\doc.xml" would come out
 * "C:doc.dtd" and be read against the process directory. It becomes
 * /C:/d/doc.xml, which merges as any absolute path does; frx_file_resolve
 * reads that form, and a file: identifier, back to a native path. */
static char *
frx_realpath_as_base(const char *p)
{
    char *real = frx_realpath(p);
#ifdef _WIN32
    char  *uri;
    size_t n, i, j = 0;
    if (!real) return NULL;
    n = strlen(real);
    uri = (char *)malloc(n + 2);
    if (!uri) { free(real); return NULL; }
    if (frx_is_drive(real)) uri[j++] = '/';
    for (i = 0; i < n; i++) uri[j++] = real[i] == '\\' ? '/' : real[i];
    uri[j] = '\0';
    free(real);
    return uri;
#else
    return real;
#endif
}

/* real starts with the dir_len bytes of dir, as this platform names files */
static int
frx_path_under(const char *real, const char *dir, size_t dir_len)
{
#ifdef _WIN32
    size_t i;
    for (i = 0; i < dir_len; i++) {
        char a = real[i], b = dir[i];
        if (!a) return 0;
        if (a >= 'A' && a <= 'Z') a = (char)(a + 32);
        if (b >= 'A' && b <= 'Z') b = (char)(b + 32);
        if (a == '/') a = '\\';
        if (b == '/') b = '\\';
        if (a != b) return 0;
    }
    return 1;
#else
    return strncmp(real, dir, dir_len) == 0;
#endif
}

static const char *
frx_file_resolve(void *vud, const char *pub, const char *sys, const char *base,
                 int kind, frx_fetched *out)
{
    frx_resolver_ud *ud = (frx_resolver_ud *)vud;
#ifdef PERL_IMPLICIT_CONTEXT
    dTHXa(ud->my_perl);
#endif
    const char *path;
    char   *real;
    PerlIO *fp;
    Stat_t  st;
    char   *bytes;
    size_t  n;
    PERL_UNUSED_ARG(pub);
    PERL_UNUSED_ARG(base);
    PERL_UNUSED_ARG(kind);

    if (!sys || !*sys) return "the reference has no system identifier to read";
    path = sys;
    if ((sys[0] == 'f' || sys[0] == 'F') && strlen(sys) > 5 && (sys[1] | 0x20) == 'i' && (sys[2] | 0x20) == 'l'
        && (sys[3] | 0x20) == 'e' && sys[4] == ':') {
        path = sys + 5;
        if (path[0] == '/' && path[1] == '/') {
            path += 2;                                  /* file://host/path: the host must be empty */
            if (*path != '/' && !frx_is_drive(path))    /* file://C:/... names a drive, not a host */
                return "a file: identifier with a host is not read";
        }
    } else {
        const char *q = sys;
        while ((*q >= 'a' && *q <= 'z') || (*q >= 'A' && *q <= 'Z') || (*q >= '0' && *q <= '9')
               || *q == '+' || *q == '-' || *q == '.') q++;
        if (q > sys && *q == ':' && q[1] == '/' && q[2] == '/')
            return "only a file path or a file: identifier is read by the file resolver";
    }
    if (path[0] == '/' && frx_is_drive(path + 1)) path++;   /* /C:/d/x: the slash is the URI's */
    real = frx_realpath(path);
    if (!real) return "the system identifier does not name a readable file";
    if (!frx_path_under(real, ud->dir, ud->dir_len) || !frx_is_dir_sep(real[ud->dir_len])) {
        free(real);
        return "the system identifier escapes the document's directory";
    }
    if (PerlLIO_stat(real, &st) != 0 || !S_ISREG(st.st_mode)) {
        free(real);
        return "the system identifier is not a regular file";
    }
    fp = PerlIO_open(real, "rb");
    free(real);
    if (!fp) return "the system identifier cannot be opened";
    n = (size_t)st.st_size;
    bytes = (char *)malloc(n ? n : 1);
    if (!bytes) { PerlIO_close(fp); return "out of memory"; }
    {
        size_t got = 0;
        while (got < n) {
            SSize_t r = PerlIO_read(fp, bytes + got, n - got);
            if (r <= 0) break;
            got += (size_t)r;
        }
        n = got;
    }
    PerlIO_close(fp);
    out->bytes   = bytes;
    out->len     = n;
    out->release = frx_file_release;
    out->ud      = bytes;
    return NULL;
}

/* the directory of path as a real path, for the file resolver */
static char *
frx_dir_of(const char *path)
{
    char  *real = frx_realpath(path);
    size_t n;
    if (!real) return NULL;
    n = strlen(real);
    while (n && !frx_is_dir_sep(real[n - 1])) n--;
    if (n > 1) n--;                                     /* drop the separator, keep a root */
    real[n] = '\0';
    return real;
}

/* frx_opts_ex from an options HV. Unknown keys croak; `plugin` is known
 * because file_plugin_build_opts puts it there. The id_attrs names are
 * freed with the current pseudo-block, so parse before it ends. `profile`
 * is 'strict' (the default) or 'full'; anything else croaks naming both.
 * ud receives a resolver's state; path is the document's file when there
 * is one (the plugin) and NULL for the codec. */
static void
frx_opts_from_hv(pTHX_ HV *hv, frx_opts_ex *oe, frx_resolver_ud *ud, const char *path)
{
    HE *he;
    frx_opts *o = &oe->base;
    memset(oe, 0, sizeof *oe);
    oe->size    = sizeof *oe;
    oe->profile = FRX_PROFILE_STRICT;
    memset(ud, 0, sizeof *ud);
#ifdef PERL_IMPLICIT_CONTEXT
    ud->my_perl = aTHX;
#endif
    if (!hv) return;
    hv_iterinit(hv);
    while ((he = hv_iternext(hv))) {
        I32 klen;
        const char *k = hv_iterkey(he, &klen);
        SV *v = hv_iterval(hv, he);
        if (klen == 6 && memcmp(k, "plugin", 6) == 0) continue;
        if (klen == 6 && memcmp(k, "record", 6) == 0) {
            /* the stream phase's own option, read by frx_plugin.h */
            if (!path) croak("File::Raw::XML: record is an option of the xml plugin's stream phase; use File::Raw::each_line");
            continue;
        }
        if (klen == 7 && memcmp(k, "profile", 7) == 0) {
            STRLEN n;
            const char *s = SvPV(v, n);
            if      (n == 6 && memcmp(s, "strict", 6) == 0) oe->profile = FRX_PROFILE_STRICT;
            else if (n == 4 && memcmp(s, "full", 4) == 0)   oe->profile = FRX_PROFILE_FULL;
            else croak("File::Raw::XML: profile must be 'strict' or 'full', not '%.*s'", (int)n, s);
        } else if (klen == 8 && memcmp(k, "encoding", 8) == 0) {
            /* the string lives in the options HV, which outlives the parse */
            oe->encoding = SvPV_nolen(v);
        } else if (klen == 9 && memcmp(k, "max_bytes", 9) == 0) {
            o->max_bytes = (size_t)SvUV(v);
        } else if (klen == 9 && memcmp(k, "max_depth", 9) == 0) {
            o->max_depth = (int)SvIV(v);
        } else if (klen == 16 && memcmp(k, "max_entity_depth", 16) == 0) {
            oe->max_entity_depth = (int)SvIV(v);
        } else if (klen == 19 && memcmp(k, "max_expansion_bytes", 19) == 0) {
            oe->max_expansion_bytes = (size_t)SvUV(v);
        } else if (klen == 19 && memcmp(k, "max_expansion_ratio", 19) == 0) {
            oe->max_expansion_ratio = (int)SvIV(v);
        } else if (klen == 8 && memcmp(k, "validate", 8) == 0) {
            /* 1 stops at the first violation, 'collect' gathers them all */
            if (SvPOK(v) && !SvIOK(v) && !SvNOK(v)) {
                STRLEN n;
                const char *s = SvPV(v, n);
                if (n == 7 && memcmp(s, "collect", 7) == 0) oe->validate = 2;
                else if (!n) oe->validate = 0;
                else croak("File::Raw::XML: validate must be 1, 0 or 'collect', not '%.*s'", (int)n, s);
            } else {
                oe->validate = SvTRUE(v) ? 1 : 0;
            }
        } else if (klen == 15 && memcmp(k, "max_token_bytes", 15) == 0) {
            oe->max_token_bytes = (size_t)SvUV(v);   /* a reader's bound; both profiles */
        } else if (klen == 11 && memcmp(k, "max_fetches", 11) == 0) {
            oe->max_fetches = (int)SvIV(v);
        } else if (klen == 4 && memcmp(k, "base", 4) == 0) {
            oe->base_uri = SvPV_nolen(v);           /* lives in the options HV */
        } else if (klen == 8 && memcmp(k, "xinclude", 8) == 0) {
            oe->xinclude = SvTRUE(v) ? 1 : 0;
        } else if (klen == 18 && memcmp(k, "max_xinclude_depth", 18) == 0) {
            oe->max_xinclude_depth = (int)SvIV(v);
        } else if (klen == 7 && memcmp(k, "resolve", 7) == 0) {
            if (!SvOK(v)) continue;                 /* undef: no resolver */
            if (SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVCV) {
                ud->cv = SvRV(v);                   /* the HV holds the reference */
                oe->resolve    = frx_perl_resolve;
                oe->resolve_ud = ud;
            } else if (SvPOK(v) && SvCUR(v) == 4 && memcmp(SvPVX(v), "file", 4) == 0) {
                if (!path)
                    croak("File::Raw::XML: resolve => 'file' needs a document with a path; "
                          "use file_slurp($path, plugin => 'xml', resolve => 'file')");
                {
                    char *d = frx_dir_of(path);
                    if (!d)
                        croak("File::Raw::XML: resolve => 'file': cannot resolve the directory of '%s'", path);
                    ud->dir = savepv(d);            /* freed with the pseudo-block, croak or not */
                    SAVEFREEPV(ud->dir);
                    free(d);
                }
                ud->dir_len    = strlen(ud->dir);
                oe->resolve    = frx_file_resolve;
                oe->resolve_ud = ud;
            } else {
                croak("File::Raw::XML: resolve must be a coderef or 'file'");
            }
        } else if (klen == 8 && memcmp(k, "id_attrs", 8) == 0) {
            AV *av;
            I32 n, i;
            const char **names;
            if (!SvROK(v) || SvTYPE(SvRV(v)) != SVt_PVAV)
                croak("File::Raw::XML: id_attrs must be an arrayref of attribute names");
            av = (AV *)SvRV(v);
            n  = (I32)(av_len(av) + 1);
            if (!n) continue;
            Newx(names, n, const char *);
            SAVEFREEPV(names);
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(av, i, 0);
                if (!e || !SvOK(*e))
                    croak("File::Raw::XML: id_attrs must be an arrayref of attribute names");
                names[i] = SvPV_nolen(*e);
            }
            o->id_attrs   = names;
            o->n_id_attrs = (int)n;
        } else {
            croak("File::Raw::XML: unknown option '%.*s'", (int)klen, k);
        }
    }
    /* an option the strict profile would silently ignore is refused instead */
    if (oe->profile == FRX_PROFILE_STRICT) {
        if (oe->encoding)
            croak("File::Raw::XML: encoding is an option of profile => 'full'; strict takes UTF-8 only");
        if (oe->max_entity_depth || oe->max_expansion_bytes || oe->max_expansion_ratio)
            croak("File::Raw::XML: the expansion budgets are options of profile => 'full'; strict expands no entity");
        if (oe->validate)
            croak("File::Raw::XML: validate is an option of profile => 'full'; strict reads no DOCTYPE");
        if (oe->resolve || oe->max_fetches || oe->base_uri)
            croak("File::Raw::XML: resolve, base and max_fetches are options of profile => 'full'; strict reads nothing external");
        if (oe->xinclude || oe->max_xinclude_depth)
            croak("File::Raw::XML: xinclude is an option of profile => 'full'; strict includes nothing");
    }
}

/* parse bytes under an options HV into a blessed document, or croak in
 * the one message shape. path is the file the bytes came from, or NULL. */
static SV *
frx_parse_to_sv(pTHX_ const char *in, STRLEN len, HV *opts, const char *path)
{
    frx_opts_ex     o;
    frx_err         e;
    frx_doc        *d;
    frx_resolver_ud ud;
    char           *real = NULL;
    frx_opts_from_hv(aTHX_ opts, &o, &ud, path);
    if (o.resolve && !o.base_uri && path) {
        real = frx_realpath_as_base(path);
        if (real) o.base_uri = real;
    }
    d = frx_parse_doc_ex(in, (size_t)len, &o, &e);
    free(real);
    if (!d) {
        char   msg[512];
        size_t n = frx_err_format(&e, in, (size_t)len, msg, sizeof msg);
        croak("%.*s", (int)n, msg);
    }
    return frx_doc_bless(aTHX_ d);
}

/* ns as the ABI wants it: NULL for undef (any), the string otherwise */
static const char *
frx_ns_arg(pTHX_ SV *sv)
{
    return SvOK(sv) ? SvPV_nolen(sv) : NULL;
}

/* ---- the writer's options and result ---------------------------------- */

/* the document behind a node's inner IV (the mg_obj of a node) */
static frx_doc *
frx_doc_from_iv(pTHX_ SV *iv)
{
    MAGIC *mg = mg_findext(iv, PERL_MAGIC_ext, &frx_doc_vtbl);
    if (!mg || !mg->mg_ptr) croak("File::Raw::XML: the node's document is gone");
    return (frx_doc *)mg->mg_ptr;
}

/* to_string(%opts) from an options HV. is_doc sets the defaults a whole
 * document wants (a declaration, the DOCTYPE); *perl_chars is set by
 * encoding => 'perl', which asks for a character string. The preserve
 * names live on the savestack for the call. */
static void
frx_write_opts_from_hv(pTHX_ HV *hv, frx_write_opts *o, int *perl_chars, const char *who, int is_doc)
{
    HE *he;
    frx_write_opts_init(o);
    o->declaration = is_doc;
    o->doctype     = is_doc;
    *perl_chars    = 0;
    if (!hv) return;
    hv_iterinit(hv);
    while ((he = hv_iternext(hv))) {
        I32 klen;
        const char *k = hv_iterkey(he, &klen);
        SV *v = hv_iterval(hv, he);
        if (klen == 6 && memcmp(k, "plugin", 6) == 0) continue;
        if (klen == 11 && memcmp(k, "declaration", 11) == 0)      o->declaration = SvTRUE(v) ? 1 : 0;
        else if (klen == 6 && memcmp(k, "indent", 6) == 0)        o->indent = (int)SvIV(v);
        else if (klen == 11 && memcmp(k, "empty_short", 11) == 0) o->empty_short = SvTRUE(v) ? 1 : 0;
        else if (klen == 10 && memcmp(k, "escape_all", 10) == 0)  o->escape_all = SvTRUE(v) ? 1 : 0;
        else if (klen == 7 && memcmp(k, "doctype", 7) == 0)       o->doctype = SvTRUE(v) ? 1 : 0;
        else if (klen == 7 && memcmp(k, "drop_ws", 7) == 0)       o->drop_ws = SvTRUE(v) ? 1 : 0;
        else if (klen == 5 && memcmp(k, "quote", 5) == 0) {
            STRLEN n;
            const char *q = SvPV(v, n);
            if (n != 1 || (q[0] != '"' && q[0] != '\''))
                croak("File::Raw::XML: %s: quote must be \" or '", who);
            o->quote = q[0];
        } else if (klen == 8 && memcmp(k, "encoding", 8) == 0) {
            STRLEN n;
            const char *e = SvPV(v, n);
            if (n == 4 && memcmp(e, "perl", 4) == 0) {
                o->encoding = FRX_ENC_UTF8;
                o->encoding_attr = 0;
                *perl_chars = 1;
            } else if (frx_enc_ieq(e, n, "utf-16") || frx_enc_ieq(e, n, "utf-16le")) {
                o->encoding = FRX_ENC_UTF16LE;
            } else if (frx_enc_ieq(e, n, "utf-16be")) {
                o->encoding = FRX_ENC_UTF16BE;
            } else {
                int kind = frx_enc_kind_by_name(e, n);
                if (kind < 0)
                    croak("File::Raw::XML: %s: encoding must be UTF-8, UTF-16, UTF-16LE, UTF-16BE, ISO-8859-1, US-ASCII or perl", who);
                o->encoding = kind;
            }
        } else if (klen == 8 && memcmp(k, "preserve", 8) == 0) {
            AV *av;
            I32 n, i;
            const char **names;
            if (!SvROK(v) || SvTYPE(SvRV(v)) != SVt_PVAV)
                croak("File::Raw::XML: %s: preserve must be an arrayref of element names", who);
            av = (AV *)SvRV(v);
            n  = (I32)(av_len(av) + 1);
            if (n) {
                Newx(names, n, const char *);
                SAVEFREEPV(names);
                for (i = 0; i < n; i++) {
                    SV **e = av_fetch(av, i, 0);
                    if (!e || !SvOK(*e)) croak("File::Raw::XML: %s: preserve must be an arrayref of element names", who);
                    names[i] = SvPV_nolen(*e);
                }
                o->preserve   = names;
                o->n_preserve = (int)n;
            }
        } else {
            croak("File::Raw::XML: %s: unknown option '%.*s'", who, (int)klen, k);
        }
    }
}

/* the markup of apex under o, as a +1 SV: bytes, or characters for
 * encoding => 'perl' */
static SV *
frx_write_sv(pTHX_ const frx_node *apex, const frx_doc *d, const frx_write_opts *o, int perl_chars, const char *who)
{
    frx_buf b;
    frx_err e;
    SV *out;
    frx_buf_init(&b);
    if (!frx_write(apex, d, o, &b, &e)) {
        frx_buf_free(&b);
        croak("File::Raw::XML: %s: %s at the node at byte offset %lu", who, e.what ? e.what : "cannot write", (unsigned long)e.offset);
    }
    out = newSVpvn(b.p ? b.p : "", b.len);
    frx_buf_free(&b);
    if (perl_chars) SvUTF8_on(out);
    return out;
}

/* ---- the reader object ---------------------------------------------------
 *
 * A File::Raw::XML::Reader is a blessed IV with ext magic whose free hook
 * frees this record: the reader itself, the resolver state it may hold
 * (the coderef kept at +1, the confined directory), and durable copies
 * of the option strings the options HV would otherwise own for one call. */

#define FRX_READER_CLASS "File::Raw::XML::Reader"

/* The event kinds a caller can name a callback for. FRX_DOCTYPE (7) is
 * the highest, so a table indexed by kind is eight wide, and the push
 * form dispatches by indexing it rather than by looking a name up per
 * event. Returns -1 for a key that is not an event name, which is how
 * file_xml_events tells a callback from a reader option. */
#define FRX_EVENT_KINDS 8

static int
frx_event_kind_named(const char *k, STRLEN n)
{
    switch (n) {
    case 2: if (memcmp(k, "pi",      2) == 0) return FRX_PI;      break;
    case 3: if (memcmp(k, "end",     3) == 0) return FRX_END;     break;
    case 4: if (memcmp(k, "text",    4) == 0) return FRX_TEXT;    break;
    case 5: if (memcmp(k, "start",   5) == 0) return FRX_START;   break;
    case 7:
        if (memcmp(k, "comment", 7) == 0) return FRX_COMMENT;
        if (memcmp(k, "doctype", 7) == 0) return FRX_DOCTYPE;
        break;
    default: break;
    }
    return -1;
}

/* what from_file pulls from the file each time the parser wants more */
#define FRX_READER_CHUNK (64 * 1024)

typedef struct frx_reader_xs {
    frx_reader      r;
    frx_resolver_ud ud;
    SV   *cv;
    char *base;
    char *encoding;
    char *dir;
    /* a reader made by from_file owns a File::Raw chunk handle and pulls
     * from it in next, in C: -1 when the bytes come from feed instead.
     * Zero is a valid handle, so this is set after the memset, not by
     * it. file_chunk.h comes in through XML.xs, before this header. */
    IV chunk;
} frx_reader_xs;

static char *
frx_strdup(const char *s)
{
    size_t n = strlen(s);
    char *p = (char *)malloc(n + 1);
    if (p) memcpy(p, s, n + 1);
    return p;
}

static void
frx_reader_xs_free(pTHX_ frx_reader_xs *x)
{
    if (!x) return;
    if (x->chunk >= 0) file_chunk_close(aTHX_ x->chunk);
    frx_reader_free(&x->r);
    if (x->cv) SvREFCNT_dec(x->cv);
    free(x->base);
    free(x->encoding);
    free(x->dir);
    free(x);
}

/* a reader over the options HV; path is the file it reads, when it is
 * one (the plugin), for the file resolver and the base */
static frx_reader_xs *
frx_reader_xs_new(pTHX_ HV *opts, const char *path)
{
    frx_opts_ex     oe;
    frx_resolver_ud ud;
    frx_reader_xs  *x;
    frx_opts_from_hv(aTHX_ opts, &oe, &ud, path);
    x = (frx_reader_xs *)malloc(sizeof *x);
    if (!x) croak("File::Raw::XML: out of memory");
    memset(x, 0, sizeof *x);
    x->chunk = -1;              /* 0 is a chunk handle, not "no handle" */
    x->ud = ud;
    if (ud.cv)  { x->cv = SvREFCNT_inc(ud.cv); x->ud.cv = x->cv; }
    if (ud.dir) { x->dir = frx_strdup(ud.dir); x->ud.dir = x->dir; }
    if (oe.resolve) oe.resolve_ud = &x->ud;
    if (oe.base_uri) {
        x->base = frx_strdup(oe.base_uri);
        oe.base_uri = x->base;
    } else if (oe.resolve && path) {
        x->base = frx_realpath_as_base(path);
        oe.base_uri = x->base;
    }
    if (oe.encoding) {
        x->encoding = frx_strdup(oe.encoding);
        oe.encoding = x->encoding;
    }
    oe.base.id_attrs   = NULL;                  /* a reader builds no index */
    oe.base.n_id_attrs = 0;
    frx_reader_init(&x->r, &oe);
    return x;
}

static int
frx_reader_mg_free(pTHX_ SV *sv, MAGIC *mg)
{
    frx_reader_xs *x = (frx_reader_xs *)mg->mg_ptr;
    PERL_UNUSED_ARG(sv);
    if (x) {
        frx_reader_xs_free(aTHX_ x);
        mg->mg_ptr = NULL;
    }
    return 0;
}

static MGVTBL frx_reader_vtbl = { NULL, NULL, NULL, NULL, frx_reader_mg_free, NULL, NULL, NULL };

static SV *
frx_reader_bless(pTHX_ frx_reader_xs *x, const char *class_name)
{
    SV *iv = newSViv(0);
    sv_magicext(iv, NULL, PERL_MAGIC_ext, &frx_reader_vtbl, (const char *)x, 0);
    return sv_bless(newRV_noinc(iv), gv_stashpv(class_name, GV_ADD));
}

static frx_reader_xs *
frx_reader_from_sv(pTHX_ SV *sv, const char *meth)
{
    MAGIC *mg = frx_obj_magic(aTHX_ sv, &frx_reader_vtbl);
    if (!mg || !mg->mg_ptr)
        croak("File::Raw::XML: %s: the invocant is not a " FRX_READER_CLASS, meth);
    return (frx_reader_xs *)mg->mg_ptr;
}

/* the reader's refusal, in the one message shape, over the bytes it
 * still holds */
static void
frx_reader_croak(pTHX_ frx_reader_xs *x)
{
    char   msg[512];
    size_t n = frx_err_format_at(&x->r.err, x->r.in.p, x->r.in.len, x->r.dropped, msg, sizeof msg);
    croak("%.*s", (int)n, msg);
}

/* ---- edits from Perl ----------------------------------------------------
 *
 * A node an edit creates is blessed exactly as a parsed one: the same
 * magic, the document's inner IV as mg_obj at +1, so it holds its
 * document and a detached node keeps the document alive. A node passed to
 * an edit must belong to the invocant's document, checked by the inner
 * IV; one from another document is refused before anything is touched,
 * and import is the way across. */

/* a node of the same document as doc_iv, writable */
static frx_node *
frx_node_arg(pTHX_ SV *sv, SV *doc_iv, const char *meth)
{
    SV *their = NULL;
    const frx_node *n = frx_node_from_sv(aTHX_ sv, meth, &their);
    if (their != doc_iv)
        croak("File::Raw::XML: %s: the node belongs to another document; use import", meth);
    return (frx_node *)n;
}

static void
frx_edit_croak(pTHX_ const char *meth, const frx_err *e)
{
    if (e->offset)
        croak("File::Raw::XML: %s: %s (the node at byte offset %lu)", meth, e->what ? e->what : "refused", (unsigned long)e->offset);
    croak("File::Raw::XML: %s: %s", meth, e->what ? e->what : "refused");
}

/* the bytes of a string argument, or "" for undef */
static const char *
frx_arg_bytes(pTHX_ SV *sv, STRLEN *len)
{
    if (!sv || !SvOK(sv)) { *len = 0; return ""; }
    return frx_input(aTHX_ sv, len);
}

/* prefix and local from a name that may carry one colon */
static void
frx_split_arg(const char *name, STRLEN nlen, const char **prefix, STRLEN *plen, const char **local, STRLEN *llen)
{
    const char *colon = (const char *)memchr(name, ':', nlen);
    if (colon) {
        *prefix = name; *plen = (STRLEN)(colon - name);
        *local = colon + 1; *llen = nlen - *plen - 1;
    } else {
        *prefix = ""; *plen = 0;
        *local = name; *llen = nlen;
    }
}

/* the current event's doctype as the Document method renders one */
static SV *
frx_doctype_sv(pTHX_ const frx_doctype *dt)
{
    HV *hv;
    if (!dt) return newSV(0);
    hv = newHV();
    (void)hv_stores(hv, "name", frx_str_sv(aTHX_ &dt->name));
    (void)hv_stores(hv, "public_id", dt->public_id.len ? frx_str_sv(aTHX_ &dt->public_id) : newSV(0));
    (void)hv_stores(hv, "system_id", dt->system_id.len ? frx_str_sv(aTHX_ &dt->system_id) : newSV(0));
    (void)hv_stores(hv, "internal_subset", dt->has_subset ? frx_str_sv(aTHX_ &dt->subset) : newSV(0));
    return newRV_noinc((SV *)hv);
}

#endif /* FRX_OBJ_H */
