/* mds_inline.c — scalar CommonMark §6 inline tokenizer.
 *
 * Algorithm follows the cmark reference implementation and the
 * CommonMark spec appendix ("An algorithm for parsing nested emphasis
 * and links").
 *
 * Single forward pass builds a doubly-linked list of nodes:
 *   TEXT, CODE, AUTOLINK, HTMLINLINE, SOFTBREAK, LINEBREAK
 *   DELIM (* / _ runs)
 *   OPEN_BRACKET ([), OPEN_BANG_BRACKET (![)
 *
 * Then process_emphasis() folds DELIM nodes into EMPH/STRONG using the
 * delimiter-run stack algorithm.  process_links_and_images() is folded
 * inline during the forward pass at ']' time (cmark does it that way too).
 *
 * Finally emit() walks the linked list and dispatches SAX events.
 */

#include "mds_inline.h"
#include "mds_ir.h"
#include "mds_linkref.h"
#include "mds_footnote.h"
#include "mds_entity.h"
#include "mds_arena.h"
#include "mds.h"
#if defined(__ARM_NEON) || defined(__aarch64__)
#  include <arm_neon.h>
#  define MDS_INLINE_HAVE_NEON 1
#endif

#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <stdio.h>

/* ---------------- byte class table ---------------- */

enum {
    BC_PUNCT = 1 << 0,   /* ASCII punctuation per CommonMark §2.1 */
    BC_WS    = 1 << 1,   /* ASCII whitespace: space tab \n \v \f \r */
    BC_ALNUM = 1 << 2
};

static unsigned char g_byteclass[256];
static int g_byteclass_inited = 0;

static void byteclass_init(void) {
    int c;
    if (g_byteclass_inited) return;
    for (c = 0; c < 256; c++) {
        unsigned f = 0;
        if (c == ' ' || c == '\t' || c == '\n' || c == '\v' ||
            c == '\f' || c == '\r')
            f |= BC_WS;
        if ((c >= '0' && c <= '9') ||
            (c >= 'A' && c <= 'Z') ||
            (c >= 'a' && c <= 'z'))
            f |= BC_ALNUM;
        /* CommonMark "ASCII punctuation": !"#$%&'()*+,-./:;<=>?@[\]^_`{|}~ */
        if ((c >= 33 && c <= 47) || (c >= 58 && c <= 64) ||
            (c >= 91 && c <= 96) || (c >= 123 && c <= 126))
            f |= BC_PUNCT;
        g_byteclass[c] = (unsigned char)f;
    }
    g_byteclass_inited = 1;
}

static inline int is_ascii_punct(unsigned char c) { return g_byteclass[c] & BC_PUNCT; }
static inline int is_unicode_ws(unsigned char c)  { return g_byteclass[c] & BC_WS;    }

/* Decode a single UTF-8 codepoint at s[i] (i < n). Returns codepoint;
 * sets *adv to bytes consumed. Lenient on invalid bytes. */
static unsigned mds_utf8_decode(const char* s, size_t n, size_t i, int* adv) {
    unsigned char c = (unsigned char)s[i];
    if (c < 0x80) { *adv = 1; return c; }
    if ((c & 0xE0) == 0xC0 && i + 1 < n &&
        ((unsigned char)s[i+1] & 0xC0) == 0x80) {
        *adv = 2;
        return ((unsigned)(c & 0x1F) << 6) | ((unsigned char)s[i+1] & 0x3F);
    }
    if ((c & 0xF0) == 0xE0 && i + 2 < n &&
        ((unsigned char)s[i+1] & 0xC0) == 0x80 &&
        ((unsigned char)s[i+2] & 0xC0) == 0x80) {
        *adv = 3;
        return ((unsigned)(c & 0x0F) << 12)
             | (((unsigned char)s[i+1] & 0x3F) << 6)
             | ((unsigned char)s[i+2] & 0x3F);
    }
    if ((c & 0xF8) == 0xF0 && i + 3 < n &&
        ((unsigned char)s[i+1] & 0xC0) == 0x80 &&
        ((unsigned char)s[i+2] & 0xC0) == 0x80 &&
        ((unsigned char)s[i+3] & 0xC0) == 0x80) {
        *adv = 4;
        return ((unsigned)(c & 0x07) << 18)
             | (((unsigned char)s[i+1] & 0x3F) << 12)
             | (((unsigned char)s[i+2] & 0x3F) << 6)
             | ((unsigned char)s[i+3] & 0x3F);
    }
    *adv = 1;
    return c;
}

/* Decode the codepoint ending just before s[pos]; pos > 0 required.
 * Walks backward over continuation bytes (max 3). Returns codepoint;
 * sets *cp_start to start offset. */
static unsigned mds_utf8_decode_prev(const char* s, size_t n, size_t pos,
                                     size_t* cp_start) {
    size_t i = pos - 1;
    int back = 0;
    int adv;
    while (i > 0 && back < 3 &&
           ((unsigned char)s[i] & 0xC0) == 0x80) {
        i--; back++;
    }
    *cp_start = i;
    return mds_utf8_decode(s, n, i, &adv);
}

/* Is codepoint Unicode whitespace per CommonMark spec (General_Category
 * Zs, plus tab/CR/LF/FF). */
static int cp_is_ws(unsigned cp) {
    if (cp == 0x09 || cp == 0x0A || cp == 0x0B || cp == 0x0C || cp == 0x0D ||
        cp == 0x20) return 1;
    if (cp == 0xA0) return 1;           /* NBSP */
    if (cp == 0x1680) return 1;
    if (cp >= 0x2000 && cp <= 0x200A) return 1;
    if (cp == 0x2028 || cp == 0x2029) return 1;
    if (cp == 0x202F || cp == 0x205F) return 1;
    if (cp == 0x3000) return 1;
    return 0;
}

/* Is codepoint Unicode punctuation per CommonMark 0.31 spec
 * (General_Category P* or S*). For non-ASCII we approximate with the
 * ranges most likely to appear in spec examples: Latin-1 punctuation
 * and symbols (¡¢£¤¥¦§¨©ª«¬®¯°±²³´¶·¸¹º»¼½¾¿×÷), General Punctuation
 * (U+2000-206F), Currency Symbols (U+20A0-U+20CF), Letterlike (some),
 * Arrows (U+2190-U+21FF), Mathematical (U+2200-U+22FF), Misc Tech
 * (U+2300-U+23FF), Box Drawing/Block (U+2500-U+259F), Geometric
 * (U+25A0-U+25FF), Misc Symbols (U+2600-U+26FF), Dingbats (U+2700-U+27BF),
 * CJK Symbols (U+3000-U+303F), Halfwidth (U+FF00-U+FFEF symbols subset). */
static int cp_is_punct(unsigned cp) {
    if (cp < 0x80) return g_byteclass[cp] & BC_PUNCT;
    /* Latin-1 Supplement P/S categories */
    if (cp >= 0xA1 && cp <= 0xBF) return 1;
    if (cp == 0xD7 || cp == 0xF7) return 1;
    /* General Punctuation block */
    if (cp >= 0x2000 && cp <= 0x206F) return 1;
    /* Superscripts/Subscripts (Sm subset) */
    if (cp >= 0x2070 && cp <= 0x209F) return 1;
    /* Currency Symbols */
    if (cp >= 0x20A0 && cp <= 0x20CF) return 1;
    /* Letterlike symbols (S subset) */
    if (cp >= 0x2100 && cp <= 0x214F) return 1;
    /* Arrows / Math / Misc Tech / Box / Geometric / Misc / Dingbats */
    if (cp >= 0x2190 && cp <= 0x27BF) return 1;
    /* CJK Symbols and Punctuation */
    if (cp >= 0x3000 && cp <= 0x303F) return 1;
    /* Halfwidth / Fullwidth punctuation (subset) */
    if (cp >= 0xFF00 && cp <= 0xFF0F) return 1;
    if (cp >= 0xFF1A && cp <= 0xFF20) return 1;
    if (cp >= 0xFF3B && cp <= 0xFF40) return 1;
    if (cp >= 0xFF5B && cp <= 0xFF65) return 1;
    return 0;
}

