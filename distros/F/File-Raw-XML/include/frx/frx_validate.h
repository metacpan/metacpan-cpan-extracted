#ifndef FRX_VALIDATE_H
#define FRX_VALIDATE_H

/* The validity constraints, over the finished tree.
 *
 * The parse read the declarations and applied the two that change what a
 * document means: attribute defaults are already on the elements that
 * lacked them, and attribute values are already normalised by their
 * declared type. This is the rest, and it is a second pass rather than
 * work threaded through the parse driver, because the tree the driver
 * finished already has every element and every attribute including the
 * defaulted ones, and one walk over it is simpler than automaton state
 * carried down the parse. THE READER DOES NOT VALIDATE: an event stream
 * has no finished tree to walk, and frx_reader.h says so.
 *
 * `validate => 1` stops at the first violation and reports it with its
 * offset, in the same message shape as every other refusal. `validate
 * => 'collect'` runs the whole pass, returns the document, and hangs the
 * list off it in document order for `$doc->errors`. There is no warning
 * channel: the specification's "at user option" errors are collected.
 *
 * THE ID INDEX. Validation knows which attributes are IDs because the
 * DTD says so, which is a different question from the `id_attrs` option,
 * and the two never both apply: a document parsed with `id_attrs` keeps
 * that index and its source, and one validated without it gets an index
 * built from the declared ID attributes, with `id_source` saying which,
 * so XPath's id() does not have to guess. Uniqueness is a validity
 * error here rather than the parse-time refusal `id_attrs` gives, and
 * the reason is the same in both: which of two elements is "the" one is
 * the whole of the signature wrapping attack.
 *
 * NAMESPACE DECLARATIONS ARE NOT ATTRIBUTES in this tree (frx_tree.h),
 * and a DTD does not know that, so validation puts them back: Namespaces
 * in XML is a layer above XML 1.0, and to the grammar `xmlns:foo="..."`
 * is an Attribute like any other. It is therefore held to VC: Attribute
 * Value Type like any other, and where the DTD does declare it, what the
 * DTD says about its value is enforced too, which is what a #FIXED
 * `xmlns` is written to say. The name is matched by comparison against
 * the prefix, so asking the question allocates nothing.
 *
 * THAT IS STRICTER THAN IT LOOKS, and deliberately. A DTD that does not
 * declare `xmlns` makes every namespaced document drawn from it invalid,
 * which is a real friction between DTDs and namespaces and not a bug
 * here: it is why a DTD written for namespaced markup declares the
 * xmlns attributes it expects. The conformance suite pins it - eduni
 * hst-bh-005 and hst-bh-006 are two elements whose only attribute is a
 * namespace declaration, and the suite marks both invalid. It costs
 * nothing unless `validate` is asked for, which is off by default.
 *
 * Nothing recurses (rule 2): the walk is frx_walk_next, and an element's
 * content model is run over its own child list in one loop.
 *
 * Needs frx_tree.h, frx_dtd.h, frx_parse.h, frx_model.h. */

typedef struct frx_verr {
    const char      *what;      /* static; names the constraint */
    size_t           offset;
    struct frx_verr *next;
} frx_verr;

typedef struct frx_idref {
    frx_str value;
    size_t  offset;
} frx_idref;

typedef struct frx_val {
    frx_doc       *doc;
    const frx_dtd *dtd;
    frx_arena     *arena;
    frx_dtd_map    models;      /* element name to frx_cm_dfa * */
    int            collect;     /* 0: stop at the first violation */
    int            standalone;
    int            own_ids;     /* the index is ours to build (no id_attrs) */
    frx_verr      *first, *last;
    int            n;
    int            nomem;
    int            stop;
    frx_idx       *ids;         int n_ids,    cap_ids;
    frx_idref     *idrefs;      int n_idrefs, cap_idrefs;
} frx_val;

/* the type check, used by the declaration pass above the definition to
 * check a declared default and by the document pass below it to check a
 * written value */
static const char *frx_val_syntax_check(int type, const frx_str *enums,
                                        int n_enums, const frx_str *value);

/* One collected violation as a message, in the shape every refusal uses
 * minus the context: the bytes the offset points into are gone by the
 * time a caller reads the list. */
