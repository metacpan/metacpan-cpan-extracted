#ifndef FRX_C14N_H
#define FRX_C14N_H

/* Canonical XML: the serialiser, the node set, and the three algorithms.
 *
 * THE NODE SET is the apex's subtree minus every `without` subtree. A node
 * in `without` excludes itself, its attributes, its declarations and
 * everything below it; one outside the apex's subtree excludes nothing;
 * one equal to the apex renders nothing. Exclusion never orphans a node -
 * a node's ancestors are in the set whenever the node is - so exclusion
 * never triggers the ancestor-inheritance rules, and that is why the
 * enveloped-signature transform can be an exclusion during serialisation
 * rather than an edit of the tree. The tree is never mutated.
 *
 * The only element whose ancestors are outside the set is therefore the
 * apex, and the ancestor rules of each algorithm apply to it alone.
 *
 * RENDERING, shared by every mode (Canonical XML 1.0 section 2.3):
 *   - names as written; declarations before attributes; declarations
 *     sorted by prefix with the default first; attributes sorted by
 *     namespace URI then local name, the empty URI least;
 *   - text escapes & < > and CR; attribute values escape & < " TAB CR LF
 *     (> is not escaped in a value, " is not escaped in text);
 *   - comment and PI bodies unescaped; <?target data?> or <?target?>;
 *   - <a></a>, never <a/>; comments only when asked; PIs always; the
 *     declaration and any DOCTYPE never;
 *   - a document apex renders top-level comments and PIs with a newline
 *     after each one before the root and before each one after it.
 *
 * NAMESPACES, inclusive (Canonical XML 1.0 and 1.1): an element renders an
 * in-scope binding unless its parent in the output has the same binding
 * in scope; xmlns="" is rendered only when a non-empty default was in
 * scope above; the xml prefix is never rendered. For the apex, whose
 * parent is outside the set, every in-scope binding is rendered.
 * Exclusive renders only what is visibly utilised.
 *
 * THE APEX AND xml: ATTRIBUTES. Canonical XML 1.0 section 2.4: the nearest
 * occurrence of every attribute in the xml namespace on the omitted
 * ancestors is copied onto the apex unless the apex has one of that name.
 * Canonical XML 1.1 section 2.4: only xml:lang and xml:space are simple
 * inheritable and are copied that way; xml:id is never copied; xml:base
 * is joined - the values on the omitted ancestors and the apex, outermost
 * first, reduced from the innermost pair outward through the spec's
 * "join-URI-References", which is RFC 3986 sections 5.2.1, 5.2.2 and
 * 5.2.4 with these changes: the base needs no scheme; a trailing ".." on
 * the base becomes "../"; remove-dot-segments keeps leading "../"
 * segments, collapses runs of "/", and appends "/" to a trailing "..";
 * the reference's fragment is dropped. The join is performed only when an
 * omitted ancestor had an xml:base, and an empty result is not rendered.
 * Every other xml: attribute is ordinary. Exclusive inherits nothing.
 *
 * Output is UTF-8 bytes into an frx_buf; the SV layer wraps them once
 * with no character flag, because a signature is over bytes.
 *
 * THE DOCUMENT'S VERSION IS NOT CONSULTED. Canonical XML and Exclusive
 * XML Canonicalization are defined over the data model - nodes, names,
 * values - and say nothing about the XML version that produced it. An
 * XML 1.1 document (full profile) reaches here as the same kind of tree,
 * its NEL and LS line ends already LF and its referenced restricted
 * characters already characters, and canonicalises under all three
 * algorithms exactly as a 1.0 document does; no declaration is ever
 * rendered, so no version is either.
 *
 * Nothing recurses (rule 2): the walk is iterative, the end tags emitted
 * on the way back up. malloc for the scratch arrays, freed before return.
 *
 * Needs frx_abi.h, frx_buf.h, frx_uri.h, frx_tree.h, frx_ns.h, frx_parse.h. */

/* ---- escaping --------------------------------------------------------- */

static void
frx_c14n_esc_text(frx_buf *o, const char *p, size_t n)
{
    size_t i, run = 0;
    for (i = 0; i < n; i++) {
        const char *rep = NULL;
        switch (p[i]) {
        case '&':  rep = "&amp;";  break;
        case '<':  rep = "&lt;";   break;
        case '>':  rep = "&gt;";   break;
        case '\r': rep = "&#xD;";  break;
        default: break;
        }
        if (rep) {
            if (i > run) frx_buf_append_n(o, p + run, i - run);
            frx_buf_append(o, rep);
            run = i + 1;
        }
    }
    if (n > run) frx_buf_append_n(o, p + run, n - run);
}

