/* Perl binding for the FreeType font rendering library.
 *
 * Copyright 2004, Geoff Richards.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the same terms as Perl itself.
 */

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <ft2build.h>
#include FT_SFNT_NAMES_H
#include FT_FREETYPE_H
#include FT_GLYPH_H
#include FT_OUTLINE_H
#include FT_BBOX_H
#include FT_TYPE1_TABLES_H

#undef assert
#include <assert.h>

/* utf8_to_uvchr is deprecated in 5.16, but
 * utf8_to_uvchr_buf is not available before 5.16
 * If I need to get fancier, I should look at Dumper.xs
 * in Data::Dumper
 */
#if PERL_VERSION <= 15 && ! defined(utf8_to_uvchr_buf)
#define utf8_to_uvchr_buf(s, send, p_length) (utf8_to_uvchr(s, p_length))
#endif

/* Macro for testing whether we have at least a certain version of
 * Freetype available.  */
#define QEFFT2_FT_AT_LEAST(major, minor, patch) \
    FREETYPE_MAJOR > major || \
        (FREETYPE_MAJOR == major && \
            (FREETYPE_MINOR > minor || \
                (FREETYPE_MINOR == minor && FREETYPE_PATCH >= patch)))

/* Define the newer names for constants in terms of the old names if we're
 * compiling against an old version of the library.  These uppercase
 * constants, which are defined in enums, were added in Freetype 2.1.3.  */
#if !(QEFFT2_FT_AT_LEAST(2,1,3))
#define FT_GLYPH_FORMAT_NONE ft_glyph_format_none
#define FT_GLYPH_FORMAT_COMPOSITE ft_glyph_format_composite
#define FT_GLYPH_FORMAT_BITMAP ft_glyph_format_bitmap
#define FT_GLYPH_FORMAT_OUTLINE ft_glyph_format_outline
#define FT_GLYPH_FORMAT_PLOTTER ft_glyph_format_plotter
#define FT_RENDER_MODE_NORMAL ft_render_mode_normal
#define FT_RENDER_MODE_MONO ft_render_mode_mono
#define FT_PIXEL_MODE_NONE ft_pixel_mode_none
#define FT_PIXEL_MODE_MONO ft_pixel_mode_mono
#define FT_PIXEL_MODE_GRAY ft_pixel_mode_grays
#define FT_PIXEL_MODE_GRAY2 ft_pixel_mode_pal2
#define FT_PIXEL_MODE_GRAY4 ft_pixel_mode_pal4
#define FT_KERNING_DEFAULT ft_kerning_default
#define FT_KERNING_UNFITTED ft_kerning_unfitted
#define FT_KERNING_UNSCALED ft_kerning_unscaled
#endif

#define QEF_BUF_SZ 256

/* Scary macrology follows, stolen from fterrors.h
 * This stuff sets up a table mapping error codes to descriptive strings.
 * I find the whole idea of 'callback macros' rather distasteful though.
 */
#undef __FTERRORS_H__
#define FT_ERRORDEF( e, v, s )  { e, s },
#define FT_ERROR_START_LIST {
#define FT_ERROR_END_LIST { 0, 0 } };
struct QefFT2_Errstr_
{
  int num;
  const char *message;
};
typedef struct QefFT2_Errstr_ QefFT2_Errstr;
QefFT2_Errstr qefft2_errstr[] = /* rest filled in by the header */
#include FT_ERRORS_H

#define ftnum_to_nv(num) newSVnv((double) (num) / 1.0)

struct QefFT2_Glyph_
{
    SV *face_sv;
    FT_ULong char_code;     /* 0 if not yet known */
    bool has_char_code;
    FT_UInt index;
    char *name;
};
struct QefFT2_Face_Extra_
{
    SV *library_sv;
    FT_UInt loaded_glyph_idx;
    FT_Int32 glyph_load_flags;
    FT_Glyph glyph_ft;
    int slot_valid;
};
typedef struct QefFT2_Face_Extra_ QefFT2_Face_Extra;

struct QefFT2_Outline_Decompose_Extra_
{
    SV *move_to;
    SV *line_to;
    SV *conic_to;
    SV *cubic_to;
    double curx, cury;
};

typedef FT_Library Font_FreeType;
typedef FT_Face Font_FreeType_Face;
typedef FT_CharMap Font_FreeType_CharMap;
typedef FT_BBox* Font_FreeType_BoundingBox;
typedef FT_SfntName* Font_FreeType_NamedInfo;
typedef struct QefFT2_Glyph_ * Font_FreeType_Glyph;