/* ---------------- inline node ---------------- */

typedef enum {
    N_TEXT,
    N_CODE,
    N_AUTOLINK,
    N_HTMLINLINE,
    N_SOFTBREAK,
    N_LINEBREAK,
    N_DELIM,           /* * or _ run */
    N_OPEN_BRACKET,    /* '[' */
    N_OPEN_BANG,       /* '![' */
    N_EMPH,            /* after process_emphasis */
    N_STRONG,
    N_STRIKE,
    N_LINK,
    N_IMAGE,
    N_FOOTNOTE_REF  /* GFM §6.13 */
} ntype;

typedef struct inode {
    ntype           type;
    struct inode*   prev;
    struct inode*   next;
    const char*     s;
    size_t          n;
    int             is_email;
    unsigned char   delim_char;
    int             count;
    int             can_open;
    int             can_close;
    int             active;
    int             bracket_after_emph;
    struct inode*   children;
    struct inode*   children_tail;
    const char*     href; size_t hlen;
    const char*     title; size_t tlen;
} inode;
/* Bitfield packing of the flag ints was attempted but
 * produced no measurable speedup (commonmark-spec / synth-prose within
 * +/-2%, synth-tables drifted -5%) so the original layout is kept. The
 * 32-byte aspirational target requires splitting href/title into a side
 * allocation keyed off type == N_LINK|N_IMAGE; deferred until the inline
 * parser is rewritten around tagged unions. */

/* ---------------- scanner state ---------------- */

typedef struct {
    mds_ctx*    ctx;
    const char* s;
    size_t      n;
    size_t      pos;
    inode*      head;
    inode*      tail;
} scn;

static inode* node_new(scn* z, ntype t) {
    inode* x = (inode*)mds_arena_alloc(&z->ctx->arena, sizeof(inode));
    memset(x, 0, sizeof *x);
    x->type = t;
    return x;
}

static void append(scn* z, inode* x) {
    x->prev = z->tail;
    x->next = NULL;
    if (z->tail) z->tail->next = x;
    else         z->head = x;
    z->tail = x;
}

static void append_to(inode* parent, inode* x) {
    x->prev = parent->children_tail;
    x->next = NULL;
    if (parent->children_tail) parent->children_tail->next = x;
    else                       parent->children = x;
    parent->children_tail = x;
}

/* Append literal text bytes; coalesces with previous TEXT node if possible
 * (only if contiguous in source). */
static void append_text(scn* z, const char* p, size_t k) {
    inode* x;
    if (k == 0) return;
    if (z->tail && z->tail->type == N_TEXT &&
        z->tail->s + z->tail->n == p) {
        z->tail->n += k;
        return;
    }
    x = node_new(z, N_TEXT);
    x->s = p; x->n = k;
    append(z, x);
}

/* Allocate a fresh text node referring to arena-stored bytes (e.g. an
 * entity expansion). */
static void append_text_dup(scn* z, const char* p, size_t k) {
    char* d;
    inode* x;
    if (k == 0) return;
    d = (char*)mds_arena_alloc(&z->ctx->arena, k);
    memcpy(d, p, k);
    x = node_new(z, N_TEXT);
    x->s = d; x->n = k;
    append(z, x);
}

/* ---------------- flanking rules (§6.4) ---------------- */
/*
 * preceded_by_ws / followed_by_ws : Unicode whitespace at run boundary
 * preceded_by_punct / followed_by_punct : ASCII punct (Unicode punct is
 *    approximated as the high-bit set + any non-alnum byte; full UTF-8
 *    Unicode-punct lookup is deferred).
 *
 * left-flanking  iff: NOT followed by Unicode-WS AND
 *                     (NOT followed by punct OR
 *                      preceded by Unicode-WS or punct)
 *
 * right-flanking iff: NOT preceded by Unicode-WS AND
 *                     (NOT preceded by punct OR
 *                      followed by Unicode-WS or punct)
 */
static int classify_run(const char* s, size_t n, size_t pos, size_t runlen,
                        int* can_open_out, int* can_close_out,
                        unsigned char ch) {
    unsigned cp_before, cp_after;
    size_t after_pos;
    int before_ws, after_ws, before_punct, after_punct;
    int left, right;
    int can_open, can_close;

    /* Decode the codepoint immediately before pos and the one starting
     * at pos+runlen. Treat document edges as line feeds (whitespace).
     * Decoding multi-byte codepoints is essential for non-ASCII spec
     * cases (NBSP as WS, currency / arrows / etc. as Unicode punct). */
    if (pos == 0) {
        cp_before = '\n';
    } else {
        unsigned char b = (unsigned char)s[pos - 1];
        if (b < 0x80) {
            cp_before = b;
        } else {
            size_t st;
            cp_before = mds_utf8_decode_prev(s, n, pos, &st);
        }
    }
    after_pos = pos + runlen;
    if (after_pos >= n) {
        cp_after = '\n';
    } else {
        unsigned char a = (unsigned char)s[after_pos];
        if (a < 0x80) {
            cp_after = a;
        } else {
            int adv;
            cp_after = mds_utf8_decode(s, n, after_pos, &adv);
        }
    }

    before_ws    = cp_is_ws(cp_before);
    after_ws     = cp_is_ws(cp_after);
    before_punct = cp_is_punct(cp_before);
    after_punct  = cp_is_punct(cp_after);

    left  = !after_ws  && (!after_punct  || before_ws || before_punct);
    right = !before_ws && (!before_punct || after_ws  || after_punct);

    if (ch == '_') {
        /* §6.4: _ delimiters with intra-word restrictions */
        can_open  = left  && (!right || before_punct);
        can_close = right && (!left  || after_punct);
    } else {
        /* * (and ~ for strikethrough) */
        can_open  = left;
        can_close = right;
    }
    *can_open_out  = can_open;
    *can_close_out = can_close;
    return 1;
}

/* ---------------- code span (§6.3) ---------------- */

/* Try to match a code span starting at pos (first byte = '`').
 * On success returns new pos past the closing fence; emits one node.
 * On failure returns 0 (caller consumes one backtick as text). */
static size_t try_code_span(scn* z, size_t pos) {
    const char* s = z->s;
    size_t n = z->n;
    size_t open_start = pos;
    size_t open_len;
    size_t content_start;
    size_t scan;
    while (pos < n && s[pos] == '`') pos++;
    open_len = pos - open_start;
    content_start = pos;
    scan = pos;
    while (scan < n) {
        /* find next run of backticks */
        const char* p = (const char*)memchr(s + scan, '`', n - scan);
        size_t bs;
        size_t be;
        if (!p) return 0;
        bs = (size_t)(p - s);
        be = bs;
        while (be < n && s[be] == '`') be++;
        if (be - bs == open_len) {
            /* matched */
            size_t cs = content_start;
            size_t ce = bs;
            int has_nonspace = 0;
            int needs_replace = 0;
            inode* x;
            size_t i;
            /* normalisation: if first and last are space, and content is
             * not all spaces, strip one leading and trailing space. */
            for (i = cs; i < ce; i++) {
                if (s[i] != ' ' && s[i] != '\n') { has_nonspace = 1; break; }
            }
            if (has_nonspace && ce - cs >= 2 &&
                (s[cs] == ' ' || s[cs] == '\n') &&
                (s[ce - 1] == ' ' || s[ce - 1] == '\n')) {
                cs++; ce--;
            }
            /* replace newlines with spaces */
            for (i = cs; i < ce; i++) {
                if (s[i] == '\n') { needs_replace = 1; break; }
            }
            x = node_new(z, N_CODE);
            if (needs_replace) {
                char* d = (char*)mds_arena_alloc(&z->ctx->arena, ce - cs);
                for (i = cs; i < ce; i++)
                    d[i - cs] = (s[i] == '\n') ? ' ' : s[i];
                x->s = d; x->n = ce - cs;
            } else {
                x->s = s + cs; x->n = ce - cs;
            }
            append(z, x);
            return be;
        }
        scan = be;
    }
    return 0;
}

