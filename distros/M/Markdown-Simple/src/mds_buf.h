/* mds_buf.h — output buffer wrapping a Perl SV.
 *
 * Owns a cursor into SvPV so we avoid SvCUR/SvLEN roundtrips per write.
 * Caller must call mds_buf_finalize() before the SV is consumed by Perl.
 */
#ifndef MDS_BUF_H
#define MDS_BUF_H

#include <stddef.h>
#include "EXTERN.h"
#include "perl.h"
#include "mds_compiler.h"

typedef struct mds_buf {
    SV*   sv;
    char* base;     /* SvPVX(sv) */
    char* cur;      /* write cursor */
    char* end;      /* base + SvLEN(sv) - 1 (room for trailing NUL) */
} mds_buf;

/* Attach to an existing SV, predict initial capacity. */
void mds_buf_init(pTHX_ mds_buf* b, SV* sv, size_t hint);

/* Input-aware initial capacity. Samples the head of
 * `input` for pipe density and picks 2.25\u00d7 for table-heavy inputs,
 * 1.50\u00d7 for everything else. Falls back to mds_buf_init's prose
 * default when input is NULL. */
void mds_buf_init_for_input(pTHX_ mds_buf* b, SV* sv,
                            const char* input, size_t hint);

/* Ensure at least `need` bytes free; grows SV and refreshes cursor. */
void mds_buf_reserve(pTHX_ mds_buf* b, size_t need);

/* Append n bytes. The grow check is the only branch; the common case
 * (n bytes fit) compiles to a 2-instruction cursor bump + memcpy that
 * the optimiser turns into a register store when n is a compile-time
 * constant under 8. Marked always-inline so the constant-n cases at
 * call sites (HTML tags via MDS_BUF_LIT) really do specialise. */
MDS_ALWAYS_INLINE static void mds_buf_write(pTHX_ mds_buf* b, const char* s, size_t n) {
    if (MDS_UNLIKELY(b->cur + n > b->end)) mds_buf_reserve(aTHX_ b, n);
    memcpy(b->cur, s, n);
    b->cur += n;
}

MDS_ALWAYS_INLINE static void mds_buf_putc(pTHX_ mds_buf* b, char c) {
    if (MDS_UNLIKELY(b->cur + 1 > b->end)) mds_buf_reserve(aTHX_ b, 1);
    *b->cur++ = c;
}

/* Write a compile-time literal. */
#define MDS_BUF_LIT(b, lit) mds_buf_write(aTHX_ (b), "" lit, sizeof(lit) - 1)

/* Commit cursor to SvCUR, NUL-terminate. */
void mds_buf_finalize(pTHX_ mds_buf* b);

#endif
