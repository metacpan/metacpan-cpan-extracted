#ifndef FRX_ABI_IMPL_H
#define FRX_ABI_IMPL_H

/* The table behind File::Raw::XML::_abi_ptr.
 *
 * Every entry points at a core function, wrapped only where the ABI's
 * signature differs from the core's: parse turns an frx_err into NULL
 * plus a mortal message SV; text and c14n turn an frx_buf into a +1 SV;
 * the accessors read a field. Nothing is implemented here (rule 5):
 * logic written in this file has found a core function with the wrong
 * shape.
 *
 * The table is a static const; _abi_ptr returns its address as an IV and
 * a consumer INT2PTRs it once at BOOT and compares abi_version with >=,
 * never ==. Append only after 0.01.
 *
 * `parse` points at the strict form and always will; `parse_ex` is the
 * full profile's entry, and everything after it in the table is the rest
 * of what the full profile built. Nothing has been released, so the whole
 * table is version 1; the append-only rule begins the day it ships.
 *
 * Needs frx_abi.h and every core header the entries name. */

static void
frx_abi_opts_init(frx_opts *o)
{
    o->max_bytes  = 0;
    o->max_depth  = 0;
    o->id_attrs   = NULL;
    o->n_id_attrs = 0;
}

static frx_doc *
frx_abi_parse(pTHX_ const char *bytes, STRLEN len, const frx_opts *o, SV **err)
{
    frx_err e;
    frx_doc *d = frx_parse_doc(bytes, (size_t)len, o, &e);
    if (!d && err) {
        char   msg[512];
        size_t n = frx_err_format(&e, bytes, (size_t)len, msg, sizeof msg);
        *err = sv_2mortal(newSVpvn(msg, n));
    }
    return d;
}

static void
frx_abi_doc_free(pTHX_ frx_doc *d)
{
    PERL_UNUSED_CONTEXT;
    frx_doc_free(d);
}

static const frx_node *frx_abi_root(const frx_doc *d)          { return d->root; }
static const frx_node *frx_abi_document(const frx_doc *d)      { return d->document; }
static int             frx_abi_kind(const frx_node *n)          { return n->kind; }
static const frx_node *frx_abi_parent(const frx_node *n)        { return n->parent; }
static const frx_node *frx_abi_first_child(const frx_node *n)   { return n->first_child; }
static const frx_node *frx_abi_next(const frx_node *n)          { return n->next; }
static int             frx_abi_attr_count(const frx_node *n)    { return n->n_attrs; }

static const char *
frx_abi_str(const frx_str *s, STRLEN *len)
{
    if (len) *len = (STRLEN)s->len;
    return s->p ? s->p : "";
}

static const char *frx_abi_ns(const frx_node *n, STRLEN *len)     { return frx_abi_str(&n->ns, len); }
static const char *frx_abi_local(const frx_node *n, STRLEN *len)  { return frx_abi_str(&n->local, len); }
static const char *frx_abi_prefix(const frx_node *n, STRLEN *len) { return frx_abi_str(&n->prefix, len); }

static void
frx_abi_attr(const frx_node *n, int i,
             const char **ns, STRLEN *nslen,
             const char **local, STRLEN *loclen,
             const char **value, STRLEN *vlen)
{
    const frx_attr *a;
    if (i < 0 || i >= n->n_attrs) {
        if (ns)    *ns    = NULL;
        if (local) *local = NULL;
        if (value) *value = NULL;
        if (nslen)  *nslen  = 0;
        if (loclen) *loclen = 0;
        if (vlen)   *vlen   = 0;
        return;
    }
    a = &n->attrs[i];
    if (ns)    *ns    = frx_abi_str(&a->ns, nslen);
    if (local) *local = frx_abi_str(&a->local, loclen);
    if (value) *value = frx_abi_str(&a->value, vlen);
}

static const char *
frx_abi_attr_value(const frx_node *n, const char *ns, const char *local, STRLEN *len)
{
    const frx_str *v = frx_attr_value(n, ns, local);
    if (!v) { if (len) *len = 0; return NULL; }
    return frx_abi_str(v, len);
}

static const frx_node *
frx_abi_by_id(const frx_doc *d, const char *attr, const char *value, STRLEN vlen)
{
    return frx_by_id(d, attr, value, (size_t)vlen);
}

static SV *
frx_abi_text(pTHX_ const frx_node *n)
{
    frx_buf b;
    SV *out;
    frx_buf_init(&b);
    frx_text(n, &b);
    out = b.failed ? NULL : newSVpvn(b.p ? b.p : "", b.len);
    if (out) SvUTF8_on(out);
    frx_buf_free(&b);
    return out;
}

static SV *
frx_abi_c14n(pTHX_ const frx_node *n, const frx_c14n *c)
{
    frx_buf b;
    SV *out;
    frx_buf_init(&b);
    out = frx_c14n_render(n, c, &b) ? newSVpvn(b.p ? b.p : "", b.len) : NULL;
    frx_buf_free(&b);
    return out;
}


