#ifndef FRX_READER_H
#define FRX_READER_H

/* The pull reader: bytes in, one event at a time out, at a flat cost.
 *
 * A reader owns a driver (frx_parse.h) whose sink queues events, and
 * pumps it one step at a time: next() hands out the next queued event,
 * and when the queue is empty runs a step, which either queues one or two
 * events (a text flush and the token that ended it), says the input ended
 * inside a token (0: feed more), or ends the document. Every event's
 * strings live in the reader's scratch arena and are valid until the
 * event after next() moves past them; a caller keeps what it needs.
 *
 * Memory: two arenas. The DTD, the entities and the fetch cache are in
 * the persistent one, because a record may refer to them at any point of
 * the stream. Everything a token allocates - names, values, attribute
 * arrays, namespace scopes - is in the scratch arena, which is marked
 * when a token is about to be read at depth one (between records) and
 * released when the end event of that record has been consumed, so a
 * stream of a million records costs the scratch of one. The root's own
 * strings and scope were allocated before the first mark and stay. The
 * input buffer is compacted the same way: consumed bytes are dropped
 * from its front once a token boundary is known, and the lexer's base
 * offset carries the count so every offset reported is into the stream.
 *
 * Encodings: under the full profile the first bytes choose the encoding
 * (frx_enc.h), and everything after is transcoded to UTF-8 as it
 * arrives, one unit at a time, with up to three bytes carried between
 * feeds: the one place a partial unit exists. Under strict the bytes are
 * UTF-8 or refused, as everywhere.
 *
 * Subtrees: at a start event, frx_reader_subtree switches the driver's
 * sink to the tree sink in copy mode over a fresh document, replays that
 * start, and pumps until the matching end; the document it returns is
 * independent of the reader. If the input ends inside the subtree the
 * call returns 0 and the reader stays in capture: feed and call it
 * again. That is what the plugin's record mode does per record.
 *
 * Needs frx_parse.h (and through it everything the core has), frx_enc.h. */

/* FRX_START, FRX_END and FRX_DOCTYPE are frx_abi.h's, since a consumer
 * reading events compares against them. */

typedef struct frx_event {
    int               kind;
    frx_str           qname;
    frx_str           prefix;
    frx_str           local;
    frx_str           ns;
    frx_str           value;        /* text, comment body, pi data */
    frx_str           entity;       /* text: the entity it came from; "" for the document */
    const frx_attr   *attrs;
    int               n_attrs;
    const frx_nsdecl *decls;
    int               n_decls;
    const frx_scope  *scope;
    size_t            offset;
    int               depth;        /* elements open before this event; a start's own depth is depth + 1 */
    int               empty;        /* start: <a/> */
    const frx_doctype *doctype;
} frx_event;

#define FRX_READER_QUEUE   8
#define FRX_READER_COMPACT (64u * 1024u)

typedef struct frx_reader {
    frx_opts_ex   oe;
    int           profile;
    frx_arena     arena;            /* persistent */
    frx_arena     scratch;          /* per record */
    frx_parse     p;
    frx_buf       raw;              /* fed bytes not yet transcoded (a non-UTF-8 stream) */
    size_t        raw_pos;
    frx_buf       in;               /* what the lexer reads */
    size_t        dropped;          /* bytes dropped from the front of in */
    int           eof_fed;
    int           enc_ready;        /* the encoding has been chosen */
    int           enc_kind;
    int           enc_bom;
    frx_event     q[FRX_READER_QUEUE];
    int           qh, qn;
    frx_event     cur;              /* the event last handed out */
    int           have_cur;
    int           done;
    int           failed;
    frx_err       err;
    frx_arena_mark mark;
    int           have_mark;
    int           pending_release;
    /* subtree capture */
    int           capturing;
    int           cap_depth;        /* the captured element's own depth */
    frx_doc      *cap_doc;
    frx_tree_sink cap_sink;
} frx_reader;

#define FRX_READER_FAIL(r, c, off, what) \
    (frx_err_set(&(r)->err, (c), (off), (what)), (r)->failed = 1, 0)

/* ---- the queue sink ------------------------------------------------------ */

