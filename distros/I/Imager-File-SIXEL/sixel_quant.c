/*
 * Imager::File::SIXEL - colour quantization used by the SIXEL encoder.
 *
 * Copyright (C) 2026 davenonymous.
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself.
 *
 * Palette construction:
 *
 *   exact     - images with few colours keep them, rounded to SIXEL
 *               percentages; colours that round alike share an entry.
 *   adaptive  - a 5/6/5 bit histogram is split into boxes, always
 *               splitting the box whose best axis aligned cut removes
 *               the most squared error (a greedy variant of Wu's
 *               quantizer). Each box contributes its mean colour.
 *   webmap    - the fixed 6x6x6 web-safe cube.
 *
 * Pixel mapping uses a lazily filled 6/6/6 bit lookup table over cells
 * of 4 x 4 x 4 colours. When dithering, a cell maps all its colours to
 * the entry nearest to its centre; the dither absorbs the difference.
 * Without dithering every colour is mapped to its exactly nearest
 * entry: a cell holds either the entry nearest to all its colours or a
 * list of the entries that can be nearest to one of them, with the
 * answer for each colour cached once found.
 */
#include "sixel_quant.h"

#include <limits.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>

#define PIXEL_PAINTED(p) ((p)[3] != 0)

int
sixel_percent_from_sample(int sample) {
	return (sample * 100 + 127) / 255;
}

int
sixel_sample_from_percent(int percent) {
	return (percent * 255 + 50) / 100;
}

static unsigned char
snapped_sample(int sample) {
	return (unsigned char)sixel_sample_from_percent(sixel_percent_from_sample(sample));
}

void
sixel_palette_snap(sixel_palette *palette) {
	int i, c;

	for (i = 0; i < palette->size; ++i) {
		for (c = 0; c < 3; ++c)
			palette->rgb[i][c] = snapped_sample(palette->rgb[i][c]);
	}
}

void
sixel_palette_webmap(sixel_palette *palette) {
	int r, g, b;
	int n = 0;

	for (r = 0; r < 6; ++r) {
		for (g = 0; g < 6; ++g) {
			for (b = 0; b < 6; ++b) {
				palette->rgb[n][0] = (unsigned char)(r * 51);
				palette->rgb[n][1] = (unsigned char)(g * 51);
				palette->rgb[n][2] = (unsigned char)(b * 51);
				++n;
			}
		}
	}
	palette->size = n;
}

/* ------------------------------------------------------------------ */
/* exact palettes                                                      */

#define EXACT_HASH_BITS 10
#define EXACT_HASH_SIZE (1 << EXACT_HASH_BITS)
#define EXACT_KEY_USED 0x01000000u

typedef struct {
	uint32_t key[EXACT_HASH_SIZE];
	uint16_t index[EXACT_HASH_SIZE];
} exact_table;

static uint32_t
exact_slot(uint32_t key) {
	return (key * 2654435761u) >> (32 - EXACT_HASH_BITS);
}

int
sixel_palette_exact(const unsigned char *rgba, size_t pixel_count, int max_colors,
                    sixel_palette *palette, uint16_t *map) {
	exact_table table;
	unsigned char snapped[256];
	uint32_t last_pixel = 0;
	uint16_t last_index = 0;
	size_t i;
	int sample;

	memset(table.key, 0, sizeof(table.key));
	for (sample = 0; sample < 256; ++sample)
		snapped[sample] = snapped_sample(sample);
	palette->size = 0;

	for (i = 0; i < pixel_count; ++i, rgba += 4) {
		uint32_t pixel, key, slot;

		if (!PIXEL_PAINTED(rgba)) {
			map[i] = SIXEL_TRANSPARENT;
			continue;
		}
		pixel = EXACT_KEY_USED | ((uint32_t)rgba[0] << 16) | ((uint32_t)rgba[1] << 8) | rgba[2];
		if (pixel == last_pixel) {
			map[i] = last_index;
			continue;
		}

		/* colours are counted as SIXEL writes them */
		key = EXACT_KEY_USED | ((uint32_t)snapped[rgba[0]] << 16) | ((uint32_t)snapped[rgba[1]] << 8)
		      | snapped[rgba[2]];
		slot = exact_slot(key);
		while (table.key[slot] != 0 && table.key[slot] != key)
			slot = (slot + 1) & (EXACT_HASH_SIZE - 1);

		if (table.key[slot] == 0) {
			if (palette->size >= max_colors)
				return 0;
			table.key[slot] = key;
			table.index[slot] = (uint16_t)palette->size;
			palette->rgb[palette->size][0] = snapped[rgba[0]];
			palette->rgb[palette->size][1] = snapped[rgba[1]];
			palette->rgb[palette->size][2] = snapped[rgba[2]];
			++palette->size;
		}
		last_pixel = pixel;
		last_index = table.index[slot];
		map[i] = last_index;
	}

	return 1;
}

