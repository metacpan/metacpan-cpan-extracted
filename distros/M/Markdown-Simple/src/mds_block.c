/* mds_block.c — scalar CommonMark block scanner.
 *
 * Scope:
 *   - Thematic break (§4.1)
 *   - ATX heading (§4.2)
 *   - Fenced code (§4.5)
 *   - Paragraph (§4.8)
 *   - Block quote (§5.1) with lazy continuation
 *   - Bullet list + ordered list + list item (§5.2, §5.3)
 *
 * Inline content is emitted as raw text via cb->text; the inline
 * tokeniser handles it downstream.
 */

#include "mds_block.h"
#include "mds_ir.h"
#include "mds_ctx.h"
#include "mds_arena.h"
#include "mds_linkref.h"
#include "mds_footnote.h"

/* Forward decl — defined in mds_render_html.c which is unity-included
 * AFTER this file. Used to emit the footnotes section in first-use
 * order. NULL-safe in the unlikely case the caller installs a non-HTML
 * renderer; iteration just stops at index 0. */
int mds_render_html_used_footnote(void* ud, size_t i,
                                  const char** label_out,
                                  size_t* label_len_out);
#include "mds_inline.h"
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#define MAX_DEPTH 1000

typedef enum { CT_DOC, CT_QUOTE, CT_LIST, CT_LIST_ITEM } ct_kind;

typedef struct {
    ct_kind kind;
    int     ordered;
    int     start;
    char    marker;
    int     tight;
    int     had_blank_inside;
    int     pending_blank;        /* CT_LIST only: a blank line was seen, awaiting next non-blank to decide loose-ness */
    int     content_col;
    int     opened;
    int     ev_idx;        /* index of the buffered enter_block event */
    int     is_empty;      /* CT_LIST_ITEM only: opened with no content */
    int     blank_after_empty; /* CT_LIST_ITEM only: blank line seen while still empty */
} ctn;

typedef enum {
    LF_NONE,
    LF_PARAGRAPH,
    LF_CODE_FENCED,
    LF_CODE_INDENTED,
    LF_HTML
} leaf_kind;

typedef enum {
    EV_ENTER_BLOCK,
    EV_LEAVE_BLOCK,
    EV_TEXT,
    EV_RAW,
    EV_INLINE   /* bytes need mds_inline_scan at flush time */
} ev_type;

typedef struct {
    ev_type type;
    union {
        struct { mds_block_type t; mds_block_detail d; const char* info_ptr; size_t info_len; } enter;
        struct { mds_block_type t; } leave;
        struct { size_t off; size_t len; } bytes;
    } u;
} ev_rec;

typedef struct {
    mds_ctx*    ctx;
    ctn         stack[MAX_DEPTH];
    int         depth;
    int         list_depth;       /* # CT_LIST containers currently on stack */
    leaf_kind   leaf;
    int         leaf_in_container;

    char*       para;
    size_t      para_len;
    size_t      para_cap;

    char        fence_char;
    int         fence_len;
    int         fence_indent;
    char*       fence_info;
    size_t      fence_info_len;
    char*       code_body;
    size_t      code_len;
    size_t      code_cap;
    int         pending_blanks;
    int         blank_pending;    /* 1 = blank line seen, attribute to deepest surviving CT_LIST after next walk */
    int         setext_level;
    int         html_type;        /* 1..7 when leaf == LF_HTML */
    char*       html_body;
    size_t      html_len;
    size_t      html_cap;

    /* Event buffer used while list_depth > 0 so we can patch is_tight on
     * the LIST enter event once we know whether the list is loose. */
    ev_rec*     evbuf;
    size_t      ev_len;
    size_t      ev_cap;
    char*       bytepool;
    size_t      bp_len;
    size_t      bp_cap;
    char*       line_scratch;     /* per-line buffer for tab-expanded line copy */
    size_t      line_scratch_cap;
} bscanner;

/* ---------- heap buffer helpers ---------- */

static void buf_grow(char** buf, size_t* cap, size_t need) {
    size_t nc;
    if (need <= *cap) return;
    nc = *cap ? *cap : 256;
    while (nc < need) nc = nc + (nc >> 1) + 64;
    *buf = (char*)realloc(*buf, nc);
    *cap = nc;
}
static void buf_append(char** buf, size_t* len, size_t* cap,
                       const char* s, size_t n) {
    buf_grow(buf, cap, *len + n + 1);
    memcpy(*buf + *len, s, n);
    *len += n;
    (*buf)[*len] = '\0';
}

/* ---------- SAX dispatch (buffered while inside a list) ---------- */

static size_t pool_intern(bscanner* b, const char* s, size_t n) {
    size_t off;
    buf_grow(&b->bytepool, &b->bp_cap, b->bp_len + n + 1);
    off = b->bp_len;
    if (n) memcpy(b->bytepool + off, s, n);
    b->bp_len += n;
    return off;
}
static ev_rec* ev_alloc(bscanner* b) {
    if (b->ev_len == b->ev_cap) {
        size_t nc = b->ev_cap ? b->ev_cap * 2 : 64;
        b->evbuf = (ev_rec*)realloc(b->evbuf, nc * sizeof(ev_rec));
        b->ev_cap = nc;
    }
    return &b->evbuf[b->ev_len++];
}

static int sax_enter(bscanner* b, mds_block_type t, const mds_block_detail* d) {
    /* Always buffer at document level: defers inline_scan until linkref
     * table is fully populated. Returns the event index. */
    {
        ev_rec* e = ev_alloc(b);
        e->type = EV_ENTER_BLOCK;
        e->u.enter.t = t;
        e->u.enter.d = d ? *d : (mds_block_detail){0};
        e->u.enter.info_ptr = NULL;
        e->u.enter.info_len = 0;
        if (t == MDS_BLK_CODE_FENCED && d && d->u.code_fenced.info_len) {
            size_t off = pool_intern(b, d->u.code_fenced.info, d->u.code_fenced.info_len);
            e->u.enter.info_ptr = (const char*)(uintptr_t)off;
            e->u.enter.info_len = d->u.code_fenced.info_len;
        }
        return (int)(b->ev_len - 1);
    }
}
static void sax_leave(bscanner* b, mds_block_type t) {
    ev_rec* e = ev_alloc(b);
    e->type = EV_LEAVE_BLOCK;
    e->u.leave.t = t;
}
static void sax_text(bscanner* b, const char* s, size_t n) {
    size_t off = pool_intern(b, s, n);
    ev_rec* e = ev_alloc(b);
    e->type = EV_TEXT;
    e->u.bytes.off = off;
    e->u.bytes.len = n;
}
static void sax_raw(bscanner* b, const char* s, size_t n) {
    size_t off = pool_intern(b, s, n);
    ev_rec* e = ev_alloc(b);
    e->type = EV_RAW;
    e->u.bytes.off = off;
    e->u.bytes.len = n;
}

static void sax_inline_text(bscanner* b, const char* s, size_t n) {
    size_t off = pool_intern(b, s, n);
    ev_rec* e = ev_alloc(b);
    e->type = EV_INLINE;
    e->u.bytes.off = off;
    e->u.bytes.len = n;
}

static void sax_flush(bscanner* b) {
    /* Hoist the callback table and bytepool base out of
     * the per-event loop. The callbacks are guaranteed non-NULL by the
     * HTML renderer setup, but the scanner has to remain generic, so
     * we still null-check; MDS_LIKELY tells the compiler to fall
     * through (the renderer is by far the most common consumer). */
    const mds_callbacks cb = b->ctx->cb;
    void* const ud         = b->ctx->ud;
    const char* const pool = b->bytepool;
    const size_t n         = b->ev_len;
    ev_rec* const evs      = b->evbuf;
    for (size_t i = 0; i < n; i++) {
        ev_rec* e = &evs[i];
        switch (e->type) {
        case EV_ENTER_BLOCK:
            if (e->u.enter.t == MDS_BLK_CODE_FENCED && e->u.enter.info_len) {
                size_t off = (size_t)(uintptr_t)e->u.enter.info_ptr;
                e->u.enter.d.u.code_fenced.info = pool + off;
                e->u.enter.d.u.code_fenced.info_len = e->u.enter.info_len;
            }
            if (MDS_LIKELY(cb.enter_block != NULL))
                cb.enter_block(ud, e->u.enter.t, &e->u.enter.d);
            break;
        case EV_LEAVE_BLOCK:
            if (MDS_LIKELY(cb.leave_block != NULL))
                cb.leave_block(ud, e->u.leave.t);
            break;
        case EV_TEXT:
            if (MDS_LIKELY(cb.text != NULL))
                cb.text(ud, pool + e->u.bytes.off, e->u.bytes.len);
            break;
        case EV_RAW:
            if (MDS_LIKELY(cb.raw != NULL))
                cb.raw(ud, pool + e->u.bytes.off, e->u.bytes.len);
            break;
        case EV_INLINE:
            mds_inline_scan(b->ctx, pool + e->u.bytes.off, e->u.bytes.len);
            break;
        }
    }
    b->ev_len = 0;
    b->bp_len = 0;
}

/* ---------- container helpers ---------- */

static ctn* top(bscanner* b) { return &b->stack[b->depth - 1]; }

static int push(bscanner* b, ct_kind k) {
    ctn* c;
    if (b->depth >= MAX_DEPTH) return 0;
    c = &b->stack[b->depth++];
    memset(c, 0, sizeof *c);
    c->kind   = k;
    c->tight  = 1;
    c->ev_idx = -1;
    if (k == CT_LIST) b->list_depth++;
    return 1;
}

/* ---------- forward decls ---------- */

static void emit_open(bscanner* b, int idx);
static void emit_close(bscanner* b, ctn* c);
static void finalize_leaf(bscanner* b);
static void close_containers_to(bscanner* b, int target_depth);

/* ---------- link reference definition extractor ----------
 *
 * Tries to consume one definition starting at *p_in. Returns 1 if one was
 * fully parsed, 0 otherwise. On success updates *p_in past the end of the
 * definition.
 *
 * Grammar (simplified subset):
 *   ^ {0,3} '[' label ']' ':' ws+ url (ws+ title)? ws* \n?
 *   - label may contain anything but ']', '[', '\n' (no nesting).
 *   - url either <bracketed> with no '<>' inside, or a bareword with no
 *     spaces (parens balanced not enforced here).
 *   - title in "...", '...', or (...), possibly on next line.
 */