static void
frx_c14n_esc_attr(frx_buf *o, const char *p, size_t n)
{
    size_t i, run = 0;
    for (i = 0; i < n; i++) {
        const char *rep = NULL;
        switch (p[i]) {
        case '&':  rep = "&amp;";  break;
        case '<':  rep = "&lt;";   break;
        case '"':  rep = "&quot;"; break;
        case '\t': rep = "&#x9;";  break;
        case '\n': rep = "&#xA;";  break;
        case '\r': rep = "&#xD;";  break;
        default: break;
        }
        if (rep) {
            if (i > run) frx_buf_append_n(o, p + run, i - run);
            frx_buf_append(o, rep);
            run = i + 1;
        }
    }
    if (n > run) frx_buf_append_n(o, p + run, n - run);
}

/* ---- the xml:base join: frx_uri.h in its Canonical XML 1.1 form ------- */

static int
frx_join_base(frx_buf *out, const char *base, size_t blen, const char *ref, size_t rlen)
{
    return frx_uri_join(out, base, blen, ref, rlen, 1);
}

/* ---- the renderer ------------------------------------------------------ */

typedef struct frx_c14n_ns {
    frx_str prefix;
    frx_str uri;
} frx_c14n_ns;

/* an attribute to render: the element's own, or one inherited onto the apex */
typedef struct frx_c14n_attr {
    frx_str ns;
    frx_str local;
    frx_str qname;
    frx_str value;
} frx_c14n_attr;

typedef struct frx_c14n_ctx {
    const frx_c14n *c;
    frx_buf        *out;
    const frx_node *apex;
    int             failed;
    frx_c14n_ns    *ns;   int n_ns,   cap_ns;    /* this element's rendered declarations */
    frx_c14n_attr  *at;   int n_at,   cap_at;    /* this element's rendered attributes */
    frx_buf         base;                        /* the joined xml:base, when any */
    /* ns_rendered of the Recommendation's section 3.1: every declaration an
     * output ancestor rendered, nearest last, with a mark per open element
     * so the end tag restores the ancestor's view */
    frx_c14n_ns    *rendered; int n_rendered, cap_rendered;
    int            *marks;    int n_marks,    cap_marks;
} frx_c14n_ctx;

static int
frx_c14n_omitted(const frx_c14n *c, const frx_node *n)
{
    int i;
    for (i = 0; i < c->n_without; i++)
        if (c->without[i] == n) return 1;
    return 0;
}

static int
frx_c14n_is_xml_ns(const frx_str *ns)
{
    return frx_str_eq(ns, FRX_XML_NS, sizeof FRX_XML_NS - 1);
}

static int
frx_c14n_push_ns(frx_c14n_ctx *x, const frx_str *prefix, const frx_str *uri)
{
    if (x->n_ns == x->cap_ns) {
        int ncap = x->cap_ns ? x->cap_ns * 2 : 16;
        frx_c14n_ns *nn = (frx_c14n_ns *)realloc(x->ns, (size_t)ncap * sizeof *nn);
        if (!nn) { x->failed = 1; return 0; }
        x->ns = nn; x->cap_ns = ncap;
    }
    x->ns[x->n_ns].prefix = *prefix;
    x->ns[x->n_ns].uri    = *uri;
    x->n_ns++;
    return 1;
}

static int
frx_c14n_push_attr(frx_c14n_ctx *x, const frx_str *ns, const frx_str *local,
                   const frx_str *qname, const frx_str *value)
{
    if (x->n_at == x->cap_at) {
        int ncap = x->cap_at ? x->cap_at * 2 : 16;
        frx_c14n_attr *na = (frx_c14n_attr *)realloc(x->at, (size_t)ncap * sizeof *na);
        if (!na) { x->failed = 1; return 0; }
        x->at = na; x->cap_at = ncap;
    }
    x->at[x->n_at].ns    = *ns;
    x->at[x->n_at].local = *local;
    x->at[x->n_at].qname = *qname;
    x->at[x->n_at].value = *value;
    x->n_at++;
    return 1;
}

