/*
 * Imager::File::SIXEL - SIXEL encoder.
 *
 * Copyright (C) 2026 davenonymous.
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself.
 *
 * An image is encoded in three stages:
 *
 *   1. the image is reduced to a palette of at most 256 colours and an
 *      index map holding one palette index (or SIXEL_TRANSPARENT) per
 *      pixel,
 *   2. the colour registers used by the map are defined,
 *   3. the map is emitted band by band, six rows per band.
 *
 * Within a band every column contributes one entry per distinct colour
 * holding that colour's six bit mask. The entries are bucketed by
 * colour with a counting sort, which keeps them in column order. Each
 * colour's entries are split into segments at long gaps, and the
 * segments are packed greedily onto as few run length encoded sixel
 * lines as possible. The cost of stage 3 is therefore linear in the
 * number of pixels and independent of the palette size.
 */
#include "imext.h"
#include "imsixel.h"
#include "sixel_quant.h"

#include <errno.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define OUTPUT_CAPACITY 65536
/* the longest token: "#255;2;100;100;100" or a run "!<20 digits>c" */
#define OUTPUT_TOKEN_MAX 64

#define DEFAULT_ALPHA_THRESHOLD 128

typedef enum {
	PALETTE_ADAPTIVE,
	PALETTE_WEBMAP
} palette_kind;

typedef struct {
	int max_colors;
	palette_kind palette;
	sixel_dither dither;
	int alpha_threshold;
	int pan;
	int pad;
} write_options;

/* ------------------------------------------------------------------ */
/* options                                                             */

/* Parses a tag holding a decimal integer, with an optional sign and no
 * other characters.
 */
static int
tag_integer(const i_img_tag *tag, long *value) {
	const char *text = tag->data;
	char *end;

	if (!text) {
		*value = tag->idata;
		return 1;
	}
	if (!(text[0] == '-' || text[0] == '+' || (text[0] >= '0' && text[0] <= '9')))
		return 0;
	errno = 0;
	*value = strtol(text, &end, 10);
	return errno == 0 && end != text && end == text + tag->size;
}

static int
read_int_option(i_img *im, const char *name, int minimum, int maximum, int *value) {
	long found;
	int entry;

	if (!i_tags_find(&im->tags, name, 0, &entry))
		return 1;
	if (!tag_integer(im->tags.tags + entry, &found) || found < minimum || found > maximum) {
		i_push_errorf(0, "%s must be an integer from %d to %d", name, minimum, maximum);
		return 0;
	}
	*value = (int)found;
	return 1;
}

/* Reads a keyword option, storing the index of the matching keyword.
 * The whole tag value must match, so an embedded NUL byte or trailing
 * text makes it unknown.
 */
static int
read_keyword_option(i_img *im, const char *name, const char *const *keywords, int *value) {
	const i_img_tag *tag;
	int entry;
	int i;

	if (!i_tags_find(&im->tags, name, 0, &entry))
		return 1;
	tag = im->tags.tags + entry;
	if (!tag->data) {
		i_push_errorf(0, "unknown %s value '%d'", name, tag->idata);
		return 0;
	}
	for (i = 0; keywords[i]; ++i) {
		if ((size_t)tag->size == strlen(keywords[i]) && memcmp(tag->data, keywords[i], (size_t)tag->size) == 0) {
			*value = i;
			return 1;
		}
	}
	i_push_errorf(0, "unknown %s value '%.*s'", name, tag->size, tag->data);
	return 0;
}

