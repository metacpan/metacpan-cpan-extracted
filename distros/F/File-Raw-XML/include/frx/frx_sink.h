#ifndef FRX_SINK_H
#define FRX_SINK_H

/* What the parse driver produces, and the tree builder as one consumer
 * of it.
 *
 * frx_parse.h resolves names and namespaces, enforces every
 * well-formedness constraint, merges text, and then calls a sink: a
 * vtable of start, end, text, comment, pi, doctype and finish. Every sink
 * sees resolved names and only well-formed sequences, because the checks
 * live in the driver and not in any sink. The tree sink here builds the
 * document the codec returns; frx_reader.h's sink queues events for a
 * pull reader; the reader's subtree capture is this tree sink again,
 * copying, over one element of a stream.
 *
 * Ownership: an event's strings and arrays live in the driver's token
 * arena. In tree mode that arena is the document's own, so the tree sink
 * keeps the pointers and copies nothing, exactly as 0.01's parser did. In
 * copy mode (a subtree cut out of a stream) every string is duplicated
 * into the document's arena and the namespace chain is rebuilt from the
 * event's scope, because the reader releases its token arena at the end
 * of each record.
 *
 * Needs frx_tree.h, frx_ns.h; frx_parse.h declares frx_parse and the
 * event structs and includes this file after them. */

typedef struct frx_tree_sink {
    frx_doc   *doc;
    frx_frame *top;             /* the open element's frame; NULL at the top level */
    frx_idx   *ids;             /* growing, malloc'd; copied into the arena at finish */
    int        n_ids;
    int        cap_ids;
    int        copy;            /* duplicate every string into doc's arena */
} frx_tree_sink;

static void
frx_tree_sink_init(frx_tree_sink *ts, frx_doc *doc, int copy)
{
    memset(ts, 0, sizeof *ts);
    ts->doc  = doc;
    ts->copy = copy;
}

static void
frx_tree_sink_free(frx_tree_sink *ts)
{
    free(ts->ids);
    ts->ids = NULL;
    ts->n_ids = ts->cap_ids = 0;
}

static frx_node *
frx_tree_sink_parent(frx_tree_sink *ts)
{
    return ts->top ? ts->top->node : ts->doc->document;
}

/* s into the document's arena when copying; s itself otherwise */
static int
frx_tree_sink_str(frx_tree_sink *ts, const frx_str *s, frx_str *out)
{
    if (!ts->copy) { *out = *s; return 1; }
    *out = frx_arena_strndup(&ts->doc->arena, s->p ? s->p : "", s->len);
    return out->p != NULL;
}

static int
frx_tree_sink_push_id(frx_parse *p, frx_tree_sink *ts, const frx_attr *a, const frx_node *n)
{
    if (ts->n_ids == ts->cap_ids) {
        int ncap = ts->cap_ids ? ts->cap_ids * 2 : 16;
        frx_idx *ni = (frx_idx *)realloc(ts->ids, (size_t)ncap * sizeof *ni);
        if (!ni) return frx_parse_nomem(p, a->offset);
        ts->ids    = ni;
        ts->cap_ids = ncap;
    }
    ts->ids[ts->n_ids].attr   = a->local;
    ts->ids[ts->n_ids].value  = a->value;
    ts->ids[ts->n_ids].node   = n;
    ts->ids[ts->n_ids].offset = a->offset;
    ts->n_ids++;
    return 1;
}

/* An ID attribute: one named in id_attrs by local name in any namespace,
 * or, under the full profile, xml:id, which the xml:id Recommendation
 * makes an ID in every document with no declaration. Under
 * strict xml:id is an ordinary attribute, as in 0.01, so that profile's
 * index cannot grow an entry. */
static int
frx_tree_sink_is_id_attr(const frx_tree_sink *ts, const frx_attr *a)
{
    int i;
    for (i = 0; i < ts->doc->n_id_attrs; i++)
        if (frx_str_eq2(&ts->doc->id_attrs[i], &a->local)) return 1;
    if (ts->doc->profile == FRX_PROFILE_FULL
        && frx_str_eq(&a->ns, FRX_XML_NS, sizeof FRX_XML_NS - 1)
        && frx_str_eq(&a->local, "id", 2)) return 1;
    return 0;
}

