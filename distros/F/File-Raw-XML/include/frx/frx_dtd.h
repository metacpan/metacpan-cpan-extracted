#ifndef FRX_DTD_H
#define FRX_DTD_H

/* The document type declaration, the internal subset and, through a
 * resolver, the external subset: the structures a DTD becomes in the
 * arena, and the declaration parser that fills them. Full profile only.
 *
 * What is kept: element declarations with their content model as a token
 * list (frx_validate.h validates against it; here its syntax is checked and
 * nothing else), attribute lists with each attribute's type and default,
 * general and parameter entities, and notations, each marked with where
 * it was declared, because the standalone constraints of section 2.9
 * turn on that origin. What is used here: attribute types select the
 * 3.3.3 normalisation, defaults are materialised onto every element that
 * lacks them (in declaration order, after the written attributes, and a
 * defaulted xmlns attribute is a namespace declaration like any other,
 * which is why defaulting happens in the lexer before the parser reads
 * the tag), and entities are expanded through frx_entity.h.
 *
 * The internal subset is read first and the external subset after it,
 * so a declaration in the internal subset is the one that binds (section
 * 2.9: internal declarations take precedence). Section 2.8's rules are
 * enforced per frame: in the internal subset a parameter entity
 * reference may stand only between declarations (WFC: PEs in Internal
 * Subset) and a conditional section is refused; in the external subset
 * and in an external parameter entity a PE reference may stand wherever
 * whitespace may (4.4.8: its text is included with a space on each side),
 * inside an entity value (4.4.5: included in the literal), and
 * conditional sections nest. A PE whose text ends inside a declaration is
 * popped and reading continues, which is the non-validating reading of
 * VC: Proper Declaration/PE Nesting; validation may enforce the VC. The
 * first declaration of an entity or of an attribute binds and a later
 * one is read for its syntax and dropped (sections 4.2 and 3.3), as is a
 * second ELEMENT declaration for one name.
 *
 * Nothing external is fetched here; frx_entity.h fetches through the
 * caller's resolver, and with none an external subset is refused at its
 * system literal and an external entity at its reference, each with a
 * message naming the option, because a document whose declarations were
 * only partly read would canonicalise differently from a processor that
 * read them all, and this dist exists to canonicalise for signatures.
 *
 * Nothing recurses (rule 2): the content model parser keeps its group
 * stack in a malloc'd array on the lexer, conditional sections are a
 * counter, and the subset loop is one loop over frames. Every name lookup
 * is a small hash over the arena.
 *
 * Needs frx_tree.h (frx_doctype, the frx_str helpers) and frx_lex.h (its
 * primitives and the forward declarations there); frx_entity.h follows
 * and is declared below. */

/* attribute types, XML 1.0 section 3.3.1 */
enum {
    FRX_ATT_CDATA = 0, FRX_ATT_ID, FRX_ATT_IDREF, FRX_ATT_IDREFS,
    FRX_ATT_ENTITY, FRX_ATT_ENTITIES, FRX_ATT_NMTOKEN, FRX_ATT_NMTOKENS,
    FRX_ATT_NOTATION, FRX_ATT_ENUM
};

/* default declarations, section 3.3.2 */
enum { FRX_DEF_VALUE = 0, FRX_DEF_REQUIRED, FRX_DEF_IMPLIED, FRX_DEF_FIXED };

/* content specifications, section 3.2 */
enum { FRX_CONTENT_EMPTY = 0, FRX_CONTENT_ANY, FRX_CONTENT_MIXED, FRX_CONTENT_CHILDREN };

/* content model tokens: the kind is the character for ( ) | , ? * + and
 * one of these two for a name and #PCDATA */
enum { FRX_CM_NAME = 'N', FRX_CM_PCDATA = 'P' };

typedef struct frx_cm_tok {
    int     kind;
    frx_str name;               /* FRX_CM_NAME only */
} frx_cm_tok;

struct frx_attdef {
    frx_str        name;        /* as written; a QName, xmlns:* included */
    int            type;        /* FRX_ATT_* */
    const frx_str *enums;       /* NOTATION and ENUM: the names or tokens */
    int            n_enums;
    int            def;         /* FRX_DEF_* */
    int            has_value;   /* FRX_DEF_VALUE or FRX_DEF_FIXED */
    frx_str        value;       /* the default, normalised by type */
    int            external;    /* declared in the external subset or an external PE */
    size_t         offset;      /* document offset of the definition */
    struct frx_attdef *next;    /* declaration order */
};

struct frx_eldecl {
    frx_str          name;
    int              declared;  /* how many ELEMENT declarations were read, so 0 is none (an
                                 * ATTLIST may come first) and more than one is a validity
                                 * error validation reports; only the first one binds */
    int              content;   /* FRX_CONTENT_* */
    const frx_cm_tok *model;    /* MIXED and CHILDREN: the tokens, parentheses included */
    int              n_model;
    int              external;  /* the ELEMENT declaration was external markup */
    frx_attdef      *attdefs;   /* declaration order */
    frx_attdef      *last_attdef;
    int              n_attdefs;
    size_t           offset;
    struct frx_eldecl *next;    /* declaration order, for validation */
};

struct frx_entity {
    frx_str name;
    int     is_pe;
    int     external;           /* SYSTEM or PUBLIC */
    int     unparsed;           /* NDATA */
    int     external_decl;      /* declared in the external subset or an external PE */
    int     direct;             /* declared directly in the internal subset: not in the
                                 * external subset nor inside any parameter entity, which
                                 * is what WFC: Entity Declared asks of a standalone document */
    frx_str public_id;          /* "" when none */
    frx_str system_id;
    frx_str ndata;
    frx_str base;               /* base URI of the entity the declaration stood in */
    frx_str text;               /* the replacement text of section 4.5; fetched once for an external one */
    frx_str padded;             /* text with a space on each side (4.4.8), built on first use */
    frx_str uri;                /* external: the resolved identifier, once fetched */
    int     fetched;            /* external: text is filled */
    int     version11;          /* external: its text declaration said 1.1 */
    int     flat;               /* declared in fetched text: offsets inside it are the reference's */
    size_t  offset;             /* document offset of the declaration */
    size_t  text_offset;        /* document offset of the literal's first byte */
    int     expanding;          /* on the frame stack now; WFC: No Recursion */
};

typedef struct frx_notation {
    frx_str name;
    frx_str public_id;
    frx_str system_id;
    size_t  offset;
} frx_notation;

