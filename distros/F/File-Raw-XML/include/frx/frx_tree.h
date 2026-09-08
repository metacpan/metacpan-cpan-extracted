#ifndef FRX_TREE_H
#define FRX_TREE_H

/* The arena tree the ABI describes.
 *
 * frx_node and frx_doc are opaque in frx_abi.h and defined here. Every
 * string is an frx_str in the document's arena, NUL-terminated, so a
 * consumer compares with memcmp and prints with %s and never copies.
 * Every pointer is stable for the life of the document because the arena
 * never reallocates (rule 3).
 *
 * An element carries its resolved namespace, prefix and local name, its
 * attributes in document order with their namespaces resolved, its own
 * namespace declarations, and a pointer to the scope that binds prefixes
 * for it and its descendants. xmlns and xmlns:* are declarations, never
 * attributes. Text, comments and PIs carry a value; a PI's target is in
 * local. The document node is kind FRX_DOCUMENT; its children are the
 * top-level comments and PIs with the root element among them.
 *
 * frx_doc_free releases the arena and the doc, and the one thing an edit
 * may have added: an ID index that grew out of the arena into a malloc'd
 * array (frx_edit.h). Nothing else is allocated.
 *
 * Mutation (frx_edit.h) pays in the arena's currency: a node is never
 * moved or freed by an edit, so every pointer stays stable as rule 3
 * promises; attributes and declarations live in blocks with a capacity,
 * and growing past it allocates a larger block, copies, and orphans the
 * old one until the document is freed. An edit loop that runs for the
 * document's life grows the arena; to_string and a reparse are the
 * compaction.
 *
 * Needs frx_abi.h, frx_arena.h, frx_utf8.h; frx_dtd is frx_dtd.h's, held
 * by pointer. This file precedes frx_lex.h, which reads frx_str helpers
 * and the doctype record from here. */

typedef struct frx_dtd frx_dtd;
struct frx_verr;                /* frx_validate.h: one collected violation */

typedef struct frx_attr {
    frx_str ns;                 /* "" when none; never the default namespace */
    frx_str prefix;             /* "" when none */
    frx_str local;
    frx_str qname;              /* as written */
    frx_str value;              /* normalised */
    size_t  offset;             /* where it was written; a default's is its declaration's */
    int     defaulted;          /* full: materialised from an ATTLIST default, not written */
} frx_attr;

typedef struct frx_nsdecl {
    frx_str prefix;             /* "" for the default namespace */
    frx_str uri;                /* "" for xmlns="" */
} frx_nsdecl;

/* An element with declarations creates a scope pointing at the enclosing
 * one; lookup walks the chain (a chain, not copies). */
typedef struct frx_scope {
    const struct frx_scope *up;
    const frx_nsdecl       *decls;
    int                     n_decls;
} frx_scope;

/* What a run of character data knows about how it got there, which
 * second edition erratum E15 needs and nothing else does. REF_CHARS: a
 * character or predefined-entity reference expanded into this run while
 * content was being read, so its characters do not "appear directly in
 * the document" and cannot be the ignorable white space of section 2.10.
 * REF_HERE: a reference stood in this run at all, the empty-replacement
 * case included, which is content even when it leaves nothing behind.
 * An entity's own replacement text carries neither: the entity is a
 * storage unit and its text stands where the reference was. */
enum { FRX_TEXT_REF_CHARS = 1, FRX_TEXT_REF_HERE = 2 };

/* frx_node.from_ref. FROM_REF is Second edition erratum E15: on a text
 * node, some of its characters were produced by a character or
 * predefined-entity reference here rather than standing in the document;
 * on an element, a reference stood directly in its content and left no
 * characters behind, which an element declared EMPTY may not hold either.
 * XMLNS_XML is on an element that wrote an xmlns:xml declaration. That
 * declaration is accepted and dropped from decls, because binding the xml
 * prefix to its own namespace changes nothing a lookup, a canonical form
 * or the writer would do; validation is the one pass that still has to
 * know it was written, because to a DTD it is an Attribute like any other
 * and VC: Attribute Value Type applies to it. */
enum { FRX_NODE_FROM_REF = 1, FRX_NODE_XMLNS_XML = 2 };

/* A CDATA section inside a merged text node: where in the value it began
 * and how long it is. Only the writer cares; the data model and
 * the canonical form see text. Recorded under the full profile only. */
typedef struct frx_span {
    size_t offset;
    size_t len;
} frx_span;

