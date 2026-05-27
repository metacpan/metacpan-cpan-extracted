/* mds_linkref.c — link reference definition table.
 *
 * Simple linear-scan table backed by arena memory. CommonMark §4.7
 * specifies first-definition-wins; we honour that via mds_linkref_add()
 * returning 0 for duplicates.
 *
 * Label normalisation (per spec): trim, lowercase ASCII, collapse runs
 * of whitespace to a single space. Unicode case-folding deferred.
 */

#include "mds_linkref.h"
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

/* Decode a single UTF-8 codepoint starting at s[i] (i < n). Returns the
 * codepoint, sets *adv to the byte count consumed. On invalid bytes,
 * returns the byte as a codepoint and adv=1 (lenient). */
static unsigned cf_decode(const char* s, size_t n, size_t i, int* adv) {
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

/* Encode codepoint as UTF-8 into out; returns bytes written (0..4). */
static int cf_encode(unsigned cp, char* out) {
    if (cp < 0x80) { out[0] = (char)cp; return 1; }
    if (cp < 0x800) {
        out[0] = (char)(0xC0 | (cp >> 6));
        out[1] = (char)(0x80 | (cp & 0x3F));
        return 2;
    }
    if (cp < 0x10000) {
        out[0] = (char)(0xE0 | (cp >> 12));
        out[1] = (char)(0x80 | ((cp >> 6) & 0x3F));
        out[2] = (char)(0x80 | (cp & 0x3F));
        return 3;
    }
    out[0] = (char)(0xF0 | (cp >> 18));
    out[1] = (char)(0x80 | ((cp >> 12) & 0x3F));
    out[2] = (char)(0x80 | ((cp >> 6) & 0x3F));
    out[3] = (char)(0x80 | (cp & 0x3F));
    return 4;
}

/* Case-fold a single codepoint to its lowercase form, writing 1..4
 * bytes to out. Covers ASCII, Latin-1 supplement, Latin Extended-A
 * (selected), Greek, Cyrillic, plus a tiny exception list (ẞ → ss,
 * µ → μ). Returns bytes written. This is the subset needed by
 * CommonMark spec examples; full CaseFolding.txt is overkill. */
static int cf_fold(unsigned cp, char* out) {
    /* Exceptions that expand (1 codepoint -> 2 codepoints). */
    if (cp == 0x1E9E) { out[0] = 's'; out[1] = 's'; return 2; } /* ẞ */

    /* Single-codepoint mappings. */
    if (cp >= 'A' && cp <= 'Z') cp = cp + 0x20;
    else if (cp == 0xB5) cp = 0x3BC;                        /* µ -> μ */
    else if (cp >= 0xC0 && cp <= 0xDE && cp != 0xD7) cp += 0x20;
    else if (cp >= 0x391 && cp <= 0x3A1) cp += 0x20;       /* Α..Ρ */
    else if (cp >= 0x3A3 && cp <= 0x3AB) cp += 0x20;       /* Σ..Ϋ */
    else if (cp == 0x3A2) { /* reserved, leave */ }
    else if (cp >= 0x400 && cp <= 0x40F) cp += 0x50;       /* Cyrillic Ѐ..Џ */
    else if (cp >= 0x410 && cp <= 0x42F) cp += 0x20;       /* Cyrillic А..Я */
    /* Else: leave codepoint as-is (no fold). */

    return cf_encode(cp, out);
}

/* Normalise label per CommonMark spec: trim outer whitespace, collapse
 * inner whitespace runs to a single space, and case-fold codepoints.
 * Writes at most 4 bytes per input byte plus 4 trailing bytes; caller
 * must provide an output buffer of size >= n*4 + 4. Returns output
 * length. */
static size_t cf_normalise(const char* s, size_t n, char* out) {
    /* Trim ends */
    size_t a = 0, b = n;
    while (a < b && (s[a] == ' ' || s[a] == '\t' || s[a] == '\n')) a++;
    while (b > a && (s[b-1] == ' ' || s[b-1] == '\t' || s[b-1] == '\n')) b--;
    size_t j = 0;
    int in_ws = 0;
    size_t i = a;
    while (i < b) {
        unsigned char c = (unsigned char)s[i];
        if (c == ' ' || c == '\t' || c == '\n') {
            if (!in_ws) { out[j++] = ' '; in_ws = 1; }
            i++;
        } else {
            int adv;
            unsigned cp = cf_decode(s, b, i, &adv);
            j += cf_fold(cp, out + j);
            i += adv;
            in_ws = 0;
        }
    }
    return j;
}

static char* normalise_label(mds_arena* a, const char* s, size_t n, size_t* nlen) {
    char* out = (char*)mds_arena_alloc(a, n * 4 + 4);
    size_t j = cf_normalise(s, n, out);
    out[j] = '\0';
    *nlen = j;
    return out;
}

static char* arena_dup(mds_arena* a, const char* s, size_t n) {
    char* d = (char*)mds_arena_alloc(a, n + 1);
    if (n) memcpy(d, s, n);
    d[n] = '\0';
    return d;
}

void mds_linkref_init(struct mds_linkref_tab* t, mds_arena* a) {
    t->entries = NULL;
    t->len     = 0;
    t->cap     = 0;
    t->arena   = a;
}

const mds_linkref* mds_linkref_get(const struct mds_linkref_tab* t,
                                   const char* label, size_t llen) {
    /* Normalise into a stack buffer. Max expansion is 4x (4-byte UTF-8
     * input expanding to 4-byte fold). Cap at 4 KiB; pathologically long
     * labels can't match a stored entry anyway. */
    char buf[4096];
    if (llen > sizeof buf / 4 - 4) return NULL;
    size_t nlen = cf_normalise(label, llen, buf);
    for (size_t i = 0; i < t->len; i++) {
        if (t->entries[i].klen == nlen &&
            (nlen == 0 || memcmp(t->entries[i].key, buf, nlen) == 0))
            return &t->entries[i];
    }
    return NULL;
}

int mds_linkref_add(struct mds_linkref_tab* t,
                    const char* label, size_t llen,
                    const char* url,   size_t ulen,
                    const char* title, size_t tlen) {
    size_t nlen;
    char* key = normalise_label(t->arena, label, llen, &nlen);
    /* dup check */
    for (size_t i = 0; i < t->len; i++) {
        if (t->entries[i].klen == nlen &&
            (nlen == 0 || memcmp(t->entries[i].key, key, nlen) == 0))
            return 0;
    }
    if (t->len == t->cap) {
        size_t nc = t->cap ? t->cap * 2 : 8;
        t->entries = (mds_linkref*)realloc(t->entries, nc * sizeof(mds_linkref));
        t->cap = nc;
    }
    mds_linkref* e = &t->entries[t->len++];
    e->key   = key;     e->klen = nlen;
    e->url   = arena_dup(t->arena, url, ulen);   e->ulen = ulen;
    e->title = tlen ? arena_dup(t->arena, title, tlen) : NULL;
    e->tlen  = tlen;
    return 1;
}