/* Table of FreeType constants, for exporting into Perl.  */
#define QEFFT2_CONSTANT(symbol) { #symbol, symbol },
struct QefFT2_Uv_Const_
{
    char *name;
    UV value;
};
typedef struct QefFT2_Uv_Const_ QefFT2_Uv_Const;
const static QefFT2_Uv_Const qefft2_uv_const[] =
{
    QEFFT2_CONSTANT(FT_LOAD_DEFAULT)
    QEFFT2_CONSTANT(FT_LOAD_NO_SCALE)
    QEFFT2_CONSTANT(FT_LOAD_NO_HINTING)
    QEFFT2_CONSTANT(FT_LOAD_NO_BITMAP)
    QEFFT2_CONSTANT(FT_LOAD_VERTICAL_LAYOUT)
    QEFFT2_CONSTANT(FT_LOAD_FORCE_AUTOHINT)
    QEFFT2_CONSTANT(FT_LOAD_CROP_BITMAP)
    QEFFT2_CONSTANT(FT_LOAD_PEDANTIC)
    QEFFT2_CONSTANT(FT_LOAD_IGNORE_GLOBAL_ADVANCE_WIDTH)
    /* FT_LOAD_NO_RECURSE - for internal use only*/
    QEFFT2_CONSTANT(FT_LOAD_IGNORE_TRANSFORM)
    QEFFT2_CONSTANT(FT_LOAD_LINEAR_DESIGN)
#if QEFFT2_FT_AT_LEAST(2,1,3)
    QEFFT2_CONSTANT(FT_LOAD_NO_AUTOHINT)
#endif
#if QEFFT2_FT_AT_LEAST(2,6,1)
    QEFFT2_CONSTANT(FT_LOAD_COMPUTE_METRICS)
#endif
    QEFFT2_CONSTANT(FT_RENDER_MODE_NORMAL)
#if QEFFT2_FT_AT_LEAST(2,1,4)
    QEFFT2_CONSTANT(FT_RENDER_MODE_LIGHT)
#endif
    QEFFT2_CONSTANT(FT_RENDER_MODE_MONO)
#if QEFFT2_FT_AT_LEAST(2,1,3)
    QEFFT2_CONSTANT(FT_RENDER_MODE_LCD)
    QEFFT2_CONSTANT(FT_RENDER_MODE_LCD_V)
#endif
    QEFFT2_CONSTANT(FT_KERNING_DEFAULT)
    QEFFT2_CONSTANT(FT_KERNING_UNFITTED)
    QEFFT2_CONSTANT(FT_KERNING_UNSCALED)

    QEFFT2_CONSTANT(FT_ENCODING_NONE)
    QEFFT2_CONSTANT(FT_ENCODING_UNICODE)
    QEFFT2_CONSTANT(FT_ENCODING_MS_SYMBOL)
    QEFFT2_CONSTANT(FT_ENCODING_SJIS)
    QEFFT2_CONSTANT(FT_ENCODING_GB2312)
    QEFFT2_CONSTANT(FT_ENCODING_BIG5)
    QEFFT2_CONSTANT(FT_ENCODING_WANSUNG)
    QEFFT2_CONSTANT(FT_ENCODING_JOHAB)
    QEFFT2_CONSTANT(FT_ENCODING_ADOBE_LATIN_1)
    QEFFT2_CONSTANT(FT_ENCODING_ADOBE_STANDARD)
    QEFFT2_CONSTANT(FT_ENCODING_ADOBE_EXPERT)
    QEFFT2_CONSTANT(FT_ENCODING_ADOBE_CUSTOM)
    QEFFT2_CONSTANT(FT_ENCODING_APPLE_ROMAN)
    QEFFT2_CONSTANT(FT_ENCODING_OLD_LATIN_2)
    QEFFT2_CONSTANT(FT_ENCODING_MS_SJIS)
    QEFFT2_CONSTANT(FT_ENCODING_MS_GB2312)
    QEFFT2_CONSTANT(FT_ENCODING_MS_BIG5)
    QEFFT2_CONSTANT(FT_ENCODING_MS_WANSUNG)
    QEFFT2_CONSTANT(FT_ENCODING_MS_JOHAB)
};

static void
errchk (FT_Error err, const char *desc)
{
    QefFT2_Errstr *errmap;

    if (err == 0)
        return;

    errmap = qefft2_errstr;
    while (errmap->message) {
        if (errmap->num == err) {
            croak("error %s: %s", desc, errmap->message);
        }
        ++errmap;
    }

    croak("error %s: unknown error code", desc);
}

static SV *
make_glyph (SV *face_sv, FT_ULong char_code, bool has_cc, FT_UInt index)
{
    Font_FreeType_Glyph glyph;
    SV *sv;
    Newx(glyph, 1, struct QefFT2_Glyph_);

    glyph->face_sv = face_sv;
    SvREFCNT_inc(face_sv);

    glyph->char_code = char_code;
    glyph->has_char_code = has_cc;
    glyph->index = index;
    glyph->name = 0;

    sv = newSV(0);
    sv_setref_pv(sv, "Font::FreeType::Glyph", (void *) glyph);
    return sv;
}

static FT_GlyphSlot
ensure_glyph_loaded (FT_Face face, Font_FreeType_Glyph glyph)
{
    QefFT2_Face_Extra *extra = face->generic.data;

    if (extra->loaded_glyph_idx != glyph->index || !extra->slot_valid) {
        if (extra->glyph_ft) {
            FT_Done_Glyph(extra->glyph_ft);
            extra->glyph_ft = 0;
        }
        errchk(FT_Load_Glyph(face, glyph->index, extra->glyph_load_flags),
               "loading freetype glyph");
        extra->loaded_glyph_idx = glyph->index;
        extra->slot_valid = 1;
    }

    return face->glyph;
}

static bool
ensure_outline_loaded (FT_Face face, Font_FreeType_Glyph glyph)
{
    QefFT2_Face_Extra *extra;
    ensure_glyph_loaded(face, glyph);

    extra = face->generic.data;
    if (!extra->glyph_ft)
        errchk(FT_Get_Glyph(face->glyph, &extra->glyph_ft),
               "getting glyph object from freetype");

    return extra->glyph_ft->format == FT_GLYPH_FORMAT_OUTLINE;
}

/* Macros to help the outline event handlers call Perl code */
#define QEFFT2_CALL_PREP  dSP; ENTER; SAVETMPS; PUSHMARK(SP);
#define QEFFT2_NUM(num)  ((double) (num) / 64.0)
#define QEFFT2_PUSH_NUM(num)  XPUSHs(sv_2mortal(newSVnv((double) num / 64.0)));
#define QEFFT2_PUSH_DNUM(num)  XPUSHs(sv_2mortal(newSVnv(num)));
#define QEFFT2_CALL(code)  PUTBACK; call_sv(code, G_DISCARD);
#define QEFFT2_CALL_TIDY  FREETMPS; LEAVE;

static int
handle_move_to (const FT_Vector *to, void *data)
{
    struct QefFT2_Outline_Decompose_Extra_ *extra = data;
    double x = QEFFT2_NUM(to->x), y = QEFFT2_NUM(to->y);

    QEFFT2_CALL_PREP
    QEFFT2_PUSH_DNUM(x)
    QEFFT2_PUSH_DNUM(y)
    QEFFT2_CALL(extra->move_to)
    QEFFT2_CALL_TIDY

    extra->curx = x;
    extra->cury = y;
    return 0;
}

