/*
 * eshu_xs.h — XS file indentation scanner
 *
 * Dual-mode: delegates to eshu_c.h for C code above `MODULE =`,
 * then uses XS-specific rules for XSUB declarations below.
 */

#ifndef ESHU_XS_H
#define ESHU_XS_H

#include "eshu.h"
#include "eshu_c.h"

/* ══════════════════════════════════════════════════════════════════
 *  XS mode tracking
 * ══════════════════════════════════════════════════════════════════ */

enum eshu_xs_mode {
	ESHU_XS_C_MODE,     /* before MODULE = line             */
	ESHU_XS_XSUB_MODE   /* after MODULE = line              */
};

enum eshu_xs_section {
	ESHU_XS_NONE,        /* between XSUBs / return type line */
	ESHU_XS_PARAMS,      /* parameter declarations           */
	ESHU_XS_LABEL,       /* just saw a label (CODE: etc)     */
	ESHU_XS_BODY         /* inside a label body              */
};

typedef struct {
	enum eshu_xs_mode    mode;
	enum eshu_xs_section section;
	eshu_ctx_t           c_ctx;       /* C scanner context    */
	int                  c_depth;     /* brace depth in CODE: */
	int                  is_boot;     /* inside BOOT section  */
	eshu_config_t        cfg;
} eshu_xs_ctx_t;

static void eshu_xs_ctx_init(eshu_xs_ctx_t *ctx, const eshu_config_t *cfg) {
	ctx->mode    = ESHU_XS_C_MODE;
	ctx->section = ESHU_XS_NONE;
	ctx->c_depth = 0;
	ctx->is_boot = 0;
	ctx->cfg     = *cfg;
	eshu_ctx_init(&ctx->c_ctx, cfg);
}

/* ══════════════════════════════════════════════════════════════════
 *  Detection helpers
 * ══════════════════════════════════════════════════════════════════ */

/* Check if the line starts with MODULE followed by optional
 * whitespace and '=' */
static int eshu_xs_is_module_line(const char *content, const char *eol) {
	const char *p = content;
	if (eol - p < 8) return 0;
	if (memcmp(p, "MODULE", 6) != 0) return 0;
	p += 6;
	while (p < eol && (*p == ' ' || *p == '\t')) p++;
	return (p < eol && *p == '=');
}

/* XS labels: CODE, INIT, OUTPUT, PREINIT, CLEANUP, POSTCALL,
 * PPCODE, BOOT, CASE, INTERFACE, INTERFACE_MACRO, PROTOTYPES,
 * VERSIONCHECK, INCLUDE, FALLBACK, OVERLOAD, ALIAS, ATTRS */
static int eshu_xs_is_label(const char *content, const char *eol,
                            int *is_boot) {
	const char *p = content;
	const char *start;
	int len;

	*is_boot = 0;

	/* must start with alpha */
	if (!isalpha((unsigned char)*p)) return 0;

	start = p;
	while (p < eol && (isalpha((unsigned char)*p) || *p == '_'))
		p++;
	len = (int)(p - start);

	/* must be followed by ':' (possibly with whitespace) */
	while (p < eol && (*p == ' ' || *p == '\t')) p++;
	if (p >= eol || *p != ':') return 0;

	/* check it's not a C label like 'default:' or 'case:' */
	/* it also must not be a :: (package separator) */
	if (p + 1 < eol && *(p + 1) == ':') return 0;

	/* Known XS labels */
	if ((len == 4 && memcmp(start, "CODE", 4) == 0) ||
	    (len == 4 && memcmp(start, "INIT", 4) == 0) ||
	    (len == 6 && memcmp(start, "OUTPUT", 6) == 0) ||
	    (len == 7 && memcmp(start, "PREINIT", 7) == 0) ||
	    (len == 7 && memcmp(start, "CLEANUP", 7) == 0) ||
	    (len == 8 && memcmp(start, "POSTCALL", 8) == 0) ||
	    (len == 6 && memcmp(start, "PPCODE", 6) == 0) ||
	    (len == 4 && memcmp(start, "CASE", 4) == 0) ||
	    (len == 9 && memcmp(start, "INTERFACE", 9) == 0) ||
	    (len == 15 && memcmp(start, "INTERFACE_MACRO", 15) == 0) ||
	    (len == 10 && memcmp(start, "PROTOTYPES", 10) == 0) ||
	    (len == 12 && memcmp(start, "VERSIONCHECK", 12) == 0) ||
	    (len == 7 && memcmp(start, "INCLUDE", 7) == 0) ||
	    (len == 8 && memcmp(start, "FALLBACK", 8) == 0) ||
	    (len == 8 && memcmp(start, "OVERLOAD", 8) == 0) ||
	    (len == 5 && memcmp(start, "ALIAS", 5) == 0) ||
	    (len == 5 && memcmp(start, "ATTRS", 5) == 0)) {
		/* not a label that belongs to these */
	} else {
		return 0;
	}

	if (len == 4 && memcmp(start, "BOOT", 4) == 0)
		*is_boot = 1;
	/* BOOT is checked above but it's not in the list — add it */

	return 1;
}

