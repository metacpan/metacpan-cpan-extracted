/*
 * eshu_ruby.h — Ruby language indentation scanner
 *
 * Ruby uses keyword-based block delimiters (def/end, class/end, do/end, etc.)
 * plus braces { } for single-line blocks and hashes.
 *
 * Pure C, no Perl dependencies, header-only.
 */

#ifndef ESHU_RUBY_H
#define ESHU_RUBY_H

#include "eshu.h"

/* ══════════════════════════════════════════════════════════════════
 *  Word-boundary helper
 * ══════════════════════════════════════════════════════════════════ */

static int eshu_rb_word_end(const char *p, const char *end) {
    if (p >= end) return 1;
    char c = *p;
    return !(isalnum((unsigned char)c) || c == '_' || c == '?' || c == '!');
}

static int eshu_rb_kw_at(const char *p, const char *end, const char *kw, int kwlen) {
    if (p + kwlen > end) return 0;
    if (strncmp(p, kw, (size_t)kwlen) != 0) return 0;
    return eshu_rb_word_end(p + kwlen, end);
}

/* ══════════════════════════════════════════════════════════════════
 *  String/literal scanning helpers
 * ══════════════════════════════════════════════════════════════════ */

/* Scan DQ string starting just after opening '"'. */
static const char *eshu_rb_scan_dq(const char *p, const char *end) {
    int interp = 0;
    while (p < end) {
        char c = *p;
        if (c == '\\' && p + 1 < end) { p += 2; continue; }
        if (c == '#' && p + 1 < end && *(p+1) == '{') { interp++; p += 2; continue; }
        if (interp > 0 && c == '}') { interp--; p++; continue; }
        if (interp == 0 && c == '"') return p + 1;
        p++;
    }
    return end;
}

/* Scan SQ string starting just after opening '\''. */
static const char *eshu_rb_scan_sq(const char *p, const char *end) {
    while (p < end) {
        char c = *p;
        if (c == '\\' && p + 1 < end) { p += 2; continue; }
        if (c == '\'') return p + 1;
        p++;
    }
    return end;
}

/* Scan backtick starting just after opening '`'. */
static const char *eshu_rb_scan_bt(const char *p, const char *end) {
    while (p < end) {
        char c = *p;
        if (c == '\\' && p + 1 < end) { p += 2; continue; }
        if (c == '`') return p + 1;
        p++;
    }
    return end;
}

/* Scan % literal starting just AFTER the type char (or '%' for no type).
 * open = the opening delimiter char. Returns pointer past the closing delim. */
static const char *eshu_rb_scan_pct(const char *p, const char *end, char open) {
    char close;
    int depth = 1;
    switch (open) {
        case '(': close = ')'; break;
        case '[': close = ']'; break;
        case '{': close = '}'; break;
        case '<': close = '>'; break;
        default:  close = open; break;
    }
    while (p < end) {
        char c = *p;
        if (c == '\\' && p + 1 < end) { p += 2; continue; }
        if (close != open) {
            if (c == open)  { depth++; p++; continue; }
            if (c == close) { depth--; p++; if (depth == 0) return p; continue; }
        } else {
            if (c == close) return p + 1;
        }
        p++;
    }
    return end;
}

/* Scan regex starting just after opening '/'.
 * Returns pointer past closing '/' and flags. */
static const char *eshu_rb_scan_regex(const char *p, const char *end) {
    int in_class = 0;
    while (p < end) {
        char c = *p;
        if (c == '\\' && p + 1 < end) { p += 2; continue; }
        if (!in_class && c == '[') { in_class = 1; p++; continue; }
        if (in_class  && c == ']') { in_class = 0; p++; continue; }
        if (!in_class && c == '/') {
            p++;
            while (p < end && (*p == 'i' || *p == 'm' || *p == 'x' ||
                               *p == 's' || *p == 'u' || *p == 'e'))
                p++;
            return p;
        }
        if (c == '\n') return p;
        p++;
    }
    return end;
}

/* Detect <<HEREDOC or <<~HEREDOC at some position on a line.
 * Fills ctx->heredoc_tag, sets ctx->heredoc_squig.
 * Returns 1 if found. */