static int
handle_line_to (const FT_Vector *to, void *data)
{
    struct QefFT2_Outline_Decompose_Extra_ *extra = data;
    double x = QEFFT2_NUM(to->x), y = QEFFT2_NUM(to->y);

    QEFFT2_CALL_PREP
    QEFFT2_PUSH_DNUM(x)
    QEFFT2_PUSH_DNUM(y)
    QEFFT2_CALL(extra->line_to)
    QEFFT2_CALL_TIDY

    extra->curx = x;
    extra->cury = y;
    return 0;
}

static int
handle_conic_to (const FT_Vector *control, const FT_Vector *to, void *data)
{
    struct QefFT2_Outline_Decompose_Extra_ *extra = data;
    double x = QEFFT2_NUM(to->x), y = QEFFT2_NUM(to->y);
    double cx = QEFFT2_NUM(control->x), cy = QEFFT2_NUM(control->y);

    QEFFT2_CALL_PREP
    QEFFT2_PUSH_DNUM(x)
    QEFFT2_PUSH_DNUM(y)

    /* If there's no conic callback, simulate an equivalent cubic one */
    if (extra->conic_to) {
        QEFFT2_PUSH_DNUM(cx)
        QEFFT2_PUSH_DNUM(cy)
        QEFFT2_CALL(extra->conic_to)
    }
    else {
        QEFFT2_PUSH_DNUM((extra->curx + 2 * cx) / 3)
        QEFFT2_PUSH_DNUM((extra->cury + 2 * cy) / 3)
        QEFFT2_PUSH_DNUM((2 * cx + x) / 3)
        QEFFT2_PUSH_DNUM((2 * cy + y) / 3)
        QEFFT2_CALL(extra->cubic_to)
    }

    QEFFT2_CALL_TIDY

    extra->curx = x;
    extra->cury = y;
    return 0;
}

static int
handle_cubic_to (const FT_Vector *control1, const FT_Vector *control2, const FT_Vector *to,
                 void *data)
{
    struct QefFT2_Outline_Decompose_Extra_ *extra = data;
    double x = QEFFT2_NUM(to->x), y = QEFFT2_NUM(to->y);

    QEFFT2_CALL_PREP
    QEFFT2_PUSH_DNUM(x)
    QEFFT2_PUSH_DNUM(y)
    QEFFT2_PUSH_NUM(control1->x)
    QEFFT2_PUSH_NUM(control1->y)
    QEFFT2_PUSH_NUM(control2->x)
    QEFFT2_PUSH_NUM(control2->y)
    QEFFT2_CALL(extra->cubic_to)
    QEFFT2_CALL_TIDY

    extra->curx = x;
    extra->cury = y;
    return 0;
}

MODULE = Font::FreeType   PACKAGE = Font::FreeType   PREFIX = qefft2_library_

PROTOTYPES: DISABLE


void
qefft2_import (const char *target_pkg)
    PREINIT:
        HV *stash;
        size_t i;
    PPCODE:
        stash = gv_stashpv(target_pkg, 0);
        if (!stash)
            croak("the package I'm importing into doesn't seem to exist");
        for (i = 0; i < sizeof(qefft2_uv_const) / sizeof(QefFT2_Uv_Const); ++i) {
            const char* name = qefft2_uv_const[i].name;
            if ( !hv_exists(stash, name, strlen(name)) )
                 newCONSTSUB(stash, name,  newSVuv(qefft2_uv_const[i].value));
        }


Font_FreeType
qefft2_library_new (void)
    CODE:
        errchk(FT_Init_FreeType(&RETVAL),
               "opening freetype library");
    OUTPUT:
        RETVAL


void
qefft2_library_DESTROY (Font_FreeType library)
    CODE:
        if (FT_Done_FreeType(library))
            warn("error closing freetype library");


void
qefft2_library_version (Font_FreeType library)
    PREINIT:
        FT_Int major, minor, patch;
    PPCODE:
        major = minor = patch = -1;
        FT_Library_Version(library, &major, &minor, &patch);
        assert(major != -1);
        assert(minor != -1);
        assert(patch != -1);
        if (GIMME_V != G_ARRAY)
            PUSHs(sv_2mortal(newSVpvf("%d.%d.%d",
                                      (int) major, (int) minor, (int) patch)));
        else {
            EXTEND(SP, 3);
            PUSHs(sv_2mortal(newSViv(major)));
            PUSHs(sv_2mortal(newSViv(minor)));
            PUSHs(sv_2mortal(newSViv(patch)));
        }


Font_FreeType_Face
qefft2_face (Font_FreeType library, const char *filename, int faceidx, FT_Int32 glyph_load_flags)
    PREINIT:
        SV *library_sv;
        QefFT2_Face_Extra *extra;
    CODE:
        errchk(FT_New_Face(library, filename, faceidx, &RETVAL),
               "opening font face");
        library_sv = SvRV(ST(0));
        SvREFCNT_inc(library_sv);
        Newx(extra, 1, QefFT2_Face_Extra);
        extra->library_sv = library_sv;
        extra->loaded_glyph_idx = 0;
        extra->slot_valid = 0;
        extra->glyph_load_flags = glyph_load_flags;
        extra->glyph_ft = 0;
        RETVAL->generic.data = (void *) extra;
        /*
        set active charmap if we don't have one;  caused by regression:
        https://git.savannah.gnu.org/cgit/freetype/freetype2.git/commit/?id=79e3789f81e14266578e71196ce71ecf5381d142
        http://lists.nongnu.org/archive/html/freetype/2017-10/msg00006.html
        */
#if (QEFFT2_FT_AT_LEAST(2,8,1))
        if (!RETVAL->charmap && RETVAL->num_charmaps) {
            RETVAL->charmap = RETVAL->charmaps[0];
        }
#endif

    OUTPUT:
        RETVAL


MODULE = Font::FreeType   PACKAGE = Font::FreeType::Face   PREFIX = qefft2_face_


