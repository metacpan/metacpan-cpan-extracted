/*
 * eshu_lua.h — Lua language indentation scanner
 *
 * Lua uses keyword-based block nesting (do/end, if/then/end, etc.)
 * with no braces for control flow (braces only for table constructors).
 * Long strings [[...]] and long comments --[[...]] can span multiple lines.
 */

#ifndef ESHU_LUA_H
#define ESHU_LUA_H

#include "eshu.h"

/* ══════════════════════════════════════════════════════════════════
 *  Scanner context — persists across lines
 * ══════════════════════════════════════════════════════════════════ */

typedef struct {
	int             depth;
	int             brace_depth;    /* { } table constructor nesting  */
	int             paren_depth;    /* ( ) nesting                    */
	int             long_level;     /* = count in [=[...]=]           */
	enum eshu_state state;
	eshu_config_t   cfg;
} eshu_lua_ctx_t;

static void eshu_lua_ctx_init(eshu_lua_ctx_t *ctx, const eshu_config_t *cfg) {
	ctx->depth       = 0;
	ctx->brace_depth = 0;
	ctx->paren_depth = 0;
	ctx->long_level  = 0;
	ctx->state       = ESHU_CODE;
	ctx->cfg         = *cfg;
}

/* ══════════════════════════════════════════════════════════════════
 *  Helpers
 * ══════════════════════════════════════════════════════════════════ */

static int eshu_lua_isword(char c) {
	return isalnum((unsigned char)c) || c == '_';
}

/* Match keyword kw at p: must not be preceded by or followed by word chars */
static int eshu_lua_kw(const char *src, const char *p, const char *end,
                       const char *kw, int klen) {
	if ((size_t)(end - p) < (size_t)klen) return 0;
	if (memcmp(p, kw, (size_t)klen) != 0) return 0;
	if (p > src && eshu_lua_isword(*(p - 1))) return 0;
	if (p + klen < end && eshu_lua_isword(p[klen])) return 0;
	return 1;
}

/* Scan past opening long bracket [=*[ starting at p (which points to first '[').
 * Returns: level count (number of '='), or -1 if not a long bracket.
 * Advances *pp past the opening bracket. */
static int eshu_lua_open_long(const char **pp, const char *end) {
	const char *p = *pp;
	int level = 0;
	if (p >= end || *p != '[') return -1;
	p++;
	while (p < end && *p == '=') { level++; p++; }
	if (p >= end || *p != '[') return -1;
	p++;
	*pp = p;
	return level;
}

/* Returns 1 if p points to closing long bracket ]=*] matching level.
 * Advances *pp past the closing bracket if matched. */
static int eshu_lua_close_long(const char **pp, const char *end, int level) {
	const char *p = *pp;
	int i;
	if (p >= end || *p != ']') return 0;
	p++;
	for (i = 0; i < level; i++) {
		if (p >= end || *p != '=') return 0;
		p++;
	}
	if (p >= end || *p != ']') return 0;
	p++;
	*pp = p;
	return 1;
}

/* ══════════════════════════════════════════════════════════════════
 *  Per-line scanner: returns pre/post depth deltas
 * ══════════════════════════════════════════════════════════════════ */

typedef struct {
	int pre;
	int post;
} eshu_lua_delta_t;

