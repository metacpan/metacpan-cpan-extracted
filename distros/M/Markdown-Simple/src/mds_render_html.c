/* mds_render_html.c — SAX consumer that writes HTML into an mds_buf.
 *
 * Handles the block kinds the scanner emits
 * (paragraph, heading, thematic-break, fenced code, quote, list, list_item)
 * plus pass-through inline text (HTML-escaped) and pre-escaped raw.
 *
 * Captures aTHX via tTHX in render_state since the inline `mds_buf_write`
 * needs the interpreter context.
 */

#include "mds_render_html.h"
#include "mds_buf.h"
#include "mds_ir.h"
#include "mds.h"
#include "mds_entity.h"

#include "EXTERN.h"
#include "perl.h"

#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#define CLOSE_STACK_MAX 1024

typedef enum {
    CLOSE_NONE = 0,
    CLOSE_P,
    CLOSE_H1, CLOSE_H2, CLOSE_H3, CLOSE_H4, CLOSE_H5, CLOSE_H6,
    CLOSE_CODE_FENCED,
    CLOSE_CODE_INDENTED,
    CLOSE_BLOCKQUOTE,
    CLOSE_OL,
    CLOSE_UL,
    CLOSE_OL_TIGHT,
    CLOSE_UL_TIGHT,
    CLOSE_LI,
    CLOSE_TABLE,
    CLOSE_THEAD,
    CLOSE_TBODY,
    CLOSE_TR,
    CLOSE_TH,
    CLOSE_TD,
    CLOSE_TIGHT_PARA,
    CLOSE_FN_SECTION,
    CLOSE_FN_DEF,
    CLOSE_FN_DEF_SKIP,
    CLOSE_NOOP
} close_kind;

typedef struct {
#ifdef MULTIPLICITY
    tTHX        my_perl;     /* captured interpreter, used via dTHXa */
#endif
    mds_buf*    buf;
    close_kind  closes[CLOSE_STACK_MAX];
    int         top;
    /* tight_stack[i] = 1 if the i-th open container forces tight rendering
     * (suppress <p>) for direct paragraph children, 0 otherwise. Push on
     * every container enter that affects paragraph rendering (LIST,
     * BLOCKQUOTE); pop on close. Paragraph checks tight_stack[tight_top-1].
     * BLOCKQUOTE pushes 0 to shield its inner paragraphs from an outer
     * tight list. Loose LIST also pushes 0 to shield deeper paragraphs. */
    unsigned char tight_stack[CLOSE_STACK_MAX];
    int         tight_top;
    int         tight_depth;   /* legacy counter; still tracks >0 = any tight list active */
    int         image_depth;   /* >0 = inside an <img>; collect alt text */
    char*       alt;           /* malloc'd alt-text accumulator */
    size_t      alt_len;
    size_t      alt_cap;
    unsigned    flags;         /* MDS_FLAG_* bitmask */
    int         li_check_pending; /* >0 = look for [ ]/[x] at start of first text in LIST_ITEM */
    int         li_first_block;   /* 1 = waiting for first block child after <li> */
    int         need_nl_next;     /* 1 = emit '\n' before next block (after suppressed tight para) */
    int         in_thead;         /* 1 inside <thead>, 0 inside <tbody> */
    const mds_align* tbl_aligns;  /* current table column alignments */
    unsigned    tbl_ncols;        /* column count */
    unsigned    tbl_col;          /* next cell index in current row */
    /* GFM autolink: coalesce consecutive cb_text events so the scanner can
     * see across intra-word `_`/`*` splits emitted by the inline tokenizer. */
    char*       pending_text;
    size_t      pending_len;
    size_t      pending_cap;
    /* Tier E.1 — footnote tracking. fn_used[i] = malloc'd label string;
     * fn_uses[i] = instance counter (incremented per FOOTNOTE_REF).
     * fn_count = number of distinct labels used. Indices double as 1-based
     * footnote ordinals (first-use order). fn_skip is set while we are
     * inside a FOOTNOTE_DEF whose label was never referenced; it
     * suppresses all output between enter/leave of that def. fn_in_def is
     * the 1-based ordinal of the def we are currently rendering (so the
     * leave callback knows what backref label/idx to emit). fn_section_open
     * tracks whether we have already written the <section><ol> headers. */
    const char** fn_labels;       /* arena-borrowed label pointers */
    size_t*     fn_label_lens;    /* parallel label lengths */
    unsigned*   fn_uses;          /* parallel use counts */
    size_t      fn_count;
    size_t      fn_cap;
    int         fn_skip;          /* inside an unused def */
    unsigned    fn_in_def;        /* 1-based ordinal of current def, 0 if none */
    const char* fn_in_def_label;  /* label of current def (for backref) */
    size_t      fn_in_def_label_len;
} render_state;

/* Forward decls for helpers defined later but used by early callbacks. */
static void flush_pending_text(pTHX_ render_state* st);
static unsigned fn_lookup(render_state* st, const char* s, size_t n);
static unsigned fn_register(render_state* st, const char* s, size_t n);
static void write_fn_label_attr(pTHX_ mds_buf* b, const char* s, size_t n);

/* Static escape tables: zero entry means byte is safe (run/memcpy through);
 * non-zero entries supply the replacement string and length. Built once at
 * load with the four chars that matter in HTML text/attribute context. */
typedef struct { const char* rep; unsigned char rlen; } mds_esc_entry;

static const mds_esc_entry mds_escape_text[256] = {
    ['<'] = { "&lt;",   4 },
    ['>'] = { "&gt;",   4 },
    ['&'] = { "&amp;",  5 },
    ['"'] = { "&quot;", 6 },
};

/* Image info stack: 32 nested images max — generous. */
#define IMG_STACK_MAX 32
typedef struct {
    const char* href; size_t hlen;
    const char* title; size_t tlen;
} img_info;
static img_info g_img_stack[IMG_STACK_MAX];
static int      g_img_stack_top = 0;

static void alt_append(render_state* st, const char* s, size_t n) {
    if (n == 0) return;
    if (st->alt_len + n + 1 > st->alt_cap) {
        size_t nc = st->alt_cap ? st->alt_cap * 2 : 64;
        while (nc < st->alt_len + n + 1) nc *= 2;
        st->alt = (char*)realloc(st->alt, nc);
        st->alt_cap = nc;
    }
    memcpy(st->alt + st->alt_len, s, n);
    st->alt_len += n;
}

/* The XS hook keeps this single per-call instance alive in stack scope and
 * passes &st as ud_storage. mds_render_html_install() merely wires the
 * callbacks and stores `buf` (the rest is already initialised). */

static void push_close(render_state* st, close_kind k) {
    if (st->top < CLOSE_STACK_MAX) st->closes[st->top++] = k;
}
static close_kind pop_close(render_state* st) {
    return st->top > 0 ? st->closes[--st->top] : CLOSE_NONE;
}

/* SWAR-accelerated HTML escape. Every rendered text byte flows
 * through here, so the inner loop matters a lot. We process 8 bytes at a
 * time with the classic "has-zero" trick to detect whether the word
 * contains ANY of '<', '>', '&', '"'. Clean words advance the run
 * pointer without touching `mds_buf_write` until we either hit a hot
 * byte or reach the tail. On corpora dominated by plain prose this skips
 * ~7/8 of the per-byte work. */
#define MDS_HASZ(x) (((x) - 0x0101010101010101ULL) & ~(x) & 0x8080808080808080ULL)
static inline uint64_t mds_escape_hot64(uint64_t w) {
    /* '<'=0x3C  '>'=0x3E  '&'=0x26  '"'=0x22 */
    uint64_t a = w ^ 0x3C3C3C3C3C3C3C3CULL;
    uint64_t b = w ^ 0x3E3E3E3E3E3E3E3EULL;
    uint64_t c = w ^ 0x2626262626262626ULL;
    uint64_t d = w ^ 0x2222222222222222ULL;
    return MDS_HASZ(a) | MDS_HASZ(b) | MDS_HASZ(c) | MDS_HASZ(d);
}

