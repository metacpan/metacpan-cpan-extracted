/*
 * eshu_rust.h — Rust language indentation scanner
 *
 * Rust is brace-based like Go.  Additional constructs handled:
 *   - nested block comments (comment_depth counter)
 *   - raw strings r"...", r#"..."#, r##"..."##  (raw_hash_count)
 *   - byte strings b"...", byte chars b'.', raw byte strings br#"..."#
 *   - char literals '.' vs lifetime annotations 'a
 *   - attributes #[...] and #![...] (treated as plain lines)
 */

#ifndef ESHU_RUST_H
#define ESHU_RUST_H

#include "eshu.h"

/* ══════════════════════════════════════════════════════════════════
 *  Scanner context — persists across lines
 * ══════════════════════════════════════════════════════════════════ */

typedef struct {
	int             depth;
	int             comment_depth;   /* nesting level for block comments */
	int             raw_hash_count;  /* # count in r#"..."# literals  */
	enum eshu_state state;
	eshu_config_t   cfg;
} eshu_rust_ctx_t;

static void eshu_rust_ctx_init(eshu_rust_ctx_t *ctx, const eshu_config_t *cfg) {
	ctx->depth          = 0;
	ctx->comment_depth  = 0;
	ctx->raw_hash_count = 0;
	ctx->state          = ESHU_CODE;
	ctx->cfg            = *cfg;
}

/* ══════════════════════════════════════════════════════════════════
 *  Helpers
 * ══════════════════════════════════════════════════════════════════ */

/* Returns 1 if the ' at p is a lifetime annotation rather than a char literal.
 * Lifetime: 'ident not followed by '  (e.g., 'a, 'static, 'lifetime)
 * Char lit:  '.' or 'a' or '\n' etc. */
static int eshu_rust_is_lifetime(const char *p, const char *end) {
	const char *q = p + 1;
	if (q >= end) return 0;
	/* escape sequences are always char literals */
	if (*q == '\\') return 0;
	/* non-alphabetic start → char literal */
	if (!isalpha((unsigned char)*q) && *q != '_') return 0;
	/* scan the identifier body */
	q++;
	while (q < end && (isalnum((unsigned char)*q) || *q == '_')) q++;
	/* if the identifier is immediately followed by ' → char literal, else lifetime */
	return (q >= end || *q != '\'') ? 1 : 0;
}

/* Try to match a raw string opener at *pp (which may point to 'r' or 'b').
 * Handles r"", r#""#, r##""##, br"", br#""#.
 * Returns number of # signs (>= 0) on success, -1 on failure.
 * Advances *pp past the opening quote on success. */
static int eshu_rust_raw_open(const char **pp, const char *end) {
	const char *p = *pp;
	/* skip optional 'b' prefix: br"" */
	if (*p == 'b' && p + 1 < end && *(p + 1) == 'r') p++;
	if (p >= end || *p != 'r') return -1;
	p++;
	int hashes = 0;
	while (p < end && *p == '#') { hashes++; p++; }
	if (p >= end || *p != '"') return -1;
	p++; /* skip opening " */
	*pp = p;
	return hashes;
}

/* Try to match a raw string closer at *pp: " followed by raw_hash_count '#' chars.
 * Advances *pp past the closer on success. */
static int eshu_rust_raw_close(const char **pp, const char *end, int hashes) {
	const char *p = *pp;
	if (p >= end || *p != '"') return 0;
	p++;
	int h = 0;
	while (h < hashes && p < end && *p == '#') { h++; p++; }
	if (h < hashes) return 0;
	*pp = p;
	return 1;
}

/* ══════════════════════════════════════════════════════════════════
 *  Line scanner — updates ctx->depth in place
 * ══════════════════════════════════════════════════════════════════ */

