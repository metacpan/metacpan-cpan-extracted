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
	int             case_depth;       /* depth at which last case/default was seen */
	int             case_extra;       /* 1 = add extra indent to case body lines  */
	int             suppressed_parens; /* unclosed ( whose depth was suppressed   */
	int             line_paren_delta;  /* net ( opens on current line             */
	int             line_brace_delta;  /* net { opens on current line             */
	int             line_bracket_delta;/* net [ opens on current line             */
	enum eshu_state state;
	int             tmpl_depth;
	int             tmpl_brace_depth[ESHU_JS_MAX_TMPL_DEPTH];
	int             can_regex;         /* 1 if next / starts a regex              */
	eshu_config_t   cfg;
} eshu_js_ctx_t;

static void eshu_js_ctx_init(eshu_js_ctx_t *ctx, const eshu_config_t *cfg) {
	ctx->depth              = 0;
	ctx->case_depth         = 0;
	ctx->case_extra         = 0;
	ctx->suppressed_parens  = 0;
	ctx->line_paren_delta   = 0;
	ctx->line_brace_delta   = 0;
	ctx->line_bracket_delta = 0;
	ctx->state              = ESHU_CODE;
	ctx->tmpl_depth         = 0;
	ctx->can_regex          = 1;
	ctx->cfg                = *cfg;
}

/* ══════════════════════════════════════════════════════════════════
 *  Classify first non-ws char for pre-indent adjustment
 * ══════════════════════════════════════════════════════════════════ */

static int eshu_js_is_closing(char c) {
	return c == '}' || c == ')' || c == ']';
}

/* Is this line a switch case/default label?
 * Case labels stay at brace depth; body content gets +1 via case_extra. */
