/*
 * flex.h — CSS Flexible Box layout engine (single + multi-line)
 *
 * Supports flex-wrap, align-content, gap (main_gap/cross_gap),
 * and per-item margins (margin_main_start/end, margin_cross_start/end).
 * Zero dependencies beyond <stdlib.h> and <float.h>.
 */

#ifndef LAYOUT_FLEX_H
#define LAYOUT_FLEX_H

#include <stdlib.h>
#include <float.h>

/* ── direction ──────────────────────────────────────────────────── */
#define LF_DIR_ROW    0
#define LF_DIR_COLUMN 1

/* ── justify-content ────────────────────────────────────────────── */
#define LF_JUST_START         0
#define LF_JUST_END           1
#define LF_JUST_CENTER        2
#define LF_JUST_SPACE_BETWEEN 3
#define LF_JUST_SPACE_AROUND  4
#define LF_JUST_SPACE_EVENLY  5

/* ── align-items / align-self ───────────────────────────────────── */
#define LF_ALIGN_STRETCH 0
#define LF_ALIGN_START   1
#define LF_ALIGN_END     2
#define LF_ALIGN_CENTER  3

/* ── flex-wrap ──────────────────────────────────────────────────── */
#define LF_WRAP_NOWRAP  0
#define LF_WRAP_WRAP    1
#define LF_WRAP_REVERSE 2

/* ── align-content ──────────────────────────────────────────────── */
#define LF_ACONT_STRETCH       0
#define LF_ACONT_START         1
#define LF_ACONT_END           2
#define LF_ACONT_CENTER        3
#define LF_ACONT_SPACE_BETWEEN 4
#define LF_ACONT_SPACE_AROUND  5
#define LF_ACONT_SPACE_EVENLY  6

/* ── item descriptor ─────────────────────────────────────────────── */

typedef struct {
    float basis;
    float grow;
    float shrink;
    float min_main;
    float max_main;           /* 0 = unconstrained */
    float min_cross;
    float max_cross;          /* 0 = unconstrained */
    float cross;              /* natural cross size (non-stretch align) */
    int   align_self;         /* LF_ALIGN_* or -1 to inherit           */
    float margin_main_start;  /* margin before item on main axis        */
    float margin_main_end;    /* margin after  item on main axis        */
    float margin_cross_start; /* margin before item on cross axis       */
    float margin_cross_end;   /* margin after  item on cross axis       */
} lf_item_t;

/* ── container context ───────────────────────────────────────────── */

typedef struct {
    float      main_size;
    float      cross_size;
    int        direction;       /* LF_DIR_*   */
    int        justify;         /* LF_JUST_*  */
    int        align_items;     /* LF_ALIGN_* */
    int        wrap;            /* LF_WRAP_*  */
    int        align_content;   /* LF_ACONT_* */
    float      main_gap;        /* fixed gap between items on main axis  */
    float      cross_gap;       /* fixed gap between lines on cross axis */
    lf_item_t *items;
    int        n_items;
} lf_ctx_t;

/* ── output rectangle ────────────────────────────────────────────── */

typedef struct { float x, y, w, h; } lf_rect_t;

/* ── internal: per-line descriptor ──────────────────────────────── */

typedef struct {
    int   start;
    int   count;
    float cross_size;
    float cross_pos;
} lf__line_t;

/* ── internal helpers ─────────────────────────────────────────────── */

static float lf__fmax(float a, float b) { return a > b ? a : b; }
static float lf__fmin(float a, float b) { return a < b ? a : b; }
static float lf__clamp(float v, float lo, float hi) {
    return v < lo ? lo : (v > hi ? hi : v);
}

/* outer main-axis size of one item (content size + margins) */
static float lf__outer_main(const lf_item_t *it, float size) {
    return size + it->margin_main_start + it->margin_main_end;
}

/* outer cross-axis size for line-cross contribution */
static float lf__outer_cross(const lf_item_t *it, float ic) {
    return ic + it->margin_cross_start + it->margin_cross_end;
}

/* ── grow/shrink violation-freezing loop for one line ──────────── */

