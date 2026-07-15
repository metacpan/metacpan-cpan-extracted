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
	ESHU_LANG_CSS    = 5,
	ESHU_LANG_JS     = 6,
	ESHU_LANG_POD    = 7,
	ESHU_LANG_PYTHON = 8,
	ESHU_LANG_BASH   = 9,
	ESHU_LANG_GO     = 10,
	ESHU_LANG_RUST   = 11,
	ESHU_LANG_TS     = 12,
	ESHU_LANG_RUBY   = 13,
	ESHU_LANG_LUA    = 14,
	ESHU_LANG_JAVA   = 15,
	ESHU_LANG_SQL    = 16,
	ESHU_LANG_JSON   = 17,
	ESHU_LANG_YAML   = 18,
	ESHU_LANG_PHP    = 19
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
	ESHU_POD_OVER,
	/* Python-specific states */
	ESHU_PY_STRING_DQ3,  /* triple double-quote string """...""" */
	ESHU_PY_STRING_SQ3,  /* triple single-quote string '''...''' */
	ESHU_PY_STRING_DQ,   /* single double-quote "..."            */
	ESHU_PY_STRING_SQ,   /* single single-quote '...'            */
	ESHU_PY_FSTRING_DQ,  /* f"..." — same as DQ but tracks {}    */
	ESHU_PY_FSTRING_SQ,  /* f'...'                               */
	/* JSON/JSONC states */
	ESHU_JSON_STRING,        /* "..." — content opaque, track \-escapes */
	ESHU_JSON_COMMENT_LINE,  /* // to EOL (JSONC only)                  */
	ESHU_JSON_COMMENT_BLOCK, /* block comment (JSONC only)                */
	/* Bash-specific states */
	ESHU_BASH_HEREDOC,       /* <<WORD  heredoc body                 */
	ESHU_BASH_HEREDOC_IND,   /* <<-WORD heredoc with stripped tabs   */
	ESHU_BASH_ANSI_STR,      /* $'...' ANSI-C quoting                */
	ESHU_BASH_DQUOTE,        /* "..." with $var interpolation        */
	ESHU_BASH_ARITH,         /* $(( )) arithmetic expansion          */
	/* Go-specific states */
	ESHU_GO_RAW_STR,         /* `...` raw string literal (backtick)  */
	ESHU_GO_RUNE,            /* '.' rune literal                     */
	/* Lua-specific states */
	ESHU_LUA_STRING_DQ,      /* "..." double-quoted string           */
	ESHU_LUA_STRING_SQ,      /* '...' single-quoted string           */
	ESHU_LUA_LONG_STR,       /* [[...]] / [=[...]=] long string      */
	ESHU_LUA_LONG_CMT,       /* --[[...]] long comment               */
	/* Java-specific states */
	ESHU_JAVA_TEXT_BLOCK,    /* """...""" text block (Java 15+)       */
	ESHU_JAVA_CHAR,          /* '.' char literal                     */
	ESHU_JAVA_ANNOTATION,    /* @Annotation — single-line            */
	/* PHP-specific states */
	ESHU_PHP_STRING_DQ,      /* "..." with $var interpolation        */
	ESHU_PHP_STRING_SQ,      /* '...' no interpolation               */
	ESHU_PHP_HEREDOC,        /* <<<EOT heredoc body                  */
	ESHU_PHP_NOWDOC,         /* <<<'EOT' nowdoc body                 */
	ESHU_PHP_HTML,           /* content between ?> and <?php         */
	/* Rust-specific states */
	ESHU_RUST_RAW_STR,       /* r"...", r#"..."#, r##"..."## raw strings */
	ESHU_RUST_BYTE_STR,      /* b"..." byte string literal           */
	ESHU_RUST_CHAR,          /* '.' char literal                     */
	ESHU_RUST_LIFETIME,      /* 'a lifetime annotation               */
	/* Ruby-specific states */
	ESHU_RB_STRING_DQ,       /* "..." with #{} interpolation         */
	ESHU_RB_STRING_SQ,       /* '...' no interpolation               */
	ESHU_RB_STRING_PCT,      /* %w[] %i[] %Q[] etc.                  */
	ESHU_RB_HEREDOC,         /* <<HEREDOC body                       */
	ESHU_RB_HEREDOC_SQUIG,   /* <<~HEREDOC body (strips indent)      */
	ESHU_RB_REGEX,           /* /regex/ literal                      */
	ESHU_RB_SYMBOL,          /* :symbol                              */
	ESHU_RB_INTERP,          /* #{...} interpolation inside string   */
	/* SQL-specific states */
	ESHU_SQL_STRING_SQ,      /* '...' single-quoted string (ANSI)    */
	ESHU_SQL_STRING_DQ,      /* "..." double-quoted identifier        */
	ESHU_SQL_IDENT_BT,       /* `...` backtick identifier (MySQL)    */
	ESHU_SQL_IDENT_BR,       /* [...] bracketed identifier (T-SQL)   */
	ESHU_SQL_COMMENT_LINE,   /* -- to EOL                            */
	ESHU_SQL_COMMENT_BLOCK,  /* block comment                        */
	ESHU_SQL_DOLLAR_STR,     /* $$ ... $$ dollar-quoted (PostgreSQL) */
	/* YAML-specific states */
	ESHU_YAML_BLOCK_SCALAR_LIT,  /* | literal block scalar body          */
	ESHU_YAML_BLOCK_SCALAR_FOLD, /* > folded block scalar body           */
	ESHU_YAML_FLOW_MAP,          /* { ... } flow mapping                 */
	ESHU_YAML_FLOW_SEQ,          /* [ ... ] flow sequence                */
	ESHU_YAML_STRING_DQ,         /* "..." double-quoted scalar           */
	ESHU_YAML_STRING_SQ,         /* '...' single-quoted scalar           */
	ESHU_YAML_DIRECTIVE          /* %YAML / %TAG directives              */
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

