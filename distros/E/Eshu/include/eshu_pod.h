/*
 * eshu_pod.h — POD (Plain Old Documentation) indentation scanner
 *
 * Normalizes indentation within POD sections:
 * - Directives (=head1, =over, =item, etc.) stay at column 0
 * - Text paragraphs stay at column 0
 * - Verbatim/code blocks (lines starting with whitespace) are
 *   re-indented to a consistent level (one indent unit by default)
 * - =over/=back nesting is NOT tracked for text indent (that's
 *   a formatter's job) but IS respected for code block context
 */

#ifndef ESHU_POD_H
#define ESHU_POD_H

#include "eshu.h"

/* ══════════════════════════════════════════════════════════════════
 *  Scanner context — persists across lines
 * ══════════════════════════════════════════════════════════════════ */

typedef struct {
	int             in_verbatim;  /* currently in a code block?       */
	int             over_depth;   /* =over nesting depth              */
	eshu_config_t   cfg;
} eshu_pod_ctx_t;

static void eshu_pod_ctx_init(eshu_pod_ctx_t *ctx, const eshu_config_t *cfg) {
	ctx->in_verbatim = 0;
	ctx->over_depth  = 0;
	ctx->cfg         = *cfg;
}

/* ══════════════════════════════════════════════════════════════════
 *  Detect POD directive lines (=head1, =over, =item, =cut, etc.)
 *  These are lines starting with '=' followed by a letter.
 * ══════════════════════════════════════════════════════════════════ */

static int eshu_pod_is_directive(const char *p) {
	return (*p == '=' && isalpha((unsigned char)p[1]));
}

/* Case-insensitive prefix match for directive names */
static int eshu_pod_directive_is(const char *p, const char *name, int nlen) {
	int i;
	if (*p != '=') return 0;
	p++;
	for (i = 0; i < nlen; i++) {
		if (!p[i]) return 0;
		if (tolower((unsigned char)p[i]) != name[i]) return 0;
	}
	/* must be followed by space, digit, or end of meaningful chars */
	if (p[nlen] && isalpha((unsigned char)p[nlen])) return 0;
	return 1;
}

/* ══════════════════════════════════════════════════════════════════
 *  Find the minimum leading whitespace in a block of verbatim lines.
 *  Used for normalization: we strip this common prefix and re-indent.
 * ══════════════════════════════════════════════════════════════════ */

static int eshu_pod_measure_indent(const char *line_start, const char *eol) {
	int n = 0;
	const char *p = line_start;
	while (p < eol && (*p == ' ' || *p == '\t')) {
		if (*p == '\t')
			n += 4; /* count tab as 4 spaces for measurement */
		else
			n++;
		p++;
	}
	return n;
}

/* ══════════════════════════════════════════════════════════════════
 *  Process a single POD line
 * ══════════════════════════════════════════════════════════════════ */

static void eshu_pod_process_line(eshu_pod_ctx_t *ctx, eshu_buf_t *out,
                                  const char *line_start, const char *eol) {
	const char *content = eshu_skip_leading_ws(line_start);
	int content_len = (int)(eol - content);
	int has_leading_ws = (content > line_start);

	/* ── Blank line ── */
	if (content >= eol) {
		ctx->in_verbatim = 0;
		eshu_buf_putc(out, '\n');
		return;
	}

	/* ── Directive line (=something) — always column 0 ── */
	if (eshu_pod_is_directive(content)) {
		ctx->in_verbatim = 0;

		/* Track =over/=back depth */
		if (eshu_pod_directive_is(content, "over", 4)) {
			ctx->over_depth++;
		} else if (eshu_pod_directive_is(content, "back", 4)) {
			ctx->over_depth--;
			if (ctx->over_depth < 0) ctx->over_depth = 0;
		}

		/* Emit at column 0 (strip any accidental leading whitespace) */
		eshu_buf_write_trimmed(out, content, content_len);
		eshu_buf_putc(out, '\n');
		return;
	}

	/* ── Verbatim/code block: line starts with whitespace ── */
	if (has_leading_ws) {
		ctx->in_verbatim = 1;

		/* Remove original leading whitespace, apply one indent level */
		eshu_emit_indent(out, 1, &ctx->cfg);
		eshu_buf_write_trimmed(out, content, content_len);
		eshu_buf_putc(out, '\n');
		return;
	}

	/* ── Normal text paragraph: stays at column 0 ── */
	ctx->in_verbatim = 0;
	eshu_buf_write_trimmed(out, content, content_len);
	eshu_buf_putc(out, '\n');
}

/* ══════════════════════════════════════════════════════════════════
 *  Public API — indent a POD string
 * ══════════════════════════════════════════════════════════════════ */

static char * eshu_indent_pod(const char *src, size_t src_len,
                              const eshu_config_t *cfg, size_t *out_len) {
	eshu_pod_ctx_t ctx;
	eshu_buf_t out;
	const char *p   = src;
	const char *end = src + src_len;
	char *result;

	eshu_pod_ctx_init(&ctx, cfg);
	eshu_buf_init(&out, src_len + 256);

	while (p < end) {
		const char *eol = eshu_find_eol(p);
		eshu_pod_process_line(&ctx, &out, p, eol);
		p = (*eol == '\n') ? eol + 1 : eol;
		if (p > end) p = end;
	}

	/* NUL-terminate */
	eshu_buf_putc(&out, '\0');
	out.len--;

	*out_len = out.len;
	result = out.data;
	return result;
}

#endif /* ESHU_POD_H */