/* ---------------- entity (§6.2) ---------------- */

/* Try to decode entity starting at pos (s[pos] == '&').
 * Returns chars consumed (including & and ;) on success, 0 otherwise. */
static size_t try_entity(scn* z, size_t pos) {
    const char* s = z->s; size_t n = z->n;
    size_t q;
    size_t name_start;
    const mds_entity* e;
    mds_entity ent_scratch;
    if (pos + 1 >= n) return 0;
    q = pos + 1;
    if (s[q] == '#') {
        unsigned long cp = 0;
        size_t digits = 0;
        char buf[5];
        size_t blen;
        q++;
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
        /* Encode codepoint as UTF-8. NUL → U+FFFD. */
        if (cp == 0 || cp > 0x10FFFF || (cp >= 0xD800 && cp <= 0xDFFF))
            cp = 0xFFFD;
        if (cp < 0x80) {
            buf[0] = (char)cp; blen = 1;
        } else if (cp < 0x800) {
            buf[0] = (char)(0xC0 | (cp >> 6));
            buf[1] = (char)(0x80 | (cp & 0x3F)); blen = 2;
        } else if (cp < 0x10000) {
            buf[0] = (char)(0xE0 | (cp >> 12));
            buf[1] = (char)(0x80 | ((cp >> 6) & 0x3F));
            buf[2] = (char)(0x80 | (cp & 0x3F)); blen = 3;
        } else {
            buf[0] = (char)(0xF0 | (cp >> 18));
            buf[1] = (char)(0x80 | ((cp >> 12) & 0x3F));
            buf[2] = (char)(0x80 | ((cp >> 6) & 0x3F));
            buf[3] = (char)(0x80 | (cp & 0x3F)); blen = 4;
        }
        append_text_dup(z, buf, blen);
        return q - pos;
    }
    /* named entity */
    name_start = q;
    while (q < n && isalnum((unsigned char)s[q])) q++;
    if (q == name_start || q >= n || s[q] != ';') return 0;
    e = mds_entity_lookup(s + name_start, q - name_start, &ent_scratch);
    if (!e) return 0;
    q++;
    append_text_dup(z, e->utf8, e->ulen);
    return q - pos;
}

/* ---------------- autolink (§6.7) ---------------- */

/* Returns total chars (including <>) on success, 0 otherwise. */
static size_t try_autolink(scn* z, size_t pos) {
    const char* s = z->s; size_t n = z->n;
    size_t q;
    size_t scheme_start;
    size_t scheme_len;
    size_t body_start;
    size_t r;
    size_t e_start;
    int dot_ok = 0;
    int label_len = 0;
    inode* x;
    if (pos >= n || s[pos] != '<') return 0;
    q = pos + 1;
    /* URI autolink: scheme = [A-Za-z][A-Za-z0-9+.-]{1,31}: */
    scheme_start = q;
    if (q >= n || !isalpha((unsigned char)s[q])) goto try_email;
    q++;
    while (q < n && (isalnum((unsigned char)s[q]) || s[q] == '+' ||
                     s[q] == '.' || s[q] == '-'))
        q++;
    scheme_len = q - scheme_start;
    if (scheme_len < 2 || scheme_len > 32) goto try_email;
    if (q >= n || s[q] != ':') goto try_email;
    /* body: any non-WS, non-< non-> */
    body_start = q + 1;
    r = body_start;
    while (r < n && s[r] != '>' && s[r] != '<' &&
           !is_unicode_ws((unsigned char)s[r]) &&
           (unsigned char)s[r] >= 0x20)
        r++;
    if (r < n && s[r] == '>') {
        x = node_new(z, N_AUTOLINK);
        x->s = s + pos + 1; x->n = r - (pos + 1);
        x->is_email = 0;
        append(z, x);
        return r - pos + 1;
    }
try_email:
    /* email autolink: simple validation */
    q = pos + 1;
    e_start = q;
    while (q < n && (isalnum((unsigned char)s[q]) ||
                     strchr(".!#$%&'*+/=?^_`{|}~-", s[q])))
        q++;
    if (q == e_start || q >= n || s[q] != '@') return 0;
    q++;
    while (q < n && s[q] != '>') {
        char c = s[q];
        if (isalnum((unsigned char)c)) { label_len++; q++; }
        else if (c == '-') { if (!label_len) return 0; label_len++; q++; }
        else if (c == '.') { if (!label_len) return 0; dot_ok = 1; label_len = 0; q++; }
        else return 0;
        if (label_len > 63) return 0;
    }
    (void)dot_ok;
    if (q >= n || s[q] != '>' || label_len == 0) return 0;
    x = node_new(z, N_AUTOLINK);
    x->s = s + pos + 1; x->n = q - (pos + 1);
    x->is_email = 1;
    append(z, x);
    return q - pos + 1;
}

/* ---------------- raw HTML inline (§6.8) ---------------- */

static int html_attr_name_char(char c, int first) {
    if (first) return isalpha((unsigned char)c) || c == '_' || c == ':';
    return isalnum((unsigned char)c) || c == '_' || c == ':' || c == '.' || c == '-';
}

static size_t try_html_inline(scn* z, size_t pos) {
    const char* s = z->s; size_t n = z->n;
    size_t q;
    inode* x;
    int closing;
    if (pos >= n || s[pos] != '<') return 0;
    if (pos + 1 >= n) return 0;
    q = pos + 1;
    /* comment (CommonMark 0.30+):
     *   <!-->  | <!--->  | <!--  ...not containing -->...  --> */
    if (q + 2 < n && s[q] == '!' && s[q+1] == '-' && s[q+2] == '-') {
        size_t r = q + 3;
        /* short forms */
        if (r < n && s[r] == '>') {
            r += 1;
            x = node_new(z, N_HTMLINLINE);
            x->s = s + pos; x->n = r - pos;
            append(z, x);
            return r - pos;
        }
        if (r + 1 < n && s[r] == '-' && s[r+1] == '>') {
            r += 2;
            x = node_new(z, N_HTMLINLINE);
            x->s = s + pos; x->n = r - pos;
            append(z, x);
            return r - pos;
        }
        /* general form: scan for "-->" with no constraint on inner '--'. */
        while (r + 2 < n) {
            if (s[r] == '-' && s[r+1] == '-' && s[r+2] == '>') {
                r += 3;
                x = node_new(z, N_HTMLINLINE);
                x->s = s + pos; x->n = r - pos;
                append(z, x);
                return r - pos;
            }
            r++;
        }
        return 0;
    }
    /* PI */
    if (q < n && s[q] == '?') {
        q++;
        while (q + 1 < n) {
            if (s[q] == '?' && s[q+1] == '>') {
                q += 2;
                x = node_new(z, N_HTMLINLINE);
                x->s = s + pos; x->n = q - pos;
                append(z, x);
                return q - pos;
            }
            q++;
        }
        return 0;
    }
    /* CDATA */
    if (q + 7 < n && memcmp(s + q, "![CDATA[", 8) == 0) {
        q += 8;
        while (q + 2 < n) {
            if (s[q] == ']' && s[q+1] == ']' && s[q+2] == '>') {
                q += 3;
                x = node_new(z, N_HTMLINLINE);
                x->s = s + pos; x->n = q - pos;
                append(z, x);
                return q - pos;
            }
            q++;
        }
        return 0;
    }
    /* declaration <!A...> */
    if (q < n && s[q] == '!' && q + 1 < n && isalpha((unsigned char)s[q+1])) {
        q += 2;
        while (q < n && s[q] != '>') q++;
        if (q >= n) return 0;
        q++;
        x = node_new(z, N_HTMLINLINE);
        x->s = s + pos; x->n = q - pos;
        append(z, x);
        return q - pos;
    }
    /* closing tag */
    closing = 0;
    if (q < n && s[q] == '/') { closing = 1; q++; }
    /* tag name */
    if (q >= n || !isalpha((unsigned char)s[q])) return 0;
    q++;
    while (q < n && (isalnum((unsigned char)s[q]) || s[q] == '-')) q++;
    if (closing) {
        while (q < n && (s[q] == ' ' || s[q] == '\t' || s[q] == '\n')) q++;
        if (q >= n || s[q] != '>') return 0;
        q++;
        x = node_new(z, N_HTMLINLINE);
        x->s = s + pos; x->n = q - pos;
        append(z, x);
        return q - pos;
    }
    /* attributes */
    while (q < n) {
        size_t pre_attr = q;
        int saw_ws = 0;
        size_t save;
        while (q < n && (s[q] == ' ' || s[q] == '\t' || s[q] == '\n')) {
            saw_ws = 1; q++;
        }
        if (q >= n) return 0;
        if (s[q] == '>' || s[q] == '/') break;
        if (!saw_ws) return 0;
        if (!html_attr_name_char(s[q], 1)) { q = pre_attr; break; }
        q++;
        while (q < n && html_attr_name_char(s[q], 0)) q++;
        /* optional value */
        save = q;
        while (q < n && (s[q] == ' ' || s[q] == '\t' || s[q] == '\n')) q++;
        if (q < n && s[q] == '=') {
            q++;
            while (q < n && (s[q] == ' ' || s[q] == '\t' || s[q] == '\n')) q++;
            if (q < n && (s[q] == '"' || s[q] == '\'')) {
                char qc = s[q]; q++;
                while (q < n && s[q] != qc) q++;
                if (q >= n) return 0;
                q++;
            } else {
                /* unquoted */
                size_t vs = q;
                while (q < n && s[q] != ' ' && s[q] != '\t' && s[q] != '\n' &&
                       s[q] != '"' && s[q] != '\'' && s[q] != '=' &&
                       s[q] != '<' && s[q] != '>' && s[q] != '`') q++;
                if (q == vs) return 0;
            }
        } else {
            q = save;
        }
    }
    while (q < n && (s[q] == ' ' || s[q] == '\t' || s[q] == '\n')) q++;
    if (q < n && s[q] == '/') q++;
    if (q >= n || s[q] != '>') return 0;
    q++;
    x = node_new(z, N_HTMLINLINE);
    x->s = s + pos; x->n = q - pos;
    append(z, x);
    return q - pos;
}