static size_t
frx_verr_format(const frx_verr *e, char *out, size_t cap)
{
    size_t pos = 0;
    frx_err_put(out, cap, &pos, FRX_ERR_PREFIX, sizeof FRX_ERR_PREFIX - 1);
    frx_err_put(out, cap, &pos, e->what, strlen(e->what));
    frx_err_put(out, cap, &pos, " at byte offset ", 16);
    frx_err_put_num(out, cap, &pos, e->offset);
    if (cap) out[pos < cap ? pos : cap - 1] = '\0';
    return pos < cap ? pos : cap - 1;
}

/* ---- names, section 2.3 ------------------------------------------------- */

/* Nmtoken over UTF-8. frx_utf8.h's tables leave the colon out, because
 * the lexer applies the QName rule to it itself; in an Nmtoken it is an
 * ordinary name character, which is what XML 1.0 says it is, and which
 * the erratum below does not narrow.
 *
 * A Name is not used for a tokenised attribute value. Namespaces in XML
 * erratum NE08 narrows the six tokenised types - ID, IDREF, IDREFS,
 * ENTITY, ENTITIES and NOTATION - to NCName in a namespace-aware
 * document, and this parser is always namespace-aware, so `id="a:b"` is
 * a violation and not a name with a colon in it. frx_is_ncname is that
 * production. */
static int
frx_val_is_nmtoken(const frx_str *s)
{
    unsigned long cp;
    size_t at = 0, k;
    if (!s->len) return 0;
    while (at < s->len) {
        k = frx_utf8_decode((const unsigned char *)s->p + at, s->len - at, &cp);
        if (!k || !(frx_is_name_char(cp) || cp == ':')) return 0;
        at += k;
    }
    return 1;
}

/* NE08: an NCName, so a colon is a violation and not a name character */
static int
frx_val_is_name(const frx_str *s) { return frx_is_ncname(s->p, s->len); }

/* The next token of a list value; 0 at the end. THE SEPARATOR IS A SPACE
 * AND NOTHING ELSE: section 3.3.3 normalised this value by its declared
 * type, which turned every literal tab, line feed and carriage return
 * into a space and collapsed the runs, so a tab still in it arrived as a
 * character reference and is part of the token, not between two. That is
 * what makes `bar="abc&#9;xyz"` one token and not a name token. */
static int
frx_val_token(const frx_str *v, size_t *at, frx_str *out)
{
    size_t start;
    while (*at < v->len && v->p[*at] == ' ') (*at)++;
    start = *at;
    while (*at < v->len && v->p[*at] != ' ') (*at)++;
    if (*at == start) return 0;
    out->p   = v->p + start;
    out->len = *at - start;
    return 1;
}

/* is this the name of a namespace declaration rather than an attribute? */
static int
frx_val_is_xmlns(const frx_str *name)
{
    return frx_str_eq(name, "xmlns", 5)
        || (name->len > 6 && memcmp(name->p, "xmlns:", 6) == 0);
}

/* The attribute definition, if any, for the declaration of this prefix.
 * Built by comparison rather than by making the name, so nothing is
 * allocated to ask the question. */
static const frx_attdef *
frx_val_nsdecl_attdef(const frx_eldecl *ed, const frx_str *prefix)
{
    const frx_attdef *ad;
    for (ad = ed->attdefs; ad; ad = ad->next) {
        if (!prefix->len) {
            if (frx_str_eq(&ad->name, "xmlns", 5)) return ad;
        } else if (ad->name.len == 6 + prefix->len
                   && memcmp(ad->name.p, "xmlns:", 6) == 0
                   && memcmp(ad->name.p + 6, prefix->p, prefix->len) == 0) {
            return ad;
        }
    }
    return NULL;
}

static int
frx_val_has_nsdecl(const frx_node *n, const frx_str *name)
{
    int i;
    for (i = 0; i < n->n_decls; i++) {
        const frx_str *p = &n->decls[i].prefix;
        if (!p->len) { if (frx_str_eq(name, "xmlns", 5)) return 1; }
        else if (name->len == 6 + p->len && memcmp(name->p, "xmlns:", 6) == 0
                 && memcmp(name->p + 6, p->p, p->len) == 0) return 1;
    }
    return 0;
}

/* ---- reporting ---------------------------------------------------------- */

/* Record a violation. Returns 0 when the pass should stop, which is
 * always under `validate => 1` and never under collect. */
