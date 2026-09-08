#ifndef FRX_EDIT_H
#define FRX_EDIT_H

/* The mutable tree: building documents, editing them, moving subtrees.
 *
 * Every operation keeps the two promises the read-only tree made. Pointers
 * stay stable: a node is never moved or freed by an edit; detaching
 * unlinks it and it remains a valid node of its document, so a Perl Node
 * holding it holds the document as before. Growth is by replacement
 * block: attributes and declarations are arena blocks with a capacity,
 * and adding past it allocates a larger block, copies, and orphans the
 * old one until the document is freed (frx_tree.h says so at the top).
 *
 * Every string an edit writes is checked as XML Chars under the
 * document's version and every name as a Name or a QName, at the edit,
 * so an unwritable document cannot be built; the writer's own checks
 * (frx_write.h) are a belt over these braces. A comment may not hold
 * `--`, a PI may not hold `?>` or be targeted at `xml`.
 *
 * Namespaces on attach. When a subtree is appended or inserted, its
 * scope chain is re-rooted onto the new parent's, then every element
 * and attribute in it is checked against what is now in scope: a prefix
 * unbound there, or bound to a different URI than the node carries, gets
 * a declaration on that node, and an unprefixed element whose namespace
 * is not the default in force gets one for the default (xmlns="" when it
 * has no namespace). Every declaration goes on the node whose name would
 * otherwise change, so it is scoped to exactly what it fixes and reaches
 * no name elsewhere. A node's URI is always known: `ns` is resolved at
 * parse or given at creation, and a prefix without a namespace is
 * refused at creation.
 *
 * Cross-document moves are copies: import deep-copies a subtree into this
 * arena, with the bindings in scope at its source declared on the copy's
 * root so it means the same wherever it is attached; the source is
 * untouched. A node from another document passed to any other edit is
 * refused at the Perl boundary, because its strings live in the other
 * arena and would dangle.
 *
 * The ID index stays a sorted array. The first edit that touches it
 * copies the arena's array into a malloc'd one the document frees;
 * set_attr on an indexed name refuses a duplicate with the tree
 * unchanged and inserts in place, remove_attr and detach delete, and an
 * attached subtree's indexed attributes are checked before the link.
 * Every structural edit sets doc->renumber; frx_doc_renumber (frx_tree.h)
 * recomputes `order` in one walk when a consumer of document order asks.
 *
 * Nothing recurses (rule 2): subtree walks use frx_walk_next and an
 * explicit stack for the import.
 *
 * Needs frx_tree.h, frx_ns.h, frx_utf8.h, frx_parse.h (frx_walk_next). */

/* the refusal as an expression, for `return FRX_EDIT_FAIL(...)`, and as a
 * statement, for the functions that answer with a NULL node: the comma
 * form's discarded value is an error under the MinGW proof's -Werror */
#define FRX_EDIT_FAIL(e, off, what) (frx_err_set((e), FRX_E_SYNTAX, (off), (what)), 0)
#define FRX_EDIT_SET(e, off, what)  frx_err_set((e), FRX_E_SYNTAX, (off), (what))

static int
frx_edit_v11(const frx_doc *d)
{
    return frx_str_eq(&d->version, "1.1", 3);
}

/* every code point valid UTF-8 and a Char under the version */
static int
frx_edit_check_chars(const frx_doc *d, const char *p, size_t n, frx_err *e, const char *what)
{
    size_t i = 0;
    int v11 = frx_edit_v11(d);
    while (i < n) {
        unsigned long cp;
        size_t k;
        unsigned char c = (unsigned char)p[i];
        if (c < 0x80) { cp = c; k = 1; }
        else {
            k = frx_utf8_decode((const unsigned char *)p + i, n - i, &cp);
            if (!k) return FRX_EDIT_FAIL(e, i, "not UTF-8");
        }
        if (!(v11 ? frx_is_char11(cp) : frx_is_char(cp))) return FRX_EDIT_FAIL(e, i, what);
        i += k;
    }
    return 1;
}

/* a Name (qname 0: no colon; qname 1: at most one, a part on each side) */
static int
frx_edit_check_name(const char *p, size_t n, int qname, frx_err *e, const char *what)
{
    size_t i = 0, colons = 0;
    int first = 1;
    if (!n) return FRX_EDIT_FAIL(e, 0, what);
    while (i < n) {
        unsigned long cp;
        size_t k;
        unsigned char c = (unsigned char)p[i];
        if (c < 0x80) { cp = c; k = 1; }
        else {
            k = frx_utf8_decode((const unsigned char *)p + i, n - i, &cp);
            if (!k) return FRX_EDIT_FAIL(e, i, what);
        }
        if (cp == ':') {
            if (!qname || first || colons) return FRX_EDIT_FAIL(e, i, what);
            colons++;
            first = 1;
            i++;
            continue;
        }
        if (first ? !frx_is_name_start(cp) : !frx_is_name_char(cp)) return FRX_EDIT_FAIL(e, i, what);
        first = 0;
        i += k;
    }
    if (first) return FRX_EDIT_FAIL(e, n, what);
    return 1;
}

