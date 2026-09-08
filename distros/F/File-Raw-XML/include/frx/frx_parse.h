#ifndef FRX_PARSE_H
#define FRX_PARSE_H

/* Tokens become events; a sink makes them a tree, or a stream.
 *
 * An iterative driver with an explicit open-element stack (rule 2): each
 * open element is a record in a malloc'd array, so depth costs no C
 * stack. Depth is the stack height; the root is depth 1, an opening tag
 * at max_depth + 1 is refused, and the default of 256 applies when
 * max_depth is 0.
 *
 * The driver resolves names and namespaces (frx_ns.h: the scope chain,
 * interning, the rules), enforces the well-formedness constraints (one
 * root, matching end tags, duplicate attributes, unbound prefixes), and
 * merges text: character data accumulates until a non-text token
 * arrives, then goes to the sink as one text event, which is how adjacent
 * text and CDATA merge in O(n). Whitespace outside the root is dropped;
 * anything else outside the root is refused.
 *
 * What it produces goes to a sink (frx_sink.h): the tree sink the codec
 * uses, the reader's queue, or a subtree capture. The driver allocates an
 * event's arrays in tok_arena and interns namespace URIs in arena; in
 * tree mode both are the document's, so the tree sink keeps every
 * pointer, and 0.01's tree is what it always was (t/30 pins its bytes).
 * A reader gives a token arena it releases per record.
 *
 * The driver is stepped: frx_parse_step reads one token and calls the
 * sink for what it means, and says whether the input ended, ended
 * inside a token (more bytes wanted, the lexer having rewound), or was
 * refused. The whole-document parse is that step in a loop.
 *
 * Under the full profile the lexer hands over a DOCTYPE token after it
 * has read the subset; the driver's part is that it stands before the
 * root, and it passes the records on. Defaulted attributes arrive in the
 * token's attribute list like written ones, flagged, so a defaulted
 * xmlns is a declaration here like any other.
 *
 * The walkers the object layer wraps - find, descendants, text - live
 * here, iterative, so that the XS above is wrappers and nothing else.
 *
 * Needs frx_err.h, frx_arena.h, frx_buf.h, frx_utf8.h, frx_tree.h,
 * frx_lex.h, frx_dtd.h, frx_entity.h, frx_ns.h; frx_sink.h is included
 * from here, after the types it needs. */

#define FRX_DEFAULT_MAX_DEPTH 256

/* the tree sink's open-element frame, in the document's arena */
typedef struct frx_frame {
    frx_node          *node;
    struct frx_frame  *up;
} frx_frame;

/* a start event: the element with its names resolved */
typedef struct frx_ev_start {
    frx_str           qname;
    frx_str           prefix;
    frx_str           local;
    frx_str           ns;
    const frx_attr   *attrs;        /* document order, namespaces resolved; never xmlns */
    int               n_attrs;
    const frx_nsdecl *decls;
    int               n_decls;
    const frx_scope  *scope;        /* what binds prefixes for it and its descendants */
    size_t            offset;
    int               empty;        /* <a/>: no end event follows */
    int               xmlns_xml;    /* an xmlns:xml declaration was written and dropped */
} frx_ev_start;

typedef struct frx_parse frx_parse;

typedef struct frx_sink {
    int (*start)(frx_parse *p, void *ud, const frx_ev_start *ev);
    int (*end)(frx_parse *p, void *ud, const frx_str *qname, size_t offset);
    int (*text)(frx_parse *p, void *ud, const char *s, size_t n,
                const frx_span *spans, int n_spans, size_t offset, const frx_str *entity,
                int text_flags);
    int (*comment)(frx_parse *p, void *ud, const frx_str *value, size_t offset);
    int (*pi)(frx_parse *p, void *ud, const frx_str *target, const frx_str *data, size_t offset);
    int (*doctype)(frx_parse *p, void *ud, const frx_doctype *dt, const frx_dtd *dtd);
    int (*finish)(frx_parse *p, void *ud);        /* at a successful end of input; may be NULL */
} frx_sink;

/* an open element */
typedef struct frx_open {
    frx_str          qname;
    const frx_scope *scope;
    size_t           offset;
} frx_open;

