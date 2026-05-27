/* mds_entity.h — minimal HTML named-entity table used by inline scanner.
 *
 * We ship the high-frequency subset (XML5 mandatory entities plus the
 * most common typographic ones).  Unknown names leave the '&name;'
 * literal untouched, which is spec-conformant only for cases outside
 * the HTML5 named list — the full ~2200-entry table can be generated
 * later via tools/gen_entities.pl.
 *
 * Lookup is a tiny linear scan: < 50 entries, called rarely.
 */
#ifndef MDS_ENTITY_H
#define MDS_ENTITY_H

#include <stddef.h>
#include <string.h>

typedef struct {
    const char* name;     /* without leading '&' and trailing ';' */
    size_t      nlen;
    const char* utf8;     /* replacement bytes */
    size_t      ulen;
} mds_entity;

static const mds_entity MDS_ENTITIES[] = {
    /* core 5 (XML) */
    { "amp",    3, "&",            1 },
    { "lt",     2, "<",            1 },
    { "gt",     2, ">",            1 },
    { "quot",   4, "\"",           1 },
    { "apos",   4, "'",            1 },
    /* high-frequency typographic / spacing */
    { "nbsp",   4, "\xc2\xa0",     2 },
    { "copy",   4, "\xc2\xa9",     2 },
    { "reg",    3, "\xc2\xae",     2 },
    { "trade",  5, "\xe2\x84\xa2", 3 },
    { "hellip", 6, "\xe2\x80\xa6", 3 },
    { "mdash",  5, "\xe2\x80\x94", 3 },
    { "ndash",  5, "\xe2\x80\x93", 3 },
    { "lsquo",  5, "\xe2\x80\x98", 3 },
    { "rsquo",  5, "\xe2\x80\x99", 3 },
    { "ldquo",  5, "\xe2\x80\x9c", 3 },
    { "rdquo",  5, "\xe2\x80\x9d", 3 },
    { "laquo",  5, "\xc2\xab",     2 },
    { "raquo",  5, "\xc2\xbb",     2 },
    { "deg",    3, "\xc2\xb0",     2 },
    { "plusmn", 6, "\xc2\xb1",     2 },
    { "times",  5, "\xc3\x97",     2 },
    { "divide", 6, "\xc3\xb7",     2 },
    { "para",   4, "\xc2\xb6",     2 },
    { "sect",   4, "\xc2\xa7",     2 },
    { "middot", 6, "\xc2\xb7",     2 },
    { "bull",   4, "\xe2\x80\xa2", 3 },
    { "dagger", 6, "\xe2\x80\xa0", 3 },
    { "Dagger", 6, "\xe2\x80\xa1", 3 },
    { "permil", 6, "\xe2\x80\xb0", 3 },
    { "euro",   4, "\xe2\x82\xac", 3 },
    { "pound",  5, "\xc2\xa3",     2 },
    { "yen",    3, "\xc2\xa5",     2 },
    { "cent",   4, "\xc2\xa2",     2 },
};
#define MDS_ENTITY_COUNT (sizeof(MDS_ENTITIES)/sizeof(MDS_ENTITIES[0]))

#include "mds_entities_full.h"

static inline const mds_entity* mds_entity_lookup(const char* name, size_t n) {
    /* Fast path: small high-frequency table (linear scan). */
    for (size_t i = 0; i < MDS_ENTITY_COUNT; i++) {
        if (MDS_ENTITIES[i].nlen == n &&
            memcmp(MDS_ENTITIES[i].name, name, n) == 0)
            return &MDS_ENTITIES[i];
    }
    /* Slow path: full HTML5 table (binary search). Return value reuses the
     * mds_entity layout so callers don't have to care which table hit. */
    const mds_entity_full* f = mds_entity_full_lookup(name, n);
    if (!f) return NULL;
    static _Thread_local mds_entity scratch;
    scratch.name = f->name;
    scratch.nlen = f->nlen;
    scratch.utf8 = f->utf8;
    scratch.ulen = f->ulen;
    return &scratch;
}

#endif
