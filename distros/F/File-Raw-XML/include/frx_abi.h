#ifndef FRX_ABI_H
#define FRX_ABI_H

/* Public C ABI for File::Raw::XML (the provider) and its XS consumers (the
 * first is Punk::SAML, which verifies XML signatures over the canonical
 * form). It is resolved at RUNTIME via File::Raw::XML::_abi_ptr - a
 * versioned function-pointer table - so there is no link-time symbol
 * coupling and each dist builds and upgrades independently. A consumer
 * reaches this header through ExtUtils::Depends (no copying) and checks
 * abi_version at boot with >=, never ==: the table is append-only from
 * the first release onwards, so a provider newer than the consumer is
 * always safe, and an equality check would turn every append into a
 * breaking change. Nothing has been released yet, so the whole of this
 * table is version 1 and every entry in it is still free to move; the
 * append-only rule begins to bind the day it ships.
 *
 * Perl headers (EXTERN.h / perl.h / XSUB.h) must be included before this
 * file so SV, STRLEN and pTHX are defined. Only the entries that touch an
 * SV take pTHX_; the tree accessors are plain C, callable from a harness
 * with no interpreter.
 *
 * Three departures from the design in Punk/plan/punk-saml/01-file-raw-xml.md:
 *
 *   - frx_c14n.mode replaces `int exclusive`: three algorithms ship
 *     (Exclusive 1.0, Canonical XML 1.0, Canonical XML 1.1).
 *   - FRX_DOCUMENT is a node kind: a signature whose Reference has URI=""
 *     is over the whole document, and canonicalising it means an apex that
 *     is the document node, with top-level comments and processing
 *     instructions rendered under the document-level newline rules. The
 *     document node's children are the top-level misc and the root
 *     element; root() still returns the root element; parent() of the root
 *     is the document node.
 *   - document() is appended after root().
 *
 * Ownership: every string the table returns is borrowed from the document,
 * NUL-terminated, and valid until doc_free. Every node is borrowed from its
 * document: a consumer that holds a node holds the document. Every SV the
 * table returns has a reference count of one owned by the caller.
 *
 * Two lifetimes are shorter than that, and both are the reader's. A
 * string from `reader_str` or `reader_attr` lives in the arena the reader
 * releases at the end of each record, so it is valid until the next
 * `reader_next` and not after; copy it if you need it longer. The
 * `frx_err *` from `reader_error` is valid while the reader is.
 *
 * A message never is. `frx_err.what` is a static string and so is the
 * compile refusal from `xpath_compile`, precisely so that a consumer can
 * free what failed and then report it: a message built from arena memory
 * and read after the free is a use-after-free whose only symptom is a
 * wrong message, which is the hardest kind to notice. */

#define FRX_ABI_VERSION 1

typedef struct frx_doc  frx_doc;      /* opaque; owns every node and string */
typedef struct frx_node frx_node;     /* opaque; borrowed from its doc */

/* ---- refusals -----------------------------------------------------------
 *
 * The core never croaks: it fills an frx_err and returns NULL or 0. The
 * `parse` entry renders that into a mortal SV, because it is the entry a
 * consumer reaches for first and a message is what it wants; every other
 * entry that can fail takes an frx_err * and the consumer renders it with
 * `err_format`, so no entry needs a wrapper to translate one. */

typedef enum {
    FRX_OK = 0,
    FRX_E_NOMEM,          /* an allocation failed */
    FRX_E_TOO_LARGE,      /* over max_bytes */
    FRX_E_TOO_DEEP,       /* over max_depth */
    FRX_E_ENCODING,       /* not UTF-8: a BOM, a declaration, a first pair */
    FRX_E_DOCTYPE,        /* <!DOCTYPE, or any <! that is not -- or [CDATA[ */
    FRX_E_UTF8,           /* a byte sequence that is not UTF-8, or not Char */
    FRX_E_SYNTAX,         /* not well-formed */
    FRX_E_NAME,           /* not a Name, or a QName with the wrong colons */
    FRX_E_REFERENCE,      /* an undeclared entity, or a reference to a non-Char */
    FRX_E_NAMESPACE,      /* unbound prefix, xmlns misuse, a relative URI */
    FRX_E_DUP_ATTR,       /* the same attribute twice, literally or expanded */
    FRX_E_DUP_ID,         /* two elements with one ID value */
    FRX_E_ROOT,           /* no root element, or more than one */
    FRX_E_DTD,            /* full: a markup declaration that is not well-formed */
    FRX_E_ENTITY,         /* full: an entity well-formedness constraint */
    FRX_E_EXPANSION,      /* full: an entity expansion budget crossed */
    FRX_E_VALIDITY        /* full: a validity constraint, under validate */
} frx_code;