/* Check for BOOT: label specifically */
static int eshu_xs_is_boot_label(const char *content, const char *eol) {
	const char *p = content;
	if (eol - p < 5) return 0;
	if (memcmp(p, "BOOT", 4) != 0) return 0;
	p += 4;
	while (p < eol && (*p == ' ' || *p == '\t')) p++;
	return (p < eol && *p == ':' && (p + 1 >= eol || *(p + 1) != ':'));
}

/* Detect if line is a new XSUB return type / function header.
 * In XS mode at depth 0, a line that starts with an identifier
 * (C type name) at column 0 and is NOT a label indicates
 * a new XSUB. */
static int eshu_xs_is_xsub_start(const char *content, const char *eol) {
	const char *p = content;

	/* Must start with alpha or underscore (type name) */
	if (!isalpha((unsigned char)*p) && *p != '_')
		return 0;

	/* Skip the identifier */
	while (p < eol && (isalnum((unsigned char)*p) || *p == '_' || *p == '*' || *p == ' ' || *p == '\t'))
		p++;

	/* Could be a function name with parens, or just a type */
	/* This is sufficient — we rely on being in XS mode at depth 0 */
	return 1;
}

/* ══════════════════════════════════════════════════════════════════
 *  Scan a line for C nesting changes (simplified for XS body)
 * ══════════════════════════════════════════════════════════════════ */

