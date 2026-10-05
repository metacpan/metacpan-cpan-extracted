/*
 * Imager::File::SIXEL - SIXEL decoder.
 *
 * Copyright (C) 2026 davenonymous.
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself.
 *
 * The input is scanned for device control strings (DCS) whose final
 * character is 'q' and which have no intermediate characters; every
 * other byte, including other control strings, is skipped. Each sixel
 * control string becomes one image.
 *
 * Pixels keep the colour their register held when they were painted,
 * so streams that redefine registers to show more colours than there
 * are registers decode as intended. The image covers every painted
 * pixel and at least the size declared by the raster attributes.
 */
#include "imext.h"
#include "imsixel.h"

#include <math.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define INPUT_BUFFER_SIZE 65536

#define CHAR_EOF (-1)
#define CHAR_CAN 0x18
#define CHAR_SUB 0x1A
#define CHAR_ESC 0x1B
#define CHAR_DCS 0x90
#define CHAR_ST 0x9C

#define REGISTER_COUNT 1024
#define INITIAL_REGISTER 15
/* pixels hold colour numbers below MAX_COLORS, or UNPAINTED */
#define MAX_COLORS 0xFFFE
#define UNPAINTED 0xFFFF
#define MAX_PARAMS 16
/* parameters saturate here, as do cursor coordinates */
#define PARAM_LIMIT 0x3FFFFFFF
/* Painting may write each pixel of the canvas this many times, plus
 * PAINT_ALLOWANCE writes, before decoding stops: legitimate images
 * paint most pixels once or twice, while the repeat command lets a few
 * bytes paint over the same pixels endlessly.
 */
#define PAINT_FACTOR 16
#define PAINT_ALLOWANCE (1u << 24)

/* ------------------------------------------------------------------ */
/* input                                                               */

typedef struct {
	io_glue *io;
	unsigned char buffer[INPUT_BUFFER_SIZE];
	size_t position;
	size_t length;
	int pushed_back[2];
	int pushed_count;
	int at_end;
	int failed;
} input;

static void
input_init(input *in, io_glue *io) {
	in->io = io;
	in->position = 0;
	in->length = 0;
	in->pushed_count = 0;
	in->at_end = 0;
	in->failed = 0;
}

static int
input_refill(input *in) {
	ssize_t got;

	if (in->at_end)
		return 0;
	got = i_io_read(in->io, in->buffer, sizeof(in->buffer));
	if (got <= 0) {
		if (got < 0) {
			i_push_error(0, "read failed");
			in->failed = 1;
		}
		in->at_end = 1;
		return 0;
	}
	in->position = 0;
	in->length = (size_t)got;
	return 1;
}

/* Returns the next byte or CHAR_EOF. */
static inline int
input_next(input *in) {
	if (in->pushed_count)
		return in->pushed_back[--in->pushed_count];
	if (in->position == in->length && !input_refill(in))
		return CHAR_EOF;
	return in->buffer[in->position++];
}

/* Returns c to the input; at most two bytes may be pending. */
static void
input_push_back(input *in, int c) {
	in->pushed_back[in->pushed_count++] = c;
}

/* Consumes the byte after an ESC that ends a control string. Unless the
 * pair is the string terminator ESC \ it begins a new escape sequence,
 * which is returned to the input for the search for the next image.
 */
static void
finish_escape(input *in) {
	int c = input_next(in);

	if (c == '\\' || c == CHAR_EOF)
		return;
	input_push_back(in, c);
	input_push_back(in, CHAR_ESC);
}

/* ------------------------------------------------------------------ */
/* control string framing                                              */

typedef enum {
	FOUND_SIXEL,
	FOUND_NOTHING
} search_result;

/* count reaches MAX_PARAMS + 1 once further parameters are ignored */
typedef struct {
	int count;
	int value[MAX_PARAMS];
} params;

static int
is_digit(int c) {
	return c >= '0' && c <= '9';
}

static void
params_reset(params *p) {
	p->count = 1;
	p->value[0] = 0;
}