static int parse_linkref(const char* p, const char* end, const char** p_out,
                         const char** lbl_s, const char** lbl_e,
                         const char** url_s, const char** url_e,
                         const char** tit_s, const char** tit_e) {
    const char* q;
    int lead;
    const char* ls;
    int label_nl;
    const char* r;
    const char* le;
    int has_nonws;
    int nl;
    const char *us, *ue;
    const char *ts, *te;
    const char* save_after_url;
    int saw_nl;
    int saw_ws;
    char open, close;
    int blank_found;
    const char* check;

    q = p;
    lead = 0;
    while (q < end && *q == ' ' && lead < 3) { q++; lead++; }
    if (q >= end || *q != '[') return 0;
    q++;
    ls = q;
    /* Label may span multiple lines (no blank line). Allow \] inside. */
    label_nl = 0;
    while (q < end && *q != ']') {
        if (*q == '\\' && q + 1 < end) { q += 2; continue; }
        if (*q == '[') return 0;
        if (*q == '\n') {
            if (++label_nl > 0) {
                /* check for blank line */
                r = q + 1;
                while (r < end && (*r == ' ' || *r == '\t')) r++;
                if (r >= end || *r == '\n') return 0;
            }
        }
        q++;
    }
    if (q >= end || *q != ']') return 0;
    le = q;
    if (le == ls) return 0;          /* empty label invalid */
    /* Label must contain at least one non-whitespace char. */
    has_nonws = 0;
    for (r = ls; r < le; r++) {
        if (*r != ' ' && *r != '\t' && *r != '\n') { has_nonws = 1; break; }
    }
    if (!has_nonws) return 0;
    q++;
    if (q >= end || *q != ':') return 0;
    q++;
    /* whitespace, may include up to one newline */
    nl = 0;
    while (q < end && (*q == ' ' || *q == '\t' || *q == '\n')) {
        if (*q == '\n') { if (++nl > 1) return 0; }
        q++;
    }
    if (q >= end) return 0;
    /* url */
    if (*q == '<') {
        q++;
        us = q;
        while (q < end && *q != '>' && *q != '\n' && *q != '<') q++;
        if (q >= end || *q != '>') return 0;
        ue = q;
        q++;
    } else {
        us = q;
        while (q < end && *q != ' ' && *q != '\t' && *q != '\n') {
            /* disallow ASCII control */
            if ((unsigned char)*q < 0x20) return 0;
            q++;
        }
        ue = q;
        if (ue == us) return 0;
    }
    /* optional title — must be separated from URL by at least one ws char
     * (per CM §4.7). Without separator, '<bar>(baz)' is not a valid def. */
    ts = NULL; te = NULL;
    save_after_url = q;
    saw_nl = 0;
    saw_ws = 0;
    while (q < end && (*q == ' ' || *q == '\t' || *q == '\n')) {
        if (*q == '\n') saw_nl++;
        saw_ws = 1;
        q++;
    }
    if (q < end && (*q == '"' || *q == '\'' || *q == '(') && saw_nl <= 1 && saw_ws) {
        open = *q;
        close = (open == '(') ? ')' : open;
        q++;
        ts = q;
        /* Title may span multiple lines but cannot contain a blank line.
           Detect blank line as: \n followed by (spaces|tabs)* \n . */
        blank_found = 0;
        while (q < end && *q != close) {
            if (open != '(' && *q == '\\' && q + 1 < end) { q += 2; continue; }
            if (open == '(' && *q == '(') { /* unescaped '(' invalid in paren title */
                blank_found = 1; break;
            }
            if (*q == '\n') {
                r = q + 1;
                while (r < end && (*r == ' ' || *r == '\t')) r++;
                if (r >= end || *r == '\n') { blank_found = 1; break; }
            }
            q++;
        }
        if (blank_found) { ts = NULL; te = NULL; q = save_after_url; goto end_title; }
        if (q < end && *q == close) {
            te = q;
            q++;
            /* nothing but ws/newline allowed on remainder of title-line */
            check = q;
            while (check < end && check < end && *check != '\n') {
                if (*check != ' ' && *check != '\t') { ts = NULL; te = NULL; q = save_after_url; goto end_title; }
                check++;
            }
        } else {
            ts = NULL; te = NULL;
            q = save_after_url;
        }
    } else {
        q = save_after_url;
    }
end_title:
    /* consume trailing ws + one newline */
    while (q < end && (*q == ' ' || *q == '\t')) q++;
    if (q < end && *q == '\n') q++;
    else if (q < end) {
        /* trailing content on same line invalidates the title; reparse without title */
        if (ts) {
            ts = NULL; te = NULL;
            q = save_after_url;
            while (q < end && (*q == ' ' || *q == '\t')) q++;
            if (q < end && *q == '\n') q++;
            else if (q < end) return 0;
        } else {
            return 0;
        }
    }
    *p_out = q;
    *lbl_s = ls; *lbl_e = le;
    *url_s = us; *url_e = ue;
    *tit_s = ts; *tit_e = te;
    return 1;
}

static void ensure_linkref_tab(mds_ctx* ctx) {
    if (ctx->refs) return;
    ctx->refs = (struct mds_linkref_tab*)mds_arena_alloc(
        &ctx->arena, sizeof(struct mds_linkref_tab));
    mds_linkref_init(ctx->refs, &ctx->arena);
}

static void ensure_footnote_tab(mds_ctx* ctx) {
    if (ctx->footnotes) return;
    ctx->footnotes = (struct mds_footnote_tab*)mds_arena_alloc(
        &ctx->arena, sizeof(struct mds_footnote_tab));
    mds_footnote_init(ctx->footnotes, &ctx->arena);
}

/* Tier E.1 (extended) — line-level preprocessing pass that walks the input
 * once, identifies top-level `[^label]:` definitions, captures their
 * multi-line bodies (continuation = blank lines or 4-space-indented lines,
 * with 4-space dedent), registers them in the footnote table, and returns
 * a cleaned input with those lines elided. Only invoked when
 * MDS_FLAG_FOOTNOTES is set. Tracks fenced-code state to avoid matching
 * `[^…]:` inside fenced blocks.
 *
 * The cleaned buffer is allocated from the arena so it survives the
 * lifetime of the scan; the original ctx->input is left in place for
 * sub-scans (which re-run mds_block_scan on individual def bodies).
 *
 * NOTE: this is a coarse, document-level pass — defs nested inside list
 * items or blockquotes are still handled by finalize_paragraph's leading-
 * defs strip. */
static void preprocess_footnotes(mds_ctx* ctx) {
    const char* in;
    size_t      ilen;
    char*  out;
    size_t olen;
    const char* p;
    const char* end;
    int in_fence;
    char fence_ch;
    int fence_len;
    const char* le;
    const char* nxt;
    size_t lsz;
    const char* q;
    int ind;
    int run;
    const char* tail;
    char fc;
    int fl;
    const char *lbs, *lbe, *bs;
    char* body;
    size_t blen;
    const char *le2, *nxt2;
    int blank;
    const char* r;
    int sp;

    in   = ctx->input;
    ilen = ctx->len;
    if (!ilen) return;

    /* Worst-case: same size as input. */
    out = (char*)mds_arena_alloc(&ctx->arena, ilen + 1);
    olen = 0;

    p   = in;
    end = in + ilen;
    in_fence = 0;
    fence_ch = 0;
    fence_len = 0;

    while (p < end) {
        le = (const char*)memchr(p, '\n', (size_t)(end - p));
        if (!le) le = end;
        nxt = (le < end) ? le + 1 : end;
        lsz = (size_t)(nxt - p);

        /* Walk up to 3 leading spaces. */
        q = p;
        ind = 0;
        while (q < le && *q == ' ' && ind < 3) { q++; ind++; }

        if (in_fence) {
            /* Close-fence detection: run of fence_ch ≥ fence_len, then ws. */
            run = 0;
            while (q + run < le && q[run] == fence_ch) run++;
            if (run >= fence_len) {
                tail = q + run;
                while (tail < le && (*tail == ' ' || *tail == '\t')) tail++;
                if (tail == le) in_fence = 0;
            }
            memcpy(out + olen, p, lsz); olen += lsz;
            p = nxt;
            continue;
        }

        /* Open-fence detection. */
        if (le - q >= 3 && (q[0] == '`' || q[0] == '~') && q[1] == q[0] && q[2] == q[0]) {
            fc = q[0];
            fl = 3;
            while (q + fl < le && q[fl] == fc) fl++;
            /* Tilde fences can have any info; backtick fences must not
             * contain backticks in info — but for our purposes (we only
             * care about hiding defs inside the fence body) treat both
             * the same. */
            fence_ch = fc;
            fence_len = fl;
            in_fence = 1;
            memcpy(out + olen, p, lsz); olen += lsz;
            p = nxt;
            continue;
        }

        /* Footnote def? `[^label]:` */
        if (le - q >= 4 && q[0] == '[' && q[1] == '^') {
            lbs = q + 2;
            lbe = lbs;
            while (lbe < le && *lbe != ']' && *lbe != '[' && *lbe != '\n') lbe++;
            if (lbe < le && *lbe == ']' && lbe > lbs &&
                lbe + 1 < le && lbe[1] == ':') {
                /* Match. Capture body. */
                bs = lbe + 2;
                while (bs < le && (*bs == ' ' || *bs == '\t')) bs++;

                /* Body buffer (arena). Worst case the rest of the input. */
                body = (char*)mds_arena_alloc(&ctx->arena,
                                              (size_t)(end - bs) + 1);
                blen = 0;
                if (bs < le) {
                    memcpy(body + blen, bs, (size_t)(le - bs));
                    blen += (size_t)(le - bs);
                }

                p = nxt;
                /* Continuation lines: blank OR ≥4 spaces (or 1 tab) leading. */
                while (p < end) {
                    le2 = (const char*)memchr(p, '\n', (size_t)(end - p));
                    if (!le2) le2 = end;
                    nxt2 = (le2 < end) ? le2 + 1 : end;

                    /* Blank? (only ws up to newline) */
                    blank = 1;
                    for (r = p; r < le2; r++) {
                        if (*r != ' ' && *r != '\t') { blank = 0; break; }
                    }
                    if (blank) {
                        body[blen++] = '\n';
                        p = nxt2;
                        continue;
                    }

                    /* Check ≥4 leading spaces (or one tab counts as 4). */
                    sp = 0;
                    r = p;
                    while (r < le2 && sp < 4) {
                        if (*r == ' ') { sp++; r++; }
                        else if (*r == '\t') { sp = 4; r++; break; }
                        else break;
                    }
                    if (sp < 4) break;  /* end of def body */

                    body[blen++] = '\n';
                    if (le2 > r) {
                        memcpy(body + blen, r, (size_t)(le2 - r));
                        blen += (size_t)(le2 - r);
                    }
                    p = nxt2;
                }

                /* Strip trailing blank/whitespace bytes for tidy rendering. */
                while (blen > 0 && (body[blen-1] == '\n' ||
                                    body[blen-1] == ' '  ||
                                    body[blen-1] == '\t')) blen--;

                ensure_footnote_tab(ctx);
                mds_footnote_add(ctx->footnotes,
                                 lbs, (size_t)(lbe - lbs),
                                 body, blen);
                /* Do NOT copy these lines into out. */
                continue;
            }
        }

        /* Default: copy line. */
        memcpy(out + olen, p, lsz); olen += lsz;
        p = nxt;
    }

    out[olen] = '\0';
    ctx->input = out;
    ctx->len   = olen;
}

/* GFM footnote definition: ` {0,3}[^label]:` followed by body bytes
 * (continuation rules collapsed in this MVP — body is whatever remains
 * of the paragraph buffer up to the next `[^...]:` line or end). Returns
 * 1 if a def was consumed, advancing *p_in. Body bytes are the slice
 * [body_s..body_e). */
static int parse_footnote_def(const char* p, const char* end,
                              const char** p_out,
                              const char** lbl_s, const char** lbl_e,
                              const char** body_s, const char** body_e) {
    const char* q;
    int lead;
    const char* ls;
    const char* le;
    const char* bs;
    const char* be;
    const char* nxt;
    const char* r;
    int rlead;
    const char* rr;

    q = p;
    lead = 0;
    while (q < end && *q == ' ' && lead < 3) { q++; lead++; }
    if (end - q < 4) return 0;
    if (q[0] != '[' || q[1] != '^') return 0;
    q += 2;
    ls = q;
    while (q < end && *q != ']' && *q != '\n' && *q != '[') q++;
    if (q >= end || *q != ']' || q == ls) return 0;
    le = q;
    q++;
    if (q >= end || *q != ':') return 0;
    q++;
    /* Spec: any number of spaces/tabs follow; they are stripped. */
    while (q < end && (*q == ' ' || *q == '\t')) q++;
    /* Body runs until the next bare-line `[^...]:` or end of buffer.
     * In this MVP we accept body across newlines but NOT across blank
     * lines (the para buffer would already have been split). */
    bs = q;
    be = q;
    while (q < end) {
        if (*q == '\n') {
            nxt = q + 1;
            /* Peek next line: another `[^...]:` ? -> stop here. */
            r = nxt;
            rlead = 0;
            while (r < end && *r == ' ' && rlead < 3) { r++; rlead++; }
            if (end - r >= 4 && r[0] == '[' && r[1] == '^') {
                rr = r + 2;
                while (rr < end && *rr != ']' && *rr != '\n' && *rr != '[') rr++;
                if (rr < end && *rr == ']' && rr + 1 < end && rr[1] == ':') {
                    be = q;        /* don't include the \n */
                    q = nxt;       /* next def starts here */
                    goto done;
                }
            }
            be = q + 1;  /* keep the \n in body */
            q = nxt;
            continue;
        }
        q++;
    }
    be = q;
done:
    *p_out = q;
    *lbl_s = ls; *lbl_e = le;
    *body_s = bs; *body_e = be;
    return 1;
}