static int
frx_edit_dup(frx_doc *d, const char *p, size_t n, frx_str *out)
{
    *out = frx_arena_strndup(&d->arena, p ? p : "", n);
    return out->p != NULL;
}

/* ---- creation --------------------------------------------------------- */

/* an empty document with its document node; version11 selects XML 1.1 */
static frx_doc *
frx_doc_new_empty(int version11)
{
    frx_doc *d = frx_doc_new();
    if (!d) return NULL;
    d->profile  = FRX_PROFILE_FULL;
    d->max_depth = 0;
    if (version11) { d->version.p = "1.1"; d->version.len = 3; }
    d->document = frx_node_new(d, FRX_DOCUMENT, 0);
    if (!d->document) { frx_doc_free(d); return NULL; }
    return d;
}

/* the qualified name prefix:local, or local, in the arena; prefix and
 * local point into it */
static int
frx_edit_qname(frx_doc *d, const char *prefix, size_t plen, const char *local, size_t llen,
               frx_str *qname, frx_str *pfx, frx_str *loc)
{
    char *p = (char *)frx_arena_alloc(&d->arena, plen + llen + 2);
    if (!p) return 0;
    if (plen) { memcpy(p, prefix, plen); p[plen] = ':'; memcpy(p + plen + 1, local, llen); }
    else memcpy(p, local, llen);
    p[plen ? plen + 1 + llen : llen] = '\0';
    qname->p = p; qname->len = plen ? plen + 1 + llen : llen;
    frx_ns_split(qname, pfx, loc);
    return 1;
}

/* the name rules an element or attribute shares */
static int
frx_edit_check_named(const char *ns, size_t nslen, const char *prefix, size_t plen,
                     const char *local, size_t llen, frx_err *e)
{
    if (!frx_edit_check_name(local, llen, 0, e, "the local name is not a name")) return 0;
    if (plen && !frx_edit_check_name(prefix, plen, 0, e, "the prefix is not a name")) return 0;
    if (plen == 5 && memcmp(prefix, "xmlns", 5) == 0) return FRX_EDIT_FAIL(e, 0, "the xmlns prefix is not a name for elements or attributes; use declare_ns");
    if (plen && !nslen) return FRX_EDIT_FAIL(e, 0, "a prefix needs a namespace name");
    if (plen == 3 && memcmp(prefix, "xml", 3) == 0 && !(nslen == sizeof FRX_XML_NS - 1 && memcmp(ns, FRX_XML_NS, nslen) == 0))
        return FRX_EDIT_FAIL(e, 0, "the xml prefix is bound to its own namespace and no other");
    if (nslen && !frx_ns_is_absolute(ns, nslen)) return FRX_EDIT_FAIL(e, 0, "a relative namespace URI is refused");
    if (nslen == sizeof FRX_XMLNS_NS - 1 && memcmp(ns, FRX_XMLNS_NS, nslen) == 0) return FRX_EDIT_FAIL(e, 0, "the xmlns namespace name cannot be bound");
    return 1;
}

static frx_node *
frx_new_element(frx_doc *d, const char *ns, size_t nslen, const char *prefix, size_t plen,
                const char *local, size_t llen, frx_err *e)
{
    frx_node *n;
    if (!frx_edit_check_named(ns, nslen, prefix, plen, local, llen, e)) return NULL;
    n = frx_node_new(d, FRX_ELEMENT, 0);
    if (!n) { FRX_EDIT_SET(e, 0, "out of memory"); return NULL; }
    if (!frx_edit_qname(d, prefix, plen, local, llen, &n->qname, &n->prefix, &n->local)
        || !frx_edit_dup(d, ns, nslen, &n->ns)) { FRX_EDIT_SET(e, 0, "out of memory"); return NULL; }
    d->renumber = 1;
    return n;
}

static frx_node *
frx_new_text(frx_doc *d, const char *s, size_t n, frx_err *e)
{
    frx_node *node;
    if (!frx_edit_check_chars(d, s, n, e, "text holds a character that is not an XML character")) return NULL;
    node = frx_node_new(d, FRX_TEXT, 0);
    if (!node || !frx_edit_dup(d, s, n, &node->value)) { FRX_EDIT_SET(e, 0, "out of memory"); return NULL; }
    d->renumber = 1;
    return node;
}

static int
frx_edit_check_comment(const frx_doc *d, const char *s, size_t n, frx_err *e)
{
    size_t i;
    if (!frx_edit_check_chars(d, s, n, e, "a comment holds a character that is not an XML character")) return 0;
    for (i = 0; i + 1 < n; i++) if (s[i] == '-' && s[i + 1] == '-') return FRX_EDIT_FAIL(e, i, "-- is not allowed inside a comment");
    if (n && s[n - 1] == '-') return FRX_EDIT_FAIL(e, n - 1, "a comment cannot end in -");
    return 1;
}

static frx_node *
frx_new_comment(frx_doc *d, const char *s, size_t n, frx_err *e)
{
    frx_node *node;
    if (!frx_edit_check_comment(d, s, n, e)) return NULL;
    node = frx_node_new(d, FRX_COMMENT, 0);
    if (!node || !frx_edit_dup(d, s, n, &node->value)) { FRX_EDIT_SET(e, 0, "out of memory"); return NULL; }
    d->renumber = 1;
    return node;
}

