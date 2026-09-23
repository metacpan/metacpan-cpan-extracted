/*
 * Minimal Skia C wrapper for Perl FFI::Platypus
 * Provides: surface creation, path drawing, color fill, pixel access
 */
#include "core/SkSurface.h"
#include "core/SkCanvas.h"
#include "core/SkPaint.h"
#include "core/SkPath.h"
#include "core/SkPathBuilder.h"
#include "core/SkColor.h"
#include <cstdint>
#include <cstring>

extern "C" {

struct SkiaCtx {
    sk_sp<SkSurface> surface;
    SkCanvas *canvas;
    SkPaint paint;
    SkPathBuilder pathb;
    int width, height;
};

SkiaCtx *skia_create(int w, int h) {
    auto ctx = new SkiaCtx;
    ctx->width = w;
    ctx->height = h;
    auto info = SkImageInfo::MakeN32Premul(w, h);
    ctx->surface = SkSurfaces::Raster(info);
    ctx->canvas = ctx->surface->getCanvas();
    ctx->paint.setAntiAlias(true);
    return ctx;
}

void skia_destroy(SkiaCtx *ctx) { delete ctx; }

void skia_clear(SkiaCtx *ctx, uint32_t color) {
    ctx->canvas->clear(color);
}

void skia_set_color(SkiaCtx *ctx, uint8_t r, uint8_t g, uint8_t b, uint8_t a) {
    ctx->paint.setColor(SkColorSetARGB(a, r, g, b));
}

void skia_set_stroke(SkiaCtx *ctx, float width) {
    ctx->paint.setStyle(SkPaint::kStroke_Style);
    ctx->paint.setStrokeWidth(width);
}

void skia_set_fill(SkiaCtx *ctx) {
    ctx->paint.setStyle(SkPaint::kFill_Style);
}

void skia_path_reset(SkiaCtx *ctx) { ctx->pathb.reset(); }
void skia_path_move(SkiaCtx *ctx, float x, float y) { ctx->pathb.moveTo(x, y); }
void skia_path_line(SkiaCtx *ctx, float x, float y) { ctx->pathb.lineTo(x, y); }
void skia_path_close(SkiaCtx *ctx) { ctx->pathb.close(); }

void skia_draw_path(SkiaCtx *ctx) {
    ctx->canvas->drawPath(ctx->pathb.detach(), ctx->paint);
}

void skia_draw_line(SkiaCtx *ctx, float x0, float y0, float x1, float y1) {
    ctx->canvas->drawLine(x0, y0, x1, y1, ctx->paint);
}

void skia_draw_circle(SkiaCtx *ctx, float cx, float cy, float r) {
    ctx->canvas->drawCircle(cx, cy, r, ctx->paint);
}

void skia_draw_rect(SkiaCtx *ctx, float x, float y, float w, float h) {
    ctx->canvas->drawRect(SkRect::MakeXYWH(x, y, w, h), ctx->paint);
}

/* Copy pixel data to output buffer (RGBA premultiplied -> RGB) */
int skia_get_pixels(SkiaCtx *ctx, uint8_t *out, int out_stride) {
    auto img = ctx->surface->makeImageSnapshot();
    if (!img) return 0;
    SkPixmap pm;
    if (!img->peekPixels(&pm)) return 0;
    for (int y = 0; y < ctx->height; y++) {
        const uint32_t *src = (const uint32_t *)pm.addr32(0, y);
        uint8_t *dst = out + y * out_stride;
        for (int x = 0; x < ctx->width; x++) {
            uint32_t c = src[x];
            /* BGRA -> RGB (Skia native is BGRA on little-endian) */
            dst[x*3+0] = (c >> 16) & 0xFF;
            dst[x*3+1] = (c >> 8) & 0xFF;
            dst[x*3+2] = c & 0xFF;
        }
    }
    return 1;
}

int skia_get_width(SkiaCtx *ctx) { return ctx->width; }
int skia_get_height(SkiaCtx *ctx) { return ctx->height; }

} /* extern "C" */