/* ══════════════════════════════════════════════════════════════════
 *  Python context
 * ══════════════════════════════════════════════════════════════════ */

typedef struct {
	int            depth;           /* current logical indent depth         */
	int            depth_stack[64]; /* leading-space count per depth level  */
	int            depth_top;       /* number of entries in depth_stack     */
	int            bracket_depth;   /* unclosed ( [ { count                 */
	int            in_continuation; /* 1 if prev line ended with backslash  */
	enum eshu_state state;
	eshu_config_t  cfg;
} eshu_py_ctx_t;

/* ══════════════════════════════════════════════════════════════════
 *  JSON context
 * ══════════════════════════════════════════════════════════════════ */

typedef struct {
	int            depth;
	int            jsonc;  /* 1 = tolerate // and block comments */
	enum eshu_state state;
	eshu_config_t  cfg;
} eshu_json_ctx_t;

/* ══════════════════════════════════════════════════════════════════
 *  Java context
 * ══════════════════════════════════════════════════════════════════ */

typedef struct {
	int            depth;
	int            paren_depth;
	int            bracket_depth;
	int            case_depth;
	int            case_extra;
	int            switch_arrow;
	enum eshu_state state;
	eshu_config_t  cfg;
} eshu_java_ctx_t;

/* ══════════════════════════════════════════════════════════════════
 *  PHP context
 * ══════════════════════════════════════════════════════════════════ */

typedef struct {
	int            depth;
	int            paren_depth;
	int            bracket_depth;
	int            case_depth;
	int            case_extra;
	int            in_php;           /* 0 = HTML mode, 1 = PHP mode */
	char           heredoc_tag[64];  /* end-marker for current heredoc */
	int            heredoc_indent;   /* leading-ws chars on end marker */
	enum eshu_state state;
	eshu_config_t  cfg;
} eshu_php_ctx_t;

/* ══════════════════════════════════════════════════════════════════
 *  Ruby context
 * ══════════════════════════════════════════════════════════════════ */

typedef struct {
	int            depth;
	int            brace_depth;       /* { } for hash/block */
	int            paren_depth;       /* ( ) */
	int            bracket_depth;     /* [ ] */
	int            interp_depth;      /* #{} nesting in strings */
	char           heredoc_tag[64];
	int            heredoc_squig;     /* 1 if <<~ */
	int            can_regex;         /* 1 if / starts a regex */
	enum eshu_state state;
	eshu_config_t  cfg;
} eshu_rb_ctx_t;

#endif /* ESHU_H */