/* ---------------- link parsing helpers ---------------- */

/* Parse a CommonMark link destination starting at *p.  On success advances
 * *p past it and sets [out_s, out_e) to the destination bytes (still in the
 * source buffer; the renderer normalises). */
static int parse_link_destination(const char* s, size_t* pp, size_t n,
                                  const char** out_s, size_t* out_n) {
    size_t p = *pp;
    size_t ds;
    int paren;
    if (p >= n) return 0;
    if (s[p] == '<') {
        p++;
        ds = p;
        while (p < n && s[p] != '>' && s[p] != '<' && s[p] != '\n') {
            if (s[p] == '\\' && p + 1 < n) p++;
            p++;
        }
        if (p >= n || s[p] != '>') return 0;
        *out_s = s + ds;
        *out_n = p - ds;
        *pp = p + 1;
        return 1;
    }
    paren = 0;
    ds = p;
    while (p < n) {
        unsigned char c = (unsigned char)s[p];
        if (c < 0x20 || c == 0x7f) break;
        if (c == ' ' || c == '\t' || c == '\n') break;
        if (c == '\\' && p + 1 < n && is_ascii_punct((unsigned char)s[p+1])) { p += 2; continue; }
        if (c == '(') { paren++; p++; continue; }
        if (c == ')') { if (paren == 0) break; paren--; p++; continue; }
        p++;
    }
    if (p == ds || paren != 0) return 0;
    *out_s = s + ds;
    *out_n = p - ds;
    *pp = p;
    return 1;
}

static int parse_link_title(const char* s, size_t* pp, size_t n,
                            const char** out_s, size_t* out_n) {
    size_t p = *pp;
    char open, close;
    size_t ts;
    int prev_blank_line;
    if (p >= n) return 0;
    open = s[p];
    if (open == '"' || open == '\'') close = open;
    else if (open == '(') close = ')';
    else return 0;
    p++;
    ts = p;
    prev_blank_line = 0;
    while (p < n && s[p] != close) {
        if (s[p] == '\\' && p + 1 < n && is_ascii_punct((unsigned char)s[p+1])) { p += 2; continue; }
        if (open == '(' && s[p] == '(') return 0;
        if (s[p] == '\n') {
            /* check for blank line */
            size_t r = p + 1;
            while (r < n && (s[r] == ' ' || s[r] == '\t')) r++;
            if (r >= n || s[r] == '\n') { prev_blank_line = 1; break; }
        }
        p++;
    }
    if (prev_blank_line || p >= n || s[p] != close) return 0;
    *out_s = s + ts;
    *out_n = p - ts;
    *pp = p + 1;
    return 1;
}

/* ---------------- find matching open bracket ---------------- */

static inode* find_open_bracket(scn* z, int* is_image) {
    inode* x;
    *is_image = 0;
    for (x = z->tail; x; x = x->prev) {
        if (x->type == N_OPEN_BRACKET || x->type == N_OPEN_BANG) {
            *is_image = (x->type == N_OPEN_BANG);
            return x;  /* return topmost — caller checks ->active */
        }
    }
    return NULL;
}

/* Disable any '[' opener nodes appearing before x (for nested-link rule). */
static void deactivate_brackets(scn* z, inode* x) {
    inode* p;
    for (p = x->prev; p; p = p->prev) {
        if (p->type == N_OPEN_BRACKET) p->active = 0;
    }
    (void)z;
}

/* Move nodes (open_bracket->next .. end) into a new container of type t,
 * which replaces the open_bracket and everything after.  Returns the
 * container. */
static inode* wrap_after(scn* z, inode* open, ntype t) {
    inode* c = node_new(z, t);
    c->children = open->next;
    c->children_tail = z->tail;
    if (c->children) c->children->prev = NULL;
    /* sever tail link */
    z->tail = open->prev;
    if (z->tail) z->tail->next = NULL;
    else         z->head = NULL;
    /* remove the open bracket itself */
    /* (it's now floating; we won't re-link it) */
    append(z, c);
    return c;
}

/* ---------------- process_emphasis (§6.4) ---------------- */

/* The CommonMark algorithm operates on the delimiter stack.  We use the
 * doubly-linked node list directly; DELIM nodes ARE the stack entries.
 *
 * stack_bottom: only consider delimiters strictly after this node.
 *               NULL = whole list (or list head).
 */