MDS_HOT static void html_escape(pTHX_ mds_buf* b, const char* s, size_t n) {
    const char* run = s;
    const char* end = s + n;
    const char* p   = s;
    /* Fast 8-byte SWAR skip over clean prose. Unaligned loads are fine
     * on arm64/x86_64; misaligned reads near the page boundary are safe
     * because we never dereference past `end`. */
    while ((size_t)(end - p) >= 8) {
        uint64_t w;
        memcpy(&w, p, 8);
        if (MDS_LIKELY(!mds_escape_hot64(w))) { p += 8; continue; }
        /* Word has at least one hot byte: emit any of the 8 that match
         * via the standard table, then continue. */
        for (int k = 0; k < 8; k++) {
            const mds_esc_entry e = mds_escape_text[(unsigned char)p[k]];
            if (!e.rlen) continue;
            if (p + k > run) mds_buf_write(aTHX_ b, run, (size_t)((p + k) - run));
            mds_buf_write(aTHX_ b, e.rep, e.rlen);
            run = p + k + 1;
        }
        p += 8;
    }
    /* Scalar tail (<8 bytes). */
    for (; p < end; p++) {
        const mds_esc_entry e = mds_escape_text[(unsigned char)*p];
        if (!e.rlen) continue;
        if (p > run) mds_buf_write(aTHX_ b, run, (size_t)(p - run));
        mds_buf_write(aTHX_ b, e.rep, e.rlen);
        run = p + 1;
    }
    if (run < end) mds_buf_write(aTHX_ b, run, (size_t)(end - run));
}
#undef MDS_HASZ

/* HTML-escape with backslash unescaping for ASCII punctuation. Used for
 * link/image title attributes which honour §6.1 backslash escapes. */
static void html_escape_unesc(pTHX_ mds_buf* b, const char* s, size_t n) {
    /* expand_entity_at writes through `out` which is just `b` for titles. */
    extern size_t mds_expand_entity_at(const char* s, size_t i, size_t n,
                                       char* out, size_t* outlen);
    size_t i = 0;
    while (i < n) {
        if (s[i] == '\\' && i + 1 < n) {
            unsigned char nx = (unsigned char)s[i+1];
            if ((nx >= 0x21 && nx <= 0x2F) ||
                (nx >= 0x3A && nx <= 0x40) ||
                (nx >= 0x5B && nx <= 0x60) ||
                (nx >= 0x7B && nx <= 0x7E)) {
                const mds_esc_entry e = mds_escape_text[nx];
                if (e.rlen) mds_buf_write(aTHX_ b, e.rep, e.rlen);
                else        mds_buf_write(aTHX_ b, (const char*)&nx, 1);
                i += 2;
                continue;
            }
        }
        if (s[i] == '&') {
            char ebuf[8]; size_t elen;
            size_t k = mds_expand_entity_at(s, i, n, ebuf, &elen);
            if (k) {
                /* Re-emit decoded bytes through html_escape_text so chars
                 * like '<' '&' '"' get re-escaped. */
                for (size_t z = 0; z < elen; z++) {
                    const mds_esc_entry e = mds_escape_text[(unsigned char)ebuf[z]];
                    if (e.rlen) mds_buf_write(aTHX_ b, e.rep, e.rlen);
                    else        mds_buf_write(aTHX_ b, ebuf + z, 1);
                }
                i += k;
                continue;
            }
        }
        const mds_esc_entry e = mds_escape_text[(unsigned char)s[i]];
        if (e.rlen) mds_buf_write(aTHX_ b, e.rep, e.rlen);
        else        mds_buf_write(aTHX_ b, s + i, 1);
        i++;
    }
}

/* Decode an entity at s[i..] — either &name; or &#NNN; / &#xHH; — into
 * `out` (up to 8 bytes is enough for any single entity; multi-codepoint
 * entities like &ngE; need 5). Returns the number of source bytes
 * consumed (0 = not an entity), and stores the UTF-8 length in *outlen. */
size_t mds_expand_entity_at(const char* s, size_t i, size_t n,
                            char* out, size_t* outlen) {
    if (i >= n || s[i] != '&') return 0;
    size_t q = i + 1;
    if (q < n && s[q] == '#') {
        q++;
        unsigned long cp = 0;
        size_t digits = 0;
        if (q < n && (s[q] == 'x' || s[q] == 'X')) {
            q++;
            while (q < n && digits < 6 && isxdigit((unsigned char)s[q])) {
                char c = s[q];
                cp = cp * 16 + (c <= '9' ? c - '0' :
                                (c <= 'F' ? c - 'A' + 10 : c - 'a' + 10));
                q++; digits++;
            }
        } else {
            while (q < n && digits < 7 && s[q] >= '0' && s[q] <= '9') {
                cp = cp * 10 + (unsigned long)(s[q] - '0');
                q++; digits++;
            }
        }
        if (!digits || q >= n || s[q] != ';') return 0;
        q++;
        if (cp == 0 || cp > 0x10FFFF || (cp >= 0xD800 && cp <= 0xDFFF))
            cp = 0xFFFD;
        size_t blen;
        if (cp < 0x80) {
            out[0] = (char)cp; blen = 1;
        } else if (cp < 0x800) {
            out[0] = (char)(0xC0 | (cp >> 6));
            out[1] = (char)(0x80 | (cp & 0x3F)); blen = 2;
        } else if (cp < 0x10000) {
            out[0] = (char)(0xE0 | (cp >> 12));
            out[1] = (char)(0x80 | ((cp >> 6) & 0x3F));
            out[2] = (char)(0x80 | (cp & 0x3F)); blen = 3;
        } else {
            out[0] = (char)(0xF0 | (cp >> 18));
            out[1] = (char)(0x80 | ((cp >> 12) & 0x3F));
            out[2] = (char)(0x80 | ((cp >> 6) & 0x3F));
            out[3] = (char)(0x80 | (cp & 0x3F)); blen = 4;
        }
        *outlen = blen;
        return q - i;
    }
    size_t name_start = q;
    while (q < n && isalnum((unsigned char)s[q])) q++;
    if (q == name_start || q >= n || s[q] != ';') return 0;
    const mds_entity* e = mds_entity_lookup(s + name_start, q - name_start);
    if (!e) return 0;
    if (e->ulen > 8) return 0;
    memcpy(out, e->utf8, e->ulen);
    *outlen = e->ulen;
    return (q + 1) - i;
}

/* Returns 1 if URL starts with a scheme we refuse to emit (xss vectors)
 * unless MDS_FLAG_UNSAFE is set. `for_image` permits data: image MIME. */
static int url_is_dangerous(const char* s, size_t n, int for_image) {
    /* Skip leading whitespace (already trimmed upstream but be defensive). */
    size_t i = 0;
    while (i < n && (unsigned char)s[i] <= 0x20) i++;
    /* Find optional scheme ending at ':'. */
    size_t j = i;
    while (j < n) {
        char c = s[j];
        if (c == ':') break;
        if (!isalnum((unsigned char)c) && c != '+' && c != '-' && c != '.') return 0;
        j++;
    }
    if (j >= n || j == i) return 0;
    size_t sl = j - i;
    /* Case-insensitive scheme compare. */
    #define SCHEME_EQ(lit) (sl == (sizeof(lit) - 1) && strncasecmp(s + i, (lit), sl) == 0)
    if (SCHEME_EQ("javascript") || SCHEME_EQ("vbscript") || SCHEME_EQ("file"))
        return 1;
    if (SCHEME_EQ("data")) {
        if (!for_image) return 1;
        /* Allow only data:image/{gif,png,jpeg,webp}[;...]. */
        const char* p = s + j + 1;
        size_t rem = n - (j + 1);
        if (rem < 6 || strncasecmp(p, "image/", 6) != 0) return 1;
        p += 6; rem -= 6;
        if ((rem >= 3 && strncasecmp(p, "gif", 3) == 0) ||
            (rem >= 3 && strncasecmp(p, "png", 3) == 0) ||
            (rem >= 4 && strncasecmp(p, "jpeg", 4) == 0) ||
            (rem >= 4 && strncasecmp(p, "webp", 4) == 0))
            return 0;
        return 1;
    }
    #undef SCHEME_EQ
    return 0;
}

