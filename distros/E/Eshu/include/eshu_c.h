/*
 * eshu_c.h — C language indentation scanner
 *
 * Tracks {} () [] nesting depth while skipping strings, comments,
 * and preprocessor directives. Rewrites leading whitespace only.
 */

#ifndef ESHU_C_H
#define ESHU_C_H

#include "eshu.h"

/* ══════════════════════════════════════════════════════════════════
 *  Scanner context — persists across lines
 * ══════════════════════════════════════════════════════════════════ */

typedef struct {
	int            depth;       /* brace nesting depth       */
	int            pp_depth;    /* preprocessor #if depth    */
	enum eshu_state state;      /* current scanner state     */
	eshu_config_t  cfg;
} eshu_ctx_t;

static void eshu_ctx_init(eshu_ctx_t *ctx, const eshu_config_t *cfg) {
	ctx->depth    = 0;
	ctx->pp_depth = 0;
	ctx->state    = ESHU_CODE;
	ctx->cfg      = *cfg;
}

/* ══════════════════════════════════════════════════════════════════
 *  Classify first non-ws char for pre-indent adjustment
 * ══════════════════════════════════════════════════════════════════ */

/* Does the line's content (after stripping ws) start with a
 * closing brace/bracket/paren? If so we dedent before emitting. */
static int eshu_c_is_closing(char c) {
	return c == '}' || c == ')' || c == ']';
}

/* Is this a preprocessor line? (first non-ws char is '#') */
static int eshu_c_is_pp(const char *content) {
	return *content == '#';
}

/* ══════════════════════════════════════════════════════════════════
 *  Classify preprocessor directive for pp_depth tracking
 *  Returns: +1 for #if/#ifdef/#ifndef, -1 for #endif, 0 otherwise
 *  Sets *is_else = 1 for #else/#elif
 * ══════════════════════════════════════════════════════════════════ */

static int eshu_c_pp_classify(const char *content, int *is_else) {
	const char *p = content + 1; /* skip '#' */
	*is_else = 0;

	while (*p == ' ' || *p == '\t') p++;

	if (strncmp(p, "if", 2) == 0 && !isalnum((unsigned char)p[2]) && p[2] != '_')
		return 1;
	if (strncmp(p, "ifdef", 5) == 0 && !isalnum((unsigned char)p[5]))
		return 1;
	if (strncmp(p, "ifndef", 6) == 0 && !isalnum((unsigned char)p[6]))
		return 1;
	if (strncmp(p, "endif", 5) == 0 && !isalnum((unsigned char)p[5]))
		return -1;
	if (strncmp(p, "else", 4) == 0 && !isalnum((unsigned char)p[4])) {
		*is_else = 1;
		return 0;
	}
	if (strncmp(p, "elif", 4) == 0 && !isalnum((unsigned char)p[4])) {
		*is_else = 1;
		return 0;
	}

	return 0;
}

/* ══════════════════════════════════════════════════════════════════
 *  Scan a line for nesting changes (in CODE state)
 *
 *  Called AFTER the line has been emitted. Updates ctx->state
 *  and ctx->depth for the next line.
 * ══════════════════════════════════════════════════════════════════ */

static void eshu_c_scan_line(eshu_ctx_t *ctx, const char *p, const char *end) {
	while (p < end) {
		char c = *p;

		switch (ctx->state) {
		case ESHU_CODE:
			if (c == '{' || c == '(' || c == '[') {
				ctx->depth++;
			} else if (c == '}' || c == ')' || c == ']') {
				ctx->depth--;
				if (ctx->depth < 0) ctx->depth = 0;
			} else if (c == '"') {
				ctx->state = ESHU_STRING_DQ;
			} else if (c == '\'') {
				ctx->state = ESHU_CHAR_LIT;
			} else if (c == '/' && p + 1 < end && *(p + 1) == '/') {
				/* line comment — skip rest of line */
				return;
			} else if (c == '/' && p + 1 < end && *(p + 1) == '*') {
				ctx->state = ESHU_COMMENT_BLOCK;
				p++; /* skip the '*' */
			}
			break;

		case ESHU_STRING_DQ:
			if (c == '\\' && p + 1 < end) {
				p++; /* skip escaped char */
			} else if (c == '"') {
				ctx->state = ESHU_CODE;
			}
			break;

		case ESHU_CHAR_LIT:
			if (c == '\\' && p + 1 < end) {
				p++; /* skip escaped char */
			} else if (c == '\'') {
				ctx->state = ESHU_CODE;
			}
			break;

		case ESHU_STRING_SQ:
			/* C doesn't use SQ strings, but keep state complete */
			if (c == '\\' && p + 1 < end) {
				p++;
			} else if (c == '\'') {
				ctx->state = ESHU_CODE;
			}
			break;

		case ESHU_COMMENT_BLOCK:
			if (c == '*' && p + 1 < end && *(p + 1) == '/') {
				ctx->state = ESHU_CODE;
				p++; /* skip the '/' */
			}
			break;

		case ESHU_COMMENT_LINE:
			/* shouldn't happen — we return early above */
			return;

		case ESHU_PREPROCESSOR:
			/* handled separately */
			break;

		/* Perl-only states — not used in C scanner */
		case ESHU_HEREDOC:
		case ESHU_HEREDOC_INDENT:
		case ESHU_REGEX:
		case ESHU_QW:
		case ESHU_QQ:
		case ESHU_Q:
		case ESHU_POD:
			break;
		}
		p++;
	}
}

