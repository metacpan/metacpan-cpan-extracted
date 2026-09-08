#ifndef FRX_WRITE_H
#define FRX_WRITE_H

/* The general serialiser: the tree back to markup, the way a caller
 * asks for it.
 *
 * A second walker over the same tree and the same frx_buf as
 * frx_c14n.h, sharing its escapers by call for the default case and
 * nothing else, so that no option here can move a canonical byte. What
 * it offers is what the canonical form fixes: a declaration or none, an
 * output encoding, indentation, the short empty tag, the quote, the
 * escaping of more than the minimum, the recorded DOCTYPE and CDATA
 * sections back where they were.
 *
 * Everything is written as UTF-8 first and transcoded at the end. Under
 * an encoding that cannot hold a character (ISO-8859-1 above U+00FF,
 * US-ASCII above U+007F) the character becomes a hexadecimal reference
 * in text and attribute values, and is a refusal in a comment, a
 * processing instruction or a name, where a reference cannot stand. An
 * XML 1.1 document's restricted characters are written as references
 * for the same reason. Every string written is checked as UTF-8 and as
 * Char under the document's version, and a comment's `--`, a PI's `?>`
 * and a target of `xml` are refused, so an edited tree cannot
 * write a document this parser would refuse.
 *
 * Indentation never touches text: an element holding any text that is
 * not whitespace, or named in `preserve`, or under xml:space="preserve",
 * is written as it is; an element holding whitespace-only text is left
 * alone too unless `drop_ws` says to drop that text, which is the one
 * lossy option and is off by default. A text node's value is already
 * normalised (frx_lex.h) and is never normalised again: a carriage
 * return that arrived as a reference leaves as one.
 *
 * Entity references were resolved at parse and are not regenerated: the
 * text is the replacement text, and the recorded internal subset is
 * written back as it was, so a written document that declares an entity
 * it no longer uses is still well-formed and equivalent. A node written
 * on its own carries the namespace bindings in scope at it, so it parses
 * on its own.
 *
 * Nothing recurses (rule 2): an explicit stack of open elements, the end
 * tags written on the way back up.
 *
 * Needs frx_abi.h, frx_buf.h, frx_utf8.h, frx_enc.h, frx_tree.h,
 * frx_ns.h, frx_c14n.h. */

/* frx_write_opts is frx_abi.h's: the table hands it to a consumer
 * directly, so its shape is public. */

static void
frx_write_opts_init(frx_write_opts *o)
{
    memset(o, 0, sizeof *o);
    o->declaration   = 1;
    o->encoding      = FRX_ENC_UTF8;
    o->encoding_attr = 1;
    o->empty_short   = 1;
    o->quote         = '"';
    o->doctype       = 1;
}

typedef struct frx_writer {
    frx_buf *out;                   /* UTF-8; the caller's buffer or a stage */
    const frx_write_opts *o;
    int      version11;
    unsigned long limit;            /* the largest code point the encoding holds */
    frx_err *err;
    int      failed;
} frx_writer;

typedef struct frx_write_frame {
    const frx_node *node;
    int             indented;
    int             preserve;
} frx_write_frame;

#define FRX_WRITE_FAIL(w, off, what) \
    (frx_err_set((w)->err, FRX_E_SYNTAX, (off), (what)), (w)->failed = 1, 0)

static int
frx_write_is_char(const frx_writer *w, unsigned long cp)
{
    return w->version11 ? frx_is_char11(cp) : frx_is_char(cp);
}

/* a character only a reference can carry: beyond the encoding, a control
 * the version admits by reference alone, or under XML 1.1 a NEL or LS,
 * which written literally would be a line end on the way back in */
static int
frx_write_needs_ref(const frx_writer *w, unsigned long cp)
{
    if (cp > w->limit) return 1;
    if (w->version11) return frx_is_restricted11(cp) || cp == 0x85 || cp == 0x2028;
    return 0;
}

static void
frx_write_ref(frx_buf *o, unsigned long cp)
{
    static const char hex[] = "0123456789ABCDEF";
    char tmp[8];
    int n = 0;
    frx_buf_append(o, "&#x");
    do { tmp[n++] = hex[cp & 15]; cp >>= 4; } while (cp);
    while (n) frx_buf_append_ch(o, tmp[--n]);
    frx_buf_append_ch(o, ';');
}

