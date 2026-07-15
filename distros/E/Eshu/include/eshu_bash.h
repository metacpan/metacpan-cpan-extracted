/*
 * eshu_bash.h — Bash/shell indentation scanner
 *
 * Handles keyword-pair blocks (if/fi, for/done, while/done, until/done,
 * case/esac, select/done, function/}), brace grouping { }, and heredocs.
 * Strings, comments, and $(...) subshells are tracked to avoid misidentifying
 * keywords inside quoted contexts.
 */

#ifndef ESHU_BASH_H
#define ESHU_BASH_H

#include "eshu.h"

#define ESHU_BASH_HEREDOC_MAX  64
#define ESHU_BASH_DEPTH_MAX    64

/* ══════════════════════════════════════════════════════════════════
 *  Scanner context — persists across lines
 * ══════════════════════════════════════════════════════════════════ */

typedef struct {
	int            depth;
	int            brace_depth;        /* { } grouping nesting           */
	int            subshell_depth;     /* $( ) nesting count             */
	int            arith_depth;        /* $(( )) arithmetic nesting      */
	int            bracket_depth;      /* [[ ]] or [ ] nesting           */
	/* case state */
	int            in_case;            /* 1 = inside case...esac         */
	int            case_depth;         /* depth at the 'case' keyword    */
	int            case_pat_open;      /* 1 = just opened a pattern body */
	/* heredoc state */
	char           heredoc_tag[ESHU_BASH_HEREDOC_MAX];
	int            heredoc_len;
	int            heredoc_strip;      /* 1 = <<-, strip leading tabs    */
	int            heredoc_pending;    /* 1 = body starts next line      */
	/* scanner state */
	enum eshu_state state;
	eshu_config_t  cfg;
} eshu_bash_ctx_t;

static void eshu_bash_ctx_init(eshu_bash_ctx_t *ctx, const eshu_config_t *cfg) {
	ctx->depth           = 0;
	ctx->brace_depth     = 0;
	ctx->subshell_depth  = 0;
	ctx->arith_depth     = 0;
	ctx->bracket_depth   = 0;
	ctx->in_case         = 0;
	ctx->case_depth      = 0;
	ctx->case_pat_open   = 0;
	ctx->heredoc_tag[0]  = '\0';
	ctx->heredoc_len     = 0;
	ctx->heredoc_strip   = 0;
	ctx->heredoc_pending = 0;
	ctx->state           = ESHU_CODE;
	ctx->cfg             = *cfg;
}

/* ══════════════════════════════════════════════════════════════════
 *  Helpers
 * ══════════════════════════════════════════════════════════════════ */

static int eshu_bash_isword(char c) {
	return isalnum((unsigned char)c) || c == '_';
}

/* Match a keyword token at p: keyword must end on a word boundary
 * (followed by whitespace, EOL, ';', '(', ')', '{', '}', '#', or NUL). */
static int eshu_bash_kw_match(const char *p, const char *end,
                              const char *kw, size_t klen) {
	if ((size_t)(end - p) < klen) return 0;
	if (memcmp(p, kw, klen) != 0) return 0;
	if (p + klen < end) {
		char nc = p[klen];
		if (eshu_bash_isword(nc)) return 0;
	}
	return 1;
}

/* Return 1 if p is at a word boundary start (preceded by whitespace, BOL,
 * ';', '|', '&', '(', '`', or NUL). Used to guard keyword detection. */
static int eshu_bash_at_word_start(const char *src, const char *p) {
	if (p == src) return 1;
	char prev = *(p - 1);
	return prev == ' ' || prev == '\t' || prev == ';' ||
	       prev == '|' || prev == '&'  || prev == '(' ||
	       prev == '`' || prev == '\n' || prev == '{';
}

/* Scan past the end of a $'...' ANSI-C quoted string.
 * p points just past the opening '. Returns pointer past closing '. */
