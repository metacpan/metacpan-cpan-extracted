/*
 * eshu_css.h — CSS indentation scanner
 *
 * Brace-based nesting like C, but with CSS-specific quoting,
 * comment syntax (no // line comments), and url() skipping.
 */

#ifndef ESHU_CSS_H
#define ESHU_CSS_H

#include "eshu.h"

/* ══════════════════════════════════════════════════════════════════
 *  Scanner context
 * ══════════════════════════════════════════════════════════════════ */

typedef struct {
	int             depth;
	enum eshu_state state;
	eshu_config_t   cfg;
} eshu_css_ctx_t;

static void eshu_css_ctx_init(eshu_css_ctx_t *ctx, const eshu_config_t *cfg) {
	ctx->depth = 0;
	ctx->state = ESHU_CODE;
	ctx->cfg   = *cfg;
}

/* ══════════════════════════════════════════════════════════════════
 *  Scan a line to compute depth changes
 *
 *  Sets *pre_adj  = depth change BEFORE indenting (leading '}')
 *  Sets *post_adj = net depth change from rest of line
 * ══════════════════════════════════════════════════════════════════ */

static void eshu_css_scan_line(eshu_css_ctx_t *ctx,
                               const char *content, const char *eol,
                               int *pre_adj, int *post_adj) {
	const char *p = content;
	int first_close_counted = 0;
	*pre_adj  = 0;
	*post_adj = 0;

	while (p < eol) {
		/* ── Block comment state ── */
		if (ctx->state == ESHU_CSS_COMMENT) {
			if (p + 1 < eol && p[0] == '*' && p[1] == '/') {
				ctx->state = ESHU_CODE;
				p += 2;
				continue;
			}
			p++;
			continue;
		}

		/* ── Double-quoted string ── */
		if (ctx->state == ESHU_CSS_STRING_DQ) {
			if (*p == '\\' && p + 1 < eol) {
				p += 2; /* skip escaped char */
				continue;
			}
			if (*p == '"') {
				ctx->state = ESHU_CODE;
			}
			p++;
			continue;
		}

		/* ── Single-quoted string ── */
		if (ctx->state == ESHU_CSS_STRING_SQ) {
			if (*p == '\\' && p + 1 < eol) {
				p += 2;
				continue;
			}
			if (*p == '\'') {
				ctx->state = ESHU_CODE;
			}
			p++;
			continue;
		}

		/* ── url() content ── */
		if (ctx->state == ESHU_CSS_URL) {
			if (*p == ')') {
				ctx->state = ESHU_CODE;
			}
			p++;
			continue;
		}

		/* ── Normal CODE state ── */

		/* Block comment: /* */
		if (p + 1 < eol && p[0] == '/' && p[1] == '*') {
			ctx->state = ESHU_CSS_COMMENT;
			p += 2;
			continue;
		}

		/* Double-quoted string */
		if (*p == '"') {
			ctx->state = ESHU_CSS_STRING_DQ;
			p++;
			continue;
		}

		/* Single-quoted string */
		if (*p == '\'') {
			ctx->state = ESHU_CSS_STRING_SQ;
			p++;
			continue;
		}

		/* url( — skip content until ) */
		if (p + 3 < eol && p[0] == 'u' && p[1] == 'r' && p[2] == 'l' && p[3] == '(') {
			ctx->state = ESHU_CSS_URL;
			p += 4;
			continue;
		}

		/* Opening brace */
		if (*p == '{') {
			*post_adj += 1;
			p++;
			continue;
		}

		/* Closing brace */
		if (*p == '}') {
			if (p == content && !first_close_counted) {
				/* Leading '}' — apply as pre-adjust */
				*pre_adj -= 1;
				first_close_counted = 1;
			} else {
				*post_adj -= 1;
			}
			p++;
			continue;
		}

		p++;
	}
}

/* ══════════════════════════════════════════════════════════════════
 *  Process a single line
 * ══════════════════════════════════════════════════════════════════ */

static void eshu_css_process_line(eshu_css_ctx_t *ctx,
                                  const char *line, const char *eol,
                                  eshu_buf_t *out) {
	const char *content = eshu_skip_leading_ws(line);
	int content_len = (int)(eol - content);
	int is_blank = (content == eol || *content == '\n');

	/* Blank line */
	if (is_blank) {
		if (*eol == '\n') eshu_buf_putc(out, '\n');
		return;
	}

	/* Determine depth adjustments */
	{
		int pre_adj = 0, post_adj = 0;
		int indent_depth;

		/* Check for leading '}' */
		if (*content == '}') {
			pre_adj = -1;
		}

		indent_depth = ctx->depth + pre_adj;
		if (indent_depth < 0) indent_depth = 0;

		/* Emit indentation + content */
		eshu_emit_indent(out, indent_depth, &ctx->cfg);
		eshu_buf_write_trimmed(out, content, content_len);
		if (*eol == '\n') eshu_buf_putc(out, '\n');

		/* Scan line for full depth changes */
		{
			int scan_pre = 0, scan_post = 0;
			eshu_css_scan_line(ctx, content, eol, &scan_pre, &scan_post);

			ctx->depth += scan_pre + scan_post;
			if (ctx->depth < 0) ctx->depth = 0;
		}
	}
}

/* ══════════════════════════════════════════════════════════════════
 *  Public API
 * ══════════════════════════════════════════════════════════════════ */

static char * eshu_indent_css(const char *src, size_t src_len,
                              const eshu_config_t *cfg, size_t *out_len) {
	eshu_css_ctx_t ctx;
	eshu_buf_t out;
	const char *p   = src;
	const char *end = src + src_len;
	char *result;

	eshu_css_ctx_init(&ctx, cfg);
	eshu_buf_init(&out, src_len + 256);

	while (p < end) {
		const char *eol = eshu_find_eol(p);
		eshu_css_process_line(&ctx, p, eol, &out);
		p = (*eol == '\n') ? eol + 1 : eol;
		if (p > end) p = end;
	}

	*out_len = out.len;
	result = out.data;
	return result;
}

#endif /* ESHU_CSS_H */