static void process_emphasis(scn* z, inode* stack_bottom) {
    /* openers_bottom[delim_idx][closer_count_mod3][can_open(0|1)] */
    inode* openers_bottom[3][3][2];
    inode* closer;
    int a, b, c;
    int use2;
    ntype tt;
    unsigned _ifl;
    inode* container;
    inode* first;
    inode* last;
    inode* before;
    inode* after;
    inode* new_open;
    inode* new_close;
    inode* prev_link;
    inode* start;
    inode* p;
    for (a = 0; a < 3; a++)
        for (b = 0; b < 3; b++)
            for (c = 0; c < 2; c++)
                openers_bottom[a][b][c] = stack_bottom;

    closer = stack_bottom ? stack_bottom->next : z->head;
    /* find first potential closer */
    while (closer) {
        if (closer->type == N_DELIM && closer->can_close &&
            (closer->delim_char == '*' || closer->delim_char == '_' ||
             closer->delim_char == '~'))
            break;
        closer = closer->next;
    }
    while (closer) {
        unsigned char ch = closer->delim_char;
        int didx = (ch == '*') ? 0 : (ch == '_') ? 1 : 2;
        int co_mod = closer->count % 3;
        int co_op  = closer->can_open ? 1 : 0;
        inode* bot = openers_bottom[didx][co_mod][co_op];

        /* walk back for matching opener */
        inode* opener = closer->prev;
        int found = 0;
        while (opener && opener != bot && opener != stack_bottom) {
            if (opener->type == N_DELIM && opener->can_open &&
                opener->delim_char == ch) {
                /* rule of three */
                int odd_match = (closer->can_open || opener->can_close) &&
                                ((opener->count + closer->count) % 3 == 0) &&
                                !(opener->count % 3 == 0 && closer->count % 3 == 0);
                if (!odd_match) { found = 1; break; }
            }
            opener = opener->prev;
        }
        if (!found) {
            openers_bottom[didx][co_mod][co_op] = closer->prev;
            /* If the closer itself can't also open, mark it inert so it
             * becomes literal text in the final sweep. Either way, advance. */
            if (!closer->can_open) closer->can_close = 0;
            closer = closer->next;
            while (closer) {
                if (closer->type == N_DELIM && closer->can_close &&
                    (closer->delim_char == '*' || closer->delim_char == '_' ||
                     closer->delim_char == '~'))
                    break;
                closer = closer->next;
            }
            continue;
        }

        use2 = (ch == '~')
            ? opener->count   /* matched count for tildes */
            : ((opener->count >= 2 && closer->count >= 2) ? 2 : 1);

        /* GFM strike: counts must match and be 1 or 2 (no triple+). */
        if (ch == '~' && (opener->count != closer->count ||
                          (opener->count != 1 && opener->count != 2))) {
            /* skip — leave as text */
            openers_bottom[didx][co_mod][co_op] = opener;
            closer = closer->next;
            while (closer) {
                if (closer->type == N_DELIM && closer->can_close &&
                    (closer->delim_char == '*' || closer->delim_char == '_' ||
                     closer->delim_char == '~'))
                    break;
                closer = closer->next;
            }
            continue;
        }

        tt = (ch == '~') ? N_STRIKE : (use2 == 2 ? N_STRONG : N_EMPH);
        _ifl = z->ctx->flags;
        if ((tt == N_EMPH   && (_ifl & MDS_FLAG_NO_EMPH)) ||
            (tt == N_STRONG && (_ifl & MDS_FLAG_NO_STRONG))) {
            /* Skip: leave delim run as-is, advance closer (becomes text) */
            openers_bottom[didx][co_mod][co_op] = opener;
            if (!closer->can_open) closer->can_close = 0;
            closer = closer->next;
            while (closer) {
                if (closer->type == N_DELIM && closer->can_close &&
                    (closer->delim_char == '*' || closer->delim_char == '_' ||
                     closer->delim_char == '~'))
                    break;
                closer = closer->next;
            }
            continue;
        }
        container = node_new(z, tt);
        /* children = (opener->next .. closer->prev) */
        first = opener->next;
        last  = closer->prev;
        if (first != closer) {
            container->children = first;
            container->children_tail = last;
            first->prev = NULL;
            last->next  = NULL;
        }
        /* shrink/remove delimiters */
        opener->count -= use2;
        closer->count -= use2;

        /* relink: replace [opener? closer?] block with container */
        before = opener->prev;
        after  = closer->next;

        new_open  = (opener->count > 0) ? opener : NULL;
        new_close = (closer->count > 0) ? closer : NULL;

        /* shrink opener s/n bytes for proper future text emission? Not
         * needed — opener bytes are never emitted directly; only the count
         * matters when shrunken to >0 and treated as remaining delim. */
        if (new_open) {
            /* truncate opener's literal length so leftover delim chars
             * remain rendered if not consumed later */
            new_open->n = (size_t)new_open->count;
        }
        if (new_close) {
            new_close->n = (size_t)new_close->count;
            new_close->s = new_close->s; /* keep pointer, length adjusted */
        }

        /* build list: before, new_open?, container, new_close?, after */
        prev_link = before;
        if (new_open) {
            if (prev_link) prev_link->next = new_open;
            else           z->head = new_open;
            new_open->prev = prev_link;
            prev_link = new_open;
        }
        if (prev_link) prev_link->next = container;
        else           z->head = container;
        container->prev = prev_link;
        prev_link = container;
        if (new_close) {
            prev_link->next = new_close;
            new_close->prev = prev_link;
            prev_link = new_close;
        }
        prev_link->next = after;
        if (after) after->prev = prev_link;
        else       z->tail = prev_link;

        /* continue: if closer still has count, use it as closer again;
         * otherwise resume from after */
        if (new_close) {
            closer = new_close;
        } else {
            closer = after;
            while (closer) {
                if (closer->type == N_DELIM && closer->can_close &&
                    (closer->delim_char == '*' || closer->delim_char == '_' ||
                     closer->delim_char == '~'))
                    break;
                closer = closer->next;
            }
        }
    }
    /* clear remaining DELIMs to TEXT */
    start = stack_bottom ? stack_bottom->next : z->head;
    for (p = start; p; p = p->next) {
        if (p->type == N_DELIM) {
            p->type = N_TEXT;
        }
    }
}

/* ---------------- process ']' ---------------- */