/* Accumulates a parameter byte (a digit or ';'). */
static void
params_add(params *p, int c) {
	int *v;

	if (c == ';') {
		if (p->count < MAX_PARAMS)
			p->value[p->count] = 0;
		if (p->count <= MAX_PARAMS)
			p->count++;
		return;
	}
	if (p->count > MAX_PARAMS)
		return;
	v = p->value + p->count - 1;
	*v = *v > (PARAM_LIMIT - 9) / 10 ? PARAM_LIMIT : *v * 10 + (c - '0');
}

static int
param_or(const params *p, int index, int fallback) {
	return index < p->count && index < MAX_PARAMS ? p->value[index] : fallback;
}

/* Skips the rest of a control string. */
static void
skip_control_string(input *in) {
	for (;;) {
		int c = input_next(in);
		switch (c) {
		case CHAR_EOF:
		case CHAR_ST:
		case CHAR_CAN:
		case CHAR_SUB:
			return;
		case CHAR_ESC:
			finish_escape(in);
			return;
		}
	}
}

/* Reads the parameters and final byte of a control string that has
 * been introduced. Returns 1 for a sixel string, leaving the input at
 * the start of its data, and 0 after skipping anything else.
 */
static int
read_dcs_header(input *in, params *header) {
	int plain = 1;

	params_reset(header);
	for (;;) {
		int c = input_next(in);

		if (c == CHAR_EOF || c == CHAR_CAN || c == CHAR_SUB)
			return 0;
		if (c == CHAR_ESC) {
			input_push_back(in, c);
			return 0;
		}
		if (c == CHAR_ST)
			return 0;
		if (is_digit(c) || c == ';') {
			params_add(header, c);
		}
		else if (c >= 0x20 && c <= 0x2F) {
			plain = 0;              /* intermediate */
		}
		else if (c >= 0x3C && c <= 0x3F) {
			plain = 0;              /* private marker */
		}
		else if (c >= 0x40 && c <= 0x7E) {
			if (plain && c == 'q')
				return 1;
			skip_control_string(in);
			return 0;
		}
		/* other control characters are ignored */
	}
}

/* The number of continuation bytes following a UTF-8 lead byte. */
static int
utf8_continuations(int c) {
	if (c >= 0xC2 && c <= 0xDF)
		return 1;
	if (c >= 0xE0 && c <= 0xEF)
		return 2;
	if (c >= 0xF0 && c <= 0xF4)
		return 3;
	return 0;
}

/* Advances to the data of the next sixel control string. A byte 0x90
 * that continues a UTF-8 character in the surrounding text is not a
 * control string introducer.
 */
static search_result
find_sixel(input *in, params *header) {
	int continuations = 0;

	for (;;) {
		int c = input_next(in);

		if (continuations && c >= 0x80 && c <= 0xBF) {
			--continuations;
			continue;
		}
		continuations = utf8_continuations(c);
		if (c == CHAR_EOF)
			return FOUND_NOTHING;
		if (c == CHAR_ESC) {
			c = input_next(in);
			if (c == 'P') {
				if (read_dcs_header(in, header))
					return FOUND_SIXEL;
			}
			else if (c != CHAR_EOF) {
				input_push_back(in, c);
			}
		}
		else if (c == CHAR_DCS) {
			if (read_dcs_header(in, header))
				return FOUND_SIXEL;
		}
	}
}

/* ------------------------------------------------------------------ */
/* colour registers                                                    */

/* the VT340 power-on colour map, in percent */
static const unsigned char vt340_colors[16][3] = {
	{  0,  0,  0 }, { 20, 20, 80 }, { 80, 13, 13 }, { 20, 80, 20 },
	{ 80, 20, 80 }, { 20, 80, 80 }, { 80, 80, 20 }, { 53, 53, 53 },
	{ 26, 26, 26 }, { 33, 33, 60 }, { 60, 26, 26 }, { 33, 60, 33 },
	{ 60, 33, 60 }, { 33, 60, 60 }, { 60, 60, 33 }, { 80, 80, 80 },
};

static unsigned char
sample_from_percent(int percent) {
	if (percent > 100)
		percent = 100;
	return (unsigned char)((percent * 255 + 50) / 100);
}

static unsigned char
sample_from_unit(double value) {
	return (unsigned char)floor(value * 255.0 + 0.5);
}