/* the element's scope when copying: the subtree's root flattens the
 * whole chain it inherits into one record (nearest binding first, which
 * is the order lookup walks), a descendant with declarations gets a
 * record over its parent's, one without shares its parent's */
static const frx_scope *
frx_tree_sink_scope(frx_tree_sink *ts, const frx_ev_start *ev, const frx_nsdecl *own, int n_own)
{
    frx_arena *a = &ts->doc->arena;
    frx_scope *s;
    if (ts->top) {
        if (!n_own) return ts->top->node->scope;
        s = (frx_scope *)frx_arena_alloc(a, sizeof *s);
        if (!s) return NULL;
        s->up = ts->top->node->scope;
        s->decls = own;
        s->n_decls = n_own;
        return s;
    }
    {
        const frx_scope *c;
        int total = 0, k = 0;
        frx_nsdecl *all;
        for (c = ev->scope; c; c = c->up) total += c->n_decls;
        if (!total) return NULL;
        all = (frx_nsdecl *)frx_arena_alloc(a, (size_t)total * sizeof *all);
        s   = (frx_scope *)frx_arena_alloc(a, sizeof *s);
        if (!all || !s) return NULL;
        for (c = ev->scope; c; c = c->up) {
            int i;
            for (i = 0; i < c->n_decls; i++) {
                all[k].prefix = frx_arena_strndup(a, c->decls[i].prefix.p, c->decls[i].prefix.len);
                all[k].uri    = frx_arena_strndup(a, c->decls[i].uri.p, c->decls[i].uri.len);
                if (!all[k].prefix.p || !all[k].uri.p) return NULL;
                k++;
            }
        }
        s->up = NULL;
        s->decls = all;
        s->n_decls = total;
        return s;
    }
}

static int
frx_tree_sink_start(frx_parse *p, void *ud, const frx_ev_start *ev)
{
    frx_tree_sink *ts = (frx_tree_sink *)ud;
    frx_doc  *d = ts->doc;
    frx_node *n = frx_node_new(d, FRX_ELEMENT, ev->offset);
    int i;
    if (!n) return frx_parse_nomem(p, ev->offset);

    if (!frx_tree_sink_str(ts, &ev->qname, &n->qname)) return frx_parse_nomem(p, ev->offset);
    frx_ns_split(&n->qname, &n->prefix, &n->local);
    if (!frx_tree_sink_str(ts, &ev->ns, &n->ns)) return frx_parse_nomem(p, ev->offset);
    if (ev->xmlns_xml) n->from_ref |= FRX_NODE_XMLNS_XML;

    if (ev->n_decls) {
        if (ts->copy) {
            frx_nsdecl *decls = (frx_nsdecl *)frx_arena_alloc(&d->arena, (size_t)ev->n_decls * sizeof *decls);
            if (!decls) return frx_parse_nomem(p, ev->offset);
            for (i = 0; i < ev->n_decls; i++) {
                if (!frx_tree_sink_str(ts, &ev->decls[i].prefix, &decls[i].prefix)
                    || !frx_tree_sink_str(ts, &ev->decls[i].uri, &decls[i].uri))
                    return frx_parse_nomem(p, ev->offset);
            }
            n->decls = decls;
        } else {
            n->decls = ev->decls;
        }
        n->n_decls = ev->n_decls;
    }
    if (ts->copy) {
        n->scope = frx_tree_sink_scope(ts, ev, n->decls, n->n_decls);
        if (!n->scope && (ev->scope || n->n_decls)) return frx_parse_nomem(p, ev->offset);
    } else {
        n->scope = ev->scope;
    }

    if (ev->n_attrs) {
        if (ts->copy) {
            frx_attr *attrs = (frx_attr *)frx_arena_alloc(&d->arena, (size_t)ev->n_attrs * sizeof *attrs);
            if (!attrs) return frx_parse_nomem(p, ev->offset);
            for (i = 0; i < ev->n_attrs; i++) {
                attrs[i] = ev->attrs[i];
                if (!frx_tree_sink_str(ts, &ev->attrs[i].qname, &attrs[i].qname)
                    || !frx_tree_sink_str(ts, &ev->attrs[i].value, &attrs[i].value)
                    || !frx_tree_sink_str(ts, &ev->attrs[i].ns, &attrs[i].ns))
                    return frx_parse_nomem(p, ev->offset);
                frx_ns_split(&attrs[i].qname, &attrs[i].prefix, &attrs[i].local);
            }
            n->attrs = attrs;
        } else {
            n->attrs = ev->attrs;
        }
        n->n_attrs = ev->n_attrs;
        for (i = 0; i < n->n_attrs; i++) {
            const frx_attr *a = &n->attrs[i];
            if (!frx_tree_sink_is_id_attr(ts, a)) continue;
            if (frx_str_eq(&a->ns, FRX_XML_NS, sizeof FRX_XML_NS - 1)) {
                /* xml:id section 4: the value must be an NCName */
                if (!frx_is_ncname(a->value.p, a->value.len))
                    return FRX_PARSE_FAIL(p, FRX_E_SYNTAX, a->offset,
                                          "an xml:id value must be an NCName");
                if (d->id_source == FRX_ID_NONE) d->id_source = FRX_ID_XMLID;
            }
            if (!frx_tree_sink_push_id(p, ts, a, n)) return 0;
        }
    }

    frx_node_append(frx_tree_sink_parent(ts), n);
    if (!ts->top) d->root = n;
    if (!ev->empty) {
        frx_frame *f = (frx_frame *)frx_arena_alloc(&d->arena, sizeof *f);
        if (!f) return frx_parse_nomem(p, ev->offset);
        f->node = n;
        f->up   = ts->top;
        ts->top = f;
    }
    return 1;
}