static int
frx_val_err(frx_val *v, const char *what, size_t offset)
{
    frx_verr *e = (frx_verr *)frx_arena_alloc(v->arena, sizeof *e);
    if (!e) { v->nomem = 1; v->stop = 1; return 0; }
    e->what   = what;
    e->offset = offset;
    e->next   = NULL;
    if (v->last) v->last->next = e;
    else         v->first = e;
    v->last = e;
    v->n++;
    if (!v->collect) v->stop = 1;
    return v->collect;
}

/* The same, but placed by offset rather than appended, for a violation
 * found before the walk that has to appear where it belongs in the list.
 * The list is short and this runs once per exempted reference. */
static int
frx_val_err_ordered(frx_val *v, const char *what, size_t offset)
{
    frx_verr *e, *prev, *cur;
    if (!v->first || v->last->offset <= offset) return frx_val_err(v, what, offset);
    e = (frx_verr *)frx_arena_alloc(v->arena, sizeof *e);
    if (!e) { v->nomem = 1; v->stop = 1; return 0; }
    e->what   = what;
    e->offset = offset;
    for (prev = NULL, cur = v->first; cur && cur->offset <= offset; prev = cur, cur = cur->next)
        ;
    e->next = cur;
    if (prev) prev->next = e;
    else      v->first   = e;
    v->n++;
    if (!v->collect) v->stop = 1;
    return v->collect;
}

/* ---- the ID bookkeeping ------------------------------------------------- */

static int
frx_val_push_id(frx_val *v, const frx_str *attr, const frx_str *value,
                const frx_node *n, size_t offset)
{
    if (v->n_ids == v->cap_ids) {
        int ncap = v->cap_ids ? v->cap_ids * 2 : 32;
        frx_idx *ni = (frx_idx *)realloc(v->ids, (size_t)ncap * sizeof *ni);
        if (!ni) { v->nomem = 1; v->stop = 1; return 0; }
        v->ids     = ni;
        v->cap_ids = ncap;
    }
    v->ids[v->n_ids].attr   = *attr;
    v->ids[v->n_ids].value  = *value;
    v->ids[v->n_ids].node   = n;
    v->ids[v->n_ids].offset = offset;
    v->n_ids++;
    return 1;
}

static int
frx_val_push_idref(frx_val *v, const frx_str *value, size_t offset)
{
    if (v->n_idrefs == v->cap_idrefs) {
        int ncap = v->cap_idrefs ? v->cap_idrefs * 2 : 32;
        frx_idref *ni = (frx_idref *)realloc(v->idrefs, (size_t)ncap * sizeof *ni);
        if (!ni) { v->nomem = 1; v->stop = 1; return 0; }
        v->idrefs     = ni;
        v->cap_idrefs = ncap;
    }
    v->idrefs[v->n_idrefs].value  = *value;
    v->idrefs[v->n_idrefs].offset = offset;
    v->n_idrefs++;
    return 1;
}

/* an ID value already seen, whatever attribute carried it */
static int
frx_val_id_seen(const frx_val *v, const frx_str *value)
{
    int i;
    for (i = 0; i < v->n_ids; i++)
        if (frx_str_eq2(&v->ids[i].value, value)) return 1;
    return 0;
}

/* ---- the declarations --------------------------------------------------- */

static int
frx_val_notation_declared(const frx_val *v, const frx_str *name)
{
    return frx_dtd_map_find(&v->dtd->notations, name) != NULL;
}

/* Compile every content model once, and make the checks that are about
 * the declarations rather than the document. */