static double
hls_component(double low, double high, double hue) {
	if (hue < 0)
		hue += 360;
	if (hue >= 360)
		hue -= 360;
	if (hue < 60)
		return low + (high - low) * hue / 60;
	if (hue < 180)
		return high;
	if (hue < 240)
		return low + (high - low) * (240 - hue) / 60;
	return low;
}

/* Converts a DEC HLS colour (hue 0..360 with blue at 0, lightness and
 * saturation 0..100) to RGB.
 */
static void
hls_to_rgb(int hue, int lightness, int saturation, unsigned char *rgb) {
	double l = (lightness > 100 ? 100 : lightness) / 100.0;
	double s = (saturation > 100 ? 100 : saturation) / 100.0;
	double h = fmod(hue + 240.0, 360.0);    /* rotate blue from 0 to 240 */
	double high = l <= 0.5 ? l * (1 + s) : l + s - l * s;
	double low = 2 * l - high;

	rgb[0] = sample_from_unit(hls_component(low, high, h + 120));
	rgb[1] = sample_from_unit(hls_component(low, high, h));
	rgb[2] = sample_from_unit(hls_component(low, high, h - 120));
}

/* ------------------------------------------------------------------ */
/* canvas                                                              */

/* A colour a register held while painting. Redefining a register that
 * has painted pixels starts a new colour, so pixels keep the colour
 * they were painted with.
 */
typedef struct {
	unsigned char rgb[3];
	unsigned char painted;
} color_entry;

typedef struct {
	uint16_t register_color[REGISTER_COUNT];
	color_entry *colors;
	size_t color_count;
	size_t color_capacity;
	uint16_t *pixels;
	i_img_dim allocated_width;
	i_img_dim allocated_height;
	i_img_dim painted_width;    /* one past the rightmost painted pixel */
	i_img_dim painted_height;   /* one past the lowest painted pixel */
	i_img_dim declared_width;
	i_img_dim declared_height;
	i_img_dim x;
	i_img_dim y;
	int current;
	int transparent;
	int pan;
	int pad;
	int seen_data;
	uint64_t painted;           /* pixel writes so far */
	/* Imager's file limits, 0 meaning unlimited */
	i_img_dim limit_width;
	i_img_dim limit_height;
	size_t limit_bytes;
} canvas;

/* The pixel aspect ratio selected by P1 of the control string. */
static void
aspect_from_p1(int p1, int *pan, int *pad) {
	*pad = 1;
	switch (p1) {
	case 2:
		*pan = 5;
		break;
	case 3:
	case 4:
		*pan = 3;
		break;
	case 7:
	case 8:
	case 9:
		*pan = 1;
		break;
	default:
		*pan = 2;
		break;
	}
}

static int
canvas_init(canvas *cv, const params *header) {
	int i;

	cv->pixels = NULL;
	cv->color_capacity = 2 * REGISTER_COUNT;
	cv->colors = calloc(cv->color_capacity, sizeof(*cv->colors));
	if (!cv->colors) {
		i_push_error(0, "out of memory");
		return 0;
	}
	cv->color_count = REGISTER_COUNT;
	for (i = 0; i < REGISTER_COUNT; ++i)
		cv->register_color[i] = (uint16_t)i;
	for (i = 0; i < 16; ++i) {
		cv->colors[i].rgb[0] = sample_from_percent(vt340_colors[i][0]);
		cv->colors[i].rgb[1] = sample_from_percent(vt340_colors[i][1]);
		cv->colors[i].rgb[2] = sample_from_percent(vt340_colors[i][2]);
	}
	cv->allocated_width = cv->allocated_height = 0;
	cv->painted_width = cv->painted_height = 0;
	cv->declared_width = cv->declared_height = 0;
	cv->x = cv->y = 0;
	cv->current = INITIAL_REGISTER;
	cv->transparent = param_or(header, 1, 0) == 1;
	cv->seen_data = 0;
	cv->painted = 0;
	aspect_from_p1(param_or(header, 0, 0), &cv->pan, &cv->pad);
	i_get_image_file_limits(&cv->limit_width, &cv->limit_height, &cv->limit_bytes);
	return 1;
}