static int
read_write_options(i_img *im, write_options *opts) {
	static const char *const palette_names[] = { "adaptive", "webmap", NULL };
	static const char *const dither_names[] = { "none", "ordered", "diffusion", NULL };
	int palette = PALETTE_ADAPTIVE;
	int dither = SIXEL_DITHER_DIFFUSION;

	opts->max_colors = SIXEL_MAX_PALETTE;
	opts->alpha_threshold = DEFAULT_ALPHA_THRESHOLD;
	opts->pan = 1;
	opts->pad = 1;

	if (!read_int_option(im, "sixel_max_colors", 1, SIXEL_MAX_PALETTE, &opts->max_colors)
	    || !read_int_option(im, "sixel_alpha_threshold", 0, 255, &opts->alpha_threshold)
	    || !read_int_option(im, "sixel_pan", 1, 0x7FFFFFFF, &opts->pan)
	    || !read_int_option(im, "sixel_pad", 1, 0x7FFFFFFF, &opts->pad)
	    || !read_keyword_option(im, "sixel_palette", palette_names, &palette)
	    || !read_keyword_option(im, "sixel_dither", dither_names, &dither))
		return 0;

	opts->palette = (palette_kind)palette;
	opts->dither = (sixel_dither)dither;
	return 1;
}

/* ------------------------------------------------------------------ */
/* stage 1: palette and index map                                      */

typedef struct {
	sixel_palette palette;
	uint16_t *map;
	i_img_dim width;
	i_img_dim height;
	int transparent;
} indexed_image;

static void
indexed_release(indexed_image *indexed) {
	free(indexed->map);
	indexed->map = NULL;
}

/* The number of pixels, or 0 for an image too large to encode: the
 * band scratch space indexes the up to 6 entries per column of a band
 * and its segments with signed 32 bit numbers, and the RGBA copy must
 * fit in memory.
 */
static size_t
pixel_count_of(i_img *im) {
	size_t width = (size_t)im->xsize;
	size_t height = (size_t)im->ysize;

	if (width == 0 || height == 0 || width > INT32_MAX / 6 || height > SIZE_MAX / 4 / width)
		return 0;
	return width * height;
}

/* Reads the image as packed RGBA with the alpha byte reduced to 0
 * (unpainted) or 255 (painted).
 */
static unsigned char *
fetch_rgba(i_img *im, int alpha_threshold) {
	static const int gray_channels[4] = { 0, 0, 0, 1 };
	size_t width = (size_t)im->xsize;
	size_t pixel_count = pixel_count_of(im);
	int alpha_channel = -1;
	int has_alpha = i_img_alpha_channel(im, &alpha_channel);
	int channels[4];
	int sample_count = has_alpha ? 4 : 3;
	unsigned char *rgba;
	unsigned char *row = NULL;
	i_img_dim y;

	if (i_img_color_channels(im) < 3) {
		memcpy(channels, gray_channels, sizeof(channels));
	}
	else {
		channels[0] = 0;
		channels[1] = 1;
		channels[2] = 2;
	}
	channels[3] = alpha_channel;

	rgba = malloc(pixel_count * 4);
	if (!has_alpha)
		row = malloc(width * 3);
	if (!rgba || (!has_alpha && !row)) {
		free(rgba);
		free(row);
		i_push_error(0, "out of memory");
		return NULL;
	}

	for (y = 0; y < im->ysize; ++y) {
		unsigned char *out = rgba + (size_t)y * width * 4;
		size_t x;

		if (has_alpha) {
			i_gsamp(im, 0, im->xsize, y, out, channels, sample_count);
			for (x = 0; x < width; ++x)
				out[x * 4 + 3] = out[x * 4 + 3] < alpha_threshold ? 0 : 255;
		}
		else {
			i_gsamp(im, 0, im->xsize, y, row, channels, sample_count);
			for (x = 0; x < width; ++x) {
				out[x * 4] = row[x * 3];
				out[x * 4 + 1] = row[x * 3 + 1];
				out[x * 4 + 2] = row[x * 3 + 2];
				out[x * 4 + 3] = 255;
			}
		}
	}

	free(row);
	return rgba;
}

/* Fills register_of with the register each palette entry is written
 * to: its own index, or that of the first entry with the same colour.
 */
static void
share_identical_registers(const sixel_palette *palette, uint16_t *register_of) {
	int i, j;

	for (i = 0; i < palette->size; ++i) {
		for (j = 0; memcmp(palette->rgb[j], palette->rgb[i], 3) != 0; ++j)
			;
		register_of[i] = (uint16_t)j;
	}
}

/* Paletted images whose palette fits are encoded with that palette.
 * Entries that round to the same SIXEL colour share a register.
 */
