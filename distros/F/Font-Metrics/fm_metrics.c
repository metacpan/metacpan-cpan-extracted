#include "fm.h"
#include <string.h>
#include <stdlib.h>

static float fm_scale(const fm_font_t *fm, float size) {
    if (fm->type == FM_STD14)
        return size / 1000.0f;
    return (fm->units_per_em > 0) ? size / (float)fm->units_per_em : 0.0f;
}

/* Binary search: codepoint → glyph id, 0 if not found */
static uint16_t fm_cmap_lookup(const fm_font_t *fm, uint32_t cp) {
    int lo = 0, hi = fm->n_cmap - 1;
    while (lo <= hi) {
        int mid = (lo + hi) / 2;
        if (fm->cmap_cp[mid] == cp)  return fm->cmap_glyph[mid];
        if (fm->cmap_cp[mid] < cp)   lo = mid + 1;
        else                          hi = mid - 1;
    }
    return 0;
}

float fm_char_width(const fm_font_t *fm, unsigned int cp, float size) {
    if (!fm) return 0.0f;
    if (fm->type == FM_STD14) {
        if (cp > 255) return 0.0f;
        return (float)fm_std14_widths[fm->std14_idx][cp] * fm_scale(fm, size);
    }
    /* TrueType */
    {
        uint16_t glyph = fm_cmap_lookup(fm, (uint32_t)cp);
        uint16_t adv;
        if (!fm->adv_width || fm->n_glyphs == 0) return 0.0f;
        /* TrueType spec: glyphs beyond numberOfHMetrics reuse last entry */
        adv = (glyph < (uint16_t)fm->n_glyphs)
            ? fm->adv_width[glyph]
            : fm->adv_width[fm->n_glyphs - 1];
        return (float)adv * fm_scale(fm, size);
    }
}

float fm_string_width(const fm_font_t *fm, const char *text, float size) {
    float w = 0.0f;
    if (!fm || !text) return 0.0f;
    while (*text)
        w += fm_char_width(fm, (unsigned char)*text++, size);
    return w;
}

/* Decode one UTF-8 codepoint; advance *pp past it. Returns 0 at end of string. */
uint32_t
fm_utf8_decode(const char **pp)
{
    const unsigned char *p = (const unsigned char *)*pp;
    uint32_t cp;

    if (!*p) return 0;

    if (*p < 0x80) {
        cp = *p++;
    } else if (*p < 0xC2) {
        cp = 0xFFFD; p++;                               /* stray continuation / overlong */
    } else if (*p < 0xE0) {
        cp  = (uint32_t)(*p++ & 0x1F) << 6;
        if ((*p & 0xC0) == 0x80) cp |= *p++ & 0x3F;
    } else if (*p < 0xF0) {
        cp  = (uint32_t)(*p++ & 0x0F) << 12;
        if ((*p & 0xC0) == 0x80) { cp |= (uint32_t)(*p++ & 0x3F) << 6; }
        if ((*p & 0xC0) == 0x80) { cp |= *p++ & 0x3F; }
    } else {
        cp  = (uint32_t)(*p++ & 0x07) << 18;
        if ((*p & 0xC0) == 0x80) { cp |= (uint32_t)(*p++ & 0x3F) << 12; }
        if ((*p & 0xC0) == 0x80) { cp |= (uint32_t)(*p++ & 0x3F) <<  6; }
        if ((*p & 0xC0) == 0x80) { cp |= *p++ & 0x3F; }
    }

    *pp = (const char *)p;
    return cp;
}

float fm_string_width_utf8(const fm_font_t *fm, const char *text, float size) {
    float    w = 0.0f;
    uint32_t cp;
    if (!fm || !text) return 0.0f;
    while ((cp = fm_utf8_decode(&text)) != 0)
        w += fm_char_width(fm, (unsigned int)cp, size);
    return w;
}

float fm_ascender(const fm_font_t *fm, float size) {
    if (!fm) return 0.0f;
    if (fm->type == FM_STD14)
        return (float)fm_std14_ascender[fm->std14_idx] * fm_scale(fm, size);
    return (float)fm->tt_ascender * fm_scale(fm, size);
}

float fm_descender(const fm_font_t *fm, float size) {
    if (!fm) return 0.0f;
    if (fm->type == FM_STD14)
        return (float)fm_std14_descender[fm->std14_idx] * fm_scale(fm, size);
    return (float)fm->tt_descender * fm_scale(fm, size);
}

float fm_cap_height(const fm_font_t *fm, float size) {
    if (!fm) return 0.0f;
    if (fm->type == FM_STD14)
        return (float)fm_std14_cap_height[fm->std14_idx] * fm_scale(fm, size);
    return (float)fm->tt_cap_height * fm_scale(fm, size);
}

float fm_x_height(const fm_font_t *fm, float size) {
    if (!fm) return 0.0f;
    if (fm->type == FM_STD14)
        return (float)fm_std14_x_height[fm->std14_idx] * fm_scale(fm, size);
    return (float)fm->tt_x_height * fm_scale(fm, size);
}

float fm_line_height(const fm_font_t *fm, float size) {
    if (!fm) return size;
    return fm_ascender(fm, size) - fm_descender(fm, size);
}

float fm_kern_pair(const fm_font_t *fm, unsigned int cp1, unsigned int cp2, float size) {
    const uint32_t *pairs;
    const int16_t  *vals;
    int             n, lo, hi;
    uint32_t        key;
    uint16_t        g1, g2;

    if (!fm) return 0.0f;

    if (fm->type == FM_STD14) {
        pairs = fm_std14_kern_pairs[fm->std14_idx];
        vals  = fm_std14_kern_values[fm->std14_idx];
        n     = fm_std14_n_kern[fm->std14_idx];
        /* For Std14, kern pairs are indexed by character code packed as (cp1<<8|cp2) */
        key = (uint32_t)((cp1 << 8) | cp2);
    } else {
        pairs = fm->kern_pairs;
        vals  = fm->kern_values;
        n     = fm->n_kern;
        g1 = fm_cmap_lookup(fm, (uint32_t)cp1);
        g2 = fm_cmap_lookup(fm, (uint32_t)cp2);
        key = ((uint32_t)g1 << 16) | (uint32_t)g2;
    }

    if (!pairs || !vals || n == 0) return 0.0f;

    lo = 0; hi = n - 1;
    while (lo <= hi) {
        int mid = (lo + hi) / 2;
        if (pairs[mid] == key)  return (float)vals[mid] * fm_scale(fm, size);
        if (pairs[mid] < key)   lo = mid + 1;
        else                    hi = mid - 1;
    }
    return 0.0f;
}