/* ------------------ callbacks ------------------ */

static void cb_enter_block(void* ud, mds_block_type t, const mds_block_detail* d) {
    render_state* st = (render_state*)ud;
    dTHXa(st->my_perl);
    mds_buf* b = st->buf;
    /* While we are inside an unreferenced footnote def, swallow all
     * nested block events. Push CLOSE_NOOP so the matching leave pops
     * cleanly without disturbing the close stack. The FOOTNOTE_DEF
     * event itself is fired BEFORE fn_skip is set (in this function),
     * so the dispatch below still runs for that one event. */
    if (st->fn_skip && t != MDS_BLK_FOOTNOTE_DEF && t != MDS_BLK_FOOTNOTES_SECTION) {
        push_close(st, CLOSE_NOOP);
        return;
    }
    flush_pending_text(aTHX_ st);
    /* Decide if this block starts on the same line as <li> (tight para)
     * or on a new line. li_first_block fires only for the very first child
     * of a list item; need_nl_next fires after a suppressed tight paragraph
     * when any further block follows in the same item. */
    if (st->li_first_block) {
        st->li_first_block = 0;
        int tight_para = (t == MDS_BLK_PARAGRAPH &&
                          st->tight_top > 0 &&
                          st->tight_stack[st->tight_top - 1]);
        if (!tight_para) MDS_BUF_LIT(b, "\n");
    } else if (st->need_nl_next) {
        st->need_nl_next = 0;
        MDS_BUF_LIT(b, "\n");
    }

    switch (t) {
    case MDS_BLK_DOC:
        push_close(st, CLOSE_NOOP);
        break;
    case MDS_BLK_PARAGRAPH: {
        int suppress = (st->tight_top > 0 &&
                        st->tight_stack[st->tight_top - 1]);
        if (suppress) {
            push_close(st, CLOSE_TIGHT_PARA);
        } else {
            MDS_BUF_LIT(b, "<p>");
            push_close(st, CLOSE_P);
        }
        break;
    }
    case MDS_BLK_HEADING: {
        int lvl = d->u.heading.level;
        if (lvl < 1) lvl = 1; else if (lvl > 6) lvl = 6;
        char open[5] = { '<', 'h', (char)('0' + lvl), '>', 0 };
        mds_buf_write(aTHX_ b, open, 4);
        push_close(st, (close_kind)(CLOSE_H1 + (lvl - 1)));
        break;
    }
    case MDS_BLK_THEMATIC_BREAK:
        MDS_BUF_LIT(b, "<hr />\n");
        push_close(st, CLOSE_NOOP);
        break;
    case MDS_BLK_HTML:
        /* Raw HTML block: children are EV_RAW text; nothing to wrap. */
        push_close(st, CLOSE_NOOP);
        break;
    case MDS_BLK_CODE_FENCED: {
        const char* info = d->u.code_fenced.info;
        size_t       il  = d->u.code_fenced.info_len;
        /* Trim info to first word for the language class. */
        size_t lang_len = 0;
        while (lang_len < il && info[lang_len] != ' ' && info[lang_len] != '\t')
            lang_len++;
        if (lang_len > 0) {
            MDS_BUF_LIT(b, "<pre><code class=\"language-");
            html_escape_unesc(aTHX_ b, info, lang_len);
            MDS_BUF_LIT(b, "\">");
        } else {
            MDS_BUF_LIT(b, "<pre><code>");
        }
        push_close(st, CLOSE_CODE_FENCED);
        break;
    }
    case MDS_BLK_CODE_INDENTED:
        MDS_BUF_LIT(b, "<pre><code>");
        push_close(st, CLOSE_CODE_INDENTED);
        break;
    case MDS_BLK_QUOTE:
        MDS_BUF_LIT(b, "<blockquote>\n");
        if (st->tight_top < CLOSE_STACK_MAX)
            st->tight_stack[st->tight_top++] = 0;
        push_close(st, CLOSE_BLOCKQUOTE);
        break;
    case MDS_BLK_LIST: {
        int tight = d->u.list.is_tight;
        if (tight) st->tight_depth++;
        if (st->tight_top < CLOSE_STACK_MAX)
            st->tight_stack[st->tight_top++] = (unsigned char)(tight ? 1 : 0);
        if (d->u.list.is_ordered) {
            if (d->u.list.start != 1) {
                char buf[64];
                int n = snprintf(buf, sizeof buf, "<ol start=\"%d\">\n",
                                 d->u.list.start);
                if (n > 0) mds_buf_write(aTHX_ b, buf, (size_t)n);
            } else {
                MDS_BUF_LIT(b, "<ol>\n");
            }
            push_close(st, tight ? CLOSE_OL_TIGHT : CLOSE_OL);
        } else {
            MDS_BUF_LIT(b, "<ul>\n");
            push_close(st, tight ? CLOSE_UL_TIGHT : CLOSE_UL);
        }
        break;
    }
    case MDS_BLK_LIST_ITEM:
        MDS_BUF_LIT(b, "<li>");
        st->li_check_pending = 1;
        st->li_first_block = 1;
        st->need_nl_next = 0;
        push_close(st, CLOSE_LI);
        break;
    case MDS_BLK_TABLE:
        MDS_BUF_LIT(b, "<table>\n");
        st->tbl_aligns = d->u.table.aligns;
        st->tbl_ncols  = d->u.table.ncols;
        push_close(st, CLOSE_TABLE);
        break;
    case MDS_BLK_TABLE_HEAD:
        MDS_BUF_LIT(b, "<thead>\n");
        st->in_thead = 1;
        push_close(st, CLOSE_THEAD);
        break;
    case MDS_BLK_TABLE_BODY:
        MDS_BUF_LIT(b, "<tbody>\n");
        st->in_thead = 0;
        push_close(st, CLOSE_TBODY);
        break;
    case MDS_BLK_TABLE_ROW:
        MDS_BUF_LIT(b, "<tr>\n");
        st->tbl_col = 0;
        push_close(st, CLOSE_TR);
        break;
    case MDS_BLK_TABLE_CELL: {
        mds_align al = (st->tbl_col < st->tbl_ncols && st->tbl_aligns)
                       ? st->tbl_aligns[st->tbl_col] : MDS_ALIGN_NONE;
        if (MDS_LIKELY(al == MDS_ALIGN_NONE)) {
            /* Fast path — 4-byte literal in a single buf write.
             * synth-tables corpus hits this on every cell. */
            if (st->in_thead) MDS_BUF_LIT(b, "<th>");
            else              MDS_BUF_LIT(b, "<td>");
        } else {
            const char* tag = st->in_thead ? "th" : "td";
            const char* aname = al == MDS_ALIGN_LEFT ? "left"
                              : al == MDS_ALIGN_RIGHT ? "right" : "center";
            mds_buf_write(aTHX_ b, "<", 1);
            mds_buf_write(aTHX_ b, tag, 2);
            MDS_BUF_LIT(b, " align=\"");
            mds_buf_write(aTHX_ b, aname, strlen(aname));
            MDS_BUF_LIT(b, "\">");
        }
        st->tbl_col++;
        push_close(st, st->in_thead ? CLOSE_TH : CLOSE_TD);
        break;
    }
    default:
        push_close(st, CLOSE_NOOP);
        break;
    case MDS_BLK_FOOTNOTES_SECTION:
        MDS_BUF_LIT(b, "<section class=\"footnotes\" data-footnotes>\n<ol>\n");
        push_close(st, CLOSE_FN_SECTION);
        break;
    case MDS_BLK_FOOTNOTE_DEF: {
        const char* lab = d->u.footnote_def.label;
        size_t       ll = d->u.footnote_def.label_len;
        unsigned     idx = fn_lookup(st, lab, ll);
        if (!idx) {
            /* Unreferenced def: drop the entire subtree. */
            st->fn_skip = 1;
            push_close(st, CLOSE_FN_DEF_SKIP);
            break;
        }
        st->fn_in_def = idx;
        st->fn_in_def_label = lab;
        st->fn_in_def_label_len = ll;
        MDS_BUF_LIT(b, "<li id=\"fn-");
        write_fn_label_attr(aTHX_ b, lab, ll);
        MDS_BUF_LIT(b, "\">\n");
        push_close(st, CLOSE_FN_DEF);
        break;
    }
    }
}

