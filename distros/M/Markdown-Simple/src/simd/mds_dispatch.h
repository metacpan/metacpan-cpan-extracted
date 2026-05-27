/* src/simd/mds_dispatch.h — 256-byte handler-kind dispatch table.
 *
 * The parser keeps a single 1-bit "interesting" bitmap (built by
 * classify_structural) and dispatches off the byte value at each
 * interesting position via this table. This keeps the bitmap small
 * (good L1 residency) and gives us a single branch-free
 * byte-to-handler-kind translation.
 *
 * Kinds are kept in lockstep with the actual scanner switches in
 * mds_inline.c / mds_block.c — see the asserts in t/10-equivalence.t.
 */
#ifndef MDS_DISPATCH_H
#define MDS_DISPATCH_H

#include <stdint.h>

typedef enum mds_kind {
    MDS_K_TEXT           = 0,   /* ordinary byte (paranoid default)  */
    MDS_K_NEWLINE        = 1,   /* '\n'                              */
    MDS_K_CR             = 2,   /* '\r'                              */
    MDS_K_TAB            = 3,   /* '\t'                              */
    MDS_K_SPACE          = 4,   /* ' '                               */
    MDS_K_BANG           = 5,   /* '!' (image, also block setext)    */
    MDS_K_QUOTE          = 6,   /* '"'                               */
    MDS_K_HASH           = 7,   /* '#' (atx heading)                 */
    MDS_K_AMP            = 8,   /* '&' (entity)                      */
    MDS_K_PAREN_OPEN     = 9,   /* '('                               */
    MDS_K_PAREN_CLOSE    = 10,  /* ')'                               */
    MDS_K_STAR           = 11,  /* '*' (emph, list, hr)              */
    MDS_K_PLUS           = 12,  /* '+' (list)                        */
    MDS_K_DASH           = 13,  /* '-' (list, hr, setext)            */
    MDS_K_DOT            = 14,  /* '.' (ordered list)                */
    MDS_K_COLON          = 15,  /* ':' (link title context)          */
    MDS_K_LT             = 16,  /* '<' (autolink, html inline)       */
    MDS_K_EQ             = 17,  /* '=' (setext)                      */
    MDS_K_GT             = 18,  /* '>' (blockquote)                  */
    MDS_K_BRACKET_OPEN   = 19,  /* '['                               */
    MDS_K_BACKSLASH      = 20,  /* '\\' (escape)                     */
    MDS_K_BRACKET_CLOSE  = 21,  /* ']'                               */
    MDS_K_UNDERSCORE     = 22,  /* '_'                               */
    MDS_K_BACKTICK       = 23,  /* '`' (code span)                   */
    MDS_K_PIPE           = 24,  /* '|' (tables)                      */
    MDS_K_TILDE          = 25,  /* '~' (strike, fence)               */
    MDS_K_MAX
} mds_kind;

/* Built once at process start (see mds_dispatch.c). */
extern const uint8_t mds_dispatch[256];

#endif
