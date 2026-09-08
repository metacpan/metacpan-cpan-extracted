#ifndef FRX_ENTITY_H
#define FRX_ENTITY_H

/* Entity expansion: the frame stack, the constraints of section 4.4, and
 * the fetch of everything external through the caller's resolver.
 *
 * A reference to an internal entity pushes a frame (frx_lex.h explains
 * why it is a frame and not a substitution) and the lexer reads the
 * replacement text as if it stood where the reference was; the end of
 * that text pops the frame and reading continues after the reference. A
 * reference to an external entity fetches its bytes first: the resolver
 * is handed the public identifier, the system identifier resolved
 * against the base of the entity that declared it (section 4.2.2, RFC
 * 3986 section 5.2) and that base, the bytes come back transcoded by
 * frx_enc.h from their own byte order mark and text declaration (section
 * 4.3.1, stripped here; the encoding it names must be the one detected,
 * 4.3.3), and the text is kept in the arena for the parse. A fetch is
 * done once per resolved identifier per parse and counted once against
 * max_fetches; the same DTD named from three places is fetched once. The
 * frame a fetched text makes is flat: its bytes are not in the document,
 * so every offset inside it reports the reference. The constraints:
 *
 *   WFC: Entity Declared        an undeclared name is refused
 *   WFC: No Recursion           an entity on the stack is refused
 *   WFC: Parsed Entity          an unparsed entity is refused; an element
 *                               opened inside a frame must close inside
 *                               it, checked at the pop (frx_lex.h checks
 *                               the end tag that would close an outer one)
 *   WFC: No External Entity References   in an attribute value
 *   WFC: No < in Attribute Values        frx_lex_attr_value, on the frame
 *   section 4.3.4               a 1.1 entity in a 1.0 document is refused
 *
 * and with no resolver every external reference is refused with the
 * option named. Under standalone="yes" WFC: Entity Declared asks more: a
 * reference in the document (not one inside the DTD's own text) must name
 * an entity declared directly in the internal subset, not in the external
 * subset nor inside any parameter entity, and that is a well-formedness
 * refusal whatever validate says. The rest of section 2.9's standalone
 * rules (a default or a type from external markup the document relies
 * on) are validity constraints, applied under validate with the VC named.
 *
 * Three budgets, all counted per parse across every frame and each
 * refused with the offset of the reference that crossed it: the depth of
 * the stack, the total bytes pushed (fetched text included), and the
 * ratio of bytes pushed to input bytes; and a fourth on fetches. The
 * bytes are counted at the push, so the work done before a refusal is
 * bounded by the budget itself, and a fetched text is bounded by
 * max_bytes on its own before it is counted.
 *
 * Needs frx_lex.h, frx_dtd.h, frx_enc.h, frx_uri.h. */

/* the frame push every kind of expansion goes through: text becomes the
 * current input with base_off as its offset base (flat: every offset
 * reports base_off), cur_base its base URI and ext_decl its markup rule */
static int
frx_entity_push_text(frx_lex *l, frx_entity *e, const frx_str *text, size_t ref_rel,
                     int flat, size_t base_off, const frx_str *cur_base, int ext_decl)
{
    size_t ref_abs = FRX_LEX_ABS(l, ref_rel);
    frx_frame_in *f;

    if (e && e->expanding)
        return FRX_LEX_FAIL_ABS(l, FRX_E_ENTITY, ref_abs,
                                "an entity refers to itself, directly or through another (WFC: No Recursion)");
    if (l->n_frames + 1 > l->max_entity_depth)
        return FRX_LEX_FAIL_ABS(l, FRX_E_EXPANSION, ref_abs,
                                "entity references nested deeper than max_entity_depth");
    l->pushed += text->len;
    if (l->pushed > l->max_expansion_bytes)
        return FRX_LEX_FAIL_ABS(l, FRX_E_EXPANSION, ref_abs,
                                "entity expansion exceeds max_expansion_bytes");
    if (l->doc_len && l->pushed / l->doc_len > (size_t)l->max_expansion_ratio)
        return FRX_LEX_FAIL_ABS(l, FRX_E_EXPANSION, ref_abs,
                                "entity expansion exceeds max_expansion_ratio times the input");

    if (l->n_frames == l->cap_frames) {
        int ncap = l->cap_frames ? l->cap_frames * 2 : 8;
        frx_frame_in *nf = (frx_frame_in *)realloc(l->frames, (size_t)ncap * sizeof *nf);
        if (!nf) return frx_lex_nomem(l);
        l->frames     = nf;
        l->cap_frames = ncap;
    }
    f = &l->frames[l->n_frames++];
    f->in            = l->in;
    f->len           = l->len;
    f->pos           = l->pos;
    f->base          = l->base;
    f->cur_base      = l->cur_base;
    f->flat          = l->flat;
    f->ext_decl      = l->ext_decl;
    f->in_dtd        = l->in_dtd;
    f->entity        = e;
    f->seq           = ++l->frame_seq;
    f->depth_at_push = l->tag_depth;
    f->ref_offset    = ref_abs;

    l->in       = (const unsigned char *)text->p;
    l->len      = text->len;
    l->pos      = 0;
    l->base     = base_off;
    l->flat     = flat;
    l->cur_base = *cur_base;
    l->ext_decl = ext_decl;
    if (!e || e->is_pe) l->in_dtd = 1;          /* the subset, or a parameter entity; inherited below */
    if (e) e->expanding = 1;
    return 1;
}