/* one code point at p[i]; 0 on bad UTF-8 */
static size_t
frx_write_cp(const char *p, size_t n, size_t i, unsigned long *cp)
{
    unsigned char c = (unsigned char)p[i];
    if (c < 0x80) { *cp = c; return 1; }
    return frx_utf8_decode((const unsigned char *)p + i, n - i, cp);
}

/* text or an attribute value: escaped, with references for what the
 * encoding or the version cannot hold literally */
static int
frx_write_escape(frx_writer *w, const char *p, size_t n, int in_attr, size_t off)
{
    const frx_write_opts *o = w->o;
    size_t i = 0;
    int plain = w->limit == 0x10FFFF && !w->version11 && o->quote == '"' && !o->escape_all;

    if (plain) {
        /* the default case is the canonical escaping, by call */
        size_t k;
        unsigned long cp;
        for (k = 0; k < n; k += frx_write_cp(p, n, k, &cp)) {
            size_t m = frx_write_cp(p, n, k, &cp);
            if (!m) return FRX_WRITE_FAIL(w, off, "not UTF-8");
            if (!frx_is_char(cp)) return FRX_WRITE_FAIL(w, off, "not an XML character");
        }
        if (in_attr) frx_c14n_esc_attr(w->out, p, n);
        else         frx_c14n_esc_text(w->out, p, n);
        return 1;
    }
    while (i < n) {
        unsigned long cp;
        size_t k = frx_write_cp(p, n, i, &cp);
        const char *rep = NULL;
        if (!k) return FRX_WRITE_FAIL(w, off, "not UTF-8");
        if (!frx_write_is_char(w, cp)) return FRX_WRITE_FAIL(w, off, "not an XML character");
        switch (cp) {
        case '&':  rep = "&amp;"; break;
        case '<':  rep = "&lt;";  break;
        case '>':  rep = "&gt;";  break;
        case '\r': rep = "&#xD;"; break;
        case '"':  if ((in_attr && o->quote == '"') || (!in_attr && o->escape_all)) rep = "&quot;"; break;
        case '\'': if ((in_attr && o->quote == '\'') || (!in_attr && o->escape_all)) rep = "&#39;"; break;
        case '\t': if (in_attr) rep = "&#x9;"; break;
        case '\n': if (in_attr) rep = "&#xA;"; break;
        default: break;
        }
        if (rep) frx_buf_append(w->out, rep);
        else if (frx_write_needs_ref(w, cp)) frx_write_ref(w->out, cp);
        else frx_buf_append_n(w->out, p + i, k);
        i += k;
    }
    return 1;
}

/* a comment, a PI target or data, a name: nothing here can be a
 * reference, so every character must be writable as it is */
static int
frx_write_check(frx_writer *w, const char *p, size_t n, size_t off)
{
    size_t i = 0;
    while (i < n) {
        unsigned long cp;
        size_t k = frx_write_cp(p, n, i, &cp);
        if (!k) return FRX_WRITE_FAIL(w, off, "not UTF-8");
        if (!frx_write_is_char(w, cp)) return FRX_WRITE_FAIL(w, off, "not an XML character");
        if (frx_write_needs_ref(w, cp))
            return FRX_WRITE_FAIL(w, off, "a character that cannot be written in the output encoding stands where no reference can");
        i += k;
    }
    return 1;
}

static int
frx_write_name(frx_writer *w, const frx_str *s, size_t off)
{
    size_t i = 0;
    int first = 1;
    if (!s->len) return FRX_WRITE_FAIL(w, off, "an empty name");
    while (i < s->len) {
        unsigned long cp;
        size_t k = frx_write_cp(s->p, s->len, i, &cp);
        if (!k) return FRX_WRITE_FAIL(w, off, "a name that is not UTF-8");
        if (cp > w->limit) return FRX_WRITE_FAIL(w, off, "a name that cannot be written in the output encoding");
        if (cp != ':' && (first ? !frx_is_name_start(cp) : !frx_is_name_char(cp)))
            return FRX_WRITE_FAIL(w, off, "a name that is not a name");
        first = 0;
        i += k;
    }
    return 1;
}