/* ------------------------------------------------------------------ */
/* nearest colour search                                               */

/* A palette ordered by green, so a search can start at the query's
 * green value and stop once the green difference alone exceeds the
 * best distance found. Coordinates are doubled so that the centres of
 * lookup table cells are integers.
 */
typedef struct {
	const sixel_palette *palette;
	int by_green[SIXEL_MAX_PALETTE];
	int green2[SIXEL_MAX_PALETTE];
} green_order;

static void
green_order_init(green_order *order, const sixel_palette *palette) {
	int i;

	order->palette = palette;
	/* insertion sort by green, ties by index; palettes are small */
	for (i = 0; i < palette->size; ++i) {
		int green2 = 2 * palette->rgb[i][1];
		int j = i;
		while (j > 0 && order->green2[j - 1] > green2) {
			order->green2[j] = order->green2[j - 1];
			order->by_green[j] = order->by_green[j - 1];
			--j;
		}
		order->green2[j] = green2;
		order->by_green[j] = i;
	}
}

/* Returns the first position in the green order whose green is not
 * below g2.
 */
static int
green_position(const green_order *order, int g2) {
	int lo = 0;
	int hi = order->palette->size;

	while (lo < hi) {
		int mid = (lo + hi) / 2;
		if (order->green2[mid] < g2)
			lo = mid + 1;
		else
			hi = mid;
	}
	return lo;
}

static inline void
consider_entry(const green_order *order, int position, int r2, int g2, int b2,
               int *best, int *best_index) {
	int index = order->by_green[position];
	const unsigned char *entry = order->palette->rgb[index];
	int dr = 2 * entry[0] - r2;
	int dg = 2 * entry[1] - g2;
	int db = 2 * entry[2] - b2;
	int d = dr * dr + dg * dg + db * db;

	if (d < *best || (d == *best && index < *best_index)) {
		*best = d;
		*best_index = index;
	}
}

/* Returns the index of the palette entry nearest to the doubled
 * coordinates (r2, g2, b2), preferring the lowest index on ties.
 */
static int
nearest_entry(const green_order *order, int r2, int g2, int b2) {
	int size = order->palette->size;
	int best = INT_MAX;
	int best_index = 0;
	int up = green_position(order, g2);
	int down = up - 1;

	while (up < size || down >= 0) {
		if (up < size) {
			int dg = order->green2[up] - g2;
			if (dg * dg > best)
				up = size;
			else
				consider_entry(order, up++, r2, g2, b2, &best, &best_index);
		}
		if (down >= 0) {
			int dg = g2 - order->green2[down];
			if (dg * dg > best)
				down = -1;
			else
				consider_entry(order, down--, r2, g2, b2, &best, &best_index);
		}
	}
	return best_index;
}

/* Blocks of 16 x 16 x 16 colours, whose diameter in doubled
 * coordinates is 2 * sqrt(3 * 15 * 15).
 */
#define BLOCK_SHIFT 4
#define BLOCK_COUNT (1 << (3 * (8 - BLOCK_SHIFT)))
#define BLOCK_KEY(r, g, b) \
	((((unsigned)(r) >> BLOCK_SHIFT) << 8) | (((unsigned)(g) >> BLOCK_SHIFT) << 4) | ((unsigned)(b) >> BLOCK_SHIFT))
#define BLOCK_DIAMETER2 52.0

/* A growable array of palette indices. */
typedef struct {
	unsigned char *items;
	size_t used;
	size_t capacity;
} index_pool;

/* Makes room for count more items of size bytes in a growable array. */
static int
reserve_items(void **items, size_t *capacity, size_t used, size_t count, size_t size) {
	size_t wanted = *capacity ? *capacity : 1024;
	void *grown;

	if (used + count <= *capacity)
		return 1;
	while (wanted < used + count)
		wanted *= 2;
	grown = realloc(*items, wanted * size);
	if (!grown)
		return 0;
	*items = grown;
	*capacity = wanted;
	return 1;
}

/* Appends to pool the entries among candidates (all entries if
 * candidates is NULL) within distance limit2 (squared, doubled
 * coordinates) of (r2, g2, b2). Returns the number appended, or -1 if
 * the pool cannot grow.
 */