/* the current frame is exhausted: back to the one it interrupted */
static int
frx_entity_pop(frx_lex *l)
{
    frx_frame_in *f = &l->frames[l->n_frames - 1];
    if (l->tag_depth != f->depth_at_push)
        return FRX_LEX_FAIL_ABS(l, FRX_E_ENTITY, f->ref_offset,
                                "an element opened inside an entity must close inside it (WFC: Parsed Entity)");
    if (f->entity) f->entity->expanding = 0;
    l->in       = f->in;
    l->len      = f->len;
    l->pos      = f->pos;
    l->base     = f->base;
    l->cur_base = f->cur_base;
    l->flat     = f->flat;
    l->ext_decl = f->ext_decl;
    l->in_dtd   = f->in_dtd;
    l->n_frames--;
    return 1;
}

/* ---- fetching --------------------------------------------------------- */

/* A text declaration at the start of fetched text, section 4.3.1:
 * <?xml VersionInfo? EncodingDecl S? ?>. Its byte count goes to *skip so
 * the caller drops it; the encoding must be the one the transcoder
 * detected; the version is reported. A pseudo-attribute scanner over the
 * text, since the lexer's own reads through l->in. */
static int
frx_entity_text_decl(frx_lex *l, const char *p, size_t n, int enc_kind, int enc_bom,
                     size_t ref_rel, size_t *skip, int *version11)
{
    size_t i = 5;
    int have_encoding = 0;
    *skip = 0;
    *version11 = 0;
    if (n < 6 || memcmp(p, "<?xml", 5) != 0 || !frx_is_s((unsigned char)p[5])) return 1;
    for (;;) {
        const char *name;
        size_t nlen, vstart, vlen;
        char q;
        while (i < n && frx_is_s((unsigned char)p[i])) i++;
        if (i + 1 < n && p[i] == '?' && p[i + 1] == '>') { i += 2; break; }
        name = p + i;
        while (i < n && p[i] != '=' && !frx_is_s((unsigned char)p[i]) && p[i] != '?') i++;
        nlen = (size_t)(p + i - name);
        while (i < n && frx_is_s((unsigned char)p[i])) i++;
        if (i >= n || p[i] != '=')
            return FRX_LEX_FAIL(l, FRX_E_ENTITY, ref_rel, "malformed text declaration in an external entity");
        i++;
        while (i < n && frx_is_s((unsigned char)p[i])) i++;
        if (i >= n || (p[i] != '"' && p[i] != '\''))
            return FRX_LEX_FAIL(l, FRX_E_ENTITY, ref_rel, "malformed text declaration in an external entity");
        q = p[i++];
        vstart = i;
        while (i < n && p[i] != q) i++;
        if (i >= n) return FRX_LEX_FAIL(l, FRX_E_ENTITY, ref_rel, "unterminated text declaration in an external entity");
        vlen = i - vstart;
        i++;
        if (nlen == 7 && memcmp(name, "version", 7) == 0) {
            if (have_encoding)
                return FRX_LEX_FAIL(l, FRX_E_ENTITY, ref_rel, "in a text declaration the version precedes the encoding (section 4.3.1)");
            if (vlen == 3 && memcmp(p + vstart, "1.1", 3) == 0) *version11 = 1;
            else if (!(vlen == 3 && memcmp(p + vstart, "1.0", 3) == 0))
                return FRX_LEX_FAIL(l, FRX_E_ENTITY, ref_rel, "an external entity declares an XML version other than 1.0 or 1.1");
        } else if (nlen == 8 && memcmp(name, "encoding", 8) == 0) {
            have_encoding = 1;
            if (frx_enc_kind_by_name(p + vstart, vlen) < 0)
                return FRX_LEX_FAIL(l, FRX_E_ENTITY, ref_rel,
                                    "an external entity declares an encoding this parser does not support (UTF-8, UTF-16, ISO-8859-1, US-ASCII)");
            if (!frx_enc_declared_matches(enc_kind, p + vstart, vlen))
                return FRX_LEX_FAIL(l, FRX_E_ENTITY, ref_rel,
                                    enc_bom ? "an external entity's encoding declaration contradicts its byte order mark"
                                            : "an external entity's encoding declaration contradicts the encoding it arrived in");
        } else {
            return FRX_LEX_FAIL(l, FRX_E_ENTITY, ref_rel, "a text declaration carries only version and encoding");
        }
    }
    if (!have_encoding)
        return FRX_LEX_FAIL(l, FRX_E_ENTITY, ref_rel, "a text declaration must name its encoding (section 4.3.1)");
    *skip = i;
    return 1;
}