static eshu_lua_delta_t eshu_lua_scan_line(eshu_lua_ctx_t *ctx,
                                            const char *content, int len)
{
	eshu_lua_delta_t d = {0, 0};
	const char *p   = content;
	const char *end = content + len;
	const char *src = content;
	int local_brace_opens = 0;  /* { opened on this line — cancel same-line } */

	while (p < end) {
		char c = *p;

		/* ── string/comment contexts ── */

		/* single-quoted string */
		if (c == '\'' && ctx->state == ESHU_CODE) {
			p++;
			while (p < end && *p != '\'') {
				if (*p == '\\') { p++; if (p < end) p++; }
				else p++;
			}
			if (p < end) p++;
			continue;
		}

		/* double-quoted string */
		if (c == '"' && ctx->state == ESHU_CODE) {
			p++;
			while (p < end && *p != '"') {
				if (*p == '\\') { p++; if (p < end) p++; }
				else p++;
			}
			if (p < end) p++;
			continue;
		}

		/* long string [=*[ */
		if (c == '[' && ctx->state == ESHU_CODE) {
			const char *tp = p;
			int level = eshu_lua_open_long(&tp, end);
			if (level >= 0) {
				ctx->long_level = level;
				ctx->state = ESHU_LUA_LONG_STR;
				p = tp;
				/* scan rest of line for close */
				while (p < end) {
					if (*p == ']') {
						const char *cp = p;
						if (eshu_lua_close_long(&cp, end, level)) {
							ctx->state = ESHU_CODE;
							p = cp;
							break;
						}
					}
					p++;
				}
				continue;
			}
		}

		/* line comment -- */
		if (c == '-' && p + 1 < end && *(p + 1) == '-' &&
		    ctx->state == ESHU_CODE) {
			/* check for long comment --[=*[ */
			const char *tp = p + 2;
			if (tp < end && *tp == '[') {
				int level = eshu_lua_open_long(&tp, end);
				if (level >= 0) {
					ctx->long_level = level;
					ctx->state = ESHU_LUA_LONG_CMT;
					p = tp;
					/* scan rest of line for close */
					while (p < end) {
						if (*p == ']') {
							const char *cp = p;
							if (eshu_lua_close_long(&cp, end, level)) {
								ctx->state = ESHU_CODE;
								p = cp;
								break;
							}
						}
						p++;
					}
					continue;
				}
			}
			/* plain line comment: rest of line ignored */
			break;
		}

		/* inside long string: scan for close bracket */
		if (ctx->state == ESHU_LUA_LONG_STR ||
		    ctx->state == ESHU_LUA_LONG_CMT) {
			if (c == ']') {
				const char *cp = p;
				if (eshu_lua_close_long(&cp, end, ctx->long_level)) {
					ctx->state = ESHU_CODE;
					p = cp;
					continue;
				}
			}
			p++;
			continue;
		}

		/* paren tracking — suppress keyword detection inside () */
		if (c == '(' && ctx->state == ESHU_CODE) { ctx->paren_depth++; p++; continue; }
		if (c == ')' && ctx->paren_depth > 0)    { ctx->paren_depth--; p++; continue; }

		/* table brace tracking — same-line { } pairs cancel to avoid net depth change */
		if (c == '{' && ctx->state == ESHU_CODE) {
			ctx->brace_depth++;
			local_brace_opens++;
			p++; continue;
		}
		if (c == '}' && ctx->brace_depth > 0) {
			ctx->brace_depth--;
			if (local_brace_opens > 0) {
				local_brace_opens--;  /* cancel same-line open — no net depth change */
			} else {
				d.pre--;  /* close a brace opened on a previous line */
			}
			p++; continue;
		}

		/* ── keyword detection at word boundaries, outside parens ── */
		if (ctx->state == ESHU_CODE && ctx->paren_depth == 0 &&
		    (p == src || !eshu_lua_isword(*(p - 1)))) {

			/* Closers: end, until */
			if (eshu_lua_kw(src, p, end, "end",   3)) { d.pre--; p += 3; continue; }
			if (eshu_lua_kw(src, p, end, "until", 5)) { d.pre--; p += 5; continue; }

			/* elseif: pre-- only; then on same line provides post++ */
			if (eshu_lua_kw(src, p, end, "elseif", 6)) {
				d.pre--;
				p += 6; continue;
			}

			/* else: -1 pre, +1 post (no then follows) */
			if (eshu_lua_kw(src, p, end, "else", 4)) {
				d.pre--; d.post++;
				p += 4; continue;
			}

			/* Deferred openers: then, do */
			if (eshu_lua_kw(src, p, end, "then", 4)) { d.post++; p += 4; continue; }
			if (eshu_lua_kw(src, p, end, "do",   2)) { d.post++; p += 2; continue; }

			/* repeat: opens directly (no then/do follows) */
			if (eshu_lua_kw(src, p, end, "repeat", 6)) { d.post++; p += 6; continue; }

			/* function: +1 post */
			if (eshu_lua_kw(src, p, end, "function", 8)) { d.post++; p += 8; continue; }
		}

		p++;
	}

	/* remaining brace opens that weren't closed on this line → deferred depth increase */
	d.post += local_brace_opens;

	return d;
}

/* ══════════════════════════════════════════════════════════════════
 *  Main indentation entry point
 * ══════════════════════════════════════════════════════════════════ */