static int
collect_candidates(const green_order *order, const unsigned char *candidates, int count,
                   int r2, int g2, int b2, int limit2, index_pool *pool) {
	const sixel_palette *palette = order->palette;
	int collected = 0;
	int i;

	if (!candidates)
		count = palette->size;
	if (!reserve_items((void **)&pool->items, &pool->capacity, pool->used, (size_t)count, 1))
		return -1;

	for (i = 0; i < count; ++i) {
		int index = candidates ? candidates[i] : i;
		const unsigned char *entry = palette->rgb[index];
		int dr = 2 * entry[0] - r2;
		int dg = 2 * entry[1] - g2;
		int db = 2 * entry[2] - b2;

		if (dr * dr + dg * dg + db * db <= limit2)
			pool->items[pool->used + collected++] = (unsigned char)index;
	}
	return collected;
}

/* The nearest of the candidate entries to (r2, g2, b2) in doubled
 * coordinates, preferring the lowest index on ties.
 */
static int
nearest_candidate(const sixel_palette *palette, const unsigned char *candidates, int count,
                  int r2, int g2, int b2) {
	int best = INT_MAX;
	int best_index = 0;
	int i;

	for (i = 0; i < count; ++i) {
		int index = candidates[i];
		const unsigned char *entry = palette->rgb[index];
		int dr = 2 * entry[0] - r2;
		int dg = 2 * entry[1] - g2;
		int db = 2 * entry[2] - b2;
		int d = dr * dr + dg * dg + db * db;
		if (d < best || (d == best && index < best_index)) {
			best = d;
			best_index = index;
		}
	}
	return best_index;
}

/* The squared reach, in doubled coordinates, within which an entry may
 * be nearest to some colour of a region: the distance from the region's
 * centre to its nearest entry plus the region's diameter.
 */
static int
candidate_reach(const sixel_palette *palette, int nearest, int r2, int g2, int b2, double diameter) {
	const unsigned char *entry = palette->rgb[nearest];
	int dr = 2 * entry[0] - r2;
	int dg = 2 * entry[1] - g2;
	int db = 2 * entry[2] - b2;
	double reach = sqrt((double)(dr * dr + dg * dg + db * db)) + diameter;

	return (int)ceil(reach * reach);
}

/* For each block of 16 x 16 x 16 colours, the palette entries that may
 * be nearest to one of its colours, found on first use.
 */
typedef struct {
	green_order order;
	/* one past the start of a block's candidates in blocks, or 0 while
	 * unknown, and their number */
	size_t block_first[BLOCK_COUNT];
	uint16_t block_size[BLOCK_COUNT];
	index_pool blocks;
} block_index;

static void
block_index_init(block_index *index, const sixel_palette *palette) {
	green_order_init(&index->order, palette);
	memset(index->block_first, 0, sizeof(index->block_first));
	index->blocks.items = NULL;
	index->blocks.used = 0;
	index->blocks.capacity = 0;
}

static void
block_index_release(block_index *index) {
	free(index->blocks.items);
	index->blocks.items = NULL;
}

/* Returns the entries that may be nearest to some colour of the block
 * containing (r, g, b), computing them on first use, and their number
 * in *count; NULL if memory ran out.
 */
static const unsigned char *
block_candidates(block_index *index, int r, int g, int b, int *count) {
	unsigned key = BLOCK_KEY(r, g, b);
	int block = 1 << BLOCK_SHIFT;

	if (!index->block_first[key]) {
		int r2 = 2 * (r & ~(block - 1)) + block - 1;
		int g2 = 2 * (g & ~(block - 1)) + block - 1;
		int b2 = 2 * (b & ~(block - 1)) + block - 1;
		int nearest = nearest_entry(&index->order, r2, g2, b2);
		int limit2 = candidate_reach(index->order.palette, nearest, r2, g2, b2, BLOCK_DIAMETER2);
		int collected = collect_candidates(&index->order, NULL, 0, r2, g2, b2, limit2, &index->blocks);

		if (collected < 0)
			return NULL;
		index->block_first[key] = index->blocks.used + 1;
		index->block_size[key] = (uint16_t)collected;
		index->blocks.used += (size_t)collected;
	}
	*count = index->block_size[key];
	return index->blocks.items + index->block_first[key] - 1;
}

/* Returns the entry nearest to (r2, g2, b2) in doubled coordinates,
 * preferring the lowest index on ties.
 */