static int try_close_bracket(scn* z, size_t* pos_io) {
    const char* s = z->s; size_t n = z->n;
    size_t pos = *pos_io;
    int is_image = 0;
    inode* opener;
    size_t p;
    int matched = 0;
    const char *href_s = NULL, *title_s = NULL;
    size_t hlen = 0, tlen = 0;
    int is_ref = 0;
    const mds_linkref* refent = NULL;
    ntype t;
    inode* container;
    opener = find_open_bracket(z, &is_image);
    if (!opener) {
        return 0; /* no opener — caller emits literal ']' */
    }
    /* CommonMark "look for link or image" step 3: if the opener exists
     * but is inactive, remove it from the stack (convert to literal `[`)
     * and treat this `]` as literal text. Do NOT keep searching for an
     * earlier active opener — the inactive opener blocks it. This is
     * what makes the alt text of an image with a nested link come out
     * as `[foo](uri2)` literally (CM example 520). */
    if (!opener->active) {
        opener->type = N_TEXT;
        opener->active = 0;
        return 0;
    }
    p = pos + 1;

    /* GFM footnote reference [^label] — checked first so it wins over
     * inline link/ref interpretations. Requires the bracket content to
     * begin with `^` and the label (everything after) to be present in
     * ctx->footnotes. Unresolved [^label] falls through to normal
     * processing (becomes literal text). */
    if ((z->ctx->flags & MDS_FLAG_FOOTNOTES) && z->ctx->footnotes) {
        size_t txt_s0 = (size_t)((opener->s + opener->n) - s);
        size_t txt_e0 = pos;
        if (txt_e0 > txt_s0 && s[txt_s0] == '^') {
            const char* lab_s = s + txt_s0 + 1;
            size_t      lab_n = txt_e0 - txt_s0 - 1;
            const mds_footnote* fn = mds_footnote_get(z->ctx->footnotes,
                                                       lab_s, lab_n);
            if (fn) {
                /* Discard any children between opener and the `]` (the
                 * `^label` text/delim nodes); we don't render them. */
                opener->children = NULL;
                opener->children_tail = NULL;
                /* Drop everything after opener up to but not including pos. */
                opener->next = NULL;
                z->tail = opener;
                if (opener->type == N_OPEN_BANG) {
                    inode* fnref;
                    /* Salvage the literal `!` byte that the bang opener
                     * absorbed — emit it as a sibling TEXT node BEFORE
                     * the footnote ref. Without this, inputs like
                     * `text![^1]` lose the `!`. */
                    opener->type = N_TEXT;
                    opener->n    = 1;       /* s already points at '!' */
                    fnref = node_new(z, N_FOOTNOTE_REF);
                    fnref->href   = fn->label;
                    fnref->hlen   = fn->llen;
                    fnref->active = 0;
                    append(z, fnref);       /* updates z->tail */
                } else {
                    /* Convert opener into the FOOTNOTE_REF node itself. */
                    opener->type = N_FOOTNOTE_REF;
                    opener->href = fn->label;
                    opener->hlen = fn->llen;
                    opener->active = 0;
                }
                *pos_io = pos + 1;
                return 1;
            }
        }
    }

    /* (a) inline link [text](url "title") */
    if (p < n && s[p] == '(') {
        size_t q = p + 1;
        while (q < n && (s[q] == ' ' || s[q] == '\t' || s[q] == '\n')) q++;
        if (q < n && s[q] != ')') {
            if (parse_link_destination(s, &q, n, &href_s, &hlen)) {
                size_t after_dest = q;
                while (q < n && (s[q] == ' ' || s[q] == '\t' || s[q] == '\n')) q++;
                if (q < n && (s[q] == '"' || s[q] == '\'' || s[q] == '(')) {
                    if (!parse_link_title(s, &q, n, &title_s, &tlen)) {
                        q = after_dest;
                        title_s = NULL; tlen = 0;
                    } else {
                        while (q < n && (s[q] == ' ' || s[q] == '\t' || s[q] == '\n')) q++;
                    }
                }
                if (q < n && s[q] == ')') {
                    p = q + 1;
                    matched = 1;
                }
            }
        } else if (q < n && s[q] == ')') {
            /* empty destination */
            href_s = s; hlen = 0;
            p = q + 1;
            matched = 1;
        }
    }

    /* (b) ref link forms */
    if (!matched && z->ctx->refs) {
        /* label text bytes are between opener and current ] */
        size_t lbl_start_off = (size_t)(opener->s - s) + opener->n; /* after [ */
        /* Actually opener->s points at '[' itself; opener->n == 1 (or 2 for ![) */
        /* simpler: text content range is open_text..pos */
        size_t txt_s = (size_t)((opener->s + opener->n) - s);
        size_t txt_e = pos;
        int tried_full = 0;
        (void)lbl_start_off;

        /* full ref: [text][label] */
        if (p < n && s[p] == '[') {
            size_t q = p + 1;
            size_t lbl_s = q;
            while (q < n && s[q] != ']' && s[q] != '[' && q - lbl_s < 1000) {
                if (s[q] == '\\' && q + 1 < n) q++;
                q++;
            }
            if (q < n && s[q] == ']' && q > lbl_s) {
                tried_full = 1;
                refent = mds_linkref_get(z->ctx->refs, s + lbl_s, q - lbl_s);
                if (refent) { p = q + 1; is_ref = 1; matched = 1; }
            } else if (q < n && s[q] == ']' && q == lbl_s) {
                /* collapsed [text][] */
                refent = mds_linkref_get(z->ctx->refs, s + txt_s, txt_e - txt_s);
                if (refent) { p = q + 1; is_ref = 1; matched = 1; }
            }
        }
        if (!matched && !tried_full) {
            /* shortcut [text] — only when there is no [label] following */
            refent = mds_linkref_get(z->ctx->refs, s + txt_s, txt_e - txt_s);
            if (refent) { is_ref = 1; matched = 1; }
        }
        if (matched && refent) {
            href_s = refent->url; hlen = refent->ulen;
            title_s = refent->title; tlen = refent->tlen;
        }
    }

    if (!matched) {
        /* no link: drop opener from stack — convert to plain TEXT so it
         * doesn't block outer brackets from matching this ']'. (CM spec
         * "look for link or image" step: remove opener on failure.) */
        opener->type = N_TEXT;
        opener->active = 0;
        return 0;
    }

    /* run process_emphasis on the children range (opener->next .. tail) */
    process_emphasis(z, opener);

    /* wrap into LINK or IMAGE container */
    t = is_image ? N_IMAGE : N_LINK;
    container = wrap_after(z, opener, t);
    container->href = href_s; container->hlen = hlen;
    container->title = title_s; container->tlen = tlen;

    /* unlink opener from list (it became the boundary; wrap_after kept it
     * outside the new container — we need to remove it now). */
    if (opener->prev) opener->prev->next = container;
    else              z->head = container;
    container->prev = opener->prev;

    /* deactivate any earlier '[' if this is a link (not image) */
    if (!is_image) deactivate_brackets(z, container);

    *pos_io = p;
    (void)is_ref;
    return 1;
}

/* ---------------- forward pass ---------------- */

/* SWAR / NEON fast-skip over runs of plain prose. The inline
 * scanner's outer switch fires on exactly these 11 bytes:
 *   '\\'  '`'  '<'  '&'  '*'  '_'  '~'  '['  '!'  ']'  '\n'
 * Everything else falls through to `default: pos++;`. We replace that
 * single-byte advance with a 16-byte (NEON) or 8-byte (SWAR) scan that
 * returns the offset to the next interesting byte (or the chunk size if
 * none). On prose corpora ~99% of bytes match the fast path. */

static const unsigned char mds_inline_interest[256] = {
    ['\\']=1, ['`']=1, ['<']=1, ['&']=1, ['*']=1, ['_']=1,
    ['~']=1,  ['[']=1, ['!']=1, [']']=1, ['\n']=1,
};

#if MDS_INLINE_HAVE_NEON
static inline size_t mds_inline_skip16(const char* p) {
    /* Returns 0..16: bytes safe to skip before the first interesting one. */
    uint8x16_t v = vld1q_u8((const uint8_t*)p);
    uint8x16_t bs   = vceqq_u8(v, vdupq_n_u8('\\'));
    uint8x16_t bt   = vceqq_u8(v, vdupq_n_u8('`'));
    uint8x16_t lt   = vceqq_u8(v, vdupq_n_u8('<'));
    uint8x16_t amp  = vceqq_u8(v, vdupq_n_u8('&'));
    uint8x16_t st   = vceqq_u8(v, vdupq_n_u8('*'));
    uint8x16_t us   = vceqq_u8(v, vdupq_n_u8('_'));
    uint8x16_t ti   = vceqq_u8(v, vdupq_n_u8('~'));
    uint8x16_t lb   = vceqq_u8(v, vdupq_n_u8('['));
    uint8x16_t bg   = vceqq_u8(v, vdupq_n_u8('!'));
    uint8x16_t rb   = vceqq_u8(v, vdupq_n_u8(']'));
    uint8x16_t nl   = vceqq_u8(v, vdupq_n_u8('\n'));
    uint8x16_t any  = vorrq_u8(vorrq_u8(vorrq_u8(bs, bt), vorrq_u8(lt, amp)),
                               vorrq_u8(vorrq_u8(vorrq_u8(st, us), vorrq_u8(ti, lb)),
                                        vorrq_u8(vorrq_u8(bg, rb), nl)));
    uint8x8_t lo, hi;
    uint8x8_t packed_lo;
    uint64_t  m;
    if (vmaxvq_u8(any) == 0) return 16;
    /* Reduce to 64-bit then ctz to find first match. */
    lo = vget_low_u8(any);
    hi = vget_high_u8(any);
    /* Pack each byte's high bit into a 16-bit mask via shrn trick. */
    packed_lo = vshrn_n_u16(vreinterpretq_u16_u8(any), 4);
    m = vget_lane_u64(vreinterpret_u64_u8(packed_lo), 0);
    (void)lo; (void)hi;
    return (size_t)(__builtin_ctzll(m) >> 2);
}
#endif

static inline size_t mds_inline_skip8(const char* p) {
    /* Portable SWAR fallback: 8-byte stride. */
    uint64_t w;
    uint64_t m;
    memcpy(&w, p, 8);
    #define MDS_HASZ(x) (((x) - 0x0101010101010101ULL) & ~(x) & 0x8080808080808080ULL)
    #define MDS_BC(b)   ((uint64_t)(b) * 0x0101010101010101ULL)
    m = MDS_HASZ(w ^ MDS_BC('\\'))
      | MDS_HASZ(w ^ MDS_BC('`'))
      | MDS_HASZ(w ^ MDS_BC('<'))
      | MDS_HASZ(w ^ MDS_BC('&'))
      | MDS_HASZ(w ^ MDS_BC('*'))
      | MDS_HASZ(w ^ MDS_BC('_'))
      | MDS_HASZ(w ^ MDS_BC('~'))
      | MDS_HASZ(w ^ MDS_BC('['))
      | MDS_HASZ(w ^ MDS_BC('!'))
      | MDS_HASZ(w ^ MDS_BC(']'))
      | MDS_HASZ(w ^ MDS_BC('\n'));
    #undef MDS_HASZ
    #undef MDS_BC
    if (!m) return 8;
    /* m has high bit set in each matching lane (little-endian byte order). */
    return (size_t)(__builtin_ctzll(m) >> 3);
}