/* is prefix already in x->ns? */
static int
frx_c14n_ns_seen(const frx_c14n_ctx *x, const frx_str *prefix)
{
    int i;
    for (i = 0; i < x->n_ns; i++)
        if (frx_str_eq2(&x->ns[i].prefix, prefix)) return 1;
    return 0;
}

/* is prefix in the PrefixList ("#default" names the default)? */
static int
frx_c14n_in_prefix_list(const frx_c14n *c, const frx_str *prefix)
{
    int i;
    for (i = 0; i < c->n_prefix; i++) {
        const char *p = c->prefix_list[i];
        if (prefix->len == 0) {
            if (strcmp(p, "#default") == 0) return 1;
        } else if (frx_str_eq(prefix, p, strlen(p))) {
            return 1;
        }
    }
    return 0;
}

static int
frx_c14n_cmp_ns(const void *pa, const void *pb)
{
    const frx_c14n_ns *a = (const frx_c14n_ns *)pa, *b = (const frx_c14n_ns *)pb;
    return frx_str_cmp(&a->prefix, &b->prefix);
}

static int
frx_c14n_cmp_attr(const void *pa, const void *pb)
{
    const frx_c14n_attr *a = (const frx_c14n_attr *)pa, *b = (const frx_c14n_attr *)pb;
    int c = frx_str_cmp(&a->ns, &b->ns);
    return c ? c : frx_str_cmp(&a->local, &b->local);
}

/* what the output ancestors rendered for prefix, nearest wins; NULL when
 * none did */
static const frx_str *
frx_c14n_rendered_value(const frx_c14n_ctx *x, const frx_str *prefix)
{
    int i;
    for (i = x->n_rendered - 1; i >= 0; i--)
        if (frx_str_eq2(&x->rendered[i].prefix, prefix)) return &x->rendered[i].uri;
    return NULL;
}

/* remember what this element rendered, behind a mark its end tag pops */
static int
frx_c14n_push_frame(frx_c14n_ctx *x)
{
    int i;
    if (x->n_marks == x->cap_marks) {
        int ncap = x->cap_marks ? x->cap_marks * 2 : 32;
        int *nm = (int *)realloc(x->marks, (size_t)ncap * sizeof *nm);
        if (!nm) { x->failed = 1; return 0; }
        x->marks = nm; x->cap_marks = ncap;
    }
    x->marks[x->n_marks++] = x->n_rendered;
    for (i = 0; i < x->n_ns; i++) {
        if (x->n_rendered == x->cap_rendered) {
            int ncap = x->cap_rendered ? x->cap_rendered * 2 : 32;
            frx_c14n_ns *nr = (frx_c14n_ns *)realloc(x->rendered, (size_t)ncap * sizeof *nr);
            if (!nr) { x->failed = 1; return 0; }
            x->rendered = nr; x->cap_rendered = ncap;
        }
        x->rendered[x->n_rendered++] = x->ns[i];
    }
    return 1;
}

static void
frx_c14n_pop_frame(frx_c14n_ctx *x)
{
    if (x->n_marks > 0) x->n_rendered = x->marks[--x->n_marks];
}

/* Does element e visibly utilise prefix? Its own, or one of its
 * attributes' (an unprefixed attribute utilises nothing). */
static int
frx_c14n_utilised(const frx_node *e, const frx_str *prefix)
{
    int i;
    if (frx_str_eq2(&e->prefix, prefix)) return 1;
    if (prefix->len == 0) return 0;
    for (i = 0; i < e->n_attrs; i++)
        if (frx_str_eq2(&e->attrs[i].prefix, prefix)) return 1;
    return 0;
}

/* Collect the declarations e renders, into x->ns, sorted.
 *
 * Candidates are every in-scope binding, nearest per prefix, with the
 * default counted as "" when nothing declared it. Inclusive keeps every
 * candidate; exclusive keeps those e visibly utilises or the PrefixList
 * names. A candidate is then rendered unless an output ancestor rendered
 * the same prefix with the same value (ns_rendered, section 3.1 of the
 * exclusive Recommendation, which for inclusive is the same test as
 * section 2.3 of Canonical XML). xmlns="" is the one candidate rendered
 * only when an ancestor rendered a non-empty default: there is nothing to
 * undo otherwise. */
