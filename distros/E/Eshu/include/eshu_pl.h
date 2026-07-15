/*
 * eshu_pl.h — Perl language indentation scanner
 *
 * Tracks {} () [] nesting depth while skipping strings, heredocs,
 * regex, qw/qq/q constructs, pod sections, and comments.
 * Rewrites leading whitespace only.
 */

#ifndef ESHU_PL_H
#define ESHU_PL_H

#include "eshu.h"

#define ESHU_PL_HEREDOC_MAX  64   /* max length of heredoc terminator */
#define ESHU_PL_QDEPTH_MAX   8   /* max nesting depth for paired delims */

/* ══════════════════════════════════════════════════════════════════
 *  Scanner context — persists across lines
 * ══════════════════════════════════════════════════════════════════ */

typedef struct {
	int             depth;          /* brace/paren/bracket nesting  */
	enum eshu_state state;          /* current scanner state        */
	eshu_config_t   cfg;

	/* Heredoc tracking */
	char            heredoc_tag[ESHU_PL_HEREDOC_MAX];
	int             heredoc_tag_len;
	int             heredoc_indented;  /* <<~ variant */
	int             heredoc_pending;   /* heredoc detected, body starts next line */

	/* Quoted construct tracking (qw, qq, q, s, tr, y, m) */
	char            q_open;         /* opening delimiter */
	char            q_close;        /* closing delimiter (0 for non-paired) */
	int             q_depth;        /* nesting depth for paired delimiters */
	int             q_sections;     /* remaining sections (2 for s///, 1 for others) */

	/* Regex tracking */
	char            rx_delim;       /* regex delimiter char */

	/* Track whether last significant token could precede division */
	int             last_was_value; /* 1 if last token was var/number/)/] */

	/* POD buffering */
	eshu_buf_t      pod_buf;
	int             pod_active;

	/* __END__ / __DATA__ — everything after is non-code */
	int             past_end;

	/* Paren suppression: when ( and { appear on the same line
	 * (e.g. method(sub {), the ( doesn't add structural indent.
	 * Track suppressed ( so matching ) doesn't decrement depth. */
	int             suppressed_parens;

	/* Per-line delta tracking for suppression detection */
	int             line_paren_delta;
	int             line_brace_delta;
	int             line_bracket_delta;
} eshu_pl_ctx_t;

static void eshu_pl_ctx_init(eshu_pl_ctx_t *ctx, const eshu_config_t *cfg) {
	ctx->depth           = 0;
	ctx->state           = ESHU_CODE;
	ctx->cfg             = *cfg;
	ctx->heredoc_tag[0]  = '\0';
	ctx->heredoc_tag_len = 0;
	ctx->heredoc_indented = 0;
	ctx->heredoc_pending = 0;
	ctx->q_open          = 0;
	ctx->q_close         = 0;
	ctx->q_depth         = 0;
	ctx->q_sections      = 0;
	ctx->rx_delim        = 0;
	ctx->last_was_value  = 0;
	eshu_buf_init(&ctx->pod_buf, 256);
	ctx->pod_active      = 0;
	ctx->past_end        = 0;
	ctx->suppressed_parens  = 0;
	ctx->line_paren_delta   = 0;
	ctx->line_brace_delta   = 0;
	ctx->line_bracket_delta = 0;
}

/* ══════════════════════════════════════════════════════════════════
 *  Delimiter helpers
 * ══════════════════════════════════════════════════════════════════ */

static char eshu_pl_matching_close(char open) {
	switch (open) {
	case '(': return ')';
	case '{': return '}';
	case '[': return ']';
	case '<': return '>';
	default:  return 0; /* non-paired: same char closes */
	}
}

static int eshu_pl_is_paired(char c) {
	return c == '(' || c == '{' || c == '[' || c == '<';
}

/* ══════════════════════════════════════════════════════════════════
 *  Heredoc detection
 *
 *  Recognises:  <<EOF  <<'EOF'  <<"EOF"  <<~EOF  <<~'EOF'  <<~"EOF"
 *  Sets heredoc_pending=1 so the NEXT line enters heredoc state.
 * ══════════════════════════════════════════════════════════════════ */

static int eshu_pl_detect_heredoc(eshu_pl_ctx_t *ctx,
                                  const char *p, const char *end) {
	const char *start;
	int indented = 0;
	char quote = 0;
	int len;

	/* p points to the first '<' — we need "<<" */
	if (p + 1 >= end || *(p + 1) != '<')
		return 0;
	p += 2;

	/* optional ~ for indented heredoc */
	if (p < end && *p == '~') {
		indented = 1;
		p++;
	}

	/* optional quote */
	if (p < end && (*p == '\'' || *p == '"' || *p == '`')) {
		quote = *p;
		p++;
	}

	/* identifier */
	start = p;
	while (p < end && (isalnum((unsigned char)*p) || *p == '_'))
		p++;
	len = (int)(p - start);
	if (len == 0 || len >= ESHU_PL_HEREDOC_MAX)
		return 0;

	/* closing quote must match */
	if (quote && (p >= end || *p != quote))
		return 0;

	memcpy(ctx->heredoc_tag, start, len);
	ctx->heredoc_tag[len]  = '\0';
	ctx->heredoc_tag_len   = len;
	ctx->heredoc_indented  = indented;
	ctx->heredoc_pending   = 1;

	return 1;
}

/* ══════════════════════════════════════════════════════════════════
 *  Check if line is a heredoc terminator
 * ══════════════════════════════════════════════════════════════════ */