static void
frx_write_indent(frx_writer *w, int level)
{
    int n = level * w->o->indent;
    frx_buf_append_ch(w->out, '\n');
    while (n-- > 0) frx_buf_append_ch(w->out, ' ');
}

static int
frx_write_quoted(frx_writer *w, const frx_str *v, size_t off)
{
    frx_buf_append_ch(w->out, (char)w->o->quote);
    if (!frx_write_escape(w, v->p, v->len, 1, off)) return 0;
    frx_buf_append_ch(w->out, (char)w->o->quote);
    return 1;
}

static int
frx_write_decl(frx_writer *w, const frx_str *prefix, const frx_str *uri, size_t off)
{
    if (prefix->len && !frx_write_name(w, prefix, off)) return 0;   /* a prefix is a name */
    frx_buf_append(w->out, " xmlns");
    if (prefix->len) { frx_buf_append_ch(w->out, ':'); frx_buf_append_n(w->out, prefix->p, prefix->len); }
    frx_buf_append_ch(w->out, '=');
    return frx_write_quoted(w, uri, off);
}

/* is prefix among the first n of the list? */
static int
frx_write_prefix_seen(const frx_str *list, int n, const frx_str *prefix)
{
    int i;
    for (i = 0; i < n; i++) if (frx_str_eq2(&list[i], prefix)) return 1;
    return 0;
}

/* <name decls attrs> or <name decls attrs/>; inherit says the bindings in
 * scope but declared above the element are written too, which is what
 * makes a node written on its own parse on its own */
static int
frx_write_start(frx_writer *w, const frx_node *n, int inherit, int empty)
{
    int i;
    if (!frx_write_name(w, &n->qname, n->offset)) return 0;
    frx_buf_append_ch(w->out, '<');
    frx_buf_append_n(w->out, n->qname.p, n->qname.len);
    for (i = 0; i < n->n_decls; i++)
        if (!frx_write_decl(w, &n->decls[i].prefix, &n->decls[i].uri, n->offset)) return 0;
    if (inherit && n->scope) {
        /* nearest binding of each prefix wins, as lookup walks it */
        const frx_scope *s;
        frx_str *seen = NULL;
        int n_seen = 0, cap = 0;
        for (s = n->scope; s; s = s->up) {
            for (i = 0; i < s->n_decls; i++) {
                const frx_nsdecl *d = &s->decls[i];
                int own = 0, j;
                for (j = 0; j < n->n_decls; j++) if (frx_str_eq2(&n->decls[j].prefix, &d->prefix)) own = 1;
                if (own || frx_write_prefix_seen(seen, n_seen, &d->prefix)) continue;
                if (n_seen == cap) {
                    int ncap = cap ? cap * 2 : 8;
                    frx_str *ns = (frx_str *)realloc(seen, (size_t)ncap * sizeof *ns);
                    if (!ns) { free(seen); return FRX_WRITE_FAIL(w, n->offset, "out of memory"); }
                    seen = ns; cap = ncap;
                }
                seen[n_seen++] = d->prefix;
                if (!d->prefix.len && !d->uri.len) continue;   /* the default unbound: nothing to say */
                if (!frx_write_decl(w, &d->prefix, &d->uri, n->offset)) { free(seen); return 0; }
            }
        }
        free(seen);
    }
    for (i = 0; i < n->n_attrs; i++) {
        const frx_attr *a = &n->attrs[i];
        if (!frx_write_name(w, &a->qname, a->offset)) return 0;
        frx_buf_append_ch(w->out, ' ');
        frx_buf_append_n(w->out, a->qname.p, a->qname.len);
        frx_buf_append_ch(w->out, '=');
        if (!frx_write_quoted(w, &a->value, a->offset)) return 0;
    }
    if (empty && w->o->empty_short) frx_buf_append(w->out, "/>");
    else frx_buf_append_ch(w->out, '>');
    return 1;
}

static void
frx_write_end(frx_writer *w, const frx_node *n)
{
    frx_buf_append(w->out, "</");
    frx_buf_append_n(w->out, n->qname.p, n->qname.len);
    frx_buf_append_ch(w->out, '>');
}