static const char *eshu_bash_skip_ansi(const char *p, const char *end) {
	while (p < end && *p != '\'') {
		if (*p == '\\') { p++; if (p < end) p++; }
		else p++;
	}
	if (p < end) p++; /* consume closing ' */
	return p;
}

/* ══════════════════════════════════════════════════════════════════
 *  Heredoc tag extraction helper
 * ══════════════════════════════════════════════════════════════════ */

/* Called when we've seen '<<' (and optionally '-'). p points to the
 * character after the optional '-'. Extracts the tag into ctx, sets
 * heredoc_pending = 1.  Returns pointer past the tag (and closing quote
 * if quoted). */
static const char *eshu_bash_heredoc_start(eshu_bash_ctx_t *ctx,
                                            const char *p, const char *end) {
	char qchar = 0;
	const char *tag_start;
	int tl;

	if (p < end && (*p == '\'' || *p == '"' || *p == '`')) {
		qchar = *p++;
	}
	tag_start = p;
	while (p < end && *p != '\n' && *p != '\r' &&
	       (qchar ? *p != qchar : (isalnum((unsigned char)*p) || *p == '_')))
		p++;
	tl = (int)(p - tag_start);
	if (tl > 0 && tl < ESHU_BASH_HEREDOC_MAX) {
		memcpy(ctx->heredoc_tag, tag_start, (size_t)tl);
		ctx->heredoc_tag[tl] = '\0';
		ctx->heredoc_len     = tl;
		ctx->heredoc_pending = 1;
	}
	if (qchar && p < end && *p == qchar) p++;
	return p;
}

/* ══════════════════════════════════════════════════════════════════
 *  Per-line scanner: process one line of Bash, update ctx, emit
 * ══════════════════════════════════════════════════════════════════ */

/*
 * We scan token-by-token through the line content (with leading whitespace
 * already stripped) to:
 *   1. Detect keywords that open (+1) or close (-1) depth.
 *   2. Skip string/comment/subshell contexts so embedded keywords are ignored.
 *
 * We accumulate open/close deltas and apply them after line emission.
 *
 * Special logic:
 *   - Keywords that open a new block: 'then', 'do', 'function NAME {',
 *     standalone '{', and the implicit opener after 'repeat'.
 *   - Keywords that close a block: 'fi', 'done', 'esac', 'end' (not Bash,
 *     but guard anyway), and standalone '}'.
 *   - 'elif' and 'else': -1 before line, +1 after.
 *   - 'case EXPR in': +1 after.
 *   - 'esac': -1 before.
 *   - case pattern ')': track as pattern body opener (+1) inside case.
 *   - ';;'/';&'/';;&': case arm close, -1 then +0 (next arm will open).
 */

/* Returned from line scanner: how many levels to adjust before/after emit */
typedef struct {
	int pre;   /* apply to depth before emitting the line */
	int post;  /* apply to depth after emitting the line  */
} eshu_bash_delta_t;