static int eshu_pl_is_heredoc_end(const eshu_pl_ctx_t *ctx,
                                  const char *line, const char *eol) {
	const char *p = line;
	int len;

	/* for <<~ the terminator may be indented */
	if (ctx->heredoc_indented) {
		while (p < eol && (*p == ' ' || *p == '\t'))
			p++;
	}

	len = (int)(eol - p);
	/* terminator may have trailing ; or whitespace but we'll be strict:
	   the line content (trimmed) must exactly match the tag */
	if (len < ctx->heredoc_tag_len)
		return 0;

	if (memcmp(p, ctx->heredoc_tag, ctx->heredoc_tag_len) != 0)
		return 0;

	/* rest of line must be empty or just whitespace/semicolons */
	p += ctx->heredoc_tag_len;
	while (p < eol) {
		if (*p != ' ' && *p != '\t' && *p != ';')
			return 0;
		p++;
	}
	return 1;
}

/* ══════════════════════════════════════════════════════════════════
 *  Pod detection — "=word" at start of line
 * ══════════════════════════════════════════════════════════════════ */

static int eshu_pl_is_pod_start(const char *content, const char *eol) {
	if (*content != '=')
		return 0;
	/* must be followed by a letter */
	if (content + 1 >= eol || !isalpha((unsigned char)content[1]))
		return 0;
	/* must NOT be =cut */
	if (eol - content >= 4 && memcmp(content, "=cut", 4) == 0)
		return 0;
	return 1;
}

static int eshu_pl_is_pod_end(const char *content, const char *eol) {
	int len = (int)(eol - content);
	if (len < 4) return 0;
	if (memcmp(content, "=cut", 4) != 0) return 0;
	/* rest should be whitespace or EOL */
	if (len > 4 && content[4] != ' ' && content[4] != '\t')
		return 0;
	return 1;
}

/* ══════════════════════════════════════════════════════════════════
 *  Classify whether a preceding context expects regex or division
 *
 *  Returns 1 if the next '/' should be treated as regex opening.
 * ══════════════════════════════════════════════════════════════════ */

static int eshu_pl_expects_regex(const eshu_pl_ctx_t *ctx) {
	/*
	 * If last token was a "value" (variable, number, closing bracket/paren)
	 * then / is division. Otherwise it's regex.
	 */
	return !ctx->last_was_value;
}

/* ══════════════════════════════════════════════════════════════════
 *  Enter a quoted construct (q/qq/qw/qx/s/tr/y/m)
 *
 *  p points to the character AFTER the keyword letter(s).
 *  Returns the number of chars consumed for the delimiter.
 * ══════════════════════════════════════════════════════════════════ */

static int eshu_pl_enter_quoted(eshu_pl_ctx_t *ctx, char delim,
                                int sections, enum eshu_state state) {
	ctx->q_open     = delim;
	ctx->q_sections = sections;
	if (eshu_pl_is_paired(delim)) {
		ctx->q_close = eshu_pl_matching_close(delim);
		ctx->q_depth = 1;
	} else {
		ctx->q_close = delim;
		ctx->q_depth = 0; /* non-paired don't nest */
	}
	ctx->state = state;
	return 1; /* consumed the delimiter char */
}

/* ══════════════════════════════════════════════════════════════════
 *  Try to detect q/qq/qw/qx/s/tr/y/m constructs
 *
 *  p points to a char that may be q, s, t, m, y.
 *  Returns chars consumed (including keyword + delimiter) or 0.
 * ══════════════════════════════════════════════════════════════════ */

static int eshu_pl_try_q_construct(eshu_pl_ctx_t *ctx,
                                   const char *p, const char *end) {
	const char *start = p;
	char c = *p;
	int sections = 1;
	enum eshu_state st = ESHU_Q;

	if (c == 'q') {
		p++;
		if (p < end && *(p) == 'w') {
			p++; st = ESHU_QW;
		} else if (p < end && *(p) == 'q') {
			p++; st = ESHU_QQ;
		} else if (p < end && *(p) == 'x') {
			p++; st = ESHU_QQ; /* qx behaves like qq */
		} else if (p < end && *(p) == 'r') {
			p++; st = ESHU_QQ; /* qr// behaves like qq for scanning */
		} else {
			st = ESHU_Q;
		}
	} else if (c == 's') {
		p++;
		sections = 2;
		st = ESHU_QQ; /* s/// — two sections, interpolates */
	} else if (c == 't' && p + 1 < end && *(p + 1) == 'r') {
		p += 2;
		sections = 2;
		st = ESHU_QQ;
	} else if (c == 'y') {
		p++;
		sections = 2;
		st = ESHU_QQ;
	} else if (c == 'm') {
		p++;
		st = ESHU_QQ; /* m// uses same delimiter tracking as qq */
	} else {
		return 0;
	}

	/* Must be followed by a non-alnum delimiter */
	if (p >= end)
		return 0;
	if (isalnum((unsigned char)*p) || *p == '_')
		return 0;
	if (*p == ' ' || *p == '\t' || *p == '\n')
		return 0;

	eshu_pl_enter_quoted(ctx, *p, sections, st);
	p++;
	return (int)(p - start);
}

/* Check if the character before position p is a word character
 * (to prevent matching 'eq' as 'q' construct, etc.) */
static int eshu_pl_preceded_by_word(const char *line_start, const char *p) {
	if (p <= line_start)
		return 0;
	return isalnum((unsigned char)*(p - 1)) || *(p - 1) == '_';
}

/* ══════════════════════════════════════════════════════════════════
 *  Scan a line for nesting changes (Perl-aware)
 *
 *  Called AFTER the line has been emitted. Updates ctx->state
 *  and ctx->depth for the next line.
 * ══════════════════════════════════════════════════════════════════ */