static int
index_paletted(i_img *im, const write_options *opts, indexed_image *indexed) {
	i_color colors[SIXEL_MAX_PALETTE];
	int painted[SIXEL_MAX_PALETTE];
	uint16_t register_of[SIXEL_MAX_PALETTE];
	int color_count = i_colorcount(im);
	int alpha_channel = -1;
	int has_alpha = i_img_alpha_channel(im, &alpha_channel);
	int gray = i_img_color_channels(im) < 3;
	size_t width = (size_t)im->xsize;
	i_palidx *row;
	i_img_dim y;
	int i;

	if (!i_getcolors(im, 0, colors, color_count)) {
		i_push_error(0, "cannot read the image palette");
		return 0;
	}
	row = malloc(width * sizeof(*row));
	if (!row) {
		i_push_error(0, "out of memory");
		return 0;
	}

	for (i = 0; i < color_count; ++i) {
		const unsigned char *channel = colors[i].channel;
		painted[i] = !has_alpha || channel[alpha_channel] >= opts->alpha_threshold;
		indexed->palette.rgb[i][0] = channel[0];
		indexed->palette.rgb[i][1] = channel[gray ? 0 : 1];
		indexed->palette.rgb[i][2] = channel[gray ? 0 : 2];
	}
	indexed->palette.size = color_count;
	sixel_palette_snap(&indexed->palette);
	share_identical_registers(&indexed->palette, register_of);

	for (y = 0; y < im->ysize; ++y) {
		uint16_t *out = indexed->map + (size_t)y * width;
		size_t x;

		i_gpal(im, 0, im->xsize, y, row);
		for (x = 0; x < width; ++x) {
			int index = row[x];
			out[x] = index < color_count && painted[index] ? register_of[index] : SIXEL_TRANSPARENT;
		}
	}

	free(row);
	return 1;
}

static int
index_rgba(i_img *im, const write_options *opts, const i_color *custom, int custom_size,
           indexed_image *indexed) {
	size_t pixel_count = pixel_count_of(im);
	sixel_palette *palette = &indexed->palette;
	unsigned char *rgba = fetch_rgba(im, opts->alpha_threshold);
	int i;

	if (!rgba)
		return 0;

	if (custom) {
		for (i = 0; i < custom_size; ++i)
			memcpy(palette->rgb[i], custom[i].channel, 3);
		palette->size = custom_size;
		sixel_palette_snap(palette);
	}
	else if (opts->palette == PALETTE_WEBMAP) {
		sixel_palette_webmap(palette);
	}
	else {
		if (sixel_palette_exact(rgba, pixel_count, opts->max_colors, palette, indexed->map)) {
			free(rgba);
			return 1;
		}
		if (!sixel_palette_adaptive(rgba, pixel_count, opts->max_colors, palette)) {
			free(rgba);
			i_push_error(0, "out of memory");
			return 0;
		}
	}

	if (!sixel_map_pixels(rgba, (size_t)im->xsize, (size_t)im->ysize, palette, opts->dither, indexed->map)) {
		free(rgba);
		i_push_error(0, "out of memory");
		return 0;
	}

	free(rgba);
	return 1;
}

static int
index_image(i_img *im, const write_options *opts, const i_color *custom, int custom_size,
            indexed_image *indexed) {
	size_t pixel_count = pixel_count_of(im);
	int uses_own_palette;

	indexed->width = im->xsize;
	indexed->height = im->ysize;
	indexed->transparent = i_img_has_alpha(im);
	indexed->map = NULL;

	if (pixel_count == 0) {
		i_push_error(0, "image too large to encode");
		return 0;
	}
	indexed->map = malloc(pixel_count * sizeof(uint16_t));
	if (!indexed->map) {
		i_push_error(0, "out of memory");
		return 0;
	}

	uses_own_palette = !custom
		&& opts->palette == PALETTE_ADAPTIVE
		&& i_img_type(im) == i_palette_type
		&& i_colorcount(im) <= opts->max_colors;

	if (uses_own_palette ? index_paletted(im, opts, indexed)
	                     : index_rgba(im, opts, custom, custom_size, indexed))
		return 1;

	indexed_release(indexed);
	return 0;
}