/* one CDATA section over p; a ]]> inside is split into two sections */
static void
frx_write_cdata(frx_writer *w, const char *p, size_t n)
{
    size_t i, run = 0;
    frx_buf_append(w->out, "<![CDATA[");
    for (i = 0; i + 2 < n; i++) {
        if (p[i] == ']' && p[i + 1] == ']' && p[i + 2] == '>') {
            frx_buf_append_n(w->out, p + run, i + 2 - run);
            frx_buf_append(w->out, "]]><![CDATA[");
            run = i + 2;
            i += 1;
        }
    }
    frx_buf_append_n(w->out, p + run, n - run);
    frx_buf_append(w->out, "]]>");
}

/* can this span be a CDATA section: every character literal under the
 * encoding and the version? */
static int
frx_write_span_literal(frx_writer *w, const char *p, size_t n)
{
    size_t i = 0;
    while (i < n) {
        unsigned long cp;
        size_t k = frx_write_cp(p, n, i, &cp);
        if (!k || !frx_write_is_char(w, cp) || frx_write_needs_ref(w, cp)) return 0;
        i += k;
    }
    return 1;
}

/* a text node: its CDATA spans as sections, the rest escaped */
static int
frx_write_text(frx_writer *w, const frx_node *n)
{
    size_t at = 0;
    int i;
    for (i = 0; i < n->n_cdata_spans; i++) {
        const frx_span *sp = &n->cdata_spans[i];
        if (sp->offset > at && !frx_write_escape(w, n->value.p + at, sp->offset - at, 0, n->offset)) return 0;
        if (frx_write_span_literal(w, n->value.p + sp->offset, sp->len))
            frx_write_cdata(w, n->value.p + sp->offset, sp->len);
        else if (!frx_write_escape(w, n->value.p + sp->offset, sp->len, 0, n->offset))
            return 0;                                  /* a reference has to go in: text, not CDATA */
        at = sp->offset + sp->len;
    }
    if (n->value.len > at && !frx_write_escape(w, n->value.p + at, n->value.len - at, 0, n->offset)) return 0;
    return 1;
}

static int
frx_write_comment(frx_writer *w, const frx_node *n)
{
    const char *p = n->value.p;
    size_t i;
    if (!frx_write_check(w, p, n->value.len, n->offset)) return 0;
    for (i = 0; i + 1 < n->value.len; i++)
        if (p[i] == '-' && p[i + 1] == '-') return FRX_WRITE_FAIL(w, n->offset, "-- inside a comment");
    if (n->value.len && p[n->value.len - 1] == '-') return FRX_WRITE_FAIL(w, n->offset, "a comment ending in -");
    frx_buf_append(w->out, "<!--");
    frx_buf_append_n(w->out, p, n->value.len);
    frx_buf_append(w->out, "-->");
    return 1;
}

static int
frx_write_pi(frx_writer *w, const frx_node *n)
{
    size_t i;
    if (!frx_write_name(w, &n->local, n->offset)) return 0;
    if (frx_lex_target_is_xml(&n->local)) return FRX_WRITE_FAIL(w, n->offset, "a processing instruction target of xml");
    if (!frx_write_check(w, n->value.p, n->value.len, n->offset)) return 0;
    for (i = 0; i + 1 < n->value.len; i++)
        if (n->value.p[i] == '?' && n->value.p[i + 1] == '>') return FRX_WRITE_FAIL(w, n->offset, "?> inside a processing instruction");
    frx_buf_append(w->out, "<?");
    frx_buf_append_n(w->out, n->local.p, n->local.len);
    if (n->value.len) { frx_buf_append_ch(w->out, ' '); frx_buf_append_n(w->out, n->value.p, n->value.len); }
    frx_buf_append(w->out, "?>");
    return 1;
}

static int
frx_write_ws_only(const frx_node *n)
{
    return frx_str_is_s(&n->value);
}

/* may this element's children be laid out on their own lines? */
static int
frx_write_indentable(const frx_writer *w, const frx_node *n, int preserve)
{
    const frx_node *c;
    int any = 0;
    if (!w->o->indent || preserve) return 0;
    for (c = n->first_child; c; c = c->next) {
        if (c->kind == FRX_TEXT) {
            if (!frx_write_ws_only(c) || !w->o->drop_ws) return 0;
        } else {
            any = 1;
        }
    }
    return any;
}