/* ---------- GFM tables ---------- */

#include "mds.h"

static const char* next_line(const char* p, const char* end,
                             const char** line_end_out);

#define MDS_TBL_MAX_COLS 64

/* Tables: memchr-driven pipe scan. libc memchr is SIMD-vectorised
 * on every platform we care about (Apple libSystem uses NEON, glibc uses
 * AVX2), so iterating candidate pipes is dramatically faster than a
 * byte-by-byte loop. We confirm each pipe is unescaped by counting the
 * run of preceding backslashes — odd count means escaped. */
MDS_HOT
static const char* tbl_find_pipe(const char* p, const char* end) {
    const char* q;
    const char* bs;

    while (p < end) {
        q = (const char*)memchr(p, '|', (size_t)(end - p));
        if (!q) return NULL;
        /* Count preceding backslashes. */
        bs = q;
        while (bs > p && bs[-1] == '\\') bs--;
        if (((q - bs) & 1u) == 0u) return q;   /* even ⇒ unescaped */
        p = q + 1;
    }
    return NULL;
}

/* Does the cell contain a backslash? Cheap check that lets the fast
 * path skip the per-byte unescape pass entirely. */
MDS_ALWAYS_INLINE static int tbl_cell_needs_unescape(const char* s, size_t n) {
    return memchr(s, '\\', n) != NULL;
}

/* Split a line on unescaped '|', trimming leading/trailing whitespace
 * and any single leading/trailing pipe. Writes (start,len) pairs to
 * cells[] up to max_cells. Returns the cell count (without truncation). */
static unsigned tbl_split_cells(const char* line, size_t len,
                                const char** out_s, size_t* out_n,
                                unsigned max_cells) {
    const char* p;
    const char* end;
    int esc;
    const char* q;
    unsigned count;
    const char* pipe;
    const char* cell_end;
    const char* cs;
    const char* ce;

    p = line;
    end = line + len;
    /* Trim outer whitespace. */
    while (p < end && (*p == ' ' || *p == '\t')) p++;
    while (end > p && (end[-1] == ' ' || end[-1] == '\t')) end--;
    /* Strip a single leading unescaped pipe. */
    if (p < end && *p == '|') p++;
    /* Strip a single trailing unescaped pipe (must not be escaped). */
    if (end > p && end[-1] == '|') {
        esc = 0;
        q = end - 1;
        while (q > p && q[-1] == '\\') { esc = !esc; q--; }
        if (!esc) end--;
    }
    count = 0;
    while (p <= end) {
        pipe = tbl_find_pipe(p, end);
        cell_end = pipe ? pipe : end;
        cs = p;
        ce = cell_end;
        while (cs < ce && (*cs == ' ' || *cs == '\t')) cs++;
        while (ce > cs && (ce[-1] == ' ' || ce[-1] == '\t')) ce--;
        if (count < max_cells) {
            out_s[count] = cs;
            out_n[count] = (size_t)(ce - cs);
        }
        count++;
        if (!pipe) break;
        p = pipe + 1;
    }
    return count;
}

/* Parse a separator row: zero or more spaces, optional |, then per cell
 * `:?-+:?` separated by `|`, optional trailing |. Returns cell count and
 * fills aligns[]. Returns 0 if not a valid separator. */
static unsigned tbl_parse_separator(const char* line, size_t len,
                                    mds_align* aligns, unsigned max_cells) {
    const char* p;
    const char* end;
    unsigned count;
    const char* cs;
    const char* ce;
    int left, right;
    const char* q;

    p = line;
    end = line + len;
    while (p < end && (*p == ' ' || *p == '\t')) p++;
    while (end > p && (end[-1] == ' ' || end[-1] == '\t')) end--;
    if (p >= end) return 0;
    if (*p == '|') p++;
    /* Strip trailing |. */
    if (end > p && end[-1] == '|') end--;
    count = 0;
    while (p <= end) {
        cs = p;
        while (p < end && *p != '|') p++;
        ce = p;
        /* Trim spaces around the cell. */
        while (cs < ce && (*cs == ' ' || *cs == '\t')) cs++;
        while (ce > cs && (ce[-1] == ' ' || ce[-1] == '\t')) ce--;
        if (cs >= ce) return 0;
        left = (*cs == ':');
        if (left) cs++;
        right = (ce > cs && ce[-1] == ':');
        if (right) ce--;
        if (cs >= ce) return 0;
        for (q = cs; q < ce; q++)
            if (*q != '-') return 0;
        if (count < max_cells) {
            aligns[count] = left && right ? MDS_ALIGN_CENTER :
                            left          ? MDS_ALIGN_LEFT   :
                            right         ? MDS_ALIGN_RIGHT  : MDS_ALIGN_NONE;
        }
        count++;
        if (p >= end) break;
        p++; /* skip '|' */
    }
    return count;
}

/* Returns the next newline in [p,end) or end. *le_out is the line end
 * (excluding CR). */
static const char* tbl_next_line(const char* p, const char* end, const char** le_out) {
    const char* nl = (const char*)memchr(p, '\n', (size_t)(end - p));
    const char* le = nl ? nl : end;
    if (le > p && le[-1] == '\r') le--;
    *le_out = le;
    return nl ? nl + 1 : end;
}

/* Returns 1 when the cell text has no byte that could begin an inline
 * construct, so the inline scanner can be bypassed entirely and the
 * text emitted as a plain EV_TEXT event. Mirrors the trigger set used
 * by mds_inline_scan's fast path. Tables of single-word cells (the
 * common case in real-world reports) hit this on every cell. */
MDS_ALWAYS_INLINE static int tbl_cell_is_plain(const char* s, size_t n) {
    if (n == 0) return 1;
    for (size_t i = 0; i < n; i++) {
        unsigned char c = (unsigned char)s[i];
        if (c == '*' || c == '_' || c == '~' || c == '`'  ||
            c == '['  || c == ']' || c == '!' || c == '<'  ||
            c == '&'  || c == '\\' || c == '\n')
            return 0;
    }
    /* Reject trailing double-space (CommonMark hard-break candidate). */
    if (n >= 2 && s[n-1] == ' ' && s[n-2] == ' ') return 0;
    return 1;
}

/* Emit a row whose cells are already split (cs[i], cn[i]).
 * `count` is the number of cells the split produced; we always emit
 * exactly `nhead` cells, padding with empties if needed. */
MDS_HOT
static void tbl_emit_row_pre(bscanner* b,
                             const char* const* cs, const size_t* cn,
                             unsigned count,
                             const mds_align* aligns, unsigned nhead) {
    mds_block_detail d;
    unsigned i;
    mds_block_detail cd;
    const char* s;
    size_t      n;
    size_t off;
    char* dst;
    size_t bl;
    size_t j;
    ev_rec* e;

    d.u.table_cell.align = MDS_ALIGN_NONE;     /* placeholder, row has no align */
    sax_enter(b, MDS_BLK_TABLE_ROW, &d);
    for (i = 0; i < nhead; i++) {
        cd.u.table_cell.align = aligns[i];
        sax_enter(b, MDS_BLK_TABLE_CELL, &cd);
        if (i < count && cn[i]) {
            s = cs[i];
            n = cn[i];
            if (MDS_LIKELY(!tbl_cell_needs_unescape(s, n))) {
                /* Fast path: no '\\' anywhere in the cell. If the cell
                 * is also free of inline triggers (the common single-
                 * word case), emit EV_TEXT directly so sax_flush calls
                 * cb.text without going through mds_inline_scan. Else
                 * fall back to EV_INLINE. Both branches use the same
                 * pool_intern, so input bytes are never double-copied. */
                if (MDS_LIKELY(tbl_cell_is_plain(s, n))) {
                    sax_text(b, s, n);
                } else {
                    sax_inline_text(b, s, n);
                }
            } else {
                /* Slow path: copy-and-unescape '\\|' → '|' in one pass
                 * directly into the bytepool, then record the event. */
                buf_grow(&b->bytepool, &b->bp_cap, b->bp_len + n + 1);
                off = b->bp_len;
                dst = b->bytepool + off;
                bl = 0;
                for (j = 0; j < n; j++) {
                    if (s[j] == '\\' && j + 1 < n && s[j+1] == '|') {
                        dst[bl++] = '|'; j++;
                    } else {
                        dst[bl++] = s[j];
                    }
                }
                b->bp_len += bl;
                e = ev_alloc(b);
                e->type = EV_INLINE;
                e->u.bytes.off = off;
                e->u.bytes.len = bl;
            }
        }
        sax_leave(b, MDS_BLK_TABLE_CELL);
    }
    sax_leave(b, MDS_BLK_TABLE_ROW);
}

/* Convenience wrapper for body rows: split + emit. */
MDS_HOT
static void tbl_emit_row(bscanner* b, const char* line, size_t len,
                         const mds_align* aligns, unsigned nhead) {
    const char* cs[MDS_TBL_MAX_COLS];
    size_t      cn[MDS_TBL_MAX_COLS];
    unsigned count;

    count = tbl_split_cells(line, len, cs, cn, MDS_TBL_MAX_COLS);
    tbl_emit_row_pre(b, cs, cn, count, aligns, nhead);
}

/* Cheap detection: returns 1 if the first two lines starting at p form a
 * valid GFM table header + separator (matching column count). Emits nothing. */
static int tbl_peek_header(const char* p, const char* end) {
    const char* le1;
    const char* p2;
    const char* hs[MDS_TBL_MAX_COLS];
    size_t      hn[MDS_TBL_MAX_COLS];
    unsigned nhead;
    const char* le2;
    mds_align aligns[MDS_TBL_MAX_COLS];
    unsigned nsep;

    memset(aligns, 0, sizeof aligns);
    p2 = tbl_next_line(p, end, &le1);
    if (p2 >= end) return 0;
    if (!tbl_find_pipe(p, le1)) return 0;
    nhead = tbl_split_cells(p, (size_t)(le1 - p), hs, hn, MDS_TBL_MAX_COLS);
    if (nhead < 1 || nhead > MDS_TBL_MAX_COLS) return 0;
    (void)tbl_next_line(p2, end, &le2);
    nsep = tbl_parse_separator(p2, (size_t)(le2 - p2), aligns, MDS_TBL_MAX_COLS);
    return (nsep == nhead);
}

/* Attempt to emit a table starting at the given paragraph buffer.
 * Returns the number of bytes consumed, or 0 if no table starts here. */