struct frx_parse {
    frx_lex     lex;
    frx_err     err;
    int         failed;
    int         profile;        /* FRX_PROFILE_*; read here and in frx_lex.h, nowhere else */
    int         validate;       /* full: the root element name must match the DOCTYPE (a VC) */
    const frx_sink *sink;
    void       *ud;
    frx_arena  *arena;          /* interned namespace URIs: for the parse's life */
    frx_arena  *tok_arena;      /* an event's arrays: a reader may release them per record */
    frx_open   *stack;          /* the open elements, malloc'd */
    int         depth;
    int         cap_stack;
    int         max_depth;
    int         seen_root;
    const frx_doctype *doctype;
    frx_intern  intern;
    frx_buf     text;           /* pending character data */
    int         have_text;
    size_t      text_offset;
    frx_str     text_entity;    /* the entity the pending text came from */
    int         text_flags;     /* FRX_TEXT_REF_*, ored over the pending run */
    int         split_entities; /* a text event per entity boundary (the reader); else merged */
    frx_span   *spans;          /* full: the CDATA sections in the pending text; malloc'd */
    int         n_spans;
    int         cap_spans;
};

enum { FRX_STEP_FAIL = 0, FRX_STEP_OK = 1, FRX_STEP_MORE = 2, FRX_STEP_EOF = 3 };

/* A size-aware read of a consumer's frx_opts_ex: the defaults, then as
 * many bytes as the consumer's struct holds (never more than ours), so a
 * struct from an older or a newer header is read whole and never past its
 * end. Every reader of the extended options goes through this. */
static void
frx_opts_ex_norm(const frx_opts_ex *in, frx_opts_ex *out)
{
    memset(out, 0, sizeof *out);
    out->size    = sizeof *out;
    out->profile = FRX_PROFILE_STRICT;
    if (in) {
        size_t n = in->size < sizeof *out ? in->size : sizeof *out;
        if (n > sizeof(size_t)) memcpy((char *)out + sizeof(size_t),
                                       (const char *)in + sizeof(size_t),
                                       n - sizeof(size_t));
        out->size = sizeof *out;
    }
}

/* frx_validate.h, which follows this file because it walks the finished
 * tree with the walkers defined at the end of it */
static int frx_validate_doc(frx_doc *doc, int collect, frx_err *err);
static int frx_xinclude_doc(frx_doc *doc, const frx_opts_ex *oe, frx_err *err);

#define FRX_PARSE_FAIL(p, c, off, what) \
    (frx_err_set(&(p)->err, (c), (off), (what)), (p)->failed = 1, 0)

static int
frx_parse_nomem(frx_parse *p, size_t off)
{
    return FRX_PARSE_FAIL(p, FRX_E_NOMEM, off, "out of memory");
}

#include "frx_sink.h"

/* ---- the driver ------------------------------------------------------- */

/* the driver over options already normalised; the input and the lexer
 * are set separately, because a reader has no bytes yet */
static void
frx_parse_init(frx_parse *p, const frx_opts_ex *oe, frx_arena *arena, frx_arena *tok_arena,
               const frx_sink *sink, void *ud)
{
    memset(p, 0, sizeof *p);
    p->profile   = oe->profile == FRX_PROFILE_FULL ? FRX_PROFILE_FULL : FRX_PROFILE_STRICT;
    p->validate  = oe->validate != 0;
    p->max_depth = (oe->base.max_depth > 0) ? oe->base.max_depth : FRX_DEFAULT_MAX_DEPTH;
    p->sink      = sink;
    p->ud        = ud;
    p->arena     = arena;
    p->tok_arena = tok_arena;
    p->text_entity = FRX_EMPTY_STR;
    frx_intern_init(&p->intern);
    frx_buf_init(&p->text);
}

/* what the extended options say to the lexer, once it exists */
static void
frx_parse_wire_lex(frx_parse *p, const frx_opts_ex *oe)
{
    frx_lex *l = &p->lex;
    if (oe->max_expansion_bytes) l->max_expansion_bytes = oe->max_expansion_bytes;
    if (oe->max_entity_depth)    l->max_entity_depth    = oe->max_entity_depth;
    if (oe->max_expansion_ratio) l->max_expansion_ratio = oe->max_expansion_ratio;
    if (oe->max_fetches)         l->max_fetches         = oe->max_fetches;
    if (oe->max_token_bytes)     l->max_token_bytes     = oe->max_token_bytes;
    l->resolve    = oe->resolve;
    l->resolve_ud = oe->resolve_ud;
    l->max_bytes  = oe->base.max_bytes;
    l->validate   = p->validate;
    if (oe->base_uri) {
        l->cur_base.p   = oe->base_uri;
        l->cur_base.len = strlen(oe->base_uri);
    }
}