static int
frx_edit_check_pi(const frx_doc *d, const char *target, size_t tlen, const char *data, size_t dlen, frx_err *e)
{
    frx_str t;
    size_t i;
    if (!frx_edit_check_name(target, tlen, 0, e, "the target is not a name")) return 0;
    t.p = target; t.len = tlen;
    if (frx_lex_target_is_xml(&t)) return FRX_EDIT_FAIL(e, 0, "the xml target is reserved");
    if (!frx_edit_check_chars(d, data, dlen, e, "the data holds a character that is not an XML character")) return 0;
    for (i = 0; i + 1 < dlen; i++) if (data[i] == '?' && data[i + 1] == '>') return FRX_EDIT_FAIL(e, i, "?> is not allowed inside a processing instruction");
    return 1;
}

static frx_node *
frx_new_pi(frx_doc *d, const char *target, size_t tlen, const char *data, size_t dlen, frx_err *e)
{
    frx_node *node;
    if (!frx_edit_check_pi(d, target, tlen, data, dlen, e)) return NULL;
    node = frx_node_new(d, FRX_PI, 0);
    if (!node || !frx_edit_dup(d, target, tlen, &node->local) || !frx_edit_dup(d, data, dlen, &node->value)) {
        FRX_EDIT_SET(e, 0, "out of memory");
        return NULL;
    }
    node->qname = node->local;
    d->renumber = 1;
    return node;
}

/* ---- the ID index ------------------------------------------------------ */

static int
frx_edit_is_id_attr(const frx_doc *d, const frx_str *local)
{
    int i;
    for (i = 0; i < d->n_id_attrs; i++) if (frx_str_eq2(&d->id_attrs[i], local)) return 1;
    return 0;
}

/* the index as a malloc'd array the document owns, once */
static int
frx_edit_ids_mut(frx_doc *d)
{
    if (d->ids_mut) return 1;
    d->cap_ids_mut = d->n_ids ? d->n_ids * 2 : 8;
    d->ids_mut = (frx_idx *)malloc((size_t)d->cap_ids_mut * sizeof *d->ids_mut);
    if (!d->ids_mut) return 0;
    if (d->n_ids) memcpy(d->ids_mut, d->ids, (size_t)d->n_ids * sizeof *d->ids_mut);
    d->ids = d->ids_mut;
    return 1;
}

/* the index slot for (attr, value): *found says a match is there */
static int
frx_edit_ids_find(const frx_doc *d, const frx_str *attr, const frx_str *value, int *found)
{
    int lo = 0, hi = d->n_ids;
    frx_idx key;
    key.attr = *attr; key.value = *value; key.node = NULL; key.offset = 0;
    while (lo < hi) {
        int mid = (lo + hi) / 2;
        int c = frx_idx_key_cmp(&d->ids[mid], &key);
        if (c < 0) lo = mid + 1; else hi = mid;
    }
    *found = lo < d->n_ids && frx_idx_key_cmp(&d->ids[lo], &key) == 0;
    return lo;
}

static int
frx_edit_ids_insert(frx_doc *d, const frx_attr *a, const frx_node *n)
{
    int found, at;
    if (!frx_edit_ids_mut(d)) return 0;
    at = frx_edit_ids_find(d, &a->local, &a->value, &found);
    if (found) return 0;                            /* the caller checked; a duplicate here is a bug */
    if (d->n_ids == d->cap_ids_mut) {
        frx_idx *ni = (frx_idx *)realloc(d->ids_mut, (size_t)d->cap_ids_mut * 2 * sizeof *ni);
        if (!ni) return 0;
        d->ids_mut = ni; d->cap_ids_mut *= 2; d->ids = ni;
    }
    memmove(d->ids_mut + at + 1, d->ids_mut + at, (size_t)(d->n_ids - at) * sizeof *d->ids_mut);
    d->ids_mut[at].attr = a->local; d->ids_mut[at].value = a->value; d->ids_mut[at].node = n; d->ids_mut[at].offset = a->offset;
    d->n_ids++;
    return 1;
}

static int
frx_edit_ids_remove(frx_doc *d, const frx_str *attr, const frx_str *value, const frx_node *n)
{
    int found, at;
    if (!d->n_ids) return 1;
    at = frx_edit_ids_find(d, attr, value, &found);
    if (!found || d->ids[at].node != n) return 1;
    if (!frx_edit_ids_mut(d)) return 0;
    memmove(d->ids_mut + at, d->ids_mut + at + 1, (size_t)(d->n_ids - at - 1) * sizeof *d->ids_mut);
    d->n_ids--;
    return 1;
}

/* the indexed attributes of a subtree, out of or into the index; a
 * duplicate on the way in is refused before anything is linked */