/* Section 2.11 on input: an external parsed entity's line ends become LF
 * before it is parsed (CR LF and CR; under XML 1.1 also NEL, CR NEL and
 * LS), in place, so that inside its frame a CR is a character that came
 * from a reference, as the frame rule in frx_lex.h assumes. */
static void
frx_entity_normalise_eol(char *p, size_t *len, int v11)
{
    size_t r = 0, w = 0, n = *len;
    while (r < n) {
        unsigned char c = (unsigned char)p[r];
        if (c == '\r') {
            p[w++] = '\n';
            r++;
            if (r < n && p[r] == '\n') r++;
            else if (v11 && r + 1 < n && (unsigned char)p[r] == 0xC2 && (unsigned char)p[r + 1] == 0x85) r += 2;
            continue;
        }
        if (v11 && c == 0xC2 && r + 1 < n && (unsigned char)p[r + 1] == 0x85) { p[w++] = '\n'; r += 2; continue; }
        if (v11 && c == 0xE2 && r + 2 < n && (unsigned char)p[r + 1] == 0x80 && (unsigned char)p[r + 2] == 0xA8) { p[w++] = '\n'; r += 3; continue; }
        p[w++] = (char)c;
        r++;
    }
    p[w] = '\0';
    *len = w;
}

/* the bytes behind (pub, sys) resolved against base, as arena UTF-8 text
 * with its text declaration stripped; cached per resolved identifier */