static void
frx_parse_free(frx_parse *p)
{
    frx_lex_free(&p->lex);
    frx_intern_free(&p->intern);
    frx_buf_free(&p->text);
    free(p->spans);
    free(p->stack);
    p->spans = NULL;
    p->stack = NULL;
}

static const frx_scope *
frx_parse_scope(const frx_parse *p)
{
    return p->depth ? p->stack[p->depth - 1].scope : NULL;
}

/* the pending text goes to the sink as one event */
static int
frx_parse_flush_text(frx_parse *p)
{
    int ok;
    if (!p->have_text) return 1;
    p->have_text = 0;
    if (p->text.failed) return frx_parse_nomem(p, p->text_offset);
    ok = p->sink->text(p, p->ud, p->text.p ? p->text.p : "", p->text.len,
                       p->spans, p->n_spans, p->text_offset, &p->text_entity,
                       p->text_flags);
    p->n_spans    = 0;
    p->text_flags = 0;
    return ok;
}

static int
frx_parse_text(frx_parse *p, const frx_tok *t)
{
    if (!p->depth) {
        if (t->cdata)                                  /* not Misc, whatever it holds */
            return FRX_PARSE_FAIL(p, FRX_E_SYNTAX, t->offset, "a CDATA section is not allowed outside the root element");
        if (frx_str_is_s(&t->value)) return 1;         /* whitespace outside the root */
        return FRX_PARSE_FAIL(p, FRX_E_SYNTAX, t->offset,
                              p->seen_root ? "content after the root element"
                                           : "content before the root element");
    }
    if (p->have_text && p->split_entities && !frx_str_eq2(&p->text_entity, &t->entity)) {
        if (!frx_parse_flush_text(p)) return 0;        /* a reader wants the entity boundary */
    }
    if (!p->have_text) {
        p->have_text     = 1;
        p->text_offset   = t->offset;
        p->text_entity   = t->entity;
        p->text.len      = 0;
        p->n_spans       = 0;
        p->text_flags    = 0;
    }
    /* E15, and only this far: a reference expanded while content was being
     * read taints the run. An entity's replacement text does not, because
     * the entity is a storage unit and its text stands directly where the
     * reference was - which is why the suite calls E15e and E15f valid and
     * E15g and E15h invalid, the difference between them being whether the
     * character reference was expanded into the entity's literal value at
     * declaration (section 4.5) or read as a reference here. */
    p->text_flags |= t->text_flags;
    if (t->cdata && p->profile == FRX_PROFILE_FULL) {
        if (p->n_spans == p->cap_spans) {
            int ncap = p->cap_spans ? p->cap_spans * 2 : 4;
            frx_span *ns = (frx_span *)realloc(p->spans, (size_t)ncap * sizeof *ns);
            if (!ns) return frx_parse_nomem(p, t->offset);
            p->spans = ns; p->cap_spans = ncap;
        }
        p->spans[p->n_spans].offset = p->text.len;
        p->spans[p->n_spans].len    = t->value.len;
        p->n_spans++;
    }
    frx_buf_append_n(&p->text, t->value.p, t->value.len);
    return 1;
}

/* a START or EMPTY token: declarations, the scope, the element, its
 * attributes with namespaces resolved, the duplicate checks; then the
 * sink */