static int
frx_edit_ids_subtree(frx_doc *d, frx_node *root, int insert, frx_err *e)
{
    frx_node *n = root;
    if (!d->n_id_attrs) return 1;
    while (n) {
        if (n->kind == FRX_ELEMENT) {
            int i;
            for (i = 0; i < n->n_attrs; i++) {
                const frx_attr *a = &n->attrs[i];
                if (!frx_edit_is_id_attr(d, &a->local)) continue;
                if (insert) {
                    int found;
                    frx_edit_ids_find(d, &a->local, &a->value, &found);
                    if (found) return FRX_EDIT_FAIL(e, a->offset, "the attached subtree carries an ID value the document already has");
                } else if (!frx_edit_ids_remove(d, &a->local, &a->value, n)) {
                    return FRX_EDIT_FAIL(e, a->offset, "out of memory");
                }
            }
        }
        n = (frx_node *)frx_walk_next(n, root);
    }
    if (insert) {
        for (n = root; n; n = (frx_node *)frx_walk_next(n, root)) {
            if (n->kind != FRX_ELEMENT) continue;
            {
                int i;
                for (i = 0; i < n->n_attrs; i++)
                    if (frx_edit_is_id_attr(d, &n->attrs[i].local) && !frx_edit_ids_insert(d, &n->attrs[i], n))
                        return FRX_EDIT_FAIL(e, n->attrs[i].offset, "out of memory");
            }
        }
    }
    return 1;
}

/* ---- namespaces ---------------------------------------------------------- */

/* the scope an element's descendants inherit from it */
static int
frx_edit_owns_scope(const frx_node *el)
{
    return el->scope && el->n_decls && el->scope->decls == el->decls;
}

/* the subtree at root sees new_inherit where it saw old_inherit: nodes
 * sharing it, and scope records chained onto it */
static void
frx_edit_reroot(frx_node *root, const frx_scope *old_inherit, const frx_scope *new_inherit)
{
    frx_node *n = root;
    if (old_inherit == new_inherit) return;
    while (n) {
        if (n->kind == FRX_ELEMENT) {
            if (n->scope == old_inherit) n->scope = new_inherit;
            else if (n->scope && n->scope->up == old_inherit) ((frx_scope *)n->scope)->up = new_inherit;
        }
        n = (frx_node *)frx_walk_next(n, root);
    }
}

/* a declaration on el: added, or its URI replaced; el's own scope record
 * is created on the first, and its descendants re-rooted onto it */
static int
frx_declare_ns(frx_doc *d, frx_node *el, const char *prefix, size_t plen, const char *uri, size_t ulen, frx_err *e)
{
    int i;
    frx_str uri_s;
    if (el->kind != FRX_ELEMENT) return FRX_EDIT_FAIL(e, el->offset, "only an element declares a namespace");
    if (plen && !frx_edit_check_name(prefix, plen, 0, e, "the prefix is not a name")) return 0;
    if (plen == 5 && memcmp(prefix, "xmlns", 5) == 0) return FRX_EDIT_FAIL(e, el->offset, "the xmlns prefix cannot be declared");
    if (ulen == sizeof FRX_XMLNS_NS - 1 && memcmp(uri, FRX_XMLNS_NS, ulen) == 0) return FRX_EDIT_FAIL(e, el->offset, "the xmlns namespace name cannot be bound");
    if (plen == 3 && memcmp(prefix, "xml", 3) == 0) {
        if (!(ulen == sizeof FRX_XML_NS - 1 && memcmp(uri, FRX_XML_NS, ulen) == 0))
            return FRX_EDIT_FAIL(e, el->offset, "the xml prefix is bound to its own namespace and no other");
        return 1;                                   /* accepted, and dropped, as at parse */
    }
    if (ulen == sizeof FRX_XML_NS - 1 && memcmp(uri, FRX_XML_NS, ulen) == 0) return FRX_EDIT_FAIL(e, el->offset, "only the xml prefix may be bound to the xml namespace");
    if (plen && !ulen) return FRX_EDIT_FAIL(e, el->offset, "a prefix cannot be undeclared (that is Namespaces 1.1)");
    if (ulen && !frx_ns_is_absolute(uri, ulen)) return FRX_EDIT_FAIL(e, el->offset, "a relative namespace URI is refused");
    if (!frx_edit_dup(d, uri, ulen, &uri_s)) return FRX_EDIT_FAIL(e, el->offset, "out of memory");

    for (i = 0; i < el->n_decls; i++) {
        if (frx_str_eq(&el->decls[i].prefix, prefix, plen)) {
            ((frx_nsdecl *)el->decls)[i].uri = uri_s;
            return 1;
        }
    }
    if (el->n_decls == (el->cap_decls ? el->cap_decls : el->n_decls)) {
        int ncap = el->n_decls ? el->n_decls * 2 : 4;
        frx_nsdecl *nd = (frx_nsdecl *)frx_arena_alloc(&d->arena, (size_t)ncap * sizeof *nd);
        if (!nd) return FRX_EDIT_FAIL(e, el->offset, "out of memory");
        if (el->n_decls) memcpy(nd, el->decls, (size_t)el->n_decls * sizeof *nd);
        el->decls = nd;
        el->cap_decls = ncap;
    }
    {
        frx_nsdecl *nd = (frx_nsdecl *)el->decls;
        if (!frx_edit_dup(d, prefix, plen, &nd[el->n_decls].prefix)) return FRX_EDIT_FAIL(e, el->offset, "out of memory");
        nd[el->n_decls].uri = uri_s;
        el->n_decls++;
    }
    if (frx_edit_owns_scope(el) || (el->scope && el->n_decls > 1 && el->scope->decls != el->decls && el->scope->up != NULL && 0)) {
        frx_scope *s = (frx_scope *)el->scope;
        s->decls   = el->decls;
        s->n_decls = el->n_decls;
    } else if (el->scope && el->n_decls > 1) {
        /* the record exists but its block was replaced above */
        frx_scope *s = (frx_scope *)el->scope;
        s->decls   = el->decls;
        s->n_decls = el->n_decls;
    } else {
        /* the first declaration: el gets its own record over what it
         * inherited, and its descendants come with it */
        frx_scope *s = (frx_scope *)frx_arena_alloc(&d->arena, sizeof *s);
        const frx_scope *inherited = el->scope;
        if (!s) return FRX_EDIT_FAIL(e, el->offset, "out of memory");
        s->up      = inherited;
        s->decls   = el->decls;
        s->n_decls = el->n_decls;
        frx_edit_reroot(el, inherited, s);
        el->scope = s;
    }
    return 1;
}