static int
nearest_color(block_index *index, int r2, int g2, int b2) {
	int count = 0;
	const unsigned char *candidates = block_candidates(index, r2 / 2, g2 / 2, b2 / 2, &count);

	return candidates
		? nearest_candidate(index->order.palette, candidates, count, r2, g2, b2)
		: nearest_entry(&index->order, r2, g2, b2);
}


/* ------------------------------------------------------------------ */
/* adaptive palettes                                                   */

#define HIST_SHIFT_R 3
#define HIST_SHIFT_G 2
#define HIST_SHIFT_B 3
#define HIST_KEY(r, g, b) \
	((((unsigned)(r) >> HIST_SHIFT_R) << 11) | (((unsigned)(g) >> HIST_SHIFT_G) << 5) | ((unsigned)(b) >> HIST_SHIFT_B))
#define HIST_SIZE (1 << 16)
#define HIST_MAX_LEVELS 64
#define REFINE_ITERATIONS 2

static const int hist_levels[3] = { 32, 64, 32 };

typedef struct {
	uint64_t sum[3];
	uint64_t count;
	unsigned char coord[3];
} hist_bin;

typedef struct {
	size_t start;
	size_t end;
	double count;
	double sum[3];
	double gain;
	int axis;
	int cut;
} color_box;

typedef struct {
	double count;
	double sum[3];
} box_moments;

static double
moments_energy(const box_moments *m) {
	return (m->sum[0] * m->sum[0] + m->sum[1] * m->sum[1] + m->sum[2] * m->sum[2]) / m->count;
}

/* Sums the bins of box and records the axis aligned cut that removes
 * the most squared error, or a gain of 0 when the box cannot be split.
 */
static void
box_analyze(color_box *box, const hist_bin *bins) {
	box_moments buckets[HIST_MAX_LEVELS];
	box_moments total;
	double total_energy;
	size_t i;
	int axis;

	memset(&total, 0, sizeof(total));
	for (i = box->start; i < box->end; ++i) {
		total.count += (double)bins[i].count;
		total.sum[0] += (double)bins[i].sum[0];
		total.sum[1] += (double)bins[i].sum[1];
		total.sum[2] += (double)bins[i].sum[2];
	}
	box->count = total.count;
	memcpy(box->sum, total.sum, sizeof(box->sum));
	box->gain = 0;
	box->axis = -1;
	box->cut = 0;

	if (box->end - box->start < 2)
		return;

	total_energy = moments_energy(&total);
	for (axis = 0; axis < 3; ++axis) {
		box_moments left;
		int levels = hist_levels[axis];
		int t;

		memset(buckets, 0, sizeof(buckets[0]) * levels);
		for (i = box->start; i < box->end; ++i) {
			box_moments *bucket = buckets + bins[i].coord[axis];
			bucket->count += (double)bins[i].count;
			bucket->sum[0] += (double)bins[i].sum[0];
			bucket->sum[1] += (double)bins[i].sum[1];
			bucket->sum[2] += (double)bins[i].sum[2];
		}

		memset(&left, 0, sizeof(left));
		for (t = 0; t < levels - 1; ++t) {
			box_moments right;
			double gain;
			int c;

			left.count += buckets[t].count;
			for (c = 0; c < 3; ++c)
				left.sum[c] += buckets[t].sum[c];
			if (left.count == 0)
				continue;
			right.count = total.count - left.count;
			if (right.count <= 0)
				break;
			for (c = 0; c < 3; ++c)
				right.sum[c] = total.sum[c] - left.sum[c];

			gain = moments_energy(&left) + moments_energy(&right) - total_energy;
			if (gain > box->gain) {
				box->gain = gain;
				box->axis = axis;
				box->cut = t;
			}
		}
	}
}

/* Moves the bins of box whose coordinate on the cut axis is at most
 * the cut to the front and returns the index of the first other bin.
 */
static size_t
box_partition(const color_box *box, hist_bin *bins) {
	size_t lo = box->start;
	size_t hi = box->end;

	while (lo < hi) {
		if (bins[lo].coord[box->axis] <= box->cut) {
			++lo;
		}
		else {
			hist_bin swap = bins[lo];
			bins[lo] = bins[--hi];
			bins[hi] = swap;
		}
	}
	return lo;
}

