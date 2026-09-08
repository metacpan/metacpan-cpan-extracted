#ifndef FRX_LEX_H
#define FRX_LEX_H

/* Bytes in, tokens out, every refusal with an offset.
 *
 * This is the whole of the attacker-facing surface: everything after it
 * operates on validated names and decoded strings already in the arena. A
 * pull tokeniser rather than a lexer folded into the parser, so that every
 * refusal is testable through the _lex accessor without a tree, and so that
 * the every-offset test can hit the lexer alone.
 *
 * What it accepts: XML 1.0 with the five predefined entities and numeric
 * character references, in UTF-8. What it refuses, each with the offset it
 * was found at: any DOCTYPE (and any <! that is not a comment or CDATA -
 * one rule removes entity expansion, external entities, the billion laughs
 * and XXE as a class, with no option to allow them); UTF-16 and UTF-32 by
 * BOM or by first pair; a declared encoding other than utf-8; version 1.1;
 * a <?xml declaration anywhere but offset 0; a named reference other than
 * the five; a reference to a non-Char; ]]> in content; a literal < in an
 * attribute value; -- inside a comment; a PI whose target is xml in any
 * case; a Name that is not a QName (at most one colon, both parts
 * non-empty); anything not well-formed.
 *
 * Normalisation, in this order and with this word: line ends first (XML
 * 1.0 section 2.11, CRLF and CR become LF, in text and in attribute
 * values), then attribute values (section 3.3.3: with no DTD every
 * attribute is CDATA, so each LITERAL TAB, LF or CR becomes a space). A
 * character reference to one of those - &#x9; &#xA; &#xD; - stays the
 * character. Canonical XML escapes TAB, LF and CR in attribute values, and
 * the only way such a character reaches the serialiser is through a
 * reference, because the literal form was already a space. A lexer that
 * normalises after expanding references produces canonical bytes that
 * differ from every other implementation's.
 *
 * Every string a token carries is in the arena, NUL-terminated. CDATA is a
 * TEXT token with the cdata flag, so the parser can merge it with its
 * neighbours; there is no CDATA node kind. The attribute list of a START or
 * EMPTY token is borrowed from the lexer's scratch and valid until the next
 * frx_lex_next.
 *
 * THE FULL PROFILE reads a DOCTYPE and expands the internal subset's
 * entities. An entity is an input frame, not a string substitution: the
 * lexer's in/len/pos describe the frame being read, a reference saves them
 * and points them at the replacement text, and reaching the end of that
 * text restores them. Every token-level function reads through in/len/pos
 * unchanged; the frame boundary is the one place the rules of section 4.4
 * are enforced (an element, comment, PI, CDATA section or attribute value
 * that opened inside a frame must close inside it; an end tag inside a
 * frame must close an element opened inside it), and that is the whole of
 * the well-formedness of a parsed entity. Offsets: `base` is the document
 * offset the current frame's byte 0 corresponds to, 0 for the document
 * itself and the entity literal's first byte otherwise, so a refusal
 * inside an entity points into its declaration; FRX_LEX_FAIL takes a
 * frame-relative offset and adds base, FRX_LEX_FAIL_ABS takes a document
 * offset. Attribute types come from the DTD before an element is lexed
 * (the DTD is complete before the root starts), which is what lets the
 * 3.3.3 normalisation by type happen here, in the one place the literal
 * whitespace rule already lives. The declaration parser is frx_dtd.h and
 * the frame stack's push, pop and budgets are frx_entity.h; both need this
 * file's primitives, so they follow it and are declared below.
 *
 * Needs frx_err.h, frx_arena.h, frx_buf.h, frx_utf8.h, frx_enc.h,
 * frx_tree.h. */

typedef struct frx_eldecl  frx_eldecl;   /* frx_dtd.h; frx_dtd and frx_doctype are frx_tree.h's */
typedef struct frx_attdef  frx_attdef;   /* frx_dtd.h */
typedef struct frx_entity  frx_entity;   /* frx_dtd.h */

/* what an entity reference saves: the frame it interrupted */
typedef struct frx_frame_in {
    const unsigned char *in;        /* the interrupted frame's bytes */
    size_t      len, pos, base;
    frx_str     cur_base;           /* its base URI */
    int         flat;               /* its offsets were flat */
    int         ext_decl;           /* it allowed PE references inside declarations */
    int         in_dtd;             /* it was inside a parameter entity or the external subset */
    frx_entity *entity;             /* the entity whose text is now current; NULL for fetched text with none */
    int         depth_at_push;      /* open elements when pushed; must match at pop */
    int         seq;                /* which replacement text this is: unique for the parse, so
                                     * that two references to different entities at one depth
                                     * are told apart (VC: Proper Declaration/PE Nesting) */
    size_t      ref_offset;         /* document offset of the reference, for messages */
} frx_frame_in;

/* the per-parse cache of fetched text, keyed by resolved identifier */
typedef struct frx_fetch_entry {
    frx_str uri;
    frx_str text;                   /* UTF-8, the text declaration stripped, in the arena */
    int     version11;
    struct frx_fetch_entry *next;
} frx_fetch_entry;

#define FRX_DEFAULT_MAX_FETCHES 32

#define FRX_DEFAULT_MAX_ENTITY_DEPTH     16
#define FRX_DEFAULT_MAX_EXPANSION_BYTES  (16u * 1024u * 1024u)
#define FRX_DEFAULT_MAX_EXPANSION_RATIO  100

enum {
    FRX_TOK_EOF = 0,
    FRX_TOK_START,      /* <name attrs>      */
    FRX_TOK_END,        /* </name>           */
    FRX_TOK_EMPTY,      /* <name attrs/>     */
    FRX_TOK_TEXT,       /* character data, or CDATA with cdata set */
    FRX_TOK_COMMENT,    /* <!-- value -->    */
    FRX_TOK_PI,         /* <?name value?>    */
    FRX_TOK_DOCTYPE,    /* full: <!DOCTYPE ...>, its subset already read into l->dtd */
    FRX_TOK_MORE        /* the input ended inside a token and eof is not set: feed more and call again */
};

#define FRX_DEFAULT_MAX_TOKEN_BYTES (16u * 1024u * 1024u)

typedef struct frx_lex_attr {
    frx_str name;
    frx_str value;
    size_t  offset;                 /* document offset; a default's is its declaration's */
    int     defaulted;              /* full: from an ATTLIST default, not written */
} frx_lex_attr;

typedef struct frx_tok {
    int     kind;
    size_t  offset;
    frx_str name;                   /* START/END/EMPTY: the qname; PI: the target */
    frx_str value;                  /* TEXT, COMMENT: the body; PI: the data */
    int     cdata;                  /* TEXT from a CDATA section */
    int     text_flags;             /* TEXT: FRX_TEXT_REF_* below */
    const frx_lex_attr *attrs;      /* START/EMPTY; borrowed until the next call */
    int     n_attrs;
    frx_str entity;                 /* the entity whose text the token came from; "" for the document */
} frx_tok;