static int
frx_parse_element(frx_parse *p, const frx_tok *t)
{
    frx_ev_start ev;
    frx_nsdecl *decls = NULL;
    frx_attr   *attrs = NULL;
    frx_scope  *scope = NULL;
    const frx_scope *parent_scope = frx_parse_scope(p);
    int         n_decls = 0, n_attrs = 0, i, j;

    if (!frx_parse_flush_text(p)) return 0;

    if (!p->depth && p->seen_root)
        return FRX_PARSE_FAIL(p, FRX_E_ROOT, t->offset, "more than one root element");
    /* VC: Root Element Type is frx_validate.h's, with every other
     * validity constraint, so that `collect` can gather it too */
    if (p->depth + 1 > p->max_depth)
        return FRX_PARSE_FAIL(p, FRX_E_TOO_DEEP, t->offset, "nesting deeper than max_depth");

    memset(&ev, 0, sizeof ev);
    ev.qname  = t->name;
    ev.offset = t->offset;
    ev.empty  = t->kind == FRX_TOK_EMPTY;

    /* declarations first: they bind the element's own prefix */
    for (i = 0; i < t->n_attrs; i++) {
        frx_str prefix;
        if (frx_ns_is_decl(&t->attrs[i].name, &prefix)) n_decls++;
    }
    if (n_decls) {
        decls = (frx_nsdecl *)frx_arena_alloc(p->tok_arena, (size_t)n_decls * sizeof *decls);
        scope = (frx_scope *)frx_arena_alloc(p->tok_arena, sizeof *scope);
        if (!decls || !scope) return frx_parse_nomem(p, t->offset);
        n_decls = 0;
        for (i = 0; i < t->n_attrs; i++) {
            const frx_lex_attr *a = &t->attrs[i];
            frx_str prefix;
            const frx_str *v = &a->value;
            if (!frx_ns_is_decl(&a->name, &prefix)) continue;
            if (frx_str_eq(&prefix, "xmlns", 5))
                return FRX_PARSE_FAIL(p, FRX_E_NAMESPACE, a->offset, "the xmlns prefix cannot be declared");
            if (frx_str_eq(v, FRX_XMLNS_NS, sizeof FRX_XMLNS_NS - 1))
                return FRX_PARSE_FAIL(p, FRX_E_NAMESPACE, a->offset, "the xmlns namespace name cannot be bound");
            if (frx_str_eq(&prefix, "xml", 3)) {
                if (!frx_str_eq(v, FRX_XML_NS, sizeof FRX_XML_NS - 1))
                    return FRX_PARSE_FAIL(p, FRX_E_NAMESPACE, a->offset, "the xml prefix is bound to its own namespace and no other");
                ev.xmlns_xml = 1;                          /* validation still has to see it */
                continue;                                  /* accepted, and dropped */
            }
            if (frx_str_eq(v, FRX_XML_NS, sizeof FRX_XML_NS - 1))
                return FRX_PARSE_FAIL(p, FRX_E_NAMESPACE, a->offset, "only the xml prefix may be bound to the xml namespace");
            /* Namespaces 1.1 section 5 allows xmlns:p="" and Namespaces
             * 1.0 does not. Which one applies is decided by the document's
             * XML version, because Namespaces 1.1 is the companion of XML
             * 1.1 and says so; a 1.0 document undeclaring a prefix is
             * still refused, and so is every strict-profile document,
             * which never sets version11. */
            if (prefix.len && !v->len && !p->lex.version11)
                return FRX_PARSE_FAIL(p, FRX_E_NAMESPACE, a->offset,
                    "a prefix cannot be undeclared; that is Namespaces 1.1, which needs an XML 1.1 document");
            if (!frx_ns_is_absolute(v->p, v->len))
                return FRX_PARSE_FAIL(p, FRX_E_NAMESPACE, a->offset, "a relative namespace URI is refused; canonicalisation is undefined over it");
            for (j = 0; j < n_decls; j++)
                if (frx_str_eq2(&decls[j].prefix, &prefix))
                    return FRX_PARSE_FAIL(p, FRX_E_DUP_ATTR, a->offset, "prefix declared twice on one element");
            decls[n_decls].prefix = prefix;
            decls[n_decls].uri    = frx_intern_uri(&p->intern, p->arena, v->p, v->len);
            if (v->len && !decls[n_decls].uri.p) return frx_parse_nomem(p, a->offset);
            n_decls++;
        }
    }
    if (n_decls) {
        scope->up      = parent_scope;
        scope->decls   = decls;
        scope->n_decls = n_decls;
        ev.decls   = decls;
        ev.n_decls = n_decls;
        ev.scope   = scope;
    } else {
        ev.scope = parent_scope;                       /* no declarations, or only xmlns:xml */
    }

    /* the element's own name */
    {
        const frx_str *uri;
        frx_ns_split(&ev.qname, &ev.prefix, &ev.local);
        uri = frx_ns_lookup(ev.scope, ev.prefix.p, ev.prefix.len);
        if (!uri)
            return FRX_PARSE_FAIL(p, FRX_E_NAMESPACE, t->offset, "element prefix is not bound to a namespace");
        ev.ns = *uri;
    }

    /* the attributes: everything that was not a declaration */
    for (i = 0; i < t->n_attrs; i++) {
        frx_str prefix;
        if (!frx_ns_is_decl(&t->attrs[i].name, &prefix)) n_attrs++;
    }
    if (n_attrs) {
        attrs = (frx_attr *)frx_arena_alloc(p->tok_arena, (size_t)n_attrs * sizeof *attrs);
        if (!attrs) return frx_parse_nomem(p, t->offset);
        n_attrs = 0;
        for (i = 0; i < t->n_attrs; i++) {
            const frx_lex_attr *la = &t->attrs[i];
            frx_attr *a = &attrs[n_attrs];
            frx_str prefix;
            if (frx_ns_is_decl(&la->name, &prefix)) continue;
            a->qname     = la->name;
            a->value     = la->value;
            a->offset    = la->offset;
            a->defaulted = la->defaulted;
            frx_ns_split(&a->qname, &a->prefix, &a->local);
            if (a->prefix.len) {
                const frx_str *uri = frx_ns_lookup(ev.scope, a->prefix.p, a->prefix.len);
                if (!uri)
                    return FRX_PARSE_FAIL(p, FRX_E_NAMESPACE, a->offset, "attribute prefix is not bound to a namespace");
                a->ns = *uri;
            } else {
                a->ns = FRX_EMPTY_STR;                     /* never the default */
            }
            for (j = 0; j < n_attrs; j++)
                if (frx_str_eq2(&attrs[j].local, &a->local) && frx_str_eq2(&attrs[j].ns, &a->ns))
                    return FRX_PARSE_FAIL(p, FRX_E_DUP_ATTR, a->offset,
                                          "two attributes with one namespace and local name");
            n_attrs++;
        }
        ev.attrs   = attrs;
        ev.n_attrs = n_attrs;
    }

    if (!p->depth) p->seen_root = 1;
    if (!p->sink->start(p, p->ud, &ev)) return 0;

    if (!ev.empty) {
        if (p->depth == p->cap_stack) {
            int ncap = p->cap_stack ? p->cap_stack * 2 : 32;
            frx_open *ns = (frx_open *)realloc(p->stack, (size_t)ncap * sizeof *ns);
            if (!ns) return frx_parse_nomem(p, t->offset);
            p->stack     = ns;
            p->cap_stack = ncap;
        }
        p->stack[p->depth].qname  = ev.qname;
        p->stack[p->depth].scope  = ev.scope;
        p->stack[p->depth].offset = ev.offset;
        p->depth++;
    }
    return 1;
}