FT_Int32
qefft2_face_load_flags (Font_FreeType_Face face, FT_Int32 val = NO_INIT )
    PREINIT:
        QefFT2_Face_Extra *extra;
    CODE:
        extra = face->generic.data;
        if( items > 1 )
        {
            extra->slot_valid = 0;
            extra->glyph_load_flags = val;
        }
        RETVAL = extra->glyph_load_flags;
    OUTPUT:
        RETVAL


void
qefft2_face_DESTROY (Font_FreeType_Face face)
    PREINIT:
        QefFT2_Face_Extra *extra;
    CODE:
        assert(face->generic.data);
        extra = face->generic.data;
        if (FT_Done_Face(face))
            warn("error destroying freetype face");
        SvREFCNT_dec(extra->library_sv);
        Safefree(extra);


long
qefft2_face_number_of_faces (Font_FreeType_Face face)
    CODE:
        RETVAL = face->num_faces;
    OUTPUT:
        RETVAL


long
qefft2_face_current_face_index (Font_FreeType_Face face)
    CODE:
        RETVAL = face->face_index;
    OUTPUT:
        RETVAL


SV *
qefft2_face_postscript_name (Font_FreeType_Face face)
    PREINIT:
        const char *ps_name;
    CODE:
        ps_name = FT_Get_Postscript_Name(face);
        if (ps_name)
            RETVAL = newSVpv(ps_name, 0);
        else
            RETVAL = &PL_sv_undef;
    OUTPUT:
        RETVAL


const char *
qefft2_face_family_name (Font_FreeType_Face face)
    CODE:
        RETVAL = face->family_name;
    OUTPUT:
        RETVAL


SV *
qefft2_face_style_name (Font_FreeType_Face face)
    CODE:
        if (face->style_name)
            RETVAL = newSVpv(face->style_name, 0);
        else
            RETVAL = &PL_sv_undef;
    OUTPUT:
        RETVAL


bool
qefft2_face_is_scalable (Font_FreeType_Face face)
    CODE:
        RETVAL = FT_IS_SCALABLE(face) ? 1 : 0;
    OUTPUT:
        RETVAL


bool
qefft2_face_is_fixed_width (Font_FreeType_Face face)
    CODE:
        RETVAL = FT_IS_FIXED_WIDTH(face) ? 1 : 0;
    OUTPUT:
        RETVAL


bool
qefft2_face_is_sfnt (Font_FreeType_Face face)
    CODE:
        RETVAL = FT_IS_SFNT(face) ? 1 : 0;
    OUTPUT:
        RETVAL


bool
qefft2_face_has_horizontal_metrics (Font_FreeType_Face face)
    CODE:
        RETVAL = FT_HAS_HORIZONTAL(face) ? 1 : 0;
    OUTPUT:
        RETVAL


bool
qefft2_face_has_vertical_metrics (Font_FreeType_Face face)
    CODE:
        RETVAL = FT_HAS_VERTICAL(face) ? 1 : 0;
    OUTPUT:
        RETVAL


bool
qefft2_face_has_kerning (Font_FreeType_Face face)
    CODE:
        RETVAL = FT_HAS_KERNING(face) ? 1 : 0;
    OUTPUT:
        RETVAL


bool
qefft2_face_has_glyph_names (Font_FreeType_Face face)
    CODE:
        RETVAL = FT_HAS_GLYPH_NAMES(face) ? 1 : 0;
    OUTPUT:
        RETVAL


bool
qefft2_face_has_reliable_glyph_names (Font_FreeType_Face face)
    CODE:
        /* The FT_Has_PS_Glyph_Names function was added in version 2.1.1.  */
#if QEFFT2_FT_AT_LEAST(2,1,1)
        RETVAL = FT_HAS_GLYPH_NAMES(face) && FT_Has_PS_Glyph_Names(face);
#else
        RETVAL = 0;
#endif
    OUTPUT:
        RETVAL


bool
qefft2_face_is_italic (Font_FreeType_Face face)
    CODE:
        RETVAL = face->style_flags & FT_STYLE_FLAG_ITALIC ? 1 : 0;
    OUTPUT:
        RETVAL


bool
qefft2_face_is_bold (Font_FreeType_Face face)
    CODE:
        RETVAL = face->style_flags & FT_STYLE_FLAG_BOLD ? 1 : 0;
    OUTPUT:
        RETVAL


long
qefft2_face_number_of_glyphs (Font_FreeType_Face face)
    CODE:
        RETVAL = face->num_glyphs;
    OUTPUT:
        RETVAL


SV *
qefft2_face_units_per_em (Font_FreeType_Face face)
    CODE:
        RETVAL = FT_IS_SCALABLE(face) ? newSVuv((UV) face->units_per_EM)
                                      : &PL_sv_undef;
    OUTPUT:
        RETVAL


void
qefft2_face_attach_file (Font_FreeType_Face face, const char *filename)
    CODE:
        errchk(FT_Attach_File(face, filename),
               "attaching file to freetype face");


void
qefft2_face_set_char_size (Font_FreeType_Face face, FT_F26Dot6 width, FT_F26Dot6 height, FT_UInt x_res, FT_UInt y_res)
    CODE:
        errchk(FT_Set_Char_Size(face, width, height, x_res, y_res),
               "setting char size of freetype face");
        ((QefFT2_Face_Extra *) face->generic.data)->slot_valid = 0;


void
qefft2_face_set_pixel_size (Font_FreeType_Face face, FT_UInt width, FT_UInt height)
    CODE:
        errchk(FT_Set_Pixel_Sizes(face, width, height),
               "setting pixel size of freetype face");
        ((QefFT2_Face_Extra *) face->generic.data)->slot_valid = 0;


SV *
qefft2_face_height (Font_FreeType_Face face)
    CODE:
        RETVAL = FT_IS_SCALABLE(face) ? newSViv(face->height)
                                      : &PL_sv_undef;
    OUTPUT:
        RETVAL