/* ------------------------------------------------------------------ */
/* output buffering                                                    */

typedef struct {
	io_glue *io;
	unsigned char *buffer;
	size_t length;
	int failed;
} output;

static void
output_flush(output *out) {
	if (out->length && !out->failed) {
		if (i_io_write(out->io, out->buffer, out->length) != (ssize_t)out->length) {
			i_push_error(0, "write failed");
			out->failed = 1;
		}
	}
	out->length = 0;
}

/* Returns where a token of at most OUTPUT_TOKEN_MAX bytes may be stored. */
static inline unsigned char *
output_reserve(output *out) {
	if (out->length > OUTPUT_CAPACITY - OUTPUT_TOKEN_MAX)
		output_flush(out);
	return out->buffer + out->length;
}

static inline unsigned char *
format_number(unsigned char *p, uint64_t value) {
	unsigned char digits[20];
	int n = 0;

	do {
		digits[n++] = (unsigned char)('0' + value % 10);
		value /= 10;
	} while (value);
	while (n)
		*p++ = digits[--n];
	return p;
}

static inline void
output_byte(output *out, unsigned char c) {
	output_reserve(out)[0] = c;
	out->length++;
}

static void
output_text(output *out, const char *text) {
	unsigned char *start = output_reserve(out);
	size_t length = strlen(text);

	memcpy(start, text, length);
	out->length += length;
}

/* Writes count copies of the sixel character c. */
static inline void
output_run(output *out, unsigned char c, size_t count) {
	unsigned char *start = output_reserve(out);
	unsigned char *p = start;

	if (count > 3) {
		*p++ = '!';
		p = format_number(p, count);
		*p++ = c;
	}
	else {
		while (count--)
			*p++ = c;
	}
	out->length += (size_t)(p - start);
}

/* ------------------------------------------------------------------ */
/* stages 2 and 3: SIXEL stream                                        */

static void
write_header(output *out, const write_options *opts, const indexed_image *indexed) {
	unsigned char *start = output_reserve(out);
	unsigned char *p = start;

	/* DCS P1;P2;P3 q - P2 = 1 leaves unpainted pixels transparent */
	*p++ = 0x1B;
	*p++ = 'P';
	*p++ = '0';
	*p++ = ';';
	*p++ = indexed->transparent ? '1' : '0';
	*p++ = ';';
	*p++ = '0';
	*p++ = 'q';
	/* raster attributes " Pan ; Pad ; Ph ; Pv */
	*p++ = '"';
	p = format_number(p, (uint64_t)opts->pan);
	*p++ = ';';
	p = format_number(p, (uint64_t)opts->pad);
	*p++ = ';';
	p = format_number(p, (uint64_t)indexed->width);
	*p++ = ';';
	p = format_number(p, (uint64_t)indexed->height);
	out->length += (size_t)(p - start);
}

static void
write_registers(output *out, const indexed_image *indexed) {
	const sixel_palette *palette = &indexed->palette;
	char used[SIXEL_MAX_PALETTE];
	size_t pixel_count = (size_t)indexed->width * (size_t)indexed->height;
	size_t i;
	int index;

	memset(used, 0, sizeof(used));
	for (i = 0; i < pixel_count; ++i) {
		if (indexed->map[i] != SIXEL_TRANSPARENT)
			used[indexed->map[i]] = 1;
	}

	for (index = 0; index < palette->size; ++index) {
		unsigned char *start, *p;
		int c;

		if (!used[index])
			continue;
		start = p = output_reserve(out);
		*p++ = '#';
		p = format_number(p, (uint64_t)index);
		*p++ = ';';
		*p++ = '2';
		for (c = 0; c < 3; ++c) {
			*p++ = ';';
			p = format_number(p, (uint64_t)sixel_percent_from_sample(palette->rgb[index][c]));
		}
		out->length += (size_t)(p - start);
	}
}

/* A colour's columns are split into segments wherever SEGMENT_GAP or
 * more columns lack the colour; shorter gaps are cheaper to skip with
 * '?' than to start a new segment.
 */