static void eshu_pl_scan_line(eshu_pl_ctx_t *ctx,
                              const char *p, const char *end) {
	const char *line_start = p;

	while (p < end) {
		char c = *p;

		switch (ctx->state) {
		case ESHU_CODE:
			if (c == '{' || c == '(' || c == '[') {
				ctx->depth++;
				if (c == '(') ctx->line_paren_delta++;
				else if (c == '{') ctx->line_brace_delta++;
				else ctx->line_bracket_delta++;
				ctx->last_was_value = 0;
			} else if (c == '}' || c == ']') {
				ctx->depth--;
				if (ctx->depth < 0) ctx->depth = 0;
				if (c == '}') ctx->line_brace_delta--;
				else ctx->line_bracket_delta--;
				ctx->last_was_value = 1;
			} else if (c == ')') {
				if (ctx->line_paren_delta > 0) {
					/* closing a ( from this line — normal */
					ctx->line_paren_delta--;
					ctx->depth--;
					if (ctx->depth < 0) ctx->depth = 0;
				} else if (ctx->suppressed_parens > 0) {
					/* closing a suppressed ( — don't change depth */
					ctx->suppressed_parens--;
				} else {
					ctx->depth--;
					if (ctx->depth < 0) ctx->depth = 0;
				}
				ctx->last_was_value = 1;
			} else if (c == '"') {
				ctx->state = ESHU_STRING_DQ;
				ctx->last_was_value = 0;
			} else if (c == '\'') {
				ctx->state = ESHU_STRING_SQ;
				ctx->last_was_value = 0;
			} else if (c == '#') {
				/* line comment — skip rest */
				ctx->last_was_value = 0;
				return;
			} else if (c == '<' && eshu_pl_detect_heredoc(ctx, p, end)) {
				/* heredoc_pending is set; continue scanning rest of line */
				/* skip past the heredoc operator to avoid re-matching */
				p += 2; /* skip << */
				if (p < end && *p == '~') p++;
				if (p < end && (*p == '\'' || *p == '"' || *p == '`')) {
					char hq = *p; p++;
					while (p < end && *p != hq) p++;
					if (p < end) p++;
				} else {
					while (p < end && (isalnum((unsigned char)*p) || *p == '_'))
						p++;
				}
				ctx->last_was_value = 1;
				continue;
			} else if (c == '/' && eshu_pl_expects_regex(ctx)) {
				/* Check for // (defined-or) — not a regex even in regex context */
				if (p + 1 < end && *(p + 1) == '/') {
					/* // or //= — defined-or operator */
					p += 2;
					if (p < end && *p == '=') p++; /* //= */
					ctx->last_was_value = 0;
					continue;
				}
				/* regex literal */
				ctx->rx_delim = '/';
				ctx->state = ESHU_REGEX;
				ctx->last_was_value = 0;
			} else if ((c == 'q' || c == 'm' || c == 's' || c == 'y' ||
			            (c == 't' && p + 1 < end && *(p + 1) == 'r')) &&
			           !eshu_pl_preceded_by_word(line_start, p) &&
			           !(p > line_start && *(p - 1) == '{')) {
				int consumed = eshu_pl_try_q_construct(ctx, p, end);
				if (consumed > 0) {
					p += consumed;
					ctx->last_was_value = 0;
					continue;
				}
				/* not a q-construct, fall through */
				if (isalnum((unsigned char)c))
					ctx->last_was_value = 0;
			} else if (c == '/' && !eshu_pl_expects_regex(ctx)) {
				/* division or // (defined-or) operator */
				if (p + 1 < end && *(p + 1) == '/') {
					p += 2;
					if (p < end && *p == '=') p++; /* //= */
					ctx->last_was_value = 0;
					continue;
				}
				ctx->last_was_value = 0;
			} else if (c == '$' || c == '@' || c == '%') {
				/* variable sigil — skip the variable name */
				ctx->last_was_value = 1;
				p++;
				/* $# is the "last index" operator: $#array, $#$ref */
				if (c == '$' && p < end && *p == '#') {
					p++;
					/* $#$ref or $#{ — skip the extra sigil */
					if (p < end && *p == '$')
						p++;
				}
				while (p < end && (isalnum((unsigned char)*p) || *p == '_' || *p == ':'))
					p++;
				continue;
			} else if (isdigit((unsigned char)c)) {
				ctx->last_was_value = 1;
				while (p < end && (isalnum((unsigned char)*p) || *p == '.' || *p == '_'))
					p++;
				continue;
			} else if (c == '=' && p + 1 < end && *(p + 1) == '~') {
				/* =~ forces next / to be regex */
				ctx->last_was_value = 0;
				p += 2;
				continue;
			} else if (c == '!' && p + 1 < end && *(p + 1) == '~') {
				ctx->last_was_value = 0;
				p += 2;
				continue;
			} else if (c == ' ' || c == '\t') {
				/* whitespace — don't change last_was_value */
			} else if (isalpha((unsigned char)c) || c == '_') {
				/* keyword or bareword — skip it */
				const char *ws = p;
				while (p < end && (isalnum((unsigned char)*p) || *p == '_'))
					p++;
				/* barewords ending in a value context: could be function call */
				ctx->last_was_value = 0;
				continue;
			} else {
				/* operator chars: = + - * etc */
				ctx->last_was_value = 0;
			}
			break;

		case ESHU_STRING_DQ:
			if (c == '\\' && p + 1 < end) {
				p++; /* skip escaped char */
			} else if (c == '"') {
				ctx->state = ESHU_CODE;
				ctx->last_was_value = 1;
			}
			break;

		case ESHU_STRING_SQ:
			if (c == '\\' && p + 1 < end) {
				p++; /* skip escaped char */
			} else if (c == '\'') {
				ctx->state = ESHU_CODE;
				ctx->last_was_value = 1;
			}
			break;

		case ESHU_REGEX:
			if (c == '\\' && p + 1 < end) {
				p++; /* skip escaped char */
			} else if (c == ctx->rx_delim) {
				ctx->state = ESHU_CODE;
				ctx->last_was_value = 1;
				/* skip optional flags */
				p++;
				while (p < end && isalpha((unsigned char)*p))
					p++;
				continue;
			}
			break;

		case ESHU_QW:
		case ESHU_QQ:
		case ESHU_Q:
			if (c == '\\' && p + 1 < end && ctx->state != ESHU_QW) {
				p++; /* skip escaped char (not in qw) */
			} else if (ctx->q_close != ctx->q_open) {
				/* paired delimiters — track nesting */
				if (c == ctx->q_open) {
					ctx->q_depth++;
				} else if (c == ctx->q_close) {
					ctx->q_depth--;
					if (ctx->q_depth == 0) {
						ctx->q_sections--;
						if (ctx->q_sections <= 0) {
							ctx->state = ESHU_CODE;
							ctx->last_was_value = 1;
							/* skip optional flags */
							p++;
							while (p < end && isalpha((unsigned char)*p))
								p++;
							continue;
						} else {
							/* next section: find new delimiter */
							p++;
							/* skip whitespace between sections */
							while (p < end && (*p == ' ' || *p == '\t'))
								p++;
							if (p < end) {
								eshu_pl_enter_quoted(ctx, *p,
									ctx->q_sections, ctx->state);
								p++; /* skip past opening delimiter */
							}
							continue;
						}
					}
				}
			} else {
				/* non-paired: same char opens and closes */
				if (c == ctx->q_close) {
					ctx->q_sections--;
					if (ctx->q_sections <= 0) {
						ctx->state = ESHU_CODE;
						ctx->last_was_value = 1;
						/* skip optional flags */
						p++;
						while (p < end && isalpha((unsigned char)*p))
							p++;
						continue;
					}
					/* next section uses same delimiter, just continue */
				}
			}
			break;

		/* States handled at line level, or not used by Perl scanner */
		default:
			return;
		}
		p++;
	}
}