typedef struct frx_lex {
    const unsigned char *in;
    size_t   len;
    size_t   pos;
    frx_arena *arena;
    frx_err  err;
    int      failed;
    int      profile;               /* FRX_PROFILE_*; read here and in frx_parse.h, nowhere else */
    int      version11;             /* full: the declaration said 1.1; 2.11 line ends and RestrictedChar apply */
    frx_str  version;               /* the declared version string; empty when there was no declaration */
    int      enc_kind;              /* full: what frx_enc.h detected, FRX_ENC_* */
    int      enc_bom;               /* full: a byte order mark was present */
    int      enc_override;          /* full: the caller named the encoding; the declaration is not judged */
    int      standalone;            /* the declaration said standalone="yes" */
    frx_lex_attr *attrs;            /* scratch, grows with realloc */
    int      n_attrs;
    int      cap_attrs;
    frx_buf  tmp;                   /* decoding scratch */

    /* the full profile: the DTD and the entity frames */
    frx_dtd     *dtd;               /* what the DOCTYPE declared; NULL without one */
    frx_doctype *doctype;           /* the DOCTYPE's names and subset text; NULL without one */
    frx_frame_in *frames;           /* the interrupted frames, malloc'd; the document is below them all */
    int      n_frames;
    int      cap_frames;
    size_t   base;                  /* document offset of the current frame's byte 0 */
    size_t   tok_start;             /* frame-relative start of the token being lexed */
    int      tag_depth;             /* START tokens minus END tokens so far */
    int      in_subset;             /* lexing the internal subset */
    size_t   doc_len;               /* the document's bytes, for the ratio budget */
    size_t   pushed;                /* replacement bytes pushed so far, every frame counted */
    size_t   max_expansion_bytes;
    int      max_entity_depth;
    int      max_expansion_ratio;
    int     *cm_stack;              /* content model group stack, malloc'd; frx_dtd.h */
    int     *cm_frame;              /* and the entity frame each of those groups opened in */
    int      cm_cap;
    int     *cond_frame;            /* the frame each open conditional section opened in */
    int      cond_cap;
    int      frame_seq;             /* the last serial handed to a frame */
    int      decl_seq;              /* the replacement text the current declaration began in */
    int      decl_frame0;           /* frames open when the current declaration began */
    int      cond_depth;            /* open INCLUDE sections of the external subset */
    int      last_collapse_changed; /* the last typed attribute value was changed by 3.3.3 */

    /* the full profile: fetching. A fetched frame is "flat":
     * its bytes are not in the document, so every offset inside it
     * reports the reference that pulled it in. */
    frx_resolve_fn resolve;         /* NULL: every external reference is refused */
    void    *resolve_ud;
    int      max_fetches;
    int      n_fetches;
    size_t   max_bytes;             /* applied to each fetched text */
    int      validate;              /* the standalone validity constraints are applied */
    frx_str  cur_base;              /* base URI of the current frame; "" when none */
    int      flat;                  /* current frame is fetched text */
    int      ext_decl;              /* current frame is external markup: PE references inside declarations */
    int      in_dtd;                /* current frame is inside a parameter entity or the external subset */
    frx_fetch_entry *fetches;       /* the cache, in the arena */

    /* streaming: with eof clear, the document's bytes may grow.
     * A token the input ends inside is not an error but FRX_TOK_MORE: the
     * lexer rewinds to its start and the caller feeds more and calls
     * again. Token strings go to tok_arena, which a reader may release
     * between records; the DTD and the entities stay in arena. */
    /* WFC: Entity Declared exempts an undeclared general entity when the
     * processor may not have seen every declaration - there is an external
     * subset, or the internal subset made a parameter entity reference -
     * and the document is not standalone. The reference is then not a
     * well-formedness error but a validity error, so it produces nothing
     * and its offset is kept here for the validate pass. */
    size_t  *undecl;                /* offsets, in document order; malloc'd */
    int      n_undecl, cap_undecl;

    int      eof;                   /* the input is complete */
    int      need_more;             /* set by a token function that ran out of input */
    int      prolog_done;
    size_t   prolog_max_bytes;      /* the max_bytes the prolog applies */
    size_t   max_token_bytes;       /* a token longer than this is refused, not retried */
    frx_arena *tok_arena;           /* where token strings go; arena unless a reader says otherwise */
} frx_lex;

/* a frame-relative offset as a document offset */
#define FRX_LEX_ABS(l, off) ((l)->flat ? (l)->base : (l)->base + (off))

#define FRX_LEX_FAIL(l, c, off, what) \
    (frx_err_set(&(l)->err, (c), FRX_LEX_ABS((l), (off)), (what)), (l)->failed = 1, 0)
#define FRX_LEX_FAIL_ABS(l, c, off, what) \
    (frx_err_set(&(l)->err, (c), (off), (what)), (l)->failed = 1, 0)
/* the input ended inside a token: a refusal when it is complete, a
 * request for more bytes when the document itself may still grow */
#define FRX_LEX_NEED(l, c, off, what) \
    ((!(l)->eof && (l)->n_frames == 0) ? ((l)->need_more = 1, 0) : FRX_LEX_FAIL((l), (c), (off), (what)))

/* defined in frx_dtd.h and frx_entity.h, which need the primitives here */
static int frx_dtd_doctype(frx_lex *l, frx_tok *t);
static const frx_eldecl *frx_dtd_element(const frx_dtd *dtd, const frx_str *name);
static const frx_attdef *frx_dtd_attdef(const frx_eldecl *ed, const frx_str *name);
static int frx_dtd_attdef_collapses(const frx_attdef *ad);
static int frx_dtd_attdef_external(const frx_attdef *ad);
static int frx_dtd_apply_defaults(frx_lex *l, const frx_eldecl *ed);
static int frx_entity_reference(frx_lex *l, size_t start, int in_attr);
static int frx_entity_pop(frx_lex *l);
static const frx_str *frx_entity_name_of(const frx_entity *e);

static int
frx_lex_nomem(frx_lex *l)
{
    return FRX_LEX_FAIL(l, FRX_E_NOMEM, l->pos, "out of memory");
}

/* n bytes of s into the token arena; 0 on failure */
static int
frx_lex_intern(frx_lex *l, const unsigned char *s, size_t n, frx_str *out)
{
    *out = frx_arena_strndup(l->tok_arena, (const char *)s, n);
    return out->p ? 1 : frx_lex_nomem(l);
}

static int
frx_lex_intern_buf(frx_lex *l, frx_str *out)
{
    if (l->tmp.failed) return frx_lex_nomem(l);
    return frx_lex_intern(l, (const unsigned char *)(l->tmp.p ? l->tmp.p : ""),
                          l->tmp.len, out);
}

static int
frx_lex_starts(const frx_lex *l, size_t at, const char *lit)
{
    size_t n = strlen(lit);
    return l->len - at >= n && memcmp(l->in + at, lit, n) == 0;
}

/* the input ends inside lit: what is there is a proper prefix of it */
static int
frx_lex_short(const frx_lex *l, size_t at, const char *lit)
{
    size_t n = strlen(lit), have = l->len - at;
    return have < n && memcmp(l->in + at, lit, have) == 0;
}

/* XML 1.1 section 2.11: is a NEL (C2 85) or an LS (E2 80 A8) at pos?
 * Returns its byte length, 0 when neither. */
static size_t
frx_lex_nel_or_ls(const frx_lex *l, size_t pos)
{
    if (l->len - pos >= 2 && l->in[pos] == 0xC2 && l->in[pos + 1] == 0x85) return 2;
    if (l->len - pos >= 3 && l->in[pos] == 0xE2 && l->in[pos + 1] == 0x80 && l->in[pos + 2] == 0xA8) return 3;
    return 0;
}