static void scan_forward(scn* z) {
    const char* s = z->s;
    size_t n = z->n;
    size_t pos = 0;
    size_t text_start = 0;

    #define FLUSH_TEXT() do { \
        if (pos > text_start) append_text(z, s + text_start, pos - text_start); \
        text_start = pos; \
    } while (0)

    while (pos < n) {
        unsigned char c = (unsigned char)s[pos];
        switch (c) {
        case '\\': {
            inode* x;
            if (pos + 1 < n && s[pos+1] == '\n') {
                /* hard break */
                FLUSH_TEXT();
                x = node_new(z, N_LINEBREAK);
                append(z, x);
                pos += 2;
                /* skip leading spaces on next line */
                while (pos < n && (s[pos] == ' ' || s[pos] == '\t')) pos++;
                text_start = pos;
                continue;
            }
            if (pos + 1 < n && is_ascii_punct((unsigned char)s[pos+1])) {
                FLUSH_TEXT();
                append_text_dup(z, s + pos + 1, 1);
                pos += 2;
                text_start = pos;
                continue;
            }
            pos++;
            (void)x;
            continue;
        }
        case '`': {
            size_t end;
            if (z->ctx->flags & MDS_FLAG_NO_CODE) {
                /* emit literal backtick(s) as text */
                size_t r = pos;
                while (r < n && s[r] == '`') r++;
                FLUSH_TEXT();
                append_text(z, s + pos, r - pos);
                pos = r; text_start = pos; continue;
            }
            end = try_code_span(z, pos);
            if (end) {
                /* flush bytes before pos */
                if (pos > text_start) {
                    /* append_text already; but z->tail is the new CODE node.
                     * We need to insert text BEFORE it. Re-do manually. */
                }
                /* Actually: try_code_span already appended a CODE node,
                 * so the prior bytes weren't flushed. Need to flush first. */
                /* To keep things simple, flush BEFORE attempting span. */
                /* Implementation note: re-do as flush-then-attempt below. */
                (void)end;
            }
            /* re-attempt with flush */
            {
                size_t saved_pos = pos;
                size_t end2;
                size_t r;
                /* remove the CODE node just appended (we did it above) */
                if (end && z->tail && z->tail->type == N_CODE) {
                    inode* dead = z->tail;
                    z->tail = dead->prev;
                    if (z->tail) z->tail->next = NULL;
                    else         z->head = NULL;
                }
                /* flush text */
                if (saved_pos > text_start)
                    append_text(z, s + text_start, saved_pos - text_start);
                text_start = saved_pos;
                /* re-attempt cleanly */
                end2 = try_code_span(z, saved_pos);
                if (end2) {
                    pos = end2; text_start = pos; continue;
                }
                /* failed: emit literal backticks */
                r = pos;
                while (r < n && s[r] == '`') r++;
                append_text(z, s + pos, r - pos);
                pos = r; text_start = pos; continue;
            }
        }
        case '<': {
            size_t end;
            FLUSH_TEXT();
            end = try_autolink(z, pos);
            if (end) { pos += end; text_start = pos; continue; }
            if (!(z->ctx->flags & MDS_FLAG_NO_HTML)) {
                end = try_html_inline(z, pos);
                if (end) { pos += end; text_start = pos; continue; }
            }
            append_text(z, s + pos, 1);
            pos++; text_start = pos;
            continue;
        }
        case '&': {
            size_t consumed = try_entity(z, pos);
            if (consumed) {
                /* flush prior text first */
                size_t before = pos;
                /* try_entity already appended the entity TEXT; we need to
                 * insert prior bytes before it. */
                if (z->tail && before > text_start) {
                    inode* added = z->tail;
                    /* detach */
                    z->tail = added->prev;
                    if (z->tail) z->tail->next = NULL;
                    else         z->head = NULL;
                    append_text(z, s + text_start, before - text_start);
                    /* re-append */
                    added->prev = z->tail;
                    added->next = NULL;
                    if (z->tail) z->tail->next = added;
                    else         z->head = added;
                    z->tail = added;
                }
                pos += consumed; text_start = pos;
                continue;
            }
            pos++; continue;
        }
        case '*':
        case '_':
        case '~': {
            size_t start;
            size_t runlen;
            int co, cc;
            inode* x;
            FLUSH_TEXT();
            start = pos;
            while (pos < n && (unsigned char)s[pos] == c) pos++;
            runlen = pos - start;
            if (c == '~' && ((runlen != 1 && runlen != 2) || !(z->ctx->flags & MDS_FLAG_STRIKE))) {
                /* not strike candidate (or strikethrough disabled); emit as text */
                append_text(z, s + start, runlen);
                text_start = pos;
                continue;
            }
            classify_run(s, n, start, runlen, &co, &cc, c);
            x = node_new(z, N_DELIM);
            x->delim_char = c;
            x->count = (int)runlen;
            x->can_open  = co;
            x->can_close = cc;
            x->s = s + start; x->n = runlen;
            append(z, x);
            text_start = pos;
            continue;
        }
        case '[': {
            inode* x;
            if (z->ctx->flags & MDS_FLAG_NO_LINKS) {
                FLUSH_TEXT();
                append_text(z, s + pos, 1);
                pos++; text_start = pos; continue;
            }
            FLUSH_TEXT();
            x = node_new(z, N_OPEN_BRACKET);
            x->s = s + pos; x->n = 1;
            x->active = 1;
            append(z, x);
            pos++; text_start = pos;
            continue;
        }
        case '!': {
            if (pos + 1 < n && s[pos+1] == '[' &&
                !(z->ctx->flags & MDS_FLAG_NO_IMAGES)) {
                inode* x;
                FLUSH_TEXT();
                x = node_new(z, N_OPEN_BANG);
                x->s = s + pos; x->n = 2;
                x->active = 1;
                append(z, x);
                pos += 2; text_start = pos;
                continue;
            }
            pos++; continue;
        }
        case ']': {
            size_t p2;
            FLUSH_TEXT();
            p2 = pos;
            if (try_close_bracket(z, &p2)) {
                pos = p2; text_start = pos;
                continue;
            }
            /* literal ] */
            append_text(z, s + pos, 1);
            pos++; text_start = pos;
            continue;
        }
        case '\n': {
            int hard;
            inode* br;
            FLUSH_TEXT();
            /* hard break iff prev TEXT ended with two-or-more spaces */
            hard = 0;
            if (z->tail && z->tail->type == N_TEXT) {
                inode* t = z->tail;
                if (t->n >= 2 && t->s[t->n - 1] == ' ' && t->s[t->n - 2] == ' ') {
                    /* trim trailing spaces */
                    while (t->n > 0 && t->s[t->n - 1] == ' ') t->n--;
                    if (t->n == 0) {
                        /* remove empty text */
                        z->tail = t->prev;
                        if (z->tail) z->tail->next = NULL;
                        else         z->head = NULL;
                    }
                    hard = 1;
                } else if (t->n >= 1 && t->s[t->n - 1] == ' ') {
                    /* single space trailing — strip */
                    t->n--;
                    if (t->n == 0) {
                        z->tail = t->prev;
                        if (z->tail) z->tail->next = NULL;
                        else         z->head = NULL;
                    }
                }
            }
            br = node_new(z, hard ? N_LINEBREAK : N_SOFTBREAK);
            append(z, br);
            pos++;
            /* skip leading spaces on next line */
            while (pos < n && (s[pos] == ' ' || s[pos] == '\t')) pos++;
            text_start = pos;
            continue;
        }
        default:
        {
            /* Fast skip over plain prose. The chunked stride keeps the
             * text run intact (no FLUSH_TEXT needed) — we just advance
             * `pos` past bytes the outer switch would have ignored. */
#if MDS_INLINE_HAVE_NEON
            while (pos + 16 <= n) {
                size_t k = mds_inline_skip16(s + pos);
                pos += k;
                if (k < 16) goto next_iter;
            }
#endif
            while (pos + 8 <= n) {
                size_t k = mds_inline_skip8(s + pos);
                pos += k;
                if (k < 8) goto next_iter;
            }
            /* Tail: 1-byte at a time. The interest table makes the
             * predicate branch-free. */
            while (pos < n && !mds_inline_interest[(unsigned char)s[pos]])
                pos++;
        next_iter:
            continue;
        }
        }
    }
    FLUSH_TEXT();
    #undef FLUSH_TEXT
}