struct frx_node {
    int               kind;
    struct frx_node  *parent;
    struct frx_node  *first_child;
    struct frx_node  *last_child;
    struct frx_node  *next;
    struct frx_node  *prev;     /* so that detaching is O(1); set at parse and by every edit */
    frx_str           ns;       /* element */
    frx_str           prefix;   /* element */
    frx_str           local;    /* element; a PI's target */
    frx_str           qname;    /* element, as written */
    frx_str           value;    /* text, comment, PI */
    const frx_attr   *attrs;
    int               n_attrs;
    int               cap_attrs;    /* the block's capacity; 0 means exactly n_attrs (a parsed node) */
    const frx_nsdecl *decls;
    int               n_decls;
    int               cap_decls;
    const frx_scope  *scope;
    size_t            offset;   /* where it started, for messages */
    const frx_span   *cdata_spans;  /* text under full: the CDATA sections in value; else NULL */
    int               n_cdata_spans;
    int               from_ref;     /* FRX_NODE_* below: the provenance bits the
                                     * tree keeps, tested by mask and never for
                                     * plain truth */
    long              order;    /* document order, assigned at parse; stale when doc->renumber */
};

/* what a DOCTYPE said, under the full profile; NULL under strict */
typedef struct frx_doctype {
    frx_str name;
    frx_str public_id;          /* "" when none */
    frx_str system_id;          /* "" when none */
    frx_str subset;             /* the internal subset's text, "" when none */
    int     has_subset;         /* there was a [ ], even an empty one */
    size_t  offset;
} frx_doctype;

/* Where the ID index came from, so XPath's id() does not guess: the
 * `id_attrs` option today, the DTD's declared ID attributes under
 * validate, xml:id under full. */
enum { FRX_ID_NONE = 0, FRX_ID_ATTRS, FRX_ID_DTD, FRX_ID_XMLID };

/* one ID index entry: sorted by (attr, value) */
typedef struct frx_idx {
    frx_str          attr;      /* the attribute's local name */
    frx_str          value;
    const frx_node  *node;
    size_t           offset;
} frx_idx;

struct frx_doc {
    frx_arena        arena;
    frx_node        *document;
    frx_node        *root;
    const frx_idx   *ids;       /* NULL without id_attrs; sorted by (attr, value) */
    int              n_ids;
    frx_idx         *ids_mut;   /* the index once an edit has touched it: malloc'd, ids points at it */
    int              cap_ids_mut;
    const frx_str   *id_attrs;  /* the names indexed, copied into the arena */
    int              n_id_attrs;
    int              id_source; /* FRX_ID_* : what the index was built from */
    int              max_depth; /* as applied */
    int              profile;   /* FRX_PROFILE_* it was parsed under */
    frx_str          version;   /* "1.0" unless the declaration said otherwise */
    frx_str          base_uri;  /* the document's own URI, from the base option; "" when unknown */
    int              standalone;/* 1 yes, 0 no or unsaid */
    const frx_doctype *doctype; /* full only; NULL otherwise */
    const frx_dtd   *dtd;       /* full: what the internal subset declared; NULL without one */
    long             next_order;/* the next order value to assign */
    int              renumber;  /* set by an edit; order is stale until renumbered */
    const struct frx_verr *errors;   /* validate => collect: the violations, in document order */
    int              n_errors;
    const size_t    *undeclared_refs;   /* full: where entity references stood that
                                         * WFC: Entity Declared exempted, so that
                                         * validation can report VC: Entity Declared */
    int              n_undeclared_refs;
};

static const frx_str FRX_EMPTY_STR = { "", 0 };

static frx_doc *
frx_doc_new(void)
{
    frx_doc *d = (frx_doc *)malloc(sizeof *d);
    if (!d) return NULL;
    frx_arena_init(&d->arena);
    d->document   = NULL;
    d->root       = NULL;
    d->ids        = NULL;
    d->n_ids      = 0;
    d->ids_mut    = NULL;
    d->cap_ids_mut = 0;
    d->id_attrs   = NULL;
    d->n_id_attrs = 0;
    d->id_source  = FRX_ID_NONE;
    d->max_depth  = 0;
    d->profile    = FRX_PROFILE_STRICT;
    d->version.p  = "1.0";
    d->version.len = 3;
    d->base_uri   = FRX_EMPTY_STR;
    d->standalone = 0;
    d->doctype    = NULL;
    d->dtd        = NULL;
    d->next_order = 0;
    d->renumber   = 0;
    d->errors     = NULL;
    d->n_errors   = 0;
    return d;
}

static void
frx_doc_free(frx_doc *d)
{
    if (!d) return;
    free(d->ids_mut);
    frx_arena_free(&d->arena);
    free(d);
}

static frx_node *
frx_node_new(frx_doc *d, int kind, size_t offset)
{
    frx_node *n = (frx_node *)frx_arena_alloc(&d->arena, sizeof *n);
    if (!n) return NULL;
    memset(n, 0, sizeof *n);
    n->kind   = kind;
    n->offset = offset;
    n->ns = n->prefix = n->local = n->qname = n->value = FRX_EMPTY_STR;
    n->order  = d->next_order++;       /* nodes are created in document order */
    return n;
}