static size_t try_emit_table(bscanner* b, const char* p, const char* end) {
    /* Read first line. */
    const char* le1;
    const char* p2;
    const char* hs[MDS_TBL_MAX_COLS];
    size_t      hn[MDS_TBL_MAX_COLS];
    unsigned nhead;
    const char* le2;
    const char* p3;
    mds_align aligns[MDS_TBL_MAX_COLS];
    unsigned nsep;
    mds_block_detail d;
    mds_align* alstore;
    mds_block_detail hd;
    const char* row;
    int body_open;
    const char* le;
    const char* nx;
    mds_block_detail bd;

    memset(aligns, 0, sizeof aligns);
    p2 = tbl_next_line(p, end, &le1);
    if (p2 >= end) return 0;  /* need a second line */
    /* Header must contain at least one unescaped pipe. */
    if (!tbl_find_pipe(p, le1)) return 0;
    /* Count header cells. */
    nhead = tbl_split_cells(p, (size_t)(le1 - p), hs, hn, MDS_TBL_MAX_COLS);
    if (nhead < 1 || nhead > MDS_TBL_MAX_COLS) return 0;
    /* Read separator line. */
    p3 = tbl_next_line(p2, end, &le2);
    nsep = tbl_parse_separator(p2, (size_t)(le2 - p2), aligns, MDS_TBL_MAX_COLS);
    if (nsep != nhead) return 0;
    /* Emit table. */
    memset(&d, 0, sizeof d);
    d.u.table.ncols = nhead;
    /* Persist aligns in arena so the renderer can see them. */
    alstore = (mds_align*)mds_arena_alloc(&b->ctx->arena,
                                          sizeof(mds_align) * nhead);
    memcpy(alstore, aligns, sizeof(mds_align) * nhead);
    d.u.table.aligns = alstore;
    sax_enter(b, MDS_BLK_TABLE, &d);
    /* Head. Reuse the already-split header instead of splitting again. */
    memset(&hd, 0, sizeof hd);
    sax_enter(b, MDS_BLK_TABLE_HEAD, &hd);
    tbl_emit_row_pre(b, hs, hn, nhead, aligns, nhead);
    sax_leave(b, MDS_BLK_TABLE_HEAD);
    /* Body: keep consuming lines that contain at least one unescaped pipe. */
    row = p3;
    body_open = 0;
    while (row < end) {
        nx = tbl_next_line(row, end, &le);
        if (le == row) { row = nx; break; }   /* blank */
        if (!tbl_find_pipe(row, le)) break;
        if (!body_open) {
            memset(&bd, 0, sizeof bd);
            sax_enter(b, MDS_BLK_TABLE_BODY, &bd);
            body_open = 1;
        }
        tbl_emit_row(b, row, (size_t)(le - row), aligns, nhead);
        row = nx;
    }
    if (body_open) sax_leave(b, MDS_BLK_TABLE_BODY);
    sax_leave(b, MDS_BLK_TABLE);
    return (size_t)(row - p);
}

/* ---------- leaf finalisation ---------- */

static void finalize_paragraph(bscanner* b) {
    /* Consume any leading link-reference and footnote definitions. */
    char* p;
    char* end;
    unsigned _bf;
    const char* np;
    const char *ls, *le_, *us, *ue, *ts, *te;
    const char *fls, *fle, *bs, *be;
    size_t blen;
    size_t rem;
    char c;
    size_t lead;
    int sx;
    mds_block_detail d;
    const char* tp;
    const char* tend;
    const char* run;
    const char* le;
    const char* nx;
    const char* re;
    size_t consumed;

    p = b->para;
    end = b->para + b->para_len;
    _bf = b->ctx->flags;
    while (p < end) {
        /* Footnote def MUST be checked before linkref, since a label
         * beginning with `^` would otherwise be eaten as a linkref. */
        if ((_bf & MDS_FLAG_FOOTNOTES)) {
            if (parse_footnote_def(p, end, &np, &fls, &fle, &bs, &be)) {
                ensure_footnote_tab(b->ctx);
                blen = (size_t)(be - bs);
                while (blen > 0 && (bs[blen - 1] == '\n' || bs[blen - 1] == ' ' ||
                                     bs[blen - 1] == '\t')) blen--;
                mds_footnote_add(b->ctx->footnotes,
                                 fls, (size_t)(fle - fls),
                                 bs, blen);
                p = (char*)np;
                continue;
            }
        }
        if (!(_bf & MDS_FLAG_NO_REFERENCES) &&
            parse_linkref(p, end, &np, &ls, &le_, &us, &ue, &ts, &te)) {
            ensure_linkref_tab(b->ctx);
            mds_linkref_add(b->ctx->refs,
                            ls, (size_t)(le_ - ls),
                            us, (size_t)(ue - us),
                            ts ? ts : "", ts ? (size_t)(te - ts) : 0);
            p = (char*)np;
            continue;
        }
        break;
    }
    /* Shift remaining content to the start of the buffer. */
    if (p > b->para) {
        rem = (size_t)(end - p);
        if (rem) memmove(b->para, p, rem);
        b->para_len = rem;
    }
    /* Trim trailing whitespace. */
    while (b->para_len > 0) {
        c = b->para[b->para_len - 1];
        if (c == ' ' || c == '\t' || c == '\n' || c == '\r') b->para_len--;
        else break;
    }
    /* Trim leading whitespace. */
    lead = 0;
    while (lead < b->para_len &&
           (b->para[lead] == ' ' || b->para[lead] == '\t' || b->para[lead] == '\n'))
        lead++;
    if (lead) { memmove(b->para, b->para + lead, b->para_len - lead); b->para_len -= lead; }
    if (b->para_len == 0) {
        b->setext_level = 0;
        return;
    }
    sx = b->setext_level;
    b->setext_level = 0;
    memset(&d, 0, sizeof d);
    if (sx) {
        d.u.heading.level = sx;
        sax_enter(b, MDS_BLK_HEADING, &d);
        sax_inline_text(b, b->para, b->para_len);
        sax_leave(b, MDS_BLK_HEADING);
    } else if ((b->ctx->flags & MDS_FLAG_TABLES) &&
               b->para_len >= 3) {
        /* Try GFM table detection: header line | separator. May appear
         * embedded — split paragraph into pre-text, table(s), post-text. */
        tp   = b->para;
        tend = b->para + b->para_len;
        run = tp;
        while (tp < tend) {
            /* find current line bounds */
            nx = next_line(tp, tend, &le);
            if (tbl_peek_header(tp, tend)) {
                /* flush any prior text as paragraph BEFORE emitting table */
                if (tp > run) {
                    re = tp;
                    while (re > run && (re[-1] == '\n' || re[-1] == '\r' ||
                                        re[-1] == ' '  || re[-1] == '\t')) re--;
                    if (re > run) {
                        sax_enter(b, MDS_BLK_PARAGRAPH, &d);
                        sax_inline_text(b, run, (size_t)(re - run));
                        sax_leave(b, MDS_BLK_PARAGRAPH);
                    }
                }
                consumed = try_emit_table(b, tp, tend);
                tp  = tp + consumed;
                run = tp;
                continue;
            }
            (void)le;
            tp = nx;
        }
        if (run < tend) {
            re = tend;
            while (re > run && (re[-1] == '\n' || re[-1] == '\r' ||
                                re[-1] == ' '  || re[-1] == '\t')) re--;
            if (re > run) {
                sax_enter(b, MDS_BLK_PARAGRAPH, &d);
                sax_inline_text(b, run, (size_t)(re - run));
                sax_leave(b, MDS_BLK_PARAGRAPH);
            }
        }
    } else {
        sax_enter(b, MDS_BLK_PARAGRAPH, &d);
        sax_inline_text(b, b->para, b->para_len);
        sax_leave(b, MDS_BLK_PARAGRAPH);
    }
    b->para_len = 0;
}

static void finalize_code_indented(bscanner* b) {
    size_t i;
    size_t ls;
    size_t j;
    int blank;
    mds_block_detail d;
    /* Strip trailing blank lines. */
    while (b->code_len > 0) {
        i = b->code_len;
        /* find start of last line */
        ls = i;
        if (ls > 0) ls--;        /* skip its '\n' */
        while (ls > 0 && b->code_body[ls - 1] != '\n') ls--;
        blank = 1;
        for (j = ls; j + 1 < i; j++) {
            if (b->code_body[j] != ' ' && b->code_body[j] != '\t') { blank = 0; break; }
        }
        if (!blank) break;
        b->code_len = ls;
    }
    memset(&d, 0, sizeof d);
    sax_enter(b, MDS_BLK_CODE_INDENTED, &d);
    if (b->code_len) sax_text(b, b->code_body, b->code_len);
    sax_leave(b, MDS_BLK_CODE_INDENTED);
    b->code_len = 0;
    b->pending_blanks = 0;
}

static void finalize_code_fenced(bscanner* b) {
    mds_block_detail d;
    memset(&d, 0, sizeof d);
    d.u.code_fenced.info     = b->fence_info;
    d.u.code_fenced.info_len = b->fence_info_len;
    sax_enter(b, MDS_BLK_CODE_FENCED, &d);
    if (b->code_len) sax_text(b, b->code_body, b->code_len);
    sax_leave(b, MDS_BLK_CODE_FENCED);
    b->code_len = 0;
    b->fence_info = NULL;
    b->fence_info_len = 0;
}

static void finalize_html(bscanner* b) {
    size_t i;
    size_t ls;
    size_t j;
    int blank;
    mds_block_detail d;
    /* trim trailing blank lines */
    while (b->html_len > 0) {
        i = b->html_len;
        ls = i;
        if (ls > 0) ls--;
        while (ls > 0 && b->html_body[ls - 1] != '\n') ls--;
        blank = 1;
        for (j = ls; j + 1 < i; j++) {
            if (b->html_body[j] != ' ' && b->html_body[j] != '\t') { blank = 0; break; }
        }
        if (!blank) break;
        b->html_len = ls;
    }
    memset(&d, 0, sizeof d);
    sax_enter(b, MDS_BLK_HTML, &d);
    if (b->html_len) sax_raw(b, b->html_body, b->html_len);
    sax_leave(b, MDS_BLK_HTML);
    b->html_len = 0;
    b->html_type = 0;
}

static void finalize_leaf(bscanner* b) {
    switch (b->leaf) {
    case LF_PARAGRAPH:     finalize_paragraph(b); break;
    case LF_CODE_FENCED:   finalize_code_fenced(b); break;
    case LF_CODE_INDENTED: finalize_code_indented(b); break;
    case LF_HTML:          finalize_html(b); break;
    case LF_NONE: break;
    }
    b->leaf = LF_NONE;
}

/* ---------- container emit ---------- */

static void emit_open(bscanner* b, int idx) {
    ctn* c = &b->stack[idx];
    mds_block_detail d;
    if (c->opened) return;
    c->opened = 1;
    memset(&d, 0, sizeof d);
    if (c->kind == CT_QUOTE) {
        sax_enter(b, MDS_BLK_QUOTE, &d);
    } else if (c->kind == CT_LIST) {
        d.u.list.is_ordered = c->ordered;
        d.u.list.is_tight   = c->tight;
        d.u.list.start      = c->start;
        d.u.list.marker     = c->marker;
        c->ev_idx = sax_enter(b, MDS_BLK_LIST, &d);
    } else if (c->kind == CT_LIST_ITEM) {
        sax_enter(b, MDS_BLK_LIST_ITEM, &d);
    }
}

static void emit_close(bscanner* b, ctn* c) {
    if (!c->opened) return;
    if (c->kind == CT_QUOTE) {
        sax_leave(b, MDS_BLK_QUOTE);
    } else if (c->kind == CT_LIST) {
        /* Patch is_tight on the buffered enter event if any. */
        if (c->ev_idx >= 0 && (size_t)c->ev_idx < b->ev_len) {
            ev_rec* e = &b->evbuf[c->ev_idx];
            if (e->type == EV_ENTER_BLOCK && e->u.enter.t == MDS_BLK_LIST) {
                e->u.enter.d.u.list.is_tight = c->had_blank_inside ? 0 : 1;
            }
        }
        sax_leave(b, MDS_BLK_LIST);
        b->list_depth--;
        /* Doc-wide buffering: flush only at end of mds_block_scan. */
    } else if (c->kind == CT_LIST_ITEM) {
        sax_leave(b, MDS_BLK_LIST_ITEM);
    }
}

static void close_containers_to(bscanner* b, int target_depth) {
    ctn* c;
    while (b->depth > target_depth) {
        finalize_leaf(b);
        c = &b->stack[b->depth - 1];
        emit_close(b, c);
        b->depth--;
    }
}

/* ---------- line helpers ---------- */