/* S; under XML 1.1 a NEL or LS is a line end wherever it stands (section
 * 2.11 normalises before parsing), so between attributes and between
 * declarations it is whitespace too */
static size_t
frx_lex_skip_s(frx_lex *l)
{
    size_t start = l->pos;
    for (;;) {
        size_t n;
        if (l->pos >= l->len) break;
        if (frx_is_s(l->in[l->pos])) { l->pos++; continue; }
        if (l->version11 && (n = frx_lex_nel_or_ls(l, l->pos)) != 0) { l->pos += n; continue; }
        break;
    }
    return l->pos - start;
}

/* does the input end inside what may be a UTF-8 sequence, with more to come? */
static int
frx_lex_utf8_cut(const frx_lex *l)
{
    unsigned char c = l->in[l->pos];
    return !l->eof && !l->n_frames && l->len - l->pos < 4 && c >= 0xC2 && c <= 0xF4;
}

/* One character of content at pos: validated as UTF-8 and as Char,
 * appended to tmp with line ends normalised. Returns 0 on refusal.
 *
 * Under XML 1.1 (full profile, a 1.1 declaration) section 2.11 also turns
 * NEL, CR NEL and LS into LF, and production [1] refuses a literal
 * RestrictedChar. The 1.0 path is 0.01's, untouched.
 *
 * Inside an entity frame the LINE ENDS do not apply: the entity's literal
 * was normalised when it was declared, so a CR, NEL or LS in its
 * replacement text came from a character reference and is the character,
 * as it would be written in content by reference. Section 3.3.3's table
 * (two entities of &#xD; and &#xA; giving two spaces, not one) is the
 * case that tells the two apart.
 *
 * RESTRICTED CHARACTERS APPLY IN AN EXTERNAL FRAME AND NOT AN INTERNAL
 * ONE, which is the grammar and not a guess. Two productions subtract
 * them, and only two:
 *
 *   [1]  document     ::= ( prolog element Misc* ) - ( Char* RestrictedChar Char* )
 *   [78] extParsedEnt ::= ( TextDecl? content )   - ( Char* RestrictedChar Char* )
 *
 * so the document entity and an external parsed entity are subject to it
 * and an internal entity's replacement text is subject to nothing: a
 * character reference in an entity's literal, which 4.4.5 Included in
 * Literal expanded when the entity was declared, may put a restricted
 * character into content. eduni rmt-054 is that case and the suite marks
 * it valid, saying in its own comment that the CR grammar made it illegal
 * and "this is probably not intended". IBM's ibm02n13 is the same
 * construct marked not-wf; it was written against that draft and the
 * Recommendation contradicts it. t/xmlconf/expected-fail.txt carries it.
 *
 * The version that decides is the DOCUMENT's, never the frame's, because
 * 4.3.4 says an XML 1.1 document may invoke XML 1.0 external entities
 * and "in such a case the rules of XML 1.1 are applied to the entire
 * document". So a version='1.0' external entity, whose own version admits
 * #x7F to #x9F as ordinary characters, may not carry one into a 1.1
 * document. l->flat is the discriminator: it is set from the entity's own
 * external-ness as each frame is pushed.
 *
 * The line ends do not conflict with any of this: none of CR, NEL and LS
 * is a RestrictedChar. */
static int
frx_lex_char(frx_lex *l)
{
    unsigned char c = l->in[l->pos];
    if (l->n_frames) {
        if (c < 0x80) {
            if (c == 0) return FRX_LEX_FAIL(l, FRX_E_UTF8, l->pos, "control character is not allowed");
            if (l->version11 && l->flat && frx_is_restricted11(c))
                return FRX_LEX_FAIL(l, FRX_E_UTF8, l->pos, "a restricted character may appear only as a character reference in XML 1.1");
            frx_buf_append_ch(&l->tmp, (char)c);
            l->pos++;
            return 1;
        } else {
            unsigned long cp;
            size_t n = frx_utf8_decode(l->in + l->pos, l->len - l->pos, &cp);
            if (!n) return FRX_LEX_FAIL(l, FRX_E_UTF8, l->pos, "not UTF-8");
            if (l->version11 && l->flat && frx_is_restricted11(cp))
                return FRX_LEX_FAIL(l, FRX_E_UTF8, l->pos, "a restricted character may appear only as a character reference in XML 1.1");
            frx_buf_append_n(&l->tmp, (const char *)(l->in + l->pos), n);
            l->pos += n;
            return 1;
        }
    }
    if (l->version11) {
        size_t n;
        if (c == '\r') {
            frx_buf_append_ch(&l->tmp, '\n');
            l->pos++;
            if (l->pos < l->len && l->in[l->pos] == '\n') l->pos++;
            else if ((n = frx_lex_nel_or_ls(l, l->pos)) == 2) l->pos += 2;   /* CR NEL */
            return 1;
        }
        if ((n = frx_lex_nel_or_ls(l, l->pos)) != 0) {
            frx_buf_append_ch(&l->tmp, '\n');
            l->pos += n;
            return 1;
        }
        if (c < 0x80) {
            if (frx_is_restricted11(c))
                return FRX_LEX_FAIL(l, FRX_E_UTF8, l->pos, "a restricted character may appear only as a character reference in XML 1.1");
            if (c == 0)
                return FRX_LEX_FAIL(l, FRX_E_UTF8, l->pos, "control character is not allowed");
            frx_buf_append_ch(&l->tmp, (char)c);
            l->pos++;
            return 1;
        } else {
            unsigned long cp;
            n = frx_utf8_decode(l->in + l->pos, l->len - l->pos, &cp);
            if (!n) { if (frx_lex_utf8_cut(l)) { l->need_more = 1; return 0; } return FRX_LEX_FAIL(l, FRX_E_UTF8, l->pos, "not UTF-8"); }
            if (frx_is_restricted11(cp))
                return FRX_LEX_FAIL(l, FRX_E_UTF8, l->pos, "a restricted character may appear only as a character reference in XML 1.1");
            if (!frx_is_char11(cp)) return FRX_LEX_FAIL(l, FRX_E_UTF8, l->pos, "not an XML character");
            frx_buf_append_n(&l->tmp, (const char *)(l->in + l->pos), n);
            l->pos += n;
            return 1;
        }
    }
    if (c < 0x80) {
        if (c == '\r') {
            frx_buf_append_ch(&l->tmp, '\n');
            l->pos++;
            if (l->pos < l->len && l->in[l->pos] == '\n') l->pos++;
            return 1;
        }
        if (c < 0x20 && c != '\t' && c != '\n')
            return FRX_LEX_FAIL(l, FRX_E_UTF8, l->pos, "control character is not allowed");
        frx_buf_append_ch(&l->tmp, (char)c);
        l->pos++;
        return 1;
    } else {
        unsigned long cp;
        size_t n = frx_utf8_decode(l->in + l->pos, l->len - l->pos, &cp);
        if (!n) { if (frx_lex_utf8_cut(l)) { l->need_more = 1; return 0; } return FRX_LEX_FAIL(l, FRX_E_UTF8, l->pos, "not UTF-8"); }
        if (!frx_is_char(cp)) return FRX_LEX_FAIL(l, FRX_E_UTF8, l->pos, "not an XML character");
        frx_buf_append_n(&l->tmp, (const char *)(l->in + l->pos), n);
        l->pos += n;
        return 1;
    }
}