static void
canvas_release(canvas *cv) {
	free(cv->pixels);
	free(cv->colors);
	cv->pixels = NULL;
	cv->colors = NULL;
}

/* Checks a size against the file limits, pushing Imager's error. */
static int
dimensions_allowed(i_img_dim width, i_img_dim height, int transparent) {
	if (width > PARAM_LIMIT || height > PARAM_LIMIT) {
		i_push_error(0, "image dimensions are too large");
		return 0;
	}
	return i_int_check_image_file_limits(width, height, transparent ? 4 : 3, sizeof(i_sample_t));
}

/* The same check without reporting, for choosing allocation sizes. */
static int
within_limits(const canvas *cv, i_img_dim width, i_img_dim height) {
	size_t channels = cv->transparent ? 4 : 3;

	if (width > PARAM_LIMIT || height > PARAM_LIMIT)
		return 0;
	if ((cv->limit_width && width > cv->limit_width) || (cv->limit_height && height > cv->limit_height))
		return 0;
	return !cv->limit_bytes || (size_t)width * (size_t)height * channels <= cv->limit_bytes;
}

/* The largest width within the limits for a canvas of the given height. */
static i_img_dim
largest_width(const canvas *cv, i_img_dim height) {
	i_img_dim largest = PARAM_LIMIT;
	size_t channels = cv->transparent ? 4 : 3;

	if (cv->limit_width && cv->limit_width < largest)
		largest = cv->limit_width;
	if (cv->limit_bytes && (size_t)largest * (size_t)height * channels > cv->limit_bytes)
		largest = (i_img_dim)(cv->limit_bytes / ((size_t)height * channels));
	return largest;
}

/* The largest height within the limits for a canvas of the given width. */
static i_img_dim
largest_height(const canvas *cv, i_img_dim width) {
	i_img_dim largest = PARAM_LIMIT;
	size_t channels = cv->transparent ? 4 : 3;

	if (cv->limit_height && cv->limit_height < largest)
		largest = cv->limit_height;
	if (cv->limit_bytes && (size_t)largest * (size_t)width * channels > cv->limit_bytes)
		largest = (i_img_dim)(cv->limit_bytes / ((size_t)width * channels));
	return largest;
}

static i_img_dim
clamp_dimension(i_img_dim value, i_img_dim low, i_img_dim high) {
	return value > high ? (high > low ? high : low) : value;
}

/* Moves the pixels to storage of new_width x new_height. Storage that
 * only grows in height is reallocated in place.
 */
static int
canvas_resize(canvas *cv, i_img_dim new_width, i_img_dim new_height) {
	size_t old_count = (size_t)cv->allocated_width * (size_t)cv->allocated_height;
	size_t new_count;
	uint16_t *pixels;
	i_img_dim y;

	if ((size_t)new_height > SIZE_MAX / sizeof(uint16_t) / (size_t)new_width) {
		i_push_error(0, "image dimensions are too large");
		return 0;
	}
	new_count = (size_t)new_width * (size_t)new_height;

	if (new_width == cv->allocated_width) {
		pixels = realloc(cv->pixels, new_count * sizeof(uint16_t));
		if (!pixels) {
			i_push_error(0, "out of memory");
			return 0;
		}
		memset(pixels + old_count, 0xFF, (new_count - old_count) * sizeof(uint16_t));
	}
	else {
		pixels = malloc(new_count * sizeof(uint16_t));
		if (!pixels) {
			i_push_error(0, "out of memory");
			return 0;
		}
		memset(pixels, 0xFF, new_count * sizeof(uint16_t));
		for (y = 0; y < cv->allocated_height; ++y) {
			memcpy(pixels + (size_t)y * new_width,
			       cv->pixels + (size_t)y * cv->allocated_width,
			       (size_t)cv->allocated_width * sizeof(uint16_t));
		}
		free(cv->pixels);
	}
	cv->pixels = pixels;
	cv->allocated_width = new_width;
	cv->allocated_height = new_height;
	return 1;
}

/* Grows the pixel storage to at least width x height. Each growing
 * axis is doubled or, when that breaks a limit, grown to the largest
 * size within the limits, so storage is moved O(log n) times. The
 * first allocation also covers the declared size, so that images
 * painted within it are never moved.
 */