static int
frx_tree_sink_end(frx_parse *p, void *ud, const frx_str *qname, size_t offset)
{
    frx_tree_sink *ts = (frx_tree_sink *)ud;
    (void)p; (void)qname; (void)offset;
    if (ts->top) ts->top = ts->top->up;
    return 1;
}

static int
frx_tree_sink_text(frx_parse *p, void *ud, const char *s, size_t n,
                   const frx_span *spans, int n_spans, size_t offset, const frx_str *entity,
                   int text_flags)
{
    frx_tree_sink *ts = (frx_tree_sink *)ud;
    frx_node *node;
    (void)entity;
    /* A reference whose replacement text is empty produces a run with no
     * characters. There is no text node for it - the data model has none,
     * and one would change every walk and every canonical form - but the
     * reference did stand in the element's content, which is what an
     * element declared EMPTY may not have (erratum E15, case E15a).
     * An empty CDATA section is not this: it is still a section, it still
     * has a span, and it still makes the content character data. */
    if (n == 0 && n_spans == 0 && (text_flags & FRX_TEXT_REF_HERE)) {
        frx_node *parent = frx_tree_sink_parent(ts);
        if (parent) parent->from_ref |= FRX_NODE_FROM_REF;
        return 1;
    }
    node = frx_node_new(ts->doc, FRX_TEXT, offset);
    if (!node) return frx_parse_nomem(p, offset);
    node->from_ref = (text_flags & FRX_TEXT_REF_CHARS) ? FRX_NODE_FROM_REF : 0;
    node->value = frx_arena_strndup(&ts->doc->arena, s ? s : "", n);
    if (!node->value.p) return frx_parse_nomem(p, offset);
    if (n_spans) {
        frx_span *sp = (frx_span *)frx_arena_alloc(&ts->doc->arena, (size_t)n_spans * sizeof *sp);
        if (!sp) return frx_parse_nomem(p, offset);
        memcpy(sp, spans, (size_t)n_spans * sizeof *sp);
        node->cdata_spans   = sp;
        node->n_cdata_spans = n_spans;
    }
    frx_node_append(frx_tree_sink_parent(ts), node);
    return 1;
}