static void
frx_node_append(frx_node *parent, frx_node *child)
{
    child->parent = parent;
    child->next   = NULL;
    child->prev   = parent->last_child;
    if (parent->last_child) parent->last_child->next = child;
    else                    parent->first_child = child;
    parent->last_child = child;
}

/* child before ref, under ref's parent */
static void
frx_node_insert_before(frx_node *ref, frx_node *child)
{
    frx_node *parent = ref->parent;
    child->parent = parent;
    child->next   = ref;
    child->prev   = ref->prev;
    if (ref->prev) ref->prev->next = child;
    else           parent->first_child = child;
    ref->prev = child;
}

/* out of its parent's list; the node itself is untouched and still its
 * document's */
static void
frx_node_unlink(frx_node *n)
{
    frx_node *parent = n->parent;
    if (!parent) return;
    if (n->prev) n->prev->next = n->next; else parent->first_child = n->next;
    if (n->next) n->next->prev = n->prev; else parent->last_child = n->prev;
    n->parent = n->prev = n->next = NULL;
}

/* document order reassigned from the document node down, iteratively,
 * after edits have made it stale; cheap when nothing changed */
static void
frx_doc_renumber(frx_doc *d)
{
    frx_node *n = d->document;
    long k = 0;
    if (!d->renumber || !n) return;
    while (n) {
        n->order = k++;
        if (n->first_child) { n = n->first_child; continue; }
        while (n && !n->next) n = n->parent;
        if (n) n = n->next;
    }
    d->next_order = k;
    d->renumber   = 0;
}

static int
frx_str_eq(const frx_str *a, const char *p, size_t n)
{
    return a->len == n && (n == 0 || memcmp(a->p, p, n) == 0);
}

static int
frx_str_eq2(const frx_str *a, const frx_str *b)
{
    return frx_str_eq(a, b->p, b->len);
}

/* every byte an S: what is dropped outside the root */
static int
frx_str_is_s(const frx_str *s)
{
    size_t i;
    for (i = 0; i < s->len; i++)
        if (!frx_is_s((unsigned char)s->p[i])) return 0;
    return 1;
}

/* ---- equality over the data model ------------------------------------
 *
 * Two nodes are equal when their kinds match, an element's namespace
 * name and local name match and its attributes match as an unordered
 * set of (namespace, local name, value), text and comment values match,
 * a PI's target and data match, and their children are equal in order.
 * Prefixes, CDATA spans, the defaulted flag and offsets are not
 * compared: they are not the data model. This is the round-trip oracle
 * for the writer, iterative over an explicit stack of pairs (rule 2). */

static int
frx_node_same(const frx_node *a, const frx_node *b)
{
    int i, j;
    if (a->kind != b->kind) return 0;
    switch (a->kind) {
    case FRX_ELEMENT:
        if (!frx_str_eq2(&a->ns, &b->ns) || !frx_str_eq2(&a->local, &b->local)) return 0;
        if (a->n_attrs != b->n_attrs) return 0;
        for (i = 0; i < a->n_attrs; i++) {
            int found = 0;
            for (j = 0; j < b->n_attrs && !found; j++)
                if (frx_str_eq2(&a->attrs[i].ns, &b->attrs[j].ns)
                    && frx_str_eq2(&a->attrs[i].local, &b->attrs[j].local)
                    && frx_str_eq2(&a->attrs[i].value, &b->attrs[j].value))
                    found = 1;
            if (!found) return 0;
        }
        return 1;
    case FRX_PI:
        if (!frx_str_eq2(&a->local, &b->local)) return 0;
        /* fall through */
    case FRX_TEXT:
    case FRX_COMMENT:
        return frx_str_eq2(&a->value, &b->value);
    default:
        return 1;
    }
}

typedef struct frx_node_pair { const frx_node *a; const frx_node *b; } frx_node_pair;

static int
frx_tree_equal(const frx_node *a, const frx_node *b)
{
    frx_node_pair *stack = NULL;
    int sp = 0, cap = 0, equal = 1;
    stack = (frx_node_pair *)malloc(16 * sizeof *stack);
    if (!stack) return 0;
    cap = 16;
    stack[sp].a = a; stack[sp].b = b; sp++;
    while (sp && equal) {
        const frx_node *ca, *cb;
        sp--;
        a = stack[sp].a; b = stack[sp].b;
        if (!frx_node_same(a, b)) { equal = 0; break; }
        ca = a->first_child; cb = b->first_child;
        while (ca && cb) {
            if (sp == cap) {
                int ncap = cap * 2;
                frx_node_pair *ns = (frx_node_pair *)realloc(stack, (size_t)ncap * sizeof *ns);
                if (!ns) { free(stack); return 0; }
                stack = ns; cap = ncap;
            }
            stack[sp].a = ca; stack[sp].b = cb; sp++;
            ca = ca->next; cb = cb->next;
        }
        if (ca || cb) equal = 0;
    }
    free(stack);
    return equal;
}

#endif /* FRX_TREE_H */