/* ══════════════════════════════════════════════════════════════════
 *  Process a single Perl line — decide indent, emit, scan
 * ══════════════════════════════════════════════════════════════════ */

static void eshu_pl_process_line(eshu_pl_ctx_t *ctx, eshu_buf_t *out,
                                 const char *line_start, const char *eol) {
	const char *content = eshu_skip_leading_ws(line_start);
	int line_len;
	int indent_depth;

	/* ── Pod section: buffer and indent (before blank check!) ── */
	if (ctx->state == ESHU_POD) {
		if (content < eol && eshu_pl_is_pod_end(content, eol)) {
			/* Run buffered POD through the POD indenter */
			if (ctx->pod_buf.len > 0) {
				char *pod_result;
				size_t pod_out_len;
				eshu_buf_putc(&ctx->pod_buf, '\0');
				ctx->pod_buf.len--;
				pod_result = eshu_indent_pod(ctx->pod_buf.data, ctx->pod_buf.len, &ctx->cfg, &pod_out_len);
				eshu_buf_write(out, pod_result, (int)pod_out_len);
				free(pod_result);
			}
			ctx->pod_buf.len = 0;
			ctx->pod_active = 0;
			/* Emit =cut at column 0 */
			eshu_buf_write_trimmed(out, content, (int)(eol - content));
			eshu_buf_putc(out, '\n');
			ctx->state = ESHU_CODE;
		} else {
			/* Buffer this POD line (including blanks) */
			eshu_buf_write(&ctx->pod_buf, line_start, (int)(eol - line_start));
			eshu_buf_putc(&ctx->pod_buf, '\n');
		}
		return;
	}

	/* ── Heredoc body: pass through verbatim (before blank check!) ── */
	if (ctx->state == ESHU_HEREDOC || ctx->state == ESHU_HEREDOC_INDENT) {
		/* emit line exactly as-is */
		eshu_buf_write_trimmed(out, line_start, (int)(eol - line_start));
		eshu_buf_putc(out, '\n');

		/* check for terminator */
		if (eshu_pl_is_heredoc_end(ctx, line_start, eol)) {
			ctx->state = ESHU_CODE;
			ctx->heredoc_tag[0] = '\0';
			ctx->heredoc_tag_len = 0;
		}
		return;
	}

	/* empty line — preserve it */
	if (content >= eol) {
		eshu_buf_putc(out, '\n');
		return;
	}

	line_len = (int)(eol - content);

	/* ── Past __END__ / __DATA__: pass through verbatim ── */
	if (ctx->past_end) {
		/* Still detect POD starts within __END__ section */
		if (content == line_start && eshu_pl_is_pod_start(content, eol)) {
			ctx->state = ESHU_POD;
			ctx->pod_active = 1;
			eshu_buf_write(&ctx->pod_buf, content, (int)(eol - content));
			eshu_buf_putc(&ctx->pod_buf, '\n');
			return;
		}
		/* verbatim — don't change indentation */
		eshu_buf_write_trimmed(out, line_start, (int)(eol - line_start));
		eshu_buf_putc(out, '\n');
		return;
	}

	/* ── __END__ / __DATA__ detection ── */
	if (content == line_start &&
	    ((line_len >= 7 && memcmp(content, "__END__", 7) == 0 &&
	      (line_len == 7 || content[7] == ' ' || content[7] == '\t' || content[7] == '\r')) ||
	     (line_len >= 8 && memcmp(content, "__DATA__", 8) == 0 &&
	      (line_len == 8 || content[8] == ' ' || content[8] == '\t' || content[8] == '\r')))) {
		ctx->past_end = 1;
		eshu_buf_write_trimmed(out, content, line_len);
		eshu_buf_putc(out, '\n');
		return;
	}

	/* ── Pod start detection (= at column 0) ── */
	if (content == line_start && eshu_pl_is_pod_start(content, eol)) {
		ctx->state = ESHU_POD;
		ctx->pod_active = 1;
		/* Buffer the opening directive line */
		eshu_buf_write(&ctx->pod_buf, content, (int)(eol - content));
		eshu_buf_putc(&ctx->pod_buf, '\n');
		return;
	}

	/* ── Inside multi-line DQ/SQ string: preserve verbatim (re-indenting changes value) ── */
	if (ctx->state == ESHU_STRING_DQ || ctx->state == ESHU_STRING_SQ) {
		eshu_buf_write_trimmed(out, line_start, (int)(eol - line_start));
		eshu_buf_putc(out, '\n');
		eshu_pl_scan_line(ctx, content, eol);
		return;
	}

	/* ── Inside multi-line qq/q (string literals): preserve verbatim ── */
	if (ctx->state == ESHU_QQ || ctx->state == ESHU_Q) {
		eshu_buf_write_trimmed(out, line_start, (int)(eol - line_start));
		eshu_buf_putc(out, '\n');
		eshu_pl_scan_line(ctx, content, eol);
		return;
	}

	/* ── Inside multi-line qw/regex: indent at current depth+1 ── */
	if (ctx->state == ESHU_QW || ctx->state == ESHU_REGEX) {
		int qdepth = ctx->depth + 1;
		/* closing delimiter line gets same depth as opening line */
		if (ctx->q_close && *content == ctx->q_close)
			qdepth = ctx->depth;
		eshu_emit_indent(out, qdepth, &ctx->cfg);
		eshu_buf_write_trimmed(out, content, line_len);
		eshu_buf_putc(out, '\n');
		eshu_pl_scan_line(ctx, content, eol);
		return;
	}

	/* ── Normal Perl code ── */
	indent_depth = ctx->depth;

	/* If line starts with closer, dedent this line */
	if (*content == ')' && ctx->suppressed_parens > 0) {
		/* suppressed paren — don't dedent */
	} else if (*content == '}' || *content == ')' || *content == ']') {
		indent_depth--;
		if (indent_depth < 0) indent_depth = 0;
	}

	eshu_emit_indent(out, indent_depth, &ctx->cfg);
	eshu_buf_write_trimmed(out, content, line_len);
	eshu_buf_putc(out, '\n');

	/* scan for nesting changes */
	ctx->line_paren_delta   = 0;
	ctx->line_brace_delta   = 0;
	ctx->line_bracket_delta = 0;
	eshu_pl_scan_line(ctx, content, eol);

	/* Suppress unmatched ( when { or [ also opened on the same line.
	 * e.g. method(sub { or method([ — the ( is just call syntax,
	 * only the { or [ should add structural indentation. */
	if (ctx->line_paren_delta > 0 &&
	    (ctx->line_brace_delta > 0 || ctx->line_bracket_delta > 0)) {
		ctx->depth -= ctx->line_paren_delta;
		ctx->suppressed_parens += ctx->line_paren_delta;
	}

	/* If a heredoc was detected on this line, enter heredoc state now */
	if (ctx->heredoc_pending) {
		ctx->heredoc_pending = 0;
		ctx->state = ctx->heredoc_indented ? ESHU_HEREDOC_INDENT : ESHU_HEREDOC;
	}
}

