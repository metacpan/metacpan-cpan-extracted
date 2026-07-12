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
	int            depth;       /* brace nesting depth                      */
	int            pp_depth;    /* preprocessor #if depth                   */
	int            case_depth;  /* depth at which last case/default was seen */
	int            case_extra;  /* 1 = add extra indent to case body lines  */
	enum eshu_state state;      /* current scanner state                    */
	eshu_config_t  cfg;
} eshu_ctx_t;

static void eshu_ctx_init(eshu_ctx_t *ctx, const eshu_config_t *cfg) {
	ctx->depth      = 0;
	ctx->pp_depth   = 0;
	ctx->case_depth = 0;
	ctx->case_extra = 0;
	ctx->state      = ESHU_CODE;
	ctx->cfg        = *cfg;
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

/* Is this line a switch case/default label?
 * Matches "case <expr>:" or "default:" (ignoring trailing // comments).
 * Case labels stay at brace depth; their body content gets +1 via case_extra. */
static int eshu_c_is_case_label(const char *content, int len) {
	const char *p, *end;
	int is_kw = 0;

	if (len < 2) return 0;

	if (len >= 5 && strncmp(content, "case ", 5) == 0)
		is_kw = 1;
	else if (len >= 7 && strncmp(content, "default", 7) == 0 &&
	         (len == 7 || content[7] == ':' || content[7] == ' ' ||
	          content[7] == '\t' || content[7] == '/'))
		is_kw = 1;

	if (!is_kw) return 0;

	/* Trimmed content must end with ':' (ignore // comments) */
	p   = content;
	end = content + len;
	while (p < end) {
		if (*p == '/' && p + 1 < end && *(p + 1) == '/') { end = p; break; }
		if (*p == '"' || *p == '\'') {
			char d = *p++;
			while (p < end && *p != d) {
				if (*p == '\\') p++;
				p++;
			}
		}
		p++;
	}
	while (end > content && (*(end - 1) == ' ' || *(end - 1) == '\t')) end--;
	return end > content && *(end - 1) == ':';
}

/* Is this line a bare goto label (identifier followed by ':' alone)?
 * Excludes case/default. These are emitted at column 0 in C style. */
static int eshu_c_is_goto_label(const char *content, int len) {
	const char *p;
	int ident_len;

	if (len < 2) return 0;
	if (!isalpha((unsigned char)*content) && *content != '_') return 0;

	p = content;
	while (p < content + len && (isalnum((unsigned char)*p) || *p == '_')) p++;
	ident_len = (int)(p - content);

	/* exclude case and default */
	if (ident_len == 4 && strncmp(content, "case",    4) == 0) return 0;
	if (ident_len == 7 && strncmp(content, "default", 7) == 0) return 0;

	while (p < content + len && (*p == ' ' || *p == '\t')) p++;
	if (p >= content + len || *p != ':') return 0;
	p++;

	while (p < content + len && (*p == ' ' || *p == '\t')) p++;
	if (p >= content + len) return 1;
	return *p == '/' && p + 1 < content + len && *(p + 1) == '/';
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

		/* States not used by the C scanner — ignore */
		default:
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

	/* Leaving a case block: clear case_extra once depth drops below case_depth */
	if (ctx->case_extra && ctx->depth < ctx->case_depth)
		ctx->case_extra = 0;

	if (eshu_c_is_closing(*content)) {
		/* closing brace/paren — dedent this line */
		indent_depth--;
		if (indent_depth < 0) indent_depth = 0;
		/* still inside a case block at deeper nesting */
		if (ctx->case_extra && ctx->depth > ctx->case_depth)
			indent_depth++;
	} else if (eshu_c_is_case_label(content, line_len)) {
		/* case/default label: stays at brace depth; body lines get +1 */
		ctx->case_depth = ctx->depth;
		ctx->case_extra = 1;
	} else if (eshu_c_is_goto_label(content, line_len)) {
		/* goto label: always at column 0 */
		indent_depth = 0;
	} else if (ctx->case_extra && ctx->depth >= ctx->case_depth) {
		/* body line inside a case block: add one extra indent level */
		indent_depth++;
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
