/*
 * eshu_sql.h — SQL language indentation formatter
 *
 * SQL has no mandatory indentation; this pass applies conventional
 * clause-based formatting:
 *
 *   SELECT           ← depth 0
 *       col1,        ← depth 1
 *   FROM             ← depth 0
 *       table1       ← depth 1
 *   WHERE            ← depth 0
 *       cond = 1     ← depth 1
 *
 * Subqueries increase depth via `(` and decrease via `)`.
 * BEGIN/END blocks increase/decrease depth like braces.
 * CASE/WHEN/THEN/ELSE/END expressions are also tracked.
 *
 * Clause keywords that reset to depth 0 (within the current paren level):
 *   SELECT FROM WHERE JOIN (INNER/LEFT/RIGHT/FULL/CROSS JOIN) ON USING
 *   GROUP BY ORDER BY HAVING LIMIT OFFSET
 *   UNION INTERSECT EXCEPT
 *   INSERT INTO VALUES UPDATE SET DELETE
 *   RETURNING WITH
 *
 * String/identifier quoting handled so braces/parens inside strings
 * don't affect depth.
 */

#ifndef ESHU_SQL_H
#define ESHU_SQL_H

#include "eshu.h"
#include <string.h>
#include <ctype.h>

/* ══════════════════════════════════════════════════════════════════
 *  Context
 * ══════════════════════════════════════════════════════════════════ */

typedef struct {
	int             depth;         /* current indent depth               */
	int             paren_depth;   /* net unclosed ( ) subquery nesting  */
	int             begin_depth;   /* BEGIN/END block nesting            */
	int             case_depth;    /* CASE/END expression nesting        */
	int             clause_active; /* 1 = we just emitted a clause kw    */
	enum eshu_state state;
	char            dollar_tag[64];/* current $tag$ for dollar-quoting   */
	int             dollar_tag_len;
	eshu_config_t   cfg;
} eshu_sql_ctx_t;

static void eshu_sql_ctx_init(eshu_sql_ctx_t *ctx, const eshu_config_t *cfg) {
	memset(ctx, 0, sizeof(*ctx));
	ctx->state = ESHU_CODE;
	ctx->cfg   = *cfg;
}

/* ══════════════════════════════════════════════════════════════════
 *  Case-insensitive keyword helpers
 * ══════════════════════════════════════════════════════════════════ */

static int eshu_sql_ci_eq(const char *a, const char *b, int len) {
	int i;
	for (i = 0; i < len; i++) {
		char ca = (a[i] >= 'a' && a[i] <= 'z') ? a[i] - 32 : a[i];
		char cb = (b[i] >= 'a' && b[i] <= 'z') ? b[i] - 32 : b[i];
		if (ca != cb) return 0;
	}
	return 1;
}

/* Match keyword kw (len klen) at position p in content.
 * p must point to start of word; word must be followed by non-alnum. */
static int eshu_sql_kw_at(const char *p, const char *end,
                           const char *kw, int klen) {
	if (p + klen > end) return 0;
	if (!eshu_sql_ci_eq(p, kw, klen)) return 0;
	if (p + klen < end && (isalnum((unsigned char)p[klen]) || p[klen] == '_'))
		return 0;
	return 1;
}

/* Like eshu_sql_kw_at but also consume trailing whitespace and a second word.
 * e.g. "GROUP BY", "ORDER BY", "INSERT INTO", "DELETE FROM", "LEFT JOIN" */
static int eshu_sql_kw2_at(const char *p, const char *end,
                            const char *w1, int l1,
                            const char *w2, int l2,
                            int *total_len) {
	if (p + l1 >= end) return 0;
	if (!eshu_sql_ci_eq(p, w1, l1)) return 0;
	if (isalnum((unsigned char)p[l1]) || p[l1] == '_') return 0;
	const char *q = p + l1;
	while (q < end && (*q == ' ' || *q == '\t')) q++;
	if (q + l2 > end) return 0;
	if (!eshu_sql_ci_eq(q, w2, l2)) return 0;
	if (q + l2 < end && (isalnum((unsigned char)q[l2]) || q[l2] == '_'))
		return 0;
	*total_len = (int)(q + l2 - p);
	return 1;
}