static void cb_leave_block(void* ud, mds_block_type t) {
    render_state* st = (render_state*)ud;
    dTHXa(st->my_perl);
    mds_buf* b = st->buf;
    (void)t;
    /* Mirror cb_enter_block: in fn_skip mode, nested events were given
     * CLOSE_NOOP on the stack so pop here and return without flushing. */
    if (st->fn_skip) {
        close_kind k = pop_close(st);
        if (k == CLOSE_FN_DEF_SKIP) {
            st->fn_skip = 0;
        }
        return;
    }
    flush_pending_text(aTHX_ st);
    if (st->li_check_pending == 2) {
        MDS_BUF_LIT(b, "[");
    }
    st->li_check_pending = 0;
    close_kind k = pop_close(st);
    switch (k) {
    case CLOSE_NONE:
    case CLOSE_NOOP:
        break;
    case CLOSE_P:           MDS_BUF_LIT(b, "</p>\n"); break;
    case CLOSE_H1:          MDS_BUF_LIT(b, "</h1>\n"); break;
    case CLOSE_H2:          MDS_BUF_LIT(b, "</h2>\n"); break;
    case CLOSE_H3:          MDS_BUF_LIT(b, "</h3>\n"); break;
    case CLOSE_H4:          MDS_BUF_LIT(b, "</h4>\n"); break;
    case CLOSE_H5:          MDS_BUF_LIT(b, "</h5>\n"); break;
    case CLOSE_H6:          MDS_BUF_LIT(b, "</h6>\n"); break;
    case CLOSE_CODE_FENCED: MDS_BUF_LIT(b, "</code></pre>\n"); break;
    case CLOSE_CODE_INDENTED: MDS_BUF_LIT(b, "</code></pre>\n"); break;
    case CLOSE_BLOCKQUOTE:  MDS_BUF_LIT(b, "</blockquote>\n");
                            if (st->tight_top > 0) st->tight_top--; break;
    case CLOSE_OL:          MDS_BUF_LIT(b, "</ol>\n");
                            if (st->tight_top > 0) st->tight_top--; break;
    case CLOSE_UL:          MDS_BUF_LIT(b, "</ul>\n");
                            if (st->tight_top > 0) st->tight_top--; break;
    case CLOSE_OL_TIGHT:    MDS_BUF_LIT(b, "</ol>\n"); st->tight_depth--;
                            if (st->tight_top > 0) st->tight_top--; break;
    case CLOSE_UL_TIGHT:    MDS_BUF_LIT(b, "</ul>\n"); st->tight_depth--;
                            if (st->tight_top > 0) st->tight_top--; break;
    case CLOSE_LI:          st->need_nl_next = 0; st->li_first_block = 0;
                            MDS_BUF_LIT(b, "</li>\n"); break;
    case CLOSE_TIGHT_PARA:  st->need_nl_next = 1; break;
    case CLOSE_TABLE:       MDS_BUF_LIT(b, "</table>\n"); break;
    case CLOSE_THEAD:       MDS_BUF_LIT(b, "</thead>\n"); break;
    case CLOSE_TBODY:       MDS_BUF_LIT(b, "</tbody>\n"); break;
    case CLOSE_TR:          MDS_BUF_LIT(b, "</tr>\n"); break;
    case CLOSE_TH:          MDS_BUF_LIT(b, "</th>\n"); break;
    case CLOSE_TD:          MDS_BUF_LIT(b, "</td>\n"); break;
    case CLOSE_FN_SECTION:  MDS_BUF_LIT(b, "</ol>\n</section>\n"); break;
    case CLOSE_FN_DEF_SKIP: st->fn_skip = 0; break;
    case CLOSE_FN_DEF: {
        /* Sub-scanned body has now emitted all its blocks. If the very
         * last bytes are `</p>\n` we rewind 5 bytes and inject the
         * backref(s) before the </p>; otherwise the def ended in a
         * code block / quote / etc. and the backref goes after as a
         * bare <a>. One backref per ref-instance; first is plain `↩`,
         * subsequent are `↩<sup>N</sup>`. */
        unsigned idx  = st->fn_in_def;
        unsigned uses = (idx >= 1 && idx <= st->fn_count) ? st->fn_uses[idx - 1] : 1;
        int inject_in_p = 0;
        if (b->cur - b->base >= 5 && memcmp(b->cur - 5, "</p>\n", 5) == 0) {
            b->cur -= 5;
            inject_in_p = 1;
        }
        for (unsigned u = 1; u <= uses; u++) {
            /* Inside <p>: separate anchors from preceding content with
             * a space. As a bare trailing anchor (after </pre>/<blockquote>
             * etc.) no leading space — the newline from the prior block
             * already provides the visual gap. Subsequent anchors in the
             * same line always get a single space separator. */
            if (inject_in_p || u > 1) MDS_BUF_LIT(b, " ");
            MDS_BUF_LIT(b, "<a href=\"#fnref-");
            write_fn_label_attr(aTHX_ b, st->fn_in_def_label, st->fn_in_def_label_len);
            if (u > 1) {
                char nbuf[16];
                int nn = snprintf(nbuf, sizeof nbuf, "-%u", u);
                if (nn > 0) mds_buf_write(aTHX_ b, nbuf, (size_t)nn);
            }
            MDS_BUF_LIT(b, "\" class=\"footnote-backref\" data-footnote-backref data-footnote-backref-idx=\"");
            char ibuf[32];
            int in;
            if (u == 1) in = snprintf(ibuf, sizeof ibuf, "%u", idx);
            else        in = snprintf(ibuf, sizeof ibuf, "%u-%u", idx, u);
            if (in > 0) mds_buf_write(aTHX_ b, ibuf, (size_t)in);
            MDS_BUF_LIT(b, "\" aria-label=\"Back to reference ");
            if (in > 0) mds_buf_write(aTHX_ b, ibuf, (size_t)in);
            MDS_BUF_LIT(b, "\">\xe2\x86\xa9");
            if (u > 1) {
                MDS_BUF_LIT(b, "<sup class=\"footnote-ref\">");
                char nbuf[16];
                int nn = snprintf(nbuf, sizeof nbuf, "%u", u);
                if (nn > 0) mds_buf_write(aTHX_ b, nbuf, (size_t)nn);
                MDS_BUF_LIT(b, "</sup>");
            }
            MDS_BUF_LIT(b, "</a>");
        }
        if (inject_in_p) {
            MDS_BUF_LIT(b, "</p>\n");
        } else {
            MDS_BUF_LIT(b, "\n");
        }
        MDS_BUF_LIT(b, "</li>\n");
        st->fn_in_def = 0;
        st->fn_in_def_label = NULL;
        st->fn_in_def_label_len = 0;
        break;
    }
    }
}

/* ------------------ GFM autolink extension (§6.9) ------------------ */

static void write_url_attr(pTHX_ mds_buf* b, const char* s, size_t n);

/* GFM footnote label encoder. Percent-encodes bytes that would be unsafe
 * in an HTML attribute / URL fragment. Per GFM expected output, leaves
 * unreserved + a few sub-delim bytes literal: `( ) ! * - . _ ~ /` and
 * alphanumerics. Everything else (incl. control bytes, space, `"`, `<`,
 * `>`, `&`, `\\`, `^`, backtick, `{ | }`, `[ ]`, `%`, `?`, `#`, `+`,
 * `=`, `,`, `;`, `:`, `'`, `@`, `$`, `/`) is %XX-encoded. Multi-byte
 * UTF-8 sequences are encoded byte-by-byte. */