typedef struct frx_dtd_slot {
    frx_str              name;
    void                *value;
    struct frx_dtd_slot *next;
} frx_dtd_slot;

#define FRX_DTD_BUCKETS 64

typedef struct frx_dtd_map {
    frx_dtd_slot *b[FRX_DTD_BUCKETS];
} frx_dtd_map;

struct frx_dtd {
    frx_dtd_map elements;
    frx_dtd_map general;
    frx_dtd_map params;
    frx_dtd_map notations;
    frx_eldecl *first_element;
    frx_eldecl *last_element;
    int         external_subset;    /* the DOCTYPE carried an external ID */
    int         external_read;      /* and it was fetched and read */
    int         pe_ref_seen;        /* a parameter entity reference stood in the subset */
    /* A markup declaration, a content model group or a conditional
     * section that began inside one parameter entity's replacement text
     * and ended outside it, or the other way about. Reading continues
     * either way, because the text of a parameter entity is included in
     * the stream and the construct does finish; it is a validity
     * constraint and frx_validate.h reports it. */
    int         pe_nest_bad;
    size_t      pe_nest_offset;
};

/* the first straddling construct, remembered for validation */
static void
frx_dtd_pe_nest(frx_lex *l, size_t at);

/* which replacement text is being read: 0 for the document or the
 * external subset itself, and each parameter entity's own serial
 * otherwise. Frame depth alone will not do, because `%a;%b;` puts two
 * different texts at one depth. */
static int
frx_dtd_cur_seq(const frx_lex *l)
{
    return l->n_frames ? l->frames[l->n_frames - 1].seq : 0;
}

/* frx_entity.h */
static int frx_entity_pe_reference(frx_lex *l, size_t start, int padded);
static int frx_entity_push_text(frx_lex *l, frx_entity *e, const frx_str *text, size_t ref_rel,
                                int flat, size_t base_off, const frx_str *cur_base, int ext_decl);
static int frx_entity_fetch(frx_lex *l, int kind, const frx_str *pub, const frx_str *sys,
                            const frx_str *base, size_t ref_rel,
                            frx_str *text, frx_str *uri, int *version11);

/* the lexer names the entity a token came from through this, since the
 * struct is complete only here */
static const frx_str *
frx_entity_name_of(const frx_entity *e)
{
    return &e->name;
}

/* ---- the maps ---------------------------------------------------------- */

static unsigned
frx_dtd_hash(const char *p, size_t n)
{
    unsigned h = 2166136261u;                   /* FNV-1a */
    size_t i;
    for (i = 0; i < n; i++) { h ^= (unsigned char)p[i]; h *= 16777619u; }
    return h & (FRX_DTD_BUCKETS - 1);
}

static void *
frx_dtd_map_find(const frx_dtd_map *m, const frx_str *name)
{
    const frx_dtd_slot *s;
    for (s = m->b[frx_dtd_hash(name->p, name->len)]; s; s = s->next)
        if (frx_str_eq2(&s->name, name)) return s->value;
    return NULL;
}

static int
frx_dtd_map_add(frx_arena *a, frx_dtd_map *m, const frx_str *name, void *value)
{
    unsigned h = frx_dtd_hash(name->p, name->len);
    frx_dtd_slot *s = (frx_dtd_slot *)frx_arena_alloc(a, sizeof *s);
    if (!s) return 0;
    s->name  = *name;
    s->value = value;
    s->next  = m->b[h];
    m->b[h]  = s;
    return 1;
}

static void
frx_dtd_pe_nest(frx_lex *l, size_t at)
{
    if (l->dtd && !l->dtd->pe_nest_bad) {
        l->dtd->pe_nest_bad    = 1;
        l->dtd->pe_nest_offset = FRX_LEX_ABS(l, at);
    }
}

static frx_dtd *
frx_dtd_new(frx_arena *a)
{
    frx_dtd *d = (frx_dtd *)frx_arena_alloc(a, sizeof *d);
    if (d) memset(d, 0, sizeof *d);
    return d;
}

static const frx_eldecl *
frx_dtd_element(const frx_dtd *dtd, const frx_str *name)
{
    return (const frx_eldecl *)frx_dtd_map_find(&dtd->elements, name);
}

static const frx_attdef *
frx_dtd_attdef(const frx_eldecl *ed, const frx_str *name)
{
    const frx_attdef *ad;
    for (ad = ed->attdefs; ad; ad = ad->next)
        if (frx_str_eq2(&ad->name, name)) return ad;
    return NULL;
}

/* section 3.3.3: every type but CDATA collapses */
static int
frx_dtd_attdef_collapses(const frx_attdef *ad)
{
    return ad->type != FRX_ATT_CDATA;
}

static int
frx_dtd_attdef_external(const frx_attdef *ad)
{
    return ad->external;
}

static frx_entity *
frx_dtd_entity(const frx_dtd *dtd, const frx_str *name, int is_pe)
{
    return (frx_entity *)frx_dtd_map_find(is_pe ? &dtd->params : &dtd->general, name);
}

/* the element's record, created on first mention by ELEMENT or ATTLIST */
static frx_eldecl *
frx_dtd_eldecl_get(frx_lex *l, const frx_str *name, size_t offset)
{
    frx_eldecl *ed = (frx_eldecl *)frx_dtd_map_find(&l->dtd->elements, name);
    if (ed) return ed;
    ed = (frx_eldecl *)frx_arena_alloc(l->arena, sizeof *ed);
    if (!ed) return NULL;
    memset(ed, 0, sizeof *ed);
    ed->name   = *name;
    ed->offset = offset;
    if (!frx_dtd_map_add(l->arena, &l->dtd->elements, name, ed)) return NULL;
    if (l->dtd->last_element) l->dtd->last_element->next = ed;
    else                      l->dtd->first_element = ed;
    l->dtd->last_element = ed;
    return ed;
}

/* the declared defaults the tag lacks, appended after what was written */
static int
frx_dtd_apply_defaults(frx_lex *l, const frx_eldecl *ed)
{
    const frx_attdef *ad;
    int n_written = l->n_attrs;
    for (ad = ed->attdefs; ad; ad = ad->next) {
        int i, have = 0;
        if (!ad->has_value) continue;
        for (i = 0; i < n_written; i++)
            if (frx_str_eq2(&l->attrs[i].name, &ad->name)) { have = 1; break; }
        if (have) continue;
        if (ad->external && l->standalone && l->validate)
            return FRX_LEX_FAIL(l, FRX_E_DTD, l->tok_start,
                                "standalone=\"yes\" but an attribute default declared in the external subset applies (VC: Standalone Document Declaration)");
        if (!frx_lex_push_attr(l, &ad->name, &ad->value, ad->offset, 1)) return 0;
    }
    return 1;
}