static int
canvas_reserve(canvas *cv, i_img_dim width, i_img_dim height) {
	i_img_dim needed_width, needed_height, new_width, new_height;

	if (width <= cv->allocated_width && height <= cv->allocated_height)
		return 1;
	if (!cv->pixels) {
		if (width < cv->declared_width)
			width = cv->declared_width;
		if (height < cv->declared_height)
			height = cv->declared_height;
	}
	needed_width = width > cv->allocated_width ? width : cv->allocated_width;
	needed_height = height > cv->allocated_height ? height : cv->allocated_height;
	if (!dimensions_allowed(needed_width, needed_height, cv->transparent))
		return 0;

	new_width = needed_width > cv->allocated_width && needed_width < 2 * cv->allocated_width
		? 2 * cv->allocated_width : needed_width;
	new_height = needed_height > cv->allocated_height && needed_height < 2 * cv->allocated_height
		? 2 * cv->allocated_height : needed_height;
	if (!within_limits(cv, new_width, new_height)) {
		new_width = clamp_dimension(new_width, needed_width, largest_width(cv, needed_height));
		new_height = clamp_dimension(new_height, needed_height, largest_height(cv, new_width));
		if (!within_limits(cv, new_width, new_height)) {
			new_width = needed_width;
			new_height = needed_height;
		}
	}
	return canvas_resize(cv, new_width, new_height);
}

static i_img_dim
advance(i_img_dim position, i_img_dim distance) {
	return position + distance > PARAM_LIMIT ? PARAM_LIMIT : position + distance;
}

/* Paints the sixel bits at the cursor repeat times and advances it. */
static int
canvas_paint(canvas *cv, int bits, int repeat) {
	i_img_dim right, bottom, y;
	int top_row = 0;
	int bottom_row = 5;

	cv->seen_data = 1;
	if (bits == 0) {
		cv->x = advance(cv->x, repeat);
		return 1;
	}

	while (!(bits & (1 << top_row)))
		++top_row;
	while (!(bits & (1 << bottom_row)))
		--bottom_row;

	right = cv->x + repeat;
	bottom = cv->y + bottom_row + 1;
	if (right > PARAM_LIMIT || bottom > PARAM_LIMIT) {
		i_push_error(0, "image dimensions are too large");
		return 0;
	}
	if (!canvas_reserve(cv, right, bottom))
		return 0;

	for (y = top_row; y <= bottom_row; ++y)
		cv->painted += (bits >> y) & 1 ? (uint64_t)repeat : 0;
	if (cv->painted > PAINT_FACTOR * (uint64_t)cv->allocated_width * (uint64_t)cv->allocated_height + PAINT_ALLOWANCE) {
		i_push_error(0, "SIXEL data paints too many pixels");
		return 0;
	}

	for (y = top_row; y <= bottom_row; ++y) {
		uint16_t *p, *end;
		if (!(bits & (1 << y)))
			continue;
		p = cv->pixels + (size_t)(cv->y + y) * cv->allocated_width + cv->x;
		end = p + repeat;
		while (p < end)
			*p++ = cv->register_color[cv->current];
	}
	cv->colors[cv->register_color[cv->current]].painted = 1;

	if (right > cv->painted_width)
		cv->painted_width = right;
	if (bottom > cv->painted_height)
		cv->painted_height = bottom;
	cv->x = right;
	return 1;
}

/* Sets the colour of a register. A register whose colour has painted
 * pixels gets a new colour, unless MAX_COLORS have been used, in which
 * case its earlier pixels change as well.
 */
static int
canvas_define_register(canvas *cv, int index, const unsigned char *rgb) {
	color_entry *entry = cv->colors + cv->register_color[index];

	if (entry->painted && cv->color_count < MAX_COLORS) {
		if (cv->color_count == cv->color_capacity) {
			size_t capacity = cv->color_capacity * 2 > MAX_COLORS ? MAX_COLORS : cv->color_capacity * 2;
			color_entry *colors = realloc(cv->colors, capacity * sizeof(*colors));
			if (!colors) {
				i_push_error(0, "out of memory");
				return 0;
			}
			cv->colors = colors;
			cv->color_capacity = capacity;
		}
		cv->register_color[index] = (uint16_t)cv->color_count;
		entry = cv->colors + cv->color_count++;
		entry->painted = 0;
	}
	memcpy(entry->rgb, rgb, 3);
	return 1;
}