/* ---------------- emit pass ---------------- */

static void emit_children(scn* z, inode* head);

/* HTML-escape NOT done here; renderer cb_text does the escaping. */
static void emit_text(scn* z, const char* s, size_t n) {
    if (n == 0) return;
    if (z->ctx->cb.text) z->ctx->cb.text(z->ctx->ud, s, n);
}
static void emit_raw(scn* z, const char* s, size_t n) {
    if (n == 0) return;
    if (z->ctx->cb.raw) z->ctx->cb.raw(z->ctx->ud, s, n);
}

static void emit_node(scn* z, inode* x) {
    mds_callbacks* cb = &z->ctx->cb;
    mds_inline_detail d;
    memset(&d, 0, sizeof d);
    switch (x->type) {
    case N_TEXT:
        emit_text(z, x->s, x->n);
        break;
    case N_SOFTBREAK:
        if (cb->enter_inline) cb->enter_inline(z->ctx->ud, MDS_INL_SOFTBREAK, &d);
        if (cb->leave_inline) cb->leave_inline(z->ctx->ud, MDS_INL_SOFTBREAK);
        break;
    case N_LINEBREAK:
        if (cb->enter_inline) cb->enter_inline(z->ctx->ud, MDS_INL_LINEBREAK, &d);
        if (cb->leave_inline) cb->leave_inline(z->ctx->ud, MDS_INL_LINEBREAK);
        break;
    case N_CODE:
        if (cb->enter_inline) cb->enter_inline(z->ctx->ud, MDS_INL_CODE, &d);
        emit_text(z, x->s, x->n);
        if (cb->leave_inline) cb->leave_inline(z->ctx->ud, MDS_INL_CODE);
        break;
    case N_AUTOLINK:
        d.u.autolink.uri = x->s;
        d.u.autolink.uri_len = x->n;
        d.u.autolink.is_email = x->is_email;
        if (cb->enter_inline) cb->enter_inline(z->ctx->ud, MDS_INL_AUTOLINK, &d);
        if (cb->leave_inline) cb->leave_inline(z->ctx->ud, MDS_INL_AUTOLINK);
        break;
    case N_HTMLINLINE:
        if (cb->enter_inline) cb->enter_inline(z->ctx->ud, MDS_INL_HTML_INLINE, &d);
        emit_raw(z, x->s, x->n);
        if (cb->leave_inline) cb->leave_inline(z->ctx->ud, MDS_INL_HTML_INLINE);
        break;
    case N_EMPH:
        if (cb->enter_inline) cb->enter_inline(z->ctx->ud, MDS_INL_EMPH, &d);
        emit_children(z, x->children);
        if (cb->leave_inline) cb->leave_inline(z->ctx->ud, MDS_INL_EMPH);
        break;
    case N_STRONG:
        if (cb->enter_inline) cb->enter_inline(z->ctx->ud, MDS_INL_STRONG, &d);
        emit_children(z, x->children);
        if (cb->leave_inline) cb->leave_inline(z->ctx->ud, MDS_INL_STRONG);
        break;
    case N_STRIKE:
        if (cb->enter_inline) cb->enter_inline(z->ctx->ud, MDS_INL_STRIKE, &d);
        emit_children(z, x->children);
        if (cb->leave_inline) cb->leave_inline(z->ctx->ud, MDS_INL_STRIKE);
        break;
    case N_LINK:
        d.u.link.href = x->href; d.u.link.href_len = x->hlen;
        d.u.link.title = x->title; d.u.link.title_len = x->tlen;
        if (cb->enter_inline) cb->enter_inline(z->ctx->ud, MDS_INL_LINK, &d);
        emit_children(z, x->children);
        if (cb->leave_inline) cb->leave_inline(z->ctx->ud, MDS_INL_LINK);
        break;
    case N_IMAGE:
        d.u.image.href = x->href; d.u.image.href_len = x->hlen;
        d.u.image.title = x->title; d.u.image.title_len = x->tlen;
        d.u.image.alt = NULL; d.u.image.alt_len = 0; /* renderer derives alt from children */
        if (cb->enter_inline) cb->enter_inline(z->ctx->ud, MDS_INL_IMAGE, &d);
        emit_children(z, x->children);
        if (cb->leave_inline) cb->leave_inline(z->ctx->ud, MDS_INL_IMAGE);
        break;
    case N_FOOTNOTE_REF:
        /* opener->href / hlen carry the raw label captured at match
         * time; we stuffed them there because inode has no dedicated
         * label slot. The renderer manages numbering. */
        d.u.footnote_ref.label     = x->href;
        d.u.footnote_ref.label_len = x->hlen;
        if (cb->enter_inline) cb->enter_inline(z->ctx->ud, MDS_INL_FOOTNOTE_REF, &d);
        if (cb->leave_inline) cb->leave_inline(z->ctx->ud, MDS_INL_FOOTNOTE_REF);
        break;
    case N_DELIM:
    case N_OPEN_BRACKET:
    case N_OPEN_BANG:
        /* leftover unmatched delimiter/bracket — emit as literal text */
        emit_text(z, x->s, x->n);
        break;
    }
}

static void emit_children(scn* z, inode* head) {
    inode* p;
    for (p = head; p; p = p->next) emit_node(z, p);
}

/* ---------------- public entry ---------------- */

MDS_HOT void mds_inline_scan(mds_ctx* ctx, const char* s, size_t n) {
    scn z;
    if (n == 0) return;

    /* Fast path for table cells and trivial paragraphs: if no byte in
     * the run can possibly trigger an inline construct, we can skip
     * the entire inode-list build / process_emphasis / emit_children
     * pipeline and just call cb.text directly. Inline triggers are:
     *   `* _ ~ ` [ ] ! < & \\` plus the line-break candidates `\n` and
     * the trailing-spaces hard-break case. The classifier dispatch
     * table (src/simd/mds_dispatch.h) is the authoritative list; we
     * use a small per-call SWAR-style scalar scan rather than the SIMD
     * classifier so this stays cheap for short cell-sized runs.
     *
     * Tables hit this constantly (cells are typically a single word),
     * and ordinary prose paragraphs hit it for runs between inline
     * markers. The slow path is bit-identical to the original code. */
    {
        const unsigned char* p   = (const unsigned char*)s;
        const unsigned char* end = p + n;
        for (; p < end; p++) {
            unsigned char c = *p;
            /* Bucket the trigger set with a small bitmap-style check.
             * The compiler turns this into a branchless OR-chain. */
            if (c == '*' || c == '_' || c == '~' || c == '`'  ||
                c == '['  || c == ']' || c == '!' || c == '<'  ||
                c == '&'  || c == '\\' || c == '\n') break;
        }
        if (MDS_LIKELY(p == end)) {
            /* Also bail out on trailing spaces, which CommonMark would
             * otherwise turn into a hard-break candidate. Table cells
             * never have them (the splitter trims) and most paragraph
             * runs don't either. */
            if (n < 2 || !(s[n-1] == ' ' && s[n-2] == ' ')) {
                if (ctx->cb.text) ctx->cb.text(ctx->ud, s, n);
                return;
            }
        }
    }

    byteclass_init();
    memset(&z, 0, sizeof z);
    z.ctx = ctx;
    z.s   = s;
    z.n   = n;

    scan_forward(&z);
    process_emphasis(&z, NULL);
    emit_children(&z, z.head);
}