/* ---- the declaration parser --------------------------------------------- */

#define FRX_DTD_PE_MESSAGE \
    "a parameter entity reference is not allowed inside a markup declaration in the internal subset (WFC: PEs in Internal Subset)"

/* Whitespace inside a declaration, and what section 2.8 lets stand where
 * it does: in the internal subset a parameter entity reference is
 * refused; in external markup it is expanded with its padding (4.4.8) and
 * reading continues into it, and a frame that ends here is popped. *had
 * says whether anything was consumed, which is what "S required" means
 * when a PE supplied it. */
static int
frx_dtd_ws(frx_lex *l, size_t *had)
{
    *had = 0;
    for (;;) {
        *had += frx_lex_skip_s(l);
        if (l->pos >= l->len) {
            if (l->n_frames > l->decl_frame0) { if (!frx_entity_pop(l)) return 0; (*had)++; continue; }
            return 1;
        }
        if (l->in[l->pos] == '%') {
            size_t at = l->pos;
            if (!l->ext_decl) return FRX_LEX_FAIL(l, FRX_E_DTD, at, FRX_DTD_PE_MESSAGE);
            l->pos++;
            if (!frx_entity_pe_reference(l, at, 1)) return 0;
            (*had)++;
            continue;
        }
        return 1;
    }
}

static int
frx_dtd_need_s(frx_lex *l, const char *what)
{
    size_t had;
    if (!frx_dtd_ws(l, &had)) return 0;
    if (!had) return FRX_LEX_FAIL(l, FRX_E_DTD, l->pos, what);
    return 1;
}

static int
frx_dtd_is_ascii_name_char(unsigned char c)
{
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9')
        || c == '_' || c == '-' || c == '.' || c == ':' || c >= 0x80;
}

/* a keyword at pos, not run into a longer name; consumed when matched */
static int
frx_dtd_word(frx_lex *l, const char *lit)
{
    size_t n = strlen(lit);
    if (!frx_lex_starts(l, l->pos, lit)) return 0;
    if (l->pos + n < l->len && frx_dtd_is_ascii_name_char(l->in[l->pos + n])) return 0;
    l->pos += n;
    return 1;
}

/* a quoted literal: SystemLiteral (any characters) or PubidLiteral
 * (section 2.3's PubidChar) */
static int
frx_dtd_literal(frx_lex *l, int pubid, frx_str *out)
{
    unsigned char q;
    size_t start = l->pos;
    if (l->pos >= l->len || ((q = l->in[l->pos]) != '"' && q != '\''))
        return FRX_LEX_FAIL(l, FRX_E_DTD, l->pos, pubid ? "expected a quoted public ID" : "expected a quoted system literal");
    l->pos++;
    l->tmp.len = 0;
    for (;;) {
        unsigned char c;
        if (l->pos >= l->len)
            return FRX_LEX_FAIL(l, FRX_E_DTD, start, pubid ? "unterminated public ID" : "unterminated system literal");
        c = l->in[l->pos];
        if (c == q) { l->pos++; break; }
        if (pubid) {
            if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9')
                  || c == 0x20 || c == 0xD || c == 0xA
                  || (c && c < 0x80 && strchr("-'()+,./:=?;!*#@$_%", c))))
                return FRX_LEX_FAIL(l, FRX_E_DTD, l->pos, "not a public ID character");
            frx_buf_append_ch(&l->tmp, (char)c);
            l->pos++;
        } else {
            if (!frx_lex_char(l)) return 0;
        }
    }
    return frx_lex_intern_buf(l, out);
}

/* SYSTEM S SystemLiteral | PUBLIC S PubidLiteral S SystemLiteral, and with
 * pubid_only the NOTATION form that stops after the public ID. *sys_at
 * gets the frame-relative offset of the system literal, or of the keyword. */
static int
frx_dtd_external_id(frx_lex *l, frx_str *pub, frx_str *sys, int pubid_only, size_t *sys_at)
{
    size_t had;
    *pub = *sys = FRX_EMPTY_STR;
    *sys_at = l->pos;
    if (frx_dtd_word(l, "SYSTEM")) {
        if (!frx_dtd_need_s(l, "expected whitespace after SYSTEM")) return 0;
        *sys_at = l->pos;
        return frx_dtd_literal(l, 0, sys);
    }
    if (frx_dtd_word(l, "PUBLIC")) {
        if (!frx_dtd_need_s(l, "expected whitespace after PUBLIC")) return 0;
        if (!frx_dtd_literal(l, 1, pub)) return 0;
        if (!frx_dtd_ws(l, &had)) return 0;
        if (l->pos < l->len && (l->in[l->pos] == '"' || l->in[l->pos] == '\'')) {
            if (!had) return FRX_LEX_FAIL(l, FRX_E_DTD, l->pos, "expected whitespace before the system literal");
            *sys_at = l->pos;
            return frx_dtd_literal(l, 0, sys);
        }
        if (!pubid_only) return FRX_LEX_FAIL(l, FRX_E_DTD, l->pos, "expected a system literal after the public ID");
        return 1;
    }
    return FRX_LEX_FAIL(l, FRX_E_DTD, l->pos, "expected SYSTEM or PUBLIC");
}

/* an Nmtoken: NameChar+, the colon included (an Nmtoken is not a QName) */
static int
frx_dtd_nmtoken(frx_lex *l, frx_str *out)
{
    size_t start = l->pos;
    while (l->pos < l->len) {
        unsigned char c = l->in[l->pos];
        unsigned long cp;
        size_t n;
        if (c < 0x80) { cp = c; n = 1; }
        else {
            n = frx_utf8_decode(l->in + l->pos, l->len - l->pos, &cp);
            if (!n) return FRX_LEX_FAIL(l, FRX_E_UTF8, l->pos, "not UTF-8");
        }
        if (cp != ':' && !frx_is_name_char(cp)) break;
        l->pos += n;
    }
    if (l->pos == start) return FRX_LEX_FAIL(l, FRX_E_DTD, start, "expected a name token");
    return frx_lex_intern(l, l->in + start, l->pos - start, out);
}