static char *eshu_indent_lua(const char *src, size_t src_len,
                              const eshu_config_t *cfg, size_t *out_len)
{
	eshu_lua_ctx_t ctx;
	eshu_buf_t     out;
	const char    *p   = src;
	const char    *end = src + src_len;
	int            lineno = 1;

	eshu_lua_ctx_init(&ctx, cfg);
	eshu_buf_init(&out, src_len + 512);

	while (p < end) {
		const char *line_start = p;
		const char *eol;
		const char *content;
		int         content_len;
		int         is_blank;
		eshu_lua_delta_t delta;

		eol = p;
		while (eol < end && *eol != '\n') eol++;

		content     = eshu_skip_leading_ws(p);
		content_len = (int)(eol - content);
		while (content_len > 0 &&
		       (content[content_len - 1] == ' ' ||
		        content[content_len - 1] == '\t'))
			content_len--;

		is_blank = (content_len == 0);

		/* Inside a long string or comment: emit verbatim */
		if (ctx.state == ESHU_LUA_LONG_STR || ctx.state == ESHU_LUA_LONG_CMT) {
			/* scan for closing bracket on this line */
			const char *pp = content;
			const char *cl = content + content_len;
			while (pp < cl) {
				if (*pp == ']') {
					const char *cp = pp;
					if (eshu_lua_close_long(&cp, cl, ctx.long_level)) {
						ctx.state = ESHU_CODE;
						break;
					}
				}
				pp++;
			}
			eshu_buf_write(&out, line_start, (size_t)(eol - line_start));
			if (eol < end) { eshu_buf_putc(&out, '\n'); eol++; }
			p = eol;
			lineno++;
			continue;
		}

		if (is_blank) {
			if (eol < end) eshu_buf_putc(&out, '\n');
			p = (eol < end) ? eol + 1 : eol;
			lineno++;
			continue;
		}

		delta = eshu_lua_scan_line(&ctx, content, content_len);

		ctx.depth += delta.pre;
		if (ctx.depth < 0) ctx.depth = 0;

		if (eshu_in_range(cfg, lineno)) {
			eshu_emit_indent(&out, ctx.depth, cfg);
		} else {
			eshu_buf_write(&out, line_start, (size_t)(content - line_start));
		}

		eshu_buf_write_trimmed(&out, content, (int)(eol - content));
		if (eol < end) eshu_buf_putc(&out, '\n');

		ctx.depth += delta.post;
		if (ctx.depth < 0) ctx.depth = 0;

		p = (eol < end) ? eol + 1 : eol;
		lineno++;
	}

	eshu_buf_putc(&out, '\0');
	*out_len = out.len - 1;
	return out.data;
}


#include "eshu_hl_util.h"

/* ══════════════════════════════════════════════════════════════════
 *  Lua keyword / builtin tables
 * ══════════════════════════════════════════════════════════════════ */

static const char * const eshu_hl_lua_kw[] = {
    "and", "break", "do", "else", "elseif", "end",
    "false", "for", "function", "goto", "if", "in",
    "local", "nil", "not", "or", "repeat", "return",
    "then", "true", "until", "while",
    NULL
};

static const char * const eshu_hl_lua_bi[] = {
    /* standard library functions */
    "assert", "collectgarbage", "dofile", "error",
    "getmetatable", "ipairs", "load", "loadfile",
    "next", "pairs", "pcall", "print",
    "rawequal", "rawget", "rawlen", "rawset",
    "require", "select", "setmetatable",
    "tonumber", "tostring", "type", "warn", "xpcall",
    /* standard library tables */
    "coroutine", "debug", "io", "math", "os",
    "package", "string", "table", "utf8",
    NULL
};

/* ══════════════════════════════════════════════════════════════════
 *  Lua highlighter
 * ══════════════════════════════════════════════════════════════════ */