#define SEGMENT_GAP 10

/* A run of one colour's column entries within a band. */
typedef struct {
	uint32_t first;         /* first entry in line_x / line_mask */
	uint32_t count;
	uint32_t start;         /* first column */
	uint32_t end;           /* one past the last column */
	uint16_t color;
	int32_t next;           /* next segment starting at the same column */
} segment;

/* Per band scratch space, sized for the worst case of six distinct
 * colours in every column.
 */
typedef struct {
	uint16_t *entry_color;
	uint32_t *entry_x;
	unsigned char *entry_mask;
	uint32_t *line_x;
	unsigned char *line_mask;
	segment *segments;
	int32_t *starting_at;   /* first segment starting at each column */
	uint32_t *next_start;   /* union-find: next column with a segment */
	uint32_t color_count[SIXEL_MAX_PALETTE];
	uint32_t color_end[SIXEL_MAX_PALETTE];
	uint16_t band_colors[SIXEL_MAX_PALETTE];
} band_scratch;

static int
band_scratch_init(band_scratch *scratch, size_t width) {
	size_t capacity = width * 6;

	scratch->entry_color = malloc(capacity * sizeof(uint16_t));
	scratch->entry_x = malloc(capacity * sizeof(uint32_t));
	scratch->entry_mask = malloc(capacity);
	scratch->line_x = malloc(capacity * sizeof(uint32_t));
	scratch->line_mask = malloc(capacity);
	scratch->segments = malloc(capacity * sizeof(segment));
	scratch->starting_at = malloc(width * sizeof(int32_t));
	scratch->next_start = malloc((width + 1) * sizeof(uint32_t));
	memset(scratch->color_count, 0, sizeof(scratch->color_count));
	return scratch->entry_color && scratch->entry_x && scratch->entry_mask
		&& scratch->line_x && scratch->line_mask && scratch->segments
		&& scratch->starting_at && scratch->next_start;
}

static void
band_scratch_release(band_scratch *scratch) {
	free(scratch->entry_color);
	free(scratch->entry_x);
	free(scratch->entry_mask);
	free(scratch->line_x);
	free(scratch->line_mask);
	free(scratch->segments);
	free(scratch->starting_at);
	free(scratch->next_start);
}

/* Groups the band's pixels into per colour column entries, ordered by
 * colour and then column. Returns the number of colours; their entries
 * end at color_end[band_colors[i]]. Sets *opaque when every pixel of
 * the band is painted.
 */
static int
collect_band(band_scratch *scratch, const indexed_image *indexed, i_img_dim top, int rows, int *opaque) {
	size_t width = (size_t)indexed->width;
	const uint16_t *band = indexed->map + (size_t)top * width;
	size_t entry_count = 0;
	int band_color_count = 0;
	size_t offset = 0;
	size_t x, e;
	int i;

	*opaque = 1;
	for (x = 0; x < width; ++x) {
		uint16_t column_color[6];
		unsigned char column_mask[6];
		int distinct = 0;
		int row, k;

		for (row = 0; row < rows; ++row) {
			uint16_t color = band[(size_t)row * width + x];
			if (color == SIXEL_TRANSPARENT) {
				*opaque = 0;
				continue;
			}
			for (k = 0; k < distinct && column_color[k] != color; ++k)
				;
			if (k == distinct) {
				column_color[distinct] = color;
				column_mask[distinct] = 0;
				++distinct;
			}
			column_mask[k] |= (unsigned char)(1 << row);
		}

		for (k = 0; k < distinct; ++k) {
			uint16_t color = column_color[k];
			if (scratch->color_count[color]++ == 0)
				scratch->band_colors[band_color_count++] = color;
			scratch->entry_color[entry_count] = color;
			scratch->entry_x[entry_count] = (uint32_t)x;
			scratch->entry_mask[entry_count] = column_mask[k];
			++entry_count;
		}
	}

	/* counting sort by colour, which keeps each colour's columns in order */
	for (i = 0; i < band_color_count; ++i) {
		uint16_t color = scratch->band_colors[i];
		scratch->color_end[color] = (uint32_t)offset;
		offset += scratch->color_count[color];
	}
	for (e = 0; e < entry_count; ++e) {
		uint32_t slot = scratch->color_end[scratch->entry_color[e]]++;
		scratch->line_x[slot] = scratch->entry_x[e];
		scratch->line_mask[slot] = scratch->entry_mask[e];
	}
	return band_color_count;
}