/* the DOCTYPE token: its declarations are already in the lexer's DTD and
 * applied from there; the driver's part is where it may stand */
static int
frx_parse_doctype(frx_parse *p, const frx_tok *t)
{
    if (p->depth || p->seen_root)
        return FRX_PARSE_FAIL(p, FRX_E_DTD, t->offset, "the DOCTYPE must precede the root element");
    p->doctype = p->lex.doctype;
    return p->sink->doctype(p, p->ud, p->lex.doctype, p->lex.dtd);
}

static int
frx_parse_end(frx_parse *p, const frx_tok *t)
{
    frx_str qname;
    if (!p->depth)
        return FRX_PARSE_FAIL(p, FRX_E_SYNTAX, t->offset, "end tag with no open element");
    if (!frx_str_eq2(&p->stack[p->depth - 1].qname, &t->name))
        return FRX_PARSE_FAIL(p, FRX_E_SYNTAX, t->offset, "end tag does not match the open element");
    if (!frx_parse_flush_text(p)) return 0;
    qname = p->stack[p->depth - 1].qname;
    p->depth--;
    return p->sink->end(p, p->ud, &qname, t->offset);
}

/* one token to the sink: FRX_STEP_OK, or MORE (the input ended inside a
 * token and may grow), EOF (the input is finished; call frx_parse_finish)
 * or FAIL (p->err) */