static eshu_bash_delta_t eshu_bash_scan_line(eshu_bash_ctx_t *ctx,
                                              const char *content, int len)
{
	eshu_bash_delta_t d = {0, 0};
	const char *p   = content;
	const char *end = content + len;

	/* Skip shebang on first line — but ctx has no line counter, so we detect
	 * '#!' at position 0 with depth==0 as a no-op (comment branch covers it). */

	while (p < end) {
		char c = *p;

		/* single-quote string: '...' — no escapes except '' */
		if (c == '\'' && ctx->state == ESHU_CODE) {
			p++;
			while (p < end && *p != '\'') p++;
			if (p < end) p++;
			continue;
		}

		/* $'...' ANSI-C string */
		if (c == '$' && p + 1 < end && *(p + 1) == '\'' && ctx->state == ESHU_CODE) {
			p += 2;
			p = eshu_bash_skip_ansi(p, end);
			continue;
		}

		/* double-quoted string: "..." — contains $var, $(cmd), ${var} */
		if (c == '"' && ctx->state == ESHU_CODE) {
			p++;
			while (p < end && *p != '"') {
				if (*p == '\\') { p++; if (p < end) p++; }
				else p++;
			}
			if (p < end) p++;
			continue;
		}

		/* backtick command substitution: `...` */
		if (c == '`' && ctx->state == ESHU_CODE) {
			p++;
			while (p < end && *p != '`') {
				if (*p == '\\') { p++; if (p < end) p++; }
				else p++;
			}
			if (p < end) p++;
			continue;
		}

		/* comment: # to EOL — only when at a word boundary (not escaped) */
		if (c == '#' && ctx->state == ESHU_CODE &&
		    eshu_bash_at_word_start(content, p)) {
			break;
		}

		/* heredoc start: << or <<- */
		if (c == '<' && p + 1 < end && *(p + 1) == '<' && ctx->state == ESHU_CODE) {
			p += 2;
			ctx->heredoc_strip = 0;
			if (p < end && *p == '-') { ctx->heredoc_strip = 1; p++; }
			p = eshu_bash_heredoc_start(ctx, p, end);
			continue;
		}

		/* $(( )) arithmetic — track to avoid counting ) as closing */
		if (c == '$' && p + 1 < end && *(p + 1) == '(' &&
		    p + 2 < end && *(p + 2) == '(' && ctx->state == ESHU_CODE) {
			ctx->arith_depth++;
			p += 3;
			continue;
		}
		if (c == ')' && p + 1 < end && *(p + 1) == ')' && ctx->arith_depth > 0) {
			ctx->arith_depth--;
			p += 2;
			continue;
		}

		/* $( ) subshell — track so ) doesn't look like case pattern closer */
		if (c == '$' && p + 1 < end && *(p + 1) == '(' && ctx->state == ESHU_CODE) {
			ctx->subshell_depth++;
			p += 2;
			continue;
		}
		if (c == ')' && ctx->subshell_depth > 0) {
			ctx->subshell_depth--;
			p++;
			continue;
		}

		/* [[ ]] / [ ] arithmetic/test — track bracket depth */
		if (c == '[' && ctx->state == ESHU_CODE) {
			ctx->bracket_depth++;
			p++;
			continue;
		}
		if (c == ']' && ctx->bracket_depth > 0) {
			ctx->bracket_depth--;
			p++;
			continue;
		}

		/* ── Keyword detection: only at word-start positions ── */
		if (ctx->state == ESHU_CODE && ctx->bracket_depth == 0 &&
		    ctx->subshell_depth == 0 && ctx->arith_depth == 0 &&
		    eshu_bash_at_word_start(content, p)) {

			/* Keywords that pre-dedent: fi, done, esac, } */
			if (eshu_bash_kw_match(p, end, "fi",   2)) { d.pre--; p += 2; continue; }
			if (eshu_bash_kw_match(p, end, "done", 4)) { d.pre--; p += 4; continue; }
			if (eshu_bash_kw_match(p, end, "esac", 4)) {
				/* esac closes the case block and any open pattern body */
				if (ctx->in_case && ctx->case_pat_open) { d.pre -= 2; }
				else                                     { d.pre--;    }
				ctx->in_case = 0;
				ctx->case_pat_open = 0;
				p += 4;
				continue;
			}
			/* standalone } closes a brace group */
			if (c == '}' && ctx->brace_depth > 0) {
				ctx->brace_depth--;
				d.pre--;
				p++;
				continue;
			}

			/* Keywords that post-open: then, do */
			if (eshu_bash_kw_match(p, end, "then", 4)) { d.post++; p += 4; continue; }
			if (eshu_bash_kw_match(p, end, "do",   2)) { d.post++; p += 2; continue; }

			/* else / elif: -1 pre, +1 post (same depth as if/while body) */
			if (eshu_bash_kw_match(p, end, "elif", 4)) {
				d.pre--;        /* then on the same or next line provides post++ */
				p += 4; continue;
			}
			if (eshu_bash_kw_match(p, end, "else", 4)) {
				d.pre--; d.post++;
				p += 4; continue;
			}

			/* case EXPR in: post+1 to open case body */
			if (eshu_bash_kw_match(p, end, "case", 4)) {
				ctx->in_case    = 1;
				ctx->case_depth = ctx->depth + d.pre + d.post;
				ctx->case_pat_open = 0;
				/* 'in' will trigger the post+1 when we encounter it */
				p += 4; continue;
			}
			if (ctx->in_case && eshu_bash_kw_match(p, end, "in", 2)) {
				d.post++;
				p += 2; continue;
			}

			/* standalone { opens a brace group */
			if (c == '{' && (p + 1 >= end || *(p + 1) == ' ' ||
			    *(p + 1) == '\t' || *(p + 1) == '\n' ||
			    *(p + 1) == ';' || *(p + 1) == '#')) {
				ctx->brace_depth++;
				d.post++;
				p++;
				continue;
			}

			/* function keyword: 'function NAME' or 'NAME()' — the opening {
			 * will be caught by the standalone { branch above when it appears
			 * on the same or next line. */
			if (eshu_bash_kw_match(p, end, "function", 8)) {
				p += 8; continue; /* { handled separately */
			}
		}

		/* case arm: ')' at case body depth (not subshell, not [[ ]]) */
		if (c == ')' && ctx->in_case &&
		    ctx->bracket_depth == 0 && ctx->subshell_depth == 0 &&
		    ctx->arith_depth == 0) {
			if (ctx->case_pat_open) {
				/* close previous arm body before opening new one */
				d.pre--;
			}
			ctx->case_pat_open = 1;
			d.post++;  /* next lines are inside the pattern body */
			p++;
			continue;
		}

		/* ;; ;& ;;& — end of case arm body */
		if (c == ';' && p + 1 < end && *(p + 1) == ';' && ctx->in_case &&
		    ctx->subshell_depth == 0 && ctx->arith_depth == 0) {
			if (ctx->case_pat_open) {
				d.post--;  /* emit ;; at body depth, dedent after */
				ctx->case_pat_open = 0;
			}
			p += 2;
			/* consume optional & */
			if (p < end && *p == '&') p++;
			continue;
		}

		p++;
	}

	return d;
}