static int
frx_dtd_cm_push(frx_lex *l, int kind, const frx_str *name)
{
    frx_cm_tok t;
    t.kind = kind;
    t.name = name ? *name : FRX_EMPTY_STR;
    frx_buf_append_n(&l->tmp, (const char *)&t, sizeof t);
    return l->tmp.failed ? frx_lex_nomem(l) : 1;
}

static int
frx_dtd_cm_group_push(frx_lex *l, int *sp, int frame)
{
    if (*sp == l->cm_cap) {
        int ncap = l->cm_cap ? l->cm_cap * 2 : 16;
        int *ns = (int *)realloc(l->cm_stack, (size_t)ncap * sizeof *ns);
        int *nf;
        if (!ns) return frx_lex_nomem(l);
        l->cm_stack = ns;
        nf = (int *)realloc(l->cm_frame, (size_t)ncap * sizeof *nf);
        if (!nf) return frx_lex_nomem(l);
        l->cm_frame = nf;
        l->cm_cap   = ncap;
    }
    l->cm_frame[*sp]     = frame;               /* VC: Proper Group/PE Nesting */
    l->cm_stack[(*sp)++] = 0;                   /* separator not yet known */
    return 1;
}

/* a modifier right after a name or a closing parenthesis, no S between */
static int
frx_dtd_cm_modifier(frx_lex *l)
{
    if (l->pos < l->len) {
        unsigned char c = l->in[l->pos];
        if (c == '?' || c == '*' || c == '+') {
            l->pos++;
            return frx_dtd_cm_push(l, c, NULL);
        }
    }
    return 1;
}

/* Mixed or children, section 3.2.1 and 3.2.2; pos is at the opening
 * parenthesis. The tokens accumulate in tmp as raw frx_cm_tok bytes and
 * are copied into the arena at the end. A PE may supply any part of it
 * in external markup, since frx_dtd_ws expands one wherever S may stand. */
static int
frx_dtd_content_model(frx_lex *l, int *content, const frx_cm_tok **model, int *n_model)
{
    size_t open = l->pos;
    int    open_frame = frx_dtd_cur_seq(l);   /* VC: Proper Group/PE Nesting */
    size_t had;
    frx_str name;
    l->tmp.len = 0;
    l->pos++;
    if (!frx_dtd_cm_push(l, '(', NULL)) return 0;
    if (!frx_dtd_ws(l, &had)) return 0;

    if (frx_lex_starts(l, l->pos, "#PCDATA")) {
        int names = 0;
        l->pos += 7;
        if (!frx_dtd_cm_push(l, FRX_CM_PCDATA, NULL)) return 0;
        for (;;) {
            if (!frx_dtd_ws(l, &had)) return 0;
            if (l->pos >= l->len)
                return FRX_LEX_FAIL(l, FRX_E_DTD, open, "unterminated content model");
            if (l->in[l->pos] == ')') {
                if (frx_dtd_cur_seq(l) != open_frame) frx_dtd_pe_nest(l, open);
                l->pos++;
                if (!frx_dtd_cm_push(l, ')', NULL)) return 0;
                if (l->pos < l->len && l->in[l->pos] == '*') {
                    l->pos++;
                    if (!frx_dtd_cm_push(l, '*', NULL)) return 0;
                } else if (names) {
                    return FRX_LEX_FAIL(l, FRX_E_DTD, l->pos, "a mixed content model that names elements must end in )*");
                }
                break;
            }
            if (l->in[l->pos] != '|')
                return FRX_LEX_FAIL(l, FRX_E_DTD, l->pos, "expected | or ) in a mixed content model");
            l->pos++;
            if (!frx_dtd_cm_push(l, '|', NULL)) return 0;
            if (!frx_dtd_ws(l, &had)) return 0;
            if (!frx_lex_name(l, 1, &name)) return 0;
            if (!frx_dtd_cm_push(l, FRX_CM_NAME, &name)) return 0;
            names++;
        }
        *content = FRX_CONTENT_MIXED;
    } else {
        int sp = 0;
        int expect_cp = 1;
        if (!frx_dtd_cm_group_push(l, &sp, open_frame)) return 0;
        while (sp > 0) {
            unsigned char c;
            if (!frx_dtd_ws(l, &had)) return 0;
            if (l->pos >= l->len)
                return FRX_LEX_FAIL(l, FRX_E_DTD, open, "unterminated content model");
            c = l->in[l->pos];
            if (expect_cp) {
                if (c == '(') {
                    l->pos++;
                    if (!frx_dtd_cm_push(l, '(', NULL)) return 0;
                    if (!frx_dtd_cm_group_push(l, &sp, frx_dtd_cur_seq(l))) return 0;
                    continue;
                }
                if (!frx_lex_name(l, 1, &name)) return 0;
                if (!frx_dtd_cm_push(l, FRX_CM_NAME, &name)) return 0;
                if (!frx_dtd_cm_modifier(l)) return 0;
                expect_cp = 0;
                continue;
            }
            if (c == '|' || c == ',') {
                int *sep = &l->cm_stack[sp - 1];
                if (*sep == 0) *sep = c;
                else if (*sep != (int)c)
                    return FRX_LEX_FAIL(l, FRX_E_DTD, l->pos, "a content model group is a choice or a sequence, not both");
                l->pos++;
                if (!frx_dtd_cm_push(l, c, NULL)) return 0;
                expect_cp = 1;
                continue;
            }
            if (c == ')') {
                if (frx_dtd_cur_seq(l) != l->cm_frame[sp - 1]) frx_dtd_pe_nest(l, open);
                l->pos++;
                if (!frx_dtd_cm_push(l, ')', NULL)) return 0;
                sp--;
                if (!frx_dtd_cm_modifier(l)) return 0;
                continue;
            }
            return FRX_LEX_FAIL(l, FRX_E_DTD, l->pos, "expected |, a comma or ) in a content model");
        }
        *content = FRX_CONTENT_CHILDREN;
    }

    {
        size_t n = l->tmp.len / sizeof(frx_cm_tok);
        frx_cm_tok *toks = (frx_cm_tok *)frx_arena_alloc(l->arena, n * sizeof *toks);
        if (!toks) return frx_lex_nomem(l);
        memcpy(toks, l->tmp.p, n * sizeof *toks);
        *model   = toks;
        *n_model = (int)n;
    }
    return 1;
}