static int
frx_c14n_collect_ns(frx_c14n_ctx *x, const frx_node *e)
{
    const frx_scope *s;
    int exclusive = x->c->mode == FRX_C14N_EXC;
    int i, w, saw_default = 0;

    x->n_ns = 0;
    for (s = e->scope; s; s = s->up) {
        for (i = 0; i < s->n_decls; i++) {
            const frx_nsdecl *d = &s->decls[i];
            if (frx_c14n_ns_seen(x, &d->prefix)) continue;
            if (!frx_c14n_push_ns(x, &d->prefix, &d->uri)) return 0;
            if (d->prefix.len == 0) saw_default = 1;
        }
    }
    if (!saw_default && !frx_c14n_push_ns(x, &FRX_EMPTY_STR, &FRX_EMPTY_STR)) return 0;

    w = 0;
    for (i = 0; i < x->n_ns; i++) {
        const frx_c14n_ns *c = &x->ns[i];
        const frx_str *have;
        int keep;
        if (exclusive && !frx_c14n_in_prefix_list(x->c, &c->prefix)
            && !frx_c14n_utilised(e, &c->prefix)) {
            keep = 0;
        } else {
            have = frx_c14n_rendered_value(x, &c->prefix);
            if (c->prefix.len == 0 && c->uri.len == 0)
                keep = have != NULL && have->len > 0;
            else
                keep = have == NULL || !frx_str_eq2(have, &c->uri);
        }
        if (keep) x->ns[w++] = *c;
    }
    x->n_ns = w;
    if (x->n_ns > 1) qsort(x->ns, (size_t)x->n_ns, sizeof *x->ns, frx_c14n_cmp_ns);
    return 1;
}

/* the nearest ancestor attribute in the xml namespace with this local
 * name, above e (e itself excluded); NULL when none */
static const frx_attr *
frx_c14n_nearest_xml(const frx_node *e, const char *local)
{
    const frx_node *a;
    for (a = e->parent; a && a->kind == FRX_ELEMENT; a = a->parent) {
        int i;
        for (i = 0; i < a->n_attrs; i++)
            if (frx_c14n_is_xml_ns(&a->attrs[i].ns) && frx_str_eq(&a->attrs[i].local, local, strlen(local)))
                return &a->attrs[i];
    }
    return NULL;
}

static const frx_attr *
frx_c14n_own_xml(const frx_node *e, const char *local)
{
    int i;
    for (i = 0; i < e->n_attrs; i++)
        if (frx_c14n_is_xml_ns(&e->attrs[i].ns) && frx_str_eq(&e->attrs[i].local, local, strlen(local)))
            return &e->attrs[i];
    return NULL;
}

/* Collect the attributes e renders, into x->at, sorted: its own, plus
 * what the algorithm inherits onto the apex. */