/* A reference at pos (the &): the five entities, &#N; and &#xN;, and under
 * the full profile a declared general entity, whose replacement text
 * becomes the current frame (frx_entity.h) for the caller to read on
 * through. A character's bytes go to tmp as UTF-8. Returns 0 on refusal.
 * in_attr says the reference stands in an attribute value, where an
 * external entity is refused outright (WFC: No External Entity References). */
static int
frx_lex_ref(frx_lex *l, int in_attr)
{
    size_t start = l->pos;
    size_t i = start + 1;
    unsigned long cp = 0;
    unsigned char enc[4];
    size_t n;

    if (i < l->len && l->in[i] == '#') {
        int hex = 0, any = 0;
        i++;
        if (i < l->len && l->in[i] == 'x') { hex = 1; i++; }
        for (; i < l->len; i++) {
            unsigned char c = l->in[i];
            unsigned d;
            if (c >= '0' && c <= '9') d = c - '0';
            else if (hex && c >= 'a' && c <= 'f') d = c - 'a' + 10;
            else if (hex && c >= 'A' && c <= 'F') d = c - 'A' + 10;
            else break;
            cp = cp * (hex ? 16 : 10) + d;
            if (cp > 0x10FFFF) cp = 0x110000;             /* clamp; refused below */
            any = 1;
        }
        if (i >= l->len)
            return FRX_LEX_NEED(l, FRX_E_REFERENCE, start, "malformed character reference");
        if (!any || l->in[i] != ';')
            return FRX_LEX_FAIL(l, FRX_E_REFERENCE, start, "malformed character reference");
        /* 1.1's Char admits the restricted characters by reference; #x0 is
         * a Char in neither version */
        if (l->version11 ? !frx_is_char11(cp) : !frx_is_char(cp))
            return FRX_LEX_FAIL(l, FRX_E_REFERENCE, start, "character reference to a non-XML character");
        l->pos = i + 1;
    } else {
        static const struct { const char *name; size_t n; unsigned long cp; } ent[] = {
            { "lt;", 3, '<' }, { "gt;", 3, '>' }, { "amp;", 4, '&' },
            { "apos;", 5, '\'' }, { "quot;", 5, '"' }
        };
        size_t k;
        for (k = 0; k < sizeof ent / sizeof ent[0]; k++) {
            if (frx_lex_starts(l, i, ent[k].name)) {
                cp = ent[k].cp;
                l->pos = i + ent[k].n;
                break;
            }
        }
        if (k == sizeof ent / sizeof ent[0]) {
            if (!l->eof && !l->n_frames) {
                for (k = 0; k < sizeof ent / sizeof ent[0]; k++)
                    if (frx_lex_short(l, i, ent[k].name)) { l->need_more = 1; return 0; }
            }
            if (l->profile == FRX_PROFILE_FULL)
                return frx_entity_reference(l, start, in_attr);
            return FRX_LEX_FAIL(l, FRX_E_REFERENCE, start,
                                "undeclared entity (no DOCTYPE is accepted, so only the five predefined exist)");
        }
    }
    n = frx_utf8_encode(cp, enc);
    frx_buf_append_n(&l->tmp, (const char *)enc, n);
    return 1;
}

/* the frame the current one interrupted, or NULL at the document */
static const frx_frame_in *
frx_lex_top_frame(const frx_lex *l)
{
    return l->n_frames ? &l->frames[l->n_frames - 1] : NULL;
}

/* A Name at pos into the arena. With qname, the Namespaces rule: at most
 * one colon, neither part empty. */
static int
frx_lex_name(frx_lex *l, int qname, frx_str *out)
{
    size_t start = l->pos;
    size_t colons = 0;
    int first = 1;
    while (l->pos < l->len) {
        unsigned char c = l->in[l->pos];
        unsigned long cp;
        size_t n;
        if (c < 0x80) { cp = c; n = 1; }
        else {
            n = frx_utf8_decode(l->in + l->pos, l->len - l->pos, &cp);
            if (!n) { if (frx_lex_utf8_cut(l)) { l->need_more = 1; return 0; } return FRX_LEX_FAIL(l, FRX_E_UTF8, l->pos, "not UTF-8"); }
        }
        if (cp == ':') {
            if (!qname || first || colons)
                return FRX_LEX_FAIL(l, FRX_E_NAME, l->pos, "a name may carry one colon, with a part on each side");
            colons++;
            l->pos++;
            first = 1;                                     /* the local part must start a name too */
            continue;
        }
        if (first ? !frx_is_name_start(cp) : !frx_is_name_char(cp)) break;
        first = 0;
        l->pos += n;
    }
    if (l->pos >= l->len && !l->eof && !l->n_frames) { l->need_more = 1; return 0; }   /* it may go on */
    if (l->pos == start)
        return FRX_LEX_FAIL(l, FRX_E_NAME, start, "expected a name");
    if (first)                                             /* ended on a colon, or empty local part */
        return FRX_LEX_FAIL(l, FRX_E_NAME, start, "a name may carry one colon, with a part on each side");
    return frx_lex_intern(l, l->in + start, l->pos - start, out);
}

/* Section 3.3.3 for a type other than CDATA: leading and trailing spaces
 * (#x20 only) dropped, runs of them made one. tmp in place; returns
 * whether anything changed, which the standalone constraint asks. */
static int
frx_lex_collapse(frx_buf *b)
{
    size_t r, w = 0;
    int    pending = 0;
    if (!b->p) return 0;
    for (r = 0; r < b->len; r++) {
        if (b->p[r] == ' ') { pending = w > 0; continue; }
        if (pending) { b->p[w++] = ' '; pending = 0; }
        b->p[w++] = b->p[r];
    }
    if (w == b->len) return 0;
    b->len  = w;
    b->p[w] = '\0';
    return 1;
}

/* An attribute value at pos (the quote). Section 2.11 then 3.3.3, on
 * literal whitespace only; references exempt; a literal < refused. Under
 * the full profile an entity reference pushes a frame the loop reads on
 * through: its quote does not close the value (4.4.5, Included in
 * Literal), its < is refused (WFC: No < in Attribute Values), and it must
 * end before the value does. collapse is the further 3.3.3 rule for a
 * declared type other than CDATA. */
static int
frx_lex_attr_value(frx_lex *l, frx_str *out, int collapse)
{
    unsigned char q = l->in[l->pos];
    size_t start = l->pos;
    int    frame0 = l->n_frames;
    if (q != '"' && q != '\'')
        return FRX_LEX_FAIL(l, FRX_E_SYNTAX, l->pos, "expected a quoted attribute value");
    l->pos++;
    l->tmp.len = 0;
    for (;;) {
        unsigned char c;
        if (l->pos >= l->len) {
            if (l->n_frames > frame0) { if (!frx_entity_pop(l)) return 0; continue; }
            return FRX_LEX_NEED(l, FRX_E_SYNTAX, start, "unterminated attribute value");
        }
        c = l->in[l->pos];
        if (c == q && l->n_frames == frame0) { l->pos++; break; }
        if (c == '<')
            return FRX_LEX_FAIL(l, FRX_E_SYNTAX, l->pos,
                                l->n_frames > frame0
                                    ? "an entity referenced in an attribute value must not contain <"
                                    : "a literal < is not allowed in an attribute value");
        if (c == '&') { if (!frx_lex_ref(l, 1)) return 0; continue; }
        if (c == '\r') {                                   /* 2.11, then 3.3.3 */
            frx_buf_append_ch(&l->tmp, ' ');
            l->pos++;
            if (l->n_frames) continue;                     /* replacement text: each character one space */
            if (l->pos < l->len && l->in[l->pos] == '\n') l->pos++;
            else if (l->version11 && frx_lex_nel_or_ls(l, l->pos) == 2) l->pos += 2;   /* 1.1: CR NEL */
            continue;
        }
        if (c == '\n' || c == '\t') {                      /* 3.3.3 */
            frx_buf_append_ch(&l->tmp, ' ');
            l->pos++;
            continue;
        }
        if (l->version11 && !l->n_frames) {                /* 1.1: NEL and LS are line ends, so spaces */
            size_t n = frx_lex_nel_or_ls(l, l->pos);
            if (n) { frx_buf_append_ch(&l->tmp, ' '); l->pos += n; continue; }
        }
        if (!frx_lex_char(l)) return 0;
    }
    l->last_collapse_changed = collapse ? frx_lex_collapse(&l->tmp) : 0;
    return frx_lex_intern_buf(l, out);
}

