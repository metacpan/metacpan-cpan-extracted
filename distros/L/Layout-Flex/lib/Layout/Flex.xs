#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef WIN32
#  undef malloc
#  undef calloc
#  undef realloc
#  undef free
#endif

#include "flex.h"

/* Parse an align string into an LF_ALIGN_* constant, -1 if unrecognised */
static int lf_parse_align(const char *s) {
    if (!s) return -1;
    if (strEQ(s, "stretch"))  return LF_ALIGN_STRETCH;
    if (strEQ(s, "start"))    return LF_ALIGN_START;
    if (strEQ(s, "end"))      return LF_ALIGN_END;
    if (strEQ(s, "center"))   return LF_ALIGN_CENTER;
    return -1;
}

/* Fetch a float from a hashref field; no-op if key absent */
static void lf_hv_float(pTHX_ HV *hv, const char *key, I32 klen, float *dst) {
    SV **sv = hv_fetch(hv, key, klen, 0);
    if (sv && SvOK(*sv)) *dst = (float)SvNV(*sv);
}

/* Built-in proportional text measurement: 0.6em wide per char, 1.4em tall */
static void lf_measure_simple(const char *text, float font_size,
                               float *w, float *h) {
    size_t len = strlen(text);
    *w = (float)len * font_size * 0.6f;
    *h = font_size * 1.4f;
}

/* Built-in wrapped measurement: reflow text into avail_w, stack lines */
static void lf_measure_simple_wrapped(const char *text, float font_size,
                                       float avail_w, float *w, float *h) {
    float char_w  = font_size * 0.6f;
    float line_h  = font_size * 1.4f;
    size_t len    = strlen(text);
    int cpl       = (char_w > 0.0f && avail_w > 0.0f)
                  ? (int)(avail_w / char_w) : (int)len;
    if (cpl < 1) cpl = 1;
    int n_lines   = ((int)len + cpl - 1) / cpl;
    if (n_lines < 1) n_lines = 1;
    *w = avail_w;
    *h = (float)n_lines * line_h;
}

/* Call a Perl code-ref measure(hashref) → (w, h) */
static void lf_measure_cb(pTHX_ SV *cb, HV *item_hv, float *w, float *h) {
    dSP;
    int count;
    *w = 0.0f; *h = 0.0f;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newRV_inc((SV *)item_hv)));
    PUTBACK;
    count = call_sv(cb, G_ARRAY);
    SPAGAIN;
    if (count >= 2) { *h = (float)POPn; *w = (float)POPn; }
    else if (count == 1) { *w = (float)POPn; }
    PUTBACK;
    FREETMPS; LEAVE;
}

/* Call a Perl code-ref measure(hashref, avail_w) → (w, h) for wrapped text */
static void lf_measure_cb_wrapped(pTHX_ SV *cb, HV *item_hv,
                                   float avail_w, float *w, float *h) {
    dSP;
    int count;
    *w = avail_w; *h = 0.0f;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newRV_inc((SV *)item_hv)));
    XPUSHs(sv_2mortal(newSVnv((NV)avail_w)));
    PUTBACK;
    count = call_sv(cb, G_ARRAY);
    SPAGAIN;
    if (count >= 2) { *h = (float)POPn; *w = (float)POPn; }
    else if (count == 1) { *h = (float)POPn; }
    PUTBACK;
    FREETMPS; LEAVE;
}

MODULE = Layout::Flex  PACKAGE = Layout::Flex

PROTOTYPES: DISABLE