static int
frx_c14n_collect_attrs(frx_c14n_ctx *x, const frx_node *e)
{
    int i;
    int is_apex = e == x->apex && e->parent && e->parent->kind == FRX_ELEMENT;

    x->n_at = 0;
    for (i = 0; i < e->n_attrs; i++) {
        const frx_attr *a = &e->attrs[i];
        if (!frx_c14n_push_attr(x, &a->ns, &a->local, &a->qname, &a->value)) return 0;
    }
    if (!is_apex || x->c->mode == FRX_C14N_EXC) goto sort;

    if (x->c->mode == FRX_C14N_INC10) {
        /* every xml: attribute, nearest occurrence, unless e has it */
        const frx_node *a;
        for (a = e->parent; a && a->kind == FRX_ELEMENT; a = a->parent) {
            for (i = 0; i < a->n_attrs; i++) {
                const frx_attr *at = &a->attrs[i];
                int j, have = 0;
                if (!frx_c14n_is_xml_ns(&at->ns)) continue;
                for (j = 0; j < x->n_at; j++)
                    if (frx_c14n_is_xml_ns(&x->at[j].ns) && frx_str_eq2(&x->at[j].local, &at->local)) { have = 1; break; }
                if (have) continue;
                if (!frx_c14n_push_attr(x, &at->ns, &at->local, &at->qname, &at->value)) return 0;
            }
        }
    } else {
        /* 1.1: xml:lang and xml:space simply; xml:base joined; xml:id never */
        static const char *const simple[] = { "lang", "space" };
        size_t k;
        for (k = 0; k < sizeof simple / sizeof simple[0]; k++) {
            const frx_attr *near;
            if (frx_c14n_own_xml(e, simple[k])) continue;
            near = frx_c14n_nearest_xml(e, simple[k]);
            if (near && !frx_c14n_push_attr(x, &near->ns, &near->local, &near->qname, &near->value)) return 0;
        }
        {
            /* the ancestors' xml:base values, outermost first, then e's own */
            const frx_node *a;
            const frx_attr **vals = NULL;
            int nv = 0, cap = 0, any_ancestor = 0, depth = 0;
            const frx_attr *own = frx_c14n_own_xml(e, "base");
            for (a = e->parent; a && a->kind == FRX_ELEMENT; a = a->parent) depth++;
            if (depth) {
                vals = (const frx_attr **)malloc((size_t)(depth + 1) * sizeof *vals);
                if (!vals) { x->failed = 1; return 0; }
                cap = depth + 1;
                /* fill from the innermost ancestor backwards into the array's tail */
                nv = 0;
                for (a = e->parent; a && a->kind == FRX_ELEMENT; a = a->parent) {
                    const frx_attr *b = frx_c14n_own_xml(a, "base");
                    if (b) { vals[nv++] = b; any_ancestor = 1; }
                }
                /* vals is innermost-first; the reduction wants innermost-first
                 * combining, so this order is the one to consume */
            }
            if (any_ancestor) {
                /* acc = own (or the innermost ancestor value); then for each
                 * further outer value: acc = join(outer, acc) */
                frx_buf acc;
                int start = 0;
                frx_buf_init(&acc);
                if (own) {
                    frx_buf_append_n(&acc, own->value.p, own->value.len);
                } else {
                    frx_buf_append_n(&acc, vals[0]->value.p, vals[0]->value.len);
                    start = 1;
                }
                for (i = start; i < nv && !x->failed; i++) {
                    frx_buf tmp;
                    frx_buf_init(&tmp);
                    if (!frx_join_base(&tmp, vals[i]->value.p, vals[i]->value.len,
                                       acc.p ? acc.p : "", acc.len)) { x->failed = 1; }
                    frx_buf_free(&acc);
                    acc = tmp;
                }
                x->base.len = 0;
                frx_buf_append_n(&x->base, acc.p ? acc.p : "", acc.len);
                frx_buf_free(&acc);
                /* replace e's own xml:base with the joined value, or add it */
                if (x->base.len && !x->failed) {
                    static const frx_str q = { "xml:base", 8 };
                    static const frx_str l = { "base", 4 };
                    static const frx_str nsx = { FRX_XML_NS, sizeof FRX_XML_NS - 1 };
                    frx_str v;
                    int j, replaced = 0;
                    v.p = x->base.p; v.len = x->base.len;
                    for (j = 0; j < x->n_at; j++) {
                        if (frx_c14n_is_xml_ns(&x->at[j].ns) && frx_str_eq(&x->at[j].local, "base", 4)) {
                            x->at[j].value = v; replaced = 1; break;
                        }
                    }
                    if (!replaced && !frx_c14n_push_attr(x, &nsx, &l, &q, &v)) { free(vals); return 0; }
                } else if (!x->failed) {
                    /* an empty result: xml:base MUST NOT be rendered */
                    int j, w = 0;
                    for (j = 0; j < x->n_at; j++) {
                        if (frx_c14n_is_xml_ns(&x->at[j].ns) && frx_str_eq(&x->at[j].local, "base", 4)) continue;
                        x->at[w++] = x->at[j];
                    }
                    x->n_at = w;
                }
            }
            free(vals);
            (void)cap;
            if (x->failed) return 0;
        }
    }
sort:
    if (x->n_at > 1) qsort(x->at, (size_t)x->n_at, sizeof *x->at, frx_c14n_cmp_attr);
    return 1;
}