/* Collects the occupied histogram bins of the painted pixels. */
static hist_bin *
histogram_collect(const unsigned char *rgba, size_t pixel_count, size_t *bin_count) {
	size_t capacity = pixel_count < HIST_SIZE ? pixel_count : HIST_SIZE;
	uint32_t *slot_of_key;
	hist_bin *bins;
	size_t used = 0;
	size_t i;

	slot_of_key = calloc(HIST_SIZE, sizeof(*slot_of_key));
	bins = malloc(capacity * sizeof(*bins));
	if (!slot_of_key || !bins) {
		free(slot_of_key);
		free(bins);
		return NULL;
	}

	for (i = 0; i < pixel_count; ++i, rgba += 4) {
		unsigned key;
		hist_bin *bin;

		if (!PIXEL_PAINTED(rgba))
			continue;
		key = HIST_KEY(rgba[0], rgba[1], rgba[2]);
		if (slot_of_key[key] == 0) {
			bin = bins + used++;
			memset(bin, 0, sizeof(*bin));
			bin->coord[0] = (unsigned char)(rgba[0] >> HIST_SHIFT_R);
			bin->coord[1] = (unsigned char)(rgba[1] >> HIST_SHIFT_G);
			bin->coord[2] = (unsigned char)(rgba[2] >> HIST_SHIFT_B);
			slot_of_key[key] = (uint32_t)used;
		}
		else {
			bin = bins + slot_of_key[key] - 1;
		}
		bin->count++;
		bin->sum[0] += rgba[0];
		bin->sum[1] += rgba[1];
		bin->sum[2] += rgba[2];
	}

	free(slot_of_key);
	*bin_count = used;
	return bins;
}

static unsigned char
mean_sample(double sum, double count) {
	double mean = sum / count + 0.5;
	return (unsigned char)(mean > 255 ? 255 : mean);
}

/* Moves every palette entry to the mean of the histogram bins nearest
 * to it (Lloyd's algorithm). Entries without bins keep their colour.
 */
static int
palette_refine(const hist_bin *bins, size_t bin_count, sixel_palette *palette) {
	double sums[SIXEL_MAX_PALETTE][4];
	block_index *index = malloc(sizeof(*index));
	int iteration;

	if (!index)
		return 0;

	for (iteration = 0; iteration < REFINE_ITERATIONS; ++iteration) {
		size_t i;
		int k;

		memset(sums, 0, sizeof(sums));
		block_index_init(index, palette);
		for (i = 0; i < bin_count; ++i) {
			const hist_bin *bin = bins + i;
			double count = (double)bin->count;
			int nearest = nearest_color(index,
			                            (int)(2.0 * (double)bin->sum[0] / count + 0.5),
			                            (int)(2.0 * (double)bin->sum[1] / count + 0.5),
			                            (int)(2.0 * (double)bin->sum[2] / count + 0.5));
			sums[nearest][0] += (double)bin->sum[0];
			sums[nearest][1] += (double)bin->sum[1];
			sums[nearest][2] += (double)bin->sum[2];
			sums[nearest][3] += count;
		}
		for (k = 0; k < palette->size; ++k) {
			if (sums[k][3] == 0)
				continue;
			palette->rgb[k][0] = mean_sample(sums[k][0], sums[k][3]);
			palette->rgb[k][1] = mean_sample(sums[k][1], sums[k][3]);
			palette->rgb[k][2] = mean_sample(sums[k][2], sums[k][3]);
		}
		block_index_release(index);
	}
	free(index);
	return 1;
}

int
sixel_palette_adaptive(const unsigned char *rgba, size_t pixel_count, int max_colors,
                       sixel_palette *palette) {
	color_box boxes[SIXEL_MAX_PALETTE];
	size_t bin_count;
	hist_bin *bins;
	int box_count;
	int ok;
	int i;

	bins = histogram_collect(rgba, pixel_count, &bin_count);
	if (!bins)
		return 0;

	palette->size = 0;
	if (bin_count == 0) {
		free(bins);
		return 1;
	}

	boxes[0].start = 0;
	boxes[0].end = bin_count;
	box_analyze(boxes, bins);
	box_count = 1;

	while (box_count < max_colors) {
		color_box *widest = NULL;
		size_t middle;

		for (i = 0; i < box_count; ++i) {
			if (boxes[i].gain > 0 && (!widest || boxes[i].gain > widest->gain))
				widest = boxes + i;
		}
		if (!widest)
			break;

		middle = box_partition(widest, bins);
		boxes[box_count].start = middle;
		boxes[box_count].end = widest->end;
		widest->end = middle;
		box_analyze(widest, bins);
		box_analyze(boxes + box_count, bins);
		++box_count;
	}

	for (i = 0; i < box_count; ++i) {
		palette->rgb[i][0] = mean_sample(boxes[i].sum[0], boxes[i].count);
		palette->rgb[i][1] = mean_sample(boxes[i].sum[1], boxes[i].count);
		palette->rgb[i][2] = mean_sample(boxes[i].sum[2], boxes[i].count);
	}
	palette->size = box_count;
	ok = palette_refine(bins, bin_count, palette);
	sixel_palette_snap(palette);

	free(bins);
	return ok;
}