static int
frx_val_declarations(frx_val *v)
{
    const frx_eldecl *ed;
    int i;

    for (ed = v->dtd->first_element; ed && !v->stop; ed = ed->next) {
        const frx_attdef *ad;
        int n_id = 0, n_notation = 0;

        if (!ed->declared) continue;               /* an ATTLIST for an undeclared type */
        if (ed->declared > 1
            && !frx_val_err(v, "the element type is declared more than once (VC: Unique Element Type Declaration)",
                            ed->offset)) return 0;

        if (ed->content == FRX_CONTENT_MIXED || ed->content == FRX_CONTENT_CHILDREN) {
            frx_cm_dfa *d = NULL;
            switch (frx_model_build(v->arena, ed, &d)) {
            case FRX_MODEL_OK:
                if (!frx_dtd_map_add(v->arena, &v->models, &ed->name, d)) {
                    v->nomem = 1; v->stop = 1; return 0;
                }
                break;
            case FRX_MODEL_DUPTYPE:
                if (!frx_val_err(v, "a mixed content model names the same element type twice (VC: No Duplicate Types)",
                                 ed->offset)) return 0;
                break;
            case FRX_MODEL_NONDET:
                if (!frx_val_err(v, "the content model is not deterministic: one name could match two positions (VC: Deterministic Content Model)",
                                 ed->offset)) return 0;
                break;
            default:
                v->nomem = 1; v->stop = 1; return 0;
            }
        }

        for (ad = ed->attdefs; ad; ad = ad->next) {
            /* VC: Attribute Default Value Syntactically Correct. A
             * default is a value of the declared type like any other,
             * and the declaration is where a bad one is written. */
            if (ad->has_value) {
                const char *bad = frx_val_syntax_check(ad->type, ad->enums, ad->n_enums, &ad->value);
                if (bad
                    && !frx_val_err(v, "the default value declared for an attribute does not meet its type's constraints (VC: Attribute Default Value Syntactically Correct)",
                                    ad->offset)) return 0;
            }
            /* VC: No Duplicate Tokens */
            if (ad->type == FRX_ATT_ENUM || ad->type == FRX_ATT_NOTATION) {
                int j;
                for (i = 1; i < ad->n_enums; i++)
                    for (j = 0; j < i; j++)
                        if (frx_str_eq2(&ad->enums[i], &ad->enums[j])
                            && !frx_val_err(v, "an enumeration or notation list names the same token twice (VC: No Duplicate Tokens)",
                                            ad->offset)) return 0;
            }
            if (ad->type == FRX_ATT_ID) {
                n_id++;
                if (n_id > 1
                    && !frx_val_err(v, "an element type has more than one ID attribute (VC: One ID per Element Type)",
                                    ad->offset)) return 0;
                if (ad->def != FRX_DEF_IMPLIED && ad->def != FRX_DEF_REQUIRED
                    && !frx_val_err(v, "an ID attribute must be #IMPLIED or #REQUIRED (VC: ID Attribute Default)",
                                    ad->offset)) return 0;
            }
            if (ad->type == FRX_ATT_NOTATION) {
                n_notation++;
                if (n_notation > 1
                    && !frx_val_err(v, "an element type has more than one NOTATION attribute (VC: One Notation per Element Type)",
                                    ad->offset)) return 0;
                if (ed->content == FRX_CONTENT_EMPTY
                    && !frx_val_err(v, "an element declared EMPTY may not have a NOTATION attribute (VC: No Notation on Empty Element)",
                                    ad->offset)) return 0;
                for (i = 0; i < ad->n_enums; i++)
                    if (!frx_val_notation_declared(v, &ad->enums[i])
                        && !frx_val_err(v, "a NOTATION attribute names a notation that is not declared (VC: Notation Attributes)",
                                        ad->offset)) return 0;
            }
        }
    }
    return !v->stop;
}

/* VC: Notation Declared, over the unparsed entities */
static int
frx_val_notations(frx_val *v)
{
    int i;
    for (i = 0; i < FRX_DTD_BUCKETS && !v->stop; i++) {
        const frx_dtd_slot *s;
        for (s = v->dtd->general.b[i]; s && !v->stop; s = s->next) {
            const frx_entity *e = (const frx_entity *)s->value;
            if (!e->unparsed) continue;
            if (!frx_val_notation_declared(v, &e->ndata)
                && !frx_val_err(v, "an unparsed entity names a notation that is not declared (VC: Notation Declared)",
                                e->offset)) return 0;
        }
    }
    return !v->stop;
}

/* ---- attributes --------------------------------------------------------- */

/* THE SHAPE OF A VALUE UNDER ITS TYPE, and nothing that depends on the
 * rest of the document: is it a Name, a list of Names, a name token, one
 * of the enumerated tokens. A static message when it fails, NULL when it
 * holds, no side effects.
 *
 * This is the whole of what a declared default has to satisfy at its
 * declaration (VC: Attribute Default Value Syntactically Correct). The
 * constraints that look at the rest of the document - does this ENTITY
 * name a declared unparsed entity, does this IDREF resolve - apply to a
 * default only when the default is actually used, which is the third
 * edition's erratum E06, so they are checked over the tree, where a
 * defaulted attribute is an attribute like any other and one the
 * document supplied instead is not there to check. */
