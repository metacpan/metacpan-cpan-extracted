/*
 * Imager::File::SIXEL - colour quantization used by the SIXEL encoder.
 *
 * Copyright (C) 2026 davenonymous.
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself.
 */
#ifndef IMAGER_SIXEL_QUANT_H
#define IMAGER_SIXEL_QUANT_H

#include <stddef.h>
#include <stdint.h>

/* Most colour registers the encoder ever defines. */
#define SIXEL_MAX_PALETTE 256

/* Index map value for a pixel that is left unpainted. */
#define SIXEL_TRANSPARENT 0xFFFF

/* Palette entries are always exactly representable in SIXEL, whose
 * RGB colour definitions use percentages (0..100) per channel.
 */
typedef struct {
	int size;
	unsigned char rgb[SIXEL_MAX_PALETTE][3];
} sixel_palette;

typedef enum {
	SIXEL_DITHER_NONE,
	SIXEL_DITHER_ORDERED,
	SIXEL_DITHER_DIFFUSION
} sixel_dither;

/* Conversions between 8-bit samples and SIXEL percentages. Converting a
 * percentage to a sample and back is lossless.
 */
int sixel_percent_from_sample(int sample);
int sixel_sample_from_percent(int percent);

/* The pixel buffers below are packed RGBA, 4 bytes per pixel, whose
 * alpha byte is either 0 (unpainted) or 255 (painted).
 */

/* Builds a palette of the distinct painted colours, rounded to SIXEL
 * percentages, and the matching index map. Returns 0, leaving palette
 * and map unspecified, when the image holds more than max_colors
 * distinct colours after rounding.
 */
int sixel_palette_exact(const unsigned char *rgba, size_t pixel_count, int max_colors,
                        sixel_palette *palette, uint16_t *map);

/* Builds a palette of at most max_colors entries representing the
 * painted pixels by variance minimizing box splitting of a colour
 * histogram. Returns 0 only when memory cannot be allocated.
 */
int sixel_palette_adaptive(const unsigned char *rgba, size_t pixel_count, int max_colors,
                           sixel_palette *palette);

/* Fills palette with the 216 colour web-safe cube. */
void sixel_palette_webmap(sixel_palette *palette);

/* Rounds every palette entry to the nearest SIXEL representable colour. */
void sixel_palette_snap(sixel_palette *palette);

/* Maps every pixel to its nearest palette entry, optionally dithering.
 * Unpainted pixels map to SIXEL_TRANSPARENT. Returns 0 only when memory
 * cannot be allocated.
 */
int sixel_map_pixels(const unsigned char *rgba, size_t width, size_t height,
                     const sixel_palette *palette, sixel_dither dither, uint16_t *map);

#endif