static void write_fn_label_attr(pTHX_ mds_buf* b, const char* s, size_t n) {
    static const char hex[] = "0123456789ABCDEF";
    for (size_t i = 0; i < n; i++) {
        unsigned char c = (unsigned char)s[i];
        int safe = (c >= '0' && c <= '9') ||
                   (c >= 'A' && c <= 'Z') ||
                   (c >= 'a' && c <= 'z') ||
                   c == '(' || c == ')' || c == '!' || c == '*' ||
                   c == '-' || c == '.' || c == '_' || c == '~' ||
                   c == '/';
        if (safe) {
            mds_buf_write(aTHX_ b, (const char*)&c, 1);
        } else {
            char esc[3] = { '%', hex[c >> 4], hex[c & 0xF] };
            mds_buf_write(aTHX_ b, esc, 3);
        }
    }
}

/* Look up label in render_state's used set. Returns 1-based ordinal
 * if found, 0 if not. Linear scan; footnote counts are tiny. */
static unsigned fn_lookup(render_state* st, const char* s, size_t n) {
    for (size_t i = 0; i < st->fn_count; i++) {
        if (st->fn_label_lens[i] == n &&
            memcmp(st->fn_labels[i], s, n) == 0) {
            return (unsigned)(i + 1);
        }
    }
    return 0;
}

/* Register or increment usage. Returns 1-based ordinal. */
static unsigned fn_register(render_state* st, const char* s, size_t n) {
    unsigned idx = fn_lookup(st, s, n);
    if (idx) {
        st->fn_uses[idx - 1]++;
        return idx;
    }
    if (st->fn_count == st->fn_cap) {
        size_t nc = st->fn_cap ? st->fn_cap * 2 : 8;
        st->fn_labels    = (const char**)realloc(st->fn_labels,    nc * sizeof(*st->fn_labels));
        st->fn_label_lens = (size_t*)realloc(st->fn_label_lens,    nc * sizeof(*st->fn_label_lens));
        st->fn_uses      = (unsigned*)realloc(st->fn_uses,         nc * sizeof(*st->fn_uses));
        st->fn_cap = nc;
    }
    /* Label bytes are stable in the arena (footnote table arena_dup). */
    st->fn_labels[st->fn_count]      = s;
    st->fn_label_lens[st->fn_count]  = n;
    st->fn_uses[st->fn_count]        = 1;
    st->fn_count++;
    return (unsigned)st->fn_count;
}

static int gfm_word_byte(unsigned char c) {
    return isalnum(c) || c == '_';
}

/* Domain scanner. p..end points at start of would-be domain. Returns
 * length on success (>=1 dot, valid segments, no underscores in last
 * two segments), else 0. */
static size_t gfm_scan_domain_ex(const char* p, const char* end, int need_dot) {
    const char* q = p;
    int dots = 0;
    const char* last_dot = NULL;
    const char* prev_dot = NULL;
    while (q < end) {
        unsigned char c = (unsigned char)*q;
        if (c == '.') {
            if (q == p || q[-1] == '.') break;
            prev_dot = last_dot; last_dot = q; dots++;
            q++; continue;
        }
        if (isalnum(c) || c == '-' || c == '_' || c >= 0x80) { q++; continue; }
        break;
    }
    if (q == p) return 0;
    if (need_dot && dots == 0) return 0;
    /* Permit trailing dot in domain; strip-trail handles it. Roll q back
     * just past the dot for the underscore check. */
    const char* check_end = q;
    if (check_end > p && check_end[-1] == '.') {
        check_end--;
        /* recompute last_dot/prev_dot if the trailing dot was the last one */
        if (last_dot == check_end) {
            last_dot = prev_dot;
            prev_dot = NULL;
            for (const char* r = p; r < last_dot; r++) if (*r == '.') prev_dot = r;
        }
    }
    if (last_dot) {
        /* No underscores in last two segments. */
        const char* l_s = last_dot + 1;
        const char* l_e = check_end;
        for (const char* r = l_s; r < l_e; r++) if (*r == '_') return 0;
        const char* m_s = prev_dot ? prev_dot + 1 : p;
        const char* m_e = last_dot;
        for (const char* r = m_s; r < m_e; r++) if (*r == '_') return 0;
    } else {
        /* No dot at all (only allowed when need_dot==0): also disallow `_`. */
        for (const char* r = p; r < check_end; r++) if (*r == '_') return 0;
    }
    return (size_t)(q - p);
}

static size_t gfm_scan_domain(const char* p, const char* end) {
    return gfm_scan_domain_ex(p, end, 1);
}

/* Strip GFM trailing-punct from URL run p..q. Returns new q. */
static const char* gfm_strip_trail(const char* p, const char* q) {
    while (q > p) {
        unsigned char c = (unsigned char)q[-1];
        if (c == '?' || c == '!' || c == '.' || c == ',' ||
            c == ':' || c == '*' || c == '_' || c == '~' ||
            c == '\'' || c == '"') {
            q--; continue;
        }
        if (c == ')') {
            int opens = 0, closes = 0;
            for (const char* r = p; r < q; r++) {
                if (*r == '(') opens++;
                else if (*r == ')') closes++;
            }
            if (closes > opens) { q--; continue; }
            break;
        }
        if (c == ';') {
            const char* r = q - 1;
            while (r > p && isalnum((unsigned char)*r)) r--;
            if (r > p && *r == '&') { q = r; continue; }
        }
        break;
    }
    return q;
}

/* Scan body bytes for a URL after a scheme (http/https/ftp) or after a
 * www. prefix. Returns length consumed past start of domain, 0 if no
 * valid URL. */
static size_t gfm_scan_url_body(const char* p, const char* end) {
    size_t dl = gfm_scan_domain_ex(p, end, 0);
    if (!dl) return 0;
    const char* q = p + dl;
    /* Optional path: byte run until whitespace, '<', or end. */
    while (q < end) {
        unsigned char c = (unsigned char)*q;
        if (c <= 0x20 || c == '<') break;
        q++;
    }
    /* Strip trailing punctuation, applied to entire URL [p,q). */
    q = gfm_strip_trail(p, q);
    return (size_t)(q - p);
}

/* Email body scan starting at @. base is start of text run so we can
 * walk backwards. Sets *l_out to local-part length before @, *d_out to
 * domain length after @. Returns 1 on success. */
static int gfm_scan_email_at(const char* base, const char* at, const char* end,
                              size_t* l_out, size_t* d_out) {
    /* local part: [a-zA-Z0-9._+-] walking back */
    const char* L = at;
    while (L > base) {
        unsigned char c = (unsigned char)L[-1];
        if (isalnum(c) || c == '.' || c == '_' || c == '+' || c == '-') L--;
        else break;
    }
    if (L == at) return 0;
    if (*L == '.') return 0;  /* can't start with dot */
    /* domain: alphanum, _, -, ., must have a dot, no _ in last two segs */
    const char* D = at + 1;
    size_t dl = gfm_scan_domain(D, end);
    if (!dl) return 0;
    /* Trailing punct stripping on domain. */
    const char* de = gfm_strip_trail(D, D + dl);
    dl = (size_t)(de - D);
    if (!dl) return 0;
    *l_out = (size_t)(at - L);
    *d_out = dl;
    return 1;
}

/* Emit a chunk that may contain autolinks; non-autolink bytes go through
 * html_escape. Caller must have already handled li_check / image alt. */
/* Emit a chunk that may contain autolinks; non-autolink bytes go through
 * html_escape. Caller must have already handled li_check / image alt. */
static void gfm_emit_autolinked(pTHX_ render_state* st,
                                 const char* s, size_t n);

/* Flush any buffered text accumulated from consecutive cb_text events.
 * Called by every non-text event so the AUTOLINK scanner sees the whole
 * contiguous text run (the inline tokenizer splits at intra-word `_`/`*`). */
