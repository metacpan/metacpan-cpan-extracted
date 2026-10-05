/*
 * Imager::File::SIXEL - public C interface used by SIXEL.xs.
 *
 * Copyright (C) 2026 davenonymous.
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself.
 */
#ifndef IMAGER_IMSIXEL_H
#define IMAGER_IMSIXEL_H

#include "imdatatypes.h"

/* Decode the zero based page'th SIXEL image found in ig.
 *
 * When allow_incomplete is non-zero an image truncated by the end of
 * input is returned with the i_incomplete tag set instead of failing.
 */
i_img *i_readsixel(io_glue *ig, int page, int allow_incomplete);

/* Decode every SIXEL image found in ig. *count receives the number of
 * images; the returned array must be released with myfree().
 */
i_img **i_readsixel_multi(io_glue *ig, int *count, int allow_incomplete);

/* Encode one image. palette/palette_size describe an optional caller
 * supplied palette (palette may be NULL, palette_size is then ignored).
 * Encoder settings are taken from the sixel_* tags of the image.
 */
int i_writesixel(io_glue *ig, i_img *im, const i_color *palette, int palette_size);

/* Encode count images as consecutive SIXEL sequences. */
int i_writesixel_multi(io_glue *ig, i_img **imgs, int count, const i_color *palette, int palette_size);

#endif