/* offset is a document offset */
static int
frx_lex_push_attr(frx_lex *l, const frx_str *name, const frx_str *value, size_t offset, int defaulted)
{
    int i;
    for (i = 0; i < l->n_attrs; i++) {
        if (l->attrs[i].name.len == name->len
            && memcmp(l->attrs[i].name.p, name->p, name->len) == 0)
            return FRX_LEX_FAIL_ABS(l, FRX_E_DUP_ATTR, offset, "attribute given twice");
    }
    if (l->n_attrs == l->cap_attrs) {
        int ncap = l->cap_attrs ? l->cap_attrs * 2 : 8;
        frx_lex_attr *na = (frx_lex_attr *)realloc(l->attrs, (size_t)ncap * sizeof *na);
        if (!na) return frx_lex_nomem(l);
        l->attrs     = na;
        l->cap_attrs = ncap;
    }
    l->attrs[l->n_attrs].name      = *name;
    l->attrs[l->n_attrs].value     = *value;
    l->attrs[l->n_attrs].offset    = offset;
    l->attrs[l->n_attrs].defaulted = defaulted;
    l->n_attrs++;
    return 1;
}

/* <name attrs> or <name attrs/>; pos is just past the <. With a DTD, each
 * attribute's declared type selects the 3.3.3 normalisation before its
 * value is read, and the declared defaults the tag lacks are appended
 * after the written attributes, in declaration order. */
static int
frx_lex_start_tag(frx_lex *l, frx_tok *t)
{
    const frx_eldecl *ed;
    if (!frx_lex_name(l, 1, &t->name)) return 0;
    ed = l->dtd ? frx_dtd_element(l->dtd, &t->name) : NULL;
    l->n_attrs = 0;
    for (;;) {
        size_t had_s = frx_lex_skip_s(l);
        unsigned char c;
        if (l->pos >= l->len)
            return FRX_LEX_NEED(l, FRX_E_SYNTAX, l->tok_start, "unterminated start tag");
        c = l->in[l->pos];
        if (c == '>') { l->pos++; t->kind = FRX_TOK_START; break; }
        if (c == '/') {
            if (l->pos + 1 >= l->len)
                return FRX_LEX_NEED(l, FRX_E_SYNTAX, l->pos, "expected /> to close an empty element");
            if (l->in[l->pos + 1] != '>')
                return FRX_LEX_FAIL(l, FRX_E_SYNTAX, l->pos, "expected /> to close an empty element");
            l->pos += 2;
            t->kind = FRX_TOK_EMPTY;
            break;
        }
        if (!had_s)
            return FRX_LEX_FAIL(l, FRX_E_SYNTAX, l->pos, "expected whitespace before an attribute");
        {
            frx_str name, value;
            size_t at = l->pos;
            const frx_attdef *ad;
            if (!frx_lex_name(l, 1, &name)) return 0;
            ad = ed ? frx_dtd_attdef(ed, &name) : NULL;
            frx_lex_skip_s(l);
            if (l->pos >= l->len)
                return FRX_LEX_NEED(l, FRX_E_SYNTAX, l->pos, "expected = after an attribute name");
            if (l->in[l->pos] != '=')
                return FRX_LEX_FAIL(l, FRX_E_SYNTAX, l->pos, "expected = after an attribute name");
            l->pos++;
            frx_lex_skip_s(l);
            if (l->pos >= l->len)
                return FRX_LEX_NEED(l, FRX_E_SYNTAX, at, "unterminated attribute");
            if (!frx_lex_attr_value(l, &value, ad ? frx_dtd_attdef_collapses(ad) : 0)) return 0;
            if (ad && l->last_collapse_changed && l->standalone && l->validate && frx_dtd_attdef_external(ad))
                return FRX_LEX_FAIL(l, FRX_E_DTD, at,
                                    "standalone=\"yes\" but an attribute type declared in the external subset changed this value (VC: Standalone Document Declaration)");
            if (!frx_lex_push_attr(l, &name, &value, FRX_LEX_ABS(l, at), 0)) return 0;
        }
    }
    if (ed && !frx_dtd_apply_defaults(l, ed)) return 0;
    t->attrs   = l->attrs;
    t->n_attrs = l->n_attrs;
    return 1;
}

/* </name>; pos is just past the </ */
static int
frx_lex_end_tag(frx_lex *l, frx_tok *t)
{
    if (!frx_lex_name(l, 1, &t->name)) return 0;
    frx_lex_skip_s(l);
    if (l->pos >= l->len)
        return FRX_LEX_NEED(l, FRX_E_SYNTAX, l->tok_start, "unterminated end tag");
    if (l->in[l->pos] != '>')
        return FRX_LEX_FAIL(l, FRX_E_SYNTAX, l->tok_start, "unterminated end tag");
    l->pos++;
    t->kind = FRX_TOK_END;
    return 1;
}

/* content up to the terminator lit, validated and line-end normalised
 * into tmp; start is frame-relative; pos ends past lit. The end of the
 * frame is the end of the input here: a comment, PI or CDATA section that
 * opened inside an entity must close inside it. */
static int
frx_lex_run(frx_lex *l, const char *lit, size_t start, const char *unterminated,
            int comment)
{
    size_t n = strlen(lit);
    l->tmp.len = 0;
    for (;;) {
        if (l->pos >= l->len)
            return FRX_LEX_NEED(l, FRX_E_SYNTAX, start, unterminated);
        if (l->len - l->pos >= n && memcmp(l->in + l->pos, lit, n) == 0) {
            l->pos += n;
            return 1;
        }
        if (!l->eof && !l->n_frames && frx_lex_short(l, l->pos, lit)) {
            l->need_more = 1;                          /* the terminator may be cut */
            return 0;
        }
        if (comment && l->in[l->pos] == '-' && l->pos + 1 < l->len && l->in[l->pos + 1] == '-')
            return FRX_LEX_FAIL(l, FRX_E_SYNTAX, l->pos, "-- is not allowed inside a comment");
        if (!frx_lex_char(l)) return 0;
    }
}

/* <!-- ... -->; pos is just past the <!-- */
static int
frx_lex_comment(frx_lex *l, frx_tok *t)
{
    if (!frx_lex_run(l, "-->", l->tok_start, "unterminated comment", 1)) return 0;
    t->kind = FRX_TOK_COMMENT;
    return frx_lex_intern_buf(l, &t->value);
}