void
qefft2_face_fixed_sizes (Font_FreeType_Face face)
    PREINIT:
        int i;
        FT_Bitmap_Size *size;
        HV *hash;
        double pt = 0.0, ppem;
    PPCODE:
        if (GIMME_V != G_ARRAY) {
            PUSHs(sv_2mortal(newSViv((int) face->num_fixed_sizes)));
        }
        else {
            EXTEND(SP, face->num_fixed_sizes);
            for (i = 0; i < face->num_fixed_sizes; ++i) {
                size = &face->available_sizes[i];
                hash = newHV();
                if (size->height)
                    hv_store(hash, "height", 6, newSVuv(size->height), 0);
                if (size->width)
                    hv_store(hash, "width", 5, newSVuv(size->width), 0);
                /* The 'size', 'x_ppem', and 'y_ppem' fields were only added
                 * to the FT_Bitmap_Size structure in version 2.1.5.  */
#if QEFFT2_FT_AT_LEAST(2,1,5)
                if (size->size) {
                    pt = size->size / 64.0;
                    hv_store(hash, "size", 4, newSVnv(pt), 0);
                }
                if (size->x_ppem) {
                    ppem = size->x_ppem / 64.0;
                    hv_store(hash, "x_res_ppem", 10, newSVnv(ppem), 0);
                    if (size->size)
                        hv_store(hash, "x_res_dpi", 9,
                                 newSVnv((72 * ppem) / pt), 0);
                }
                if (size->y_ppem) {
                    ppem = size->y_ppem / 64.0;
                    hv_store(hash, "y_res_ppem", 10, newSVnv(ppem), 0);
                    if (size->size)
                        hv_store(hash, "y_res_dpi", 9,
                                 newSVnv((72 * ppem) / pt), 0);
                }
#endif
                PUSHs(sv_2mortal(newRV_inc((SV *) hash)));
            }
        }


SV *
qefft2_face_ascender (Font_FreeType_Face face)
    CODE:
        RETVAL = FT_IS_SCALABLE(face) ? newSViv(face->ascender)
                                      : &PL_sv_undef;
    OUTPUT:
        RETVAL


SV *
qefft2_face_descender (Font_FreeType_Face face)
    CODE:
        RETVAL = FT_IS_SCALABLE(face) ? newSViv(face->descender)
                                      : &PL_sv_undef;
    OUTPUT:
        RETVAL


SV *
qefft2_face_underline_position (Font_FreeType_Face face)
    CODE:
        /* TODO - can I get this in scaled coords? */
        RETVAL = FT_IS_SCALABLE(face) ? newSViv(face->underline_position)
                                      : &PL_sv_undef;
    OUTPUT:
        RETVAL


SV *
qefft2_face_underline_thickness (Font_FreeType_Face face)
    CODE:
        /* TODO - can I get this in scaled coords? */
        RETVAL = FT_IS_SCALABLE(face) ? newSViv(face->underline_thickness)
                                      : &PL_sv_undef;
    OUTPUT:
        RETVAL


Font_FreeType_CharMap
qefft2_face_charmap (Font_FreeType_Face face)
    CODE:
        RETVAL = face->charmap;
    OUTPUT:
        RETVAL

AV *
qefft2_face_charmaps (Font_FreeType_Face face)
    PREINIT:
        AV* array;
        int i;
        Font_FreeType_CharMap* ptr;
    CODE:
        array = newAV();
        ptr = face->charmaps;
        for(i = 0; i < face->num_charmaps; i++) {
            SV *sv = newSV(0);
            sv_setref_pv(sv, "Font::FreeType::CharMap", (void *) *ptr++);
            av_push(array, sv);
        }
        RETVAL = array;
    OUTPUT:
        RETVAL

Font_FreeType_BoundingBox
qefft2_face_bounding_box (Font_FreeType_Face face)
    CODE:
        if (!FT_IS_SCALABLE(face)) {
            XSRETURN_UNDEF;
        } else {
            RETVAL = &face->bbox;
        }
    OUTPUT:
        RETVAL

AV*
qefft2_face_namedinfos (Font_FreeType_Face face)
    PREINIT:
        AV* array;
        int i;
    CODE:
        if (!FT_IS_SCALABLE(face)) {
            XSRETURN_UNDEF;
        } else {
            array = newAV();
            int count = FT_Get_Sfnt_Name_Count(face);
            for(i = 0; i < count; i++) {
                SV *sv = newSV(0);
                FT_SfntName* sfnt;
                Newx(sfnt, 1, FT_SfntName);
                errchk(FT_Get_Sfnt_Name(face, i, sfnt),
                       "loading sfnt structure");
                sv_setref_pv(sv, "Font::FreeType::NamedInfo", (void *) sfnt);
                av_push(array, sv);
            }
            RETVAL = array;
        }
    OUTPUT:
        RETVAL

void
qefft2_face_kerning (Font_FreeType_Face face, FT_UInt left_glyph_idx, FT_UInt right_glyph_idx, UV kern_mode = FT_KERNING_DEFAULT)
    PREINIT:
        FT_Vector kerning;
    PPCODE:
        errchk(FT_Get_Kerning(face, left_glyph_idx, right_glyph_idx, kern_mode,
                              &kerning),
               "getting kerning from freetype face");
        if (GIMME_V != G_ARRAY) {
            PUSHs(sv_2mortal(newSVnv((double) kerning.x / 64.0)));
        }
        else {
            EXTEND(SP, 2);
            PUSHs(sv_2mortal(newSVnv((double) kerning.x / 64.0)));
            PUSHs(sv_2mortal(newSVnv((double) kerning.y / 64.0)));
        }


SV *
qefft2_face_glyph_from_char_code (Font_FreeType_Face face, FT_ULong char_code, int fallback = 0)
    PREINIT:
        FT_UInt glyph_idx;
    CODE:
        glyph_idx = FT_Get_Char_Index(face, char_code);
        if (glyph_idx || fallback)
            RETVAL = make_glyph(SvRV(ST(0)), char_code, 1, glyph_idx);
        else
            RETVAL = &PL_sv_undef;
    OUTPUT:
        RETVAL


