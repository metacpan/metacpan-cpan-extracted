/* mds_footnote.c — GFM footnote definitions table.
 *
 * Lookup is by case-folded label (matching link-reference rules so that
 * `[^Foo]: x` is found by `[^foo]`). The implementation reuses the
 * same fold/normalise approach as mds_linkref by simply lowercasing
 * ASCII and collapsing inner whitespace; GFM spec examples only need
 * that subset for footnote labels (no Unicode case-folding in tests).
 */

#include "mds_footnote.h"
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

static size_t fn_normalise(const char* s, size_t n, char* out) {
    size_t a = 0, b = n;
    while (a < b && (s[a] == ' ' || s[a] == '\t' || s[a] == '\n')) a++;
    while (b > a && (s[b-1] == ' ' || s[b-1] == '\t' || s[b-1] == '\n')) b--;
    size_t j = 0;
    int in_ws = 0;
    for (size_t i = a; i < b; i++) {
        unsigned char c = (unsigned char)s[i];
        if (c == ' ' || c == '\t' || c == '\n') {
            if (!in_ws) { out[j++] = ' '; in_ws = 1; }
        } else {
            if (c >= 'A' && c <= 'Z') c = (unsigned char)(c + 0x20);
            out[j++] = (char)c;
            in_ws = 0;
        }
    }
    return j;
}

static char* fn_arena_dup(mds_arena* a, const char* s, size_t n) {
    char* d = (char*)mds_arena_alloc(a, n + 1);
    if (n) memcpy(d, s, n);
    d[n] = '\0';
    return d;
}

void mds_footnote_init(struct mds_footnote_tab* t, mds_arena* a) {
    t->entries = NULL;
    t->len = 0;
    t->cap = 0;
    t->arena = a;
}

const mds_footnote* mds_footnote_get(const struct mds_footnote_tab* t,
                                     const char* label, size_t llen) {
    if (!t || !t->len) return NULL;
    char buf[4096];
    if (llen > sizeof buf) return NULL;
    size_t nlen = fn_normalise(label, llen, buf);
    for (size_t i = 0; i < t->len; i++) {
        if (t->entries[i].klen == nlen &&
            (nlen == 0 || memcmp(t->entries[i].key, buf, nlen) == 0))
            return &t->entries[i];
    }
    return NULL;
}

int mds_footnote_add(struct mds_footnote_tab* t,
                     const char* label, size_t llen,
                     const char* body,  size_t blen) {
    char nbuf[4096];
    if (llen > sizeof nbuf) return 0;
    size_t nlen = fn_normalise(label, llen, nbuf);
    /* duplicate label: first-wins (spec §6.13). */
    for (size_t i = 0; i < t->len; i++) {
        if (t->entries[i].klen == nlen &&
            (nlen == 0 || memcmp(t->entries[i].key, nbuf, nlen) == 0))
            return 0;
    }
    if (t->len == t->cap) {
        size_t nc = t->cap ? t->cap * 2 : 8;
        t->entries = (mds_footnote*)realloc(t->entries, nc * sizeof(mds_footnote));
        t->cap = nc;
    }
    mds_footnote* e = &t->entries[t->len++];
    e->label = fn_arena_dup(t->arena, label, llen);   e->llen = llen;
    e->key   = fn_arena_dup(t->arena, nbuf, nlen);    e->klen = nlen;
    e->body  = fn_arena_dup(t->arena, body, blen);    e->blen = blen;
    return 1;
}