/* <![CDATA[ ... ]]>; pos is just past the <![CDATA[ */
static int
frx_lex_cdata(frx_lex *l, frx_tok *t)
{
    if (!frx_lex_run(l, "]]>", l->tok_start, "unterminated CDATA section", 0)) return 0;
    t->kind  = FRX_TOK_TEXT;
    t->cdata = 1;
    return frx_lex_intern_buf(l, &t->value);
}

static int
frx_lex_target_is_xml(const frx_str *s)
{
    return s->len == 3
        && (s->p[0] == 'x' || s->p[0] == 'X')
        && (s->p[1] == 'm' || s->p[1] == 'M')
        && (s->p[2] == 'l' || s->p[2] == 'L');
}

/* <?target data?>; pos is just past the <? */
static int
frx_lex_pi(frx_lex *l, frx_tok *t)
{
    size_t name_at = l->pos;
    if (!frx_lex_name(l, 0, &t->name)) return 0;
    if (frx_lex_target_is_xml(&t->name))
        return FRX_LEX_FAIL(l, FRX_E_SYNTAX, name_at,
                            "the xml processing instruction target is reserved (a declaration is accepted only at offset 0)");
    if (frx_lex_starts(l, l->pos, "?>")) {
        l->pos += 2;
        t->value.p   = "";
        t->value.len = 0;
        t->kind = FRX_TOK_PI;
        return 1;
    }
    if (l->pos >= l->len)
        return FRX_LEX_NEED(l, FRX_E_SYNTAX, l->pos, "unterminated processing instruction");
    if (!frx_lex_skip_s(l))
        return FRX_LEX_FAIL(l, FRX_E_SYNTAX, l->pos, "expected whitespace after a processing instruction target");
    if (!frx_lex_run(l, "?>", l->tok_start, "unterminated processing instruction", 0)) return 0;
    t->kind = FRX_TOK_PI;
    return frx_lex_intern_buf(l, &t->value);
}

/* character data up to the next < or the end of the frame; pos is at a
 * non-< byte. An entity reference switches frames mid-run and the loop
 * reads on; the frame's end ends the token, and the next call pops. */
static int
frx_lex_text(frx_lex *l, frx_tok *t)
{
    int frames0 = l->n_frames;
    l->tmp.len = 0;
    while (l->pos < l->len && l->in[l->pos] != '<') {
        unsigned char c = l->in[l->pos];
        if (c == '&') {
            /* outside the root only Misc may stand (section 2.1, [1] and
             * [27]): a reference there is not well-formed even when it
             * would produce whitespace or the root element itself */
            if (!l->tag_depth)
                return FRX_LEX_FAIL(l, FRX_E_SYNTAX, l->pos, "a reference is not allowed outside the root element");
            if (!frx_lex_ref(l, 0)) return 0;
            /* an entity's text is its own token: the boundary is what a
             * reader reports, and the tree merges the pieces anyway */
            if (l->n_frames > frames0) { t->text_flags |= FRX_TEXT_REF_HERE; break; }
            /* Second edition erratum E15: white space in element content
             * must be characters that stand in the document, not ones a
             * reference produced. This branch is a character or a
             * predefined-entity reference, which expands here rather than
             * pushing a frame, so its characters are not written directly. */
            t->text_flags |= FRX_TEXT_REF_CHARS | FRX_TEXT_REF_HERE;
            continue;
        }
        if (c == ']' && frx_lex_starts(l, l->pos, "]]>"))
            return FRX_LEX_FAIL(l, FRX_E_SYNTAX, l->pos, "]]> is not allowed in content");
        if (!frx_lex_char(l)) return 0;
    }
    /* a run the input ends inside may go on in the next chunk: one text
     * token per run, whatever the chunking, is what a reader promises */
    if (l->pos >= l->len && l->n_frames == frames0 && !l->eof && !l->n_frames) { l->need_more = 1; return 0; }
    t->kind = FRX_TOK_TEXT;
    return frx_lex_intern_buf(l, &t->value);
}

/* Is the DOCTYPE at pos complete in the input, its > found at bracket
 * depth zero outside quotes, comments and processing instructions? With
 * eof clear a DOCTYPE the input ends inside is FRX_TOK_MORE before its
 * parser runs, so that parser needs no retry logic of its own. */
static int
frx_lex_doctype_complete(const frx_lex *l)
{
    size_t i = l->pos;
    int depth = 0;
    char q = 0;
    while (i < l->len) {
        unsigned char c = l->in[i];
        if (q) { if (c == (unsigned char)q) q = 0; i++; continue; }
        if (c == '"' || c == '\'') { q = (char)c; i++; continue; }
        if (frx_lex_starts(l, i, "<!--")) {
            i += 4;
            while (i < l->len && !frx_lex_starts(l, i, "-->")) i++;
            if (i >= l->len) return 0;
            i += 3;
            continue;
        }
        if (frx_lex_starts(l, i, "<?")) {
            i += 2;
            while (i < l->len && !frx_lex_starts(l, i, "?>")) i++;
            if (i >= l->len) return 0;
            i += 2;
            continue;
        }
        if (c == '[') depth++;
        else if (c == ']') { if (depth) depth--; }
        else if (c == '>' && depth == 0) return 1;
        i++;
    }
    return 0;
}

/* a pseudo-attribute of the XML declaration: name S? = S? quoted; the
 * value is returned as a slice of the input */
static int
frx_lex_pseudo(frx_lex *l, const char *name, const unsigned char **v, size_t *vlen)
{
    unsigned char q;
    size_t start;
    if (!frx_lex_starts(l, l->pos, name)) {
        if (!l->eof && frx_lex_short(l, l->pos, name)) l->need_more = 1;
        return 0;
    }
    l->pos += strlen(name);
    frx_lex_skip_s(l);
    if (l->pos >= l->len) { if (!l->eof) l->need_more = 1; return 0; }
    if (l->in[l->pos] != '=') return 0;
    l->pos++;
    frx_lex_skip_s(l);
    if (l->pos >= l->len) { if (!l->eof) l->need_more = 1; return 0; }
    q = l->in[l->pos];
    if (q != '"' && q != '\'') return 0;
    start = ++l->pos;
    while (l->pos < l->len && l->in[l->pos] != q) l->pos++;
    if (l->pos >= l->len) { if (!l->eof) l->need_more = 1; return 0; }
    *v    = l->in + start;
    *vlen = l->pos - start;
    l->pos++;
    return 1;
}

static int
frx_lex_ieq(const unsigned char *v, size_t n, const char *lit)
{
    size_t i;
    if (n != strlen(lit)) return 0;
    for (i = 0; i < n; i++) {
        unsigned char a = v[i], b = (unsigned char)lit[i];
        if (a >= 'A' && a <= 'Z') a = (unsigned char)(a - 'A' + 'a');
        if (a != b) return 0;
    }
    return 1;
}

/* the prolog: max_bytes, the BOMs, the first pair, the declaration. With
 * eof clear it asks for more bytes wherever the declaration may go on. */
#define FRX_PROLOG_NEED(l, what) \
    (((l)->need_more || ((l)->pos >= (l)->len && !(l)->eof)) ? ((l)->need_more = 1, 0) : FRX_LEX_FAIL((l), FRX_E_SYNTAX, at, (what)))