static void flush_pending_text(pTHX_ render_state* st) {
    if (st->pending_len == 0) return;
    size_t n = st->pending_len;
    st->pending_len = 0;  /* clear first so re-entry is safe */
    gfm_emit_autolinked(aTHX_ st, st->pending_text, n);
}

static void gfm_emit_autolinked(pTHX_ render_state* st,
                                 const char* s, size_t n) {
    mds_buf* b = st->buf;
    const char* end = s + n;
    const char* run = s;
    const char* p = s;
    while (p < end) {
        unsigned char c = (unsigned char)*p;
        int boundary = (p == s) ? 1 : !gfm_word_byte((unsigned char)p[-1]);
        if (!boundary) { p++; continue; }
        /* http://, https://, ftp:// */
        size_t url_len = 0; size_t scheme_len = 0; int is_email = 0;
        const char* scheme_prefix = NULL;
        if (c == 'h' && (size_t)(end - p) >= 7 &&
            memcmp(p, "http://", 7) == 0) {
            scheme_len = 7;
            url_len = gfm_scan_url_body(p + 7, end);
        } else if (c == 'h' && (size_t)(end - p) >= 8 &&
                   memcmp(p, "https://", 8) == 0) {
            scheme_len = 8;
            url_len = gfm_scan_url_body(p + 8, end);
        } else if (c == 'f' && (size_t)(end - p) >= 6 &&
                   memcmp(p, "ftp://", 6) == 0) {
            scheme_len = 6;
            url_len = gfm_scan_url_body(p + 6, end);
        } else if (c == 'w' && (size_t)(end - p) >= 4 &&
                   memcmp(p, "www.", 4) == 0) {
            scheme_len = 0;
            /* www. variant: require at least one further dot in domain. */
            size_t dl = gfm_scan_domain(p, end);
            if (dl) {
                /* Optional path. */
                const char* qq = p + dl;
                while (qq < end) {
                    unsigned char x = (unsigned char)*qq;
                    if (x <= 0x20 || x == '<') break;
                    qq++;
                }
                qq = gfm_strip_trail(p, qq);
                url_len = (size_t)(qq - p);
            }
            if (url_len) scheme_prefix = "http://";
        }
        if (scheme_len || scheme_prefix) {
            if (url_len) {
                size_t total = (scheme_prefix ? url_len : scheme_len + url_len);
                /* flush text before */
                if (p > run) html_escape(aTHX_ b, run, (size_t)(p - run));
                MDS_BUF_LIT(b, "<a href=\"");
                if (scheme_prefix) mds_buf_write(aTHX_ b, scheme_prefix, strlen(scheme_prefix));
                write_url_attr(aTHX_ b, p, total);
                MDS_BUF_LIT(b, "\">");
                html_escape(aTHX_ b, p, total);
                MDS_BUF_LIT(b, "</a>");
                p += total;
                run = p;
                continue;
            }
        }
        /* xmpp:user@host or mailto:user@host */
        if (c == 'x' && (size_t)(end - p) >= 5 && memcmp(p, "xmpp:", 5) == 0) {
            const char* at = (const char*)memchr(p + 5, '@', (size_t)(end - p - 5));
            if (at) {
                size_t ll, dl;
                if (gfm_scan_email_at(p + 5, at, end, &ll, &dl) &&
                    (const char*)at - ll == p + 5) {
                    size_t total = 5 + ll + 1 + dl;
                    /* xmpp: includes optional /path in the autolink. */
                    const char* q = p + total;
                    if (q < end && *q == '/') {
                        while (q < end) {
                            unsigned char x = (unsigned char)*q;
                            if (x <= 0x20 || x == '<') break;
                            q++;
                        }
                        q = gfm_strip_trail(p + total, q);
                        total = (size_t)(q - p);
                    }
                    if (p > run) html_escape(aTHX_ b, run, (size_t)(p - run));
                    MDS_BUF_LIT(b, "<a href=\"");
                    write_url_attr(aTHX_ b, p, total);
                    MDS_BUF_LIT(b, "\">");
                    html_escape(aTHX_ b, p, total);
                    MDS_BUF_LIT(b, "</a>");
                    p += total;
                    run = p;
                    continue;
                }
            }
        }
        if (c == 'm' && (size_t)(end - p) >= 7 && memcmp(p, "mailto:", 7) == 0) {
            const char* at = (const char*)memchr(p + 7, '@', (size_t)(end - p - 7));
            if (at) {
                size_t ll, dl;
                if (gfm_scan_email_at(p + 7, at, end, &ll, &dl) &&
                    (const char*)at - ll == p + 7) {
                    size_t total = 7 + ll + 1 + dl;
                    if (p > run) html_escape(aTHX_ b, run, (size_t)(p - run));
                    MDS_BUF_LIT(b, "<a href=\"mailto:");
                    write_url_attr(aTHX_ b, p + 7, total - 7);
                    MDS_BUF_LIT(b, "\">");
                    html_escape(aTHX_ b, p, total);
                    MDS_BUF_LIT(b, "</a>");
                    p += total;
                    run = p;
                    continue;
                }
            }
        }
        /* Bare email: look forward for '@', not just at this byte. */
        if (isalnum(c) || c == '.' || c == '_' || c == '+' || c == '-') {
            /* Find next '@' within this text run, bounded by whitespace. */
            const char* q = p;
            while (q < end) {
                unsigned char x = (unsigned char)*q;
                if (x == '@') break;
                if (!(isalnum(x) || x == '.' || x == '_' || x == '+' || x == '-')) {
                    q = NULL; break;
                }
                q++;
            }
            if (q && q < end && *q == '@') {
                size_t ll, dl;
                if (gfm_scan_email_at(p, q, end, &ll, &dl) &&
                    q - ll == p) {
                    size_t total = ll + 1 + dl;
                    if (p > run) html_escape(aTHX_ b, run, (size_t)(p - run));
                    MDS_BUF_LIT(b, "<a href=\"mailto:");
                    write_url_attr(aTHX_ b, p, total);
                    MDS_BUF_LIT(b, "\">");
                    html_escape(aTHX_ b, p, total);
                    MDS_BUF_LIT(b, "</a>");
                    p += total;
                    run = p;
                    continue;
                }
            }
        }
        p++;
    }
    if (run < end) html_escape(aTHX_ b, run, (size_t)(end - run));
}

static void cb_text(void* ud, const char* s, size_t n) {
    render_state* st = (render_state*)ud;
    dTHXa(st->my_perl);
    if (st->fn_skip) return;
    if (st->li_check_pending) {
        /* Inline tokenizer may emit `[` as its own text event, then the
         * remainder. Coalesce up to two text events to detect [ ]/[x]/[X]
         * followed by space. State 1 = fresh LI; state 2 = saw lone `[`. */
        if (st->li_check_pending == 1 && n == 1 && s[0] == '[') {
            st->li_check_pending = 2;
            return;
        }
        if (st->li_check_pending == 2) {
            st->li_check_pending = 0;
            if (n >= 3 && s[1] == ']' && s[2] == ' ' &&
                (s[0] == ' ' || s[0] == 'x' || s[0] == 'X')) {
                if (s[0] == ' ')
                    MDS_BUF_LIT(st->buf, "<input type=\"checkbox\" disabled=\"\" /> ");
                else
                    MDS_BUF_LIT(st->buf, "<input type=\"checkbox\" checked=\"\" disabled=\"\" /> ");
                s += 3; n -= 3;
                if (n == 0) return;
            } else {
                /* Not a task marker — flush buffered `[` then fall through. */
                MDS_BUF_LIT(st->buf, "[");
            }
        } else {
            st->li_check_pending = 0;
            if (n >= 4 && s[0] == '[' && s[2] == ']' && s[3] == ' ' &&
                (s[1] == ' ' || s[1] == 'x' || s[1] == 'X')) {
                if (s[1] == ' ')
                    MDS_BUF_LIT(st->buf, "<input type=\"checkbox\" disabled=\"\" /> ");
                else
                    MDS_BUF_LIT(st->buf, "<input type=\"checkbox\" disabled=\"\" checked=\"\" /> ");
                s += 4; n -= 4;
                if (n == 0) return;
            }
        }
    }
    if (st->image_depth > 0) {
        /* For alt: append raw bytes (no HTML escape — done later when
         * emitting alt="..." attribute via html_escape on accumulated). */
        alt_append(st, s, n);
        return;
    }
    if (st->flags & MDS_FLAG_AUTOLINK) {
        /* Accumulate; flushed by any non-text callback. */
        size_t need = st->pending_len + n;
        if (need > st->pending_cap) {
            size_t nc = st->pending_cap ? st->pending_cap : 64;
            while (nc < need) nc *= 2;
            char* np = (char*)realloc(st->pending_text, nc);
            if (!np) { /* OOM: bypass coalescing for this chunk */
                flush_pending_text(aTHX_ st);
                gfm_emit_autolinked(aTHX_ st, s, n);
                return;
            }
            st->pending_text = np;
            st->pending_cap  = nc;
        }
        memcpy(st->pending_text + st->pending_len, s, n);
        st->pending_len += n;
        return;
    }
    html_escape(aTHX_ st->buf, s, n);
}