static int eshu_rb_detect_heredoc(eshu_rb_ctx_t *ctx,
                                  const char *p, const char *end) {
    while (p + 1 < end) {
        if (*p == '<' && *(p+1) == '<') {
            const char *h = p + 2;
            int squig = 0;
            if (h < end && *h == '~') { squig = 1; h++; }
            char q = 0;
            if (h < end && (*h == '\'' || *h == '"' || *h == '`')) q = *h++;
            int i = 0;
            while (h < end && *h != '\n' && *h != '\r' &&
                   (isalnum((unsigned char)*h) || *h == '_') && i < 63) {
                ctx->heredoc_tag[i++] = *h++;
            }
            if (i == 0) { p++; continue; }
            ctx->heredoc_tag[i] = '\0';
            if (q && h < end && *h == q) h++;
            ctx->heredoc_squig = squig;
            ctx->state = squig ? ESHU_RB_HEREDOC_SQUIG : ESHU_RB_HEREDOC;
            return 1;
        }
        p++;
    }
    return 0;
}

/* ══════════════════════════════════════════════════════════════════
 *  Single-pass line analyzer
 *
 *  Scans [content, content+len) in ONE pass, tracking string/regex
 *  state and counting:
 *   - opens: block-opening keywords/{ (modifier forms excluded)
 *   - closes: block-closing end/}
 *   - is_mid: 1 if line starts with rescue/ensure/else/elsif/when
 * ══════════════════════════════════════════════════════════════════ */

typedef struct {
    int opens;
    int closes;
    int is_mid;
} eshu_rb_info_t;