/* Selects a register, defining its colour first if the colour space
 * is known.
 */
static int
canvas_select_color(canvas *cv, const params *p) {
	int index = p->value[0] % REGISTER_COUNT;
	int space = param_or(p, 1, 0);
	int x = param_or(p, 2, 0);
	int y = param_or(p, 3, 0);
	int z = param_or(p, 4, 0);
	unsigned char rgb[3];

	cv->current = index;
	if (p->count < 5)
		return 1;

	if (space == 1) {
		hls_to_rgb(x > 360 ? 360 : x, y, z, rgb);
	}
	else if (space == 2) {
		rgb[0] = sample_from_percent(x);
		rgb[1] = sample_from_percent(y);
		rgb[2] = sample_from_percent(z);
	}
	else {
		return 1;       /* other colour spaces leave the register unchanged */
	}
	return canvas_define_register(cv, index, rgb);
}

/* Raster attributes take effect only before the first sixel. */
static int
canvas_raster_attributes(canvas *cv, const params *p) {
	int pan = param_or(p, 0, 0);
	int pad = param_or(p, 1, 0);
	int width = param_or(p, 2, 0);
	int height = param_or(p, 3, 0);

	if (cv->seen_data)
		return 1;

	if (pan > 0 && pad > 0) {
		cv->pan = pan;
		cv->pad = pad;
	}
	if (width > 0 && height > 0) {
		if (!dimensions_allowed(width, height, cv->transparent))
			return 0;
		cv->declared_width = width;
		cv->declared_height = height;
	}
	return 1;
}

/* ------------------------------------------------------------------ */
/* sixel data                                                          */

typedef enum {
	DATA_COMPLETE,
	DATA_TRUNCATED,
	DATA_FAILED
} data_result;

/* Reads parameter bytes, returning the first byte that is not one. A
 * space ends a number, so digits after it start the next parameter.
 * Control characters, such as line breaks, are ignored.
 */
static int
read_params(input *in, params *p) {
	int in_number = 0;
	int number_ended = 0;

	params_reset(p);
	for (;;) {
		int c = input_next(in);
		if (is_digit(c)) {
			if (number_ended)
				params_add(p, ';');
			params_add(p, c);
			in_number = 1;
			number_ended = 0;
		}
		else if (c == ';') {
			params_add(p, c);
			in_number = 0;
			number_ended = 0;
		}
		else if (c == ' ') {
			number_ended = in_number;
		}
		else if (c == CHAR_EOF || c > 0x20 || c == CHAR_ESC || c == CHAR_CAN || c == CHAR_SUB) {
			return c;
		}
	}
}

static int
is_sixel_char(int c) {
	return c >= '?' && c <= '~';
}

static data_result
read_sixel_data(input *in, canvas *cv) {
	params p;
	int c = input_next(in);

	for (;;) {
		if (is_sixel_char(c)) {
			if (!canvas_paint(cv, c - '?', 1))
				return DATA_FAILED;
			c = input_next(in);
			continue;
		}

		switch (c) {
		case CHAR_EOF:
			return in->failed ? DATA_FAILED : DATA_TRUNCATED;

		case CHAR_ST:
		case CHAR_CAN:
		case CHAR_SUB:
			return DATA_COMPLETE;

		case CHAR_ESC:
			/* ESC \ is the string terminator; any other escape
			 * sequence ends the control string as well */
			finish_escape(in);
			return DATA_COMPLETE;

		case '!':
			c = read_params(in, &p);
			if (is_sixel_char(c)) {
				int repeat = p.value[0] ? p.value[0] : 1;
				if (!canvas_paint(cv, c - '?', repeat))
					return DATA_FAILED;
				c = input_next(in);
			}
			continue;

		case '#':
			c = read_params(in, &p);
			if (!canvas_select_color(cv, &p))
				return DATA_FAILED;
			continue;

		case '"':
			c = read_params(in, &p);
			if (!canvas_raster_attributes(cv, &p))
				return DATA_FAILED;
			continue;

		case '$':
			cv->x = 0;
			break;

		case '-':
			cv->x = 0;
			cv->y = advance(cv->y, 6);
			break;

		default:
			/* anything else is ignored */
			break;
		}
		c = input_next(in);
	}
}

