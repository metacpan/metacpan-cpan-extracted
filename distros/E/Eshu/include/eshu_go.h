/*
 * eshu_go.h — Go language indentation scanner
 *
 * Go is brace-based like C but without preprocessor directives.
 * Handles {}, (), [] nesting; interpreted strings "..."; raw string
 * literals `...` (backtick, can span lines); rune literals '.' ;
 * and // / block comments.  No case_extra needed — Go switch/case
 * keeps case labels at the same depth as the braces.
 */

#ifndef ESHU_GO_H
#define ESHU_GO_H

#include "eshu.h"

/* ══════════════════════════════════════════════════════════════════
 *  Scanner context — persists across lines
 * ══════════════════════════════════════════════════════════════════ */

typedef struct {
	int            depth;
	enum eshu_state state;
	eshu_config_t  cfg;
} eshu_go_ctx_t;

static void eshu_go_ctx_init(eshu_go_ctx_t *ctx, const eshu_config_t *cfg) {
	ctx->depth = 0;
	ctx->state = ESHU_CODE;
	ctx->cfg   = *cfg;
}

/* ══════════════════════════════════════════════════════════════════
 *  Helpers
 * ══════════════════════════════════════════════════════════════════ */

/* Go case/default labels sit at switch-brace level (depth-1 vs body).
 * Returns 1 if trimmed line content is a case or default clause header. */
static int eshu_go_is_case_label(const char *content, int len) {
	const char *end = content + len;
	while (end > content && (*(end-1) == ' ' || *(end-1) == '\t')) end--;
	len = (int)(end - content);
	if (len < 5) return 0;
	if (end == content || *(end-1) != ':') return 0;
	if (strncmp(content, "case ", 5) == 0) return 1;
	if (len >= 7 && strncmp(content, "default", 7) == 0 &&
	    (len == 7 || content[7] == ':' || content[7] == ' ')) return 1;
	return 0;
}

/* ══════════════════════════════════════════════════════════════════
 *  Scan a line for nesting changes — called after emit
 * ══════════════════════════════════════════════════════════════════ */