/* After a subtree is attached: every name in it must still mean what it
 * meant. A declaration goes on the node whose name would otherwise
 * change, never on the subtree's root, so it is scoped to exactly what it
 * fixes and cannot reach a name anywhere else; that is what lets an
 * unprefixed element declare the default namespace here (the plan's
 * generated prefix was the price of declaring on a shared ancestor, and
 * nothing declares on one). An element that ends up needing no namespace
 * under a default gets xmlns="" the same way. */
static int
frx_edit_fixup(frx_doc *d, frx_node *root, frx_err *e)
{
    frx_node *n = root;
    while (n) {
        if (n->kind == FRX_ELEMENT) {
            const frx_str *bound;
            int i;
            if (n->prefix.len) {
                if (!frx_str_eq(&n->prefix, "xml", 3)) {
                    bound = frx_ns_lookup(n->scope, n->prefix.p, n->prefix.len);
                    if (!bound || !frx_str_eq2(bound, &n->ns))
                        if (!frx_declare_ns(d, n, n->prefix.p, n->prefix.len, n->ns.p, n->ns.len, e)) return 0;
                }
            } else {
                bound = frx_ns_lookup(n->scope, "", 0);
                if (!bound || !frx_str_eq2(bound, &n->ns))
                    if (!frx_declare_ns(d, n, "", 0, n->ns.p, n->ns.len, e)) return 0;
            }
            for (i = 0; i < n->n_attrs; i++) {
                const frx_attr *a = &n->attrs[i];
                if (!a->prefix.len || frx_str_eq(&a->prefix, "xml", 3)) continue;
                bound = frx_ns_lookup(n->scope, a->prefix.p, a->prefix.len);
                if (!bound || !frx_str_eq2(bound, &a->ns))
                    if (!frx_declare_ns(d, n, a->prefix.p, a->prefix.len, a->ns.p, a->ns.len, e)) return 0;
            }
        }
        n = (frx_node *)frx_walk_next(n, root);
    }
    return 1;
}

/* ---- structure ---------------------------------------------------------- */

static int
frx_edit_is_ancestor(const frx_node *maybe, const frx_node *of)
{
    for (; of; of = of->parent) if (of == maybe) return 1;
    return 0;
}

/* what an attach needs true of parent and child */
static int
frx_edit_can_attach(frx_doc *d, frx_node *parent, frx_node *child, frx_err *e)
{
    if (child->parent) return FRX_EDIT_FAIL(e, child->offset, "the node has a parent; detach it first");
    if (child->kind == FRX_DOCUMENT) return FRX_EDIT_FAIL(e, child->offset, "a document node cannot be a child");
    if (parent->kind == FRX_DOCUMENT) {
        if (child->kind == FRX_TEXT) return FRX_EDIT_FAIL(e, child->offset, "text is not allowed outside the root element");
        if (child->kind == FRX_ELEMENT && d->root) return FRX_EDIT_FAIL(e, child->offset, "a document has one root element");
    } else if (parent->kind != FRX_ELEMENT) {
        return FRX_EDIT_FAIL(e, parent->offset, "only an element or the document node has children");
    }
    if (frx_edit_is_ancestor(child, parent)) return FRX_EDIT_FAIL(e, child->offset, "a node cannot be put under itself");
    return 1;
}

/* the scope a detached subtree's root inherits: what its chain ends at */
static const frx_scope *
frx_edit_inherited(const frx_node *child)
{
    if (child->kind != FRX_ELEMENT) return NULL;
    return frx_edit_owns_scope(child) ? child->scope->up : child->scope;
}