static int eshu_js_is_case_label(const char *content, int len) {
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
			if (c == '{') {
				ctx->depth++;
				ctx->line_brace_delta++;
				ctx->can_regex = 1;
			} else if (c == '(' || c == '[') {
				ctx->depth++;
				if (c == '(') ctx->line_paren_delta++;
				else ctx->line_bracket_delta++;
				ctx->can_regex = 1;
			} else if (c == '}') {
				ctx->depth--;
				if (ctx->depth < 0) ctx->depth = 0;
				ctx->line_brace_delta--;
				/* Check if this closes a template expression */
				if (ctx->tmpl_depth > 0 &&
				    ctx->depth == ctx->tmpl_brace_depth[ctx->tmpl_depth - 1]) {
					ctx->tmpl_depth--;
					ctx->state = ESHU_JS_TEMPLATE;
					ctx->can_regex = 0;
					break;
				}
				ctx->can_regex = 0;
			} else if (c == ']') {
				ctx->depth--;
				if (ctx->depth < 0) ctx->depth = 0;
				ctx->line_bracket_delta--;
				ctx->can_regex = 0;
			} else if (c == ')') {
				if (ctx->line_paren_delta > 0) {
					ctx->line_paren_delta--;
					ctx->depth--;
					if (ctx->depth < 0) ctx->depth = 0;
				} else if (ctx->suppressed_parens > 0) {
					ctx->suppressed_parens--;
				} else {
					ctx->depth--;
					if (ctx->depth < 0) ctx->depth = 0;
				}
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

	/* Leaving a case block: clear case_extra once depth drops below case_depth */
	if (ctx->case_extra && ctx->depth < ctx->case_depth)
		ctx->case_extra = 0;

	if (*content == ')' && ctx->suppressed_parens > 0) {
		/* suppressed paren — don't dedent */
	} else if (eshu_js_is_closing(*content)) {
		indent_depth--;
		if (indent_depth < 0) indent_depth = 0;
		/* still inside a case block at deeper nesting */
		if (ctx->case_extra && ctx->depth > ctx->case_depth)
			indent_depth++;
	} else if (eshu_js_is_case_label(content, line_len)) {
		/* case/default label: stays at brace depth; body lines get +1 */
		ctx->case_depth = ctx->depth;
		ctx->case_extra = 1;
	} else if (ctx->case_extra && ctx->depth >= ctx->case_depth) {
		/* body line inside a case block: add one extra indent level */
		indent_depth++;
	}

	eshu_emit_indent(out, indent_depth, &ctx->cfg);
	eshu_buf_write_trimmed(out, content, line_len);
	eshu_buf_putc(out, '\n');

	/* Scan for nesting changes */
	ctx->line_paren_delta   = 0;
	ctx->line_brace_delta   = 0;
	ctx->line_bracket_delta = 0;
	eshu_js_scan_line(ctx, content, eol);

	/* Suppress unmatched ( when { or [ also opened on the same line.
	 * e.g. foo((x) => { or foo((x) => [ — the outer ( is just call syntax,
	 * only the { or [ should add structural indentation. */
	if (ctx->line_paren_delta > 0 &&
	    (ctx->line_brace_delta > 0 || ctx->line_bracket_delta > 0)) {
		ctx->depth -= ctx->line_paren_delta;
		ctx->suppressed_parens += ctx->line_paren_delta;
	}
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


#include "eshu_hl_util.h"

/* ══════════════════════════════════════════════════════════════════
 *  JavaScript keyword list
 * ══════════════════════════════════════════════════════════════════ */

static const char * const eshu_hl_js_kw[] = {
    "async", "await",
    "break",
    "case", "catch", "class", "const", "continue",
    "debugger", "default", "delete", "do",
    "else", "export", "extends",
    "false", "finally", "for", "function",
    "get",
    "if", "import", "in", "instanceof",
    "let",
    "new", "null",
    "of",
    "return",
    "set", "static", "super", "switch",
    "this", "throw", "true", "try", "typeof",
    "undefined",
    "var", "void",
    "while", "with",
    "yield",
    /* built-ins often treated as keywords */
    "Infinity", "NaN",
    NULL
};

/* ══════════════════════════════════════════════════════════════════
 *  JavaScript highlighter
 * ══════════════════════════════════════════════════════════════════ */

static char *eshu_highlight_js(const char *src, size_t src_len, size_t *out_len) {
    eshu_buf_t out;
    const char *p     = src;
    const char *end   = src + src_len;
    const char *plain = p;
    int last_val      = 0;
    int tmpl_depth    = 0; /* template literal nesting */

    eshu_buf_init(&out, src_len * 2 + 64);

#define JS_SPAN(cls, ts, te) do { \
    eshu_hl_flush(&out, plain, (ts)); \
    eshu_hl_span(&out, (cls), (ts), (te)); \
    p = (te); plain = p; \
} while(0)

    while (p < end) {
        char c = *p;

        /* line comment */
        if (c == '/' && p + 1 < end && *(p + 1) == '/') {
            const char *ts = p; p += 2;
            while (p < end && *p != '\n') p++;
            JS_SPAN("esh-c", ts, p);
            last_val = 0; continue;
        }

        /* block comment */
        if (c == '/' && p + 1 < end && *(p + 1) == '*') {
            const char *ts = p; p += 2;
            while (p + 1 < end && !(*p == '*' && *(p + 1) == '/')) p++;
            if (p + 1 < end) p += 2;
            JS_SPAN("esh-c", ts, p);
            last_val = 0; continue;
        }

        /* template literal */
        if (c == '`') {
            const char *ts = p++;
            tmpl_depth++;
            while (p < end) {
                if (*p == '\\') { p++; if (p < end) p++; continue; }
                if (*p == '`') { p++; tmpl_depth--; break; }
                /* ${...} we skip without sub-highlighting for now */
                p++;
            }
            JS_SPAN("esh-s", ts, p);
            last_val = 1; continue;
        }

        /* string */
        if (c == '"' || c == '\'') {
            const char *ts = p++;
            while (p < end && *p != c) {
                if (*p == '\\') { p++; if (p < end) p++; continue; }
                if (*p == '\n') break;
                p++;
            }
            if (p < end && *p == c) p++;
            JS_SPAN("esh-s", ts, p);
            last_val = 1; continue;
        }

        /* regex: / not preceded by rvalue and not // */
        if (c == '/' && !last_val &&
            !(p + 1 < end && *(p + 1) == '/') &&
            !(p + 1 < end && *(p + 1) == '*')) {
            const char *ts = p++;
            int in_class = 0;
            while (p < end) {
                if (*p == '\\') { p++; if (p < end) p++; continue; }
                if (*p == '[') { in_class = 1; p++; continue; }
                if (*p == ']') { in_class = 0; p++; continue; }
                if (!in_class && *p == '/') { p++; break; }
                if (*p == '\n') { p = ts + 1; goto js_not_regex; }
                p++;
            }
            while (p < end && isalpha((unsigned char)*p)) p++;
            JS_SPAN("esh-r", ts, p);
            last_val = 1; continue;
        js_not_regex:;
        }

        /* number */
        if (isdigit((unsigned char)c) ||
            (c == '.' && p + 1 < end && isdigit((unsigned char)*(p + 1)))) {
            const char *ts = p;
            if (c == '0' && p + 1 < end && (*(p + 1) == 'x' || *(p + 1) == 'X')) {
                p += 2; while (p < end && isxdigit((unsigned char)*p)) p++;
            } else if (c == '0' && p + 1 < end && (*(p + 1) == 'b' || *(p + 1) == 'B')) {
                p += 2; while (p < end && (*p == '0' || *p == '1')) p++;
            } else if (c == '0' && p + 1 < end && (*(p + 1) == 'o' || *(p + 1) == 'O')) {
                p += 2; while (p < end && *p >= '0' && *p <= '7') p++;
            } else {
                while (p < end && (isdigit((unsigned char)*p) || *p == '_')) p++;
                if (p < end && *p == '.') {
                    p++; while (p < end && isdigit((unsigned char)*p)) p++;
                }
                if (p < end && (*p == 'e' || *p == 'E')) {
                    p++; if (p < end && (*p == '+' || *p == '-')) p++;
                    while (p < end && isdigit((unsigned char)*p)) p++;
                }
            }
            /* bigint suffix */
            if (p < end && *p == 'n') p++;
            JS_SPAN("esh-n", ts, p);
            last_val = 1; continue;
        }

        /* identifier or keyword */
        if (eshu_hl_isalpha_(c)) {
            const char *ts = p;
            while (p < end && eshu_hl_isalnum_(*p)) p++;
            eshu_hl_flush(&out, plain, ts);
            plain = p;
            size_t ilen = (size_t)(p - ts);
            if (eshu_hl_kw(ts, ilen, eshu_hl_js_kw)) {
                eshu_hl_span(&out, "esh-k", ts, p);
                last_val = 0;
            } else {
                eshu_hl_write_html(&out, ts, ilen);
                last_val = 1;
            }
            continue;
        }

        /* rvalue context tracking */
        if (c == ')' || c == ']') last_val = 1;
        else if (c == '(' || c == '[' || c == ',' || c == ';' ||
                 c == '=' || c == '!' || c == ':' || c == '?' ||
                 c == '{' || c == '&' || c == '|' || c == '^' ||
                 c == '+' || c == '-' || c == '*' || c == '<' || c == '>')
            last_val = 0;
        if (c == '\n') last_val = 0;
        p++;
    }

    eshu_hl_flush(&out, plain, end);
    eshu_buf_putc(&out, '\0');
    *out_len = out.len - 1;
    return out.data;

#undef JS_SPAN
}

#endif /* ESHU_JS_H */
