/* mds_inline.h — scalar inline tokenizer (CommonMark §6).
 *
 * Public entry:  mds_inline_scan(ctx, s, n)
 *     Parses bytes [s, s+n) as inline content of one paragraph/heading and
 *     emits SAX inline events (enter_inline/leave_inline/text) through
 *     ctx->cb.  Caller is responsible for the surrounding enter/leave_block.
 */
#ifndef MDS_INLINE_H
#define MDS_INLINE_H

#include <stddef.h>
#include "mds_ctx.h"

void mds_inline_scan(mds_ctx* ctx, const char* s, size_t n);

#endif