static int
frx_edit_attach(frx_doc *d, frx_node *parent, frx_node *child, frx_node *before, frx_err *e)
{
    const frx_scope *old_inherit, *new_inherit;
    if (!frx_edit_can_attach(d, parent, child, e)) return 0;
    if (!frx_edit_ids_subtree(d, child, 1, e)) return 0;
    old_inherit = frx_edit_inherited(child);
    new_inherit = parent->kind == FRX_ELEMENT ? parent->scope : NULL;
    if (before) frx_node_insert_before(before, child);
    else        frx_node_append(parent, child);
    if (child->kind == FRX_ELEMENT) {
        frx_edit_reroot(child, old_inherit, new_inherit);
        if (!frx_edit_fixup(d, child, e)) return 0;
    }
    if (parent->kind == FRX_DOCUMENT && child->kind == FRX_ELEMENT) d->root = child;
    d->renumber = 1;
    return 1;
}

static int
frx_append_child(frx_doc *d, frx_node *parent, frx_node *child, frx_err *e)
{
    return frx_edit_attach(d, parent, child, NULL, e);
}

static int
frx_insert_before(frx_doc *d, frx_node *ref, frx_node *child, frx_err *e)
{
    if (!ref->parent) return FRX_EDIT_FAIL(e, ref->offset, "the reference node has no parent");
    return frx_edit_attach(d, ref->parent, child, ref, e);
}

/* out of the tree; the node stays a node of its document */
static int
frx_remove(frx_doc *d, frx_node *n, frx_err *e)
{
    if (n->kind == FRX_DOCUMENT) return FRX_EDIT_FAIL(e, 0, "the document node cannot be detached");
    if (!n->parent) return 1;
    if (!frx_edit_ids_subtree(d, n, 0, e)) return 0;
    if (d->root == n) d->root = NULL;
    frx_node_unlink(n);
    d->renumber = 1;
    return 1;
}

/* ---- attributes and content ---------------------------------------------- */

static int
frx_set_attr(frx_doc *d, frx_node *el, const char *ns, size_t nslen, const char *prefix, size_t plen,
             const char *local, size_t llen, const char *value, size_t vlen, frx_err *e)
{
    frx_str v, loc, nss;
    frx_attr *a = NULL;
    int i, indexed;
    if (el->kind != FRX_ELEMENT) return FRX_EDIT_FAIL(e, el->offset, "only an element has attributes");
    if (!frx_edit_check_named(ns, nslen, prefix, plen, local, llen, e)) return 0;
    if (nslen && !plen) return FRX_EDIT_FAIL(e, el->offset, "an attribute with a namespace needs a prefix");
    if (!plen && llen == 5 && memcmp(local, "xmlns", 5) == 0) return FRX_EDIT_FAIL(e, el->offset, "xmlns is a declaration; use declare_ns");
    if (!frx_edit_check_chars(d, value, vlen, e, "the value holds a character that is not an XML character")) return 0;
    loc.p = local; loc.len = llen;
    nss.p = ns; nss.len = nslen;
    indexed = frx_edit_is_id_attr(d, &loc);
    if (!frx_edit_dup(d, value, vlen, &v)) return FRX_EDIT_FAIL(e, el->offset, "out of memory");

    for (i = 0; i < el->n_attrs; i++)
        if (frx_str_eq2(&el->attrs[i].local, &loc) && frx_str_eq2(&el->attrs[i].ns, &nss)) { a = (frx_attr *)&el->attrs[i]; break; }

    if (indexed) {
        int found, at = frx_edit_ids_find(d, &loc, &v, &found);
        if (found && d->ids[at].node != el)
            return FRX_EDIT_FAIL(e, el->offset, "another element carries that ID value already");
        if (a && !frx_edit_ids_remove(d, &a->local, &a->value, el)) return FRX_EDIT_FAIL(e, el->offset, "out of memory");
    }
    if (a) {
        a->value = v;
    } else {
        if (el->n_attrs == (el->cap_attrs ? el->cap_attrs : el->n_attrs)) {
            int ncap = el->n_attrs ? el->n_attrs * 2 : 4;
            frx_attr *na = (frx_attr *)frx_arena_alloc(&d->arena, (size_t)ncap * sizeof *na);
            if (!na) return FRX_EDIT_FAIL(e, el->offset, "out of memory");
            if (el->n_attrs) memcpy(na, el->attrs, (size_t)el->n_attrs * sizeof *na);
            el->attrs = na;
            el->cap_attrs = ncap;
        }
        a = (frx_attr *)&el->attrs[el->n_attrs];
        memset(a, 0, sizeof *a);
        if (!frx_edit_qname(d, prefix, plen, local, llen, &a->qname, &a->prefix, &a->local)
            || !frx_edit_dup(d, ns, nslen, &a->ns))
            return FRX_EDIT_FAIL(e, el->offset, "out of memory");
        a->value  = v;
        a->offset = el->offset;
        el->n_attrs++;
    }
    if (indexed && !frx_edit_ids_insert(d, a, el)) return FRX_EDIT_FAIL(e, el->offset, "out of memory");
    /* the prefix must mean the namespace here */
    if (plen && !frx_str_eq(&a->prefix, "xml", 3)) {
        const frx_str *bound = frx_ns_lookup(el->scope, a->prefix.p, a->prefix.len);
        if (!bound || !frx_str_eq2(bound, &a->ns))
            if (!frx_declare_ns(d, el, prefix, plen, ns, nslen, e)) return 0;
    }
    return 1;
}