/* ---- the full profile ---------------------------------------------------
 *
 * Almost every entry below is a direct pointer to a core function, which
 * is what taking an frx_err * rather than an SV bought. What is here is
 * field reads, in the shape the v1 accessors already use, and the three
 * places the ABI's types differ from the core's: STRLEN for size_t, and
 * the two selectors that keep the reader from needing an entry per
 * accessor. */

static STRLEN
frx_abi_err_format(const frx_err *e, const char *in, STRLEN len, char *out, STRLEN cap)
{
    return (STRLEN)frx_err_format(e, in, (size_t)len, out, (size_t)cap);
}

static int frx_abi_version(const frx_doc *d)
{
    return frx_str_eq(&d->version, "1.1", 3) ? 11 : 10;
}
static int frx_abi_standalone(const frx_doc *d) { return d->standalone ? 1 : 0; }

static const char *
frx_abi_dt(const frx_doc *d, int which, STRLEN *len)
{
    const frx_doctype *dt = d->doctype;
    if (!dt) { if (len) *len = 0; return NULL; }
    switch (which) {
    case 1:  return frx_abi_str(&dt->public_id, len);
    case 2:  return frx_abi_str(&dt->system_id, len);
    case 3:  return frx_abi_str(&dt->subset, len);
    default: return frx_abi_str(&dt->name, len);
    }
}

static const char *frx_abi_dt_name(const frx_doc *d, STRLEN *l)   { return frx_abi_dt(d, 0, l); }
static const char *frx_abi_dt_public(const frx_doc *d, STRLEN *l) { return frx_abi_dt(d, 1, l); }
static const char *frx_abi_dt_system(const frx_doc *d, STRLEN *l) { return frx_abi_dt(d, 2, l); }
static const char *frx_abi_dt_subset(const frx_doc *d, STRLEN *l) { return frx_abi_dt(d, 3, l); }

static int frx_abi_span_count(const frx_node *n) { return n->n_cdata_spans; }

static void
frx_abi_span(const frx_node *n, int i, STRLEN *off, STRLEN *len)
{
    if (i < 0 || i >= n->n_cdata_spans) {
        if (off) *off = 0;
        if (len) *len = 0;
        return;
    }
    if (off) *off = (STRLEN)n->cdata_spans[i].offset;
    if (len) *len = (STRLEN)n->cdata_spans[i].len;
}

static int frx_abi_error_count(const frx_doc *d) { return d->n_errors; }

static const char *
frx_abi_error_at(const frx_doc *d, int i, STRLEN *offset)
{
    const frx_verr *e = d->errors;
    if (offset) *offset = 0;
    if (i < 0) return NULL;
    while (e && i--) e = e->next;
    if (!e) return NULL;
    if (offset) *offset = (STRLEN)e->offset;
    return e->what;
}

static SV *
frx_abi_write(pTHX_ const frx_node *apex, const frx_doc *d,
              const frx_write_opts *o, frx_err *err)
{
    frx_buf b;
    SV *out;
    frx_buf_init(&b);
    out = frx_write(apex, d, o, &b, err) ? newSVpvn(b.p ? b.p : "", b.len) : NULL;
    frx_buf_free(&b);
    return out;
}

/* ---- the reader's two selectors ---------------------------------------- */

static const char *
frx_abi_reader_str(const frx_reader *r, int which, STRLEN *len)
{
    const frx_event *e = &r->cur;
    if (!r->have_cur) { if (len) *len = 0; return ""; }
    switch (which) {
    case FRX_R_LOCAL:  return frx_abi_str(&e->local, len);
    case FRX_R_NS:     return frx_abi_str(&e->ns, len);
    case FRX_R_PREFIX: return frx_abi_str(&e->prefix, len);
    case FRX_R_VALUE:  return frx_abi_str(&e->value, len);
    case FRX_R_ENTITY: return frx_abi_str(&e->entity, len);
    default:           return frx_abi_str(&e->qname, len);
    }
}

static int
frx_abi_reader_int(const frx_reader *r, int which)
{
    switch (which) {
    case FRX_R_DEPTH:
        if (!r->have_cur) return 0;
        return r->cur.kind == FRX_START ? r->cur.depth + 1 : r->cur.depth;
    case FRX_R_EMPTY:      return r->have_cur ? (r->cur.empty ? 1 : 0) : 0;
    case FRX_R_DONE:       return r->done ? 1 : 0;
    case FRX_R_CAPTURING:  return r->capturing ? 1 : 0;
    default:               return r->have_cur ? r->cur.kind : 0;
    }
}

static STRLEN frx_abi_reader_offset(const frx_reader *r)
{
    return r->have_cur ? (STRLEN)r->cur.offset : 0;
}

static int frx_abi_reader_attr_count(const frx_reader *r)
{
    return r->have_cur ? r->cur.n_attrs : 0;
}