static const char* next_line(const char* p, const char* end,
                             const char** line_end_out) {
    const char* nl;
    const char* le;
    nl = (const char*)memchr(p, '\n', (size_t)(end - p));
    if (!nl) { *line_end_out = end; return end; }
    le = nl;
    if (le > p && *(le - 1) == '\r') le--;
    *line_end_out = le;
    return nl + 1;
}

static int consume_indent(const char** p, const char* end, int max) {
    int col = 0;
    const char* q = *p;
    while (q < end && col < max) {
        if (*q == ' ') { col++; q++; }
        else if (*q == '\t') {
            int adv = 4 - (col & 3);
            if (col + adv > max) break;
            col += adv; q++;
        } else break;
    }
    *p = q;
    return col;
}

static int count_indent(const char* p, const char* end) {
    int col = 0;
    while (p < end) {
        if (*p == ' ') col++;
        else if (*p == '\t') col += 4 - (col & 3);
        else break;
        p++;
    }
    return col;
}

static int is_blank(const char* p, const char* end) {
    while (p < end) {
        if (*p != ' ' && *p != '\t') return 0;
        p++;
    }
    return 1;
}

/* ---------- HTML block recognition (CommonMark §4.6) ---------- */

static int ascii_ieq(const char* a, const char* b, size_t n) {
    size_t i;
    char x, y;
    for (i = 0; i < n; i++) {
        x = a[i]; y = b[i];
        if (x >= 'A' && x <= 'Z') x = (char)(x + 32);
        if (y >= 'A' && y <= 'Z') y = (char)(y + 32);
        if (x != y) return 0;
    }
    return 1;
}

/* Type-6 block tag names (lowercased). Sorted by length then alpha for
 * a simple linear scan; the set is small enough that hashing isn't worth it. */
static const char* const HTML6_TAGS[] = {
    "address","article","aside","base","basefont","blockquote","body","caption",
    "center","col","colgroup","dd","details","dialog","dir","div","dl","dt",
    "fieldset","figcaption","figure","footer","form","frame","frameset",
    "h1","h2","h3","h4","h5","h6","head","header","hr","html","iframe","legend",
    "li","link","main","menu","menuitem","nav","noframes","ol","optgroup","option",
    "p","param","search","section","summary","table","tbody","td","tfoot","th",
    "thead","title","tr","track","ul", NULL
};

static int is_html6_tag(const char* s, size_t n) {
    for (int i = 0; HTML6_TAGS[i]; i++) {
        size_t tl = strlen(HTML6_TAGS[i]);
        if (tl == n && ascii_ieq(s, HTML6_TAGS[i], n)) return 1;
    }
    return 0;
}

static int is_alpha(char c) {
    return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z');
}
static int is_alnum(char c) {
    return is_alpha(c) || (c >= '0' && c <= '9');
}

/* Type-7 helpers: validate a complete open or close tag on one line.
 * Returns 1 if `[p, end)` (after the initial '<') is a complete tag
 * followed only by whitespace. */
static int is_type7_open_tag(const char* p, const char* end) {
    const char* name;
    size_t nlen;
    int i;
    const char* aws;
    const char* vs;
    char q;
    const char* uv;
    /* tag name: ASCII letter, then [A-Za-z0-9-]* */
    if (p >= end || !is_alpha(*p)) return 0;
    name = p;
    p++;
    while (p < end && (is_alnum(*p) || *p == '-')) p++;
    nlen = (size_t)(p - name);
    /* disallowed tag names for type 7 */
    {
        static const char* const banned[] = {"script","pre","style","textarea",NULL};
        for (i = 0; banned[i]; i++) {
            size_t bl = strlen(banned[i]);
            if (bl == nlen && ascii_ieq(name, banned[i], nlen)) return 0;
        }
    }
    /* attributes */
    while (p < end) {
        /* whitespace then attr-name */
        aws = p;
        while (p < end && (*p == ' ' || *p == '\t')) p++;
        if (p == aws) break;            /* must have ws before attr */
        if (p >= end || *p == '/' || *p == '>') break;
        if (!is_alpha(*p) && *p != '_' && *p != ':') return 0;
        p++;
        while (p < end && (is_alnum(*p) || *p == '_' || *p == ':' || *p == '.' || *p == '-')) p++;
        /* optional value */
        vs = p;
        while (p < end && (*p == ' ' || *p == '\t')) p++;
        if (p < end && *p == '=') {
            p++;
            while (p < end && (*p == ' ' || *p == '\t')) p++;
            if (p >= end) return 0;
            if (*p == '"' || *p == '\'') {
                q = *p++;
                while (p < end && *p != q) p++;
                if (p >= end) return 0;
                p++;
            } else {
                uv = p;
                while (p < end && *p != ' ' && *p != '\t' && *p != '\"'
                       && *p != '\'' && *p != '=' && *p != '<' && *p != '>'
                       && *p != '`') p++;
                if (p == uv) return 0;
            }
        } else {
            p = vs;   /* no value, rewind */
        }
    }
    while (p < end && (*p == ' ' || *p == '\t')) p++;
    if (p < end && *p == '/') p++;
    if (p >= end || *p != '>') return 0;
    p++;
    while (p < end && (*p == ' ' || *p == '\t')) p++;
    return p == end;
}

static int is_type7_close_tag(const char* p, const char* end) {
    const char* name;
    size_t nlen;
    int i;
    /* already past '</' */
    if (p >= end || !is_alpha(*p)) return 0;
    name = p;
    p++;
    while (p < end && (is_alnum(*p) || *p == '-')) p++;
    nlen = (size_t)(p - name);
    {
        static const char* const banned[] = {"script","pre","style","textarea",NULL};
        for (i = 0; banned[i]; i++) {
            size_t bl = strlen(banned[i]);
            if (bl == nlen && ascii_ieq(name, banned[i], nlen)) return 0;
        }
    }
    while (p < end && (*p == ' ' || *p == '\t')) p++;
    if (p >= end || *p != '>') return 0;
    p++;
    while (p < end && (*p == ' ' || *p == '\t')) p++;
    return p == end;
}

/* Detect HTML block start. Returns 1..7 on match, 0 otherwise.
 * Caller has already stripped container prefixes; `p` is the line start
 * after container content_col indent (but possibly with up to 3 leading
 * spaces left). `allow_type7` is 0 when inside a paragraph (rule 7
 * cannot interrupt). */
static int detect_html_block_start(const char* p, const char* end, int allow_type7) {
    int lead = 0;
    const char* q;
    while (p < end && *p == ' ' && lead < 3) { p++; lead++; }
    if (p >= end || *p != '<') return 0;
    q = p + 1;
    /* Type 2: <!-- */
    if (q + 2 < end && q[0] == '!' && q[1] == '-' && q[2] == '-') return 2;
    /* Type 3: <? */
    if (q < end && *q == '?') return 3;
    /* Type 5: <![CDATA[ */
    if (q + 7 < end && q[0] == '!' && q[1] == '[' && memcmp(q+2,"CDATA[",6) == 0) return 5;
    /* Type 4: <! followed by ASCII letter */
    if (q + 1 < end && *q == '!' && is_alpha(q[1])) return 4;
    /* Type 1: <script, <pre, <style, <textarea, optionally case-insensitive,
     * followed by ws, '>' or EOL */
    {
        static const char* const t1[] = {"script","pre","style","textarea",NULL};
        int i;
        for (i = 0; t1[i]; i++) {
            size_t tl = strlen(t1[i]);
            if ((size_t)(end - q) >= tl && ascii_ieq(q, t1[i], tl)) {
                const char* a = q + tl;
                if (a == end || *a == ' ' || *a == '\t' || *a == '>') return 1;
            }
        }
    }
    /* Type 6: tag name in HTML6_TAGS, possibly with leading '/' for close */
    {
        const char* r = q;
        int closing = 0;
        const char* name;
        size_t nlen;
        if (r < end && *r == '/') { closing = 1; r++; }
        name = r;
        while (r < end && is_alnum(*r)) r++;
        nlen = (size_t)(r - name);
        if (nlen > 0 && is_html6_tag(name, nlen)) {
            if (r == end || *r == ' ' || *r == '\t' || *r == '>'
                || (!closing && r + 1 <= end && *r == '/' && r + 1 < end && r[1] == '>'))
                return 6;
        }
        (void)closing;
    }
    /* Type 7: complete open or close tag followed only by whitespace */
    if (allow_type7) {
        const char* r = q;
        if (r < end && *r == '/') {
            if (is_type7_close_tag(r + 1, end)) return 7;
        } else {
            if (is_type7_open_tag(r, end)) return 7;
        }
    }
    return 0;
}

/* Detect HTML block end for the given type, examining the whole line p..end. */
static int detect_html_block_end(int type, const char* p, const char* end, int blank) {
    const char* q;
    if (blank) {
        return (type == 6 || type == 7);
    }
    switch (type) {
    case 1: {
        /* line contains </script>, </pre>, </style>, or </textarea> (ci) */
        for (q = p; q < end; q++) {
            if (*q != '<') continue;
            if (q + 1 >= end || q[1] != '/') continue;
            {
                const char* r = q + 2;
                static const char* const t1[] = {"script","pre","style","textarea",NULL};
                int i;
                for (i = 0; t1[i]; i++) {
                    size_t tl = strlen(t1[i]);
                    if ((size_t)(end - r) >= tl + 1
                        && ascii_ieq(r, t1[i], tl) && r[tl] == '>') return 1;
                }
            }
        }
        return 0;
    }
    case 2:
        for (q = p; q + 2 < end; q++)
            if (q[0] == '-' && q[1] == '-' && q[2] == '>') return 1;
        return 0;
    case 3:
        for (q = p; q + 1 < end; q++)
            if (q[0] == '?' && q[1] == '>') return 1;
        return 0;
    case 4:
        for (q = p; q < end; q++) if (*q == '>') return 1;
        return 0;
    case 5:
        for (q = p; q + 2 < end; q++)
            if (q[0] == ']' && q[1] == ']' && q[2] == '>') return 1;
        return 0;
    case 6:
    case 7:
        return 0;   /* only blank lines end these */
    }
    return 0;
}

/* ---------- leaf openers ---------- */

static int try_thematic_break(const char* p, const char* end) {
    int lead = 0;
    char c;
    int count = 0;
    while (p < end && *p == ' ' && lead < 3) { p++; lead++; }
    if (p >= end) return 0;
    c = *p;
    if (c != '-' && c != '_' && c != '*') return 0;
    while (p < end) {
        if (*p == c) count++;
        else if (*p != ' ' && *p != '\t') return 0;
        p++;
    }
    return count >= 3;
}

static int try_atx_heading(const char* p, const char* end,
                           int* level_out,
                           const char** body_start, const char** body_end) {
    int lead = 0;
    int n = 0;
    const char* bs;
    const char* be;
    const char* trim;
    while (p < end && *p == ' ' && lead < 3) { p++; lead++; }
    while (p < end && *p == '#' && n < 7) { p++; n++; }
    if (n == 0 || n > 6) return 0;
    if (p < end && *p != ' ' && *p != '\t') return 0;
    while (p < end && (*p == ' ' || *p == '\t')) p++;
    bs = p;
    be = end;
    while (be > bs && (be[-1] == ' ' || be[-1] == '\t')) be--;
    /* optional trailing #s */
    trim = be;
    while (trim > bs && trim[-1] == '#') trim--;
    if (trim < be && (trim == bs || trim[-1] == ' ' || trim[-1] == '\t')) {
        be = trim;
        while (be > bs && (be[-1] == ' ' || be[-1] == '\t')) be--;
    }
    *level_out  = n;
    *body_start = bs;
    *body_end   = be;
    return 1;
}

