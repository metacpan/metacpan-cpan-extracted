/*
 * Imager::File::SIXEL - XS glue.
 *
 * Copyright (C) 2026 davenonymous.
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself.
 */
#define PERL_NO_GET_CONTEXT
#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "imext.h"
#include "imperl.h"
#include "imsixel.h"
#ifdef __cplusplus
}
#endif

DEFINE_IMAGER_CALLBACKS;

/* Copies an array reference of Imager::Color objects, or undef, into a
 * colour array freed with the current Perl scope; *size receives the
 * number of colours. The Perl layer validates the palette, so misuse
 * croaks.
 */
static i_color *
palette_from_sv(pTHX_ SV *sv, int *size) {
	AV *av;
	i_color *palette;
	SSize_t count, i;

	*size = 0;
	if (!SvOK(sv))
		return NULL;
	if (!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVAV)
		croak("palette must be an array reference");

	av = (AV *)SvRV(sv);
	count = av_len(av) + 1;
	if (count < 1 || count > 256)
		croak("palette must hold from 1 to 256 colors");

	Newx(palette, count, i_color);
	SAVEFREEPV(palette);
	for (i = 0; i < count; ++i) {
		SV **entry = av_fetch(av, i, 0);
		if (!entry || !SvROK(*entry) || !sv_derived_from(*entry, "Imager::Color"))
			croak("palette entry %d is not an Imager::Color", (int)i);
		palette[i] = *INT2PTR(i_color *, SvIV(SvRV(*entry)));
	}
	*size = (int)count;
	return palette;
}

static i_img *
image_from_sv(pTHX_ SV *sv) {
	if (!SvROK(sv) || !sv_derived_from(sv, "Imager::ImgRaw"))
		croak("only images can be written");
	return INT2PTR(i_img *, SvIV(SvRV(sv)));
}

MODULE = Imager::File::SIXEL  PACKAGE = Imager::File::SIXEL

PROTOTYPES: DISABLE

Imager::ImgRaw
i_readsixel(ig, page, allow_incomplete)
	Imager::IO ig
	int page
	int allow_incomplete

void
i_readsixel_multi(ig, allow_incomplete)
	Imager::IO ig
	int allow_incomplete
    PREINIT:
	i_img **imgs;
	int count;
	int i;
    PPCODE:
	imgs = i_readsixel_multi(ig, &count, allow_incomplete);
	if (imgs) {
		EXTEND(SP, count);
		for (i = 0; i < count; ++i) {
			SV *sv = sv_newmortal();
			sv_setref_pv(sv, "Imager::ImgRaw", (void *)imgs[i]);
			PUSHs(sv);
		}
		myfree(imgs);
	}

undef_int
i_writesixel(ig, palette, im)
	Imager::IO ig
	SV *palette
	Imager::ImgRaw im
    PREINIT:
	i_color *colors;
	int color_count;
    CODE:
	colors = palette_from_sv(aTHX_ palette, &color_count);
	RETVAL = i_writesixel(ig, im, colors, color_count);
    OUTPUT:
	RETVAL

undef_int
i_writesixel_multi(ig, palette, ...)
	Imager::IO ig
	SV *palette
    PREINIT:
	i_color *colors;
	int color_count;
	i_img **imgs;
	int img_count;
	int i;
    CODE:
	img_count = items - 2;
	if (img_count < 1)
		croak("Usage: i_writesixel_multi(ig, palette, images...)");
	Newx(imgs, img_count, i_img *);
	SAVEFREEPV(imgs);
	for (i = 0; i < img_count; ++i)
		imgs[i] = image_from_sv(aTHX_ ST(2 + i));
	colors = palette_from_sv(aTHX_ palette, &color_count);
	RETVAL = i_writesixel_multi(ig, imgs, img_count, colors, color_count);
    OUTPUT:
	RETVAL

BOOT:
	PERL_INITIALIZE_IMAGER_CALLBACKS;