/* ══════════════════════════════════════════════════════════════════
 *  Process a single line — decide indent, emit, scan
 * ══════════════════════════════════════════════════════════════════ */

static void eshu_c_process_line(eshu_ctx_t *ctx, eshu_buf_t *out,
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

	/* If we're in a block comment, pass through with current depth */
	if (ctx->state == ESHU_COMMENT_BLOCK) {
		/* inside block comment: indent at current depth + 1
		 * (the comment was opened inside a code block) */
		eshu_emit_indent(out, ctx->depth, &ctx->cfg);
		eshu_buf_write_trimmed(out, content, line_len);
		eshu_buf_putc(out, '\n');
		eshu_c_scan_line(ctx, content, eol);
		return;
	}

	/* Preprocessor line */
	if (eshu_c_is_pp(content)) {
		int is_else = 0;
		int pp_dir = eshu_c_pp_classify(content, &is_else);

		if (ctx->cfg.indent_pp) {
			if (pp_dir < 0) {
				/* #endif — dedent first */
				ctx->pp_depth--;
				if (ctx->pp_depth < 0) ctx->pp_depth = 0;
			}
			if (is_else) {
				eshu_emit_indent(out, ctx->pp_depth - 1, &ctx->cfg);
			} else {
				eshu_emit_indent(out, ctx->pp_depth, &ctx->cfg);
			}
			if (pp_dir > 0)
				ctx->pp_depth++;
		} else {
			/* no pp indent — emit at column 0 */
			if (pp_dir > 0)
				ctx->pp_depth++;
			else if (pp_dir < 0) {
				ctx->pp_depth--;
				if (ctx->pp_depth < 0) ctx->pp_depth = 0;
			}
		}

		eshu_buf_write_trimmed(out, content, line_len);
		eshu_buf_putc(out, '\n');
		return;
	}

	/* Normal code line */
	indent_depth = ctx->depth;

	/* If line starts with closer, dedent this line */
	if (eshu_c_is_closing(*content)) {
		indent_depth--;
		if (indent_depth < 0) indent_depth = 0;
	}

	eshu_emit_indent(out, indent_depth, &ctx->cfg);
	eshu_buf_write_trimmed(out, content, line_len);
	eshu_buf_putc(out, '\n');

	/* Scan for nesting changes */
	eshu_c_scan_line(ctx, content, eol);
}

/* ══════════════════════════════════════════════════════════════════
 *  Public API — indent a C source string
 * ══════════════════════════════════════════════════════════════════ */

static char * eshu_indent_c(const char *src, size_t src_len,
                            const eshu_config_t *cfg, size_t *out_len) {
	eshu_ctx_t ctx;
	eshu_buf_t out;
	const char *p   = src;
	const char *end = src + src_len;
	char *result;

	eshu_ctx_init(&ctx, cfg);
	eshu_buf_init(&out, src_len + 256);

	{
		int line_num = 1;
		while (p < end) {
			const char *eol = eshu_find_eol(p);

			if (eshu_in_range(cfg, line_num)) {
				eshu_c_process_line(&ctx, &out, p, eol);
			} else {
				/* Outside range: scan for state, emit verbatim */
				size_t saved = out.len;
				eshu_c_process_line(&ctx, &out, p, eol);
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
	out.len--; /* don't count NUL in length */

	*out_len = out.len;
	result = out.data;
	/* caller owns result, must free() it */
	return result;
}

#endif /* ESHU_C_H */
