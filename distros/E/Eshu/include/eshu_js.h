/*
 * eshu_js.h — JavaScript indentation scanner
 *
 * Tracks {} () [] nesting depth while handling JS-specific constructs:
 * double-quoted strings, single-quoted strings, template literals with
 * ${} interpolation, regex literals, line comments, and block comments.
 */

#ifndef ESHU_JS_H
#define ESHU_JS_H

#include "eshu.h"

#define ESHU_JS_MAX_TMPL_DEPTH 16

/* ══════════════════════════════════════════════════════════════════
 *  Scanner context — persists across lines
 * ══════════════════════════════════════════════════════════════════ */

typedef struct {
	int             depth;
	enum eshu_state state;
	int             tmpl_depth;
	int             tmpl_brace_depth[ESHU_JS_MAX_TMPL_DEPTH];
	int             can_regex;   /* 1 if next / starts a regex */
	eshu_config_t   cfg;
} eshu_js_ctx_t;

static void eshu_js_ctx_init(eshu_js_ctx_t *ctx, const eshu_config_t *cfg) {
	ctx->depth      = 0;
	ctx->state      = ESHU_CODE;
	ctx->tmpl_depth = 0;
	ctx->can_regex  = 1;
	ctx->cfg        = *cfg;
}

/* ══════════════════════════════════════════════════════════════════
 *  Classify first non-ws char for pre-indent adjustment
 * ══════════════════════════════════════════════════════════════════ */

static int eshu_js_is_closing(char c) {
	return c == '}' || c == ')' || c == ']';
}

/* ══════════════════════════════════════════════════════════════════
 *  Scan a line for nesting changes
 *
 *  Called AFTER the line has been emitted. Updates ctx->state
 *  and ctx->depth for the next line.
 * ══════════════════════════════════════════════════════════════════ */

static void eshu_js_scan_line(eshu_js_ctx_t *ctx,
                              const char *p, const char *end) {
	while (p < end) {
		char c = *p;

		switch (ctx->state) {

		case ESHU_CODE:
			if (c == '{' || c == '(' || c == '[') {
				ctx->depth++;
				ctx->can_regex = 1;
			} else if (c == '}') {
				ctx->depth--;
				if (ctx->depth < 0) ctx->depth = 0;
				/* Check if this closes a template expression */
				if (ctx->tmpl_depth > 0 &&
				    ctx->depth == ctx->tmpl_brace_depth[ctx->tmpl_depth - 1]) {
					ctx->tmpl_depth--;
					ctx->state = ESHU_JS_TEMPLATE;
					ctx->can_regex = 0;
					break;
				}
				ctx->can_regex = 0;
			} else if (c == ')' || c == ']') {
				ctx->depth--;
				if (ctx->depth < 0) ctx->depth = 0;
				ctx->can_regex = 0;
			} else if (c == '"') {
				ctx->state = ESHU_STRING_DQ;
			} else if (c == '\'') {
				ctx->state = ESHU_STRING_SQ;
			} else if (c == '`') {
				ctx->state = ESHU_JS_TEMPLATE;
				ctx->can_regex = 0;
			} else if (c == '/' && p + 1 < end && *(p + 1) == '/') {
				/* line comment — skip rest of line */
				return;
			} else if (c == '/' && p + 1 < end && *(p + 1) == '*') {
				ctx->state = ESHU_COMMENT_BLOCK;
				p++;  /* skip '*' */
			} else if (c == '/' && ctx->can_regex) {
				/* regex literal */
				ctx->state = ESHU_JS_REGEX;
			} else if (c == '/') {
				/* division operator */
				ctx->can_regex = 1;
			} else if (isalnum((unsigned char)c) || c == '_' || c == '$') {
				ctx->can_regex = 0;
				/* skip rest of identifier/number */
				while (p + 1 < end &&
				       (isalnum((unsigned char)*(p + 1)) ||
				        *(p + 1) == '_' || *(p + 1) == '$'))
					p++;
			} else if (c == '+' || c == '-') {
				if (p + 1 < end && *(p + 1) == c) {
					p++;  /* ++ or -- */
					ctx->can_regex = 0;
				} else {
					ctx->can_regex = 1;
				}
			} else if (c == '=' || c == ',' || c == ';' || c == '!' ||
			           c == '~' || c == '<' || c == '>' || c == '&' ||
			           c == '|' || c == '^' || c == '?' || c == ':' ||
			           c == '%' || c == '*') {
				ctx->can_regex = 1;
			}
			/* whitespace does not change can_regex */
			break;

		case ESHU_STRING_DQ:
			if (c == '\\' && p + 1 < end) {
				p++;  /* skip escaped char */
			} else if (c == '"') {
				ctx->state = ESHU_CODE;
				ctx->can_regex = 0;
			}
			break;

		case ESHU_STRING_SQ:
			if (c == '\\' && p + 1 < end) {
				p++;
			} else if (c == '\'') {
				ctx->state = ESHU_CODE;
				ctx->can_regex = 0;
			}
			break;

		case ESHU_JS_TEMPLATE:
			if (c == '\\' && p + 1 < end) {
				p++;  /* skip escaped char */
			} else if (c == '`') {
				ctx->state = ESHU_CODE;
				ctx->can_regex = 0;
			} else if (c == '$' && p + 1 < end && *(p + 1) == '{') {
				p++;  /* skip '{' */
				if (ctx->tmpl_depth < ESHU_JS_MAX_TMPL_DEPTH) {
					ctx->tmpl_brace_depth[ctx->tmpl_depth] = ctx->depth;
					ctx->tmpl_depth++;
				}
				ctx->depth++;
				ctx->state = ESHU_CODE;
				ctx->can_regex = 1;
			}
			break;

		case ESHU_JS_REGEX:
			if (c == '\\' && p + 1 < end) {
				p++;
			} else if (c == '[') {
				ctx->state = ESHU_JS_REGEX_CLASS;
			} else if (c == '/') {
				/* end of regex — skip flags */
				while (p + 1 < end && isalpha((unsigned char)*(p + 1)))
					p++;
				ctx->state = ESHU_CODE;
				ctx->can_regex = 0;
			}
			break;

		case ESHU_JS_REGEX_CLASS:
			if (c == '\\' && p + 1 < end) {
				p++;
			} else if (c == ']') {
				ctx->state = ESHU_JS_REGEX;
			}
			break;

		case ESHU_COMMENT_BLOCK:
			if (c == '*' && p + 1 < end && *(p + 1) == '/') {
				ctx->state = ESHU_CODE;
				ctx->can_regex = 1;
				p++;
			}
			break;

		default:
			break;
		}
		p++;
	}
}