/* ------------------------------------------------------------------ */
/* lookup table                                                        */

#define LUT_SHIFT 2
#define LUT_SIZE (1 << 18)
#define LUT_KEY(r, g, b) \
	((((unsigned)(r) >> LUT_SHIFT) << 12) | (((unsigned)(g) >> LUT_SHIFT) << 6) | ((unsigned)(b) >> LUT_SHIFT))
#define CELL_COLORS (1 << (3 * LUT_SHIFT))
#define CELL_SLOT(r, g, b) \
	(((((unsigned)(r) & 3) << LUT_SHIFT | ((unsigned)(g) & 3)) << LUT_SHIFT) | ((unsigned)(b) & 3))
/* lookup table values: palette indices, then candidate list numbers */
#define LUT_FIRST_LIST 0x0100
#define LUT_SEARCH 0xFFFE
#define LUT_EMPTY 0xFFFF
#define LUT_MAX_LISTS (LUT_SEARCH - LUT_FIRST_LIST)
#define CHOICE_UNKNOWN 0xFFFF
/* Twice the largest distance, in doubled coordinates, between the
 * centre of a cell and any colour in it: 2 * sqrt(3 * 3 * 3), rounded up.
 */
#define LUT_CELL_DIAMETER2 10.4
/* The palette entries that may be nearest to some colour of a cell,
 * stored in the finder's candidate pool, and the nearest entry of each
 * of the cell's colours once known.
 */
typedef struct {
	size_t first;
	int count;
	uint16_t choice[CELL_COLORS];
} candidate_list;

typedef struct {
	block_index index;
	/* whether to resolve colours exactly or by the cell centre */
	int exact;
	uint16_t *lut;
	candidate_list *lists;
	size_t list_count;
	size_t list_capacity;
	index_pool pool;
} nearest_finder;

static int
nearest_init(nearest_finder *finder, const sixel_palette *palette, int exact) {
	memset(finder, 0, sizeof(*finder));
	finder->exact = exact;
	finder->lut = malloc(LUT_SIZE * sizeof(*finder->lut));
	if (!finder->lut)
		return 0;
	memset(finder->lut, 0xFF, LUT_SIZE * sizeof(*finder->lut));
	block_index_init(&finder->index, palette);
	return 1;
}

static void
nearest_release(nearest_finder *finder) {
	free(finder->lut);
	free(finder->lists);
	free(finder->pool.items);
	block_index_release(&finder->index);
}

/* Decides the lookup table cell containing (r, g, b), searching the
 * candidates of its block. Without exact resolution the cell stores
 * the entry nearest to its centre. With it, the cell stores the only
 * entry that may be nearest to one of its colours, or a list of them.
 */
static uint16_t
lut_fill(nearest_finder *finder, unsigned key, int r, int g, int b) {
	const sixel_palette *palette = finder->index.order.palette;
	int cell = 1 << LUT_SHIFT;
	int r2 = 2 * (r & ~(cell - 1)) + cell - 1;
	int g2 = 2 * (g & ~(cell - 1)) + cell - 1;
	int b2 = 2 * (b & ~(cell - 1)) + cell - 1;
	int block_count = 0;
	const unsigned char *block = block_candidates(&finder->index, r, g, b, &block_count);
	int nearest = block
		? nearest_candidate(palette, block, block_count, r2, g2, b2)
		: nearest_entry(&finder->index.order, r2, g2, b2);
	candidate_list *list;
	int count;
	uint16_t value = LUT_SEARCH;

	if (!finder->exact) {
		finder->lut[key] = (uint16_t)nearest;
		return (uint16_t)nearest;
	}

	count = collect_candidates(&finder->index.order, block, block_count, r2, g2, b2,
	                           candidate_reach(palette, nearest, r2, g2, b2, LUT_CELL_DIAMETER2),
	                           &finder->pool);
	if (count == 1) {
		value = (uint16_t)nearest;
	}
	else if (count > 1 && finder->list_count < LUT_MAX_LISTS
	         && reserve_items((void **)&finder->lists, &finder->list_capacity, finder->list_count,
	                          1, sizeof(*finder->lists))) {
		list = finder->lists + finder->list_count;
		list->first = finder->pool.used;
		list->count = count;
		memset(list->choice, 0xFF, sizeof(list->choice));
		finder->pool.used += (size_t)count;
		value = (uint16_t)(LUT_FIRST_LIST + finder->list_count++);
	}
	/* otherwise memory ran out and every colour of the cell is searched */
	finder->lut[key] = value;
	return value;
}