static int
frx_remove_attr(frx_doc *d, frx_node *el, const char *ns, size_t nslen, const char *local, size_t llen, frx_err *e)
{
    int i;
    if (el->kind != FRX_ELEMENT) return FRX_EDIT_FAIL(e, el->offset, "only an element has attributes");
    for (i = 0; i < el->n_attrs; i++) {
        frx_attr *a = (frx_attr *)&el->attrs[i];
        if (!frx_str_eq(&a->local, local, llen) || !frx_str_eq(&a->ns, ns, nslen)) continue;
        if (frx_edit_is_id_attr(d, &a->local) && !frx_edit_ids_remove(d, &a->local, &a->value, el))
            return FRX_EDIT_FAIL(e, el->offset, "out of memory");
        memmove(a, a + 1, (size_t)(el->n_attrs - i - 1) * sizeof *a);
        el->n_attrs--;
        if (!el->cap_attrs) el->cap_attrs = el->n_attrs + 1;   /* the block is one longer than n now */
        return 1;
    }
    return 1;
}

/* a text node's value; an element's content replaced by one text node */
static int
frx_set_text(frx_doc *d, frx_node *n, const char *s, size_t len, frx_err *e)
{
    switch (n->kind) {
    case FRX_TEXT: {
        frx_str v;
        if (!frx_edit_check_chars(d, s, len, e, "text holds a character that is not an XML character")) return 0;
        if (!frx_edit_dup(d, s, len, &v)) return FRX_EDIT_FAIL(e, n->offset, "out of memory");
        n->value = v; n->cdata_spans = NULL; n->n_cdata_spans = 0;
        return 1;
    }
    case FRX_COMMENT: {
        frx_str v;
        if (!frx_edit_check_comment(d, s, len, e)) return 0;
        if (!frx_edit_dup(d, s, len, &v)) return FRX_EDIT_FAIL(e, n->offset, "out of memory");
        n->value = v;
        return 1;
    }
    case FRX_PI: {
        frx_str v;
        if (!frx_edit_check_pi(d, n->local.p, n->local.len, s, len, e)) return 0;
        if (!frx_edit_dup(d, s, len, &v)) return FRX_EDIT_FAIL(e, n->offset, "out of memory");
        n->value = v;
        return 1;
    }
    case FRX_ELEMENT: {
        frx_node *t = frx_new_text(d, s, len, e);
        if (!t) return 0;
        while (n->first_child) {
            frx_node *c = n->first_child;
            if (!frx_remove(d, c, e)) return 0;
        }
        return frx_append_child(d, n, t, e);
    }
    default:
        return FRX_EDIT_FAIL(e, n->offset, "the document node has no text to set");
    }
}

static int
frx_set_name(frx_doc *d, frx_node *el, const char *ns, size_t nslen, const char *prefix, size_t plen,
             const char *local, size_t llen, frx_err *e)
{
    frx_str q, p, l, nss;
    if (el->kind != FRX_ELEMENT) return FRX_EDIT_FAIL(e, el->offset, "only an element is renamed");
    if (!frx_edit_check_named(ns, nslen, prefix, plen, local, llen, e)) return 0;
    if (!frx_edit_qname(d, prefix, plen, local, llen, &q, &p, &l) || !frx_edit_dup(d, ns, nslen, &nss))
        return FRX_EDIT_FAIL(e, el->offset, "out of memory");
    el->qname = q; el->prefix = p; el->local = l; el->ns = nss;
    if (el->parent) return frx_edit_fixup(d, el, e);   /* attached: the prefix must mean this here */
    return 1;
}

/* ---- import --------------------------------------------------------------- */

typedef struct frx_import_frame { const frx_node *src; frx_node *dst; } frx_import_frame;