/* ══════════════════════════════════════════════════════════════════
 *  Clause keyword detection at start of content
 *
 *  Returns:
 *    0  — not a top-level clause keyword
 *    1  — clause keyword at depth 0 (SELECT, FROM, WHERE, ...)
 *    2  — BEGIN keyword (open block)
 *    3  — END keyword (close block / CASE end)
 *    4  — CASE keyword (open case)
 * ══════════════════════════════════════════════════════════════════ */

#define SQL_KW1(w)     eshu_sql_kw_at(p, end, w, (int)sizeof(w)-1)
#define SQL_KW2(a,b)   eshu_sql_kw2_at(p, end, a, (int)sizeof(a)-1, b, (int)sizeof(b)-1, kw_len)

static int eshu_sql_classify_line(const char *p, const char *end, int *kw_len) {
	/* skip leading whitespace */
	while (p < end && (*p == ' ' || *p == '\t')) p++;
	if (p >= end) return 0;

	*kw_len = 0;

	/* BEGIN / END */
	if (SQL_KW1("BEGIN"))  { *kw_len = 5; return 2; }
	if (SQL_KW1("END"))    { *kw_len = 3; return 3; }
	if (SQL_KW1("CASE"))   { *kw_len = 4; return 4; }

	/* Multi-word clauses first (longer match wins) */
	if (SQL_KW2("GROUP","BY"))   return 1;
	if (SQL_KW2("ORDER","BY"))   return 1;
	if (SQL_KW2("INSERT","INTO")) return 1;
	if (SQL_KW2("DELETE","FROM")) return 1;
	if (SQL_KW2("LEFT","JOIN"))   return 1;
	if (SQL_KW2("RIGHT","JOIN"))  return 1;
	if (SQL_KW2("INNER","JOIN"))  return 1;
	if (SQL_KW2("FULL","JOIN"))   return 1;
	if (SQL_KW2("CROSS","JOIN"))  return 1;
	if (SQL_KW2("FULL","OUTER"))  return 1;

	/* Single-word clauses */
	if (SQL_KW1("SELECT"))    { *kw_len=6;  return 1; }
	if (SQL_KW1("FROM"))      { *kw_len=4;  return 1; }
	if (SQL_KW1("WHERE"))     { *kw_len=5;  return 1; }
	if (SQL_KW1("JOIN"))      { *kw_len=4;  return 1; }
	/* ON / USING are continuations of JOIN — not standalone clause resets */
	if (SQL_KW1("HAVING"))    { *kw_len=6;  return 1; }
	if (SQL_KW1("LIMIT"))     { *kw_len=5;  return 1; }
	if (SQL_KW1("OFFSET"))    { *kw_len=6;  return 1; }
	if (SQL_KW1("UNION"))     { *kw_len=5;  return 1; }
	if (SQL_KW1("INTERSECT")) { *kw_len=9;  return 1; }
	if (SQL_KW1("EXCEPT"))    { *kw_len=6;  return 1; }
	if (SQL_KW1("VALUES"))    { *kw_len=6;  return 1; }
	if (SQL_KW1("UPDATE"))    { *kw_len=6;  return 1; }
	if (SQL_KW1("SET"))       { *kw_len=3;  return 1; }
	if (SQL_KW1("RETURNING")) { *kw_len=9;  return 1; }
	if (SQL_KW1("WITH"))      { *kw_len=4;  return 1; }
	if (SQL_KW1("CREATE"))    { *kw_len=6;  return 1; }
	if (SQL_KW1("ALTER"))     { *kw_len=5;  return 1; }
	if (SQL_KW1("DROP"))      { *kw_len=4;  return 1; }
	if (SQL_KW1("TRUNCATE"))  { *kw_len=8;  return 1; }

	/* WHEN/THEN/ELSE inside CASE — dedent/same-level transitions */
	if (SQL_KW1("WHEN"))     { *kw_len=4;  return 5; }
	if (SQL_KW1("THEN"))     { *kw_len=4;  return 6; }
	if (SQL_KW1("ELSE"))     { *kw_len=4;  return 6; }

	return 0;
}

#undef SQL_KW1
#undef SQL_KW2

/* ══════════════════════════════════════════════════════════════════
 *  Scan a line for paren depth changes (outside strings/comments)
 * ══════════════════════════════════════════════════════════════════ */