static int
frx_entity_fetch(frx_lex *l, int kind, const frx_str *pub, const frx_str *sys,
                 const frx_str *base, size_t ref_rel,
                 frx_str *text, frx_str *uri, int *version11)
{
    frx_buf     joined;
    frx_fetch_entry *fe;
    frx_fetched f;
    frx_enc     enc;
    const char *err;
    const char *utf8;
    size_t      ulen, skip;
    int         v11;

    /* the resolved identifier: the system literal against the declaring
     * entity's base; with no base it is used as written */
    frx_buf_init(&joined);
    if (!frx_uri_join(&joined, base->p, base->len, sys->p, sys->len, 0)) {
        frx_buf_free(&joined);
        return frx_lex_nomem(l);
    }
    *uri = frx_arena_strndup(l->arena, joined.p ? joined.p : "", joined.len);
    frx_buf_free(&joined);
    if (!uri->p) return frx_lex_nomem(l);

    for (fe = l->fetches; fe; fe = fe->next) {
        if (frx_str_eq2(&fe->uri, uri)) {
            *text = fe->text;
            *version11 = fe->version11;
            return 1;
        }
    }

    if (!l->resolve)
        return FRX_LEX_FAIL(l, FRX_E_ENTITY, ref_rel,
                            kind == FRX_REF_SUBSET
                                ? "the external subset cannot be read without a resolver; the resolve option arrives with external entities"
                                : "an external entity cannot be read without a resolver; the resolve option arrives with external entities");
    if (l->n_fetches >= l->max_fetches)
        return FRX_LEX_FAIL(l, FRX_E_EXPANSION, ref_rel, "more external fetches than max_fetches");
    l->n_fetches++;

    memset(&f, 0, sizeof f);
    err = l->resolve(l->resolve_ud, pub->len ? pub->p : NULL, uri->p, base->len ? base->p : NULL, kind, &f);
    if (err) return FRX_LEX_FAIL(l, FRX_E_ENTITY, ref_rel, err);
    if (l->max_bytes && f.len > l->max_bytes) {
        if (f.release) f.release(f.ud, &f);
        return FRX_LEX_FAIL(l, FRX_E_TOO_LARGE, ref_rel, "a fetched entity exceeds max_bytes");
    }

    /* its own encoding: byte order mark, first bytes, text declaration */
    memset(&enc, 0, sizeof enc);
    if (!frx_enc_detect(&enc, (const unsigned char *)f.bytes, f.len, NULL, &l->err)
        || !frx_enc_run(&enc, (const unsigned char *)f.bytes, f.len, &l->err)) {
        l->failed = 1;
        l->err.offset = FRX_LEX_ABS(l, ref_rel);
        l->err.enc = NULL;
        frx_enc_free(&enc);
        if (f.release) f.release(f.ud, &f);
        return 0;
    }
    utf8 = enc.out ? enc.out : f.bytes + enc.bom;
    ulen = enc.out ? enc.out_len : f.len - (size_t)enc.bom;
    if (!frx_entity_text_decl(l, utf8, ulen, enc.kind, enc.bom != 0, ref_rel, &skip, &v11)) {
        frx_enc_free(&enc);
        if (f.release) f.release(f.ud, &f);
        return 0;
    }
    *text = frx_arena_strndup(l->arena, utf8 + skip, ulen - skip);
    frx_enc_free(&enc);
    if (f.release) f.release(f.ud, &f);
    if (!text->p) return frx_lex_nomem(l);
    frx_entity_normalise_eol((char *)text->p, &text->len, l->version11 || v11);
    *version11 = v11;

    fe = (frx_fetch_entry *)frx_arena_alloc(l->arena, sizeof *fe);
    if (!fe) return frx_lex_nomem(l);
    fe->uri       = *uri;
    fe->text      = *text;
    fe->version11 = v11;
    fe->next      = l->fetches;
    l->fetches    = fe;
    return 1;
}

/* an external entity's text, fetched on first use */
static int
frx_entity_ensure_fetched(frx_lex *l, frx_entity *e, size_t ref_rel)
{
    if (e->fetched) return 1;
    if (!frx_entity_fetch(l, FRX_REF_ENTITY, &e->public_id, &e->system_id, &e->base, ref_rel,
                          &e->text, &e->uri, &e->version11)) return 0;
    e->fetched = 1;
    return 1;
}

/* the text of e with 4.4.8's space on each side, built once (a padded
 * text is never empty, so its length says whether it exists) */
static const frx_str *
frx_entity_padded(frx_lex *l, frx_entity *e)
{
    if (!e->padded.len) {
        char *p = (char *)frx_arena_alloc(l->arena, e->text.len + 3);
        if (!p) return NULL;
        p[0] = ' ';
        memcpy(p + 1, e->text.p, e->text.len);
        p[e->text.len + 1] = ' ';
        p[e->text.len + 2] = '\0';
        e->padded.p   = p;
        e->padded.len = e->text.len + 2;
    }
    return &e->padded;
}

/* push e: an internal entity's own text at its declaration's offset, an
 * external one's fetched text as a flat frame at the reference */
static int
frx_entity_push(frx_lex *l, frx_entity *e, size_t ref_rel, int padded)
{
    const frx_str *text;
    if (e->external) {
        if (!frx_entity_ensure_fetched(l, e, ref_rel)) return 0;
        if (e->version11 && !l->version11)
            return FRX_LEX_FAIL(l, FRX_E_ENTITY, ref_rel,
                                "an XML 1.1 entity cannot be referenced from an XML 1.0 document (section 4.3.4)");
        text = padded ? frx_entity_padded(l, e) : &e->text;
        if (!text) return frx_lex_nomem(l);
        return frx_entity_push_text(l, e, text, ref_rel, 1, FRX_LEX_ABS(l, ref_rel), &e->uri, 1);
    }
    text = padded ? frx_entity_padded(l, e) : &e->text;
    if (!text) return frx_lex_nomem(l);
    /* the padding space precedes the literal's first byte, which follows
     * a quote, so the base moves back one and offsets inside still map */
    return frx_entity_push_text(l, e, text, ref_rel, e->flat,
                                padded ? e->text_offset - 1 : e->text_offset, &e->base, l->ext_decl);
}