static void
frx_abi_reader_attr(const frx_reader *r, int i,
                    const char **ns, STRLEN *nslen,
                    const char **local, STRLEN *loclen,
                    const char **value, STRLEN *vlen)
{
    const frx_attr *a;
    if (!r->have_cur || i < 0 || i >= r->cur.n_attrs) {
        if (ns)    *ns    = NULL;
        if (local) *local = NULL;
        if (value) *value = NULL;
        if (nslen)  *nslen  = 0;
        if (loclen) *loclen = 0;
        if (vlen)   *vlen   = 0;
        return;
    }
    a = &r->cur.attrs[i];
    if (ns)    *ns    = frx_abi_str(&a->ns, nslen);
    if (local) *local = frx_abi_str(&a->local, loclen);
    if (value) *value = frx_abi_str(&a->value, vlen);
}

static int
frx_abi_reader_feed(frx_reader *r, const char *bytes, STRLEN len, int eof)
{
    return frx_reader_feed(r, bytes, (size_t)len, eof);
}

static int
frx_abi_reader_next(frx_reader *r)
{
    frx_event ev;
    int rc = frx_reader_next(r, &ev);
    return rc > 0 ? ev.kind : rc;      /* 0 wants bytes, -1 is the end */
}

static frx_doc *
frx_abi_reader_subtree(frx_reader *r)
{
    frx_doc *d = NULL;
    return frx_reader_subtree(r, &d) > 0 ? d : NULL;
}

static const frx_err *frx_abi_reader_error(const frx_reader *r) { return &r->err; }

/* ---- the edits, with STRLEN where the core takes size_t ---------------- */

static frx_node *
frx_abi_new_element(frx_doc *d, const char *ns, STRLEN nslen,
                    const char *prefix, STRLEN plen,
                    const char *local, STRLEN llen, frx_err *e)
{
    return frx_new_element(d, ns, (size_t)nslen, prefix, (size_t)plen,
                           local, (size_t)llen, e);
}
static frx_node *frx_abi_new_text(frx_doc *d, const char *s, STRLEN n, frx_err *e)
{ return frx_new_text(d, s, (size_t)n, e); }
static frx_node *frx_abi_new_comment(frx_doc *d, const char *s, STRLEN n, frx_err *e)
{ return frx_new_comment(d, s, (size_t)n, e); }
static frx_node *frx_abi_new_pi(frx_doc *d, const char *t, STRLEN tl,
                                const char *v, STRLEN vl, frx_err *e)
{ return frx_new_pi(d, t, (size_t)tl, v, (size_t)vl, e); }

static int
frx_abi_set_attr(frx_doc *d, frx_node *el, const char *ns, STRLEN nslen,
                 const char *prefix, STRLEN plen, const char *local, STRLEN llen,
                 const char *value, STRLEN vlen, frx_err *e)
{
    return frx_set_attr(d, el, ns, (size_t)nslen, prefix, (size_t)plen,
                        local, (size_t)llen, value, (size_t)vlen, e);
}
static int frx_abi_remove_attr(frx_doc *d, frx_node *el, const char *ns, STRLEN nslen,
                               const char *local, STRLEN llen, frx_err *e)
{ return frx_remove_attr(d, el, ns, (size_t)nslen, local, (size_t)llen, e); }
static int frx_abi_set_text(frx_doc *d, frx_node *n, const char *s, STRLEN len, frx_err *e)
{ return frx_set_text(d, n, s, (size_t)len, e); }
static int frx_abi_declare_ns(frx_doc *d, frx_node *el, const char *p, STRLEN pl,
                              const char *u, STRLEN ul, frx_err *e)
{ return frx_declare_ns(d, el, p, (size_t)pl, u, (size_t)ul, e); }
static int frx_abi_set_name(frx_doc *d, frx_node *el, const char *ns, STRLEN nslen,
                            const char *prefix, STRLEN plen, const char *local, STRLEN llen,
                            frx_err *e)
{ return frx_set_name(d, el, ns, (size_t)nslen, prefix, (size_t)plen, local, (size_t)llen, e); }

/* ---- XPath ------------------------------------------------------------- */

static frx_doc *
frx_abi_parse_ex(const char *bytes, STRLEN len, const frx_opts_ex *o, frx_err *err)
{
    frx_opts_ex oe;
    if (o) return frx_parse_doc_ex(bytes, (size_t)len, o, err);
    memset(&oe, 0, sizeof oe);
    oe.size    = sizeof oe;
    oe.profile = FRX_PROFILE_STRICT;
    return frx_parse_doc_ex(bytes, (size_t)len, &oe, err);
}

static frx_xpath *
frx_abi_xpath_compile(const char *expr, STRLEN len, const frx_ns_map *ns,
                      int max_depth, const char **err, STRLEN *err_at)
{
    size_t at = 0;
    frx_xpath *x = frx_xpath_compile(expr, (size_t)len, ns, max_depth, err, &at);
    if (err_at) *err_at = (STRLEN)at;
    return x;
}

static int
frx_abi_xpath_bind_str(frx_xpath *x, int i, const char *p, STRLEN n)
{
    return frx_xpath_bind_str(x, i, p, (size_t)n);
}

static int frx_abi_xpath_kind(const frx_xp_result *r)     { return r->kind; }
static double frx_abi_xpath_number(const frx_xp_result *r) { return r->num; }

static const char *
frx_abi_xpath_string(const frx_xp_result *r, STRLEN *len)
{
    if (len) *len = (STRLEN)r->str.len;
    return r->str.p ? r->str.p : "";
}