/* one node of another document copied into d, without its children */
static frx_node *
frx_import_one(frx_doc *d, const frx_node *src, frx_err *e)
{
    frx_node *n = frx_node_new(d, src->kind, 0);
    if (!n) { FRX_EDIT_SET(e, 0, "out of memory"); return NULL; }
    switch (src->kind) {
    case FRX_ELEMENT: {
        int i;
        if (!frx_edit_dup(d, src->qname.p, src->qname.len, &n->qname) || !frx_edit_dup(d, src->ns.p, src->ns.len, &n->ns)) goto nomem;
        frx_ns_split(&n->qname, &n->prefix, &n->local);
        if (src->n_attrs) {
            frx_attr *attrs = (frx_attr *)frx_arena_alloc(&d->arena, (size_t)src->n_attrs * sizeof *attrs);
            if (!attrs) goto nomem;
            for (i = 0; i < src->n_attrs; i++) {
                attrs[i] = src->attrs[i];
                attrs[i].offset = 0;
                if (!frx_edit_dup(d, src->attrs[i].qname.p, src->attrs[i].qname.len, &attrs[i].qname)
                    || !frx_edit_dup(d, src->attrs[i].value.p, src->attrs[i].value.len, &attrs[i].value)
                    || !frx_edit_dup(d, src->attrs[i].ns.p, src->attrs[i].ns.len, &attrs[i].ns)) goto nomem;
                frx_ns_split(&attrs[i].qname, &attrs[i].prefix, &attrs[i].local);
            }
            n->attrs = attrs; n->n_attrs = src->n_attrs;
        }
        if (src->n_decls) {
            frx_nsdecl *decls = (frx_nsdecl *)frx_arena_alloc(&d->arena, (size_t)src->n_decls * sizeof *decls);
            if (!decls) goto nomem;
            for (i = 0; i < src->n_decls; i++)
                if (!frx_edit_dup(d, src->decls[i].prefix.p, src->decls[i].prefix.len, &decls[i].prefix)
                    || !frx_edit_dup(d, src->decls[i].uri.p, src->decls[i].uri.len, &decls[i].uri)) goto nomem;
            n->decls = decls; n->n_decls = src->n_decls;
        }
        return n;
    }
    case FRX_PI:
        if (!frx_edit_dup(d, src->local.p, src->local.len, &n->local)) goto nomem;
        n->qname = n->local;
        /* fall through */
    default:
        if (!frx_edit_dup(d, src->value.p, src->value.len, &n->value)) goto nomem;
        return n;
    }
nomem:
    FRX_EDIT_SET(e, 0, "out of memory");
    return NULL;
}

/* the copy's root declares every binding in scope at the source that it
 * does not already declare, so the copy means the same anywhere */
static int
frx_import_bindings(frx_doc *d, const frx_node *src, frx_node *dst, frx_err *e)
{
    const frx_scope *s;
    int i;
    for (s = src->scope; s; s = s->up) {
        for (i = 0; i < s->n_decls; i++) {
            const frx_nsdecl *dec = &s->decls[i];
            int j, have = 0;
            for (j = 0; j < dst->n_decls; j++) if (frx_str_eq2(&dst->decls[j].prefix, &dec->prefix)) have = 1;
            if (have) continue;
            if (!dec->prefix.len && !dec->uri.len) {
                /* the default undeclared: only worth saying if the copy needs it */
                continue;
            }
            if (!frx_declare_ns(d, dst, dec->prefix.p, dec->prefix.len, dec->uri.p, dec->uri.len, e)) return 0;
        }
    }
    return 1;
}

/* a detached deep copy of src, a node of another document, into d */
static frx_node *
frx_import(frx_doc *d, const frx_node *src, frx_err *e)
{
    frx_import_frame *stack = NULL;
    int sp = 0, cap = 0;
    frx_node *root, *cur_dst;
    const frx_node *cur;

    if (src->kind == FRX_DOCUMENT) { FRX_EDIT_SET(e, 0, "the document node cannot be imported; import its root"); return NULL; }
    root = frx_import_one(d, src, e);
    if (!root) return NULL;
    if (src->kind == FRX_ELEMENT) {
        /* the copy's own declarations become its scope; then the rest of
         * what was in scope at the source */
        if (root->n_decls) {
            frx_scope *s = (frx_scope *)frx_arena_alloc(&d->arena, sizeof *s);
            if (!s) { FRX_EDIT_SET(e, 0, "out of memory"); return NULL; }
            s->up = NULL; s->decls = root->decls; s->n_decls = root->n_decls;
            root->scope = s;
        }
        if (!frx_import_bindings(d, src, root, e)) return NULL;
    }

    cur = src->first_child;
    cur_dst = root;
    while (cur) {
        frx_node *copy = frx_import_one(d, cur, e);
        if (!copy) { free(stack); return NULL; }
        if (copy->kind == FRX_ELEMENT) {
            if (copy->n_decls) {
                frx_scope *s = (frx_scope *)frx_arena_alloc(&d->arena, sizeof *s);
                if (!s) { free(stack); FRX_EDIT_SET(e, 0, "out of memory"); return NULL; }
                s->up = cur_dst->scope; s->decls = copy->decls; s->n_decls = copy->n_decls;
                copy->scope = s;
            } else {
                copy->scope = cur_dst->scope;
            }
        }
        frx_node_append(cur_dst, copy);
        if (cur->first_child) {
            if (sp == cap) {
                int ncap = cap ? cap * 2 : 16;
                frx_import_frame *ns = (frx_import_frame *)realloc(stack, (size_t)ncap * sizeof *ns);
                if (!ns) { free(stack); FRX_EDIT_SET(e, 0, "out of memory"); return NULL; }
                stack = ns; cap = ncap;
            }
            stack[sp].src = cur; stack[sp].dst = cur_dst; sp++;
            cur_dst = copy;
            cur = cur->first_child;
            continue;
        }
        while (!cur->next && sp) {
            sp--;
            cur     = stack[sp].src;
            cur_dst = stack[sp].dst;
        }
        cur = cur->next;
        if (!cur && !sp) break;
    }
    free(stack);
    d->renumber = 1;
    return root;
}

#endif /* FRX_EDIT_H */