static void lf__flex_line(const lf_item_t *items, int start, int count,
                          float main_size, float main_gap, float *sizes) {
    int    i, end = start + count;
    float *proposed;
    int   *frozen;
    float  free_space;
    float  gaps;

    if (count <= 0) return;

    proposed = (float *)calloc((size_t)count, sizeof(float));
    frozen   = (int   *)calloc((size_t)count, sizeof(int));

    gaps = main_gap * (count > 1 ? count - 1 : 0);

    /* free space = main_size - gaps - sum(outer sizes) */
    free_space = main_size - gaps;
    for (i = start; i < end; i++)
        free_space -= lf__outer_main(&items[i], sizes[i]);

    if (free_space > 0.0f) {
        for (;;) {
            float remaining, tg = 0.0f;
            int   viol = 0, j;
            remaining = main_size - gaps;
            for (i = start; i < end; i++) remaining -= lf__outer_main(&items[i], sizes[i]);
            for (i = start; i < end; i++) { j = i-start; if (!frozen[j]) tg += items[i].grow; }
            if (tg <= 0.0f) break;
            for (i = start; i < end; i++) {
                j = i - start;
                if (frozen[j]) { proposed[j] = sizes[i]; continue; }
                proposed[j] = sizes[i] + remaining * (items[i].grow / tg);
            }
            for (i = start; i < end; i++) {
                float mn, mx, c;
                j = i - start;
                if (frozen[j]) continue;
                mn = items[i].min_main;
                mx = items[i].max_main > 0.0f ? items[i].max_main : FLT_MAX;
                c  = lf__clamp(proposed[j], mn, mx);
                if (c != proposed[j]) { sizes[i] = c; frozen[j] = 1; viol = 1; }
                else sizes[i] = proposed[j];
            }
            if (!viol) break;
        }
    } else if (free_space < 0.0f) {
        for (;;) {
            float remaining, ts = 0.0f;
            int   viol = 0, j;
            remaining = main_size - gaps;
            for (i = start; i < end; i++) remaining -= lf__outer_main(&items[i], sizes[i]);
            for (i = start; i < end; i++) { j = i-start; if (!frozen[j]) ts += items[i].shrink * sizes[i]; }
            if (ts <= 0.0f) break;
            for (i = start; i < end; i++) {
                j = i - start;
                if (frozen[j]) { proposed[j] = sizes[i]; continue; }
                proposed[j] = sizes[i] + remaining * (items[i].shrink * sizes[i] / ts);
            }
            for (i = start; i < end; i++) {
                float mn, mx, c;
                j = i - start;
                if (frozen[j]) continue;
                mn = items[i].min_main;
                mx = items[i].max_main > 0.0f ? items[i].max_main : FLT_MAX;
                c  = lf__clamp(proposed[j], mn, mx);
                if (c != proposed[j]) { sizes[i] = c; frozen[j] = 1; viol = 1; }
                else sizes[i] = proposed[j];
            }
            if (!viol) break;
        }
    }

    free(proposed);
    free(frozen);
}

/* ── justify spacing for one line ────────────────────────────────── */
/*
 * gap_before  — offset before the first item's margin
 * gap_between — space between consecutive items' outer edges (includes main_gap)
 */
static void lf__justify(int justify, float main_size, float main_gap,
                         const lf_item_t *items, float *sizes,
                         int start, int count,
                         float *gap_before, float *gap_between) {
    int   i, end = start + count;
    float ff = main_size - main_gap * (count > 1 ? count - 1 : 0);
    for (i = start; i < end; i++) ff -= lf__outer_main(&items[i], sizes[i]);
    ff = lf__fmax(ff, 0.0f);

    *gap_before  = 0.0f;
    *gap_between = main_gap;  /* base is the fixed gap */

    switch (justify) {
    case LF_JUST_START:   break;
    case LF_JUST_END:     *gap_before = ff; break;
    case LF_JUST_CENTER:  *gap_before = ff / 2.0f; break;
    case LF_JUST_SPACE_BETWEEN:
        *gap_between += (count > 1) ? ff / (float)(count - 1) : 0.0f; break;
    case LF_JUST_SPACE_AROUND: {
        float g = (count > 0) ? ff / (float)count : 0.0f;
        *gap_between += g; *gap_before = g / 2.0f;
    } break;
    case LF_JUST_SPACE_EVENLY: {
        float g = (count > 0) ? ff / (float)(count + 1) : 0.0f;
        *gap_between += g; *gap_before = g;
    } break;
    }
}