static int frx_abi_xpath_count(const frx_xp_result *r)
{
    return r->kind == FRX_XV_NODESET ? r->set.n : 0;
}

static const frx_node *
frx_abi_xpath_node(const frx_xp_result *r, int i, int *kind, int *index)
{
    if (kind)  *kind  = 0;
    if (index) *index = 0;
    if (r->kind != FRX_XV_NODESET || i < 0 || i >= r->set.n) return NULL;
    if (kind)  *kind  = r->set.v[i].kind;
    if (index) *index = r->set.v[i].index;
    return r->set.v[i].node;
}

static const frx_abi FRX_ABI = {
    FRX_ABI_VERSION,
    frx_abi_opts_init,
    frx_abi_parse,
    frx_abi_doc_free,
    frx_abi_root,
    frx_abi_document,
    frx_abi_kind,
    frx_abi_ns,
    frx_abi_local,
    frx_abi_prefix,
    frx_abi_parent,
    frx_abi_first_child,
    frx_abi_next,
    frx_abi_attr_count,
    frx_abi_attr,
    frx_abi_attr_value,
    frx_find,
    frx_abi_by_id,
    frx_abi_text,
    frx_abi_c14n,

    /* the full profile */
    frx_abi_parse_ex,
    frx_abi_err_format,
    frx_abi_version,
    frx_abi_standalone,
    frx_abi_dt_name,
    frx_abi_dt_public,
    frx_abi_dt_system,
    frx_abi_dt_subset,
    frx_abi_span_count,
    frx_abi_span,
    frx_abi_error_count,
    frx_abi_error_at,
    frx_write_opts_init,
    frx_abi_write,
    frx_tree_equal,

    frx_reader_new,
    frx_reader_destroy,
    frx_abi_reader_feed,
    frx_abi_reader_next,
    frx_abi_reader_str,
    frx_abi_reader_int,
    frx_abi_reader_offset,
    frx_abi_reader_attr_count,
    frx_abi_reader_attr,
    frx_abi_reader_subtree,
    frx_abi_reader_error,

    frx_doc_new_empty,
    frx_abi_new_element,
    frx_abi_new_text,
    frx_abi_new_comment,
    frx_abi_new_pi,
    frx_append_child,
    frx_insert_before,
    frx_remove,
    frx_abi_set_attr,
    frx_abi_remove_attr,
    frx_abi_set_text,
    frx_abi_declare_ns,
    frx_abi_set_name,
    frx_import,

    frx_abi_xpath_compile,
    frx_xpath_free,
    frx_xpath_var_count,
    frx_xpath_var_name,
    frx_abi_xpath_bind_str,
    frx_xpath_bind_num,
    frx_xpath_bind_bool,
    frx_xpath_result_new,
    frx_xpath_result_destroy,
    frx_xpath_eval_at,
    frx_abi_xpath_kind,
    frx_abi_xpath_number,
    frx_abi_xpath_string,
    frx_abi_xpath_count,
    frx_abi_xpath_node
};

/* The selftest: a fixed document through every entry, in C, with every
 * answer checked. Returns the exclusive canonical bytes of the root as a
 * +1 SV, or NULL on the first mismatch; the test compares those bytes
 * with the Perl surface's for the same literal. */
#define FRX_SELFTEST_INPUT \
    "<?pi data?><!-- c --><r xmlns=\"urn:d\" xmlns:p=\"urn:p\" ID=\"r1\" a=\"1\" p:b=\"2\">" \
    "<p:e ID=\"e1\">text<![CDATA[!]]></p:e><f/><!-- x --><?q?></r>"