/* ══════════════════════════════════════════════════════════════════
 *  Main indentation entry point
 * ══════════════════════════════════════════════════════════════════ */

static char *eshu_indent_bash(const char *src, size_t src_len,
                               const eshu_config_t *cfg, size_t *out_len)
{
	eshu_bash_ctx_t ctx;
	eshu_buf_t      out;
	const char     *p     = src;
	const char     *end   = src + src_len;
	int             lineno = 1;

	eshu_bash_ctx_init(&ctx, cfg);
	eshu_buf_init(&out, src_len + 512);

	while (p < end) {
		const char *line_start = p;
		const char *eol;
		const char *content;
		int         content_len;
		int         is_blank;
		eshu_bash_delta_t delta;

		/* find end of line */
		eol = p;
		while (eol < end && *eol != '\n') eol++;

		content     = eshu_skip_leading_ws(p);
		content_len = (int)(eol - content);
		/* trim trailing whitespace for measurement */
		while (content_len > 0 &&
		       (content[content_len - 1] == ' ' ||
		        content[content_len - 1] == '\t'))
			content_len--;

		is_blank = (content_len == 0);

		/* ── heredoc body passthrough ── */
		if (ctx.heredoc_pending) {
			/* check if this line is the terminator */
			const char *chk = p;
			if (ctx.heredoc_strip) {
				while (chk < eol && *chk == '\t') chk++;
			}
			if (ctx.heredoc_len > 0 &&
			    (size_t)(eol - chk) == (size_t)ctx.heredoc_len &&
			    memcmp(chk, ctx.heredoc_tag, (size_t)ctx.heredoc_len) == 0) {
				/* terminator line: emit verbatim, clear heredoc */
				eshu_buf_write(&out, p, (size_t)(eol - p));
				if (eol < end) { eshu_buf_putc(&out, '\n'); eol++; }
				ctx.heredoc_pending = 0;
				ctx.heredoc_len     = 0;
				p = eol;
				lineno++;
				continue;
			} else {
				/* heredoc body: emit verbatim */
				eshu_buf_write(&out, p, (size_t)(eol - p));
				if (eol < end) { eshu_buf_putc(&out, '\n'); eol++; }
				p = eol;
				lineno++;
				continue;
			}
		}

		/* ── blank line: preserve, no indent change ── */
		if (is_blank) {
			if (eol < end) eshu_buf_putc(&out, '\n');
			p = (eol < end) ? eol + 1 : eol;
			lineno++;
			continue;
		}

		/* ── scan line for depth deltas ── */
		delta = eshu_bash_scan_line(&ctx, content, content_len);

		/* ── apply pre-delta, clamp depth ── */
		ctx.depth += delta.pre;
		if (ctx.depth < 0) ctx.depth = 0;

		/* ── emit (only if in range) ── */
		if (eshu_in_range(cfg, lineno)) {
			eshu_emit_indent(&out, ctx.depth, cfg);
		} else {
			/* out-of-range: preserve original leading whitespace */
			eshu_buf_write(&out, line_start, (size_t)(content - line_start));
		}

		/* emit trimmed content */
		eshu_buf_write_trimmed(&out, content, (int)(eol - content));
		if (eol < end) eshu_buf_putc(&out, '\n');

		/* ── apply post-delta ── */
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
 *  Bash keyword and builtin lists
 * ══════════════════════════════════════════════════════════════════ */

static const char * const eshu_hl_bash_kw[] = {
    "break", "case", "continue", "do", "done", "elif", "else",
    "esac", "eval", "exit", "export", "false", "fi", "for",
    "function", "if", "in", "local", "readonly", "return",
    "select", "set", "shift", "source", "then", "trap",
    "true", "typeset", "unset", "until", "while",
    NULL
};

static const char * const eshu_hl_bash_bi[] = {
    "alias", "awk", "basename", "cat", "cd", "chmod", "chown",
    "cp", "cut", "date", "declare", "dirname", "echo", "exec",
    "find", "getopts", "grep", "head", "kill", "ln", "ls",
    "mkdir", "mktemp", "mv", "printf", "pwd", "read", "rm",
    "rmdir", "sed", "sleep", "sort", "tail", "test", "touch",
    "tr", "uniq", "wc", "xargs",
    NULL
};

/* ══════════════════════════════════════════════════════════════════
 *  Bash highlighter
 * ══════════════════════════════════════════════════════════════════ */

static char *eshu_highlight_bash(const char *src, size_t src_len, size_t *out_len) {
    eshu_buf_t  out;
    const char *p     = src;
    const char *end   = src + src_len;
    const char *plain = p;
    int         at_bol = 1;

    eshu_buf_init(&out, src_len * 2 + 64);

#define BASH_SPAN(cls, ts, te) do { \
    eshu_hl_flush(&out, plain, (ts)); \
    eshu_hl_span(&out, (cls), (ts), (te)); \
    p = (te); plain = p; \
} while(0)

    while (p < end) {
        char c = *p;

        /* comment: # to EOL */
        if (c == '#') {
            const char *ts = p;
            while (p < end && *p != '\n') p++;
            BASH_SPAN("esh-c", ts, p);
            at_bol = 0;
            continue;
        }

        /* heredoc start: <<[-] — highlight operator, body emitted as plain later */
        if (c == '<' && p + 1 < end && *(p + 1) == '<') {
            const char *ts = p;
            p += 2;
            if (p < end && *p == '-') p++;
            /* consume optional quote and tag name */
            char qc = 0;
            if (p < end && (*p == '\'' || *p == '"' || *p == '`')) qc = *p++;
            while (p < end && *p != '\n' && *p != '\r' &&
                   (qc ? *p != qc : (isalnum((unsigned char)*p) || *p == '_')))
                p++;
            if (qc && p < end && *p == qc) p++;
            BASH_SPAN("esh-h", ts, p);
            at_bol = 0;
            continue;
        }

        /* $'...' ANSI-C quoted string */
        if (c == '$' && p + 1 < end && *(p + 1) == '\'') {
            const char *ts = p;
            p += 2;
            while (p < end && *p != '\'') {
                if (*p == '\\') { p++; if (p < end) p++; }
                else p++;
            }
            if (p < end) p++;
            BASH_SPAN("esh-s", ts, p);
            at_bol = 0;
            continue;
        }

        /* double-quoted string "..." */
        if (c == '"') {
            const char *ts = p++;
            while (p < end && *p != '"') {
                if (*p == '\\') { p++; if (p < end) p++; }
                else p++;
            }
            if (p < end) p++;
            BASH_SPAN("esh-s", ts, p);
            at_bol = 0;
            continue;
        }

        /* single-quoted string '...' */
        if (c == '\'') {
            const char *ts = p++;
            while (p < end && *p != '\'') p++;
            if (p < end) p++;
            BASH_SPAN("esh-s", ts, p);
            at_bol = 0;
            continue;
        }

        /* variable: $VAR  ${VAR}  $#  $@  $?  $!  $$  $0-$9 */
        if (c == '$') {
            const char *ts = p++;
            if (p < end && *p == '{') {
                p++;
                while (p < end && *p != '}') p++;
                if (p < end) p++;
            } else if (p < end && (eshu_hl_isalpha_(*p))) {
                while (p < end && eshu_hl_isalnum_(*p)) p++;
            } else if (p < end && (*p == '#' || *p == '@' || *p == '?' ||
                                   *p == '!' || *p == '$' || *p == '*' ||
                                   *p == '-' || isdigit((unsigned char)*p))) {
                p++;
            }
            BASH_SPAN("esh-v", ts, p);
            at_bol = 0;
            continue;
        }

        /* number */
        if (isdigit((unsigned char)c)) {
            const char *ts = p;
            while (p < end && (isdigit((unsigned char)*p) || *p == '_')) p++;
            BASH_SPAN("esh-n", ts, p);
            at_bol = 0;
            continue;
        }

        /* identifier: keyword, builtin, or plain name */
        if (eshu_hl_isalpha_(c)) {
            const char *ts = p;
            while (p < end && (eshu_hl_isalnum_(*p) || *p == '-')) p++;
            /* distinguish: word followed by '=' is an assignment, not keyword */
            if (p < end && *p == '=') {
                /* plain: variable assignment LHS */
                at_bol = 0;
                continue;
            }
            eshu_hl_flush(&out, plain, ts);
            plain = p;
            size_t ilen = (size_t)(p - ts);
            if (eshu_hl_kw(ts, ilen, eshu_hl_bash_kw)) {
                eshu_hl_span(&out, "esh-k", ts, p);
            } else if (eshu_hl_kw(ts, ilen, eshu_hl_bash_bi)) {
                eshu_hl_span(&out, "esh-b", ts, p);
            } else {
                eshu_hl_write_html(&out, ts, ilen);
            }
            at_bol = 0;
            continue;
        }

        if (c == '\n') { at_bol = 1; }
        else if (c != ' ' && c != '\t') { at_bol = 0; }
        (void)at_bol;
        p++;
    }

    eshu_hl_flush(&out, plain, end);
    eshu_buf_putc(&out, '\0');
    *out_len = out.len - 1;
    return out.data;

#undef BASH_SPAN
}

#endif /* ESHU_BASH_H */