/* ── main algorithm ──────────────────────────────────────────────── */

static void lf_compute(const lf_ctx_t *ctx, lf_rect_t *out) {
    int       n = ctx->n_items;
    int       i, li;
    float    *sizes;
    lf__line_t *lines;
    int       n_lines = 0;

    if (n <= 0) return;

    sizes = (float     *)calloc((size_t)n, sizeof(float));
    lines = (lf__line_t *)calloc((size_t)n, sizeof(lf__line_t));

    /* ── 1. hypothetical main sizes ─────────────────────────────── */
    for (i = 0; i < n; i++) {
        float mn = ctx->items[i].min_main;
        float mx = ctx->items[i].max_main > 0.0f ? ctx->items[i].max_main : FLT_MAX;
        sizes[i] = lf__clamp(ctx->items[i].basis, mn, mx);
    }

    /* ── 2. line breaking ────────────────────────────────────────── */
    if (ctx->wrap == LF_WRAP_NOWRAP) {
        lines[0].start = 0;
        lines[0].count = n;
        n_lines = 1;
    } else {
        int   ls  = 0;
        float lsz = 0.0f;
        for (i = 0; i < n; i++) {
            float outer_i = lf__outer_main(&ctx->items[i], sizes[i]);
            float gap_i   = (i > ls) ? ctx->main_gap : 0.0f;
            if (i > ls && lsz + gap_i + outer_i > ctx->main_size) {
                lines[n_lines].start = ls;
                lines[n_lines].count = i - ls;
                n_lines++;
                ls  = i;
                lsz = outer_i;
            } else {
                lsz += gap_i + outer_i;
            }
        }
        lines[n_lines].start = ls;
        lines[n_lines].count = n - ls;
        n_lines++;
    }

    /* ── 3. grow / shrink per line ───────────────────────────────── */
    for (li = 0; li < n_lines; li++)
        lf__flex_line(ctx->items, lines[li].start, lines[li].count,
                      ctx->main_size, ctx->main_gap, sizes);

    /* ── 4. line cross sizes ─────────────────────────────────────── */
    if (n_lines == 1) {
        lines[0].cross_size = ctx->cross_size;
        lines[0].cross_pos  = 0.0f;
    } else {
        float total_cs = 0.0f;
        float ff;

        for (li = 0; li < n_lines; li++) {
            int   start = lines[li].start;
            int   end   = start + lines[li].count;
            float lcs   = 0.0f;
            for (i = start; i < end; i++) {
                int   al = (ctx->items[i].align_self >= 0)
                         ? ctx->items[i].align_self : ctx->align_items;
                float ic = (al == LF_ALIGN_STRETCH)
                         ? ctx->items[i].min_cross
                         : lf__fmax(ctx->items[i].cross, ctx->items[i].min_cross);
                lcs = lf__fmax(lcs, lf__outer_cross(&ctx->items[i], ic));
            }
            lines[li].cross_size = lcs;
            total_cs += lcs;
        }

        ff = ctx->cross_size
           - total_cs
           - ctx->cross_gap * (n_lines > 1 ? n_lines - 1 : 0);

        /* stretch distributes remaining cross space equally among lines */
        if (ctx->align_content == LF_ACONT_STRETCH && ff > 0.0f) {
            float add = ff / (float)n_lines;
            for (li = 0; li < n_lines; li++) lines[li].cross_size += add;
            ff = 0.0f;
        }

        /* ── 5. align-content → line cross positions ─────────────── */
        {
            float gb  = 0.0f;
            float gbw = ctx->cross_gap;
            float pos;
            float pff = lf__fmax(ff, 0.0f);

            switch (ctx->align_content) {
            case LF_ACONT_STRETCH:
            case LF_ACONT_START:   break;
            case LF_ACONT_END:     gb = pff; break;
            case LF_ACONT_CENTER:  gb = pff / 2.0f; break;
            case LF_ACONT_SPACE_BETWEEN:
                gbw += (n_lines > 1) ? pff / (float)(n_lines - 1) : 0.0f; break;
            case LF_ACONT_SPACE_AROUND: {
                float g = (n_lines > 0) ? pff / (float)n_lines : 0.0f;
                gbw += g; gb = g / 2.0f;
            } break;
            case LF_ACONT_SPACE_EVENLY: {
                float g = (n_lines > 0) ? pff / (float)(n_lines + 1) : 0.0f;
                gbw += g; gb = g;
            } break;
            }

            if (ctx->wrap == LF_WRAP_REVERSE) {
                pos = gb;
                for (li = n_lines - 1; li >= 0; li--) {
                    lines[li].cross_pos = pos;
                    pos += lines[li].cross_size;
                    if (li > 0) pos += gbw;
                }
            } else {
                pos = gb;
                for (li = 0; li < n_lines; li++) {
                    lines[li].cross_pos = pos;
                    pos += lines[li].cross_size;
                    if (li < n_lines - 1) pos += gbw;
                }
            }
        }
    }

    /* ── 6. place items ─────────────────────────────────────────── */
    for (li = 0; li < n_lines; li++) {
        int   start        = lines[li].start;
        int   count        = lines[li].count;
        int   end          = start + count;
        float lcs          = lines[li].cross_size;
        float cross_origin = lines[li].cross_pos;
        float gb, gbw, main_pos;

        lf__justify(ctx->justify, ctx->main_size, ctx->main_gap,
                    ctx->items, sizes, start, count, &gb, &gbw);
        main_pos = gb;

        for (i = start; i < end; i++) {
            const lf_item_t *it  = &ctx->items[i];
            int   al    = (it->align_self >= 0) ? it->align_self : ctx->align_items;
            float mn_c  = it->min_cross;
            float mx_c  = it->max_cross > 0.0f ? it->max_cross : FLT_MAX;
            float nat   = it->cross;
            float mcs   = it->margin_cross_start;
            float mce   = it->margin_cross_end;
            float avail = lcs - mcs - mce;  /* cross space inside margins */
            float ic, cp;

            switch (al) {
            case LF_ALIGN_STRETCH:
                ic = lf__clamp(avail, mn_c, mx_c);
                cp = mcs;
                break;
            case LF_ALIGN_START:
                ic = (nat > 0.0f) ? lf__clamp(nat, mn_c, lf__fmin(mx_c, avail))
                                  : lf__clamp(avail, mn_c, mx_c);
                cp = mcs;
                break;
            case LF_ALIGN_END:
                ic = (nat > 0.0f) ? lf__clamp(nat, mn_c, lf__fmin(mx_c, avail))
                                  : lf__clamp(avail, mn_c, mx_c);
                cp = lcs - ic - mce;
                break;
            case LF_ALIGN_CENTER:
                ic = (nat > 0.0f) ? lf__clamp(nat, mn_c, lf__fmin(mx_c, avail))
                                  : lf__clamp(avail, mn_c, mx_c);
                cp = mcs + (avail - ic) / 2.0f;
                break;
            default:
                ic = avail; cp = mcs;
            }

            /* place content box after margin_main_start */
            main_pos += it->margin_main_start;

            if (ctx->direction == LF_DIR_ROW) {
                out[i].x = main_pos;
                out[i].y = cross_origin + cp;
                out[i].w = sizes[i];
                out[i].h = ic;
            } else {
                out[i].x = cross_origin + cp;
                out[i].y = main_pos;
                out[i].w = ic;
                out[i].h = sizes[i];
            }

            main_pos += sizes[i] + it->margin_main_end;
            if (i < end - 1) main_pos += gbw;
        }
    }

    free(sizes);
    free(lines);
}

#endif /* LAYOUT_FLEX_H */