/* &Name; in content or an attribute value, not one of the five; pos is
 * at the &, start is its frame-relative offset */
static int
frx_entity_reference(frx_lex *l, size_t start, int in_attr)
{
    frx_str name;
    frx_entity *e;
    l->pos = start + 1;
    if (!frx_lex_name(l, 0, &name)) return 0;
    if (l->pos >= l->len || l->in[l->pos] != ';')
        return FRX_LEX_FAIL(l, FRX_E_REFERENCE, start, "malformed entity reference");
    l->pos++;
    e = l->dtd ? frx_dtd_entity(l->dtd, &name, 0) : NULL;
    if (!e) {
        /* WFC: Entity Declared applies to a document with no DTD, one
         * whose internal subset made no parameter entity reference, or one
         * declared standalone="yes". Outside those three the processor may
         * not have seen every declaration, so an undeclared name is NOT a
         * well-formedness error; it is VC: Entity Declared, which only a
         * validating parse reports. The reference then stands for nothing
         * and contributes no characters, and its offset is kept so the
         * validate pass can report it. Erratum E13 is the case where the
         * parameter entity reference alone is what opens the exemption.
         *
         * Nothing of this reaches the strict profile, which refuses every
         * DOCTYPE, so a caller that wants an undeclared entity to be fatal
         * has it by staying there. */
        if (l->dtd && !l->standalone
            && (l->dtd->pe_ref_seen || l->dtd->external_subset)) {
            if (l->n_undecl == l->cap_undecl) {
                int ncap = l->cap_undecl ? l->cap_undecl * 2 : 8;
                size_t *nu = (size_t *)realloc(l->undecl, (size_t)ncap * sizeof *nu);
                if (!nu) return FRX_LEX_FAIL(l, FRX_E_NOMEM, start, "out of memory");
                l->undecl = nu;
                l->cap_undecl = ncap;
            }
            l->undecl[l->n_undecl++] = FRX_LEX_ABS(l, start);
            return 1;                       /* included as nothing */
        }
        return FRX_LEX_FAIL(l, FRX_E_REFERENCE, start,
                            l->dtd ? "undeclared entity"
                                   : "undeclared entity (there is no DOCTYPE, so only the five predefined exist)");
    }
    if (e->unparsed)
        return FRX_LEX_FAIL(l, FRX_E_ENTITY, start,
                            "an unparsed entity may be named only by an ENTITY attribute (WFC: Parsed Entity)");
    if (e->external && in_attr)
        return FRX_LEX_FAIL(l, FRX_E_ENTITY, start,
                            "an attribute value must not refer to an external entity (WFC: No External Entity References)");
    if (l->standalone && !e->direct && !l->in_dtd)
        return FRX_LEX_FAIL(l, FRX_E_ENTITY, start,
                            "standalone=\"yes\" but the entity is declared in the external subset or a parameter entity (WFC: Entity Declared)");
    return frx_entity_push(l, e, start, 0);
}

/* %Name; in the DTD; pos is past the %. padded says it is included as a
 * PE (4.4.8, between or inside declarations) rather than in a literal. */
static int
frx_entity_pe_reference(frx_lex *l, size_t start, int padded)
{
    frx_str name;
    frx_entity *e;
    if (!frx_lex_name(l, 0, &name)) return 0;
    if (l->pos >= l->len || l->in[l->pos] != ';')
        return FRX_LEX_FAIL(l, FRX_E_REFERENCE, start, "malformed parameter entity reference");
    l->pos++;
    l->dtd->pe_ref_seen = 1;
    e = frx_dtd_entity(l->dtd, &name, 1);
    if (!e)
        return FRX_LEX_FAIL(l, FRX_E_REFERENCE, start, "undeclared parameter entity");
    return frx_entity_push(l, e, start, padded);
}

#endif /* FRX_ENTITY_H */