/* ══════════════════════════════════════════════════════════════════
 *  Process a single line — decide indent, emit, scan
 * ══════════════════════════════════════════════════════════════════ */

static void eshu_js_process_line(eshu_js_ctx_t *ctx, eshu_buf_t *out,
                                 const char *line_start, const char *eol) {
	const char *content = eshu_skip_leading_ws(line_start);
	int line_len;
	int indent_depth;

	/* empty line — preserve it */
	if (content >= eol) {
		eshu_buf_putc(out, '\n');
		return;
	}

	line_len = (int)(eol - content);

	/* Template literal continuation: pass through verbatim
	 * (template literal whitespace is significant) */
	if (ctx->state == ESHU_JS_TEMPLATE) {
		eshu_buf_write(out, line_start, (size_t)(eol - line_start));
		if (*eol == '\n') eshu_buf_putc(out, '\n');
		eshu_js_scan_line(ctx, line_start, eol);
		return;
	}

	/* Block comment continuation */
	if (ctx->state == ESHU_COMMENT_BLOCK) {
		eshu_emit_indent(out, ctx->depth, &ctx->cfg);
		eshu_buf_write_trimmed(out, content, line_len);
		eshu_buf_putc(out, '\n');
		eshu_js_scan_line(ctx, content, eol);
		return;
	}

	/* Regex spanning lines (rare but possible) */
	if (ctx->state == ESHU_JS_REGEX ||
	    ctx->state == ESHU_JS_REGEX_CLASS) {
		eshu_emit_indent(out, ctx->depth, &ctx->cfg);
		eshu_buf_write_trimmed(out, content, line_len);
		eshu_buf_putc(out, '\n');
		eshu_js_scan_line(ctx, content, eol);
		return;
	}

	/* Normal code line */
	indent_depth = ctx->depth;

	/* If line starts with closer, dedent this line */
	if (eshu_js_is_closing(*content)) {
		indent_depth--;
		if (indent_depth < 0) indent_depth = 0;
	}

	eshu_emit_indent(out, indent_depth, &ctx->cfg);
	eshu_buf_write_trimmed(out, content, line_len);
	eshu_buf_putc(out, '\n');

	/* Scan for nesting changes */
	eshu_js_scan_line(ctx, content, eol);
}

/* ══════════════════════════════════════════════════════════════════
 *  Public API — indent a JavaScript source string
 * ══════════════════════════════════════════════════════════════════ */

static char * eshu_indent_js(const char *src, size_t src_len,
                             const eshu_config_t *cfg, size_t *out_len) {
	eshu_js_ctx_t ctx;
	eshu_buf_t out;
	const char *p   = src;
	const char *end = src + src_len;
	char *result;

	eshu_js_ctx_init(&ctx, cfg);
	eshu_buf_init(&out, src_len + 256);

	{
		int line_num = 1;
		while (p < end) {
			const char *eol = eshu_find_eol(p);

			if (eshu_in_range(cfg, line_num)) {
				eshu_js_process_line(&ctx, &out, p, eol);
			} else {
				/* Outside range: scan for state, emit verbatim */
				size_t saved = out.len;
				eshu_js_process_line(&ctx, &out, p, eol);
				out.len = saved;
				eshu_buf_write_trimmed(&out, p, (int)(eol - p));
				eshu_buf_putc(&out, '\n');
			}

			p = eol;
			if (*p == '\n') p++;
			line_num++;
		}
	}

	/* NUL-terminate */
	eshu_buf_putc(&out, '\0');
	out.len--;

	*out_len = out.len;
	result = out.data;
	return result;
}

#endif /* ESHU_JS_H */