static const char *
frx_val_syntax_check(int type, const frx_str *enums, int n_enums, const frx_str *value)
{
    frx_str tok;
    size_t  at = 0;
    int     i, any = 0;

    switch (type) {
    case FRX_ATT_ID:
        return frx_val_is_name(value) ? NULL : "an ID value is not an NCName (VC: ID, and Namespaces erratum NE08)";

    case FRX_ATT_IDREF:
        return frx_val_is_name(value) ? NULL : "an IDREF value is not an NCName (VC: IDREF, and Namespaces erratum NE08)";

    case FRX_ATT_IDREFS:
        while (frx_val_token(value, &at, &tok)) {
            any = 1;
            if (!frx_val_is_name(&tok))
                return "an IDREFS value holds something that is not an NCName (VC: IDREF, and Namespaces erratum NE08)";
        }
        return any ? NULL : "an IDREFS value is empty (VC: IDREF)";

    case FRX_ATT_ENTITY:
        if (!frx_val_is_name(value))
            return "an ENTITY value is not an NCName (VC: Entity Name, and Namespaces erratum NE08)";
        return NULL;

    case FRX_ATT_ENTITIES:
        while (frx_val_token(value, &at, &tok)) {
            any = 1;
            if (!frx_val_is_name(&tok))
                return "an ENTITIES value holds something that is not an NCName (VC: Entity Name, and Namespaces erratum NE08)";
        }
        return any ? NULL : "an ENTITIES value is empty (VC: Entity Name)";

    case FRX_ATT_NMTOKEN:
        return frx_val_is_nmtoken(value) ? NULL
             : "an NMTOKEN value is not a name token (VC: Name Token)";

    case FRX_ATT_NMTOKENS:
        while (frx_val_token(value, &at, &tok)) {
            any = 1;
            if (!frx_val_is_nmtoken(&tok))
                return "an NMTOKENS value holds something that is not a name token (VC: Name Token)";
        }
        return any ? NULL : "an NMTOKENS value is empty (VC: Name Token)";

    case FRX_ATT_NOTATION:
    case FRX_ATT_ENUM:
        for (i = 0; i < n_enums; i++)
            if (frx_str_eq2(&enums[i], value)) return NULL;
        return type == FRX_ATT_NOTATION
             ? "a NOTATION value is not one of the notations declared for it (VC: Notation Attributes)"
             : "an enumerated value is not one of the ones declared for it (VC: Enumeration)";

    default:
        return NULL;                               /* CDATA takes any value */
    }
}

/* what the rest of the document has to say about a value of this type */
static const char *
frx_val_semantic_check(const frx_val *v, int type, const frx_str *value)
{
    frx_str tok;
    size_t  at = 0;
    if (type != FRX_ATT_ENTITY && type != FRX_ATT_ENTITIES) return NULL;
    while (frx_val_token(value, &at, &tok)) {
        const frx_entity *e = frx_dtd_entity(v->dtd, &tok, 0);
        if (!e || !e->unparsed)
            return "an ENTITY or ENTITIES value does not name an unparsed entity (VC: Entity Name)";
    }
    return NULL;
}

static int
frx_val_attr(frx_val *v, const frx_node *n, const frx_attr *a, const frx_attdef *ad)
{
    const char *bad;
    frx_str     tok;
    size_t      at = 0;

    if (ad->def == FRX_DEF_FIXED && !frx_str_eq2(&a->value, &ad->value)
        && !frx_val_err(v, "an attribute declared #FIXED has another value (VC: Fixed Attribute Default)",
                        a->offset)) return 0;

    bad = frx_val_syntax_check(ad->type, ad->enums, ad->n_enums, &a->value);
    if (!bad) bad = frx_val_semantic_check(v, ad->type, &a->value);
    if (bad) return frx_val_err(v, bad, a->offset);

    /* the two types that are about the document as a whole rather than
     * about this value's shape */
    if (ad->type == FRX_ATT_ID) {
        if (frx_val_id_seen(v, &a->value))
            return frx_val_err(v, "two elements carry the same ID value (VC: ID)", a->offset);
        return frx_val_push_id(v, &a->local, &a->value, n, a->offset);
    }
    if (ad->type == FRX_ATT_IDREF) return frx_val_push_idref(v, &a->value, a->offset);
    if (ad->type == FRX_ATT_IDREFS) {
        while (frx_val_token(&a->value, &at, &tok))
            if (!frx_val_push_idref(v, &tok, a->offset)) return 0;
    }
    return 1;
}

static int
frx_val_attrs(frx_val *v, const frx_node *n, const frx_eldecl *ed)
{
    const frx_attdef *ad;
    int i;

    for (i = 0; i < n->n_attrs && !v->stop; i++) {
        const frx_attr   *a  = &n->attrs[i];
        const frx_attdef *ad2 = ed ? frx_dtd_attdef(ed, &a->qname) : NULL;
        if (!ad2) {
            if (!frx_val_err(v, "the attribute is not declared for this element type (VC: Attribute Value Type)",
                             a->offset)) return 0;
            continue;
        }
        if (!frx_val_attr(v, n, a, ad2)) return 0;
    }
    if (!ed) return !v->stop;

    /* A namespace declaration is a declaration and not an attribute in
     * this tree, but a DTD does not know that: Namespaces is a layer above
     * XML 1.0, and to the grammar `xmlns:foo="..."` is an Attribute like
     * any other. So a validating parse holds it to VC: Attribute Value
     * Type exactly as it holds a written attribute, and where the DTD does
     * declare it, what the DTD says about its value holds too, which is
     * what a #FIXED xmlns is for. */
    for (i = 0; i < n->n_decls && !v->stop; i++) {
        const frx_attdef *ad2 = frx_val_nsdecl_attdef(ed, &n->decls[i].prefix);
        const char *bad;
        if (!ad2) {
            if (!frx_val_err(v, "the attribute is not declared for this element type (VC: Attribute Value Type)",
                             n->offset)) return 0;
            continue;
        }
        if (ad2->def == FRX_DEF_FIXED && !frx_str_eq2(&n->decls[i].uri, &ad2->value)
            && !frx_val_err(v, "an attribute declared #FIXED has another value (VC: Fixed Attribute Default)",
                            n->offset)) return 0;
        bad = frx_val_syntax_check(ad2->type, ad2->enums, ad2->n_enums, &n->decls[i].uri);
        if (bad && !frx_val_err(v, bad, n->offset)) return 0;
    }

    /* An xmlns:xml declaration is accepted and dropped from decls, so the
     * loop above cannot see it; the element carries a bit saying it was
     * written (frx_tree.h). VC: Attribute Value Type does not care that
     * the binding it makes is the one the xml prefix already has. */
    if (!v->stop && (n->from_ref & FRX_NODE_XMLNS_XML)) {
        static const frx_str xml_prefix = { "xml", 3 };
        if (!frx_val_nsdecl_attdef(ed, &xml_prefix)
            && !frx_val_err(v, "the attribute is not declared for this element type (VC: Attribute Value Type)",
                            n->offset)) return 0;
    }

    for (ad = ed->attdefs; ad && !v->stop; ad = ad->next) {
        int have = 0;
        if (ad->def != FRX_DEF_REQUIRED) continue;
        if (frx_val_is_xmlns(&ad->name)) {
            if (!frx_val_has_nsdecl(n, &ad->name)
                && !frx_val_err(v, "an attribute declared #REQUIRED is absent (VC: Required Attribute)",
                                n->offset)) return 0;
            continue;
        }
        for (i = 0; i < n->n_attrs; i++)
            if (frx_str_eq2(&n->attrs[i].qname, &ad->name)) { have = 1; break; }
        if (!have
            && !frx_val_err(v, "an attribute declared #REQUIRED is absent (VC: Required Attribute)",
                            n->offset)) return 0;
    }
    return !v->stop;
}

/* ---- content ------------------------------------------------------------ */