static int try_fence_open(const char* p, const char* end,
                          int* indent_out, char* ch_out, int* len_out,
                          const char** info_start, const char** info_end) {
    int lead = 0;
    char ch;
    int n = 0;
    const char* is;
    const char* ie;
    const char* q;
    while (p < end && *p == ' ' && lead < 3) { p++; lead++; }
    if (p >= end) return 0;
    ch = *p;
    if (ch != '`' && ch != '~') return 0;
    while (p < end && *p == ch) { p++; n++; }
    if (n < 3) return 0;
    while (p < end && (*p == ' ' || *p == '\t')) p++;
    is = p;
    ie = end;
    while (ie > is && (ie[-1] == ' ' || ie[-1] == '\t')) ie--;
    if (ch == '`') {
        for (q = is; q < ie; q++) if (*q == '`') return 0;
    }
    *indent_out = lead;
    *ch_out     = ch;
    *len_out    = n;
    *info_start = is;
    *info_end   = ie;
    return 1;
}

static int is_fence_close(const char* p, const char* end, char ch, int min_len) {
    int lead = 0;
    int n = 0;
    while (p < end && *p == ' ' && lead < 3) { p++; lead++; }
    while (p < end && *p == ch) { p++; n++; }
    if (n < min_len) return 0;
    while (p < end) {
        if (*p != ' ' && *p != '\t') return 0;
        p++;
    }
    return 1;
}

static int try_open_quote(const char** p, const char* end) {
    const char* q = *p;
    int lead = 0;
    while (q < end && *q == ' ' && lead < 3) { q++; lead++; }
    if (q >= end || *q != '>') return 0;
    q++;
    if (q < end && (*q == ' ' || *q == '\t')) q++;
    *p = q;
    return 1;
}

static int try_open_list_item(const char** p_inout, const char* end,
                              int* ordered, int* start, char* marker,
                              int* content_col, int* is_empty) {
    const char* p = *p_inout;
    int col = 0, lead = 0;
    int mc;
    char m;
    int ord = 0, st = 1, marker_len = 0;
    int spaces_after = 0;
    int empty;
    while (p < end && *p == ' ' && lead < 3) { p++; col++; lead++; }
    if (p >= end) return 0;
    mc = col;
    m = *p;
    if (m == '-' || m == '+' || m == '*') {
        marker_len = 1;
        p++; col++;
    } else if (m >= '0' && m <= '9') {
        const char* q = p;
        int digits = 0, val = 0;
        while (q < end && *q >= '0' && *q <= '9' && digits < 9) {
            val = val * 10 + (*q - '0');
            q++; digits++;
        }
        if (digits == 0 || q >= end) return 0;
        if (*q != '.' && *q != ')') return 0;
        m = *q;
        marker_len = (int)(q - p) + 1;
        col += marker_len;
        p = q + 1;
        ord = 1;
        st  = val;
    } else {
        return 0;
    }
    empty = (p >= end);
    if (!empty) {
        if (*p == ' ') {
            while (p < end && spaces_after < 5 && *p == ' ') { p++; spaces_after++; col++; }
        } else if (*p == '\t') {
            int adv = 4 - (col & 3);
            spaces_after = adv;
            col += adv;
            p++;
        } else {
            return 0;
        }
        empty = is_blank(p, end);
    }
    if (spaces_after >= 5) {
        p -= (spaces_after - 1);
        col -= (spaces_after - 1);
        spaces_after = 1;
    }
    if (empty) {
        *content_col = mc + marker_len + 1;
    } else {
        *content_col = col;
    }
    *ordered = ord;
    *start   = st;
    *marker  = m;
    *is_empty = empty;
    *p_inout = p;
    return 1;
}

/* Setext underline: 0-3 leading spaces, then a run of '=' (level 1) or
 * '-' (level 2), optional trailing spaces, end of line. Returns 1 or 2. */
static int try_setext_underline(const char* p, const char* end) {
    int lead = 0;
    char c;
    int n = 0;
    while (p < end && *p == ' ' && lead < 3) { p++; lead++; }
    if (p >= end) return 0;
    c = *p;
    if (c != '=' && c != '-') return 0;
    while (p < end && *p == c) { p++; n++; }
    while (p < end && (*p == ' ' || *p == '\t')) p++;
    if (p != end || n < 1) return 0;
    return (c == '=') ? 1 : 2;
}

/* ---------- main scan ---------- */

static void scan_line(bscanner* b, const char* line, const char* line_end);

MDS_HOT void mds_block_scan(mds_ctx* ctx) {
    bscanner b;
    mds_block_scratch* sc;
    const char* p;
    const char* end;
    memset(&b, 0, sizeof b);
    b.ctx = ctx;

    /* Borrow scratch buffers from the session (if any) so
     * we skip the per-parse malloc/free for para/code/html/ev/bytepool.
     * Lengths are reset to zero; capacities and pointers are taken
     * verbatim and written back at end-of-scan. */
    sc = (mds_block_scratch*)ctx->scratch;
    if (sc) {
        b.para      = sc->para;       b.para_cap = sc->para_cap;
        b.code_body = sc->code_body;  b.code_cap = sc->code_cap;
        b.html_body = sc->html_body;  b.html_cap = sc->html_cap;
        b.evbuf     = (ev_rec*)sc->evbuf;  b.ev_cap = sc->ev_cap;
        b.bytepool  = sc->bytepool;   b.bp_cap   = sc->bp_cap;
    }

    push(&b, CT_DOC);
    b.stack[0].opened = 1;

    /* Tier E.1 extended — strip top-level footnote defs from the input so
     * the main scan never sees them (they would otherwise become stray
     * paragraphs). The captured bodies are arena-owned and re-parsed
     * later via a recursive mds_block_scan when the footnotes section
     * is emitted. */
    if (ctx->flags & MDS_FLAG_FOOTNOTES) {
        preprocess_footnotes(ctx);
    }

    p   = ctx->input;
    end = ctx->input + ctx->len;
    while (p < end) {
        const char* le;
        const char* nxt = next_line(p, end, &le);
        const char* lp = p;
        const char* lend = le;
        /* If line contains a TAB, expand into line_scratch with tab-stop=4.
         * Per CommonMark §2.2, tabs behave as if replaced by spaces with a
         * tab stop of 4 chars. Doing this once per line lets the rest of
         * the block scanner remain tab-agnostic. scan_line is responsible
         * for copying any text it needs to keep beyond the line's lifetime,
         * so the scratch may be reused for the next line. */
        /* Tabs that appear in "container indent" positions must be
         * expanded for proper column accounting per CommonMark spec.
         * Walk the line accepting WS and container markers (>, list
         * markers) until we hit text content, expanding any tab to
         * spaces using tab-stop=4 based on the current logical column.
         * Tabs in code content (after text starts) are preserved
         * literally. */
        if (memchr(p, '\t', (size_t)(le - p))) {
            /* Find the end of the structural prefix. */
            const char* ws_end = p;
            int saw_tab = 0;
            while (ws_end < le) {
                char c = *ws_end;
                if (c == ' ' || c == '\t') {
                    if (c == '\t') saw_tab = 1;
                    ws_end++;
                    continue;
                }
                /* blockquote marker */
                if (c == '>') { ws_end++; continue; }
                /* unordered list marker followed by WS */
                if ((c == '-' || c == '+' || c == '*') &&
                    ws_end + 1 < le &&
                    (ws_end[1] == ' ' || ws_end[1] == '\t')) {
                    ws_end++; continue;
                }
                /* ordered list marker n.[ \t] or n)[ \t] */
                if (c >= '0' && c <= '9') {
                    const char* q = ws_end;
                    int digits = 0;
                    while (q < le && *q >= '0' && *q <= '9' && digits < 9) { q++; digits++; }
                    if (q < le && (*q == '.' || *q == ')') &&
                        q + 1 < le && (q[1] == ' ' || q[1] == '\t')) {
                        ws_end = q + 1; continue;
                    }
                }
                break;
            }
            if (saw_tab) {
                size_t need;
                char* dst;
                int col;
                need = (size_t)(ws_end - p) * 4 + (size_t)(le - ws_end) + 8;
                buf_grow(&b.line_scratch, &b.line_scratch_cap, need);
                dst = b.line_scratch;
                col = 0;
                for (const char* s = p; s < ws_end; s++) {
                    if (*s == '\t') {
                        int adv = 4 - (col & 3);
                        while (adv-- > 0) { *dst++ = ' '; col++; }
                    } else { *dst++ = *s; col++; }
                }
                if (le > ws_end) memcpy(dst, ws_end, (size_t)(le - ws_end));
                dst += (le - ws_end);
                lp = b.line_scratch;
                lend = dst;
            }
        }
        scan_line(&b, lp, lend);
        p = nxt;
    }
    close_containers_to(&b, 1);
    finalize_leaf(&b);

    sax_flush(&b);

    /* Tier E.1 extended — emit FOOTNOTES_SECTION directly via callbacks
     * AFTER the main flush so the renderer has finished accumulating
     * the used-label set from inline FOOTNOTE_REF callbacks. For each
     * registered def we fire enter/leave around a recursive
     * mds_block_scan over the captured body bytes (with FOOTNOTES
     * disabled in the sub-context to prevent re-detection). Unused
     * defs are filtered by the renderer via its fn_skip flag. */
    if ((ctx->flags & MDS_FLAG_FOOTNOTES) && ctx->footnotes && ctx->footnotes->len) {
        const mds_callbacks cb = ctx->cb;
        void* const ud         = ctx->ud;
        if (MDS_LIKELY(cb.enter_block != NULL)) {
            /* Emit in renderer's first-use order (queried via the
             * public mds_render_html_used_footnote helper); fall back
             * to definition order for non-HTML renderers / when no
             * refs were seen (section will then be empty / all defs
             * are unused). */
            size_t emit_n = 0;
            const char* lbl;
            size_t      llen;
            while (mds_render_html_used_footnote(ud, emit_n, &lbl, &llen)) emit_n++;

            if (emit_n == 0) {
                /* No referenced footnotes — skip the whole section to
                 * avoid an empty <section><ol></ol></section>. */
            } else {
                mds_block_detail d;
                memset(&d, 0, sizeof d);
                cb.enter_block(ud, MDS_BLK_FOOTNOTES_SECTION, &d);
                for (size_t k = 0; k < emit_n; k++) {
                    const mds_footnote* fn;
                    mds_block_detail fd;
                    mds_render_html_used_footnote(ud, k, &lbl, &llen);
                    fn = mds_footnote_get(ctx->footnotes, lbl, llen);
                    if (!fn) continue;
                    memset(&fd, 0, sizeof fd);
                    fd.u.footnote_def.label     = fn->label;
                    fd.u.footnote_def.label_len = fn->llen;
                    fd.u.footnote_def.body      = fn->body;
                    fd.u.footnote_def.body_len  = fn->blen;
                    cb.enter_block(ud, MDS_BLK_FOOTNOTE_DEF, &fd);
                    if (fn->blen) {
                        mds_ctx sub = *ctx;
                        sub.input    = fn->body;
                        sub.len      = fn->blen;
                        sub.flags    = ctx->flags & ~MDS_FLAG_FOOTNOTES;
                        sub.footnotes = NULL;
                        sub.scratch  = NULL;
                        mds_block_scan(&sub);
                    }
                    if (cb.leave_block != NULL)
                        cb.leave_block(ud, MDS_BLK_FOOTNOTE_DEF);
                }
                if (cb.leave_block != NULL)
                    cb.leave_block(ud, MDS_BLK_FOOTNOTES_SECTION);
            }
        }
    }

    if (sc) {
        /* Write back potentially-grown buffers; ownership stays with sc. */
        sc->para      = b.para;       sc->para_cap = b.para_cap;
        sc->code_body = b.code_body;  sc->code_cap = b.code_cap;
        sc->html_body = b.html_body;  sc->html_cap = b.html_cap;
        sc->evbuf     = b.evbuf;      sc->ev_cap   = b.ev_cap;
        sc->bytepool  = b.bytepool;   sc->bp_cap   = b.bp_cap;
    } else {
        free(b.para);
        free(b.code_body);
        free(b.html_body);
        free(b.evbuf);
        free(b.bytepool);
    }
    free(b.line_scratch);
}