static uint16_t
nearest_in_list(const nearest_finder *finder, candidate_list *list, int r, int g, int b) {
	const sixel_palette *palette = finder->index.order.palette;
	const unsigned char *candidates = finder->pool.items + list->first;
	uint16_t *choice = list->choice + CELL_SLOT(r, g, b);
	int best = INT_MAX;
	int best_index = 0;
	int i;

	if (*choice != CHOICE_UNKNOWN)
		return *choice;

	for (i = 0; i < list->count; ++i) {
		int index = candidates[i];
		const unsigned char *entry = palette->rgb[index];
		int dr = entry[0] - r;
		int dg = entry[1] - g;
		int db = entry[2] - b;
		int d = dr * dr + dg * dg + db * db;
		if (d < best || (d == best && index < best_index)) {
			best = d;
			best_index = index;
		}
	}
	*choice = (uint16_t)best_index;
	return *choice;
}

/* Returns the palette entry nearest to (r, g, b), preferring the
 * lowest index on ties.
 */
static inline uint16_t
nearest_lookup(nearest_finder *finder, int r, int g, int b) {
	unsigned key = LUT_KEY(r, g, b);
	uint16_t value = finder->lut[key];

	if (value == LUT_EMPTY)
		value = lut_fill(finder, key, r, g, b);
	if (value < LUT_FIRST_LIST)
		return value;
	if (value == LUT_SEARCH)
		return (uint16_t)nearest_entry(&finder->index.order, 2 * r, 2 * g, 2 * b);
	return nearest_in_list(finder, finder->lists + (value - LUT_FIRST_LIST), r, g, b);
}

/* ------------------------------------------------------------------ */
/* pixel mapping                                                       */

static const unsigned char bayer8[64] = {
	 0, 32,  8, 40,  2, 34, 10, 42,
	48, 16, 56, 24, 50, 18, 58, 26,
	12, 44,  4, 36, 14, 46,  6, 38,
	60, 28, 52, 20, 62, 30, 54, 22,
	 3, 35, 11, 43,  1, 33,  9, 41,
	51, 19, 59, 27, 49, 17, 57, 25,
	15, 47,  7, 39, 13, 45,  5, 37,
	63, 31, 55, 23, 61, 29, 53, 21,
};

static inline int
clamp_sample(int value) {
	return value < 0 ? 0 : value > 255 ? 255 : value;
}

/* The mean distance from each palette entry to its nearest neighbour,
 * used as the amplitude of ordered dithering.
 */
static double
palette_spacing(const sixel_palette *palette) {
	double total = 0;
	int i, j;

	if (palette->size < 2)
		return 0;

	for (i = 0; i < palette->size; ++i) {
		int nearest = INT_MAX;
		for (j = 0; j < palette->size; ++j) {
			int dr, dg, db, d;
			if (i == j)
				continue;
			dr = palette->rgb[i][0] - palette->rgb[j][0];
			dg = palette->rgb[i][1] - palette->rgb[j][1];
			db = palette->rgb[i][2] - palette->rgb[j][2];
			d = dr * dr + dg * dg + db * db;
			if (d < nearest)
				nearest = d;
		}
		total += sqrt((double)nearest);
	}
	return total / palette->size;
}

static void
map_plain(const unsigned char *rgba, size_t width, size_t height,
          nearest_finder *finder, uint16_t *map) {
	size_t count = width * height;
	size_t i;

	for (i = 0; i < count; ++i, rgba += 4) {
		map[i] = PIXEL_PAINTED(rgba)
			? nearest_lookup(finder, rgba[0], rgba[1], rgba[2])
			: SIXEL_TRANSPARENT;
	}
}