/* the > that ends a declaration, after optional whitespace */
static int
frx_dtd_close(frx_lex *l, size_t at, const char *unterminated)
{
    size_t had;
    if (!frx_dtd_ws(l, &had)) return 0;
    if (l->pos >= l->len || l->in[l->pos] != '>')
        return FRX_LEX_FAIL(l, FRX_E_DTD, at, unterminated);
    /* VC: Proper Declaration/PE Nesting: the > is in the replacement
     * text the <! was in, or in neither */
    if (frx_dtd_cur_seq(l) != l->decl_seq) frx_dtd_pe_nest(l, at);
    l->pos++;
    return 1;
}

/* <!ELEMENT S Name S contentspec S? >; pos is past the keyword */
static int
frx_dtd_element_decl(frx_lex *l, size_t at)
{
    frx_str name;
    frx_eldecl *ed;
    int content = FRX_CONTENT_EMPTY;
    const frx_cm_tok *model = NULL;
    int n_model = 0;
    if (!frx_dtd_need_s(l, "expected whitespace after ELEMENT")) return 0;
    if (!frx_lex_name(l, 1, &name)) return 0;
    if (!frx_dtd_need_s(l, "expected whitespace after the element name")) return 0;
    if (frx_dtd_word(l, "EMPTY"))    content = FRX_CONTENT_EMPTY;
    else if (frx_dtd_word(l, "ANY")) content = FRX_CONTENT_ANY;
    else if (l->pos < l->len && l->in[l->pos] == '(') {
        if (!frx_dtd_content_model(l, &content, &model, &n_model)) return 0;
    } else {
        return FRX_LEX_FAIL(l, FRX_E_DTD, l->pos, "expected EMPTY, ANY or a content model");
    }
    if (!frx_dtd_close(l, at, "unterminated ELEMENT declaration")) return 0;
    ed = frx_dtd_eldecl_get(l, &name, FRX_LEX_ABS(l, at));
    if (!ed) return frx_lex_nomem(l);
    if (!ed->declared++) {                      /* a second declaration is counted and dropped */
        ed->content  = content;
        ed->model    = model;
        ed->n_model  = n_model;
        ed->external = l->ext_decl;
    }
    return 1;
}

/* <!ATTLIST S Name AttDef* S? >; pos is past the keyword */
static int
frx_dtd_attlist_decl(frx_lex *l, size_t at)
{
    frx_str ename;
    frx_eldecl *ed;
    if (!frx_dtd_need_s(l, "expected whitespace after ATTLIST")) return 0;
    if (!frx_lex_name(l, 1, &ename)) return 0;
    ed = frx_dtd_eldecl_get(l, &ename, FRX_LEX_ABS(l, at));
    if (!ed) return frx_lex_nomem(l);
    for (;;) {
        size_t had, def_at;
        frx_str aname, value;
        int type, def = FRX_DEF_VALUE, has_value = 0, n_enums = 0;
        const frx_str *enums = NULL;
        if (!frx_dtd_ws(l, &had)) return 0;
        if (l->pos >= l->len)
            return FRX_LEX_FAIL(l, FRX_E_DTD, at, "unterminated ATTLIST declaration");
        if (l->in[l->pos] == '>') {
            if (frx_dtd_cur_seq(l) != l->decl_seq) frx_dtd_pe_nest(l, at);
            l->pos++;
            break;
        }
        if (!had)
            return FRX_LEX_FAIL(l, FRX_E_DTD, l->pos, "expected whitespace before an attribute definition");
        def_at = l->pos;
        if (!frx_lex_name(l, 1, &aname)) return 0;
        if (!frx_dtd_need_s(l, "expected whitespace after the attribute name")) return 0;

        /* AttType */
        if (l->pos >= l->len)
            return FRX_LEX_FAIL(l, FRX_E_DTD, at, "unterminated ATTLIST declaration");
        if (l->in[l->pos] == '(' || frx_lex_starts(l, l->pos, "NOTATION")) {
            int notation = l->in[l->pos] != '(';
            size_t open;
            int n = 0;
            type = notation ? FRX_ATT_NOTATION : FRX_ATT_ENUM;
            if (notation) {
                l->pos += 8;
                if (!frx_dtd_need_s(l, "expected whitespace after NOTATION")) return 0;
            }
            if (l->pos >= l->len || l->in[l->pos] != '(')
                return FRX_LEX_FAIL(l, FRX_E_DTD, l->pos, "expected ( after NOTATION");
            open = l->pos;
            l->pos++;
            l->tmp.len = 0;
            for (;;) {
                frx_str tok;
                if (!frx_dtd_ws(l, &had)) return 0;
                if (notation ? !frx_lex_name(l, 0, &tok) : !frx_dtd_nmtoken(l, &tok)) return 0;
                frx_buf_append_n(&l->tmp, (const char *)&tok, sizeof tok);
                if (l->tmp.failed) return frx_lex_nomem(l);
                n++;
                if (!frx_dtd_ws(l, &had)) return 0;
                if (l->pos >= l->len)
                    return FRX_LEX_FAIL(l, FRX_E_DTD, open, "unterminated enumeration");
                if (l->in[l->pos] == ')') { l->pos++; break; }
                if (l->in[l->pos] != '|')
                    return FRX_LEX_FAIL(l, FRX_E_DTD, l->pos, "expected | or ) in an enumeration");
                l->pos++;
            }
            {
                frx_str *arr = (frx_str *)frx_arena_alloc(l->arena, (size_t)n * sizeof *arr);
                if (!arr) return frx_lex_nomem(l);
                memcpy(arr, l->tmp.p, (size_t)n * sizeof *arr);
                enums   = arr;
                n_enums = n;
            }
        }
        else if (frx_dtd_word(l, "CDATA"))    type = FRX_ATT_CDATA;
        else if (frx_dtd_word(l, "IDREFS"))   type = FRX_ATT_IDREFS;
        else if (frx_dtd_word(l, "IDREF"))    type = FRX_ATT_IDREF;
        else if (frx_dtd_word(l, "ID"))       type = FRX_ATT_ID;
        else if (frx_dtd_word(l, "ENTITIES")) type = FRX_ATT_ENTITIES;
        else if (frx_dtd_word(l, "ENTITY"))   type = FRX_ATT_ENTITY;
        else if (frx_dtd_word(l, "NMTOKENS")) type = FRX_ATT_NMTOKENS;
        else if (frx_dtd_word(l, "NMTOKEN"))  type = FRX_ATT_NMTOKEN;
        else return FRX_LEX_FAIL(l, FRX_E_DTD, l->pos, "expected an attribute type");

        if (!frx_dtd_need_s(l, "expected whitespace before the default declaration")) return 0;

        /* DefaultDecl; a default value is an AttValue, read as one: entity
         * references included in the literal, a < refused, the type's
         * normalisation applied; a PE reference is not recognised in it */
        if (frx_dtd_word(l, "#REQUIRED"))     def = FRX_DEF_REQUIRED;
        else if (frx_dtd_word(l, "#IMPLIED")) def = FRX_DEF_IMPLIED;
        else {
            if (frx_dtd_word(l, "#FIXED")) {
                def = FRX_DEF_FIXED;
                if (!frx_dtd_need_s(l, "expected whitespace after #FIXED")) return 0;
            }
            if (l->pos >= l->len || (l->in[l->pos] != '"' && l->in[l->pos] != '\''))
                return FRX_LEX_FAIL(l, FRX_E_DTD, l->pos, "expected #REQUIRED, #IMPLIED, #FIXED or a quoted default value");
            if (!frx_lex_attr_value(l, &value, type != FRX_ATT_CDATA)) return 0;
            has_value = 1;
        }

        if (!frx_dtd_attdef(ed, &aname)) {          /* the first definition binds */
            frx_attdef *ad = (frx_attdef *)frx_arena_alloc(l->arena, sizeof *ad);
            if (!ad) return frx_lex_nomem(l);
            memset(ad, 0, sizeof *ad);
            ad->name      = aname;
            ad->type      = type;
            ad->enums     = enums;
            ad->n_enums   = n_enums;
            ad->def       = def;
            ad->has_value = has_value;
            ad->value     = has_value ? value : FRX_EMPTY_STR;
            ad->external  = l->ext_decl;
            ad->offset    = FRX_LEX_ABS(l, def_at);
            if (ed->last_attdef) ed->last_attdef->next = ad;
            else                 ed->attdefs = ad;
            ed->last_attdef = ad;
            ed->n_attdefs++;
        }
    }
    return 1;
}