static void eshu_rust_scan_line(eshu_rust_ctx_t *ctx,
                                const char *p, const char *end)
{
	while (p < end) {
		char c = *p;

		/* ── block comment (potentially nested) ── */
		if (ctx->state == ESHU_COMMENT_BLOCK) {
			if (c == '/' && p + 1 < end && *(p + 1) == '*') {
				ctx->comment_depth++;
				p += 2; continue;
			}
			if (c == '*' && p + 1 < end && *(p + 1) == '/') {
				if (--ctx->comment_depth <= 0) {
					ctx->comment_depth = 0;
					ctx->state = ESHU_CODE;
				}
				p += 2; continue;
			}
			p++; continue;
		}

		/* ── raw string ── */
		if (ctx->state == ESHU_RUST_RAW_STR) {
			const char *tp = p;
			if (eshu_rust_raw_close(&tp, end, ctx->raw_hash_count)) {
				ctx->state = ESHU_CODE;
				p = tp;
			} else {
				p++;
			}
			continue;
		}

		/* ── regular DQ string / byte string ── */
		if (ctx->state == ESHU_STRING_DQ || ctx->state == ESHU_RUST_BYTE_STR) {
			if (c == '\\' && p + 1 < end) {
				p += 2; continue;
			}
			if (c == '"') {
				ctx->state = ESHU_CODE;
			}
			p++; continue;
		}

		/* ── char literal ── */
		if (ctx->state == ESHU_RUST_CHAR) {
			if (c == '\\' && p + 1 < end) {
				p += 2; continue;
			}
			if (c == '\'') {
				ctx->state = ESHU_CODE;
			}
			p++; continue;
		}

		/* ══ ESHU_CODE ══ */

		/* line comment: // */
		if (c == '/' && p + 1 < end && *(p + 1) == '/') {
			return; /* rest of line is comment */
		}

		/* block comment open: / * */
		if (c == '/' && p + 1 < end && *(p + 1) == '*') {
			ctx->state    = ESHU_COMMENT_BLOCK;
			ctx->comment_depth = 1;
			p += 2; continue;
		}

		/* attribute: #[ or #![ — treat as plain, no depth change */
		if (c == '#' && p + 1 < end &&
		    (*(p + 1) == '[' || (*(p + 1) == '!' && p + 2 < end && *(p + 2) == '['))) {
			/* skip to matching ] */
			int attr_depth = 0;
			p++;
			while (p < end) {
				if (*p == '[') { attr_depth++; p++; }
				else if (*p == ']') { attr_depth--; p++; if (attr_depth <= 0) break; }
				else p++;
			}
			continue;
		}

		/* raw string: r"", r#""#, br"" */
		if ((c == 'r' || (c == 'b' && p + 1 < end && *(p + 1) == 'r')) &&
		    ctx->state == ESHU_CODE) {
			const char *tp = p;
			int hashes = eshu_rust_raw_open(&tp, end);
			if (hashes >= 0) {
				ctx->raw_hash_count = hashes;
				ctx->state = ESHU_RUST_RAW_STR;
				p = tp;
				continue;
			}
		}

		/* byte string: b"..." or byte char: b'.' */
		if (c == 'b' && p + 1 < end && ctx->state == ESHU_CODE) {
			if (*(p + 1) == '"') {
				ctx->state = ESHU_RUST_BYTE_STR;
				p += 2; continue;
			}
			if (*(p + 1) == '\'') {
				ctx->state = ESHU_RUST_CHAR;
				p += 2; continue;
			}
		}

		/* regular DQ string */
		if (c == '"') {
			ctx->state = ESHU_STRING_DQ;
			p++; continue;
		}

		/* char literal or lifetime */
		if (c == '\'') {
			if (eshu_rust_is_lifetime(p, end)) {
				/* lifetime 'a — skip the identifier */
				p++;
				while (p < end && (isalnum((unsigned char)*p) || *p == '_')) p++;
				continue;
			}
			ctx->state = ESHU_RUST_CHAR;
			p++; continue;
		}

		/* braces / parens / brackets */
		if (c == '{' || c == '(' || c == '[') {
			ctx->depth++;
		} else if (c == '}' || c == ')' || c == ']') {
			ctx->depth--;
			if (ctx->depth < 0) ctx->depth = 0;
		}

		p++;
	}
}