static SV *
frx_abi_selftest(pTHX)
{
    const frx_abi *A = &FRX_ABI;
    static const char *const ids[] = { "ID" };
    frx_opts o;
    SV *err = NULL;
    frx_doc *d;
    const frx_node *doc, *root, *n, *e, *f;
    const char *s;
    STRLEN len;
    SV *text = NULL, *out = NULL, *tmp;
    frx_c14n c;
    int i;

    if (A->abi_version < 1) return NULL;
    A->opts_init(&o);
    o.id_attrs   = ids;
    o.n_id_attrs = 1;
    d = A->parse(aTHX_ FRX_SELFTEST_INPUT, sizeof FRX_SELFTEST_INPUT - 1, &o, &err);
    if (!d) return NULL;

    doc  = A->document(d);
    root = A->root(d);
    if (A->kind(doc) != FRX_DOCUMENT || A->kind(root) != FRX_ELEMENT) goto fail;
    if (A->parent(root) != doc || A->parent(doc) != NULL) goto fail;

    /* the document's children: PI, comment, root, end */
    n = A->first_child(doc);
    if (!n || A->kind(n) != FRX_PI) goto fail;
    s = A->local(n, &len);
    if (len != 2 || memcmp(s, "pi", 2)) goto fail;
    n = A->next(n);
    if (!n || A->kind(n) != FRX_COMMENT) goto fail;
    n = A->next(n);
    if (n != root || A->next(n) != NULL) goto fail;

    /* names */
    s = A->ns(root, &len);     if (len != 5 || memcmp(s, "urn:d", 5)) goto fail;
    s = A->local(root, &len);  if (len != 1 || s[0] != 'r') goto fail;
    s = A->prefix(root, &len); if (len != 0 || s[0] != '\0') goto fail;

    /* attributes: ID, a, p:b in order; xmlns never counted */
    if (A->attr_count(root) != 3) goto fail;
    {
        const char *ns, *local, *value;
        STRLEN nsl, ll, vl;
        A->attr(root, 2, &ns, &nsl, &local, &ll, &value, &vl);
        if (nsl != 5 || memcmp(ns, "urn:p", 5) || ll != 1 || local[0] != 'b' || vl != 1 || value[0] != '2') goto fail;
        A->attr(root, 3, &ns, &nsl, &local, &ll, &value, &vl);
        if (ns || local || value) goto fail;
    }
    s = A->attr_value(root, NULL, "b", &len);    if (!s || len != 1 || s[0] != '2') goto fail;
    s = A->attr_value(root, "", "b", &len);      if (s) goto fail;
    s = A->attr_value(root, "urn:p", "b", &len); if (!s || len != 1 || s[0] != '2') goto fail;
    s = A->attr_value(root, "", "a", &len);      if (!s || len != 1 || s[0] != '1') goto fail;

    /* find with the cursor, to exhaustion */
    e = A->find(root, NULL, "e", NULL);
    if (!e || A->kind(e) != FRX_ELEMENT) goto fail;
    s = A->ns(e, &len); if (len != 5 || memcmp(s, "urn:p", 5)) goto fail;
    if (A->find(root, NULL, "e", e) != NULL) goto fail;
    f = A->find(root, "urn:d", "f", NULL);
    if (!f) goto fail;
    if (A->find(root, "", "f", NULL) != NULL) goto fail;
    if (A->parent(e) != root || A->first_child(f) != NULL) goto fail;
    n = A->next(e); if (n != f) goto fail;
    n = A->next(f); if (!n || A->kind(n) != FRX_COMMENT) goto fail;
    n = A->next(n); if (!n || A->kind(n) != FRX_PI) goto fail;
    if (A->next(n) != NULL) goto fail;

    /* by_id */
    if (A->by_id(d, "ID", "e1", 2) != e) goto fail;
    if (A->by_id(d, "ID", "r1", 2) != root) goto fail;
    if (A->by_id(d, "ID", "zz", 2) != NULL) goto fail;
    if (A->by_id(d, "Id", "e1", 2) != NULL) goto fail;

    /* text */
    text = A->text(aTHX_ root);
    if (!text) goto fail;
    s = SvPV(text, len);
    if (len != 5 || memcmp(s, "text!", 5)) goto fail;

    /* c14n in every mode; the exclusive bytes are the answer */
    c.comments = 0; c.prefix_list = NULL; c.n_prefix = 0; c.without = NULL; c.n_without = 0;
    for (i = FRX_C14N_INC11; i >= FRX_C14N_EXC; i--) {
        c.mode = i;
        tmp = A->c14n(aTHX_ root, &c);
        if (!tmp || !SvCUR(tmp)) { if (tmp) SvREFCNT_dec(tmp); goto fail; }
        if (i == FRX_C14N_EXC) out = tmp; else SvREFCNT_dec(tmp);
    }

    /* a refusal is NULL and a message, never a croak */
    {
        SV *e2 = NULL;
        frx_doc *bad = A->parse(aTHX_ "<!DOCTYPE x><x/>", 16, NULL, &e2);
        if (bad) { A->doc_free(aTHX_ bad); goto fail; }
        if (!e2 || !SvPOK(e2) || !strstr(SvPV_nolen(e2), "DOCTYPE")) goto fail;
    }

    A->doc_free(aTHX_ d);
    SvREFCNT_dec(text);
    return out;

fail:
    A->doc_free(aTHX_ d);
    if (text) SvREFCNT_dec(text);
    if (out)  SvREFCNT_dec(out);
    return NULL;
}


/* The full profile's selftest: a document with a DOCTYPE, a CDATA
 * section and a validity error through every entry the strict selftest
 * does not reach. Returns 0 when all of it held and the number of the
 * check that did not otherwise, so a failure names itself.
 *
 * The document is invalid on purpose - `b` is declared EMPTY and holds
 * text - so that `validate => collect` has something to collect and the
 * error entries have something to report. */
#define FRX_SELFTEST_FULL \
    "<?xml version=\"1.0\" standalone=\"yes\"?>" \
    "<!DOCTYPE r PUBLIC \"-//p//DTD//EN\" \"r.dtd\" [" \
      "<!ELEMENT r (a,b)><!ELEMENT a (#PCDATA)><!ELEMENT b EMPTY>" \
      "<!ATTLIST a id ID #IMPLIED>" \
      "<!ENTITY e \"E\">" \
    "]>" \
    "<r><a id=\"a1\">x&e;<![CDATA[<&]]></a><b>no</b></r>"

#define FRX_STEP(n) do { step = (n); } while (0)

/* the selftest's resolver: the DOCTYPE names an external subset, so
 * something has to hand the bytes over, and this is also the one place
 * the resolver seam is walked from C */
static const char *
frx_abi_selftest_resolve(void *ud, const char *pub, const char *sys,
                         const char *base, int kind, frx_fetched *out)
{
    static const char subset[] = "<!ENTITY x \"X\">";
    (void)ud; (void)pub; (void)sys; (void)base;
    if (kind != FRX_REF_SUBSET) return "the selftest resolves only the external subset";
    out->bytes   = subset;
    out->len     = sizeof subset - 1;
    out->release = NULL;
    out->ud      = NULL;
    return NULL;
}

static int
frx_abi_selftest_full(pTHX)
{
    const frx_abi *A = &FRX_ABI;
    frx_opts_ex  oe;
    frx_err      err;
    frx_doc     *d = NULL, *d2 = NULL, *built = NULL;
    frx_node    *el, *tx;
    const frx_node *n, *a;
    const char  *s;
    STRLEN       len, off;
    int          step = 0;
    SV          *out = NULL;

    memset(&err, 0, sizeof err);

    /* parse_ex, and the whole prolog it read */
    memset(&oe, 0, sizeof oe);
    oe.size     = sizeof oe;
    oe.profile  = FRX_PROFILE_FULL;
    oe.validate = 2;                                   /* collect */
    oe.resolve  = frx_abi_selftest_resolve;
    FRX_STEP(1);
    d = A->parse_ex(FRX_SELFTEST_FULL, sizeof FRX_SELFTEST_FULL - 1, &oe, &err);
    if (!d) goto fail;

    FRX_STEP(2); if (A->version(d) != 10) goto fail;
    FRX_STEP(3); if (!A->standalone(d)) goto fail;
    FRX_STEP(4);
    s = A->doctype_name(d, &len);   if (!s || len != 1 || s[0] != 'r') goto fail;
    FRX_STEP(5);
    s = A->doctype_public(d, &len); if (!s || len != 13) goto fail;
    FRX_STEP(6);
    s = A->doctype_system(d, &len); if (!s || len != 5 || memcmp(s, "r.dtd", 5)) goto fail;
    FRX_STEP(7);
    s = A->doctype_subset(d, &len); if (!s || !len) goto fail;

    /* the CDATA section inside a's merged text: "xE<&", the section at 2 */
    FRX_STEP(8);
    a = A->find(A->root(d), NULL, "a", NULL);
    if (!a) goto fail;
    n = A->first_child(a);
    if (!n || A->kind(n) != FRX_TEXT) goto fail;
    FRX_STEP(9);  if (A->cdata_span_count(n) != 1) goto fail;
    FRX_STEP(10);
    A->cdata_span(n, 0, &off, &len);
    if (off != 2 || len != 2) goto fail;
    FRX_STEP(11);
    A->cdata_span(n, 1, &off, &len);
    if (off != 0 || len != 0) goto fail;              /* out of range is zeroed */

    /* the validity error collect gathered */
    FRX_STEP(12); if (A->error_count(d) < 1) goto fail;
    FRX_STEP(13);
    s = A->error_at(d, 0, &off);
    if (!s || !strstr(s, "VC:")) goto fail;
    FRX_STEP(14); if (A->error_at(d, A->error_count(d), NULL) != NULL) goto fail;

    /* write, then read what was written back and compare as data */
    {
        frx_write_opts w;
        A->write_opts_init(&w);
        FRX_STEP(15);
        out = A->write(aTHX_ A->document(d), d, &w, &err);
        if (!out || !SvCUR(out)) goto fail;
        FRX_STEP(16);
        d2 = A->parse_ex(SvPVX(out), SvCUR(out), &oe, &err);
        if (!d2) goto fail;
        FRX_STEP(17);
        if (!A->tree_equal(A->document(d), A->document(d2))) goto fail;
        FRX_STEP(18);
        if (A->tree_equal(A->root(d), A->find(A->root(d), NULL, "a", NULL))) goto fail;
        A->doc_free(aTHX_ d2);
        d2 = NULL;
        SvREFCNT_dec(out);
        out = NULL;
    }

    /* err_format renders a refusal, and parse_ex refuses without croaking */
    {
        char msg[512];
        frx_doc *bad;
        FRX_STEP(19);
        bad = A->parse_ex("<r><</r>", 8, &oe, &err);
        if (bad) { A->doc_free(aTHX_ bad); goto fail; }
        FRX_STEP(20);
        len = A->err_format(&err, "<r><</r>", 8, msg, sizeof msg);
        if (!len || !strstr(msg, "File::Raw::XML: ")) goto fail;
    }

    /* the reader over the same bytes */
    {
        frx_reader *r;
        int kind, saw_start = 0, saw_cdata = 0;
        FRX_STEP(21);
        r = A->reader_new(&oe);
        if (!r) goto fail;
        FRX_STEP(22);
        if (!A->reader_feed(r, FRX_SELFTEST_FULL, sizeof FRX_SELFTEST_FULL - 1, 1)) {
            A->reader_free(r);
            goto fail;
        }
        while ((kind = A->reader_next(r)) >= 0) {
            if (kind == 0) break;                      /* wants bytes it will not get */
            if (kind == FRX_START) {
                s = A->reader_str(r, FRX_R_LOCAL, &len);
                if (len == 1 && s[0] == 'a') {
                    saw_start = 1;
                    if (A->reader_int(r, FRX_R_KIND) != FRX_START) break;
                    if (A->reader_int(r, FRX_R_DEPTH) != 2) break;
                    if (A->reader_int(r, FRX_R_EMPTY)) break;
                    if (A->reader_attr_count(r) != 1) break;
                    {
                        const char *ans, *al, *av;
                        STRLEN anl, all, avl;
                        A->reader_attr(r, 0, &ans, &anl, &al, &all, &av, &avl);
                        if (all != 2 || memcmp(al, "id", 2) || avl != 2 || memcmp(av, "a1", 2)) break;
                    }
                    if (!A->reader_offset(r)) break;
                    saw_start = 2;
                }
            } else if (kind == FRX_TEXT) {
                s = A->reader_str(r, FRX_R_VALUE, &len);
                if (len == 2 && memcmp(s, "<&", 2) == 0) saw_cdata = 1;
            }
        }
        FRX_STEP(23);
        if (saw_start != 2) { A->reader_free(r); goto fail; }
        FRX_STEP(24);
        if (!saw_cdata) { A->reader_free(r); goto fail; }
        FRX_STEP(25);
        if (!A->reader_int(r, FRX_R_DONE)) { A->reader_free(r); goto fail; }
        FRX_STEP(26);
        if (A->reader_error(r) == NULL) { A->reader_free(r); goto fail; }
        A->reader_free(r);
    }

    /* the reader again, this time cutting one element out as a document */
    {
        frx_reader *r = A->reader_new(&oe);
        frx_doc *sub = NULL;
        int kind;
        FRX_STEP(27);
        if (!r) goto fail;
        (void)A->reader_feed(r, FRX_SELFTEST_FULL, sizeof FRX_SELFTEST_FULL - 1, 1);
        while ((kind = A->reader_next(r)) > 0) {
            if (kind != FRX_START) continue;
            s = A->reader_str(r, FRX_R_LOCAL, &len);
            if (len == 1 && s[0] == 'a') { sub = A->reader_subtree(r); break; }
        }
        FRX_STEP(28);
        if (!sub) { A->reader_free(r); goto fail; }
        FRX_STEP(29);
        s = A->local(A->root(sub), &len);
        if (len != 1 || s[0] != 'a') { A->doc_free(aTHX_ sub); A->reader_free(r); goto fail; }
        A->doc_free(aTHX_ sub);
        A->reader_free(r);
    }

    /* the mutable tree, built from nothing and then taken apart */
    FRX_STEP(30);
    built = A->new_document(0);
    if (!built) goto fail;
    FRX_STEP(31);
    el = A->new_element(built, "urn:x", 5, "p", 1, "top", 3, &err);
    if (!el) goto fail;
    FRX_STEP(32);
    if (!A->append_child(built, (frx_node *)A->document(built), el, &err)) goto fail;
    FRX_STEP(33);
    if (!A->set_attr(built, el, "", 0, "", 0, "k", 1, "v", 1, &err)) goto fail;
    FRX_STEP(34);
    s = A->attr_value(el, "", "k", &len);
    if (!s || len != 1 || s[0] != 'v') goto fail;
    FRX_STEP(35);
    tx = A->new_text(built, "hi", 2, &err);
    if (!tx || !A->append_child(built, el, tx, &err)) goto fail;
    FRX_STEP(36);
    {
        frx_node *c = A->new_comment(built, " c ", 3, &err);
        frx_node *pi = A->new_pi(built, "t", 1, "d", 1, &err);
        if (!c || !pi) goto fail;
        if (!A->insert_before(built, tx, c, &err)) goto fail;
        if (!A->append_child(built, el, pi, &err)) goto fail;
    }
    FRX_STEP(37);
    if (!A->declare_ns(built, el, "q", 1, "urn:q", 5, &err)) goto fail;
    FRX_STEP(38);
    if (!A->set_name(built, el, "urn:x", 5, "p", 1, "renamed", 7, &err)) goto fail;
    FRX_STEP(39);
    s = A->local(el, &len);
    if (len != 7 || memcmp(s, "renamed", 7)) goto fail;
    FRX_STEP(40);
    if (!A->set_text(built, tx, "bye", 3, &err)) goto fail;
    FRX_STEP(41);
    if (!A->remove_attr(built, el, "", 0, "k", 1, &err)) goto fail;
    FRX_STEP(42);
    if (A->attr_value(el, "", "k", &len) != NULL) goto fail;
    FRX_STEP(43);
    {
        frx_node *copy = A->import_node(built, A->find(A->root(d), NULL, "a", NULL), &err);
        if (!copy) goto fail;
        if (!A->append_child(built, el, copy, &err)) goto fail;
        if (!A->remove_node(built, copy, &err)) goto fail;
    }
    FRX_STEP(44);
    /* a refusal leaves the tree alone and fills err */
    if (A->new_element(built, NULL, 0, "", 0, "1bad", 4, &err) != NULL) goto fail;
    FRX_STEP(45);
    if (err.code == FRX_OK || !err.what) goto fail;

    /* XPath, compiled once and evaluated against two documents */
    {
        frx_ns_binding b;
        frx_ns_map     map;
        frx_xpath     *x;
        frx_xp_result *res;
        const char    *xerr = NULL;
        STRLEN         xat = 0;

        b.prefix = "p"; b.uri = "urn:x";
        map.v = &b; map.n = 1;

        FRX_STEP(46);
        x = A->xpath_compile("count(//p:renamed)", 18, &map, 0, &xerr, &xat);
        if (!x) goto fail;
        FRX_STEP(47);
        res = A->xpath_result_new();
        if (!res) { A->xpath_free(x); goto fail; }
        FRX_STEP(48);
        if (!A->xpath_eval(x, built, A->document(built), res, &xerr)) goto fail_x;
        FRX_STEP(49);
        if (A->xpath_result_kind(res) != FRX_XP_NUMBER) goto fail_x;
        FRX_STEP(50);
        if (A->xpath_result_number(res) != 1.0) goto fail_x;
        A->xpath_result_free(res);
        A->xpath_free(x);

        FRX_STEP(51);
        x = A->xpath_compile("//a/@id", 7, NULL, 0, &xerr, &xat);
        if (!x) goto fail;
        res = A->xpath_result_new();
        FRX_STEP(52);
        if (!res || !A->xpath_eval(x, d, A->document(d), res, &xerr)) goto fail_x;
        FRX_STEP(53);
        if (A->xpath_result_kind(res) != FRX_XP_NODESET) goto fail_x;
        FRX_STEP(54);
        if (A->xpath_result_count(res) != 1) goto fail_x;
        FRX_STEP(55);
        {
            int kind = -1, index = -1;
            n = A->xpath_result_node(res, 0, &kind, &index);
            if (!n || kind != FRX_XP_KATTR || index != 0) goto fail_x;
            A->attr(n, index, NULL, NULL, &s, &len, NULL, NULL);
            if (len != 2 || memcmp(s, "id", 2)) goto fail_x;
        }
        FRX_STEP(56);
        if (A->xpath_result_node(res, 1, NULL, NULL) != NULL) goto fail_x;
        A->xpath_result_free(res);
        A->xpath_free(x);

        /* a variable, and an unmapped prefix as a compile refusal */
        FRX_STEP(57);
        x = A->xpath_compile("string($v)", 10, NULL, 0, &xerr, &xat);
        if (!x) goto fail;
        FRX_STEP(58);
        if (A->xpath_var_count(x) != 1) { A->xpath_free(x); goto fail; }
        FRX_STEP(59);
        s = A->xpath_var_name(x, 0, &len);
        if (len != 1 || s[0] != 'v') { A->xpath_free(x); goto fail; }
        FRX_STEP(60);
        if (!A->xpath_bind_str(x, 0, "bound", 5)) { A->xpath_free(x); goto fail; }
        res = A->xpath_result_new();
        FRX_STEP(61);
        if (!res || !A->xpath_eval(x, d, A->document(d), res, &xerr)) goto fail_x;
        FRX_STEP(62);
        s = A->xpath_result_string(res, &len);
        if (len != 5 || memcmp(s, "bound", 5)) goto fail_x;
        A->xpath_result_free(res);
        A->xpath_free(x);

        /* the other two bindings, over one expression that reads both */
        FRX_STEP(63);
        x = A->xpath_compile("$n + 1 = 2 and $b", 17, NULL, 0, &xerr, &xat);
        if (!x) goto fail;
        FRX_STEP(64);
        if (A->xpath_var_count(x) != 2) { A->xpath_free(x); goto fail; }
        A->xpath_bind_num(x, 0, 1.0);
        A->xpath_bind_bool(x, 1, 1);
        res = A->xpath_result_new();
        FRX_STEP(65);
        if (!res || !A->xpath_eval(x, d, A->document(d), res, &xerr)) goto fail_x;
        FRX_STEP(66);
        if (A->xpath_result_kind(res) != FRX_XP_BOOLEAN) goto fail_x;
        A->xpath_result_free(res);
        A->xpath_free(x);
        goto compiled;
    fail_x:
        if (res) A->xpath_result_free(res);
        A->xpath_free(x);
        goto fail;
    compiled:
        /* an unmapped prefix is a compile refusal with an offset */
        FRX_STEP(67);
        if (A->xpath_compile("//q:e", 5, NULL, 0, &xerr, &xat) != NULL) goto fail;
        FRX_STEP(68);
        if (!xerr || !xat) goto fail;
    }

    A->doc_free(aTHX_ built);
    A->doc_free(aTHX_ d);
    return 0;

fail:
    if (out)   SvREFCNT_dec(out);
    if (d2)    A->doc_free(aTHX_ d2);
    if (built) A->doc_free(aTHX_ built);
    if (d)     A->doc_free(aTHX_ d);
    return step;
}

#endif /* FRX_ABI_IMPL_H */
