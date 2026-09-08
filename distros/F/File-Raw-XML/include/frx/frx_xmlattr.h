#ifndef FRX_XMLATTR_H
#define FRX_XMLATTR_H

/* The four attributes the XML family gives meaning to without a DTD:
 * xml:base, xml:lang, xml:space, and xml:id.
 *
 * xml:id is the parser's business and is handled where the ID index is
 * built (frx_sink.h): under the full profile it is an ID attribute in
 * every document without being named in id_attrs, its value must be an
 * NCName, and a second element with the same value is refused exactly as
 * a duplicate in id_attrs is. Under strict it is an ordinary attribute,
 * as in 0.01.
 *
 * The other three are read on request, by walking ancestors, because the
 * tree is mutable and a cached answer would go stale (decision 2). They
 * are here rather than in frx_uri.h, which the plan named, because
 * frx_uri.h knows nothing of nodes: it is included before frx_tree.h so
 * that the canonicaliser can use its join. This file is the node-shaped
 * face of the same rules.
 *
 * base_uri is XML Base section 3: the base of an element is its own
 * xml:base resolved against the base of its parent, and the base of the
 * document is the URI it was read from, which the caller supplies as the
 * `base` option and the plugin fills in from the file's path. The join
 * is frx_uri.h's plain RFC 3986 one, not the Canonical XML 1.1 variant,
 * so a document's base and a signature's xml:base cannot drift into each
 * other. Nothing is cached.
 *
 * lang is xml:lang from the nearest ancestor-or-self that carries one,
 * the empty string when none does and when the nearest says "", which
 * section 2.12 gives as the way to say no language. space is
 * xml:space from the nearest ancestor-or-self carrying it: "preserve" or
 * "default", the latter when nothing says otherwise.
 *
 * Nothing recurses: each walk is a loop up the parent chain, and the
 * base walk collects the chain into a small array first so that it can
 * be joined from the outside in.
 *
 * Needs frx_tree.h, frx_uri.h, frx_buf.h. */

/* the value of an xml: attribute on n, or NULL */
static const frx_str *
frx_xml_attr(const frx_node *n, const char *local)
{
    int i;
    if (n->kind != FRX_ELEMENT) return NULL;
    for (i = 0; i < n->n_attrs; i++) {
        const frx_attr *a = &n->attrs[i];
        if (frx_str_eq(&a->ns, FRX_XML_NS, sizeof FRX_XML_NS - 1)
            && frx_str_eq(&a->local, local, strlen(local)))
            return &a->value;
    }
    return NULL;
}

/* the nearest xml:lang at or above n; "" when none, and "" when the
 * nearest is empty, which section 2.12 uses to say "no language" */
static frx_str
frx_node_lang(const frx_node *n)
{
    for (; n; n = n->parent) {
        const frx_str *v = frx_xml_attr(n, "lang");
        if (v) return *v;
    }
    return FRX_EMPTY_STR;
}

/* "preserve" when the nearest xml:space says so, "default" otherwise */
static const char *
frx_node_space(const frx_node *n)
{
    for (; n; n = n->parent) {
        const frx_str *v = frx_xml_attr(n, "space");
        if (v) return frx_str_eq(v, "preserve", 8) ? "preserve" : "default";
    }
    return "default";
}

/* The base URI of n into out: the document's base, then every xml:base
 * from the outermost ancestor inwards, each joined onto what came
 * before. 0 on allocation failure. */
static int
frx_node_base_uri(const frx_node *n, const frx_doc *d, frx_buf *out)
{
    const frx_str **chain = NULL;
    int cap = 0, cnt = 0, i, ok = 1;
    const frx_node *c;
    frx_buf acc;

    for (c = n; c; c = c->parent) {
        const frx_str *v = frx_xml_attr(c, "base");
        if (!v) continue;
        if (cnt == cap) {
            int ncap = cap ? cap * 2 : 8;
            const frx_str **nc = (const frx_str **)realloc(chain, (size_t)ncap * sizeof *nc);
            if (!nc) { free(chain); return 0; }
            chain = nc; cap = ncap;
        }
        chain[cnt++] = v;
    }

    frx_buf_init(&acc);
    frx_buf_append_n(&acc, d->base_uri.p, d->base_uri.len);
    for (i = cnt - 1; ok && i >= 0; i--) {          /* outermost first */
        frx_buf joined;
        frx_buf_init(&joined);
        ok = frx_uri_join(&joined, acc.p ? acc.p : "", acc.len, chain[i]->p, chain[i]->len, 0);
        if (ok) {
            acc.len = 0;
            frx_buf_append_n(&acc, joined.p ? joined.p : "", joined.len);
            ok = !acc.failed;
        }
        frx_buf_free(&joined);
    }
    free(chain);
    out->len = 0;
    if (ok) {
        frx_buf_append_n(out, acc.p ? acc.p : "", acc.len);
        ok = !out->failed;
    }
    frx_buf_free(&acc);
    return ok;
}

#endif /* FRX_XMLATTR_H */