/* ------------------------------------------------------------------ */
/* image construction                                                  */

static void
set_tags(i_img *img, const canvas *cv, int incomplete) {
	i_tags_set(&img->tags, "i_format", "sixel", -1);
	i_tags_setn(&img->tags, "sixel_pan", cv->pan);
	i_tags_setn(&img->tags, "sixel_pad", cv->pad);
	if (incomplete)
		i_tags_setn(&img->tags, "i_incomplete", 1);
}

/* Unpainted pixels show the background: transparency, numbered one
 * past the last colour, or the final colour of register 0.
 */
static inline size_t
pixel_color(const canvas *cv, uint16_t value) {
	if (value != UNPAINTED)
		return value;
	return cv->transparent ? cv->color_count : cv->register_color[0];
}

static void
color_value(const canvas *cv, size_t color, i_color *out) {
	if (color == cv->color_count) {
		out->rgba.r = out->rgba.g = out->rgba.b = out->rgba.a = 0;
		return;
	}
	out->rgba.r = cv->colors[color].rgb[0];
	out->rgba.g = cv->colors[color].rgb[1];
	out->rgba.b = cv->colors[color].rgb[2];
	out->rgba.a = 255;
}

static i_img *
build_paletted(const canvas *cv, i_img_dim width, i_img_dim height, int channels,
               const int *palette_index) {
	i_color colors[256];
	int color_count = 0;
	i_palidx *line;
	i_img *img;
	i_img_dim x, y;
	size_t color;

	for (color = 0; color <= cv->color_count; ++color) {
		if (palette_index[color] >= 0)
			color_value(cv, color, colors + color_count++);
	}

	line = malloc((size_t)width * sizeof(*line));
	if (!line) {
		i_push_error(0, "out of memory");
		return NULL;
	}
	img = i_img_pal_new(width, height, channels, 256);
	if (!img) {
		free(line);
		return NULL;
	}
	i_addcolors(img, colors, color_count);

	for (y = 0; y < height; ++y) {
		const uint16_t *row = cv->pixels + (size_t)y * cv->allocated_width;
		for (x = 0; x < width; ++x)
			line[x] = (i_palidx)palette_index[pixel_color(cv, row[x])];
		i_ppal(img, 0, width, y, line);
	}

	free(line);
	return img;
}

static i_img *
build_direct(const canvas *cv, i_img_dim width, i_img_dim height, int channels) {
	unsigned char *line;
	i_img *img;
	i_img_dim x, y;

	line = malloc((size_t)width * channels);
	if (!line) {
		i_push_error(0, "out of memory");
		return NULL;
	}
	img = i_img_8_new(width, height, channels);
	if (!img) {
		free(line);
		return NULL;
	}

	for (y = 0; y < height; ++y) {
		const uint16_t *row = cv->pixels + (size_t)y * cv->allocated_width;
		unsigned char *out = line;
		for (x = 0; x < width; ++x) {
			i_color color;
			color_value(cv, pixel_color(cv, row[x]), &color);
			memcpy(out, color.channel, channels);
			out += channels;
		}
		i_psamp(img, 0, width, y, line, NULL, channels);
	}

	free(line);
	return img;
}

/* Builds a paletted image when at most 256 colours are needed, else a
 * direct colour image.
 */