/* Splits the band's colours into segments and files each under the
 * column it starts at. Returns the number of segments.
 */
static size_t
build_segments(band_scratch *scratch, int band_color_count, size_t width) {
	size_t segment_count = 0;
	size_t x;
	int i;

	for (x = 0; x < width; ++x)
		scratch->starting_at[x] = -1;

	for (i = 0; i < band_color_count; ++i) {
		uint16_t color = scratch->band_colors[i];
		uint32_t end = scratch->color_end[color];
		uint32_t k = end - scratch->color_count[color];

		scratch->color_count[color] = 0;
		while (k < end) {
			segment *seg = scratch->segments + segment_count;
			uint32_t last = k;

			while (last + 1 < end && scratch->line_x[last + 1] - scratch->line_x[last] - 1 < SEGMENT_GAP)
				++last;
			seg->first = k;
			seg->count = last - k + 1;
			seg->start = scratch->line_x[k];
			seg->end = scratch->line_x[last] + 1;
			seg->color = color;
			seg->next = scratch->starting_at[seg->start];
			scratch->starting_at[seg->start] = (int32_t)segment_count;
			++segment_count;
			k = last + 1;
		}
	}

	/* a column without segments points to the next column */
	for (x = 0; x < width; ++x)
		scratch->next_start[x] = scratch->starting_at[x] >= 0 ? (uint32_t)x : (uint32_t)x + 1;
	scratch->next_start[width] = (uint32_t)width;
	return segment_count;
}

/* The first column at or after x where a segment starts, or the width. */
static uint32_t
find_next_start(uint32_t *next_start, uint32_t x) {
	while (next_start[x] != x) {
		next_start[x] = next_start[next_start[x]];
		x = next_start[x];
	}
	return x;
}

/* Writes a segment's sixels from its first column on; columns of the
 * segment without the colour are skipped with '?'.
 */
static void
write_segment_data(output *out, const band_scratch *scratch, const segment *seg) {
	const uint32_t *xs = scratch->line_x + seg->first;
	const unsigned char *masks = scratch->line_mask + seg->first;
	size_t next_x = seg->start;
	unsigned char run_char = 0;
	size_t run_length = 0;
	uint32_t i;

	for (i = 0; i < seg->count; ++i) {
		unsigned char c = (unsigned char)('?' + masks[i]);

		if (xs[i] != next_x) {
			if (run_length)
				output_run(out, run_char, run_length);
			output_run(out, '?', xs[i] - next_x);
			run_length = 0;
		}
		if (run_length && c == run_char) {
			++run_length;
		}
		else {
			if (run_length)
				output_run(out, run_char, run_length);
			run_char = c;
			run_length = 1;
		}
		next_x = (size_t)xs[i] + 1;
	}
	if (run_length)
		output_run(out, run_char, run_length);
}

/* Writes one band. Segments are packed greedily, left to right, into
 * as few sixel lines as possible. In an opaque band the segments of the
 * first line paint every row of their columns: the pixels of other
 * colours are painted over by later lines, and the full columns
 * compress into long runs.
 *
 * *active is the colour register currently selected, or -1. Bands
 * without pixels are written only as the '-' before the next band
 * with pixels, counted in *pending_newlines.
 */