/* ══════════════════════════════════════════════════════════════════
 *  Public API — indent a Perl source string
 * ══════════════════════════════════════════════════════════════════ */

static char * eshu_indent_pl(const char *src, size_t src_len,
                             const eshu_config_t *cfg, size_t *out_len) {
	eshu_pl_ctx_t ctx;
	eshu_buf_t out;
	const char *p   = src;
	const char *end = src + src_len;
	char *result;

	eshu_pl_ctx_init(&ctx, cfg);
	eshu_buf_init(&out, src_len + 256);

	{
		int line_num = 1;
		while (p < end) {
			const char *eol = eshu_find_eol(p);

			if (eshu_in_range(cfg, line_num)) {
				eshu_pl_process_line(&ctx, &out, p, eol);
			} else {
				size_t saved = out.len;
				eshu_pl_process_line(&ctx, &out, p, eol);
				out.len = saved;
				eshu_buf_write_trimmed(&out, p, (int)(eol - p));
				eshu_buf_putc(&out, '\n');
			}

			p = eol;
			if (*p == '\n') p++;
			line_num++;
		}
	}

	/* Flush any remaining buffered POD (no =cut at EOF) */
	if (ctx.pod_buf.len > 0) {
		char *pod_result;
		size_t pod_out_len;
		eshu_buf_putc(&ctx.pod_buf, '\0');
		ctx.pod_buf.len--;
		pod_result = eshu_indent_pod(ctx.pod_buf.data, ctx.pod_buf.len, &ctx.cfg, &pod_out_len);
		eshu_buf_write(&out, pod_result, (int)pod_out_len);
		free(pod_result);
	}
	eshu_buf_free(&ctx.pod_buf);

	/* NUL-terminate */
	eshu_buf_putc(&out, '\0');
	out.len--;

	*out_len = out.len;
	result = out.data;
	return result;
}


#include "eshu_hl_util.h"

/* ══════════════════════════════════════════════════════════════════
 *  Perl keyword list
 * ══════════════════════════════════════════════════════════════════ */