SV *
qefft2_face_glyph_from_char (Font_FreeType_Face face, SV *sv, int fallback = 0)
    PREINIT:
        FT_UInt glyph_idx;
        const U8 *str;
        STRLEN len;
        UV char_code;
    CODE:
        if (!SvPOK(sv))
            croak("argument must be a string containing a character");
        str = (const U8*)SvPV(sv, len);
        if (!len)
            croak("string has no characters");
        if (!UTF8_IS_INVARIANT(*str)) {
            STRLEN s_len;
            char_code = utf8_to_uvchr_buf(str, str + len, &s_len);
            if (len != s_len) {
                croak("malformed string (looks as UTF-8, but isn't it)");
            }
        } else {
            char_code = *str;
        }
        glyph_idx = FT_Get_Char_Index(face, char_code);
        fallback = SvOK(ST(2)) ? SvIV(ST(2)) : 0;
        if (glyph_idx || fallback)
            RETVAL = make_glyph(SvRV(ST(0)), char_code, 1, glyph_idx);
        else
            RETVAL = &PL_sv_undef;
    OUTPUT:
        RETVAL

FT_UInt
qefft2_face_get_name_index (Font_FreeType_Face face, SV *sv)
    PREINIT:
        char *name;
    CODE:
        name = SvPV_nolen(sv);
        RETVAL = FT_Get_Name_Index(face, name);
    OUTPUT:
        RETVAL

SV *
qefft2_face_glyph_from_index (Font_FreeType_Face face, FT_UInt ix)
    CODE:
        RETVAL = make_glyph(SvRV(ST(0)), 0, 0, ix);
    OUTPUT:
        RETVAL

SV *
qefft2_face_glyph_from_name (Font_FreeType_Face face, SV *sv, int fallback = 0)
    PREINIT:
        char *name;
        FT_UInt ix;
    CODE:
        name = SvPV_nolen(sv);
        ix = FT_Get_Name_Index(face, name);
        if (ix || fallback || !strcmp(name, ".notdef"))
            RETVAL = make_glyph(SvRV(ST(0)), 0, 0, ix);
        else
            RETVAL = &PL_sv_undef;
    OUTPUT:
        RETVAL

void
qefft2_face_foreach_char (Font_FreeType_Face face, SV *code)
    PREINIT:
        FT_ULong char_code;
        FT_UInt glyph_idx;
    CODE:
        char_code = FT_Get_First_Char(face, &glyph_idx);
        while (glyph_idx) {
            dSP;
            ENTER;
            SAVETMPS;

            PUSHMARK(SP);
            SAVESPTR(DEFSV);
            DEFSV = sv_2mortal(make_glyph(SvRV(ST(0)), char_code, 1, glyph_idx));
            PUTBACK;

            call_sv(code, G_VOID | G_DISCARD);

            FREETMPS;
            LEAVE;

            char_code = FT_Get_Next_Char(face, char_code, &glyph_idx);
        }


void
qefft2_face_foreach_glyph (Font_FreeType_Face face, SV *code)
    PREINIT:
        FT_UInt glyph_idx;
    CODE:
        for (glyph_idx  = 0 ; glyph_idx < face->num_glyphs ; glyph_idx++) {
            dSP;
            ENTER;
            SAVETMPS;

            PUSHMARK(SP);
            SAVESPTR(DEFSV);
            DEFSV = sv_2mortal(make_glyph(SvRV(ST(0)), 0, 0, glyph_idx));
            PUTBACK;

            call_sv(code, G_VOID | G_DISCARD);

            FREETMPS;
            LEAVE;
        }


MODULE = Font::FreeType   PACKAGE = Font::FreeType::Glyph   PREFIX = qefft2_glyph_


void
qefft2_glyph_DESTROY (Font_FreeType_Glyph glyph)
    PREINIT:
        FT_Face face;
        QefFT2_Face_Extra *extra;
    CODE:
        face = (FT_Face) SvIV(glyph->face_sv);
        extra = face->generic.data;
        if (extra->glyph_ft) {
            FT_Done_Glyph(extra->glyph_ft);
            extra->glyph_ft = 0;
        }
        assert(glyph->face_sv);
        SvREFCNT_dec(glyph->face_sv);
        Safefree(glyph->name);
        Safefree(glyph);


SV *
qefft2_glyph_char_code (Font_FreeType_Glyph glyph)
    PREINIT:
        FT_Face face;
        FT_ULong char_code;
        FT_UInt glyph_idx;
    CODE:
        if (glyph->has_char_code) {
            RETVAL = newSVuv((UV) glyph->char_code);
        }
        else {
            /* Unfortunately, the only way I know of finding the character
             * code given a glyph index is to hunt through all the
             * glyphs.  Some glyphs might not have codes in the current
             * charmap, in which case undef is returned. */
            RETVAL = &PL_sv_undef;
            face = (FT_Face) SvIV(glyph->face_sv);
            char_code = FT_Get_First_Char(face, &glyph_idx);
            while (glyph_idx) {
                if (glyph_idx == glyph->index) {
                    glyph->char_code = char_code;
                    RETVAL = newSVuv((UV) glyph->char_code);
                    break;
                }
                char_code = FT_Get_Next_Char(face, char_code, &glyph_idx);
            }
        }
    OUTPUT:
        RETVAL


FT_UInt
qefft2_glyph_index (Font_FreeType_Glyph glyph)
    CODE:
        RETVAL = glyph->index;
    OUTPUT:
        RETVAL


SV *
qefft2_glyph_name (Font_FreeType_Glyph glyph)
    PREINIT:
        FT_Face face;
        char *buf;
        int bufsz;
        STRLEN len;
    CODE:
        if (glyph->name)
            RETVAL = newSVpv(glyph->name, 0);
        else {
            face = (FT_Face) SvIV(glyph->face_sv);
            if (!FT_HAS_GLYPH_NAMES(face))
                RETVAL = &PL_sv_undef;
            else {
                /* The loop repeatedly expands the buffer if it looks like
                 * the glyph name might be longer than the space available.  */
                bufsz = QEF_BUF_SZ;
                Newx(buf, bufsz, char);
                while (1) {
                    errchk(FT_Get_Glyph_Name(face, glyph->index, buf, bufsz),
                           "getting freetype glyph name");
                    len = strlen(buf);
                    if (len == bufsz - 1) {
                        bufsz = bufsz * 2;
                        Renew(buf, bufsz, char);
                    }
                    else
                        break;
                }

                glyph->name = buf;
                RETVAL = newSVpv(buf, len);
            }
        }
    OUTPUT:
        RETVAL


