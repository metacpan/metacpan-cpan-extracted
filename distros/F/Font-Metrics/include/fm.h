#ifndef FM_H
#define FM_H

#include <stdint.h>

#define FM_STD14    0
#define FM_TRUETYPE 1
#define FM_N_STD14  14

typedef struct {
    int       type;
    int       std14_idx;

    /* TrueType fields — NULL for Std14 */
    uint16_t *adv_width;    /* glyph_id → advance width in design units */
    uint32_t *cmap_cp;      /* sorted codepoint array for binary search  */
    uint16_t *cmap_glyph;   /* parallel glyph id array                   */
    int       n_cmap;
    int       n_glyphs;
    int       units_per_em;
    int       tt_ascender;
    int       tt_descender;
    int       tt_cap_height;
    int       tt_x_height;

    /* Kerning */
    int       n_kern;
    uint32_t *kern_pairs;   /* packed (glyph1<<16|glyph2), sorted */
    int16_t  *kern_values;  /* parallel values in design units     */
} fm_font_t;

/* Std14 tables (defined in src/fm_std14.c) */
extern const int16_t *fm_std14_widths[FM_N_STD14]; /* pointer per font face */
extern const int     fm_std14_ascender[FM_N_STD14];
extern const int     fm_std14_descender[FM_N_STD14];
extern const int     fm_std14_cap_height[FM_N_STD14];
extern const int     fm_std14_x_height[FM_N_STD14];

/* Std14 kern pairs (defined in src/fm_std14.c, set in task 5) */
extern const int      fm_std14_n_kern[FM_N_STD14];
extern const uint32_t *fm_std14_kern_pairs[FM_N_STD14];
extern const int16_t  *fm_std14_kern_values[FM_N_STD14];

/* Std14 name → index, -1 if not found */
int  fm_std14_index(const char *name);
void fm_std14_init(void);

/* Per-glyph and string metrics (defined in src/fm_metrics.c) */
float    fm_char_width(const fm_font_t *fm, unsigned int codepoint, float size);
float    fm_string_width(const fm_font_t *fm, const char *text, float size);
uint32_t fm_utf8_decode(const char **pp);
float    fm_string_width_utf8(const fm_font_t *fm, const char *text, float size);
float fm_ascender(const fm_font_t *fm, float size);
float fm_descender(const fm_font_t *fm, float size);
float fm_cap_height(const fm_font_t *fm, float size);
float fm_x_height(const fm_font_t *fm, float size);
float fm_line_height(const fm_font_t *fm, float size);
float fm_kern_pair(const fm_font_t *fm, unsigned int cp1, unsigned int cp2, float size);

/* TrueType file loader (defined in src/fm_truetype.c) */
fm_font_t *fm_load_truetype(const char *path);
void       fm_free(fm_font_t *fm);

#endif /* FM_H */