/* ══════════════════════════════════════════════════════════════════
 *  Process a single line — decide indent, emit, scan
 * ══════════════════════════════════════════════════════════════════ */

static void eshu_rust_process_line(eshu_rust_ctx_t *ctx, eshu_buf_t *out,
                                   const char *line_start, const char *eol,
                                   int lineno)
{
	const char *content = eshu_skip_leading_ws(line_start);
	int line_len;
	int indent_depth;

	/* empty line */
	if (content >= eol) {
		eshu_buf_putc(out, '\n');
		return;
	}

	line_len = (int)(eol - content);

	/* raw string continuation: emit verbatim (no reindent) */
	if (ctx->state == ESHU_RUST_RAW_STR) {
		if (eshu_in_range(&ctx->cfg, lineno)) {
			eshu_buf_write_trimmed(out, content, line_len);
		} else {
			eshu_buf_write_trimmed(out, line_start, (int)(eol - line_start));
		}
		eshu_buf_putc(out, '\n');
		eshu_rust_scan_line(ctx, content, eol);
		return;
	}

	/* block comment continuation: emit with current indent + original content */
	if (ctx->state == ESHU_COMMENT_BLOCK) {
		eshu_emit_indent(out, ctx->depth, &ctx->cfg);
		eshu_buf_write_trimmed(out, line_start, (int)(eol - line_start));
		eshu_buf_putc(out, '\n');
		eshu_rust_scan_line(ctx, content, eol);
		return;
	}

	indent_depth = ctx->depth;

	/* closing brace/bracket/paren at start of content → dedent this line */
	if (*content == '}' || *content == ')' || *content == ']') {
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

	eshu_rust_scan_line(ctx, content, eol);
}

/* ══════════════════════════════════════════════════════════════════
 *  Public API — indent a Rust source string
 * ══════════════════════════════════════════════════════════════════ */

static char *eshu_indent_rust(const char *src, size_t src_len,
                               const eshu_config_t *cfg, size_t *out_len)
{
	eshu_rust_ctx_t ctx;
	eshu_buf_t      out;
	const char     *p   = src;
	const char     *end = src + src_len;
	int             lineno = 1;

	eshu_rust_ctx_init(&ctx, cfg);
	eshu_buf_init(&out, src_len + 256);

	while (p < end) {
		const char *eol = eshu_find_eol(p);
		eshu_rust_process_line(&ctx, &out, p, eol, lineno);
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
 *  Rust keyword / builtin lists
 * ══════════════════════════════════════════════════════════════════ */

static const char * const eshu_hl_rust_kw[] = {
    "Self", "as", "async", "await", "break", "const", "continue",
    "crate", "dyn", "else", "enum", "extern", "false", "fn", "for",
    "if", "impl", "in", "let", "loop", "match", "mod", "move", "mut",
    "pub", "ref", "return", "self", "static", "struct", "super",
    "trait", "true", "type", "union", "unsafe", "use", "where", "while",
    /* reserved / future keywords */
    "abstract", "become", "box", "do", "final", "macro", "override",
    "priv", "try", "typeof", "unsized", "virtual", "yield",
    NULL
};

static const char * const eshu_hl_rust_bi[] = {
    /* primitive types */
    "bool", "char", "f32", "f64",
    "i8", "i16", "i32", "i64", "i128", "isize",
    "str", "u8", "u16", "u32", "u64", "u128", "usize",
    /* standard library types / traits */
    "Box", "Clone", "Copy", "Debug", "Default", "Display", "Drop",
    "Eq", "Error", "From", "Hash", "Into", "Iterator",
    "None", "Option", "Ord", "PartialEq", "PartialOrd",
    "Result", "Send", "Some", "String", "Sync", "ToString", "Vec",
    /* common macros (bare name, '!' handled separately) */
    "assert", "assert_eq", "assert_ne",
    "dbg", "eprint", "eprintln", "format",
    "include_bytes", "include_str",
    "panic", "print", "println",
    "todo", "unimplemented", "unreachable", "vec", "write", "writeln",
    NULL
};

/* ══════════════════════════════════════════════════════════════════
 *  Rust highlighter helpers
 * ══════════════════════════════════════════════════════════════════ */

static int eshu_hl_rust_is_lifetime(const char *p, const char *end) {
    const char *q = p + 1;
    if (q >= end) return 0;
    if (*q == '\\') return 0;
    if (!isalpha((unsigned char)*q) && *q != '_') return 0;
    q++;
    while (q < end && (isalnum((unsigned char)*q) || *q == '_')) q++;
    return (q >= end || *q != '\'') ? 1 : 0;
}

/* ══════════════════════════════════════════════════════════════════
 *  Rust highlighter
 * ══════════════════════════════════════════════════════════════════ */

static char *eshu_highlight_rust(const char *src, size_t src_len, size_t *out_len) {
    eshu_buf_t  out;
    const char *p     = src;
    const char *end   = src + src_len;
    const char *plain = p;

    eshu_buf_init(&out, src_len * 2 + 64);

#define RUST_SPAN(cls, ts, te) do { \
    eshu_hl_flush(&out, plain, (ts)); \
    eshu_hl_span(&out, (cls), (ts), (te)); \
    p = (te); plain = p; \
} while(0)

    while (p < end) {
        char c = *p;

        /* line comment: // */
        if (c == '/' && p + 1 < end && *(p + 1) == '/') {
            const char *ts = p;
            p += 2;
            while (p < end && *p != '\n') p++;
            RUST_SPAN("esh-c", ts, p);
            continue;
        }

        /* nested block comment */
        if (c == '/' && p + 1 < end && *(p + 1) == '*') {
            const char *ts = p;
            int depth = 1;
            p += 2;
            while (p < end && depth > 0) {
                if (*p == '/' && p + 1 < end && *(p + 1) == '*') {
                    depth++; p += 2;
                } else if (*p == '*' && p + 1 < end && *(p + 1) == '/') {
                    depth--; p += 2;
                } else {
                    p++;
                }
            }
            RUST_SPAN("esh-c", ts, p);
            continue;
        }

        /* attribute: #[...] or #![...] */
        if (c == '#' && p + 1 < end &&
            (*(p + 1) == '[' ||
             (*(p + 1) == '!' && p + 2 < end && *(p + 2) == '['))) {
            const char *ts = p;
            int depth = 0;
            while (p < end) {
                if (*p == '[')       { depth++; p++; }
                else if (*p == ']')  { depth--; p++; if (depth <= 0) break; }
                else if (*p == '\n') break;
                else                   p++;
            }
            RUST_SPAN("esh-p", ts, p);
            continue;
        }

        /* raw byte string: br"..." or br#"..."# */
        if (c == 'b' && p + 1 < end && *(p + 1) == 'r') {
            const char *rp = p + 2;
            int hashes = 0;
            while (rp < end && *rp == '#') { hashes++; rp++; }
            if (rp < end && *rp == '"') {
                const char *ts = p;
                rp++;
                while (rp < end) {
                    if (*rp == '"') {
                        const char *cp = rp + 1;
                        int h = 0;
                        while (h < hashes && cp < end && *cp == '#') { h++; cp++; }
                        if (h == hashes) { rp = cp; break; }
                    }
                    rp++;
                }
                RUST_SPAN("esh-s", ts, rp);
                continue;
            }
        }

        /* byte string: b"..." */
        if (c == 'b' && p + 1 < end && *(p + 1) == '"') {
            const char *ts = p;
            p += 2;
            while (p < end && *p != '"') {
                if (*p == '\\') { p++; if (p < end) p++; continue; }
                p++;
            }
            if (p < end) p++;
            RUST_SPAN("esh-s", ts, p);
            continue;
        }

        /* byte char: b'.' */
        if (c == 'b' && p + 1 < end && *(p + 1) == '\'') {
            const char *ts = p;
            p += 2;
            while (p < end && *p != '\'') {
                if (*p == '\\') { p++; if (p < end) p++; continue; }
                if (*p == '\n') break;
                p++;
            }
            if (p < end && *p == '\'') p++;
            RUST_SPAN("esh-s", ts, p);
            continue;
        }

        /* raw string: r"..." or r#"..."# */
        if (c == 'r') {
            const char *rp = p + 1;
            int hashes = 0;
            while (rp < end && *rp == '#') { hashes++; rp++; }
            if (rp < end && *rp == '"') {
                const char *ts = p;
                rp++;
                while (rp < end) {
                    if (*rp == '"') {
                        const char *cp = rp + 1;
                        int h = 0;
                        while (h < hashes && cp < end && *cp == '#') { h++; cp++; }
                        if (h == hashes) { rp = cp; break; }
                    }
                    rp++;
                }
                RUST_SPAN("esh-s", ts, rp);
                continue;
            }
        }

        /* regular DQ string "..." */
        if (c == '"') {
            const char *ts = p++;
            while (p < end && *p != '"') {
                if (*p == '\\') { p++; if (p < end) p++; continue; }
                p++;
            }
            if (p < end) p++;
            RUST_SPAN("esh-s", ts, p);
            continue;
        }

        /* char literal '.' or lifetime 'a */
        if (c == '\'') {
            if (eshu_hl_rust_is_lifetime(p, end)) {
                /* lifetime annotation: highlight as builtin */
                const char *ts = p++;
                while (p < end && (isalnum((unsigned char)*p) || *p == '_')) p++;
                RUST_SPAN("esh-b", ts, p);
                continue;
            }
            const char *ts = p++;
            while (p < end && *p != '\'') {
                if (*p == '\\') { p++; if (p < end) p++; continue; }
                if (*p == '\n') break;
                p++;
            }
            if (p < end && *p == '\'') p++;
            RUST_SPAN("esh-s", ts, p);
            continue;
        }

        /* number: 0x, 0b, 0o, decimal, float */
        if (isdigit((unsigned char)c) ||
            (c == '.' && p + 1 < end && isdigit((unsigned char)*(p + 1)))) {
            const char *ts = p;
            if (c == '0' && p + 1 < end) {
                char nx = *(p + 1);
                if (nx == 'x' || nx == 'X') {
                    p += 2;
                    while (p < end && (isxdigit((unsigned char)*p) || *p == '_')) p++;
                } else if (nx == 'b' || nx == 'B') {
                    p += 2;
                    while (p < end && (*p == '0' || *p == '1' || *p == '_')) p++;
                } else if (nx == 'o' || nx == 'O') {
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
            RUST_SPAN("esh-n", ts, p);
            continue;
        }

        /* identifier / keyword / builtin / macro */
        if (eshu_hl_isalpha_(c)) {
            const char *ts = p;
            while (p < end && eshu_hl_isalnum_(*p)) p++;
            /* check for macro call: identifier followed by '!' */
            int is_macro = (p < end && *p == '!' &&
                            !(p + 1 < end && *(p + 1) == '='));
            eshu_hl_flush(&out, plain, ts);
            plain = p;
            if (eshu_hl_kw(ts, (size_t)(p - ts), eshu_hl_rust_kw)) {
                eshu_hl_span(&out, "esh-k", ts, p);
            } else if (eshu_hl_kw(ts, (size_t)(p - ts), eshu_hl_rust_bi) || is_macro) {
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

#undef RUST_SPAN
}

#endif /* ESHU_RUST_H */