static frx_event *
frx_reader_enqueue(frx_reader *r)
{
    frx_event *e;
    if (r->qn == FRX_READER_QUEUE) return NULL;
    e = &r->q[(r->qh + r->qn) % FRX_READER_QUEUE];
    r->qn++;
    memset(e, 0, sizeof *e);
    e->qname = e->prefix = e->local = e->ns = e->value = e->entity = FRX_EMPTY_STR;
    return e;
}

static int
frx_reader_sink_start(frx_parse *p, void *ud, const frx_ev_start *ev)
{
    frx_reader *r = (frx_reader *)ud;
    frx_event *e = frx_reader_enqueue(r);
    if (!e) return FRX_PARSE_FAIL(p, FRX_E_SYNTAX, ev->offset, "reader queue overflow");
    e->kind    = FRX_START;
    e->qname   = ev->qname;
    e->prefix  = ev->prefix;
    e->local   = ev->local;
    e->ns      = ev->ns;
    e->attrs   = ev->attrs;
    e->n_attrs = ev->n_attrs;
    e->decls   = ev->decls;
    e->n_decls = ev->n_decls;
    e->scope   = ev->scope;
    e->offset  = ev->offset;
    e->depth   = p->depth;
    e->empty   = ev->empty;
    return 1;
}

static int
frx_reader_sink_end(frx_parse *p, void *ud, const frx_str *qname, size_t offset)
{
    frx_reader *r = (frx_reader *)ud;
    frx_event *e = frx_reader_enqueue(r);
    if (!e) return FRX_PARSE_FAIL(p, FRX_E_SYNTAX, offset, "reader queue overflow");
    e->kind   = FRX_END;
    e->qname  = *qname;
    frx_ns_split(&e->qname, &e->prefix, &e->local);
    e->offset = offset;
    e->depth  = p->depth + 1;                  /* the driver has popped it; report its own depth */
    return 1;
}

static int
frx_reader_sink_text(frx_parse *p, void *ud, const char *s, size_t n,
                     const frx_span *spans, int n_spans, size_t offset, const frx_str *entity,
                     int from_ref)
{
    frx_reader *r = (frx_reader *)ud;
    frx_event *e = frx_reader_enqueue(r);
    (void)spans; (void)n_spans; (void)from_ref;
    if (!e) return FRX_PARSE_FAIL(p, FRX_E_SYNTAX, offset, "reader queue overflow");
    e->kind   = FRX_TEXT;
    e->value  = frx_arena_strndup(&r->scratch, s, n);     /* the driver's buffer is reused */
    if (!e->value.p) return frx_parse_nomem(p, offset);
    e->entity = *entity;
    e->offset = offset;
    e->depth  = p->depth;
    return 1;
}

static int
frx_reader_sink_comment(frx_parse *p, void *ud, const frx_str *value, size_t offset)
{
    frx_reader *r = (frx_reader *)ud;
    frx_event *e = frx_reader_enqueue(r);
    if (!e) return FRX_PARSE_FAIL(p, FRX_E_SYNTAX, offset, "reader queue overflow");
    e->kind   = FRX_COMMENT;
    e->value  = *value;
    e->offset = offset;
    e->depth  = p->depth;
    return 1;
}

static int
frx_reader_sink_pi(frx_parse *p, void *ud, const frx_str *target, const frx_str *data, size_t offset)
{
    frx_reader *r = (frx_reader *)ud;
    frx_event *e = frx_reader_enqueue(r);
    if (!e) return FRX_PARSE_FAIL(p, FRX_E_SYNTAX, offset, "reader queue overflow");
    e->kind   = FRX_PI;
    e->local  = *target;
    e->qname  = *target;
    e->value  = *data;
    e->offset = offset;
    e->depth  = p->depth;
    return 1;
}

static int
frx_reader_sink_doctype(frx_parse *p, void *ud, const frx_doctype *dt, const frx_dtd *dtd)
{
    frx_reader *r = (frx_reader *)ud;
    frx_event *e = frx_reader_enqueue(r);
    (void)dtd;
    if (!e) return FRX_PARSE_FAIL(p, FRX_E_SYNTAX, dt->offset, "reader queue overflow");
    e->kind    = FRX_DOCTYPE;
    e->qname   = dt->name;
    e->local   = dt->name;
    e->doctype = dt;
    e->offset  = dt->offset;
    e->depth   = 0;
    return 1;
}

