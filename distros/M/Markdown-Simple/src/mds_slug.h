/* mds_slug.h - heading text to anchor id.
 *
 * Header-only, in the style of the Eshu headers this engine already pulls in.
 * The rule is GitHub's, because that is what readers' muscle memory and every
 * existing cross-document link already assume: lowercase, ASCII punctuation
 * dropped, runs of whitespace collapsed to a single hyphen, leading and
 * trailing hyphens trimmed.
 *
 * Bytes >= 0x80 pass through untouched. Lowercasing UTF-8 properly would mean
 * carrying a case-folding table for the whole of Unicode, and getting it half
 * right (ASCII-folding the lead bytes of a multi-byte sequence) would corrupt
 * the text outright. Passing them through leaves a heading in Greek or
 * Japanese with a usable, stable, round-trippable id.
 *
 * Slugs must be unique within a document, so the caller keeps a table of what
 * it has already emitted and mds_slug_uniq appends -1, -2 and so on. The
 * table is the caller's because the renderer owns the document scope; this
 * header stays free of state.
 */
#ifndef MDS_SLUG_H
#define MDS_SLUG_H

#include <stddef.h>
#include <string.h>
#include <stdlib.h>

/* Keep an id from growing without bound on a pathological heading. Long
 * enough that no realistic heading is truncated. */
#define MDS_SLUG_MAX 128

/* True for the ASCII bytes a slug keeps verbatim. */
static int mds_slug_keep(unsigned char c) {
    return (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') ||
           c == '-' || c == '_' || c >= 0x80;
}

/* Write the slug for `src` into `out` (at least MDS_SLUG_MAX + 1 bytes).
 * Returns the length written, excluding the NUL. May be 0: a heading of pure
 * punctuation has no slug, and the caller decides what to do about that. */
static size_t mds_slugify(const char* src, size_t len, char* out) {
    size_t i, n = 0;
    int pending_dash = 0;

    for (i = 0; i < len && n < MDS_SLUG_MAX; i++) {
        unsigned char c = (unsigned char)src[i];

        if (c >= 'A' && c <= 'Z') c = (unsigned char)(c - 'A' + 'a');

        if (c == ' ' || c == '\t' || c == '\n' || c == '\r') {
            /* Defer: a run of whitespace becomes one hyphen, and trailing
             * whitespace becomes nothing at all. */
            if (n > 0) pending_dash = 1;
            continue;
        }
        if (!mds_slug_keep(c)) continue;      /* ASCII punctuation */

        if (pending_dash) {
            out[n++] = '-';
            pending_dash = 0;
            if (n >= MDS_SLUG_MAX) break;
        }
        out[n++] = (char)c;
    }

    /* Trim hyphens that ended up at either edge. Leading ones can only come
     * from the source text, since pending_dash never fires at n == 0. */
    while (n > 0 && out[n - 1] == '-') n--;
    {
        size_t lead = 0;
        while (lead < n && out[lead] == '-') lead++;
        if (lead) { memmove(out, out + lead, n - lead); n -= lead; }
    }

    out[n] = '\0';
    return n;
}

/* A table of the slugs already emitted for this document. Grown off the
 * general heap; the caller frees it with mds_slug_table_free. */
typedef struct mds_slug_table {
    char** slugs;
    size_t len;
    size_t cap;
} mds_slug_table;

static void mds_slug_table_free(mds_slug_table* t) {
    size_t i;
    if (!t) return;
    for (i = 0; i < t->len; i++) free(t->slugs[i]);
    free(t->slugs);
    t->slugs = NULL;
    t->len = t->cap = 0;
}

/* Make `slug` unique against `t`, extending it in place with -1, -2, ... as
 * GitHub does, and record the result. `slug` must have room for
 * MDS_SLUG_MAX + 16 bytes. Returns the final length.
 *
 * A linear scan is the right shape here: a page has tens of headings, and a
 * hash table would cost more to build than it ever saves. */
static size_t mds_slug_uniq(mds_slug_table* t, char* slug, size_t len) {
    size_t i;
    unsigned suffix = 0;
    size_t base_len = len;

    for (;;) {
        int clash = 0;
        for (i = 0; i < t->len; i++) {
            if (strcmp(t->slugs[i], slug) == 0) { clash = 1; break; }
        }
        if (!clash) break;
        suffix++;
        /* Rewrite the suffix onto the original stem each time, so the second
         * "Notes" is notes-1 rather than notes-1-1. */
        len = base_len;
        {
            char num[16];
            size_t nl = 0, k;
            unsigned v = suffix;
            do { num[nl++] = (char)('0' + (v % 10)); v /= 10; } while (v);
            slug[len++] = '-';
            for (k = 0; k < nl; k++) slug[len + k] = num[nl - 1 - k];
            len += nl;
            slug[len] = '\0';
        }
    }

    if (t->len == t->cap) {
        size_t nc = t->cap ? t->cap * 2 : 16;
        char** ns = (char**)realloc(t->slugs, nc * sizeof(char*));
        if (!ns) return len;                  /* OOM: skip recording */
        t->slugs = ns;
        t->cap = nc;
    }
    {
        char* copy = (char*)malloc(len + 1);
        if (copy) {
            memcpy(copy, slug, len + 1);
            t->slugs[t->len++] = copy;
        }
    }
    return len;
}

#endif /* MDS_SLUG_H */