typedef struct frx_err {
    frx_code    code;
    size_t      offset;
    const char *what;     /* static; never arena memory */
    const char *enc;      /* the input's encoding when it was transcoded and
                           * offset indexes the caller's bytes; NULL otherwise */
} frx_err;

/* node kinds; CDATA is text in the data model and merges into it at parse */
enum { FRX_ELEMENT = 1, FRX_TEXT, FRX_COMMENT, FRX_PI, FRX_DOCUMENT };

/* canonicalisation algorithms */
enum { FRX_C14N_EXC = 0, FRX_C14N_INC10, FRX_C14N_INC11 };

/* Parse options. Fill with opts_init() (or pass NULL to parse) for the
 * defaults, then set what you need. */
typedef struct frx_opts {
    size_t max_bytes;                 /* 0: no cap */
    int    max_depth;                 /* 0: the default, 256 */
    const char *const *id_attrs;      /* attribute local names that are IDs,
                                       * in any namespace; NULL: no index */
    int    n_id_attrs;
} frx_opts;

/* Canonicalisation options. */
typedef struct frx_c14n {
    int mode;                         /* FRX_C14N_* */
    int comments;                     /* 1: render comments */
    const char *const *prefix_list;   /* InclusiveNamespaces PrefixList;
                                       * "#default" names the default ns */
    int n_prefix;
    const frx_node *const *without;   /* subtrees omitted from the node set:
                                       * the enveloped-signature transform */
    int n_without;
} frx_c14n;

/* ---- the full profile's options ------------------------------------------
 *
 * frx_opts is in the table by pointer with no size field, so once this
 * ships it can never grow: a later provider would read past an older
 * consumer's struct. frx_opts_ex is the struct the full profile grows
 * into instead. It begins with `size`, the sizeof the consumer was
 * compiled with, and every reader copies min(size, its own sizeof) over a
 * defaults block, so a later version can append fields and an older
 * consumer's shorter struct is still read whole. A field that turns out
 * not to be needed keeps its slot and its comment; the offset of every
 * field after it is what `size` protects.
 *
 * `parse` takes frx_opts and means the strict profile, and that is all it
 * will ever mean: a consumer that calls it can never receive an
 * entity-expanded or transcoded document, which is the guarantee
 * Punk::SAML wants. `parse_ex` takes this struct and is the full
 * profile's entry. */

enum { FRX_PROFILE_STRICT = 0, FRX_PROFILE_FULL = 1 };

/* what a resolver hands back; release is called once when the parse is
 * done with the bytes, or never when it is NULL */
typedef struct frx_fetched {
    const char *bytes;
    size_t      len;
    void      (*release)(void *ud, struct frx_fetched *f);
    void       *ud;
} frx_fetched;

/* what is being resolved */
enum { FRX_REF_ENTITY = 1, FRX_REF_SUBSET, FRX_REF_XINCLUDE };

/* The pull reader's event kinds: the node kinds where the meaning is the
 * same, and two more. FRX_START is FRX_ELEMENT because a start event is
 * an element arriving. */
enum { FRX_START = FRX_ELEMENT, FRX_END = 6, FRX_DOCTYPE = 7 };

/* the objects the full profile hands out, each opaque and each with its
 * own new and free in the table */
typedef struct frx_reader frx_reader;
typedef struct frx_xpath  frx_xpath;
typedef struct frx_xp_val frx_xp_result;

/* what reader_str and reader_int select from the current event. A string
 * that the event does not have is "" and never NULL. */
enum {
    FRX_R_QNAME = 0, FRX_R_LOCAL, FRX_R_NS, FRX_R_PREFIX, FRX_R_VALUE, FRX_R_ENTITY
};
enum {
    FRX_R_KIND = 0,     /* the current event's kind, 0 before the first */
    FRX_R_DEPTH,        /* elements open at it, a start counting its own */
    FRX_R_EMPTY,        /* a start written <a/>: no end event follows */
    FRX_R_DONE,         /* the document has ended */
    FRX_R_CAPTURING     /* between a subtree that wanted bytes and the one that gave the document */
};

/* an XPath result's type, and what a node-set entry is */
enum { FRX_XP_NODESET = 0, FRX_XP_BOOLEAN, FRX_XP_NUMBER, FRX_XP_STRING };
enum { FRX_XP_KNODE = 0, FRX_XP_KNS, FRX_XP_KATTR };

/* how the general serialiser writes; fill with write_opts_init */
typedef struct frx_write_opts {
    int         declaration;    /* 1: <?xml version="..." encoding="..."?> */
    int         encoding;       /* FRX_ENC_*; UTF-8 by default */
    int         encoding_attr;  /* 1: the declaration names the encoding */
    int         indent;         /* 0: none; n: n spaces per level */
    const char *const *preserve;
    int         n_preserve;
    int         empty_short;    /* 1: <a/> */
    int         quote;          /* '"' or '\'' */
    int         escape_all;     /* 1: escape " and ' in text too */
    int         doctype;        /* 1: re-emit the recorded DOCTYPE */
    int         drop_ws;        /* 1: drop whitespace-only text under indented elements */
} frx_write_opts;

/* the prefix map an XPath expression is compiled under; the only source
 * of namespace URIs, so an expression means the same thing wherever it
 * is evaluated */
typedef struct frx_ns_binding {
    const char *prefix;
    const char *uri;
} frx_ns_binding;

typedef struct frx_ns_map {
    const frx_ns_binding *v;
    int                   n;
} frx_ns_map;

/* The caller's resolver for an external entity, the external subset or an
 * XInclude (decision D: the core never opens a file or a socket). NULL on
 * success with *out filled; a static error string otherwise, which the
 * parse reports with the reference's offset. A NULL resolver means every
 * external reference is refused. */
typedef const char *(*frx_resolve_fn)(void *ud, const char *public_id,
                                      const char *system_id, const char *base,
                                      int kind, frx_fetched *out);

typedef struct frx_opts_ex {
    size_t   size;                  /* sizeof(frx_opts_ex) the consumer was built with */
    frx_opts base;                  /* max_bytes, max_depth, id_attrs */
    int      profile;               /* FRX_PROFILE_STRICT (0) | FRX_PROFILE_FULL */
    const char *encoding;           /* override; NULL = detect */
    frx_resolve_fn resolve;         /* NULL = every external reference refused */
    void    *resolve_ud;
    int      validate;              /* 0, 1 = die at the first error, 2 = collect */
    int      xinclude;              /* 0 | 1 */
    size_t   max_expansion_bytes;   /* 0 = 16 MiB */
    int      max_entity_depth;      /* 0 = 16 */
    int      max_expansion_ratio;   /* 0 = 100 */
    int      max_fetches;           /* 0 = 32 */
    int      max_xinclude_depth;    /* 0 = 8 */
    size_t   max_token_bytes;       /* 0 = 16 MiB */
    const char *base_uri;           /* the document's base for relative system
                                     * identifiers; NULL = none, they are used as written */
} frx_opts_ex;