void
compute(class, ...)
    SV * class
    PPCODE:
    {
        lf_ctx_t  ctx;
        lf_item_t *lf_items = NULL;
        lf_rect_t *rects = NULL;
        AV        *items_av = NULL;
        SV        *measure_sv = NULL;
        int        i, n;

        PERL_UNUSED_VAR(class);

        /* ── defaults ── */
        ctx.main_size     = 0.0f;
        ctx.cross_size    = 0.0f;
        ctx.direction     = LF_DIR_ROW;
        ctx.justify       = LF_JUST_START;
        ctx.align_items   = LF_ALIGN_STRETCH;
        ctx.wrap          = LF_WRAP_NOWRAP;
        ctx.align_content = LF_ACONT_STRETCH;
        ctx.main_gap      = 0.0f;
        ctx.cross_gap     = 0.0f;
        ctx.items         = NULL;
        ctx.n_items       = 0;

        /* ── parse named args ── */
        for (i = 1; i + 1 < items; i += 2) {
            const char *key = SvPV_nolen(ST(i));
            SV         *val = ST(i + 1);

            if (strEQ(key, "main_size")) {
                ctx.main_size = (float)SvNV(val);
            } else if (strEQ(key, "cross_size")) {
                ctx.cross_size = (float)SvNV(val);
            } else if (strEQ(key, "direction")) {
                const char *d = SvPV_nolen(val);
                ctx.direction = strEQ(d, "column") ? LF_DIR_COLUMN : LF_DIR_ROW;
            } else if (strEQ(key, "justify")) {
                const char *j = SvPV_nolen(val);
                if      (strEQ(j, "end"))           ctx.justify = LF_JUST_END;
                else if (strEQ(j, "center"))        ctx.justify = LF_JUST_CENTER;
                else if (strEQ(j, "space-between")) ctx.justify = LF_JUST_SPACE_BETWEEN;
                else if (strEQ(j, "space-around"))  ctx.justify = LF_JUST_SPACE_AROUND;
                else if (strEQ(j, "space-evenly"))  ctx.justify = LF_JUST_SPACE_EVENLY;
                else                                ctx.justify = LF_JUST_START;
            } else if (strEQ(key, "align")) {
                int a = lf_parse_align(SvPV_nolen(val));
                ctx.align_items = (a >= 0) ? a : LF_ALIGN_STRETCH;
            } else if (strEQ(key, "wrap")) {
                const char *w = SvPV_nolen(val);
                if      (strEQ(w, "wrap"))         ctx.wrap = LF_WRAP_WRAP;
                else if (strEQ(w, "wrap-reverse")) ctx.wrap = LF_WRAP_REVERSE;
                else                               ctx.wrap = LF_WRAP_NOWRAP;
            } else if (strEQ(key, "align_content")) {
                const char *ac = SvPV_nolen(val);
                if      (strEQ(ac, "start"))          ctx.align_content = LF_ACONT_START;
                else if (strEQ(ac, "end"))            ctx.align_content = LF_ACONT_END;
                else if (strEQ(ac, "center"))         ctx.align_content = LF_ACONT_CENTER;
                else if (strEQ(ac, "space-between"))  ctx.align_content = LF_ACONT_SPACE_BETWEEN;
                else if (strEQ(ac, "space-around"))   ctx.align_content = LF_ACONT_SPACE_AROUND;
                else if (strEQ(ac, "space-evenly"))   ctx.align_content = LF_ACONT_SPACE_EVENLY;
                else                                  ctx.align_content = LF_ACONT_STRETCH;
            } else if (strEQ(key, "measure")) {
                /* code ref or the string 'simple' */
                if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVCV)
                    measure_sv = val;
                else if (SvOK(val))
                    measure_sv = val;   /* treat any non-ref as 'simple' */
            } else if (strEQ(key, "gap")) {
                ctx.main_gap = ctx.cross_gap = (float)SvNV(val);
            } else if (strEQ(key, "main_gap")) {
                ctx.main_gap  = (float)SvNV(val);
            } else if (strEQ(key, "cross_gap")) {
                ctx.cross_gap = (float)SvNV(val);
            } else if (strEQ(key, "items")) {
                if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV)
                    items_av = (AV *)SvRV(val);
            }
        }

        if (!items_av) XSRETURN(0);

        n = (int)(av_len(items_av) + 1);
        if (n <= 0) XSRETURN(0);

        lf_items = (lf_item_t *)calloc((size_t)n, sizeof(lf_item_t));
        rects    = (lf_rect_t *)calloc((size_t)n, sizeof(lf_rect_t));

        /* ── populate items from hashrefs ── */
        for (i = 0; i < n; i++) {
            SV **elem = av_fetch(items_av, (SSize_t)i, 0);
            HV  *hv;

            /* defaults */
            lf_items[i].basis             = 0.0f;
            lf_items[i].grow              = 0.0f;
            lf_items[i].shrink            = 1.0f;
            lf_items[i].min_main          = 0.0f;
            lf_items[i].max_main          = 0.0f;
            lf_items[i].min_cross         = 0.0f;
            lf_items[i].max_cross         = 0.0f;
            lf_items[i].cross             = 0.0f;
            lf_items[i].align_self        = -1;
            lf_items[i].margin_main_start  = 0.0f;
            lf_items[i].margin_main_end    = 0.0f;
            lf_items[i].margin_cross_start = 0.0f;
            lf_items[i].margin_cross_end   = 0.0f;

            if (!elem || !SvOK(*elem) || !SvROK(*elem)
                || SvTYPE(SvRV(*elem)) != SVt_PVHV)
                continue;

            hv = (HV *)SvRV(*elem);

            lf_hv_float(aTHX_ hv, "basis",     5,  &lf_items[i].basis);
            lf_hv_float(aTHX_ hv, "grow",      4,  &lf_items[i].grow);
            lf_hv_float(aTHX_ hv, "shrink",    6,  &lf_items[i].shrink);
            lf_hv_float(aTHX_ hv, "min_main",  8,  &lf_items[i].min_main);
            lf_hv_float(aTHX_ hv, "max_main",  8,  &lf_items[i].max_main);
            lf_hv_float(aTHX_ hv, "min_cross", 9,  &lf_items[i].min_cross);
            lf_hv_float(aTHX_ hv, "max_cross", 9,  &lf_items[i].max_cross);
            lf_hv_float(aTHX_ hv, "cross",     5,  &lf_items[i].cross);
            {
                SV **sv = hv_fetch(hv, "align_self", 10, 0);
                if (sv && SvOK(*sv))
                    lf_items[i].align_self = lf_parse_align(SvPV_nolen(*sv));
            }
            /* margins: read as top/right/bottom/left (CSS convention),
               then map to main/cross axes after all items are read     */
            {
                float mt = 0.0f, mr = 0.0f, mb = 0.0f, ml = 0.0f, mall = 0.0f;
                lf_hv_float(aTHX_ hv, "margin",        6,  &mall);
                mt = mr = mb = ml = mall;
                lf_hv_float(aTHX_ hv, "margin_top",    10, &mt);
                lf_hv_float(aTHX_ hv, "margin_right",  12, &mr);
                lf_hv_float(aTHX_ hv, "margin_bottom", 13, &mb);
                lf_hv_float(aTHX_ hv, "margin_left",   11, &ml);
                /* direction is already parsed; map T/R/B/L to main/cross */
                if (ctx.direction == LF_DIR_ROW) {
                    lf_items[i].margin_main_start  = ml;
                    lf_items[i].margin_main_end    = mr;
                    lf_items[i].margin_cross_start = mt;
                    lf_items[i].margin_cross_end   = mb;
                } else {
                    lf_items[i].margin_main_start  = mt;
                    lf_items[i].margin_main_end    = mb;
                    lf_items[i].margin_cross_start = ml;
                    lf_items[i].margin_cross_end   = mr;
                }
            }
            /* content-driven sizing: if item has 'text' and measure is set,
               derive basis/cross unless already explicitly provided          */
            if (measure_sv) {
                SV **text_sv = hv_fetch(hv, "text", 4, 0);
                if (text_sv && SvOK(*text_sv)) {
                    int no_basis = !hv_exists(hv, "basis", 5);
                    int no_cross = !hv_exists(hv, "cross", 5);
                    if (no_basis || no_cross) {
                        float tw = 0.0f, th = 0.0f;
                        if (SvROK(measure_sv)) {
                            lf_measure_cb(aTHX_ measure_sv, hv, &tw, &th);
                        } else {
                            float font_size = 12.0f;
                            lf_hv_float(aTHX_ hv, "font_size", 9, &font_size);
                            lf_measure_simple(SvPV_nolen(*text_sv),
                                              font_size, &tw, &th);
                        }
                        if (ctx.direction == LF_DIR_ROW) {
                            if (no_basis) lf_items[i].basis = tw;
                            if (no_cross) lf_items[i].cross = th;
                        } else {
                            if (no_basis) lf_items[i].basis = th;
                            if (no_cross) lf_items[i].cross = tw;
                        }
                    }
                }
            }
        }

        ctx.items   = lf_items;
        ctx.n_items = n;

        lf_compute(&ctx, rects);

        /* ── second pass: wrap text items ───────────────────────── */
        if (measure_sv) {
            int needs_recompute = 0;
            for (i = 0; i < n; i++) {
                SV **elem2 = av_fetch(items_av, (SSize_t)i, 0);
                HV  *hv2;
                SV **wt_sv, **text_sv2;
                float avail, tw, th, new_cross;

                if (!elem2 || !SvOK(*elem2) || !SvROK(*elem2)
                    || SvTYPE(SvRV(*elem2)) != SVt_PVHV) continue;
                hv2 = (HV *)SvRV(*elem2);

                wt_sv = hv_fetch(hv2, "wrap_text", 9, 0);
                if (!wt_sv || !SvOK(*wt_sv) || !SvTRUE(*wt_sv)) continue;

                text_sv2 = hv_fetch(hv2, "text", 4, 0);
                if (!text_sv2 || !SvOK(*text_sv2)) continue;

                avail = (ctx.direction == LF_DIR_ROW) ? rects[i].w : rects[i].h;
                tw = 0.0f; th = 0.0f;

                if (SvROK(measure_sv)) {
                    lf_measure_cb_wrapped(aTHX_ measure_sv, hv2, avail, &tw, &th);
                } else {
                    float font_size = 12.0f;
                    lf_hv_float(aTHX_ hv2, "font_size", 9, &font_size);
                    lf_measure_simple_wrapped(SvPV_nolen(*text_sv2),
                                              font_size, avail, &tw, &th);
                }

                new_cross = (ctx.direction == LF_DIR_ROW) ? th : tw;
                if (new_cross != lf_items[i].cross) {
                    lf_items[i].cross = new_cross;
                    needs_recompute   = 1;
                }
            }
            if (needs_recompute) lf_compute(&ctx, rects);
        }

        EXTEND(SP, n);
        for (i = 0; i < n; i++) {
            AV *rect = newAV();
            av_push(rect, newSVnv((NV)rects[i].x));
            av_push(rect, newSVnv((NV)rects[i].y));
            av_push(rect, newSVnv((NV)rects[i].w));
            av_push(rect, newSVnv((NV)rects[i].h));
            PUSHs(sv_2mortal(newRV_noinc((SV *)rect)));
        }

        free(lf_items);
        free(rects);
    }
