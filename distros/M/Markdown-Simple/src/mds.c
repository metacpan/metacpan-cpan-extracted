/* mds.c — public entry point for the new Markdown::Simple parser.
 *
 * Pipeline: arena init -> block scanner -> SAX -> HTML renderer.
 * The inline tokeniser HTML-escapes text bytes downstream.
 */

#include "mds.h"
#include "mds_buf.h"
#include "mds_ctx.h"
#include "mds_arena.h"
#include "mds_block.h"
#include "mds_linkref.h"
#include "mds_footnote.h"
#include "mds_render_html.h"
#include "simd/mds_simd.h"

#include <string.h>
#include <stdint.h>
#include <stdlib.h>

/* Opaque blob sized comfortably larger than the renderer's private
 * `render_state`. The renderer placement-initialises this via the
 * pointer returned in ud_out. Keeping it stack-local keeps us
 * thread-safe and costs no allocation for the state itself.
 *
 * The state is not entirely allocation free, though: the renderer grows
 * several buffers through it on demand (alt text, autolink coalescing,
 * the highlight accumulator, the footnote tables). Because the blob is a
 * stack local, nothing reclaims those when it goes out of scope, so every
 * exit path below has to call mds_render_html_cleanup. Before that call
 * existed each render leaked between 60 bytes and a few kilobytes
 * depending on which features the document used. */
struct mds_render_state_blob {
    unsigned char bytes[16 * 1024];
};

int mds_render_html_to_sv_toc(pTHX_
                              const char*        input,
                              size_t             len,
                              unsigned           flags,
                              SV*                output_sv,
                              mds_arena*         borrowed_arena,
                              mds_block_scratch* borrowed_scratch,
                              AV*                toc) {
    mds_buf buf;
    struct mds_render_state_blob blob;
    void* ud;
    mds_callbacks cb;
    mds_ctx ctx;
    mds_arena local_arena;
    mds_arena* arena;

    /* Pass raw `len` so mds_buf_init_for_input owns the output-size
     * multiplier; avoids double-inflation. */
    mds_buf_init_for_input(aTHX_ &buf, output_sv, input, len);

    memset(&blob, 0, sizeof blob);
    ud = &blob;

    memset(&cb, 0, sizeof cb);
    mds_render_html_install(&cb, &ud, &buf, flags, toc);

    memset(&ctx, 0, sizeof ctx);
    ctx.input   = input;
    ctx.len     = len;
    ctx.flags   = flags;
    ctx.cb      = cb;
    ctx.ud      = ud;
    ctx.scratch = borrowed_scratch;

    /* If a persistent (borrowed) arena was provided, use
     * it by value and reset (not free) at the end so the warm head page
     * survives between parses. Otherwise allocate a per-call arena. */
    if (borrowed_arena) {
        arena = borrowed_arena;
    } else {
        arena = &local_arena;
        mds_arena_init(arena);
    }
    /* mds_ctx embeds the arena by value, so callees that take &ctx.arena
     * see the same storage; we copy in/out around mds_block_scan. */
    ctx.arena = *arena;

    /* ---- Preprocessing: validate UTF-8, build line index. ---- */
    {
        const mds_simd_ops* ops = (flags & MDS_FLAG_NO_SIMD)
            ? mds_simd_ops_scalar()
            : mds_simd_get();

        if ((flags & MDS_FLAG_STRICT_UTF8) && len) {
            if (MDS_UNLIKELY(!ops->validate_utf8(input, len))) {
                mds_arena_snapshot(&ctx.arena, &mds_last_arena_profile);
                *arena = ctx.arena;
                if (borrowed_arena) mds_arena_reset(arena);
                else                mds_arena_free(arena);
                mds_render_html_cleanup(ud);
                mds_buf_finalize(aTHX_ &buf);
                return -1;                         /* malformed UTF-8 */
            }
        }

        if (len && len <= 0xFFFFFFFFu) {
            /* Conservative cap: at most one newline per byte. We cap at
             * len so worst-case all-newline inputs still fit. */
            size_t cap = len;
            uint32_t* offs = (uint32_t*)mds_arena_alloc(&ctx.arena,
                                                       cap * sizeof(uint32_t));
            if (offs) {
                size_t n = ops->find_newlines(input, len, offs, cap);
                if (n == (size_t)-1) {
                    ctx.line_idx_overflow = 1;
                    ctx.line_offsets = NULL;
                    ctx.n_lines = 0;
                } else {
                    ctx.line_offsets = offs;
                    ctx.n_lines = n;
                }
            }
        }
        /* ctx.line_offsets is precomputed and validated by tests, but the
         * scanner still does its own per-line walk. */
    }

    mds_block_scan(&ctx);

    /* Both tables live in the arena but grow their entry arrays off the
     * general heap, so they have to be released while the arena that holds
     * the table structs is still valid. */
    mds_linkref_free(ctx.refs);
    mds_footnote_free(ctx.footnotes);

    mds_arena_snapshot(&ctx.arena, &mds_last_arena_profile);
    *arena = ctx.arena;
    if (borrowed_arena) mds_arena_reset(arena);
    else                mds_arena_free(arena);
    mds_render_html_cleanup(ud);
    mds_buf_finalize(aTHX_ &buf);
    return 0;
}

int mds_render_html_to_sv_ex(pTHX_
                             const char*        input,
                             size_t             len,
                             unsigned           flags,
                             SV*                output_sv,
                             mds_arena*         borrowed_arena,
                             mds_block_scratch* borrowed_scratch) {
    return mds_render_html_to_sv_toc(aTHX_ input, len, flags, output_sv,
                                     borrowed_arena, borrowed_scratch, NULL);
}

int mds_render_html_to_sv(pTHX_
                          const char* input,
                          size_t      len,
                          unsigned    flags,
                          SV*         output_sv) {
    return mds_render_html_to_sv_toc(aTHX_ input, len, flags, output_sv,
                                     NULL, NULL, NULL);
}

/* Last-parse arena snapshot, populated unconditionally
 * by mds_render_html_to_sv. Not thread-safe; intended for profiling
 * scripts (bench/profile_arena.pl). */
mds_arena_profile mds_last_arena_profile;