void mds_block_scratch_free(mds_block_scratch* s) {
    if (!s) return;
    free(s->para);      s->para = NULL;      s->para_cap = 0;
    free(s->code_body); s->code_body = NULL; s->code_cap = 0;
    free(s->html_body); s->html_body = NULL; s->html_cap = 0;
    free(s->evbuf);     s->evbuf = NULL;     s->ev_cap = 0;
    free(s->bytepool);  s->bytepool = NULL;  s->bp_cap = 0;
}

MDS_HOT static void scan_line(bscanner* b, const char* line, const char* line_end) {
    const char* p = line;
    int blank = is_blank(p, line_end);
    int matched;
    int i;
    int lazy;
    int level;
    const char* bs;
    const char* be;
    int findent;
    char fch;
    int flen;
    const char* ifs;
    const char* ife;
    const char* tp;
    int lead;

    /* If inside fenced code, only check for close OR continue accumulating. */
    if (b->leaf == LF_CODE_FENCED) {
        const char* cp;
        int strip;
        size_t add;
        /* still need to walk containers to count matched (for nested fenced code) */
        for (i = 1; i < b->depth; i++) {
            ctn* c = &b->stack[i];
            if (c->kind == CT_QUOTE) {
                if (!try_open_quote(&p, line_end)) {
                    /* container break terminates code */
                    finalize_leaf(b);
                    close_containers_to(b, i);
                    goto regular;
                }
            } else if (c->kind == CT_LIST_ITEM) {
                int col = count_indent(p, line_end);
                if (!blank && col < c->content_col) {
                    finalize_leaf(b);
                    close_containers_to(b, i);
                    goto regular;
                }
                consume_indent(&p, line_end, c->content_col);
            }
        }
        if (is_fence_close(p, line_end, b->fence_char, b->fence_len)) {
            finalize_leaf(b);
            return;
        }
        cp = p;
        strip = b->fence_indent;
        while (cp < line_end && strip > 0 && *cp == ' ') { cp++; strip--; }
        add = (size_t)(line_end - cp);
        buf_grow(&b->code_body, &b->code_cap, b->code_len + add + 2);
        if (add) memcpy(b->code_body + b->code_len, cp, add);
        b->code_len += add;
        b->code_body[b->code_len++] = '\n';
        return;
    }

    /* If inside an HTML block, walk containers then either close (on end
     * condition) or append the raw line. */
    if (b->leaf == LF_HTML) {
        size_t add;
        for (i = 1; i < b->depth; i++) {
            ctn* c = &b->stack[i];
            if (c->kind == CT_QUOTE) {
                if (!try_open_quote(&p, line_end)) {
                    finalize_leaf(b);
                    close_containers_to(b, i);
                    goto regular;
                }
            } else if (c->kind == CT_LIST_ITEM) {
                int col = count_indent(p, line_end);
                if (!blank && col < c->content_col) {
                    finalize_leaf(b);
                    close_containers_to(b, i);
                    goto regular;
                }
                consume_indent(&p, line_end, c->content_col);
            }
        }
        if (blank && (b->html_type == 6 || b->html_type == 7)) {
            finalize_leaf(b);
            return;
        }
        add = (size_t)(line_end - p);
        buf_grow(&b->html_body, &b->html_cap, b->html_len + add + 2);
        if (add) memcpy(b->html_body + b->html_len, p, add);
        b->html_len += add;
        b->html_body[b->html_len++] = '\n';
        if (detect_html_block_end(b->html_type, p, line_end, blank)) {
            finalize_leaf(b);
        }
        return;
    }
regular:
    ;  /* empty statement so the following declaration is legal C89/C99 */

    /* ---- 1. WALK ---- */
    matched = 1;
    for (i = 1; i < b->depth; i++) {
        ctn* c = &b->stack[i];
        if (c->kind == CT_QUOTE) {
            if (try_open_quote(&p, line_end)) { matched = i + 1; }
            else break;
        } else if (c->kind == CT_LIST) {
            matched = i + 1;
        } else if (c->kind == CT_LIST_ITEM) {
            int col = count_indent(p, line_end);
            if (blank) { matched = i + 1; }
            else if (col >= c->content_col) {
                /* CommonMark §5.2: an empty list item closes after one
                 * blank line. The enclosing CT_LIST also closes (no new
                 * item starter present). */
                if (c->is_empty && c->blank_after_empty) {
                    if (i > 0 && b->stack[i-1].kind == CT_LIST) matched = i - 1;
                    break;
                }
                consume_indent(&p, line_end, c->content_col);
                matched = i + 1;
                c->is_empty = 0;
            } else break;
        } else {
            matched = i + 1;
        }
    }

    /* After the walk, if all remaining bytes are whitespace, treat as blank.
     * This catches lines like ">" inside a blockquote, where the line is
     * not blank as a whole but becomes empty after consuming the quote
     * marker. The blank handler below will then close the paragraph but,
     * because matched == depth, leave the quote container open. */
    if (!blank && is_blank(p, line_end)) blank = 1;

    if (blank) {
        /* Inside indented code: a "blank" line with >= 4 columns of leading
         * whitespace is actually content (CommonMark §4.4: blank lines
         * preceding/following are stripped, but inner blank lines keep
         * their trailing whitespace beyond column 4). */
        if (b->leaf == LF_CODE_INDENTED) {
            int col = count_indent(p, line_end);
            if (col >= 4) {
                size_t add;
                while (b->pending_blanks > 0) {
                    buf_grow(&b->code_body, &b->code_cap, b->code_len + 2);
                    b->code_body[b->code_len++] = '\n';
                    b->pending_blanks--;
                }
                consume_indent(&p, line_end, 4);
                add = (size_t)(line_end - p);
                buf_grow(&b->code_body, &b->code_cap, b->code_len + add + 2);
                if (add) memcpy(b->code_body + b->code_len, p, add);
                b->code_len += add;
                b->code_body[b->code_len++] = '\n';
                return;
            }
            /* CM §5.1: a blank line without the blockquote marker still
             * ends the enclosing blockquote, even if indented code is
             * open inside it. Fall through to the normal blank-line
             * handling (paragraph finalise + quote close). */
            if (matched < b->depth) {
                int has_unmatched_quote = 0;
                for (int i = matched; i < b->depth; i++) {
                    if (b->stack[i].kind == CT_QUOTE) { has_unmatched_quote = 1; break; }
                }
                if (has_unmatched_quote) {
                    /* flush code, then fall through. */
                    finalize_leaf(b);
                } else {
                    b->pending_blanks++;
                    return;
                }
            } else {
                b->pending_blanks++;
                return;
            }
        }
        /* mark list loose flag, finalise paragraph.
         * CommonMark loose-ness rule: a blank line only affects a list if
         * it lies directly inside one of that list's items (not nested
         * inside an inner blockquote). Defer the attribution: just remember
         * a blank was seen, and attribute it to the deepest surviving
         * CT_LIST after the next non-blank line has walked containers.
         * Exception: if the matched stack has a CT_QUOTE *above* the
         * deepest matched CT_LIST_ITEM, the blank is quote-internal and
         * should not propagate to any outer list. */
        if (b->leaf == LF_PARAGRAPH) finalize_leaf(b);
        {
            int deepest_li = -1;
            int has_quote_above_li = 0;
            for (int i = 0; i < matched; i++) {
                if (b->stack[i].kind == CT_LIST_ITEM) deepest_li = i;
            }
            if (deepest_li >= 0) {
                for (int i = deepest_li + 1; i < matched; i++) {
                    if (b->stack[i].kind == CT_QUOTE) { has_quote_above_li = 1; break; }
                }
            }
            if (!has_quote_above_li) b->blank_pending = 1;
        }
        for (int i = 0; i < b->depth; i++) {
            if (b->stack[i].kind == CT_LIST_ITEM && b->stack[i].is_empty)
                b->stack[i].blank_after_empty = 1;
        }
        /* CommonMark §5.1: a block quote ends at a blank line that doesn't
         * have its own quote marker. Close any CT_QUOTE that the walk didn't
         * match. (Lists handle blank lines via had_blank_inside; quotes don't
         * have a same notion.) */
        if (matched < b->depth) {
            for (int i = matched; i < b->depth; i++) {
                if (b->stack[i].kind == CT_QUOTE) {
                    close_containers_to(b, matched);
                    break;
                }
            }
        }
        return;
    }

    /* ---- lazy continuation check ---- */
    lazy = 0;
    if (matched < b->depth && b->leaf == LF_PARAGRAPH) {
        /* If line doesn't open something new on its own AND existing leaf is
         * paragraph, treat as continuation in original container. */
        int lvl;
        const char* ds; const char* de;
        int fi; char fc; int fl;
        const char* ifs; const char* ife;
        const char* tp = p;
        int ord, st, cc, em; char mk;
        unsigned _f = b->ctx->flags;
        if (!(_f & MDS_FLAG_NO_THEMATIC_BREAK) && try_thematic_break(p, line_end)) ;
        else if (!(_f & MDS_FLAG_NO_HEADINGS) && try_atx_heading(p, line_end, &lvl, &ds, &de)) ;
        else if (!(_f & MDS_FLAG_NO_FENCED_CODE) && try_fence_open(p, line_end, &fi, &fc, &fl, &ifs, &ife)) ;
        else if (!(_f & MDS_FLAG_NO_HTML) && detect_html_block_start(p, line_end, 0)) ;
        else if (!(_f & MDS_FLAG_NO_QUOTES) && try_open_quote(&tp, line_end)) ;
        else { int _both_lists;
               tp = p;
               _both_lists = (_f & MDS_FLAG_NO_ORDERED_LISTS) && (_f & MDS_FLAG_NO_UNORDERED_LISTS);
               if (!_both_lists && try_open_list_item(&tp, line_end, &ord, &st, &mk, &cc, &em)) {
                   if ((ord && (_f & MDS_FLAG_NO_ORDERED_LISTS)) ||
                       (!ord && (_f & MDS_FLAG_NO_UNORDERED_LISTS))) lazy = 1;
               } else lazy = 1; }
    }
    if (!lazy) close_containers_to(b, matched);

    /* CommonMark §5.3: a list ends when followed by a non-list-item block
     * at the same indentation (after blank lines). If the walk closed the
     * last CT_LIST_ITEM but left the parent CT_LIST open, and the new line
     * doesn't start a same-kind item, close the LIST too so subsequent
     * blocks render outside it. */
    if (!lazy && b->depth > 1 && top(b)->kind == CT_LIST) {
        const char* pk = p;
        int ord2, st2, cc2, em2; char mk2;
        ctn* lst = top(b);
        int keep = 0;
        if (!((b->ctx->flags & MDS_FLAG_NO_ORDERED_LISTS) &&
              (b->ctx->flags & MDS_FLAG_NO_UNORDERED_LISTS)) &&
            try_open_list_item(&pk, line_end, &ord2, &st2, &mk2, &cc2, &em2) &&
            ord2 == lst->ordered && mk2 == lst->marker) {
            keep = 1;
        }
        if (!keep) {
            emit_close(b, top(b));
            b->depth--;
        }
    }

    /* Attribute deferred blank line (if any) to the deepest CT_LIST that
     * is still alive after the container walk and post-list-close. Inner
     * lists that closed during the walk implicitly bubble their blank up
     * to their parent list (this is how 325/326 become loose at the outer
     * level while inner stays tight). */
    if (b->blank_pending) {
        int deepest = -1;
        for (int i = 0; i < b->depth; i++)
            if (b->stack[i].kind == CT_LIST) deepest = i;
        if (deepest >= 0) b->stack[deepest].pending_blank = 1;
        b->blank_pending = 0;
    }

    /* Promote deferred blank-lines into loose-marks for any CT_LIST that is
     * still alive after the walk + post-list-close above. Lists that just
     * closed lose their pending blank silently (a trailing blank doesn't
     * make a closed list loose). */
    for (i = 0; i < b->depth; i++) {
        if (b->stack[i].kind == CT_LIST && b->stack[i].pending_blank) {
            b->stack[i].had_blank_inside = 1;
            b->stack[i].pending_blank = 0;
        }
    }

    /* ---- indented code continuation / open ---- */
    /* (Cannot interrupt a paragraph; cannot start where the container walk
     * left us with too little room.) */
    {
        int col = count_indent(p, line_end);
        if (col >= 4 && b->leaf != LF_PARAGRAPH &&
            !(b->ctx->flags & MDS_FLAG_NO_INDENTED_CODE)) {
            size_t add;
            /* This is an indented-code line. */
            consume_indent(&p, line_end, 4);
            if (b->leaf != LF_CODE_INDENTED) {
                finalize_leaf(b);
                b->leaf = LF_CODE_INDENTED;
                b->leaf_in_container = b->depth - 1;
                b->pending_blanks = 0;
            } else {
                /* flush pending blanks */
                while (b->pending_blanks > 0) {
                    buf_grow(&b->code_body, &b->code_cap, b->code_len + 2);
                    b->code_body[b->code_len++] = '\n';
                    b->pending_blanks--;
                }
            }
            add = (size_t)(line_end - p);
            buf_grow(&b->code_body, &b->code_cap, b->code_len + add + 2);
            if (add) memcpy(b->code_body + b->code_len, p, add);
            b->code_len += add;
            b->code_body[b->code_len++] = '\n';
            return;
        }
        if (b->leaf == LF_CODE_INDENTED) {
            /* non-indented non-blank line ends indented code (blanks were buffered) */
            b->pending_blanks = 0;
            finalize_leaf(b);
        }
    }

    /* ---- setext upgrade ---- */
    /* CommonMark §4.3: a setext underline may not be a lazy continuation
     * line of a paragraph inside a container that this line doesn't fully
     * match. Skip the upgrade when we'd be relying on lazy continuation. */
    if (b->leaf == LF_PARAGRAPH && !(b->ctx->flags & MDS_FLAG_NO_HEADINGS) && !lazy) {
        int sx = try_setext_underline(p, line_end);
        if (sx) {
            /* CM §4.7: link-reference-definition lines do not contribute
             * content. If the entire paragraph buffer consists of ref-defs,
             * there is no real paragraph above to upgrade — treat the
             * '===' / '---' as a fresh paragraph (or thematic break,
             * already checked earlier). */
            int all_refs = 0;
            if (!(b->ctx->flags & MDS_FLAG_NO_REFERENCES) && b->para_len) {
                const char* rp = b->para;
                const char* re = b->para + b->para_len;
                while (rp < re) {
                    const char* nrp;
                    const char *xls, *xle, *xus, *xue, *xts, *xte;
                    if (!parse_linkref(rp, re, &nrp,
                                       &xls, &xle, &xus, &xue, &xts, &xte))
                        break;
                    rp = nrp;
                }
                /* Skip trailing whitespace. */
                while (rp < re && (*rp == ' ' || *rp == '\t' || *rp == '\n')) rp++;
                if (rp == re) all_refs = 1;
            }
            if (!all_refs) {
                b->setext_level = sx;
                finalize_leaf(b);
                return;
            }
        }
    }

    /* ---- 2. OPEN ---- */
    for (;;) {
        const char* before;
        unsigned _of;
        int ord, st, cc, em; char mk;
        const char* save;
        int _both_lists2;
        ctn* t;
        int nested_inside_item;
        int same_list;
        ctn* lc;
        ctn* it;
        before = p;
        _of = b->ctx->flags;
        if (!(_of & MDS_FLAG_NO_QUOTES) && try_open_quote(&p, line_end)) {
            finalize_leaf(b);
            if (!push(b, CT_QUOTE)) { p = before; break; }
            emit_open(b, b->depth - 1);
            continue;
        }
        save = p;
        _both_lists2 = (_of & MDS_FLAG_NO_ORDERED_LISTS) && (_of & MDS_FLAG_NO_UNORDERED_LISTS);
        /* CommonMark §4.1: thematic break wins over a list-item interpretation. */
        if (!(_of & MDS_FLAG_NO_THEMATIC_BREAK) &&
            try_thematic_break(p, line_end)) {
            break;
        }
        if (!_both_lists2 && try_open_list_item(&p, line_end, &ord, &st, &mk, &cc, &em)) {
            if ((ord && (_of & MDS_FLAG_NO_ORDERED_LISTS)) ||
                (!ord && (_of & MDS_FLAG_NO_UNORDERED_LISTS))) { p = save; break; }
            /* CommonMark §5.2: a list item may only interrupt a paragraph
             * if (a) the marker isn't empty, and (b) for ordered lists,
             * the start number is 1. */
            if (b->leaf == LF_PARAGRAPH && (em || (ord && st != 1))) {
                p = save;
                break;
            }
            finalize_leaf(b);
            t = (b->depth > 0) ? top(b) : NULL;
            nested_inside_item = (t && t->kind == CT_LIST_ITEM);
            same_list = (t && t->kind == CT_LIST
                             && t->ordered == ord && t->marker == mk);
            if (nested_inside_item) {
                /* Start a fresh nested list inside the current item. */
                if (!push(b, CT_LIST)) { p = save; break; }
                lc = top(b);
                lc->ordered = ord;
                lc->start   = st;
                lc->marker  = mk;
                lc->tight   = 1;
                emit_open(b, b->depth - 1);
            } else if (same_list) {
                /* close the previous list_item (one below top) is implicit;
                 * actually no list_item is on top here — close prior sibling
                 * item if any sits inside this list. */
                /* (no-op: a sibling item is added below.) */
            } else {
                /* Different list at root or beside another list — close any
                 * trailing list/list_item below this depth and start anew. */
                while (b->depth > 1 &&
                      (top(b)->kind == CT_LIST_ITEM || top(b)->kind == CT_LIST)) {
                    emit_close(b, top(b));
                    b->depth--;
                }
                if (!push(b, CT_LIST)) { p = save; break; }
                lc = top(b);
                lc->ordered = ord;
                lc->start   = st;
                lc->marker  = mk;
                lc->tight   = 1;
                emit_open(b, b->depth - 1);
            }
            if (!push(b, CT_LIST_ITEM)) break;
            it = top(b);
            it->content_col = cc;
            it->is_empty    = em;
            it->blank_after_empty = 0;
            emit_open(b, b->depth - 1);
            if (em) return;
            continue;
        }
        break;
    }

    /* ---- 3. LEAF ---- */
    /* Indented-code check (post-OPEN). When a new container (quote or
     * list-item) was opened in this line, the leading whitespace at `p`
     * may now reach 4 columns and be eligible for an indented code block.
     * (Cannot interrupt a paragraph.) */
    if (b->leaf != LF_PARAGRAPH && b->leaf != LF_CODE_INDENTED &&
        !(b->ctx->flags & MDS_FLAG_NO_INDENTED_CODE)) {
        int col2 = count_indent(p, line_end);
        if (col2 >= 4) {
            size_t add;
            consume_indent(&p, line_end, 4);
            finalize_leaf(b);
            b->leaf = LF_CODE_INDENTED;
            b->leaf_in_container = b->depth - 1;
            b->pending_blanks = 0;
            add = (size_t)(line_end - p);
            buf_grow(&b->code_body, &b->code_cap, b->code_len + add + 2);
            if (add) memcpy(b->code_body + b->code_len, p, add);
            b->code_len += add;
            b->code_body[b->code_len++] = '\n';
            return;
        }
    }
    /* HTML block start — types 1..6 can interrupt a paragraph; type 7 cannot. */
    if (!(b->ctx->flags & MDS_FLAG_NO_HTML)) {
        int allow7 = (b->leaf != LF_PARAGRAPH);
        int htype  = detect_html_block_start(p, line_end, allow7);
        if (htype) {
            size_t add;
            finalize_leaf(b);
            b->leaf = LF_HTML;
            b->leaf_in_container = b->depth - 1;
            b->html_type = htype;
            b->html_len = 0;
            add = (size_t)(line_end - p);
            buf_grow(&b->html_body, &b->html_cap, b->html_len + add + 2);
            if (add) memcpy(b->html_body + b->html_len, p, add);
            b->html_len += add;
            b->html_body[b->html_len++] = '\n';
            if (detect_html_block_end(htype, p, line_end, blank)) {
                finalize_leaf(b);
            }
            return;
        }
    }
    if (!(b->ctx->flags & MDS_FLAG_NO_HEADINGS) &&
        try_atx_heading(p, line_end, &level, &bs, &be)) {
        mds_block_detail d;
        finalize_leaf(b);
        memset(&d, 0, sizeof d);
        d.u.heading.level = level;
        sax_enter(b, MDS_BLK_HEADING, &d);
        if (be > bs) sax_inline_text(b, bs, (size_t)(be - bs));
        sax_leave(b, MDS_BLK_HEADING);
        return;
    }
    if (!(b->ctx->flags & MDS_FLAG_NO_THEMATIC_BREAK) &&
        try_thematic_break(p, line_end)) {
        mds_block_detail d;
        finalize_leaf(b);
        /* CommonMark §4.1: a thematic break closes any enclosing list
         * whose item context has already been closed (top-of-stack is
         * CT_LIST without an open CT_LIST_ITEM). When the top is a
         * CT_LIST_ITEM we are inside a new item (e.g. "- * * *") and
         * the break legitimately renders within it. */
        while (b->depth > 1 && top(b)->kind == CT_LIST) {
            emit_close(b, top(b));
            b->depth--;
        }
        memset(&d, 0, sizeof d);
        sax_enter(b, MDS_BLK_THEMATIC_BREAK, &d);
        sax_leave(b, MDS_BLK_THEMATIC_BREAK);
        return;
    }
    if (!(b->ctx->flags & MDS_FLAG_NO_FENCED_CODE) &&
        try_fence_open(p, line_end, &findent, &fch, &flen, &ifs, &ife)) {
        size_t iln;
        finalize_leaf(b);
        b->leaf = LF_CODE_FENCED;
        b->leaf_in_container = b->depth - 1;
        b->fence_char   = fch;
        b->fence_len    = flen;
        b->fence_indent = findent;
        iln = (size_t)(ife - ifs);
        if (iln) {
            size_t w;
            /* CommonMark: backslash-escape ASCII punctuation in info string. */
            b->fence_info = (char*)mds_arena_alloc(&b->ctx->arena, iln + 1);
            w = 0;
            for (size_t r = 0; r < iln; r++) {
                unsigned char ch = (unsigned char)ifs[r];
                if (ch == '\\' && r + 1 < iln) {
                    unsigned char nx = (unsigned char)ifs[r+1];
                    if ((nx >= 0x21 && nx <= 0x2F) ||
                        (nx >= 0x3A && nx <= 0x40) ||
                        (nx >= 0x5B && nx <= 0x60) ||
                        (nx >= 0x7B && nx <= 0x7E)) {
                        b->fence_info[w++] = (char)nx;
                        r++;
                        continue;
                    }
                }
                b->fence_info[w++] = (char)ch;
            }
            b->fence_info[w] = '\0';
            b->fence_info_len = w;
        } else {
            b->fence_info = NULL;
            b->fence_info_len = 0;
        }
        return;
    }

    /* paragraph (new or continuation) */
    if (b->leaf != LF_PARAGRAPH) {
        b->leaf = LF_PARAGRAPH;
        b->leaf_in_container = b->depth - 1;
    }
    tp = p;
    lead = 0;
    while (tp < line_end && *tp == ' ' && lead < 3) { tp++; lead++; }
    if (b->para_len > 0) {
        buf_grow(&b->para, &b->para_cap, b->para_len + 2);
        b->para[b->para_len++] = '\n';
    }
    buf_append(&b->para, &b->para_len, &b->para_cap,
               tp, (size_t)(line_end - tp));
}