static void eshu_xs_scan_c_nesting(eshu_xs_ctx_t *ctx,
                                   const char *p, const char *end) {
	/* Track {}/()/ nesting within XSUB body code using the C scanner's
	 * state machine for strings/comments, but tracking depth locally */
	while (p < end) {
		char c = *p;

		switch (ctx->c_ctx.state) {
		case ESHU_CODE:
			if (c == '{') {
				ctx->c_depth++;
			} else if (c == '}') {
				ctx->c_depth--;
				if (ctx->c_depth < 0) ctx->c_depth = 0;
			} else if (c == '"') {
				ctx->c_ctx.state = ESHU_STRING_DQ;
			} else if (c == '\'') {
				ctx->c_ctx.state = ESHU_CHAR_LIT;
			} else if (c == '/' && p + 1 < end && *(p + 1) == '/') {
				return; /* line comment */
			} else if (c == '/' && p + 1 < end && *(p + 1) == '*') {
				ctx->c_ctx.state = ESHU_COMMENT_BLOCK;
				p++;
			}
			break;

		case ESHU_STRING_DQ:
			if (c == '\\' && p + 1 < end) p++;
			else if (c == '"') ctx->c_ctx.state = ESHU_CODE;
			break;

		case ESHU_CHAR_LIT:
			if (c == '\\' && p + 1 < end) p++;
			else if (c == '\'') ctx->c_ctx.state = ESHU_CODE;
			break;

		case ESHU_COMMENT_BLOCK:
			if (c == '*' && p + 1 < end && *(p + 1) == '/') {
				ctx->c_ctx.state = ESHU_CODE;
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
 *  Process a single XS line
 * ══════════════════════════════════════════════════════════════════ */

static void eshu_xs_process_line(eshu_xs_ctx_t *ctx, eshu_buf_t *out,
                                 const char *line_start, const char *eol) {
	const char *content = eshu_skip_leading_ws(line_start);
	int line_len;

	/* empty line — preserve it */
	if (content >= eol) {
		eshu_buf_putc(out, '\n');
		return;
	}

	line_len = (int)(eol - content);

	/* ── C mode: before MODULE = ── */
	if (ctx->mode == ESHU_XS_C_MODE) {
		/* Check if this is the MODULE line */
		if (eshu_xs_is_module_line(content, eol)) {
			ctx->mode = ESHU_XS_XSUB_MODE;
			ctx->section = ESHU_XS_NONE;
			ctx->c_depth = 0;
			ctx->c_ctx.state = ESHU_CODE;
			/* MODULE line at column 0 */
			eshu_buf_write_trimmed(out, content, line_len);
			eshu_buf_putc(out, '\n');
			return;
		}
		/* Delegate to C scanner */
		eshu_c_process_line(&ctx->c_ctx, out, line_start, eol);
		return;
	}

	/* ── XS mode ── */

	/* Another MODULE line resets */
	if (eshu_xs_is_module_line(content, eol)) {
		ctx->section = ESHU_XS_NONE;
		ctx->c_depth = 0;
		ctx->c_ctx.state = ESHU_CODE;
		eshu_buf_write_trimmed(out, content, line_len);
		eshu_buf_putc(out, '\n');
		return;
	}

	/* Block comment continuation in XS body */
	if (ctx->c_ctx.state == ESHU_COMMENT_BLOCK) {
		int depth = (ctx->section == ESHU_XS_BODY) ? 2 + ctx->c_depth : 1;
		eshu_emit_indent(out, depth, &ctx->cfg);
		eshu_buf_write_trimmed(out, content, line_len);
		eshu_buf_putc(out, '\n');
		eshu_xs_scan_c_nesting(ctx, content, eol);
		return;
	}

	/* Check for BOOT: label (special: depth 0) */
	if (eshu_xs_is_boot_label(content, eol)) {
		ctx->section = ESHU_XS_LABEL;
		ctx->c_depth = 0;
		ctx->is_boot = 1;
		ctx->c_ctx.state = ESHU_CODE;
		/* BOOT: at depth 0 */
		eshu_buf_write_trimmed(out, content, line_len);
		eshu_buf_putc(out, '\n');
		ctx->section = ESHU_XS_BODY;
		return;
	}

	/* Check for XS labels (CODE:, OUTPUT:, etc.) */
	{
		int is_boot = 0;
		if (eshu_xs_is_label(content, eol, &is_boot)) {
			ctx->section = ESHU_XS_LABEL;
			ctx->c_depth = 0;
			ctx->is_boot = 0;
			ctx->c_ctx.state = ESHU_CODE;
			/* Labels at depth 1 */
			eshu_emit_indent(out, 1, &ctx->cfg);
			eshu_buf_write_trimmed(out, content, line_len);
			eshu_buf_putc(out, '\n');
			ctx->section = ESHU_XS_BODY;
			return;
		}
	}

	/* Check for preprocessor in XS mode */
	if (*content == '#') {
		/* Preprocessor stays at column 0 in XS too */
		eshu_buf_write_trimmed(out, content, line_len);
		eshu_buf_putc(out, '\n');
		return;
	}

	/* Determine indent based on current section */
	switch (ctx->section) {
	case ESHU_XS_NONE: {
		/* XSUB return type / function signature — depth 0 */
		eshu_buf_write_trimmed(out, content, line_len);
		eshu_buf_putc(out, '\n');

		/* If line has '(' it might be the function name line;
		 * the next lines will be params until we hit a label */
		{
			const char *pp = content;
			while (pp < eol) {
				if (*pp == '(') {
					ctx->section = ESHU_XS_PARAMS;
					break;
				}
				pp++;
			}
		}
		break;
	}

	case ESHU_XS_PARAMS:
		/* Parameter declarations at depth 1 */
		eshu_emit_indent(out, 1, &ctx->cfg);
		eshu_buf_write_trimmed(out, content, line_len);
		eshu_buf_putc(out, '\n');
		break;

	case ESHU_XS_LABEL:
		/* Shouldn't get here — labels transition to BODY immediately */
		eshu_emit_indent(out, 2, &ctx->cfg);
		eshu_buf_write_trimmed(out, content, line_len);
		eshu_buf_putc(out, '\n');
		break;

	case ESHU_XS_BODY: {
		/* Code inside a label body — base depth 2, or 1 for BOOT */
		int base = ctx->is_boot ? 1 : 2;
		int depth = base + ctx->c_depth;

		/* If line starts with '}', dedent first */
		if (*content == '}') {
			depth--;
			if (depth < base) depth = base;
		}

		eshu_emit_indent(out, depth, &ctx->cfg);
		eshu_buf_write_trimmed(out, content, line_len);
		eshu_buf_putc(out, '\n');

		/* Scan for C nesting changes */
		eshu_xs_scan_c_nesting(ctx, content, eol);
		break;
	}
	}
}

/* ══════════════════════════════════════════════════════════════════
 *  Detect new XSUB boundary — reset section when we see a blank
 *  line or a new return-type line at depth 0 after a completed XSUB
 * ══════════════════════════════════════════════════════════════════ */

static void eshu_xs_check_xsub_boundary(eshu_xs_ctx_t *ctx,
                                        const char *content, const char *eol) {
	/* If we're in XS mode and see a blank line, reset section */
	if (content >= eol) {
		if (ctx->mode == ESHU_XS_XSUB_MODE) {
			ctx->section = ESHU_XS_NONE;
			ctx->c_depth = 0;
			ctx->is_boot = 0;
			ctx->c_ctx.state = ESHU_CODE;
		}
		return;
	}

	/* If we're in params/body and hit a line at column 0 that looks
	 * like a new return type, reset */
	if (ctx->mode == ESHU_XS_XSUB_MODE &&
	    ctx->c_depth == 0 &&
	    (ctx->section == ESHU_XS_PARAMS || ctx->section == ESHU_XS_BODY)) {
		/* A non-indented line that doesn't look like it belongs to
		 * current XSUB — might be new return type */
		/* We handle this via blank-line separation instead */
	}
}

/* ══════════════════════════════════════════════════════════════════
 *  Public API — indent an XS source string
 * ══════════════════════════════════════════════════════════════════ */

static char * eshu_indent_xs(const char *src, size_t src_len,
                             const eshu_config_t *cfg, size_t *out_len) {
	eshu_xs_ctx_t ctx;
	eshu_buf_t out;
	const char *p   = src;
	const char *end = src + src_len;
	char *result;

	eshu_xs_ctx_init(&ctx, cfg);
	eshu_buf_init(&out, src_len + 256);

	{
		int line_num = 1;
		while (p < end) {
			const char *eol = eshu_find_eol(p);
			const char *content = eshu_skip_leading_ws(p);

			/* Check for XSUB boundary (blank lines reset section) */
			eshu_xs_check_xsub_boundary(&ctx, content, eol);

			if (eshu_in_range(cfg, line_num)) {
				eshu_xs_process_line(&ctx, &out, p, eol);
			} else {
				size_t saved = out.len;
				eshu_xs_process_line(&ctx, &out, p, eol);
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

#endif /* ESHU_XS_H */