static int
frx_write_preserved(const frx_writer *w, const frx_node *n, int inherited)
{
    int i, pres = inherited;
    for (i = 0; i < n->n_attrs; i++) {
        const frx_attr *a = &n->attrs[i];
        if (frx_str_eq(&a->ns, FRX_XML_NS, sizeof FRX_XML_NS - 1) && frx_str_eq(&a->local, "space", 5))
            pres = frx_str_eq(&a->value, "preserve", 8);
    }
    for (i = 0; i < w->o->n_preserve; i++)
        if (frx_str_eq(&n->local, w->o->preserve[i], strlen(w->o->preserve[i]))) pres = 1;
    return pres;
}

/* the subtree under apex, or every top-level node of a document apex */
static int
frx_write_walk(frx_writer *w, const frx_node *apex)
{
    frx_write_frame *stack = NULL;
    int sp = 0, cap = 0, level = 0;
    int top_level = apex->kind == FRX_DOCUMENT;
    int first_top = 1;
    const frx_node *n = top_level ? apex->first_child : apex;

    while (n) {
        int parent_indented = sp ? stack[sp - 1].indented : 0;
        int parent_preserve = sp ? stack[sp - 1].preserve : 0;
        int ok = 1;

        if (!sp && top_level) {
            if (!first_top) frx_buf_append_ch(w->out, '\n');
            first_top = 0;
        } else if (parent_indented && n->kind != FRX_TEXT) {
            frx_write_indent(w, level);
        }

        switch (n->kind) {
        case FRX_ELEMENT: {
            int pres = frx_write_preserved(w, n, parent_preserve);
            int ind  = frx_write_indentable(w, n, pres);
            ok = frx_write_start(w, n, n == apex && !top_level, n->first_child == NULL);
            if (ok && n->first_child) {
                if (sp == cap) {
                    int ncap = cap ? cap * 2 : 32;
                    frx_write_frame *ns = (frx_write_frame *)realloc(stack, (size_t)ncap * sizeof *ns);
                    if (!ns) { free(stack); return FRX_WRITE_FAIL(w, n->offset, "out of memory"); }
                    stack = ns; cap = ncap;
                }
                stack[sp].node = n; stack[sp].indented = ind; stack[sp].preserve = pres; sp++;
                level++;
                n = n->first_child;
                continue;
            }
            if (ok && !n->first_child && !w->o->empty_short) frx_write_end(w, n);
            break;
        }
        case FRX_TEXT:
            if (!(parent_indented && w->o->drop_ws && frx_write_ws_only(n))) ok = frx_write_text(w, n);
            break;
        case FRX_COMMENT: ok = frx_write_comment(w, n); break;
        case FRX_PI:      ok = frx_write_pi(w, n);      break;
        default:          ok = FRX_WRITE_FAIL(w, n->offset, "a node of no kind"); break;
        }
        if (!ok) { free(stack); return 0; }

        /* the next node: a sibling, or up with the end tag */
        for (;;) {
            if (n == apex) { free(stack); return 1; }
            if (n->next) { n = n->next; break; }
            if (!sp) { free(stack); return 1; }
            sp--; level--;
            n = stack[sp].node;
            if (stack[sp].indented) frx_write_indent(w, level);
            frx_write_end(w, n);
        }
    }
    free(stack);
    return 1;
}