static void eshu_sql_scan_parens(eshu_sql_ctx_t *ctx,
                                  const char *p, const char *end)
{
	while (p < end) {
		char c = *p;

		if (ctx->state == ESHU_SQL_COMMENT_BLOCK) {
			if (c == '*' && p+1 < end && *(p+1) == '/') {
				ctx->state = ESHU_CODE; p += 2;
			} else p++;
			continue;
		}
		if (ctx->state == ESHU_SQL_COMMENT_LINE) {
			/* handled by line end */
			p++; continue;
		}
		if (ctx->state == ESHU_SQL_STRING_SQ) {
			if (c == '\'' && p+1 < end && *(p+1) == '\'') { p += 2; continue; }
			if (c == '\'') { ctx->state = ESHU_CODE; }
			p++; continue;
		}
		if (ctx->state == ESHU_SQL_STRING_DQ) {
			if (c == '"') ctx->state = ESHU_CODE;
			p++; continue;
		}
		if (ctx->state == ESHU_SQL_IDENT_BT) {
			if (c == '`') ctx->state = ESHU_CODE;
			p++; continue;
		}
		if (ctx->state == ESHU_SQL_IDENT_BR) {
			if (c == ']') ctx->state = ESHU_CODE;
			p++; continue;
		}
		if (ctx->state == ESHU_SQL_DOLLAR_STR) {
			/* look for closing $tag$ */
			if (c == '$' && ctx->dollar_tag_len > 0) {
				int tl = ctx->dollar_tag_len;
				if (p + tl <= end &&
				    memcmp(p, ctx->dollar_tag, (size_t)tl) == 0) {
					ctx->state = ESHU_CODE;
					ctx->dollar_tag_len = 0;
					p += tl; continue;
				}
			}
			p++; continue;
		}

		/* ESHU_CODE */
		if (c == '-' && p+1 < end && *(p+1) == '-') {
			ctx->state = ESHU_SQL_COMMENT_LINE;
			return; /* rest of line is comment */
		}
		if (c == '/' && p+1 < end && *(p+1) == '*') {
			ctx->state = ESHU_SQL_COMMENT_BLOCK; p += 2; continue;
		}
		if (c == '\'') { ctx->state = ESHU_SQL_STRING_SQ; p++; continue; }
		if (c == '"')  { ctx->state = ESHU_SQL_STRING_DQ; p++; continue; }
		if (c == '`')  { ctx->state = ESHU_SQL_IDENT_BT;  p++; continue; }
		if (c == '[')  { ctx->state = ESHU_SQL_IDENT_BR;  p++; continue; }

		/* dollar-quoting: $tag$ or $$ */
		if (c == '$') {
			const char *q = p + 1;
			while (q < end && *q != '$' && *q != '\n') q++;
			if (q < end && *q == '$') {
				int tl = (int)(q - p + 1);
				if (tl < 64) {
					memcpy(ctx->dollar_tag, p, (size_t)tl);
					ctx->dollar_tag[tl] = '\0';
					ctx->dollar_tag_len = tl;
					ctx->state = ESHU_SQL_DOLLAR_STR;
					p = q + 1; continue;
				}
			}
		}

		if (c == '(') { ctx->paren_depth++; ctx->depth++; }
		if (c == ')') {
			ctx->paren_depth--;
			ctx->depth--;
			if (ctx->depth < 0) ctx->depth = 0;
		}
		p++;
	}
	/* end of line resets line-comment state */
	if (ctx->state == ESHU_SQL_COMMENT_LINE)
		ctx->state = ESHU_CODE;
}

/* ══════════════════════════════════════════════════════════════════
 *  Process one line
 * ══════════════════════════════════════════════════════════════════ */