static eshu_rb_info_t eshu_rb_analyze(const char *content, int len) {
    eshu_rb_info_t info = {0, 0, 0};
    const char *p   = content;
    const char *end = content + len;
    int can_regex   = 1;   /* 1 when next '/' is a regex */
    int first_tok   = 1;   /* 1 before first significant non-ws token */
    int content_before = 0; /* 1 if we saw non-ws, non-comment before current kw */

    while (p < end) {
        /* skip whitespace */
        while (p < end && (*p == ' ' || *p == '\t')) p++;
        if (p >= end) break;

        char c = *p;

        /* # comment — stop */
        if (c == '#') break;

        /* double-quoted string */
        if (c == '"') {
            p = eshu_rb_scan_dq(p + 1, end);
            can_regex = 0; first_tok = 0; content_before = 1;
            continue;
        }

        /* single-quoted string */
        if (c == '\'' && (can_regex || first_tok ||
                          (p > content && *(p-1) == ' '))) {
            /* simple heuristic: ' is string when preceded by space/operator */
            p = eshu_rb_scan_sq(p + 1, end);
            can_regex = 0; first_tok = 0; content_before = 1;
            continue;
        }

        /* backtick */
        if (c == '`') {
            p = eshu_rb_scan_bt(p + 1, end);
            can_regex = 0; first_tok = 0; content_before = 1;
            continue;
        }

        /* % literal */
        if (c == '%' && p + 1 < end) {
            char nx = *(p+1);
            int is_pct = 0;
            char delim = 0;
            int skip = 2; /* default: skip '%' + type char, delim is p[2] */
            if (nx == 'w' || nx == 'W' || nx == 'i' || nx == 'I' ||
                nx == 'q' || nx == 'Q' || nx == 'r' || nx == 's' || nx == 'x') {
                if (p + 2 < end) { delim = *(p+2); skip = 3; is_pct = 1; }
            } else if (nx == '(' || nx == '[' || nx == '{' || nx == '<' || nx == '|') {
                delim = nx; skip = 2; is_pct = 1;
            }
            if (is_pct) {
                p = eshu_rb_scan_pct(p + skip, end, delim);
                can_regex = 0; first_tok = 0; content_before = 1;
                continue;
            }
        }

        /* heredoc << — skip to end of line */
        if (c == '<' && p + 1 < end && *(p+1) == '<') {
            /* just advance past everything; heredoc body handled across lines */
            while (p < end) p++;
            break;
        }

        /* regex */
        if (c == '/' && can_regex) {
            p = eshu_rb_scan_regex(p + 1, end);
            can_regex = 0; first_tok = 0; content_before = 1;
            continue;
        }

        /* opening brace */
        if (c == '{') {
            info.opens++;
            can_regex = 1; first_tok = 0; content_before = 1;
            p++;
            continue;
        }

        /* closing brace */
        if (c == '}') {
            info.closes++;
            can_regex = 0; first_tok = 0; content_before = 1;
            p++;
            continue;
        }

        /* keywords: must start an identifier */
        if (isalpha((unsigned char)c) || c == '_') {
            const char *ts = p;
            while (p < end && (isalnum((unsigned char)*p) || *p == '_')) p++;
            /* Ruby allows ? and ! at end of method names */
            if (p < end && (*p == '?' || *p == '!') &&
                !(p + 1 < end && *(p+1) == '='))
                p++;
            int kwlen = (int)(p - ts);

            /* check for block-opening keywords */
            if ((kwlen == 3 && strncmp(ts, "def", 3) == 0) ||
                (kwlen == 5 && strncmp(ts, "class", 5) == 0) ||
                (kwlen == 6 && strncmp(ts, "module", 6) == 0)) {
                /* opener only if not a method call (no content before on line) */
                if (!content_before) {
                    info.opens++;
                }
                can_regex = 0; first_tok = 0; content_before = 1;
                continue;
            }

            if (kwlen == 2 && strncmp(ts, "do", 2) == 0) {
                info.opens++;
                can_regex = 1; first_tok = 0; content_before = 1;
                continue;
            }

            if ((kwlen == 2  && strncmp(ts, "if",     2)  == 0) ||
                (kwlen == 6  && strncmp(ts, "unless", 6)  == 0) ||
                (kwlen == 5  && strncmp(ts, "while",  5)  == 0) ||
                (kwlen == 5  && strncmp(ts, "until",  5)  == 0) ||
                (kwlen == 3  && strncmp(ts, "for",    3)  == 0)) {
                /* only open if NOT a modifier (no non-ws content before it) */
                if (!content_before) {
                    info.opens++;
                }
                can_regex = 1; first_tok = 0; content_before = 1;
                continue;
            }

            if ((kwlen == 5 && strncmp(ts, "begin", 5) == 0) ||
                (kwlen == 4 && strncmp(ts, "case",  4) == 0)) {
                if (!content_before) {
                    info.opens++;
                }
                can_regex = 1; first_tok = 0; content_before = 1;
                continue;
            }

            /* block-closing keyword */
            if (kwlen == 3 && strncmp(ts, "end", 3) == 0) {
                info.closes++;
                can_regex = 0; first_tok = 0; content_before = 1;
                continue;
            }

            /* middle keywords (dedent before, same depth after) */
            if (first_tok || !content_before) {
                if ((kwlen == 6 && strncmp(ts, "rescue", 6) == 0) ||
                    (kwlen == 6 && strncmp(ts, "ensure", 6) == 0) ||
                    (kwlen == 4 && strncmp(ts, "else",   4) == 0) ||
                    (kwlen == 5 && strncmp(ts, "elsif",  5) == 0) ||
                    (kwlen == 4 && strncmp(ts, "when",   4) == 0)) {
                    info.is_mid = 1;
                }
            }

            can_regex = 1; /* after keyword, / can be regex */
            first_tok = 0; content_before = 1;
            continue;
        }

        /* update can_regex based on operator chars */
        if (c == '=' || c == '(' || c == ',' || c == '[' || c == ';' ||
            c == '+' || c == '-' || c == '*' || c == '<' || c == '>' ||
            c == '!' || c == '|' || c == '&' || c == '^' || c == '~' ||
            c == ':') {
            can_regex = 1;
        } else if (c == ')' || c == ']') {
            can_regex = 0;
        }

        if (c != ' ' && c != '\t') {
            first_tok = 0;
            content_before = 1;
        }
        p++;
    }

    return info;
}

/* ══════════════════════════════════════════════════════════════════
 *  Process a single line
 * ══════════════════════════════════════════════════════════════════ */