/* EntityValue, section 4.5: character references become the character,
 * general entity references stay as written, and a parameter entity
 * reference is refused in the internal subset and included in the literal
 * (4.4.5) in external markup, where the literal's own quote is the only
 * one that ends it. */
static int
frx_dtd_entity_value(frx_lex *l, frx_str *out)
{
    unsigned char q = l->in[l->pos];
    size_t start = l->pos;
    int    frame0 = l->n_frames;
    l->pos++;
    l->tmp.len = 0;
    for (;;) {
        unsigned char c;
        if (l->pos >= l->len) {
            if (l->n_frames > frame0) { if (!frx_entity_pop(l)) return 0; continue; }
            return FRX_LEX_FAIL(l, FRX_E_DTD, start, "unterminated entity value");
        }
        c = l->in[l->pos];
        if (c == q && l->n_frames == frame0) { l->pos++; break; }
        if (c == '%') {
            size_t at = l->pos;
            if (!l->ext_decl)
                return FRX_LEX_FAIL(l, FRX_E_DTD, at, FRX_DTD_PE_MESSAGE);
            l->pos++;
            if (!frx_entity_pe_reference(l, at, 0)) return 0;
            continue;
        }
        if (c == '&') {
            if (l->pos + 1 < l->len && l->in[l->pos + 1] == '#') {
                if (!frx_lex_ref(l, 0)) return 0;      /* the numeric branch */
            } else {
                size_t s = l->pos;
                frx_str name;
                l->pos++;
                if (!frx_lex_name(l, 0, &name)) return 0;
                if (l->pos >= l->len || l->in[l->pos] != ';')
                    return FRX_LEX_FAIL(l, FRX_E_REFERENCE, s, "malformed entity reference");
                l->pos++;
                frx_buf_append_n(&l->tmp, (const char *)(l->in + s), l->pos - s);
            }
            continue;
        }
        if (!frx_lex_char(l)) return 0;
    }
    return frx_lex_intern_buf(l, out);
}

/* <!ENTITY S (Name S EntityDef | % S Name S PEDef) S? >; pos is past the keyword */
static int
frx_dtd_entity_decl(frx_lex *l, size_t at)
{
    frx_entity *e;
    frx_str name;
    size_t had;
    int is_pe = 0;
    if (!frx_lex_skip_s(l))
        return FRX_LEX_FAIL(l, FRX_E_DTD, l->pos, "expected whitespace after ENTITY");
    if (l->pos < l->len && l->in[l->pos] == '%') {
        l->pos++;
        if (l->pos < l->len && !frx_is_s(l->in[l->pos])) {
            if (!l->ext_decl) return FRX_LEX_FAIL(l, FRX_E_DTD, l->pos - 1, FRX_DTD_PE_MESSAGE);
            l->pos--;                                  /* external markup: a PE supplies what follows */
        } else {
            is_pe = 1;
        }
    }
    if (!frx_dtd_ws(l, &had)) return 0;
    if (!is_pe && l->pos < l->len && l->in[l->pos] == '%') {   /* "% " after a PE frame */
        l->pos++;
        if (!frx_dtd_need_s(l, "expected whitespace after % in a parameter entity declaration")) return 0;
        is_pe = 1;
    } else if (is_pe && !had) {
        return FRX_LEX_FAIL(l, FRX_E_DTD, l->pos, "expected whitespace after % in a parameter entity declaration");
    }
    if (!frx_lex_name(l, 0, &name)) return 0;
    if (!frx_dtd_need_s(l, "expected whitespace after the entity name")) return 0;

    e = (frx_entity *)frx_arena_alloc(l->arena, sizeof *e);
    if (!e) return frx_lex_nomem(l);
    memset(e, 0, sizeof *e);
    e->name   = name;
    e->is_pe  = is_pe;
    e->offset = FRX_LEX_ABS(l, at);
    e->external_decl = l->ext_decl;
    e->direct = !l->ext_decl && !l->in_dtd;
    e->base   = l->cur_base;
    e->flat   = l->flat;
    e->public_id = e->system_id = e->ndata = e->text = e->padded = e->uri = FRX_EMPTY_STR;

    if (l->pos >= l->len)
        return FRX_LEX_FAIL(l, FRX_E_DTD, at, "unterminated ENTITY declaration");
    if (l->in[l->pos] == '"' || l->in[l->pos] == '\'') {
        e->text_offset = FRX_LEX_ABS(l, l->pos + 1);
        if (!frx_dtd_entity_value(l, &e->text)) return 0;
    } else {
        size_t sys_at;
        if (!frx_dtd_external_id(l, &e->public_id, &e->system_id, 0, &sys_at)) return 0;
        e->external = 1;
        if (!is_pe) {
            if (!frx_dtd_ws(l, &had)) return 0;
            if (frx_lex_starts(l, l->pos, "NDATA")) {
                if (!had) return FRX_LEX_FAIL(l, FRX_E_DTD, l->pos, "expected whitespace before NDATA");
                l->pos += 5;
                if (!frx_dtd_need_s(l, "expected whitespace after NDATA")) return 0;
                if (!frx_lex_name(l, 0, &e->ndata)) return 0;
                e->unparsed = 1;
            }
        }
    }
    if (!frx_dtd_close(l, at, "unterminated ENTITY declaration")) return 0;
    if (!frx_dtd_entity(l->dtd, &name, is_pe)) {  /* the first declaration binds */
        if (!frx_dtd_map_add(l->arena, is_pe ? &l->dtd->params : &l->dtd->general, &name, e))
            return frx_lex_nomem(l);
    }
    return 1;
}