static void cb_raw(void* ud, const char* s, size_t n) {
    render_state* st = (render_state*)ud;
    dTHXa(st->my_perl);
    if (st->fn_skip) return;
    flush_pending_text(aTHX_ st);
    if (st->image_depth > 0) {
        /* raw HTML inside alt: stripped to text per spec; just append as text */
        alt_append(st, s, n);
        return;
    }
    if (st->flags & MDS_FLAG_DISALLOW_RAW_HTML) {
        /* GFM §6.11: rewrite the opening `<` of these tags as `&lt;`. */
        static const char* const banned[] = {
            "title", "textarea", "style", "xmp", "iframe",
            "noembed", "noframes", "script", "plaintext", NULL
        };
        const char* run = s;
        const char* end = s + n;
        for (const char* p = s; p < end; p++) {
            if (*p != '<') continue;
            const char* q = p + 1;
            if (q < end && *q == '/') q++;
            const char* name = q;
            while (q < end && isalnum((unsigned char)*q)) q++;
            size_t nlen = (size_t)(q - name);
            if (nlen == 0) continue;
            int hit = 0;
            for (int i = 0; banned[i]; i++) {
                size_t bl = strlen(banned[i]);
                if (nlen == bl && strncasecmp(name, banned[i], bl) == 0) {
                    hit = 1; break;
                }
            }
            if (!hit) continue;
            if (p > run) mds_buf_write(aTHX_ st->buf, run, (size_t)(p - run));
            mds_buf_write(aTHX_ st->buf, "&lt;", 4);
            run = p + 1;
        }
        if (run < end) mds_buf_write(aTHX_ st->buf, run, (size_t)(end - run));
        return;
    }
    mds_buf_write(aTHX_ st->buf, s, n);
}

/* ------------------ inline callbacks ------------------ */

static void write_url_attr_impl(pTHX_ mds_buf* b, const char* s, size_t n, int unesc) {
    /* Percent-escape URL: leave already-safe chars; escape <>"'`{}|\ ^ and ws.
     * Then HTML-escape & to &amp;. When unesc=1, also unescape \X for ASCII
     * punctuation (§6.1 — backslash escapes work in link destinations and
     * titles, but NOT in autolinks). Entities (named + numeric) are expanded
     * before percent-encoding so the resulting UTF-8 bytes are escaped. */
    static const char hex[] = "0123456789ABCDEF";
    for (size_t i = 0; i < n; ) {
        unsigned char c = (unsigned char)s[i];
        if (unesc && c == '\\' && i + 1 < n) {
            unsigned char nx = (unsigned char)s[i+1];
            if ((nx >= 0x21 && nx <= 0x2F) ||
                (nx >= 0x3A && nx <= 0x40) ||
                (nx >= 0x5B && nx <= 0x60) ||
                (nx >= 0x7B && nx <= 0x7E)) {
                c = nx;
                i += 2;
                goto emit_byte;
            }
        }
        if (c == '&') {
            char ebuf[8]; size_t elen;
            size_t k = mds_expand_entity_at(s, i, n, ebuf, &elen);
            if (k) {
                /* Re-feed decoded bytes through the same loop logic, so
                 * non-ASCII gets percent-encoded and '&' itself becomes
                 * &amp; (CommonMark expects e.g. &amp; → %26? No, spec
                 * says ENT decoded to '&' renders as &amp; in href, and
                 * &auml; → ä → %C3%A4). */
                for (size_t z = 0; z < elen; z++) {
                    unsigned char ec = (unsigned char)ebuf[z];
                    if (ec == '&') { mds_buf_write(aTHX_ b, "&amp;", 5); continue; }
                    if (ec <= 0x20 || ec == 0x7f ||
                        ec >= 0x80 ||
                        ec == '"' || ec == '<' || ec == '>' || ec == '`' ||
                        ec == '{' || ec == '}' || ec == '|' || ec == '\\' ||
                        ec == '^' || ec == '[' || ec == ']') {
                        char esc[3] = { '%', hex[ec >> 4], hex[ec & 0xF] };
                        mds_buf_write(aTHX_ b, esc, 3);
                        continue;
                    }
                    mds_buf_write(aTHX_ b, (const char*)&ec, 1);
                }
                i += k;
                continue;
            }
            mds_buf_write(aTHX_ b, "&amp;", 5);
            i++;
            continue;
        }
        i++;
emit_byte:
        if (c <= 0x20 || c == 0x7f || c >= 0x80 ||
            c == '"' || c == '<' || c == '>' || c == '`' ||
            c == '{' || c == '}' || c == '|' || c == '\\' ||
            c == '^' || c == '[' || c == ']') {
            char esc[3] = { '%', hex[c >> 4], hex[c & 0xF] };
            mds_buf_write(aTHX_ b, esc, 3);
            continue;
        }
        mds_buf_write(aTHX_ b, (const char*)&c, 1);
    }
}

static void write_url_attr(pTHX_ mds_buf* b, const char* s, size_t n) {
    write_url_attr_impl(aTHX_ b, s, n, /*unesc=*/1);
}
static void write_url_attr_raw(pTHX_ mds_buf* b, const char* s, size_t n) {
    write_url_attr_impl(aTHX_ b, s, n, /*unesc=*/0);
}