static const frx_sink FRX_READER_SINK = {
    frx_reader_sink_start, frx_reader_sink_end, frx_reader_sink_text,
    frx_reader_sink_comment, frx_reader_sink_pi, frx_reader_sink_doctype,
    NULL
};

/* ---- lifetime ------------------------------------------------------------- */

static void
frx_reader_init(frx_reader *r, const frx_opts_ex *oe_in)
{
    memset(r, 0, sizeof *r);
    frx_opts_ex_norm(oe_in, &r->oe);
    r->profile = r->oe.profile == FRX_PROFILE_FULL ? FRX_PROFILE_FULL : FRX_PROFILE_STRICT;
    frx_arena_init(&r->arena);
    frx_arena_init(&r->scratch);
    frx_buf_init(&r->raw);
    frx_buf_init(&r->in);
    frx_parse_init(&r->p, &r->oe, &r->arena, &r->scratch, &FRX_READER_SINK, r);
    r->p.split_entities = 1;
    frx_err_set(&r->err, FRX_OK, 0, NULL);
    r->cur.qname = r->cur.prefix = r->cur.local = r->cur.ns = r->cur.value = r->cur.entity = FRX_EMPTY_STR;
}

/* A reader on the heap, for a caller that cannot see the struct: the C
 * ABI hands out a pointer and takes it back, and nothing else needs
 * these two. */
static frx_reader *
frx_reader_new(const frx_opts_ex *oe)
{
    frx_reader *r = (frx_reader *)malloc(sizeof *r);
    if (r) frx_reader_init(r, oe);
    return r;
}

static void
frx_reader_free(frx_reader *r)
{
    frx_parse_free(&r->p);
    frx_tree_sink_free(&r->cap_sink);
    if (r->cap_doc) frx_doc_free(r->cap_doc);
    frx_buf_free(&r->raw);
    frx_buf_free(&r->in);
    frx_arena_free(&r->scratch);
    frx_arena_free(&r->arena);
}

/* the other half of frx_reader_new: release what the reader holds and
 * then the reader itself */
static void
frx_reader_destroy(frx_reader *r)
{
    if (!r) return;
    frx_reader_free(r);
    free(r);
}

/* ---- input --------------------------------------------------------------- */

/* the lexer's view of the document frame follows the buffer */
static void
frx_reader_sync_lex(frx_reader *r)
{
    frx_lex *l = &r->p.lex;
    const unsigned char *in = (const unsigned char *)(r->in.p ? r->in.p : "");
    if (l->n_frames) {
        l->frames[0].in  = in;
        l->frames[0].len = r->in.len;
    } else {
        l->in  = in;
        l->len = r->in.len;
    }
    l->doc_len = r->dropped + r->in.len;
    l->eof     = r->eof_fed && r->raw_pos >= r->raw.len;
}

/* the encoding from the first bytes; once, when there are enough of them
 * or the input is complete */
static int
frx_reader_choose_encoding(frx_reader *r)
{
    frx_enc enc;
    if (r->enc_ready) return 1;
    if (r->profile != FRX_PROFILE_FULL) {
        r->enc_kind  = FRX_ENC_UTF8;
        r->enc_ready = 1;
    } else {
        if (r->raw.len < 4 && !r->eof_fed) return 1;   /* wait */
        memset(&enc, 0, sizeof enc);
        if (!frx_enc_detect(&enc, (const unsigned char *)(r->raw.p ? r->raw.p : ""), r->raw.len, r->oe.encoding, &r->err)) {
            r->failed = 1;
            return 0;
        }
        r->enc_kind  = enc.kind;
        r->enc_bom   = enc.bom;
        r->raw_pos   = (size_t)enc.bom;
        r->enc_ready = 1;
        r->p.lex.enc_kind     = enc.kind;
        r->p.lex.enc_bom      = enc.bom != 0;
        r->p.lex.enc_override = enc.override;
    }
    return 1;
}