static void
map_ordered(const unsigned char *rgba, size_t width, size_t height,
            nearest_finder *finder, uint16_t *map) {
	double spacing = palette_spacing(finder->index.order.palette);
	int offset[64];
	size_t x, y;
	int i;

	for (i = 0; i < 64; ++i)
		offset[i] = (int)floor(((bayer8[i] + 0.5) / 64.0 - 0.5) * spacing + 0.5);

	for (y = 0; y < height; ++y) {
		const int *row_offset = offset + (y & 7) * 8;
		for (x = 0; x < width; ++x, rgba += 4, ++map) {
			int o;
			if (!PIXEL_PAINTED(rgba)) {
				*map = SIXEL_TRANSPARENT;
				continue;
			}
			o = row_offset[x & 7];
			*map = nearest_lookup(finder,
			                      clamp_sample(rgba[0] + o),
			                      clamp_sample(rgba[1] + o),
			                      clamp_sample(rgba[2] + o));
		}
	}
}

/* Errors are kept in sixteenths of a sample. Every pixel distributes
 * at most 16 * 255 sixteenths, so adding ERROR_BIAS keeps the sum
 * positive and the rounding below a plain unsigned division.
 */
#define ERROR_BIAS (16 * 512)

/* Rounds an error in sixteenths to whole sample units, halves up. */
static inline int
error_units(int sixteenths) {
	return (int)((unsigned)(sixteenths + ERROR_BIAS + 8) / 16u) - ERROR_BIAS / 16;
}

/* Floyd-Steinberg error diffusion with serpentine scanning. The error
 * for the next pixel of a row is carried in locals; the errors for the
 * following row are collected in a buffer with a guard cell at either
 * end.
 */
static int
map_diffusion(const unsigned char *rgba, size_t width, size_t height,
              nearest_finder *finder, uint16_t *map) {
	const sixel_palette *palette = finder->index.order.palette;
	size_t row_cells = (width + 2) * 3;
	int *current = calloc(row_cells, sizeof(int));
	int *next = calloc(row_cells, sizeof(int));
	size_t y;

	if (!current || !next) {
		free(current);
		free(next);
		return 0;
	}

	for (y = 0; y < height; ++y) {
		int forward = (y & 1) == 0;
		ptrdiff_t step = forward ? 1 : -1;
		size_t x = forward ? 0 : width - 1;
		const unsigned char *pixel = rgba + (y * width + x) * 4;
		uint16_t *out = map + y * width + x;
		int *below = next + (x + 1) * 3;
		const int *above = current + (x + 1) * 3;
		int carry[3] = { 0, 0, 0 };
		size_t n;
		int *swap;

		memset(next, 0, row_cells * sizeof(int));
		for (n = 0; n < width; ++n, pixel += 4 * step, out += step, below += 3 * step, above += 3 * step) {
			const unsigned char *chosen;
			int value[3];
			uint16_t index;
			int c;

			if (!PIXEL_PAINTED(pixel)) {
				*out = SIXEL_TRANSPARENT;
				carry[0] = carry[1] = carry[2] = 0;
				continue;
			}
			for (c = 0; c < 3; ++c)
				value[c] = clamp_sample(pixel[c] + error_units(above[c] + carry[c]));

			index = nearest_lookup(finder, value[0], value[1], value[2]);
			*out = index;

			chosen = palette->rgb[index];
			for (c = 0; c < 3; ++c) {
				int error = value[c] - chosen[c];
				carry[c] = error * 7;
				below[c - 3 * step] += error * 3;
				below[c] += error * 5;
				below[c + 3 * step] += error;
			}
		}
		swap = current;
		current = next;
		next = swap;
	}

	free(current);
	free(next);
	return 1;
}

int
sixel_map_pixels(const unsigned char *rgba, size_t width, size_t height,
                 const sixel_palette *palette, sixel_dither dither, uint16_t *map) {
	nearest_finder *finder;
	int ok = 1;

	if (palette->size == 0) {
		size_t i, count = width * height;
		for (i = 0; i < count; ++i)
			map[i] = SIXEL_TRANSPARENT;
		return 1;
	}

	finder = malloc(sizeof(*finder));
	/* dithering absorbs the error of resolving by cell centres */
	if (!finder || !nearest_init(finder, palette, dither == SIXEL_DITHER_NONE)) {
		free(finder);
		return 0;
	}

	switch (dither) {
	case SIXEL_DITHER_NONE:
		map_plain(rgba, width, height, finder, map);
		break;
	case SIXEL_DITHER_ORDERED:
		map_ordered(rgba, width, height, finder, map);
		break;
	case SIXEL_DITHER_DIFFUSION:
		ok = map_diffusion(rgba, width, height, finder, map);
		break;
	}

	nearest_release(finder);
	free(finder);
	return ok;
}
