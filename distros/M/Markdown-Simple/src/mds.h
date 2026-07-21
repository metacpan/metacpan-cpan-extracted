/* mds.h — public C entry point for the new Markdown::Simple parser.
 *
 * The old markdown_to_html in Simple.xs is unaffected by this API.
 */
#ifndef MDS_H
#define MDS_H

#include <stddef.h>
#include "EXTERN.h"
#include "perl.h"
#include "mds_arena.h"
#include "mds_block.h"

/* Last-parse arena snapshot, populated unconditionally
 * by mds_render_html_to_sv. Read by the bench/profile_arena.pl driver
 * via the _last_arena_profile XS shim. Not thread-safe. */
extern mds_arena_profile mds_last_arena_profile;

/* Options bitmask. Map from Perl-side options in XS glue. */
#define MDS_FLAG_TABLES            (1u << 0)
#define MDS_FLAG_STRIKE            (1u << 1)
#define MDS_FLAG_TASKLIST          (1u << 2)
#define MDS_FLAG_AUTOLINK          (1u << 3)
#define MDS_FLAG_DISALLOW_RAW_HTML (1u << 4)
#define MDS_FLAG_HARD_BREAKS       (1u << 5)
#define MDS_FLAG_UNSAFE            (1u << 6)
#define MDS_FLAG_NO_SIMD           (1u << 7)
#define MDS_FLAG_STRICT_UTF8       (1u << 22) /* reject malformed UTF-8 with error */

/* Per-syntax disables. Negative polarity: default (bit clear) means the
 * syntax is recognised normally, matching legacy "enable_foo => 1" defaults.
 * When set, the parser ignores that syntax and the bytes fall through as
 * paragraph text (CommonMark "no parse" semantics, NOT stripping). */
#define MDS_FLAG_NO_HEADINGS        (1u <<  8)  /* ATX `#` and setext === --- */
#define MDS_FLAG_NO_EMPH            (1u <<  9)  /* single `*` `_` italic */
#define MDS_FLAG_NO_STRONG          (1u << 10)  /* double `**` `__` bold */
#define MDS_FLAG_NO_CODE            (1u << 11)  /* inline `code` spans */
#define MDS_FLAG_NO_LINKS           (1u << 12)  /* `[text](url)` and refs */
#define MDS_FLAG_NO_IMAGES          (1u << 13)  /* `![alt](url)` */
#define MDS_FLAG_NO_ORDERED_LISTS   (1u << 14)  /* `1.` `2)` markers */
#define MDS_FLAG_NO_UNORDERED_LISTS (1u << 15)  /* `-` `*` `+` markers */
#define MDS_FLAG_NO_QUOTES          (1u << 16)  /* `>` block quotes */
#define MDS_FLAG_NO_THEMATIC_BREAK  (1u << 17)  /* `---` `***` `___` hr */
#define MDS_FLAG_NO_FENCED_CODE     (1u << 18)  /* ``` ``` and ~~~ ~~~ */
#define MDS_FLAG_NO_INDENTED_CODE   (1u << 19)  /* 4-space code blocks */
#define MDS_FLAG_NO_HTML            (1u << 20)  /* raw HTML blocks + inline */
#define MDS_FLAG_NO_REFERENCES      (1u << 21)  /* `[id]: url` definitions */
#define MDS_FLAG_FOOTNOTES          (1u << 23)  /* GFM `[^label]` footnotes */
#define MDS_FLAG_HIGHLIGHT          (1u << 24)  /* syntax-highlight fenced code blocks via Eshu */

/* GFM-superset preset. NOTE: HARD_BREAKS is NOT part of GFM defaults
 * (CommonMark §6.8 keeps softbreaks as newlines). Callers can OR it in. */
#define MDS_FLAGS_GFM \
    (MDS_FLAG_TABLES | MDS_FLAG_STRIKE | MDS_FLAG_TASKLIST | \
     MDS_FLAG_AUTOLINK | MDS_FLAG_DISALLOW_RAW_HTML | MDS_FLAG_FOOTNOTES)

/* Pure CommonMark preset — no GFM extensions. */
#define MDS_FLAGS_COMMONMARK 0u

/* Single public entry point. Appends rendered HTML to output_sv.
 * Returns 0 on success, non-zero on error. */
int mds_render_html_to_sv(pTHX_
                          const char* input,
                          size_t      len,
                          unsigned    flags,
                          SV*         output_sv);

/* Extended entry that borrows a caller-owned arena.
 * When borrowed_arena is non-NULL the arena is initialised by the caller
 * (via mds_arena_init), used for this parse, then mds_arena_reset is
 * called (head page stays warm). When borrowed_arena is NULL the
 * behaviour matches mds_render_html_to_sv (local arena, freed at end).
 * borrowed_scratch (optional) carries the block scanner's
 * para / code / html / ev / bytepool buffers across calls so the malloc
 * traffic from realloc-grown scratch is amortised over many renders. */
int mds_render_html_to_sv_ex(pTHX_
                             const char*        input,
                             size_t             len,
                             unsigned           flags,
                             SV*                output_sv,
                             mds_arena*         borrowed_arena,
                             mds_block_scratch* borrowed_scratch);

#endif