FT_F26Dot6
qefft2_glyph_width (Font_FreeType_Glyph glyph)
    PREINIT:
        FT_Face face;
    CODE:
        face = (FT_Face) SvIV(glyph->face_sv);
        RETVAL = ensure_glyph_loaded(face, glyph)->metrics.width;
    OUTPUT:
        RETVAL


FT_F26Dot6
qefft2_glyph_height (Font_FreeType_Glyph glyph)
    PREINIT:
        FT_Face face;
    CODE:
        face = (FT_Face) SvIV(glyph->face_sv);
        RETVAL = ensure_glyph_loaded(face, glyph)->metrics.height;
    OUTPUT:
        RETVAL


FT_F26Dot6
qefft2_glyph_left_bearing (Font_FreeType_Glyph glyph)
    PREINIT:
        FT_Face face;
    CODE:
        face = (FT_Face) SvIV(glyph->face_sv);
        RETVAL = ensure_glyph_loaded(face, glyph)->metrics.horiBearingX;
    OUTPUT:
        RETVAL


FT_F26Dot6
qefft2_glyph_right_bearing (Font_FreeType_Glyph glyph)
    PREINIT:
        FT_Face face;
        const FT_Glyph_Metrics *metrics;
    CODE:
        face = (FT_Face) SvIV(glyph->face_sv);
        metrics = &ensure_glyph_loaded(face, glyph)->metrics;
        RETVAL = metrics->horiAdvance - metrics->horiBearingX - metrics->width;
    OUTPUT:
        RETVAL


FT_F26Dot6
qefft2_glyph_horizontal_advance (Font_FreeType_Glyph glyph)
    PREINIT:
        FT_Face face;
    CODE:
        face = (FT_Face) SvIV(glyph->face_sv);
        RETVAL = ensure_glyph_loaded(face, glyph)->metrics.horiAdvance;
    OUTPUT:
        RETVAL


FT_F26Dot6
qefft2_glyph_vertical_advance (Font_FreeType_Glyph glyph)
    PREINIT:
        FT_Face face;
    CODE:
        face = (FT_Face) SvIV(glyph->face_sv);
        RETVAL = ensure_glyph_loaded(face, glyph)->metrics.vertAdvance;
    OUTPUT:
        RETVAL


void
qefft2_glyph_load (Font_FreeType_Glyph glyph)
    PREINIT:
        FT_Face face;
    CODE:
        face = (FT_Face) SvIV(glyph->face_sv);
        ensure_glyph_loaded(face, glyph);


bool
qefft2_glyph_has_outline (Font_FreeType_Glyph glyph)
    PREINIT:
        FT_Face face;
    CODE:
        face = (FT_Face) SvIV(glyph->face_sv);
        RETVAL = ensure_outline_loaded(face, glyph);
    OUTPUT:
        RETVAL


void
qefft2_glyph_outline_bbox (Font_FreeType_Glyph glyph)
    PREINIT:
        FT_Face face;
        QefFT2_Face_Extra *extra;
        FT_OutlineGlyph outline_glyph;
        FT_BBox bbox;
    PPCODE:
        face = (FT_Face) SvIV(glyph->face_sv);
        if (!ensure_outline_loaded(face, glyph))
            croak("glyph %lu does not have an outline",
                  (unsigned long) glyph->char_code);
        extra = face->generic.data;
        outline_glyph = (FT_OutlineGlyph) extra->glyph_ft;
        errchk(FT_Outline_Get_BBox(&outline_glyph->outline, &bbox),
               "getting glyph outline bounding box");
        EXTEND(SP, 4);
        PUSHs(sv_2mortal(newSVnv((double) bbox.xMin / 64.0)));
        PUSHs(sv_2mortal(newSVnv((double) bbox.yMin / 64.0)));
        PUSHs(sv_2mortal(newSVnv((double) bbox.xMax / 64.0)));
        PUSHs(sv_2mortal(newSVnv((double) bbox.yMax / 64.0)));


void
qefft2_glyph_outline_decompose_ (Font_FreeType_Glyph glyph, HV *args)
    PREINIT:
        FT_Face face;
        QefFT2_Face_Extra *extra;
        FT_OutlineGlyph outline_glyph;
        FT_Outline_Funcs handlers;
        struct QefFT2_Outline_Decompose_Extra_ decompose_extra;
        STRLEN len;
        HE *he;
        const char *key;
        SV *sv;
    CODE:
        face = (FT_Face) SvIV(glyph->face_sv);
        if (!ensure_outline_loaded(face, glyph))
            croak("glyph %lu does not have an outline",
                  (unsigned long) glyph->char_code);
        extra = face->generic.data;

        decompose_extra.move_to = 0;
        decompose_extra.line_to = 0;
        decompose_extra.conic_to = 0;
        decompose_extra.cubic_to = 0;
        hv_iterinit(args);
        while ((he = hv_iternext(args))) {
            key = HePV(he, len);
            sv = HeVAL(he);
            if (!strcmp(key, "move_to"))
                decompose_extra.move_to = sv;
            else if (!strcmp(key, "line_to"))
                decompose_extra.line_to = sv;
            else if (!strcmp(key, "conic_to"))
                decompose_extra.conic_to = sv;
            else if (!strcmp(key, "cubic_to"))
                decompose_extra.cubic_to = sv;
            else
                croak("hash key '%s' not the name of a known event", key);
        }

        if (!decompose_extra.move_to)
            croak("callback handler 'move_to' argument required");
        if (!decompose_extra.line_to)
            croak("callback handler 'line_to' argument required");
        if (!decompose_extra.cubic_to)
            croak("callback handler 'cubic_to' argument required");

        handlers.move_to = handle_move_to;
        handlers.line_to = handle_line_to;
        handlers.conic_to = handle_conic_to;
        handlers.cubic_to = handle_cubic_to;
        handlers.shift = 0;
        handlers.delta = 0;
        outline_glyph = (FT_OutlineGlyph) extra->glyph_ft;
        errchk(FT_Outline_Decompose(&outline_glyph->outline, &handlers,
                                    &decompose_extra),
               "decomposing FreeType outline");