/* VC: Element Valid, over one element's own children */
static int
frx_val_content(frx_val *v, const frx_node *n, const frx_eldecl *ed)
{
    const frx_cm_dfa *d = (const frx_cm_dfa *)frx_dtd_map_find(&v->models, &ed->name);
    const frx_node   *c;
    int at = -1;

    /* a reference that left no characters is still content, and an
     * element declared EMPTY may hold none (erratum E15, case E15a);
     * frx_sink.h records it here because there is no node to hang it on */
    if (ed->content == FRX_CONTENT_EMPTY && (n->from_ref & FRX_NODE_FROM_REF)
        && !frx_val_err(v, "an element declared EMPTY has content (VC: Element Valid)", n->offset))
        return 0;

    for (c = n->first_child; c && !v->stop; c = c->next) {
        if (c->kind == FRX_COMMENT || c->kind == FRX_PI) {
            /* a content model ignores these, but EMPTY means no content
             * at all, comments and processing instructions included
             * (second edition erratum E15) */
            if (ed->content == FRX_CONTENT_EMPTY
                && !frx_val_err(v, "an element declared EMPTY has content (VC: Element Valid)", c->offset))
                return 0;
            continue;
        }

        if (c->kind == FRX_TEXT) {
            /* A CDATA section is character data whatever it holds, and
             * an empty one is still a section: it is not the ignorable
             * white space of section 2.10, which is white space written
             * directly in element content. The spans are recorded so the
             * writer can put the sections back; this is the other thing
             * knowing where they were is good for.
             *
             * Second edition erratum E15 says the same of a reference:
             * "the white space in element content must be white space
             * characters that appear directly in the document, not
             * characters that result from the expansion of a character or
             * entity reference". The parse marks such a run, for the same
             * reason and by the same means. */
            int ws = frx_str_is_s(&c->value) && !c->n_cdata_spans && !(c->from_ref & FRX_NODE_FROM_REF);
            if (ed->content == FRX_CONTENT_MIXED || ed->content == FRX_CONTENT_ANY) continue;
            if (ed->content == FRX_CONTENT_EMPTY) {
                if (!frx_val_err(v, "an element declared EMPTY has content (VC: Element Valid)", c->offset))
                    return 0;
                continue;
            }
            if (!ws) {
                if (!frx_val_err(v, "character data where the content model allows only elements (VC: Element Valid)",
                                 c->offset)) return 0;
                continue;
            }
            /* whitespace directly in element content is ignored by the
             * model, and is the fourth clause of the standalone VC when
             * the declaration came from external markup */
            if (v->standalone && ed->external
                && !frx_val_err(v, "standalone=\"yes\" but white space stands directly in an element whose content model was declared in external markup (VC: Standalone Document Declaration)",
                                c->offset)) return 0;
            continue;
        }

        if (c->kind != FRX_ELEMENT) continue;

        switch (ed->content) {
        case FRX_CONTENT_EMPTY:
            if (!frx_val_err(v, "an element declared EMPTY has content (VC: Element Valid)", c->offset))
                return 0;
            break;
        case FRX_CONTENT_ANY:
            break;                                 /* any declared element, checked when visited */
        case FRX_CONTENT_MIXED:
            if (d && !frx_model_mixed_has(d, &c->qname)
                && !frx_val_err(v, "an element the mixed content model does not name (VC: Element Valid)",
                                c->offset)) return 0;
            break;
        default:
            if (!d) break;                         /* the model was refused; do not report twice */
            at = frx_model_step(d, at, &c->qname);
            if (at < 0) {
                if (!frx_val_err(v, "an element the content model does not allow here (VC: Element Valid)",
                                 c->offset)) return 0;
                return !v->stop;                   /* the run is over; one report per element */
            }
            break;
        }
    }

    if (!v->stop && ed->content == FRX_CONTENT_CHILDREN && d && !frx_model_accepts(d, at))
        return frx_val_err(v, "the element's content ends before the content model does (VC: Element Valid)",
                           n->offset);
    return !v->stop;
}

/* ---- the pass ----------------------------------------------------------- */

static void
frx_val_free(frx_val *v)
{
    free(v->ids);
    free(v->idrefs);
    v->ids    = NULL;
    v->idrefs = NULL;
}

/* The index this pass built, sorted into the arena for by_id and XPath.
 * The names go with it: by_id is asked for one, and XPath's id() has no
 * name to give, so it searches every name the index was built from. The
 * sort is by (attr, value), so the distinct names are contiguous. */