static int
frx_parse_step(frx_parse *p)
{
    frx_tok t;
    int ok;
    if (p->failed) return FRX_STEP_FAIL;
    if (!frx_lex_next(&p->lex, &t)) {
        if (p->lex.failed) { p->err = p->lex.err; p->failed = 1; return FRX_STEP_FAIL; }
        if (t.kind == FRX_TOK_MORE) return FRX_STEP_MORE;
        return FRX_STEP_EOF;
    }
    switch (t.kind) {
    case FRX_TOK_START:
    case FRX_TOK_EMPTY:   ok = frx_parse_element(p, &t); break;
    case FRX_TOK_END:     ok = frx_parse_end(p, &t);     break;
    case FRX_TOK_TEXT:    ok = frx_parse_text(p, &t);    break;
    case FRX_TOK_COMMENT: ok = frx_parse_flush_text(p) && p->sink->comment(p, p->ud, &t.value, t.offset); break;
    case FRX_TOK_PI:      ok = frx_parse_flush_text(p) && p->sink->pi(p, p->ud, &t.name, &t.value, t.offset); break;
    case FRX_TOK_DOCTYPE: ok = frx_parse_doctype(p, &t); break;
    default:              ok = FRX_PARSE_FAIL(p, FRX_E_SYNTAX, t.offset, "unexpected token"); break;
    }
    return ok ? FRX_STEP_OK : FRX_STEP_FAIL;
}

/* after EOF: what must be true of a whole document, then the sink's finish */
static int
frx_parse_finish(frx_parse *p, size_t end_offset)
{
    if (p->failed) return 0;
    if (p->depth)
        return FRX_PARSE_FAIL(p, FRX_E_SYNTAX, p->stack[p->depth - 1].offset, "element is never closed");
    if (!p->seen_root)
        return FRX_PARSE_FAIL(p, FRX_E_ROOT, end_offset, "no root element");
    if (p->sink->finish && !p->sink->finish(p, p->ud)) return 0;
    return 1;
}

/* the whole parse under the extended options: a document, or NULL with
 * *err filled. frx_parse_doc, below, is the strict form the v1 ABI keeps. */