/* raw bytes become UTF-8 in `in`; a partial unit waits for the next feed */
static int
frx_reader_transcode(frx_reader *r)
{
    const unsigned char *raw = (const unsigned char *)(r->raw.p ? r->raw.p : "");
    if (r->enc_kind == FRX_ENC_UTF8) {
        if (r->raw_pos < r->raw.len) frx_buf_append_n(&r->in, (const char *)raw + r->raw_pos, r->raw.len - r->raw_pos);
        r->raw_pos = r->raw.len;
    } else {
        while (r->raw_pos < r->raw.len) {
            unsigned long cp;
            const char *what = NULL;
            unsigned char u8[4];
            size_t n, k;
            n = frx_enc_step(r->enc_kind, raw, r->raw.len, r->raw_pos, &cp, &what);
            if (!n) {
                /* a unit the feed cut: wait unless the input is complete */
                if (!r->eof_fed && r->raw.len - r->raw_pos < 4) break;
                return FRX_READER_FAIL(r, FRX_E_ENCODING, r->raw_pos, what);
            }
            k = frx_utf8_encode(cp, u8);
            frx_buf_append_n(&r->in, (const char *)u8, k);
            r->raw_pos += n;
        }
    }
    if (r->in.failed) return FRX_READER_FAIL(r, FRX_E_NOMEM, 0, "out of memory");
    /* what was transcoded is not needed again */
    if (r->raw_pos > 0 && r->raw_pos == r->raw.len) { r->raw.len = 0; r->raw_pos = 0; }
    else if (r->raw_pos > FRX_READER_COMPACT) {
        memmove(r->raw.p, r->raw.p + r->raw_pos, r->raw.len - r->raw_pos);
        r->raw.len -= r->raw_pos;
        r->raw_pos = 0;
    }
    return 1;
}

/* bytes arrive; eof says these are the last */
static int
frx_reader_feed(frx_reader *r, const char *bytes, size_t len, int eof)
{
    if (r->failed) return 0;
    if (r->eof_fed) return FRX_READER_FAIL(r, FRX_E_SYNTAX, r->dropped + r->in.len, "fed after eof");
    if (r->oe.base.max_bytes && r->dropped + r->in.len + r->raw.len + len > r->oe.base.max_bytes)
        return FRX_READER_FAIL(r, FRX_E_TOO_LARGE, r->oe.base.max_bytes, "input exceeds max_bytes");
    if (len) frx_buf_append_n(&r->raw, bytes, len);
    if (r->raw.failed) return FRX_READER_FAIL(r, FRX_E_NOMEM, 0, "out of memory");
    if (eof) r->eof_fed = 1;
    if (!frx_reader_choose_encoding(r)) return 0;
    if (r->enc_ready && !frx_reader_transcode(r)) return 0;
    if (r->enc_ready && !r->p.lex.arena) {
        /* the lexer exists from the first bytes; the prolog runs when there are enough */
        frx_lex_init_stream(&r->p.lex, &r->oe.base, r->profile, &r->arena, &r->scratch,
                            r->enc_kind, r->enc_bom != 0, r->oe.encoding != NULL);
        r->p.lex.prolog_max_bytes = 0;             /* applied above, on the stream */
        frx_parse_wire_lex(&r->p, &r->oe);
    }
    if (r->p.lex.arena) frx_reader_sync_lex(r);
    return 1;
}

/* consumed bytes leave the buffer; only between tokens of the document frame */
static void
frx_reader_compact(frx_reader *r)
{
    frx_lex *l = &r->p.lex;
    if (l->n_frames || l->pos < FRX_READER_COMPACT || !r->in.p) return;
    memmove(r->in.p, r->in.p + l->pos, r->in.len - l->pos);
    r->in.len  -= l->pos;
    r->dropped += l->pos;
    l->pos      = 0;
    l->base     = r->dropped;
    frx_reader_sync_lex(r);
}

/* ---- events -------------------------------------------------------------- */

static int
frx_reader_pump(frx_reader *r)
{
    int step;
    if (!r->p.lex.arena) return FRX_STEP_MORE;         /* no bytes yet */
    if (r->p.depth == 1 && !r->have_mark && !r->capturing) {
        frx_arena_mark_get(&r->scratch, &r->mark);
        r->have_mark = 1;
    }
    frx_reader_sync_lex(r);
    step = frx_parse_step(&r->p);
    if (step == FRX_STEP_FAIL) { r->err = r->p.err; r->failed = 1; }
    else if (step == FRX_STEP_OK) frx_reader_compact(r);
    return step;
}

/* the next event into *ev: 1, or 0 when more bytes are needed, or -1 at
 * the end, or -2 while a subtree is being captured (a caller's mistake,
 * not the stream's: the reader is not failed); r->failed with r->err on
 * a refusal */