static int
frx_lex_prolog(frx_lex *l)
{
    const unsigned char *in = l->in;
    size_t len = l->len;
    const unsigned char *v;
    size_t vlen, had_s;

    if (l->prolog_max_bytes && len > l->prolog_max_bytes)
        return FRX_LEX_FAIL(l, FRX_E_TOO_LARGE, l->prolog_max_bytes, "input exceeds max_bytes");
    /* the marks below need four bytes, and a declaration is judged whole */
    if (!l->eof && (len < 4 || frx_lex_short(l, 0, "<?xml "))) { l->need_more = 1; return 0; }

    if (len >= 2 && ((in[0] == 0xFE && in[1] == 0xFF) || (in[0] == 0xFF && in[1] == 0xFE)))
        return FRX_LEX_FAIL(l, FRX_E_ENCODING, 0, "UTF-16 or UTF-32 byte order mark; only UTF-8 is accepted");
    if (len >= 4 && in[0] == 0 && in[1] == 0 && in[2] == 0xFE && in[3] == 0xFF)
        return FRX_LEX_FAIL(l, FRX_E_ENCODING, 0, "UTF-32 byte order mark; only UTF-8 is accepted");
    if (len >= 2 && ((in[0] == '<' && in[1] == 0) || (in[0] == 0 && in[1] == '<')))
        return FRX_LEX_FAIL(l, FRX_E_ENCODING, 0, "UTF-16 without a byte order mark; only UTF-8 is accepted");
    if (len >= 3 && in[0] == 0xEF && in[1] == 0xBB && in[2] == 0xBF)
        l->pos = 3;

    /* the declaration: <?xml S version S? = S? "1.0" (S encoding ...)? (S standalone ...)? S? ?> */
    if (frx_lex_starts(l, l->pos, "<?xml") && l->pos + 5 < len && frx_is_s(in[l->pos + 5])) {
        size_t at = l->pos;
        l->pos += 5;
        frx_lex_skip_s(l);
        if (!frx_lex_pseudo(l, "version", &v, &vlen))
            return FRX_PROLOG_NEED(l, "the XML declaration must start with version");
        if (vlen == 3 && memcmp(v, "1.1", 3) == 0 && l->profile == FRX_PROFILE_FULL) {
            l->version11 = 1;                              /* full only; strict keeps 0.01's refusal */
        } else if (vlen == 3 && memcmp(v, "1.0", 3) == 0) {
            /* the one version both profiles know */
        } else if (l->profile == FRX_PROFILE_FULL && vlen > 2 && v[0] == '1' && v[1] == '.') {
            /* XML 1.0 fifth edition section 2.8: a 1.x this processor does
             * not know is processed as 1.0; the declared string is kept */
            size_t k;
            for (k = 2; k < vlen; k++)
                if (v[k] < '0' || v[k] > '9')
                    return FRX_LEX_FAIL(l, FRX_E_SYNTAX, at, "only XML version 1.0 is accepted");
        } else {
            return FRX_LEX_FAIL(l, FRX_E_SYNTAX, at, "only XML version 1.0 is accepted");
        }
        if (!frx_lex_intern(l, v, vlen, &l->version)) return 0;
        had_s = frx_lex_skip_s(l);
        if (l->pos >= l->len)
            return FRX_PROLOG_NEED(l, "unterminated XML declaration");
        if (frx_lex_starts(l, l->pos, "encoding")) {
            if (!had_s)
                return FRX_LEX_FAIL(l, FRX_E_SYNTAX, l->pos, "expected whitespace before encoding in the XML declaration");
            if (!frx_lex_pseudo(l, "encoding", &v, &vlen))
                return FRX_PROLOG_NEED(l, "malformed encoding declaration");
            if (l->profile == FRX_PROFILE_FULL) {
                /* XML 1.0 4.3.3: the declaration must name what the
                 * document arrived in. What arrived was detected by
                 * frx_enc.h and the bytes here are already UTF-8. */
                if (!l->enc_override) {
                    if (frx_enc_kind_by_name((const char *)v, vlen) < 0)
                        return FRX_LEX_FAIL(l, FRX_E_ENCODING, at,
                                            "the declared encoding is not one this parser supports "
                                            "(UTF-8, UTF-16, ISO-8859-1, US-ASCII)");
                    if (!frx_enc_declared_matches(l->enc_kind, (const char *)v, vlen))
                        return FRX_LEX_FAIL(l, FRX_E_ENCODING, at,
                                            l->enc_bom ? "the encoding declaration contradicts the byte order mark"
                                                       : "the encoding declaration contradicts the encoding the document arrived in");
                }
            } else if (!frx_lex_ieq(v, vlen, "utf-8")) {
                return FRX_LEX_FAIL(l, FRX_E_ENCODING, at, "only the UTF-8 encoding is accepted");
            }
            had_s = frx_lex_skip_s(l);
            if (l->pos >= l->len)
                return FRX_PROLOG_NEED(l, "unterminated XML declaration");
        }
        if (frx_lex_starts(l, l->pos, "standalone")) {
            if (!had_s)
                return FRX_LEX_FAIL(l, FRX_E_SYNTAX, l->pos, "expected whitespace before standalone in the XML declaration");
            if (!frx_lex_pseudo(l, "standalone", &v, &vlen))
                return FRX_PROLOG_NEED(l, "malformed standalone declaration");
            if (!((vlen == 3 && memcmp(v, "yes", 3) == 0) || (vlen == 2 && memcmp(v, "no", 2) == 0)))
                return FRX_LEX_FAIL(l, FRX_E_SYNTAX, at, "malformed standalone declaration");
            l->standalone = vlen == 3;
            frx_lex_skip_s(l);
        }
        if (!frx_lex_starts(l, l->pos, "?>")) {
            /* a keyword or the close cut by the end of the input so far */
            if (!l->eof && (frx_lex_short(l, l->pos, "encoding") || frx_lex_short(l, l->pos, "standalone")
                            || frx_lex_short(l, l->pos, "?>")))
                l->need_more = 1;
            return FRX_PROLOG_NEED(l, "unterminated XML declaration");
        }
        l->pos += 2;
    } else if (!l->eof && frx_lex_short(l, l->pos, "<?xml ")) {
        l->need_more = 1;
        return 0;
    }
    return 1;
}

/* the full profile's form: the transcoder's findings go in before the
 * prolog is judged. 0 on refusal, with err set. profile is FRX_PROFILE_*:
 * under strict the prolog's checks are 0.01's, byte for byte. The
 * expansion budgets start at their defaults; the parse overrides them
 * from the extended options after this returns. */
/* the fields every form shares; the input, eof and the prolog are the
 * caller's next step */
static void
frx_lex_setup(frx_lex *l, const frx_opts *o, int profile, frx_arena *arena,
              int enc_kind, int enc_bom, int enc_override)
{
    memset(l, 0, sizeof *l);
    l->arena     = arena;
    l->tok_arena = arena;
    l->profile   = profile;
    l->enc_kind  = enc_kind;
    l->enc_bom   = enc_bom;
    l->enc_override = enc_override;
    l->prolog_max_bytes = o ? o->max_bytes : 0;
    l->max_expansion_bytes = FRX_DEFAULT_MAX_EXPANSION_BYTES;
    l->max_entity_depth    = FRX_DEFAULT_MAX_ENTITY_DEPTH;
    l->max_expansion_ratio = FRX_DEFAULT_MAX_EXPANSION_RATIO;
    l->max_fetches     = FRX_DEFAULT_MAX_FETCHES;
    l->max_token_bytes = FRX_DEFAULT_MAX_TOKEN_BYTES;
    l->cur_base.p   = "";
    l->cur_base.len = 0;
    frx_err_set(&l->err, FRX_OK, 0, NULL);
    frx_buf_init(&l->tmp);
}