typedef struct frx_abi {
    int abi_version;                  /* consumers compare >= what they need */

    void (*opts_init)(frx_opts *o);

    /* Parse bytes into a document. Returns NULL and a mortal message SV in
     * *err on refusal (a DOCTYPE, a non-UTF-8 encoding, depth or size over
     * the cap, a duplicate ID, anything not well-formed); never croaks.
     * `o` may be NULL for the defaults. */
    frx_doc *(*parse)(pTHX_ const char *bytes, STRLEN len,
                      const frx_opts *o, SV **err);
    void     (*doc_free)(pTHX_ frx_doc *d);

    /* The tree. Strings borrowed, NUL-terminated, valid until doc_free;
     * *len may be NULL. ns and prefix return "" when there is none. local
     * on a PI is its target. */
    const frx_node *(*root)(const frx_doc *d);
    const frx_node *(*document)(const frx_doc *d);
    int             (*kind)(const frx_node *n);
    const char     *(*ns)(const frx_node *n, STRLEN *len);
    const char     *(*local)(const frx_node *n, STRLEN *len);
    const char     *(*prefix)(const frx_node *n, STRLEN *len);
    const frx_node *(*parent)(const frx_node *n);     /* NULL above the document */
    const frx_node *(*first_child)(const frx_node *n);
    const frx_node *(*next)(const frx_node *n);

    /* Attributes in document order. xmlns and xmlns:* are declarations,
     * never attributes: never counted, never returned. */
    int  (*attr_count)(const frx_node *n);
    void (*attr)(const frx_node *n, int i,
                 const char **ns, STRLEN *nslen,
                 const char **local, STRLEN *loclen,
                 const char **value, STRLEN *vlen);
    /* ns NULL: any namespace; "": no namespace. NULL when absent. */
    const char *(*attr_value)(const frx_node *n, const char *ns,
                              const char *local, STRLEN *len);

    /* Direct children matching (ns, local), ns as for attr_value; iterate
     * by passing the previous match as `after`, NULL to start. */
    const frx_node *(*find)(const frx_node *n, const char *ns,
                            const char *local, const frx_node *after);
    /* Exactly one element carrying attribute `attr` with this value, or
     * NULL. Only attribute names given in id_attrs at parse are indexed,
     * and a duplicate value was refused at parse, so this cannot be
     * steered to a second element. */
    const frx_node *(*by_id)(const frx_doc *d, const char *attr,
                             const char *value, STRLEN vlen);

    /* SVs, caller owns. text: element = descendant text concatenated,
     * text = itself, comment = body, PI = data, document = the root's text.
     * c14n: the canonical bytes of the node set rooted at n under c;
     * UTF-8 with no character flag, because a signature is over bytes. */
    SV *(*text)(pTHX_ const frx_node *n);
    SV *(*c14n)(pTHX_ const frx_node *n, const frx_c14n *c);

    /* ---- the full profile -------------------------------------------
     *
     * The entries above are the strict profile, which is what `parse`
     * gives and all it will ever give. These are the rest, in the order
     * they were built, so the table reads as its own history.
     *
     * Every one of them that can fail takes an frx_err * rather than a
     * message SV; `err_format` renders one. */

    /* the full profile's parse. `o` may be NULL for strict defaults. */
    frx_doc *(*parse_ex)(const char *bytes, STRLEN len, const frx_opts_ex *o, frx_err *err);
    /* the refusal as the one message shape; returns the length written,
     *     which may exceed cap, as snprintf reports it. `in` may be NULL. */
    STRLEN (*err_format)(const frx_err *e, const char *in, STRLEN len, char *out, STRLEN cap);

    /* 10 or 11, whatever the declaration said */
    int (*version)(const frx_doc *d);
    /* the declaration said standalone="yes" */
    int (*standalone)(const frx_doc *d);

    /* the DOCTYPE as it was written; NULL when the document has
     *         none, and "" for an identifier or a subset it did not have */
    const char *(*doctype_name)(const frx_doc *d, STRLEN *len);
    const char *(*doctype_public)(const frx_doc *d, STRLEN *len);
    const char *(*doctype_system)(const frx_doc *d, STRLEN *len);
    const char *(*doctype_subset)(const frx_doc *d, STRLEN *len);

    /* the CDATA sections inside a text node's value, as offsets
     *         into it. The data model has no CDATA: this is what the
     *         writer puts the sections back from. Full profile only. */
    int  (*cdata_span_count)(const frx_node *n);
    void (*cdata_span)(const frx_node *n, int i, STRLEN *off, STRLEN *len);

    /* the violations of a `validate => collect` parse, in
     *          document order; the string is static, the offset is the
     *          document's. */
    int         (*error_count)(const frx_doc *d);
    const char *(*error_at)(const frx_doc *d, int i, STRLEN *offset);

    /* the general serialiser. write returns a +1 SV of bytes in
     *          the requested encoding with no character flag, or NULL
     *          with *err filled. */
    void (*write_opts_init)(frx_write_opts *o);
    SV  *(*write)(pTHX_ const frx_node *apex, const frx_doc *d,
                  const frx_write_opts *o, frx_err *err);

    /* equal as data: kind, namespace and local name, attributes as an
     *      unordered set, text, children in order. Prefixes, CDATA
     *      boundaries, defaulting and offsets do not count. */
    int (*tree_equal)(const frx_node *a, const frx_node *b);

    /* the pull reader. reader_new mallocs and reader_free
     *          releases; reader_next returns an FRX_* event kind, 0 when
     *          it wants more bytes and -1 at the end of the document, and
     *          reader_error is filled after a refusal. The accessors read
     *          the current event and are meaningless before the first. */
    frx_reader *(*reader_new)(const frx_opts_ex *o);
    void        (*reader_free)(frx_reader *r);
    int         (*reader_feed)(frx_reader *r, const char *bytes, STRLEN len, int eof);
    int         (*reader_next)(frx_reader *r);
    const char *(*reader_str)(const frx_reader *r, int which, STRLEN *len);
    int         (*reader_int)(const frx_reader *r, int which);
    STRLEN      (*reader_offset)(const frx_reader *r);
    int         (*reader_attr_count)(const frx_reader *r);
    void        (*reader_attr)(const frx_reader *r, int i,
                               const char **ns, STRLEN *nslen,
                               const char **local, STRLEN *loclen,
                               const char **value, STRLEN *vlen);
    /* at a start event, the element and everything under it as a document
     * of its own, which the caller frees; NULL when more bytes are wanted */
    frx_doc        *(*reader_subtree)(frx_reader *r);
    const frx_err  *(*reader_error)(const frx_reader *r);

    /* the mutable tree. A node is never moved or freed by an
     *          edit, so every pointer stays stable; the memory an edit
     *          costs is returned when the document is freed. Each of
     *          these returns NULL or 0 with *err filled and the tree
     *          unchanged. */
    frx_doc  *(*new_document)(int version11);
    frx_node *(*new_element)(frx_doc *d, const char *ns, STRLEN nslen,
                             const char *prefix, STRLEN plen,
                             const char *local, STRLEN llen, frx_err *err);
    frx_node *(*new_text)(frx_doc *d, const char *s, STRLEN n, frx_err *err);
    frx_node *(*new_comment)(frx_doc *d, const char *s, STRLEN n, frx_err *err);
    frx_node *(*new_pi)(frx_doc *d, const char *target, STRLEN tlen,
                        const char *data, STRLEN dlen, frx_err *err);
    int (*append_child)(frx_doc *d, frx_node *parent, frx_node *child, frx_err *err);
    int (*insert_before)(frx_doc *d, frx_node *ref, frx_node *child, frx_err *err);
    int (*remove_node)(frx_doc *d, frx_node *n, frx_err *err);
    int (*set_attr)(frx_doc *d, frx_node *el, const char *ns, STRLEN nslen,
                    const char *prefix, STRLEN plen, const char *local, STRLEN llen,
                    const char *value, STRLEN vlen, frx_err *err);
    int (*remove_attr)(frx_doc *d, frx_node *el, const char *ns, STRLEN nslen,
                       const char *local, STRLEN llen, frx_err *err);
    int (*set_text)(frx_doc *d, frx_node *n, const char *s, STRLEN len, frx_err *err);
    int (*declare_ns)(frx_doc *d, frx_node *el, const char *prefix, STRLEN plen,
                      const char *uri, STRLEN ulen, frx_err *err);
    int (*set_name)(frx_doc *d, frx_node *el, const char *ns, STRLEN nslen,
                    const char *prefix, STRLEN plen, const char *local, STRLEN llen,
                    frx_err *err);
    /* a detached deep copy, in d, of a node of another document */
    frx_node *(*import_node)(frx_doc *d, const frx_node *src, frx_err *err);

    /* XPath 1.0. An expression is compiled once, holds no
     *          document, and is evaluated against as many as you like.
     *          A compile refusal is a static message and an offset into
     *          the expression. Every variable the expression names must
     *          be bound before evaluating. */
    frx_xpath *(*xpath_compile)(const char *expr, STRLEN len, const frx_ns_map *ns,
                                int max_depth, const char **err, STRLEN *err_at);
    void       (*xpath_free)(frx_xpath *x);
    int         (*xpath_var_count)(const frx_xpath *x);
    const char *(*xpath_var_name)(const frx_xpath *x, int i, STRLEN *len);
    int         (*xpath_bind_str)(frx_xpath *x, int i, const char *p, STRLEN n);
    void        (*xpath_bind_num)(frx_xpath *x, int i, double v);
    void        (*xpath_bind_bool)(frx_xpath *x, int i, int b);
    frx_xp_result *(*xpath_result_new)(void);
    void           (*xpath_result_free)(frx_xp_result *r);
    int (*xpath_eval)(frx_xpath *x, frx_doc *d, const frx_node *ctx,
                      frx_xp_result *out, const char **err);
    int    (*xpath_result_kind)(const frx_xp_result *r);   /* FRX_XP_* */
    double (*xpath_result_number)(const frx_xp_result *r);
    /* the characters of a string result; for a result of another type,
     * compile `string(...)` around the expression, which is what XPath
     * itself would do */
    const char *(*xpath_result_string)(const frx_xp_result *r, STRLEN *len);
    int (*xpath_result_count)(const frx_xp_result *r);
    /* the i'th member in document order. *kind is FRX_XP_KNODE, KATTR or
     * KNS; for the latter two the node is the owning element and *index
     * selects the attribute or the namespace node. */
    const frx_node *(*xpath_result_node)(const frx_xp_result *r, int i,
                                         int *kind, int *index);
} frx_abi;

#endif /* FRX_ABI_H */