/* <!NOTATION S Name S (ExternalID | PublicID) S? >; pos is past the keyword */
static int
frx_dtd_notation_decl(frx_lex *l, size_t at)
{
    frx_notation *n;
    frx_str name;
    size_t sys_at;
    if (!frx_dtd_need_s(l, "expected whitespace after NOTATION")) return 0;
    if (!frx_lex_name(l, 0, &name)) return 0;
    if (!frx_dtd_need_s(l, "expected whitespace after the notation name")) return 0;
    n = (frx_notation *)frx_arena_alloc(l->arena, sizeof *n);
    if (!n) return frx_lex_nomem(l);
    n->name   = name;
    n->offset = FRX_LEX_ABS(l, at);
    if (!frx_dtd_external_id(l, &n->public_id, &n->system_id, 1, &sys_at)) return 0;
    if (!frx_dtd_close(l, at, "unterminated NOTATION declaration")) return 0;
    if (!frx_dtd_map_find(&l->dtd->notations, &name)) {
        if (!frx_dtd_map_add(l->arena, &l->dtd->notations, &name, n)) return frx_lex_nomem(l);
    }
    return 1;
}

/* <![ S? INCLUDE S? [ ... ]]> opens a section the loop keeps reading;
 * <![ S? IGNORE S? [ ... ]]> is skipped here with its nested sections.
 * pos is past the <![. External markup only. */
static int
frx_dtd_conditional(frx_lex *l, size_t at)
{
    size_t had;
    int include;
    int open_frame = l->decl_seq;       /* the text the <![ stood in */
    if (!frx_dtd_ws(l, &had)) return 0;
    if (frx_dtd_word(l, "INCLUDE"))     include = 1;
    else if (frx_dtd_word(l, "IGNORE")) include = 0;
    else return FRX_LEX_FAIL(l, FRX_E_DTD, l->pos, "expected INCLUDE or IGNORE in a conditional section");
    if (!frx_dtd_ws(l, &had)) return 0;
    if (l->pos >= l->len || l->in[l->pos] != '[')
        return FRX_LEX_FAIL(l, FRX_E_DTD, l->pos, "expected [ after INCLUDE or IGNORE");
    /* VC: Proper Conditional Section/PE Nesting */
    if (frx_dtd_cur_seq(l) != open_frame) frx_dtd_pe_nest(l, at);
    l->pos++;
    if (include) {
        if (l->cond_depth == l->cond_cap) {
            int ncap = l->cond_cap ? l->cond_cap * 2 : 16;
            int *nc = (int *)realloc(l->cond_frame, (size_t)ncap * sizeof *nc);
            if (!nc) return frx_lex_nomem(l);
            l->cond_frame = nc;
            l->cond_cap   = ncap;
        }
        l->cond_frame[l->cond_depth++] = open_frame;
        return 1;
    }
    {
        int depth = 1;
        while (depth) {
            if (l->pos >= l->len)
                return FRX_LEX_FAIL(l, FRX_E_DTD, at, "unterminated IGNORE section");
            if (frx_lex_starts(l, l->pos, "<![")) { depth++; l->pos += 3; continue; }
            if (frx_lex_starts(l, l->pos, "]]>")) { depth--; l->pos += 3; continue; }
            l->pos++;
        }
    }
    return 1;
}

/* the subset loop: the internal subset from past the [ to its ] (with
 * *close its frame-relative offset), or, with external set, the fetched
 * text of the external subset from its first byte to its end. A frame
 * that ends between declarations is popped; a declaration's own frames
 * are the declaration parser's business. */