static void cb_enter_inline(void* ud, mds_inline_type t, const mds_inline_detail* d) {
    render_state* st = (render_state*)ud;
    dTHXa(st->my_perl);
    mds_buf* b = st->buf;
    if (st->fn_skip) return;
    flush_pending_text(aTHX_ st);
    /* If the LIST_ITEM had a lone `[` buffered, flush it before this inline. */
    if (st->li_check_pending == 2) {
        MDS_BUF_LIT(b, "[");
        st->li_check_pending = 0;
    } else if (st->li_check_pending && t != MDS_INL_TEXT) {
        st->li_check_pending = 0;
    }
    /* Inside an image: alt text is plain text per CommonMark. Suppress all
     * markup wrappers; child TEXT/RAW bytes are routed through alt_append. */
    if (st->image_depth > 0 && t != MDS_INL_IMAGE) {
        return;
    }
    switch (t) {
    case MDS_INL_EMPH:    MDS_BUF_LIT(b, "<em>"); break;
    case MDS_INL_STRONG:  MDS_BUF_LIT(b, "<strong>"); break;
    case MDS_INL_STRIKE:  MDS_BUF_LIT(b, "<del>"); break;
    case MDS_INL_CODE:    MDS_BUF_LIT(b, "<code>"); break;
    case MDS_INL_SOFTBREAK:
        if (st->flags & MDS_FLAG_HARD_BREAKS) MDS_BUF_LIT(b, "<br />\n");
        else MDS_BUF_LIT(b, "\n");
        break;
    case MDS_INL_LINEBREAK: MDS_BUF_LIT(b, "<br />\n"); break;
    case MDS_INL_LINK: {
        MDS_BUF_LIT(b, "<a href=\"");
        if ((st->flags & MDS_FLAG_UNSAFE) ||
            !url_is_dangerous(d->u.link.href, d->u.link.href_len, 0)) {
            write_url_attr(aTHX_ b, d->u.link.href, d->u.link.href_len);
        }
        MDS_BUF_LIT(b, "\"");
        if (d->u.link.title_len) {
            MDS_BUF_LIT(b, " title=\"");
            html_escape_unesc(aTHX_ b, d->u.link.title, d->u.link.title_len);
            MDS_BUF_LIT(b, "\"");
        }
        MDS_BUF_LIT(b, ">");
        break;
    }
    case MDS_INL_IMAGE: {
        if (st->image_depth == 0) {
            st->alt_len = 0;
        }
        st->image_depth++;
        if (g_img_stack_top < IMG_STACK_MAX) {
            g_img_stack[g_img_stack_top].href = d->u.image.href;
            g_img_stack[g_img_stack_top].hlen = d->u.image.href_len;
            g_img_stack[g_img_stack_top].title = d->u.image.title;
            g_img_stack[g_img_stack_top].tlen = d->u.image.title_len;
            g_img_stack_top++;
        }
        break;
    }
    case MDS_INL_AUTOLINK: {
        MDS_BUF_LIT(b, "<a href=\"");
        if (d->u.autolink.is_email) {
            MDS_BUF_LIT(b, "mailto:");
        }
        if ((st->flags & MDS_FLAG_UNSAFE) ||
            !url_is_dangerous(d->u.autolink.uri, d->u.autolink.uri_len, 0)) {
            write_url_attr_raw(aTHX_ b, d->u.autolink.uri, d->u.autolink.uri_len);
        }
        MDS_BUF_LIT(b, "\">");
        html_escape(aTHX_ b, d->u.autolink.uri, d->u.autolink.uri_len);
        break;
    }
    case MDS_INL_HTML_INLINE:
        /* opens nothing; children come via cb_raw */
        break;
    case MDS_INL_FOOTNOTE_REF: {
        const char* lab = d->u.footnote_ref.label;
        size_t       ll = d->u.footnote_ref.label_len;
        unsigned     idx = fn_register(st, lab, ll);
        unsigned     uses = st->fn_uses[idx - 1];
        MDS_BUF_LIT(b, "<sup class=\"footnote-ref\"><a href=\"#fn-");
        write_fn_label_attr(aTHX_ b, lab, ll);
        MDS_BUF_LIT(b, "\" id=\"fnref-");
        write_fn_label_attr(aTHX_ b, lab, ll);
        if (uses > 1) {
            char nbuf[16];
            int nn = snprintf(nbuf, sizeof nbuf, "-%u", uses);
            if (nn > 0) mds_buf_write(aTHX_ b, nbuf, (size_t)nn);
        }
        MDS_BUF_LIT(b, "\" data-footnote-ref>");
        char ibuf[16];
        int in = snprintf(ibuf, sizeof ibuf, "%u", idx);
        if (in > 0) mds_buf_write(aTHX_ b, ibuf, (size_t)in);
        MDS_BUF_LIT(b, "</a></sup>");
        break;
    }
    case MDS_INL_TEXT:
    case MDS_INL__COUNT:
        break;
    }
}

/* (image-info stack defined above) */

static void cb_leave_inline(void* ud, mds_inline_type t) {
    render_state* st = (render_state*)ud;
    dTHXa(st->my_perl);
    mds_buf* b = st->buf;
    if (st->fn_skip) return;
    flush_pending_text(aTHX_ st);
    /* Suppress closing wrappers while we are still inside an image (alt mode).
     * The leave for the image itself still fires this function with image_depth
     * about to be decremented, so only short-circuit for nested non-image kinds. */
    if (st->image_depth > 0 && t != MDS_INL_IMAGE) {
        return;
    }
    switch (t) {
    case MDS_INL_EMPH:    MDS_BUF_LIT(b, "</em>"); break;
    case MDS_INL_STRONG:  MDS_BUF_LIT(b, "</strong>"); break;
    case MDS_INL_STRIKE:  MDS_BUF_LIT(b, "</del>"); break;
    case MDS_INL_CODE:    MDS_BUF_LIT(b, "</code>"); break;
    case MDS_INL_LINK:    MDS_BUF_LIT(b, "</a>"); break;
    case MDS_INL_AUTOLINK: MDS_BUF_LIT(b, "</a>"); break;
    case MDS_INL_FOOTNOTE_REF: break;  /* closing tags emitted in enter */
    case MDS_INL_IMAGE: {
        st->image_depth--;
        if (g_img_stack_top > 0) g_img_stack_top--;
        if (st->image_depth == 0) {
            mds_buf* rb = st->buf;
            img_info inf = g_img_stack[g_img_stack_top];
            MDS_BUF_LIT(rb, "<img src=\"");
            if ((st->flags & MDS_FLAG_UNSAFE) ||
                !url_is_dangerous(inf.href, inf.hlen, 1)) {
                write_url_attr(aTHX_ rb, inf.href, inf.hlen);
            }
            MDS_BUF_LIT(rb, "\" alt=\"");
            if (st->alt_len) html_escape(aTHX_ rb, st->alt, st->alt_len);
            MDS_BUF_LIT(rb, "\"");
            if (inf.tlen) {
                MDS_BUF_LIT(rb, " title=\"");
                html_escape_unesc(aTHX_ rb, inf.title, inf.tlen);
                MDS_BUF_LIT(rb, "\"");
            }
            MDS_BUF_LIT(rb, " />");
            st->alt_len = 0;
        }
        break;
    }
    case MDS_INL_SOFTBREAK:
    case MDS_INL_LINEBREAK:
    case MDS_INL_HTML_INLINE:
    case MDS_INL_TEXT:
    case MDS_INL__COUNT:
        break;
    }
}

/* ------------------ install ------------------ */

/* The caller allocates a `render_state` (on the stack) and passes &st as
 * ud_storage. We initialise its `buf` field, capture the current aTHX,
 * and wire up the callbacks. ud_out is set to point at the state. */
void mds_render_html_install(mds_callbacks* cb, void** ud_out, mds_buf* buf,
                             unsigned flags) {
    dTHX;
    render_state* st = (render_state*)*ud_out;
#ifdef MULTIPLICITY
    st->my_perl = aTHX;
#endif
    st->buf     = buf;
    st->top     = 0;
    st->tight_depth = 0;
    st->image_depth = 0;
    st->alt = NULL; st->alt_len = 0; st->alt_cap = 0;
    st->flags = flags;
    st->li_check_pending = 0;
    st->in_thead = 0;
    st->tbl_aligns = NULL;
    st->tbl_ncols = 0;
    st->tbl_col = 0;
    st->pending_text = NULL;
    st->pending_len = 0;
    st->pending_cap = 0;
    st->fn_labels = NULL;
    st->fn_label_lens = NULL;
    st->fn_uses = NULL;
    st->fn_count = 0;
    st->fn_cap = 0;
    st->fn_skip = 0;
    st->fn_in_def = 0;
    st->fn_in_def_label = NULL;
    st->fn_in_def_label_len = 0;
    g_img_stack_top = 0;

    cb->enter_block  = cb_enter_block;
    cb->leave_block  = cb_leave_block;
    cb->enter_inline = cb_enter_inline;
    cb->leave_inline = cb_leave_inline;
    cb->text         = cb_text;
    cb->raw          = cb_raw;
}

int mds_render_html_used_footnote(void* ud, size_t i,
                                  const char** label_out,
                                  size_t* label_len_out) {
    render_state* st = (render_state*)ud;
    if (!st || i >= st->fn_count) return 0;
    if (label_out)     *label_out     = st->fn_labels[i];
    if (label_len_out) *label_len_out = st->fn_label_lens[i];
    return 1;
}