static int
frx_val_install_ids(frx_val *v)
{
    frx_idx *in_arena;
    frx_str *names;
    int i, n_names = 0;

    if (!v->own_ids || !v->n_ids) return 1;
    qsort(v->ids, (size_t)v->n_ids, sizeof *v->ids, frx_idx_cmp);
    in_arena = (frx_idx *)frx_arena_alloc(v->arena, (size_t)v->n_ids * sizeof *in_arena);
    names    = (frx_str *)frx_arena_alloc(v->arena, (size_t)v->n_ids * sizeof *names);
    if (!in_arena || !names) { v->nomem = 1; return 0; }
    memcpy(in_arena, v->ids, (size_t)v->n_ids * sizeof *in_arena);
    for (i = 0; i < v->n_ids; i++)
        if (!n_names || !frx_str_eq2(&names[n_names - 1], &in_arena[i].attr))
            names[n_names++] = in_arena[i].attr;

    v->doc->ids        = in_arena;
    v->doc->n_ids      = v->n_ids;
    v->doc->id_attrs   = names;
    v->doc->n_id_attrs = n_names;
    v->doc->id_source  = FRX_ID_DTD;
    return 1;
}

/* Validate the finished document against its DTD. 1 when it is valid or
 * when every violation was collected; 0 with *err filled when the caller
 * asked to stop at the first one, or on an allocation failure. */
static int
frx_validate_doc(frx_doc *doc, int collect, frx_err *err)
{
    frx_val         v;
    const frx_node *n;
    int             i;

    memset(&v, 0, sizeof v);
    v.doc        = doc;
    v.dtd        = doc->dtd;
    v.arena      = &doc->arena;
    v.collect    = collect;
    v.standalone = doc->standalone;
    v.own_ids    = doc->id_source == FRX_ID_NONE;

    if (!doc->doctype) {
        /* a document with no document type declaration is not valid, and
         * that is the whole of what can be said about it */
        frx_val_err(&v, "the document has no document type declaration to be valid against (VC: Element Valid)", 0);
        goto finish;
    }
    if (!v.dtd) goto finish;

    if (!frx_str_eq2(&doc->doctype->name, &doc->root->qname))
        (void)frx_val_err(&v, "the root element is not the one the DOCTYPE names (VC: Root Element Type)",
                          doc->root->offset);

    if (v.dtd->pe_nest_bad)
        (void)frx_val_err(&v, "a markup declaration, a content model group or a conditional section began inside one parameter entity's replacement text and ended outside it (VC: Proper Declaration/PE Nesting)",
                          v.dtd->pe_nest_offset);

    if (!v.stop) (void)frx_val_declarations(&v);
    if (!v.stop) (void)frx_val_notations(&v);

    for (n = doc->document->first_child; n && !v.stop; n = frx_walk_next(n, doc->document)) {
        const frx_eldecl *ed;
        if (n->kind != FRX_ELEMENT) continue;
        ed = frx_dtd_element(v.dtd, &n->qname);
        if (!ed || !ed->declared) {
            if (!frx_val_err(&v, "the element type is not declared (VC: Element Valid)", n->offset)) break;
            continue;
        }
        if (!frx_val_attrs(&v, n, ed))   break;
        if (!frx_val_content(&v, n, ed)) break;
    }

    /* VC: IDREF, once every ID in the document has been seen */
    for (i = 0; i < v.n_idrefs && !v.stop; i++)
        if (!frx_val_id_seen(&v, &v.idrefs[i].value)
            && !frx_val_err(&v, "an IDREF or IDREFS value matches no ID in the document (VC: IDREF)",
                            v.idrefs[i].offset)) break;

    if (!v.nomem) (void)frx_val_install_ids(&v);

    /* VC: Entity Declared, for each reference the parse exempted from the
     * well-formedness constraint (frx_entity.h). They are collected in
     * document order and the walk above produced its own list in document
     * order, so the two are merged rather than appended: `collect` says
     * the list is in document order and means it. */
    for (i = 0; i < doc->n_undeclared_refs && !v.stop; i++)
        if (!frx_val_err_ordered(&v, "an entity reference names no declared entity (VC: Entity Declared)",
                                 doc->undeclared_refs[i])) break;

finish:
    frx_val_free(&v);
    if (v.nomem) {
        frx_err_set(err, FRX_E_NOMEM, 0, "out of memory");
        return 0;
    }
    doc->errors   = v.first;
    doc->n_errors = v.n;
    if (!collect && v.first) {
        frx_err_set(err, FRX_E_VALIDITY, v.first->offset, v.first->what);
        return 0;
    }
    return 1;
}

#endif /* FRX_VALIDATE_H */