static int
frx_reader_next(frx_reader *r, frx_event *ev)
{
    if (r->failed) return 0;
    if (r->capturing) return -2;
    if (r->pending_release) {
        frx_arena_release(&r->scratch, &r->mark);
        r->have_mark = 0;
        r->pending_release = 0;
    }
    for (;;) {
        if (r->qn) {
            r->cur = r->q[r->qh];
            r->qh  = (r->qh + 1) % FRX_READER_QUEUE;
            r->qn--;
            r->have_cur = 1;
            *ev = r->cur;
            if (r->cur.kind == FRX_END && r->cur.depth <= 2 && r->have_mark) r->pending_release = 1;
            return 1;
        }
        if (r->done) return -1;
        {
            int step = frx_reader_pump(r);
            if (step == FRX_STEP_FAIL) return 0;
            if (step == FRX_STEP_MORE) return 0;
            if (step == FRX_STEP_EOF) {
                r->done = 1;
                if (!frx_parse_finish(&r->p, r->dropped + r->in.len)) { r->err = r->p.err; r->failed = 1; return 0; }
            }
        }
    }
}

/* a Document for the element of the current start event: 1 with *out,
 * 0 when more bytes are needed (feed, call again), -2 when the current
 * event is not a start (the reader is not failed), and r->failed on a
 * refusal */
static int
frx_reader_subtree(frx_reader *r, frx_doc **out)
{
    *out = NULL;
    if (r->failed) return 0;
    if (!r->capturing) {
        frx_doc *d;
        frx_ev_start ev;
        if (!r->have_cur || r->cur.kind != FRX_START) return -2;
        d = frx_doc_new();
        if (!d) return FRX_READER_FAIL(r, FRX_E_NOMEM, r->cur.offset, "out of memory");
        d->profile   = r->profile;
        d->max_depth = r->p.max_depth;
        d->document  = frx_node_new(d, FRX_DOCUMENT, 0);
        if (!d->document) { frx_doc_free(d); return FRX_READER_FAIL(r, FRX_E_NOMEM, r->cur.offset, "out of memory"); }
        frx_tree_sink_init(&r->cap_sink, d, 1);
        r->cap_doc   = d;
        r->cap_depth = r->cur.depth + 1;
        memset(&ev, 0, sizeof ev);
        ev.qname   = r->cur.qname;  ev.prefix = r->cur.prefix; ev.local = r->cur.local; ev.ns = r->cur.ns;
        ev.attrs   = r->cur.attrs;  ev.n_attrs = r->cur.n_attrs;
        ev.decls   = r->cur.decls;  ev.n_decls = r->cur.n_decls;
        ev.scope   = r->cur.scope;  ev.offset  = r->cur.offset; ev.empty = r->cur.empty;
        if (!frx_tree_sink_start(&r->p, &r->cap_sink, &ev)) { r->err = r->p.err; r->failed = 1; return 0; }
        if (r->cur.empty) {
            *out = d;
            r->cap_doc = NULL;
            frx_tree_sink_free(&r->cap_sink);
            if (r->cap_depth <= 2 && r->have_mark) r->pending_release = 1;
            return 1;
        }
        r->capturing = 1;
        r->p.sink = &FRX_TREE_SINK;
        r->p.ud   = &r->cap_sink;
        r->p.split_entities = 0;
    }
    for (;;) {
        int step = frx_reader_pump(r);
        if (step == FRX_STEP_FAIL) return 0;
        if (step == FRX_STEP_MORE) return 0;
        if (step == FRX_STEP_EOF) {
            r->done = 1;
            return FRX_READER_FAIL(r, FRX_E_SYNTAX, r->dropped + r->in.len, "the input ended inside the subtree");
        }
        if (r->p.depth < r->cap_depth) break;      /* its end tag has been read */
    }
    r->capturing = 0;
    r->p.sink = &FRX_READER_SINK;
    r->p.ud   = r;
    r->p.split_entities = 1;
    *out = r->cap_doc;
    r->cap_doc = NULL;
    frx_tree_sink_free(&r->cap_sink);
    if (r->cap_depth <= 2 && r->have_mark) r->pending_release = 1;
    return 1;
}

#endif /* FRX_READER_H */