static frx_doc *
frx_parse_doc_ex(const char *bytes, size_t len, const frx_opts_ex *oe_in, frx_err *err)
{
    frx_parse     p;
    frx_tree_sink ts;
    frx_doc      *d;
    frx_opts_ex   oe;
    const frx_opts *o;
    frx_enc       enc;
    const unsigned char *lex_in = NULL;
    size_t        lex_len = 0;
    int           ok, step;
    int           i;

    frx_opts_ex_norm(oe_in, &oe);
    o = &oe.base;
    memset(&enc, 0, sizeof enc);

    frx_err_set(err, FRX_OK, 0, NULL);
    d = frx_doc_new();
    if (!d) { frx_err_set(err, FRX_E_NOMEM, 0, "out of memory"); return NULL; }

    frx_tree_sink_init(&ts, d, 0);
    frx_parse_init(&p, &oe, &d->arena, &d->arena, &FRX_TREE_SINK, &ts);
    d->max_depth = p.max_depth;
    d->profile   = p.profile;

    /* the id attribute names, copied so the caller's strings need not live */
    if (o->n_id_attrs > 0 && o->id_attrs) {
        frx_str *names = (frx_str *)frx_arena_alloc(&d->arena, (size_t)o->n_id_attrs * sizeof *names);
        if (!names) { frx_err_set(err, FRX_E_NOMEM, 0, "out of memory"); frx_parse_free(&p); frx_doc_free(d); return NULL; }
        for (i = 0; i < o->n_id_attrs; i++) {
            names[i] = frx_arena_strndup(&d->arena, o->id_attrs[i], strlen(o->id_attrs[i]));
            if (!names[i].p) { frx_err_set(err, FRX_E_NOMEM, 0, "out of memory"); frx_parse_free(&p); frx_doc_free(d); return NULL; }
        }
        d->id_attrs   = names;
        d->n_id_attrs = o->n_id_attrs;
        d->id_source  = FRX_ID_ATTRS;
    }

    /* the document's own URI, which xml:base is resolved against and an
     * xi:include's href is joined onto */
    if (oe.base_uri) {
        d->base_uri = frx_arena_strndup(&d->arena, oe.base_uri, strlen(oe.base_uri));
        if (!d->base_uri.p) { frx_err_set(err, FRX_E_NOMEM, 0, "out of memory"); frx_parse_free(&p); frx_doc_free(d); return NULL; }
    }

    d->document = frx_node_new(d, FRX_DOCUMENT, 0);
    if (!d->document) { frx_err_set(err, FRX_E_NOMEM, 0, "out of memory"); frx_parse_free(&p); frx_doc_free(d); return NULL; }

    if (p.profile == FRX_PROFILE_FULL) {
        /* the transcoder in front of the lexer: max_bytes on the input, the
         * lexer over the UTF-8 it produces, offsets mapped back on failure */
        frx_opts lo = *o;
        if (o->max_bytes && len > o->max_bytes) {
            frx_err_set(err, FRX_E_TOO_LARGE, o->max_bytes, "input exceeds max_bytes");
            frx_parse_free(&p);
            frx_doc_free(d);
            return NULL;
        }
        lo.max_bytes = 0;
        ok = frx_enc_detect(&enc, (const unsigned char *)bytes, len, oe.encoding, err)
          && frx_enc_run(&enc, (const unsigned char *)bytes, len, err);
        if (!ok) { frx_parse_free(&p); frx_doc_free(d); return NULL; }
        lex_in  = enc.out ? (const unsigned char *)enc.out : (const unsigned char *)bytes + enc.bom;
        lex_len = enc.out ? enc.out_len : len - (size_t)enc.bom;
        frx_lex_setup(&p.lex, &lo, p.profile, &d->arena, enc.kind, enc.bom != 0, enc.override);
    } else {
        frx_lex_setup(&p.lex, o, p.profile, &d->arena, FRX_ENC_UTF8, 0, 0);
        lex_in  = (const unsigned char *)bytes;
        lex_len = len;
    }
    p.lex.in      = lex_in;
    p.lex.len     = lex_len;
    p.lex.doc_len = lex_len;
    p.lex.eof     = 1;
    frx_parse_wire_lex(&p, &oe);

    ok = frx_lex_prolog(&p.lex);
    if (ok) {
        p.lex.prolog_done = 1;
        if (p.lex.version.len) d->version = p.lex.version;   /* as declared; "1.0" otherwise */
        d->standalone = p.lex.standalone;
    }
    while (ok) {
        step = frx_parse_step(&p);
        if (step == FRX_STEP_OK) continue;
        if (step == FRX_STEP_EOF) { ok = frx_parse_finish(&p, len); break; }
        ok = 0;                                        /* FAIL; MORE cannot happen with eof set */
    }
    if (ok && p.lex.failed) { p.err = p.lex.err; p.failed = 1; ok = 0; }

    /* The references WFC: Entity Declared exempted, into the document's
     * arena so the validate pass can report each as VC: Entity Declared.
     * The lexer's array dies with the lexer. */
    if (ok && p.lex.n_undecl) {
        size_t *u = (size_t *)frx_arena_alloc(&d->arena,
                                              (size_t)p.lex.n_undecl * sizeof *u);
        if (!u) { ok = frx_parse_nomem(&p, 0); }
        else {
            memcpy(u, p.lex.undecl, (size_t)p.lex.n_undecl * sizeof *u);
            d->undeclared_refs   = u;
            d->n_undeclared_refs = p.lex.n_undecl;
        }
    }

    /* the validity constraints, over the finished tree: `validate => 1`
     * fails the parse at the first one, `collect` hangs them all off the
     * document and returns it */
    if (ok && oe.validate && !frx_validate_doc(d, oe.validate == 2, &p.err)) {
        p.failed = 1;
        ok = 0;
    }

    /* XInclude, after the tree is whole and valid: every xi:include
     * replaced by what it names, through the same resolver */
    if (ok && oe.xinclude && p.profile == FRX_PROFILE_FULL
        && !frx_xinclude_doc(d, &oe, &p.err)) {
        p.failed = 1;
        ok = 0;
    }

    frx_parse_free(&p);
    frx_tree_sink_free(&ts);

    if (!ok) {
        *err = p.failed ? p.err : p.lex.err;
        if (err->code == FRX_OK) frx_err_set(err, FRX_E_SYNTAX, len, "parse failed");
        if (p.profile == FRX_PROFILE_FULL && (enc.out || enc.bom)) {
            /* the offset is in the transcoded bytes; say it in the caller's */
            err->offset = frx_enc_input_offset(&enc, (const unsigned char *)bytes, len, err->offset);
            if (enc.out) err->enc = frx_enc_name(enc.kind);
        }
        frx_enc_free(&enc);
        frx_doc_free(d);
        return NULL;
    }
    frx_enc_free(&enc);            /* the tree holds copies of every string */
    return d;
}