static i_img *
canvas_to_image(canvas *cv) {
	i_img_dim width = cv->painted_width > cv->declared_width ? cv->painted_width : cv->declared_width;
	i_img_dim height = cv->painted_height > cv->declared_height ? cv->painted_height : cv->declared_height;
	int channels = cv->transparent ? 4 : 3;
	int *palette_index;
	int color_count = 0;
	i_img_dim x, y;
	size_t color;
	i_img *img;

	if (width == 0 || height == 0) {
		i_push_error(0, "SIXEL image contains no pixels");
		return NULL;
	}
	if (!dimensions_allowed(width, height, cv->transparent) || !canvas_reserve(cv, width, height))
		return NULL;

	/* one more for transparency */
	palette_index = malloc((cv->color_count + 1) * sizeof(int));
	if (!palette_index) {
		i_push_error(0, "out of memory");
		return NULL;
	}
	for (color = 0; color <= cv->color_count; ++color)
		palette_index[color] = -1;
	for (y = 0; y < height; ++y) {
		const uint16_t *row = cv->pixels + (size_t)y * cv->allocated_width;
		for (x = 0; x < width; ++x)
			palette_index[pixel_color(cv, row[x])] = 0;
	}
	for (color = 0; color <= cv->color_count; ++color) {
		if (palette_index[color] >= 0)
			palette_index[color] = color_count++;
	}

	img = color_count <= 256
		? build_paletted(cv, width, height, channels, palette_index)
		: build_direct(cv, width, height, channels);
	free(palette_index);
	return img;
}

/* ------------------------------------------------------------------ */
/* public interface                                                    */

typedef enum {
	NEXT_IMAGE,
	NEXT_END,
	NEXT_FAILED
} next_status;

/* Decodes the next sixel image of the input. */
static i_img *
read_next_image(input *in, int allow_incomplete, next_status *status) {
	params header;
	canvas cv;
	data_result result;
	i_img *img;

	if (find_sixel(in, &header) == FOUND_NOTHING) {
		*status = in->failed ? NEXT_FAILED : NEXT_END;
		return NULL;
	}

	if (!canvas_init(&cv, &header)) {
		*status = NEXT_FAILED;
		return NULL;
	}
	result = read_sixel_data(in, &cv);
	if (result == DATA_TRUNCATED && !allow_incomplete) {
		i_push_error(0, "premature end of SIXEL data");
		result = DATA_FAILED;
	}
	img = result == DATA_FAILED ? NULL : canvas_to_image(&cv);
	canvas_release(&cv);

	if (!img) {
		*status = NEXT_FAILED;
		return NULL;
	}
	set_tags(img, &cv, result == DATA_TRUNCATED);
	*status = NEXT_IMAGE;
	return img;
}

i_img *
i_readsixel(io_glue *ig, int page, int allow_incomplete) {
	input *in;
	next_status status = NEXT_END;
	i_img *img = NULL;
	int skipped;

	i_clear_error();
	if (page < 0) {
		i_push_error(0, "page must be a non-negative integer");
		return NULL;
	}
	in = malloc(sizeof(*in));
	if (!in) {
		i_push_error(0, "out of memory");
		return NULL;
	}
	input_init(in, ig);

	for (skipped = 0; skipped < page; ++skipped) {
		params header;
		if (find_sixel(in, &header) == FOUND_NOTHING)
			break;
		skip_control_string(in);
	}
	if (skipped == page)
		img = read_next_image(in, allow_incomplete, &status);
	if (!img && status != NEXT_FAILED && !in->failed) {
		if (page == 0)
			i_push_error(0, "no SIXEL image found");
		else
			i_push_errorf(0, "SIXEL page %d not found", page);
	}

	free(in);
	return img;
}

i_img **
i_readsixel_multi(io_glue *ig, int *count, int allow_incomplete) {
	input *in;
	i_img **imgs = NULL;
	int allocated = 0;
	next_status status;

	i_clear_error();
	*count = 0;
	in = malloc(sizeof(*in));
	if (!in) {
		i_push_error(0, "out of memory");
		return NULL;
	}
	input_init(in, ig);

	for (;;) {
		i_img *img = read_next_image(in, allow_incomplete, &status);
		if (!img)
			break;
		if (*count == allocated) {
			allocated = allocated ? allocated * 2 : 4;
			imgs = imgs ? myrealloc(imgs, allocated * sizeof(*imgs))
			            : mymalloc(allocated * sizeof(*imgs));
		}
		imgs[(*count)++] = img;
	}
	free(in);

	if (status == NEXT_FAILED || *count == 0) {
		int i;
		if (status != NEXT_FAILED)
			i_push_error(0, "no SIXEL image found");
		for (i = 0; i < *count; ++i)
			i_img_destroy(imgs[i]);
		myfree(imgs);
		*count = 0;
		return NULL;
	}
	return imgs;
}
