/*
 * eshu_diff.h — Simple unified-diff generator
 *
 * Pure C, no Perl dependencies.
 */

#ifndef ESHU_DIFF_H
#define ESHU_DIFF_H

#include "eshu.h"
#include <stdio.h>

/* Generate a simple unified diff between old and new text.
 * Returns a malloc'd string (caller must free). */
static char *eshu_simple_diff(const char *label,
                              const char *old_text, size_t old_len,
                              const char *new_text, size_t new_len,
                              size_t *out_len)
{
	eshu_buf_t buf;
	/* Split both into line arrays */
	size_t old_cap = 256, new_cap = 256;
	size_t old_count = 0, new_count = 0;
	const char **old_lines, **new_lines;
	size_t *old_lens, *new_lens;
	const char *p;
	size_t i, max, hunk_old_count, hunk_new_count;
	int hunk_start;
	/* Temp arrays for hunk lines */
	size_t hunk_cap = 64;
	size_t *ho_idx, *hn_idx;
	char numbuf[64];

	eshu_buf_init(&buf, old_len > new_len ? old_len : new_len);

	old_lines = (const char **)malloc(old_cap * sizeof(const char *));
	old_lens  = (size_t *)malloc(old_cap * sizeof(size_t));
	new_lines = (const char **)malloc(new_cap * sizeof(const char *));
	new_lens  = (size_t *)malloc(new_cap * sizeof(size_t));

	/* Parse old lines */
	p = old_text;
	while (p < old_text + old_len) {
		const char *eol = p;
		while (eol < old_text + old_len && *eol != '\n') eol++;
		if (eol < old_text + old_len) eol++; /* include the newline */
		if (old_count >= old_cap) {
			old_cap *= 2;
			old_lines = (const char **)realloc(old_lines, old_cap * sizeof(const char *));
			old_lens  = (size_t *)realloc(old_lens, old_cap * sizeof(size_t));
		}
		old_lines[old_count] = p;
		old_lens[old_count]  = (size_t)(eol - p);
		old_count++;
		p = eol;
	}

	/* Parse new lines */
	p = new_text;
	while (p < new_text + new_len) {
		const char *eol = p;
		while (eol < new_text + new_len && *eol != '\n') eol++;
		if (eol < new_text + new_len) eol++;
		if (new_count >= new_cap) {
			new_cap *= 2;
			new_lines = (const char **)realloc(new_lines, new_cap * sizeof(const char *));
			new_lens  = (size_t *)realloc(new_lens, new_cap * sizeof(size_t));
		}
		new_lines[new_count] = p;
		new_lens[new_count]  = (size_t)(eol - p);
		new_count++;
		p = eol;
	}

	/* Header */
	eshu_buf_write(&buf, "--- a/", 6);
	eshu_buf_write(&buf, label, strlen(label));
	eshu_buf_putc(&buf, '\n');
	eshu_buf_write(&buf, "+++ b/", 6);
	eshu_buf_write(&buf, label, strlen(label));
	eshu_buf_putc(&buf, '\n');

	ho_idx = (size_t *)malloc(hunk_cap * sizeof(size_t));
	hn_idx = (size_t *)malloc(hunk_cap * sizeof(size_t));

	max = old_count > new_count ? old_count : new_count;
	hunk_start = -1;
	hunk_old_count = 0;
	hunk_new_count = 0;

	for (i = 0; i <= max; i++) {
		int same = 0;
		if (i < old_count && i < new_count
		    && old_lens[i] == new_lens[i]
		    && memcmp(old_lines[i], new_lines[i], old_lens[i]) == 0) {
			same = 1;
		}

		if (!same && hunk_start < 0) {
			hunk_start = (int)i;
			hunk_old_count = 0;
			hunk_new_count = 0;
		}
		if (hunk_start >= 0 && !same) {
			if (i < old_count) {
				if (hunk_old_count >= hunk_cap) {
					hunk_cap *= 2;
					ho_idx = (size_t *)realloc(ho_idx, hunk_cap * sizeof(size_t));
					hn_idx = (size_t *)realloc(hn_idx, hunk_cap * sizeof(size_t));
				}
				ho_idx[hunk_old_count++] = i;
			}
			if (i < new_count) {
				if (hunk_new_count >= hunk_cap) {
					hunk_cap *= 2;
					ho_idx = (size_t *)realloc(ho_idx, hunk_cap * sizeof(size_t));
					hn_idx = (size_t *)realloc(hn_idx, hunk_cap * sizeof(size_t));
				}
				hn_idx[hunk_new_count++] = i;
			}
		}
		if (same || i == max) {
			if (hunk_start >= 0) {
				size_t j;
				int len = sprintf(numbuf, "@@ -%d,%d +%d,%d @@\n",
					hunk_start + 1, (int)hunk_old_count,
					hunk_start + 1, (int)hunk_new_count);
				eshu_buf_write(&buf, numbuf, (size_t)len);
				for (j = 0; j < hunk_old_count; j++) {
					size_t idx = ho_idx[j];
					eshu_buf_putc(&buf, '-');
					eshu_buf_write(&buf, old_lines[idx], old_lens[idx]);
					if (old_lens[idx] == 0 || old_lines[idx][old_lens[idx]-1] != '\n')
						eshu_buf_putc(&buf, '\n');
				}
				for (j = 0; j < hunk_new_count; j++) {
					size_t idx = hn_idx[j];
					eshu_buf_putc(&buf, '+');
					eshu_buf_write(&buf, new_lines[idx], new_lens[idx]);
					if (new_lens[idx] == 0 || new_lines[idx][new_lens[idx]-1] != '\n')
						eshu_buf_putc(&buf, '\n');
				}
				hunk_start = -1;
			}
		}
	}

	free(ho_idx);
	free(hn_idx);
	free(old_lines);
	free(old_lens);
	free(new_lines);
	free(new_lens);

	*out_len = buf.len;
	return buf.data;
}

#endif /* ESHU_DIFF_H */