/* the strict parse: what the v1 ABI's parse entry means, forever */
static frx_doc *
frx_parse_doc(const char *bytes, size_t len, const frx_opts *o, frx_err *err)
{
    frx_opts_ex oe;
    memset(&oe, 0, sizeof oe);
    oe.size    = sizeof oe;
    if (o) oe.base = *o;
    oe.profile = FRX_PROFILE_STRICT;
    return frx_parse_doc_ex(bytes, len, &oe, err);
}

/* ---- the walkers ------------------------------------------------------ */

/* does the element match (ns, local)? ns NULL: any; "": none */
static int
frx_node_matches(const frx_node *n, const char *ns, const char *local)
{
    if (n->kind != FRX_ELEMENT) return 0;
    if (!frx_str_eq(&n->local, local, strlen(local))) return 0;
    if (ns && !frx_str_eq(&n->ns, ns, strlen(ns))) return 0;
    return 1;
}

/* direct children matching, from after (NULL to start) */
static const frx_node *
frx_find(const frx_node *n, const char *ns, const char *local, const frx_node *after)
{
    const frx_node *c = after ? after->next : n->first_child;
    for (; c; c = c->next)
        if (frx_node_matches(c, ns, local)) return c;
    return NULL;
}

/* the node after n in document order, staying inside root; NULL at the end */
static const frx_node *
frx_walk_next(const frx_node *n, const frx_node *root)
{
    if (n->first_child) return n->first_child;
    while (n != root && !n->next) n = n->parent;
    return n == root ? NULL : n->next;
}

/* every descendant of n in document order, to cb; 0 from cb stops */
static int
frx_descendants(const frx_node *n, int (*cb)(const frx_node *, void *), void *ud)
{
    const frx_node *c = n->first_child;
    while (c) {
        if (!cb(c, ud)) return 0;
        c = frx_walk_next(c, n);
    }
    return 1;
}

static int
frx_text_cb(const frx_node *n, void *ud)
{
    if (n->kind == FRX_TEXT) frx_buf_append_n((frx_buf *)ud, n->value.p, n->value.len);
    return 1;
}

/* text: element or document = descendant text in order; text = itself;
 * comment = body; PI = data */
static void
frx_text(const frx_node *n, frx_buf *out)
{
    switch (n->kind) {
    case FRX_TEXT:
    case FRX_COMMENT:
    case FRX_PI:
        frx_buf_append_n(out, n->value.p, n->value.len);
        break;
    default:
        frx_descendants(n, frx_text_cb, out);
        break;
    }
}

/* the attribute value for (ns, local), or NULL; ns NULL: any, "": none */
static const frx_str *
frx_attr_value(const frx_node *n, const char *ns, const char *local)
{
    int i;
    for (i = 0; i < n->n_attrs; i++) {
        const frx_attr *a = &n->attrs[i];
        if (!frx_str_eq(&a->local, local, strlen(local))) continue;
        if (ns && !frx_str_eq(&a->ns, ns, strlen(ns))) continue;
        return &a->value;
    }
    return NULL;
}

/* exactly one element, or NULL */
static const frx_node *
frx_by_id(const frx_doc *d, const char *attr, const char *value, size_t vlen)
{
    frx_idx key;
    const frx_idx *hit;
    if (!d->n_ids) return NULL;
    key.attr.p    = attr;
    key.attr.len  = strlen(attr);
    key.value.p   = value;
    key.value.len = vlen;
    key.node      = NULL;
    key.offset    = 0;
    /* keys are unique after finish, so the key order finds the one */
    hit = (const frx_idx *)bsearch(&key, d->ids, (size_t)d->n_ids, sizeof *d->ids, frx_idx_key_cmp);
    return hit ? hit->node : NULL;
}

#endif /* FRX_PARSE_H */