static void eshu_go_scan_line(eshu_go_ctx_t *ctx, const char *p, const char *end) {
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
			} else if (c == '`') {
				ctx->state = ESHU_GO_RAW_STR;
			} else if (c == '\'') {
				ctx->state = ESHU_GO_RUNE;
			} else if (c == '/' && p + 1 < end && *(p + 1) == '/') {
				return; /* line comment — stop */
			} else if (c == '/' && p + 1 < end && *(p + 1) == '*') {
				ctx->state = ESHU_COMMENT_BLOCK;
				p++;
			}
			break;

		case ESHU_STRING_DQ:
			if (c == '\\' && p + 1 < end) {
				p++; /* skip escaped char */
			} else if (c == '"') {
				ctx->state = ESHU_CODE;
			}
			break;

		case ESHU_GO_RAW_STR:
			/* backtick string: no escapes, terminated by next backtick */
			if (c == '`') {
				ctx->state = ESHU_CODE;
			}
			break;

		case ESHU_GO_RUNE:
			if (c == '\\' && p + 1 < end) {
				p++;
			} else if (c == '\'') {
				ctx->state = ESHU_CODE;
			}
			break;

		case ESHU_COMMENT_BLOCK:
			if (c == '*' && p + 1 < end && *(p + 1) == '/') {
				ctx->state = ESHU_CODE;
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

static void eshu_go_process_line(eshu_go_ctx_t *ctx, eshu_buf_t *out,
                                 const char *line_start, const char *eol,
                                 int lineno) {
	const char *content = eshu_skip_leading_ws(line_start);
	int line_len;
	int indent_depth;

	/* empty line — preserve it */
	if (content >= eol) {
		eshu_buf_putc(out, '\n');
		return;
	}

	line_len = (int)(eol - content);

	/* Inside a raw string or block comment: pass through verbatim */
	if (ctx->state == ESHU_GO_RAW_STR) {
		if (eshu_in_range(&ctx->cfg, lineno)) {
			eshu_buf_write_trimmed(out, content, line_len);
		} else {
			eshu_buf_write_trimmed(out, line_start, (int)(eol - line_start));
		}
		eshu_buf_putc(out, '\n');
		eshu_go_scan_line(ctx, content, eol);
		return;
	}

	if (ctx->state == ESHU_COMMENT_BLOCK) {
		/* Preserve interior whitespace of block comment continuation lines. */
		eshu_emit_indent(out, ctx->depth, &ctx->cfg);
		eshu_buf_write_trimmed(out, line_start, (int)(eol - line_start));
		eshu_buf_putc(out, '\n');
		eshu_go_scan_line(ctx, content, eol);
		return;
	}

	indent_depth = ctx->depth;

	/* Closing brace/paren/bracket — dedent this line */
	if (*content == '}' || *content == ')' || *content == ']') {
		indent_depth--;
		if (indent_depth < 0) indent_depth = 0;
	} else if (eshu_go_is_case_label(content, line_len)) {
		/* case/default labels sit one level shallower than the body */
		indent_depth--;
		if (indent_depth < 0) indent_depth = 0;
	}

	if (eshu_in_range(&ctx->cfg, lineno)) {
		eshu_emit_indent(out, indent_depth, &ctx->cfg);
	} else {
		eshu_buf_write(out, line_start, (size_t)(content - line_start));
	}

	eshu_buf_write_trimmed(out, content, line_len);
	eshu_buf_putc(out, '\n');

	eshu_go_scan_line(ctx, content, eol);
}

/* ══════════════════════════════════════════════════════════════════
 *  Public API — indent a Go source string
 * ══════════════════════════════════════════════════════════════════ */

static char *eshu_indent_go(const char *src, size_t src_len,
                             const eshu_config_t *cfg, size_t *out_len) {
	eshu_go_ctx_t ctx;
	eshu_buf_t    out;
	const char   *p   = src;
	const char   *end = src + src_len;
	int           lineno = 1;

	eshu_go_ctx_init(&ctx, cfg);
	eshu_buf_init(&out, src_len + 256);

	while (p < end) {
		const char *eol = eshu_find_eol(p);
		eshu_go_process_line(&ctx, &out, p, eol, lineno);
		p = eol;
		if (*p == '\n') p++;
		lineno++;
	}

	eshu_buf_putc(&out, '\0');
	out.len--;
	*out_len = out.len;
	return out.data;
}


#include "eshu_hl_util.h"

/* ══════════════════════════════════════════════════════════════════
 *  Go keyword / builtin tables
 * ══════════════════════════════════════════════════════════════════ */

static const char * const eshu_hl_go_kw[] = {
    "break", "case", "chan", "const", "continue",
    "default", "defer", "else", "fallthrough", "for",
    "func", "go", "goto", "if", "import",
    "interface", "map", "package", "range", "return",
    "select", "struct", "switch", "type", "var",
    NULL
};

static const char * const eshu_hl_go_bi[] = {
    /* predeclared functions */
    "append", "cap", "close", "complex", "copy",
    "delete", "imag", "len", "make", "new",
    "panic", "print", "println", "real", "recover",
    /* predeclared types */
    "bool", "byte", "complex64", "complex128",
    "error", "float32", "float64",
    "int", "int8", "int16", "int32", "int64",
    "rune", "string",
    "uint", "uint8", "uint16", "uint32", "uint64", "uintptr",
    /* predeclared constants */
    "false", "iota", "nil", "true",
    NULL
};

/* ══════════════════════════════════════════════════════════════════
 *  Go highlighter
 * ══════════════════════════════════════════════════════════════════ */

static char *eshu_highlight_go(const char *src, size_t src_len, size_t *out_len) {
    eshu_buf_t  out;
    const char *p     = src;
    const char *end   = src + src_len;
    const char *plain = p;

    eshu_buf_init(&out, src_len * 2 + 64);

#define GO_SPAN(cls, ts, te) do { \
    eshu_hl_flush(&out, plain, (ts)); \
    eshu_hl_span(&out, (cls), (ts), (te)); \
    p = (te); plain = p; \
} while(0)

    while (p < end) {
        char c = *p;

        /* line comment */
        if (c == '/' && p + 1 < end && *(p + 1) == '/') {
            const char *ts = p;
            p += 2;
            while (p < end && *p != '\n') p++;
            GO_SPAN("esh-c", ts, p);
            continue;
        }

        /* block comment */
        if (c == '/' && p + 1 < end && *(p + 1) == '*') {
            const char *ts = p;
            p += 2;
            while (p + 1 < end && !(*p == '*' && *(p + 1) == '/')) p++;
            if (p + 1 < end) p += 2;
            GO_SPAN("esh-c", ts, p);
            continue;
        }

        /* interpreted string "..." */
        if (c == '"') {
            const char *ts = p++;
            while (p < end && *p != '"') {
                if (*p == '\\') { p++; if (p < end) p++; continue; }
                if (*p == '\n') break;
                p++;
            }
            if (p < end && *p == '"') p++;
            GO_SPAN("esh-s", ts, p);
            continue;
        }

        /* raw string `...` — can span multiple lines */
        if (c == '`') {
            const char *ts = p++;
            while (p < end && *p != '`') p++;
            if (p < end) p++;
            GO_SPAN("esh-s", ts, p);
            continue;
        }

        /* rune literal '.' */
        if (c == '\'') {
            const char *ts = p++;
            while (p < end && *p != '\'') {
                if (*p == '\\') { p++; if (p < end) p++; continue; }
                if (*p == '\n') break;
                p++;
            }
            if (p < end && *p == '\'') p++;
            GO_SPAN("esh-s", ts, p);
            continue;
        }

        /* number: digit, 0x hex, 0b binary, 0o octal, or .digit float */
        if (isdigit((unsigned char)c) ||
            (c == '.' && p + 1 < end && isdigit((unsigned char)*(p + 1)))) {
            const char *ts = p;
            if (c == '0' && p + 1 < end) {
                char next = *(p + 1);
                if (next == 'x' || next == 'X') {
                    p += 2;
                    while (p < end && (isxdigit((unsigned char)*p) || *p == '_')) p++;
                } else if (next == 'b' || next == 'B') {
                    p += 2;
                    while (p < end && (*p == '0' || *p == '1' || *p == '_')) p++;
                } else if (next == 'o' || next == 'O') {
                    p += 2;
                    while (p < end && ((*p >= '0' && *p <= '7') || *p == '_')) p++;
                } else {
                    while (p < end && (isdigit((unsigned char)*p) || *p == '_')) p++;
                    if (p < end && *p == '.') {
                        p++;
                        while (p < end && (isdigit((unsigned char)*p) || *p == '_')) p++;
                    }
                    if (p < end && (*p == 'e' || *p == 'E')) {
                        p++;
                        if (p < end && (*p == '+' || *p == '-')) p++;
                        while (p < end && isdigit((unsigned char)*p)) p++;
                    }
                }
            } else {
                while (p < end && (isdigit((unsigned char)*p) || *p == '_')) p++;
                if (p < end && *p == '.') {
                    p++;
                    while (p < end && (isdigit((unsigned char)*p) || *p == '_')) p++;
                }
                if (p < end && (*p == 'e' || *p == 'E')) {
                    p++;
                    if (p < end && (*p == '+' || *p == '-')) p++;
                    while (p < end && isdigit((unsigned char)*p)) p++;
                }
            }
            /* imaginary suffix */
            if (p < end && *p == 'i') p++;
            GO_SPAN("esh-n", ts, p);
            continue;
        }

        /* identifier / keyword / builtin */
        if (eshu_hl_isalpha_(c)) {
            const char *ts = p;
            while (p < end && eshu_hl_isalnum_(*p)) p++;
            eshu_hl_flush(&out, plain, ts);
            plain = p;
            if (eshu_hl_kw(ts, (size_t)(p - ts), eshu_hl_go_kw)) {
                eshu_hl_span(&out, "esh-k", ts, p);
            } else if (eshu_hl_kw(ts, (size_t)(p - ts), eshu_hl_go_bi)) {
                eshu_hl_span(&out, "esh-b", ts, p);
            } else {
                eshu_hl_write_html(&out, ts, (size_t)(p - ts));
            }
            continue;
        }

        p++;
    }

    eshu_hl_flush(&out, plain, end);
    eshu_buf_putc(&out, '\0');
    *out_len = out.len - 1;
    return out.data;

#undef GO_SPAN
}

#endif /* ESHU_GO_H */