static const char * const eshu_hl_pl_kw[] = {
    "BEGIN", "END", "AUTOLOAD", "DESTROY",
    "abs", "accept", "alarm", "and", "atan2",
    "bind", "binmode", "bless",
    "caller", "chdir", "chmod", "chomp", "chop", "chown", "chr",
    "chroot", "close", "closedir", "connect", "cos", "crypt",
    "dbmclose", "dbmopen", "defined", "delete", "die", "do", "dump",
    "each", "else", "elsif", "endgrent", "endhostent", "endnetent",
    "endprotoent", "endpwent", "endservent", "eof", "eval", "exec",
    "exists", "exit", "exp",
    "fcntl", "fileno", "flock", "for", "foreach", "fork", "format",
    "formline",
    "getc", "getgrent", "getgrgid", "getgrnam", "gethostbyaddr",
    "gethostbyname", "gethostent", "getlogin", "getnetbyaddr",
    "getnetbyname", "getnetent", "getpeername", "getpgrp", "getppid",
    "getpriority", "getprotobyname", "getprotobynumber", "getprotoent",
    "getpwent", "getpwnam", "getpwuid", "getservbyname",
    "getservbyport", "getservent", "getsockname", "getsockopt",
    "given", "glob", "gmtime", "goto", "grep",
    "hex",
    "if", "import", "index", "int", "ioctl",
    "join",
    "keys", "kill",
    "last", "lc", "lcfirst", "length", "link", "listen", "local",
    "localtime", "log", "lstat",
    "m", "map", "mkdir", "msgctl", "msgget", "msgrcv", "msgsnd",
    "my",
    "next", "no",
    "oct", "open", "opendir", "or", "ord", "our",
    "pack", "package", "pipe", "pop", "pos", "print", "printf",
    "prototype", "push",
    "q", "qq", "qr", "quotemeta", "qw", "qx",
    "rand", "read", "readdir", "readline", "readlink", "readpipe",
    "recv", "redo", "ref", "rename", "require", "reset", "return",
    "reverse", "rewinddir", "rindex", "rmdir",
    "s", "say", "scalar", "seek", "seekdir", "select", "semctl",
    "semget", "semop", "send", "setgrent", "sethostent", "setnetent",
    "setpgrp", "setpriority", "setprotoent", "setpwent", "setservent",
    "setsockopt", "shift", "shmctl", "shmget", "shmread", "shmwrite",
    "shutdown", "sin", "sleep", "socket", "socketpair", "sort", "splice",
    "split", "sprintf", "sqrt", "srand", "stat", "state", "study", "sub",
    "substr", "symlink", "syscall", "sysopen", "sysread", "sysseek",
    "system", "syswrite",
    "tell", "telldir", "tie", "tied", "time", "times", "tr",
    "truncate",
    "uc", "ucfirst", "umask", "undef", "unless", "unlink", "unpack",
    "unshift", "untie", "until", "use", "utime",
    "values", "vec",
    "wait", "waitpid", "wantarray", "warn", "when", "while", "write",
    "y",
    NULL
};

/* ══════════════════════════════════════════════════════════════════
 *  Perl highlighter
 * ══════════════════════════════════════════════════════════════════ */

/* Paired delimiter map: ( → ), [ → ], { → }, < → > */
static char eshu_hl_paired(char open) {
    switch (open) {
    case '(': return ')';
    case '[': return ']';
    case '{': return '}';
    case '<': return '>';
    default:  return open;
    }
}

/* Scan past a quoted construct body using delimiter d_open/d_close.
 * p points to the first char after the opening delimiter.
 * Returns pointer past the closing delimiter. */
static const char *eshu_hl_pl_qbody(const char *p, const char *end,
                                     char d_open, char d_close) {
    int depth = 1;
    int is_paired = (d_open != d_close);
    while (p < end && depth > 0) {
        if (*p == '\\') { p++; if (p < end) p++; continue; }
        if (is_paired && *p == d_open)  { depth++; p++; continue; }
        if (*p == d_close) { depth--; p++; continue; }
        p++;
    }
    return p;
}

/* Detect whether '/' at p is a regex delimiter (vs division).
 * last_was_value: 1 if previous token was an rvalue (number, var, ')' etc.) */
static int eshu_hl_pl_is_regex(const char *src_start, const char *p,
                                int last_was_value) {
    (void)src_start;
    if (last_was_value) return 0;
    return 1;
}

/* Single special Perl variable chars after sigil (no alpha start) */
static int eshu_hl_pl_special_var(char c) {
    switch (c) {
    case '_': case '!': case '@': case '&': case '\'': case '"':
    case ';': case ',': case '\\': case '/': case '.': case '?':
    case '|': case '+': case '-': case '^': case '~': case '0':
    case '$': case '*': case '(': case ')': case '[': case '{':
    case '}': case '<': case '>': case '=': case '%': case '#':
        return 1;
    default:
        return isdigit((unsigned char)c);
    }
}

#define ESHU_HL_HEREDOC_MAX 64