void
qefft2_glyph_bitmap (Font_FreeType_Glyph glyph, UV render_mode = FT_RENDER_MODE_NORMAL)
    PREINIT:
        FT_Face face;
        FT_GlyphSlot glyph_ft;
        FT_Bitmap *bitmap;
        unsigned char *buf;
        int i, j;
        int bits = 0;
        AV *rows;
        unsigned char *row_buf;
    PPCODE:
        face = (FT_Face) SvIV(glyph->face_sv);
        /* XXX: For some reason I can't work out how to load the bitmap and
         * then load the outline later, but it works the other way round.
         * To ensure that a glyph object can be used for both, in either order,
         * I load the outline first even if it's not needed.  There's probably
         * a better way of doing this.  I'll ask on the mailing list.  */
        ensure_outline_loaded(face, glyph);
        glyph_ft = face->glyph;
        if (glyph_ft->format != FT_GLYPH_FORMAT_BITMAP) {
            errchk(FT_Render_Glyph(glyph_ft, render_mode), "rendering glyph");
        }
        bitmap = &glyph_ft->bitmap;
        assert(bitmap);

        rows = newAV();
        av_extend(rows, bitmap->rows - 1);
        buf = bitmap->buffer;
        Newx(row_buf, bitmap->width, unsigned char);

        if (bitmap->pixel_mode == FT_PIXEL_MODE_MONO) {
            for (i = 0; i < bitmap->rows; ++i) {
                for (j = 0; j < bitmap->width; ++j) {
                    if (j % 8 == 0)
                        bits = buf[j / 8];
                    row_buf[j] = bits & 0x80 ? 0xFF : 0x00;
                    bits <<= 1;
                }
                /* Not bothering to check that value was actually stored */
                av_store(rows, i, newSVpvn(row_buf, bitmap->width));
                buf += bitmap->pitch;
            }
        }
        else if (bitmap->pixel_mode == FT_PIXEL_MODE_GRAY) {
            for (i = 0; i < bitmap->rows; ++i) {
                for (j = 0; j < bitmap->width; ++j) {
                    row_buf[j] = buf[j];
                }
                /* Not bothering to check that value was actually stored */
                av_store(rows, i, newSVpvn(row_buf, bitmap->width));
                buf += bitmap->pitch;
            }
        }
        else {
            Safefree(row_buf);
            SvREFCNT_dec(rows);
            croak("unsupported pixel mode %d", (int) bitmap->pixel_mode);
        }

        Safefree(row_buf);
        EXTEND(SP, 3);
        PUSHs(sv_2mortal(newRV_inc((SV *) rows)));
        PUSHs(sv_2mortal(newSViv(glyph_ft->bitmap_left)));
        PUSHs(sv_2mortal(newSViv(glyph_ft->bitmap_top)));


MODULE = Font::FreeType   PACKAGE = Font::FreeType::CharMap   PREFIX = qefft2_charmap_

FT_Encoding
qefft2_charmap_encoding (Font_FreeType_CharMap charmap)
    CODE:
        RETVAL = charmap->encoding;
    OUTPUT:
        RETVAL

FT_UShort
qefft2_charmap_platform_id (Font_FreeType_CharMap charmap)
    CODE:
        RETVAL = charmap->platform_id;
    OUTPUT:
        RETVAL

FT_UShort
qefft2_charmap_encoding_id (Font_FreeType_CharMap charmap)
    CODE:
        RETVAL = charmap->encoding_id;
    OUTPUT:
        RETVAL

MODULE = Font::FreeType   PACKAGE = Font::FreeType::NamedInfo   PREFIX = qefft2_named_info_

void
qefft2_named_info_DESTROY (Font_FreeType_NamedInfo info)
    CODE:
        Safefree(info);

FT_UShort
qefft2_named_info_platform_id (Font_FreeType_NamedInfo info)
    CODE:
        RETVAL = info->platform_id;
    OUTPUT:
        RETVAL

FT_UShort
qefft2_named_info_encoding_id (Font_FreeType_NamedInfo info)
    CODE:
        RETVAL = info->encoding_id;
    OUTPUT:
        RETVAL

FT_UShort
qefft2_named_info_language_id (Font_FreeType_NamedInfo info)
    CODE:
        RETVAL = info->language_id;
    OUTPUT:
        RETVAL

FT_UShort
qefft2_named_info_name_id (Font_FreeType_NamedInfo info)
    CODE:
        RETVAL = info->name_id;
    OUTPUT:
        RETVAL

SV*
qefft2_named_info_string (Font_FreeType_NamedInfo info)
    CODE:
        RETVAL = newSVpvn(info->string, info->string_len);
    OUTPUT:
        RETVAL

MODULE = Font::FreeType   PACKAGE = Font::FreeType::BoundingBox   PREFIX = qefft2_bb_

FT_Pos
qefft2_bb_x_min (Font_FreeType_BoundingBox bb)
    CODE:
        RETVAL = bb->xMin;
    OUTPUT:
        RETVAL

FT_Pos
qefft2_bb_y_min (Font_FreeType_BoundingBox bb)
    CODE:
        RETVAL = bb->yMin;
    OUTPUT:
        RETVAL

FT_Pos
qefft2_bb_x_max (Font_FreeType_BoundingBox bb)
    CODE:
        RETVAL = bb->xMax;
    OUTPUT:
        RETVAL

FT_Pos
qefft2_bb_y_max (Font_FreeType_BoundingBox bb)
    CODE:
        RETVAL = bb->yMax;
    OUTPUT:
        RETVAL

# vi:ts=4 sw=4 expandtab:
