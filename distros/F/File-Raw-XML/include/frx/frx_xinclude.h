#ifndef FRX_XINCLUDE_H
#define FRX_XINCLUDE_H

/* XInclude 1.0, under `xinclude => 1` and the full profile: the pass
 * that replaces every xi:include element with what it names.
 *
 * A pass over the tree after the parse, like validation, and the first
 * consumer of the tree's import and the second of the caller's resolver.
 * Every byte still arrives through the caller's resolver, called with
 * kind xinclude, so a document cannot reach the filesystem or the
 * network by naming an href any more than by naming an external entity.
 *
 * What is supported: href, absent for a same-document include; parse,
 * "xml" (the default) or "text"; encoding, for text; xpointer, limited
 * to the element() scheme and the bare shorthand name, both of which
 * resolve through the ID index and a child sequence walk (decision 4:
 * full XPointer needs XPath over the included document, which frx_xpath.h
 * provides, and is one call away when a consumer asks); and xi:fallback.
 * accept and accept-language are read and ignored: they are for a
 * transport this dist does not have.
 *
 * The errors XInclude 4.1 separates are separated here. A resource error
 * (the resolver refuses, or the fetched bytes do not parse) takes the
 * xi:fallback children in place of the include, or is fatal when there
 * is no fallback. An inclusion loop and a chain deeper than
 * max_xinclude_depth (default 8) are fatal whatever fallback says: a
 * document that includes itself has no fallback answer.
 *
 * Nothing recurses (rule 2). The pass is a work list of (include
 * element, chain, depth): processing one imports its content, then scans
 * exactly what was imported for further xi:include elements and pushes
 * them with the chain extended by the URI just fetched. The chain is a
 * linked list in the arena, one node per fetched URI, so two branches
 * share their common ancestry and a loop is a walk up it.
 *
 * The included subtree is imported into the including document, so the
 * result is one arena and one document, and section 4.7.5's xml:base
 * fixup puts the resolved URI on the imported root when it differs from
 * the base the include element stood at. That attribute is part of the
 * data model and appears in the canonical form; the POD says so.
 *
 * Needs frx_tree.h, frx_parse.h, frx_edit.h, frx_xmlattr.h, frx_enc.h. */

#define FRX_XI_NS "http://www.w3.org/2001/XInclude"
#define FRX_DEFAULT_MAX_XINCLUDE_DEPTH 8

/* one fetched URI on the inclusion chain, and what it was included from */
typedef struct frx_xi_chain {
    frx_str uri;
    const struct frx_xi_chain *up;
} frx_xi_chain;

typedef struct frx_xi_work {
    frx_node *inc;                  /* the xi:include element */
    const frx_xi_chain *chain;
    int depth;
} frx_xi_work;

typedef struct frx_xi {
    frx_doc *doc;
    const frx_opts_ex *oe;
    frx_err *err;
    frx_xi_work *work;
    int n_work, cap_work;
    int fetches;
    int max_depth;
} frx_xi;

/* the refusal as an expression, for `return FRX_XI_FAIL(...)`, and as a
 * statement, for the functions that answer with a NULL node: a discarded
 * comma value is an error under the MinGW proof's -Werror */
#define FRX_XI_FAIL(x, off, what) (frx_err_set((x)->err, FRX_E_SYNTAX, (off), (what)), 0)
#define FRX_XI_SET(x, off, what)  frx_err_set((x)->err, FRX_E_SYNTAX, (off), (what))

static int
frx_xi_is(const frx_node *n, const char *local)
{
    return n->kind == FRX_ELEMENT
        && frx_str_eq(&n->ns, FRX_XI_NS, sizeof FRX_XI_NS - 1)
        && frx_str_eq(&n->local, local, strlen(local));
}

/* an attribute with no namespace, which is what XInclude's are */
static const frx_str *
frx_xi_attr(const frx_node *n, const char *local)
{
    int i;
    for (i = 0; i < n->n_attrs; i++)
        if (!n->attrs[i].ns.len && frx_str_eq(&n->attrs[i].local, local, strlen(local)))
            return &n->attrs[i].value;
    return NULL;
}

static int
frx_xi_push(frx_xi *x, frx_node *inc, const frx_xi_chain *chain, int depth)
{
    if (x->n_work == x->cap_work) {
        int ncap = x->cap_work ? x->cap_work * 2 : 16;
        frx_xi_work *nw = (frx_xi_work *)realloc(x->work, (size_t)ncap * sizeof *nw);
        if (!nw) return FRX_XI_FAIL(x, inc->offset, "out of memory");
        x->work = nw; x->cap_work = ncap;
    }
    x->work[x->n_work].inc   = inc;
    x->work[x->n_work].chain = chain;
    x->work[x->n_work].depth = depth;
    x->n_work++;
    return 1;
}

/* every xi:include in the subtree at root, outermost first; one inside
 * another include's fallback is left alone, because fallback content is
 * only processed when it is used */
static int
frx_xi_scan(frx_xi *x, frx_node *root, const frx_xi_chain *chain, int depth)
{
    frx_node *n = root;
    while (n) {
        if (frx_xi_is(n, "include")) {
            if (!frx_xi_push(x, n, chain, depth)) return 0;
            /* its children are fallback: not scanned */
            while (n != root && !n->next) n = n->parent;
            if (n == root) return 1;
            n = n->next;
            continue;
        }
        n = (frx_node *)frx_walk_next(n, root);
    }
    return 1;
}

/* the element() scheme and the bare name, XPointer Framework section 3
 * and the element() scheme's own: "name", "name/1/2" or "/1/2" */
static frx_node *
frx_xi_xpointer(frx_xi *x, frx_doc *sub, const frx_str *ptr, size_t off)
{
    const char *p = ptr->p;
    size_t n = ptr->len, i = 0;
    frx_node *cur;

    if (n > 8 && memcmp(p, "element(", 8) == 0 && p[n - 1] == ')') { p += 8; n -= 9; i = 0; }
    else if (memchr(p, '(', n)) {
        FRX_XI_SET(x, off, "only the element() scheme and a bare name are supported in an xpointer");
        return NULL;
    }

    if (n && p[0] != '/') {                         /* a name, then a child sequence */
        size_t k = 0;
        const frx_node *hit;
        while (k < n && p[k] != '/') k++;
        hit = frx_by_id(sub, "id", p, k);
        if (!hit) {
            /* the ID index of the included document names it by local
             * name, so an id_attrs name and xml:id both answer here */
            int j;
            for (j = 0; j < sub->n_ids; j++)
                if (frx_str_eq(&sub->ids[j].value, p, k)) { hit = sub->ids[j].node; break; }
        }
        if (!hit) { FRX_XI_SET(x, off, "the xpointer names no element in the included document"); return NULL; }
        cur = (frx_node *)hit;
        i = k;
    } else {
        cur = sub->root;
        if (n >= 2) {                               /* /1 is the root itself */
            size_t k = 1, v = 0;
            while (k < n && p[k] >= '0' && p[k] <= '9') { v = v * 10 + (size_t)(p[k] - '0'); k++; }
            if (v != 1) { FRX_XI_SET(x, off, "an element() child sequence starts at the document element, /1"); return NULL; }
            i = k;
        } else {
            i = n;
        }
    }

    while (i < n) {                                 /* /k steps down the children */
        size_t v = 0, seen = 0;
        frx_node *c;
        if (p[i] != '/') { FRX_XI_SET(x, off, "a malformed element() child sequence"); return NULL; }
        i++;
        while (i < n && p[i] >= '0' && p[i] <= '9') { v = v * 10 + (size_t)(p[i] - '0'); i++; }
        if (!v) { FRX_XI_SET(x, off, "a malformed element() child sequence"); return NULL; }
        for (c = cur->first_child; c; c = c->next) {
            if (c->kind != FRX_ELEMENT) continue;
            if (++seen == v) break;
        }
        if (!c) { FRX_XI_SET(x, off, "the xpointer names no element in the included document"); return NULL; }
        cur = c;
    }
    return cur;
}

/* the fallback children in place of the include; the include is removed.
 * 0 when there is no fallback, which makes the resource error fatal. */
static int
frx_xi_fallback(frx_xi *x, frx_node *inc)
{
    frx_node *fb = NULL, *c;
    for (c = inc->first_child; c; c = c->next)
        if (frx_xi_is(c, "fallback")) { fb = c; break; }
    if (!fb) return 0;
    while (fb->first_child) {
        frx_node *kid = fb->first_child;
        frx_err e;
        if (!frx_remove(x->doc, kid, &e)) { *x->err = e; return -1; }
        if (!frx_insert_before(x->doc, inc, kid, &e)) { *x->err = e; return -1; }
    }
    {
        frx_err e;
        if (!frx_remove(x->doc, inc, &e)) { *x->err = e; return -1; }
    }
    return 1;
}

/* the resolver, for one href already resolved to an absolute URI */
static int
frx_xi_fetch(frx_xi *x, const frx_str *uri, frx_fetched *out, size_t off)
{
    const char *msg;
    if (!x->oe->resolve)
        return FRX_XI_FAIL(x, off, "an xi:include cannot be read without a resolver; pass resolve");
    if (x->fetches >= (x->oe->max_fetches ? x->oe->max_fetches : FRX_DEFAULT_MAX_FETCHES))
        return FRX_XI_FAIL(x, off, "more external fetches than max_fetches");
    x->fetches++;
    memset(out, 0, sizeof *out);
    msg = x->oe->resolve(x->oe->resolve_ud, NULL, uri->p, NULL, FRX_REF_XINCLUDE, out);
    if (msg) return FRX_XI_FAIL(x, off, msg);
    return 1;
}

/* parse="text": the bytes as one text node under the named encoding */
static frx_node *
frx_xi_text(frx_xi *x, const frx_fetched *f, const frx_str *enc_name, size_t off)
{
    frx_enc   enc;
    frx_err   e;
    frx_node *t;
    const char *utf8;
    size_t    ulen;
    char      name[64];

    memset(&enc, 0, sizeof enc);
    if (enc_name && enc_name->len && enc_name->len < sizeof name) {
        memcpy(name, enc_name->p, enc_name->len);
        name[enc_name->len] = '\0';
    } else {
        name[0] = '\0';
    }
    if (!frx_enc_detect(&enc, (const unsigned char *)f->bytes, f->len, name[0] ? name : NULL, &e)
        || !frx_enc_run(&enc, (const unsigned char *)f->bytes, f->len, &e)) {
        frx_enc_free(&enc);
        *x->err = e;
        x->err->offset = off;
        return NULL;
    }
    utf8 = enc.out ? enc.out : f->bytes + enc.bom;
    ulen = enc.out ? enc.out_len : f->len - (size_t)enc.bom;
    t = frx_new_text(x->doc, utf8, ulen, &e);
    frx_enc_free(&enc);
    if (!t) { *x->err = e; x->err->offset = off; }
    return t;
}

/* one xi:include: fetch, build, replace. 1 done, 0 refused. */
static int
frx_xi_one(frx_xi *x, const frx_xi_work *w)
{
    frx_node *inc = w->inc;
    const frx_str *href = frx_xi_attr(inc, "href");
    const frx_str *mode = frx_xi_attr(inc, "parse");
    const frx_str *ptr  = frx_xi_attr(inc, "xpointer");
    const frx_str *encn = frx_xi_attr(inc, "encoding");
    int text = mode && frx_str_eq(mode, "text", 4);
    frx_buf   base, uri;
    frx_str   uri_s;
    frx_fetched f;
    frx_node *content = NULL;
    frx_doc  *sub = NULL;
    const frx_xi_chain *c;
    frx_err   e;
    int ok = 1, fetched = 0, rc;

    if (mode && !text && !frx_str_eq(mode, "xml", 3))
        return FRX_XI_FAIL(x, inc->offset, "parse must be xml or text");
    if (w->depth + 1 > x->max_depth)
        return FRX_XI_FAIL(x, inc->offset, "xi:include nested deeper than max_xinclude_depth");
    if (!href && !ptr)
        return FRX_XI_FAIL(x, inc->offset, "an xi:include needs an href or an xpointer");

    /* the href against the base in force at the include element */
    frx_buf_init(&base);
    frx_buf_init(&uri);
    if (!frx_node_base_uri(inc, x->doc, &base)) { frx_buf_free(&base); frx_buf_free(&uri); return FRX_XI_FAIL(x, inc->offset, "out of memory"); }
    if (href) {
        if (!frx_uri_join(&uri, base.p ? base.p : "", base.len, href->p, href->len, 0)) ok = 0;
    } else {
        frx_buf_append_n(&uri, base.p ? base.p : "", base.len);
    }
    if (ok) ok = !uri.failed && frx_edit_dup(x->doc, uri.p ? uri.p : "", uri.len, &uri_s);
    frx_buf_free(&base);
    frx_buf_free(&uri);
    if (!ok) return FRX_XI_FAIL(x, inc->offset, "out of memory");

    /* a loop is fatal, fallback or not */
    if (href) {
        for (c = w->chain; c; c = c->up)
            if (frx_str_eq2(&c->uri, &uri_s))
                return FRX_XI_FAIL(x, inc->offset, "an xi:include names a document already being included: a loop");
    }

    if (href) {
        if (!frx_xi_fetch(x, &uri_s, &f, inc->offset)) {
            /* a resource error: the fallback, or fatal */
            rc = frx_xi_fallback(x, inc);
            if (rc < 0) return 0;
            if (rc == 0) return 0;                  /* the fetch's own message stands */
            frx_err_set(x->err, FRX_OK, 0, NULL);
            return 1;
        }
        fetched = 1;
    }

    if (text) {
        if (!href) { if (fetched && f.release) f.release(f.ud, &f); return FRX_XI_FAIL(x, inc->offset, "parse=\"text\" needs an href"); }
        content = frx_xi_text(x, &f, encn, inc->offset);
        if (f.release) f.release(f.ud, &f);
        if (!content) {
            rc = frx_xi_fallback(x, inc);
            if (rc <= 0) return 0;
            frx_err_set(x->err, FRX_OK, 0, NULL);
            return 1;
        }
    } else {
        frx_node *pick;
        if (href) {
            frx_opts_ex so = *x->oe;
            so.xinclude = 0;                        /* this pass owns the nesting */
            so.base_uri = uri_s.p;
            sub = frx_parse_doc_ex(f.bytes, f.len, &so, &e);
            if (f.release) f.release(f.ud, &f);
            if (!sub) {
                rc = frx_xi_fallback(x, inc);
                if (rc < 0) return 0;
                if (rc == 0) { *x->err = e; x->err->offset = inc->offset; return 0; }
                frx_err_set(x->err, FRX_OK, 0, NULL);
                return 1;
            }
            pick = ptr ? frx_xi_xpointer(x, sub, ptr, inc->offset) : sub->root;
            if (!pick) { frx_doc_free(sub); return 0; }
            content = frx_import(x->doc, pick, &e);
            frx_doc_free(sub);
            if (!content) { *x->err = e; return 0; }
        } else {
            /* a same-document include: the pointer over this document */
            pick = ptr ? frx_xi_xpointer(x, x->doc, ptr, inc->offset) : NULL;
            if (!pick) return 0;
            if (frx_edit_is_ancestor(pick, inc))
                return FRX_XI_FAIL(x, inc->offset, "a same-document xi:include names an ancestor of itself: a loop");
            content = frx_import(x->doc, pick, &e);
            if (!content) { *x->err = e; return 0; }
        }
        /* section 4.7.5: the included root carries where it came from,
         * when that differs from the base the include element stood at */
        if (href && content->kind == FRX_ELEMENT) {
            frx_buf inc_base;
            frx_buf_init(&inc_base);
            if (frx_node_base_uri(inc, x->doc, &inc_base)
                && !(inc_base.len == uri_s.len && (!uri_s.len || memcmp(inc_base.p, uri_s.p, uri_s.len) == 0))) {
                if (!frx_set_attr(x->doc, content, FRX_XML_NS, sizeof FRX_XML_NS - 1,
                                  "xml", 3, "base", 4, uri_s.p, uri_s.len, &e)) {
                    frx_buf_free(&inc_base);
                    *x->err = e;
                    return 0;
                }
            }
            frx_buf_free(&inc_base);
        }
    }

    if (!frx_insert_before(x->doc, inc, content, &e)) { *x->err = e; return 0; }
    if (!frx_remove(x->doc, inc, &e)) { *x->err = e; return 0; }

    /* what was just imported may include further documents */
    if (!text) {
        frx_xi_chain *link = (frx_xi_chain *)frx_arena_alloc(&x->doc->arena, sizeof *link);
        if (!link) return FRX_XI_FAIL(x, inc->offset, "out of memory");
        link->uri = uri_s;
        link->up  = w->chain;
        if (!frx_xi_scan(x, content, link, w->depth + 1)) return 0;
    }
    return 1;
}

/* the pass over the document; 0 with *err on refusal */
static int
frx_xinclude_doc(frx_doc *d, const frx_opts_ex *oe, frx_err *err)
{
    frx_xi x;
    frx_xi_chain root_chain;
    int i, ok = 1;

    memset(&x, 0, sizeof x);
    x.doc = d;
    x.oe  = oe;
    x.err = err;
    x.max_depth = oe->max_xinclude_depth ? oe->max_xinclude_depth : FRX_DEFAULT_MAX_XINCLUDE_DEPTH;
    frx_err_set(err, FRX_OK, 0, NULL);

    root_chain.uri = d->base_uri;
    root_chain.up  = NULL;
    if (!d->document || !frx_xi_scan(&x, d->document, &root_chain, 0)) { free(x.work); return 0; }

    /* the list grows as includes bring in more; each is processed once */
    for (i = 0; ok && i < x.n_work; i++) ok = frx_xi_one(&x, &x.work[i]);
    free(x.work);
    if (ok) d->renumber = 1;
    return ok;
}

#endif /* FRX_XINCLUDE_H */