static char *eshu_highlight_pl(const char *src, size_t src_len, size_t *out_len) {
    eshu_buf_t out;
    const char *p     = src;
    const char *end   = src + src_len;
    const char *plain = p;
    int last_val      = 0; /* last non-ws was rvalue-like */
    int past_end_data = 0; /* past __END__ / __DATA__ */
    int in_pod        = 0;
    char hd_tag[ESHU_HL_HEREDOC_MAX];
    int  hd_len       = 0;
    int  hd_pending   = 0; /* heredoc body starts on next line */
    int  at_bol       = 1;

    eshu_buf_init(&out, src_len * 2 + 64);

#define PL_SPAN(cls, ts, te) do { \
    eshu_hl_flush(&out, plain, (ts)); \
    eshu_hl_span(&out, (cls), (ts), (te)); \
    p = (te); plain = p; \
} while(0)

    while (p < end) {
        char c = *p;

        /* ── past __END__ / __DATA__: dump rest as comment ── */
        if (past_end_data) {
            PL_SPAN("esh-c", p, end);
            break;
        }

        /* ── POD block ── */
        if (in_pod) {
            /* POD ends at '=cut' at start of line */
            if (at_bol && p + 4 <= end && memcmp(p, "=cut", 4) == 0 &&
                (p + 4 >= end || *(p + 4) == '\n' || *(p + 4) == '\r' ||
                 *(p + 4) == ' ')) {
                const char *ts = p;
                while (p < end && *p != '\n') p++;
                if (p < end) p++;
                PL_SPAN("esh-d", ts, p);
                in_pod = 0;
                at_bol = 1;
            } else {
                const char *ts = p;
                while (p < end && *p != '\n') p++;
                if (p < end) p++;
                PL_SPAN("esh-d", ts, p);
                at_bol = 1;
            }
            continue;
        }

        /* ── heredoc body ── */
        if (hd_pending && at_bol) {
            /* check if this line is the terminator */
            if (hd_len > 0 && (size_t)(end - p) >= (size_t)hd_len &&
                memcmp(p, hd_tag, (size_t)hd_len) == 0 &&
                (p + hd_len >= end || *(p + hd_len) == '\n' ||
                 *(p + hd_len) == '\r')) {
                const char *ts = p;
                while (p < end && *p != '\n') p++;
                if (p < end) p++;
                PL_SPAN("esh-h", ts, p);
                hd_pending = 0;
                hd_len = 0;
                at_bol = 1;
            } else {
                const char *ts = p;
                while (p < end && *p != '\n') p++;
                if (p < end) p++;
                PL_SPAN("esh-h", ts, p);
                at_bol = 1;
            }
            continue;
        }

        /* ── POD start: '=word' at beginning of line ── */
        if (at_bol && c == '=') {
            const char *np = p + 1;
            if (np < end && isalpha((unsigned char)*np)) {
                /* check it's not '=~' operator */
                const char *ts = p;
                while (p < end && *p != '\n') p++;
                if (p < end) p++;
                PL_SPAN("esh-d", ts, p);
                in_pod = 1;
                at_bol = 1;
                continue;
            }
        }

        /* ── comment: '#' not inside anything ── */
        if (c == '#') {
            const char *ts = p;
            while (p < end && *p != '\n') p++;
            PL_SPAN("esh-c", ts, p);
            at_bol = 0;
            last_val = 0;
            continue;
        }

        /* ── heredoc start: << or <<~ ── */
        if (c == '<' && p + 1 < end && *(p + 1) == '<') {
            const char *ts = p;
            p += 2;
            int indented = 0;
            if (p < end && *p == '~') { indented = 1; p++; }
            /* optional quote around tag */
            char qchar = 0;
            if (p < end && (*p == '\'' || *p == '"' || *p == '`')) {
                qchar = *p++;
            }
            /* collect tag */
            const char *tag_start = p;
            while (p < end && *p != '\n' && *p != '\r' &&
                   (qchar ? *p != qchar : (isalnum((unsigned char)*p) || *p == '_')))
                p++;
            int tl = (int)(p - tag_start);
            if (tl > 0 && tl < ESHU_HL_HEREDOC_MAX) {
                memcpy(hd_tag, tag_start, (size_t)tl);
                hd_tag[tl] = '\0';
                hd_len = tl;
                hd_pending = 1;
            }
            if (qchar && p < end && *p == qchar) p++;
            /* the rest of the current line (after <<TAG) continues normally */
            /* emit the << token as plain; body will be highlighted next line */
            PL_SPAN("esh-h", ts, p);
            (void)indented;
            last_val = 1;
            continue;
        }

        /* ── __END__ / __DATA__ ── */
        if (at_bol && (
            (p + 7 <= end && memcmp(p, "__END__", 7) == 0 &&
             (p + 7 >= end || *(p + 7) == '\n' || *(p + 7) == '\r')) ||
            (p + 8 <= end && memcmp(p, "__DATA__", 8) == 0 &&
             (p + 8 >= end || *(p + 8) == '\n' || *(p + 8) == '\r')))) {
            /* consume the token line */
            const char *ts = p;
            while (p < end && *p != '\n') p++;
            if (p < end) p++;
            PL_SPAN("esh-k", ts, p);
            past_end_data = 1;
            at_bol = 1;
            continue;
        }

        /* ── string: "..." '...' `...` ── */
        if (c == '"' || c == '\'' || c == '`') {
            const char *ts = p++;
            while (p < end && *p != c) {
                if (*p == '\\') { p++; if (p < end) p++; continue; }
                p++;
            }
            if (p < end) p++;
            PL_SPAN("esh-s", ts, p);
            last_val = 1;
            at_bol = 0;
            continue;
        }

        /* ── number: digits ── */
        if (isdigit((unsigned char)c) ||
            (c == '.' && p + 1 < end && isdigit((unsigned char)*(p + 1)))) {
            const char *ts = p;
            if (c == '0' && p + 1 < end) {
                char nc = *(p + 1);
                if (nc == 'x' || nc == 'X') {
                    p += 2; while (p < end && isxdigit((unsigned char)*p)) p++;
                } else if (nc == 'b' || nc == 'B') {
                    p += 2; while (p < end && (*p == '0' || *p == '1')) p++;
                } else {
                    while (p < end && isdigit((unsigned char)*p)) p++;
                }
            } else {
                while (p < end && (isdigit((unsigned char)*p) || *p == '_')) p++;
                if (p < end && *p == '.') {
                    p++;
                    while (p < end && isdigit((unsigned char)*p)) p++;
                }
                if (p < end && (*p == 'e' || *p == 'E')) {
                    p++; if (p < end && (*p == '+' || *p == '-')) p++;
                    while (p < end && isdigit((unsigned char)*p)) p++;
                }
            }
            PL_SPAN("esh-n", ts, p);
            last_val = 1;
            at_bol = 0;
            continue;
        }

        /* ── variable sigil: $, @, % ── */
        if (c == '$' || c == '@' || c == '%') {
            const char *ts = p++;
            /* $# prefix (last-index-of) */
            if (c == '$' && p < end && *p == '#') {
                p++;
                if (p < end && eshu_hl_isalpha_(*p)) {
                    while (p < end && eshu_hl_isalnum_(*p)) p++;
                }
            } else if (p < end && eshu_hl_isalpha_(*p)) {
                while (p < end && eshu_hl_isalnum_(*p)) p++;
            } else if (p < end && eshu_hl_pl_special_var(*p)) {
                p++;
            } else if (p < end && *p == '{') {
                p++;
                while (p < end && *p != '}') p++;
                if (p < end) p++;
            }
            PL_SPAN("esh-v", ts, p);
            last_val = 1;
            at_bol = 0;
            continue;
        }

        /* ── regex / quoted-like starting with m, s, qw, qq, qr, q, tr, y ── */
        if ((c == 'm' || c == 's' || c == 'q' || c == 'y') &&
            (p + 1 >= end || !eshu_hl_isalnum_(*(p + 1)))) {
            /* single-char operator: m/./, s/../., q(.) etc. */
            const char *ts = p++;
            char d_open = (p < end) ? *p++ : '/';
            char d_close = eshu_hl_paired(d_open);
            p = eshu_hl_pl_qbody(p, end, d_open, d_close);
            if (c == 's' || c == 'y') {
                /* s and y always have a second section */
                if (d_open != d_close) {
                    /* paired delimiters: consume new opening delimiter */
                    if (p < end) {
                        d_open = *p++;
                        d_close = eshu_hl_paired(d_open);
                        p = eshu_hl_pl_qbody(p, end, d_open, d_close);
                    }
                } else {
                    /* same delimiter: second section starts immediately */
                    p = eshu_hl_pl_qbody(p, end, d_open, d_close);
                }
            }
            /* skip flags: gimsxpeodual etc. */
            while (p < end && isalpha((unsigned char)*p)) p++;
            PL_SPAN("esh-r", ts, p);
            last_val = 1;
            at_bol = 0;
            continue;
        }

        /* ── qw / qq / qr (multi-char) ── */
        if (c == 'q' && p + 1 < end &&
            (*(p + 1) == 'w' || *(p + 1) == 'q' || *(p + 1) == 'r' ||
             *(p + 1) == 'x') &&
            (p + 2 >= end || !eshu_hl_isalnum_(*(p + 2)))) {
            const char *ts = p;
            p += 2;
            char d_open = (p < end) ? *p++ : '(';
            char d_close = eshu_hl_paired(d_open);
            p = eshu_hl_pl_qbody(p, end, d_open, d_close);
            PL_SPAN("esh-r", ts, p);
            last_val = 1;
            at_bol = 0;
            continue;
        }

        /* ── tr/y (two-char) ── */
        if (((c == 't' && p + 1 < end && *(p + 1) == 'r') ||
             (c == 'y')) &&
            (p + (c == 'y' ? 1 : 2) >= end ||
             !eshu_hl_isalnum_(*(p + (c == 'y' ? 1 : 2))))) {
            const char *ts = p;
            p += (c == 'y') ? 1 : 2;
            char d_open = (p < end) ? *p++ : '/';
            char d_close = eshu_hl_paired(d_open);
            p = eshu_hl_pl_qbody(p, end, d_open, d_close);
            if (d_open == d_close) {
                /* same delimiter: second section starts immediately */
                p = eshu_hl_pl_qbody(p, end, d_open, d_close);
            } else {
                /* paired delimiters: consume opening delimiter of second section */
                if (p < end) {
                    d_open = *p++;
                    d_close = eshu_hl_paired(d_open);
                    p = eshu_hl_pl_qbody(p, end, d_open, d_close);
                }
            }
            while (p < end && isalpha((unsigned char)*p)) p++;
            PL_SPAN("esh-r", ts, p);
            last_val = 1;
            at_bol = 0;
            continue;
        }

        /* ── bare regex: / not preceded by rvalue ── */
        if (c == '/' && !last_val) {
            const char *ts = p++;
            while (p < end && *p != '/') {
                if (*p == '\\') { p++; if (p < end) p++; continue; }
                if (*p == '\n') { p = ts + 1; goto pl_not_regex; }
                p++;
            }
            if (p < end) p++;
            while (p < end && isalpha((unsigned char)*p)) p++;
            PL_SPAN("esh-r", ts, p);
            last_val = 1;
            at_bol = 0;
            continue;
        pl_not_regex:;
        }

        /* ── identifier or keyword ── */
        if (eshu_hl_isalpha_(c)) {
            const char *ts = p;
            while (p < end && eshu_hl_isalnum_(*p)) p++;
            eshu_hl_flush(&out, plain, ts);
            plain = p;
            size_t ilen = (size_t)(p - ts);
            if (eshu_hl_kw(ts, ilen, eshu_hl_pl_kw)) {
                eshu_hl_span(&out, "esh-k", ts, p);
                last_val = 0;
            } else {
                eshu_hl_write_html(&out, ts, ilen);
                last_val = 1;
            }
            at_bol = 0;
            continue;
        }

        /* ── track rvalue context ── */
        if (c == ')' || c == ']') last_val = 1;
        else if (c == '(' || c == ',' || c == ';' || c == '=' ||
                 c == '+' || c == '-' || c == '*' || c == '!' ||
                 c == '~' || c == ':' || c == '?' || c == '{' ||
                 c == '[' || c == '&' || c == '|' || c == '^')
            last_val = 0;

        if (c == '\n') { at_bol = 1; last_val = 0; }
        else if (c != ' ' && c != '\t') at_bol = 0;
        p++;
    }

    eshu_hl_flush(&out, plain, end);
    eshu_buf_putc(&out, '\0');
    *out_len = out.len - 1;
    return out.data;

#undef PL_SPAN
}

#endif /* ESHU_PL_H */