/* the staged UTF-8 in the requested encoding */
static int
frx_write_transcode(const frx_buf *u8, int enc, frx_buf *out)
{
    size_t i = 0;
    const char *p = u8->p ? u8->p : "";
    out->len = 0;
    if (enc == FRX_ENC_UTF16LE) { frx_buf_append_ch(out, (char)0xFF); frx_buf_append_ch(out, (char)0xFE); }
    if (enc == FRX_ENC_UTF16BE) { frx_buf_append_ch(out, (char)0xFE); frx_buf_append_ch(out, (char)0xFF); }
    while (i < u8->len) {
        unsigned long cp;
        size_t k = frx_write_cp(p, u8->len, i, &cp);
        if (!k) return 0;
        if (enc == FRX_ENC_UTF16LE || enc == FRX_ENC_UTF16BE) {
            unsigned units[2];
            int n = 1, j;
            if (cp >= 0x10000) {
                cp -= 0x10000;
                units[0] = 0xD800 + (unsigned)(cp >> 10);
                units[1] = 0xDC00 + (unsigned)(cp & 0x3FF);
                n = 2;
            } else {
                units[0] = (unsigned)cp;
            }
            for (j = 0; j < n; j++) {
                unsigned char hi = (unsigned char)(units[j] >> 8), lo = (unsigned char)(units[j] & 0xFF);
                if (enc == FRX_ENC_UTF16LE) { frx_buf_append_ch(out, (char)lo); frx_buf_append_ch(out, (char)hi); }
                else                        { frx_buf_append_ch(out, (char)hi); frx_buf_append_ch(out, (char)lo); }
            }
        } else {
            frx_buf_append_ch(out, (char)cp);          /* every character is under the limit by construction */
        }
        i += k;
    }
    return !out->failed;
}

/* the document (apex = its document node) or the subtree at apex, as
 * markup in out; 0 with *err on refusal */
static int
frx_write(const frx_node *apex, const frx_doc *d, const frx_write_opts *o, frx_buf *out, frx_err *err)
{
    frx_writer w;
    frx_buf    stage;
    int direct = o->encoding == FRX_ENC_UTF8;
    int ok;

    frx_buf_init(&stage);
    out->len = 0;
    w.out       = direct ? out : &stage;
    w.o         = o;
    w.version11 = frx_str_eq(&d->version, "1.1", 3);
    w.limit     = o->encoding == FRX_ENC_LATIN1 ? 0xFF : o->encoding == FRX_ENC_ASCII ? 0x7F : 0x10FFFF;
    w.err       = err;
    w.failed    = 0;
    frx_err_set(err, FRX_OK, 0, NULL);

    if (o->declaration) {
        frx_buf_append(w.out, "<?xml version=\"");
        frx_buf_append_n(w.out, d->version.p, d->version.len);
        frx_buf_append_ch(w.out, '"');
        if (o->encoding_attr) {
            frx_buf_append(w.out, " encoding=\"");
            frx_buf_append(w.out, frx_enc_name(o->encoding));
            frx_buf_append_ch(w.out, '"');
        }
        if (d->standalone) frx_buf_append(w.out, " standalone=\"yes\"");
        frx_buf_append(w.out, "?>\n");
    }
    if (apex->kind == FRX_DOCUMENT && o->doctype && d->doctype) {
        const frx_doctype *dt = d->doctype;
        if (!frx_write_name(&w, &dt->name, dt->offset)) { frx_buf_free(&stage); return 0; }
        frx_buf_append(w.out, "<!DOCTYPE ");
        frx_buf_append_n(w.out, dt->name.p, dt->name.len);
        if (dt->public_id.len) {
            frx_buf_append(w.out, " PUBLIC \"");
            frx_buf_append_n(w.out, dt->public_id.p, dt->public_id.len);
            frx_buf_append(w.out, "\" \"");
            frx_buf_append_n(w.out, dt->system_id.p, dt->system_id.len);
            frx_buf_append_ch(w.out, '"');
        } else if (dt->system_id.len) {
            frx_buf_append(w.out, " SYSTEM \"");
            frx_buf_append_n(w.out, dt->system_id.p, dt->system_id.len);
            frx_buf_append_ch(w.out, '"');
        }
        if (dt->has_subset) {
            if (!frx_write_check(&w, dt->subset.p, dt->subset.len, dt->offset)) { frx_buf_free(&stage); return 0; }
            frx_buf_append(w.out, " [");
            frx_buf_append_n(w.out, dt->subset.p, dt->subset.len);
            frx_buf_append_ch(w.out, ']');
        }
        frx_buf_append(w.out, ">\n");
    }

    ok = frx_write_walk(&w, apex);
    if (ok && w.out->failed) ok = FRX_WRITE_FAIL(&w, 0, "out of memory");
    if (ok && !direct) {
        if (!frx_write_transcode(&stage, o->encoding, out)) ok = FRX_WRITE_FAIL(&w, 0, "out of memory");
    }
    frx_buf_free(&stage);
    return ok;
}

#endif /* FRX_WRITE_H */