static void eshu_sql_process_line(eshu_sql_ctx_t *ctx, eshu_buf_t *out,
                                   const char *line_start, const char *eol,
                                   int lineno)
{
	const char *content = eshu_skip_leading_ws(line_start);
	int line_len;
	int indent_depth;
	int kw_len = 0;
	int kw_class;

	/* empty line */
	if (content >= eol) {
		eshu_buf_putc(out, '\n');
		return;
	}
	line_len = (int)(eol - content);

	/* continuation of block comment or dollar-quoted string: emit verbatim */
	if (ctx->state == ESHU_SQL_COMMENT_BLOCK || ctx->state == ESHU_SQL_DOLLAR_STR) {
		if (eshu_in_range(&ctx->cfg, lineno)) {
			eshu_emit_indent(out, ctx->depth, &ctx->cfg);
			eshu_buf_write_trimmed(out, content, line_len);
		} else {
			eshu_buf_write(out, line_start, (size_t)(eol - line_start));
		}
		eshu_buf_putc(out, '\n');
		eshu_sql_scan_parens(ctx, content, eol);
		return;
	}

	/* Classify the first keyword on this line */
	kw_class = eshu_sql_classify_line(content, eol, &kw_len);

	switch (kw_class) {
	case 1: /* top-level clause keyword — emit at paren_depth */
		indent_depth = ctx->paren_depth;
		ctx->clause_active = 1;
		break;
	case 2: /* BEGIN */
		indent_depth = ctx->paren_depth + ctx->begin_depth;
		ctx->begin_depth++;
		ctx->clause_active = 0;
		break;
	case 3: /* END */
		if (ctx->case_depth > 0) {
			ctx->case_depth--;
			indent_depth = ctx->paren_depth + ctx->begin_depth + ctx->case_depth;
		} else if (ctx->begin_depth > 0) {
			ctx->begin_depth--;
			indent_depth = ctx->paren_depth + ctx->begin_depth;
		} else {
			indent_depth = ctx->paren_depth;
		}
		ctx->clause_active = 0;
		break;
	case 4: /* CASE */
		indent_depth = ctx->paren_depth + ctx->begin_depth + ctx->case_depth;
		ctx->case_depth++;
		ctx->clause_active = 0;
		break;
	case 5: /* WHEN — transition inside CASE, at case level */
		indent_depth = ctx->paren_depth + ctx->begin_depth +
		               (ctx->case_depth > 0 ? ctx->case_depth - 1 : 0) + 1;
		ctx->clause_active = 0;
		break;
	case 6: /* THEN/ELSE — same as WHEN position */
		indent_depth = ctx->paren_depth + ctx->begin_depth +
		               (ctx->case_depth > 0 ? ctx->case_depth - 1 : 0) + 1;
		ctx->clause_active = 0;
		break;
	default:
		/* closing paren at start of content */
		if (*content == ')') {
			eshu_sql_scan_parens(ctx, content, eol);
			indent_depth = ctx->paren_depth + ctx->begin_depth + ctx->case_depth;
			if (eshu_in_range(&ctx->cfg, lineno)) {
				eshu_emit_indent(out, indent_depth, &ctx->cfg);
			} else {
				eshu_buf_write(out, line_start, (size_t)(content - line_start));
			}
			eshu_buf_write_trimmed(out, content, line_len);
			eshu_buf_putc(out, '\n');
			ctx->clause_active = 0;
			return;
		}
		/* continuation line */
		indent_depth = ctx->paren_depth + ctx->begin_depth + ctx->case_depth
		               + (ctx->clause_active ? 1 : 0);
		break;
	}

	if (eshu_in_range(&ctx->cfg, lineno)) {
		eshu_emit_indent(out, indent_depth, &ctx->cfg);
	} else {
		eshu_buf_write(out, line_start, (size_t)(content - line_start));
	}
	eshu_buf_write_trimmed(out, content, line_len);
	eshu_buf_putc(out, '\n');

	{
		int old_paren = ctx->paren_depth;
		eshu_sql_scan_parens(ctx, content, eol);
		/* If a clause kw opened a net paren, the paren provides indentation */
		if (kw_class == 1 && ctx->paren_depth > old_paren)
			ctx->clause_active = 0;
	}
}

/* ══════════════════════════════════════════════════════════════════
 *  Public API
 * ══════════════════════════════════════════════════════════════════ */