static void eshu_rb_process_line(eshu_rb_ctx_t *ctx, eshu_buf_t *out,
                                 const char *line_start, const char *eol) {
    const char *content = eshu_skip_leading_ws(line_start);
    int len;

    /* empty line */
    if (content >= eol) {
        eshu_buf_putc(out, '\n');
        return;
    }

    len = (int)(eol - content);

    /* ── heredoc body ────────────────────────────────────────────── */
    if (ctx->state == ESHU_RB_HEREDOC || ctx->state == ESHU_RB_HEREDOC_SQUIG) {
        size_t tlen = strlen(ctx->heredoc_tag);
        /* for squiggly: compare against stripped content;
         * for classic: compare against stripped content (end marker can be indented
         * for <<~ or at col 0 for <<) */
        size_t check_len = (size_t)len;
        /* strip trailing ws from check */
        while (check_len > 0 && (content[check_len-1] == ' ' ||
               content[check_len-1] == '\t')) check_len--;

        if (check_len == tlen && strncmp(content, ctx->heredoc_tag, tlen) == 0) {
            /* end marker: emit at current depth 0 (traditional) */
            eshu_buf_write_trimmed(out, content, (int)check_len);
            eshu_buf_putc(out, '\n');
            ctx->state = ESHU_CODE;
        } else {
            /* body: verbatim */
            eshu_buf_write(out, line_start, (size_t)(eol - line_start));
            eshu_buf_putc(out, '\n');
        }
        return;
    }

    /* ── =begin block comment ────────────────────────────────────── */
    if (ctx->state == ESHU_COMMENT_BLOCK) {
        eshu_buf_write(out, line_start, (size_t)(eol - line_start));
        eshu_buf_putc(out, '\n');
        if (len >= 4 && strncmp(content, "=end", 4) == 0 &&
            (len == 4 || content[4] == ' ' || content[4] == '\n'))
            ctx->state = ESHU_CODE;
        return;
    }

    /* ── =begin detection ───────────────────────────────────────── */
    if (content[0] == '=' && len >= 6 && strncmp(content, "=begin", 6) == 0 &&
        (len == 6 || content[6] == ' ')) {
        ctx->state = ESHU_COMMENT_BLOCK;
        eshu_buf_write(out, line_start, (size_t)(eol - line_start));
        eshu_buf_putc(out, '\n');
        return;
    }

    /* ── normal Ruby code ────────────────────────────────────────── */
    eshu_rb_info_t info = eshu_rb_analyze(content, len);

    int indent_depth;

    if (info.is_mid) {
        /* middle keyword (rescue, else, etc.): emit at depth-1, depth unchanged */
        indent_depth = ctx->depth - 1;
        if (indent_depth < 0) indent_depth = 0;
    } else {
        /* For the line's own indent: only dedent by the NET number of extra closers.
         * A balanced {}/end on one line doesn't change the line's indent. */
        int net_close = info.closes - info.opens;
        if (net_close > 0) {
            indent_depth = ctx->depth - net_close;
            if (indent_depth < 0) indent_depth = 0;
        } else {
            indent_depth = ctx->depth;
        }
    }

    eshu_emit_indent(out, indent_depth, &ctx->cfg);
    eshu_buf_write_trimmed(out, content, len);
    eshu_buf_putc(out, '\n');

    /* update depth for next line */
    if (!info.is_mid) {
        ctx->depth += info.opens - info.closes;
        if (ctx->depth < 0) ctx->depth = 0;
    }
    /* is_mid: depth is unchanged (body of next clause at same depth as before) */

    /* detect heredoc on this line */
    if (ctx->state == ESHU_CODE)
        eshu_rb_detect_heredoc(ctx, content, eol);
}

/* ══════════════════════════════════════════════════════════════════
 *  Public API
 * ══════════════════════════════════════════════════════════════════ */

static char *eshu_indent_ruby(const char *src, size_t src_len,
                              const eshu_config_t *cfg, size_t *out_len) {
    eshu_rb_ctx_t  ctx;
    eshu_buf_t     out;
    const char    *p   = src;
    const char    *end = src + src_len;
    char          *result;

    memset(&ctx, 0, sizeof(ctx));
    ctx.state     = ESHU_CODE;
    ctx.can_regex = 1;
    ctx.cfg       = *cfg;

    eshu_buf_init(&out, src_len + 256);

    {
        int line_num = 1;
        while (p < end) {
            const char *eol = eshu_find_eol(p);

            if (eshu_in_range(cfg, line_num)) {
                eshu_rb_process_line(&ctx, &out, p, eol);
            } else {
                size_t saved = out.len;
                eshu_rb_process_line(&ctx, &out, p, eol);
                out.len = saved;
                eshu_buf_write_trimmed(&out, p, (int)(eol - p));
                eshu_buf_putc(&out, '\n');
            }

            p = eol;
            if (*p == '\n') p++;
            line_num++;
        }
    }

    eshu_buf_putc(&out, '\0');
    out.len--;
    *out_len = out.len;
    result   = out.data;
    return result;
}


#include "eshu_hl_util.h"