static int
frx_dtd_subset(frx_lex *l, size_t open, size_t *close, int external)
{
    int frame0 = l->n_frames;
    frx_tok scratch;
    l->in_subset = 1;
    for (;;) {
        unsigned char c;
        size_t at;
        if (l->pos >= l->len) {
            if (l->n_frames > frame0) { if (!frx_entity_pop(l)) return 0; continue; }
            if (external) break;
            return FRX_LEX_FAIL(l, FRX_E_DTD, open, "unterminated internal subset");
        }
        c = l->in[l->pos];
        if (!external && c == ']' && l->n_frames == frame0) { *close = l->pos; l->pos++; break; }
        if (frx_lex_skip_s(l)) continue;
        at = l->pos;
        l->decl_frame0 = l->n_frames;
        l->decl_seq    = frx_dtd_cur_seq(l);
        if (c == '%') {
            l->pos++;
            if (!frx_entity_pe_reference(l, at, 1)) return 0;
            continue;
        }
        if (frx_lex_starts(l, at, "<!--")) {
            l->tok_start = at;
            l->pos += 4;
            if (!frx_lex_comment(l, &scratch)) return 0;
            continue;
        }
        if (frx_lex_starts(l, at, "<?")) {
            l->tok_start = at;
            l->pos += 2;
            if (!frx_lex_pi(l, &scratch)) return 0;
            continue;
        }
        if (frx_lex_starts(l, at, "<!ELEMENT"))  { l->pos += 9;  if (!frx_dtd_element_decl(l, at))  return 0; continue; }
        if (frx_lex_starts(l, at, "<!ATTLIST"))  { l->pos += 9;  if (!frx_dtd_attlist_decl(l, at))  return 0; continue; }
        if (frx_lex_starts(l, at, "<!ENTITY"))   { l->pos += 8;  if (!frx_dtd_entity_decl(l, at))   return 0; continue; }
        if (frx_lex_starts(l, at, "<!NOTATION")) { l->pos += 10; if (!frx_dtd_notation_decl(l, at)) return 0; continue; }
        if (frx_lex_starts(l, at, "<![")) {
            if (!l->ext_decl)
                return FRX_LEX_FAIL(l, FRX_E_DTD, at, "a conditional section is allowed only in the external subset");
            l->pos += 3;
            if (!frx_dtd_conditional(l, at)) return 0;
            continue;
        }
        if (l->ext_decl && frx_lex_starts(l, at, "]]>")) {
            if (!l->cond_depth)
                return FRX_LEX_FAIL(l, FRX_E_DTD, at, "]]> outside a conditional section");
            l->cond_depth--;
            if (frx_dtd_cur_seq(l) != l->cond_frame[l->cond_depth]) frx_dtd_pe_nest(l, at);
            l->pos += 3;
            continue;
        }
        if (c == ']')
            return FRX_LEX_FAIL(l, FRX_E_DTD, at, external ? "] is not allowed in the external subset"
                                                          : "a parameter entity's text must not close the internal subset");
        return FRX_LEX_FAIL(l, FRX_E_DTD, at, "expected a markup declaration in the internal subset");
    }
    if (external && l->cond_depth)
        return FRX_LEX_FAIL(l, FRX_E_DTD, open, "unterminated INCLUDE section");
    l->in_subset = 0;
    return 1;
}

/* the external subset: fetched through the resolver, read as external
 * markup after the internal subset. sys_at is the system literal's
 * frame-relative offset, which every refusal inside the subset reports. */
static int
frx_dtd_load_external(frx_lex *l, frx_doctype *dt, size_t sys_at)
{
    frx_str text, uri;
    size_t close = 0;
    int version11 = 0;
    if (!l->resolve)
        return FRX_LEX_FAIL(l, FRX_E_DTD, sys_at,
                            "the external subset cannot be read without a resolver; the resolve option arrives with external entities");
    if (!frx_entity_fetch(l, FRX_REF_SUBSET, &dt->public_id, &dt->system_id, &l->cur_base, sys_at,
                          &text, &uri, &version11)) return 0;
    if (version11 && !l->version11)
        return FRX_LEX_FAIL(l, FRX_E_ENTITY, sys_at,
                            "an XML 1.1 external subset cannot be used by an XML 1.0 document (section 4.3.4)");
    if (!frx_entity_push_text(l, NULL, &text, sys_at, 1, FRX_LEX_ABS(l, sys_at), &uri, 1)) return 0;
    if (!frx_dtd_subset(l, 0, &close, 1)) return 0;
    if (!frx_entity_pop(l)) return 0;
    l->dtd->external_read = 1;
    return 1;
}

/* <!DOCTYPE S Name (S ExternalID)? S? ([ intSubset ] S?)? >; pos is at
 * the <. One per document, before the root: no frame can be open here
 * because entities exist only after it, so every offset is a document
 * offset. The external subset, when there is one, is read after the
 * internal subset and before the >. */
static int frx_dtd_doctype_body(frx_lex *l, frx_tok *t);

/* the DTD's strings outlive any record a reader releases, so they go to
 * the persistent arena whatever the token arena is at the time */
static int
frx_dtd_doctype(frx_lex *l, frx_tok *t)
{
    frx_arena *saved = l->tok_arena;
    int ok;
    l->tok_arena = l->arena;
    ok = frx_dtd_doctype_body(l, t);
    l->tok_arena = saved;
    return ok;
}

static int
frx_dtd_doctype_body(frx_lex *l, frx_tok *t)
{
    size_t at = l->pos;
    size_t sys_at = 0;
    frx_doctype *dt;
    if (l->dtd || l->n_frames)
        return FRX_LEX_FAIL(l, FRX_E_DTD, at, "a document has one DOCTYPE, before the root element");
    l->pos += 9;
    if (!frx_lex_skip_s(l))
        return FRX_LEX_FAIL(l, FRX_E_DTD, l->pos, "expected whitespace after DOCTYPE");
    dt = (frx_doctype *)frx_arena_alloc(l->arena, sizeof *dt);
    if (!dt) return frx_lex_nomem(l);
    memset(dt, 0, sizeof *dt);
    dt->public_id = dt->system_id = dt->subset = FRX_EMPTY_STR;
    dt->offset = at;
    if (!frx_lex_name(l, 1, &dt->name)) return 0;
    l->dtd = frx_dtd_new(l->arena);
    if (!l->dtd) return frx_lex_nomem(l);
    l->decl_frame0 = 0;
    frx_lex_skip_s(l);
    if (l->pos < l->len && (l->in[l->pos] == 'S' || l->in[l->pos] == 'P')) {
        if (!frx_dtd_external_id(l, &dt->public_id, &dt->system_id, 0, &sys_at)) return 0;
        l->dtd->external_subset = 1;
        frx_lex_skip_s(l);
    }
    if (l->pos < l->len && l->in[l->pos] == '[') {
        size_t open = l->pos, close = 0;
        l->pos++;
        if (!frx_dtd_subset(l, open, &close, 0)) return 0;
        dt->subset = frx_arena_strndup(l->arena, (const char *)(l->in + open + 1), close - open - 1);
        if (!dt->subset.p) return frx_lex_nomem(l);
        dt->has_subset = 1;
        frx_lex_skip_s(l);
    }
    if (l->dtd->external_subset) {
        l->doctype = dt;
        if (!frx_dtd_load_external(l, dt, sys_at)) return 0;
    }
    if (l->pos >= l->len || l->in[l->pos] != '>')
        return FRX_LEX_FAIL(l, FRX_E_DTD, at, "unterminated DOCTYPE");
    l->pos++;
    l->doctype = dt;
    t->kind = FRX_TOK_DOCTYPE;
    t->name = dt->name;
    return 1;
}

#endif /* FRX_DTD_H */