static char *eshu_indent_sql(const char *src, size_t src_len,
                              const eshu_config_t *cfg, size_t *out_len)
{
	eshu_sql_ctx_t ctx;
	eshu_buf_t     out;
	const char    *p   = src;
	const char    *end = src + src_len;
	int            lineno = 1;

	eshu_sql_ctx_init(&ctx, cfg);
	eshu_buf_init(&out, src_len + 256);

	while (p < end) {
		const char *eol = eshu_find_eol(p);
		eshu_sql_process_line(&ctx, &out, p, eol, lineno);
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
 *  SQL keyword / builtin lists  (stored uppercase; matched case-insensitively)
 * ══════════════════════════════════════════════════════════════════ */

static const char * const eshu_hl_sql_kw[] = {
    /* DML */
    "SELECT", "FROM", "WHERE", "JOIN", "INNER", "LEFT", "RIGHT",
    "FULL", "OUTER", "CROSS", "ON", "USING",
    "GROUP", "BY", "HAVING", "ORDER", "LIMIT", "OFFSET",
    "UNION", "ALL", "INTERSECT", "EXCEPT",
    "INSERT", "INTO", "VALUES", "UPDATE", "SET", "DELETE",
    "RETURNING",
    /* DDL */
    "CREATE", "ALTER", "DROP", "TRUNCATE", "RENAME",
    "TABLE", "VIEW", "INDEX", "SEQUENCE", "SCHEMA",
    "COLUMN", "CONSTRAINT", "PRIMARY", "KEY", "FOREIGN",
    "REFERENCES", "UNIQUE", "CHECK", "DEFAULT", "NOT", "NULL",
    "AUTO_INCREMENT", "SERIAL", "IDENTITY",
    /* DQL / expressions */
    "AS", "DISTINCT", "EXISTS", "IN", "BETWEEN", "LIKE", "ILIKE",
    "IS", "AND", "OR", "CASE", "WHEN", "THEN", "ELSE", "END",
    "CAST", "COALESCE", "NULLIF", "WITH",
    /* procedural */
    "BEGIN", "DECLARE", "PROCEDURE", "FUNCTION",
    "TRIGGER", "IF", "ELSIF", "ELSEIF", "LOOP", "WHILE", "FOR",
    "RETURN", "RAISE", "EXCEPTION",
    NULL
};

static const char * const eshu_hl_sql_bi[] = {
    "COUNT", "SUM", "AVG", "MIN", "MAX",
    "UPPER", "LOWER", "TRIM", "LENGTH", "SUBSTR", "SUBSTRING",
    "REPLACE", "CONCAT",
    "NOW", "CURRENT_DATE", "CURRENT_TIME", "CURRENT_TIMESTAMP",
    "DATE_TRUNC", "DATE_PART", "EXTRACT",
    "TO_CHAR", "TO_DATE", "TO_NUMBER",
    "ROW_NUMBER", "RANK", "DENSE_RANK", "LEAD", "LAG",
    "FIRST_VALUE", "LAST_VALUE", "NTILE", "OVER", "PARTITION",
    NULL
};

/* Case-insensitive keyword lookup for SQL */
static int eshu_hl_sql_kw_match(const char *s, size_t n,
                                  const char * const *list) {
    size_t i;
    for (i = 0; list[i]; i++) {
        size_t klen = strlen(list[i]);
        if (klen != n) continue;
        size_t j;
        for (j = 0; j < n; j++) {
            char sc = s[j], kc = list[i][j];
            if (sc >= 'a' && sc <= 'z') sc -= 32;
            if (sc != kc) break;
        }
        if (j == n) return 1;
    }
    return 0;
}

/* ══════════════════════════════════════════════════════════════════
 *  SQL highlighter
 * ══════════════════════════════════════════════════════════════════ */

static char *eshu_highlight_sql(const char *src, size_t src_len, size_t *out_len) {
    eshu_buf_t  out;
    const char *p     = src;
    const char *end   = src + src_len;
    const char *plain = p;
    /* dollar-quoting tag */
    char        dtag[64];
    int         dtag_len = 0;
    int         in_dollar = 0;

    eshu_buf_init(&out, src_len * 2 + 64);

#define SQL_SPAN(cls, ts, te) do { \
    eshu_hl_flush(&out, plain, (ts)); \
    eshu_hl_span(&out, (cls), (ts), (te)); \
    p = (te); plain = p; \
} while(0)

    while (p < end) {
        char c = *p;

        /* dollar-quoted string */
        if (in_dollar) {
            if (c == '$' && dtag_len > 0 &&
                (size_t)(end - p) >= (size_t)dtag_len &&
                memcmp(p, dtag, (size_t)dtag_len) == 0) {
                p += dtag_len;
                SQL_SPAN("esh-s", plain, p);
                in_dollar = 0; dtag_len = 0;
                /* plain already reset by SQL_SPAN */
            } else {
                p++;
            }
            continue;
        }

        /* line comment -- */
        if (c == '-' && p+1 < end && *(p+1) == '-') {
            const char *ts = p;
            while (p < end && *p != '\n') p++;
            SQL_SPAN("esh-c", ts, p);
            continue;
        }

        /* block comment */
        if (c == '/' && p+1 < end && *(p+1) == '*') {
            const char *ts = p;
            p += 2;
            while (p+1 < end && !(*p == '*' && *(p+1) == '/')) p++;
            if (p+1 < end) p += 2;
            SQL_SPAN("esh-c", ts, p);
            continue;
        }

        /* single-quoted string '...' with '' escape */
        if (c == '\'') {
            const char *ts = p++;
            while (p < end) {
                if (*p == '\'' && p+1 < end && *(p+1) == '\'') { p += 2; continue; }
                if (*p == '\'') { p++; break; }
                p++;
            }
            SQL_SPAN("esh-s", ts, p);
            continue;
        }

        /* double-quoted identifier "..." */
        if (c == '"') {
            const char *ts = p++;
            while (p < end && *p != '"') p++;
            if (p < end) p++;
            SQL_SPAN("esh-a", ts, p);
            continue;
        }

        /* backtick identifier `...` (MySQL) */
        if (c == '`') {
            const char *ts = p++;
            while (p < end && *p != '`') p++;
            if (p < end) p++;
            SQL_SPAN("esh-a", ts, p);
            continue;
        }

        /* bracketed identifier [...] (T-SQL) */
        if (c == '[') {
            const char *ts = p++;
            while (p < end && *p != ']') p++;
            if (p < end) p++;
            SQL_SPAN("esh-a", ts, p);
            continue;
        }

        /* dollar-quoting: $tag$ or $$ */
        if (c == '$') {
            const char *q = p + 1;
            while (q < end && *q != '$' && *q != '\n') q++;
            if (q < end && *q == '$') {
                int tl = (int)(q - p + 1);
                if (tl < 64) {
                    /* start of dollar-quoted string — the opening tag is plain */
                    eshu_hl_flush(&out, plain, p);
                    plain = p;
                    memcpy(dtag, p, (size_t)tl);
                    dtag[tl] = '\0';
                    dtag_len = tl;
                    in_dollar = 1;
                    p = q + 1;
                    continue;
                }
            }
        }

        /* number */
        if (isdigit((unsigned char)c) ||
            (c == '.' && p+1 < end && isdigit((unsigned char)*(p+1)))) {
            const char *ts = p;
            while (p < end && (isdigit((unsigned char)*p) || *p == '.' || *p == '_')) p++;
            if (p < end && (*p == 'e' || *p == 'E')) {
                p++;
                if (p < end && (*p == '+' || *p == '-')) p++;
                while (p < end && isdigit((unsigned char)*p)) p++;
            }
            SQL_SPAN("esh-n", ts, p);
            continue;
        }

        /* identifier / keyword / builtin (case-insensitive) */
        if (eshu_hl_isalpha_(c) || c == '_') {
            const char *ts = p;
            while (p < end && (eshu_hl_isalnum_(*p) || *p == '_')) p++;
            size_t wlen = (size_t)(p - ts);
            eshu_hl_flush(&out, plain, ts);
            plain = p;
            if (eshu_hl_sql_kw_match(ts, wlen, eshu_hl_sql_kw)) {
                eshu_hl_span(&out, "esh-k", ts, p);
            } else if (eshu_hl_sql_kw_match(ts, wlen, eshu_hl_sql_bi)) {
                eshu_hl_span(&out, "esh-b", ts, p);
            } else {
                eshu_hl_write_html(&out, ts, wlen);
            }
            continue;
        }

        p++;
    }

    if (in_dollar) {
        /* unclosed dollar-string — flush as string */
        SQL_SPAN("esh-s", plain, end);
    } else {
        eshu_hl_flush(&out, plain, end);
    }
    eshu_buf_putc(&out, '\0');
    *out_len = out.len - 1;
    return out.data;

#undef SQL_SPAN
}

#endif /* ESHU_SQL_H */
