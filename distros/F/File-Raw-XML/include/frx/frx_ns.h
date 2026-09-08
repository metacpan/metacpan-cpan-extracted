#ifndef FRX_NS_H
#define FRX_NS_H

/* Namespaces 1.0: the scope chain, lookup, interning, and the rules.
 *
 * A scope chain rather than per-element copies: an element carrying
 * declarations creates a scope record pointing at the enclosing one, and a
 * lookup walks the chain. Lookups are O(depth), memory is one record per
 * declaring element, and pointers stay stable. Canonicalisation
 * collects the in-scope set by walking the chain with a per-prefix seen
 * filter.
 *
 * Namespace URIs are interned per document, so each is held once and two
 * elements in one namespace share a pointer; comparisons in find stay
 * memcmp with lengths so a consumer's own string matches too.
 *
 * The rules, each a refusal with FRX_E_NAMESPACE and an offset:
 *
 *   - The xml prefix is bound implicitly and never stored as a
 *     declaration. An explicit xmlns:xml with the correct URI is accepted
 *     and dropped; with any other URI it is refused. No other prefix may
 *     be bound to the xml namespace name (section 6.2 of the 1.0 third
 *     edition).
 *   - xmlns:xmlns is refused, and so is binding any prefix to the xmlns
 *     namespace name.
 *   - xmlns:p="" - undeclaring a prefix - is refused; that is Namespaces
 *     1.1. xmlns="" is accepted and undeclares the default.
 *   - A relative namespace URI is refused. Both Canonical XML 1.0 and 1.1
 *     require an implementation to fail on a document containing one;
 *     failing here keeps the ABI's c14n entry infallible, and Namespaces
 *     1.0 deprecates relative URIs anyway. The user decided this on
 *     2026-09-06. "Relative" means "has no scheme": RFC 3986's scheme
 *     production is ALPHA *( ALPHA / DIGIT / "+" / "-" / "." ) ":".
 *   - An element or attribute prefix with no binding in scope is refused.
 *
 * Unprefixed attributes have no namespace, never the default (6.2).
 *
 * Needs frx_tree.h. */

#define FRX_XML_NS   "http://www.w3.org/XML/1998/namespace"
#define FRX_XMLNS_NS "http://www.w3.org/2000/xmlns/"

/* the URI bound to prefix, or NULL when unbound; the default with no
 * declaration is "" (no namespace) */
static const frx_str *
frx_ns_lookup(const frx_scope *s, const char *prefix, size_t plen)
{
    static const frx_str xml_ns = { FRX_XML_NS, sizeof FRX_XML_NS - 1 };
    int i;
    if (plen == 3 && memcmp(prefix, "xml", 3) == 0) return &xml_ns;
    for (; s; s = s->up) {
        for (i = 0; i < s->n_decls; i++)
            if (frx_str_eq(&s->decls[i].prefix, prefix, plen)) {
                /* Namespaces 1.1 section 5: xmlns:p="" undeclares p. The
                 * chain stops here rather than falling through to an outer
                 * binding - that is the whole point of an undeclaration -
                 * and the prefix reads as unbound, so using it is an
                 * error. For the DEFAULT prefix an empty value is "no
                 * namespace", which is a binding and not an
                 * undeclaration, so plen guards it. */
                if (plen && !s->decls[i].uri.len) return NULL;
                return &s->decls[i].uri;
            }
    }
    return plen == 0 ? &FRX_EMPTY_STR : NULL;
}

/* RFC 3986 scheme: ALPHA *( ALPHA / DIGIT / "+" / "-" / "." ) ":" */
static int
frx_ns_is_absolute(const char *p, size_t n)
{
    size_t i;
    if (!n) return 1;                              /* the empty URI is xmlns="" */
    if (!((p[0] >= 'A' && p[0] <= 'Z') || (p[0] >= 'a' && p[0] <= 'z'))) return 0;
    for (i = 1; i < n; i++) {
        char c = p[i];
        if (c == ':') return 1;
        if (!((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')
              || (c >= '0' && c <= '9') || c == '+' || c == '-' || c == '.'))
            return 0;
    }
    return 0;
}

/* the interning table lives in the parser; the strings live in the arena */
typedef struct frx_intern {
    frx_str *uris;
    int      n;
    int      cap;
} frx_intern;

static void
frx_intern_init(frx_intern *t)
{
    t->uris = NULL;
    t->n = t->cap = 0;
}

static void
frx_intern_free(frx_intern *t)
{
    free(t->uris);
    frx_intern_init(t);
}

/* the interned copy of (p, n); p NULL on allocation failure */
static frx_str
frx_intern_uri(frx_intern *t, frx_arena *a, const char *p, size_t n)
{
    int i;
    frx_str s;
    if (!n) return FRX_EMPTY_STR;
    for (i = 0; i < t->n; i++)
        if (frx_str_eq(&t->uris[i], p, n)) return t->uris[i];
    s = frx_arena_strndup(a, p, n);
    if (!s.p) return s;
    if (t->n == t->cap) {
        int ncap = t->cap ? t->cap * 2 : 16;
        frx_str *nu = (frx_str *)realloc(t->uris, (size_t)ncap * sizeof *nu);
        if (!nu) { s.p = NULL; s.len = 0; return s; }
        t->uris = nu;
        t->cap  = ncap;
    }
    t->uris[t->n++] = s;
    return s;
}

/* split a qname at its colon; the lexer guaranteed at most one, with a
 * part on each side */
static void
frx_ns_split(const frx_str *qname, frx_str *prefix, frx_str *local)
{
    const char *colon = (const char *)memchr(qname->p, ':', qname->len);
    if (!colon) {
        *prefix = FRX_EMPTY_STR;
        *local  = *qname;
    } else {
        prefix->p   = qname->p;
        prefix->len = (size_t)(colon - qname->p);
        local->p    = colon + 1;
        local->len  = qname->len - prefix->len - 1;
    }
}

/* Is this attribute a namespace declaration, and for which prefix?
 * Returns 1 with *prefix set (empty for xmlns=""), 0 otherwise. */
static int
frx_ns_is_decl(const frx_str *qname, frx_str *prefix)
{
    if (frx_str_eq(qname, "xmlns", 5)) { *prefix = FRX_EMPTY_STR; return 1; }
    if (qname->len > 6 && memcmp(qname->p, "xmlns:", 6) == 0) {
        prefix->p   = qname->p + 6;
        prefix->len = qname->len - 6;
        return 1;
    }
    return 0;
}

#endif /* FRX_NS_H */