static void
frx_c14n_start_tag(frx_c14n_ctx *x, const frx_node *e)
{
    frx_buf *o = x->out;
    int i;
    if (!frx_c14n_collect_ns(x, e) || !frx_c14n_collect_attrs(x, e)) return;
    frx_buf_append_ch(o, '<');
    frx_buf_append_n(o, e->qname.p, e->qname.len);
    for (i = 0; i < x->n_ns; i++) {
        frx_buf_append(o, " xmlns");
        if (x->ns[i].prefix.len) {
            frx_buf_append_ch(o, ':');
            frx_buf_append_n(o, x->ns[i].prefix.p, x->ns[i].prefix.len);
        }
        frx_buf_append(o, "=\"");
        frx_c14n_esc_attr(o, x->ns[i].uri.p, x->ns[i].uri.len);
        frx_buf_append_ch(o, '"');
    }
    for (i = 0; i < x->n_at; i++) {
        frx_buf_append_ch(o, ' ');
        frx_buf_append_n(o, x->at[i].qname.p, x->at[i].qname.len);
        frx_buf_append(o, "=\"");
        frx_c14n_esc_attr(o, x->at[i].value.p, x->at[i].value.len);
        frx_buf_append_ch(o, '"');
    }
    frx_buf_append_ch(o, '>');
    frx_c14n_push_frame(x);
}

static void
frx_c14n_end_tag(frx_c14n_ctx *x, const frx_node *e)
{
    frx_buf_append(x->out, "</");
    frx_buf_append_n(x->out, e->qname.p, e->qname.len);
    frx_buf_append_ch(x->out, '>');
    frx_c14n_pop_frame(x);
}

static void
frx_c14n_misc(frx_c14n_ctx *x, const frx_node *n)
{
    frx_buf *o = x->out;
    switch (n->kind) {
    case FRX_TEXT:
        frx_c14n_esc_text(o, n->value.p, n->value.len);
        break;
    case FRX_COMMENT:
        if (x->c->comments) {
            frx_buf_append(o, "<!--");
            frx_buf_append_n(o, n->value.p, n->value.len);
            frx_buf_append(o, "-->");
        }
        break;
    case FRX_PI:
        frx_buf_append(o, "<?");
        frx_buf_append_n(o, n->local.p, n->local.len);
        if (n->value.len) {
            frx_buf_append_ch(o, ' ');
            frx_buf_append_n(o, n->value.p, n->value.len);
        }
        frx_buf_append(o, "?>");
        break;
    default:
        break;
    }
}

/* the subtree rooted at the element `top`, iteratively */
static void
frx_c14n_subtree(frx_c14n_ctx *x, const frx_node *top)
{
    const frx_node *n = top;
    if (frx_c14n_omitted(x->c, top)) return;
    for (;;) {
        int descend = 0;
        if (x->failed) return;
        if (!frx_c14n_omitted(x->c, n)) {
            if (n->kind == FRX_ELEMENT) {
                frx_c14n_start_tag(x, n);
                if (n->first_child) descend = 1;
                else frx_c14n_end_tag(x, n);
            } else {
                frx_c14n_misc(x, n);
            }
        }
        if (descend) { n = n->first_child; continue; }
        /* ascend, closing on the way, until a sibling or the top */
        while (n != top && !n->next) {
            n = n->parent;
            frx_c14n_end_tag(x, n);
        }
        if (n == top) return;
        n = n->next;
    }
}

/* the whole thing: 1 and bytes in out, or 0 on allocation failure */
static int
frx_c14n_render(const frx_node *apex, const frx_c14n *c, frx_buf *out)
{
    frx_c14n_ctx x;
    memset(&x, 0, sizeof x);
    x.c    = c;
    x.out  = out;
    x.apex = apex;
    frx_buf_init(&x.base);

    if (apex->kind == FRX_DOCUMENT) {
        /* misc before the root: each followed by "\n"; after: each preceded */
        const frx_node *n;
        int after_root = 0;
        for (n = apex->first_child; n && !x.failed; n = n->next) {
            if (frx_c14n_omitted(c, n)) continue;
            if (n->kind == FRX_ELEMENT) {
                x.apex = n;                                /* the root has no omitted ancestors */
                frx_c14n_subtree(&x, n);
                x.apex = apex;
                after_root = 1;
            } else if (n->kind == FRX_COMMENT && !c->comments) {
                continue;
            } else {
                if (after_root) frx_buf_append_ch(out, '\n');
                frx_c14n_misc(&x, n);
                if (!after_root) frx_buf_append_ch(out, '\n');
            }
        }
    } else if (apex->kind == FRX_ELEMENT) {
        frx_c14n_subtree(&x, apex);
    } else {
        if (!frx_c14n_omitted(c, apex)) frx_c14n_misc(&x, apex);
    }

    free(x.ns);
    free(x.at);
    free(x.rendered);
    free(x.marks);
    frx_buf_free(&x.base);
    return !x.failed && !out->failed;
}

#endif /* FRX_C14N_H */