/* ══════════════════════════════════════════════════════════════════
 *  Ruby highlighting
 * ══════════════════════════════════════════════════════════════════ */

static const char * const eshu_hl_rb_kw[] = {
    "BEGIN", "END",
    "alias", "and", "begin", "break", "case", "class",
    "def", "defined?", "do", "else", "elsif", "end",
    "ensure", "false", "for", "if", "in", "module",
    "next", "nil", "not", "or", "redo", "rescue",
    "retry", "return", "self", "super", "then", "true",
    "undef", "unless", "until", "when", "while", "yield",
    "__FILE__", "__LINE__", "__method__", "__dir__",
    NULL
};

static const char * const eshu_hl_rb_bi[] = {
    "puts", "print", "p", "pp", "warn", "raise", "fail",
    "require", "require_relative", "load", "include", "extend", "prepend",
    "attr_reader", "attr_writer", "attr_accessor",
    "private", "protected", "public",
    "lambda", "proc", "block_given?", "Array", "Hash", "String",
    "Integer", "Float", "Symbol", "Regexp", "Range",
    "nil?", "frozen?", "dup", "clone", "freeze", "tap",
    NULL
};

static char *eshu_highlight_ruby(const char *src, size_t src_len, size_t *out_len) {
    eshu_buf_t   out;
    const char  *p   = src;
    const char  *end = src + src_len;
    const char  *plain;
    /* in_string: 0=code, 1=dq, 2=sq, 3=backtick, 4=regex */
    int          in_string = 0;
    int          in_block_comment = 0;  /* =begin...=end */
    int          in_heredoc = 0;
    char         heredoc_tag[64];
    int          heredoc_squig = 0;
    int          can_regex = 1;         /* can the next / be a regex? */

#define RB_SPAN(cls, s, n) do { \
    eshu_hl_flush(&out, plain, (s)); \
    eshu_hl_span(&out, (cls), (s), (s) + (n)); \
    plain = (s) + (n); \
} while (0)

    eshu_buf_init(&out, src_len * 2);
    plain = p;

    while (p < end) {
        unsigned char c = (unsigned char)*p;

        /* ── heredoc body ──────────────────────────────────────────── */
        if (in_heredoc) {
            const char *ls = p;
            /* find EOL */
            while (p < end && *p != '\n') p++;
            const char *le = p;
            /* strip trailing ws */
            const char *ct = ls;
            if (heredoc_squig)
                while (ct < le && (*ct == ' ' || *ct == '\t')) ct++;
            size_t tlen = strlen(heredoc_tag);
            size_t clen = (size_t)(le - ct);
            while (clen > 0 && (ct[clen-1] == ' ' || ct[clen-1] == '\t')) clen--;
            if (clen == tlen && strncmp(ct, heredoc_tag, tlen) == 0) {
                /* end marker: emit as-is (plain) */
                in_heredoc = 0;
            } else {
                /* body: span as string */
                RB_SPAN("esh-s", ls, le - ls);
            }
            if (p < end && *p == '\n') p++;
            continue;
        }

        /* ── =begin block comment ────────────────────────────────── */
        if (in_block_comment) {
            const char *bs = p;
            while (p < end && *p != '\n') p++;
            const char *be = p;
            /* check for =end */
            size_t llen = (size_t)(be - bs);
            if (llen >= 4 && strncmp(bs, "=end", 4) == 0 &&
                (llen == 4 || bs[4] == ' '))
                in_block_comment = 0;
            RB_SPAN("esh-c", bs, be - bs);
            if (p < end && *p == '\n') p++;
            continue;
        }

        /* ── =begin detection ────────────────────────────────────── */
        if (c == '=' && p == plain &&
            (size_t)(end - p) >= 6 && strncmp(p, "=begin", 6) == 0 &&
            (end - p == 6 || p[6] == ' ' || p[6] == '\n')) {
            in_block_comment = 1;
            const char *bs = p;
            while (p < end && *p != '\n') p++;
            RB_SPAN("esh-c", bs, p - bs);
            if (p < end && *p == '\n') p++;
            continue;
        }

        /* ── # comment ───────────────────────────────────────────── */
        if (c == '#') {
            const char *cs = p;
            while (p < end && *p != '\n') p++;
            RB_SPAN("esh-c", cs, p - cs);
            can_regex = 1;
            continue;
        }

        /* ── double-quoted string ────────────────────────────────── */
        if (c == '"') {
            const char *qs = p;
            p++;
            int interp = 0;
            while (p < end) {
                char ch = *p;
                if (ch == '\\' && p + 1 < end) { p += 2; continue; }
                if (ch == '#' && p + 1 < end && *(p+1) == '{') {
                    interp++; p += 2; continue;
                }
                if (interp > 0 && ch == '}') { interp--; p++; continue; }
                if (interp == 0 && ch == '"') { p++; break; }
                p++;
            }
            RB_SPAN("esh-s", qs, p - qs);
            can_regex = 0;
            continue;
        }

        /* ── single-quoted string ────────────────────────────────── */
        if (c == '\'') {
            /* check it's not a char-like: 'x' — treat uniformly as string */
            const char *qs = p;
            p++;
            while (p < end) {
                char ch = *p;
                if (ch == '\\' && p + 1 < end) { p += 2; continue; }
                if (ch == '\'') { p++; break; }
                p++;
            }
            RB_SPAN("esh-s", qs, p - qs);
            can_regex = 0;
            continue;
        }

        /* ── backtick string ─────────────────────────────────────── */
        if (c == '`') {
            const char *qs = p;
            p++;
            while (p < end) {
                char ch = *p;
                if (ch == '\\' && p + 1 < end) { p += 2; continue; }
                if (ch == '`') { p++; break; }
                p++;
            }
            RB_SPAN("esh-s", qs, p - qs);
            can_regex = 0;
            continue;
        }

        /* ── % literals: %w %i %q %Q %r %x ─────────────────────── */
        if (c == '%' && p + 1 < end) {
            char nx = (unsigned char)*(p+1);
            char delim = 0;
            int is_pct = 0;
            const char *cls = "esh-s";
            if (nx == 'w' || nx == 'W' || nx == 'i' || nx == 'I') {
                /* word/symbol arrays */
                if (p + 2 < end) { delim = *(p+2); is_pct = 1; }
            } else if (nx == 'q' || nx == 'Q') {
                if (p + 2 < end) { delim = *(p+2); is_pct = 1; }
            } else if (nx == 'r') {
                cls = "esh-r";
                if (p + 2 < end) { delim = *(p+2); is_pct = 1; }
            } else if (nx == 'x') {
                if (p + 2 < end) { delim = *(p+2); is_pct = 1; }
            } else if (nx == '(' || nx == '[' || nx == '{' || nx == '<' || nx == '|') {
                delim = nx; is_pct = 1;
            }
            if (is_pct) {
                const char *ps = p;
                int offset = (nx == '(' || nx == '[' || nx == '{' || nx == '<' || nx == '|')
                             ? 2 : 3;
                p = (const char *)eshu_rb_scan_pct(ps + offset, end, delim);
                RB_SPAN(cls, ps, p - ps);
                can_regex = 0;
                continue;
            }
        }

        /* ── heredoc << ──────────────────────────────────────────── */
        if (c == '<' && p + 1 < end && *(p+1) == '<') {
            const char *hs = p;
            p += 2;
            int squig = 0;
            if (p < end && *p == '~') { squig = 1; p++; }
            char q = 0;
            if (p < end && (*p == '\'' || *p == '"' || *p == '`')) q = *p++;
            int i = 0;
            while (p < end && *p != '\n' && *p != '\r' &&
                   (isalnum((unsigned char)*p) || *p == '_') && i < 63) {
                heredoc_tag[i++] = *p++;
            }
            if (i > 0) {
                heredoc_tag[i] = '\0';
                if (q && p < end && *p == q) p++;
                heredoc_squig = squig;
                in_heredoc = 1;
                /* span the opening line */
                RB_SPAN("esh-s", hs, p - hs);
                /* advance to EOL */
                while (p < end && *p != '\n') p++;
                can_regex = 1;
                continue;
            }
            /* not a heredoc — treat << as operator */
        }

        /* ── regex /.../ ─────────────────────────────────────────── */
        if (c == '/' && can_regex) {
            const char *rs = p;
            p++;
            int in_class = 0;
            while (p < end) {
                char ch = *p;
                if (ch == '\\' && p + 1 < end) { p += 2; continue; }
                if (!in_class && ch == '[') { in_class = 1; p++; continue; }
                if (in_class  && ch == ']') { in_class = 0; p++; continue; }
                if (!in_class && ch == '/') {
                    p++;
                    while (p < end && (*p == 'i' || *p == 'm' || *p == 'x' ||
                                       *p == 's' || *p == 'u' || *p == 'e'))
                        p++;
                    break;
                }
                if (ch == '\n') break;
                p++;
            }
            RB_SPAN("esh-r", rs, p - rs);
            can_regex = 0;
            continue;
        }

        /* ── symbol :name or :"..." ──────────────────────────────── */
        if (c == ':' && p + 1 < end) {
            char nx = *(p+1);
            if (nx != ':' && (isalpha((unsigned char)nx) || nx == '_' ||
                              nx == '"' || nx == '\'')) {
                const char *ss = p;
                p++;
                if (*p == '"') {
                    p++;
                    while (p < end && *p != '"') {
                        if (*p == '\\' && p + 1 < end) p++;
                        p++;
                    }
                    if (p < end) p++;
                } else if (*p == '\'') {
                    p++;
                    while (p < end && *p != '\'') {
                        if (*p == '\\' && p + 1 < end) p++;
                        p++;
                    }
                    if (p < end) p++;
                } else {
                    while (p < end && (isalnum((unsigned char)*p) || *p == '_' ||
                                       *p == '?' || *p == '!'))
                        p++;
                }
                RB_SPAN("esh-r", ss, p - ss);
                can_regex = 0;
                continue;
            }
        }

        /* ── special variables $global @iv @@cv ─────────────────── */
        if ((c == '$' && p + 1 < end && (isalpha((unsigned char)*(p+1)) ||
             *(p+1) == '_' || *(p+1) == '0')) ||
            (c == '@' && p + 1 < end && (isalpha((unsigned char)*(p+1)) ||
             *(p+1) == '_' || *(p+1) == '@'))) {
            const char *vs = p;
            if (c == '@' && *(p+1) == '@') p++;
            p++;
            while (p < end && (isalnum((unsigned char)*p) || *p == '_')) p++;
            RB_SPAN("esh-v", vs, p - vs);
            can_regex = 0;
            continue;
        }

        /* ── number ──────────────────────────────────────────────── */
        if (isdigit(c) || (c == '.' && p + 1 < end && isdigit((unsigned char)*(p+1)))) {
            const char *ns = p;
            if (c == '0' && p + 1 < end && (*(p+1) == 'x' || *(p+1) == 'X')) {
                p += 2;
                while (p < end && (isxdigit((unsigned char)*p) || *p == '_')) p++;
            } else if (c == '0' && p + 1 < end && (*(p+1) == 'b' || *(p+1) == 'B')) {
                p += 2;
                while (p < end && (*p == '0' || *p == '1' || *p == '_')) p++;
            } else if (c == '0' && p + 1 < end && (*(p+1) == 'o' || *(p+1) == 'O')) {
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
            RB_SPAN("esh-n", ns, p - ns);
            can_regex = 0;
            continue;
        }

        /* ── keyword / identifier ────────────────────────────────── */
        if (isalpha(c) || c == '_') {
            const char *ts = p;
            while (p < end && (isalnum((unsigned char)*p) || *p == '_')) p++;
            /* Ruby allows ? and ! at end of method names */
            if (p < end && (*p == '?' || *p == '!') &&
                !(p + 1 < end && *(p+1) == '='))
                p++;
            size_t wlen = (size_t)(p - ts);
            if (eshu_hl_kw(ts, wlen, eshu_hl_rb_kw)) {
                RB_SPAN("esh-k", ts, wlen);
                can_regex = 1;
            } else if (eshu_hl_kw(ts, wlen, eshu_hl_rb_bi)) {
                RB_SPAN("esh-b", ts, wlen);
                can_regex = 0;
            } else {
                can_regex = 0;
            }
            continue;
        }

        /* ── update can_regex for operators ──────────────────────── */
        if (c == '=' || c == '(' || c == ',' || c == '[' || c == '{' ||
            c == '!' || c == '&' || c == '|' || c == '+' || c == '-' ||
            c == '*' || c == '<' || c == '>' || c == ';' || c == '\n') {
            can_regex = 1;
        } else if (c == ')' || c == ']' || c == '}') {
            can_regex = 0;
        }

        p++;
    }

    eshu_hl_flush(&out, plain, end);
    eshu_buf_putc(&out, '\0');
    *out_len = out.len - 1;
    return out.data;

#undef RB_SPAN
}

#endif /* ESHU_RUBY_H */