static char *eshu_highlight_lua(const char *src, size_t src_len, size_t *out_len) {
    eshu_buf_t  out;
    const char *p     = src;
    const char *end   = src + src_len;
    const char *plain = p;

    eshu_buf_init(&out, src_len * 2 + 64);

#define LUA_SPAN(cls, ts, te) do { \
    eshu_hl_flush(&out, plain, (ts)); \
    eshu_hl_span(&out, (cls), (ts), (te)); \
    p = (te); plain = p; \
} while(0)

    while (p < end) {
        char c = *p;

        /* line comment -- (and long comment --[[ ) */
        if (c == '-' && p + 1 < end && *(p + 1) == '-') {
            const char *ts = p;
            p += 2;
            /* check for long comment --[=*[ */
            if (p < end && *p == '[') {
                const char *lp = p;
                int level = 0;
                lp++;
                while (lp < end && *lp == '=') { level++; lp++; }
                if (lp < end && *lp == '[') {
                    /* long comment: scan for closing ]=level=] */
                    lp++;
                    p = lp;
                    while (p < end) {
                        if (*p == ']') {
                            const char *cp = p + 1;
                            int i;
                            for (i = 0; i < level && cp < end && *cp == '='; i++) cp++;
                            if (i == level && cp < end && *cp == ']') {
                                p = cp + 1;
                                break;
                            }
                        }
                        p++;
                    }
                    LUA_SPAN("esh-c", ts, p);
                    continue;
                }
            }
            /* plain line comment: to EOL */
            while (p < end && *p != '\n') p++;
            LUA_SPAN("esh-c", ts, p);
            continue;
        }

        /* double-quoted string */
        if (c == '"') {
            const char *ts = p++;
            while (p < end && *p != '"') {
                if (*p == '\\') { p++; if (p < end) p++; continue; }
                if (*p == '\n') break;
                p++;
            }
            if (p < end && *p == '"') p++;
            LUA_SPAN("esh-s", ts, p);
            continue;
        }

        /* single-quoted string */
        if (c == '\'') {
            const char *ts = p++;
            while (p < end && *p != '\'') {
                if (*p == '\\') { p++; if (p < end) p++; continue; }
                if (*p == '\n') break;
                p++;
            }
            if (p < end && *p == '\'') p++;
            LUA_SPAN("esh-s", ts, p);
            continue;
        }

        /* long string [=*[ */
        if (c == '[') {
            const char *lp = p + 1;
            int level = 0;
            while (lp < end && *lp == '=') { level++; lp++; }
            if (lp < end && *lp == '[') {
                const char *ts = p;
                lp++;
                p = lp;
                while (p < end) {
                    if (*p == ']') {
                        const char *cp = p + 1;
                        int i;
                        for (i = 0; i < level && cp < end && *cp == '='; i++) cp++;
                        if (i == level && cp < end && *cp == ']') {
                            p = cp + 1;
                            break;
                        }
                    }
                    p++;
                }
                LUA_SPAN("esh-s", ts, p);
                continue;
            }
        }

        /* number: 0x hex, decimal, float */
        if (isdigit((unsigned char)c)) {
            const char *ts = p;
            if (c == '0' && p + 1 < end &&
                (*(p + 1) == 'x' || *(p + 1) == 'X')) {
                p += 2;
                while (p < end && isxdigit((unsigned char)*p)) p++;
                if (p < end && *p == '.') {
                    p++;
                    while (p < end && isxdigit((unsigned char)*p)) p++;
                }
                if (p < end && (*p == 'p' || *p == 'P')) {
                    p++;
                    if (p < end && (*p == '+' || *p == '-')) p++;
                    while (p < end && isdigit((unsigned char)*p)) p++;
                }
            } else {
                while (p < end && isdigit((unsigned char)*p)) p++;
                if (p < end && *p == '.') {
                    p++;
                    while (p < end && isdigit((unsigned char)*p)) p++;
                }
                if (p < end && (*p == 'e' || *p == 'E')) {
                    p++;
                    if (p < end && (*p == '+' || *p == '-')) p++;
                    while (p < end && isdigit((unsigned char)*p)) p++;
                }
            }
            LUA_SPAN("esh-n", ts, p);
            continue;
        }

        /* identifier / keyword / builtin */
        if (eshu_hl_isalpha_(c)) {
            const char *ts = p;
            while (p < end && eshu_hl_isalnum_(*p)) p++;
            eshu_hl_flush(&out, plain, ts);
            plain = p;
            if (eshu_hl_kw(ts, (size_t)(p - ts), eshu_hl_lua_kw)) {
                eshu_hl_span(&out, "esh-k", ts, p);
            } else if (eshu_hl_kw(ts, (size_t)(p - ts), eshu_hl_lua_bi)) {
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

#undef LUA_SPAN
}

#endif /* ESHU_LUA_H */