static int
frx_lex_init_enc(frx_lex *l, const unsigned char *in, size_t len,
                 const frx_opts *o, int profile, frx_arena *arena,
                 int enc_kind, int enc_bom, int enc_override)
{
    frx_lex_setup(l, o, profile, arena, enc_kind, enc_bom, enc_override);
    l->in      = in;
    l->len     = len;
    l->doc_len = len;
    l->eof     = 1;
    if (!frx_lex_prolog(l)) return 0;
    l->prolog_done = 1;
    return 1;
}

/* the strict form, and the full form over bytes already known to be UTF-8 */
static int
frx_lex_init(frx_lex *l, const unsigned char *in, size_t len,
             const frx_opts *o, int profile, frx_arena *arena)
{
    return frx_lex_init_enc(l, in, len, o, profile, arena, FRX_ENC_UTF8, 0, 0);
}

/* the streaming form: no bytes yet, eof clear, the prolog run by the
 * first frx_lex_next that has enough of them; tok_arena is the reader's */
static void
frx_lex_init_stream(frx_lex *l, const frx_opts *o, int profile, frx_arena *arena,
                    frx_arena *tok_arena, int enc_kind, int enc_bom, int enc_override)
{
    frx_lex_setup(l, o, profile, arena, enc_kind, enc_bom, enc_override);
    l->tok_arena = tok_arena;
    l->in  = (const unsigned char *)"";
    l->len = 0;
    l->eof = 0;
}

static void
frx_lex_free(frx_lex *l)
{
    free(l->attrs);
    l->attrs = NULL;
    l->n_attrs = l->cap_attrs = 0;
    free(l->frames);
    l->frames = NULL;
    l->n_frames = l->cap_frames = 0;
    free(l->undecl);
    l->undecl = NULL;
    l->n_undecl = l->cap_undecl = 0;
    free(l->cm_stack);
    free(l->cm_frame);
    free(l->cond_frame);
    l->cm_stack = NULL;
    l->cm_frame = NULL;
    l->cond_frame = NULL;
    l->cm_cap = 0;
    l->cond_cap = 0;
    frx_buf_free(&l->tmp);
}

/* one token at pos, which holds a < ; 1 with *t filled */
static int
frx_lex_markup(frx_lex *l, frx_tok *t)
{
    if (frx_lex_starts(l, l->pos, "</")) {
        const frx_frame_in *f = frx_lex_top_frame(l);
        l->pos += 2;
        if (!frx_lex_end_tag(l, t)) return 0;
        if (f && l->tag_depth <= f->depth_at_push)
            return FRX_LEX_FAIL(l, FRX_E_ENTITY, l->tok_start,
                                "an entity's replacement text must not close an element opened outside it");
        l->tag_depth--;
        return 1;
    }
    if (frx_lex_starts(l, l->pos, "<!--"))      { l->pos += 4; return frx_lex_comment(l, t); }
    if (frx_lex_starts(l, l->pos, "<![CDATA[")) { l->pos += 9; return frx_lex_cdata(l, t); }
    if (frx_lex_starts(l, l->pos, "<!")) {
        if (!l->eof && !l->n_frames
            && (frx_lex_short(l, l->pos, "<!--") || frx_lex_short(l, l->pos, "<![CDATA[")
                || frx_lex_short(l, l->pos, "<!DOCTYPE"))) {
            l->need_more = 1;                      /* the input ends inside the mark */
            return 0;
        }
        if (l->profile == FRX_PROFILE_FULL) {
            if (frx_lex_starts(l, l->pos, "<!DOCTYPE")) {
                if (!l->eof && !l->n_frames && !frx_lex_doctype_complete(l)) { l->need_more = 1; return 0; }
                return frx_dtd_doctype(l, t);
            }
            return FRX_LEX_FAIL(l, FRX_E_SYNTAX, l->pos,
                                "only a DOCTYPE, a comment or CDATA may follow <! here");
        }
        return FRX_LEX_FAIL(l, FRX_E_DOCTYPE, l->pos,
                            "DOCTYPE and every other declaration are refused; only comments and CDATA may follow <!");
    }
    if (frx_lex_starts(l, l->pos, "<?"))        { l->pos += 2; return frx_lex_pi(l, t); }
    l->pos += 1;
    if (!frx_lex_start_tag(l, t)) return 0;
    if (t->kind == FRX_TOK_START) l->tag_depth++;
    return 1;
}

/* the next token: 1 with *t filled, 0 at EOF (t->kind is FRX_TOK_EOF),
 * when more input is needed (FRX_TOK_MORE; the position is back at the
 * token's start, so the caller appends bytes and calls again) or on
 * refusal (l->failed, l->err). A frame that ends between tokens is popped
 * here, and an empty text run (an entity whose text opens with markup)
 * is skipped rather than reported. */
static int
frx_lex_next(frx_lex *l, frx_tok *t)
{
    for (;;) {
        size_t start;
        int ok;
        memset(t, 0, sizeof *t);
        if (l->failed) return 0;
        if (!l->prolog_done) {
            l->need_more = 0;
            if (!frx_lex_prolog(l)) {
                if (l->need_more && !l->failed) { l->pos = 0; t->kind = FRX_TOK_MORE; return 0; }
                return 0;
            }
            l->prolog_done = 1;
        }
        if (l->pos >= l->len) {
            if (l->n_frames) { if (!frx_entity_pop(l)) return 0; continue; }
            if (!l->eof) { t->kind = FRX_TOK_MORE; return 0; }
            t->offset = l->base + l->pos;
            t->kind = FRX_TOK_EOF;
            return 0;
        }
        l->tok_start = l->pos;
        l->need_more = 0;
        start        = l->pos;
        t->offset    = FRX_LEX_ABS(l, l->pos);
        if (l->n_frames && l->frames[l->n_frames - 1].entity)
            t->entity = *frx_entity_name_of(l->frames[l->n_frames - 1].entity);
        else
            t->entity = FRX_EMPTY_STR;

        if (l->in[l->pos] != '<') {
            ok = frx_lex_text(l, t);
            /* a run with no characters is not reported, unless a
             * reference stood in it: an entity whose replacement text is
             * empty leaves nothing behind, and an element declared EMPTY
             * may not hold even that (erratum E15, case E15a) */
            if (ok && t->value.len == 0 && !(t->text_flags & FRX_TEXT_REF_HERE)) continue;
        } else {
            ok = frx_lex_markup(l, t);
        }
        if (ok) return 1;
        if (l->need_more && !l->failed) {
            if (l->len - start > l->max_token_bytes)
                return FRX_LEX_FAIL(l, FRX_E_TOO_LARGE, start, "a token longer than max_token_bytes");
            l->pos     = start;                        /* retry it whole when more has arrived */
            l->n_attrs = 0;
            t->kind    = FRX_TOK_MORE;
        }
        return 0;
    }
}

#endif /* FRX_LEX_H */
