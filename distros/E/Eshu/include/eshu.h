/*
 * eshu.h — Core types, config, and public API for Eshu indentation fixer
 *
 * Pure C, no Perl dependencies.
 */

#ifndef ESHU_H
#define ESHU_H

#include <stdlib.h>
#include <string.h>
#include <ctype.h>

/* ══════════════════════════════════════════════════════════════════
 *  Language enum
 * ══════════════════════════════════════════════════════════════════ */

enum eshu_lang {
	ESHU_LANG_C    = 0,
	ESHU_LANG_PERL = 1,
	ESHU_LANG_XS   = 2,
	ESHU_LANG_XML  = 3,
	ESHU_LANG_HTML = 4,
	ESHU_LANG_CSS  = 5,
	ESHU_LANG_JS   = 6,
	ESHU_LANG_POD  = 7
};

/* ══════════════════════════════════════════════════════════════════
 *  Scanner state
 * ══════════════════════════════════════════════════════════════════ */

enum eshu_state {
	ESHU_CODE,
	ESHU_STRING_DQ,
	ESHU_STRING_SQ,
	ESHU_CHAR_LIT,
	ESHU_COMMENT_LINE,
	ESHU_COMMENT_BLOCK,
	ESHU_PREPROCESSOR,
	/* Perl-specific states */
	ESHU_HEREDOC,
	ESHU_HEREDOC_INDENT,
	ESHU_REGEX,
	ESHU_QW,
	ESHU_QQ,
	ESHU_Q,
	ESHU_POD,
	/* XML/HTML-specific states */
	ESHU_XML_TAG,
	ESHU_XML_COMMENT,
	ESHU_XML_CDATA,
	ESHU_XML_PI,
	ESHU_XML_DOCTYPE,
	ESHU_XML_ATTR_DQ,
	ESHU_XML_ATTR_SQ,
	ESHU_XML_VERBATIM,
	/* CSS-specific states */
	ESHU_CSS_STRING_DQ,
	ESHU_CSS_STRING_SQ,
	ESHU_CSS_COMMENT,
	ESHU_CSS_URL,
	/* JS-specific states */
	ESHU_JS_TEMPLATE,
	ESHU_JS_REGEX,
	ESHU_JS_REGEX_CLASS,
	/* POD-specific states */
	ESHU_POD_VERBATIM,
	ESHU_POD_OVER
};

/* ══════════════════════════════════════════════════════════════════
 *  Configuration
 * ══════════════════════════════════════════════════════════════════ */

typedef struct {
	char indent_char;      /* '\t' or ' '           */
	int  indent_width;     /* spaces per level (ignored for tabs) */
	int  indent_pp;        /* indent preprocessor directives?     */
	int  lang;             /* eshu_lang enum value   */
	int  range_start;      /* first line to reindent (1-based, 0=all) */
	int  range_end;        /* last line to reindent  (1-based, 0=all) */
} eshu_config_t;

static eshu_config_t eshu_default_config(void) {
	eshu_config_t c;
	c.indent_char  = '\t';
	c.indent_width = 1;
	c.indent_pp    = 0;
	c.lang         = ESHU_LANG_C;
	c.range_start  = 0;
	c.range_end    = 0;
	return c;
}

/* Check if a line number is within the configured range (or range is disabled) */
static int eshu_in_range(const eshu_config_t *cfg, int line_num) {
	if (cfg->range_start == 0) return 1; /* no range = all lines */
	return line_num >= cfg->range_start && line_num <= cfg->range_end;
}

/* ══════════════════════════════════════════════════════════════════
 *  Dynamic buffer
 * ══════════════════════════════════════════════════════════════════ */

typedef struct {
	char   *data;
	size_t  len;
	size_t  cap;
} eshu_buf_t;

static void eshu_buf_init(eshu_buf_t *b, size_t initial) {
	b->cap  = initial > 0 ? initial : 4096;
	b->data = (char *)malloc(b->cap);
	b->len  = 0;
}

static void eshu_buf_ensure(eshu_buf_t *b, size_t extra) {
	while (b->len + extra > b->cap) {
		b->cap *= 2;
		b->data = (char *)realloc(b->data, b->cap);
	}
}

static void eshu_buf_putc(eshu_buf_t *b, char c) {
	eshu_buf_ensure(b, 1);
	b->data[b->len++] = c;
}

static void eshu_buf_write(eshu_buf_t *b, const char *s, size_t n) {
	eshu_buf_ensure(b, n);
	memcpy(b->data + b->len, s, n);
	b->len += n;
}

static void eshu_buf_free(eshu_buf_t *b) {
	if (b->data) free(b->data);
	b->data = NULL;
	b->len  = 0;
	b->cap  = 0;
}

/* ══════════════════════════════════════════════════════════════════
 *  Line extraction helper
 * ══════════════════════════════════════════════════════════════════ */

/* Find end of current line. Returns pointer to '\n' or to the
 * terminating NUL if no newline. */
static const char * eshu_find_eol(const char *p) {
	while (*p && *p != '\n')
		p++;
	return p;
}

/* Return pointer to first non-whitespace char in line */
static const char * eshu_skip_leading_ws(const char *p) {
	while (*p == ' ' || *p == '\t')
		p++;
	return p;
}

/* ══════════════════════════════════════════════════════════════════
 *  Trim trailing whitespace
 * ══════════════════════════════════════════════════════════════════ */

/* Return length of content with trailing whitespace removed */
static int eshu_trimmed_len(const char *content, int len) {
	while (len > 0 && (content[len - 1] == ' ' || content[len - 1] == '\t'))
		len--;
	return len;
}

/* Write content to buffer with trailing whitespace stripped */
static void eshu_buf_write_trimmed(eshu_buf_t *b, const char *s, int n) {
	n = eshu_trimmed_len(s, n);
	if (n > 0)
		eshu_buf_write(b, s, (size_t)n);
}

/* ══════════════════════════════════════════════════════════════════
 *  Emit indentation
 * ══════════════════════════════════════════════════════════════════ */

static void eshu_emit_indent(eshu_buf_t *out, int depth,
                             const eshu_config_t *cfg) {
	int i;
	if (depth < 0) depth = 0;
	if (cfg->indent_char == '\t') {
		for (i = 0; i < depth; i++)
			eshu_buf_putc(out, '\t');
	} else {
		int n = depth * cfg->indent_width;
		for (i = 0; i < n; i++)
			eshu_buf_putc(out, ' ');
	}
}

#endif /* ESHU_H */