static void
write_band(output *out, band_scratch *scratch, const indexed_image *indexed, i_img_dim top,
           int *active, int *pending_newlines) {
	size_t width = (size_t)indexed->width;
	int rows = indexed->height - top < 6 ? (int)(indexed->height - top) : 6;
	unsigned char full_column = (unsigned char)('?' + (1 << rows) - 1);
	int opaque;
	int band_color_count = collect_band(scratch, indexed, top, rows, &opaque);
	size_t remaining;
	int fill = opaque;

	remaining = build_segments(scratch, band_color_count, width);
	if (!remaining) {
		++*pending_newlines;
		return;
	}
	for (; *pending_newlines; --*pending_newlines)
		output_byte(out, '-');
	++*pending_newlines;

	while (remaining) {
		uint32_t x = 0;
		uint32_t column;

		while ((column = find_next_start(scratch->next_start, x)) < width) {
			int32_t index = scratch->starting_at[column];
			segment *seg = scratch->segments + index;

			scratch->starting_at[column] = seg->next;
			if (seg->next < 0)
				scratch->next_start[column] = column + 1;

			if (seg->color != *active) {
				unsigned char *start = output_reserve(out);
				unsigned char *p = start;
				*p++ = '#';
				p = format_number(p, seg->color);
				out->length += (size_t)(p - start);
				*active = seg->color;
			}
			if (seg->start > x)
				output_run(out, '?', seg->start - x);
			if (fill)
				output_run(out, full_column, seg->end - seg->start);
			else
				write_segment_data(out, scratch, seg);
			x = seg->end;
			--remaining;
		}
		if (remaining)
			output_byte(out, '$');
		fill = 0;
	}
}

static int
write_indexed(io_glue *ig, const write_options *opts, const indexed_image *indexed) {
	band_scratch scratch;
	output out;
	i_img_dim top;
	int active = -1;
	int pending_newlines = 0;
	int allocated;

	out.io = ig;
	out.length = 0;
	out.failed = 0;
	out.buffer = malloc(OUTPUT_CAPACITY);
	/* band_scratch_init leaves every member releasable, even on failure */
	allocated = band_scratch_init(&scratch, (size_t)indexed->width) && out.buffer;
	if (!allocated) {
		band_scratch_release(&scratch);
		free(out.buffer);
		i_push_error(0, "out of memory");
		return 0;
	}

	write_header(&out, opts, indexed);
	write_registers(&out, indexed);
	for (top = 0; top < indexed->height && !out.failed; top += 6)
		write_band(&out, &scratch, indexed, top, &active, &pending_newlines);
	/* without any sixel data some decoders, libsixel among them, ignore
	 * the raster attributes; a carriage return makes them apply */
	if (active < 0)
		output_byte(&out, '$');
	output_text(&out, "\x1b\\");
	output_flush(&out);

	band_scratch_release(&scratch);
	free(out.buffer);
	return !out.failed;
}

/* ------------------------------------------------------------------ */
/* public interface                                                    */

static int
write_image(io_glue *ig, i_img *im, const write_options *opts, const i_color *palette, int palette_size) {
	indexed_image indexed;
	int ok;

	if (!index_image(im, opts, palette, palette_size, &indexed))
		return 0;

	ok = write_indexed(ig, opts, &indexed);
	indexed_release(&indexed);
	return ok;
}

int
i_writesixel(io_glue *ig, i_img *im, const i_color *palette, int palette_size) {
	return i_writesixel_multi(ig, &im, 1, palette, palette_size);
}

/* Every option is validated before anything is written, so invalid
 * options never leave a partial stream behind.
 */
int
i_writesixel_multi(io_glue *ig, i_img **imgs, int count, const i_color *palette, int palette_size) {
	write_options *opts;
	int ok = 1;
	int i;

	i_clear_error();
	if (count < 1) {
		i_push_error(0, "no images to write");
		return 0;
	}
	if (palette && (palette_size < 1 || palette_size > SIXEL_MAX_PALETTE)) {
		i_push_errorf(0, "the palette must hold from 1 to %d colors", SIXEL_MAX_PALETTE);
		return 0;
	}

	opts = malloc(sizeof(*opts) * (size_t)count);
	if (!opts) {
		i_push_error(0, "out of memory");
		return 0;
	}
	for (i = 0; i < count && ok; ++i)
		ok = read_write_options(imgs[i], opts + i);
	for (i = 0; i < count && ok; ++i)
		ok = write_image(ig, imgs[i], opts + i, palette, palette_size);
	free(opts);

	if (ok && i_io_close(ig)) {
		i_push_error(0, "error closing output");
		ok = 0;
	}
	return ok;
}