static int
frx_tree_sink_misc(frx_parse *p, frx_tree_sink *ts, int kind, const frx_str *name, const frx_str *value, size_t offset)
{
    frx_node *node = frx_node_new(ts->doc, kind, offset);
    if (!node) return frx_parse_nomem(p, offset);
    if (!frx_tree_sink_str(ts, value, &node->value)) return frx_parse_nomem(p, offset);
    if (name && !frx_tree_sink_str(ts, name, &node->local)) return frx_parse_nomem(p, offset);
    frx_node_append(frx_tree_sink_parent(ts), node);
    return 1;
}

static int
frx_tree_sink_comment(frx_parse *p, void *ud, const frx_str *value, size_t offset)
{
    return frx_tree_sink_misc(p, (frx_tree_sink *)ud, FRX_COMMENT, NULL, value, offset);
}

static int
frx_tree_sink_pi(frx_parse *p, void *ud, const frx_str *target, const frx_str *data, size_t offset)
{
    return frx_tree_sink_misc(p, (frx_tree_sink *)ud, FRX_PI, target, data, offset);
}

static int
frx_tree_sink_doctype(frx_parse *p, void *ud, const frx_doctype *dt, const frx_dtd *dtd)
{
    frx_tree_sink *ts = (frx_tree_sink *)ud;
    (void)p;
    ts->doc->doctype = dt;
    ts->doc->dtd     = dtd;
    return 1;
}

static int
frx_str_cmp(const frx_str *a, const frx_str *b)
{
    size_t n = a->len < b->len ? a->len : b->len;
    int c = n ? memcmp(a->p, b->p, n) : 0;
    if (c) return c;
    return a->len < b->len ? -1 : a->len > b->len ? 1 : 0;
}

/* the search order: (attr, value) */
static int
frx_idx_key_cmp(const void *pa, const void *pb)
{
    const frx_idx *a = (const frx_idx *)pa, *b = (const frx_idx *)pb;
    int c = frx_str_cmp(&a->attr, &b->attr);
    return c ? c : frx_str_cmp(&a->value, &b->value);
}

/* the sort order: the key, then the offset, so among equal keys the
 * later one sorts after and the duplicate check cites it */
static int
frx_idx_cmp(const void *pa, const void *pb)
{
    const frx_idx *a = (const frx_idx *)pa, *b = (const frx_idx *)pb;
    int c = frx_idx_key_cmp(pa, pb);
    if (c) return c;
    return a->offset < b->offset ? -1 : a->offset > b->offset ? 1 : 0;
}

/* sort, refuse duplicates, move the index into the arena. Two elements
 * sharing a value are refused rather than resolved to either, because
 * "which one" is the whole of the signature wrapping attack. */
static int
frx_tree_sink_finish(frx_parse *p, void *ud)
{
    frx_tree_sink *ts = (frx_tree_sink *)ud;
    frx_idx *in_arena;
    int i;
    if (!ts->n_ids) return 1;
    qsort(ts->ids, (size_t)ts->n_ids, sizeof *ts->ids, frx_idx_cmp);
    for (i = 1; i < ts->n_ids; i++) {
        if (frx_str_eq2(&ts->ids[i].attr, &ts->ids[i - 1].attr)
            && frx_str_eq2(&ts->ids[i].value, &ts->ids[i - 1].value))
            return FRX_PARSE_FAIL(p, FRX_E_DUP_ID, ts->ids[i].offset,
                                  "two elements carry the same ID value");
    }
    in_arena = (frx_idx *)frx_arena_alloc(&ts->doc->arena, (size_t)ts->n_ids * sizeof *in_arena);
    if (!in_arena) return frx_parse_nomem(p, 0);
    memcpy(in_arena, ts->ids, (size_t)ts->n_ids * sizeof *in_arena);
    ts->doc->ids   = in_arena;
    ts->doc->n_ids = ts->n_ids;
    return 1;
}

static const frx_sink FRX_TREE_SINK = {
    frx_tree_sink_start, frx_tree_sink_end, frx_tree_sink_text,
    frx_tree_sink_comment, frx_tree_sink_pi, frx_tree_sink_doctype,
    frx_tree_sink_finish
};

#endif /* FRX_SINK_H */
